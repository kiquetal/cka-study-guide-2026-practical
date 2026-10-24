#!/usr/bin/env bash
# control-plane.sh — runs ONLY on the control-plane node.
# Runs `kubeadm init`, installs the Calico CNI, and writes a join command that the
# workers pick up from the shared /vagrant folder.
set -euxo pipefail

: "${CONTROL_PLANE_IP:?CONTROL_PLANE_IP must be set by the Vagrantfile}"
: "${POD_CIDR:?POD_CIDR must be set by the Vagrantfile}"

CALICO_VERSION="v3.28.0"

echo "[cp] Running kubeadm init (advertise ${CONTROL_PLANE_IP}, pod CIDR ${POD_CIDR})"
kubeadm init \
  --apiserver-advertise-address="${CONTROL_PLANE_IP}" \
  --pod-network-cidr="${POD_CIDR}"

echo "[cp] Setting up kubeconfig for the vagrant user"
mkdir -p /home/vagrant/.kube
cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
# Also for root so `sudo kubectl` works in-node.
export KUBECONFIG=/etc/kubernetes/admin.conf

echo "[cp] Installing Calico CNI (${CALICO_VERSION})"
kubectl apply -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml"

echo "[cp] Generating a join command for workers (shared via /vagrant)"
kubeadm token create --print-join-command >/vagrant/join-command.sh
chmod +x /vagrant/join-command.sh

echo "[cp] Control plane ready. Run 'kubectl get nodes' after workers join."
