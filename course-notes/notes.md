# Running Notes

> Free-form. Write whatever helps. Date your entries. Newest at the top is fine.

---

## 2026-10-27 — Rumble notes

- kubelet =  per-node agent that takes pod specs from the API server and makes the container runtime actually run them, and reports node/pod health back

- scheduler = watches for Pods with no node assigned and decides WHICH node each runs on (resources, taints/tolerations, affinity). It only assigns — the kubelet actually runs it.

- controller-manager = runs control loops that watch desired vs actual state and reconcile them. e.g. Deployment wants 3 pods, only 2 exist -> it creates the 3rd; a node dies -> it replaces its pods. (reconciliation loop = core k8s idea). If it's down, dead pods don't get recreated.

> handoff for `kubectl apply` (3 replicas):
> controller-manager (create 3 Pod objects) -> scheduler (assign each to a node) -> kubelet (tell containerd to run them)
