# Services & Networking — study notes (first principles)

🎯 **Exam scope:** Services & Networking — **20%**. The 2025 overhaul adds
emphasis on the **Gateway API** (newer than Ingress). Also: Service types,
NetworkPolicy, and CoreDNS.

> App-layer networking is fine to practice on [`kind`](../../environment/kind/)
> (fast); cluster-level DNS/CNI realism on the kubeadm VMs.

---

## 0. First principles: why Services exist

Pods are mortal — they get new IPs on every restart. You can't point clients at a
pod IP. A **Service** is a *stable name + virtual IP* in front of a set of pods,
selected by labels. kube-proxy programs the dataplane (iptables/ipvs) to load
balance to the current pod IPs.

```
   client ──▶ Service (stable ClusterIP) ──▶ Endpoints ──▶ Pod IPs (ephemeral)
                         │                        ▲
                     selector: app=web ───────────┘
                     (pods whose labels match become endpoints)
```

> 🎯 **#1 networking bug on the exam:** Service has **no Endpoints** because its
> `selector` doesn't match the pods' labels. Always check `kubectl get endpoints`.

---

## 1. Service types

```
   ClusterIP   (default) → reachable only INSIDE the cluster
   NodePort              → opens a port on EVERY node (30000-32767) → ClusterIP
   LoadBalancer          → cloud LB → NodePort → ClusterIP (needs cloud/MetalLB)
   ExternalName          → CNAME to an external DNS name (no proxying)

   LoadBalancer ⊃ NodePort ⊃ ClusterIP   (each builds on the previous)
```

Imperative creation (exam speed):
```bash
kubectl expose deployment web --port=80 --target-port=8080            # ClusterIP
kubectl expose deployment web --port=80 --type=NodePort               # NodePort
kubectl create service clusterip web --tcp=80:8080                    # alt form
```

---

## 2. Ingress vs Gateway API

Both do **L7 (HTTP) routing** from outside into Services. Gateway API is the
newer, more expressive successor (role-oriented, extensible).

```
   INGRESS (older)
   client ─▶ Ingress Controller ─▶ Ingress rules ─▶ Service ─▶ Pods
             (nginx/traefik)        host/path → svc

   GATEWAY API (2025 emphasis)
   client ─▶ GatewayClass ─▶ Gateway ─▶ HTTPRoute ─▶ Service ─▶ Pods
             (who implements) (listener) (routing rules)
```

**Gateway API objects (know the split of responsibilities):**

| Object | Who owns it | Role |
|--------|-------------|------|
| `GatewayClass` | infra provider | which controller implements gateways |
| `Gateway` | cluster operator | listeners (ports/protocols/hostnames) |
| `HTTPRoute` | app developer | host/path → backend Service rules |

Minimal HTTPRoute:
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
  - name: my-gateway          # the Gateway this route attaches to
  rules:
  - matches:
    - path: { type: PathPrefix, value: /app }
    backendRefs:
    - name: web               # target Service
      port: 80
```

> Why it replaced Ingress on the exam radar: Ingress crammed everything into one
> object + annotations. Gateway API splits infra/operator/developer concerns into
> separate resources, and is extensible (TCPRoute, GRPCRoute, etc.).

---

## 3. NetworkPolicy — firewall for pods

By default, **all pods can talk to all pods**. A NetworkPolicy restricts that.
Policies are *additive allow-lists*: once any policy selects a pod, everything not
explicitly allowed is denied (for the selected direction).

```
   No policy          → all ingress + egress allowed (default-allow)
   Policy selects pod → only explicitly-allowed traffic; rest DENIED
```

Default-deny all ingress in a namespace:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: dev
spec:
  podSelector: {}            # all pods in ns
  policyTypes: ["Ingress"]   # no ingress rules = deny all ingress
```

Allow ingress to `app=web` only from `app=api`:
```yaml
spec:
  podSelector:
    matchLabels: { app: web }
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels: { app: api }
```

> ⚠️ NetworkPolicy needs a CNI that enforces it (Calico does; some don't). On a
> non-enforcing CNI the policy is accepted but does nothing.

---

## 4. CoreDNS — in-cluster DNS

Every Service gets a DNS name. Pods resolve names via CoreDNS (runs in
`kube-system`).

```
   <service>.<namespace>.svc.cluster.local   → Service ClusterIP

   web.dev.svc.cluster.local
   └service └ns  └fixed suffix
```
```bash
# test DNS from a throwaway pod:
kubectl run t --image=busybox --rm -it --restart=Never -- nslookup web.dev
kubectl get pods -n kube-system -l k8s-app=kube-dns    # CoreDNS healthy?
```
CoreDNS down → every in-cluster name fails. Classic cascading symptom.

---

## 5. Exam-speed checklist

```
 expose a deployment       → kubectl expose deploy web --port=80 [--type=NodePort]
 service has no endpoints  → selector vs pod labels (kubectl get endpoints)
 external HTTP routing     → Ingress OR Gateway API (GatewayClass→Gateway→HTTPRoute)
 restrict pod traffic      → NetworkPolicy (needs enforcing CNI like Calico)
 DNS name of a service     → <svc>.<ns>.svc.cluster.local
 DNS broken                → check CoreDNS pods in kube-system
```

Back to [domain index](README.md) · [repo index](../../README.md).
