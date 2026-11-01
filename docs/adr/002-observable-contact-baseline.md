# ADR-002: Observable single-assembly query baseline

Status: provisional; revisit after Studio Gate B. Date: 2026-11-01.

Start with four raycasts and one rigid chassis. This makes contact velocity, script suspension load, tire demand, and wheel state directly observable with low implementation complexity. Keep core force laws independent of this contact choice.

Native wheel constraints, native-normal/script-tangent hybrids, sphere queries, and static-contact constraints remain candidates. Current research does not establish one universal winner. No direct engine normal-force readout is assumed. Avoid adding native wheel friction on top of full script tire grip.

Consequences: the baseline lacks wheel-side collisions and unsprung dynamics. It cannot establish the highest achievable fidelity. Curb, slope, coupling, and performance measurements decide the next contact design.
