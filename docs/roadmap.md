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

1. Resolve the measured 10% slope parking failure using a physically justified static-contact treatment; keep the failed trace as a regression reference.
2. Extend the completed local integration and two-client baseline to held-force/body coupling, imposed latency/loss, and standstill behavior before increasing tire stiffness.
3. Compare ray and sphere contacts on curbs using equal mass, geometry, and input traces.
4. Select one dataset with verified redistribution/calibration terms; keep complete provenance.
5. Establish profiler and multiplayer baselines before choosing ECS, Parallel Luau, or rollback architecture.

Soft-body damage, thousands of suspension nodes, and arbitrary tire coefficient downloads are outside the initial scope. They may enter only after the base model's accuracy and cost are measured.
