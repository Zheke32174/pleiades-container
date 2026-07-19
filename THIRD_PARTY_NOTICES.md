# Third-Party Notices

This repository contains Pleiades-owned bootstrap, lifecycle, validation, packaging, and documentation source under the MIT License.

It references or downloads external projects but does not include them in its source releases.

## Gentoo Linux

A real bootstrap can download a Gentoo Linux stage3 archive from a configured mirror. Gentoo artifacts remain governed by Gentoo's licenses, notices, trademarks, package metadata, and mirror terms.

This repository does not redistribute a Gentoo stage3, root filesystem, package set, or generated guest image. Before distributing a built root or derivative image, review the exact stage3 and installed package licenses and preserve all required notices and corresponding-source obligations.

## systemd

The lifecycle uses host-provided `systemd`, `systemd-nspawn`, `machinectl`, and systemd unit semantics. Those programs are not bundled here and remain governed by the licenses and notices of the host distribution and upstream systemd project.

The maintained runtime no longer depends on tmux. Historical repository material may still mention it, but current source releases do not include or require it.

## Pleiades source

The bootstrap can fetch a selected revision from the public `Zheke32174/pleiades` repository or from another explicitly supplied Git repository. That fetched source is not bundled into this repository's release assets. Its license, notices, dependencies, and data behavior must be reviewed separately at the exact resolved commit.

## GitHub Actions

Repository workflows use GitHub Actions such as `actions/checkout` and `actions/upload-artifact`. Their source, licenses, and GitHub-hosted execution terms apply independently. Action references require routine review and should not be treated as part of the MIT-licensed runtime source merely because the workflow invokes them.

## Distribution obligations

The absence of vendored third-party source in this repository does not eliminate downstream obligations. A built Gentoo root, derivative image, redistributed package cache, modified external component, or hosted network service can carry separate license, notice, source-availability, trademark, and acceptable-use requirements.

Review the exact artifacts and deployment model before redistribution. Do not rely on a catalog entry, package name, or this notice as a legal conclusion.

## No implied approval

Mentioning, downloading, verifying, or booting an external artifact does not establish that it is safe, supported, licensed for every downstream use, or approved for production deployment.

The source-release build receipt explicitly states that no Gentoo stage3, built container root, OCI image, VM image, or running service is included.
