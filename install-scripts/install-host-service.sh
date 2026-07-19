#!/usr/bin/env bash
set -euo pipefail

log() { printf '[pleiades-host-install] %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
usage() {
    cat <<'EOF'
Usage: sudo bash install-scripts/install-host-service.sh [OPTIONS]

Options:
  --root PATH   Reviewed marked container root (default: /var/lib/machines/pleiades)
  --dry-run     Validate destination compatibility and print intended host writes
  -h, --help    Show this help

The helper installs the reviewed pleiades-container.service and binds its
PLEIADES_ROOT to the selected container root. It never enables or starts it.

Disposable tests may override destination directories with
PLEIADES_SYSTEMD_UNIT_DIR and PLEIADES_CONFIG_DIR. Production defaults remain
/etc/systemd/system and /etc/pleiades.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
SOURCE_UNIT="$REPO_ROOT/systemd/system/pleiades-container.service"
ROOT="/var/lib/machines/pleiades"
DRY_RUN=false

while (($#)); do
    case "$1" in
        --root)
            (($# >= 2)) || die "--root requires a path"
            ROOT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
done

command -v realpath >/dev/null 2>&1 || die "realpath is required"
ROOT="$(realpath -m -- "$ROOT")"
[[ "$ROOT" != *$'\n'* && "$ROOT" != *$'\r'* && "$ROOT" != *$'\t'* && "$ROOT" != *' '* ]] \
    || die "container root must not contain whitespace or control characters"

case "$ROOT" in
    /|/bin|/bin/*|/boot|/boot/*|/dev|/dev/*|/etc|/etc/*|/home|/lib|/lib/*|/lib64|/lib64/*|/opt|/proc|/proc/*|/root|/run|/run/*|/sbin|/sbin/*|/sys|/sys/*|/usr|/usr/*|/var)
        die "refusing critical host path as container root: $ROOT"
        ;;
esac

[[ -f "$SOURCE_UNIT" && ! -L "$SOURCE_UNIT" ]] || die "reviewed service unit missing or not regular: $SOURCE_UNIT"
[[ -f "$ROOT/.pleiades-container-root" && ! -L "$ROOT/.pleiades-container-root" ]] \
    || die "container root is not marked by pleiades-container: $ROOT"
[[ -d "$ROOT/usr" && -d "$ROOT/etc" ]] || die "container root does not resemble a Linux root: $ROOT"

UNIT_DIR="$(realpath -m -- "${PLEIADES_SYSTEMD_UNIT_DIR:-/etc/systemd/system}")"
ENV_DIR="$(realpath -m -- "${PLEIADES_CONFIG_DIR:-/etc/pleiades}")"
UNIT_DEST="$UNIT_DIR/pleiades-container.service"
ENV_DEST="$ENV_DIR/container.env"
ENV_CONTENT="PLEIADES_ROOT=$ROOT"

validate_destinations() {
    if [[ -L "$UNIT_DEST" ]]; then
        die "refusing symlink host unit destination: $UNIT_DEST"
    fi
    if [[ -e "$UNIT_DEST" ]]; then
        cmp -s "$SOURCE_UNIT" "$UNIT_DEST" \
            || die "refusing to overwrite differing host unit: $UNIT_DEST"
    fi

    if [[ -L "$ENV_DEST" ]]; then
        die "refusing symlink host root binding: $ENV_DEST"
    fi
    if [[ -e "$ENV_DEST" ]]; then
        cmp -s <(printf '%s\n' "$ENV_CONTENT") "$ENV_DEST" \
            || die "refusing to overwrite differing host root binding: $ENV_DEST"
    fi
}

validate_destinations

if $DRY_RUN; then
    if [[ -e "$UNIT_DEST" ]]; then
        log "Host unit already matches: $UNIT_DEST"
    else
        log "Would install $UNIT_DEST from $SOURCE_UNIT"
    fi
    if [[ -e "$ENV_DEST" ]]; then
        log "Host root binding already matches: $ENV_DEST"
    else
        log "Would install $ENV_DEST with: $ENV_CONTENT"
    fi
    log "Would run systemctl daemon-reload"
    log "Would not enable or start pleiades-container.service"
    exit 0
fi

[[ "${EUID:-$(id -u)}" -eq 0 ]] || die "run as root (or use --dry-run)"
command -v systemctl >/dev/null 2>&1 || die "systemctl is required"
command -v ln >/dev/null 2>&1 || die "ln is required"

install -d -m 0755 "$UNIT_DIR" "$ENV_DIR"

TMP_UNIT="$(mktemp "$UNIT_DIR/.pleiades-container.service.XXXXXX")"
TMP_ENV="$(mktemp "$ENV_DIR/.container.env.XXXXXX")"
CREATED_UNIT=0
CREATED_ENV=0
COMMITTED=0

cleanup() {
    [[ ! -e "${TMP_UNIT:-}" ]] || rm -f -- "$TMP_UNIT"
    [[ ! -e "${TMP_ENV:-}" ]] || rm -f -- "$TMP_ENV"
    if [[ "$COMMITTED" != "1" ]]; then
        if [[ "$CREATED_ENV" == "1" ]]; then
            rm -f -- "$ENV_DEST"
        fi
        if [[ "$CREATED_UNIT" == "1" ]]; then
            rm -f -- "$UNIT_DEST"
        fi
    fi
}
trap cleanup EXIT INT TERM HUP

install -m 0644 "$SOURCE_UNIT" "$TMP_UNIT"
printf '%s\n' "$ENV_CONTENT" > "$TMP_ENV"
chmod 0644 "$TMP_ENV"

# Recheck after staging, then use same-filesystem hard links as atomic
# no-clobber publication. A destination appearing concurrently causes
# refusal rather than replacement.
validate_destinations

if [[ -e "$UNIT_DEST" ]]; then
    log "Host unit already matches"
else
    ln -- "$TMP_UNIT" "$UNIT_DEST" || die "host unit destination appeared during install: $UNIT_DEST"
    CREATED_UNIT=1
    log "Installed $UNIT_DEST"
fi

if [[ -e "$ENV_DEST" ]]; then
    log "Host root binding already matches"
else
    ln -- "$TMP_ENV" "$ENV_DEST" || die "host root binding appeared during install: $ENV_DEST"
    CREATED_ENV=1
    log "Installed $ENV_DEST"
fi

systemctl daemon-reload || die "systemctl daemon-reload failed; rolling back files created by this invocation"
COMMITTED=1
log "Reloaded systemd"
log "Service remains disabled and stopped. Review, then use systemctl start pleiades-container.service explicitly."
