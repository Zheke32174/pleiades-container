# Pleiades Container

**Gentoo systemd-nspawn container** — the deployment target for the [pleiades](https://github.com/Zheke32174/pleiades) security suite.

This repo contains the container scripts, systemd units, and configuration for the Gentoo systemd-nspawn container that hosts the Pleiades agent stack.

## Repositories

| Repo | Purpose |
|------|---------|
| [pleiades](https://github.com/Zheke32174/pleiades) | Host scripts, task master, toolchain catalog |
| **pleiades-container** (this repo) | Gentoo nspawn container — scripts, systemd units, agent stack |
| [pleiades-evidence](https://github.com/Zheke32174/pleiades-evidence) | Private — secured evidence archive |
| [underhall](https://github.com/Zheke32174/underhall) | Original Arch nspawn install layer |
| [undercity](https://github.com/Zheke32174/undercity) | Backup/restore tooling |

## Quick Start

```bash
# Start the container
sudo systemd-nspawn -D /path/to/root.x86_64 -b --network-veth -M gentoo

# Or via the install scripts
bash scripts/install-boot-persistence.sh
```

## Container Architecture

- **Distribution:** Gentoo (systemd stage 3)
- **Virtualization:** systemd-nspawn (lightweight, no kernel emulation)
- **Network:** veth pair, bridge to host
- **Storage:** Ext4 image or directory-based rootfs
- **Supervision:** systemd with multi-agent service stack

## Agent Suite

The container runs 9 agents:

| Script | Agent | Role |
|--------|-------|------|
| `scripts/Maia.sh` | Maia | Overseer, EFI/ESP persistence, GitHub rehydration |
| `scripts/Electra.sh` | Electra | Fake environment / honeypot |
| `scripts/Taygete.sh` | Taygete | Credential monitor |
| `scripts/Alcyone.sh` | Alcyone | Recon, host bridge reporting |
| `scripts/Celaeno.sh` | Celaeno | Watchdog, process guardian |
| `scripts/Sterope.sh` | Sterope | Cross-platform compatibility |
| `scripts/Asterope.sh` | Asterope | BSD compatibility layer, WASM stratum |
| `scripts/Merope.sh` | Merope | System monitoring, threat detection |
| `scripts/Atlas.sh` | Atlas | Multi-language payload execution |

## State Management

- **Backup:** `undercity archive /workspaces/gentoo/` creates state archives
- **Restore:** `undercity restore` rehydrates from archive
- **Boot persistence:** `scripts/install-boot-persistence.sh` installs auto-start
- **Self-destruct:** `scripts/pleiades-selfdestruct.sh` (evidence-preserving wipe)

## Credits & Third-Party Components

This project incorporates and builds upon the following open-source projects:

- **Gentoo Linux** — Stage 3 base system ([gentoo.org](https://gentoo.org)) — GPL v2
- **systemd** — System and service manager ([systemd.io](https://systemd.io)) — LGPL v2.1+
- **s6-overlay** — Process supervision suite ([skarnet.org](https://skarnet.org/software/s6/)) — ISC License
- **Bedrock Linux** — Multi-distribution strata system ([bedrocklinux.org](https://bedrocklinux.org)) — GPL v2
- **systemd-nspawn** — Lightweight namespace container — LGPL v2.1+

## License

See individual component licenses. The Pleiades-sourced scripts in this repository are provided under the MIT License.
