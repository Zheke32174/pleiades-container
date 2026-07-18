#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
BOOTSTRAP="$ROOT/bootstrap-container.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
    printf 'test failure: %s\n' "$*" >&2
    exit 1
}

expect_fail() {
    local name="$1"
    shift
    if "$@" >"$TMP/$name.out" 2>"$TMP/$name.err"; then
        fail "$name unexpectedly succeeded"
    fi
}

bash -n "$BOOTSTRAP"

"$BOOTSTRAP" --help > "$TMP/help.out"
grep -q -- '--install-host-services' "$TMP/help.out" \
    || fail 'help omits explicit host-service opt-in'
grep -q -- '--stage3-sha512' "$TMP/help.out" \
    || fail 'help omits independent stage3 pin'

expect_fail unknown-option "$BOOTSTRAP" --definitely-unknown
grep -q 'unknown argument' "$TMP/unknown-option.err" \
    || fail 'unknown option refusal is unexplained'

expect_fail missing-root-value "$BOOTSTRAP" --root
grep -q -- '--root requires a path' "$TMP/missing-root-value.err" \
    || fail 'missing root value refusal is unexplained'

for critical in / /etc /etc/pleiades-test /usr /var /root /opt; do
    name="critical-$(printf '%s' "$critical" | tr '/ ' '__')"
    expect_fail "$name" "$BOOTSTRAP" --dry-run --root "$critical"
    grep -q 'refusing critical host path' "$TMP/$name.err" \
        || fail "critical path refusal missing for $critical"
done

SAFE_A="$TMP/safe-a/root.x86_64"
SAFE_B="$TMP/safe-b/root.x86_64"

"$BOOTSTRAP" --dry-run --root "$SAFE_A" > "$TMP/order-a.out"
"$BOOTSTRAP" --root "$SAFE_B" --dry-run > "$TMP/order-b.out"
grep -q "Container root: $SAFE_A" "$TMP/order-a.out" \
    || fail 'dry-run then root option order parsed incorrectly'
grep -q "Container root: $SAFE_B" "$TMP/order-b.out" \
    || fail 'root then dry-run option order parsed incorrectly'
[ ! -e "$SAFE_A" ] && [ ! -e "$SAFE_B" ] \
    || fail 'dry run created a container root'

grep -q 'No host service was enabled or started' "$TMP/order-a.out" \
    || fail 'dry run did not preserve service activation boundary'

expect_fail insecure-mirror "$BOOTSTRAP" --dry-run --root "$SAFE_A" \
    --stage3-mirror http://example.invalid/stage3
grep -q 'stage3 mirror must use HTTPS' "$TMP/insecure-mirror.err" \
    || fail 'insecure mirror refusal is unexplained'

expect_fail malformed-hash "$BOOTSTRAP" --dry-run --root "$SAFE_A" \
    --stage3-sha512 deadbeef
grep -q 'exactly 128 hexadecimal' "$TMP/malformed-hash.err" \
    || fail 'malformed stage3 hash refusal is unexplained'

EXISTING="$TMP/under-review/root.x86_64"
mkdir -p "$EXISTING/usr" "$EXISTING/etc"
expect_fail unmarked-root "$BOOTSTRAP" --dry-run --root "$EXISTING"
grep -q 'existing root is unmarked' "$TMP/unmarked-root.err" \
    || fail 'unmarked root refusal is unexplained'

"$BOOTSTRAP" --dry-run --adopt-existing-root --root "$EXISTING" \
    > "$TMP/adopt.out"
grep -q 'Would adopt reviewed existing root' "$TMP/adopt.out" \
    || fail 'adoption dry run did not state its mutation'
[ ! -e "$EXISTING/.pleiades-container-root" ] \
    || fail 'adoption dry run wrote a root marker'

"$BOOTSTRAP" --dry-run --root "$SAFE_A" --install-host-services \
    > "$TMP/services.out"
grep -q '\[DRY-RUN\].*/etc/systemd/system/' "$TMP/services.out" \
    || fail 'host service opt-in did not preview destination writes'

PLEIADES_ENV=termux "$BOOTSTRAP" --root / --dry-run > "$TMP/termux.out"
grep -q 'systemd-nspawn bootstrap is not applicable' "$TMP/termux.out" \
    || fail 'Termux path did not exit through its adapter boundary'

printf 'bootstrap-container deterministic tests passed\n'
