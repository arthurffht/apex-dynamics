# Foundation laboratory validation

Local date: 2026-11-01 (America/Sao_Paulo); raw UTC run paths can start 2026-11-02. Studio binary: 0.745.0.7451137.

This phase prepares the project and test place; it adds no vehicle physics.

| Evidence | Result |
| --- | --- |
| [Foundation](foundation.json) | Eight shared laboratory checks passed in isolated Studio |
| [Audit](audit.json) | Nine drift/runtime-identity checks passed in isolated Edit context |
| [Interactive lab and Rojo](live-laboratory.json) | Eight checks passed on auto-run and rerun; distant sectors retained 25 cells; invalid input rejected; disk comment round trip verified |

Full local offline checks passed: 18 historical physics cases / 32,122 assertions, 3,307 foundation assertions, strict types/lint/format, artifact inspection, and 27 harness assertions. Nineteen strict modules were built.

Source snapshot: `1abdda21832a76f882a0167a86013c11ea423bdcb78cc1d8673f7e4eca09b252`. A final MCP audit matched all 22 managed sources. The logical-sector jump kept positions near the lab origin (maximum observed magnitude about 2,956.67 studs). Interactive Play was stopped afterward. Place1 was excluded throughout.

The initial transport probe after a Rojo restart failed to arrive: it was a genuine disconnected-session result. After reconnecting, the same bounded probe succeeded and restoration was observed. Repeating dev now replaces only the verifier, preserving Rojo/sourcemap processes; this does not promise automatic plugin reconnection to every future server session.

No continuous moving-chassis rebase, long soak, measured friction coefficients, imposed network condition, cloud version, or vehicle realism improvement is claimed. The historical slope-hold failure remains unresolved. Local check/doctor execution succeeded after a historical Defender block without security-setting changes; no diagnosis of the earlier detection follows.
