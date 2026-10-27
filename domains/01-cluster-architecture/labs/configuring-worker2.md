# Lab — Configuring `worker2` from a bare Ubuntu node (by hand)

🎯 **Exam scope:** Cluster Architecture, Installation & Configuration (25%).

Take a **plain Ubuntu `worker2`** and manually install and configure everything a
node needs, then join it to the cluster. The `provision/common.sh` and
`provision/worker.sh` scripts do all of this automatically — but on the CKA exam
(and in real life) **nobody runs your provisioning scripts for you**. You get a
node and a task: "add this node to the cluster." This lab builds that muscle.

> **Where do I run things?** Watch your shell prompt:
> - **host** → your Pop!_OS machine, in `environment/vagrant-kubeadm/`.
> - **worker2** (`vagrant@worker2:~$`) → inside the worker VM.
> - **cp** (`vagrant@cp:~$`) → inside the control-plane VM.

---

## Why this is a must-have skill (not just lab busywork)

Automation (Vagrant, Ansible, cloud-managed node pools) hides the moving parts.
When something breaks — a node stuck `NotReady`, a kubelet crash-loop, a failed
join — you cannot fix what you have never assembled by hand. The exam tests this
precisely because real on-call work does:

- **Node provisioning is a day-1 and day-2 task.** Scaling out, replacing a dead
  node, or rebuilding after a kernel upgrade all require prepping a host from
  scratch. Managed services (EKS/GKE/AKS) still leave you debugging the kubelet,
  container runtime, and networking when a node won't register.
- **The failure modes are always the same handful**, and each maps to one step
  below. Knowing the steps means you recognize the symptom instantly:
  - kubelet won't start / node never `Ready` → **swap still on** (Step 1) or
    **cgroup driver mismatch** between containerd and kubelet (Step 5).
  - Pods can't talk / `br_netfilter` errors → **kernel modules or sysctls
    missing** (Steps 2–3).
  - `kubeadm join` fails at preflight → **`conntrack` missing** or runtime not
    running (Step 4).
  - Join succeeds but node is `NotReady` → that's **expected** until the CNI
    (installed on the control plane) schedules its agent onto the node.
- **Version skew is a real outage cause.** Pinning the kube packages (Step 7)
  is how you stop an accidental `apt upgrade` from breaking the node/control-plane
  skew policy (kubelet may be up to 3 minors behind the API server, never ahead).

If you can do this cold, without the docs, you are ready for the 25% Cluster
Architecture domain and for the 3 a.m. page where a node fell out of the cluster.

---

## Prereqs

- The control-plane (`cp`) is already up and `Ready`
  (see [`00-first-cluster-bringup.md`](00-first-cluster-bringup.md)).
- A **bare** `worker2` with no kube tooling yet. Bring it up skipping
  provisioning so you do the prep yourself:

```bash
# run on: host, in environment/vagrant-kubeadm/
cd environment/vagrant-kubeadm
sg libvirt -c "vagrant up worker2 --provider=libvirt --no-provision"
sg libvirt -c "vagrant ssh worker2"
```

Then become root inside the node so you can omit `sudo` on each command:

```bash
# run on: worker2
sudo -i
```

> **Lab version:** Kubernetes **v1.37** (matches `provision/common.sh` →
> `K8S_MINOR` and the current CKA curriculum). If you bump the cluster, change
> `v1.37` in Step 6 to match.

---

## Step 1 — Disable swap  _(run on: worker2)_

The kubelet refuses to run with swap enabled (it breaks the memory accounting
the scheduler relies on).

```bash
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab   # persist across reboots
```

Verify: `free -h` shows `Swap: 0B`.

---

## Step 2 — Load kernel modules for container networking  _(run on: worker2)_

```bash
cat <<'EOF' >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
```

- `overlay` — the overlay filesystem the container runtime layers images with.
- `br_netfilter` — lets the Linux bridge pass traffic through iptables (required
  for Service/Pod networking).

Verify: `lsmod | grep -E 'overlay|br_netfilter'`.

---

## Step 3 — Sysctl params for Kubernetes networking  _(run on: worker2)_

```bash
cat <<'EOF' >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system
```

These make bridged traffic traverse iptables (so kube-proxy rules apply) and
enable IP forwarding (so the node routes Pod traffic).

Verify: `sysctl net.ipv4.ip_forward` → `= 1`.

---

## Step 4 — Install containerd + required dependencies  _(run on: worker2)_

```bash
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg apt-transport-https containerd conntrack socat
```

- `conntrack` — a **hard kubeadm preflight requirement** (kube-proxy needs it).
  Without it, `kubeadm join` aborts at preflight.
- `socat` — required for `kubectl port-forward`.

---

## Step 5 — Configure containerd with the systemd cgroup driver  _(run on: worker2)_

The container runtime's cgroup driver **must match the kubelet's** (both
`systemd`). A mismatch is the single most common cause of a kubelet that starts,
then crash-loops, leaving the node `NotReady`.

```bash
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd
```

Verify: `grep SystemdCgroup /etc/containerd/config.toml` → `SystemdCgroup = true`.

---

## Step 6 — Add the Kubernetes apt repo (v1.37)  _(run on: worker2)_

The `pkgs.k8s.io` repo is keyed by **minor version**, so the URL contains `v1.37`.

```bash
mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key" \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /" \
  >/etc/apt/sources.list.d/kubernetes.list
```

---

## Step 7 — Install kubelet, kubeadm, kubectl and pin them  _(run on: worker2)_

```bash
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl   # freeze versions (skew safety)
systemctl enable kubelet
```

`apt-mark hold` prevents an accidental `apt upgrade` from silently violating the
version-skew policy and breaking the node.

---

## Step 8 — Generate the join command  _(run on: cp)_

Join tokens **expire after 24h by default**, so never trust an old `kubeadm init`
printout — mint a fresh one:

```bash
# run on: cp
kubeadm token create --print-join-command
```

It prints something like:

```
kubeadm join 192.168.56.10:6443 --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:1234...beef
```

> **Need the CA cert hash by itself?** (e.g. the token exists but you lost the
> hash):
> ```bash
> openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
>   | openssl rsa -pubin -outform der 2>/dev/null \
>   | openssl dgst -sha256 -hex | sed 's/^.* //'
> ```

---

## Step 9 — Join the cluster  _(run on: worker2)_

Paste the exact command from Step 8, with `sudo`:

```bash
# run on: worker2
sudo kubeadm join 192.168.56.10:6443 --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:1234...beef
```

---

## Step 10 — Verify  _(run on: cp)_

```bash
# run on: cp
kubectl get nodes -o wide
```

`worker2` appears, and goes `Ready` within ~30–60s once the Calico CNI agent
lands on it. Confirm the node's role/version:

```bash
kubectl get node worker2 -o wide
```

---

## Troubleshooting (exam-grade reflexes)

| Symptom | Most likely cause | Fix |
|---|---|---|
| kubelet crash-loops; node never `Ready` | cgroup driver mismatch (Step 5) or swap on (Step 1) | `journalctl -u kubelet -f`; fix driver/swap, `systemctl restart kubelet` |
| `kubeadm join` aborts at preflight | `conntrack` missing, or containerd not running | install conntrack (Step 4); `systemctl status containerd` |
| Pods on the node can't reach others | `br_netfilter` / sysctls missing (Steps 2–3) | reapply, `sysctl --system` |
| join fails: "token not valid" / expired | token older than 24h | regenerate on cp (Step 8) |
| need to redo a join cleanly | partial/failed join state | on worker2: `sudo kubeadm reset -f`, then re-run Step 9 |

> **Allowed in the exam:** the official docs. Bookmark
> **kubernetes.io → "Installing kubeadm"** and the "Creating a cluster with
> kubeadm" / "join" pages. Knowing *where* the join and reset commands live is
> half the battle under time pressure.

---

## Wait — did I need to configure the CNI (Calico) on the worker? **No.**

A common point of confusion: you prep the node and join it, but you **never touch
CNI config on a worker** — yet the node still gets networking. Here's why:

- The CNI (Calico) was installed **once, cluster-wide, from the control-plane**
  during `kubeadm init` setup (`kubectl apply -f calico.yaml`). That created a
  Calico **DaemonSet**.
- A **DaemonSet runs one pod on *every* node automatically — including nodes that
  join later.** The instant `worker2` joined, the scheduler placed a
  `calico-node-*` pod on it with no action from you.
- That Calico pod sets up the node's pod networking, which is what flips the node
  from `NotReady` → `Ready`. The brief `NotReady` window right after join is
  simply "waiting for the CNI pod to land."

Verify the CNI landed on the new node (run on cp):

```bash
kubectl -n kube-system get pods -o wide --field-selector spec.nodeName=worker2
# expect: calico-node-xxxxx Running   +   kube-proxy-xxxxx Running
```

**Mental model:** node-prep (swap/modules/sysctls/containerd/kube tools) + `join`
is *your* job per node. The CNI is a cluster-level add-on installed once — it
self-propagates to new nodes via its DaemonSet. You only reinstall/reconfigure a
CNI at the **cluster** level, never per worker.

---

## Real-run lessons (from doing this by hand on Pop!_OS/libvirt)

Issues that actually came up — expect these and you'll move faster:

1. **DNS was broken on the bare node.** Because we used `vagrant up --no-provision`,
   `common.sh`'s DNS fix never ran, so `apt-get` failed with "Temporary failure
   resolving". Fix: point `/etc/resolv.conf` at working nameservers before any
   apt/curl:
   ```bash
   echo "nameserver 1.1.1.1"  > /etc/resolv.conf
   echo "nameserver 8.8.8.8" >> /etc/resolv.conf
   ```
2. **"Permission denied" writing `/etc/...` = you're not root.** Run `sudo -i`
   first; confirm with `whoami` → `root`. (Reason: `cmd > /etc/file` opens the
   file as *your* user before `sudo` applies — use `sudo tee` if not root.)
3. **Long commands break when pasted** (terminal wraps them, splitting a flag
   from its value → "flag needs an argument" / "command not found"). For the long
   `kubeadm join` line and the apt repo line, **put them in a file and run that**,
   or edit with `nano`, instead of pasting into the prompt:
   ```bash
   nano /root/join.sh      # paste the full 'kubeadm join ...' as ONE line, save
   bash /root/join.sh
   ```
4. **A `deb` source entry must be ONE line.** A wrapped paste produced a
   "Malformed entry ... (URI)" error in `kubernetes.list`. Fix by rewriting it as
   a single line (via `nano` or `printf`) and `cat` it to confirm no wrap.
5. **`kubectl` "fails" on the worker — that's correct.** Workers have no admin
   kubeconfig. Run `kubectl` on the control-plane (or your host). See
   [`../../../environment/using-the-cluster-with-kubectl.md`](../../../environment/using-the-cluster-with-kubectl.md).
