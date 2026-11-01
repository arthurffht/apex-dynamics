--!strict
export type Command = { throttle: number, brake: number, steering: number }
local Input = {}

local function valid(value: unknown, minimum: number, maximum: number): boolean
    return typeof(value) == "number" and value == value and value >= minimum and value <= maximum
end

-- Accept a small exact schema; reject NaN, infinity and out-of-range values.
function Input.validate(payload: unknown): Command?
    if typeof(payload) ~= "table" then
        return nil
    end
    local raw = payload :: { [string]: unknown }
    for key in raw do
        if key ~= "throttle" and key ~= "brake" and key ~= "steering" then
            return nil
        end
    end
    if
        not valid(raw.throttle, -1, 1)
        or not valid(raw.brake, 0, 1)
        or not valid(raw.steering, -1, 1)
    then
        return nil
    end
    return {
        throttle = raw.throttle :: number,
        brake = raw.brake :: number,
        steering = raw.steering :: number,
    }
end

return table.freeze(Input)
