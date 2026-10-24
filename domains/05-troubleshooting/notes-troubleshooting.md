# Troubleshooting — study notes (first principles)

🎯 **Exam scope:** Troubleshooting — **30%**, the single biggest domain. Most
tasks are "something is broken, make it work." Speed comes from a fixed triage
order, not from memorizing fixes.

> Run the hands-on break/fix exercises on the kubeadm VM cluster
> ([`../../environment/vagrant-kubeadm/`](../../environment/vagrant-kubeadm/)) —
> only real systemd nodes let you practice `journalctl -u kubelet` and static-pod
> recovery.

---

## 0. The universal triage order

```
   ┌──────────────────────────────────────────────────────────────┐
   │  1. WHAT layer?   cluster / node / control-plane / workload    │
   │  2. GET state     kubectl get <thing> -o wide                  │
   │  3. DESCRIBE      kubectl describe <thing>  → read EVENTS       │
   │  4. LOGS          kubectl logs  /  journalctl -u kubelet        │
   │  5. RUNTIME       crictl ps / crictl logs   (node-level)        │
   └──────────────────────────────────────────────────────────────┘

   Events first. 80% of exam problems announce themselves in
   `kubectl describe ... | grep -A15 Events`.
```

---

## 1. Node NotReady

```
   kubectl get nodes          → one node NotReady

   Causes, in order of likelihood:
     kubelet down/misconfigured   → systemctl status kubelet ; journalctl -u kubelet
     CNI not installed/healthy    → kubectl get pods -n kube-system (calico/flannel)
     container runtime down       → systemctl status containerd
     disk/memory pressure         → kubectl describe node <n> | grep -A10 Conditions
```

Commands (run **on the node**, systemd realism):
```bash
systemctl status kubelet          # is it running?
sudo journalctl -u kubelet -n 50 --no-pager   # why did it fail?
systemctl status containerd
sudo systemctl restart kubelet    # after fixing config
```

Common kubelet failure causes on the exam:
- bad `--config` / `/var/lib/kubelet/config.yaml` edit
- swap turned back on (kubelet refuses to start) → `swapoff -a`
- wrong cgroup driver vs containerd → both must be `systemd`
- certificate expired → `kubeadm certs check-expiration`

---

## 2. Control-plane down (static pods)

The control plane runs as **static pods** from `/etc/kubernetes/manifests/`. If
`kubectl` itself fails with `connection refused`, the API server is down.

```
   /etc/kubernetes/manifests/
     etcd.yaml
     kube-apiserver.yaml            ← break this = whole API down
     kube-controller-manager.yaml
     kube-scheduler.yaml

   kubelet watches this dir. Edit a manifest → kubelet restarts that pod.
   There is NO kubectl to fix these; edit the YAML on disk directly.
```

Triage when `kubectl` won't connect:
```bash
sudo crictl ps                     # are apiserver/etcd containers running?
sudo crictl logs <container-id>    # why did a control-plane container crash?
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml   # look for the bad edit
sudo journalctl -u kubelet -n 50   # kubelet logs why it can't start the static pod
```
Classic breaks: wrong `--etcd-servers`, bad flag/typo in the apiserver manifest,
wrong image tag, wrong `hostPath`. Fix the YAML → kubelet recreates the pod.

---

## 3. Pod not running — decode the STATUS

```
   kubectl get pod → STATUS tells you where to look:

   Pending            → not scheduled. describe → Events:
                          "untolerated taint" | "didn't match node affinity"
                          | "Insufficient cpu/memory"
   ContainerCreating  → stuck pulling image / mounting volume / CNI
   ImagePullBackOff   → bad image name/tag or registry auth
   CrashLoopBackOff   → container starts then dies → kubectl logs (and --previous)
   Error / Completed  → check logs; maybe the command exited
   Running 0/1        → started but failing readiness probe
```

Commands:
```bash
kubectl describe pod <p> | grep -A15 Events
kubectl logs <p>                 # current container
kubectl logs <p> --previous      # the crashed instance (CrashLoopBackOff)
kubectl logs <p> -c <container>  # multi-container pod
```

---

## 4. Service / networking not reachable

```
   Pod works but Service doesn't?  Check the chain:

   Service ──selector──▶ Pods ──▶ Endpoints
      │                              │
      └── no Endpoints? → selector doesn't match pod labels (most common)
```
```bash
kubectl get svc <s>
kubectl get endpoints <s>        # EMPTY = selector/label mismatch
kubectl get pods --show-labels   # do labels match the svc selector?
kubectl describe svc <s>
# DNS test from inside a pod:
kubectl run t --image=busybox --rm -it --restart=Never -- nslookup <svc>.<ns>
```
CoreDNS down → every in-cluster name fails: `kubectl get pods -n kube-system -l k8s-app=kube-dns`.

---

## 5. crictl — the node-level runtime tool

When the API is down or a pod never reaches the API, inspect the runtime directly
(on the node). `crictl` talks to containerd like a low-level `kubectl`.

```bash
sudo crictl ps                 # running containers
sudo crictl ps -a              # include exited (find the crasher)
sudo crictl logs <container>   # container logs without the API server
sudo crictl images            # is the image even pulled?
sudo crictl pods               # pod sandboxes
```

---

## 6. Resource exhaustion

```bash
kubectl top nodes              # needs metrics-server
kubectl top pods -A
kubectl describe node <n> | grep -A10 "Allocated resources"
# on the node:
free -h ; df -h ; top
```
`Insufficient cpu/memory` in Pending events = no node has room, not a config bug.
`disk-pressure` / `memory-pressure` node taints come from here.

---

## 7. Exam-speed checklist

```
 kubectl won't connect        → API server static pod (crictl ps, manifest, kubelet logs)
 node NotReady                → kubelet / CNI / containerd (journalctl -u kubelet)
 pod Pending                  → describe → Events (taint / affinity / resources)
 CrashLoopBackOff             → kubectl logs --previous
 ImagePullBackOff             → image name/tag/registry auth
 Service has no endpoints     → selector vs pod labels
 DNS fails                    → CoreDNS pods in kube-system
```

Back to [domain index](README.md) · [repo index](../../README.md).
