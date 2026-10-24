# Questions for Kiro

Drop anything you want me to research, explain, or build a lab for. I'll move items
from **Open** to **Answered** (with a link to where the answer lives) as I handle them.

## How to add one

Just append a bullet under **Open**. Keep it short — a sentence is enough.

---

## Open

_(nothing open right now — add a bullet here whenever something comes up)_

## Answered

- [x] **Why does the cluster stay `NotReady` until a CNI is installed, and how does
  `kubeadm` pick one?** → `kubeadm` does **not** install or choose a CNI for you —
  it only sets `--pod-network-cidr` and leaves the network plugin to you. The
  kubelet reports `NotReady` until a CNI is configured, and pods needing an IP
  (like CoreDNS) stay `Pending`. Installing one (we used Calico) fixes both at
  once. Seen live in
  [domains/01-cluster-architecture/labs/00-first-cluster-bringup.md](../domains/01-cluster-architecture/labs/00-first-cluster-bringup.md)
  (Steps 5–7). _(2026-10-24)_
- [x] **What is a static pod?** → A pod the kubelet runs directly from YAML in
  `/etc/kubernetes/manifests/` — no scheduler, no Deployment. The control-plane
  components (`etcd`, `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`)
  run this way to bootstrap the cluster. Pod name = manifest name + node name
  (e.g. `kube-apiserver-cp`). See the same lab, Step 4. _(2026-10-24)_

---

Back to [repo index](../README.md).
