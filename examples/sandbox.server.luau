--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local packageRoot = ReplicatedStorage:WaitForChild("ApexDynamics")
local Laboratory = require(packageRoot.Config.Laboratory)
if
    not Laboratory.referenceVehicleEnabled
    and workspace:GetAttribute("ApexReferenceEnabled") ~= true
then
    return
end
local Units = require(packageRoot.Core.Units)
local Input = require(packageRoot.Core.Input)
local Config = require(packageRoot.Presets.ReferenceSedan)
local Runtime = require(packageRoot.Config.Runtime)
local Vehicle = require(packageRoot.Roblox.Vehicle)
local Factory = require(packageRoot.Roblox.VehicleFactory)
local DriverSession = require(packageRoot.Roblox.DriverSession)
local BuildInfo = require(packageRoot.Dev.BuildInfo)

local remote = Instance.new("RemoteEvent")
remote.Name = "SandboxInput"
remote.Parent = packageRoot
local model, chassis, seat = Factory.create()
model:SetAttribute("SourceFingerprint", BuildInfo.fingerprint)
model:SetAttribute("SimulationHost", Runtime.simulationHost)
model:SetAttribute("DriverUserId", 0)
model:SetAttribute("SimulationEpoch", 0)
local vehicle = Vehicle.new(chassis, Config, { model })
local command: Input.Command = { throttle = 0, brake = 1, steering = 0 }
local lastInputTime = 0
local driver: Player? = nil
local nextPacketTime: { [Player]: number } = {}
local telemetryElapsed = 0
local serverSteps, rejectedInputs, acceptedInputs = 0, 0, 0

local function transfer(player: Player?)
    chassis:SetNetworkOwner(nil)
    local forwardSpeed = chassis.AssemblyLinearVelocity:Dot(chassis.CFrame.LookVector)
        * Units.METERS_PER_STUD
    for _, wheel in vehicle.wheels do
        wheel.omega = forwardSpeed / Config.wheelRadiusM
    end
    vehicle.steering = 0
    model:SetAttribute("InitialWheelOmega", forwardSpeed / Config.wheelRadiusM)
    model:SetAttribute("DriverUserId", if player then player.UserId else 0)
    model:SetAttribute("SimulationEpoch", (model:GetAttribute("SimulationEpoch") :: number) + 1)
    if Runtime.simulationHost == "Client" and player then
        chassis:SetNetworkOwner(player)
    end
end

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
    local occupant = seat.Occupant
    driver = if occupant then Players:GetPlayerFromCharacter(occupant.Parent) else nil
    command = { throttle = 0, brake = 1, steering = 0 }
    lastInputTime = os.clock()
    transfer(driver)
end)

remote.OnServerEvent:Connect(function(player: Player, payload: unknown)
    if player ~= driver then
        rejectedInputs += 1
        return
    end
    local now = os.clock()
    if now < (nextPacketTime[player] or 0) then
        return
    end
    nextPacketTime[player] = now + 1 / Runtime.maximumInputHz
    local validated = Input.validate(payload)
    if validated then
        acceptedInputs += 1
        command = validated
        lastInputTime = now
        if
            Runtime.simulationHost == "Client"
            and model:GetAttribute("DriverUserId") ~= player.UserId
        then
            transfer(player)
        end
    else
        rejectedInputs += 1
    end
end)

Players.PlayerRemoving:Connect(function(player)
    nextPacketTime[player] = nil
    if player == driver then
        driver = nil
        command = { throttle = 0, brake = 1, steering = 0 }
        transfer(nil)
    end
end)

RunService.PreSimulation:Connect(function(dt)
    if os.clock() - lastInputTime > Runtime.inputTimeoutS or not driver then
        command = { throttle = 0, brake = 1, steering = 0 }
        if Runtime.simulationHost == "Client" and model:GetAttribute("DriverUserId") ~= 0 then
            transfer(nil)
        end
    end
    local driverId = model:GetAttribute("DriverUserId") :: number
    if DriverSession.shouldSimulate(Runtime.simulationHost, true, 0, driverId) then
        vehicle:step(dt, command)
        serverSteps += 1
    end
    telemetryElapsed += dt
    if telemetryElapsed >= 1 / Runtime.telemetryHz then
        telemetryElapsed = 0
        model:SetAttribute(
            "SpeedMS",
            chassis.AssemblyLinearVelocity.Magnitude * Units.METERS_PER_STUD
        )
        model:SetAttribute("SupportedWheels", vehicle.supportedWheels)
        model:SetAttribute("SkippedSteps", vehicle.skippedSteps)
        model:SetAttribute("ServerSimulationSteps", serverSteps)
        model:SetAttribute("RejectedInputs", rejectedInputs)
        model:SetAttribute("AcceptedInputs", acceptedInputs)
    end
end)

print(
    "Apex Dynamics sandbox ready. Simulation host:",
    Runtime.simulationHost,
    "Source:",
    BuildInfo.fingerprint
)
