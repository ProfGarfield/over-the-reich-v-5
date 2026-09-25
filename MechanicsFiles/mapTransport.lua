local object = require("object")
local discreteEvents = require("discreteEventsRegistrar")

-- Bit of the matching @MAP_TRANSPORT_RELATIONSHIPS row.
-- Row 0 (0,1 day)  = 1
-- Row 1 (2,3 night) = 2
local DAY   = 1
local NIGHT = 2

local native = {
    { object.uJu88C6, NIGHT },
    -- { object.uBf110G4, NIGHT },
}

local function apply()
    for i = 1, #native do
        local ut, bits = native[i][1], native[i][2]
        if ut then
            ut.nativeTransport = bits
        end
    end
end

discreteEvents.onScenarioLoaded(apply)
apply()

return { apply = apply, DAY = DAY, NIGHT = NIGHT }