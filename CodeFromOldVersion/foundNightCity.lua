
local discreteEvents = require("discreteEventsRegistrar")

---@type cityObject|nil
local mostRecentCityFounded = nil

discreteEvents.onCityFounded(function (city)
    mostRecentCityFounded = city
    return function() mostRecentCityFounded = nil end
end)

local function foundNightCity(dayCity)
    local nightTile = civ.getTile(dayCity.location.x,dayCity.location.y,2) --[[@as tileObject]]
    if nightTile.city then
        return
    end
    local nightCity = civ.createCity(dayCity.owner,nightTile)
    nightCity.name = dayCity.name.." (N)"
end

discreteEvents.onActivateUnit(function(unit)
    if mostRecentCityFounded then
        foundNightCity(mostRecentCityFounded)
        mostRecentCityFounded = nil
    end
end)

discreteEvents.onKeyPress(function(keyID)
    if mostRecentCityFounded then
        foundNightCity(mostRecentCityFounded)
        mostRecentCityFounded = nil
    end
end)
