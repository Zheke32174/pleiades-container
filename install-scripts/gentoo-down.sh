#!/usr/bin/env bash
# Gracefully shut down the Gentoo container.
set -euo pipefail
ROOT=/workspaces/gentoo/root.x86_64
SESSION=gentoo
NSPAWN=$(pgrep -x systemd-nspawn | head -1 || true)
if [ -n "$NSPAWN" ]; then
  INNER=$(pgrep -P "$NSPAWN" | head -1 || true)
  [ -n "$INNER" ] && sudo kill -s RTMIN+4 "$INNER" 2>/dev/null || true
  for i in $(seq 1 30); do
    kill -0 "$NSPAWN" 2>/dev/null || break
    sleep 1
  done
fi
tmux kill-session -t "$SESSION" 2>/dev/null || true
echo "gentoo down"
