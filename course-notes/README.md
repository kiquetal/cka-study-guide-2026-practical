# Course Notes — the "capture → formalize" workflow

This folder is the **inbox**: a free-form place to dump fuzzy, half-formed notes
*fast* while reading/watching, without breaking flow. Nothing here is final.

The **domains/** folders are the **library**: clean, organized, exam-ready notes.

The rule that keeps it consistent:

> **Capture raw here → later, formalize into the matching `domains/NN-*/` note.**

---

## The flow (always the same)

```
                 ┌─────────────────────┐        promote &        ┌──────────────────────────┐
  reading/video  │ course-notes/        │       formalize         │ domains/NN-<domain>/      │
  "aha" moment ─▶│  notes.md (raw dump) │ ───────────────────────▶│  notes-<topic>.md         │
                 │  questions-for-kiro  │  (clean, diagram, lab   │  images/  labs/           │
                 └─────────────────────┘   evidence, self-test)   └──────────────────────────┘
       INBOX (fuzzy, fast, dated)                                   LIBRARY (organized, final)
```

1. **Capture (here):** jot the raw idea/command/gotcha in [`notes.md`](notes.md),
   dated. Don't stop to organize. If it's a question, drop it in
   [`questions-for-kiro.md`](questions-for-kiro.md).
2. **Promote (to a domain):** when a topic clicks, move the refined version into the
   right domain folder, following the [note template](../domains/NOTE-TEMPLATE.md)
   so every note looks the same.
3. **Prune (here):** once promoted, delete/strike the raw note so the inbox stays
   small. `course-notes/` should never grow into a second library.

## Which domain does it go to?

| Topic | Domain folder |
|-------|---------------|
| Troubleshooting, debugging broken clusters | `domains/05-troubleshooting/` |
| kubeadm, control plane, RBAC, etcd, upgrades, architecture | `domains/01-cluster-architecture/` |
| Services, Ingress, Gateway API, NetworkPolicy, CoreDNS | `domains/03-services-networking/` |
| Scheduling, taints/tolerations, workloads, HPA | `domains/02-workloads-scheduling/` |
| PV/PVC/StorageClass | `domains/04-storage/` |
| How to operate the lab (kubeconfig, libvirt, VMs) | `environment/` |
| Fast exam-day one-liners | `exam-prep/memory-muscle.md` |

Not sure? Ask me ("where does this go?") and I'll place it consistently.

## Files here

- **[`notes.md`](notes.md)** — raw running notes. Date entries, newest on top.
- **[`questions-for-kiro.md`](questions-for-kiro.md)** — queue for me to research.

## Primary resources

- **PRIMARY:** _CKA Study Guide, 2nd Edition_ (Benjamin Muschko) — 2025 overhaul edition.
- **SECONDARY:** _CKA, 4th Edition_ [Video].

> Everything formalized is findable from the top-level [`INDEX.md`](../INDEX.md).

Back to [repo index](../README.md).
