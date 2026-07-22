# Public Release-Readiness Checkpoint

Repository: `Zheke32174/pleiades-container`  
Draft branch: `hardening/host-binding-transaction-v1`  
Draft pull request: `#9`  
Stack base: PR `#6` over PR `#5`  
Default branch changed: no  
Live host modified: no  
Release authority exercised: no

## Last reviewed heads and receipts

- Last fully validated implementation head before workflow hardening: `8eaf60a2392d1c457cdc7c42fc8be9b598fdba73`
- Exact successful CI run for that head: `29709096507`
- Workflow-hardening head: `ce2adb796e0b70f4e2b3ea7899a5f98d434b5734`
- Exact-head validation for the workflow-hardening head: pending

## Completed scope

- Consolidated the managed container lifecycle and reproducible construction path through the stacked drafts.
- Corrected public claims so the repository describes source bootstrap and lifecycle material, not a bundled stage3, root filesystem, OCI image, VM image, or running service.
- Added deterministic source packaging, checksums, SPDX source inventory, and exact-source build receipts.
- Added current-tree and reachable-history sensitivity scanning with exact reviewed historical exceptions.
- Added a canonical host-service installer that validates the marked Linux root and never starts or enables the service.
- Made host binding transactional: destination compatibility is checked before dry-run success, symlinks are refused, files are staged before publication, and newly created files are removed if later publication or daemon reload fails.
- Added `--settings=no` to the canonical `systemd-nspawn` invocation so ambient host `.nspawn` files cannot silently expand the reviewed runtime contract.
- Pinned retained third-party Actions to full commit identities.
- Replaced mutable `ubuntu-latest` runners with `ubuntu-24.04`.
- Disabled persisted checkout credentials in read-only CI and the tag workflow.
- Bound release tags to commits reachable from `main`.
- Extended the tag workflow to execute the host-binding tests and to build the complete source assets twice before publication.
- Added consumer-facing checksum and GitHub release-asset verification commands.

## Validation receipts

At head `8eaf60a2392d1c457cdc7c42fc8be9b598fdba73`, CI run `29709096507` passed the complete source gate then present on the branch, including:

- Python helper compilation;
- shell parsing and ShellCheck;
- repository invariants;
- bootstrap fixtures;
- transactional host-binding fixtures;
- current-tree and reachable-history sensitivity scanning;
- deterministic double-build packaging;
- byte-for-byte asset comparison;
- checksum-manifest verification;
- exact-head candidate upload.

The current head requires a fresh exact-head receipt because workflow behavior changed. No release workflow has been executed; doing so would require a tag and publication authority outside this checkpoint.

## External practices applied

- Full-SHA GitHub Action references and least-privilege ordinary CI.
- Fixed runner image identity for reproducible validation inputs.
- Consumer verification of downloaded release assets, rather than checksums that only the publisher checks.
- Tag ancestry validation against the reviewed default branch.
- Explicit suppression of ambient `systemd-nspawn` settings for the canonical runtime contract.
- Candidate-only validation until a separately authorized disposable prerelease proves the real release path.

Primary references reviewed:

- GitHub artifact attestations: https://docs.github.com/en/actions/concepts/security/artifact-attestations
- GitHub release integrity verification: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/verify-release-integrity
- GitHub immutable releases: https://docs.github.com/en/enterprise-cloud@latest/code-security/concepts/supply-chain-security/immutable-releases
- systemd `.nspawn` settings discovery and `--settings=` behavior: https://www.freedesktop.org/software/systemd/man/systemd.nspawn.html

## Open blockers

1. The current workflow-hardening head needs one complete exact-head CI receipt.
2. PRs `#5`, `#6`, and `#9` must be reviewed and integrated in dependency order; the top branch must not be merged independently onto `main`.
3. A disposable Linux host must prove the pinned stage source, safe construction, boot, lifecycle commands, networking assumptions, second-run behavior, drift refusal, host-binding rollback, and cleanup.
4. One explicitly authorized disposable prerelease must prove actual GitHub assets, checksums, consumer verification, overwrite refusal, and download instructions.
5. Artifact attestations remain deferred until the prerelease includes a consumer verification step; generating unconsumed attestations would not close a release gate.
6. Branch protection, full-SHA Action policy, immutable-release configuration, and private vulnerability reporting require administrative verification.
7. Recursive dependency and source-lock policy must be revisited if the release begins bundling submodules, language packages, a stage3, or a built root filesystem.

## Deferred work

- Add GitHub/Sigstore provenance attestations only with an explicit verification contract and prerelease receipt.
- Decide whether immutable releases should be enabled after confirming the draft-first publication workflow and administrative policy.
- Consider offline attestation bundles only if disconnected distribution becomes a supported use case.
- Consider systemd portable-service or system-extension packaging only if the architecture changes from source bootstrap to a distributable host image; do not import that model merely for fashion.

## Reconsideration triggers

Reprocess this repository when any of the following changes:

- top stacked branch head;
- CI, sensitivity, dependency, or advisory result;
- source or stage-artifact acquisition model;
- public distribution claims or bundled artifact types;
- systemd-nspawn or host-service authority;
- release or attestation policy;
- disposable-host or prerelease evidence;
- explicit steward instruction.

## Next action

Inspect CI for the exact current head. If it passes, stop ordinary source reprocessing and retain `HOLD` for stacked integration, disposable-host validation, administrative settings, and one authorized prerelease. If it fails, repair only the exact workflow or source defect on this same branch.
