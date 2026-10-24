# Istio Ambient Mesh — Beyond Exam / Real-World

> **Status:** Placeholder. Content will be added incrementally through Q&A.
> **Scope:** This is **BEYOND the CKA exam**. It is here to build real-world
> engineering depth, not to pass the test. Nothing in this folder is exam-required.

## Why this exists

A CKA proves you can administer a cluster. A real platform engineer also understands
the service mesh layer. Istio's **Ambient mode** is the modern, sidecar-less mesh
approach and is worth knowing in production.

## Prerequisites

- A working lightweight cluster: [`../../environment/kind/`](../../environment/kind/).
- Comfort with core networking (see [`../../domains/03-services-networking/`](../../domains/03-services-networking/)).

## Planned outline (to be filled in via Q&A)

- [ ] Ambient mode vs. sidecar mode — what changed and why.
- [ ] **ztunnel** — the per-node L4 proxy (mTLS, identity).
- [ ] **Waypoint proxies** — opt-in L7 processing.
- [ ] mTLS / zero-trust identity model.
- [ ] Installing Istio Ambient on the kind cluster.
- [ ] Observability (metrics, traffic visualization).

Add questions for Kiro to research in
[`../../course-notes/questions-for-kiro.md`](../../course-notes/questions-for-kiro.md).

Back to [repo index](../../README.md).
