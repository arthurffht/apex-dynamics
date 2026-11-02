--!strict
local Grid = require("../src/foundation/WorldGrid")
local Diagnostics = require("../src/foundation/Diagnostics")
local count = 0
local function check(condition: boolean, message: string)
    count += 1
    assert(condition, message)
end
local function rejects(action: () -> ())
    local ok = pcall(action)
    check(not ok, "Invalid request was accepted")
end
for sector = -100, 100 do
    for _, offset in { -150, -100, -1, 0, 1, 99, 100, 250 } do
        local normalized, remainder = Grid.normalize(sector, offset, 100)
        check(remainder >= 0 and remainder < 100, "Offset escaped local cell")
        check(
            normalized * 100 + remainder == sector * 100 + offset,
            "Coordinate normalization changed position"
        )
    end
end
local plan = Grid.window(100000000, -100000000, 2, 25, 20261101)
local again = Grid.window(100000000, -100000000, 2, 25, 20261101)
local unique: { [string]: boolean } = {}
check(#plan == 25, "Incorrect window cardinality")
for i, cell in plan do
    check(not unique[cell.key], "Duplicate sector")
    unique[cell.key] = true
    check(cell.variant == again[i].variant and cell.key == again[i].key, "Seeded plan changed")
    check(
        math.abs(Grid.relativeM(cell.x, 100000000, 71.68)) <= 143.36,
        "Large world leaked absolute coordinates"
    )
end
for _, bad in { 0 / 0, math.huge, 1.5, 1e12 } do
    rejects(function()
        Grid.window(bad, 0, 2, 25, 1)
    end)
end
rejects(function()
    Grid.window(0, 0, 3, 25, 1)
end)
rejects(function()
    Grid.normalize(0, math.huge, 100)
end)
rejects(function()
    Grid.relativeM(100, 0, 100)
end)
local buffer = Diagnostics.new(3)
local source: Diagnostics.Fields = { value = 1 }
Diagnostics.append(buffer, 0, "info", "started", source)
source.value = 2
check(Diagnostics.snapshot(buffer)[1].fields.value == 1, "Caller mutated an event")
for i = 2, 1000 do
    Diagnostics.append(buffer, i, "info", "sample", { value = i })
end
local snapshot = Diagnostics.snapshot(buffer)
check(
    #snapshot == 3 and #buffer.events == 3 and buffer.dropped == 997,
    "Diagnostic memory grew beyond budget"
)
check(snapshot[1].sequence == 998 and snapshot[3].sequence == 1000, "Ring lost sequence order")
rejects(function()
    Diagnostics.append(buffer, 1, "info", "invalid", { value = 0 / 0 })
end)
rejects(function()
    Diagnostics.append(buffer, 1, "info", "invalid", { value = math.huge })
end)
rejects(function()
    Diagnostics.append(buffer, 1, "debug", "invalid", {})
end)
rejects(function()
    Diagnostics.new(0)
end)
check(Diagnostics.snapshot(buffer)[3].sequence == 1000, "Rejected event altered history")
print(
    string.format(
        "PASS foundation: %d assertions; bounded world plans and diagnostic history",
        count
    )
)
