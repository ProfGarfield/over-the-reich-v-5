--[[
    OTR Flak Intercept
    Three jobs, one module:

    1. Direct defense
       Flak keeps native Civ2 defense. High native DEF, 0 attack, 0 move.
       Engine resolves attacks ON the gun tile. That fight does not spend a
       magazine shot.

    2. Intercept an attack on another target
       Before combat resolves on a non-flak tile, one in-range battery with
       shots left may fire. If the aircraft dies, cancel the attack.

    3. Enter-tile fire (Tootall / Alesia pattern)
       After a successful enter (not a failed attack), one in-range battery
       may fire. Same dice as (2).

    One event -> one battery (nearest with shots).

    Hit-chance stack (multiplicative, then cap 0.95):

        chance = base(high or low)
               * night    (0.50 on a night map, else 1.00)
               * cloud    (0.75 if the AIRCRAFT tile is cloud, else 1.00)
               * wurzburg (1.25 if that battery is under Wurzburg cover, else 1.00)

        Night halves. Cloud takes another 25% off. Wurzburg puts 25% back.
        It does NOT restore full day-clear performance.

    Damage bands after a hit are unchanged. Night/cloud/W only move hit chance.

    Do not hook engine A/D dice here.
]]

local gen            = require("generalLibrary")
local object         = require("object")
local param          = require("parameters")
local text           = require("text")
local func           = require("functions")
local discreteEvents = require("discreteEventsRegistrar")
local traits         = require("traits")

local flak = {}

-- object.lua is a makeDataTable: missing keys error, they do not return nil.
local function obj(key)
    local ok, val = pcall(function() return object[key] end)
    if ok then return val end
    return nil
end

------------------------------------------------------------------------
-- Parameters (override from parameters.lua via param.flak = { ... })
------------------------------------------------------------------------

local P = param.flak or {}

flak.shotsPerTurn  = P.shotsPerTurn  or 3
flak.hitChanceHigh = P.hitChanceHigh or 0.22
flak.hitChanceLow  = P.hitChanceLow  or 0.55

flak.nightFactor    = P.nightFactor    or 0.50
flak.cloudFactor    = P.cloudFactor    or 0.75
flak.wurzburgFactor = P.wurzburgFactor or 1.25

flak.bandsHigh = P.bandsHigh or {
    { p = 0.60, lo = 1,  hi = 3  },
    { p = 0.20, lo = 4,  hi = 7  },
    { p = 0.15, lo = 8,  hi = 11 },
    { p = 0.05, lo = 20, hi = 20 },
}
flak.bandsLow = P.bandsLow or {
    { p = 0.35, lo = 2,  hi = 5  },
    { p = 0.25, lo = 6,  hi = 10 },
    { p = 0.20, lo = 11, hi = 16 },
    { p = 0.20, lo = 20, hi = 20 },
}

flak.narrate = (P.narrate ~= false)
flak.debug   = (P.debug == true)
flak.allowFriendly = (P.allowFriendly ~= false) -- test default ON; set param.flak.allowFriendly=false for real play

-- Maps: 0 low day, 1 high day, 2 low night, 3 high night
flak.lowZ  = P.lowZ  or 0
flak.highZ = P.highZ or 1
flak.nightZ = P.nightZ or {2, 3}
flak.useNightFlag  = (P.useNightFlag == true)
flak.nightFlagName = P.nightFlagName or "nighttime"
flak.wurzburgRange = P.wurzburgRange or 8

------------------------------------------------------------------------
-- Roles
------------------------------------------------------------------------

local ROLE_FIGHTER = "fighter"
local ROLE_JABO    = "jabo"
local ROLE_MEDIUM  = "medium"
local ROLE_HEAVY   = "heavy"
local ROLE_OTHER   = "other"

flak.aircraftRole = P.aircraftRole or {}

-- Prefer an explicit override, otherwise read the combat traits already
-- assigned in airCombatTestSet. Empty table used to force ROLE_OTHER,
-- which meant only Flakzug would ever fire.
local function roleOf(unitType)
    if flak.aircraftRole[unitType.id] then
        return flak.aircraftRole[unitType.id]
    end
    local function has(name)
        local ok, result = pcall(traits.hasTrait, unitType, name)
        return ok and result
    end
    if has("jabo") then return ROLE_JABO end
    if has("heavyBomber") then return ROLE_HEAVY end
    if has("mediumBomber") or has("lightBomber") then return ROLE_MEDIUM end
    if has("fighter") then return ROLE_FIGHTER end
    if has("bomber") then return ROLE_HEAVY end
    -- unknown airframe: treat as fighter so light guns still test
    return ROLE_FIGHTER
end

------------------------------------------------------------------------
-- Batteries
------------------------------------------------------------------------

local ALL_ROLES        = { [ROLE_FIGHTER]=true, [ROLE_JABO]=true, [ROLE_MEDIUM]=true, [ROLE_HEAVY]=true, [ROLE_OTHER]=true }
local FIGHTER_JABO     = { [ROLE_FIGHTER]=true, [ROLE_JABO]=true }
local FIGHTER_JABO_MED = { [ROLE_FIGHTER]=true, [ROLE_JABO]=true, [ROLE_MEDIUM]=true }
local MED_HEAVY        = { [ROLE_MEDIUM]=true, [ROLE_HEAVY]=true }

local function addBattery(key, spec)
    local u = obj(key)
    if u then
        flak.batteries[u.id] = spec
    end
end

flak.batteries = {}
addBattery("u2cmFlakvierling", { lowOnly=true,  roles=FIGHTER_JABO,     range=1 })
addBattery("u37cmFlak36",      { lowOnly=true,  roles=FIGHTER_JABO_MED, range=2 })
addBattery("u88cmFlak18",      { lowOnly=false, roles=MED_HEAVY,        range=4 })
addBattery("u128cmFlak40",     { lowOnly=false, roles=MED_HEAVY,        range=6 })
addBattery("uFlakzug",         { lowOnly=false, roles=ALL_ROLES,        range=3 })
addBattery("uPolsten20mm",     { lowOnly=true,  roles=FIGHTER_JABO,     range=1 })
addBattery("uBofors40mmUK",    { lowOnly=true,  roles=FIGHTER_JABO_MED, range=2 })
addBattery("uBofors40mmUS",    { lowOnly=true,  roles=FIGHTER_JABO_MED, range=2 })
addBattery("u37Flak",          { lowOnly=false, roles=MED_HEAVY,        range=4 })

local function nameLooksLikeFlak(unitType)
    local n = unitType.name or ""
    return n:find("[Ff]lak") or n:find("[Bb]ofors") or n:find("[Pp]olsten") or n:find("[Vv]ierling")
end

local function specFor(unitType)
    if flak.batteries[unitType.id] then
        return flak.batteries[unitType.id]
    end
    -- pad / regen / unnamed flak still counts so a test gun actually shoots
    if nameLooksLikeFlak(unitType) then
        return { lowOnly=false, roles=ALL_ROLES, range=4 }
    end
    return nil
end

local function isFlakType(unitType)
    return specFor(unitType) ~= nil
end

------------------------------------------------------------------------
-- Shot budget (plain table, same pattern as fuelTrain billedThisTurn)
-- Not a template counter -- those must be defined first and this
-- key is per unit.id created at runtime.
------------------------------------------------------------------------

local shotsUsedTable = rawget(_G, "_flakShotsUsed")
if not shotsUsedTable then
    shotsUsedTable = {}
    rawset(_G, "_flakShotsUsed", shotsUsedTable)
end

-- gunId.."#"..aircraftId already rolled this turn. Flying 8 tiles
-- through the same battery is one check, not eight.
local engagedTable = rawget(_G, "_flakEngaged")
if not engagedTable then
    engagedTable = {}
    rawset(_G, "_flakEngaged", engagedTable)
end

local function shotsUsed(flakUnit)
    return shotsUsedTable[flakUnit.id] or 0
end

local function spendShot(flakUnit)
    shotsUsedTable[flakUnit.id] = shotsUsed(flakUnit) + 1
end

local function engagedKey(flakUnit, aircraft)
    return tostring(flakUnit.id).."#"..tostring(aircraft.id)
end

local function alreadyEngaged(flakUnit, aircraft)
    return engagedTable[engagedKey(flakUnit, aircraft)] == true
end

local function markEngaged(flakUnit, aircraft)
    engagedTable[engagedKey(flakUnit, aircraft)] = true
end

function flak.shotsLeft(flakUnit)
    return math.max(0, flak.shotsPerTurn - shotsUsed(flakUnit))
end

function flak.resetAllShots()
    for k in pairs(shotsUsedTable) do
        shotsUsedTable[k] = nil
    end
    for k in pairs(engagedTable) do
        engagedTable[k] = nil
    end
end

------------------------------------------------------------------------
-- Geometry / weather / radar
------------------------------------------------------------------------

local function mapIsLow(tile)
    local z = tile.z
    return z == 0 or z == 2
end

-- 0 low day + 1 high day.  2 low night + 3 high night.
-- Guns sit on the low map and fire up at the paired high map.
-- Day batteries never engage night aircraft and vice versa.
local function sameDayNight(gunZ, tileZ)
    local function pair(z)
        if z == 0 or z == 1 then return "day" end
        if z == 2 or z == 3 then return "night" end
        return tostring(z)
    end
    return pair(gunZ) == pair(tileZ)
end

function flak.isNight(tile)
    if flak.useNightFlag then
        local flag = require("flag")
        return flag.value(flak.nightFlagName) == true
    end
    if type(flak.nightZ) == "table" then
        for i = 1, #flak.nightZ do
            if tile.z == flak.nightZ[i] then return true end
        end
        return false
    end
    return false
end

-- High-map cloud only. Low-map tCloudCoverDayLow0 / NightLow0 are reserved
-- for something else and must not count as cloud.
function flak.isCloud(tile)
    local dayHigh   = obj("tCloudCoverDayHigh0")
    local nightHigh = obj("tCloudCoverNightHigh0")
    local t = tile.terrain or tile.baseTerrain
    if dayHigh   and t == dayHigh   then return true end
    if nightHigh and t == nightHigh then return true end
    return false
end

local function wurzburgTypes()
    local t = {}
    local function add(key)
        local u = obj(key)
        if u then t[u.id] = true end
    end
    add("uWurzburg")
    add("uWuerzburg")
    add("uWurzburgRiese")
    add("uFreya")
    return t
end

function flak.hasWurzburgCover(flakUnit)
    local types = wurzburgTypes()
    if not next(types) then
        return false
    end
    for unit in civ.iterateUnits() do
        if types[unit.type.id]
        and unit.owner == flakUnit.owner
        and unit.location.z == flakUnit.location.z
        and gen.distance(unit.location, flakUnit.location) <= flak.wurzburgRange then
            return true
        end
    end
    return false
end

function flak.hitMultiplier(flakUnit, tile)
    local m = 1.0
    if flak.isNight(tile) then
        m = m * flak.nightFactor
    end
    if flak.isCloud(tile) then
        m = m * flak.cloudFactor
    end
    if flak.hasWurzburgCover(flakUnit) then
        m = m * flak.wurzburgFactor
    end
    return m
end

local function inRange(flakUnit, tile)
    local spec = specFor(flakUnit.type)
    if not spec then return false end
    if not sameDayNight(flakUnit.location.z, tile.z) then return false end
    -- xy only; zDist 0 so a gun on z=0 still reaches the aircraft on z=1
    return gen.distance(flakUnit.location, tile, 0) <= spec.range
end

local function canEngage(flakUnit, aircraft, tile)
    local spec = specFor(flakUnit.type)
    if not spec then return false end
    if (not flak.allowFriendly) and flakUnit.owner == aircraft.owner then return false end
    if flak.shotsLeft(flakUnit) <= 0 then return false end
    if alreadyEngaged(flakUnit, aircraft) then return false end
    if spec.lowOnly and not mapIsLow(tile) then return false end
    if not spec.roles[roleOf(aircraft.type)] then return false end
    if not inRange(flakUnit, tile) then return false end
    return true
end

local function pickShooter(aircraft, tile)
    local best, bestDist
    for unit in civ.iterateUnits() do
        if canEngage(unit, aircraft, tile) then
            local d = gen.distance(unit.location, tile)
            if not best or d < bestDist
            or (d == bestDist and flak.shotsLeft(unit) > flak.shotsLeft(best)) then
                best, bestDist = unit, d
            end
        end
    end
    return best
end

------------------------------------------------------------------------
-- Dice
------------------------------------------------------------------------

local function rollBand(bands)
    local r = math.random()
    local acc = 0
    for i = 1, #bands do
        acc = acc + bands[i].p
        if r <= acc then
            local b = bands[i]
            if b.lo == b.hi then return b.lo end
            return math.random(b.lo, b.hi)
        end
    end
    return bands[#bands].hi
end

local function isHeavyGun(unitType)
    local function same(key)
        local u = obj(key)
        return u and u.id == unitType.id
    end
    return same("u88cmFlak18") or same("u128cmFlak40") or same("u37Flak")
end

local function playHit(shooter, aircraft)
    if isHeavyGun(shooter.type) then
        civ.playSound("flak.wav")
    else
        civ.playSound("lightflak.wav")
    end
    if flak.narrate then
        civ.ui.text("Flak batteries open up on this "..aircraft.type.name..".")
    end
end

local function applyHit(aircraft, dmg, shooter, reason)
    playHit(shooter, aircraft)
    local hp = aircraft.type.hitpoints
    aircraft.damage = math.min(hp, aircraft.damage + dmg)
    if aircraft.damage >= hp then
        civ.deleteUnit(aircraft)
        return "killed"
    end
    return "hit"
end

function flak.resolveShot(aircraft, tile, reason)
    if aircraft.type.domain ~= 1 then
        return nil
    end
    local shooter = pickShooter(aircraft, tile)
    if not shooter then
        return nil
    end

    local base = mapIsLow(tile) and flak.hitChanceLow or flak.hitChanceHigh
    local hitP = math.min(0.95, base * flak.hitMultiplier(shooter, tile))

    markEngaged(shooter, aircraft)
    spendShot(shooter)

    if math.random() > hitP then
        if isHeavyGun(shooter.type) then
            civ.playSound("flak.wav")
        else
            civ.playSound("lightflak.wav")
        end
        if flak.narrate then
            civ.ui.text("Flak batteries fire on this "..aircraft.type.name..". But miss.")
        end
        return "miss"
    end

    local bands = mapIsLow(tile) and flak.bandsLow or flak.bandsHigh
    return applyHit(aircraft, rollBand(bands), shooter, reason)
end

------------------------------------------------------------------------
-- Public hooks
------------------------------------------------------------------------

function flak.onEnterTile(unit, previousTile, previousDomainSpec)
    if isFlakType(unit.type) then return end
    if unit.type.domain ~= 1 then return end
    flak.resolveShot(unit, unit.location, "enter")
end

function flak.onInterceptAttack(attacker, defender)
    if attacker.type.domain ~= 1 then return false end
    if defender and isFlakType(defender.type) then return false end
    local tile = defender and defender.location or attacker.location
    return flak.resolveShot(attacker, tile, "intercept") == "killed"
end

function flak.isFlakType(unitType)
    return isFlakType(unitType)
end

discreteEvents.onEnterTile(function(unit, previousTile, previousDomainSpec)
    flak.onEnterTile(unit, previousTile, previousDomainSpec)
end)

discreteEvents.onTurn(function(turn)
    flak.resetAllShots()
end)

return flak
