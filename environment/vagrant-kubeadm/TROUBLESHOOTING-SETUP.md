# Troubleshooting the Vagrant Setup (Pop!_OS 24.04 "noble")

Real problems hit while bringing up this lab **after upgrading the host OS to
Pop!_OS 24.04 LTS (Ubuntu 24.04 "noble" base)**, and how each was fixed. Keep this
next to the lab so a future re-setup is quick.

> Context: the host was upgraded to 24.04. The old distro `vagrant` package and a
> half-migrated `~/.vagrant.d` from a previous install left the toolchain in a
> broken state. None of these are problems with the lab's `Vagrantfile` or
> `provision/*.sh` — those were correct throughout.

---

## 1. `vagrant` crashes with a RubyGems version conflict

**Symptom** — every `vagrant` command (even `vagrant status`) aborts with:

```
rubygems/resolver/conflict.rb:...: undefined method `request' for nil:NilClass (NoMethodError)
Unable to satisfy the following requirements: (Gem::Resolver::Molinillo::VersionConflict)
- `vagrant (= 2.2.19)` required by `user-specified dependency`
```

**Root cause** — version mismatch between the binary and the plugin state:

- The distro package provided **Vagrant 2.2.19** (Ruby 3.2) on `/usr/bin/vagrant`.
- But `~/.vagrant.d/plugins.json` + `~/.vagrant.d/gems/3.3.8/` were created by a
  newer **Vagrant 2.4.9** (Ruby 3.3.8) install, pinning `vagrant-libvirt 0.12.2`.
- The old binary tried to load the newer plugin state and the gem resolver blew up.

**Fix** — install the Vagrant version the plugin state already expects (2.4.9).
HashiCorp dropped the distro's old version; use **HashiCorp's apt repo** (see §2–§4),
then confirm:

```bash
vagrant --version        # Vagrant 2.4.9
vagrant plugin list      # vagrant-libvirt (0.12.2, global)
vagrant status           # lists cp / worker1 / worker2 as "not created"
```

> Alternative (not used): wipe `~/.vagrant.d` and stay on the old distro Vagrant
> 2.2.19. Rejected — 2.2.19 is from 2021 and the plugin state was already built for
> 2.4.9, so matching the binary to it was cleaner.

---

## 2. HashiCorp apt repo — key endpoint rotated / stale keyring

**Symptom** — `apt-get update` fails on the HashiCorp repo:

```
NO_PUBKEY FC9CA96ACA026560
E: The repository 'https://apt.releases.hashicorp.com noble InRelease' is not signed.
```

**Root cause** — HashiCorp **rotated their signing key** (the current one was created
`2026-09-09`, fingerprint `D55C0D1AC78A8D8126CB631CFC9CA96ACA026560`, whose short id
is `FC9CA96ACA026560`). The keyring on disk was an older key that didn't include it.

**Fix** — re-fetch the current key to a temp file first, then move it into place
(avoids `sudo tee` piping quirks):

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg -o /tmp/hashicorp.asc
gpg --dearmor < /tmp/hashicorp.asc > /tmp/hashicorp.gpg
sudo cp /tmp/hashicorp.gpg /usr/share/keyrings/hashicorp-archive-keyring.gpg

# verify the right key is present (prints the fingerprint ending FC9CA96ACA026560):
gpg --show-keys /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

---

## 3. Malformed `sources.list.d/hashicorp.list` (line-wrap on paste)

**Symptom**:

```
E: Malformed entry 1 in list file /etc/apt/sources.list.d/hashicorp.list (URI)
E: The list of sources could not be read.
```

**Root cause** — pasting the long `deb [...] https://... noble main` line into the
terminal wrapped it across **two lines**, splitting the entry before the URL.

**Fix** — write it as exactly ONE line, then confirm with `wc -l` (must print `1`):

```bash
echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com noble main' \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
wc -l /etc/apt/sources.list.d/hashicorp.list   # must be 1
```

> Lesson: long one-liners that must not wrap are fragile to paste. Prefer writing the
> file directly, or build the string from short shell variables.

---

## 4. Clean install sequence (what finally worked)

```bash
# 0. remove the conflicting distro vagrant (binary only; repo + ~/.vagrant.d stay)
sudo apt-get remove -y vagrant

# 1. current HashiCorp signing key (see §2)
curl -fsSL https://apt.releases.hashicorp.com/gpg -o /tmp/hashicorp.asc
gpg --dearmor < /tmp/hashicorp.asc > /tmp/hashicorp.gpg
sudo cp /tmp/hashicorp.gpg /usr/share/keyrings/hashicorp-archive-keyring.gpg

# 2. the apt source, as ONE line (see §3)
echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com noble main' \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

# 3. install
sudo apt-get update
sudo apt-get install -y vagrant
vagrant --version        # Vagrant 2.4.9
```

---

## 5. In-VM DNS failure during provisioning (`Temporary failure resolving`)

**Symptom** — `vagrant up cp` gets into the VM but `common.sh` aborts at `apt-get`:

```
cp: Err:... https://mirrors.edge.kernel.org/ubuntu ...
cp:   Temporary failure resolving 'mirrors.edge.kernel.org'
cp: E: Unable to fetch some archives ...
The SSH command responded with a non-zero exit status.
```

**Root cause** — the `generic/ubuntu2204` box's `systemd-resolved` points at flaky
hardcoded DNS. `common.sh` already pins a static `/etc/resolv.conf` (libvirt gateway
+ public resolvers), but the box's **Ubuntu mirror host itself**
(`mirrors.edge.kernel.org`) can still intermittently fail to resolve from inside the
VM even after that, if the libvirt NAT gateway guess is wrong for your network.

**Fixes to try, in order:**

1. **Just re-run provisioning** — transient DNS/mirror blips are common; the second
   pass often succeeds:
   ```bash
   vagrant provision cp
   ```
2. **Confirm the gateway guess inside the VM** — `common.sh` writes the default route
   as the first nameserver. Verify it's correct:
   ```bash
   vagrant ssh cp -c 'ip route | grep default; cat /etc/resolv.conf; getent hosts mirrors.edge.kernel.org'
   ```
   If `getent` returns nothing, DNS is still broken — re-apply resolv.conf by hand
   (use the actual gateway from `ip route`) and re-run `apt-get update`:
   ```bash
   vagrant ssh cp
   sudo tee /etc/resolv.conf >/dev/null <<'EOF'
   nameserver 192.168.121.1   # <- your libvirt NAT gateway (adjust!)
   nameserver 1.1.1.1
   nameserver 8.8.8.8
   options timeout:2 attempts:3
   EOF
   sudo apt-get update
   ```
3. **If the box mirror is the problem**, it's a transient upstream issue — wait and
   retry, or re-provision later.

> Status at time of writing: `vagrant up cp` reached provisioning but aborted here on
> a DNS/mirror blip. The toolchain (§1–§4) is fixed; this is a per-run network issue,
> not a config bug. Re-run `vagrant provision cp` (or the full `vagrant up`) to
> continue.

---

## 6. Quick health check once it's up

```bash
vagrant ssh cp -c 'kubectl get nodes -o wide'
# expect cp + worker1 + worker2 all Ready (give Calico ~1-2 min)
vagrant ssh cp -c 'kubectl get pods -n kube-system'
```

---

## 7. DNS reverts to the systemd-resolved stub (root cause of §5)

**Symptom** — even though `common.sh` writes a static `/etc/resolv.conf`, inside the
running VM it is back to:

```
nameserver 127.0.0.53
options edns0 trust-ad
```

and `getent hosts mirrors.edge.kernel.org` returns nothing (`RESOLVE FAILED`), so
`apt-get` aborts provisioning.

**Root cause** — on the `generic/ubuntu2204` box `/etc/resolv.conf` is a **symlink
managed by `systemd-resolved`**. `common.sh` does `cat >/etc/resolv.conf`, which
writes *through* the symlink; systemd-resolved then rewrites it back to its stub
resolver (`127.0.0.53`). That stub has no working upstream on this libvirt network,
so every lookup fails. The gateway DNS itself is fine — proven by:

```bash
# inside the VM, these BOTH resolve correctly:
nslookup mirrors.edge.kernel.org 192.168.121.1   # libvirt NAT gateway dnsmasq
nslookup mirrors.edge.kernel.org 1.1.1.1
```

**Fix (applied live, per node)** — replace the symlink with a real static file that
points at the libvirt gateway + public fallbacks, then re-provision:

```bash
vagrant ssh <node> -c 'sudo rm -f /etc/resolv.conf && printf "nameserver 192.168.121.1\nnameserver 1.1.1.1\nnameserver 8.8.8.8\noptions timeout:2 attempts:3\n" | sudo tee /etc/resolv.conf >/dev/null && getent hosts pkgs.k8s.io && echo DNS OK'
vagrant provision <node>
```

> `192.168.121.1` is the `vagrant-libvirt` network's gateway on this host. Confirm
> yours with `virsh net-dumpxml vagrant-libvirt | grep "ip address"` (or
> `ip route | grep default` inside the VM — the gateway is the `via` address).
>
> Permanent fix (TODO in `common.sh`): `rm -f /etc/resolv.conf` to break the symlink
> *before* writing the static file, so systemd-resolved can't revert it.

---

## 8. Workers can't join — `/vagrant` synced folder not mounted

**Symptom** — the control-plane provisioning fails on its last step:

```
cp: /tmp/vagrant-shell: line 28: /vagrant/join-command.sh: No such file or directory
```

and each worker loops 60× then errors:

```
worker1: [worker] ERROR: join command never appeared. Did the control-plane finish provisioning?
```

**Root cause** — the handoff is file-based: `control-plane.sh` writes the join
command to `/vagrant/join-command.sh` and `worker.sh` waits for it there. But the
default `/vagrant` **synced folder is not mounted** under `vagrant-libvirt` on this
host (it needs NFS or a 9p/virtiofs driver that isn't active):

```bash
vagrant ssh cp -c 'mount | grep vagrant || echo "NO /vagrant MOUNT"'
# -> NO /vagrant MOUNT
```

So the control plane is actually healthy — `kubeadm init` + Calico succeeded; only
the file write failed. Everything after the error is fine.

**Fix (manual join, works today)** — pull the join command from the control plane and
run it on the worker by hand:

```bash
# 1. on the control plane, mint a fresh join command (tokens last 24h):
vagrant ssh cp -c 'kubeadm token create --print-join-command'
# -> kubeadm join 192.168.56.10:6443 --token <tok> --discovery-token-ca-cert-hash sha256:<hash>

# 2. make sure the worker has its binaries (fix DNS first — see §7 — then):
vagrant provision worker1   # installs containerd + kubeadm/kubelet/kubectl
# (it will still error at the /vagrant wait — that's expected; binaries are installed)

# 3. run the join on the worker by hand:
vagrant ssh worker1 -c 'sudo kubeadm join 192.168.56.10:6443 --token <tok> \
  --discovery-token-ca-cert-hash sha256:<hash>'

# 4. verify from the control plane (worker is NotReady ~1 min while Calico starts):
vagrant ssh cp -c 'kubectl get nodes -o wide'
```

> Proper fixes (TODO):
> - enable NFS synced folders in the `Vagrantfile`
>   (`config.vm.synced_folder ".", "/vagrant", type: "nfs"`, needs
>   `nfs-kernel-server` on the host), **or**
> - stop relying on `/vagrant`: have the control plane print the join command and
>   pass it to workers another way (e.g. a provisioner that reads it over SSH).

---

Back to [vagrant-kubeadm README](README.md) · [environment overview](../README.md)
· [repo index](../../README.md).
