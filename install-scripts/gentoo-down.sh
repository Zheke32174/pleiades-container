#!/usr/bin/env bash
# Stop the canonical Pleiades systemd-nspawn machine through systemd.

set -euo pipefail

UNIT="${PLEIADES_CONTAINER_UNIT:-pleiades-container.service}"
MACHINE="${PLEIADES_MACHINE:-pleiades}"

if ! systemctl cat "$UNIT" >/dev/null 2>&1; then
    echo "$UNIT is not installed" >&2
    exit 1
fi

sudo systemctl stop "$UNIT"

for _ in $(seq 1 45); do
    if ! machinectl show "$MACHINE" >/dev/null 2>&1; then
        echo "$MACHINE down"
        exit 0
    fi
    sleep 1
done

echo "$MACHINE did not stop within 45 seconds" >&2
exit 1
