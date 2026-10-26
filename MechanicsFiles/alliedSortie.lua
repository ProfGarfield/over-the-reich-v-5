--[[
    MechanicsFiles/alliedSortie.lua

    Allied computer-player sortie helper.

    1. raids[]  -- outbound packages (escorts + bombers). Empty for now.
    2. Return-to-base for AI Allied bombers whose homeCity is NONE.

    RTB rules
      - Allies only, and only while that tribe is not human.
      - Air domain, bomber (not fighter / jabo / recon), homeCity == nil.
      - Stay on the HIGH map for the whole transit
            day  -> z=1
            night -> z=3
      - Pick a random Allied city that still has support room (units
        homed there < city.size) and some shield production.
        Prefer a city within 20 tiles so they can actually arrive.
        Night bombers prefer airfields; fall back to any Allied city.
      - Destination is sticky per unit.id until the city is lost or full.
      - When the bomber is on the city column (same x,y, wrong z),
        teleport to z=0 (day) or z=2 (night), assign homeCity, spend MP.

    events.lua:
      attemptToRun('alliedSortie',"WARNING: alliedSortie.lua not found.")
]]

local object         = require("object")
local helper         = require("helper")
local gen            = require("generalLibrary")
local discreteEvents = require("discreteEventsRegistrar")
local traits         = require("traits")

local alliedSortie = {}

------------------------------------------------------------------------
-- 1. Raid catalogue (outbound). Filled later.
--    Each entry is a named package the AI can roll.
------------------------------------------------------------------------

alliedSortie.raids = {
    -- example shape, not live:
    -- {
    --     name     = "8th AF Schweinfurt",
    --     day      = true,
    --     bombers  = { { type = object.uB17FFortress, count = 6 } },
    --     escorts  = { { type = object.uP47D15Thunderbolt, count = 4 } },
    --     targetHint = "SWGermany",
    -- },
}

------------------------------------------------------------------------
-- Parameters
------------------------------------------------------------------------

local PREFER_RANGE = 20
local DAY_HIGH     = 1
local DAY_LOW      = 0
local NIGHT_HIGH   = 3
local NIGHT_LOW    = 2

-- Set true to RTB even when you are playing the Allies.
-- Turn it back to false for real play.
local TEST_AS_HUMAN = false

local destByUnit = rawget(_G, "_alliedSortieDest")
if not destByUnit then
    destByUnit = {}
    rawset(_G, "_alliedSortieDest", destByUnit)
end

------------------------------------------------------------------------
-- Tribe / role
------------------------------------------------------------------------

local function alliesTribe()
    return object.pAllies
end

local function alliesAreAi()
    local t = alliesTribe()
    if not t then return false end
    if TEST_AS_HUMAN then return true end
    return not t.isHuman
end

local function obj(key)
    local ok, val = pcall(function() return object[key] end)
    if ok then return val end
    return nil
end

local function hasTrait(unitType, name)
    local ok, result = pcall(traits.hasTrait, unitType, name)
    return ok and result
end

local function isBomber(unit)
    if not unit or not unit.type or unit.type.domain ~= 1 then
        return false
    end
    local ut = unit.type
    if hasTrait(ut, "heavyBomber") or hasTrait(ut, "mediumBomber")
        or hasTrait(ut, "lightBomber") or hasTrait(ut, "bomber") then
        return true
    end
    if hasTrait(ut, "fighter") or hasTrait(ut, "jabo")
        or hasTrait(ut, "airSuperiority") then
        return false
    end
    -- name fallback so a new airframe still RTBs
    local n = ut.name or ""
    if n:find("[Ff]ortress") or n:find("[Ll]iberator") or n:find("[Ll]ancaster")
        or n:find("[Hh]alifax") or n:find("[Ss]tirling") or n:find("[Ww]ellington")
        or n:find("[Mm]itchell") or n:find("[Mm]arauder") or n:find("[Hh]avoc")
        or n:find("[Ii]nvader") or n:find("[Bb]oston") or n:find("[Bb]altimore")
        or n:find("B%-17") or n:find("B%-24") or n:find("B%-25") or n:find("B%-26") then
        return true
    end
    return false
end

local function isNightBomber(unit)
    if not unit then return false end
    local z = unit.location and unit.location.z
    if z == 2 or z == 3 then return true end
    local ut = unit.type
    if hasTrait(ut, "nightBomber") or hasTrait(ut, "night") then return true end
    local n = (ut and ut.name) or ""
    if n:find("[Ll]ancaster") or n:find("[Hh]alifax") or n:find("[Ss]tirling")
        or n:find("[Ww]ellington") or n:find("[Pp]athfinder") then
        -- these also fly day in some packages; z is the real signal
        return z == 2 or z == 3
    end
    return false
end

local function needsRtb(unit)
    if not alliesAreAi() then return false end
    if not unit or unit.owner ~= alliesTribe() then return false end
    if unit.homeCity then return false end
    if not isBomber(unit) then return false end
    return true
end

------------------------------------------------------------------------
-- Support room
------------------------------------------------------------------------

local function homedCount(city)
    local n = 0
    if not city then return 0 end
    for u in civ.iterateUnits() do
        if u.homeCity == city then
            n = n + 1
        end
    end
    return n
end

local function hasShields(city)
    if not city then return false end
    local s = city.shields
    if type(s) == "number" and s > 0 then return true end
    -- airfields often sit at 0 stored shields but still produce
    if city.size and city.size > 0 then return true end
    return false
end

local function hasSupportRoom(city)
    if not city or city.owner ~= alliesTribe() then return false end
    if not hasShields(city) then return false end
    local cap = city.size or 0
    if cap < 1 then return false end
    return homedCount(city) < cap
end

local function isAirfield(city)
    return city and helper.isOTRAirfield and helper.isOTRAirfield(city)
end

local function xyDist(unit, city)
    if not unit or not city or not unit.location or not city.location then
        return math.huge
    end
    if gen.distance then
        return gen.distance(unit.location, city.location, 0)
    end
    local dx = unit.location.x - city.location.x
    local dy = unit.location.y - city.location.y
    return math.max(math.abs(dx), math.abs(dy))
end

local function inBritain(city)
    if not city or not helper.airZoneFor then return false end
    return helper.airZoneFor(city.location.x, city.location.y) == "Britain"
end

local function pickCity(unit)
    local night = isNightBomber(unit)
    local nearAf, farAf, nearAny, farAny = {}, {}, {}, {}
    local britainAf, britainAny = {}, {}

    for city in civ.iterateCities() do
        if hasSupportRoom(city) then
            local d = xyDist(unit, city)
            local af = isAirfield(city)
            if inBritain(city) then
                if af then britainAf[#britainAf + 1] = city
                else britainAny[#britainAny + 1] = city end
            end
            if d <= PREFER_RANGE then
                if af then nearAf[#nearAf + 1] = city
                else nearAny[#nearAny + 1] = city end
            else
                if af then farAf[#farAf + 1] = city
                else farAny[#farAny + 1] = city end
            end
        end
    end

    local pool
    -- Home is England first. Close airfields only if nothing in Britain has room.
    if night then
        pool = (#britainAf > 0 and britainAf)
            or (#britainAny > 0 and britainAny)
            or (#nearAf > 0 and nearAf)
            or (#farAf > 0 and farAf)
            or (#nearAny > 0 and nearAny)
            or farAny
    else
        -- day: any Allied city, still prefer close, airfields first among equals
        if #nearAf > 0 or #nearAny > 0 then
            pool = {}
            for i = 1, #nearAf do pool[#pool + 1] = nearAf[i] end
            for i = 1, #nearAny do pool[#pool + 1] = nearAny[i] end
        else
            pool = {}
            for i = 1, #farAf do pool[#pool + 1] = farAf[i] end
            for i = 1, #farAny do pool[#pool + 1] = farAny[i] end
        end
    end

    if not pool or #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

local function cityById(id)
    if not id then return nil end
    for city in civ.iterateCities() do
        if city.id == id then return city end
    end
    return nil
end

local function destCity(unit)
    local id = destByUnit[unit.id]
    local city = cityById(id)
    if city and hasSupportRoom(city) and city.owner == alliesTribe() then
        return city
    end
    city = pickCity(unit)
    destByUnit[unit.id] = city and city.id or nil
    return city
end

------------------------------------------------------------------------
-- Transit / land
------------------------------------------------------------------------

local function highZ(night)
    return night and NIGHT_HIGH or DAY_HIGH
end

local function lowZ(night)
    return night and NIGHT_LOW or DAY_LOW
end

local function liftToHigh(unit, night)
    local want = highZ(night)
    if unit.location.z == want then return end
    local t = civ.getTile(unit.location.x, unit.location.y, want)
    if t then
        civ.teleportUnit(unit, t)
    end
end

local function overDestColumn(unit, city)
    return unit.location.x == city.location.x
        and unit.location.y == city.location.y
end

local function landAtCity(unit, city, night)
    local z = lowZ(night)
    local pad = civ.getTile(city.location.x, city.location.y, z)
    if not pad then
        pad = city.location
    end
    civ.teleportUnit(unit, pad)
    unit.homeCity = city
    unit.moveSpent = 255
    destByUnit[unit.id] = nil
end

local function highDestTile(city, night)
    return civ.getTile(city.location.x, city.location.y, highZ(night))
end

local function stepCloser(unit, destTile)
    if not destTile then return false end
    local here = unit.location
    if here.x == destTile.x and here.y == destTile.y then
        return false
    end
    local best, bestD = nil, gen.tileDist(here, destTile)
    local adj = gen.getAdjacentTiles and gen.getAdjacentTiles(here)
    if adj then
        for _, tile in pairs(adj) do
            if tile and tile.z == here.z then
                local d = gen.tileDist(tile, destTile)
                if d < bestD then
                    best, bestD = tile, d
                end
            end
        end
    end
    if not best then return false end
    civ.teleportUnit(unit, best)
    return true
end

local function remainingMoves(unit)
    local cap = unit.type.move or 0
    local spent = unit.moveSpent or 0
    return math.max(0, cap - spent)
end

-- Fly remaining MP toward the high-alt column over the home airfield.
-- When the bomber is on that column, forced dive onto z=0 / z=2 and park.
local function flyHome(unit, city, night)
    liftToHigh(unit, night)
    if overDestColumn(unit, city) then
        landAtCity(unit, city, night)
        return true
    end
    local dest = highDestTile(city, night)
    if dest and unit.gotoTile ~= dest then
        unit.gotoTile = dest
    end
    local steps = remainingMoves(unit)
    if steps < 1 then steps = unit.type.move or 1 end
    for _ = 1, steps do
        if overDestColumn(unit, city) then
            landAtCity(unit, city, night)
            return true
        end
        if not stepCloser(unit, dest) then
            break
        end
        unit.moveSpent = (unit.moveSpent or 0) + 1
    end
    if overDestColumn(unit, city) then
        landAtCity(unit, city, night)
    end
    return true
end

local function handleBomber(unit)
    if not needsRtb(unit) then return false end
    local night = isNightBomber(unit)
    local city = destCity(unit)
    if not city then return false end
    return flyHome(unit, city, night)
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

-- Activate is when the AI is about to give orders. Set goto here.
function discreteEvents.onActivateUnit(unit, source, rep)
    if not unit then return end
    handleBomber(unit)
end

-- If goto walks them onto the column mid-turn, land immediately.
function discreteEvents.onEnterTile(unit, previousTile, previousDomainSpec)
    if not unit then return end
    if not needsRtb(unit) then return end
    local city = destCity(unit)
    if city and overDestColumn(unit, city) then
        landAtCity(unit, city, isNightBomber(unit))
    end
end

-- Safety net: every Allied AI turn, re-issue goto for stragglers
-- that the AI activated without us seeing them.
function discreteEvents.onTribeTurnBegin(turn, tribe)
    if tribe ~= alliesTribe() then return end
    if not alliesAreAi() then return end
    for unit in civ.iterateUnits() do
        if needsRtb(unit) then
            handleBomber(unit)
        end
    end
end

function discreteEvents.onUnitDeleted(deletedUnit, replacingUnit)
    if deletedUnit then
        destByUnit[deletedUnit.id] = nil
    end
end

------------------------------------------------------------------------
-- Public
------------------------------------------------------------------------

alliedSortie.needsRtb     = needsRtb
alliedSortie.pickCity     = pickCity
alliedSortie.handleBomber = handleBomber
alliedSortie.destCity     = destCity

return alliedSortie
