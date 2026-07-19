# Changelog

This project uses semantic versioning for the Pleiades-owned bootstrap, lifecycle, validation, and source-release tooling. Gentoo stage3 and fetched Pleiades revisions are versioned and reviewed separately.

## Unreleased

- Complete a disposable-host stage3 download, extraction, boot, second-run, drift-refusal, stop, restart, and rollback receipt.
- Verify the first immutable `v0.2.0` GitHub Release assets after stacked review and integration.

## 0.2.0

Public distribution and lifecycle hardening:

- consolidate the canonical `systemd-nspawn` lifecycle, deterministic bootstrap, and MODOS substrate declaration;
- refuse unsafe host paths, unmarked roots, ambiguous arguments, dirty source state, and archive traversal;
- verify Gentoo stage3 SHA-512 before disposable staged extraction;
- pin one explicit Pleiades source ref to an exact commit and content-tree receipt;
- keep host-unit and WSL boot mutation default-off;
- add a dedicated host installer that atomically binds the reviewed root to the canonical service and never enables or starts it;
- remove stale public claims about legacy units and unproven guest services;
- state clearly that no prebuilt root filesystem, OCI image, VM image, or running service is distributed;
- add public-tree and reachable-history sensitivity scanning;
- add deterministic source packaging, SHA-256 verification, SPDX 2.3 inventory, and exact-commit build receipt;
- replace mutable branch-triggered showcase releases with immutable tag-only releases containing named assets;
- add tailored security, privacy, provenance, contribution, update, rollback, removal, and support documentation;
- consolidate validation into one pull-request workflow to reduce duplicate notifications.

`0.2.0` is not considered published until the reviewed tag produces and verifies the named source archive and accompanying verification assets.

## Historical state

Earlier repository revisions contained overlapping tmux-oriented lifecycle units, a telemetry bridge unit, broad service claims, and a mutable release workflow that could update `v0.1.0` from ordinary branch pushes while advertising a moving image that was not actually built here.

Those historical paths remain part of Git history for provenance but are not the maintained release surface. Existing historical tags or releases must not be overwritten to impersonate the verified `0.2.0` checkpoint.
