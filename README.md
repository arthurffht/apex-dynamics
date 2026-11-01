# Apex Dynamics

[![CI](https://github.com/arthurffht/apex-dynamics/actions/workflows/ci.yml/badge.svg)](https://github.com/arthurffht/apex-dynamics/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Research-driven vehicle dynamics for Roblox, built in strict Luau.**

Apex Dynamics aims to make high-fidelity vehicle simulation on Roblox transparent, measurable, and open source. The project starts with explicit SI units, testable tire and wheel dynamics, and a small engine adapter. Fidelity is an engineering objective measured against data; the project does not yet claim real-vehicle accuracy or superiority over other chassis.

**Status: experimental foundation.** Numerical tests and artifact inspection run outside Roblox. A local Studio static-support observation is recorded in [the experiment report](docs/experiments/2026-11-01-static-support/README.md). Driving, performance, and multiplayer validation remain pending. See [current state](docs/STATE.md) and [validation gates](docs/validation.md).

## Quick start on Windows

Install [Git](https://git-scm.com/downloads) and [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows), then:

```powershell
git clone https://github.com/arthurffht/apex-dynamics.git
cd apex-dynamics
./scripts/bootstrap.ps1 -InstallStudioPlugin
./scripts/check.ps1
```

Open `build/ApexDynamicsSandbox.rbxlx` in Roblox Studio. Press Play, sit in the driver seat, and use **W/S** for forward/reverse torque, **A/D** for steering, and **Space** for braking. The sandbox uses server simulation and keyboard input as an integration fixture. It is not a production driving game.

For live development, run `rojo serve default.project.json` and connect the installed Rojo plugin to `localhost:34872` in a dedicated sandbox place. The reusable library is built separately as `build/ApexDynamics.rbxm`.

## Implemented

- Standard Roblox-to-SI conversion boundary and Earth-gravity sandbox.
- Combined-force radial brush approximation with illustrative load sensitivity.
- Saturated longitudinal tire law with a backward-Euler wheel solve and zero-speed brake hold.
- Exact scalar relaxation helpers, unilateral spring/damper support, and Ackermann steering.
- Idealized EV torque/power envelope and quadratic aerodynamic drag.
- Four-wheel raycast adapter with moving-ground relative velocity and reciprocal impulses on dynamic ground.
- Server-owned example with driver authorization, bounded input, rate limiting, and input timeout.
- Pinned tooling, strict type checking, lint/format checks, numerical tests, Rojo builds, and GitHub Actions.

The brush helper and the sandbox's longitudinal solver are distinct reference models. Their integration and limitations are described in [architecture](docs/architecture.md). ABS, TCS, ESC, tire thermal/wear models, a combustion drivetrain, rollback prediction, and real-car calibration remain on the [roadmap](docs/roadmap.md).

## Repository map

| Path | Purpose |
| --- | --- |
| `src/core` | Engine-independent scalar physics in SI units |
| `src/roblox` | Contact queries and Roblox impulse application |
| `src/presets` | Explicitly synthetic reference configuration |
| `examples` | Isolated sandbox and input transport |
| `tests` | Numerical invariants and generated artifact inspection |
| `scripts` | Reproducible setup, verification, and research indexing |
| `docs/research` | Evidence register, source catalog, and technical synthesis |
| `docs/adr` | Architecture decisions and their consequences |

Start with [setup](docs/setup.md), [units](docs/units.md), and the [research map](docs/research/README.md). Contributions must include reproducible evidence; see [CONTRIBUTING.md](CONTRIBUTING.md).

## License and provenance

Original project code and documentation are [MIT licensed](LICENSE). Supplied research archives are preserved locally, hashed, and excluded from Git; their source licenses are not replaced by this project's license. External tools and future datasets retain their own licenses. See [third-party provenance](THIRD_PARTY_NOTICES.md).
