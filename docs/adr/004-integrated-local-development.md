# ADR-004: Local-first source and bounded automation

Status: accepted. Date: 2026-11-01.

Use local source plus Rojo as the canonical development system. Compose the library mapping into one sandbox, generate machine-specific active projects and fingerprints, and publish verified GitHub checkpoints through branches/PRs. Keep cloud staging as a versioned promotion destination rather than a competing live source.

Expose one root command surface for setup, diagnostics, build, verification, Studio suites, host selection, source audit, research retrieval, and synchronization. Background automation is deterministic: stable edit, checks, receipt, optional checkpoint. It waits for a new edit after failure and never merges or publishes by itself.

Choose conventional server simulation as the reference and support a driver-owned client comparison using the same adapter. Explicit ownership epochs and stale-input reclamation select one simulator. This decision extends ADR-003's sandbox baseline; it does not declare a final competitive networking design or retrofit rollback semantics onto ordinary table state.

Serialize non-scriptable engine settings through the generated place. Reject rollback profiles until their state/API contract is implemented. Match measurements to source and artifact identity; a live script update and a loaded runtime are separate states.

Consequences: deterministic local workflows remain usable without MCP or cloud credentials. Interactive MCP enablement and a first Rojo plugin connection are external access steps. Engine, networking, and calibrated fidelity claims remain gated by their own recorded evidence.
