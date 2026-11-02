# System design and implementation boundaries

Status: foundation specification, 2026-11-01. This is the target architecture; the earlier vehicle code is an experimental measurement fixture. Building vehicle features is suspended until the foundation gate closes. Follow [the laboratory guide](laboratory.md), [capability matrix](platform-capabilities.md), and [workflow](development-workflow.md).

## Scope and technology decisions

| Area | Decision | Reason and change gate |
| --- | --- | --- |
| Language and tooling | Strict Luau, Rojo, Rokit, StyLua, Selene, Luau LSP, Lune, GitHub Actions | Existing pinned, exercised toolchain; no second build/package system |
| Runtime dependencies | None | Wally is available but has no dependency to install; add a package only for a measured need and compatible license |
| Composition | Explicit modules and owned handles with stop/destroy | Avoid hidden service locators, framework lifecycles, and speculative ECS |
| Execution | Serial adapter first; native rigid-body solver | Parallel Luau/Actors require profiler evidence and an ownership/communication design |
| Local laboratory | Dedicated generated place, fixed fixtures, bounded procedural sector window | Separate repeatable fixtures from the future game world |
| Cloud | Optional owned staging destination, promotion of a verified artifact | Open Cloud is a publisher, not a live editor or an engine-permission bypass |
| Input and presentation | Transport and device mapping outside physics | Future Input Action System evaluation must demonstrate support on the installed engine |
| Model identity | Synthetic reference fixture; future calibrated vehicle definitions are versioned data | Do not combine unrelated car/tire parameters into a claimed real car |
| Persistence | No DataStore for simulation ticks or tunable source settings | Source settings are versioned; future user persistence is a server adapter |

## Dependency direction and ownership

`src/core` contains SI physics only. `src/foundation` contains engine-independent lab infrastructure. `src/config` holds immutable source configuration. `src/roblox` translates engine units, queries, events, ownership, and impulses. `src/roblox/lab` is optional Studio instrumentation. Entrypoints compose those modules; shared code never requires a server/client entrypoint.

Each long-lived component must expose its owner, initialization preconditions, state, connections, run budget, stop/destroy path, and observable status. No global service locator, duplicated simulation loop, or implicit vehicle registration is part of the design. The library currently includes optional lab modules, but they are required only by Studio entrypoints; release packaging will split development modules after the public API exists.

## Chassis, contact, forces, and constraints

The selected first vehicle architecture is a **native rigid chassis with script-owned wheel/contact forces**, not a full custom rigid-body integrator. The implementation must preserve angular response and native body collisions. No CFrame steering, direct velocity drive, deprecated BodyMovers, or unbounded corrective impulses will be used to create handling.

Contact acquisition is a replaceable provider. The ray provider remains the inexpensive control/reference. A finite-volume provider (sphere or shape sweep plus explicit overlap handling) is the target experiment for curbs and road discontinuities. Spherecast alone is not a tire model, and a sphere is not a cylindrical wheel. Provider selection requires identical mass, geometry, inputs, surfaces, and measured cost/curb/standstill results.

A force application adapter converts SI force integrated over the actual simulation interval into an engine impulse at the contact point. It gathers all contacts before applying impulses and pairs reactions with dynamic ground. It owns filtering of the vehicle/occupant, invalid intervals, unit conversion, and telemetry. Native wheel friction must not duplicate the script tire's tangential force.

Modern mechanical constraints remain useful for **comparison fixtures and genuinely articulated mechanisms**. A native wheel with Hinge/Cylindrical/Spring constraints is an alternative architecture, with an explicit unsprung assembly and friction model. It will not silently coexist with full script tire grip on the same wheel. VectorForce and Torque are held-force alternatives to compare under a measured scheduling contract, not extra stabilization layers. Any static-contact actuator needs a bounded friction budget and energy/momentum tests before adoption.

## Suspension and steering definition

The first target is four independent suspension corners with declared hardpoints, travel, motion ratio, bump/rebound limits, wheel rate, asymmetric damping, bump stops, and optional anti-roll coupling. Geometry/kinematics, force law, and engine application remain separate. Specify spring travel / wheel travel for the motion ratio and transform stiffness with its square.

Begin with a quasi-static unsprung approximation; it does not claim wheel-hop or full multi-link kinematics. A later unsprung-state/native-constraint model must justify its contact cadence and numerical stability. Tire vertical compliance must not be counted twice. Suspension setup must derive from target ride frequency/load distribution, then be measured in static deflection and decay tests.

Steering input maps to hand-wheel/rack demand with rate limits outside the tire model. Geometry maps rack demand to left/right road-wheel frames. Ackermann percentage, limits, steering ratio, and alignment are explicit data. Visual wheel pose never supplies the physical contact frame.

## Tire, brakes, powertrain, and controls

The target tire module owns signed longitudinal/lateral slip, combined grip, load sensitivity, relaxation, and a low-speed stick/slide policy. It returns forces and optional aligning moment with units and validity range. The current split brush/longitudinal fixture is retained for comparison; it is not the selected final tire implementation.

The wheel-rotation integrator must handle stiff tire torque and signed brake hold without an explicit overshoot workaround. Coupled chassis/contact passivity is a separate gate from an implicit scalar wheel solve. Static slope hold remains an unresolved model decision with retained failed evidence.

Brake torque follows pressure/actuator state. Powertrain torque flows through a declared drivetrain/differential to wheel states; speed is a result. EV is the first target because its causal chain is simpler to observe. Combustion, thermal states, regeneration, ABS/TCS/ESC, wear, damage, and assists are later modules. Controllers cannot mask a failing passive chassis/contact baseline.

## Version-zero contracts

These are design contracts, not a released package API. Add executable types alongside each implemented subsystem, after its first falsification test.

| Contract | Required data and invariant |
| --- | --- |
| VehicleDefinition | Schema/version, provenance, SI mass/geometry/inertia assumptions, corner definitions, tire/drivetrain IDs; no mixed unnamed presets |
| ContactSample | Corner ID, hit/overlap state, point/normal/frame, separation/travel, ground velocity, ground assembly identity; frame and units declared |
| SuspensionState | Travel m, rate m/s, force N, limits and flags; no engine Instance in pure core |
| WheelState | Signed angular speed rad/s, tire transient states, brake/drive torque N·m, epoch; future snapshot completeness is testable |
| ForceContribution | SI force N, moment N·m, application point m and reciprocal-ground policy; one force owner |
| SimulationTick | Actual dt s, source/definition ID, ownership epoch, validity; no assumption that a Lua subloop advances engine physics |
| StateSnapshot | Schema, sequence, epoch, all mutable physical states, definition/hash, origin epoch; rollback unavailable until replay audit passes |
| TelemetryFrame | Timestamp/tick, SI values, flags, declared sampling rate and dropped counts; bounded storage |
| Scenario | ID, seed, fixture version, initial state, input trace, topology, network profile, metrics and gates; characterization separated from required pass |

## Authority, time, and future networking

The **laboratory default** is `AuthorityMode.Automatic` with ordinary server-owned assemblies and `simulationHost = Server`. The driver-owned Client comparison remains opt-in. Do not confuse either with rollback Server Authority.

Use a single selected simulator per vehicle and ownership epoch, server-authorized inputs, bounded rate, timeout reclamation, and a declared state-handoff policy. Client ownership requires abuse and latency validation; ordinary server ownership requires responsiveness validation. No production authority selection will be inferred from localhost tests.

Requested native stepping is Fixed. The current adapter uses PreSimulation and actual dt. Fixed native stepping is not proof of fixed Luau callback cadence. `BindToSimulation`/rollback is a separate future backend, gated by the installed engine, synchronized API access, replay-complete state, side-effect isolation, and latency/resimulation evidence.

## Extensive world and origin policy

The lab implements seeded integer sector plans and a bounded 5×5 rendered window (25 cells). Sector indices and meter offsets are separate; only small sector differences enter Vector3. Repeating a seed/sector reproduces the same surface variant. Large logical sector changes retire old cells instead of accumulating geometry.

This is an **extensive logical world foundation**, not continuous vehicle transport. Changing `ApexLab.SectorX/Z` relocates the lab window's logical origin; no live vehicle or player is carried. Seamless driving needs a later origin transaction: stop force injection, serialize all affected assemblies, move their poses and static window together, preserve velocities, update camera/query/constraint references, increment origin epoch, and resume. Do not shift individual multiplayer players into inconsistent physics spaces.

The precision tests must compare relative pose, linear/angular velocity, constraints, camera, contacts, and ownership before/after rebase. A shared-origin multiplayer world also needs distance bounds between participants or separate server zones. Streaming controls residency, not floating-point precision, and cannot replace this policy.

## Acceptance and implementation order

1. Foundation: current place identity, fixture map, bounded world lifecycle, repeatable checks, bounded diagnostics, source/artifact identity, protected synchronization and documented engine capabilities.
2. Contact/solver characterization: compare query/native variants, static hold, held-force cadence, drop/curb/passivity and dt sweep.
3. One coherent passive vehicle: suspension/load distribution, combined tire model, steering and drivetrain, held-out maneuvers.
4. Networks/controls/presentation: state lifecycle, latency/abuse, input devices, calibrated controls and measured performance budgets.
5. Public API/release: versioned contracts, integration examples, supported engine matrix and reproducible artifacts.

No foundation pass is a vehicle realism claim. No reported benchmark is a capacity guarantee.
