--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local remote =
    ReplicatedStorage:WaitForChild("ApexDynamics"):WaitForChild("SandboxInput") :: RemoteEvent
local player = Players.LocalPlayer
local elapsed = 0

local function key(code: Enum.KeyCode): number
    return if UserInputService:IsKeyDown(code) then 1 else 0
end

RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if elapsed < 1 / 30 then
        return
    end
    elapsed = 0
    local character = player.Character
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    local seat = if humanoid then humanoid.SeatPart else nil
    if not seat or seat.Name ~= "DriverSeat" then
        return
    end
    local focused = UserInputService:GetFocusedTextBox() ~= nil
    remote:FireServer({
        throttle = if focused then 0 else key(Enum.KeyCode.W) - key(Enum.KeyCode.S),
        brake = if focused then 1 else key(Enum.KeyCode.Space),
        steering = if focused then 0 else key(Enum.KeyCode.A) - key(Enum.KeyCode.D),
    })
end)
