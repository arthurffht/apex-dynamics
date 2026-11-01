# Apex Dynamics

[![CI](https://github.com/arthurffht/apex-dynamics/actions/workflows/ci.yml/badge.svg)](https://github.com/arthurffht/apex-dynamics/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Research-driven vehicle dynamics for Roblox, built in strict Luau.**

Apex Dynamics aims to make high-fidelity vehicle simulation on Roblox transparent, measurable, and open source. The project starts with explicit SI units, testable tire and wheel dynamics, and a small engine adapter. Fidelity is an engineering objective measured against data; the project does not yet claim real-vehicle accuracy or superiority over other chassis.

**Status: experimental, measured development baseline.** Offline invariants, local engine regressions, and two-client ownership tests have been exercised. A slope-hold research target still fails. These results do not establish real-vehicle calibration or production networking. See [current state](docs/STATE.md), [validation gates](docs/validation.md), and the [integrated workflow](docs/development-workflow.md).

## Quick start on Windows

Install [Git](https://git-scm.com/downloads) and [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows), then:

```powershell
git clone https://github.com/arthurffht/apex-dynamics.git
cd apex-dynamics
./scripts/bootstrap.ps1 -InstallStudioPlugin
./apex.ps1 check
./apex.ps1 dev -AutoCheckpoint
```

Open `build/ApexDynamicsSandbox.rbxlx` in Roblox Studio and connect its Rojo plugin to `localhost:34872`. Press Play, sit in the driver seat, and use **W/S**, **A/D**, and **Space**. Server simulation is the default; use `./apex.ps1 mode -Mode Client` for the experimental driver-owned comparison, then restart Play.

The development session watches source, maintains the LSP sourcemap, runs verification, and optionally pushes passing checkpoints to a branch/PR. The reusable library is `build/ApexDynamics.rbxm`. All commands, cloud boundaries, and MCP setup are maintained in [one workflow reference](docs/development-workflow.md).

## Implemented

- Standard Roblox-to-SI conversion boundary and Earth-gravity sandbox.
- Combined-force radial brush approximation with illustrative load sensitivity.
- Saturated longitudinal tire law with a backward-Euler wheel solve and zero-speed brake hold.
- Exact scalar relaxation helpers, unilateral spring/damper support, and Ackermann steering.
- Idealized EV torque/power envelope and quadratic aerodynamic drag.
- Four-wheel raycast adapter with moving-ground relative velocity and reciprocal impulses on dynamic ground.
- Configurable server/client execution with ownership epochs, driver authorization, rate limiting, and server reclamation after input timeout.
- Pinned tools, source/artifact fingerprints, exact-source drift probes, regression reports, and verified GitHub checkpoints.
- A repository skill, Serena Luau MCP integration, source-linked research decisions, and one root development CLI.

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
| `config` | Engine profile, optional agent-tool pins, and staging configuration example |
| `.agents/skills` | Repository-specific agent workflow without duplicated manuals |
| `docs/research` | Evidence register, source catalog, and technical synthesis |
| `docs/adr` | Architecture decisions and their consequences |

Start with [setup](docs/setup.md), [units](docs/units.md), and the [research map](docs/research/README.md). Contributions must include reproducible evidence; see [CONTRIBUTING.md](CONTRIBUTING.md).

## License and provenance

Original project code and documentation are [MIT licensed](LICENSE). Supplied research archives are preserved locally, hashed, and excluded from Git; their source licenses are not replaced by this project's license. External tools and future datasets retain their own licenses. See [third-party provenance](THIRD_PARTY_NOTICES.md).
