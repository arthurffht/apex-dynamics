--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Package = ReplicatedStorage:WaitForChild("ApexDynamics")
local Laboratory = require(Package.Config.Laboratory)
if
    not Laboratory.referenceVehicleEnabled
    and workspace:GetAttribute("ApexReferenceEnabled") ~= true
then
    return
end
local ClientDriver = require(Package.Roblox.ClientDriver)
local function key(code: Enum.KeyCode): number
    return if UserInputService:IsKeyDown(code) then 1 else 0
end
ClientDriver.start(function()
    local focused = UserInputService:GetFocusedTextBox() ~= nil
    return {
        throttle = if focused then 0 else key(Enum.KeyCode.W) - key(Enum.KeyCode.S),
        brake = if focused then 1 else key(Enum.KeyCode.Space),
        steering = if focused then 0 else key(Enum.KeyCode.A) - key(Enum.KeyCode.D),
    }
end)
