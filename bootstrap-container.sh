#!/usr/bin/env bash
# bootstrap-container.sh — Build the Pleiades Gentoo nspawn container from scratch.
#
# The default action builds or validates the container root and installs a pinned
# Pleiades script snapshot inside it. Host service and WSL boot mutation are
# separate, explicit opt-ins.
set -euo pipefail

log()  { printf '[pleiades-bootstrap] %s\n' "$*"; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
usage() {
    cat <<'EOF'
Usage: sudo bash bootstrap-container.sh [OPTIONS]

Options:
  --root PATH                 Container root (default: ./root.x86_64)
  --dry-run                   Validate and preview without writes or network use
  --adopt-existing-root       Mark a reviewed existing Gentoo root as Pleiades
  --update-scripts            Replace an older pinned Pleiades script snapshot
  --install-host-services     Install missing host systemd units explicitly
  --install-wsl-boot          Update WSL boot command explicitly (WSL only)
  --pleiades-repo URL         Source repository (default canonical repository)
  --pleiades-ref REF          Branch, tag, or commit to pin (default: main)
  --stage3-mirror URL         Gentoo stage3 mirror
  --stage3-sha512 HASH        Operator-pinned stage3 SHA-512
  -h, --help                  Show this help

Environment equivalents:
  PLEIADES_CONTAINER_ROOT, PLEIADES_REPO, PLEIADES_REF,
  STAGE3_MIRROR, STAGE3_SHA512, PLEIADES_TERMUX_LIB
EOF
}

run() {
    if $DRY_RUN; then
        printf '[DRY-RUN]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CONTAINER_ROOT="${PLEIADES_CONTAINER_ROOT:-${SCRIPT_DIR}/root.x86_64}"
PLEIADES_REPO="${PLEIADES_REPO:-https://github.com/Zheke32174/pleiades.git}"
PLEIADES_REF="${PLEIADES_REF:-main}"
STAGE3_MIRROR="${STAGE3_MIRROR:-https://distfiles.gentoo.org/releases/amd64/autobuilds}"
STAGE3_SHA512="${STAGE3_SHA512:-}"
DRY_RUN=false
ADOPT_EXISTING_ROOT=false
UPDATE_SCRIPTS=false
INSTALL_HOST_SERVICES=false
INSTALL_WSL_BOOT=false

while (($#)); do
    case "$1" in
        --root)
            (($# >= 2)) || die "--root requires a path"
            CONTAINER_ROOT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --adopt-existing-root)
            ADOPT_EXISTING_ROOT=true
            shift
            ;;
        --update-scripts)
            UPDATE_SCRIPTS=true
            shift
            ;;
        --install-host-services)
            INSTALL_HOST_SERVICES=true
            shift
            ;;
        --install-wsl-boot)
            INSTALL_WSL_BOOT=true
            shift
            ;;
        --pleiades-repo)
            (($# >= 2)) || die "--pleiades-repo requires a URL"
            PLEIADES_REPO="$2"
            shift 2
            ;;
        --pleiades-ref)
            (($# >= 2)) || die "--pleiades-ref requires a ref"
            PLEIADES_REF="$2"
            shift 2
            ;;
        --stage3-mirror)
            (($# >= 2)) || die "--stage3-mirror requires a URL"
            STAGE3_MIRROR="$2"
            shift 2
            ;;
        --stage3-sha512)
            (($# >= 2)) || die "--stage3-sha512 requires a hash"
            STAGE3_SHA512="$2"
            shift 2
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

if [[ -n "${PLEIADES_TERMUX_LIB:-}" ]]; then
    [[ -r "$PLEIADES_TERMUX_LIB" ]] || die "PLEIADES_TERMUX_LIB is not readable: $PLEIADES_TERMUX_LIB"
    # shellcheck source=/dev/null
    source "$PLEIADES_TERMUX_LIB"
fi

if [[ "${PLEIADES_ENV:-}" == "termux" ]]; then
    log "Termux environment detected — systemd-nspawn bootstrap is not applicable"
    log "Use the Pleiades Termux adapter instead"
    exit 0
fi

command -v realpath >/dev/null 2>&1 || die "realpath is required"
CONTAINER_ROOT="$(realpath -m -- "$CONTAINER_ROOT")"
ROOT_MARKER="$CONTAINER_ROOT/.pleiades-container-root"

case "$CONTAINER_ROOT" in
    /|/bin|/bin/*|/boot|/boot/*|/dev|/dev/*|/etc|/etc/*|/lib|/lib/*|/lib64|/lib64/*|/proc|/proc/*|/run|/run/*|/sbin|/sbin/*|/sys|/sys/*|/usr|/usr/*)
        die "refusing critical host path as container root: $CONTAINER_ROOT"
        ;;
esac

[[ -n "$PLEIADES_REPO" ]] || die "Pleiades repository URL cannot be empty"
[[ -n "$PLEIADES_REF" ]] || die "Pleiades ref cannot be empty"
[[ "$STAGE3_MIRROR" == https://* ]] || die "stage3 mirror must use HTTPS"
if [[ -n "$STAGE3_SHA512" ]] && [[ ! "$STAGE3_SHA512" =~ ^[[:xdigit:]]{128}$ ]]; then
    die "--stage3-sha512 must be exactly 128 hexadecimal characters"
fi

if [[ -e "$CONTAINER_ROOT" && ! -f "$ROOT_MARKER" ]]; then
    if ! $ADOPT_EXISTING_ROOT; then
        die "existing root is unmarked; review it, then use --adopt-existing-root: $CONTAINER_ROOT"
    fi
    [[ -d "$CONTAINER_ROOT/usr" && -d "$CONTAINER_ROOT/etc" ]] \
        || die "existing root does not resemble a Linux root: $CONTAINER_ROOT"
fi

log "Container root: $CONTAINER_ROOT"
log "Pleiades source: $PLEIADES_REPO @ $PLEIADES_REF"
log "Host service install: $INSTALL_HOST_SERVICES"
log "WSL boot install: $INSTALL_WSL_BOOT"

if $DRY_RUN; then
    log "Dry run: root, privilege, host-command, network, and archive checks that require writes are skipped"
else
    [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "run as root (or use --dry-run)"
    for cmd in curl git mktemp rsync sha512sum systemd-detect-virt systemd-nspawn tar; do
        command -v "$cmd" >/dev/null 2>&1 || die "$cmd is required"
    done
fi

if grep -qi microsoft /proc/version 2>/dev/null; then
    ENVIRONMENT="wsl"
elif command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt --container -q 2>/dev/null; then
    ENVIRONMENT="container"
else
    ENVIRONMENT="bare_metal"
fi
log "Environment: $ENVIRONMENT"

TMP_WORK=""
STAGING_ROOT=""
cleanup() {
    if [[ -n "$TMP_WORK" && -d "$TMP_WORK" ]]; then
        rm -rf -- "$TMP_WORK"
    fi
    if [[ -n "$STAGING_ROOT" && -d "$STAGING_ROOT" ]]; then
        rm -rf -- "$STAGING_ROOT"
    fi
}
trap cleanup EXIT INT TERM HUP

write_root_marker() {
    local root="$1"
    {
        printf 'schema=1\n'
        printf 'kind=pleiades-gentoo-nspawn-root\n'
        printf 'managed_by=Zheke32174/pleiades-container\n'
    } > "$root/.pleiades-container-root"
}

resolve_expected_sha512() {
    local digests="$1"
    local filename="$2"
    local expected

    if [[ -n "$STAGE3_SHA512" ]]; then
        printf '%s\n' "${STAGE3_SHA512,,}"
        return
    fi

    expected="$(awk -v wanted="$filename" '
        length($1) == 128 && $1 ~ /^[0-9A-Fa-f]+$/ && $2 == wanted {
            print tolower($1)
            exit
        }
    ' "$digests")"
    [[ -n "$expected" ]] || die "could not find SHA-512 for $filename in DIGESTS"
    printf '%s\n' "$expected"
}

install_stage3() {
    local parent metadata stage3_path stage3_url archive digests filename expected

    parent="$(dirname "$CONTAINER_ROOT")"
    if $DRY_RUN; then
        run install -d -m 0755 "$parent"
        log "Would resolve latest Gentoo systemd stage3 from $STAGE3_MIRROR"
        log "Would verify SHA-512, reject unsafe archive paths, extract to a sibling staging root, write marker, then atomically rename"
        return
    fi

    install -d -m 0755 "$parent"
    TMP_WORK="$(mktemp -d "${TMPDIR:-/tmp}/pleiades-bootstrap.XXXXXX")"
    STAGING_ROOT="$(mktemp -d "$parent/.pleiades-root.XXXXXX")"
    metadata="$TMP_WORK/latest-stage3.txt"

    curl --fail --silent --show-error --location \
        "$STAGE3_MIRROR/latest-stage3-amd64-systemd.txt" -o "$metadata"
    stage3_path="$(awk '!/^#/ && NF {print $1; exit}' "$metadata")"
    [[ -n "$stage3_path" ]] || die "could not resolve stage3 path from mirror metadata"
    [[ "$stage3_path" != /* && "$stage3_path" != *'..'* ]] || die "unsafe stage3 path in mirror metadata: $stage3_path"

    stage3_url="$STAGE3_MIRROR/$stage3_path"
    filename="$(basename "$stage3_path")"
    archive="$TMP_WORK/$filename"
    digests="$TMP_WORK/$filename.DIGESTS"

    log "Downloading stage3: $stage3_url"
    curl --fail --silent --show-error --location "$stage3_url" -o "$archive"
    curl --fail --silent --show-error --location "$stage3_url.DIGESTS" -o "$digests"

    expected="$(resolve_expected_sha512 "$digests" "$filename")"
    printf '%s  %s\n' "$expected" "$archive" | sha512sum --check --status \
        || die "stage3 SHA-512 verification failed"

    if tar -tf "$archive" | grep -Eq '(^/|(^|/)\.\.(/|$))'; then
        die "stage3 archive contains an unsafe absolute or parent-traversal path"
    fi

    log "Extracting verified stage3 into disposable staging root"
    tar xpf "$archive" --xattrs-include='*.*' --numeric-owner -C "$STAGING_ROOT"
    [[ -d "$STAGING_ROOT/usr" && -d "$STAGING_ROOT/etc" ]] \
        || die "extracted stage3 does not resemble a Linux root"
    write_root_marker "$STAGING_ROOT"

    [[ ! -e "$CONTAINER_ROOT" ]] || die "container root appeared during staging: $CONTAINER_ROOT"
    mv -- "$STAGING_ROOT" "$CONTAINER_ROOT"
    STAGING_ROOT=""
    log "Verified stage3 installed at $CONTAINER_ROOT"
}

if [[ -d "$CONTAINER_ROOT/usr" ]]; then
    if [[ ! -f "$ROOT_MARKER" ]]; then
        if $DRY_RUN; then
            log "Would adopt reviewed existing root and write $ROOT_MARKER"
        else
            write_root_marker "$CONTAINER_ROOT"
            log "Adopted existing root: $CONTAINER_ROOT"
        fi
    else
        log "Marked container root already exists; stage3 extraction skipped"
    fi
else
    [[ ! -e "$CONTAINER_ROOT" ]] || die "container root exists but has no usr directory: $CONTAINER_ROOT"
    install_stage3
fi

install_scripts() {
    local clone_dir source_dir scripts_dir receipt current_commit resolved_commit

    scripts_dir="$CONTAINER_ROOT/scripts"
    receipt="$scripts_dir/.pleiades-source-receipt"

    if $DRY_RUN; then
        log "Would fetch $PLEIADES_REPO ref $PLEIADES_REF, resolve one commit, and install root.x86_64/scripts with a receipt"
        if [[ -d "$scripts_dir" ]] && ! $UPDATE_SCRIPTS; then
            log "Existing scripts would require --update-scripts unless their receipt already pins the resolved commit"
        fi
        return
    fi

    [[ -n "$TMP_WORK" ]] || TMP_WORK="$(mktemp -d "${TMPDIR:-/tmp}/pleiades-bootstrap.XXXXXX")"
    clone_dir="$TMP_WORK/pleiades-source"
    git init -q "$clone_dir"
    git -C "$clone_dir" remote add origin "$PLEIADES_REPO"
    git -C "$clone_dir" fetch --depth=1 origin "$PLEIADES_REF"
    git -C "$clone_dir" checkout -q --detach FETCH_HEAD
    resolved_commit="$(git -C "$clone_dir" rev-parse HEAD)"
    source_dir="$clone_dir/root.x86_64/scripts"
    [[ -d "$source_dir" ]] || die "pinned source lacks root.x86_64/scripts"

    current_commit=""
    if [[ -f "$receipt" ]]; then
        current_commit="$(awk -F= '$1 == "source_commit" {print $2; exit}' "$receipt")"
    fi

    if [[ -d "$scripts_dir" && -n "$current_commit" && "$current_commit" == "$resolved_commit" ]]; then
        log "Pleiades scripts already match pinned commit $resolved_commit"
        return
    fi
    if [[ -d "$scripts_dir" && ! $UPDATE_SCRIPTS ]]; then
        die "scripts already exist without the requested pinned receipt; use --update-scripts after review"
    fi

    install -d -m 0755 "$scripts_dir"
    rsync -a --checksum --delete-delay --exclude '.git/' "$source_dir/" "$scripts_dir/"
    {
        printf 'schema=1\n'
        printf 'source_repository=%s\n' "$PLEIADES_REPO"
        printf 'source_ref=%s\n' "$PLEIADES_REF"
        printf 'source_commit=%s\n' "$resolved_commit"
    } > "$receipt"
    log "Installed Pleiades scripts pinned to $resolved_commit"
}

install_scripts

install_host_services() {
    local svc name dest
    $INSTALL_HOST_SERVICES || { log "Host systemd units not installed (use --install-host-services)"; return; }

    if $DRY_RUN; then
        for svc in "$SCRIPT_DIR"/systemd/system/*.service; do
            [[ -e "$svc" ]] || continue
            run install -m 0644 "$svc" "/etc/systemd/system/$(basename "$svc")"
        done
        run systemctl daemon-reload
        return
    fi

    command -v systemctl >/dev/null 2>&1 || die "systemctl is required for --install-host-services"
    for svc in "$SCRIPT_DIR"/systemd/system/*.service; do
        [[ -e "$svc" ]] || continue
        name="$(basename "$svc")"
        dest="/etc/systemd/system/$name"
        if [[ -e "$dest" ]]; then
            cmp -s "$svc" "$dest" || die "refusing to overwrite differing host unit: $dest"
            log "Host unit already matches: $name"
        else
            install -m 0644 "$svc" "$dest"
            log "Installed host unit: $name"
        fi
    done
    systemctl daemon-reload
}

install_wsl_boot() {
    local wrapper="/usr/local/sbin/pleiades-runtime-monitor"
    local conf="/etc/wsl.conf"
    local tmp backup

    $INSTALL_WSL_BOOT || { log "WSL boot entry not installed (use --install-wsl-boot on WSL)"; return; }
    [[ "$ENVIRONMENT" == "wsl" ]] || die "--install-wsl-boot is valid only in WSL"
    [[ -x "$wrapper" ]] || die "WSL runtime wrapper is missing or not executable: $wrapper"

    if $DRY_RUN; then
        log "Would update the [boot] command in $conf after writing a timestamped backup"
        return
    fi

    tmp="$(mktemp "${TMPDIR:-/tmp}/wsl.conf.XXXXXX")"
    backup="$conf.pleiades-backup.$(date -u +%Y%m%dT%H%M%SZ)"
    if [[ -e "$conf" ]]; then
        cp -a -- "$conf" "$backup"
    else
        : > "$conf"
    fi

    awk -v cmd="$wrapper" '
        BEGIN { in_boot=0; found_boot=0; wrote_command=0 }
        /^\[boot\][[:space:]]*$/ {
            if (in_boot && !wrote_command) { print "command=" cmd; wrote_command=1 }
            in_boot=1; found_boot=1; print; next
        }
        /^\[/ {
            if (in_boot && !wrote_command) { print "command=" cmd; wrote_command=1 }
            in_boot=0; print; next
        }
        in_boot && /^[[:space:]]*command[[:space:]]*=/ {
            if (!wrote_command) { print "command=" cmd; wrote_command=1 }
            next
        }
        { print }
        END {
            if (in_boot && !wrote_command) { print "command=" cmd; wrote_command=1 }
            if (!found_boot) { print ""; print "[boot]"; print "command=" cmd }
        }
    ' "$conf" > "$tmp"
    install -m 0644 "$tmp" "$conf"
    rm -f -- "$tmp"
    log "Updated WSL boot command; backup: $backup"
}

install_host_services
install_wsl_boot

log ""
log "Container prepared at: $CONTAINER_ROOT"
log "No host service was enabled or started by this script."
log "Next steps:"
log "  1. Review $CONTAINER_ROOT/scripts/.pleiades-source-receipt"
log "  2. Configure the operator inside the container"
log "  3. Install host units explicitly if desired: --install-host-services"
log "  4. Start and inspect the container through the reviewed install scripts"
