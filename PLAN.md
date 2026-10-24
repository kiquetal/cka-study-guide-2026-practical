# PLAN — CKA 2027 Study Guide & Practical Lab

Full multi-increment plan for this repository. The **Foundation** increment is built;
everything under **Later increments** is scoped for future sessions.

## Goal

A from-scratch, well-structured repo to prepare for the **CKA exam (target 2027)**,
organized by the current CKA curriculum domains, with isolated hands-on lab
environments that mirror the real exam, a free-form course-notes area tied to O'Reilly
material, and a separate "beyond exam" Istio Ambient track for real-world depth.

## Background

- **CKA (2025-2026 CNCF overhaul):** performance-based, hands-on, proctored (PSI);
  **2 hours**; **66%** to pass; valid **2 years**. The 2025 overhaul added **Gateway
  API** and **CRDs/Operators** emphasis.
- **Domains & weightings:**

  | # | Domain | Weight |
  |---|--------|:------:|
  | 05 | Troubleshooting | 30% |
  | 01 | Cluster Architecture, Installation & Configuration | 25% |
  | 03 | Services & Networking (incl. Gateway API) | 20% |
  | 02 | Workloads & Scheduling | 15% |
  | 04 | Storage | 10% |

- **O'Reilly resources:** PRIMARY — _CKA Study Guide, 2nd Edition_ (Benjamin Muschko),
  rebuilt for the 2025 overhaul. SECONDARY — _CKA, 4th Edition_ [Video] (newest video).
- **Host:** Pop!_OS (Ubuntu/Debian). KVM native via `/dev/kvm`; `vagrant-libvirt` is
  the lightest exam-realistic multi-node path. Requires VT-x/AMD-V enabled.

## Repository structure (full target)

```
cka-study-guide-2026-practical/
├── README.md                      # master index + roadmap + exam logistics + O'Reilly
├── PLAN.md                        # this file
├── .gitignore
├── course-notes/                  # free-form notes + questions queue        [DONE]
│   ├── README.md
│   ├── notes.md
│   └── questions-for-kiro.md
├── roadmap/
│   └── 2027-study-plan.md         # phased timeline                          [LATER]
├── environment/                   # isolated labs                            [DONE]
│   ├── README.md
│   ├── preflight-check.md
│   ├── vagrant-kubeadm/           # 1 cp + 2 workers (libvirt, real kubeadm)
│   │   ├── Vagrantfile
│   │   └── provision/{common,control-plane,worker}.sh
│   └── kind/
│       └── kind-cluster.yaml
├── domains/                       # per-domain notes + labs                  [LATER]
│   ├── 01-cluster-architecture/   # 25%
│   ├── 02-workloads-scheduling/   # 15%
│   ├── 03-services-networking/    # 20% (Gateway API)
│   ├── 04-storage/                # 10%
│   └── 05-troubleshooting/        # 30%
├── beyond-exam/
│   └── istio-ambient/             # real-world (beyond exam)                 [LATER]
└── exam-prep/                     # logistics, cheatsheet, mock tracker      [LATER]
```

---

## Foundation increment (DONE)

1. **Repo skeleton** — all folders, placeholder READMEs for later sections, `.gitignore`
   (`.vagrant/`, `*.box`, `*.log`, `kubeconfig*`, `*.key`, `.env`, generated
   `join-command.sh`).
2. **Root `README.md`** — master index: exam overview, 5 domains + weightings, O'Reilly
   resources, repo map, how-to-use, exam-vs-beyond-exam legend.
3. **`course-notes/`** — free-form `notes.md`, `questions-for-kiro.md` queue, and a
   README explaining the no-rigid-structure approach.
4. **`environment/preflight-check.md` + `environment/README.md`** — Pop!_OS VT-x/KVM
   check, libvirt + vagrant + `vagrant-libvirt` install; kubeadm-VM vs kind guidance.
5. **`environment/kind/`** — `kind-cluster.yaml` (1 cp + 2 workers) + docs.
6. **`environment/vagrant-kubeadm/`** — Vagrantfile (libvirt) + provision scripts
   (containerd, kubeadm/kubelet/kubectl pinned to v1.31, `kubeadm init`, Calico CNI,
   worker join) + README (lifecycle, verify, version bump, troubleshooting).
7. **`PLAN.md`** — this file.

---

## Later increments (NOT yet built)

Build order follows exam weight (heaviest first).

- **Domain 05 — Troubleshooting (30%):** notes, cheatsheet, **break/fix** labs on the
  kubeadm VM cluster (kubelet / node NotReady, control-plane static-pods, DNS &
  networking, `crictl`, resource exhaustion).
- **Domain 01 — Cluster Architecture (25%):** kubeadm lifecycle, RBAC, **etcd backup &
  restore**, `kubeadm upgrade`, HA concepts, kubeconfig/context labs.
- **Domain 03 — Services & Networking (20%):** Services (ClusterIP/NodePort/LB),
  Ingress vs **Gateway API** (emphasis on the new API), NetworkPolicies, CoreDNS.
- **Domain 02 — Workloads & Scheduling (15%):** Deployments, scaling, rollout/rollback,
  taints/tolerations, affinity, nodeSelector, ConfigMaps/Secrets, resource limits;
  imperative-command cheatsheet (`--dry-run=client -o yaml`).
- **Domain 04 — Storage (10%):** PV/PVC, StorageClasses, access modes, reclaim
  policies, dynamic provisioning (kind local-path).
- **`exam-prep/`:** `logistics.md` (booking, PSI env, allowed docs, killer.sh, time
  management), `cheatsheet-global.md` (kubectl aliases, imperative shortcuts, vim/tmux),
  `mock-exam-checklist.md` (weighted self-test tracker).
- **`beyond-exam/istio-ambient/`:** documentation-first — Ambient vs sidecar, ztunnel,
  waypoint proxies, L4/L7, mTLS; prerequisites point at the kind cluster; filled
  incrementally via Q&A. Clearly flagged **beyond exam scope**.
- **`roadmap/2027-study-plan.md`:** phased plan (Phase 0 environment → domain
  deep-dives by weight → beyond-exam Istio → mock exams) with checkpoints toward a 2027
  exam date; cross-link everything; full repo link-check.

---

## Conventions

- **Notes are free-form.** No forced chapter mapping; distill into `domains/` on review.
- **Labs target isolation.** Cluster-admin/troubleshooting → `vagrant-kubeadm/`;
  app-layer/experiments → `kind/`.
- **Exam vs real-world** is always labeled: 🎯 exam scope, 🚀 beyond exam.
