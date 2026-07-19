# Privacy and Data Behavior

Pleiades Container does not include analytics, advertising, telemetry, account tracking, or a hosted control service.

## Local data

A real bootstrap can create or modify:

- the selected container root;
- `.pleiades-container-root` ownership metadata;
- `scripts/.pleiades-source-receipt` inside the guest root;
- optional host unit and root-binding files under `/etc/systemd/system` and `/etc/pleiades`;
- an optional timestamped `/etc/wsl.conf` backup;
- temporary download, extraction, and source-checkout directories that are removed by cleanup handlers;
- local validation and release-output directories chosen by the operator.

The source receipt contains the selected source repository, requested ref, resolved commit, and content-tree SHA-256. It does not intentionally contain credentials, but it can reveal repository choices and should be reviewed before sharing publicly.

## Network behavior

`--dry-run`, repository validation, deterministic tests, public-history scanning, and source-package generation are designed to run without contacting a Pleiades service.

A real bootstrap contacts:

- the configured Gentoo HTTPS mirror to resolve and download a stage3 and, unless independently pinned, its `DIGESTS` file;
- the configured Pleiades Git repository to resolve and fetch the selected ref.

Those services can observe ordinary connection metadata such as source IP address, requested resource, timing, and client behavior. Their privacy policies apply independently.

The bootstrap does not send receipts, host inventory, logs, or guest state back to the maintainer.

## Guest and host services

This repository prepares a Linux root and lifecycle unit. Data behavior of software later installed inside that guest is governed by that software and its configuration, not by this bootstrap repository.

Before enabling network-facing guest services, review their telemetry, logs, retention, credentials, data classes, and deletion behavior separately.

## Retention and deletion

There is no remote retention service operated by this repository.

To remove local host integration, stop and disable the service if necessary, remove the installed unit and `/etc/pleiades/container.env`, and run `systemctl daemon-reload`.

To remove the guest, delete the exact reviewed container-root path only after preserving anything intentionally retained. If WSL boot integration was used, restore or edit `/etc/wsl.conf` deliberately and remove unneeded timestamped backups.

GitHub Actions artifacts and releases are retained according to the workflow retention period and GitHub repository settings. Validation logs should contain synthetic fixture paths only; do not upload private host logs or real guest images.

## Sensitive information

Do not place credentials, private topology, personal data, evidence, production logs, database snapshots, or real container roots in public issues, pull requests, test fixtures, workflow artifacts, or releases.
