# Security Policy

## Project status

Pleiades Container is experimental source infrastructure for building and operating a Gentoo `systemd-nspawn` guest. It is not a hardened hostile-workload sandbox, managed hosting service, production appliance, or substitute for a disposable VM or microVM boundary.

Only the current reviewed default branch and the most recent verified source release are eligible for fixes. Historical tags, local roots, fetched Gentoo stages, fetched Pleiades snapshots, and operator-modified units are unsupported unless a reproducer demonstrates the issue on a current reviewed revision.

## Report vulnerabilities privately

Use GitHub's private vulnerability-reporting or Security Advisory interface when available. Do not publish credentials, private topology, host paths, personal information, guest images, logs, or exploit-ready details in a public issue.

A useful report includes:

- affected repository commit or release;
- host distribution, systemd version, and whether the host is bare Linux or WSL;
- exact bootstrap arguments with sensitive values removed;
- stage3 and Pleiades source identities;
- whether the root was new, adopted, or updated;
- expected and observed behavior;
- impact on host paths, archive extraction, source receipts, unit installation, lifecycle control, networking, or rollback.

No response-time or remediation-time guarantee is offered.

## Trust boundaries

The repository is expected to:

- refuse critical host paths and unmarked existing roots;
- perform no writes or network activity in `--dry-run` mode;
- require HTTPS for the Gentoo mirror;
- verify the stage3 SHA-512 before extraction;
- reject absolute and parent-traversal archive paths;
- extract into a disposable sibling directory before final placement;
- resolve one explicitly selected Pleiades source ref to an exact commit;
- record installed-source and content-tree identities;
- refuse source drift unless an update is explicit;
- keep host unit and WSL boot changes opt-in;
- refuse overwriting differing host unit or root-binding files;
- never enable or start the service as part of installation;
- publish source releases only from immutable matching version tags with checksums, an SPDX inventory, and a build receipt.

The operator remains responsible for the selected Gentoo mirror and pin, the selected Pleiades source, host privileges, network policy, guest configuration, backups, and final promotion.

## systemd-nspawn limitations

`systemd-nspawn` shares the host kernel. Namespaces, cgroups, resource limits, private veth networking, restart limits, and orderly lifecycle control reduce accidental damage but do not create a complete boundary against a malicious or kernel-exploiting guest.

Do not use this substrate as the final isolation boundary for hostile public deception workloads, untrusted binaries, or workloads that require strong tenant separation. Use a disposable VM, microVM, or equivalent separately reviewed boundary.

Do not bind-mount broad host paths, container-engine sockets, credentials, evidence stores, SSH material, or privileged device interfaces into the guest.

## Stage3 and archive risk

Mirror-provided `DIGESTS` verifies transfer consistency with the same mirror. It is not equivalent to an independently selected trusted pin. For promotion-quality work, supply `--stage3-sha512` from a separately reviewed source.

SHA-512 and path inspection do not prove that the archive is benign, current, licensed for the intended use, or free from unsafe device nodes, setuid content, package vulnerabilities, or configuration defects. Inspect the extracted root and validate boot in a disposable host before promotion.

## Source and update risk

A branch or tag name can move. Prefer a reviewed 40-character commit for `--pleiades-ref`. The installed receipt records the resolved commit and content-tree hash; preserve that receipt with validation evidence.

`--adopt-existing-root` and `--update-scripts` are explicit authority escalations. Use them only after inspecting the existing root or source delta. They are not repair shortcuts.

## Host installation risk

The recommended `install-scripts/install-host-service.sh` binds one marked reviewed root to the canonical unit. It refuses differing existing host files and never enables or starts the service.

The compatibility `bootstrap-container.sh --install-host-services` path installs unit files only. Operators using it must separately review `/etc/pleiades/container.env`; otherwise the unit's built-in root default may not match a custom bootstrap root.

WSL boot integration is separately opt-in, requires a pre-existing reviewed wrapper, and backs up `/etc/wsl.conf`. Review the backup and resulting `[boot]` command before restarting WSL.

## Sensitive information

Do not commit or publish:

- API keys, access tokens, passwords, cookies, private keys, or real `.env` data;
- private hostnames, addresses, tailnet names, local usernames, or internal URLs;
- container roots, archives, database snapshots, evidence, logs, crash dumps, or screenshots containing private data;
- generated source receipts or state files without redaction and review;
- realistic secret fixtures that could be mistaken for live material.

CI scans the current tracked tree and reachable Git history for configured credential, private-topology, and host-local patterns. That is a review aid, not a proof of absence. If a real secret entered history, revoke or rotate it before deciding whether history rewriting is required.

## Release integrity

A valid source release must:

1. originate from a tag equal to `v$(cat VERSION)`;
2. pass shell syntax, strict ShellCheck, deterministic refusal tests, unit validation, and public-history scanning;
3. build the exact source package twice byte-for-byte;
4. include `SHA256SUMS.txt`, an SPDX 2.3 JSON source inventory, and an exact-commit build receipt;
5. state that no Gentoo stage3, root filesystem, OCI image, or running service is included;
6. refuse to overwrite an existing release identity.
