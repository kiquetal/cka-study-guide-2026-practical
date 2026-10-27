# Interacting with the control-plane components (etcd, API server, scheduler, CM)

🎯 **Domain 01 — Cluster Architecture (25%).** The architecture note showed *what*
the components are; this one is the **real use case** — how you actually talk to
each one on the node, which is exactly what the exam asks ("back up etcd", "the API
server won't start", "check component health").

See the picture first: [`notes-cluster-architecture-diagram.md`](notes-cluster-architecture-diagram.md).

---

## The idea (theory)

All four control-plane components run as **static pods** on `cp`
(`/etc/kubernetes/manifests/`). You interact with them at three different layers,
and knowing *which layer* is the whole skill:

```
  LAYER                 TOOL                 use it when…
  ─────────────────────────────────────────────────────────────────────
  1. API (normal)       kubectl              the API server is UP
  2. etcd (direct)      etcdctl (API=3)      backup/restore, inspect raw state
  3. node / runtime     static manifests,    the API server is DOWN, or you must
                        journalctl, crictl   retune/restart a component
```

- **API server** = the only front door. Everything else talks *through* it.
- **etcd** = the database. You talk to it **directly** with `etcdctl` (TLS certs),
  not through kubectl — this is how backup/restore works.
- **scheduler / controller-manager** = control loops; you rarely "talk" to them,
  you check their **health** and read their **logs**.

---

## Key parts — how you interact with each

| Component | Normal interaction | Direct/low-level interaction |
|-----------|--------------------|------------------------------|
| **API server** | every `kubectl` command; `kubectl get --raw=/healthz` | edit `/etc/kubernetes/manifests/kube-apiserver.yaml`; `journalctl -u kubelet` when it won't start |
| **etcd** | *(none via kubectl)* | `etcdctl` with the etcd certs: `member list`, `endpoint health/status`, `snapshot save/restore`, raw `get /registry/...` |
| **scheduler** | `kubectl get componentstatuses`; logs | edit `kube-scheduler.yaml`; `kubectl -n kube-system logs kube-scheduler-cp` |
| **controller-manager** | `kubectl get componentstatuses`; logs | edit `kube-controller-manager.yaml`; logs |

---

## How it works / flow — talking to etcd directly

etcd only accepts **mutually-authenticated TLS**, so every `etcdctl` call needs
three cert flags + the endpoint. The manifest tells you exactly what to use:

```
/etc/kubernetes/manifests/etcd.yaml  (verified):
  --listen-client-urls=https://127.0.0.1:2379,https://192.168.56.10:2379
  --cert-file=/etc/kubernetes/pki/etcd/server.crt
  --key-file =/etc/kubernetes/pki/etcd/server.key
  --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
```

So: endpoint `https://127.0.0.1:2379`, and certs under `/etc/kubernetes/pki/etcd/`.
Memorize that path — the exam gives you a broken cluster and expects you to know it.

---

## Verified on the lab

**1. API server health + component health (works while the API is up):**
```text
$ kubectl get --raw='/healthz'
ok

$ kubectl get componentstatuses        # (v1 ComponentStatus deprecated, still shown)
NAME                 STATUS    MESSAGE   ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-0               Healthy   ok
```

**2. Talking to etcd directly.** Note: `etcdctl`/`crictl` are **not on the node's
PATH** — the `etcdctl` binary lives *inside* the etcd image. Reach it via the pod
(the etcd image is distroless, so exec `etcdctl` directly — there is no `sh`):
```text
$ kubectl -n kube-system exec etcd-cp -- etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    member list -w table
┌──────────────────┬─────────┬──────┬────────────────────────────┬────────────────────────────┐
│        ID        │ STATUS  │ NAME │         PEER ADDRS         │        CLIENT ADDRS        │
├──────────────────┼─────────┼──────┼────────────────────────────┼────────────────────────────┤
│ f0e4577804b51494 │ started │  cp  │ https://192.168.56.10:2380 │ https://192.168.56.10:2379 │
└──────────────────┴─────────┴──────┴────────────────────────────┴────────────────────────────┘

$ ... endpoint health
https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 51ms

$ ... endpoint status -w table   (trimmed)
ENDPOINT                 VERSION  DB SIZE  IS LEADER
https://127.0.0.1:2379   3.7.0    4.1 MB   true
```

**3. How Kubernetes actually stores objects in etcd** — every resource is a key
under `/registry/...`. This is the "database" made concrete:
```text
$ ... get /registry --prefix --keys-only   (filtered)
/registry/deployments/kube-system/calico-kube-controllers
/registry/deployments/kube-system/coredns
/registry/namespaces/default
/registry/namespaces/kube-system
/registry/pods/...
```
Delete etcd → all of that is gone → the cluster is gone. That's why **etcd backup
is the single highest-value recovery skill.**

---

## Commands to remember

```bash
# --- API server / component health ---
kubectl get --raw='/healthz'            # is the API server itself healthy?
kubectl get componentstatuses           # scheduler / controller-manager / etcd
kubectl -n kube-system logs kube-scheduler-cp          # a component's logs
kubectl -n kube-system logs kube-controller-manager-cp

# --- etcd (the etcd certs + 127.0.0.1:2379 endpoint; run on cp) ---
export E="--cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379"
ETCDCTL_API=3 etcdctl $E member list -w table
ETCDCTL_API=3 etcdctl $E endpoint health

# backup (high-value exam task)
ETCDCTL_API=3 etcdctl $E snapshot save /tmp/etcd-backup.db
ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db -w table
# restore to a NEW data dir, then point etcd.yaml's hostPath at it
ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db --data-dir /var/lib/etcd-restore

# --- when the API server is DOWN (kubectl can't help) ---
sudo ls /etc/kubernetes/manifests/          # the control-plane manifests
sudo journalctl -u kubelet -n 50 --no-pager # why the static pod won't start
# (crictl/etcdctl may need installing; the binaries live in the component images)
```

---

## Gotchas / failure modes

- **`etcdctl: command not found` on the node** — normal. It ships inside the etcd
  image, not on the node PATH. Options: `kubectl exec` into `etcd-cp`, or install
  the `etcd-client` package. For a **backup**, you usually install `etcdctl` on the
  node (you need it when the API is down).
- **etcd image is distroless** — no `sh`, so `kubectl exec etcd-cp -- sh -c '...'`
  fails. Exec `etcdctl` **directly** as the command.
- **Forgot the certs/endpoint** → `context deadline exceeded`. Read them straight
  from `/etc/kubernetes/manifests/etcd.yaml`; certs are under `/etc/kubernetes/pki/etcd/`.
- **API server down → `kubectl` is useless.** Drop to the node layer: static
  manifest + `journalctl -u kubelet` (+ `crictl ps` if installed). Never try to
  "kubectl restart" a control-plane component — edit its manifest file.
- **`componentstatuses` is deprecated** (v1.19+) but still works and is a fast
  health glance on the exam.

---

## 30-second self-test

1. How do you talk to etcd — kubectl or etcdctl? → **etcdctl**, directly, with the
   etcd TLS certs. kubectl never talks to etcd.
2. Where are the etcd certs + what endpoint? → `/etc/kubernetes/pki/etcd/` +
   `https://127.0.0.1:2379`.
3. Under what etcd key prefix does Kubernetes store every object? → `/registry/...`.
4. The API server is down and `kubectl` fails — where do you look? → the static
   manifest `/etc/kubernetes/manifests/kube-apiserver.yaml` + `journalctl -u kubelet`.
5. How do you restart a control-plane component? → edit/move its **manifest file**
   (the kubelet re-runs it); not via `kubectl`.
6. Highest-value etcd skill for the exam? → **snapshot save/restore**.

---

See also: [`notes-cluster-architecture-diagram.md`](notes-cluster-architecture-diagram.md),
[`notes-cluster-architecture.md`](notes-cluster-architecture.md) (etcd backup/restore section),
[`../05-troubleshooting/notes-troubleshooting.md`](../05-troubleshooting/notes-troubleshooting.md).
