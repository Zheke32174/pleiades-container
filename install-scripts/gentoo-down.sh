#!/usr/bin/env bash
# Gracefully shut down the Gentoo container.
set -euo pipefail

if [[ -n "${PLEIADES_TERMUX_LIB:-}" ]]; then
  # shellcheck source=/dev/null
  source "$PLEIADES_TERMUX_LIB"
fi

if [[ "${PLEIADES_ENV:-}" == "termux" ]]; then
  echo "[gentoo-down] Termux: no systemd-nspawn, skipping"
  exit 0
fi

SESSION=gentoo
NSPAWN=$(pgrep -x systemd-nspawn | head -1 || true)
if [[ -n "$NSPAWN" ]]; then
  INNER=$(pgrep -P "$NSPAWN" | head -1 || true)
  if [[ -n "$INNER" ]]; then
    sudo kill -s RTMIN+4 "$INNER" 2>/dev/null || true
  fi
  for _ in {1..30}; do
    kill -0 "$NSPAWN" 2>/dev/null || break
    sleep 1
  done
fi

tmux kill-session -t "$SESSION" 2>/dev/null || true
echo "gentoo down"
