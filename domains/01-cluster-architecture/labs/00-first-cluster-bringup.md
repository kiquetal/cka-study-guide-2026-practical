# Lab 00 — First Cluster Bring-Up (follow along)

🎯 **Exam scope:** Cluster Architecture, Installation & Configuration (25%).

A slow, step-by-step walk-through of standing up the `vagrant-kubeadm` control
plane **by hand** and getting it to `Ready`. The `provision/` scripts can do all
of this automatically, but doing it yourself once teaches the pieces the exam
actually tests: `kubeadm init`, kubeconfig setup, the CNI, and why a node stays
`NotReady`.

> **Where do I run things?** Two contexts. Watch your shell prompt:
> - **host** → your Pop!_OS machine, in `environment/vagrant-kubeadm/`.
> - **node** (`vagrant@cp:~$`) → inside the control-plane VM.

---

## Step 1 — Enter the control-plane node  _(run on: host)_

```bash
cd environment/vagrant-kubeadm
sg libvirt -c "vagrant ssh cp"
```

Your prompt should change to:

```
vagrant@cp:~$
```

That `vagrant@cp` means you are **inside** the node. Everything below runs here
unless it says otherwise. Type `exit` to leave later.

---

## Step 2 — Confirm kubectl isn't configured yet  _(run on: node)_

```bash
kubectl get nodes
```

Expected (this is normal at this point):

```
The connection to the server localhost:8080 was refused ...
```

**Why:** `kubeadm init` wrote admin credentials to `/etc/kubernetes/admin.conf`
(root-only). `kubectl` looks for `~/.kube/config`, which doesn't exist yet for
the `vagrant` user, so it falls back to `localhost:8080` and fails.

---

## Step 3 — Set up kubeconfig for your user  _(run on: node)_

Run these one at a time:

```bash
mkdir -p $HOME/.kube
```
```bash
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
```
```bash
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

What each does:
1. create the `.kube` dir in your home
2. copy the admin kubeconfig into it
3. hand ownership to the `vagrant` user so `kubectl` can read it

Now test:

```bash
kubectl get nodes
```

Expected:

```
NAME   STATUS     ROLES           AGE   VERSION
cp     NotReady   control-plane   ...   v1.31.x
```

✅ `kubectl` now talks to the API server. The node is **`NotReady`** — that's
expected and we fix it next.

---

## Step 4 — Look at what's running  _(run on: node)_

```bash
kubectl get pods -n kube-system
```

You should see the control-plane static pods **Running**:
`etcd-cp`, `kube-apiserver-cp`, `kube-controller-manager-cp`, `kube-scheduler-cp`,
plus `kube-proxy-*`. The two `coredns-*` pods will be **`Pending`**.

These static pods come from manifests on disk — peek at them:

```bash
sudo ls /etc/kubernetes/manifests/
```

🎯 **Exam concept — static pods:** the kubelet watches
`/etc/kubernetes/manifests/` and runs any pod YAML it finds there directly (no
scheduler, no Deployment). This is how the control plane bootstraps itself.

---

## Step 5 — Why is the node NotReady?  _(concept)_

The node is `NotReady` and CoreDNS is `Pending` for the **same reason: there is
no CNI (pod network) installed yet.**

- The kubelet reports `NotReady` until a network plugin is configured.
- CoreDNS can't get a pod IP without a CNI, so it stays `Pending`.

Installing a CNI fixes both at once.

---

## Step 6 — Install the Calico CNI  _(run on: node)_

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

Watch the pods come up (Ctrl-C to stop watching):

```bash
kubectl get pods -n kube-system -w
```

Wait until the `calico-*` and `coredns-*` pods are `Running` (~1–2 min).

---

## Step 7 — Confirm the node is Ready  _(run on: node)_

```bash
kubectl get nodes
```

Expected:

```
NAME   STATUS   ROLES           AGE   VERSION
cp     Ready    control-plane   ...   v1.31.x
```

🎉 Single-node control plane is up and `Ready`.

---

## Step 8 — (later) Add worker1  _(run on: host, then node)_

Not now — this is the next lab. When ready, the join command printed by
`kubeadm init` looks like:

```
kubeadm join 192.168.56.10:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```

If the token has expired (they last 24h), regenerate on `cp`:

```bash
kubeadm token create --print-join-command
```

---

## Troubleshooting

- **`localhost:8080` refused** → kubeconfig not set up; redo Step 3.
- **Node stuck `NotReady` after CNI** → `kubectl get pods -n kube-system`; the
  `calico-*` pods must be `Running`. Give it another minute.
- **`kubeadm init` preflight errors** → see
  [`../../../environment/vagrant-kubeadm/README.md`](../../../environment/vagrant-kubeadm/README.md)
  (conntrack/socat and DNS fixes are documented there).

Back to [domain index](../README.md) · [repo index](../../../README.md).
