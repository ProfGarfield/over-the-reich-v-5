
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
    return city:hasImprovement(object.iCity)
end

local cityList = {}
local cityIndex = 1
local airfieldList = {}
local airfieldIndex = 1
-- list all cities and airfields
for city in civ.iterateCities() do
    if helper.isOTRCity(city) then
        cityList[cityIndex] = city
        cityIndex = cityIndex + 1
    end
    if helper.isOTRAirfield(city) then
        airfieldList[airfieldIndex] = city
        airfieldIndex = airfieldIndex + 1
    end
end

-- iterate over OTR Cities
function helper.OTRCityIterator()
    return coroutine.wrap(function()
        for _,city in pairs(cityList) do
            coroutine.yield(city)
        end
    end)
end
    
-- iterate over OTR Airfields
function helper.OTRAirfieldIterator()
    return coroutine.wrap(function()
        for _,city in pairs(airfieldList) do
            coroutine.yield(city)
        end
    end)
end

-- returns true if a tile would be within a city
-- radius of the other tile, and false otherwise
function helper.isWithinCityRadius(tile, otherTile)
    local dist = gen.tileDist(tile, otherTile)
    if dist <= 1 then
        return true
    elseif dist >= 3 then
        return false
    elseif math.abs(tile.x - otherTile.x) == 4 or
            math.abs(tile.y - otherTile.y) == 4 then
        return false
    else
        return true
    end
end
    


return helper