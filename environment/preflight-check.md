# Preflight Check — Pop!_OS Lab Readiness

Run these **before** trying to stand up the kubeadm VM cluster. Pop!_OS is
Ubuntu/Debian-based, so these Debian commands apply directly.

---

## 1. CPU virtualization support (VT-x / AMD-V)

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

- **Output > 0** → your CPU supports hardware virtualization. Good.
- **Output = 0** → either your CPU lacks it, or it's **disabled in BIOS/UEFI**.
  Reboot into firmware settings and enable *Intel VT-x* / *AMD-V* (sometimes called
  "SVM Mode" or "Virtualization Technology"), then re-run.

## 2. KVM acceleration available

```bash
sudo apt-get update
sudo apt-get install -y cpu-checker
kvm-ok
```

Expected:

```
INFO: /dev/kvm exists
KVM acceleration can be used
```

If you see "KVM acceleration can NOT be used", revisit step 1 (BIOS virtualization).

---

## 3. Install the hypervisor + tooling

```bash
sudo apt-get update
sudo apt-get install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  bridge-utils \
  virt-manager
```

Add your user to the libvirt/kvm groups so you don't need sudo for VMs:

```bash
sudo usermod -aG libvirt "$USER"
sudo usermod -aG kvm "$USER"
# Log out and back in (or run `newgrp libvirt`) for group changes to apply.
```

Verify libvirt is running:

```bash
systemctl status libvirtd --no-pager
virsh list --all        # should run without error (likely empty list)
```

---

## 4. Install Vagrant + the libvirt provider

Vagrant from the Pop!_OS repos is fine; or use HashiCorp's apt repo for a newer build.

```bash
# Option A: distro package
sudo apt-get install -y vagrant

# Build deps for the libvirt plugin:
sudo apt-get install -y libvirt-dev ruby-dev gcc make

# The plugin that lets Vagrant drive libvirt/KVM:
vagrant plugin install vagrant-libvirt
```

Verify:

```bash
vagrant --version
vagrant plugin list        # should list vagrant-libvirt
```

---

## 5. Readiness checklist

- [ ] `egrep -c '(vmx|svm)' /proc/cpuinfo` returns > 0
- [ ] `kvm-ok` says KVM acceleration can be used
- [ ] `virsh list --all` runs without permission errors
- [ ] `vagrant plugin list` shows `vagrant-libvirt`

All four checked → head to
[`vagrant-kubeadm/`](vagrant-kubeadm/) to build the exam-realistic cluster, or
[`kind/`](kind/) for a quick disposable one.

---

Back to [environment overview](README.md) · [repo index](../README.md).
