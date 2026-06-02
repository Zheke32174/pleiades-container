# Pleiades Container

The Gentoo `systemd-nspawn` container layer for Pleiades. Run this on any machine to get the full agent suite: honeypot routing, telemetry aggregation, forensic collection, recovery coordination, and policy-gated request brokering — all inside an isolated container, with the host running only a launcher and bridge.

For host scripts and setup, see [pleiades](https://github.com/Zheke32174/pleiades).

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

## Quick Start

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

To install a system startup service, see `experimental/owner-authorized-recovery/` in the main [pleiades](https://github.com/Zheke32174/pleiades) repo — it's optional and not enabled by default.

## AI Assistance

Documentation and scaffolding were partly drafted with Claude (Anthropic) and ChatGPT (OpenAI). Maintainers are responsible for testing, attribution, and security review.

---

MIT — [LICENSE](LICENSE) · [SECURITY.md](SECURITY.md)
