#!/usr/bin/env bash
# Start the canonical Pleiades systemd-nspawn machine through systemd.

set -euo pipefail

UNIT="${PLEIADES_CONTAINER_UNIT:-pleiades-container.service}"
MACHINE="${PLEIADES_MACHINE:-pleiades}"

command -v systemctl >/dev/null 2>&1 || {
    echo "systemctl is required; this helper is for a Linux host" >&2
    exit 1
}

if ! systemctl cat "$UNIT" >/dev/null 2>&1; then
    echo "$UNIT is not installed; run bootstrap-container.sh first" >&2
    exit 1
fi

sudo systemctl start "$UNIT"

for _ in $(seq 1 60); do
    state="$(machinectl show "$MACHINE" -p State --value 2>/dev/null || true)"
    case "$state" in
        running|degraded)
            echo "$MACHINE up (state=$state)"
            exit 0
            ;;
    esac
    sleep 1
done

sudo systemctl --no-pager --full status "$UNIT" || true
echo "$MACHINE did not reach a running state within 60 seconds" >&2
exit 1
