--!strict
local HttpService = game:GetService("HttpService")
local auditSource = "" -- APEX_AUDIT_SOURCE
local cases: { { [string]: any } } = {}
local function inspect()
    local probe = Instance.new("ModuleScript")
    probe.Name = "ApexAuditFixture"
    probe.Source = auditSource
    probe.Parent = game:GetService("ServerScriptService")
    local evaluate = require :: (ModuleScript) -> any
    local result = evaluate(probe)
    probe:Destroy()
    return result
end
local function check(name: string, condition: boolean)
    table.insert(cases, { name = name, passed = condition, research = false })
    assert(condition, name)
end
local ok, problem = pcall(function()
    local initial = inspect()
    check("fresh-source-matches", initial.success and initial.checked > 0)
    local package = game:GetService("ReplicatedStorage"):FindFirstChild("ApexDynamics")
    assert(package, "Managed Apex Dynamics package is missing")
    local target = package.Core.Units :: ModuleScript
    local original = target.Source
    target.Source = original .. "\n-- isolated drift fixture\n"
    local drift = inspect()
    target.Source = original
    check("changed-source-is-detected", not drift.success)
    check("restored-source-matches", inspect().success)
    local extra = Instance.new("ModuleScript")
    extra.Name = "UnexpectedAuditFixture"
    extra.Source = "return {}"
    extra.Parent = package.Core
    local unexpected = inspect()
    extra:Destroy()
    check("unexpected-managed-script-is-detected", not unexpected.success)
    local runtime = Instance.new("Model")
    runtime.Name = "ApexReferenceSedan"
    runtime.Parent = workspace
    local unstamped = inspect()
    check("unstamped-runtime-is-not-verified", unstamped.success and not unstamped.runtimeFresh)
    runtime:SetAttribute("SourceFingerprint", "deliberately-stale")
    local stale = inspect()
    runtime:Destroy()
    check("cached-runtime-is-distinct-from-source", stale.success and not stale.runtimeFresh)
    local lab = workspace:FindFirstChild("ApexLab")
    assert(lab, "Laboratory scene is missing")
    local originalFingerprint = lab:GetAttribute("SourceFingerprint")
    local labRuntime = Instance.new("Folder")
    labRuntime.Name = "Runtime"
    labRuntime.Parent = lab
    local unstampedLab = inspect()
    check(
        "unstamped-laboratory-is-not-verified",
        unstampedLab.success and not unstampedLab.runtimeFresh
    )
    lab:SetAttribute("SourceFingerprint", "deliberately-stale")
    local staleLab = inspect()
    labRuntime:Destroy()
    lab:SetAttribute("SourceFingerprint", originalFingerprint)
    check(
        "cached-laboratory-is-distinct-from-source",
        staleLab.success and not staleLab.runtimeFresh
    )
    check("audit-restores-clean-state", inspect().success)
end)
if not ok then
    table.insert(
        cases,
        { name = "audit-completion", passed = false, research = false, error = tostring(problem) }
    )
end
local report = {
    schemaVersion = 1,
    suite = "Audit",
    requiredPassed = ok,
    researchTargetsPassed = true,
    cases = cases,
}
print("APEX_TEST_REPORT=" .. HttpService:JSONEncode(report))
if ok then
    print("APEX_TEST_REQUIRED_PASS")
end
