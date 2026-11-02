--!strict
-- Bounded development events. No disk, network, player identifiers, or frame logging.
local Diagnostics = {}
export type Fields = { [string]: string | number | boolean }
export type Event = {
    sequence: number,
    timeS: number,
    level: "info" | "warn" | "error",
    code: string,
    fields: Fields,
}
export type Buffer = { capacity: number, nextSequence: number, dropped: number, events: { Event } }
function Diagnostics.new(capacity: number): Buffer
    assert(capacity % 1 == 0 and capacity >= 1 and capacity <= 4096, "Invalid event capacity")
    return { capacity = capacity, nextSequence = 1, dropped = 0, events = {} }
end
function Diagnostics.append(
    buffer: Buffer,
    timeS: number,
    level: string,
    code: string,
    fields: Fields
): Event
    assert(timeS == timeS and timeS >= 0 and timeS < math.huge, "Invalid event time")
    assert(level == "info" or level == "warn" or level == "error", "Invalid severity")
    assert(#code > 0 and #code <= 64, "Invalid event code")
    local copy: Fields = {}
    local count = 0
    for key, value in fields do
        count += 1
        assert(count <= 16 and #key <= 64, "Event fields exceed budget")
        if type(value) == "number" then
            assert(value == value and math.abs(value) < math.huge, "Nonfinite diagnostic")
        elseif type(value) == "string" then
            assert(#value <= 256, "Event string exceeds budget")
        end
        copy[key] = value
    end
    local sequence = buffer.nextSequence
    local event: Event = table.freeze({
        sequence = sequence,
        timeS = timeS,
        level = level,
        code = code,
        fields = table.freeze(copy),
    })
    buffer.events[(sequence - 1) % buffer.capacity + 1] = event
    buffer.nextSequence += 1
    buffer.dropped = math.max(0, sequence - buffer.capacity)
    return event
end
function Diagnostics.snapshot(buffer: Buffer): { Event }
    local result: { Event } = {}
    for sequence = math.max(1, buffer.nextSequence - buffer.capacity), buffer.nextSequence - 1 do
        table.insert(result, buffer.events[(sequence - 1) % buffer.capacity + 1])
    end
    return result
end
return table.freeze(Diagnostics)
