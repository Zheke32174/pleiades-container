# Pleiades Container — Agent Framework Integration

## agents-best-practices Framework

This repo follows the [agents-best-practices](https://github.com/DenisSergeevitch/agents-best-practices) framework.
All agent CLIs (Claude Code, Codex CLI, Gemini CLI, OpenCode) load this AGENTS.md on session start.

See the main [pleiades repo](https://github.com/Zheke32174/pleiades) for the cross-CLI harness rules
and [pleiades-factory-stack](https://github.com/Zheke32174/pleiades-factory-stack) for the AI/LLM tooling.

## Architecture

### MCP Servers
The container exposes these MCP servers (configured in `/workspaces/gentoo/pleiades-mcp-config.json`):
- `jcodemunch-mcp` — Token-efficient code exploration
- `fastapi-mcp` — FastAPI-based MCP endpoints
- `piia-engram` — Memory/retrieval MCP server

### Agent Scripts
The 9 agent scripts in `/scripts/` run inside the container:

| Script | Agent | Role |
|--------|-------|------|
| Maia.sh | Maia | Overseer, persistence, rehydration |
| Electra.sh | Electra | Fake environment / honeypot |
| Taygete.sh | Taygete | Credential monitor |
| Alcyone.sh | Alcyone | Recon, host bridge capability |
| Celaeno.sh | Celaeno | Watchdog, process guardian |
| Sterope.sh | Sterope | Cross-platform compatibility |
| Asterope.sh | Asterope | BSD compatibility layer |
| Merope.sh | Merope | System monitoring, threat detection |
| Atlas.sh | Atlas | Multi-language payload execution |

### Harness Level: Level 3 (Approval-gated actor)
- Read-only: automatic within project scope
- Write/mutate: explicit approval required
- Destructive: denied unless specifically authorized

## Third-Party Components

This project integrates:

| Component | License | Purpose |
|-----------|---------|---------|
| JCodeMunch MCP | MIT | Token-efficient code exploration (tools/jcodemunch-mcp) |
| fastapi_mcp | MIT | Python FastAPI MCP bridge |
| piia-engram | MIT | Agent memory/retrieval MCP server |
| box64 | MIT | x86_64 emulation on ARM64 |
| FEX | MIT | x86/x86_64 emulation on ARM64 |
| angr | BSD-2 | Binary analysis framework (tools/angr) |
| Ghidra | Apache-2.0 | Reverse engineering framework (tools/ghidra) |
| Claude Code | ToS | Agent CLI by Anthropic |
| Codex CLI | MIT | Agent CLI by OpenAI |
| Gemini CLI | ToS | Agent CLI by Google |
| OpenCode | MIT | Agent CLI by Nous Research |

## Quick Start

```bash
# Start the container
sudo gentoo-up

# Enter the container
gentoo-shell

# Check all agent services
systemctl list-units --type=service --state=running

# Run framework integration
sudo bash /scripts/install-boot-persistence.sh
```

## Credential Safety

This repo has been sanitized for public distribution.
No tokens, passwords, or API keys are included.
