#!/usr/bin/env bash
# Boot the Gentoo nspawn container (systemd PID 1) in a detached tmux session.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PLEIADES_CONTAINER_ROOT:-$(dirname "$SCRIPT_DIR")/root.x86_64}"
SESSION=gentoo

if [ ! -d "$ROOT" ]; then
  echo "ERROR: $ROOT not found." >&2
  exit 1
fi

if pgrep -x systemd-nspawn >/dev/null; then
  echo "a systemd-nspawn is already running (gentoo or arch?). Run: gentoo-down  or  arch-down"
  exit 0
fi

# /run/systemd/nspawn must be on tmpfs (lost on host restart)
if ! mountpoint -q /run/systemd/nspawn; then
  sudo mkdir -p /run/systemd/nspawn
  sudo mount -t tmpfs tmpfs /run/systemd/nspawn
fi

tmux has-session -t "$SESSION" 2>/dev/null && tmux kill-session -t "$SESSION"

# Bind-mounts: /workspaces/underhall is the source-of-truth for our install
# scripts + notebooks. Mounting it at /mnt/underhall lets the booted gentoo
# see host edits live — no re-stage step between iterations.
BIND_ARGS=()
if [ -d /workspaces/underhall ]; then
  BIND_ARGS+=(--bind=/workspaces/underhall:/mnt/underhall)
fi

tmux new-session -d -s "$SESSION" \
  "sudo systemd-nspawn -D '$ROOT' \
     --register=no --keep-unit --resolv-conf=copy-host \
     --hostname=gentoo-codespace ${BIND_ARGS[*]} --boot"

for i in $(seq 1 30); do
  NSPAWN=$(pgrep -x systemd-nspawn | head -1 || true)
  if [ -n "$NSPAWN" ]; then
    INNER=$(pgrep -P "$NSPAWN" | head -1 || true)
    if [ -n "$INNER" ]; then
      echo "gentoo up — nspawn PID $NSPAWN, inner PID $INNER"
      echo "enter with: gentoo-shell"
      exit 0
    fi
  fi
  sleep 0.5
done
echo "boot did not finish in 15s; debug with: tmux attach -t $SESSION" >&2
exit 1
