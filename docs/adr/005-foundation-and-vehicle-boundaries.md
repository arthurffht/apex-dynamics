# ADR-005: Deliver the project foundation before vehicle features

Date: 2026-11-01. Status: accepted.

The owner clarified that the immediate deliverable is the complete project structure, technical decisions, current laboratory place, tests, observability, synchronization, and autonomous workflow. The experimental vehicle fixture is evidence infrastructure, not the start of production vehicle development.

Decision: make the default Studio entry a foundation laboratory with no vehicle. Preserve prior physics code and measurements as opt-in fixtures. Compose static laboratory assets from one Rojo scene file; share the same eight infrastructure checks between interactive Play and CLI tests. Add engine-independent bounded world planning and diagnostics without changing tire/suspension equations.

The target architecture is a native rigid chassis with replaceable contact and force adapters. Raycast is the reference; finite-volume queries and native constraint architectures require comparison gates. Ordinary Server hosting under Automatic engine authority is the laboratory default; Client is an explicit experimental profile and rollback is a separate future backend. Use serialized profiles for properties unavailable to this MCP context.

An extensive world uses logical sectors plus a bounded local window. Continuous body rebasing remains a separately gated transaction. Source files, loaded modules, GitHub commits, generated artifacts, and cloud versions have distinct identities and promotion rules.

Consequences: the next queue prioritizes foundation acceptance and current-place synchronization. Do not begin a vehicle fidelity fix until that gate closes and vehicle work is requested. Existing failed slope-hold evidence is retained. A historical Defender block did not reproduce in the current full local check; no security-setting change or bypass is part of this decision.

Supersession: this changes the immediate continuation order in earlier STATE/roadmap entries; it does not erase historical experiments or claim their limitations are resolved. See system-design.md, laboratory.md, platform-capabilities.md, and development-workflow.md.
