--!strict
-- Synthetic radial brush approximation and a monotone backward-Euler wheel solve.
-- These are transparent reference models, not fitted measured tire data.
export type BrushConfig = {
    frictionCoefficient: number,
    nominalLoadN: number,
    loadSensitivity: number,
    longitudinalStiffnessN: number,
    corneringStiffnessNPerRad: number,
}

export type WheelInput = {
    angularSpeedRadS: number,
    longitudinalSpeedMS: number,
    driveTorqueNm: number,
    brakeTorqueNm: number,
    inertiaKgM2: number,
    radiusM: number,
    longitudinalStiffnessN: number,
    forceLimitN: number,
    slipRegularizationMS: number,
    dt: number,
}

local Tire = {}

function Tire.slip(
    angularSpeed: number,
    radius: number,
    speed: number,
    regularization: number
): number
    assert(radius > 0 and regularization > 0, "Invalid slip geometry")
    return (angularSpeed * radius - speed) / math.max(math.abs(speed), regularization)
end

function Tire.frictionLimit(normalLoadN: number, config: BrushConfig): number
    assert(config.nominalLoadN > 0, "Nominal tire load must be positive")
    local load = math.max(normalLoadN, 0)
    local loadRatio = (load - config.nominalLoadN) / config.nominalLoadN
    local mu = math.max(0, config.frictionCoefficient * (1 - config.loadSensitivity * loadRatio))
    return mu * load
end

-- Force axes: longitudinal forward; lateral left. Positive lateral slip gets negative force.
-- The radial extension of the cubic brush law guarantees a combined force bound.
function Tire.brush(
    longitudinalSlip: number,
    lateralSlipAngle: number,
    normalLoadN: number,
    config: BrushConfig
): (number, number)
    local cap = Tire.frictionLimit(normalLoadN, config)
    if cap <= 0 then
        return 0, 0
    end
    local fx = config.longitudinalStiffnessN * longitudinalSlip
    local fy = -config.corneringStiffnessNPerRad * math.tan(math.clamp(lateralSlipAngle, -1.4, 1.4))
    local demand = math.sqrt(fx * fx + fy * fy)
    if demand <= 1e-12 then
        return 0, 0
    end
    local q = math.min(demand / (3 * cap), 1)
    local magnitude = cap * (3 * q - 3 * q * q + q * q * q)
    return fx * magnitude / demand, fy * magnitude / demand
end

-- Dry brake torque is a set-valued friction law at zero speed. Solve the zero-speed
-- interval first, then bisect the strictly increasing residual on the proper side.
-- Velocity and load remain frozen: this does not prove coupled chassis stability.
function Tire.stepWheel(input: WheelInput): (number, number)
    for _, value in input do
        assert(
            typeof(value) == "number" and value == value and math.abs(value) < math.huge,
            "Wheel inputs must be finite"
        )
    end
    assert(input.dt > 0 and input.inertiaKgM2 > 0 and input.radiusM > 0, "Invalid wheel dynamics")
    assert(input.slipRegularizationMS > 0, "Slip regularization must be positive")
    assert(input.forceLimitN >= 0 and input.brakeTorqueNm >= 0, "Invalid force/torque limits")
    assert(input.longitudinalStiffnessN >= 0, "Tire stiffness must be nonnegative")
    local inverseStepInertia = input.inertiaKgM2 / input.dt
    local denominator = math.max(math.abs(input.longitudinalSpeedMS), input.slipRegularizationMS)
    local function force(omega: number): number
        local slip = (input.radiusM * omega - input.longitudinalSpeedMS) / denominator
        return math.clamp(
            input.longitudinalStiffnessN * slip,
            -input.forceLimitN,
            input.forceLimitN
        )
    end
    local function residual(omega: number): number
        return inverseStepInertia * (omega - input.angularSpeedRadS)
            - input.driveTorqueNm
            + input.radiusM * force(omega)
    end

    local atRest = residual(0)
    if math.abs(atRest) <= input.brakeTorqueNm then
        return 0, force(0)
    end
    local direction = if atRest < 0 then 1 else -1
    local bound = math.abs(input.angularSpeedRadS)
        + input.dt * (math.abs(input.driveTorqueNm) + input.brakeTorqueNm + input.radiusM * input.forceLimitN) / input.inertiaKgM2
        + 1
    local low = if direction > 0 then 0 else -bound
    local high = if direction > 0 then bound else 0
    for _ = 1, 48 do
        local middle = (low + high) * 0.5
        if residual(middle) + direction * input.brakeTorqueNm > 0 then
            high = middle
        else
            low = middle
        end
    end
    local omega = (low + high) * 0.5
    return omega, force(omega)
end

return table.freeze(Tire)
