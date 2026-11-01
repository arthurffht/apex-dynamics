--!strict
-- Studio CLI / command-bar entry point. It injects a probe only into the local test copy.
local StudioTestService = game:GetService("StudioTestService")
local probe = Instance.new("Script")
probe.Name = "ApexSmokeProbe"
probe.Source = [[
--!strict
local StudioTestService = game:GetService("StudioTestService")
local HttpService = game:GetService("HttpService")
local ok, result = pcall(function()
    local model = workspace:WaitForChild("ApexReferenceSedan", 15)
    assert(model, "Sandbox failed to spawn")
    local root = model:WaitForChild("Chassis") :: BasePart
    local ground = workspace:FindFirstChild("Ground") :: BasePart
    assert(ground and ground.Position.Y == -1, "Incorrect serialized ground translation")
    task.wait(6)
    local heightM = root.Position.Y * 0.28
    local speedMS = root.AssemblyLinearVelocity.Magnitude * 0.28
    local supported = model:GetAttribute("SupportedWheels")
    local steppingReadable, stepping = pcall(function()
        return workspace.PhysicsSteppingMethod.Name
    end)
    local sample = {
        heightM = heightM,
        speedMS = speedMS,
        supportedWheels = supported,
        upY = root.CFrame.UpVector.Y,
        massRMU = root.AssemblyMass,
        groundYStuds = ground.Position.Y,
        gravityStudsS2 = workspace.Gravity,
        physicsSteppingMethod = if steppingReadable then tostring(stepping) else "unavailable-to-probe",
        engineVersion = version(),
        observationDelayS = 6,
        expectedHeightM = 0.762739765625,
        heightToleranceM = 0.05,
        maximumSpeedMS = 0.1,
    }
    print("APEX_STATIC_SAMPLE=" .. HttpService:JSONEncode(sample))
    assert(supported == 4, "Expected four ray contacts")
    assert(math.abs(heightM - sample.expectedHeightM) < sample.heightToleranceM, "Unexpected equilibrium height")
    assert(speedMS < sample.maximumSpeedMS, "Static support did not settle")
    assert(sample.upY > 0.999, "Chassis is not upright")
    return sample
end)
local report = {success=ok, result=if ok then result else tostring(result)}
print("APEX_STUDIO_REPORT=" .. HttpService:JSONEncode(report))
if ok then
    print("APEX_STUDIO_SMOKE_PASS")
end
StudioTestService:EndTest(report)
]]
probe.Parent = game:GetService("ServerScriptService")
-- Allow edit-mode startup to become idle before entering the test mode.
task.wait(5)
local report = StudioTestService:ExecuteRunModeAsync({ name = "ApexStaticSupportSmoke" })
if report then
    assert(report.success, tostring(report.result))
else
    -- Some Studio builds return nil before the run-mode probe finishes. Keep the
    -- entry coroutine alive; the PowerShell wrapper still requires the probe's marker.
    task.wait(20)
end
