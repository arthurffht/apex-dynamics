--!strict
-- Inspect generated artifacts with Lune's Roblox serialization library; no engine execution.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local place = roblox.deserializePlace(fs.readFile("build/ApexDynamicsSandbox.rbxlx"))
local intended = serde.decode("json", fs.readFile(".local/generated/active.project.json"))
local xml = fs.readFile("build/ApexDynamicsSandbox.rbxlx")
for _, property in { "AuthorityMode", "PhysicsSteppingMethod", "UseFixedSimulation" } do
    local value = intended.tree.Workspace["$properties"][property].Enum
    assert(
        string.find(xml, string.format('<token name="%s">%d</token>', property, value), 1, true),
        "Engine property missing from serialized place: " .. property
    )
end
local workspace = place:GetService("Workspace")
assert(math.abs(workspace.Gravity - 35.02375) < 1e-4, "Incorrect sandbox gravity")
assert(workspace:FindFirstChild("Ground"), "Missing test surface")
local ground = workspace:FindFirstChild("Ground")
assert(ground and ground.CFrame.Position.Y == -1, "Ground translation was not serialized")
local packageRoot = place:GetService("ReplicatedStorage"):FindFirstChild("ApexDynamics")
assert(packageRoot and packageRoot:FindFirstChild("Core"), "Missing core package")
assert(packageRoot:FindFirstChild("Roblox"), "Missing engine adapter")
assert(
    place:GetService("ServerScriptService"):FindFirstChild("ApexSandbox"),
    "Missing sandbox script"
)
local modules = 0
for _, item in place:GetDescendants() do
    if item:IsA("ModuleScript") then
        modules += 1
        assert(string.find(item.Source, "--!strict", 1, true) == 1, "Module is not strict")
    end
end
assert(modules >= 12, "Missing runtime or development modules")
local config = packageRoot:FindFirstChild("Config")
assert(config and config:FindFirstChild("Runtime"), "Missing simulation-host configuration")
local library = roblox.deserializeModel(fs.readFile("build/ApexDynamics.rbxm"))
assert(#library == 1 and library[1].Name == "ApexDynamics", "Invalid library root")
print(
    string.format(
        "PASS build inspection: %d strict modules, sandbox tree, gravity, reusable library",
        modules
    )
)
