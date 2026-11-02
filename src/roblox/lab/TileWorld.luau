--!strict
local Units = require(script.Parent.Parent.Parent.Core.Units)
local Grid = require(script.Parent.Parent.Parent.Foundation.WorldGrid)
local TileWorld = {}
export type Stats = {
    alive: number,
    created: number,
    retired: number,
    sectorX: number,
    sectorZ: number,
}
export type Handle = { update: (number, number) -> Stats, stats: () -> Stats, destroy: () -> () }
function TileWorld.new(
    parent: Instance,
    tileSizeM: number,
    radius: number,
    budget: number,
    seed: number,
    origin: Vector3
): Handle
    assert(
        not parent:FindFirstChild("WorldCells"),
        "An existing world must be stopped before replacement"
    )
    local folder = Instance.new("Folder")
    folder.Name = "WorldCells"
    folder:SetAttribute("ApexOwned", true)
    folder.Parent = parent
    local tiles: { [string]: BasePart } = {}
    local created, retired, sectorX, sectorZ = 0, 0, 0, 0
    local stopped = false
    local function stats(): Stats
        local alive = 0
        for _ in tiles do
            alive += 1
        end
        return {
            alive = alive,
            created = created,
            retired = retired,
            sectorX = sectorX,
            sectorZ = sectorZ,
        }
    end
    local function update(x: number, z: number): Stats
        assert(not stopped, "World has been destroyed")
        local plan = Grid.window(x, z, radius, budget, seed)
        local wanted: { [string]: boolean } = {}
        for _, cell in plan do
            wanted[cell.key] = true
        end
        for key, part in tiles do
            if not wanted[key] then
                part:Destroy()
                tiles[key] = nil
                retired += 1
            end
        end
        for _, cell in plan do
            local tile = tiles[cell.key]
            if not tile then
                local part = Instance.new("Part")
                part.Name = cell.key
                part.Anchored = true
                part.Size = Vector3.new(Units.toStuds(tileSizeM), 2, Units.toStuds(tileSizeM))
                part.Material = Enum.Material.Asphalt
                part.Color = Color3.fromRGB(
                    48 + cell.variant * 5,
                    56 + cell.variant * 5,
                    66 + cell.variant * 5
                )
                part:SetAttribute("SectorX", cell.x)
                part:SetAttribute("SectorZ", cell.z)
                part:SetAttribute("Variant", cell.variant)
                part.Parent = folder
                tiles[cell.key] = part
                tile = part
                created += 1
            end
            tile.CFrame = CFrame.new(
                origin
                    + Vector3.new(
                        Units.toStuds(Grid.relativeM(cell.x, x, tileSizeM)),
                        -1,
                        Units.toStuds(Grid.relativeM(cell.z, z, tileSizeM))
                    )
            )
        end
        sectorX, sectorZ = x, z
        return stats()
    end
    local function destroy()
        if stopped then
            return
        end
        stopped = true
        for _, part in tiles do
            part:Destroy()
            retired += 1
        end
        table.clear(tiles)
        folder:Destroy()
    end
    return { update = update, stats = stats, destroy = destroy }
end
return table.freeze(TileWorld)
