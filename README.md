# CKA 2027 Study Guide & Practical Lab

My personal, hands-on journey to the **Certified Kubernetes Administrator (CKA)** exam,
target **2027**. Organized by the official exam domains, backed by isolated lab
environments that mirror the real exam, plus a "beyond exam" track for real-world
engineering depth.

> **Legend:** 🎯 = exam scope &nbsp;|&nbsp; 🚀 = beyond exam / real-world

> 🔎 **Looking for a specific doc?** See [`INDEX.md`](INDEX.md) — a flat, fast-lookup
> list of everything in the repo, plus a "topic → doc" map.

---

## Exam overview

| Attribute | Detail |
|-----------|--------|
| Format | Performance-based, hands-on in a live terminal (no multiple choice) |
| Duration | 2 hours |
| Passing score | 66% |
| Validity | 2 years |
| Delivery | Remote, proctored (PSI) |
| Curriculum | CNCF 2025 overhaul (adds Gateway API, CRDs/Operators emphasis) |
| Kubernetes version | **v1.37** — current curriculum is `CKA_Curriculum_v1.37.pdf` ([CNCF repo](https://github.com/cncf/curriculum)). Tracks ~latest stable; **re-verify before booking** (new minor ~every 4 months). |

> ✅ **Lab matches exam version:** both lab environments are pinned to **v1.37**
> (`environment/vagrant-kubeadm/provision/common.sh` → `K8S_MINOR`, and
> `environment/kind/kind-cluster.yaml` → `kindest/node:v1.37.0`). This matches the
> current CKA curriculum. Re-verify and bump again before booking in 2027.
> **Note:** the v1.37 kind image needs **kind ≥ v0.33.0** (older kind can't run it).

> 🎯 **Exam target: first months of 2027 — top priority.** Study order follows exam
> weight (Troubleshooting 30% first). Known recent change to study: **HPA
> scale-to-zero** (Beta, on by default in v1.37) — see
> [`domains/02-workloads-scheduling/notes-workloads.md`](domains/02-workloads-scheduling/notes-workloads.md).

## Version awareness (modern k8s) 🆕

The exam tracks a recent Kubernetes release, so newer features **are** fair game.
Running tracker of recent-version changes worth studying:

| Feature | Version / status | Why it matters | Notes |
|---------|------------------|----------------|-------|
| HPA **scale-to-zero** | gate on-by-default v1.36 (Apr 2026); **Beta + default v1.37** (Sep 2026) | Workloads & Scheduling: "configure workload autoscaling". Native scale to `minReplicas: 0` with an object/external metric | [notes-workloads.md](domains/02-workloads-scheduling/notes-workloads.md) |
| **Gateway API** | GA / curriculum emphasis (2025 overhaul) | Services & Networking: explicit competency alongside Ingress | [notes-services-networking.md](domains/03-services-networking/notes-services-networking.md) |
| **CRDs / Operators**, Helm, Kustomize | 2025 overhaul additions | Cluster Architecture: new competencies | [notes-cluster-architecture.md](domains/01-cluster-architecture/notes-cluster-architecture.md) |

> Add a row here whenever a recent release adds something exam-relevant.

### When to use a more modern k8s version in the lab

The lab now pins **v1.37** — the same version as the current exam. Guidance:

- **Fundamentals (90% of study):** v1.37 matches the exam, so you're set. The core
  commands/behavior (Pods, Deployments, Services, RBAC, etcd, scheduling, storage)
  are stable across recent versions anyway.
- **Version-specific features** (e.g. HPA scale-to-zero, Beta in v1.37): now
  available in the lab since you're on v1.37 — practice them directly.
- **~4–6 weeks before booking (early 2027):** re-check the
  [CNCF repo](https://github.com/cncf/curriculum) — if the curriculum has moved past
  v1.37, bump both environments again and do final mock runs on that version.
  **then-current curriculum version** (re-check the [CNCF repo](https://github.com/cncf/curriculum))
  and do your final mock runs there, so flags/output/deprecations match the real exam.

How to bump (documented in each env's README):
- kubeadm VMs → `K8S_MINOR` in `environment/vagrant-kubeadm/provision/common.sh`, then `vagrant destroy -f && vagrant up`.
- kind → `image: kindest/node:vX.Y.Z` in `environment/kind/kind-cluster.yaml`.

## Domains & weightings 🎯

Study order below follows **exam weight** (heaviest first), which is also the order
these sections get built out.

| # | Domain | Weight | Folder |
|---|--------|:------:|--------|
| 05 | Troubleshooting | **30%** | [`domains/05-troubleshooting/`](domains/05-troubleshooting/) |
| 01 | Cluster Architecture, Installation & Configuration | **25%** | [`domains/01-cluster-architecture/`](domains/01-cluster-architecture/) |
| 03 | Services & Networking (incl. Gateway API) | **20%** | [`domains/03-services-networking/`](domains/03-services-networking/) |
| 02 | Workloads & Scheduling | **15%** | [`domains/02-workloads-scheduling/`](domains/02-workloads-scheduling/) |
| 04 | Storage | **10%** | [`domains/04-storage/`](domains/04-storage/) |

## Primary learning resources (O'Reilly)

- **PRIMARY — _CKA Study Guide, 2nd Edition_ (Benjamin Muschko)** — rebuilt for the
  2025 curriculum overhaul (CRDs/Operators, Gateway API). Main reference for this repo.
- **SECONDARY — _Certified Kubernetes Administrator (CKA), 4th Edition_ [Video]** —
  newest video edition; watch for hands-on demonstrations.

Take notes freely in [`course-notes/`](course-notes/) as you watch/read.

---

## Repository map

| Section | What's there | Status |
|---------|--------------|--------|
| [`course-notes/`](course-notes/) | Free-form notes + a questions queue for Kiro | ✅ Ready |
| [`environment/`](environment/) | Isolated lab setup: kubeadm VMs + kind | ✅ Ready |
| [`roadmap/`](roadmap/2027-study-plan.md) | Phased timeline to the 2027 exam | 🕓 Later |
| [`domains/`](domains/) | 🎯 Per-domain notes + hands-on labs | 🕓 Later |
| [`exam-prep/`](exam-prep/) | 🎯 Logistics, global cheatsheet, mock-exam tracker | 🕓 Later |
| [`beyond-exam/istio-ambient/`](beyond-exam/istio-ambient/) | 🚀 Istio Ambient mesh (real-world) | 🕓 Later |
| [`PLAN.md`](PLAN.md) | Full multi-increment plan | ✅ Ready |

---

## How to use this repo

1. **Set up the lab first.** Start with the environment preflight:
   [`environment/preflight-check.md`](environment/preflight-check.md) to confirm your
   Pop!_OS machine can run VMs, then stand up a cluster.
   - Exam-realistic multi-node cluster (systemd kubelet, real kubeadm):
     [`environment/vagrant-kubeadm/`](environment/vagrant-kubeadm/)
   - Fast, disposable cluster for quick experiments:
     [`environment/kind/`](environment/kind/)
2. **Watch/read + take notes.** Drop running notes in
   [`course-notes/notes.md`](course-notes/notes.md). Anything you want me (Kiro) to
   research later goes in
   [`course-notes/questions-for-kiro.md`](course-notes/questions-for-kiro.md).
3. **Practice by domain**, heaviest weight first (Troubleshooting → ... → Storage).
4. **Go beyond the exam** once comfortable, with
   [`beyond-exam/istio-ambient/`](beyond-exam/istio-ambient/).

See [`PLAN.md`](PLAN.md) for the complete plan and what each future increment adds.
