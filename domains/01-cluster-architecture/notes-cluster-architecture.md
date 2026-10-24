# Cluster Architecture — study notes (first principles)

🎯 **Exam scope:** Cluster Architecture, Installation & Configuration — **25%**.
Covers how the cluster is wired, RBAC, etcd backup/restore, kubeadm upgrades,
and kubeconfig/context management.

> Hands-on belongs on the kubeadm VM cluster
> ([`../../environment/vagrant-kubeadm/`](../../environment/vagrant-kubeadm/)).
> See [Lab 00 — first cluster bring-up](labs/00-first-cluster-bringup.md).

---

## 0. The pieces (first principles)

```
   CONTROL PLANE (node: cp)                     WORKER NODES
   ┌────────────────────────────┐              ┌───────────────────┐
   │  kube-apiserver  ← the only │◀──────────── │  kubelet          │
   │     thing that writes etcd  │              │  kube-proxy       │
   │  etcd  (key-value store =   │              │  container runtime│
   │     the cluster's truth)    │              │  (containerd)     │
   │  kube-scheduler (picks node)│              │  your Pods        │
   │  kube-controller-manager    │              └───────────────────┘
   │     (reconciles desired/real)│
   └────────────────────────────┘

   Everything talks THROUGH the apiserver. etcd is the source of truth.
   Control-plane components run as STATIC PODS (/etc/kubernetes/manifests/).
```

- **apiserver** — front door; validates + persists everything to etcd.
- **etcd** — the database. Back this up and you can restore the whole cluster.
- **scheduler** — assigns Pending pods to nodes (FILTER/SCORE/BIND).
- **controller-manager** — loops reconciling desired state → actual state.
- **kubelet** — on every node; runs containers, reports status.
- **kube-proxy** — programs iptables/ipvs for Service networking.

---

## 1. kubeadm lifecycle

```bash
kubeadm init --pod-network-cidr=10.244.0.0/16   # bootstrap control plane
# → writes certs, static-pod manifests, admin.conf, prints a join command
kubeadm token create --print-join-command        # regenerate join (tokens last 24h)
kubeadm join <cp-ip>:6443 --token ... --discovery-token-ca-cert-hash sha256:...
kubeadm reset -f                                  # tear a node back down
```

After init, set up kubeconfig for your user:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Then install a CNI (the node stays `NotReady` until you do).

---

## 2. RBAC — who can do what

```
   SUBJECT (user / group / serviceaccount)
        │  bound by
        ▼
   RoleBinding ─────▶ Role          (namespaced permissions)
   ClusterRoleBinding ▶ ClusterRole (cluster-wide permissions)

   Role/ClusterRole = a set of allowed verbs on resources (what)
   *Binding         = attaches that set to a subject (who)
```

```bash
# a Role: allow get/list/watch pods in namespace dev
kubectl create role pod-reader --verb=get,list,watch --resource=pods -n dev
# bind it to user "jane"
kubectl create rolebinding jane-pods --role=pod-reader --user=jane -n dev

# cluster-wide equivalents
kubectl create clusterrole node-reader --verb=get,list --resource=nodes
kubectl create clusterrolebinding jane-nodes --clusterrole=node-reader --user=jane

# test effective permissions
kubectl auth can-i list pods -n dev --as=jane
```

- **Role + RoleBinding** = permissions in ONE namespace.
- **ClusterRole + ClusterRoleBinding** = cluster-wide (or non-namespaced resources
  like nodes, PVs).
- A **ClusterRole** can also be referenced by a **RoleBinding** to grant its verbs
  in just one namespace.

---

## 3. etcd backup & restore 🎯 (high-value exam task)

etcd holds the entire cluster state. Snapshot it, and you can restore.

```bash
# SAVE a snapshot (run on the control-plane; certs live in /etc/kubernetes/pki/etcd)
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# verify
ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db --write-out=table

# RESTORE to a new data dir
ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore
```
To use the restored data: edit `/etc/kubernetes/manifests/etcd.yaml` so its
`hostPath` volume points at `/var/lib/etcd-restore`, then the kubelet restarts
etcd against the restored state.

> Know where the certs are (`/etc/kubernetes/pki/etcd/`) and the endpoint
> (`https://127.0.0.1:2379`) cold — the exam gives you a broken cluster and a
> snapshot file.

---

## 4. kubeadm upgrade workflow

Upgrade order: **control plane first, then workers**, one minor version at a time.

```bash
# on control plane:
apt-get update && apt-get install -y kubeadm=1.31.x-*   # bump kubeadm first
kubeadm upgrade plan                                      # see what's available
kubeadm upgrade apply v1.31.x                             # upgrade control plane
# then kubelet+kubectl on the node:
apt-get install -y kubelet=1.31.x-* kubectl=1.31.x-*
systemctl daemon-reload && systemctl restart kubelet

# on each worker (drain first from control plane):
kubectl drain <worker> --ignore-daemonsets
# on the worker: bump kubeadm, `kubeadm upgrade node`, bump kubelet, restart
kubectl uncordon <worker>
```

---

## 5. kubeconfig & contexts

```
   kubeconfig = clusters + users + contexts
   context = (cluster + user + namespace) triple you're "pointed at"
```
```bash
kubectl config get-contexts
kubectl config current-context
kubectl config use-context <name>            # switch cluster/user
kubectl config set-context --current --namespace=dev   # change default ns
```
`KUBECONFIG` env var can point at (or merge) multiple config files.

---

## 6. Exam-speed checklist

```
 add a node              → kubeadm token create --print-join-command → kubeadm join
 back up cluster         → etcdctl snapshot save (API=3, etcd certs, :2379)
 restore cluster         → etcdctl snapshot restore → point etcd.yaml at new data dir
 grant permissions       → Role/ClusterRole + *Binding ; test with auth can-i
 upgrade                 → kubeadm first, control plane before workers, drain workers
 switch cluster/ns       → kubectl config use-context / set-context --current -n
```

Back to [domain index](README.md) · [repo index](../../README.md).
