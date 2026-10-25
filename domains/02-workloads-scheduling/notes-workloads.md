# Workloads — study notes (first principles)

🎯 **Exam scope:** Workloads & Scheduling — **15%**. This file covers the
*workloads* half (Deployments, scaling, rollouts, ConfigMaps/Secrets, resource
requests/limits). The *scheduling* half (taints, affinity) is in
[`notes-taints-tolerations.md`](notes-taints-tolerations.md).

> Fast iteration on [`kind`](../../environment/kind/). Lean hard on imperative
> commands + `--dry-run=client -o yaml` for exam speed.

---

## 0. First principles: the controller hierarchy

```
   Deployment ──manages──▶ ReplicaSet ──manages──▶ Pods
      │                       │                      │
      "desired state:         "keep N identical      "the actual
       image + replicas +      pods alive"            running containers"
       rollout strategy"

   You almost never create Pods or ReplicaSets directly.
   You declare a Deployment; controllers reconcile reality to match.
```

- **Pod** — one or more containers, the smallest unit. Mortal.
- **ReplicaSet** — keeps a fixed number of identical pods running.
- **Deployment** — manages ReplicaSets to give you rolling updates + rollback.

---

## 1. Create & scale (imperative = exam speed)

```bash
# create a deployment
kubectl create deployment web --image=nginx --replicas=3

# scale
kubectl scale deployment web --replicas=5

# generate YAML without creating (then edit + apply)
kubectl create deployment web --image=nginx --dry-run=client -o yaml > web.yaml
kubectl apply -f web.yaml

# autoscale (HPA, needs metrics-server)
kubectl autoscale deployment web --min=2 --max=10 --cpu-percent=80
```

> 🆕 **HPA scale-to-zero (know this for v1.37 exam).** The `HPAScaleToZero`
> feature gate became **on by default in v1.36** (Apr 2026), and in **v1.37**
> ("Garhwal", Sep 2026) scale-to-zero is **Beta, enabled by default**. An HPA that
> uses an **object or external metric** can now scale a workload down to
> `minReplicas: 0` and bring it back when the metric fires — native, no KEDA/Knative.
> Caveat: CPU/memory (resource) metrics alone can't drive to zero; you need an
> object/external metric. Since the current curriculum is **v1.37**, this is
> fair game under "Configure workload autoscaling."

> 🎯 Set up these shortcuts first thing on the exam:
> ```bash
> alias k=kubectl
> export do="--dry-run=client -o yaml"   # k create deploy web --image=nginx $do
> ```

---

## 2. Rolling updates & rollback

```
   Deployment update (e.g. new image) → new ReplicaSet created
   ┌─────────────────────────────────────────────────────────┐
   │  old RS: ███ ███ ███   (3 pods v1)                        │
   │  new RS:               → scales up as old scales down     │
   │  old RS: ███ ███       new RS: ░░░                         │
   │  old RS: ███           new RS: ░░░ ░░░                     │
   │  old RS:               new RS: ░░░ ░░░ ░░░ (3 pods v2)     │
   └─────────────────────────────────────────────────────────┘
   RollingUpdate (default): zero downtime, controlled by maxSurge/maxUnavailable
```

```bash
kubectl set image deployment/web nginx=nginx:1.26   # trigger a rollout
kubectl rollout status deployment/web               # watch it
kubectl rollout history deployment/web              # list revisions
kubectl rollout undo deployment/web                 # roll back to previous
kubectl rollout undo deployment/web --to-revision=2 # roll back to a specific one
kubectl rollout restart deployment/web              # restart pods (re-pull, re-read config)
```

---

## 3. ConfigMaps & Secrets — externalize config

```
   ConfigMap  = non-secret key/value config (plain text)
   Secret     = sensitive data (base64-encoded, not encrypted by default)

   Both can be consumed by a pod as:
     - environment variables
     - mounted files (volume)
```

```bash
# create
kubectl create configmap app-config --from-literal=LOG_LEVEL=debug
kubectl create configmap app-config --from-file=./config.properties
kubectl create secret generic db-cred --from-literal=password=s3cret
```

Consume in a pod:
```yaml
spec:
  containers:
  - name: app
    image: myapp
    envFrom:
    - configMapRef: { name: app-config }    # all keys as env vars
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef: { name: db-cred, key: password }
    volumeMounts:
    - name: cfg
      mountPath: /etc/config                 # keys become files here
  volumes:
  - name: cfg
    configMap: { name: app-config }
```

> ⚠️ Secrets are only **base64-encoded**, not encrypted at rest unless you enable
> encryption at the apiserver. `echo <val> | base64 -d` reveals them.

---

## 4. Resource requests & limits

```
   requests = what the scheduler reserves (guaranteed floor; used for FILTER)
   limits   = hard ceiling the container can't exceed

   CPU over limit   → throttled (slowed)
   Memory over limit → OOMKilled (container killed, restarted)
```

```yaml
spec:
  containers:
  - name: app
    image: myapp
    resources:
      requests: { cpu: "250m", memory: "64Mi" }   # scheduler reserves this
      limits:   { cpu: "500m", memory: "128Mi" }  # ceiling
```

- No `requests` → scheduler assumes 0 → can overcommit a node.
- `Insufficient cpu/memory` Pending event = sum of requests exceeds node capacity.

---

## 5. Probes (health checks)

```
   livenessProbe   → fails → kubelet RESTARTS the container
   readinessProbe  → fails → pod removed from Service endpoints (no traffic)
   startupProbe    → protects slow-starting apps from liveness during boot
```

```yaml
    livenessProbe:
      httpGet: { path: /healthz, port: 8080 }
      initialDelaySeconds: 5
      periodSeconds: 10
    readinessProbe:
      httpGet: { path: /ready, port: 8080 }
```

A pod stuck `Running 0/1` is almost always a failing **readiness** probe.

---

## 6. Exam-speed checklist

```
 create deployment     → kubectl create deploy web --image=nginx --replicas=3
 scale                 → kubectl scale deploy web --replicas=5
 update image          → kubectl set image deploy/web nginx=nginx:1.26
 watch / rollback      → kubectl rollout status|undo deployment/web
 config/secret         → kubectl create configmap|secret ... ; consume via env/volume
 resources             → requests (scheduler reserves) vs limits (ceiling; mem→OOMKill)
 pod Running 0/1       → failing readiness probe
 generate YAML fast    → <cmd> --dry-run=client -o yaml > file.yaml
```

---

## 7. What's new in v1.37 ("Garhwal") — Workloads & Scheduling

The exam tracks v1.37, so these are fair game. Status in parentheses.

- **HPA scale-to-zero (Beta, default on)** — `minReplicas: 0` with an **object or
  external** metric (not CPU/mem). Sets a `ScaledToZero` condition. Covered in §1.
- **Configurable HPA tolerance (GA)** — set per-HPA, per-direction tolerance under
  `behavior.scaleUp/scaleDown.tolerance` (a ratio, e.g. `0.05` = react at target×1.05),
  replacing the old global 10%.
  ```yaml
  spec:
    behavior:
      scaleUp:
        tolerance: 0.05
  ```
- **In-place resize of init & sidecar containers (GA)** — change a running
  container's CPU/mem `requests`/`limits` without recreating the Pod. Per-resource
  `resizePolicy`: `NotRequired` (live) or `RestartContainer` (restart just that one).
  App-container resize has been GA since v1.35; v1.37 extends it to sidecars/init.
- **Pod-level resources & managers (resources GA since v1.34; managers Beta, OFF by
  default in v1.37)** — set `spec.resources` for the whole Pod, not just per container.
- **Memory QoS (Beta)** — kubelet uses cgroup v2 `memory.min`/`memory.high` to throttle
  before OOM; needs `memoryThrottlingFactor` in kubelet config. (See also Troubleshooting.)
- **Node declared features (GA)** — nodes publish `status.declaredFeatures`; scheduler
  only places feature-using Pods on nodes that support them (matters during upgrades).
- **Gang scheduling via Workload API (Beta, `scheduling.k8s.io/v1beta1`)** — all-or-
  nothing scheduling for tightly-coupled jobs (`Workload` → `PodGroup` → Pods,
  `minCount`). Gate `GenericWorkload`. Niche/batch — know it exists.

Back to [domain index](README.md) · [repo index](../../README.md).
