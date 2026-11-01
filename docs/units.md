# Units and coordinate conventions

The core uses meters, kilograms, seconds, newtons, newton-meters, radians, and watts. Configuration names carry units. The Roblox adapter converts at the boundary; it does not retune SI data to disguise a scale error.

| Quantity | One Roblox unit in SI | SI to Roblox |
| --- | --- | --- |
| Length | 0.28 m per stud | divide by 0.28 |
| Mass | 21.952 kg per RMU | divide by 21.952 |
| Force / impulse | 6.14656 N / N·s | divide by 6.14656 |
| Torque / inertia | 1.7210368 N·m / kg·m² | divide by 1.7210368 |
| Linear spring stiffness / damping | 21.952 N/m / N·s/m | divide by 21.952 |
| Density | 1000 kg/m³ | divide by 1000 |

These factors follow the [standard Roblox unit interpretation](https://create.roblox.com/docs/physics/units). Time and angles are unchanged. The sandbox sets gravity to **35.02375 studs/s²**, corresponding to 9.80665 m/s². Under the same length scale, Roblox's usual 196.2 studs/s² is 54.936 m/s². A calibration at Earth gravity cannot silently carry over to that load regime.

## Axes and signs

Core tire coordinates are forward, left, and up. For a chassis CFrame these map to `LookVector`, `-RightVector`, and `UpVector`. A positive steering command turns left. Contact tangents are projected onto the hit surface; left is `normal:Cross(forward)`.

Longitudinal slip is `(radius * omega - forwardSpeed) / max(abs(forwardSpeed), regularizationSpeed)`. Positive slip produces a forward chassis force. Positive lateral velocity produces a left-positive slip angle and a negative lateral force. Wheel speed is a signed scalar representing forward rolling, independent of a visual mesh's local cylinder axis.

Brake torque opposes rotation, and at zero rotation may hold any torque inside its configured bound. Do not subtract a positive braking torque unconditionally: that would accelerate a reverse-rotating wheel in the wrong direction. Aerodynamic force opposes relative air velocity; the current sandbox assumes still air.

## Model validity

Synthetic tire load sensitivity is an illustrative linear change in normalized grip. It must be calibrated and bounded to a declared load range before use as a measured tire model. The reference sedan uses a single chassis box, not a measured inertia tensor or identified center of gravity. Changing the visual dimensions changes its inertia even when total mass stays fixed.
