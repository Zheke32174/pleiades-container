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
[[ "$(cat "$SYSTEMCTL_LOG")" == "daemon-reload" ]] \
    || fail "installer invoked unexpected systemctl action: $(cat "$SYSTEMCTL_LOG")"

# A daemon-reload failure removes only files created by this invocation.
ROLLBACK_UNIT_DIR="$TMP/rollback-systemd"
ROLLBACK_CONFIG_DIR="$TMP/rollback-config"
ROLLBACK_LOG="$TMP/systemctl-rollback.log"
expect_fail "rolling back files created" \
    sudo env \
        PATH="$FAKE_BIN:/usr/bin:/bin" \
        SYSTEMCTL_LOG="$ROLLBACK_LOG" \
        FAKE_SYSTEMCTL_RC=1 \
        PLEIADES_SYSTEMD_UNIT_DIR="$ROLLBACK_UNIT_DIR" \
        PLEIADES_CONFIG_DIR="$ROLLBACK_CONFIG_DIR" \
        bash "$SCRIPT" --root "$MARKED"
[[ ! -e "$ROLLBACK_UNIT_DIR/pleiades-container.service" ]] \
    || fail "failed transaction left a newly created unit"
[[ ! -e "$ROLLBACK_CONFIG_DIR/container.env" ]] \
    || fail "failed transaction left a newly created environment binding"

# Matching pre-existing files survive a later reload failure.
PRESERVE_UNIT_DIR="$TMP/preserve-systemd"
PRESERVE_CONFIG_DIR="$TMP/preserve-config"
sudo install -d -m 0755 "$PRESERVE_UNIT_DIR" "$PRESERVE_CONFIG_DIR"
sudo install -m 0644 "$UNIT_SOURCE" "$PRESERVE_UNIT_DIR/pleiades-container.service"
printf 'PLEIADES_ROOT=%s\n' "$MARKED" | sudo tee "$PRESERVE_CONFIG_DIR/container.env" >/dev/null
sudo chmod 0644 "$PRESERVE_CONFIG_DIR/container.env"
expect_fail "rolling back files created" \
    sudo env \
        PATH="$FAKE_BIN:/usr/bin:/bin" \
        SYSTEMCTL_LOG="$TMP/systemctl-preserve.log" \
        FAKE_SYSTEMCTL_RC=1 \
        PLEIADES_SYSTEMD_UNIT_DIR="$PRESERVE_UNIT_DIR" \
        PLEIADES_CONFIG_DIR="$PRESERVE_CONFIG_DIR" \
        bash "$SCRIPT" --root "$MARKED"
cmp -s "$UNIT_SOURCE" "$PRESERVE_UNIT_DIR/pleiades-container.service" \
    || fail "rollback altered a matching pre-existing unit"
printf 'PLEIADES_ROOT=%s\n' "$MARKED" | cmp -s - "$PRESERVE_CONFIG_DIR/container.env" \
    || fail "rollback altered a matching pre-existing binding"

printf 'PASS: host-service binding helper\n'
