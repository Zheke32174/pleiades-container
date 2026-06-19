#!/data/data/com.termux/files/usr/bin/env bash
# Gracefully shut down the Gentoo container.
source "${PLEIADES_TERMUX_LIB:-}" 2>/dev/null || true
set -euo pipefail

# Termux: no systemd-nspawn available
[[ "${PLEIADES_ENV:-}" == "termux" ]] && echo "[gentoo-down] Termux: no systemd-nspawn, skipping" && exit 0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PLEIADES_CONTAINER_ROOT:-$(dirname "$SCRIPT_DIR")/root.x86_64}"
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
