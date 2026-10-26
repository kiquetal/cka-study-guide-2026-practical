# memory-muscle.md — compact one-liners to drill into reflex (exam d-day)

🎯 Cross-domain speed reference. One line per command: **what it does → the command**.
Goal: zero thinking on exam day. Drill until your fingers type these without you.

> How to use: cover the right column, read the left, type it from memory. Repeat
> daily. The exam is 2h/~17 tasks — seconds saved here add up to a passed task.

---

## Setup first (do this at the START of the exam, once)

| Goal | Line |
|------|------|
| Alias + enable completion (saves thousands of keystrokes) | `alias k=kubectl; source <(kubectl completion bash); complete -o default -F __start_kubectl k` |
| Fast dry-run → yaml var | `export do="--dry-run=client -o yaml"` |
| Fast force-delete var | `export now="--force --grace-period=0"` |
| Set namespace for the task (stop typing -n) | `k config set-context --current --namespace=<ns>` |

## Context / kubeconfig (know where you are)

| Goal | Line |
|------|------|
| Which cluster am I on? | `k config current-context` |
| List all contexts | `k config get-contexts` |
| Switch cluster | `k config use-context <ctx>` |
| See active cluster+user+ns only | `k config view --minify` |
| Use a specific kubeconfig for one cmd | `k --kubeconfig <file> get nodes` |
| Rename a context | `k config rename-context <old> <new>` |

> **Context model (memorize):** a *context* = *cluster + user + namespace*.
> Name convention `<user>@<cluster>`. `kubeadm init` makes
> `kubernetes-admin@kubernetes` by default.

## Generate YAML fast (never hand-write boilerplate)

| Goal | Line |
|------|------|
| Pod manifest | `k run nginx --image=nginx $do > pod.yaml` |
| Deployment manifest | `k create deploy web --image=nginx --replicas=3 $do > deploy.yaml` |
| Service (ClusterIP) for a deploy | `k expose deploy web --port=80 $do > svc.yaml` |
| Job / CronJob | `k create job j --image=busybox $do -- sleep 5` / `k create cronjob c --image=busybox --schedule="*/1 * * * *" $do -- date` |
| ConfigMap / Secret | `k create cm cfg --from-literal=k=v $do` / `k create secret generic s --from-literal=p=x $do` |
| Role / RoleBinding | `k create role r --verb=get,list --resource=pods $do` / `k create rolebinding rb --role=r --user=jane $do` |
| ServiceAccount | `k create sa build $do` |

## Inspect / debug (the -o wide + describe reflex)

| Goal | Line |
|------|------|
| Where did it land / what IP | `k get pods -o wide` |
| Everything in a ns | `k get all -n <ns>` |
| Why is it broken (events at bottom) | `k describe pod <p>` |
| Logs (prev crash) | `k logs <p> --previous` |
| Shell into a pod | `k exec -it <p> -- sh` |
| Sort pods by restarts | `k get pods -A --sort-by=.status.containerRestarts` |
| One field via jsonpath | `k get po <p> -o jsonpath='{.status.podIP}'` |
| Watch until Ready | `k get pods -w` |

## Troubleshooting (30% — highest weight, drill hardest)

| Goal | Line |
|------|------|
| Node not Ready — kubelet logs | `journalctl -u kubelet -f` |
| Node not Ready — kubelet status | `systemctl status kubelet` |
| Control-plane static pods (on cp) | `ls /etc/kubernetes/manifests/` |
| Is the API server up (crictl) | `sudo crictl ps | grep apiserver` |
| Service has no endpoints? (selector bug) | `k get endpoints <svc>` |
| Can this SA/user do X? | `k auth can-i <verb> <resource> --as=<user>` |
| Resource usage | `k top nodes` / `k top pods` |

## Nodes / scheduling

| Goal | Line |
|------|------|
| Cordon (no new pods) | `k cordon <node>` |
| Drain for maintenance | `k drain <node> --ignore-daemonsets --delete-emptydir-data` |
| Uncordon | `k uncordon <node>` |
| Taint / untaint | `k taint nodes <n> key=val:NoSchedule` / `...:NoSchedule-` |
| Label a node | `k label node <n> disk=ssd` |

## kubeadm cluster lifecycle (25%)

| Goal | Line |
|------|------|
| Fresh worker join command (on cp) | `kubeadm token create --print-join-command` |
| Join a worker (on worker) | `sudo kubeadm join <API>:6443 --token ... --discovery-token-ca-cert-hash sha256:...` |
| Reset a node to redo a join | `sudo kubeadm reset -f` |
| Upgrade plan | `sudo kubeadm upgrade plan` |
| etcd snapshot save | `ETCDCTL_API=3 etcdctl snapshot save snap.db --cacert ... --cert ... --key ...` |
| etcd snapshot restore | `ETCDCTL_API=3 etcdctl snapshot restore snap.db --data-dir /var/lib/etcd-new` |

## Storage (10%)

| Goal | Line |
|------|------|
| PVCs and their PVs/status | `k get pvc,pv` |
| Why PVC Pending (events) | `k describe pvc <name>` |
| StorageClasses | `k get sc` |

## Imperative time-savers

| Goal | Line |
|------|------|
| Scale | `k scale deploy web --replicas=5` |
| Set image (rollout) | `k set image deploy/web web=nginx:1.27` |
| Rollout status / undo | `k rollout status deploy/web` / `k rollout undo deploy/web` |
| Edit live | `k edit deploy web` |
| Delete fast | `k delete pod <p> $now` |
| Apply from stdin | `k apply -f -` (then paste/heredoc) |

---

## The 5 reflexes that save the most time

1. **`alias k=kubectl` + completion** — do it first, every exam.
2. **`$do` dry-run → edit → apply** — never hand-write YAML from scratch.
3. **`k config current-context` before any destructive command** — wrong cluster = lost task.
4. **`-o wide` then `describe`** — your universal "what's wrong" probe.
5. **Set the namespace once** (`set-context --namespace`) — stop typing `-n` all task.

> Allowed in the exam: **kubernetes.io docs**. Bookmark "kubeadm", "kubectl
> Cheat Sheet", and the jsonpath reference. Knowing *where* beats memorizing *all*.
