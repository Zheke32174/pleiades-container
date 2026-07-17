#!/usr/bin/env bash
# Open a root shell inside the running Gentoo container.
set -euo pipefail

if [[ -n "${PLEIADES_TERMUX_LIB:-}" ]]; then
  # shellcheck source=/dev/null
  source "$PLEIADES_TERMUX_LIB"
fi

if [[ "${PLEIADES_ENV:-}" == "termux" ]]; then
  echo "[gentoo-shell] Termux: no nsenter, skipping"
  exit 0
fi

NSPAWN=$(pgrep -x systemd-nspawn | head -1 || true)
if [[ -z "$NSPAWN" ]]; then
  echo "gentoo not running. Run: gentoo-up" >&2
  exit 1
fi

INNER=$(pgrep -P "$NSPAWN" | head -1 || true)
if [[ -z "$INNER" ]]; then
  echo "couldn't find inner init under PID $NSPAWN" >&2
  exit 1
fi

exec sudo nsenter --target "$INNER" --mount --uts --ipc --net --pid --cgroup -- /bin/bash -l
