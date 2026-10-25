# Storage — study notes (first principles)

🎯 **Exam scope:** Storage — **10%**. PersistentVolumes, PersistentVolumeClaims,
StorageClasses, access modes, reclaim policies, dynamic provisioning.

> Practice on [`kind`](../../environment/kind/) — it ships a `local-path`
> dynamic provisioner out of the box, perfect for PVC experiments.

---

## 0. First principles: the PV / PVC split

Storage is decoupled into *supply* and *demand* so app authors don't need to know
the infrastructure:

```
   ADMIN side (supply)              USER side (demand)
   ┌──────────────────┐            ┌──────────────────┐
   │ PersistentVolume │ ◀── bind ──│ PVC (claim)       │
   │ (PV): a real      │            │ "I need 5Gi RWO"  │
   │  disk/NFS/cloud   │            └────────┬─────────┘
   │  volume)          │                     │ mounted by
   └──────────────────┘                     ▼
                                      ┌──────────────┐
                                      │ Pod          │
                                      └──────────────┘

   A PVC binds to a PV that satisfies its size + accessModes + storageClass.
```

- **PV** = a piece of storage in the cluster (provisioned by admin or dynamically).
- **PVC** = a request for storage by a user/pod.
- A Pod references a **PVC**, never a PV directly.

---

## 1. Static vs dynamic provisioning

```
   STATIC   : admin pre-creates PVs by hand. PVC binds to a matching one.
   DYNAMIC  : PVC names a StorageClass → provisioner creates the PV on demand.
              (the normal path in real clusters and kind)
```

```yaml
# PVC — the thing you usually write
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard     # omit → uses the default StorageClass
```

```bash
kubectl get pvc              # STATUS Bound = it found/created a PV
kubectl get pv               # the backing volumes
kubectl get storageclass     # which classes exist; (default) is marked
```

---

## 2. Access modes

```
   RWO  ReadWriteOnce     → mounted read-write by ONE node   (most common; block)
   ROX  ReadOnlyMany      → read-only by many nodes
   RWX  ReadWriteMany     → read-write by many nodes         (needs NFS/CephFS etc.)
   RWOP ReadWriteOncePod  → read-write by a single POD
```

> A PVC only binds to a PV whose accessModes include what the PVC asked for.
> Most block storage is RWO — if you need many pods writing, you need RWX backend.

---

## 3. Reclaim policy — what happens to the PV when the PVC is deleted

```
   Retain  → PV kept (data preserved); admin must clean up manually
   Delete  → PV and underlying storage deleted automatically (default for dynamic)
   Recycle → deprecated
```
```bash
kubectl get pv <pv> -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'; echo
```

---

## 4. Mount a PVC in a Pod

```yaml
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data            # ← the PVC from section 1
```

Flow: Pod → `volumes` references the PVC → PVC is bound to a PV → container mounts it
at `mountPath`.

---

## 5. StorageClass (dynamic provisioning)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: rancher.io/local-path     # kind's built-in; cloud uses ebs.csi.aws.com etc.
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer  # bind only once a Pod needs it
```

- `volumeBindingMode: WaitForFirstConsumer` delays binding until a Pod is
  scheduled — so the PV lands in the right zone/node. Common default.
- Mark a class default with annotation
  `storageclass.kubernetes.io/is-default-class: "true"`.

---

## 6. Troubleshooting storage

```
 PVC stuck Pending        → no PV matches (size/accessMode/class) OR no provisioner
                            → kubectl describe pvc <c>  (read Events)
 Pod stuck ContainerCreating → volume won't mount; describe pod → Events
 "node(s) had volume node   → PV pinned to a zone/node the pod can't reach
  affinity conflict"
```
```bash
kubectl describe pvc <c> | grep -A10 Events
kubectl describe pod <p> | grep -A15 Events
kubectl get pv,pvc,storageclass
```

---

## 7. Exam-speed checklist

```
 request storage         → write a PVC (size + accessModes + storageClassName)
 use default class       → omit storageClassName in the PVC
 mount in pod            → volumes.persistentVolumeClaim.claimName → volumeMounts
 keep data on delete     → reclaimPolicy: Retain
 PVC Pending             → describe pvc (no matching PV / no provisioner)
 many writers            → need RWX access mode + a backend that supports it
```

---

## 8. What's new in v1.37 ("Garhwal") — storage impact

Minor for the exam, but know them:

- **`AnyVolumeDataSource` feature gate removed** — it had been locked-on (GA) since
  v1.33, so behavior is unchanged; the gate is just gone. Populating a PVC from a
  custom data source (e.g. a snapshot/CRD) is standard now.
- **In-place resize of memory-backed `emptyDir` (Alpha)** — part of the in-place
  pod-resize work; lets you resize a memory-backed `emptyDir` without recreating the
  Pod (gate `InPlacePodVerticalScalingMemoryBackedVolumes`). Niche/alpha.
- **SELinux mount GA (cross-ref Cluster Architecture)** — changes volume labeling on
  SELinux hosts; can break mounts after upgrade. Symptom shows up as storage/mount
  failures, so it's worth knowing here too.

Back to [domain index](README.md) · [repo index](../../README.md).
