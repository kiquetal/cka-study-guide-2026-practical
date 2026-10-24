#!/usr/bin/env bash
# common.sh — runs on EVERY node (control-plane + workers).
# Installs containerd + kubeadm/kubelet/kubectl and does the required host prep.
#
# --- How to bump the Kubernetes version ---------------------------------
# Change K8S_MINOR below (e.g. v1.31 -> v1.32). The pkgs.k8s.io repo is keyed by
# the minor version. Then `vagrant destroy -f && vagrant up` to rebuild.
set -euxo pipefail

K8S_MINOR="v1.31"   # <-- pinned Kubernetes minor version

echo "[common] Disabling swap (kubelet requires it off)"
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab || true

echo "[common] Loading kernel modules for container networking"
cat <<'EOF' >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "[common] Sysctl params for Kubernetes networking"
cat <<'EOF' >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

echo "[common] Installing containerd"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg apt-transport-https containerd

echo "[common] Configuring containerd with systemd cgroup driver"
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

echo "[common] Adding the Kubernetes apt repo (${K8S_MINOR})"
mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /" \
  >/etc/apt/sources.list.d/kubernetes.list

echo "[common] Installing kubelet, kubeadm, kubectl (version-locked)"
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

echo "[common] Done."
