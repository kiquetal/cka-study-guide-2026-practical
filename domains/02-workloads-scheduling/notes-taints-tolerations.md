# Scheduling Constraints — Taints, Tolerations, Affinity (first principles)

🎯 **Exam scope:** Workloads & Scheduling (15%), and a very common clue in
Troubleshooting (30%) when a pod is stuck `Pending`.

> **Seen live:** during [Lab 00 — first cluster bring-up](../../01-cluster-architecture/labs/00-first-cluster-bringup.md),
> CoreDNS stayed `Pending` right after installing the CNI. The event said:
> `FailedScheduling ... 1 node(s) had untolerated taint {node.kubernetes.io/not-ready}`.
> Once Calico made the node `Ready`, the taint was removed and CoreDNS scheduled
> instantly. This whole document is that one observation, generalized.

---

## 0. First principles: what is "scheduling"?

A Pod is just a request: *"run these containers somewhere."* It has no node until
the **scheduler** (`kube-scheduler`) picks one. The scheduler runs a loop:

```
   ┌─────────────────────────────────────────────────────────────┐
   │  for each Pending pod:                                        │
   │                                                               │
   │   1. FILTER   ── which nodes are even allowed?  (hard rules)  │
   │                  drop nodes that fail: resources, taints,     │
   │                  nodeSelector, required affinity, ...         │
   │                                                               │
   │   2. SCORE    ── of the survivors, which is best? (soft rules)│
   │                  rank by: preferred affinity, spread, ...     │
   │                                                               │
   │   3. BIND     ── assign the pod to the winning node           │
   └─────────────────────────────────────────────────────────────┘

   No node survives FILTER  →  pod stays Pending  →  FailedScheduling event
```

Every mechanism below is just a way of influencing **FILTER** (hard / yes-no) or
**SCORE** (soft / preference). Keep that split in your head — it's the whole topic.

| Mechanism | Lives on | Direction | Filter or Score |
|-----------|----------|-----------|-----------------|
| Taint / Toleration | node / pod | **repel** (opt-out) | Filter (NoSchedule) or evict (NoExecute) |
| nodeSelector | pod | **attract** (opt-in) | Filter (hard) |
| Node affinity `required` | pod | attract | Filter (hard) |
| Node affinity `preferred` | pod | attract | Score (soft) |
| Pod (anti)affinity | pod | attract/repel vs *other pods* | Filter or Score |

---

## 1. Taints & tolerations — the "keep out" sign

**Mental model:**

```
        NODE                                   POD
   ┌───────────────┐                     ┌───────────────┐
   │  TAINT         │   "keep out"        │  TOLERATION    │  "I have a pass"
   │  gpu=true      │ ◀───── repels ───── │  tolerates     │
   │  :NoSchedule   │                     │  gpu=true      │
   └───────────────┘                     └───────────────┘

   No matching toleration → node is filtered out → pod can't land here.
   Matching toleration    → the taint is ignored → pod MAY land here.
```

> ⚠️ A toleration only *permits* — it does **not** *attract*. "I'm allowed in"
> is not "please put me here." Attraction is affinity's job (section 3).

**Anatomy of a taint:** `key=value:effect`

| Effect | Meaning |
|--------|---------|
| `NoSchedule` | Don't schedule new pods here (existing pods stay). |
| `PreferNoSchedule` | Soft — try to avoid, but allowed if nowhere else fits. |
| `NoExecute` | Don't schedule here **and evict** running pods that don't tolerate it. |

**`NoExecute` eviction timeline:**

```
   node gets taint :NoExecute
        │
        ├─ pod with NO toleration        → evicted immediately
        ├─ pod tolerates, no tolerationSeconds → stays forever
        └─ pod tolerates, tolerationSeconds: 300 → evicted after 300s
```

**Auto-taints Kubernetes adds** (this is why troubleshooting cares):

```
   node NotReady  ─────────▶  node.kubernetes.io/not-ready:NoSchedule
   node unreachable ───────▶  node.kubernetes.io/unreachable:NoExecute
   disk/mem/pid pressure ──▶  node.kubernetes.io/<x>-pressure:NoSchedule
   kubeadm control-plane ──▶  node-role.kubernetes.io/control-plane:NoSchedule
```

The CoreDNS-Pending you saw was the first line: NotReady node → auto not-ready
taint → scheduler filtered the only node → Pending. CNI → Ready → taint gone →
scheduled.

**Commands:**
```bash
# see a node's taints
kubectl describe node cp | grep -A3 Taints
kubectl get node cp -o jsonpath='{.spec.taints}'; echo

# add / remove a taint (trailing '-' removes)
kubectl taint nodes cp gpu=true:NoSchedule
kubectl taint nodes cp gpu=true:NoSchedule-

# single-node lab: let normal pods run on the control plane
kubectl taint nodes cp node-role.kubernetes.io/control-plane:NoSchedule-
```

**Toleration in a pod spec:**
```yaml
spec:
  tolerations:
  - key: "gpu"
    operator: "Equal"      # Equal = key+value must match; Exists = key only
    value: "true"
    effect: "NoSchedule"
```
Tolerate *any* taint with a key (operator `Exists`, no value):
```yaml
  tolerations:
  - key: "node.kubernetes.io/not-ready"
    operator: "Exists"
    effect: "NoSchedule"
```

---

## 2. nodeSelector — the simplest "put me here"

The opt-in opposite of a taint. The pod names labels the node **must** have.
Pure FILTER, hard, no soft option.

```
   POD wants:  disktype=ssd
                     │  matches labels?
      ┌──────────────┼───────────────────────────┐
      ▼              ▼                            ▼
  ┌────────┐    ┌────────┐                  ┌────────┐
  │ node A │    │ node B │                  │ node C │
  │ ssd ✔  │    │ hdd ✘  │                  │ ssd ✔  │
  └────────┘    └────────┘                  └────────┘
   eligible      filtered out                eligible
```

```bash
kubectl label nodes cp disktype=ssd      # label the node
```
```yaml
spec:
  nodeSelector:
    disktype: ssd
```

---

## 3. Node affinity — nodeSelector with grammar (hard AND soft)

Same idea as nodeSelector (attract a pod to nodes by label) but expressive:
operators (`In`, `NotIn`, `Exists`, `Gt`, `Lt`) and two strengths.

```
   requiredDuringScheduling...     → HARD  (FILTER)  = must match or Pending
   preferredDuringScheduling...    → SOFT  (SCORE)   = ranked higher, not required
```

```yaml
spec:
  affinity:
    nodeAffinity:
      # HARD rule: only nodes in these zones are eligible
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: topology.kubernetes.io/zone
            operator: In
            values: ["us-east-1a", "us-east-1b"]
      # SOFT rule: among those, prefer ssd (weight biases the SCORE step)
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 50
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values: ["ssd"]
```

> `IgnoredDuringExecution` = the rule is checked **only at scheduling time**. If
> the node's labels change later, a running pod is **not** evicted. (Contrast with
> a `NoExecute` taint, which *does* evict.)

---

## 4. Pod affinity / anti-affinity — place relative to OTHER pods

Not about node labels — about *which pods are already on a node*. Uses a
`topologyKey` (a node label like hostname or zone) to define "together."

```
   POD AFFINITY: "put me WITH pods like X"
   ┌──────── node1 ────────┐   ┌──── node2 ────┐
   │  [cache]  ◀── [web]   │   │               │   web wants to sit with cache
   └───────────────────────┘   └───────────────┘

   POD ANTI-AFFINITY: "keep me AWAY from pods like me" (spread replicas)
   ┌──── node1 ────┐   ┌──── node2 ────┐   ┌──── node3 ────┐
   │   [web-1]     │   │   [web-2]     │   │   [web-3]     │
   └───────────────┘   └───────────────┘   └───────────────┘
      one replica per node = resilient to a node dying
```

```yaml
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels: { app: web }
        topologyKey: kubernetes.io/hostname   # "same node" = same hostname
```

---

## 5. Putting it together — the classic GPU example

Taints and affinity solve **opposite directions** and are often used **together**:

```
   Goal: GPU jobs run ONLY on GPU nodes, and nothing else lands there.

   ① TAINT the GPU node        → repels everything by default (keep others off)
        kubectl taint nodes gpu-1 gpu=true:NoSchedule

   ② GPU pod TOLERATES it      → allowed in (removes the "keep out")
        tolerations: [{key: gpu, operator: Exists, effect: NoSchedule}]

   ③ GPU pod has node AFFINITY → actively pulled onto gpu-labelled nodes
        nodeAffinity required: hardware In [gpu]

   Toleration alone = "may enter."  Affinity = "must go here."  Need both.
```

```
            repel (taint)                 attract (affinity / nodeSelector)
   node ───────────────────▶ pod        pod ───────────────────▶ node
   "stay off unless you                 "I want to be on nodes
    hold a pass"                          matching these labels"
```

---

## 6. Troubleshooting flow (exam-speed)

Pod stuck `Pending`? Always start with the events:
```bash
kubectl describe pod <pod> -n <ns> | grep -A15 Events
```

Decode the message:

```
 "had untolerated taint {X}"        → node repels it. Tolerate it, or untaint node.
                                       If taint is node.kubernetes.io/not-ready →
                                       fix the NODE (CNI/kubelet); taint auto-clears.
 "didn't match Pod's node affinity  → no node has the required labels. Fix labels
  /selector"                           or relax the affinity/nodeSelector.
 "Insufficient cpu/memory"          → not a constraint bug; no node has room.
 "node(s) had volume node affinity  → PV is pinned to a zone the pod can't reach.
  conflict"
```

Then inspect the node side:
```bash
kubectl describe node <node> | grep -A3 Taints
kubectl get node <node> --show-labels
```

---

## 7. One-screen summary

```
 TAINT/TOLERATION   node repels; pod needs a pass.      effect: NoSchedule|PreferNoSchedule|NoExecute
 nodeSelector       pod → node by label. hard only.
 nodeAffinity       pod → node by label. required(hard)+preferred(soft). rich operators.
 podAffinity        pod → node that has (or lacks) certain OTHER pods, via topologyKey.
 ──────────────────────────────────────────────────────────────────────────────────────
 repel  = taints (opt-out)          |   attract = selector / affinity (opt-in)
 hard   = FILTER → Pending if unmet  |   soft    = SCORE  → just a preference
```

Back to [domain index](../README.md) · [repo index](../../README.md).
