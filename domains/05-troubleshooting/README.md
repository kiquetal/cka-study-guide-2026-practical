# Domain 05 — Troubleshooting (30%)

🎯 Highest-weight domain. Source: [CNCF CKA Curriculum](https://github.com/cncf/curriculum). Objectives verified verbatim against the official **CKA Curriculum v1.37** (2026-10-27).

## Exam objectives (official competencies)

- [ ] Troubleshoot clusters and nodes
- [ ] Troubleshoot cluster components
- [ ] Monitor cluster and application resource usage
- [ ] Manage and evaluate container output streams (logs)
- [ ] Troubleshoot services and networking

## Study material here

- 📖 [`notes-troubleshooting.md`](notes-troubleshooting.md) — triage order, node
  NotReady, control-plane static-pod recovery, pod STATUS decode, service
  endpoints, `crictl`, resource exhaustion.
- 🧪 `labs/` — break/fix exercises (planned; run on the kubeadm VM cluster in
  [`../../environment/vagrant-kubeadm/`](../../environment/vagrant-kubeadm/) for
  systemd realism): kubelet/node NotReady, control-plane static pods, DNS/networking,
  `crictl`, resource exhaustion.

## Recommended labs

Run on the **kubeadm VM cluster** (real systemd — needed for `journalctl`/static pods).

| # | Lab | Objective practiced | Environment |
|---|-----|---------------------|-------------|
| 1 | Break the kubelet (bad `/var/lib/kubelet/config.yaml` or swap on), watch the node go `NotReady`, fix via `journalctl -u kubelet` → restart | Troubleshoot clusters and nodes | kubeadm |
| 2 | Break a control-plane static pod (typo a flag in `kube-apiserver.yaml`), recover with `crictl` + manifest edit | Troubleshoot cluster components | kubeadm |
| 3 | Deploy a pod with a wrong image tag + a crashing command; diagnose `ImagePullBackOff` and `CrashLoopBackOff` with `logs --previous` | Evaluate container output streams | kind or kubeadm |
| 4 | Create a Service whose selector doesn't match pod labels; find the empty `endpoints` and fix | Troubleshoot services and networking | kind |
| 5 | Scale a Deployment past node capacity; read `Insufficient cpu/memory`; add `metrics-server` and use `kubectl top` | Monitor resource usage | kind or kubeadm |

Back to [repo index](../../README.md).
