# Using the lab cluster with `kubectl` — safely (don't break your real contexts)

🎯 Practical setup note. How to point `kubectl` at the `vagrant-kubeadm` lab
cluster **without** touching the kubeconfig that already holds your real clusters.

> ⚠️ **Why this matters for you specifically:** your host `~/.kube/config`
> already contains **live AWS EKS contexts** (prod-looking clusters across
> several accounts) plus others. If you overwrite or carelessly merge into that
> file, you can lose access to real clusters or — worse — run a lab command
> against the wrong (real) cluster. Every method below keeps the lab **isolated**
> from that file.

---

## The one rule

**Never `cp admin.conf ~/.kube/config`.** That overwrites your existing contexts.
Keep the lab kubeconfig in its **own file** and select it explicitly. When in
doubt, check `kubectl config current-context` before you run anything.

---

## How `kubectl` decides which cluster to talk to

`kubectl` finds its config in this order:

1. `--kubeconfig <file>` flag (highest priority)
2. `$KUBECONFIG` environment variable (can be one path or several `:`-joined)
3. `~/.kube/config` (the default — **this is your EKS file, leave it alone**)

We'll use #1 and #2 to keep the lab separate.

---

## Method A — Dedicated lab kubeconfig (recommended, safest)

Keep the lab config in its own file and point at it only when you want the lab.

### Which file do I copy, and from where?

- **The file lives on the control-plane (`cp`), at `/home/vagrant/.kube/config`.**
  It is a copy of `/etc/kubernetes/admin.conf`, which `kubeadm init` generated —
  the cluster's **admin** kubeconfig (full god-mode credentials).
- You copy **that one file** to your Pop!_OS host, into a **separate** path
  (`~/.kube/cka-lab.config`) so it never overwrites your real `~/.kube/config`.
- Workers (`worker1`/`worker2`) do **not** have this file — that's why `kubectl`
  only works from `cp` or your host, never from a worker.

```bash
# One-time: pull the admin kubeconfig off the control-plane into a SEPARATE file
cd /mydata/codes/2026/cka-study-guide-2026-practical/environment/vagrant-kubeadm
sg libvirt -c "vagrant ssh cp -c 'cat /home/vagrant/.kube/config'" \
  | grep -v -E 'Unrecognized|^\[fog\]' > ~/.kube/cka-lab.config
chmod 600 ~/.kube/cka-lab.config      # it holds admin creds — treat as a secret
```

> **Re-copy after a rebuild:** if you `vagrant destroy` + `vagrant up` the lab,
> the cluster CA is regenerated, so the old `cka-lab.config` stops working. Just
> run the copy command above again to refresh it.

Use it per-command (nothing persists, zero risk to your default config):

```bash
kubectl --kubeconfig ~/.kube/cka-lab.config get nodes -o wide
```

Or for a whole terminal session:

```bash
export KUBECONFIG=~/.kube/cka-lab.config
kubectl get nodes          # this shell only; new shells still use the default
kubectl config current-context   # verify: should be kubernetes-admin@kubernetes
```

Close the terminal (or `unset KUBECONFIG`) and you're back to your normal config.
**Your `~/.kube/config` is never modified.**

> Handy alias — add to `~/.bashrc` so `kcka` means "kubectl against the lab":
> ```bash
> alias kcka='kubectl --kubeconfig ~/.kube/cka-lab.config'
> ```
> Then just: `kcka get pods -A`

---

## Method B — Run `kubectl` inside the control-plane (exam-realistic)

No host config involved at all. This is also how the real CKA exam works: you SSH
to a node and run `kubectl` there.

```bash
cd /mydata/codes/2026/cka-study-guide-2026-practical/environment/vagrant-kubeadm
sg libvirt -c "vagrant ssh cp"
# inside cp:
kubectl get nodes          # ~/.kube/config already set up on the node
```

Downside: no host editor/clipboard integration. Good for drilling exam reflexes.

---

## Method C — Merge as an extra context (only if you really want one file)

You *can* keep everything in `~/.kube/config` as separate contexts and switch
between lab and EKS. This touches the shared file, so do it carefully with a
backup. **Method A is safer** — prefer it unless you specifically want
`kubectl config use-context` switching.

```bash
cp ~/.kube/config ~/.kube/config.backup.$(date +%Y%m%d)   # ALWAYS back up first

# Temporarily merge the lab file into a combined view and flatten it out:
KUBECONFIG=~/.kube/config:~/.kube/cka-lab.config \
  kubectl config view --flatten > ~/.kube/config.merged
mv ~/.kube/config.merged ~/.kube/config

kubectl config get-contexts                      # lab shows as kubernetes-admin@kubernetes
kubectl config use-context kubernetes-admin@kubernetes   # switch to lab
kubectl config use-context auth-ext              # switch back to your real one
```

If anything looks wrong: `cp ~/.kube/config.backup.YYYYMMDD ~/.kube/config`.

---

## Prerequisites (already true on this host, verified)

- **Reachability:** your Pop!_OS host is the libvirt gateway, so it can reach the
  API server. The kubeconfig points at `https://192.168.56.10:6443` (the API
  advertise IP on the `vagrant-kubeadm0` net — see
  [`notes-libvirt-nat-and-node-ips.md`](notes-libvirt-nat-and-node-ips.md)).
- **Client:** `kubectl` is installed on the host. (It was v1.30 vs the v1.37
  cluster — reads work fine; bump to v1.37 if you hit warnings on newer resources.)

---

## Where do the context / cluster / user names come from?

You never typed these names and neither did I — **`kubeadm init` generated them**
when the control plane was created. The admin kubeconfig it writes to
`/etc/kubernetes/admin.conf` (copied to `~/.kube/config` on `cp`) always uses the
same defaults:

| Thing | Name in this lab | Who set it |
|-------|------------------|------------|
| **cluster** | `kubernetes` | kubeadm default |
| **user** (AuthInfo) | `kubernetes-admin` | kubeadm default |
| **context** | `kubernetes-admin@kubernetes` | kubeadm default |

A **context** is just a named pairing of *(cluster + user [+ optional namespace])*.
The naming convention is `<user>@<cluster>`, which is why kubeadm's admin context
reads `kubernetes-admin@kubernetes` — the `kubernetes-admin` user talking to the
`kubernetes` cluster.

See it yourself (names come straight from the kubeconfig YAML):

```bash
kcka config get-contexts        # table: CURRENT / NAME / CLUSTER / AUTHINFO / NAMESPACE
kcka config current-context     # -> kubernetes-admin@kubernetes
kcka config view --minify       # the full cluster+user+context for the active one
```

In the YAML this is three top-level lists that reference each other by name:

```yaml
clusters:
- name: kubernetes                 # <- the cluster
  cluster: { server: https://192.168.56.10:6443, certificate-authority-data: ... }
users:
- name: kubernetes-admin           # <- the user/credentials
  user: { client-certificate-data: ..., client-key-data: ... }
contexts:
- name: kubernetes-admin@kubernetes  # <- the context: binds the two above
  context: { cluster: kubernetes, user: kubernetes-admin }
current-context: kubernetes-admin@kubernetes   # <- which context kubectl uses now
```

> **Why your EKS contexts look different:** AWS names its contexts after the
> cluster ARN (`arn:aws:eks:us-east-1:...:cluster/...`). Tools pick their own
> naming — that's why the lab's short `kubernetes-admin@kubernetes` stands out
> clearly from your real clusters. That contrast is a feature: it makes
> `current-context` an instant "am I about to hit the lab or prod?" check.

**Renaming (optional):** if `kubernetes-admin@kubernetes` is too generic, rename
the context in *your* file (doesn't touch the cluster):

```bash
kubectl --kubeconfig ~/.kube/cka-lab.config config rename-context \
  kubernetes-admin@kubernetes cka-lab
# now: kcka config current-context  ->  cka-lab
```

---

## Safety checklist before running any command

1. **Know your context:** `kubectl config current-context`
   - Lab = `kubernetes-admin@kubernetes` (or `cka-lab` if you renamed it).
     Anything with `arn:aws:eks:...` is a **real** cluster — stop and switch
     before running test/destructive commands.
2. **Scope with `-n` / `--namespace`** so you don't touch `kube-system` by accident.
3. **Treat `cka-lab.config` as a secret** (`chmod 600`); don't commit it (the
   repo `.gitignore` should ignore kubeconfigs — verify).
4. **Destroy/rebuild the lab freely** (`vagrant destroy -f && vagrant up`). It's
   disposable; your real clusters are not.

---

## TL;DR

```bash
# Safest everyday workflow:
sg libvirt -c "vagrant ssh cp -c 'cat /home/vagrant/.kube/config'" \
  | grep -v -E 'Unrecognized|^\[fog\]' > ~/.kube/cka-lab.config
chmod 600 ~/.kube/cka-lab.config
alias kcka='kubectl --kubeconfig ~/.kube/cka-lab.config'   # add to ~/.bashrc
kcka get nodes -o wide
```

Your `~/.kube/config` (with the EKS contexts) stays untouched. ✅
