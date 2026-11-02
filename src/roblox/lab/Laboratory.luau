--!strict
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LabConfig = require(script.Parent.Parent.Parent.Config.Laboratory)
local Units = require(script.Parent.Parent.Parent.Core.Units)
local Diagnostics = require(script.Parent.Parent.Parent.Foundation.Diagnostics)
local TileWorld = require(script.Parent.TileWorld)
local Checks = require(script.Parent.Checks)
local Laboratory = {}
export type Handle = { run: () -> (), stop: () -> (), events: () -> { Diagnostics.Event } }
function Laboratory.start(root: Instance, fingerprint: string): Handle
    assert(RunService:IsStudio(), "The laboratory is restricted to Studio")
    assert(not root:FindFirstChild("Runtime"), "Stop the existing laboratory before restarting")
    local owned = Instance.new("Folder")
    owned.Name = "Runtime"
    owned.Parent = root
    local reportValue = Instance.new("StringValue")
    reportValue.Name = "LastReport"
    reportValue.Parent = owned
    local world = TileWorld.new(
        owned,
        LabConfig.world.tileSizeM,
        LabConfig.world.radius,
        LabConfig.world.maxTiles,
        LabConfig.seed,
        Vector3.new(
            Units.toStuds(LabConfig.world.originXM),
            0,
            Units.toStuds(LabConfig.world.originZM)
        )
    )
    world.update(0, 0)
    local events = Diagnostics.new(LabConfig.eventCapacity)
    local running, stopped, runId = false, false, 0
    local connections: { RBXScriptConnection } = {}
    root:SetAttribute("SourceFingerprint", fingerprint)
    root:SetAttribute("LabSchemaVersion", LabConfig.schemaVersion)
    root:SetAttribute("Phase", "Foundation")
    root:SetAttribute("State", "Idle")
    root:SetAttribute("SectorX", 0)
    root:SetAttribute("SectorZ", 0)
    root:SetAttribute("ActiveTiles", world.stats().alive)
    root:SetAttribute("RunRequested", false)
    root:SetAttribute("PassedCases", 0)
    root:SetAttribute("FailedCases", 0)
    local function event(level: string, code: string, fields: Diagnostics.Fields)
        Diagnostics.append(events, os.clock(), level, code, fields)
        root:SetAttribute("EventCount", events.nextSequence - 1)
        root:SetAttribute("DroppedEvents", events.dropped)
    end
    local function run()
        if stopped or running then
            return
        end
        running = true
        runId += 1
        root:SetAttribute("State", "Running")
        root:SetAttribute("RunId", runId)
        local started = os.clock()
        local passed, failed = 0, 0
        local cases: { { [string]: any } } = {}
        event("info", "suite.started", { runId = runId })
        for _, case in Checks.cases() do
            local caseStart = os.clock()
            local ok, problem = xpcall(function()
                case.run({ root = root, world = world, fingerprint = fingerprint })
            end, debug.traceback)
            local durationS = os.clock() - caseStart
            if durationS > LabConfig.caseBudgetS then
                ok, problem = false, "Case exceeded its elapsed-time budget"
            end
            if ok then
                passed += 1
            else
                failed += 1
            end
            table.insert(cases, {
                id = case.id,
                name = case.id,
                passed = ok,
                durationS = durationS,
                error = if ok then nil else string.sub(tostring(problem), 1, 8192),
            })
            event(if ok then "info" else "error", case.id, { passed = ok, durationS = durationS })
        end
        local report = {
            schemaVersion = 1,
            suite = "Foundation",
            runId = runId,
            seed = LabConfig.seed,
            sourceFingerprint = fingerprint,
            requiredPassed = failed == 0,
            researchTargetsPassed = true,
            durationS = os.clock() - started,
            cases = cases,
            scope = "Laboratory infrastructure; no vehicle fidelity claim",
        }
        reportValue.Value = HttpService:JSONEncode(report)
        root:SetAttribute("PassedCases", passed)
        root:SetAttribute("FailedCases", failed)
        root:SetAttribute("LastDurationS", report.durationS)
        root:SetAttribute("State", if failed == 0 then "Passed" else "Failed")
        event(
            if failed == 0 then "info" else "error",
            "suite.completed",
            { passed = passed, failed = failed }
        )
        print("APEX_LAB_REPORT=" .. reportValue.Value)
        running = false
    end
    table.insert(
        connections,
        root:GetAttributeChangedSignal("RunRequested"):Connect(function()
            if root:GetAttribute("RunRequested") == true then
                root:SetAttribute("RunRequested", false)
                task.defer(run)
            end
        end)
    )
    local elapsed = 0
    table.insert(
        connections,
        RunService.Heartbeat:Connect(function(dt)
            elapsed += dt
            if elapsed < LabConfig.updateIntervalS or running then
                return
            end
            elapsed = 0
            local x, z = root:GetAttribute("SectorX"), root:GetAttribute("SectorZ")
            local ok, result = pcall(function()
                assert(
                    type(x) == "number" and type(z) == "number",
                    "Sectors must be numeric integers"
                )
                return world.update(x, z)
            end)
            if ok then
                root:SetAttribute("ActiveTiles", result.alive)
            else
                local previous = world.stats()
                root:SetAttribute("SectorX", previous.sectorX)
                root:SetAttribute("SectorZ", previous.sectorZ)
                event("warn", "world.invalid-request", {})
            end
        end)
    )
    local function stop()
        if stopped then
            return
        end
        stopped = true
        for _, connection in connections do
            connection:Disconnect()
        end
        world.destroy()
        owned:Destroy()
        root:SetAttribute("State", "Stopped")
    end
    if LabConfig.autoRun then
        task.defer(run)
    end
    return {
        run = run,
        stop = stop,
        events = function()
            return Diagnostics.snapshot(events)
        end,
    }
end
return table.freeze(Laboratory)
