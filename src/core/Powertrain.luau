--!strict
local Powertrain = {}

-- Idealized symmetric EV envelope. Battery, inverter and thermal models are future work.
function Powertrain.motorTorque(
    throttle: number,
    angularSpeedRadS: number,
    peakTorqueNm: number,
    peakPowerW: number,
    maximumSpeedRadS: number
): number
    assert(peakTorqueNm >= 0 and peakPowerW >= 0 and maximumSpeedRadS > 0, "Invalid motor envelope")
    local speed = math.abs(angularSpeedRadS)
    if speed >= maximumSpeedRadS then
        return 0
    end
    local available = math.min(peakTorqueNm, peakPowerW / math.max(speed, 1e-6))
    return math.clamp(throttle, -1, 1) * available
end

function Powertrain.dragForce(speedMS: number, airDensityKgM3: number, dragAreaM2: number): number
    assert(airDensityKgM3 >= 0 and dragAreaM2 >= 0, "Invalid aerodynamic parameters")
    return -0.5 * airDensityKgM3 * dragAreaM2 * speedMS * math.abs(speedMS)
end

return table.freeze(Powertrain)
