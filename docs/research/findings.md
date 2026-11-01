# Technical findings and implementation decisions

The supplied research is valuable because it separates documentation, mathematical derivation, source-code reading, and measurements. Its strongest project-level recommendation is to make the simulator observable and testable before adding sophisticated controls or infrastructure.

## 1. Units and gravity precede tuning

The standard scale is 0.28 m/stud and 21.952 kg/RMU. At that scale, default gravity is roughly 5.6 times Earth gravity. Tire nominal load, spring equilibrium, traction, and inertia cannot be transferred blindly between those environments. The project therefore uses an SI core and an explicit Earth-gravity sandbox. This is a verified conversion policy, not a calibrated handling result.

## 2. Separate contact, force law, integration, and networking

The research compares native wheels, native-normal/script-tangent hybrids, query contacts, custom body integration, and static-contact hybrids. Each resolves different constraints. A script-owned tire can expose load sensitivity and combined slip, while native contact supplies geometry and solver behavior that the script may not fully observe.

Start with a single-assembly query baseline for observability. Keep alternative adapters possible. The decision remains provisional until low-speed, curb, load, and network protocols are measured. Native collision friction must not be added accidentally to full script tire grip.

## 3. Solve stiff wheel states without claiming a stable whole vehicle

The archived wheel experiments warn that explicit Euler can oscillate severely at plausible script intervals. The project implements a backward-Euler wheel solve with a monotone saturated force law and static brake interval. Its tests verify the discrete torque equation and an analytic linear limit.

The same research explicitly warns that an implicit wheel does not solve a chassis driven by sampled/held tire forces. Consequently, low-speed body coupling remains a separate acceptance gate. No internal Luau loop is described as a new Roblox physics step. The conservative slip denominator trades low-speed precision for a gentler local response and must be revisited experimentally.

## 4. Use bounded combined grip and traceable tire data

The reference radial brush helper enforces a combined force limit, reproduces the small-slip stiffness sign, and reduces normalized grip at higher load using a declared synthetic parameter. The sandbox's simpler longitudinal law shares a friction budget with lateral demand. It is not branded as MF-Tyre, TMeasy, a measured tire, or a complete brush implementation.

A fitted Magic Formula is useful only with a licensed coefficient set, correct force shifts/signs, load range, camber, pressure, and validation conditions. The source audit identifies a vertical-shift-placement issue in a referenced implementation; that is a prompt to compare equations, not permission to copy or condemn a whole external project.

## 5. Braking and controls require the correct causal chain

Brake pressure/torque changes wheel slip; the tire determines chassis deceleration. Brake torque must oppose signed rotation and hold an interval at zero. The current core implements that wheel-level behavior. It does not yet implement hydraulic pressure dynamics, ABS, EBD, TCS, ESC, or parking slope constraints.

The archive contains inconsistent summaries of representable ABS modulation rates: an older high-level statement calls pulse-level behavior unsupported, while the later extension distinguishes a fast internal loop from slower observable modulation. No absolute ABS claim is adopted from those summaries. A future mean-value controller must declare its sample rate, actuator dynamics, target metric, and comparison data.

## 6. Realism needs a coherent vehicle and held-out data

The archive mixes measured public data, manufacturer specifications, identified model parameters, estimates, and illustrative examples. Those categories must remain distinct. The initial `AD-SEDAN-001` is explicitly synthetic. It does not inherit a real car's name from a wheelbase, a different car's powertrain, and a generic inertia default.

Future calibration should use one coherent vehicle/condition set, a verified license, and withheld validation maneuvers. Dataset downloads are deferred until selection and terms review; storing many gigabytes of unselected data would not improve this baseline.

## 7. Networking and operational claims need their own verification

The archive's older evidence register marks some Server Authority availability claims conflicting; its later extension says the conflict was resolved. This internal supersession is recorded rather than silently flattening the corpus into a single authoritative truth. Current API references document fixed simulation and replay, but engine compatibility and allowed operations still require a real Studio session.

The sandbox uses conventional server ownership and a validated input channel. A future rollback path must move mutable state into a replayable representation and audit every engine call. The current table-based adapter is not that implementation.

## 8. A small reproducible toolchain is the useful starting point

The two engineering manuals recommend filesystem-first source control, pinned tools, short project instructions, durable state, ADRs, selective retrieval, and layered validation. Those practices are adopted. Rojo, Rokit, formatting, linting, type checking, offline execution, CI, Git, and GitHub are configured around this repository.

Serena, graph/vector memory, multiple package managers, ECS, extra MCP servers, and automated production publishing remain conditional additions. Their presence in a research guide is not evidence that the present project needs them. `AGENTS.md`, `docs/STATE.md`, a searchable source catalog, and small modules provide the initial navigation system.
