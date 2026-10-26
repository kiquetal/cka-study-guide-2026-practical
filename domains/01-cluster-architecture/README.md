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
- 🧪 [`labs/configuring-worker2.md`](labs/configuring-worker2.md) — configure a bare
  Ubuntu worker node by hand (swap, kernel modules, sysctls, containerd, kube
  packages) and join it with `kubeadm join`. The exam/real-world node-prep skill.
- 🧪 Planned labs: RBAC, etcd backup & restore, `kubeadm upgrade`, Helm/Kustomize,
  a CRD + operator install.

## Recommended labs

Run on the **kubeadm VM cluster** (real control plane, certs, static pods).

| # | Lab | Objective practiced | Environment |
|---|-----|---------------------|-------------|
| 1 | Bring up the control plane by hand (`kubeadm init` → kubeconfig → CNI → Ready) | Create clusters using kubeadm | kubeadm |
| 2 | Join `worker1` with `kubeadm join`; regenerate a token when it expires | Create/manage clusters | kubeadm |
| 3 | `etcdctl snapshot save` then `snapshot restore` to a new data dir; repoint `etcd.yaml` | Manage cluster lifecycle | kubeadm |
| 4 | Create a `Role`/`RoleBinding` for a user in one namespace; verify with `kubectl auth can-i --as=` | Manage RBAC | kind or kubeadm |
| 5 | `kubeadm upgrade` one minor version: control plane first, then drain/upgrade a worker | Manage cluster lifecycle (upgrades) | kubeadm |
| 6 | Install a component with Helm and render/patch with Kustomize | Use Helm and Kustomize | kind |
| 7 | Define a CRD + install a simple operator; create a custom resource | Understand CRDs / operators | kind |

Back to [repo index](../../README.md).
