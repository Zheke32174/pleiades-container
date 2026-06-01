# Pleiades Container

This repository contains the Gentoo `systemd-nspawn` container layer for Pleiades.

The container hosts defensive decoy services, telemetry collectors, policy-gated automation, and forensic analysis helpers. It is designed to keep most active logic inside the container while the host provides only a minimal owner-authorized launcher and bridge.

For host scripts and the main agent suite, see [pleiades](https://github.com/Zheke32174/pleiades).

## Intended Use

This container layer is intended for:

- local security labs on hardware you own or administer
- defensive decoy and telemetry service hosting
- forensic evidence collection
- container recovery and rebuild testing

It is **not** intended for unauthorized deployment, stealth installation, or use on systems without explicit owner authorization.

## Repository Map

| Repo | Purpose |
|------|---------|
| [`pleiades`](https://github.com/Zheke32174/pleiades) | Host scripts and agent suite |
| **`pleiades-container`** (this repo) | Gentoo `systemd-nspawn` container layer |
| [`pleiades-factory-stack`](https://github.com/Zheke32174/pleiades-factory-stack) | Tooling and AI/LLM research helpers |
| `pleiades-evidence` | Private evidence archive — never public |

## What's Here

```
bootstrap-container.sh          — builds Gentoo container from scratch on any machine
install-scripts/                — container up/down/shell helpers
systemd/system/                 — host-side service units (pleiades-*.service)
gentoo-nspawn.service           — main container launcher service
gentoo-pleiades-bridge.service  — host-container telemetry bridge
```

## Container Components

| Service | Role |
|---------|------|
| `pleiades-alcyone` | Host capability inventory |
| `pleiades-atlas`   | Recovery coordinator |
| `pleiades-electra` | Decoy environment router |
| `pleiades-maia`    | Container restore coordinator |
| `pleiades-celaeno` | Policy-gated request broker |
| `pleiades-taygete` | Health monitor and supervised restart |

## Quick Start (New Machine)

```bash
# Requirements: systemd-nspawn, git, curl, xz — run as root

# 1. Build the Gentoo container from a fresh stage3 tarball
sudo bash bootstrap-container.sh

# 2. Authenticate GitHub CLI and run operator setup
gh auth login
sudo bash /path/to/scripts/pleiades-setup.sh

# 3. Start the container
bash install-scripts/gentoo-up.sh

# 4. Open a shell into the container
bash install-scripts/gentoo-shell.sh
```

`bootstrap-container.sh` supports `--dry-run` to preview actions without making changes.

## Owner-Authorized Startup Service

Installing an automatic startup service is an advanced, optional step not enabled by default. Review `experimental/owner-authorized-recovery/` in the main [pleiades](https://github.com/Zheke32174/pleiades) repo before use.

## License

MIT — see [LICENSE](LICENSE).

## Security

See [SECURITY.md](SECURITY.md).
