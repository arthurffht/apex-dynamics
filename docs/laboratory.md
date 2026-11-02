# Foundation laboratory

The default place is a development laboratory, not a playable vehicle release. Existing vehicle math/adapters are experimental fixtures and remain opt-in. The static scene is composed once from `laboratory.project.json`; runtime infrastructure is source-owned under `src/roblox/lab`.

## Place layout and execution

`Workspace.ApexLab.Stations` contains Flat, Grade10, Curbs (0.05/0.10/0.20 m), and SplitSurface geometry. Surface labels are future test inputs; different colors do not establish measured friction coefficients. The large Ground remains the original regression surface. A separate bounded sector window is centered at x = 672 m so its collision geometry does not overlap those fixtures.

Press Play in the current generated Apex place. The lab starts only in Studio, creates its owned Runtime folder and 25 cells, runs eight infrastructure checks, and displays status in `ApexLaboratoryHUD`. No reference vehicle is spawned and no vehicle input remote is created by default. The optional vehicle fixture can be enabled by setting `Workspace.ApexReferenceEnabled = true` in Edit before Play; automated Multiplayer does this explicitly in its isolated entry.

## Control and observation contract

All controls below target the sandbox **Server** DataModel during Play. No public remote accepts arbitrary test commands.

| Surface | Purpose |
| --- | --- |
| `Workspace.ApexLab.RunRequested = true` attribute | Request one infrastructure suite; requests while running do not start a second simulator/test loop |
| `SectorX`, `SectorZ` attributes | Select integer logical world sectors; invalid requests restore the previous selection and record a warning |
| `State`, `RunId`, `PassedCases`, `FailedCases`, `LastDurationS` | Observable lifecycle and last completed outcome |
| `SourceFingerprint`, `LabSchemaVersion`, `Phase` | Runtime/source identity and supported schema |
| `ActiveTiles`, `EventCount`, `DroppedEvents` | Resource/diagnostic budgets |
| `ApexLab.Runtime.LastReport.Value` | Machine-readable last suite report, including bounded error stack text |
| Laboratory handle `run/stop/events` | Explicit owner API for suites, cleanup, and chronological diagnostic snapshot |

The control attributes are Instance attributes, not child Value objects. Through MCP use `SetAttribute("RunRequested", true)`, then observe `Runtime.LastReport` and its new runId. The handle stops its Heartbeat/request connections, destroys owned runtime/cells, and leaves static fixtures intact. A Play stop discards runtime changes normally.

## Checks and limits

The shared Checks module covers identity, gravity, safe defaults, fixture map, world budget, repeat-update idempotency, distant-sector lifecycle/cleanup, and known ray/sphere query distances. Both interactive Play and `./apex.ps1 studio -Suite Foundation` use that module. Engine suites disable the lab unless explicitly testing Foundation, so fixture automation does not compete with physics regression or multiplayer setup.

Each case records elapsed time and fails if it exceeds 2 s. This is an elapsed-time gate for bounded synchronous cases, not a preemptive cancellation facility. The outer isolated Studio runner has a process deadline and validates structured completion. Future yielding/network cases need cancellation tokens and explicit teardown.

Diagnostics keep 256 immutable events in a ring, at most 16 bounded scalar fields per event. There is no per-frame Output flood, remote telemetry backend, player identifier capture, or unbounded trace array. One structured suite report is printed per run. HUD sampling is 5 Hz; physics sampling, when introduced, has a separate contract.

## World-window semantics

The grid planner uses integer sectors and local meter offsets. Normalization preserves signed positions across zero and sector boundaries. A 5×5 plan enforces the 25-cell budget before mutations. Distant sectors reuse the same local coordinate range and retire old Instances; unchanged selection allocates nothing. Tests also reject nonfinite/fractional/oversized sectors and oversized plans.

This provides repeatable extensive **logical** terrain and bounded engine residency. It does not transport a moving chassis across an origin shift. Do not interpret changing sector attributes as a tested multiplayer floating-origin implementation. The transactional rebase acceptance criteria are in system-design.md.

## Automation tiers

1. Every Play: the eight infrastructure checks run automatically.
2. Offline/CI: physics invariants, 3,307 foundation assertions, strict types/lint/format, serialized profile/scene checks, and PowerShell harness checks.
3. `dev -StudioChecks`: after a stable source change, offline checks plus the isolated Foundation suite; one run at a time.
4. `dev -StudioChecks -AutoCheckpoint`: the same gates must pass before a branch/PR checkpoint. Edit or HEAD drift cancels the checkpoint.
5. Scheduled/manual deep characterization: Regression, Multiplayer in both modes, Research, imposed-network and performance protocols. The latter protocols are not all implemented.
6. Staging promotion: only configured owned targets, matching evidence, clean main, passing CI, and returned cloud version receipt.

Consult STATE and the local session/health files for which tiers are actually running. The current revision executed local checks after a historical Defender block, without security-setting changes. A temporary source comment was observed arriving in the scoped Studio instance through Rojo and its removal was verified. Repeating dev preserves that Rojo session while replacing the verifier; deliberately stopping/restarting Rojo may require plugin reconnection.

## Foundation gate

Close this phase only when the latest source builds, all required lab checks pass in the current place, source/runtime fingerprints match, no unowned place is touched, diagnostics/world resources remain bounded, and synchronization can be demonstrated end to end. Resolve the local security block and prove an actual disk edit reaches the scoped Studio instance before calling continuous synchronization operational.

The lab is the delivery for this phase. Do not start a new tire, suspension, controller, or drivetrain implementation merely because an old fixture fails its research target.
