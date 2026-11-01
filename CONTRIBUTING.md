# Contributing

Use professional English for code, documentation, issues, and pull requests. Keep changes focused on a reproducible behavior or a documented research question.

1. Read `docs/STATE.md`, `docs/units.md`, and the relevant architecture decision.
2. Add a numerical invariant or a physical experiment with declared tolerances before claiming improved fidelity.
3. Keep SI physics independent of Roblox APIs. Identify every parameter as measured, specified, derived, or synthetic.
4. Run `scripts/check.ps1`. For engine changes, also run the relevant Studio protocol from `docs/validation.md`.
5. Report the commit, tool versions, engine version, gravity, stepping mode, ownership, device, and network conditions with measurements.

Do not add private assets, credentials, proprietary tire files, or unlicensed code. Reading another simulator is not permission to copy its implementation. Discuss substantial architecture or dependency changes in an issue and record the accepted decision in an ADR.

An offline test, a successful build, and a Studio measurement support different claims. State which one your change supplies.
