--[[
    OTR Flak Mirror
    Guns live on the ground maps only:
        z=0  day ground    fires at z=0 and z=1
        z=2  night ground  fires at z=2 and z=3
    Each pair is one battery in two places: same type, owner, homeCity, HP.
    Separate unit ids => separate 3-shot magazines. That is the point.

    Canonical tile is always z=0. Regen and improvement bind stay on z=0.
    This file keeps the z=2 twin in lockstep.
]]

local object         = require("object")
local discreteEvents = require("discreteEventsRegistrar")
local gen            = require("generalLibrary")
local helper         = require("helper")

local flakMirror = {}

local mirroring = false

local function obj(key)
    local ok, val = pcall(function() return object[key] end)
    if ok then return val end
    return nil
end

local flakTypeIds = {}
local function remember(key)
    local u = obj(key)
    if u then flakTypeIds[u.id] = true end
end
remember("u2cmFlakvierling")
remember("u37cmFlak36")
remember("u88cmFlak18")
remember("u128cmFlak40")
remember("uFlakzug")
remember("uPolsten20mm")
remember("uBofors40mmUK")
remember("uBofors40mmUS")
remember("u37Flak")

local function isFlak(unit)
    return unit and flakTypeIds[unit.type.id] == true
end

local function twinZ(z)
    if z == 0 then return 2 end
    if z == 2 then return 0 end
    return nil
end

local function twinTile(tile)
    if not tile then return nil end
    local z = twinZ(tile.z)
    if not z then return nil end
    return civ.getTile(tile.x, tile.y, z)
end

local function flakOnTile(tile, unitType, tribe)
    if not tile then return nil end
    for unit in tile.units do
        if unit.type == unitType and (not tribe or unit.owner == tribe) then
            return unit
        end
    end
    return nil
end

function flakMirror.findTwin(unit)
    if not isFlak(unit) then return nil end
    local t = twinTile(unit.location)
    if not t then return nil end
    return flakOnTile(t, unit.type, unit.owner)
end

-- Create the missing half of a pair. Never called for z=1/3.
function flakMirror.ensureTwin(unit)
    if mirroring or not isFlak(unit) then return nil end
    local dest = twinTile(unit.location)
    if not dest then return nil end
    local existing = flakOnTile(dest, unit.type, unit.owner)
    if existing then
        existing.damage = math.max(existing.damage, unit.damage)
        unit.damage     = existing.damage
        if unit.homeCity and not existing.homeCity then
            existing.homeCity = unit.homeCity
        end
        return existing
    end
    mirroring = true
    local twin = civ.createUnit(unit.type, unit.owner, dest)
    if twin then
        twin.homeCity = unit.homeCity
        twin.veteran  = unit.veteran
        twin.damage   = unit.damage
        twin.moveSpent = 255
    end
    mirroring = false
    return twin
end

-- Copy HP. Day (z=0) is the heal source at turn boundary.
-- Combat mid-turn should call syncDamage(hitUnit) so the other half
-- picks up the wound before the next heal.
function flakMirror.syncDamage(unit)
    if not isFlak(unit) then return end
    local twin = flakMirror.findTwin(unit)
    if not twin then
        flakMirror.ensureTwin(unit)
        twin = flakMirror.findTwin(unit)
    end
    if not twin then return end
    local dmg = math.max(unit.damage, twin.damage)
    unit.damage = dmg
    twin.damage = dmg
end

function flakMirror.syncHealFromDay(unit)
    if not isFlak(unit) then return end
    local z = unit.location.z
    local day = (z == 0) and unit or ((z == 2) and flakMirror.findTwin(unit))
    local night = (z == 2) and unit or ((z == 0) and flakMirror.findTwin(unit))
    if day and night then
        night.damage = day.damage
    end
end

local function deleteTwinQuiet(unit)
    if mirroring or not isFlak(unit) then return end
    local twin = flakMirror.findTwin(unit)
    if not twin then return end
    mirroring = true
    civ.deleteUnit(twin)
    mirroring = false
end

discreteEvents.onScenarioLoaded(function()
    for unit in civ.iterateUnits() do
        if isFlak(unit) and (unit.location.z == 0 or unit.location.z == 2) then
            flakMirror.ensureTwin(unit)
        end
    end
end)

discreteEvents.onTribeTurnBegin(function(turn, tribe)
    for unit in civ.iterateUnits() do
        if isFlak(unit) and unit.owner == tribe then
            if unit.location.z == 0 or unit.location.z == 2 then
                flakMirror.ensureTwin(unit)
            end
        end
    end
end)

-- After production / engine heal on the z=0 city tile, push HP to night.
discreteEvents.onTribeTurnEnd(function(turn, tribe)
    for unit in civ.iterateUnits() do
        if isFlak(unit) and unit.owner == tribe and unit.location.z == 0 then
            flakMirror.syncHealFromDay(unit)
        end
    end
end)

discreteEvents.onUnitDefeated(function(loser, winner, aggressor, victim, loserLocation)
    if mirroring then return end
    if isFlak(loser) then
        deleteTwinQuiet(loser)
    end
end)

discreteEvents.onUnitDeleted(function(deletedUnit, replacingUnit)
    if mirroring then return end
    if replacingUnit then return end
    if isFlak(deletedUnit) then
        deleteTwinQuiet(deletedUnit)
    end
end)

-- Call from combatSettings after a fight if the defender (or attacker) is flak
-- and survived. Keeps the unwounded half from looking healthy.
function flakMirror.afterCombat(attacker, defender)
    if defender and isFlak(defender) then
        flakMirror.syncDamage(defender)
    end
    if attacker and isFlak(attacker) then
        flakMirror.syncDamage(attacker)
    end
end

flakMirror.isFlak   = isFlak
flakMirror.twinTile = twinTile

return flakMirror
