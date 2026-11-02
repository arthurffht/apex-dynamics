--!strict
local RunService = game:GetService("RunService")
local StudioTestService = game:GetService("StudioTestService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Package = ReplicatedStorage:WaitForChild("ApexDynamics")
local Vehicle = require(Package.Roblox.Vehicle)
local Factory = require(Package.Roblox.VehicleFactory)
local Units = require(Package.Core.Units)
local Config = require(Package.Presets.ReferenceSedan)
local BuildInfo = require(Package.Dev.BuildInfo)
local args = StudioTestService:GetTestArgs()
local suite = if typeof(args) == "table" and typeof(args.suite) == "string"
    then args.suite
    else "Regression"
type Metrics = { [string]: any }
local results: { Metrics } = {}
local observations: { Metrics } = {}
local activeModel: Model? = nil
local activeConnection: RBXScriptConnection? = nil
local extraParts: { Instance } = {}
local gravity = Workspace.Gravity

local function cleanup()
    if activeConnection then
        activeConnection:Disconnect()
        activeConnection = nil
    end
    if activeModel then
        activeModel:Destroy()
        activeModel = nil
    end
    for _, part in extraParts do
        part:Destroy()
    end
    table.clear(extraParts)
    Workspace.Gravity = gravity
end

local function scenario(name: string, research: boolean, callback: () -> Metrics)
    cleanup()
    observations = {}
    local ok, output = pcall(callback)
    local passed = ok and output.targetPassed ~= false
    table.insert(results, {
        name = name,
        research = research,
        passed = passed,
        metrics = if ok then output else nil,
        observations = if ok then nil else observations,
        error = if not ok
            then tostring(output)
            elseif not passed then "Research target was not reached"
            else nil,
    })
    print("APEX_CASE=" .. HttpService:JSONEncode(results[#results]))
    cleanup()
end

local function fixture(frame: CFrame?, configuration: typeof(Config)?): (BasePart, Vehicle.Vehicle)
    local model, root = Factory.create(configuration, frame, "ApexTestVehicle")
    activeModel = model
    return root, Vehicle.new(root, configuration, { model })
end

local function runFor(
    root: BasePart,
    vehicle: Vehicle.Vehicle,
    seconds: number,
    command: { throttle: number, brake: number, steering: number }
): Metrics
    local elapsed, samples, dtTotal, dtMaximum, peakSpeed = 0, 0, 0, 0, 0
    local trace: { Metrics } = {}
    table.insert(observations, { requestedDurationS = seconds, command = command, trace = trace })
    local traceElapsed = 0
    activeConnection = RunService.PreSimulation:Connect(function(dt)
        elapsed += dt
        dtTotal += dt
        samples += 1
        dtMaximum = math.max(dtMaximum, dt)
        vehicle:step(dt, command)
        local speed = root.AssemblyLinearVelocity.Magnitude * Units.METERS_PER_STUD
        peakSpeed = math.max(peakSpeed, speed)
        traceElapsed += dt
        if traceElapsed >= 0.1 then
            traceElapsed = 0
            table.insert(trace, {
                timeS = elapsed,
                speedMS = speed,
                heightM = root.Position.Y * Units.METERS_PER_STUD,
                supported = vehicle.supportedWheels,
                upY = root.CFrame.UpVector.Y,
            })
        end
    end)
    while elapsed < seconds do
        task.wait(0.02)
    end
    if activeConnection then
        activeConnection:Disconnect()
        activeConnection = nil
    end
    assert(
        root.Position.Magnitude < 1e6 and root.AssemblyLinearVelocity.Magnitude < 1e5,
        "State escaped finite physical bounds"
    )
    assert(vehicle.skippedSteps == 0, "A hitch invalidated this run")
    return {
        durationS = elapsed,
        samples = samples,
        meanDtS = dtTotal / samples,
        maximumDtS = dtMaximum,
        peakSpeedMS = peakSpeed,
        trace = trace,
    }
end

local stopped = { throttle = 0, brake = 1, steering = 0 }
local forwardPeak, reversePeak = 0, 0
scenario("static-support", false, function()
    local root, vehicle = fixture(nil, nil)
    local metrics = runFor(root, vehicle, 4, stopped)
    local expected = Config.suspensionRestLengthM
        + Config.wheelRadiusM
        - Config.massKg * Units.STANDARD_GRAVITY / (4 * Config.springStiffnessNPerM)
    metrics.heightM = root.Position.Y * Units.METERS_PER_STUD
    metrics.expectedHeightM = expected
    metrics.residualSpeedMS = root.AssemblyLinearVelocity.Magnitude * Units.METERS_PER_STUD
    assert(math.abs(metrics.heightM - expected) < 0.05, "Static height outside declared tolerance")
    assert(metrics.residualSpeedMS < 0.1 and vehicle.supportedWheels == 4, "Static support failed")
    assert(root.CFrame.UpVector.Y > 0.999, "Chassis is not upright")
    return metrics
end)

scenario("free-body-impulse-units", false, function()
    Workspace.Gravity = 0
    local root = fixture(CFrame.new(0, Units.toStuds(10), 0), nil)
    root:ApplyImpulse(Vector3.new(Units.toRobloxForce(Config.massKg * 2), 0, 0))
    task.wait(0.1)
    local observed = root.AssemblyLinearVelocity.X * Units.METERS_PER_STUD
    local mass = root.AssemblyMass * Units.KILOGRAMS_PER_RMU
    assert(math.abs(observed - 2) < 0.02, "SI impulse produced the wrong engine velocity")
    assert(
        math.abs(mass - Config.massKg) / Config.massKg < 0.01,
        "Engine assembly mass differs from preset"
    )
    return { expectedVelocityMS = 2, observedVelocityMS = observed, observedMassKg = mass }
end)

if suite ~= "Smoke" then
    scenario("drop-and-recovery", false, function()
        local root, vehicle = fixture(CFrame.new(0, Units.toStuds(3), 0), nil)
        local metrics = runFor(root, vehicle, 4, stopped)
        metrics.finalHeightM = root.Position.Y * Units.METERS_PER_STUD
        metrics.finalSpeedMS = root.AssemblyLinearVelocity.Magnitude * Units.METERS_PER_STUD
        assert(
            metrics.finalHeightM > 0.4 and metrics.finalHeightM < 1.2,
            "Drop did not recover support"
        )
        assert(metrics.finalSpeedMS < 1 and root.CFrame.UpVector.Y > 0.9, "Drop remained unstable")
        return metrics
    end)
    for _, direction in { 1, -1 } do
        scenario(
            if direction == 1 then "forward-launch-brake" else "reverse-launch-brake",
            false,
            function()
                local root, vehicle = fixture(nil, nil)
                runFor(root, vehicle, 1.5, stopped)
                local launch = runFor(
                    root,
                    vehicle,
                    2.5,
                    { throttle = direction * 0.5, brake = 0, steering = 0 }
                )
                local signedSpeed = root.AssemblyLinearVelocity:Dot(root.CFrame.LookVector)
                    * Units.METERS_PER_STUD
                assert(
                    signedSpeed * direction > 1,
                    "Drive torque has incorrect direction or insufficient acceleration"
                )
                if direction == 1 then
                    forwardPeak = math.abs(signedSpeed)
                else
                    reversePeak = math.abs(signedSpeed)
                end
                local braking = runFor(root, vehicle, 3, stopped)
                local residual = root.AssemblyLinearVelocity.Magnitude * Units.METERS_PER_STUD
                assert(residual < 0.5, "Brakes did not stop the vehicle")
                return {
                    launch = launch,
                    braking = braking,
                    signedLaunchSpeedMS = signedSpeed,
                    residualSpeedMS = residual,
                }
            end
        )
    end
    scenario("forward-reverse-symmetry", false, function()
        assert(forwardPeak > 0 and reversePeak > 0, "Launch prerequisites failed")
        local errorFraction = math.abs(forwardPeak - reversePeak)
            / math.max(forwardPeak, reversePeak)
        assert(errorFraction < 0.15, "Forward/reverse response differs by over 15 percent")
        return {
            forwardSpeedMS = forwardPeak,
            reverseSpeedMS = reversePeak,
            errorFraction = errorFraction,
        }
    end)
    scenario("left-steering-sign", false, function()
        local root, vehicle = fixture(nil, nil)
        runFor(root, vehicle, 1.5, stopped)
        local metrics = runFor(root, vehicle, 2.5, { throttle = 0.3, brake = 0, steering = 0.12 })
        metrics.forwardX = root.CFrame.LookVector.X
        assert(metrics.forwardX < -0.01, "Positive steering failed to turn left")
        return metrics
    end)
    scenario("airborne-no-contact-force", false, function()
        Workspace.Gravity = 0
        local root, vehicle = fixture(CFrame.new(0, Units.toStuds(10), 0), nil)
        local metrics = runFor(root, vehicle, 0.3, { throttle = 1, brake = 0, steering = 0 })
        assert(vehicle.supportedWheels == 0, "Airborne fixture found a contact")
        assert(
            root.AssemblyLinearVelocity.Magnitude < 1e-5,
            "Airborne tire accelerated the chassis"
        )
        return metrics
    end)
    scenario("invalid-dt-and-hitch-guard", false, function()
        local root, vehicle = fixture(nil, nil)
        local before = root.AssemblyLinearVelocity
        vehicle:step(0 / 0, stopped)
        vehicle:step(-1, stopped)
        vehicle:step(0.3, stopped)
        assert(vehicle.skippedSteps == 3, "Skipped-step telemetry is incorrect")
        assert(root.AssemblyLinearVelocity == before, "Rejected steps changed chassis velocity")
        return { skippedSteps = vehicle.skippedSteps }
    end)
    scenario("dynamic-ground-momentum", false, function()
        Workspace.Gravity = 0
        local platform = Instance.new("Part")
        platform.Name = "ApexDynamicGround"
        platform.Size = Vector3.new(40, 1, 40)
        platform.Position = Vector3.new(0, 10, 0)
        platform.CustomPhysicalProperties = PhysicalProperties.new(5, 0, 0)
        platform.Parent = Workspace
        platform:SetNetworkOwner(nil)
        table.insert(extraParts, platform)
        local custom = table.clone(Config)
        custom.airDensityKgM3 = 0
        local root, vehicle = fixture(CFrame.new(0, 10.5 + Units.toStuds(0.8), 0), custom)
        platform.AssemblyLinearVelocity = Vector3.new(3, 0, 0)
        local momentumBefore = root.AssemblyMass * root.AssemblyLinearVelocity.X
            + platform.AssemblyMass * platform.AssemblyLinearVelocity.X
        local metrics = runFor(root, vehicle, 0.25, stopped)
        local momentumAfter = root.AssemblyMass * root.AssemblyLinearVelocity.X
            + platform.AssemblyMass * platform.AssemblyLinearVelocity.X
        metrics.relativeMomentumError = math.abs(momentumAfter - momentumBefore)
            / math.abs(momentumBefore)
        assert(metrics.relativeMomentumError < 0.01, "Contact did not conserve horizontal momentum")
        return metrics
    end)
end

if suite == "Research" then
    scenario("eight-vehicle-cost-characterization", true, function()
        local fleet: { Vehicle.Vehicle } = {}
        for index = 1, 8 do
            local model, root = Factory.create(
                nil,
                CFrame.new(Units.toStuds(index * 8), Units.toStuds(1.1), 0),
                "ApexFleetFixture"
            )
            table.insert(extraParts, model)
            table.insert(fleet, Vehicle.new(root, Config, { model }))
        end
        local elapsed = 0
        local cpu: { number } = {}
        activeConnection = RunService.PreSimulation:Connect(function(dt)
            elapsed += dt
            local start = os.clock()
            for _, vehicle in fleet do
                vehicle:step(dt, stopped)
            end
            table.insert(cpu, (os.clock() - start) * 1000)
        end)
        while elapsed < 3 do
            task.wait(0.02)
        end
        if activeConnection then
            activeConnection:Disconnect()
            activeConnection = nil
        end
        table.sort(cpu)
        local skipped = 0
        for _, vehicle in fleet do
            skipped += vehicle.skippedSteps
        end
        return {
            vehicles = 8,
            durationS = elapsed,
            samples = #cpu,
            p50ScriptMs = cpu[math.max(1, math.ceil(#cpu * 0.5))],
            p95ScriptMs = cpu[math.max(1, math.ceil(#cpu * 0.95))],
            maximumScriptMs = cpu[#cpu],
            skippedSteps = skipped,
            performanceBudget = "not established; local Studio characterization only",
        }
    end)
    scenario("parking-slope-creep-target", true, function()
        local slope = Instance.new("Part")
        slope.Name = "ApexSlope"
        slope.Size = Vector3.new(100, 1, 100)
        slope.Anchored = true
        slope.CFrame = CFrame.new(0, 20, 0) * CFrame.Angles(math.atan(0.1), 0, 0)
        slope.Parent = Workspace
        table.insert(extraParts, slope)
        local root, vehicle =
            fixture(slope.CFrame * CFrame.new(0, 0.5 + Units.toStuds(1.1), 0), nil)
        runFor(root, vehicle, 3, stopped)
        local origin = root.Position
        local metrics = runFor(root, vehicle, 8, stopped)
        metrics.creepM = (root.Position - origin).Magnitude * Units.METERS_PER_STUD
        print("APEX_RESEARCH_METRIC=" .. HttpService:JSONEncode({
            name = "parking-slope-creep",
            creepM = metrics.creepM,
            durationS = 8,
            targetM = 0.01,
        }))
        metrics.targetPassed = metrics.creepM < 0.01
        metrics.targetM = 0.01
        return metrics
    end)
end

local requiredPassed, researchPassed = true, true
for _, result in results do
    if not result.passed then
        if result.research then
            researchPassed = false
        else
            requiredPassed = false
        end
    end
end
local report = {
    schemaVersion = 1,
    suite = suite,
    engineVersion = if typeof(args) == "table" then args.engineVersion else "unknown",
    engineVersionSource = "Studio executable file version",
    sourceFingerprint = BuildInfo.fingerprint,
    gravityStudsS2 = gravity,
    requiredPassed = requiredPassed,
    researchTargetsPassed = researchPassed,
    cases = results,
}
cleanup()
print("APEX_TEST_REPORT=" .. HttpService:JSONEncode(report))
if requiredPassed then
    print("APEX_TEST_REQUIRED_PASS")
end
StudioTestService:EndTest(report)
