# Domain 03 — Services & Networking (20%)

🎯 Source: [CNCF CKA Curriculum](https://github.com/cncf/curriculum).

## Exam objectives (official competencies)

- [ ] Understand connectivity between Pods
- [ ] Define and enforce Network Policies
- [ ] Use ClusterIP, NodePort, LoadBalancer service types and endpoints
- [ ] Use the Gateway API to manage Ingress traffic
- [ ] Know how to use Ingress controllers and Ingress resources
- [ ] Understand and use CoreDNS

> **Note (2025 overhaul):** the **Gateway API** is now an explicit competency
> alongside Ingress. Know the `GatewayClass → Gateway → HTTPRoute` split.

## Study material here

- 📖 [`notes-services-networking.md`](notes-services-networking.md) — why Services
  exist, Service types, Ingress vs Gateway API, NetworkPolicy, CoreDNS.
- 🧪 Planned labs (on [`../../environment/kind/`](../../environment/kind/) or the
  kubeadm cluster): Service types, endpoints debugging, Ingress vs Gateway API,
  NetworkPolicy allow/deny, CoreDNS resolution.

## Recommended labs

Mostly fast on **kind**; CoreDNS/CNI realism on the kubeadm cluster.

| # | Lab | Objective practiced | Environment |
|---|-----|---------------------|-------------|
| 1 | Expose a Deployment as ClusterIP, then NodePort; curl it; inspect `endpoints` | Service types and endpoints | kind |
| 2 | Break a Service by mislabeling its selector; find the empty `endpoints` and fix | Connectivity between Pods | kind |
| 3 | Install an Ingress controller; route `/app` to a Service via an Ingress resource | Ingress controllers/resources | kind |
| 4 | Install Gateway API CRDs; create `GatewayClass → Gateway → HTTPRoute` to a Service | Use the Gateway API | kind |
| 5 | Default-deny ingress in a namespace, then allow only `app=api → app=web` | Define/enforce Network Policies | kind (Calico) |
| 6 | From a throwaway pod, resolve `<svc>.<ns>.svc.cluster.local`; break/restore CoreDNS | Understand and use CoreDNS | kind or kubeadm |

> NetworkPolicy labs need an **enforcing CNI** (Calico). kind's default CNI does
> not enforce policies — use the kubeadm cluster or a Calico-enabled kind config.

Back to [repo index](../../README.md).
