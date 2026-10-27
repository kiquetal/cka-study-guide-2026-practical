# Running Notes

> Free-form. Write whatever helps. Date your entries. Newest at the top is fine.

---

## 2026-10-27 — Rumble notes

- kubelet =  per-node agent that takes pod specs from the API server and makes the container runtime actually run them, and reports node/pod health back

- scheduler = watches for Pods with no node assigned and decides WHICH node each runs on (resources, taints/tolerations, affinity). It only assigns — the kubelet actually runs it.

- controller-manager = runs control loops that watch desired vs actual state and reconcile them. e.g. Deployment wants 3 pods, only 2 exist -> it creates the 3rd; a node dies -> it replaces its pods. (reconciliation loop = core k8s idea). If it's down, dead pods don't get recreated.

> handoff when you run `kubectl apply -f deploy.yaml` (a Deployment with replicas: 3):
> 1. kubectl -> API server: "create this Deployment" (API server validates + writes it to etcd)
> 2. controller-manager sees "Deployment wants 3 pods, 0 exist" -> creates 3 Pod objects (still unscheduled)
> 3. scheduler sees 3 Pods with no node -> assigns each to a node (writes nodeName back via API server)
> 4. each target node's kubelet sees "a Pod is assigned to me" -> tells containerd to pull image + run it
> (everything flows THROUGH the API server; etcd is the source of truth)
