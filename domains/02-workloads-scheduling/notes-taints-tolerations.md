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

**`required` (hard) vs `preferred` (soft) — what happens when you run out of nodes?**

```
   2 nodes, 3 replicas, topologyKey: kubernetes.io/hostname

   requiredDuringScheduling...  (HARD → FILTER)
   ┌──── node1 ────┐   ┌──── node2 ────┐
   │   [web-1]     │   │   [web-2]     │     web-3 → no 3rd node to spread to
   └───────────────┘   └───────────────┘       → web-3 stays  ❌ Pending
       "must not share a node — rather not run than double up"

   preferredDuringScheduling... (SOFT → SCORE)
   ┌──── node1 ────┐   ┌──── node2 ────┐
   │ [web-1]       │   │ [web-2]       │     web-3 → doubles up on a node
   │ [web-3]  ◀────┼───┼───────────────┤       → web-3 Running  ✅ (spread not perfect)
   └───────────────┘   └───────────────┘
       "try to keep apart, but run anyway if you must"
```

- **required** = guaranteed spread, but risks `Pending` if nodes < replicas.
- **preferred** = best-effort spread, never blocks scheduling.
- Same mechanism; the strength (`required`/`preferred`) is a *choice*, not built in.

The **`preferred`** form is written differently — note it nests the selector under
`podAffinityTerm` and adds a `weight` (1–100). Easy to get wrong on the exam:

```yaml
spec:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100                      # how strongly to prefer (SCORE bias)
        podAffinityTerm:                 # the selector is nested here (unlike required)
          labelSelector:
            matchLabels: { app: web }
          topologyKey: kubernetes.io/hostname
```

> Shape difference to memorize:
> - `required` → a list of **terms directly** (`labelSelector` + `topologyKey`).
> - `preferred` → a list of **{weight, podAffinityTerm}**, with the term nested.

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

---

## 8. Self-test (Q&A)

Cover the answers and quiz yourself. These are exam-style.

**Q1. Pod is `Pending`; event says `untolerated taint {dedicated=db:NoSchedule}`.
Give two ways to get it scheduled.**
- A) Add a **toleration** to the pod matching `dedicated=db:NoSchedule`
  (change the pod — keeps the node reserved).
- B) Remove the taint from the node: `kubectl taint nodes <node> dedicated=db:NoSchedule-`
  (change the node — the trailing `-` removes).
- ⚠️ Vocabulary: taints go on **nodes**, tolerations on **pods**. You never
  "taint a pod."

**Q2. Does adding a toleration guarantee the pod lands on that tainted node?**
- **No.** A toleration is *permission* ("may enter"), not *attraction*. The
  scheduler may still pick any other eligible node. To force placement you also
  need `nodeSelector` or node affinity. (A toleration is NOT a "preference" —
  that word belongs to `preferred...` affinity.)

**Q3. `NoExecute` vs `NoSchedule` for pods ALREADY running on the node?**
- `NoSchedule` → blocks only **new** pods; running pods stay.
- `NoExecute` → also **evicts** running pods that don't tolerate it.
  Timing via `tolerationSeconds`: none → immediate; `300` → after 300s;
  tolerated with no seconds → stays forever.

**Q4. `requiredDuringScheduling...` vs `preferredDuringScheduling...` in node affinity?**
- `required` = HARD → part of **FILTER** → no match ⇒ pod stays `Pending`.
- `preferred` = SOFT → part of **SCORE** → biases ranking by `weight`, but the
  pod still schedules if nothing matches.
- Shared `IgnoredDuringExecution` = checked only at schedule time; later label
  changes don't evict a running pod (unlike a `NoExecute` taint).
- Hook: **required = Pending if unmet; preferred = just a tiebreaker.**

**Q5. Spread 3 `web` replicas one-per-node across 3 nodes — mechanism + key field?**
- `podAntiAffinity` → `requiredDuringSchedulingIgnoredDuringExecution` →
  `labelSelector` matching `app: web` → `topologyKey: kubernetes.io/hostname`
  (hostname = "same node").

### Hands-on (run on the live `cp` cluster)

**Q6. Single-node cluster won't run app pods (control-plane taint). Remove it + verify.**
```bash
kubectl taint nodes cp node-role.kubernetes.io/control-plane:NoSchedule-
kubectl describe node cp | grep -A3 Taints      # expect: Taints: <none>
```

**Q7. Taint `cp` with `env=prod:NoSchedule`, prove a plain nginx pod stays Pending.**
```bash
kubectl taint nodes cp env=prod:NoSchedule
kubectl run nginx --image=nginx
kubectl describe pod nginx | grep -A5 Events     # untolerated taint {env=prod}
kubectl delete pod nginx
kubectl taint nodes cp env=prod:NoSchedule-      # cleanup
```

**Q8. Label `cp` `disktype=ssd` and require it via nodeSelector.**
```bash
kubectl label nodes cp disktype=ssd
```
```yaml
spec:
  nodeSelector:
    disktype: ssd
  containers:
  - name: web
    image: nginx
```
Exam speed: `kubectl run web --image=nginx --dry-run=client -o yaml > web.yaml`,
then add the `nodeSelector`.

Back to [domain index](../README.md) · [repo index](../../README.md).
