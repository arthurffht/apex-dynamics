--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
    return
end
local root = workspace:WaitForChild("ApexLab")
local gui = Instance.new("ScreenGui")
gui.Name = "ApexLaboratoryHUD"
gui.ResetOnSpawn = false
local text = Instance.new("TextLabel")
text.Name = "Status"
text.Position = UDim2.fromOffset(16, 60)
text.Size = UDim2.fromOffset(460, 160)
text.BackgroundColor3 = Color3.fromRGB(20, 25, 34)
text.BackgroundTransparency = 0.1
text.BorderSizePixel = 0
text.TextColor3 = Color3.fromRGB(218, 232, 245)
text.TextSize = 16
text.Font = Enum.Font.Code
text.TextXAlignment = Enum.TextXAlignment.Left
text.TextYAlignment = Enum.TextYAlignment.Top
text.Parent = gui
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local elapsed = 0
local connection: RBXScriptConnection
connection = RunService.Heartbeat:Connect(function(dt)
    if not gui.Parent then
        connection:Disconnect()
        return
    end
    elapsed += dt
    if elapsed < 0.2 then
        return
    end
    elapsed = 0
    text.Text = string.format(
        " APEX DYNAMICS | FOUNDATION LAB\n State: %s | Run: %s\n Checks: %s passed / %s failed\n World: %s cells | Sector: %s, %s\n Source: %s\n Vehicle development is opt-in.",
        tostring(root:GetAttribute("State") or "Starting"),
        tostring(root:GetAttribute("RunId") or 0),
        tostring(root:GetAttribute("PassedCases") or 0),
        tostring(root:GetAttribute("FailedCases") or 0),
        tostring(root:GetAttribute("ActiveTiles") or 0),
        tostring(root:GetAttribute("SectorX") or 0),
        tostring(root:GetAttribute("SectorZ") or 0),
        string.sub(tostring(root:GetAttribute("SourceFingerprint") or "unknown"), 1, 16)
    )
end)
