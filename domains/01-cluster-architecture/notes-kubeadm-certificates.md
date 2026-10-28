# kubeadm & cluster certificates (PKI) — the part people forget

🎯 **Domain 01 — Cluster Architecture (25%).** `kubeadm` doesn't just bootstrap
the cluster — it also builds and manages the **entire TLS PKI** that every
component uses to talk securely. Cert expiry/renewal is a real, high-value exam
and real-world task.

---

## The idea (theory)

Every connection in a cluster is **mutually-authenticated TLS** (apiserver↔etcd,
apiserver↔kubelet, controller-manager↔apiserver, etc.). Someone has to issue all
those certificates. That someone is **`kubeadm`**:

- At `kubeadm init`, it creates the **Certificate Authorities (CAs)** and signs a
  **leaf certificate** for every component, all under `/etc/kubernetes/pki/`.
- It writes **kubeconfigs** (`admin.conf`, `controller-manager.conf`,
  `scheduler.conf`, `kubelet.conf`) that embed client certs.
- `kubeadm join` uses the CA hash (in the join command) so a worker can trust the
  control plane and get its kubelet cert signed.

```
   kubeadm init
      │  generates…
      ├─ CAs (long-lived, ~10 years):   ca, etcd-ca, front-proxy-ca
      └─ leaf certs (short-lived, ~1y): apiserver, apiserver-etcd-client,
            apiserver-kubelet-client, etcd-server/peer/healthcheck,
            front-proxy-client, + the .conf kubeconfigs
```

> **The trap:** CAs last ~10 years, but **leaf certs expire in ~1 year.** A cluster
> that's ~12 months old with no upgrades → certs expire → `kubectl` suddenly fails
> with x509 errors. (`kubeadm upgrade` auto-renews them, which is why actively
> upgraded clusters rarely hit this.)

## Why is this relevant?

- 🎯 **For the exam:** "certs are expired / the API server won't start after ~1
  year" is a classic task. You must know `kubeadm certs check-expiration` and
  `kubeadm certs renew`, and where the PKI lives (`/etc/kubernetes/pki/`). The etcd
  cert paths here are the **same ones** you need for `etcdctl` backup/restore.
- 🌍 **Real-world / edge cases — strange behaviour this explains:**
  - `kubectl` fails cluster-wide with `x509: certificate has expired or is not yet
    valid` → leaf certs expired (the 1-year trap above). Renew + restart control
    plane static pods.
  - A worker's kubelet stops talking after ~1 year → kubelet client cert expired;
    kubelet cert **auto-rotation** usually handles this, but if disabled it won't.
  - Clock skew between nodes → TLS fails with "not yet valid" even on fresh certs.

---

## Key parts (verified on this lab's `cp`)

| Path / command | What it is |
|----------------|------------|
| `/etc/kubernetes/pki/` | all CAs + leaf certs (apiserver, sa, front-proxy, etcd/) |
| `/etc/kubernetes/pki/ca.{crt,key}` | the cluster **root CA** (signs most leaf certs) |
| `/etc/kubernetes/pki/etcd/` | etcd's own CA + server/peer/healthcheck certs |
| `/etc/kubernetes/*.conf` | kubeadm-generated kubeconfigs (admin, scheduler, controller-manager, kubelet, super-admin) |
| `kubeadm certs check-expiration` | table of every cert + expiry + which CA signed it |
| `kubeadm certs renew all` | renew all leaf certs (then restart the control-plane pods) |

## How it works / flow — cert renewal

```
  1. check   → kubeadm certs check-expiration        (see what's expiring)
  2. renew   → kubeadm certs renew all               (re-signs leaf certs from the CA)
  3. restart → move the 4 manifests out of /etc/kubernetes/manifests/ and back
               (or reboot) so apiserver/etc. pick up the new certs
  4. kubeconfig → if admin.conf was renewed, re-copy it to ~/.kube/config
```
The CA itself is NOT renewed here (it's good for ~10y); you only re-sign the leaves.

## Verified on the lab

```text
$ sudo ls /etc/kubernetes/pki/
apiserver.crt  apiserver.key  apiserver-etcd-client.crt  apiserver-kubelet-client.crt
ca.crt  ca.key  front-proxy-ca.crt  front-proxy-client.crt  sa.key  sa.pub  etcd/

$ sudo ls /etc/kubernetes/pki/etcd/
ca.crt  ca.key  healthcheck-client.crt  peer.crt  server.crt  (+ .key files)

$ sudo kubeadm certs check-expiration        # (trimmed)
CERTIFICATE                EXPIRES                 RESIDUAL TIME   CERTIFICATE AUTHORITY
admin.conf                 Oct 25, 2027 22:13 UTC  362d            ca
apiserver                  Oct 25, 2027 22:13 UTC  362d            ca
apiserver-etcd-client      Oct 25, 2027 22:13 UTC  362d            etcd-ca
apiserver-kubelet-client   Oct 25, 2027 22:13 UTC  362d            ca
etcd-server                Oct 25, 2027 22:13 UTC  362d            etcd-ca
...
CERTIFICATE AUTHORITY   EXPIRES                 RESIDUAL TIME
ca                      Oct 22, 2036 22:13 UTC  9y              <- CAs last ~10 years
etcd-ca                 Oct 22, 2036 22:13 UTC  9y
front-proxy-ca          Oct 22, 2036 22:13 UTC  9y
```
Note the split: **leaf certs 362d, CAs 9y** — the whole "certs expire after a year"
story in one screen.

## Commands to remember

```bash
# where everything lives (memorize)
/etc/kubernetes/pki/          # CAs + leaf certs   (etcd certs in pki/etcd/)
/etc/kubernetes/*.conf        # kubeadm kubeconfigs

# certificates
sudo kubeadm certs check-expiration        # when does each cert expire?
sudo kubeadm certs renew all               # renew all leaf certs
sudo kubeadm certs renew apiserver         # renew just one

# after renew: restart control-plane static pods so they load new certs
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp && sleep 5 \
  && sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# if admin.conf was renewed, refresh your kubeconfig
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config

# CA cert hash (for a join command, if you lost it)
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
  | openssl rsa -pubin -outform der 2>/dev/null \
  | openssl dgst -sha256 -hex | sed 's/^.* //'
```

## Gotchas / failure modes

- **`x509: certificate has expired`** cluster-wide after ~1 year → leaf certs
  expired. `kubeadm certs renew all` → restart control-plane pods → re-copy admin.conf.
- **Renewed certs but still failing** → you forgot to **restart** the static pods;
  they cached the old cert in memory.
- **kubelet cert** is usually **auto-rotated** (different from the control-plane
  leaf certs); if rotation is off, it won't renew itself.
- **Don't delete the CA** (`ca.key`) — losing it means you can't sign new certs;
  you'd have to rebuild the cluster.

## 30-second self-test

1. Where does kubeadm put the cluster certs? → `/etc/kubernetes/pki/` (etcd in `pki/etcd/`).
2. How long do leaf certs vs CAs last by default? → leaf ≈ **1 year**, CA ≈ **10 years**.
3. Command to see expiry? → `kubeadm certs check-expiration`.
4. Command to renew? → `kubeadm certs renew all`, then **restart the control-plane static pods**.
5. Why does an idle ~1-year-old cluster suddenly break? → leaf certs expired; no
   `kubeadm upgrade` ran to auto-renew them.

---

See also: [`notes-cluster-architecture.md`](notes-cluster-architecture.md) (kubeadm
lifecycle), [`notes-interacting-with-control-plane.md`](notes-interacting-with-control-plane.md)
(etcd certs reused for `etcdctl`), [`labs/configuring-worker2.md`](labs/configuring-worker2.md).
