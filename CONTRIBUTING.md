# Contributing

Pleiades Container accepts narrowly scoped improvements to bootstrap safety, host/guest lifecycle control, deterministic validation, documentation, and release reproducibility.

## Before opening a change

- Work from a clean checkout and dedicated branch.
- Do not commit container roots, stage3 archives, package caches, logs, credentials, private topology, personal data, or operational evidence.
- Keep shared Linux behavior separate from WSL-specific interoperability glue.
- Preserve the rule that normal bootstrap does not enable or start host services.
- Preserve the rule that host files are not silently overwritten.
- Do not add broad host bind mounts, container-engine sockets, secret stores, or privileged device access without an explicit authority and threat-model review.
- Prefer exact reviewed source commits and independently reviewed archive hashes in examples and tests.

## Required local checks

```bash
bash ci/check.sh
bash tests/test-bootstrap-container.sh
bash tests/test-install-host-service.sh
python3 ci/scan_public_repo.py
bash scripts/package_source.sh dist
(cd dist && sha256sum -c SHA256SUMS.txt)
```

Run strict ShellCheck across changed shell scripts. A real bootstrap or boot test belongs on a disposable Linux host, never on a production node merely to satisfy a pull-request gate.

## Pull-request evidence

Explain:

- the defect or limitation being corrected;
- affected host, guest, filesystem, network, or authority boundaries;
- whether behavior differs on bare Linux and WSL;
- exact tests and refusal cases added;
- migration and rollback behavior;
- whether host files, root markers, source receipts, release assets, or schemas change;
- any Gentoo, systemd, Pleiades-source, or downstream distribution obligations.

Do not describe a deterministic fixture as a real stage3 boot receipt. Do not describe a successful nspawn boot as proof of hostile-workload isolation.

## Compatibility and releases

Release identities are immutable. Do not edit an existing release to point at a new commit or replace an asset under the same version.

Changes to root markers, source receipts, host environment files, unit names, or command-line behavior require migration notes and rollback instructions.

The source release must not bundle a Gentoo stage3, built root filesystem, OCI image, VM image, credentials, or private configuration.

## Support expectations

This is a small experimental project. Public issues may be used for reproducible non-sensitive defects and documentation problems. Security-sensitive reports belong in GitHub's private vulnerability-reporting channel when available.

No response-time, production-support, platform-compatibility, or long-term maintenance guarantee is offered.
