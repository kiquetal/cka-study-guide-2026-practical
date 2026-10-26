# INDEX — fast lookup of everything in this repo

One flat list of every doc, grouped by purpose, with its path. For quick
navigation and fast inference. Legend: 🎯 exam scope · 🧪 hands-on lab ·
📖 notes · 🔧 lab-ops · 🚀 beyond-exam.

> Keep this file updated when adding a doc: one row, right group.

---

## Start here

| Doc | Path |
|-----|------|
| Repo overview, exam info, how-to-use | [`README.md`](README.md) |
| Full multi-increment plan | [`PLAN.md`](PLAN.md) |
| 2027 study timeline | [`roadmap/2027-study-plan.md`](roadmap/2027-study-plan.md) |

## Lab environment (set up & operate the cluster)

| | Doc | Path |
|---|-----|------|
| 🔧 | Preflight: VT-x/KVM, install libvirt+vagrant | [`environment/preflight-check.md`](environment/preflight-check.md) |
| 🔧 | Environments overview (kubeadm vs kind) | [`environment/README.md`](environment/README.md) |
| 🔧 | **Use `kubectl` safely** (don't clobber real EKS config) | [`environment/using-the-cluster-with-kubectl.md`](environment/using-the-cluster-with-kubectl.md) |
| 🔧 | **libvirt NAT + node-IP nuance** (API IP vs InternalIP vs CIDRs) | [`environment/notes-libvirt-nat-and-node-ips.md`](environment/notes-libvirt-nat-and-node-ips.md) |
| 🔧 | kubeadm VM cluster (3-node, exam-realistic) | [`environment/vagrant-kubeadm/README.md`](environment/vagrant-kubeadm/README.md) |
| 🔧 | kubeadm setup troubleshooting | [`environment/vagrant-kubeadm/TROUBLESHOOTING-SETUP.md`](environment/vagrant-kubeadm/TROUBLESHOOTING-SETUP.md) |
| 🔧 | kind fast disposable cluster | [`environment/kind/README.md`](environment/kind/README.md) |

## Domain 05 — Troubleshooting (30%) 🎯

| | Doc | Path |
|---|-----|------|
| | Domain overview + objectives | [`domains/05-troubleshooting/README.md`](domains/05-troubleshooting/README.md) |
| 📖 | Notes | [`domains/05-troubleshooting/notes-troubleshooting.md`](domains/05-troubleshooting/notes-troubleshooting.md) |

## Domain 01 — Cluster Architecture (25%) 🎯

| | Doc | Path |
|---|-----|------|
| | Domain overview + objectives | [`domains/01-cluster-architecture/README.md`](domains/01-cluster-architecture/README.md) |
| 📖 | Notes (components, kubeadm, RBAC, etcd, upgrades) | [`domains/01-cluster-architecture/notes-cluster-architecture.md`](domains/01-cluster-architecture/notes-cluster-architecture.md) |
| 🧪 | Lab: first cluster bring-up by hand | [`domains/01-cluster-architecture/labs/00-first-cluster-bringup.md`](domains/01-cluster-architecture/labs/00-first-cluster-bringup.md) |
| 🧪 | Lab: configure a bare worker node + join | [`domains/01-cluster-architecture/labs/configuring-worker2.md`](domains/01-cluster-architecture/labs/configuring-worker2.md) |

## Domain 03 — Services & Networking (20%) 🎯

| | Doc | Path |
|---|-----|------|
| | Domain overview + objectives | [`domains/03-services-networking/README.md`](domains/03-services-networking/README.md) |
| 📖 | Notes (Service types, Ingress/Gateway API, NetPol, CoreDNS) | [`domains/03-services-networking/notes-services-networking.md`](domains/03-services-networking/notes-services-networking.md) |

## Domain 02 — Workloads & Scheduling (15%) 🎯

| | Doc | Path |
|---|-----|------|
| | Domain overview + objectives | [`domains/02-workloads-scheduling/README.md`](domains/02-workloads-scheduling/README.md) |
| 📖 | Notes (workloads, autoscaling incl. HPA scale-to-zero) | [`domains/02-workloads-scheduling/notes-workloads.md`](domains/02-workloads-scheduling/notes-workloads.md) |
| 📖 | Notes: taints & tolerations | [`domains/02-workloads-scheduling/notes-taints-tolerations.md`](domains/02-workloads-scheduling/notes-taints-tolerations.md) |

## Domain 04 — Storage (10%) 🎯

| | Doc | Path |
|---|-----|------|
| | Domain overview + objectives | [`domains/04-storage/README.md`](domains/04-storage/README.md) |
| 📖 | Notes | [`domains/04-storage/notes-storage.md`](domains/04-storage/notes-storage.md) |

## Exam prep (cross-domain)

| | Doc | Path |
|---|-----|------|
| | Exam prep overview (logistics, cheatsheet, mocks) | [`exam-prep/README.md`](exam-prep/README.md) |

## Course notes & queue

| | Doc | Path |
|---|-----|------|
| 📖 | Free-form notes | [`course-notes/notes.md`](course-notes/notes.md) |
| 📝 | Questions queue for Kiro | [`course-notes/questions-for-kiro.md`](course-notes/questions-for-kiro.md) |

## Beyond exam 🚀

| | Doc | Path |
|---|-----|------|
| 🚀 | Istio Ambient mesh (real-world) | [`beyond-exam/istio-ambient/README.md`](beyond-exam/istio-ambient/README.md) |

---

## Quick topic → doc map (fast inference)

| If you need… | Go to |
|--------------|-------|
| talk to the cluster / kubeconfig / `kcka` | `environment/using-the-cluster-with-kubectl.md` |
| why two IPs? join IP vs node IP / NAT / CIDRs | `environment/notes-libvirt-nat-and-node-ips.md` |
| add/prep a worker node (swap, containerd, join) | `domains/01-cluster-architecture/labs/configuring-worker2.md` |
| bring up the control plane by hand | `domains/01-cluster-architecture/labs/00-first-cluster-bringup.md` |
| etcd backup/restore, RBAC, upgrades | `domains/01-cluster-architecture/notes-cluster-architecture.md` |
| Services, Ingress, Gateway API, NetworkPolicy, CoreDNS | `domains/03-services-networking/notes-services-networking.md` |
| scheduling, taints/tolerations, HPA | `domains/02-workloads-scheduling/` |
| PV/PVC/StorageClass | `domains/04-storage/notes-storage.md` |
| broke the cluster, debugging | `domains/05-troubleshooting/notes-troubleshooting.md` |
| set up / choose a lab environment | `environment/README.md` |
