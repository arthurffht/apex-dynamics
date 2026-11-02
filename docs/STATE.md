# Project state

Updated: 2026-11-01.

## Objective and decisions

Build a validated open-source Roblox vehicle dynamics library with professional English source and documentation. Local source plus Rojo is canonical; GitHub stores verified history and PRs. Local Studio is the primary laboratory. Cloud publishing is a separate staging promotion with explicit target IDs and credentials.

The default simulation host is Server. `apex.ps1 mode -Mode Client` selects an experimental driver-owned comparison using the same adapter. Both use conventional Automatic engine authority. Rollback Server Authority is rejected until replay-safe state/API integration exists. Non-scriptable engine settings are serialized through `config/engine.json` and a generated place; engine-profile changes require reopening that place.

## Integrated workflow

- `apex.ps1` is the root command surface; read `docs/development-workflow.md` for commands and state boundaries.
- One library mapping, one shared vehicle factory, one maintained Studio suite/runner, generated source/artifact fingerprints, and exact-source/runtime drift auditing replace parallel copies of setup logic.
- Rojo, sourcemap watching, and background verification can run in a repository-scoped development session. Optional `-AutoCheckpoint` commits/pushes passing stable edits to a branch/PR; it never merges main or publishes Roblox.
- The public GitHub remote is `arthurffht/apex-dynamics`, with authenticated CLI access, protected main, linear history, CI, a validation milestone, and a research/physics backlog. Check the current workflow result instead of assuming an older green commit validates a new one.
- A repository agent skill, source-linked research map, and Serena 2.1.0/Luau LSP integration provide selective context. Actual Serena MCP lookup of `Tire.stepWheel` succeeded with 23 tools exposed. Machine-specific Codex MCP configuration is generated locally for a new trusted session.
- The three original inputs and 122 extracted research files remain immutable local provenance. The consolidated guide is the operational entry point; the overlapping master manual is historical reference. Two downloaded tooling repositories are pinned under ignored `.local/references`; they are not nested runtime projects.

## Verified evidence

- Offline: 18 named physics/policy cases, 32,122 assertions, strict pure/Roblox types, lint/format, two builds, serialized engine-property checks, artifact receipts, and development-harness behavior.
- Local engine regression: static support, drop recovery, signed launch/braking, forward/reverse symmetry, steering direction, airborne contact, rejected dt/hitch guard, and dynamic-ground momentum passed their declared integration gates.
- Engine SI impulse: 2.0000001144 m/s observed for 2 m/s expected; assembly mass 1400.0000547 kg for 1400 kg configured.
- Two-client localhost tests: eight ownership/input checks passed separately in Server and Client modes. The client run observed 129 driver-client steps, zero other-client steps, and zero server steps in its driver window; stale input reclaimed server ownership and applied brakes.
- Exact-source audit: seven checks passed, including deliberate source drift, an unexpected package script, and missing/stale runtime identity.
- Eight-vehicle characterization: about 0.896 ms p95 for adapter calls in a short local Studio run; no full solver/mobile capacity conclusion follows.
- **Failed research target:** the parked vehicle moved 0.1178225 m over 8 s on a 10% grade, exceeding the 0.01 m characterization target. Preserve this failure; static-contact modeling remains open.

Machine-readable reports and their limits are in `docs/experiments/2026-11-01-integrated-workflow`. Earlier static-support evidence remains as historical provenance. Reports identify their actual source snapshots rather than claiming all runs used the latest commit.

## Access and remaining limits

Studio MCP is responding, but its latest inventory exposes only `Place1`, a separate project explicitly excluded by the owner. Do not inspect, edit, playtest, or close that instance. The Apex sandbox is open in a separate Studio process; live auditing is pending its own MCP registration. A running Rojo server is not proof that a particular Studio plugin session is connected; use the source audit and runtime fingerprint after connection.

The latest local `doctor` attempt was blocked by Windows Defender AMSI with `HackTool:PowerShell/ApexToolkit.A`, identifying `scripts/lib/Project.psm1`. No Defender settings, exclusions, or script execution bypasses were applied. The development session remains stopped. Earlier numerical/Studio results remain valid for their recorded snapshots; local harness availability must be revalidated after security review. Keep the integration PR unmerged while this machine's workflow is blocked.

Cloud staging has no configured owned target or API key, and no cloud version was published. The helper supports plan/execute separation, clean-main CI/evidence checks, scoped environment credentials, and a release receipt. It was not network-tested against a Roblox destination.

Real-car calibration, unified transient tires, static slope hold, curbs/sidewalls, imposed network latency/loss, client-physics abuse resistance, rollback, and mobile/fleet budgets remain open. The synthetic preset is not a measured real car. The current tire/contact architecture remains provisional.

## Continuation

Use the repository skill and `apex.ps1 doctor`; inspect Git and `.local/dev-session.json` for live session state. Fix and rerun the measured slope-hold failure before increasing tire stiffness or adding control systems. Keep runtime settings, source, loaded Studio state, GitHub, and cloud versions separate in every status report.
