# Research map

The initial corpus consists of one vehicle-physics knowledge-base ZIP and two Roblox/Codex engineering manuals supplied by the project owner. They are preserved in ignored local storage, not promoted to executable project instructions. The manuals substantially overlap; the larger one also preserves earlier source documents. The consolidated guide is the efficient operational entry point, while the master manual is the historical reference.

Read [technical findings](findings.md) for the implementation consequences and [the evidence register](evidence.md) for claims that were rechecked, derived, or remain unresolved. `catalog.json` records every extracted file's path, size, SHA-256, and available headings; it also identifies the three original inputs by hash. It is an inventory, not a claim that every paragraph was independently verified.

The [integration map](integration-map.json) connects research sections and equations directly to source files and tests. The [development workflow](../development-workflow.md) applies the operational research through the actual root CLI, agent skill, source audit, and verification pipeline. Research is part of this project; the original archive is retained only as an immutable local provenance layer.

## Local archive navigation

The original hierarchy is preserved under `.local/research/roblox-vehicle-physics-kb`. This keeps the source's cross-links and equation IDs intact. Search before opening the compiled 1.5 MB report.

| Topic | Local knowledge-base entry | Project consequence |
| --- | --- | --- |
| Overview and corrections | `docs/00_Executive_Summary.md`, `docs/03_Extension_Research_2026-11-01.md` | Read dated corrections before using older claim tables |
| Units and evidence | `docs/01_Conventions_Units_and_Evidence_Tags.md`, `atlas/equations/01_UNITS_NUMERICS.md` | SI boundary, explicit gravity, evidence labels |
| Engine/API contract | `docs/10_Roblox_Engine_API_Contract.md`, `docs/11_Roblox_API_Member_Matrix.md` | Verify API availability against current engine/docs |
| Mass/contact/network | `docs/12_Roblox_Parts_Mass_and_Wheel_Colliders.md`, `docs/13_Roblox_Networking_Server_Authority_and_Security.md` | Keep geometry, inertia, ownership and force models separate |
| Tires | `docs/20_Tires_and_Contact.md`, `atlas/equations/02_TIRES_AND_CONTACT.md` | Combined grip, load sensitivity, signed slip, low-speed treatment |
| Brakes and control | `docs/21_Brakes_ABS_and_Parking_Brake.md`, `docs/22_Stability_and_Traction_Control.md` | Build force/actuator baseline before control tuning |
| Powertrains | `docs/23_Combustion_Powertrain_Turbo_and_Supercharger.md`, `docs/24_Electric_Powertrain.md` | Torque is the cause; speed is a state; begin with a transparent EV envelope |
| Chassis and steering | `docs/25_Steering_and_Suspension.md` | Document motion ratios, Ackermann geometry and spring sampling |
| Other simulators | `docs/30_Reference_Engines_and_Open_Source_Evidence.md` | Study techniques without importing incompatible code/licenses |
| Datasets | `docs/31_Datasets_and_Real_Vehicle_Parameters.md`, `data/real_vehicle_parameters.yaml` | Never present mixed-source values as one measured car |
| Numerical audit | `docs/40_Equations_Units_and_Numerical_Stability_Audit.md` | Test dimensions, reverse braking and stiff wheel dynamics |
| Offline experiments | `docs/41_Offline_Reference_Simulation_Experiments.md`, `tools/refsim` | Treat results as conditional offline evidence |
| Architecture/protocols | `docs/50_Architecture_Tradeoffs_and_Measurement_Protocols.md` | Choose contact architecture using measurements |
| Evidence/history | `docs/60_Evidence_Register_and_Open_Questions.md`, `docs/61_Change_Log_and_Translation_Coverage.md` | Preserve uncertainty and supersession |

The supplied `guide/`, `atlas/`, `playbooks/`, and `reference/` folders are navigation layers. `corpus/` contains the large source translations. `tools/` holds original reference programs and saved results; importing them does not execute or reproduce their reported results.

## Reimport and search

```powershell
./scripts/import-research.ps1 -KnowledgeBaseZip <archive.zip> -ConsolidatedGuide <guide.md> -MasterManual <manual.md>
rg -n 'H-E1|implicit|standstill' .local/research/roblox-vehicle-physics-kb/docs
node scripts/index-research.mjs
```

The import validates archive paths, preserves inputs, and rebuilds the public metadata catalog. Originals remain excluded by `.gitignore`. Do not execute downloaded research scripts without reviewing their file/network behavior and dependencies first.

## Review depth

The initial project review inspected corpus structure, both manuals' shared operational guidance, the numerical audit, architecture tradeoffs, tire/contact equations, low-speed wheel examples, evidence/open-question registers, and subsystem/data summaries. It did not independently audit every cited paper, run the original Python suite, download all datasets, or validate any source's Roblox performance claim. The project adds its own executable Luau tests with explicit scope.
