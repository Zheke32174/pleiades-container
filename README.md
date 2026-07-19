# Pleiades Container

> **Status:** experimental, working source infrastructure. The deterministic bootstrap and lifecycle helpers are tested in CI, but a disposable-host stage3 boot and rollback receipt is still required before production promotion.

Pleiades Container builds and manages a Gentoo `systemd-nspawn` root for bounded Pleiades Linux workloads. The host kernel, systemd, network policy, and Pleiades authority contracts remain sovereign; this repository is a replaceable execution substrate, not an authority broker.

## Download

Open the [GitHub Releases page](https://github.com/Zheke32174/pleiades-container/releases) and download the versioned source bundle:

`pleiades-container-<version>.tar.gz`

A proper release also contains:

- `SHA256SUMS.txt`;
- an SPDX 2.3 JSON source inventory;
- an exact-commit build receipt.

**No prebuilt root filesystem or image is distributed.** Releases contain the bootstrap source, lifecycle helpers, unit templates, tests, and documentation. They do not contain a Gentoo stage3, OCI image, VM image, or running Pleiades service.

Until the first verified asset-bearing tag is published, a clean reviewed checkout is the supported acquisition path:

```bash
git clone https://github.com/Zheke32174/pleiades-container.git
cd pleiades-container
bash bootstrap-container.sh --dry-run
```

## What is implemented

- deterministic option parsing with unknown and missing-value refusal;
- critical-host-path and unmarked-root refusal;
- non-root, no-network `--dry-run` planning;
- HTTPS Gentoo stage3 resolution;
- SHA-512 verification from an independent operator pin or Gentoo `DIGESTS`;
- archive absolute-path and parent-traversal rejection;
- disposable sibling extraction followed by atomic root placement;
- one explicitly selected Pleiades repository/ref resolved to an exact commit;
- installed-script content-tree receipt and drift refusal;
- default-off host systemd and WSL boot mutation;
- bounded `systemd-nspawn` lifecycle through one reviewed service unit;
- deterministic tests, strict ShellCheck, systemd-unit validation, public-history sensitivity scanning, and reproducible source packaging.

## What is not implemented or claimed

- no prebuilt or continuously published container image;
- no automatic production deployment;
- no automatic service enablement or startup;
- no proof that every Pleiades service is installed or healthy inside a freshly built guest;
- no claim that `systemd-nspawn` is a sufficient boundary for hostile public deception workloads;
- no Termux runtime—the Termux adapter is a separate repository;
- no embedded credentials, private topology, evidence, or private factory dependency.

## Repository layout

```text
VERSION                                  source-bundle version
bootstrap-container.sh                   verified root and script bootstrap
install-scripts/gentoo-up.sh             bounded start helper
install-scripts/gentoo-down.sh           bounded stop helper
install-scripts/gentoo-shell.sh          machinectl shell helper
install-scripts/install-host-service.sh  bind reviewed root to host unit
systemd/system/pleiades-container.service canonical nspawn lifecycle unit
systemd/container.env.example            host root-binding example
tests/                                   deterministic refusal/contract tests
ci/check.sh                               shell and unit invariants
ci/scan_public_repo.py                    public tree/history sensitivity gate
scripts/package_source.sh                 reproducible source packager
scripts/write_spdx_sbom.py                exact-commit SPDX source inventory
```

The removed `gentoo-nspawn.service` and `gentoo-pleiades-bridge.service` files are historical paths, not the maintained lifecycle. The canonical unit is `systemd/system/pleiades-container.service`.

## Supported hosts

The primary target is a systemd-based bare Linux host with `systemd-nspawn` and `machinectl`.

WSL is a Linux substrate and can be used when its systemd/nspawn capabilities are present. WSL-specific boot-command integration is optional and separate from the shared Linux bootstrap. Termux is not a systemd-nspawn host and exits toward the dedicated Termux adapter.

A real build requires root plus Git, curl, rsync, tar, `realpath`, `systemd-nspawn`, and SHA-256/SHA-512 utilities.

## Safe quick start

### 1. Inspect without writes or network access

```bash
bash bootstrap-container.sh --dry-run \
  --root /var/lib/machines/pleiades \
  --pleiades-ref <reviewed-commit>
```

### 2. Build a pinned root

Use an independently reviewed Pleiades commit and Gentoo stage3 SHA-512:

```bash
sudo bash bootstrap-container.sh \
  --root /var/lib/machines/pleiades \
  --pleiades-ref <40-character-reviewed-commit> \
  --stage3-sha512 <128-character-sha512>
```

Without `--stage3-sha512`, the bootstrap verifies transfer integrity against Gentoo's mirror-provided `DIGESTS`; that is weaker than an independently selected pin.

A custom source repository must be explicit:

```bash
sudo bash bootstrap-container.sh \
  --root /var/lib/machines/pleiades \
  --pleiades-repo https://github.com/example/pleiades.git \
  --pleiades-ref <reviewed-ref> \
  --stage3-sha512 <reviewed-sha512>
```

The bootstrap no longer guesses a repository from GitHub CLI authentication.

### 3. Review the installed-source receipt

```bash
sudo cat /var/lib/machines/pleiades/scripts/.pleiades-source-receipt
```

The receipt records source repository, requested ref, resolved commit, and installed content-tree SHA-256. Reruns refuse altered or differently pinned script trees unless `--update-scripts` is explicit.

### 4. Install the host lifecycle without starting it

Use the dedicated helper so the service unit and exact root binding are installed together:

```bash
sudo bash install-scripts/install-host-service.sh \
  --root /var/lib/machines/pleiades \
  --dry-run

sudo bash install-scripts/install-host-service.sh \
  --root /var/lib/machines/pleiades
```

The helper:

- requires the Pleiades root marker and Linux-root shape;
- refuses critical paths and ambiguous whitespace-bearing paths;
- refuses to overwrite a differing host unit or root binding;
- writes `/etc/pleiades/container.env` atomically;
- runs `systemctl daemon-reload`;
- does not enable or start the service.

`bootstrap-container.sh --install-host-services` remains as a compatibility path that installs unit files only. The dedicated helper is the recommended public path because it binds the reviewed root explicitly.

### 5. Start, inspect, and stop deliberately

```bash
sudo systemctl start pleiades-container.service
bash install-scripts/gentoo-up.sh
bash install-scripts/gentoo-shell.sh
bash install-scripts/gentoo-down.sh
```

Review `systemctl status pleiades-container.service` and `machinectl status pleiades` during validation. Do not enable persistent startup until boot, health, network, and rollback receipts are satisfactory.

## Existing roots and updates

An existing root is refused unless it has the Pleiades marker. After inspecting a legitimate Linux root, `--adopt-existing-root` permits marking it.

A changed source pin or modified installed script tree is refused. After reviewing the delta, `--update-scripts` permits replacement and writes a new receipt.

The host-install helper refuses differing `/etc/systemd/system/pleiades-container.service` and `/etc/pleiades/container.env` files rather than silently replacing operator state.

## WSL boundary

`--install-wsl-boot` is default-off and valid only when WSL is detected. It requires an already reviewed executable `/usr/local/sbin/pleiades-runtime-monitor`, backs up the existing `/etc/wsl.conf`, and replaces only the `[boot]` command.

Shared bootstrap, verification, receipt, and lifecycle logic is Linux-first. Only the boot-command bridge is WSL-specific.

## Security boundary

`systemd-nspawn` provides namespacing and lifecycle control, not a complete hostile-workload sandbox. The unit applies bounded tasks, CPU and memory, private veth networking, restart limits, orderly shutdown, and OOM stop behavior, but the host kernel remains shared.

Do not expose untrusted public deception workloads through this substrate without a separately reviewed disposable isolation boundary. Do not mount host secrets, evidence stores, container engines, or broad host paths into the guest.

See [SECURITY.md](SECURITY.md) for the threat model and reporting route, [PRIVACY.md](PRIVACY.md) for local/network data behavior, and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for Gentoo/systemd/upstream boundaries.

## Validation and promotion

CI proves shell parsing, strict linting, deterministic refusal behavior, service-unit invariants, configured sensitivity patterns across the public tree/history, and reproducible source packaging.

CI does not prove a real Gentoo download, extraction, boot, package installation, guest-service health, network isolation, WSL restart, or rollback. Before promotion, capture a disposable-host receipt covering:

1. independently reviewed stage3 and Pleiades pins;
2. verified download and staged extraction;
3. exact installed-source receipt;
4. second-run idempotency and drift refusal;
5. host-unit/root binding installation;
6. controlled boot, shell access, stop, and restart;
7. network and capability inspection;
8. rollback and complete removal.

## Update, rollback, and removal

Update this source utility by moving to a reviewed tag or commit. Update the guest scripts separately with an explicit reviewed source ref and `--update-scripts`.

Rollback by restoring the prior source release, prior reviewed Pleiades pin, and prior root backup or disposable snapshot. The bootstrap does not create a rollback snapshot for you.

To remove the host lifecycle:

```bash
sudo systemctl disable --now pleiades-container.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/pleiades-container.service
sudo rm -f /etc/pleiades/container.env
sudo systemctl daemon-reload
```

Remove the container root only after confirming the exact path and preserving anything intentionally retained:

```bash
sudo rm -rf -- /var/lib/machines/pleiades
```

The repository does not install a package-manager entry, daemon, account, credential, or remote control plane.

## Contributing and support

See [CONTRIBUTING.md](CONTRIBUTING.md) and [CHANGELOG.md](CHANGELOG.md). This is an experimental small-maintainer project; no response-time, production-support, or long-term compatibility guarantee is offered.

## License

Pleiades-owned source in this repository is MIT licensed. Gentoo stage3 artifacts, systemd, and fetched Pleiades source remain governed by their own licenses and notices. This repository's source releases do not bundle those external artifacts.
