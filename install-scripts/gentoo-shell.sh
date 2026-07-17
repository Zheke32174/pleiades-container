#!/usr/bin/env bash
# Open an authenticated root shell in the canonical Pleiades machine.

set -euo pipefail

MACHINE="${PLEIADES_MACHINE:-pleiades}"

state="$(machinectl show "$MACHINE" -p State --value 2>/dev/null || true)"
case "$state" in
    running|degraded) ;;
    *)
        echo "$MACHINE is not running; start pleiades-container.service first" >&2
        exit 1
        ;;
esac

exec sudo machinectl shell "root@$MACHINE" /bin/bash -l
