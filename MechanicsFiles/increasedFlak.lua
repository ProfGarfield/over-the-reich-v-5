-- MechanicsFiles/increasedFlak.lua
--
-- iIncreasedAirDefense (improvement 18) can be built in any city.
-- Completing it places ONE flak unit ON THE CITY TILE (no extra-tile bind):
--
--   Germans
--     real city     -> u88cmFlak18
--     airfield      -> u37cmFlak36
--
--   Allies
--     airfield in Britain zone -> uBofors40mmUK
--     airfield in any other zone -> uBofors40mmUS
--     real city: no unit (Allies have no 88mm equivalent)
--
-- Destroying that unit removes iIncreasedAirDefense from the bound city
-- so the player must rebuild the improvement to get the gun back.
-- Selling or losing the improvement deletes the gun.

local object         = require("object")
local helper         = require("helper")
local discreteEvents = require("discreteEventsRegistrar")

local increasedFlak = {}

local IMPROVEMENT = object.iIncreasedAirDefense

local TYPE_88     = object.u88cmFlak18
local TYPE_37     = object.u37cmFlak36
local TYPE_BOF_UK = object.uBofors40mmUK
local TYPE_BOF_US = object.uBofors40mmUS

local flakTypes = {
    [TYPE_88.id]     = true,
    [TYPE_37.id]     = true,
    [TYPE_BOF_UK.id] = true,
    [TYPE_BOF_US.id] = true,
}

local function isIncreasedFlak(unit)
    return unit and flakTypes[unit.type.id] == true
end

local function isAirfield(city)
    return city and helper.isOTRAirfield(city)
end

local function zoneName(city)
    if not city then
        return nil
    end
    return helper.airZoneFor(city.location.x, city.location.y)
end

local function flakTypeForCity(city)
    if not city then
        return nil
    end
    local owner = city.owner
    local air   = isAirfield(city)

    if owner == object.pGermans then
        if air then
            return TYPE_37
        end
        return TYPE_88
    end

    if owner == object.pAllies then
        if not air then
            return nil
        end
        if zoneName(city) == "Britain" then
            return TYPE_BOF_UK
        end
        return TYPE_BOF_US
    end

    return nil
end

local function tileHasType(tile, unitType, tribe)
    if not tile or not unitType then
        return false
    end
    for unit in tile.units do
        if unit.type == unitType and (not tribe or unit.owner == tribe) then
            return true
        end
    end
    return false
end

local function findFlakOnCity(city)
    if not city then
        return nil
    end
    local tile = city.location
    for unit in tile.units do
        if isIncreasedFlak(unit) and unit.owner == city.owner then
            return unit
        end
    end
    for unit in civ.iterateUnits() do
        if isIncreasedFlak(unit)
            and unit.homeCity == city
            and unit.owner == city.owner
        then
            return unit
        end
    end
    return nil
end

local function spawnFlak(city)
    if not city then
        return nil
    end
    if not city:hasImprovement(IMPROVEMENT) then
        return nil
    end
    local unitType = flakTypeForCity(city)
    if not unitType then
        return nil
    end
    local existing = findFlakOnCity(city)
    if existing then
        existing.homeCity = city
        local flakMirror = require("flakMirror")
        flakMirror.ensureTwin(existing)
        return existing
    end
    local tile = city.location
    if tileHasType(tile, unitType, city.owner) then
        return nil
    end
    local u = civ.createUnit(unitType, city.owner, tile)
    if u then
        u.homeCity = city
        u.veteran  = false
        local flakMirror = require("flakMirror")
        flakMirror.ensureTwin(u)
    end
    return u
end

local function cityOfFlak(unit, fallbackTile)
    if not unit then
        return nil
    end
    if unit.homeCity then
        return unit.homeCity
    end
    local tile = fallbackTile or unit.location
    if tile and tile.city then
        return tile.city
    end
    return nil
end

local function stripImprovement(city)
    if city and city:hasImprovement(IMPROVEMENT) then
        city:removeImprovement(IMPROVEMENT)
    end
end

function discreteEvents.onCityProduction(city, prod)
    if prod == IMPROVEMENT then
        spawnFlak(city)
    end
end

function discreteEvents.onUnitDefeated(loser, winner, aggressor, victim, loserLocation)
    if not isIncreasedFlak(loser) then
        return
    end
    stripImprovement(cityOfFlak(loser, loserLocation))
end

function discreteEvents.onUnitDeleted(deletedUnit, replacingUnit)
    if replacingUnit then
        return
    end
    if not isIncreasedFlak(deletedUnit) then
        return
    end
    stripImprovement(cityOfFlak(deletedUnit, deletedUnit.location))
end

local function reconcileCity(city)
    if not city then
        return
    end
    local hasImp = city:hasImprovement(IMPROVEMENT)
    local gun    = findFlakOnCity(city)
    if hasImp and not gun then
        spawnFlak(city)
    elseif gun and not hasImp then
        civ.deleteUnit(gun)
    elseif gun and gun.homeCity ~= city then
        gun.homeCity = city
    end
end

function discreteEvents.onTribeTurnBegin(turn, tribe)
    for city in civ.iterateCities() do
        if city.owner == tribe then
            reconcileCity(city)
        end
    end
end

function discreteEvents.onScenarioLoaded()
    for city in civ.iterateCities() do
        reconcileCity(city)
    end
end

increasedFlak.flakTypeForCity = flakTypeForCity
increasedFlak.spawnFlak       = spawnFlak
increasedFlak.reconcileCity   = reconcileCity

return increasedFlak