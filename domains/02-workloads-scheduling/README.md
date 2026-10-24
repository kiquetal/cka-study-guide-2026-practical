# Domain 02 — Workloads & Scheduling (15%)

🎯 Source: [CNCF CKA Curriculum](https://github.com/cncf/curriculum).

## Exam objectives (official competencies)

- [ ] Understand application deployments and how to perform rolling updates and rollbacks
- [ ] Use ConfigMaps and Secrets to configure applications
- [ ] Configure workload autoscaling
- [ ] Understand the primitives used to create robust, self-healing application deployments
- [ ] Configure Pod admission and scheduling (limits, node affinity, etc.)

## Study material here

- 📖 [`notes-workloads.md`](notes-workloads.md) — controller hierarchy
  (Deployment→ReplicaSet→Pod), rolling updates/rollback, ConfigMaps & Secrets,
  resource requests/limits, probes, HPA autoscaling.
- 📖 [`notes-taints-tolerations.md`](notes-taints-tolerations.md) — the scheduling
  half, from first principles: the scheduler FILTER/SCORE/BIND loop, taints &
  tolerations, nodeSelector, node affinity, pod (anti)affinity, with ASCII
  diagrams and a self-test.
- 🧪 Planned labs (fast iteration on [`../../environment/kind/`](../../environment/kind/)):
  Deployment create/scale/rollout/rollback, ConfigMap/Secret consumption,
  taints/tolerations + affinity placement, resource limits & OOMKill.

Back to [repo index](../../README.md).
