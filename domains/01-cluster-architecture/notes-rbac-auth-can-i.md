# RBAC verification — `kubectl auth can-i` (and `--list`)

🎯 **Domain 01 — Cluster Architecture (25%), "Manage RBAC".** After you create a
Role/RoleBinding, `kubectl auth can-i` is how you **prove** it works — for your own
identity or, via impersonation, for any user/group/ServiceAccount.

---

## The idea (theory)

`kubectl auth can-i <verb> <resource>` asks the API server's authorization layer
"is this action allowed?" and answers **yes/no** — without you actually doing the
action. It's the RBAC equivalent of a dry-run permission check.

- **Default:** checks *your current* identity (the kubeconfig user).
- **`--as` / `--as-group`:** impersonate someone else and check *their* access.
- **`--list`:** dump the full table of what an identity can do.

## Why is this relevant?

- 🎯 **For the exam:** "create a Role/RoleBinding for user X, then verify" is a
  classic RBAC task. The verify step is `auth can-i ... --as=X`. Without it you're
  guessing whether your binding worked.
- 🌍 **Real-world / edge cases — strange behaviour this explains:**
  - A pod's app gets `Forbidden` (403) from the API → its **ServiceAccount** lacks
    RBAC. Reproduce instantly: `can-i <verb> <res> --as=system:serviceaccount:<ns>:<sa>`.
  - "It works for me but not for them" → you're admin; *they* aren't. `--as` shows
    the difference without logging in as them.
  - A new ServiceAccount can do **nothing** until you bind a Role to it (verified below).

---

## Key parts

| Form | What it checks |
|------|----------------|
| `kubectl auth can-i create pods` | current identity, one action → `yes`/`no` |
| `kubectl auth can-i '*' '*'` | am I cluster-admin? (all verbs on all resources) |
| `kubectl auth can-i --list` | full permission table for current identity |
| `kubectl auth can-i <v> <r> --as=jane -n dev` | impersonate **user** jane |
| `... --as=system:serviceaccount:<ns>:<sa>` | impersonate a **ServiceAccount** |
| `... --as-group=developers` | impersonate a **group** |
| `kubectl auth can-i create pods --quiet` | no output; exit 0=yes / 1=no (scripts) |
| `... get pods --subresource=log` | check a subresource (e.g. `pods/log`) |

## How it works / flow — the create-then-verify loop

```
  1. create  → kubectl create role pod-reader --verb=get,list,watch --resource=pods -n dev
  2. bind    → kubectl create rolebinding jane-read --role=pod-reader --user=jane -n dev
  3. VERIFY  → kubectl auth can-i list   pods --as=jane -n dev   # expect: yes
             → kubectl auth can-i delete pods --as=jane -n dev   # expect: no  (scoped!)
```

## Verified on the lab

```text
# admin identity is cluster-admin — the '*.* → [*]' row is the tell:
$ kubectl auth can-i '*' '*'
yes
$ kubectl auth can-i --list        # (trimmed)
Resources   Non-Resource URLs   Resource Names   Verbs
*.*         []                  []               [*]        <- cluster-admin
...

# a ServiceAccount with NO RoleBinding can do nothing:
$ kubectl auth can-i list secrets --as=system:serviceaccount:default:default -n default
no
$ kubectl auth can-i get pods     --as=system:serviceaccount:default:default -n default
no

# its --list shows only the baseline selfsubject*reviews + discovery URLs:
$ kubectl auth can-i --list --as=system:serviceaccount:default:default -n default
Resources                                       ...   Verbs
selfsubjectreviews.authentication.k8s.io        ...   [create]
selfsubjectaccessreviews.authorization.k8s.io   ...   [create]
...   (no real resource permissions)
```

Reading it: the admin's `*.* [*]` row = full access. The `default` SA has no
resource rows → it can't do anything until a Role is bound to it. That's the
secure default.

## Commands to remember

```bash
kubectl auth can-i <verb> <resource>                 # me, one action
kubectl auth can-i '*' '*'                            # am I admin?
kubectl auth can-i --list [-n <ns>]                   # all my perms
kubectl auth can-i <verb> <resource> --as=<user> -n <ns>
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>
kubectl auth can-i --list --as=<user> -n <ns>         # all of someone's perms
kubectl auth can-i create pods --quiet; echo $?       # 0=yes 1=no
```

## Gotchas / failure modes

- **ServiceAccount name format:** `system:serviceaccount:<namespace>:<sa-name>` —
  forget the prefix and the impersonation won't mean what you think.
- **Namespace matters:** a `RoleBinding` is namespaced. `can-i` without `-n` checks
  the current/`default` namespace — always pass `-n` when verifying a namespaced role.
- **Cluster-scoped resources** (nodes, PVs) ignore `-n`; you'll get a "not namespace
  scoped" warning — that's informational, not an error.
- **`--list` is the fast audit** — quicker than reading Role + RoleBinding YAML to
  work out effective permissions.

## 30-second self-test

1. Verify user `jane` can list pods in `dev`? → `kubectl auth can-i list pods --as=jane -n dev`.
2. Impersonate a ServiceAccount — what's the identity string? →
   `system:serviceaccount:<ns>:<sa>`.
3. See everything the current identity can do? → `kubectl auth can-i --list`.
4. How do you know an identity is cluster-admin from `--list`? → the `*.* → [*]` row.
5. A fresh SA with no binding — what can it do? → essentially nothing (deny by default).

---

See also: [`notes-cluster-architecture.md`](notes-cluster-architecture.md) (RBAC:
Role/ClusterRole + bindings), [`notes-interacting-with-control-plane.md`](notes-interacting-with-control-plane.md).
