# Evidence register

Initial review date: 2026-11-01. Source hashes are in `catalog.json`. Tags distinguish kinds of support, not confidence scores that can be averaged.

| Tag | Meaning |
| --- | --- |
| DOCUMENTED | Read in a current primary vendor document |
| DERIVED | Follows from stated mathematical premises |
| TESTED-OFFLINE | Executed by this project's local Luau checks |
| MEASURED-ROBLOX | Observed in a recorded Studio/engine experiment |
| SYNTHETIC | Illustrative engineering parameter or model choice |
| SOURCE-REPORTED | Present in supplied research but not independently reproduced |
| OPEN | Requires a source check or a measurement |

## Load-bearing claims

| ID | Claim / decision | Support and boundary |
| --- | --- | --- |
| AD-E01 | Standard length/mass units are 0.28 m and 21.952 kg | DOCUMENTED: [Roblox units](https://create.roblox.com/docs/physics/units); round-trip factors TESTED-OFFLINE |
| AD-E02 | Earth gravity at that scale is 35.02375 studs/s² | DERIVED from 9.80665/0.28; generated artifact TESTED-OFFLINE |
| AD-E03 | `PreSimulation` is an engine integration event; fixed simulation is a separate API | DOCUMENTED: [RunService](https://create.roblox.com/docs/reference/engine/classes/RunService), [task scheduler](https://create.roblox.com/docs/performance-optimization/microprofiler/task-scheduler) |
| AD-E04 | The engine supports position-specific impulses and point velocities | DOCUMENTED: [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart); sandbox runtime behavior OPEN |
| AD-E05 | Pinned CLI tools support a filesystem-first workflow | DOCUMENTED: [Roblox external tools](https://create.roblox.com/docs/projects/external-tools), [Rojo](https://rojo.space/docs/v7/); installations/builds executed locally |
| AD-E06 | Combined force from the radial brush helper is bounded by modeled mu times load | DERIVED from its cubic radial law; TESTED-OFFLINE over a sweep; coefficients SYNTHETIC |
| AD-E07 | The scalar wheel solve satisfies discrete torque balance and dry brake hold | DERIVED backward-Euler residual; TESTED-OFFLINE; chassis velocity/load frozen |
| AD-E08 | Isolated wheel stability proves whole-vehicle stability | Rejected implication; chassis/contact coupling OPEN |
| AD-E09 | Native contact force is available for a tire model | Not assumed; supplied research reports no usable direct force/impulse readout; any new API requires rechecking |
| AD-E10 | Single-assembly raycast contact is the most realistic Roblox architecture | OPEN; baseline chosen for observability, not proven fidelity |
| AD-E11 | Rollback restores arbitrary ordinary Luau state | Not assumed; [Server Authority techniques](https://create.roblox.com/docs/projects/server-authority/techniques) require deliberate synchronized state/input design |
| AD-E12 | Archived numerical audit has roughly 609 checks and offline vehicle comparisons | SOURCE-REPORTED; original suite/results were not reproduced in this setup |
| AD-E13 | Research says Server Authority release status changed in 2026 | SOURCE-REPORTED with conflicting older summaries and a later correction; no release-status promise is needed by current fixture |
| AD-E14 | Prototype matches a real sedan or passes regulatory maneuvers | No supporting measurement; configuration SYNTHETIC; validation OPEN |
| AD-E15 | Corrected sandbox passes a six-second flat-ground static-support smoke on engine 0.745.0.7451137 | MEASURED-ROBLOX: [experiment and source hashes](../experiments/2026-11-01-static-support/README.md); driving, time-series settling, and actual stepping mode remain unverified |

## Source freshness and conflicts

Some imported files retain a 2026-10-28 verification date while the executive summary includes a 2026-11-01 extension. Read the extension and change log before resolving contradictions. Never reinterpret the archive's reference experiment outputs as measurements from the user's Roblox project.

Tool release versions were queried from their official GitHub release APIs during initial setup. `rokit.toml` pins the selected versions; it does not automatically track latest. Bootstrap and definition downloads use committed checksums. Read the code as well as the documentation before upgrading APIs or tools.

## Primary references and follow-up leads

- [Luau language documentation](https://luau.org/) — language and type-system behavior.
- [Lune](https://github.com/lune-org/lune) — standalone Luau execution; it is not the Roblox engine.
- [Rokit](https://github.com/rojo-rbx/rokit) — project tool manifests and installation.
- [Luau LSP](https://github.com/JohnnyMorganz/luau-lsp) — editor/CLI Roblox types and sourcemaps.
- [Project Chrono vehicle models](https://api.projectchrono.org/vehicle_models.html) — tire model comparison lead; no implementation imported.
- [Jolt Physics vehicle code](https://github.com/jrouwe/JoltPhysics/tree/master/Jolt/Physics/Vehicle) — impulse/friction design lead; no code imported.
- [CommonRoad vehicle models](https://gitlab.lrz.de/tum-cps/commonroad-vehicle-models) — parameter/model provenance lead; no coefficients imported.
- [Argonne Downloadable Dynamometer Database](https://www.anl.gov/taps/downloadable-dynamometer-database) — future longitudinal validation lead; terms and attribution must be checked when selected.

These follow-up leads are research navigation, not statements that all upstream content has been independently audited in this project.
