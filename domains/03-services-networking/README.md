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

Back to [repo index](../../README.md).
