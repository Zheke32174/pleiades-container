# Pleiades Container

The Gentoo `systemd-nspawn` container substrate for Pleiades. It hosts defensive and recovery-oriented services behind an isolated Linux execution boundary while the local host kernel remains authoritative.

For host-side agents and policy, see [`pleiades`](https://github.com/Zheke32174/pleiades).

## Repository map

| Repo | Status | Purpose |
|---|---|---|
| [`pleiades`](https://github.com/Zheke32174/pleiades) | Release-track | Host scripts, node agent, and public defensive substrate |
| **`pleiades-container`** | Release-track | Gentoo `systemd-nspawn` container substrate |
| [`pleiades-factory-stack`](https://github.com/Zheke32174/pleiades-factory-stack) | Release-track | Tooling and AI/LLM research helpers |
| `pleiades-factory` | Private staging | Factory orchestration research |
| `pleiades-evidence` | Private | Forensic evidence lineage; never public runtime material |

## Contents

```text
bootstrap-container.sh          verified root/bootstrap installer
install-scripts/                reviewed container up/down/shell helpers
systemd/system/                 optional host-side service units
gentoo-nspawn.service           main container launcher service
gentoo-pleiades-bridge.service  host-container telemetry bridge
```

## Container services

| Service | Role |
|---|---|
| `pleiades-alcyone` | Host capability inventory |
| `pleiades-atlas` | Recovery coordinator |
| `pleiades-electra` | Decoy environment router |
| `pleiades-maia` | Container restore coordinator |
| `pleiades-celaeno` | Policy-gated request broker |
| `pleiades-taygete` | Health monitor and supervised restart |

## Bootstrap safety model

`bootstrap-container.sh` separates container construction from host mutation.

By default it:

1. refuses critical host paths and unmarked existing roots;
2. resolves a Gentoo systemd stage3 over HTTPS;
3. verifies SHA-512 before extraction;
4. rejects archive paths containing absolute or parent traversal;
5. extracts into a disposable sibling staging directory before atomic placement;
6. installs one commit-pinned Pleiades script snapshot;
7. writes a receipt containing source repository, requested ref, resolved commit, and content-tree SHA-256;
8. does **not** install, enable, or start host services.

Mirror-provided `DIGESTS` protects transfer integrity. For an independently selected pin, provide `--stage3-sha512` or `STAGE3_SHA512`.

Existing roots require `--adopt-existing-root` after inspection. Existing script snapshots require `--update-scripts` if the pinned commit or content receipt differs.

## Quick start

Requirements for a real build: root, `systemd-nspawn`, Git, curl, rsync, tar, and SHA-256/SHA-512 utilities.

```bash
# 1. Preview. Dry run performs no writes and no network requests.
bash bootstrap-container.sh --dry-run

# 2. Build the marked Gentoo root and install scripts pinned to one ref.
sudo bash bootstrap-container.sh --pleiades-ref main

# Better for reproducibility: pin an exact reviewed commit and stage3 hash.
sudo bash bootstrap-container.sh \
  --pleiades-ref <40-character-reviewed-commit> \
  --stage3-sha512 <128-character-sha512>

# 3. Inspect the source/content receipt before configuration.
sudo cat root.x86_64/scripts/.pleiades-source-receipt

# 4. Install missing host units only after review. This does not enable/start them.
sudo bash bootstrap-container.sh \
  --pleiades-ref <reviewed-ref> \
  --install-host-services

# 5. Start and inspect through the reviewed helper.
bash install-scripts/gentoo-up.sh
bash install-scripts/gentoo-shell.sh
```

A custom source repository must be supplied explicitly:

```bash
sudo bash bootstrap-container.sh \
  --pleiades-repo https://github.com/example/pleiades.git \
  --pleiades-ref <reviewed-ref>
```

The bootstrap no longer guesses a fork from GitHub CLI authentication.

## WSL

WSL boot-file mutation is separate and default-off. `--install-wsl-boot` is accepted only when WSL is detected and `/usr/local/sbin/pleiades-runtime-monitor` already exists as an executable reviewed wrapper. The previous `/etc/wsl.conf` is copied to a timestamped backup before replacing only the `[boot]` command.

## Promotion boundary

A successful deterministic bootstrap test does not prove a production container. Promotion still requires:

- independently reviewed stage3 and Pleiades pins;
- disposable extraction and boot receipts;
- service-unit review;
- network and capability-policy validation;
- rollback and recovery testing;
- live Alienware/Lenovo integration evidence.

## AI assistance

Documentation and scaffolding were partly drafted with Claude (Anthropic) and ChatGPT (OpenAI). Maintainers remain responsible for testing, attribution, licensing, and security review.

---

MIT — [LICENSE](LICENSE) · [SECURITY.md](SECURITY.md)
