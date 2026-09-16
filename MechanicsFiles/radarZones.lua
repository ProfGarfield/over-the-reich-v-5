-- radarZones.lua
-- Player-facing radar model for Over the Reich (single player).
--
-- Geography: helper.airZones (Britain / France / four German boxes).
-- Sites: Freya + Würzburg units on map 0, no home city. Chain Home in Britain.
-- A box's HP% is the living hitpoints of those sites. Smash the sites, the
-- box goes blind. Rebuild is just leaving the unit on the map (sliver HP).
--
-- Freya = early warning. German AI/EW gear raises a 0-3 "rung".
--   0 = zone toast only (once per German turn, later).
--   1-3 = reserved for tighter sub-box / blip markers.
-- Allied Monica, ABC, Serrate knock the rung down. A box at 0% Freya HP
-- is always rung 0.
--
-- Würzburg = gun-laying / close control. Combat will multiply flak and
-- night-fighter quality by wurzFactor (0 to 1). Perfectos lowers the
-- tech term. Window is NOT a third -1; it is a 1-2 turn blackout in the
-- raid box only (console.armWindow / later auto when Allies have Window
-- and aircraft are in the box).
--
-- Not used: Wilde Sau (day fighters onto the night map), Zahme Sau,
-- Schräge Musik, SN-2 / Lichtenstein (those unlock airframes).

local helper = require("helper")
local object = require("object")
local discreteEvents = require("discreteEventsRegistrar")

local radarZones = {}

local GERMAN = {
    France = true, NWGermany = true, SWGermany = true,
    NEGermany = true, SEGermany = true,
}

local windowLeft = {}
local toasted = {}

local function clamp(n, lo, hi)
    if n < lo then return lo end
    if n > hi then return hi end
    return n
end

local function has(tribe, tech)
    return tribe:hasTech(tech)
end

local function isAlliedAir(unit)
    return unit.owner == civ.getTribe(1) and unit.type.domain == 1
end

-- German +1: Flensburg, Naxos-Z, FuG 240 Berlin (no unit unlock)
-- Allied -1: Monica, Airborne Cigar (ABC), Serrate
local function freyaTechRung()
    local g = civ.getTribe(2)
    local a = civ.getTribe(1)
    local plus, minus = 0, 0
    if has(g, object.aFlensburg) then plus = plus + 1 end
    if has(g, object.aNaxosZ) then plus = plus + 1 end
    if has(g, object.aFuG240Berlin) then plus = plus + 1 end
    if has(a, object.aMonica) then minus = minus + 1 end
    if has(a, object.aAirborneCigarABC) then minus = minus + 1 end
    if has(a, object.aSerrate) then minus = minus + 1 end
    return clamp(plus - minus, 0, 3)
end

-- German Würzburg advances not in Rules yet → 0
-- Allied -1: Perfectos only
local function wurzTechMod()
    local minus = 0
    if has(civ.getTribe(1), object.aPerfectos) then
        minus = 1
    end
    return clamp(0 - minus, 0, 3)
end

function radarZones.quality(zoneName)
    local data = helper.radarHpByZone()
    local row = data[zoneName]
    if not row then
        return {freya = 0, wurz = 0, ch = 0, kind = "none"}
    end
    local function pct(n, d)
        if d <= 0 then return 0 end
        return n / d
    end
    local kind = "none"
    if zoneName == "Britain" then
        kind = "chainHome"
    elseif GERMAN[zoneName] then
        kind = "german"
    end
    return {
        kind = kind,
        freya = pct(row.freya, row.freyaMax),
        wurz = pct(row.wurz, row.wurzMax),
        ch = pct(row.ch, row.chMax),
    }
end

function radarZones.qualityAt(x, y)
    local name = helper.airZoneFor(x, y)
    if not name then
        return {kind = "none", freya = 0, wurz = 0, ch = 0, zone = nil}
    end
    local q = radarZones.quality(name)
    q.zone = name
    return q
end

function radarZones.armWindow(zoneName, turns)
    windowLeft[zoneName] = turns or 2
end

function radarZones.windowPenalty(zoneName)
    if (windowLeft[zoneName] or 0) > 0 then
        return 2
    end
    return 0
end

function radarZones.freyaRung(zoneName)
    local q = radarZones.quality(zoneName)
    if q.kind ~= "german" or q.freya <= 0 then
        return 0
    end
    return freyaTechRung()
end

function radarZones.wurzFactor(zoneName)
    local q = radarZones.quality(zoneName)
    if q.kind ~= "german" then
        return 0
    end
    local raw = wurzTechMod() - radarZones.windowPenalty(zoneName)
    if raw < 0 then
        return 0
    end
    return q.wurz * (raw + 1) / 4
end

function radarZones.combatModsAt(x, y)
    local name = helper.airZoneFor(x, y)
    if not name then
        return {zone = nil, kind = "none", freyaRung = 0, wurzFactor = 0, ch = 0}
    end
    local q = radarZones.quality(name)
    return {
        zone = name,
        kind = q.kind,
        freyaRung = radarZones.freyaRung(name),
        wurzFactor = radarZones.wurzFactor(name),
        ch = q.ch,
    }
end

function radarZones.applyWindowFromRaids()
    if not has(civ.getTribe(1), object.aWindow) then
        return
    end
    local hit = {}
    for u in civ.iterateUnits() do
        if isAlliedAir(u) then
            local name = helper.airZoneFor(u.location.x, u.location.y)
            if name and GERMAN[name] and not hit[name] then
                hit[name] = true
                radarZones.armWindow(name, 2)
                print("Window auto-armed in "..name)
            end
        end
    end
end

function _G.console.dumpRadarQuality()
    local t = civ.getCurrentTile()
    local q = radarZones.qualityAt(t.x, t.y)
    local m = radarZones.combatModsAt(t.x, t.y)
    print(string.format(
        "zone=%s kind=%s freyaHP=%.2f wurzHP=%.2f chHP=%.2f rung=%d wurzFactor=%.2f",
        tostring(q.zone), q.kind, q.freya, q.wurz, q.ch,
        m.freyaRung, m.wurzFactor))
end

function _G.console.armWindow()
    local t = civ.getCurrentTile()
    local name = helper.airZoneFor(t.x, t.y)
    if not name then
        print("no zone")
        return
    end
    radarZones.armWindow(name, 2)
    print("Window 2 turns in "..name)
end

function _G.console.applyWindowFromRaids()
    radarZones.applyWindowFromRaids()
end

-- Probe only: Allies activating a bomber in a live Freya box.
-- Live game will scan on the German turn instead.
discreteEvents.onActivateUnit(function(unit)
    if not isAlliedAir(unit) then
        return
    end
    local q = radarZones.qualityAt(unit.location.x, unit.location.y)
    if q.kind ~= "german" or q.freya <= 0 then
        return
    end
    local turn = civ.getTurn()
    toasted[turn] = toasted[turn] or {}
    if toasted[turn][q.zone] then
        return
    end
    toasted[turn][q.zone] = true
    civ.ui.text("Freya reports activity in "..q.zone..".")
end)

discreteEvents.onTurn(function()
    toasted[civ.getTurn()] = {}
    for z, n in pairs(windowLeft) do
        if n > 0 then
            windowLeft[z] = n - 1
        end
    end
end)

return radarZones