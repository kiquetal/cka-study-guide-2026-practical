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

Back to [repo index](../../README.md).
