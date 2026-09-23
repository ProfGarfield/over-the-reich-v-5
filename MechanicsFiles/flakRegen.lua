-- MechanicsFiles/flakRegen.lua
-- Light pad flak destroyed on an airfield respawns after a delay
-- shortened by living uArmamentsFactory in that air zone.
-- German pad gun:  u2cmFlakvierling
-- Allied pad gun:  uPolsten20mm

local object         = require("object")
local helper         = require("helper")
local param          = require("parameters")
local gen            = require("generalLibrary")
local discreteEvents = require("discreteEventsRegistrar")
local delay          = require("delayedAction")

local flakRegen = {}

local function isPadFlak(unit)
    if not unit then
        return false
    end
    local t = unit.type
    return t == object.u2cmFlakvierling or t == object.uPolsten20mm
end

local function zoneOfTile(tile)
    if not tile then
        return nil
    end
    return helper.airZoneFor(tile.x, tile.y)
end

local function armamentsInZone(tribe, zoneName)
    if not zoneName then
        return 0
    end
    local n = 0
    for unit in civ.iterateUnits() do
        if unit.type == object.uArmamentsFactory
            and unit.owner == tribe
            and zoneOfTile(unit.location) == zoneName then
            n = n + 1
        end
    end
    return n
end

local function flakDelayTurns(tribe, zoneName)
    local base = param.flakRegenBaseTurns or 4
    local per  = param.flakRegenPerArmament or 1
    local minT = param.flakRegenMinTurns or 1
    local t = base - per * armamentsInZone(tribe, zoneName)
    if t < minT then t = minT end
    return t
end

local function tileHasFlak(tile, tribe, unitType)
    if not tile then
        return false
    end
    for unit in tile.units do
        if unit.type == unitType and unit.owner == tribe then
            return true
        end
    end
    return false
end

local function respawnFlak(args)
    local tile = gen.getTileFromId(args.tileId)
    local tribe = civ.getTribe(args.tribeId)
    local unitType = civ.getUnitType(args.unitTypeId)
    if not tile or not tribe or not unitType then
        return
    end
    if tileHasFlak(tile, tribe, unitType) then
        return
    end
    local city = tile.city
    if not (city and helper.isOTRAirfield(city)) then
        return
    end
    local u = civ.createUnit(unitType, tribe, tile)
    if u then
        u.homeCity = city
        u.veteran = false
        local flakMirror = require("flakMirror")
        flakMirror.ensureTwin(u)
    end
end

delay.makeFunctionDelayable("flakRegen_respawn", respawnFlak)

local function scheduleFlak(loser, loserLocation)
    if not isPadFlak(loser) then
        return
    end
    local tile = loserLocation or loser.location
    if not tile then
        return
    end
    local city = tile.city
    if not (city and helper.isOTRAirfield(city)) then
        return
    end
    local tribe = loser.owner
    local wait = flakDelayTurns(tribe, zoneOfTile(tile))
    delay.doInFuture("flakRegen_respawn", {
        tileId     = gen.getTileId(tile),
        tribeId    = tribe.id,
        unitTypeId = loser.type.id,
    }, civ.getTurn() + wait, tribe.id)
end

function discreteEvents.onUnitDefeated(loser, winner, aggressor, victim, loserLocation)
    scheduleFlak(loser, loserLocation)
end

function discreteEvents.onUnitDeleted(deletedUnit, replacingUnit)
    if not replacingUnit then
        scheduleFlak(deletedUnit, deletedUnit.location)
    end
end

flakRegen.flakDelayTurns  = flakDelayTurns
flakRegen.armamentsInZone = armamentsInZone

return flakRegen