#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT_DIR/install-scripts/install-host-service.sh"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
expect_fail() {
    local pattern="$1"
    shift
    local output
    if output="$($@ 2>&1)"; then
        fail "command unexpectedly succeeded: $*"
    fi
    grep -Fq -- "$pattern" <<<"$output" || fail "missing failure pattern '$pattern': $output"
}

bash -n "$SCRIPT"

MARKED="$TMP/marked-root"
mkdir -p "$MARKED/usr" "$MARKED/etc"
printf 'schema=1\nkind=pleiades-gentoo-nspawn-root\nmanaged_by=Zheke32174/pleiades-container\n' > "$MARKED/.pleiades-container-root"

OUTPUT="$(bash "$SCRIPT" --dry-run --root "$MARKED")"
grep -Fq "Would install or verify /etc/systemd/system/pleiades-container.service" <<<"$OUTPUT"
grep -Fq "PLEIADES_ROOT=$MARKED" <<<"$OUTPUT"
grep -Fq "Would not enable or start" <<<"$OUTPUT"

expect_fail "unknown argument" bash "$SCRIPT" --not-an-option
expect_fail "refusing critical host path" bash "$SCRIPT" --dry-run --root /etc

UNMARKED="$TMP/unmarked-root"
mkdir -p "$UNMARKED/usr" "$UNMARKED/etc"
expect_fail "not marked" bash "$SCRIPT" --dry-run --root "$UNMARKED"

BAD="$TMP/not-linux"
mkdir -p "$BAD"
printf 'schema=1\n' > "$BAD/.pleiades-container-root"
expect_fail "does not resemble a Linux root" bash "$SCRIPT" --dry-run --root "$BAD"

printf 'PASS: host-service binding helper\n'
