--!strict
-- CLI bridge: use the same checks as the interactive laboratory.
local HttpService = game:GetService("HttpService")
local StudioTestService = game:GetService("StudioTestService")
local root = workspace:WaitForChild("ApexLab", 10)
assert(root, "Laboratory did not initialize")
local runtime = root:WaitForChild("Runtime", 10)
assert(runtime, "Laboratory runtime did not initialize")
local reportValue = runtime:WaitForChild("LastReport", 10) :: StringValue?
assert(reportValue, "Laboratory report channel did not initialize")
local deadline = os.clock() + 15
while reportValue.Value == "" and os.clock() < deadline do
    task.wait(0.1)
end
assert(reportValue.Value ~= "", "Laboratory did not complete before timeout")
local report = HttpService:JSONDecode(reportValue.Value)
print("APEX_TEST_REPORT=" .. reportValue.Value)
if report.requiredPassed then
    print("APEX_TEST_REQUIRED_PASS")
end
StudioTestService:EndTest(report)
