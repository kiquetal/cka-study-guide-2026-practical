#!/usr/bin/env bash
# worker.sh — runs ONLY on worker nodes.
# Waits for the control-plane to publish the join command, then joins the cluster.
set -euxo pipefail

JOIN_FILE="/vagrant/join-command.sh"

echo "[worker] Waiting for the control-plane join command (${JOIN_FILE})"
for i in $(seq 1 60); do
  if [ -f "${JOIN_FILE}" ]; then
    break
  fi
  echo "[worker]   ...not ready yet (attempt ${i}/60), sleeping 10s"
  sleep 10
done

if [ ! -f "${JOIN_FILE}" ]; then
  echo "[worker] ERROR: join command never appeared. Did the control-plane finish provisioning?" >&2
  exit 1
fi

echo "[worker] Joining the cluster"
bash "${JOIN_FILE}"

echo "[worker] Joined. Check 'kubectl get nodes' on the control-plane."
