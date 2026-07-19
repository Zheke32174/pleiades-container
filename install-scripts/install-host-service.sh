#!/usr/bin/env bash
set -euo pipefail

log() { printf '[pleiades-host-install] %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
usage() {
    cat <<'EOF'
Usage: sudo bash install-scripts/install-host-service.sh [OPTIONS]

Options:
  --root PATH   Reviewed marked container root (default: /var/lib/machines/pleiades)
  --dry-run     Validate and print the intended host writes
  -h, --help    Show this help

The helper installs the reviewed pleiades-container.service and binds its
PLEIADES_ROOT to the selected container root. It never enables or starts it.
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

[[ -f "$SOURCE_UNIT" ]] || die "reviewed service unit missing: $SOURCE_UNIT"
[[ -f "$ROOT/.pleiades-container-root" ]] || die "container root is not marked by pleiades-container: $ROOT"
[[ -d "$ROOT/usr" && -d "$ROOT/etc" ]] || die "container root does not resemble a Linux root: $ROOT"

UNIT_DEST="/etc/systemd/system/pleiades-container.service"
ENV_DIR="/etc/pleiades"
ENV_DEST="$ENV_DIR/container.env"
ENV_CONTENT="PLEIADES_ROOT=$ROOT"

if $DRY_RUN; then
    log "Would install or verify $UNIT_DEST from $SOURCE_UNIT"
    log "Would install or verify $ENV_DEST with: $ENV_CONTENT"
    log "Would run systemctl daemon-reload"
    log "Would not enable or start pleiades-container.service"
    exit 0
fi

[[ "${EUID:-$(id -u)}" -eq 0 ]] || die "run as root (or use --dry-run)"
command -v systemctl >/dev/null 2>&1 || die "systemctl is required"

if [[ -e "$UNIT_DEST" ]]; then
    cmp -s "$SOURCE_UNIT" "$UNIT_DEST" || die "refusing to overwrite differing host unit: $UNIT_DEST"
    log "Host unit already matches"
else
    install -m 0644 "$SOURCE_UNIT" "$UNIT_DEST"
    log "Installed $UNIT_DEST"
fi

install -d -m 0755 "$ENV_DIR"
TMP_ENV="$(mktemp "$ENV_DIR/.container.env.XXXXXX")"
cleanup() { [[ ! -e "$TMP_ENV" ]] || rm -f -- "$TMP_ENV"; }
trap cleanup EXIT INT TERM HUP
printf '%s\n' "$ENV_CONTENT" > "$TMP_ENV"
chmod 0644 "$TMP_ENV"

if [[ -e "$ENV_DEST" ]]; then
    cmp -s "$TMP_ENV" "$ENV_DEST" || die "refusing to overwrite differing host root binding: $ENV_DEST"
    log "Host root binding already matches"
else
    mv -- "$TMP_ENV" "$ENV_DEST"
    TMP_ENV=""
    log "Installed $ENV_DEST"
fi

systemctl daemon-reload
log "Reloaded systemd"
log "Service remains disabled and stopped. Review, then use systemctl start pleiades-container.service explicitly."
