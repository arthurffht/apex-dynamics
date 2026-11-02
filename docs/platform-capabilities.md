# Platform capabilities and engine profiles

Verified 2026-11-01 against Studio binary 0.745.0.7451137 and the official documentation linked below. Documentation and an installed build can expose different capabilities; preserve both observations.

## Chosen profile

`config/engine.json` is canonical: Automatic authority, Fixed native stepping, fixed-simulation rollout disabled, streaming disabled for the deterministic-residency laboratory. `src/config/Runtime.luau` separately chooses ordinary Server/Client hosting. Change the engine profile through generation/build and reopen the resulting place. Changing host mode requires restarting Play after source synchronization.

| Operation | Control surface | Current verified boundary |
| --- | --- | --- |
| Managed Luau sources, local host choice, lab configuration | Filesystem → Rojo; source audit via official MCP | Cached required modules still need a Play restart |
| Inspect scoped DataModel, query fixtures, run lab, inspect reports | Official Studio MCP | Select Apex sandbox ID from fresh inventory; Place1 excluded |
| AuthorityMode | Serialized engine profile | MCP getter failed with missing RobloxScript capability; no setter was attempted |
| PhysicsSteppingMethod | Serialized engine profile | MCP getter reported not a valid member in this build/context |
| UseFixedSimulation | Serialized engine profile | MCP getter reported not a valid member in this build/context |
| StreamingEnabled | Serialized engine profile | MCP getter returned false; no setter was attempted |
| Ordinary assembly ownership | Server runtime SetNetworkOwner | Existing two-client local tests; independent of rollback authority |
| Rollback/fixed-frequency simulation | Separate future backend | Documented APIs exist, but current adapter/state and installed-context access are not validated |
| Native sphere queries | WorldRoot Spherecast | A lab check compares known ray/sphere travel distances; initial overlap needs a separate query |
| Saved place version in an owned universe | Open Cloud place publishing | Target/key required; no destination configured or publication performed |
| Live arbitrary Workspace property setter via Open Cloud | No workflow provided | Publishing a serialized place does not modify an already running server's settings |
| Studio account login, MCP access toggles, API-key creation, beta availability | Owner/platform setup | Agent cannot infer account permission or manufacture rollout access |

## Automatic, ordinary server ownership, and Server authority

The official AuthorityMode enum distinguishes Automatic (traditional distributed ownership) from Server (server authority with client prediction/rollback). Calling SetNetworkOwner(nil) under Automatic keeps an assembly server-owned; it does not turn the experience into the rollback architecture.

Official current docs describe BindToSimulation as gated by UseFixedSimulation and synchronized properties/APIs. A backend requires replay-safe mutable state and suppressible side effects. The generator therefore rejects a rollback Server profile instead of turning a property switch into a false implementation claim.

The local API getter observations above are saved as capability evidence. They override assumptions about what this MCP execution context can access; they do not prove the properties are absent from serialized place data.

## Tooling and permission policy

Do not automate protected setup dialogs, alter Defender settings, disable AMSI, or introduce AV exclusions. A historical local Defender detection is documented in STATE. The current foundation revision subsequently executed the full local harness and doctor successfully without security-setting changes. This is an observation of current execution, not a diagnosis that the earlier detection was a false positive or a permanent security-resolution claim.

The default synchronization policy remains filesystem-first with verified Git checkpoints and explicit cloud promotion. There is no competing MCP-to-filesystem watcher or cloud-to-local source loop. A currently open place is current only after exact-source and loaded-runtime identity checks.

## Official references

- [AuthorityMode enum](https://create.roblox.com/docs/reference/engine/enums/AuthorityMode)
- [Workspace reference](https://create.roblox.com/docs/reference/engine/classes/Workspace)
- [RunService and fixed simulation](https://create.roblox.com/docs/reference/engine/classes/RunService)
- [Network ownership](https://create.roblox.com/docs/physics/network-ownership)
- [WorldRoot queries and overlap limitations](https://create.roblox.com/docs/reference/engine/classes/WorldRoot)
- [Instance streaming](https://create.roblox.com/docs/workspace/streaming)
- [Open Cloud place publishing](https://create.roblox.com/docs/cloud/guides/usage-place-publishing)
