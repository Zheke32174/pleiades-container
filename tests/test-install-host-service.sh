#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT_DIR/install-scripts/install-host-service.sh"
UNIT_SOURCE="$ROOT_DIR/systemd/system/pleiades-container.service"
TMP="$(mktemp -d)"
trap 'sudo rm -rf -- "$TMP"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
expect_fail() {
    local pattern="$1"
    shift
    local output
    if output="$("$@" 2>&1)"; then
        fail "command unexpectedly succeeded: $*"
    fi
    grep -Fq -- "$pattern" <<<"$output" || fail "missing failure pattern '$pattern': $output"
}
assert_reload_count() {
    local expected="$1"
    local log_path="$2"
    local actual
    actual="$(grep -c '^daemon-reload$' "$log_path" || true)"
    [[ "$actual" == "$expected" ]] || fail "expected $expected daemon-reload calls, got $actual: $(cat "$log_path")"
}

bash -n "$SCRIPT"
grep -Fq -- '--settings=no' "$UNIT_SOURCE" \
    || fail "canonical nspawn unit permits ambient .nspawn settings"

MARKED="$TMP/marked-root"
mkdir -p "$MARKED/usr" "$MARKED/etc"
printf 'schema=1\nkind=pleiades-gentoo-nspawn-root\nmanaged_by=Zheke32174/pleiades-container\n' > "$MARKED/.pleiades-container-root"

OUTPUT="$(bash "$SCRIPT" --dry-run --root "$MARKED")"
grep -Fq "Would install /etc/systemd/system/pleiades-container.service" <<<"$OUTPUT"
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

# Dry-run must detect the same conflicts that a real invocation would refuse.
CONFLICT_UNIT_DIR="$TMP/conflict-systemd"
CONFLICT_CONFIG_DIR="$TMP/conflict-config"
mkdir -p "$CONFLICT_UNIT_DIR" "$CONFLICT_CONFIG_DIR"
printf 'different unit\n' > "$CONFLICT_UNIT_DIR/pleiades-container.service"
expect_fail "differing host unit" \
    env PLEIADES_SYSTEMD_UNIT_DIR="$CONFLICT_UNIT_DIR" \
        PLEIADES_CONFIG_DIR="$CONFLICT_CONFIG_DIR" \
        bash "$SCRIPT" --dry-run --root "$MARKED"

rm -f "$CONFLICT_UNIT_DIR/pleiades-container.service"
printf 'PLEIADES_ROOT=/different/root\n' > "$CONFLICT_CONFIG_DIR/container.env"
expect_fail "differing host root binding" \
    env PLEIADES_SYSTEMD_UNIT_DIR="$CONFLICT_UNIT_DIR" \
        PLEIADES_CONFIG_DIR="$CONFLICT_CONFIG_DIR" \
        bash "$SCRIPT" --dry-run --root "$MARKED"

rm -f "$CONFLICT_CONFIG_DIR/container.env"
ln -s /dev/null "$CONFLICT_UNIT_DIR/pleiades-container.service"
expect_fail "symlink host unit" \
    env PLEIADES_SYSTEMD_UNIT_DIR="$CONFLICT_UNIT_DIR" \
        PLEIADES_CONFIG_DIR="$CONFLICT_CONFIG_DIR" \
        bash "$SCRIPT" --dry-run --root "$MARKED"

# Disposable real-write fixtures use a fake systemctl and destination overrides.
FAKE_BIN="$TMP/fake-bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SYSTEMCTL_LOG"
if [[ "$1" == "daemon-reload" ]]; then
    calls="$(wc -l < "$SYSTEMCTL_LOG")"
    if ((calls <= ${FAKE_SYSTEMCTL_FAIL_COUNT:-0})); then
        exit 1
    fi
    exit "${FAKE_SYSTEMCTL_RC:-0}"
fi
exit 97
EOF
chmod +x "$FAKE_BIN/systemctl"

SUCCESS_UNIT_DIR="$TMP/success-systemd"
SUCCESS_CONFIG_DIR="$TMP/success-config"
SYSTEMCTL_LOG="$TMP/systemctl-success.log"
sudo env \
    PATH="$FAKE_BIN:/usr/bin:/bin" \
    SYSTEMCTL_LOG="$SYSTEMCTL_LOG" \
    PLEIADES_SYSTEMD_UNIT_DIR="$SUCCESS_UNIT_DIR" \
    PLEIADES_CONFIG_DIR="$SUCCESS_CONFIG_DIR" \
    bash "$SCRIPT" --root "$MARKED"

cmp -s "$UNIT_SOURCE" "$SUCCESS_UNIT_DIR/pleiades-container.service" \
    || fail "installed unit differs from reviewed source"
printf 'PLEIADES_ROOT=%s\n' "$MARKED" | cmp -s - "$SUCCESS_CONFIG_DIR/container.env" \
    || fail "installed root binding differs"
assert_reload_count 1 "$SYSTEMCTL_LOG"

# Initial reload failure must remove current-invocation files and reconcile the
# systemd manager against the restored filesystem with one compensating reload.
ROLLBACK_UNIT_DIR="$TMP/rollback-systemd"
ROLLBACK_CONFIG_DIR="$TMP/rollback-config"
ROLLBACK_LOG="$TMP/systemctl-rollback.log"
expect_fail "reconciled by a compensating daemon-reload" \
    sudo env \
        PATH="$FAKE_BIN:/usr/bin:/bin" \
        SYSTEMCTL_LOG="$ROLLBACK_LOG" \
        FAKE_SYSTEMCTL_FAIL_COUNT=1 \
        PLEIADES_SYSTEMD_UNIT_DIR="$ROLLBACK_UNIT_DIR" \
        PLEIADES_CONFIG_DIR="$ROLLBACK_CONFIG_DIR" \
        bash "$SCRIPT" --root "$MARKED"
[[ ! -e "$ROLLBACK_UNIT_DIR/pleiades-container.service" ]] \
    || fail "failed transaction left a newly created unit"
[[ ! -e "$ROLLBACK_CONFIG_DIR/container.env" ]] \
    || fail "failed transaction left a newly created environment binding"
assert_reload_count 2 "$ROLLBACK_LOG"

# If both the original and compensating reload fail, report manager uncertainty.
UNCERTAIN_UNIT_DIR="$TMP/uncertain-systemd"
UNCERTAIN_CONFIG_DIR="$TMP/uncertain-config"
UNCERTAIN_LOG="$TMP/systemctl-uncertain.log"
expect_fail "systemd manager state is uncertain and requires manual reconciliation" \
    sudo env \
        PATH="$FAKE_BIN:/usr/bin:/bin" \
        SYSTEMCTL_LOG="$UNCERTAIN_LOG" \
        FAKE_SYSTEMCTL_FAIL_COUNT=2 \
        PLEIADES_SYSTEMD_UNIT_DIR="$UNCERTAIN_UNIT_DIR" \
        PLEIADES_CONFIG_DIR="$UNCERTAIN_CONFIG_DIR" \
        bash "$SCRIPT" --root "$MARKED"
[[ ! -e "$UNCERTAIN_UNIT_DIR/pleiades-container.service" ]] \
    || fail "uncertain transaction left a newly created unit"
[[ ! -e "$UNCERTAIN_CONFIG_DIR/container.env" ]] \
    || fail "uncertain transaction left a newly created environment binding"
assert_reload_count 2 "$UNCERTAIN_LOG"

# Matching pre-existing files survive both failed reload attempts unchanged.
PRESERVE_UNIT_DIR="$TMP/preserve-systemd"
PRESERVE_CONFIG_DIR="$TMP/preserve-config"
sudo install -d -m 0755 "$PRESERVE_UNIT_DIR" "$PRESERVE_CONFIG_DIR"
sudo install -m 0644 "$UNIT_SOURCE" "$PRESERVE_UNIT_DIR/pleiades-container.service"
printf 'PLEIADES_ROOT=%s\n' "$MARKED" | sudo tee "$PRESERVE_CONFIG_DIR/container.env" >/dev/null
sudo chmod 0644 "$PRESERVE_CONFIG_DIR/container.env"
PRESERVE_LOG="$TMP/systemctl-preserve.log"
expect_fail "systemd manager state is uncertain" \
    sudo env \
        PATH="$FAKE_BIN:/usr/bin:/bin" \
        SYSTEMCTL_LOG="$PRESERVE_LOG" \
        FAKE_SYSTEMCTL_FAIL_COUNT=2 \
        PLEIADES_SYSTEMD_UNIT_DIR="$PRESERVE_UNIT_DIR" \
        PLEIADES_CONFIG_DIR="$PRESERVE_CONFIG_DIR" \
        bash "$SCRIPT" --root "$MARKED"
cmp -s "$UNIT_SOURCE" "$PRESERVE_UNIT_DIR/pleiades-container.service" \
    || fail "rollback altered a matching pre-existing unit"
printf 'PLEIADES_ROOT=%s\n' "$MARKED" | cmp -s - "$PRESERVE_CONFIG_DIR/container.env" \
    || fail "rollback altered a matching pre-existing binding"
assert_reload_count 2 "$PRESERVE_LOG"

printf 'PASS: host-service binding helper\n'
