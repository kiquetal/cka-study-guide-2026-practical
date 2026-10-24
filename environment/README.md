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

Back to [repo index](../README.md).
