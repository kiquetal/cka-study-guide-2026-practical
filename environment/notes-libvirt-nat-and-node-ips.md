# Networking nuance — libvirt NAT, node IPs, and why the IP you pick matters

🎯 **Exam scope:** touches Cluster Architecture (25%) and Services & Networking
(20%). Not a standalone exam objective, but IP/interface confusion is a top cause
of "node won't join" and "API server unreachable" failures — on the exam and in
production.

This note explains the networking model behind the `vagrant-kubeadm` lab, the
**two-IP nuance** that bites people, and when you actually need to care about it.

---

## What is libvirt NAT?

When you run VMs on KVM/libvirt, each VM needs a network. The default and simplest
mode is a **NAT network**: libvirt creates a virtual bridge on the host, hands the
VMs private IPs via DHCP, and NATs their outbound traffic through the host (just
like your home router does for your laptop/phone).

- **Outbound (VM → internet):** works. The VM's private IP is masqueraded behind
  the host's real IP. This is how `apt-get`, `curl pkgs.k8s.io`, and pulling
  container images work inside the nodes.
- **Inbound (internet → VM):** blocked by default. Nothing outside the host can
  reach a NAT'd VM directly without explicit port-forwarding. **This is why the
  lab is "fully isolated"** — the cluster is reachable from your Pop!_OS host and
  between VMs, but not from the outside world.
- **VM ↔ VM on the same libvirt network:** works directly (same subnet).

`forward mode='nat'` in the network XML is what marks a network as NAT.

---

## The lab's actual networks (verified)

This lab has **three** libvirt NAT networks, and each node is on **two** of them
at once — this is the nuance to understand:

| libvirt network     | Subnet            | Gateway        | Role in the lab |
|---------------------|-------------------|----------------|-----------------|
| `vagrant-libvirt`   | `192.168.121.0/24`| `192.168.121.1`| Auto-created management net. **Vagrant SSH** lands here; it became each node's **kubelet InternalIP** (`eth0`). |
| `vagrant-kubeadm0`  | `192.168.56.0/24` | `192.168.56.1` | The `private_network` from the `Vagrantfile`. The **API server advertises `192.168.56.10`** here (`eth1`). |
| `default`           | `192.168.122.0/24`| `192.168.122.1`| libvirt's stock network; not used by cluster nodes here. |

So every node has **two NICs**:

```
# on worker2 (verified):
eth0  192.168.121.163/24   <- vagrant-libvirt  (SSH + kubelet InternalIP)
eth1  192.168.56.12/24     <- vagrant-kubeadm0 (API server advertise net)
```

---

## The nuance that bites you: which IP do I use?

You will see **two different IPs for the same cluster**, and it's not a bug:

- `kubectl get nodes -o wide` shows **INTERNAL-IP `192.168.121.x`**
  (kubelet auto-picked `eth0`, the first default-route interface).
- `kubeadm token create --print-join-command` emits
  **`kubeadm join 192.168.56.10:6443 ...`**
  (the API server's `--advertise-address`, which was set from the Vagrantfile's
  `private_network` = `eth1`).

**Rule of thumb for this lab:**

- **To join a worker** → use the **API server endpoint**, i.e. `192.168.56.10:6443`
  (the `.56.x` net). That's what `kubeadm ... --print-join-command` already prints,
  so just copy it verbatim. Don't substitute the `.121.x` IP.
- **To look at / debug nodes** → the `.121.x` InternalIP is what kubelet reports.
- **Pod/Service IPs** are a *third* thing entirely (`10.244.0.0/16` pod CIDR,
  `10.96.0.0/12` default service CIDR) — virtual, overlay-managed by Calico, and
  live only inside the cluster.

Mental model — **four IP families, don't mix them up:**

| IP family            | Example            | Who owns it | Reachable from |
|----------------------|--------------------|-------------|----------------|
| API server endpoint  | `192.168.56.10:6443` | kube-apiserver advertise-address | nodes + host |
| Node InternalIP      | `192.168.121.x`    | kubelet (picks a host NIC) | nodes + host |
| Pod CIDR             | `10.244.x.x`       | CNI (Calico) | inside cluster |
| Service (ClusterIP)  | `10.96.x.x`        | kube-proxy / API | inside cluster |

---

## Why is this relevant?

- 🎯 **For the exam:**
  - **"Node won't join" is almost always an endpoint/firewall problem.** If you hand
    `kubeadm join` the wrong IP (one the worker can't route to, or a NIC the API
    server isn't listening on), the TLS bootstrap just times out. Knowing *which*
    IP is the API endpoint turns a 20-minute head-scratch into a 10-second fix.
  - **`-o wide` reveals the InternalIP each node picked** — first stop when
    `kubectl logs`/`exec` hangs (the API server proxies those to the InternalIP).
  - **Don't confuse the IP families.** Two quick corrections people trip on:
    - *"Two IPs" is per **node**, not per cluster* — each node has 2 NICs
      (eth0 `.121.x` InternalIP, eth1 `.56.x` advertise net). 3 nodes ⇒ ~6 node IPs.
    - *InternalIP is identity/reachability, NOT capacity.* "Enough room" for
      workloads is the **pod CIDR** (`10.244.0.0/16`, huge on purpose) and
      **service CIDR** (`10.96.0.0/12`) — a different pair of ranges entirely.

- 🌍 **Real-world / edge cases — strange behaviour this explains:**
  - **Multi-NIC hosts are the norm in production** (management + data + storage
    nets). The kubelet picks *one* InternalIP and it may be the wrong NIC →
    inter-node traffic or `kubectl logs`/`exec` break. Fix: pin it with `--node-ip`.
  - **Rebuilt the control plane and now nothing can join** → the
    `--apiserver-advertise-address` (`kubeadm init`) points at a NIC the other nodes
    can't reach. A deliberate choice you must get right on multi-NIC hosts.
  - **"Weird routing failures" after install** → **pod/service CIDRs overlap** the
    node/host network. The lab keeps `10.244.0.0/16` + `10.96.0.0/12` far from
    `192.168.x.x` on purpose; overlap is a real, hard-to-debug outage.
  - **Can't reach the cluster from another machine** → **NAT = isolation**. Outbound
    works, inbound is blocked; the lab is only usable from the host without extra
    port-forwarding.

---

## When you do NOT need to care

- **Single-NIC nodes** (most cloud VMs, most kind/minikube setups): node IP, SSH
  IP, and API endpoint collapse to one address. The nuance disappears — you only
  meet it on multi-homed hosts like this Vagrant/libvirt lab or bare metal.
- **Managed clusters (EKS/GKE/AKS):** the provider wires the networking; you rarely
  touch advertise-address or node-ip. But you *will* still care about
  **pod/service CIDR planning** and **not overlapping with your VPC**.
- **Day-to-day `kubectl`** against an already-working cluster: you use the
  kubeconfig's `server:` URL and never think about NICs.

---

## Quick commands to inspect any cluster's IPs

```bash
# node InternalIP(s) and which NIC kubelet chose
kubectl get nodes -o wide

# the API server endpoint your kubeconfig actually talks to
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'; echo

# what the API server advertises (on the control-plane host)
sudo grep -E 'advertise-address' /etc/kubernetes/manifests/kube-apiserver.yaml

# pod + service CIDRs
kubectl cluster-info dump | grep -m2 -E 'cluster-cidr|service-cluster-ip-range'

# this VM's NICs (spot multi-homing)
ip -brief addr show

# libvirt networks on the host (NAT ranges)
virsh net-list --all
virsh net-dumpxml <network-name> | grep -E 'forward mode|ip address|range'
```

---

## Tips to remember

1. **Copy the join command verbatim** from `kubeadm token create
   --print-join-command`. It already contains the correct API endpoint — don't
   "fix" the IP to the one you saw in `get nodes`.
2. **`-o wide` is your friend.** `kubectl get nodes -o wide` and
   `kubectl get pods -o wide` reveal the IP each object actually got — first stop
   for any networking issue.
3. On **multi-NIC** nodes, pin kubelet's IP with **`--node-ip`** if it guesses
   wrong. Symptom: `kubectl logs`/`exec` hang or inter-node traffic fails.
4. Keep the **four IP families** separate in your head (table above). Most
   "weird k8s networking" bugs are really "someone mixed two of these up."
5. **NAT isolates.** Great for labs; remember it's why the cluster isn't reachable
   off-host without extra plumbing.
