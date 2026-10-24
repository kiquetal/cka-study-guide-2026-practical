# Domain 01 — Cluster Architecture, Installation & Configuration (25%)

🎯 Source: [CNCF CKA Curriculum](https://github.com/cncf/curriculum).

## Exam objectives (official competencies)

- [ ] Manage role based access control (RBAC)
- [ ] Prepare underlying infrastructure for installing a Kubernetes cluster
- [ ] Create and manage Kubernetes clusters using kubeadm
- [ ] Manage the lifecycle of Kubernetes clusters (upgrades, etc.)
- [ ] Implement and configure a highly-available control plane
- [ ] Use Helm and Kustomize to install cluster components
- [ ] Understand extension interfaces (CNI, CSI, CRI, etc.)
- [ ] Understand CRDs, install and configure operators

> **Note (2025 overhaul):** Helm/Kustomize, extension interfaces, and
> CRDs/Operators were added/emphasized in the 2025 curriculum. etcd
> backup/restore remains a high-value exam task under cluster lifecycle.

## Study material here

- 📖 [`notes-cluster-architecture.md`](notes-cluster-architecture.md) — control-plane
  components, kubeadm lifecycle, RBAC, etcd backup/restore, upgrade workflow,
  kubeconfig/contexts.
- 🧪 [`labs/00-first-cluster-bringup.md`](labs/00-first-cluster-bringup.md) — stand up
  the control plane by hand (kubeadm init → kubeconfig → CNI → Ready).
- 🧪 Planned labs: RBAC, etcd backup & restore, `kubeadm upgrade`, Helm/Kustomize,
  a CRD + operator install.

Back to [repo index](../../README.md).
