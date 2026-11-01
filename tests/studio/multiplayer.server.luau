--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StudioTestService = game:GetService("StudioTestService")
local HttpService = game:GetService("HttpService")
local Package = ReplicatedStorage:WaitForChild("ApexDynamics")
local Runtime = require(Package.Config.Runtime)
local BuildInfo = require(Package.Dev.BuildInfo)
local args = StudioTestService:GetTestArgs()
local cases: { { [string]: any } } = {}
local reports: { [number]: { simulationSteps: number, packets: number } } = {}
local reportRemote = Instance.new("RemoteEvent")
reportRemote.Name = "ApexClientProbeReport"
reportRemote.Parent = Package
reportRemote.OnServerEvent:Connect(function(player: Player, payload: any)
    if
        typeof(payload) == "table"
        and typeof(payload.simulationSteps) == "number"
        and typeof(payload.packets) == "number"
    then
        reports[player.UserId] =
            { simulationSteps = payload.simulationSteps, packets = payload.packets }
    end
end)
local function waitUntil(predicate: () -> boolean, timeout: number)
    local deadline = os.clock() + timeout
    repeat
        if predicate() then
            return
        end
        task.wait(0.1)
    until os.clock() > deadline
    error("Timed out waiting for multiplayer condition")
end
local function check(name: string, condition: boolean, metrics: { [string]: any }?)
    table.insert(cases, { name = name, passed = condition, research = false, metrics = metrics })
    assert(condition, name)
end
local ok, problem = pcall(function()
    waitUntil(function()
        return #Players:GetPlayers() >= 2
    end, 45)
    local players = Players:GetPlayers()
    local driver, attacker = players[1], players[2]
    driver:SetAttribute("ApexProbeRole", "Idle")
    attacker:SetAttribute("ApexProbeRole", "Attacker")
    local model = workspace:WaitForChild("ApexReferenceSedan")
    local root = model:WaitForChild("Chassis") :: BasePart
    local seat = model:WaitForChild("DriverSeat") :: VehicleSeat
    task.wait(2)
    check(
        "unauthorized-input-rejected",
        (model:GetAttribute("RejectedInputs") :: number) > 0,
        { rejected = model:GetAttribute("RejectedInputs") }
    )
    local character = driver.Character or driver.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    character:PivotTo(seat.CFrame * CFrame.new(0, 3, 0))
    seat:Sit(humanoid)
    driver:SetAttribute("ApexProbeRole", "Driver")
    waitUntil(function()
        return seat.Occupant == humanoid and (model:GetAttribute("AcceptedInputs") :: number) > 0
    end, 15)
    task.wait(0.5)
    local expectedOwner = if Runtime.simulationHost == "Client" then driver else nil
    check(
        "declared-network-owner",
        root:GetNetworkOwner() == expectedOwner,
        { mode = Runtime.simulationHost, ownerIsDriver = root:GetNetworkOwner() == driver }
    )
    local serverSteps = model:GetAttribute("ServerSimulationSteps") :: number
    task.wait(2)
    check(
        "authorized-driver-moves",
        root.AssemblyLinearVelocity.Magnitude * 0.28 > 0.2,
        { speedMS = root.AssemblyLinearVelocity.Magnitude * 0.28 }
    )
    local serverDelta = (model:GetAttribute("ServerSimulationSteps") :: number) - serverSteps
    check(
        "single-simulator-observed",
        if Runtime.simulationHost == "Client" then serverDelta == 0 else serverDelta > 0,
        { serverStepsDuringDriver = serverDelta }
    )
    waitUntil(function()
        return reports[driver.UserId] ~= nil and reports[attacker.UserId] ~= nil
    end, 10)
    local driverStats = reports[driver.UserId]
    check(
        "client-execution-policy",
        if Runtime.simulationHost == "Client"
            then driverStats.simulationSteps > 0
            else driverStats.simulationSteps == 0,
        {
            driverClientSteps = driverStats.simulationSteps,
            otherClientSteps = reports[attacker.UserId].simulationSteps,
        }
    )
    check("other-client-does-not-simulate", reports[attacker.UserId].simulationSteps == 0)
    driver:SetAttribute("ApexProbeRole", "Silent")
    task.wait(Runtime.inputTimeoutS + 1)
    check("stale-input-reclaims-server", root:GetNetworkOwner() == nil)
    task.wait(2)
    check(
        "stale-input-brakes",
        root.AssemblyLinearVelocity.Magnitude * 0.28 < 0.5,
        { residualSpeedMS = root.AssemblyLinearVelocity.Magnitude * 0.28 }
    )
end)
if not ok then
    table.insert(cases, {
        name = "multiplayer-completion",
        passed = false,
        research = false,
        error = tostring(problem),
    })
end
local report = {
    schemaVersion = 1,
    suite = "Multiplayer",
    simulationHost = Runtime.simulationHost,
    sourceFingerprint = BuildInfo.fingerprint,
    requiredPassed = ok,
    researchTargetsPassed = true,
    cases = cases,
    engineVersion = if typeof(args) == "table" then args.engineVersion else "unknown",
    engineVersionSource = "Studio executable file version",
}
print("APEX_TEST_REPORT=" .. HttpService:JSONEncode(report))
if ok then
    print("APEX_TEST_REQUIRED_PASS")
end
StudioTestService:EndTest(report)
