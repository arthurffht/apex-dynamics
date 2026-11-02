# Setup

The supported workstation is Windows x86-64 with PowerShell 7, Git, and Roblox Studio. Core development requires no cloud credentials or paid runtime dependencies.

```powershell
./scripts/bootstrap.ps1 -InstallStudioPlugin
./apex.ps1 check
./apex.ps1 setup-agents
./apex.ps1 dev -AutoCheckpoint
```

The [development workflow](development-workflow.md) is the canonical command and synchronization reference. It explains Studio connection, host selection, background verification, GitHub checkpoints, diagnostics, research retrieval, and optional staging publishing.

`rokit.toml` pins the physics/build toolchain. `config/agent-tools.json` pins optional uv/Serena tooling and downloaded reference revisions. Bootstrap verifies committed release checksums. Agent setup installs external tools, trusts only this exact project for its reviewed Serena settings, and writes an ignored project MCP configuration with machine-specific paths.

GitHub CLI authentication uses `gh auth login --hostname github.com --git-protocol https --web`, followed by `gh auth setup-git`. Tokens remain in the CLI's credential storage. Initial setup uses repository-local no-reply author settings, LF line endings, fast-forward-only pulls, protected main, and linear merge history.

Open the generated sandbox and connect Rojo once. Enable the official Studio MCP and ChatGPT/Codex Quick Connect manually if interactive agent inspection is desired. The installed connector and local CLI are separate surfaces; check actual connections before claiming MCP availability.

Changing `config/engine.json` requires rebuilding and reopening the generated place because the relevant engine properties are not ordinary runtime setters. Changing only the simulation host requires a build/sync and Play restart. The current implementation rejects rollback Server Authority profiles rather than pretending a configuration flag makes the adapter replay safe.

No package framework, vector database, cloud publishing credential, or system-wide startup service is needed. Wally is available for future reviewed dependencies; the library currently has none.
