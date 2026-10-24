# kind — Fast Disposable Cluster

[kind](https://kind.sigs.k8s.io/) ("Kubernetes IN Docker") runs cluster nodes as
Docker containers. It boots in seconds and is perfect for quick experiments:
workloads, networking, storage, and **Istio Ambient**.

> **Realism caveat:** kind nodes are containers, not VMs with systemd. You will **not**
> practice `journalctl -u kubelet`, static-pod recovery, or real `kubeadm` node joins
> here. For exam-style cluster troubleshooting use
> [`../vagrant-kubeadm/`](../vagrant-kubeadm/) instead.

## Prerequisites

- Docker (or Podman) installed and running.
- `kind` and `kubectl` on your PATH.

```bash
# kind (Linux amd64)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl
```

## Create / use / destroy

```bash
# Create the 3-node cluster defined in kind-cluster.yaml
kind create cluster --name cka-lab --config kind-cluster.yaml

# kubectl context is set automatically to kind-cka-lab
kubectl get nodes          # expect 1 control-plane + 2 workers, all Ready
kubectl cluster-info

# Tear it down completely (removes the containers)
kind delete cluster --name cka-lab
```

## Notes

- Change the Kubernetes version by editing the `image:` tag in
  [`kind-cluster.yaml`](kind-cluster.yaml) (see the kind releases page for valid
  `kindest/node` images).
- The `extraPortMappings` expose host ports 8080/8443 for later Ingress/Gateway API labs.

Back to [environment overview](../README.md) · [repo index](../../README.md).
