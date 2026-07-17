# Pleiades Container

`pleiades-container` builds and supervises the Gentoo `systemd-nspawn` substrate used by the canonical Pleiades lean runtime.

This repository owns the **host/guest lifecycle boundary**. The defensive agents themselves live in [`pleiades/lean`](https://github.com/Zheke32174/pleiades/tree/main/lean) and are staged into the guest at `/opt/pleiades-build` during bootstrap.

## Current status

Active, but still pre-production.

The current implementation provides:

- verified Gentoo stage3 download and extraction;
- explicit staging of a selected Pleiades branch, tag, or commit;
- one canonical host service: `pleiades-container.service`;
- systemd-owned supervision with restart limits and resource ceilings;
- a private veth network namespace rather than accidental host-network sharing;
- `machinectl`-based start, stop, and shell helpers;
- no tmux supervisor, PID-namespace guessing, runtime `curl | sh`, or Termux paths.

The deception plane is **not yet split into disposable microVMs**, and the current nspawn guest should not be treated as a final security boundary for hostile public services. See the defensive-plane migration in the main Pleiades repository.

## Repository layout

```text
bootstrap-container.sh                 build/stage the guest rootfs
install-scripts/gentoo-up.sh          start through systemd
install-scripts/gentoo-down.sh        stop through systemd
install-scripts/gentoo-shell.sh       enter through machinectl
systemd/system/pleiades-container.service
                                       canonical host unit
ci/check.sh                            static repository invariants
```

## Requirements

- Linux host with systemd
- `systemd-nspawn` and `machinectl`
- `curl`, `git`, `tar`, `xz`, and `sha512sum`
- root privileges for bootstrap and service installation

Termux is intentionally handled by the separate [`pleiades-container-termux`](https://github.com/Zheke32174/pleiades-container-termux) reference repository. WSL2 can host this substrate when systemd is enabled, but this repository no longer edits `/etc/wsl.conf` or launches nspawn through tmux.

## Bootstrap

```bash
sudo bash bootstrap-container.sh
```

Default locations:

```text
Guest root:      /var/lib/machines/pleiades
Host unit:       /etc/systemd/system/pleiades-container.service
Host config:     /etc/pleiades/container.env
Staged runtime:  /var/lib/machines/pleiades/opt/pleiades-build
```

The stage3 archive is checked against a SHA-512 digest from Gentoo's adjacent `DIGESTS` file. A separately recorded digest can be required explicitly:

```bash
sudo bash bootstrap-container.sh \
  --stage3-sha512 '<128-hex-character-digest>' \
  --pleiades-ref hardening/defensive-planes-v1
```

For a preview:

```bash
sudo bash bootstrap-container.sh --dry-run
```

## Start and install the guest runtime

```bash
sudo systemctl enable --now pleiades-container.service
sudo machinectl shell root@pleiades /bin/bash -l
```

Inside the guest:

```bash
bash /opt/pleiades-build/build.sh
systemctl enable --now pleiades-maia.service pleiades-maia-checkpoint.timer
```

The shorter helpers remain available:

```bash
bash install-scripts/gentoo-up.sh
bash install-scripts/gentoo-shell.sh
bash install-scripts/gentoo-down.sh
```

## Configuration

Edit `/etc/pleiades/container.env`:

```bash
PLEIADES_ROOT=/var/lib/machines/pleiades
```

The unit deliberately contains no broad host bind mounts. Host telemetry should arrive through narrow authenticated collectors, not by exposing `/proc`, `/sys`, `/run`, an entire Windows drive, or management sockets to the guest.

## Security boundary

The host kernel and host-local authority broker remain authoritative. The container may observe, analyze, and request bounded actions, but it must not own host boot, firmware, recovery authority, unrestricted host filesystems, or generic privileged execution.

Current host-unit safeguards include:

- `Restart=on-failure` with a five-failure circuit breaker;
- finite task, CPU, and memory budgets;
- `OOMPolicy=stop`;
- systemd-managed shutdown and timeout behavior;
- private veth networking;
- no tmux or custom respawn loop.

## Verification

```bash
bash ci/check.sh
```

CI also runs shell syntax checks, ShellCheck reporting, and `systemd-analyze verify` for the canonical unit.

## Related repositories

- [`pleiades`](https://github.com/Zheke32174/pleiades) — defensive runtime and architecture
- [`pleiades-windows`](https://github.com/Zheke32174/pleiades-windows) — Windows collectors and status publication
- [`pleiades-factory-stack`](https://github.com/Zheke32174/pleiades-factory-stack) — research toolchain manifests

MIT — see [LICENSE](LICENSE). Security reports should follow [SECURITY.md](SECURITY.md).
