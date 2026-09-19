-- MechanicsFiles/aircraftFactory.lua
-- Aircraft factory down: city cannot queue or finish aircraft
-- until iAircraftFactory exists again.
--
-- canBuildSettings already requires iAircraftFactory on every
-- domain-1 unit. This file does the other half: if the factory
-- target dies while the city is mid-build on an aircraft,
-- force production onto iNothing (accumulate / Never).

local object         = require("object")
local helper         = require("helper")
local gen            = require("generalLibrary")
local text           = require("text")
local discreteEvents = require("discreteEventsRegistrar")
local strat          = require("strategicTargets")

local aircraftFactory = {}

local function isAircraftItem(item)
    return item and civ.isUnitType(item) and item.domain == 1
end

local function cityHasFactory(city)
    return city and city:hasImprovement(object.iAircraftFactory)
end

local function kickToAccumulate(city, reason)
    if not city then
        return false
    end
    local prod = city.currentProduction
    if not isAircraftItem(prod) then
        return false
    end
    local wasName = prod.name
    city.currentProduction = object.iAccumulateResources
    if civ.getCurrentTribe() == city.owner or city.owner.isHuman then
        text.simple(
            city.name.." cannot complete "..wasName
                .." — the aircraft factory is gone. Production set to accumulate.",
          
            "Factory Destroyed"
        )
    end
    return true
end

local function cityForFactoryTile(tile)
    if not tile then
        return nil
    end
    if strat and strat.iterateTargets then
        for target in strat.iterateTargets(object.uAircraftFactory) do
            local tTile = target.targetLocation
            if tTile and tTile.x == tile.x and tTile.y == tile.y and tTile.z == tile.z then
                if target.city then
                    return target.city
                end
            end
        end
        for target in strat.iterateTargets(object.iAircraftFactory) do
            local tTile = target.targetLocation
            if tTile and tTile.x == tile.x and tTile.y == tile.y and tTile.z == tile.z then
                if target.city then
                    return target.city
                end
            end
        end
    end
    if tile.city and helper.isOTRCity(tile.city) then
        return tile.city
    end
    for city in civ.iterateCities() do
        if helper.isOTRCity(city) and helper.isWithinCityRadius(tile, city.location) then
            return city
        end
    end
    return nil
end

local function onFactoryLost(unitOrTile, reason)
    local tile = nil
    if unitOrTile and unitOrTile.location then
        tile = unitOrTile.location
    elseif unitOrTile and unitOrTile.x then
        tile = unitOrTile
    end
    local city = cityForFactoryTile(tile)
    if city then
        kickToAccumulate(city, reason)
    end
end

function discreteEvents.onUnitDefeated(loser, winner, aggressor, victim, loserLocation)
    if loser and loser.type == object.uAircraftFactory then
        onFactoryLost(loserLocation or loser, "combat")
    end
end

function discreteEvents.onUnitKilled(loser, winner, aggressor, victim, loserLocation)
    if loser and loser.type == object.uAircraftFactory then
        onFactoryLost(loserLocation or loser, "killed")
    end
end

function discreteEvents.onUnitDeleted(deletedUnit, replacingUnit)
    if deletedUnit and deletedUnit.type == object.uAircraftFactory and not replacingUnit then
        onFactoryLost(deletedUnit.location, "deleted")
    end
end

function discreteEvents.onTribeTurnBegin(turn, tribe)
    for city in civ.iterateCities() do
        if city.owner == tribe and helper.isOTRCity(city) and not cityHasFactory(city) then
            kickToAccumulate(city, nil)
        end
    end
end

function discreteEvents.onCityProcessingComplete(turn, tribe)
    for city in civ.iterateCities() do
        if city.owner == tribe and helper.isOTRCity(city) and not cityHasFactory(city) then
            kickToAccumulate(city, nil)
        end
    end
end

aircraftFactory.cityHasFactory   = cityHasFactory
aircraftFactory.isAircraftItem   = isAircraftItem
aircraftFactory.kickToAccumulate = kickToAccumulate

return aircraftFactory