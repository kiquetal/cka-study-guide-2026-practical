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

## Recommended labs

Fast on **kind**; scheduling/taint labs also work on the kubeadm `cp` node.

| # | Lab | Objective practiced | Environment |
|---|-----|---------------------|-------------|
| 1 | Create a Deployment, scale it, `set image`, watch `rollout status`, then `rollout undo` | Deployments, rolling updates/rollbacks | kind |
| 2 | Create a ConfigMap + Secret; consume via env vars and a mounted volume | ConfigMaps and Secrets | kind |
| 3 | `kubectl autoscale` a Deployment (HPA) + load it to trigger scaling (needs metrics-server) | Workload autoscaling | kind |
| 4 | Add liveness/readiness probes; make readiness fail and watch the pod leave Service endpoints | Self-healing primitives | kind |
| 5 | Set requests/limits; exceed memory to trigger `OOMKilled`; read it in `describe` | Pod admission (limits) | kind |
| 6 | Taint `cp`, show nginx stays Pending, add a toleration; then nodeSelector/affinity placement | Pod scheduling (taints, affinity) | kubeadm |

> Lab 6 maps directly to the self-test in
> [`notes-taints-tolerations.md`](notes-taints-tolerations.md) (Q6–Q8).

Back to [repo index](../../README.md).
