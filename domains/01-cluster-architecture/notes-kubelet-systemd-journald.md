# The Linux layer — kubelet as a systemd service, journald for insight

🎯 **Domain 01 (25%) + Troubleshooting (30%).** The kubelet is **not** a pod — it's a
plain **Linux process managed by systemd**. When a node is `NotReady` and `kubectl`
can't tell you why, you drop to this layer: `systemctl` + `journalctl`.

---

## The idea (theory)

Kubernetes components split into two groups by *how they run*:

```
   systemd services (on the node, real Linux processes)      kubectl CANNOT manage these
     • kubelet         ── the node agent
     • containerd      ── the container runtime
                          ▲ these start the whole cluster; they predate the API

   pods (managed BY the kubelet, seen via kubectl)            kubectl CAN see/manage
     • control-plane static pods (apiserver, etcd, ...)
     • your workloads
```

So the **kubelet and container runtime are the bootstrap floor** — systemd starts
them at boot, and *they* bring up everything else. That's why you manage them with
**systemd**, not kubectl: kubectl needs the API server, which the kubelet starts.

## Why is this relevant?

- 🎯 **For the exam:** "node is `NotReady`, fix it" is a core Troubleshooting task.
  The fix lives here — `systemctl status kubelet`, `journalctl -u kubelet` — not in
  `kubectl`. Same for "API server down": you debug the kubelet that should be
  running its static pod.
- 🌍 **Real-world / edge cases — strange behaviour this explains:**
  - Node `NotReady` right after a config change → kubelet failed to start; the
    reason is in `journalctl -u kubelet` (bad `config.yaml`, swap on, cgroup driver
    mismatch).
  - `kubectl` works but a node's pods never start → that node's **kubelet** or
    **containerd** systemd service is down.
  - kubelet keeps restarting (`systemctl status` shows repeated restarts) → crash
    loop; `journalctl` shows the recurring error.

---

## Key parts (verified on this lab's `cp`)

| Command | What it tells you |
|---------|-------------------|
| `systemctl list-units --type=service` | **discover** loaded+running services (find kubelet/containerd) |
| `systemctl list-unit-files` | which units exist on disk and if they're `enabled` at boot |
| `systemctl list-units --state=failed` | one-glance "what's broken on this node?" |
| `systemctl is-active kubelet` | up (`active`) or down |
| `systemctl status kubelet` | state, PID, uptime, the exact `ExecStart` line, cgroup |
| `systemctl cat kubelet` | the unit **+ the kubeadm drop-in** (`10-kubeadm.conf`) |
| `journalctl -u kubelet` | the logs — *why* it failed / what it's doing |
| `journalctl -u kubelet -f` | follow live (watch it try to start) |
| `systemctl restart kubelet` | restart after fixing config |
| `systemctl is-active containerd` | the runtime is also a systemd service |

## How it works / flow — where the kubelet reads its config

The kubeadm drop-in (`/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf`)
wires the kubelet to its config files:

```
  ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS \
                             $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
     │
     ├─ --kubeconfig=/etc/kubernetes/kubelet.conf          (how it talks to the API)
     ├─ --config=/var/lib/kubelet/config.yaml              (kubelet settings; cgroup driver here)
     └─ EnvironmentFile=/var/lib/kubelet/kubeadm-flags.env (runtime flags kubeadm generated)
```

So to retune the kubelet you edit `/var/lib/kubelet/config.yaml` (or the env file)
and `systemctl restart kubelet` — there is no `kubectl` for this.

## Verified on the lab

```text
$ systemctl list-units --type=service --state=running | grep -E 'kubelet|containerd'
  containerd.service   loaded active running containerd container runtime
  kubelet.service      loaded active running kubelet: The Kubernetes Node Agent

$ systemctl list-unit-files | grep -E 'kubelet|containerd'
containerd.service   enabled   enabled
kubelet.service      enabled   enabled
# (also note dozens of cri-containerd-<id>.scope transient units — each is ONE
#  running container; that's how containerd wires containers into systemd)

$ systemctl list-units --state=failed
● systemd-networkd-wait-online.service  loaded failed failed  Wait for Network...
# ^ harmless on this box, but this is the "what's broken on the node?" one-glance

$ systemctl list-units 'kube*' 'containerd*' --type=service    # SCOPED to k8s
  containerd.service   loaded active running   containerd container runtime
  kubelet.service      loaded active running   kubelet: The Kubernetes Node Agent
2 loaded units listed.

$ systemctl list-units 'kubepods-*.slice'      # cgroup slices: pods grouped by QoS
  kubepods-besteffort.slice            loaded active active  ...
  kubepods-burstable-pod<id>.slice     loaded active active  ...
# ^ the kubelet maps pod QoS (guaranteed/burstable/besteffort) onto cgroup slices

$ systemctl is-active kubelet ; systemctl is-enabled kubelet
active
enabled

$ systemctl status kubelet        # (trimmed)
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/lib/systemd/system/kubelet.service; enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) since Sun 2026-10-25 22:15:32 UTC; 2 days ago
   Main PID: 10677 (kubelet)
     CGroup: /system.slice/kubelet.service
             └─10677 /usr/bin/kubelet --kubeconfig=/etc/kubernetes/kubelet.conf \
                     --config=/var/lib/kubelet/config.yaml ...

$ sudo journalctl -u kubelet -n 3 --no-pager
Oct 27 12:14:04 cp kubelet[10677]: E1027 ... "Error on socket receive" ...
Oct 27 13:10:31 cp kubelet[10677]: W1027 ... watcher.go:95 Error while processing event ...

$ systemctl is-active containerd
active
```

That `Drop-In: 10-kubeadm.conf` line is the proof kubeadm configured the kubelet
via a systemd drop-in, not by editing the base unit.

## Commands to remember

```bash
# discover services on the node (find kubelet/containerd, spot failures)
systemctl list-units --type=service --state=running   # what's running now
systemctl list-unit-files | grep -E 'kubelet|containerd'  # enabled at boot?
systemctl list-units --state=failed                   # what's broken?

# SCOPED to kubernetes — systemctl takes a glob PATTERN argument (cleaner than grep):
systemctl list-units 'kube*' 'containerd*' --type=service   # just kubelet + containerd
systemctl list-units 'kube*' 'containerd*' --all            # include inactive too
systemctl list-units 'cri-containerd-*'                     # the per-container scopes
systemctl list-units 'kubepods-*.slice'                     # the pod cgroup slices (QoS)

# is the node agent up? why not?
systemctl status kubelet
sudo journalctl -u kubelet -n 50 --no-pager   # recent logs
sudo journalctl -u kubelet -f                 # follow live

# the runtime (kubelet talks to it via CRI)
systemctl status containerd

# after fixing /var/lib/kubelet/config.yaml or kubeadm-flags.env:
sudo systemctl daemon-reload      # if you changed a unit/drop-in
sudo systemctl restart kubelet

# see the effective command + drop-in kubeadm added
systemctl cat kubelet
```

## Gotchas / failure modes

- **`kubectl` won't help here.** kubelet/containerd are *below* the API server.
  Use `systemctl`/`journalctl`/`crictl`, not kubectl.
- **swap turned back on** → kubelet refuses to start; `journalctl` says so. `swapoff -a`.
- **cgroup driver mismatch** (containerd vs kubelet, must both be `systemd`) → kubelet
  starts then crash-loops. Seen in `journalctl -u kubelet`.
- **Edited a unit/drop-in but forgot `systemctl daemon-reload`** → your change isn't
  picked up.
- **`crictl` vs `kubectl`:** when the API is down, `crictl ps` (talks to containerd
  directly) shows if the static-pod containers are actually running.

## 30-second self-test

1. Is the kubelet a pod or a Linux process? → a **systemd-managed Linux process**
   (`kubelet.service`), not a pod.
2. Node `NotReady` and `kubectl` is unhelpful — two commands? →
   `systemctl status kubelet` + `journalctl -u kubelet`.
3. Where's the kubelet's config (cgroup driver etc.)? → `/var/lib/kubelet/config.yaml`.
4. How did kubeadm configure the kubelet? → a systemd **drop-in**
   (`/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf`).
5. After editing a kubelet unit/drop-in, what before restart? → `systemctl daemon-reload`.

---

See also: [`notes-cluster-architecture-diagram.md`](notes-cluster-architecture-diagram.md)
(static pods), [`notes-interacting-with-control-plane.md`](notes-interacting-with-control-plane.md),
[`../05-troubleshooting/notes-troubleshooting.md`](../05-troubleshooting/notes-troubleshooting.md).
