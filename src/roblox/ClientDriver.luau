--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Package = script.Parent.Parent
local Input = require(Package.Core.Input)
local Vehicle = require(Package.Roblox.Vehicle)
local DriverSession = require(Package.Roblox.DriverSession)
local Config = require(Package.Presets.ReferenceSedan)
local ClientDriver = {}
export type Stats = { simulationSteps: number, packets: number }
export type Handle = { stop: () -> (), getStats: () -> Stats }

function ClientDriver.start(readInput: () -> Input.Command): Handle
    local remote = Package:WaitForChild("SandboxInput") :: RemoteEvent
    local player = Players.LocalPlayer
    local elapsed = 0
    local controller: Vehicle.Vehicle? = nil
    local controllerEpoch = -1
    local simulationSteps, packets = 0, 0
    local heartbeat = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 1 / 30 then
            return
        end
        elapsed = 0
        local character = player.Character
        local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
        local seat = if humanoid then humanoid.SeatPart else nil
        if seat and seat.Name == "DriverSeat" then
            remote:FireServer(readInput())
            packets += 1
        end
    end)
    local simulation = RunService.PreSimulation:Connect(function(dt)
        local model = Workspace:FindFirstChild("ApexReferenceSedan")
        if not model then
            controller = nil
            return
        end
        local host = model:GetAttribute("SimulationHost")
        local driverId = model:GetAttribute("DriverUserId")
        if
            typeof(host) ~= "string"
            or typeof(driverId) ~= "number"
            or not DriverSession.shouldSimulate(host, false, player.UserId, driverId)
        then
            controller = nil
            controllerEpoch = -1
            return
        end
        local epoch = model:GetAttribute("SimulationEpoch") :: number
        local root = model:FindFirstChild("Chassis")
        if not root or not root:IsA("BasePart") then
            return
        end
        local active = controller
        if not active or epoch ~= controllerEpoch then
            local nextController: Vehicle.Vehicle = Vehicle.new(root, Config, { model })
            local initialOmega = model:GetAttribute("InitialWheelOmega")
            for _, wheel in nextController.wheels do
                wheel.omega = if typeof(initialOmega) == "number" then initialOmega else 0
            end
            active = nextController
            controllerEpoch = epoch
        end
        controller = active
        if active then
            active:step(dt, readInput())
            simulationSteps += 1
        end
    end)
    return {
        stop = function()
            heartbeat:Disconnect()
            simulation:Disconnect()
            controller = nil
        end,
        getStats = function()
            return { simulationSteps = simulationSteps, packets = packets }
        end,
    }
end

return table.freeze(ClientDriver)
