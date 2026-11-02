# Integrated development workflow

## Decisions

The immediate deliverable is the project foundation and laboratory described in system-design.md and laboratory.md. The default place starts the infrastructure suite without spawning a vehicle; earlier vehicle code is an opt-in measurement fixture.

The local filesystem is the source of truth for managed code and configuration. Rojo synchronizes that source into a dedicated local Studio place. GitHub receives verified commits through branches and pull requests. A Roblox cloud place is a versioned staging destination, not a second editable codebase.

The default vehicle simulation host is **Server**. An explicitly selectable **Client** mode assigns conventional ownership to the current driver and runs the same `Vehicle` adapter on that client. An unoccupied vehicle and stale-input fallback remain server simulated. These two modes use engine `AuthorityMode.Automatic`; neither is Roblox's predicted/rollback Server Authority architecture.

`config/engine.json` declares non-scriptable engine settings. The generator serializes those properties into the place, avoiding an unsupported runtime/MCP setter. Current defaults are Automatic authority, disabled fixed-simulation rollout, and Fixed native physics stepping. A rollback authority profile is rejected until the vehicle has replay-safe state and compatible API access. Requested serialized settings and observed behavior must remain distinct in reports.

## One command surface

Run commands from PowerShell 7 in the repository root.

| Command | Result |
| --- | --- |
| `./apex.ps1 doctor` | Tool, Git, Studio installation, profile, and source diagnostics; records local JSON |
| `./apex.ps1 build` | Generate the active Rojo project, source fingerprint, place, library, and artifact receipts |
| `./apex.ps1 check` | Formatting, lint, strict types, numerical invariants, builds, artifact checks, and harness checks |
| `./apex.ps1 studio -Suite Smoke` | Short engine support check |
| `./apex.ps1 studio -Suite Foundation` | Current lab's shared infrastructure checks, no vehicle |
| `./apex.ps1 studio -Suite Regression` | Engine integration battery with time-series evidence |
| `./apex.ps1 studio -Suite Research` | Regression plus fleet-cost and slope-creep characterization; failed research targets return failure |
| `./apex.ps1 studio -Suite Multiplayer` | Two-client driver authorization, ownership, single simulator, and stale-input fallback |
| `./apex.ps1 studio -Suite Audit` | Exercise exact-source drift, unexpected-script detection, and stale-runtime detection in an isolated place |
| `./apex.ps1 test -Suite Regression` | Offline checks followed by the selected Studio suite |
| `./apex.ps1 mode -Mode Server` | Select server execution, rebuild, then restart Play |
| `./apex.ps1 mode -Mode Client` | Select driver-owned execution, rebuild, then restart Play |
| `./apex.ps1 dev` | Start local Rojo, absolute sourcemap watching, and background offline verification |
| `./apex.ps1 dev -AutoCheckpoint` | Also commit and push stable, passing changes to a branch/PR |
| `./apex.ps1 dev -StudioChecks -AutoCheckpoint` | Offline plus isolated Foundation gates before a branch/PR checkpoint |
| `./apex.ps1 stop` | Stop only verified project-owned development processes |
| `./apex.ps1 sync -Message 'Describe the change'` | Verify a stable worktree, commit, push, and create/reuse a PR |
| `./apex.ps1 status` | Show Git and development-session state |
| `./apex.ps1 audit` | Generate an exact-source probe to run through the official Studio MCP |
| `./apex.ps1 research -Query 'implicit'` | Retrieve curated decisions and bounded original research excerpts |
| `./apex.ps1 setup-agents` | Install pinned optional agent tools and generate local project MCP configuration |
| `./apex.ps1 references` | Fetch exact pinned research/tooling repositories without overwriting local changes |
| `./apex.ps1 publish` | Show staging configuration/plan; no upload |
| `./apex.ps1 publish -Execute -Evidence <report.json>` | Publish only an explicitly configured staging target after release checks |

The legacy `scripts/check.ps1` and `scripts/studio-smoke.ps1` entry points remain compatible. The smoke wrapper delegates to the single maintained suite/runner rather than keeping a duplicate test implementation.

## Source, build, and runtime identity

`package.project.json` defines the library mapping once. The sandbox composes that library and adds its development metadata. `default.project.json` is the canonical map; `.local/generated/active.project.json` is a generated machine-local derivative with absolute paths, explicit engine settings, a localhost binding, and `servePlaceIds = [0]`.

Builds hash normalized source/configuration into a fingerprint and hash the resulting XML place and binary model. Studio tests reject stale source and changed artifacts before launch. Reports preserve the source snapshot, suite identity, engine executable version, observed case results, and time-series data. No successful process exit is accepted without a structured report and completion marker.

Rojo keeps managed script sources current after its plugin connects. Lua modules already required during Play can remain cached, so editing source is not proof that the running vehicle executes the new code. The sandbox records its runtime source fingerprint. The audit probe distinguishes source drift from a runtime that needs a Play restart, and detects unexpected scripts inside the managed package.

MCP edits to managed scripts must be reconciled back to source deliberately. Reconnect/rebuild from source to repair drift; do not set up competing two-way synchronization loops. Studio-authored assets require an explicit export/import decision before they become source controlled.

## Background behavior and GitHub

The watcher waits for stable edits, verifies once, and records the outcome in `.local/dev-health.json`. Unchanged failures wait for a new edit instead of retrying forever. An edit during verification cancels its checkpoint. Ignored caches, credentials, downloaded references, and build artifacts do not affect the worktree fingerprint or enter a commit.

The watcher also verifies its initial state on startup. With `-StudioChecks`, the isolated Foundation suite is part of the local verification gate before any optional checkpoint. This does not edit or run Play in the owner's currently open places. Full physics/latency/soak suites remain separately selected work.

Checks, standalone builds, and isolated Studio runs share a repository-local exclusive file lease. A concurrent verifier waits with a deadline rather than overwriting an artifact being tested. The OS releases the lease if the owning process exits; the ignored lock file is not a persistent busy flag.

With `-AutoCheckpoint`, changes from clean `main` go to a new work branch. Further edits update that branch and PR. The watcher does not force-push, merge `main`, change branch protection, or publish cloud versions. A failing local check remains visible locally; it does not become a falsely verified GitHub checkpoint. CI independently checks every PR and main commit.

The session is scoped to this repository and current login. Repeating `dev` updates verification options by replacing only the owned watcher, preserving Rojo's connection and sourcemap process. Use `stop` when deliberately disconnecting all project services. Process cleanup verifies both the recorded PID and its expected project argument before terminating the owned process tree. Start `dev` again after a machine restart; no system-wide background agent was installed.

Transport processes launch the pinned native Rojo binary from Rokit's managed storage, so recorded PIDs identify the actual server/sourcemap executables rather than tool-manager launchers. The pinned version is read from rokit.toml and checked before launch. The watcher checks process ownership at least every 15 seconds while idle and again before declaring verification successful; missing/mismatched/stopped transports make aggregate health fail even if an earlier code check passed. A healthy PID is still not proof of a connected Studio plugin.

## MCP and agent context

The existing official `Roblox_Studio` connector is reused. Its process being installed is not a live connection. In Studio, the owner enables **Assistant → Settings → MCP Servers → Enable Studio as MCP server**, and the ChatGPT/Codex Quick Connect option. The [official Roblox plugin](https://github.com/Roblox/roblox-studio-agent-plugin) documents this setup. A connector inventory must name the intended place before live inspection or edits.

Only the dedicated `ApexDynamicsSandbox.rbxlx` instance is in scope. The owner's separate `Place1` is excluded from inspection, edits, Play, and process cleanup. Enabling MCP in another Studio window does not establish access to the Apex sandbox.

Serena 2.1.0 is installed as external agent tooling, with Luau LSP supplied by the pinned project toolchain. Its actual MCP symbol lookup was exercised against `Tire.stepWheel`. The generated `.codex/config.toml` uses an absolute project launcher so desktop working-directory differences do not activate another repository. Machine paths stay ignored. Project MCP configuration is loaded in a new trusted Codex session; see [official MCP configuration](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).

The repository skill `.agents/skills/apex-engineering` supplies the workflow; `AGENTS.md` stays short. Persistent technical facts live in `docs/STATE.md`, ADRs, source-linked research decisions, and measurement reports. Serena caches/memories are local conveniences, not another authority for project facts.

## Research integration

`docs/research/integration-map.json` maps source sections and equation IDs to implementations and tests. Use it to find the relevant contract without rereading the compiled corpus. The consolidated engineering guide is the primary operational source; the larger overlapping manual is preserved for historical provenance. Original archives remain immutable local inputs with a public metadata catalog.

Downloaded Serena and official Roblox plugin repositories live under ignored `.local/references` at commits pinned in `config/agent-tools.json`. They are research/tooling references, not nested active projects or runtime dependencies. No external simulator implementation was copied into the MIT library.

## Staging cloud boundary

Cloud publishing is prepared but unconfigured. Copy `config/cloud.example.json` to ignored `.local/cloud.json`, select an owned staging universe/place, and supply `ROBLOX_API_KEY` through the environment. The helper requires a clean main commit, passing CI, matching required Studio regression evidence, and an unchanged build receipt. It records the published version and source/artifact hashes locally.

The [Open Cloud publishing API](https://create.roblox.com/docs/cloud/guides/usage-place-publishing) updates an existing place and requires its identifiers and scoped access. This workflow does not create a Roblox account or API key, infer a destination, or claim a cloud deployment without a returned version. Production publishing is outside this helper. Local development and multiplayer tests need no cloud key.
