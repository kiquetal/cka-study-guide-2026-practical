# Lab Environments

Two isolated ways to get a Kubernetes cluster for practice. Both keep Kubernetes off
your host OS. **Start with the [preflight check](preflight-check.md).**

---

## Which one should I use?

| | [`vagrant-kubeadm/`](vagrant-kubeadm/) | [`kind/`](kind/) |
|---|---|---|
| **Isolation** | Full Linux VMs (libvirt/KVM) | Docker containers as "nodes" |
| **Exam realism** | ✅ High — real `kubeadm`, systemd `kubelet`, multi-node | ⚠️ Lower — no systemd/kubelet layer |
| **Boot time** | Minutes | Seconds |
| **Resource cost** | Heavier (RAM/CPU per VM) | Light |
| **Best for** | Cluster Architecture & **Troubleshooting** labs | Workloads, Networking, Storage, **Istio Ambient** experiments |

### Rule of thumb

- **Learning cluster-admin & breaking/fixing things like the exam?** → `vagrant-kubeadm/`.
  The exam gives you real nodes with systemd — only this environment reproduces
  `journalctl -u kubelet`, static-pod manifests under `/etc/kubernetes/manifests`, etc.
- **Just need a cluster fast to try a manifest, a NetworkPolicy, or Istio?** → `kind/`.

You'll use both. Many app-layer concepts are identical on either; only the
node/control-plane troubleshooting realism differs.

---

## Setup order

1. [`preflight-check.md`](preflight-check.md) — verify VT-x/KVM, install libvirt + vagrant.
2. Pick an environment:
   - [`vagrant-kubeadm/`](vagrant-kubeadm/) — exam-realistic 3-node cluster.
   - [`kind/`](kind/) — fast disposable cluster.

---

## Operating & understanding the lab

How to actually use and reason about the lab once it's up:

- 🔌 [`using-the-cluster-with-kubectl.md`](using-the-cluster-with-kubectl.md) —
  point `kubectl` at the lab cluster **without clobbering** your real
  `~/.kube/config` (e.g. existing EKS contexts). Dedicated kubeconfig, `kcka`
  alias, safety checklist.
- 🌐 [`notes-libvirt-nat-and-node-ips.md`](notes-libvirt-nat-and-node-ips.md) —
  libvirt NAT model and the multi-NIC **two-IP nuance** (API advertise IP vs
  kubelet InternalIP vs pod/service CIDRs); when the distinction matters and when
  it doesn't.

Back to [repo index](../README.md).
