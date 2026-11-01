# ADR-001: SI core and explicit Roblox boundary

Status: accepted for the experimental foundation. Date: 2026-11-01.

The supplied research identifies unit/gravity mismatches as a major source of false realism. Adopt standard Roblox unit conversions, SI-only core functions, radian angles, and an Earth-gravity sandbox. Convert once when reading/writing engine state.

Consequences: real parameter provenance remains legible, tests run without Studio, and all engine adapters share one boundary. Existing experiences at a different gravity require an explicit compatibility/calibration decision. A matched mass alone does not identify chassis inertia.
