# Domain 04 — Storage (10%)

🎯 Source: [CNCF CKA Curriculum](https://github.com/cncf/curriculum).

## Exam objectives (official competencies)

- [ ] Implement storage classes and dynamic volume provisioning
- [ ] Configure volume types, access modes, and reclaim policies
- [ ] Manage persistent volumes and persistent volume claims

## Study material here

- 📖 [`notes-storage.md`](notes-storage.md) — the PV/PVC supply-and-demand split,
  static vs dynamic provisioning, access modes, reclaim policies, mounting a PVC
  in a Pod, StorageClasses, and storage troubleshooting.
- 🧪 Planned labs (on [`../../environment/kind/`](../../environment/kind/) —
  ships the `local-path` provisioner): static PV/PVC binding, dynamic provisioning
  via StorageClass, mount a volume and write/read data.

## Recommended labs

Fast on **kind** (ships a `local-path` dynamic provisioner).

| # | Lab | Objective practiced | Environment |
|---|-----|---------------------|-------------|
| 1 | Create a `hostPath` PV + a matching PVC; watch it go `Bound`; mount it in a Pod | Manage PV/PVC (static) | kind |
| 2 | Write a PVC with no `storageClassName`; confirm the default class dynamically provisions a PV | Dynamic provisioning | kind |
| 3 | Create two StorageClasses (`Retain` vs `Delete`); delete the PVCs; observe what happens to each PV | Reclaim policies | kind |
| 4 | Request `ReadWriteOnce` vs `ReadWriteMany`; see which binds and why | Access modes | kind |
| 5 | Mount a PVC in a Pod, write a file, delete+recreate the Pod, confirm data persists | PV/PVC + volume types | kind |

Back to [repo index](../../README.md).
