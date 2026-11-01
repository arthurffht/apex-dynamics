--!strict
-- Generated entry replaces the probe literal; the source suite remains a single file.
local StudioTestService = game:GetService("StudioTestService")
local sandbox = game:GetService("ServerScriptService"):FindFirstChild("ApexSandbox")
if sandbox and sandbox:IsA("Script") then
    sandbox.Enabled = false -- APEX_SANDBOX_ENABLED
end
local probe = Instance.new("Script")
probe.Name = "ApexRegressionProbe"
probe.Source = "" -- APEX_PROBE_SOURCE
probe.Parent = game:GetService("ServerScriptService")
-- APEX_CLIENT_SETUP
task.wait(5)
local testArgs = { suite = "Regression", engineVersion = "unknown" } -- APEX_ARGS
local report = StudioTestService:ExecuteRunModeAsync(testArgs) -- APEX_MODE
if report then
    print("APEX_TEST_REPORT=" .. game:GetService("HttpService"):JSONEncode(report))
    if report.requiredPassed then
        print("APEX_TEST_REQUIRED_PASS")
    end
    assert(report.requiredPassed, "Studio required regression failed")
else
    task.wait(50) -- APEX_KEEPALIVE
end
