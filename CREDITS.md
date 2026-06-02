# Credits and Third-Party Attribution

Every external project, developer, or organization whose work is used, cloned,
installed, wrapped, or referenced by pleiades-container is listed here.

**No third-party source code is vendored in this repository.** All external
tools are cloned or installed from upstream at setup time.
See `THIRD_PARTY_NOTICES.md` for the formal statement.

---

## Container Infrastructure

| Project | Author / Org | License | Source URL | Usage Type | Vendored? | Modified? | Local Path |
|---------|-------------|---------|-----------|-----------|-----------|-----------|------------|
| Gentoo Linux | Gentoo Foundation | Various (GPL-2.0+, MIT, etc.) | https://www.gentoo.org | stage3 rootfs downloaded by `bootstrap-container.sh` — base OS for nspawn container | No | No | N/A |
| systemd-nspawn | systemd project | LGPL-2.1+ | https://github.com/systemd/systemd | container runtime; host binary invoked by `gentoo-up.sh` and `bootstrap-container.sh` | No | No | N/A |
| tmux | Nicholas Marriott et al. | ISC | https://github.com/tmux/tmux | session manager; invoked by `gentoo-up.sh` to daemonize nspawn | No | No | N/A |

## Agent Framework References

| Project | Author / Org | License | Source URL | Usage Type | Vendored? | Modified? | Local Path |
|---------|-------------|---------|-----------|-----------|-----------|-----------|------------|
| agents-best-practices | DenisSergeevitch | MIT | https://github.com/DenisSergeevitch/agents-best-practices | structural reference cited in `AGENTS.md` — no source copied | No | No | N/A |

## Companion Repositories (not vendored)

| Project | Author / Org | License | Source URL | Usage Type | Vendored? | Modified? | Local Path |
|---------|-------------|---------|-----------|-----------|-----------|-----------|------------|
| pleiades | Zheke32174 | MIT | https://github.com/Zheke32174/pleiades | cloned into container at setup time by `bootstrap-container.sh` | No | No | N/A |
| pleiades-factory-stack | Zheke32174 | MIT | https://github.com/Zheke32174/pleiades-factory-stack | referenced for AI/LLM tooling — see its own CREDITS.md | No | No | N/A |

---

## No Vendored Third-Party Source

This repository does not vendor source code from any third-party project.
Every external tool listed above is downloaded or cloned from its upstream
source at setup time. See `THIRD_PARTY_NOTICES.md`.
