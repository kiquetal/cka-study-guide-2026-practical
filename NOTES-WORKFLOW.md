# NOTES-WORKFLOW — the one rule for how notes are written in this repo

This is the **single source of truth** for how study notes are captured, moved,
and formalized. The goal is **consistency**: every note is produced the same way,
so studying is predictable and nothing gets lost. Kiro follows these rules; you
can too.

---

## 1. Two places, two jobs

```
  ┌───────────────────────────┐              ┌────────────────────────────────┐
  │        course-notes/        │   promote    │          domains/NN-*/          │
  │          = INBOX            │ ───────────▶ │           = LIBRARY             │
  │                             │  & formalize │                                 │
  │  raw · fuzzy · fast · dated │              │  clean · final · exam-ready     │
  │  notes.md                   │              │  notes-<topic>.md               │
  │  questions-for-kiro.md      │              │  images/   labs/                │
  └───────────────────────────┘              └────────────────────────────────┘
        write without stopping                   organized with the template
```

- **`course-notes/` = INBOX.** Dump half-formed thoughts *fast* while reading or
  watching, so you never break flow. Nothing here is final. Keep it small.
- **`domains/NN-<domain>/` = LIBRARY.** The clean, organized, exam-ready version.
  This is what you revise from before the exam.

> Rule 0: **never let `course-notes/` become a second library.** Once a note is
> promoted, prune the raw version.

---

## 2. The flow (always the same three steps)

```
  reading / video / "aha" moment
            │
            ▼
   ┌──────────────────┐   1. CAPTURE (raw)         course-notes/notes.md
   │  dump it fast     │      - dated, newest on top
   │  don't organize   │      - a question instead? -> questions-for-kiro.md
   └────────┬─────────┘
            │  when the topic clicks
            ▼
   ┌──────────────────┐   2. PROMOTE (formalize)   domains/NN-<domain>/notes-<topic>.md
   │  apply template   │      - follow NOTE-TEMPLATE.md section order
   │  theory -> real   │      - add diagram + lab-verified output
   └────────┬─────────┘      - link from the domain README + INDEX.md
            │  once it lives in the domain
            ▼
   ┌──────────────────┐   3. PRUNE (clean inbox)   course-notes/notes.md
   │  delete/strike    │      - remove the raw note so the inbox stays small
   └──────────────────┘
```

---

## 3. The ordering rule inside every formalized note: THEORY → REAL WORLD

Every note tells the same story, in this order. This is the part that makes the
notes "click" — start from the idea, end at proof on the real cluster.

```
  ┌─ THEORY ──────────────┐   ┌─ MECHANISM ───────────┐   ┌─ REAL WORLD ──────────┐
  │ the idea / mental model│ ▶ │ how it works, the flow │ ▶ │ verified on the lab    │
  │ (what problem, why)    │   │ (numbered steps)       │   │ (real command output)  │
  └───────────────────────┘   └───────────────────────┘   └───────────────────────┘
          abstract  ───────────────────────────────────────────▶  concrete / proven
```

Concretely, each `domains/NN/notes-<topic>.md` has these sections **in this order**
(from [`domains/NOTE-TEMPLATE.md`](domains/NOTE-TEMPLATE.md)):

1. **Title + 🎯 domain/weight + one-line why it matters**
2. **Diagram** (optional) — image embedded from `images/`
3. **The idea (theory)** — plain-language concept + mental model
4. **Key parts** — table (thing / job / exam-relevant note)
5. **How it works / flow** — numbered mechanism or request lifecycle
6. **Verified on the lab** — REAL output from `vagrant-kubeadm` or `kind`
   (this is the theory→real-world payoff: proof, not claims)
7. **Commands to remember** — the few imperative one-liners
8. **Gotchas / failure modes** — mistake → symptom → fix
9. **30-second self-test** — Q→A pairs to drill recall
10. **See also** — cross-links to related notes/labs

Delete sections that don't apply, but **never reorder** them.

---

## 4. Where does a topic go? (routing table)

| Topic | Destination |
|-------|-------------|
| Troubleshooting, debugging broken clusters | `domains/05-troubleshooting/` |
| kubeadm, control plane, RBAC, etcd, upgrades, architecture | `domains/01-cluster-architecture/` |
| Services, Ingress, Gateway API, NetworkPolicy, CoreDNS | `domains/03-services-networking/` |
| Scheduling, taints/tolerations, workloads, HPA | `domains/02-workloads-scheduling/` |
| PV/PVC/StorageClass, volumes | `domains/04-storage/` |
| Operating the lab (kubeconfig, libvirt, node IPs) | `environment/` |
| Fast exam-day one-liners | `exam-prep/memory-muscle.md` |
| Not an exam topic (real-world depth) | `beyond-exam/` |

Unsure? Ask "where does this go?" and it gets placed per this table.

---

## 5. Naming & linking rules (so it stays findable)

- **File name:** `notes-<topic>.md` (kebab-case), inside the domain folder.
- **Labs:** `domains/NN-*/labs/<name>.md`. **Images:** `domains/NN-*/images/<file>.png`.
- **Always link a new note from two places:**
  1. that domain's `README.md` ("Study material here" list), and
  2. the top-level [`INDEX.md`](INDEX.md) (domain section + topic map).
- **One concept per note.** If a note grows two unrelated ideas, split it.

---

## 6. Rules Kiro follows (the contract)

When you ask to formalize/capture a note, Kiro will:

1. Put raw/fuzzy captures in `course-notes/`; put formalized notes in the matching
   `domains/NN-*/` (per the routing table).
2. Use the **template section order** (§3) — theory first, lab-verified output last.
3. Prefer **real, verified** lab output in "Verified on the lab" — run the command,
   don't invent output. If it can't be verified, say so.
4. Embed diagrams under the domain's `images/` and reference them relatively.
5. Link every new note from the domain README **and** `INDEX.md`.
6. Keep `course-notes/` lean — prune raw notes after promoting.
7. Keep one consistent voice/shape across all notes; never reorder template sections.

---

See also: [`course-notes/README.md`](course-notes/README.md) (the inbox),
[`domains/NOTE-TEMPLATE.md`](domains/NOTE-TEMPLATE.md) (the shape),
[`INDEX.md`](INDEX.md) (fast lookup).
