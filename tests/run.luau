--!strict
local Units = require("../src/core/Units")
local Numerics = require("../src/core/Numerics")
local Tire = require("../src/core/Tire")
local Suspension = require("../src/core/Suspension")
local Powertrain = require("../src/core/Powertrain")
local Input = require("../src/core/Input")
local Preset = require("../src/presets/ReferenceSedan")
local DriverSession = require("../src/roblox/DriverSession")

local cases = 0
local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    assert(condition, message)
end
local function near(actual: number, expected: number, tolerance: number)
    check(
        math.abs(actual - expected) <= tolerance,
        string.format("%.12g != %.12g", actual, expected)
    )
end
local function test(name: string, callback: () -> ())
    callback()
    cases += 1
    print("PASS " .. name)
end

local tireConfig = Preset.tire
local function wheel(overrides: { [string]: number }): Tire.WheelInput
    local values: Tire.WheelInput = {
        angularSpeedRadS = 0,
        longitudinalSpeedMS = 0,
        driveTorqueNm = 0,
        brakeTorqueNm = 0,
        inertiaKgM2 = 1.4,
        radiusM = 0.32,
        longitudinalStiffnessN = 65000,
        forceLimitN = 3500,
        slipRegularizationMS = 4,
        dt = 1 / 60,
    }
    local mutable = (values :: unknown) :: { [string]: number }
    for key, value in overrides do
        mutable[key] = value
    end
    return values
end

test("SI conversion round trips and dimensions", function()
    for _, value in { -1000, -1, 0, 1, 123.456, 1e6 } do
        near(Units.toMeters(Units.toStuds(value)), value, 1e-8)
        near(Units.toKilograms(Units.toRobloxMass(value)), value, 1e-8)
    end
    near(Units.toRobloxForce(21.952 * 0.28), 1, 1e-12)
    near(Units.toRobloxTorque(21.952 * 0.28 * 0.28), 1, 1e-12)
    near(Units.toStuds(Units.STANDARD_GRAVITY), 35.02375, 1e-10)
end)

test("finite-value guard", function()
    check(Numerics.isFinite(0), "Zero should be finite")
    check(not Numerics.isFinite(math.huge), "Infinity must be rejected")
    check(not Numerics.isFinite(0 / 0), "NaN must be rejected")
end)

test("exact relaxation is independent of partition", function()
    local combined = Numerics.relax(-3, 8, 0.3, 0.2)
    local split = Numerics.relax(Numerics.relax(-3, 8, 0.1, 0.2), 8, 0.2, 0.2)
    near(combined, split, 1e-12)
    near(Numerics.relaxByDistance(2, 7, 0, 1, 0.5), 2, 0)
    near(Numerics.rateLimit(0, 10, 2, 0.1), 0.2, 1e-12)
end)

test("brush tire combined grip, symmetry and dissipation", function()
    for _, load in { 0, 500, 3500, 7000, 14000 } do
        for i = -15, 15 do
            for j = -15, 15 do
                local kappa, alpha = i / 10, j / 30
                local fx, fy = Tire.brush(kappa, alpha, load, tireConfig)
                local rx, ry = Tire.brush(-kappa, -alpha, load, tireConfig)
                local limit = Tire.frictionLimit(load, tireConfig)
                check(fx * fx + fy * fy <= limit * limit + 1e-6, "Combined grip exceeded")
                check(fx * kappa >= -1e-9 and fy * alpha <= 1e-9, "Incorrect tire force sign")
                near(fx, -rx, 1e-8)
                near(fy, -ry, 1e-8)
            end
        end
    end
end)

test("load sensitivity reduces normalized grip", function()
    local low = Tire.frictionLimit(2000, tireConfig) / 2000
    local high = Tire.frictionLimit(7000, tireConfig) / 7000
    check(high < low, "Normalized grip must decrease with load")
end)

test("backward Euler matches the unsaturated analytic solution", function()
    local data =
        wheel({ longitudinalSpeedMS = 10, angularSpeedRadS = 10 / 0.32, driveTorqueNm = 50 })
    local denominator = math.max(math.abs(data.longitudinalSpeedMS), data.slipRegularizationMS)
    local lambda = data.radiusM ^ 2 * data.longitudinalStiffnessN / (data.inertiaKgM2 * denominator)
    local exact = (
        data.angularSpeedRadS
        + data.dt
            / data.inertiaKgM2
            * (data.driveTorqueNm + data.radiusM * data.longitudinalStiffnessN * data.longitudinalSpeedMS / denominator)
    ) / (1 + data.dt * lambda)
    local omega = Tire.stepWheel(data)
    near(omega, exact, 1e-10)
end)

test("wheel solve conserves discrete torque balance across regimes", function()
    for _, speed in { -30, -0.1, 0, 0.1, 30 } do
        for _, torque in { -3000, -30, 0, 30, 3000 } do
            for _, brake in { 0, 50, 2000 } do
                for _, dt in { 1 / 240, 1 / 60, 1 / 20 } do
                    local data = wheel({
                        longitudinalSpeedMS = speed,
                        driveTorqueNm = torque,
                        brakeTorqueNm = brake,
                        dt = dt,
                        angularSpeedRadS = speed / 0.32,
                    })
                    local omega, force = Tire.stepWheel(data)
                    local residual = data.inertiaKgM2 * (omega - data.angularSpeedRadS) / dt
                        - torque
                        + data.radiusM * force
                    check(Numerics.isFinite(omega), "Nonfinite wheel state")
                    check(math.abs(force) <= data.forceLimitN + 1e-9, "Wheel grip exceeded")
                    if math.abs(omega) < 1e-9 then
                        check(math.abs(residual) <= brake + 1e-6, "Invalid brake hold")
                    else
                        near(residual + math.sign(omega) * brake, 0, 1e-6)
                    end
                end
            end
        end
    end
end)

test("brake stops an airborne wheel without reversing it", function()
    for _, sign in { -1, 1 } do
        local omega = Tire.stepWheel(
            wheel({ angularSpeedRadS = sign * 10, brakeTorqueNm = 2000, forceLimitN = 0 })
        )
        near(omega, 0, 0)
    end
end)

test("isolated stiff wheel converges without explicit-Euler oscillation", function()
    local omega = 0
    for _ = 1, 120 do
        local nextOmega =
            Tire.stepWheel(wheel({ angularSpeedRadS = omega, longitudinalSpeedMS = 0.1 }))
        check(
            nextOmega >= omega - 1e-10 and nextOmega <= 0.1 / 0.32 + 1e-10,
            "Stiff wheel overshoot"
        )
        omega = nextOmega
    end
    near(omega, 0.1 / 0.32, 1e-9)
end)

test("unsupported wheels produce no contact force", function()
    local omega, force = Tire.stepWheel(wheel({ driveTorqueNm = 100, forceLimitN = 0 }))
    near(force, 0, 0)
    near(omega, 100 / 1.4 / 60, 1e-10)
end)

test("suspension is unilateral and supports quarter-car equilibrium", function()
    near(Suspension.normalLoad(-0.01, 10, 32000, 3200, 18000), 0, 0)
    near(Suspension.normalLoad(0.1, -10, 32000, 3200, 18000), 0, 0)
    near(Suspension.normalLoad(10, 10, 32000, 3200, 18000), 18000, 0)
    local quarterWeight = Preset.massKg * Units.STANDARD_GRAVITY / 4
    near(Suspension.normalLoad(quarterWeight / 32000, 0, 32000, 3200, 18000), quarterWeight, 1e-9)
    near(Suspension.criticalDamping(350, 32000), 2 * math.sqrt(350 * 32000), 1e-9)
end)

test("Ackermann symmetry and turning geometry", function()
    local left, right = Suspension.ackermann(0.3, 2.7, 1.55)
    local reverseLeft, reverseRight = Suspension.ackermann(-0.3, 2.7, 1.55)
    check(left > right and right > 0, "Inside wheel must turn more")
    near(left, -reverseRight, 1e-12)
    near(right, -reverseLeft, 1e-12)
    near(2.7 / math.tan(right) - 2.7 / math.tan(left), 1.55, 1e-10)
end)

test("motor respects torque and power limits", function()
    for _, speed in { -1000, -100, 0, 100, 1000, 1200 } do
        local torque = Powertrain.motorTorque(1, speed, 240, 110000, 1200)
        check(math.abs(torque) <= 240, "Motor torque exceeded")
        check(math.abs(torque * speed) <= 110000 + 1e-9, "Motor power exceeded")
        near(Powertrain.motorTorque(-1, speed, 240, 110000, 1200), -torque, 1e-9)
    end
    near(Powertrain.motorTorque(1, 1200, 240, 110000, 1200), 0, 0)
end)

test("aerodynamic drag always dissipates energy", function()
    for _, speed in { -100, -1, 0, 1, 100 } do
        check(Powertrain.dragForce(speed, 1.225, 0.65) * speed <= 0, "Drag added energy")
    end
end)

test("remote input rejects malformed and nonfinite commands", function()
    check(Input.validate({ throttle = 1, brake = 0, steering = -1 }) ~= nil, "Valid input rejected")
    local invalid: { unknown } = {
        false,
        "bad",
        {},
        { throttle = 0 / 0, brake = 0, steering = 0 },
        { throttle = math.huge, brake = 0, steering = 0 },
        { throttle = 0, brake = -1, steering = 0 },
        { throttle = 0, brake = 0, steering = 2 },
        { throttle = 0, brake = 0, steering = 0, force = 1e9 },
    }
    for _, payload in invalid do
        check(Input.validate(payload) == nil, "Malformed input accepted")
    end
end)

test("ownership policy selects exactly one simulator", function()
    for _, host in { "Server", "Client" } do
        for _, driver in { 0, 10, 20 } do
            local simulators = if DriverSession.shouldSimulate(host, true, 0, driver) then 1 else 0
            for _, localUser in { 10, 20 } do
                if DriverSession.shouldSimulate(host, false, localUser, driver) then
                    simulators += 1
                end
            end
            check(simulators == 1, "Concurrent or missing simulator")
        end
    end
    check(not DriverSession.shouldSimulate("Unknown", true, 0, 0), "Unknown mode must fail closed")
end)

test("wheel API rejects nonfinite fields", function()
    local fields = {
        "angularSpeedRadS",
        "longitudinalSpeedMS",
        "driveTorqueNm",
        "brakeTorqueNm",
        "inertiaKgM2",
        "radiusM",
        "longitudinalStiffnessN",
        "forceLimitN",
        "slipRegularizationMS",
        "dt",
    }
    for _, field in fields do
        for _, value in { 0 / 0, math.huge, -math.huge } do
            local ok = pcall(Tire.stepWheel, wheel({ [field] = value }))
            check(not ok, "Nonfinite " .. field .. " was accepted")
        end
    end
end)

test("passive wheel energy under seeded adversarial physical inputs", function()
    local seed = 20261101
    local function random(): number
        seed = (seed * 48271) % 2147483647
        return seed / 2147483647
    end
    for _ = 1, 4000 do
        local data = wheel({
            angularSpeedRadS = (random() - 0.5) * 2000,
            inertiaKgM2 = 0.1 + random() * 100,
            radiusM = 0.05 + random() * 2,
            longitudinalStiffnessN = 1000 + random() * 1e6,
            forceLimitN = random() * 100000,
            slipRegularizationMS = 0.1 + random() * 10,
            brakeTorqueNm = random() * 10000,
            dt = 0.0001 + random() * 0.1,
        })
        local nextOmega, force = Tire.stepWheel(data)
        check(
            Numerics.isFinite(nextOmega) and Numerics.isFinite(force),
            "Nonfinite adversarial result"
        )
        check(
            nextOmega ^ 2 <= data.angularSpeedRadS ^ 2 + 1e-6,
            "Passive wheel gained kinetic energy"
        )
        check(math.abs(force) <= data.forceLimitN + 1e-6, "Adversarial grip exceeded")
    end
end)

print(
    string.format(
        "%d tests passed; %d assertions. Offline Luau results, not Roblox measurements.",
        cases,
        assertions
    )
)
