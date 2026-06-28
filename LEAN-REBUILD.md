# Lean rebuild (2026-06)

The container substrate and the agent suite were rebuilt clean. The new approach —
a minimal Gentoo stage3 substrate, an idempotent installer that refuses unit/binary
mismatches, and hardened, rate-limited systemd units with **no runtime self-install** —
lives in the [`pleiades`](https://github.com/Zheke32174/pleiades) repo under `lean/`:

- `lean/ops/lean-bootstrap.sh` — build the minimal bootable substrate
- `lean/ops/boot-tmux.sh` — boot the container (clean teardown + retry; read-only Windows bridge)
- `lean/build.sh` — idempotent installer (checks every unit's `ExecStart` binary exists)
- `lean/units/` — one hardened unit per agent

This repo's previous `bootstrap-container.sh` and `systemd/` units remain for reference.
They superseded the parts that crash-looped (units pointing at binaries the scripts never
built) and the first-boot self-install. The always-on Windows side is in
[`pleiades-windows`](https://github.com/Zheke32174/pleiades-windows).
