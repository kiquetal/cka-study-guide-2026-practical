# Domain 05 — Troubleshooting (30%)

🎯 Highest-weight domain. Source: [CNCF CKA Curriculum](https://github.com/cncf/curriculum).

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

Back to [repo index](../../README.md).
