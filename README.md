# Pleiades Container

The Gentoo `systemd-nspawn` container layer for Pleiades.

This container hosts honeypot services, telemetry collectors, policy-gated automation, and forensic analysis helpers. The host provides a minimal launcher and bridge; the active logic runs inside the container.

For host scripts and the main agent suite, see [pleiades](https://github.com/Zheke32174/pleiades).

## What it's for

- Local security labs on hardware you own or administer
- Honeypot and decoy service hosting with local telemetry
- Forensic evidence collection
- Container recovery and rebuild drills

## Repository Map

| Repo | Status | Purpose |
|------|--------|---------|
| [`pleiades`](https://github.com/Zheke32174/pleiades) | Release-track | Host scripts and agent suite |
| **`pleiades-container`** (this repo) | Release-track | Gentoo `systemd-nspawn` container layer |
| [`pleiades-factory-stack`](https://github.com/Zheke32174/pleiades-factory-stack) | Release-track | Tooling and AI/LLM research helpers |
| `pleiades-factory` | Private staging | Future factory orchestration work; not public-ready yet |
| `pleiades-evidence` | Private forever | Forensic evidence archive — never public |

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

## Automatic Startup (Optional)

Installing a system startup service is an optional, advanced step not enabled by default. Review `experimental/owner-authorized-recovery/` in the main [pleiades](https://github.com/Zheke32174/pleiades) repo before use.

## AI Assistance Disclosure

Parts of this project's documentation, planning notes, and script scaffolding were developed with assistance from AI tools, including Claude by Anthropic and ChatGPT by OpenAI.

Human maintainers are responsible for reviewing, testing, security boundaries, attribution, and final repository contents.

## License

MIT — see [LICENSE](LICENSE).

## Security

See [SECURITY.md](SECURITY.md).
