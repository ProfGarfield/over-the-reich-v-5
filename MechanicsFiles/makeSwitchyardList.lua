local discreteEvents = require("discreteEventsRegistrar")
local gen = require("generalLibrary")
local text = require("text")
local object =require("object")
local civlua = require("civlua")


-- pairing[gen.getTileID(city.location)] = transporter tile
local pairing = {}

local function weightFn(city,tile)
    if pairing[gen.getTileID(city.location)] then
        return false
    elseif not city:hasImprovement(object.iCityI) then
        return false
    else
        return gen.distance(city,tile)
    end
end

local function addToCityList(tile)
    if pairing[gen.getTileID(tile)] then
        local menuTable = {
            "Keep paring","unpair"}
        local choice = text.menu(menuTable,"","")
        if choice == 2 then
            pairing[gen.getTileID(tile)] = nil
        end
    end
    if not gen.hasTransporter(tile) then
        return
    end
    for key,val in pairs(pairing) do
        if val == tile then
            local c = gen.getTileFromID(key).city.name
            civ.ui.text("transporter associated with "..c)
            return
        end
    end
    local nearestCities, weights = gen.getSmallestWeights(civ.iterateCities(), weightFn,3,tile)
    local menuTable = {}
    for key,val in pairs(nearestCities) do
        menuTable[key] = val.name
    end
    local choice = text.menu(menuTable,"","",true)
    if choice == 0 then
        return
    end
    pairing[gen.getTileID(nearestCities[choice].location)] = tile
    civ.createUnit(civ.getUnitType(0),civ.getTribe(0),tile)
end

local function getCityLocationKey(city)
    local loc = city.location
    for key,val in pairs(object) do
        if val == loc then
            return key
        end
    end
end

local function printCityList()
    local output = "railyardPairs = {\n"
    for key,val in pairs(pairing) do
        output = output.."[gen.getTileID(object."..getCityLocationKey(gen.getTileFromID(key).city)..")] = civ.getTile("..text.coordinates(val).."),\n"
    end
    output =output.. "}"
    print(output)
    print(civlua.serialize(pairing))
end

local keyboard = require("keyboard")
function discreteEvents.onKeyPress(keyID)
    if keyID == keyboard.backspace then
        addToCityList(civ.getCurrentTile())
    end
    if keyID == keyboard.zero then
        printCityList()
    end
end


