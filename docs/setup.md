# Development setup

The supported bootstrap target is Windows x86-64 with PowerShell 7. Roblox Studio is required for engine validation. GitHub authentication and Roblox authentication are separate.

## Toolchain

| Tool | Pinned version | Responsibility |
| --- | --- | --- |
| Rokit | 1.2.0 | Install project-specific CLI versions |
| Rojo | 7.7.1 | Build and synchronize Roblox instances |
| StyLua | 2.6.0 | Luau formatting |
| Selene | 0.32.0 | Static linting |
| Luau LSP | 1.70.1 | Strict Luau and Roblox type checking |
| Lune | 0.11.1 | Offline Luau tests and artifact inspection |
| Wally | 0.3.2 | Available for reviewed future runtime dependencies |
| GitHub CLI | 2.103.3 at initial setup | Repository and account operations |

`rokit.toml` is authoritative for project tools. The bootstrap pins Rokit and verifies its Windows release archive SHA-256 before executing it. Roblox definitions are downloaded from the pinned Luau LSP tag and verified independently. Upgrading a tool requires updating its pin and rerunning all checks.

```powershell
./scripts/bootstrap.ps1 -InstallStudioPlugin
./scripts/check.ps1
```

Bootstrap places Rokit in the user's `.rokit/bin` and sets the current process path. The initial machine setup also added that directory and the portable GitHub CLI directory to the user PATH; reopen terminals to inherit it. The portable CLI lives under `%LOCALAPPDATA%/ApexDynamics/tools/gh/bin`. No administrator installation is required.

## Git and GitHub

```powershell
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git
gh auth status
git remote -v
```

Authenticate using GitHub's device flow. Never paste tokens into this repository. Initial setup uses `main`, HTTPS, repository-local author settings, GitHub's no-reply author address, LF line endings, and fast-forward-only pulls. Existing global Git identity is preserved.

## Studio workflow

1. Build the sandbox with `scripts/check.ps1`.
2. Open `build/ApexDynamicsSandbox.rbxlx` in Studio as a dedicated development place.
3. Start `rojo serve default.project.json` in the repository.
4. Open the Rojo plugin and connect to `localhost:34872`.
5. Review the proposed synchronization tree and connect only to the dedicated sandbox.
6. Play and execute the protocols in `validation.md`.

Source-controlled code is authoritative on disk. Studio edits to synchronized scripts must be copied back deliberately before the next sync. The sandbox owns its generated map; use `package.project.json` to integrate just the library into another experience. No production place is published by these scripts.

The initial Studio MCP inventory returned no connected Studio instances. Connecting Studio's MCP server is an engine-validation prerequisite when using an agent to drive tests. Its availability must be checked again for each session; a CLI installation does not establish a Studio MCP connection.

## Optional tools and dependencies

Editor extensions are recommended in `.vscode/extensions.json`. Wally is installed, but the library currently has zero third-party runtime packages, so there is no empty package manifest or invented lockfile. Add one only with an actual dependency. Serena, vector databases, external memory servers, ECS frameworks, Open Cloud deployment, and extra package managers are deferred until a measured requirement justifies them.

Node.js is used only by optional research indexing. Core development and CI use PowerShell and the pinned Roblox/Luau tools. The original research scripts remain archived and are never executed automatically by import.
