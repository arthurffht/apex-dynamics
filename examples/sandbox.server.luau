--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local packageRoot = ReplicatedStorage:WaitForChild("ApexDynamics")
local Units = require(packageRoot.Core.Units)
local Input = require(packageRoot.Core.Input)
local Config = require(packageRoot.Presets.ReferenceSedan)
local Vehicle = require(packageRoot.Roblox.Vehicle)

local remote = Instance.new("RemoteEvent")
remote.Name = "SandboxInput"
remote.Parent = packageRoot

local model = Instance.new("Model")
model.Name = "ApexReferenceSedan"
model.Parent = Workspace

local chassis = Instance.new("Part")
chassis.Name = "Chassis"
chassis.Size = Vector3.new(Units.toStuds(1.7), Units.toStuds(0.45), Units.toStuds(4.1))
chassis.CFrame = CFrame.new(0, Units.toStuds(1.1), 0)
chassis.Color = Color3.fromRGB(30, 95, 130)
local volume = chassis.Size.X * chassis.Size.Y * chassis.Size.Z
local density = Units.toRobloxMass(Config.massKg) / volume
chassis.CustomPhysicalProperties = PhysicalProperties.new(density, 0, 0, 100, 100)
chassis.EnableFluidForces = false
chassis.Parent = model
model.PrimaryPart = chassis

local seat = Instance.new("VehicleSeat")
seat.Name = "DriverSeat"
seat.Size = Vector3.new(2, 1, 2)
seat.CFrame = chassis.CFrame * CFrame.new(0, 1.2, 0)
seat.Massless = true
seat.CanCollide = false
seat.HeadsUpDisplay = false
seat.MaxSpeed = 0
seat.Torque = 0
seat.Parent = model
local seatWeld = Instance.new("WeldConstraint")
seatWeld.Part0 = chassis
seatWeld.Part1 = seat
seatWeld.Parent = seat

for _, z in { -0.5, 0.5 } do
    for _, x in { -0.5, 0.5 } do
        local wheel = Instance.new("Part")
        wheel.Name = "WheelVisual"
        wheel.Shape = Enum.PartType.Cylinder
        local diameter = Units.toStuds(Config.wheelRadiusM * 2)
        wheel.Size = Vector3.new(0.7, diameter, diameter)
        wheel.CFrame = chassis.CFrame
            * CFrame.new(
                Units.toStuds(Config.trackM * x),
                -Units.toStuds(0.44),
                Units.toStuds(Config.wheelbaseM * z)
            )
        wheel.Color = Color3.fromRGB(25, 25, 28)
        wheel.Massless = true
        wheel.CanCollide = false
        wheel.CanQuery = false
        wheel.Parent = model
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = chassis
        weld.Part1 = wheel
        weld.Parent = wheel
    end
end
chassis:SetNetworkOwner(nil)
local vehicle = Vehicle.new(chassis, Config, { model })
local command: Input.Command = { throttle = 0, brake = 1, steering = 0 }
local lastInputTime = 0
local driver: Player? = nil
local nextPacketTime: { [Player]: number } = {}

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
    local occupant = seat.Occupant
    driver = if occupant then Players:GetPlayerFromCharacter(occupant.Parent) else nil
    command = { throttle = 0, brake = 1, steering = 0 }
    lastInputTime = 0
    -- Seating joins the character to the vehicle assembly; retain server ownership.
    chassis:SetNetworkOwner(nil)
end)

remote.OnServerEvent:Connect(function(player: Player, payload: unknown)
    if player ~= driver then
        return
    end
    local now = os.clock()
    if now < (nextPacketTime[player] or 0) then
        return
    end
    nextPacketTime[player] = now + 1 / 40
    local validated = Input.validate(payload)
    if validated then
        command = validated
        lastInputTime = now
    end
end)

Players.PlayerRemoving:Connect(function(player)
    nextPacketTime[player] = nil
end)

RunService.PreSimulation:Connect(function(dt)
    if os.clock() - lastInputTime > 0.5 or not driver then
        command = { throttle = 0, brake = 1, steering = 0 }
    end
    vehicle:step(dt, command)
    model:SetAttribute("SpeedMS", chassis.AssemblyLinearVelocity.Magnitude * Units.METERS_PER_STUD)
    model:SetAttribute("SupportedWheels", vehicle.supportedWheels)
end)

print("Apex Dynamics research sandbox ready. Sit in the driver seat; use W/S, A/D, Space.")
