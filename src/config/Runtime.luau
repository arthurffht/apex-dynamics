--!strict
-- This file is the canonical simulation-host selection; apex.ps1 mode updates it.
return table.freeze({
    simulationHost = "Server" :: "Server" | "Client",
    inputTimeoutS = 0.5,
    maximumInputHz = 40,
    telemetryHz = 10,
})
