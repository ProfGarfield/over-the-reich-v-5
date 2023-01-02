-- This file contains 'helper functions' which are specific
-- to Over the Reich, but not to any particular module.
--

local object = require("object")
local traits = require("traits")
local gen = require("generalLibrary")
local helper = {}

-- returns true if the city has the airbase improvement,
-- false otherwise
function helper.isOTRAirfield(city)
    return city:hasImprovement(object.iAirbase)
end

-- returns true if the city has the city I improvement
-- false otherwise
function helper.isOTRCity(city)
    return city:hasImprovement(object.iCityI)
end

-- returns true if a tile is within the radius of an OTRCity,
-- and false otherwise
-- if city is specified, returns true only if the tile is within
-- the radius of a different city
function helper.inOTRCityRadius(queryTile,city)
    for _,tile in pairs(gen.cityRadiusTiles(queryTile)) do
        if tile.city and tile.city ~= city and helper.isOTRCity(tile.city) then
            return true
        end
    end
    return false
end

-- returns true if the query tile has an adjacent tile which
-- has the given base terrain, and false otherwise
-- does not check the queryTile itself
function helper.adjacentBaseTerrain(queryTile,baseTerrainObject)
    for _,tile in pairs(gen.getTilesInRadius(queryTile,1,1,nil)) do
        if queryTile.baseTerrain == baseTerrainObject then
            return true
        end
    end
    return false
end

-- if an airfield can not be built on the tile,
-- return an explanatory message
-- if an airfield can be built on the tile, return false
function helper.isAirfieldForbidden(tile)
    if tile.z > 0 then
        return "Airfields may only be built on the Low Altitude Daylight Map."
    end
    if not traits.hasTrait(tile.baseTerrain,"canBuildAirfield") then
        return "Airfields can not be built on "..tile.baseTerrain.name.." tiles."
    end
    for _,adjacentTile in pairs(gen.getTilesInRadius(tile,1)) do
        if gen.hasTransporter(adjacentTile) then
            return "Airfields can not be built next to Railyards."
        end
    end
    for _,radiusTile in pairs(gen.cityRadiusTiles(tile)) do
        if radiusTile.city and helper.isOTRCity(radiusTile.city) then
            return "Airfields can not be built within a city's radius."
        end
    end
    return false
end



return helper
