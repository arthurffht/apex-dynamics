--!strict
-- Ordinary ownership, not Roblox's rollback Server Authority feature.
local DriverSession = {}

function DriverSession.shouldSimulate(
    host: string,
    isServer: boolean,
    localUserId: number,
    driverUserId: number
): boolean
    if host ~= "Server" and host ~= "Client" then
        return false
    end
    if host == "Server" or driverUserId == 0 then
        return isServer
    end
    return not isServer and driverUserId == localUserId
end

return table.freeze(DriverSession)
