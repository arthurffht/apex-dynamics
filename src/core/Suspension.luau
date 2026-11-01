--!strict
local Suspension = {}

-- Positive compression and compression velocity increase supporting load.
function Suspension.normalLoad(
    compressionM: number,
    compressionSpeedMS: number,
    stiffnessNPerM: number,
    dampingNsPerM: number,
    maximumLoadN: number
): number
    assert(stiffnessNPerM >= 0 and dampingNsPerM >= 0 and maximumLoadN >= 0, "Invalid suspension")
    if compressionM < 0 then
        return 0
    end
    return math.clamp(
        compressionM * stiffnessNPerM + compressionSpeedMS * dampingNsPerM,
        0,
        maximumLoadN
    )
end

function Suspension.criticalDamping(sprungMassKg: number, stiffnessNPerM: number): number
    assert(sprungMassKg > 0 and stiffnessNPerM > 0, "Invalid quarter-car parameters")
    return 2 * math.sqrt(sprungMassKg * stiffnessNPerM)
end

-- Relative to a centered rack command; positive angles steer left in the model.
function Suspension.ackermann(
    centerAngleRad: number,
    wheelbaseM: number,
    trackM: number
): (number, number)
    assert(wheelbaseM > 0 and trackM > 0, "Invalid steering geometry")
    if math.abs(centerAngleRad) < 1e-8 then
        return 0, 0
    end
    local radius = wheelbaseM / math.tan(math.abs(centerAngleRad))
    assert(radius > trackM * 0.5, "Steering command exceeds Ackermann geometry")
    local inner = math.atan(wheelbaseM / (radius - trackM * 0.5))
    local outer = math.atan(wheelbaseM / (radius + trackM * 0.5))
    return if centerAngleRad > 0 then inner else -outer,
        if centerAngleRad > 0 then outer else -inner
end

return table.freeze(Suspension)
