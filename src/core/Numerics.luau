--!strict
local Numerics = {}

function Numerics.isFinite(value: number): boolean
    return value == value and math.abs(value) < math.huge
end

-- Exact scalar relaxation for a constant target during the sample interval.
function Numerics.relax(current: number, target: number, dt: number, timeConstant: number): number
    assert(dt >= 0 and timeConstant > 0, "Expected nonnegative dt and positive time constant")
    return target + (current - target) * math.exp(-dt / timeConstant)
end

function Numerics.relaxByDistance(
    current: number,
    target: number,
    speed: number,
    dt: number,
    relaxationLength: number
): number
    assert(dt >= 0 and relaxationLength > 0, "Invalid relaxation parameters")
    return target + (current - target) * math.exp(-math.abs(speed) * dt / relaxationLength)
end

function Numerics.rateLimit(current: number, target: number, rate: number, dt: number): number
    assert(rate >= 0 and dt >= 0, "Invalid rate limit")
    return current + math.clamp(target - current, -rate * dt, rate * dt)
end

return table.freeze(Numerics)
