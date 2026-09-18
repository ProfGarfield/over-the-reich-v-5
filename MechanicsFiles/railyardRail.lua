local object         = require("object")
local gen            = require("generalLibrary")
local discreteEvents = require("discreteEventsRegistrar")

local targetBind = nil
local okBind, bindOrErr = pcall(require, "targetBind")
if okBind then targetBind = bindOrErr end

local function bindTilesForCity(city)
    local out = {}
    if not targetBind or not city then return out end
    for _, row in ipairs(targetBind) do
        if row.impId == object.iRailyards.id and row.cityId == city.id then
            out[#out + 1] = row
        end
    end
    return out
end

local function stripRR(x, y)
    local t0 = civ.getTile(x, y, 0)
    local t2 = civ.getTile(x, y, 2)
    if t0 then gen.removeTransportation(t0) end
    if t2 then gen.removeTransportation(t2) end
end

local function placeRR(x, y)
    local t0 = civ.getTile(x, y, 0)
    local t2 = civ.getTile(x, y, 2)
    if t0 then gen.placeRailroad(t0) end
    if t2 then gen.placeRailroad(t2) end
end

discreteEvents.onUnitKilled(function(loser, winner)
    if not loser or loser.type ~= object.uRailyards then return end
    stripRR(loser.location.x, loser.location.y)
    for _, row in ipairs(bindTilesForCity(loser.homeCity)) do
        stripRR(row.x, row.y)
    end
end)

discreteEvents.onCityProduction(function(city, item)
    if item ~= object.iRailyards then return end
    local rows = bindTilesForCity(city)
    if #rows == 0 then
        if city and city.location then
            placeRR(city.location.x, city.location.y)
        end
        return
    end
    for _, row in ipairs(rows) do
        placeRR(row.x, row.y)
    end
end)

if rawget(_G, "console") then
    function console.stripRailyardHere()
        local t = civ.getCurrentTile()
        stripRR(t.x, t.y)
        print("stripped RR at", t.x, t.y)
    end
    function console.placeRailyardHere()
        local t = civ.getCurrentTile()
        placeRR(t.x, t.y)
        print("placed RR at", t.x, t.y)
    end
end

return {}