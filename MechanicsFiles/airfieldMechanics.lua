local discreteEvents = require("discreteEventsRegistrar")
local gen = require("generalLibrary")
local factoryAirfield = require("factoryAirfield")
local helper = require("helper")
local object = require("object")
local text = require("text")

function discreteEvents.onCityFounded(city) 
    local x,y,z = city.location.x,city.location.y,city.location.z
    local lowTile = civ.getTile(x,y,0)
    local highTile = civ.getTile(x,y,1)
    local nightTile = civ.getTile(x,y,2)
    local oldLow = lowTile.baseTerrain
    local oldHigh = highTile.baseTerrain
    local oldNight = nightTile.baseTerrain
    local activeCityTile = city.location
    local eventCityTile = nightTile
    if activeCityTile == nightTile then
        eventCityTile = lowTile
    end
    local eventCity = nil
    if not eventCityTile.city then
        eventCity = civ.createCity(city.owner,eventCityTile)
        if eventCityTile == nightTile then
            eventCity.name = city.name.." (N)"
        else
            eventCity.name = city.name
        end
    end
    if activeCityTile == nightTile then
        city.name = city.name.." (N)"
    end
    city:addImprovement(object.iAirbase)
    for _,radiusTile in pairs(gen.cityRadiusTiles(city)) do
        if factoryAirfield.needsAirfield(radiusTile) then
            factoryAirfield.linkFactoryToAirfield(radiusTile,city)
            break
        end
    end
    -- the cityCancelled() function is executed if the player
    -- decides not to found the city after all
    -- (so you can undo terrain changes, etc.
    local function cityCancelled()
        lowTile.baseTerrain = oldLow
        highTile.baseTerrain = oldHigh
        nightTile.baseTerrain = oldNight
        factoryAirfield.unlinkFactoryFromAirfield(city)
        if eventCity then
            factoryAirfield.unlinkFactoryFromAirfield(eventCity)
            civ.deleteCity(eventCity)
        end
    end
    return cityCancelled

end


function discreteEvents.onCanFoundCity(unit,advancedTribe)
    local airfieldForbiddenResult = helper.isAirfieldForbidden(unit.location)
    if airfieldForbiddenResult then
        if unit.owner == civ.getPlayerTribe() then
            text.simple(airfieldForbiddenResult,"War Ministry")
        end
        return false
    else
        return true
    end
end

-- prevent airfields from exceeding size 1
function discreteEvents.onTribeTurnBegin(turn,tribe)
    for city in civ.iterateCities() do
        if helper.isOTRAirfield(city) and city.owner == tribe then
            city.food = math.min(city.food,10)
        end
    end
end

return {}
