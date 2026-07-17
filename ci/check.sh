#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
bad() { echo "[check] ERROR: $*" >&2; fail=1; }
ok() { echo "[check] OK: $*"; }

while IFS= read -r file; do
    bash -n "$file" || bad "shell syntax: $file"
done < <(find . -type f -name '*.sh' -not -path './.git/*' | sort)
[[ "$fail" -eq 0 ]] && ok "shell syntax"

if grep -RInE '^#!/data/data/com\.termux|Restart=always|TasksMax=infinity|--register=no|tmux[[:space:]]+new-session|/mnt/c|--bind(-ro)?=/(proc|sys|run)' \
    bootstrap-container.sh install-scripts systemd; then
    bad "legacy Termux, tmux, unlimited restart, or broad host-bridge pattern found"
else
    ok "legacy runtime patterns absent"
fi

unit=systemd/system/pleiades-container.service
for directive in \
    'Restart=on-failure' \
    'StartLimitBurst=5' \
    'TasksMax=1024' \
    'OOMPolicy=stop' \
    '--network-veth'; do
    grep -Fq -- "$directive" "$unit" || bad "$unit missing $directive"
done

if command -v shellcheck >/dev/null 2>&1; then
    while IFS= read -r file; do
        shellcheck --severity=error "$file" || bad "ShellCheck error: $file"
    done < <(find . -type f -name '*.sh' -not -path './.git/*' | sort)
    [[ "$fail" -eq 0 ]] && ok "ShellCheck error-level scan"
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
