#!/data/data/com.termux/files/usr/bin/env bash
# Open a root shell inside the running Gentoo container.
source "${PLEIADES_TERMUX_LIB:-}" 2>/dev/null || true
set -euo pipefail

# Termux: no nsenter available
[[ "${PLEIADES_ENV:-}" == "termux" ]] && echo "[gentoo-shell] Termux: no nsenter, skipping" && exit 0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PLEIADES_CONTAINER_ROOT:-$(dirname "$SCRIPT_DIR")/root.x86_64}"
NSPAWN=$(pgrep -x systemd-nspawn | head -1 || true)
if [ -z "$NSPAWN" ]; then
  echo "gentoo not running. Run: gentoo-up" >&2
  exit 1
fi
INNER=$(pgrep -P "$NSPAWN" | head -1 || true)
if [ -z "$INNER" ]; then
  echo "couldn't find inner init under PID $NSPAWN" >&2
  exit 1
fi
exec sudo nsenter --target "$INNER" --mount --uts --ipc --net --pid --cgroup -- /bin/bash -l
