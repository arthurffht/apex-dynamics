--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Package = ReplicatedStorage:WaitForChild("ApexDynamics")
local ClientDriver = require(Package.Roblox.ClientDriver)
local input = Package:WaitForChild("SandboxInput") :: RemoteEvent
local report = Package:WaitForChild("ApexClientProbeReport") :: RemoteEvent
local player = Players.LocalPlayer
local handle: ClientDriver.Handle? = nil
local lastStats: ClientDriver.Stats = { simulationSteps = 0, packets = 0 }
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
    local role = player:GetAttribute("ApexProbeRole")
    if role == "Driver" and not handle then
        handle = ClientDriver.start(function()
            return { throttle = 0.35, brake = 0, steering = 0 }
        end)
    elseif role ~= "Driver" and handle then
        lastStats = handle.getStats()
        handle.stop()
        handle = nil
    end
    elapsed += dt
    if elapsed < 0.1 then
        return
    end
    elapsed = 0
    if role == "Attacker" then
        input:FireServer({ throttle = 1, brake = 0, steering = 1 })
    end
    local stats = if handle then handle.getStats() else lastStats
    report:FireServer({ simulationSteps = stats.simulationSteps, packets = stats.packets })
end)
