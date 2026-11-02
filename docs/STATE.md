# Project state

Updated: 2026-11-01 (America/Sao_Paulo).

## Current phase

Deliver the professional project foundation and a current Studio laboratory. The owner explicitly deferred vehicle implementation. Do not start new tire, suspension, powertrain, controller, or vehicle-feature work until foundation acceptance and an explicit request to proceed. Preserve earlier vehicle code and measurements as opt-in experimental fixtures.

Read system-design.md for architecture/contracts, laboratory.md for place operation, platform-capabilities.md for engine/MCP/Open Cloud boundaries, and development-workflow.md for commands. ADR-005 supersedes the earlier immediate slope-hold work queue.

## Decisions

- Local source plus Rojo is canonical; GitHub stores verified checkpoints and PRs. Cloud is an explicit staging promotion, not a second editable codebase.
- Default place: no vehicle, eight automatic infrastructure checks, fixed stations, diagnostic HUD, bounded event history, and a seeded 25-cell logical world window.
- Future vehicle: native rigid chassis, replaceable contact provider and SI force adapter, independent corner suspension contracts. Raycast is the reference; finite-volume/native-constraint alternatives need comparative evidence. No new vehicle equations were added in this phase.
- Engine profile: Automatic authority, Fixed native stepping, fixed-simulation rollout disabled, streaming disabled for lab residency. Ordinary Server hosting is the fixture default; Client is opt-in. Neither is rollback Server Authority.
- Properties unavailable to this MCP context are serialized by generation/build; reopen the generated place for engine-profile changes. Open Cloud cannot grant missing engine permissions.
- Keep strict Luau and the pinned toolchain. No speculative runtime framework, ECS, parallel simulation, or runtime dependency was added.
- Logical sectors and meter offsets keep geometry bounded. Continuous vehicle/multiplayer origin rebasing is specified, not implemented.

## Verified foundation evidence

Source fingerprint: `1abdda21832a76f882a0167a86013c11ea423bdcb78cc1d8673f7e4eca09b252`.

- Full local check: formatting, lint, strict pure/Roblox types, 18 historical physics cases / 32,122 assertions, 3,307 foundation assertions, two builds, 19 strict modules, serialized scene/profile/matrix checks, and 31 harness assertions passed.
- Isolated Foundation: eight checks passed using the interactive laboratory's shared module. Identity, gravity, no default vehicle, fixture map, world budgets/idempotency/lifecycle, and ray/sphere query semantics were executed.
- Isolated Audit: nine checks passed, including source drift, unexpected scripts, missing/stale vehicle identity, and missing/stale laboratory identity.
- Live official MCP: auto-run and requested rerun each passed eight checks without a vehicle. Sectors ±100,000,000 retained 25 cells and maximum observed position about 2,956.67 studs. Invalid fractional sector input was rejected and previous selection restored.
- Rojo transport: after reconnecting its plugin, a temporary disk comment appeared in the scoped Studio module and its removal was verified. Final exact-source audit matched all 22 managed sources. The sandbox was returned to Edit mode.
- The background watcher completed offline plus isolated Foundation validation. Repeating dev replaced its watcher while preserving Rojo/sourcemap processes. Exclusive verification leases prevent concurrent artifact replacement.
- Doctor executed successfully with the expected tools. A historical Defender block no longer reproduced in current check/doctor runs. No Defender settings, AMSI changes, exclusions, or execution bypasses were applied; this is not a permanent security-resolution claim.

Reports: docs/experiments/2026-11-01-foundation. Each report retains its actual source/harness identity. Inspect ignored .local/dev-session.json and dev-health.json for active options rather than inferring a live service from this document.

## Historical vehicle evidence and open protocols

Earlier local engine regression and two-client Server/Client tests remain in docs/experiments/2026-11-01-integrated-workflow. They are experimental fixture evidence.

The 10% slope parking target failed: 0.1178225 m creep over 8 s versus a 0.01 m target. Keep its trace/backlog item; do not implement the fix during this phase. The synthetic preset is not real-car calibrated. Earlier eight-vehicle script-cost measurements exclude full solver/render/mobile capacity.

Continuous body rebasing, long soak, imposed latency/jitter/loss, adversarial client physics, rollback, final contact architecture, unsprung kinematics, unified transient tires, and calibrated vehicle behavior remain gated. config/validation-matrix.json distinguishes implemented suites, characterization, and planned protocols.

## Access, synchronization, and provenance

Only the explicitly identified ApexDynamicsSandbox.rbxlx instance is in scope. Place1 belongs to another project and was not inspected, edited, playtested, or closed. Select the current sandbox inventory ID; isolated CLI tests temporarily register extra instances with the same filename.

Services use localhost:34872 and owned process records. dev -StudioChecks runs offline plus isolated Foundation verification; adding -AutoCheckpoint permits passing stable branch/PR checkpoints. Repeated dev preserves Rojo while replacing the verifier. Explicit stop disconnects services; a new Rojo server session may require plugin reconnection. No watcher merges main or publishes Roblox automatically.

A final session check found exited transport launchers while the verifier remained alive. The recovery change records pinned native Rojo processes and rejects dead, mismatched, or stopped process records in aggregate health/doctor. Regression checks exercise those status failures; do not treat code verification alone as transport health.

GitHub repository: arthurffht/apex-dynamics, authenticated CLI, protected main, pinned CI, validation backlog. Check the current commit's CI. PR #9 carries the integrated foundation work until review/merge.

Cloud has no owned target/API key configured; no cloud version was published. The existing helper requires explicit staging promotion, clean-main CI, matching integration evidence, and an artifact receipt. The development laboratory runs only in Studio.

The three original inputs and 122 research files remain immutable ignored provenance. Research links through docs/research/integration-map.json and is not agent instruction. Pinned external tooling stays under .local/references. Serena MCP symbol lookup previously succeeded; machine-specific configuration remains local.

## Continuation

Keep the foundation current and review its design/matrix. Vehicle feature work remains paused. Update contracts, falsification tests, uncertainty/provenance and ADRs as needed. Report source, loaded Studio state, artifacts, GitHub and cloud versions separately.
