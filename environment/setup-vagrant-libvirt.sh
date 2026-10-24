#!/usr/bin/env bash
#
# setup-vagrant-libvirt.sh
# Install + verify the vagrant-libvirt lab stack on Pop!_OS / Ubuntu 22.04.
#
# Verified on: Pop!_OS 22.04 LTS, Vagrant 2.4.9, libvirt 8.0.0 (2026-10-24).
# Idempotent: safe to re-run. Only installs what's missing.
#
# Usage:
#   ./environment/setup-vagrant-libvirt.sh
#
# After it finishes, group changes require a new login session:
#   newgrp libvirt      # (this shell only)  OR  log out/in
#
set -euo pipefail

echo "=== 1/4  apt packages (hypervisor + plugin build deps) ==="
sudo apt-get update
sudo apt-get install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  bridge-utils \
  vagrant \
  libvirt-dev \
  ruby-dev \
  gcc \
  make \
  pkg-config

echo "=== 2/4  vagrant-libvirt plugin ==="
if vagrant plugin list 2>/dev/null | grep -q vagrant-libvirt; then
  echo "vagrant-libvirt already installed — skipping."
else
  vagrant plugin install vagrant-libvirt
fi

echo "=== 3/4  user groups (libvirt + kvm) ==="
for grp in libvirt kvm; do
  if id -nG "$USER" | tr ' ' '\n' | grep -qx "$grp"; then
    echo "already in group: $grp"
  else
    sudo usermod -aG "$grp" "$USER"
    echo "added $USER to group: $grp  (needs new login to take effect)"
  fi
done

echo "=== 4/4  verify ==="
vagrant --version
vagrant plugin list
echo "groups: $(id -nG "$USER")"
virsh list --all

cat <<'EOF'

Done. Readiness checklist:
  [ ] vagrant plugin list  shows  vagrant-libvirt
  [ ] groups               include  libvirt  and  kvm   (re-login if just added)
  [ ] virsh list --all     runs with no permission error

Next:
  cd environment/vagrant-kubeadm && vagrant up --provider=libvirt
EOF
