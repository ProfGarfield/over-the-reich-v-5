-- MechanicsFiles/engineHeal.lua
-- Pad heal = healBase + healPerEngineFactory * living
-- uEngineFactory in the SAME helper.airZone as the pad.
-- Capped at healMax.

local object         = require("object")
local helper         = require("helper")
local param          = require("parameters")
local discreteEvents = require("discreteEventsRegistrar")

local engineHeal = {}

local function isAircraft(unit)
    return unit and unit.type and unit.type.domain == 1
end

local function onPad(unit)
    local city = unit.location and unit.location.city
    return city and helper.isOTRAirfield(city)
end

local function zoneOf(unit)
    local tile = unit.location
    if not tile then
        return nil
    end
    return helper.airZoneFor(tile.x, tile.y)
end

local function livingEnginesInZone(tribe, zoneName)
    if not zoneName then
        return 0
    end
    local n = 0
    for unit in civ.iterateUnits() do
        if unit.type == object.uEngineFactory
            and unit.owner == tribe
            and zoneOf(unit) == zoneName then
            n = n + 1
        end
    end
    return n
end

local function healAmount(tribe, zoneName)
    local base = param.healBase or 1
    local per  = param.healPerEngineFactory or 1
    local cap  = param.healMax or 4
    local amt = base + per * livingEnginesInZone(tribe, zoneName)
    if amt > cap then amt = cap end
    return amt
end

function discreteEvents.onTribeTurnBegin(turn, tribe)
    for unit in civ.iterateUnits() do
        if unit.owner == tribe and isAircraft(unit) and onPad(unit) then
            local amount = healAmount(tribe, zoneOf(unit))
            local dmg = unit.damage or 0
            if amount > 0 and dmg > 0 then
                local nxt = dmg - amount
                if nxt < 0 then nxt = 0 end
                unit.damage = nxt
            end
        end
    end
end

engineHeal.livingEnginesInZone = livingEnginesInZone
engineHeal.healAmount          = healAmount

return engineHeal