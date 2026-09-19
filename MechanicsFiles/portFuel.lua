local object         = require("object")
local param          = require("parameters")
local discreteEvents = require("discreteEventsRegistrar")

local function pInterval() return param.portFuelTrainInterval or 4 end
local function pCount()    return param.portFuelTrainCount    or 1 end

local function spawnAtCity(city, count)
    if count < 1 then return end
    for i = 1, count do
        local u = civ.createUnit(object.uFuelTrain, city.owner, city.location)
        if u then u.homeCity = city end
    end
end

discreteEvents.onTurn(function(turn)
    if not turn or turn < 1 then return end
    local every = pInterval()
    if every < 1 or (turn % every ~= 0) then return end
    for city in civ.iterateCities() do
        if city:hasImprovement(object.iPortFacility) then
            spawnAtCity(city, pCount())
        end
    end
end)

if rawget(_G, "console") then
    function console.portFuelNow()
        for city in civ.iterateCities() do
            if city:hasImprovement(object.iPortFacility) then
                spawnAtCity(city, pCount())
                print("port train @", city.name)
            end
        end
    end
end

return {}