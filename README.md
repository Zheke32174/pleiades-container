# Pleiades Container

**Gentoo nspawn container** — the deployment target for the
[pleiades](https://github.com/Zheke32174/pleiades) Purple Team Ouroboros security suite.

This repo contains the container rootfs config, systemd units, and install scripts
for the Gentoo systemd-nspawn container that hosts the Purple Team defense stack.

## Repos

| Repo | Purpose |
|------|---------|
| [pleiades](https://github.com/Zheke32174/pleiades) | SofiaX Purple Team Polyglot Suite — The security framework itself |
| **pleiades-container** (this repo) | The Gentoo nspawn container that runs pleiades |
| [underhall](https://github.com/Zheke32174/underhall) | Original Arch nspawn install layer |
| [undercity](https://github.com/Zheke32174/undercity) | Backup/restore tooling |

## Quick Start

```bash
# On a bare metal / VM / WSL2 host with systemd
sudo systemd-nspawn -D /path/to/root.x86_64 -b --network-veth -M gentoo
```

### Systemd Auto-Start (bare metal / VM)

```bash
sudo cp gentoo-nspawn.service /etc/systemd/system/
sudo cp gentoo-purple-bridge.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now gentoo-nspawn.service
sudo systemctl enable --now gentoo-purple-bridge.service
```

### WSL2

On WSL2, the container starts via the `gentoo-up.sh` script:

```bash
bash install-scripts/gentoo-up.sh
```

## Container Architecture

- **Distribution:** Gentoo (systemd stage 3)
- **Virtualization:** systemd-nspawn (lightweight, no kernel emulation)
- **Network:** veth pair, bridge to host
- **Storage:** Ext4 image or directory at `/workspaces/gentoo/root.x86_64/`
- **Supervision:** s6-overlay / systemd double-layer

## State Management

- **Backup:** `undercity archive /workspaces/gentoo/` creates state archives
- **Restore:** `undercity restore` rehydrates from archive
- **Self-destruct:** `purge-self.sh` (in-container, signal-gated)
- **Re-deployment:** `purple-redeploy.sh` (in-container, clones from GitHub)
