#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
bad() { echo "[check] ERROR: $*" >&2; fail=1; }
ok() { echo "[check] OK: $*"; }

unit=systemd/system/pleiades-container.service
active_shell=(
    bootstrap-container.sh
    install-scripts/gentoo-up.sh
    install-scripts/gentoo-down.sh
    install-scripts/gentoo-shell.sh
    ci/check.sh
)
active_runtime=(
    bootstrap-container.sh
    install-scripts/gentoo-up.sh
    install-scripts/gentoo-down.sh
    install-scripts/gentoo-shell.sh
    "$unit"
)

for file in "${active_shell[@]}"; do
    [[ -f "$file" ]] || { bad "missing canonical file: $file"; continue; }
    bash -n "$file" || bad "shell syntax: $file"
done
[[ "$fail" -eq 0 ]] && ok "canonical shell syntax"

if grep -nHE '^#!/data/data/com\.termux|Restart=always|TasksMax=infinity|--register=no|tmux[[:space:]]+new-session|/mnt/c|--bind(-ro)?=/(proc|sys|run)' \
    "${active_runtime[@]}"; then
    bad "legacy Termux, tmux, unlimited restart, or broad host-bridge pattern found in canonical runtime"
else
    ok "legacy runtime patterns absent from canonical paths"
fi

for directive in \
    'Restart=on-failure' \
    'StartLimitBurst=5' \
    'TasksMax=1024' \
    'OOMPolicy=stop' \
    '--network-veth'; do
    grep -Fq -- "$directive" "$unit" || bad "$unit missing $directive"
done

if command -v shellcheck >/dev/null 2>&1; then
    for file in "${active_shell[@]}"; do
        shellcheck --severity=error "$file" || bad "ShellCheck error: $file"
    done
    [[ "$fail" -eq 0 ]] && ok "canonical ShellCheck error-level scan"
fi

if command -v systemd-analyze >/dev/null 2>&1 && command -v systemd-nspawn >/dev/null 2>&1; then
    systemd-analyze verify "$unit" || bad "systemd unit verification failed"
    [[ "$fail" -eq 0 ]] && ok "systemd unit verification"
fi

if [[ "$fail" -ne 0 ]]; then
    echo "[check] FAILED" >&2
    exit 1
fi

echo "[check] PASSED"
