# Integrated workflow and engine characterization

Date: 2026-11-01. Engine binary: 0.745.0.7451137. Environment: local Windows Studio, synthetic AD-SEDAN-001, no cloud deployment. Each JSON file preserves its own source fingerprint and test-harness identity; do not silently reinterpret an earlier snapshot as a later one.

## Recorded evidence

| Record | Outcome | Scope |
| --- | --- | --- |
| [Regression and research](regression-and-research.json) | Nine required cases passed; fleet characterization completed; parking target failed | Static support, drop recovery, signed launch/braking, symmetry, steering, airborne behavior, hitch guard, dynamic-ground momentum |
| [Server multiplayer](multiplayer-server.json) | Eight checks passed | Two local clients, conventional server ownership, authorized input, rejected non-driver input, stale-input braking |
| [Client multiplayer](multiplayer-client.json) | Eight checks passed | Two local clients, driver ownership, one active simulator, timeout reclamation |
| [Smoke and SI impulse](smoke-and-units.json) | Two checks passed | Engine mass/impulse conversion and flat-ground support |
| [Source audit](source-audit.json) | Seven checks passed | Exact sources, deliberate drift, restoration, unexpected managed script, missing/stale runtime identity |
| [Serena MCP](agent-mcp.json) | Actual MCP lookup succeeded | 23 tools exposed; `find_symbol` resolved `Tire.stepWheel` using Luau LSP |

The offline suite separately passed 18 cases and 32,122 assertions. Development-harness tests check PowerShell syntax, content-based change detection, exclusion of ignored data, clean fixture restoration, and rejection of unsupported rollback profiles without mutating the active project.

## Measurements and practical limits

- The free-body impulse check observed **2.0000001144 m/s** for **2 m/s** expected, with measured assembly mass **1400.0000547 kg** for 1400 kg configured.
- The required forward/reverse launch comparison measured approximately **0.33%** asymmetry in that run. Its declared smoke threshold was 15%; this is not a calibrated braking benchmark or a substitute for the full Gate B protocol.
- The client-owned multiplayer run recorded **129 driver-client simulation steps**, **zero other-client steps**, and **zero server steps** during the observation window. Server ownership and brakes resumed when valid input stopped. No imposed latency, jitter, loss, adversarial modified client, or cloud server was tested.
- Eight vehicles produced approximately **0.543 ms p50**, **0.896 ms p95**, and **1.281 ms maximum** for script adapter calls in a short local run, with zero skipped steps. This excludes full solver/rendering cost and does not establish a mobile or fleet capacity budget.
- The parking test on a **10% grade** moved **0.1178225 m in 8 s**, failing the declared **0.01 m** characterization target. Its series is retained. The longer 60 s parking protocol and a physically justified static-contact solution remain open.

## Harness findings

Initial multiplayer output appeared only in the child Studio server log, so the parent CLI result was correctly rejected as incomplete. The runner now emits the `EndTest` return value from the parent process and requires a structured report plus completion marker. No native-log scraping or success-by-exit-code fallback was added.

Engine settings are serialized through the generated Rojo project. Artifact inspection verifies the requested enum tokens. Runtime access to some settings is restricted, so the report labels the profile as requested rather than claiming an unavailable getter measured it. Neither ordinary server ownership nor client ownership is Roblox's replay/rollback Server Authority implementation.

The Studio MCP inventory was initially empty. After owner enablement it exposed only an unrelated `Place1`, which was left untouched. The dedicated Apex sandbox is open separately; these reports do not establish its live MCP/Rojo synchronization or a Roblox cloud version.

After the recorded test runs, Windows Defender AMSI blocked the local PowerShell module as `HackTool:PowerShell/ApexToolkit.A`. The current development session is stopped; previous passing reports do not establish that the local harness remains executable. No security exclusion or execution bypass was applied.
