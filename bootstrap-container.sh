#!/usr/bin/env bash
# Build a reproducible Gentoo systemd-nspawn substrate for the canonical
# Pleiades lean runtime. This script runs on the Linux host as root.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_ROOT="${PLEIADES_CONTAINER_ROOT:-/var/lib/machines/pleiades}"
PLEIADES_REPO="${PLEIADES_REPO:-https://github.com/Zheke32174/pleiades.git}"
PLEIADES_REF="${PLEIADES_REF:-main}"
STAGE3_MIRROR="${STAGE3_MIRROR:-https://distfiles.gentoo.org/releases/amd64/autobuilds}"
STAGE3_SHA512="${STAGE3_SHA512:-}"
DRY_RUN=false
INSTALL_UNIT=true
TMP_ROOT=""

usage() {
    cat <<'EOF'
Usage: sudo bash bootstrap-container.sh [options]

Options:
  --root PATH          Container root (default: /var/lib/machines/pleiades)
  --pleiades-ref REF   Pleiades branch, tag, or commit to stage (default: main)
  --stage3-sha512 HEX  Require this exact stage3 SHA-512 digest
  --no-install-unit    Do not install the host systemd unit
  --dry-run            Print mutating commands without executing them
  -h, --help           Show this help

Environment overrides:
  PLEIADES_REPO, PLEIADES_REF, PLEIADES_CONTAINER_ROOT,
  STAGE3_MIRROR, STAGE3_SHA512
EOF
}

while (($#)); do
    case "$1" in
        --root)
            [[ $# -ge 2 ]] || { echo "--root requires a path" >&2; exit 2; }
            CONTAINER_ROOT="$2"; shift 2 ;;
        --pleiades-ref)
            [[ $# -ge 2 ]] || { echo "--pleiades-ref requires a value" >&2; exit 2; }
            PLEIADES_REF="$2"; shift 2 ;;
        --stage3-sha512)
            [[ $# -ge 2 ]] || { echo "--stage3-sha512 requires a digest" >&2; exit 2; }
            STAGE3_SHA512="$2"; shift 2 ;;
        --no-install-unit) INSTALL_UNIT=false; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

log() { printf '[pleiades-container] %s\n' "$*"; }
die() { printf '[pleiades-container] ERROR: %s\n' "$*" >&2; exit 1; }

run() {
    if $DRY_RUN; then
        printf '[DRY-RUN]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

cleanup() {
    [[ -n "$TMP_ROOT" && -d "$TMP_ROOT" ]] && rm -rf -- "$TMP_ROOT"
}
trap cleanup EXIT

[[ "${EUID:-$(id -u)}" -eq 0 ]] || die "run as root"
for cmd in curl git tar xz sha512sum systemctl systemd-nspawn; do
    command -v "$cmd" >/dev/null 2>&1 || die "required command not found: $cmd"
done

if grep -qi microsoft /proc/version 2>/dev/null; then
    HOST_ENV=wsl
elif systemd-detect-virt --container -q 2>/dev/null; then
    HOST_ENV=container
else
    HOST_ENV=linux
fi
log "host environment: $HOST_ENV"
log "container root: $CONTAINER_ROOT"

TMP_ROOT="$(mktemp -d /tmp/pleiades-container.XXXXXX)"

if [[ ! -x "$CONTAINER_ROOT/usr/bin/env" ]]; then
    log "resolving current Gentoo amd64 systemd stage3"
    stage3_path="$(curl -fsSL "$STAGE3_MIRROR/latest-stage3-amd64-systemd.txt" \
        | awk '!/^#/ && NF {print $1; exit}')"
    [[ -n "$stage3_path" ]] || die "could not resolve a stage3 path"

    stage3_name="$(basename "$stage3_path")"
    stage3_url="$STAGE3_MIRROR/$stage3_path"
    archive="$TMP_ROOT/$stage3_name"
    digests="$TMP_ROOT/$stage3_name.DIGESTS"

    log "downloading $stage3_url"
    run curl -fL --retry 4 --retry-delay 2 --proto '=https' --tlsv1.2 \
        "$stage3_url" -o "$archive"

    if ! $DRY_RUN; then
        expected="$STAGE3_SHA512"
        if [[ -z "$expected" ]]; then
            curl -fL --retry 4 --retry-delay 2 --proto '=https' --tlsv1.2 \
                "$stage3_url.DIGESTS" -o "$digests"
            expected="$(awk -v f="$stage3_name" '$2 == f && length($1) == 128 {print $1; exit}' "$digests")"
        fi
        [[ "$expected" =~ ^[0-9a-fA-F]{128}$ ]] || die "no valid SHA-512 digest was available"
        actual="$(sha512sum "$archive" | awk '{print $1}')"
        [[ "${actual,,}" == "${expected,,}" ]] || die "stage3 SHA-512 verification failed"
        log "stage3 SHA-512 verified"

        install -d -m 0755 "$CONTAINER_ROOT"
        tar xpf "$archive" --xattrs-include='*.*' --numeric-owner -C "$CONTAINER_ROOT"
        log "stage3 extracted"
    fi
else
    log "existing rootfs detected; stage3 extraction skipped"
fi

# Stage the canonical lean runtime. It is installed from inside the container so
# the host never mutates the guest's runtime paths piecemeal.
repo_tmp="$TMP_ROOT/pleiades"
log "staging Pleiades ref $PLEIADES_REF from $PLEIADES_REPO"
if $DRY_RUN; then
    log "would fetch Pleiades and copy lean/ to $CONTAINER_ROOT/opt/pleiades-build"
else
    git clone --filter=blob:none --no-checkout "$PLEIADES_REPO" "$repo_tmp"
    git -C "$repo_tmp" fetch --depth=1 origin "$PLEIADES_REF"
    git -C "$repo_tmp" checkout --detach FETCH_HEAD
    [[ -x "$repo_tmp/lean/build.sh" ]] || die "selected Pleiades ref does not contain lean/build.sh"
    rm -rf "$CONTAINER_ROOT/opt/pleiades-build"
    install -d -m 0755 "$CONTAINER_ROOT/opt"
    cp -a "$repo_tmp/lean" "$CONTAINER_ROOT/opt/pleiades-build"
    printf '%s\n' "$(git -C "$repo_tmp" rev-parse HEAD)" > "$CONTAINER_ROOT/opt/pleiades-build/SOURCE_COMMIT"
    log "canonical lean runtime staged at /opt/pleiades-build"
fi

if $INSTALL_UNIT; then
    unit_src="$SCRIPT_DIR/systemd/system/pleiades-container.service"
    [[ -f "$unit_src" ]] || die "missing host unit: $unit_src"
    run install -d -m 0755 /etc/pleiades /etc/systemd/system
    run install -m 0644 "$unit_src" /etc/systemd/system/pleiades-container.service
    if [[ ! -f /etc/pleiades/container.env ]]; then
        if $DRY_RUN; then
            log "would create /etc/pleiades/container.env"
        else
            printf 'PLEIADES_ROOT=%s\n' "$CONTAINER_ROOT" > /etc/pleiades/container.env
            chmod 0644 /etc/pleiades/container.env
        fi
    fi
    run systemctl daemon-reload
fi

log "bootstrap complete"
log "next steps:"
log "  sudo systemctl start pleiades-container.service"
log "  sudo machinectl shell root@pleiades /bin/bash -l"
log "  inside guest: bash /opt/pleiades-build/build.sh"
