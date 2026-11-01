# ADR-003: Server-owned fixture before prediction

Status: accepted for sandbox only. Date: 2026-11-01.

Use conventional server ownership, authorized input, finite bounded commands, rate limiting, and stale-input braking to validate the engine adapter. Do not introduce a partially rollback-safe predicted system during initial numerical setup.

Roblox's Server Authority fixed simulation is a separate future integration requiring documented API compatibility, synchronized state, and replayable inputs. Ordinary Luau tables are not automatically restored during resimulation.

Consequences: the example has input latency and is not the final multiplayer architecture. It offers a clear single-authority baseline for later comparisons. Prediction will be selected and tested against this baseline rather than assumed to improve realism.
