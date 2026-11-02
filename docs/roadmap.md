# Engineering roadmap

The objective is a validated, extensible open-source vehicle simulator. Advancement depends on evidence gates, not feature count or calendar promises.

| Stage | Deliverable | Exit condition |
| --- | --- | --- |
| 0: reproducible foundation | Strict Luau core, provenance, tooling, CI, sandbox | Offline checks and artifact inspection pass |
| 1: engine characterization | Unit impulse, spring/load behavior, contact cadence, low-speed/body coupling | Reproducible Studio reports for B1–B7; select contact architecture using results |
| 2: tire/contact baseline | Unified combined-slip model, calibrated load sensitivity, relaxation, static contact | Tire data fits, slope-hold and dt-sensitivity gates pass |
| 3: chassis and powertrain | Mass/inertia identification, suspension kinematics, anti-roll, differential, EV battery/thermal/regen; optional mean-value combustion | Identified parameters and held-out acceleration/braking/cornering validation |
| 4: control systems | Brake hydraulics, ABS, TCS, ESC with declared actuator/control cadence | Reproducible improvement over disabled-control baseline, including low-friction cases |
| 5: multiplayer | State serialization, server authority/prediction evaluation, bounded inputs, reconciliation | Two-client latency/rollback and abuse tests meet published targets |
| 6: public package | Versioned API, accessible input, integration examples, published benchmarks | Documented support matrix and reproducible release artifacts |

## Immediate work queue

1. Close the foundation gate: current place/source/runtime identity, automatic infrastructure checks, bounded diagnostics/world lifecycle, and demonstrated synchronization.
2. Keep environment/connection health explicit; the latest local harness executes after a historical Defender block, with no security-setting changes.
3. Complete the contact/constraint and timing measurement protocols before choosing the final contact implementation; preserve the measured slope-hold failure.
4. Start vehicle implementation only after foundation acceptance and an explicit request to proceed, using the subsystem contracts in system-design.md.
5. Select a coherent licensed calibration dataset and define held-out maneuvers; introduce ECS, Parallel Luau, or rollback only after their respective evidence gates.

Soft-body damage, thousands of suspension nodes, and arbitrary tire coefficient downloads are outside the initial scope. They may enter only after the base model's accuracy and cost are measured.
