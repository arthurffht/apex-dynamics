--!strict
local Workspace = game:GetService("Workspace")
local Core = script.Parent.Parent.Core
local Units = require(Core.Units)
local Numerics = require(Core.Numerics)
local Tire = require(Core.Tire)
local Suspension = require(Core.Suspension)
local Powertrain = require(Core.Powertrain)
local Input = require(Core.Input)
local ReferenceSedan = require(script.Parent.Parent.Presets.ReferenceSedan)

type Config = typeof(ReferenceSedan)
type Wheel = { offset: Vector3, omega: number, front: boolean, left: boolean }

local Vehicle = {}
Vehicle.__index = Vehicle

type VehicleState = {
    chassis: BasePart,
    config: Config,
    query: RaycastParams,
    wheels: { Wheel },
    steering: number,
    elapsedS: number,
    supportedWheels: number,
}
export type Vehicle = typeof(setmetatable({} :: VehicleState, Vehicle))

function Vehicle.new(chassis: BasePart, config: Config?, exclusions: { Instance }): Vehicle
    assert(not chassis.Anchored, "Vehicle chassis must be unanchored")
    local resolvedConfig = config or ReferenceSedan
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = exclusions
    params.RespectCanCollide = true
    local wheels: { Wheel } = {}
    for _, front in { true, false } do
        for _, left in { true, false } do
            table.insert(wheels, {
                offset = Vector3.new(
                    Units.toStuds(resolvedConfig.trackM * (if left then -0.5 else 0.5)),
                    0,
                    Units.toStuds(resolvedConfig.wheelbaseM * (if front then -0.5 else 0.5))
                ),
                omega = 0,
                front = front,
                left = left,
            })
        end
    end
    return setmetatable({
        chassis = chassis,
        config = resolvedConfig,
        query = params,
        wheels = wheels,
        steering = 0,
        elapsedS = 0,
        supportedWheels = 0,
    }, Vehicle)
end

-- PreSimulation adapter; not a rollback-safe BindToSimulation implementation.
function Vehicle.step(self: Vehicle, dt: number, command: Input.Command)
    if not Numerics.isFinite(dt) or dt <= 0 then
        return
    end
    -- An unbounded hitch must not inject a large impulse using stale contact geometry.
    -- Telemetry records elapsed time; callers should treat dt > 0.1 as a failed fidelity run.
    self.elapsedS += dt
    if dt > 0.1 then
        return
    end
    local config = self.config
    local chassis: BasePart = self.chassis
    local frame = chassis.CFrame
    local up = frame.UpVector
    self.steering = Numerics.rateLimit(
        self.steering,
        command.steering * config.maximumSteerRad,
        config.steeringRateRadS,
        dt
    )
    local leftSteer, rightSteer =
        Suspension.ackermann(self.steering, config.wheelbaseM, config.trackM)
    local supported = 0
    for _, wheel in self.wheels do
        local origin = frame:PointToWorldSpace(wheel.offset)
        local castLength = Units.toStuds(config.suspensionRestLengthM + config.wheelRadiusM)
        local hit = Workspace:Raycast(origin, -up * castLength, self.query)
        local steer = if wheel.front then (if wheel.left then leftSteer else rightSteer) else 0
        local forward = frame.LookVector * math.cos(steer) - frame.RightVector * math.sin(steer)
        local normalLoad = 0
        local longitudinalSpeed = 0
        local lateralSpeed = 0
        local contact: Vector3? = nil
        local ground: BasePart? = nil
        local normal = up
        if hit and hit.Normal:Dot(up) > 0.25 then
            contact = hit.Position
            normal = hit.Normal
            if hit.Instance:IsA("BasePart") then
                ground = hit.Instance
            end
            forward -= normal * forward:Dot(normal)
            forward = forward.Unit
            local left = normal:Cross(forward)
            local groundVelocity = if ground
                then ground:GetVelocityAtPosition(hit.Position)
                else Vector3.zero
            local relativeVelocity = chassis:GetVelocityAtPosition(hit.Position) - groundVelocity
            local velocitySI = relativeVelocity * Units.METERS_PER_STUD
            longitudinalSpeed = velocitySI:Dot(forward)
            lateralSpeed = velocitySI:Dot(left)
            local compression = config.suspensionRestLengthM
                + config.wheelRadiusM
                - Units.toMeters(hit.Distance)
            normalLoad = Suspension.normalLoad(
                compression,
                -velocitySI:Dot(up),
                config.springStiffnessNPerM,
                config.damperNsPerM,
                config.maximumWheelLoadN
            )
            supported += 1
        end
        local cap = Tire.frictionLimit(normalLoad, config.tire)
        local slipAngle = math.atan(
            lateralSpeed / math.max(math.abs(longitudinalSpeed), config.slipRegularizationMS)
        )
        local _, lateralForce = Tire.brush(0, slipAngle, normalLoad, config.tire)
        -- Limit low-speed lateral impulse using a quarter of the assembly mass. This is
        -- a passive local approximation; rotational coupling and slope hold need validation.
        local shareMassKg = Units.toKilograms(chassis.AssemblyMass) / 4
        local lateralImpulseCap = shareMassKg * math.abs(lateralSpeed) / dt
        lateralForce = math.clamp(lateralForce, -lateralImpulseCap, lateralImpulseCap)
        local longitudinalCap = math.sqrt(math.max(0, cap * cap - lateralForce * lateralForce))
        local driveTorque = 0
        if not wheel.front then
            driveTorque = Powertrain.motorTorque(
                command.throttle,
                wheel.omega * config.finalDriveRatio,
                config.peakMotorTorqueNm,
                config.peakMotorPowerW,
                config.maximumMotorSpeedRadS
            ) * config.finalDriveRatio * config.drivelineEfficiency * 0.5
        end
        local omega, longitudinalForce = Tire.stepWheel({
            angularSpeedRadS = wheel.omega,
            longitudinalSpeedMS = longitudinalSpeed,
            driveTorqueNm = driveTorque,
            brakeTorqueNm = command.brake * config.brakeTorquePerWheelNm,
            inertiaKgM2 = config.wheelInertiaKgM2,
            radiusM = config.wheelRadiusM,
            longitudinalStiffnessN = config.tire.longitudinalStiffnessN,
            forceLimitN = longitudinalCap,
            slipRegularizationMS = config.slipRegularizationMS,
            dt = dt,
        })
        wheel.omega = omega
        if contact then
            local left = normal:Cross(forward)
            local forceSI = normal * normalLoad + forward * longitudinalForce + left * lateralForce
            local impulse = forceSI * Units.toRobloxForce(dt)
            chassis:ApplyImpulseAtPosition(impulse, contact)
            if ground and not ground.Anchored then
                ground:ApplyImpulseAtPosition(-impulse, contact)
            end
        end
    end
    self.supportedWheels = supported
    local velocity = chassis.AssemblyLinearVelocity * Units.METERS_PER_STUD
    local speed = velocity.Magnitude
    if speed > 1e-6 then
        local drag = Powertrain.dragForce(speed, config.airDensityKgM3, config.dragAreaM2)
        chassis:ApplyImpulse(velocity / speed * Units.toRobloxForce(drag * dt))
    end
end

return Vehicle
