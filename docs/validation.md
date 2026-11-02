# Validation and acceptance gates

Fidelity claims require measured error against a declared reference, not a count of subsystems. Every experiment must identify its commit, preset, conditions, tolerance, and evidence class before execution.

## Gate A: offline invariants

Run `apex.ps1 check`. It checks format, lint, pure Luau types, Roblox types against an absolute sourcemap, numerical invariants, builds, artifact receipts, and development-harness behavior. The physics suite has 18 named cases and 32,122 assertions, including seeded passive-energy stress and nonfinite-input rejection. Assertion count is not a real-vehicle accuracy score.

Required properties include SI round trips, passive drag/lateral friction signs, unilateral support, finite states, bounded tire force, correct reverse braking, static wheel brake hold, exact relaxation partitioning, Ackermann geometry, and motor power limits.

## Gate B: Studio integration

| Protocol | Setup and observable | Initial acceptance target | Status |
| --- | --- | --- | --- |
| B1: free-body units | Known mass, impulse, measured delta velocity | relative error below 1%, record sampling error | Initial local engine check passed: 2.000000114 m/s observed for 2 m/s expected; broader sampling protocol pending |
| B2: static suspension | Synthetic sedan, flat ground, no occupant; record support height and load | settles without growing oscillation; total modeled load within 2% of weight | Preliminary static smoke recorded; full protocol pending |
| B3: forward/reverse braking | Identical signed initial speeds; log wheel speeds and body velocity | signed response symmetry within 2%; no brake-driven reversal | Initial launch/braking run passed a declared 15% smoke threshold; measured asymmetry about 0.33%; full protocol pending |
| B4: low-speed and slope hold | 0–3 m/s and 10% slope, brakes held, 60 s | no growing oscillation; slope creep target below 1 cm per minute | Failed shorter characterization: 0.1178 m over 8 s against 0.01 m target |
| B5: frame-rate sweep | Repeat at 30, 60, 120 FPS, include a recorded hitch | no nonfinite state; report trajectory error and skipped steps | Pending |
| B6: moving platform | Translate and rotate contacted ground | relative slip converges; reciprocal momentum documented | Initial translational momentum check passed; rotation/contact-transient protocol pending |
| B7: curb and obstacle | Compare ray and sphere query variants | record contact loss and chassis strikes; no assumed pass | Pending |

Targets are proposed engineering criteria. A static smoke observation does not complete the full protocol. See the [initial experiment report](experiments/2026-11-01-static-support/README.md) for the narrower assertions and actual observations. A failure should cause a model/coupling change, not an undocumented tolerance adjustment.

## Gate C: performance and networking

Record CPU time per vehicle/wheel, p50/p95 frame time, query count, memory, bandwidth, ownership, and vehicle count on desktop and a representative mobile device. Establish a measured budget before setting a fleet limit. Compare 0/100/200 ms latency, disconnect/reconnect, driver changes, rejected inputs, and stale-input braking with at least two clients.

Initial two-client localhost runs passed eight ownership/input checks in each Server and Client mode. No artificial latency or packet loss was imposed. An eight-vehicle local Studio characterization measured about 0.896 ms p95 for the script adapter calls, with no skipped steps in that short run. This excludes full engine solver cost, supplies no mobile/fleet capacity guarantee, and does not establish a performance budget.

If evaluating predicted Server Authority, separately record rollback frequency, resimulation CPU cost, correction magnitude, and a complete inventory of simulation-safe APIs. Conventional `SetNetworkOwner(nil)` does not establish those properties.

## Gate D: calibrated fidelity

Choose one legally reusable vehicle/tire dataset and preserve its measurement conditions. Separate calibration runs from held-out validation. Fit mass distribution, inertia, tire force versus load/slip, road load, suspension response, acceleration, braking, steady-state cornering, and transient yaw response. Publish normalized errors with uncertainty and parameter provenance.

Standards such as FMVSS or ISO maneuvers may inspire experiments only after consulting current authoritative requirements. No regulatory compliance or real-world safety conclusion follows from this sandbox.

## Measurement record

Store results under a dated directory in `docs/experiments/`, with raw machine-readable telemetry and a concise report. Include: experiment ID, engine/build version, commit or file hashes, tool pins, units, gravity, stepping mode, simulation dt distribution, device, input trace, ownership, network conditions, reference data license, acceptance criteria, exclusions, and failed runs. Mark unobserved fields explicitly instead of inferring them from a default.
