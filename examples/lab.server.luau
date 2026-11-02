--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packageRoot = ReplicatedStorage:WaitForChild("ApexDynamics")
local Config = require(packageRoot.Config.Laboratory)
if not RunService:IsStudio() or not Config.enabled then
    return
end
local Laboratory = require(packageRoot.Roblox.lab.Laboratory)
local BuildInfo = require(packageRoot.Dev.BuildInfo)
Laboratory.start(workspace:WaitForChild("ApexLab"), BuildInfo.fingerprint)
