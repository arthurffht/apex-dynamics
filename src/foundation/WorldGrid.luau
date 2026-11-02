--!strict
-- Logical coordinates in meters; never convert a global sector product to Vector3.
local Grid = {}
export type Cell = { x: number, z: number, key: string, variant: number }
local function integer(value: number, limit: number)
    assert(value == value and math.abs(value) <= limit and value % 1 == 0, "Invalid sector/index")
end
function Grid.normalize(sector: number, offsetM: number, tileSizeM: number): (number, number)
    integer(sector, 1e9)
    assert(tileSizeM > 0 and tileSizeM < math.huge, "Invalid tile size")
    assert(offsetM == offsetM and math.abs(offsetM) < math.huge, "Nonfinite offset")
    local shift = math.floor(offsetM / tileSizeM)
    local nextSector = sector + shift
    integer(nextSector, 1e9)
    return nextSector, offsetM - shift * tileSizeM
end
function Grid.relativeM(sector: number, originSector: number, tileSizeM: number): number
    integer(sector, 1e9)
    integer(originSector, 1e9)
    assert(tileSizeM > 0 and tileSizeM < math.huge, "Invalid tile size")
    local delta = sector - originSector
    assert(math.abs(delta) <= 16, "Only the bounded local window can enter engine coordinates")
    return delta * tileSizeM
end
function Grid.window(x: number, z: number, radius: number, budget: number, seed: number): { Cell }
    integer(x, 1e9 - 8)
    integer(z, 1e9 - 8)
    integer(radius, 8)
    integer(seed, 2147483647)
    assert(radius >= 0 and (2 * radius + 1) ^ 2 <= budget, "Tile budget exceeded")
    local cells: { Cell } = {}
    for dz = -radius, radius do
        for dx = -radius, radius do
            local cx, cz = x + dx, z + dz
            local variant = ((cx % 65521) * 48271 + (cz % 65521) * 69621 + seed) % 4
            table.insert(
                cells,
                { x = cx, z = cz, key = tostring(cx) .. ":" .. tostring(cz), variant = variant }
            )
        end
    end
    return cells
end
return table.freeze(Grid)
