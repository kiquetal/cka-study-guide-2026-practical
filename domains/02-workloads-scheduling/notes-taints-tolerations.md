# Taints & Tolerations — notes

🎯 **Exam scope:** Workloads & Scheduling (15%), and a very common clue in
Troubleshooting (30%) when a pod is stuck `Pending`.

> **Seen live:** during [Lab 00 — first cluster bring-up](../../01-cluster-architecture/labs/00-first-cluster-bringup.md),
> CoreDNS stayed `Pending` right after installing the CNI. The event said:
> `FailedScheduling ... 1 node(s) had untolerated taint {node.kubernetes.io/not-ready}`.
> Once Calico made the node `Ready`, the taint was removed and CoreDNS scheduled
> instantly. That is this whole concept in one observation.

---

## The one-line mental model

- A **taint** is on a **node**. It *repels* pods.
- A **toleration** is on a **pod**. It lets that pod *ignore* a matching taint.
- No matching toleration → the scheduler will **not** place the pod there → `Pending`.

Think: taint = "keep out" sign on the node; toleration = "I'm allowed in" pass on
the pod.

---

## Anatomy of a taint

```
key=value:effect
```

- **key/value** — arbitrary label, e.g. `node.kubernetes.io/not-ready` (value empty).
- **effect** — what happens to pods that don't tolerate it:
  | Effect | Meaning |
  |--------|---------|
  | `NoSchedule` | Don't schedule new pods here (existing pods stay). |
  | `PreferNoSchedule` | Try to avoid scheduling here (soft). |
  | `NoExecute` | Don't schedule here **and evict** running pods that don't tolerate it. |

---

## Taints Kubernetes adds automatically (why this matters for troubleshooting)

The control plane auto-taints nodes based on condition. The one we hit:

- `node.kubernetes.io/not-ready:NoSchedule` — on a node that is **NotReady**
  (e.g. no CNI yet). This is exactly why CoreDNS wouldn't schedule.
- `node.kubernetes.io/unreachable` — node lost contact.
- `node.kubernetes.io/disk-pressure`, `memory-pressure`, `pid-pressure` — resource issues.

Also common: the **control-plane taint** kubeadm puts on the control-plane node so
normal workloads don't land there:

```
node-role.kubernetes.io/control-plane:NoSchedule
```

(That's why in a single-node lab you may need to *remove* that taint to run app
pods on `cp` — see commands below.)

---

## Commands you'll actually type

**See a node's taints:**
```bash
kubectl describe node cp | grep -A3 Taints
# or:
kubectl get node cp -o jsonpath='{.spec.taints}'; echo
```

**Add a taint to a node:**
```bash
kubectl taint nodes cp gpu=true:NoSchedule
```

**Remove a taint** (note the trailing `-`):
```bash
kubectl taint nodes cp gpu=true:NoSchedule-
```

**Let app pods run on a single-node (control-plane) cluster** — remove the
control-plane taint:
```bash
kubectl taint nodes cp node-role.kubernetes.io/control-plane:NoSchedule-
```

**Add a toleration to a pod** (in the pod spec):
```yaml
spec:
  tolerations:
  - key: "gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
```

Tolerate *any* taint with a given key (operator `Exists`, no value):
```yaml
  tolerations:
  - key: "node.kubernetes.io/not-ready"
    operator: "Exists"
    effect: "NoSchedule"
```

---

## Troubleshooting flow (exam-speed)

Pod stuck `Pending`?
```bash
kubectl describe pod <pod> -n <ns> | grep -A10 Events
```
If you see `had untolerated taint {...}`:
1. `kubectl describe node <node> | grep -A3 Taints` — what's the taint?
2. Is the node `NotReady`? → fix the node (CNI, kubelet) and the auto-taint clears itself.
3. Is it an intentional taint? → add a matching **toleration** to the pod, or remove
   the taint from the node.

---

## Taints vs nodeSelector / affinity (don't confuse them)

- **Taints/tolerations** = node *repels* pods (opt-out). Keeps pods *off* unless allowed.
- **nodeSelector / node affinity** = pod *attracts* to nodes (opt-in). Pulls pods *onto*
  matching nodes.
- They solve opposite directions and are often used together (taint a GPU node **and**
  affinity-target it).

Back to [domain index](../README.md) · [repo index](../../README.md).
