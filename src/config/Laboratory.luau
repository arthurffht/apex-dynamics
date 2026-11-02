--!strict
-- Development laboratory only. No vehicle is spawned by default.
return table.freeze({
    schemaVersion = 1,
    enabled = true,
    autoRun = true,
    referenceVehicleEnabled = false,
    seed = 20261101,
    eventCapacity = 256,
    updateIntervalS = 0.2,
    caseBudgetS = 2,
    world = table.freeze({
        tileSizeM = 71.68,
        radius = 2,
        maxTiles = 25,
        originXM = 672,
        originZM = 0,
    }),
})
