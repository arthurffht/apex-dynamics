--!strict
-- SI inside the model; standard Roblox units at the engine boundary.
local Units = {
    METERS_PER_STUD = 0.28,
    KILOGRAMS_PER_RMU = 21.952,
    NEWTONS_PER_ROBLOX_FORCE = 6.14656,
    NEWTON_METERS_PER_ROBLOX_TORQUE = 1.7210368,
    STANDARD_GRAVITY = 9.80665,
}

function Units.toStuds(meters: number): number
    return meters / Units.METERS_PER_STUD
end

function Units.toMeters(studs: number): number
    return studs * Units.METERS_PER_STUD
end

function Units.toRobloxMass(kilograms: number): number
    return kilograms / Units.KILOGRAMS_PER_RMU
end

function Units.toKilograms(robloxMass: number): number
    return robloxMass * Units.KILOGRAMS_PER_RMU
end

function Units.toRobloxForce(newtons: number): number
    return newtons / Units.NEWTONS_PER_ROBLOX_FORCE
end

function Units.toRobloxTorque(newtonMeters: number): number
    return newtonMeters / Units.NEWTON_METERS_PER_ROBLOX_TORQUE
end

return table.freeze(Units)
