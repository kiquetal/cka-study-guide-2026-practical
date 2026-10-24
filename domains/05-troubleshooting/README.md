# Domain 05 — Troubleshooting (30%)

> **Status:** Placeholder. Content will be added in a later increment.
> This is the **highest-weight** domain — it will be built out first.

Planned contents:

- Study notes on diagnosing node, control-plane, networking, and workload failures.
- `cheatsheet.md` — triage commands (`kubectl get events`, `journalctl -u kubelet`,
  `crictl ps`, etc.).
- `labs/` — **break/fix** exercises (run on the kubeadm VM cluster in
  [`../../environment/vagrant-kubeadm/`](../../environment/vagrant-kubeadm/) for systemd realism):
  - kubelet / node NotReady failures.
  - Control-plane static-pod issues.
  - DNS / networking debugging.
  - `crictl` container runtime inspection.
  - Resource exhaustion.

Back to [repo index](../../README.md).
