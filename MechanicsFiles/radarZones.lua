-- radarZones.lua
-- Player-facing radar model for Over the Reich (single player).
--
-- Geography: helper.airZones (Britain / France / four German boxes).
-- Sites: Freya + Würzburg on map 0, no home city. Chain Home in Britain.
-- Box HP% = living hitpoints of those sites.
--   Smash Freya to 0%  → rung 0, no toast, no blips.
--   Smash Würzburg     → wurzFactor scales down (combat uses that later).
--
-- Freya = early warning. German AI/EW raises a 0-3 rung.
--   0 = zone toast only, once when Germany's turn begins.
--   3 = also plant a pollution blip on detected Allied air stacks.
-- Allied Monica / ABC / Serrate lower the global rung.
-- A Wellington RCM sitting in a box applies a further -1 in THAT box for 2 turns.
--
-- Würzburg = gun-laying / close control. Combat will use wurzFactor (0-1).
-- Perfectos is a lasting -1 to the tech term.
-- Window is a box blackout (wurzFactor 0) for 3 turns, but ONLY if a
-- Pathfinder is in that box on the German turn (Lancaster Pathfinder 151,
-- B-17 Pathfinder 141, B-24 Pathfinder 142). A stray Lancaster does nothing.
--
-- console.testBlip / clearBlips / armWindow / armRCM exist so we can
-- see markers and timers without ending a turn.
--
-- Not used: Wilde Sau, Zahme Sau, Schräge Musik, SN-2 / Lichtenstein.

local helper = require("helper")
local object = require("object")
local gen = require("generalLibrary")
local discreteEvents = require("discreteEventsRegistrar")

local radarZones = {}

local GERMAN = {
    France = true, NWGermany = true, SWGermany = true,
    NEGermany = true, SEGermany = true,
}

local windowLeft = {}
local rcmLeft = {}
local blipTiles = {}

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

local function isPathfinder(unit)
    local id = unit.type.id
    return id == 151 or id == 141 or id == 142
end

local function isRCM(unit)
    return unit.type.id == 131
end

local function tileKey(tile)
    return tile.x..","..tile.y..","..tile.z
end

local function placeBlip(tile)
    if not tile then
        return
    end
    gen.placePollution(tile)
    blipTiles[tileKey(tile)] = tile
end

local function clearBlips()
    for _, tile in pairs(blipTiles) do
        gen.removePollution(tile)
    end
    blipTiles = {}
end

-- German +1: Flensburg, Naxos-Z, FuG 240 Berlin
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
-- Allied lasting -1: Perfectos
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
    windowLeft[zoneName] = turns or 3
end

function radarZones.armRCM(zoneName, turns)
    rcmLeft[zoneName] = turns or 2
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
    local extra = 0
    if (rcmLeft[zoneName] or 0) > 0 then
        extra = 1
    end
    return clamp(freyaTechRung() - extra, 0, 3)
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

function _G.console.dumpRadarQuality()
    local t = civ.getCurrentTile()
    local q = radarZones.qualityAt(t.x, t.y)
    local m = radarZones.combatModsAt(t.x, t.y)
    print(string.format(
        "zone=%s kind=%s freyaHP=%.2f wurzHP=%.2f chHP=%.2f rung=%d wurzFactor=%.2f window=%d rcm=%d",
        tostring(q.zone), q.kind, q.freya, q.wurz, q.ch,
        m.freyaRung, m.wurzFactor,
        windowLeft[q.zone] or 0, rcmLeft[q.zone] or 0))
end

function _G.console.armWindow()
    local name = helper.airZoneFor(civ.getCurrentTile().x, civ.getCurrentTile().y)
    if not name then
        print("no zone")
        return
    end
    radarZones.armWindow(name, 3)
    print("Window 3 turns in "..name)
end

function _G.console.armRCM()
    local name = helper.airZoneFor(civ.getCurrentTile().x, civ.getCurrentTile().y)
    if not name then
        print("no zone")
        return
    end
    radarZones.armRCM(name, 2)
    print("RCM 2 turns in "..name)
end

function _G.console.testBlip()
    local t = civ.getCurrentTile()
    placeBlip(t)
    print(string.format("blip planted at %d,%d,%d", t.x, t.y, t.z))
end

function _G.console.clearBlips()
    clearBlips()
    print("blips cleared")
end

discreteEvents.onTribeTurnBegin(function(turn, tribe)
    if tribe ~= civ.getTribe(2) then
        return
    end
    clearBlips()
    local seen, pf, rcm = {}, {}, {}
    for u in civ.iterateUnits() do
        if u.owner == civ.getTribe(1) then
            local name = helper.airZoneFor(u.location.x, u.location.y)
            if name and GERMAN[name] then
                if isPathfinder(u) then
                    pf[name] = true
                end
                if isRCM(u) then
                    rcm[name] = true
                end
                if isAlliedAir(u) then
                    local q = radarZones.quality(name)
                    local rung = radarZones.freyaRung(name)
                    if q.freya > 0 and not seen[name] then
                        seen[name] = true
                        civ.ui.text("Freya reports activity in "..name..".")
                    end
                    if q.freya > 0 and rung >= 3 then
                        placeBlip(u.location)
                    end
                end
            end
        end
    end
    for name in pairs(pf) do
        radarZones.armWindow(name, 3)
    end
    for name in pairs(rcm) do
        radarZones.armRCM(name, 2)
    end
end)

discreteEvents.onTurn(function()
    for z, n in pairs(windowLeft) do
        if n > 0 then
            windowLeft[z] = n - 1
        end
    end
    for z, n in pairs(rcmLeft) do
        if n > 0 then
            rcmLeft[z] = n - 1
        end
    end
end)

return radarZones