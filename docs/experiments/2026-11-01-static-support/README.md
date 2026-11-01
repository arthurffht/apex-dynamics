# Initial Studio static-support smoke

Date: 2026-11-01. Scope: local Run mode, synthetic sedan, flat ground, no player/occupant, conventional server ownership. This is an integration smoke, not a calibrated vehicle benchmark or a completed Gate B.

## Declared checks

Observe the chassis six seconds after it spawns. Require four supported wheels, upright orientation, height within 0.05 m of the static spring prediction, and linear speed below 0.1 m/s. These smoke tolerances were set before the first launch and were not widened after failure.

With 1400 kg, 9.80665 m/s² gravity, four 32,000 N/m springs, 0.55 m rest length, and 0.32 m wheel radius, the predicted chassis origin height above a ground top at zero is:

`0.55 + 0.32 - (1400 * 9.80665 / 4) / 32000 = 0.762739765625 m`

An exploratory corrected run on Studio **0.745.0.7451137** observed **0.7643560123 m**, **0.0322126636 m/s**, four supported wheels, and an upright chassis. This is approximately 1.62 mm above the scalar equilibrium prediction. A single sample does not establish long-duration settling or sample-rate independence.

The final repeatable harness passed on the same engine build with **0.7605582619 m** height, **0.0017838275 m/s** speed, four supported wheels, and `UpVector.Y = 1`. Height error was about **−2.18 mm**. The actual server completion marker and JSON report were verified. [measurement.json](measurement.json) records that run and the source file hashes. Variation between these samples reinforces the need for a time-series settling protocol.

## Failures and corrections

1. The original sandbox run reported 1.0690819454 m against the zero-ground prediction and failed the height assertion. Inspection found that `Position` was serialized as a separate property rather than the intended `CFrame`; the initial ground placement did not survive as intended. Ground/spawn transforms now use Rojo's 12-component CFrame representation, and artifact inspection asserts the ground translation.
2. Code review also found sequential impulse application while subsequent wheels were still sampling the body. Forces now sample all contacts before applying impulses. This correction was made with the ground fix; the experiment does not independently attribute an error magnitude to either change.
3. Some CLI attempts ended without a completion marker. The installed Studio build can return from `ExecuteRunModeAsync` before the probe is finished. The harness now keeps the entry coroutine alive if the result is nil and requires an actual server-emitted marker. Exit code zero alone is rejected.
4. A harness attempt waited for `game.Loaded` in edit mode and timed out; that redundant wait was removed because the CLI already runs the entry after opening the place.
5. Reading `Workspace.PhysicsSteppingMethod` from the runtime probe failed in this installed build despite its presence in downloaded definitions. The metadata read is now guarded and reported as unavailable when inaccessible. The smoke makes no claim about the actual solver stepping mode.

## Reproduction and evidence

```powershell
./scripts/check.ps1
./scripts/studio-smoke.ps1
```

The wrapper launches a dedicated local place, injects its probe into the test copy, records JSON/log output under ignored `build/studio`, and closes the process. It publishes no experience and saves no edits into a user-authored place. The public JSON report contains only test observations and source hashes; full machine-specific Studio logs remain local.

Simulation dt distribution, CPU/device characterization, force time series, moving ground, slope creep, driving input, and network latency were not measured. The next experiment should collect time series and repeat the static case under declared stepping and frame-rate conditions.
