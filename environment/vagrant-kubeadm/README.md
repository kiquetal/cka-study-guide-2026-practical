# vagrant-kubeadm — Exam-Realistic Cluster

A **3-node** Kubernetes cluster (1 control-plane + 2 workers) built with **real
`kubeadm`** on **libvirt/KVM** VMs. This mirrors the CKA exam environment: systemd
`kubelet`, static-pod manifests, real node joins — the stuff you actually troubleshoot
on the exam.

> Do the [preflight check](../preflight-check.md) first (VT-x/KVM + `vagrant-libvirt`).

## What gets built

| Node | Hostname | IP | Role |
|------|----------|----|------|
| Control plane | `cp` | `192.168.56.10` | API server, etcd, scheduler, controller-manager |
| Worker 1 | `worker1` | `192.168.56.11` | workloads |
| Worker 2 | `worker2` | `192.168.56.12` | workloads |

- **Container runtime:** containerd (systemd cgroup driver)
- **CNI:** Calico (`v3.28.0`), pod CIDR `10.244.0.0/16`
- **Kubernetes:** pinned to `v1.37` (matches current CKA curriculum; see "Changing the version" below)
- **Isolation:** nodes sit on a private network `192.168.56.0/24`; nothing is published
  to your host. `vagrant destroy` removes everything.

## Files

```
vagrant-kubeadm/
├── Vagrantfile              # defines the 3 VMs (libvirt)
└── provision/
    ├── common.sh            # runs on ALL nodes: containerd + kubeadm/kubelet/kubectl
    ├── control-plane.sh     # kubeadm init + Calico + emits join command
    └── worker.sh            # waits for + runs the join command
```

The control-plane writes `join-command.sh` into the shared `/vagrant` folder; workers
read it from there. (That generated file is git-ignored.)

## Lifecycle

```bash
# From this directory:
vagrant up --provider=libvirt     # build & provision all 3 nodes (takes a few minutes)

# Shell into a node:
vagrant ssh cp
vagrant ssh worker1

# On the control-plane, verify the cluster:
vagrant ssh cp -c 'kubectl get nodes -o wide'
# Expect cp + worker1 + worker2, all STATUS=Ready (after Calico settles, ~1-2 min)

# Tear it all down (fully removes the VMs; your host is untouched):
vagrant destroy -f
```

## Verify it worked

```bash
vagrant ssh cp -c 'kubectl get nodes'
# NAME      STATUS   ROLES           AGE   VERSION
# cp        Ready    control-plane   ...   v1.31.x
# worker1   Ready    <none>          ...   v1.31.x
# worker2   Ready    <none>          ...   v1.31.x

vagrant ssh cp -c 'kubectl get pods -n kube-system'
# calico-* , coredns-*, etcd-cp, kube-apiserver-cp, etc. all Running
```

If a worker is missing, re-run its provisioner: `vagrant provision worker1`.

## Changing the Kubernetes version

Edit `K8S_MINOR` in [`provision/common.sh`](provision/common.sh) (e.g. `v1.31` →
`v1.32`), then rebuild:

```bash
vagrant destroy -f && vagrant up --provider=libvirt
```

## Troubleshooting the setup

- **`vagrant up` can't find libvirt provider** → `vagrant plugin install vagrant-libvirt`
  (see [preflight](../preflight-check.md)).
- **`Error while connecting to Libvirt ... /var/run/libvirt/libvirt-sock: Permission denied`**
  → your user isn't in the `libvirt` group *in the current shell session*. Add it (once),
  then start a fresh session:

  ```bash
  sudo usermod -aG libvirt,kvm "$USER"
  newgrp libvirt          # or log out / back in for the change to take effect
  ```

  If you can't start a new session yet, run Vagrant under the group for a single command:

  ```bash
  sg libvirt -c "vagrant up --provider=libvirt"
  ```

- **Tight on RAM?** Bring up a subset instead of all three nodes (cp + one worker
  ≈ 3 GB with the trimmed sizing in the Vagrantfile):

  ```bash
  vagrant up cp worker1 --provider=libvirt
  # add the second worker later:
  vagrant up worker2 --provider=libvirt
  ```

- **Nodes stuck NotReady** → CNI still coming up; wait 1-2 min, then
  `kubectl get pods -n kube-system`. Calico pods must be Running.
- **Worker never joins** → check the control-plane finished and wrote
  `join-command.sh`; then `vagrant provision worker1`.
- **Provisioning fails early with `Temporary failure resolving` / `Could not
  resolve host`** → the `generic/ubuntu2204` box ships `systemd-resolved`
  pointed at flaky hardcoded public DNS servers (`4.2.2.x`), so `apt-get`
  can't reach the Ubuntu mirrors or `pkgs.k8s.io` and `common.sh` aborts at
  its first `apt` call (it runs under `set -e`). `common.sh` now fixes this
  up front by writing a static `/etc/resolv.conf` that uses the libvirt NAT
  gateway plus public resolvers. If you ever hit it on a running node, apply
  the same fix by hand:

  ```bash
  sudo tee /etc/resolv.conf >/dev/null <<'EOF'
  nameserver 192.168.121.1   # libvirt NAT gateway (adjust if your net differs)
  nameserver 1.1.1.1
  nameserver 8.8.8.8
  options timeout:2 attempts:3
  EOF
  # verify, then clear any stuck apt and re-provision:
  getent hosts pkgs.k8s.io && sudo apt-get update
  ```

  Find your actual gateway with `ip route | grep default` inside the node.
- **`kubeadm init` fails preflight with `[ERROR FileExisting-conntrack]: conntrack
  not found`** → the `generic/ubuntu2204` box doesn't ship `conntrack` (a fatal
  kubeadm requirement for kube-proxy) or `socat` (needed by `kubectl port-forward`).
  `common.sh` now installs both alongside containerd. On a running node you can add
  them by hand, then re-provision:

  ```bash
  sudo apt-get update && sudo apt-get install -y conntrack socat
  sudo kubeadm reset -f        # only if a partial init left state behind
  ```

---

Back to [environment overview](../README.md) · [repo index](../../README.md).
