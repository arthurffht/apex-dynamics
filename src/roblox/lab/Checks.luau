--!strict
local Workspace = game:GetService("Workspace")
local Units = require(script.Parent.Parent.Parent.Core.Units)
local TileWorld = require(script.Parent.TileWorld)
local Checks = {}
export type Context = { root: Instance, world: TileWorld.Handle, fingerprint: string }
export type Case = { id: string, run: (Context) -> () }
local function fixture(action: (Folder) -> ())
    local folder = Instance.new("Folder")
    folder.Name = "ApexFoundationFixture"
    folder.Parent = Workspace
    local ok, problem = pcall(function()
        action(folder)
        return ""
    end)
    folder:Destroy()
    assert(ok, tostring(problem))
end
function Checks.cases(): { Case }
    return {
        {
            id = "foundation.identity",
            run = function(context)
                assert(
                    context.root:GetAttribute("SourceFingerprint") == context.fingerprint,
                    "Runtime identity mismatch"
                )
                assert(context.root:GetAttribute("LabSchemaVersion") == 1, "Unsupported lab schema")
            end,
        },
        {
            id = "foundation.gravity",
            run = function()
                assert(
                    math.abs(Workspace.Gravity - Units.STANDARD_GRAVITY / Units.METERS_PER_STUD)
                        < 1e-4,
                    "Gravity mismatch"
                )
            end,
        },
        {
            id = "foundation.safe-default",
            run = function()
                assert(
                    not Workspace:FindFirstChild("ApexReferenceSedan"),
                    "Reference vehicle must be opt-in"
                )
            end,
        },
        {
            id = "foundation.fixture-map",
            run = function(context)
                local stations = context.root:FindFirstChild("Stations")
                assert(stations, "Missing laboratory stations")
                for _, name in { "Flat", "Grade10", "Curbs", "SplitSurface" } do
                    assert(stations:FindFirstChild(name), "Missing station: " .. name)
                end
            end,
        },
        {
            id = "foundation.world-budget",
            run = function(context)
                assert(context.world.stats().alive == 25, "World window is incomplete")
            end,
        },
        {
            id = "foundation.world-idempotency",
            run = function(context)
                local before = context.world.stats()
                local after = context.world.update(before.sectorX, before.sectorZ)
                assert(
                    after.created == before.created and after.retired == before.retired,
                    "Unchanged window allocated instances"
                )
            end,
        },
        {
            id = "foundation.world-lifecycle",
            run = function()
                fixture(function(folder)
                    local world =
                        TileWorld.new(folder, 71.68, 2, 25, 20261101, Vector3.new(0, 1000, 0))
                    world.update(0, 0)
                    local moved = world.update(100000000, -100000000)
                    assert(
                        moved.alive == 25 and moved.created == 50 and moved.retired == 25,
                        "Distant sector leaked tiles"
                    )
                    local cells = folder:FindFirstChild("WorldCells")
                    assert(cells, "World cells were not created")
                    for _, tile in cells:GetChildren() do
                        assert(
                            (tile :: BasePart).Position.Magnitude < 1500,
                            "Global coordinates leaked into engine positions"
                        )
                    end
                    world.destroy()
                    world.destroy()
                    assert(
                        world.stats().alive == 0 and #folder:GetChildren() == 0,
                        "World cleanup leaked instances"
                    )
                end)
            end,
        },
        {
            id = "foundation.query-contracts",
            run = function()
                fixture(function(folder)
                    local surface = Instance.new("Part")
                    surface.Anchored = true
                    surface.Size = Vector3.new(20, 2, 20)
                    surface.CFrame = CFrame.new(0, 1000, 0)
                    surface.Parent = folder
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Include
                    params.FilterDescendantsInstances = { folder }
                    local ray =
                        Workspace:Raycast(Vector3.new(0, 1010, 0), Vector3.new(0, -20, 0), params)
                    local sphere = Workspace:Spherecast(
                        Vector3.new(0, 1010, 0),
                        1,
                        Vector3.new(0, -20, 0),
                        params
                    )
                    assert(
                        ray and sphere and ray.Instance == surface and sphere.Instance == surface,
                        "Query missed isolated fixture"
                    )
                    assert(
                        math.abs(ray.Distance - 9) < 1e-3 and math.abs(sphere.Distance - 8) < 1e-3,
                        "Ray/shape travel semantics changed"
                    )
                end)
            end,
        },
    }
end
return table.freeze(Checks)
