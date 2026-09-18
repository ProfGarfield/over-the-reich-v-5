--[[
supplyLines.lua
OTR adaptation for fuel-train pathing along railroad improvements.

Original module: Knighttime (CivFanatics), "Supply Lines" v1.0
Adapted for Over the Reich (single player) so a land unit can ask:
    is there a railroad path from here to a fuel-silo unit?

Place this file in MechanicsFiles/supplyLines.lua
Require from the train event file (or events.lua) with:

    local supplyLines = require("supplyLines")

Do not put a second copy in LuaCore / EventsFiles / LuaParameterFiles
(events.lua errors on duplicate file names).

TERMS
    depot  = tile that has an object.uFuelStorageSilos unit
    link   = railroad improvement (bit 0x20), or a friendly city square
    line   = shortest tile path of links from the unit to a depot
]]

local versionNumber = 1
local fileModified = true

local object = require("object")
local gen = require("generalLibrary"):minVersion(1)

local SHOW_SUPPLY_LINE_KEYCODE = 85          -- U; set nil for release
local SHOW_SUPPLY_LINE_KEYLABEL = "[u]"
local CUSTOMIZE_RULES_FLAT_WORLD = true
local MAX_SUPPLY_LINE_LENGTH = 80            -- set < 0 for unlimited
local SUPPLY_MARKER_UNITTYPE = nil           -- set to a dummy unit type to draw paths
local MAX_SUPPLY_MARKERS = 1000
local RAIL_BIT = 0x20                        -- confirmed on OTR rail tiles (improvements 48 = road+rail)
local SILO_UNITTYPE = object.uFuelStorageSilos

local mapWidth, mapHeight, mapQuantity = civ.getMapDimensions()
local supplyLineLastUnitId = -1
local supplyLineFound = nil
local validSupplyZoneTiles = {}
local validSupplyLine = {}

local function isEnemy(tribe1, tribe2)
    if tribe1.id == 0 or tribe2.id == 0 then
        return true
    end
    return (tribe1.treaties[tribe2] & 0x2000 > 0)
        or (tribe2.treaties[tribe1] & 0x2000 > 0)
end

local function containsOtherTribeCity(tile, forTribe)
    return tile.city ~= nil and tile.city.owner ~= forTribe
end

local function containsOtherTribeUnit(tile, forTribe)
    for unit in tile.units do
        if unit.owner ~= forTribe then
            return true
        end
    end
    return false
end

local function isRail(tile)
    return (tile.improvements & RAIL_BIT) == RAIL_BIT
end

local function tileHasSiloUnit(tile, forTribe)
    for u in tile.units do
        if u.type == SILO_UNITTYPE and u.owner == forTribe then
            return true
        end
    end
    return false
end

-- Optional extra filter set by the caller (zone-first search).
-- fn(tile, forTribe) -> bool.  nil means any friendly silo is a depot.
local depotExtraFilter = nil

local function isValidSupplyDepot(tile, forTribe)
    if not tileHasSiloUnit(tile, forTribe) then
        return false, ""
    end
    if depotExtraFilter and not depotExtraFilter(tile, forTribe) then
        return false, ""
    end
    local desc = "silo at "..tile.x..","..tile.y..","..tile.z
    if tile.city then
        desc = desc.." ("..tile.city.name..")"
    end
    return true, desc
end

-- Railroad improvement, or a friendly city (city tiles often lack the rail bit).
-- Map 0 only. Enemy cities / units block.
local function isValidSupplyLink(tile, forTribe)
    if tile == nil then
        return false
    end
    if tile.z ~= 0 then
        return false
    end
    if containsOtherTribeCity(tile, forTribe) then
        return false
    end
    if containsOtherTribeUnit(tile, forTribe) then
        return false
    end
    if tile.city and tile.city.owner == forTribe then
        return true
    end
    return isRail(tile)
end

local function adjacentTiles(tile)
    local list = {}
    local function push(x, y)
        if CUSTOMIZE_RULES_FLAT_WORLD then
            if x < 0 or x >= mapWidth or y < 0 or y >= mapHeight then
                return
            end
        else
            x = x % mapWidth
        end
        local t = civ.getTile(x, y, tile.z)
        if t then
            list[#list + 1] = t
        end
    end
    push(tile.x - 2, tile.y)
    push(tile.x - 1, tile.y - 1)
    push(tile.x,     tile.y - 2)
    push(tile.x + 1, tile.y - 1)
    push(tile.x + 2, tile.y)
    push(tile.x + 1, tile.y + 1)
    push(tile.x,     tile.y + 2)
    push(tile.x - 1, tile.y + 1)
    return list
end

local function tileKey(tile)
    return tile.x + (tile.y * mapWidth) + (tile.z * mapWidth * mapHeight)
end

-- hasSupplyLine(unit, extraFilter) -> bool
-- extraFilter is optional: function(tile, tribe) -> bool
--   use it to restrict depots to "silo in this zone" on the first pass
local function hasSupplyLine(unit, extraFilter)
    depotExtraFilter = extraFilter
    supplyLineLastUnitId = unit.id
    supplyLineFound = nil
    validSupplyZoneTiles = {}
    validSupplyLine = {}

    if unit.type.domain ~= 0 then
        return false
    end

    supplyLineFound = false
    local tilesEncountered = {}
    local tilesNotYetConsidered = {}
    tilesEncountered[tileKey(unit.location)] = 0
    tilesNotYetConsidered[1] = { tile = unit.location, path = {} }

    while #tilesNotYetConsidered > 0 do
        local considering = tilesNotYetConsidered[1]
        table.remove(tilesNotYetConsidered, 1)
        local consideringTile = considering.tile
        local consideringTilePath = { table.unpack(considering.path) }
        local consideringTileDistance = #consideringTilePath
        consideringTilePath[#consideringTilePath + 1] = consideringTile

        local validDepot, _ = isValidSupplyDepot(consideringTile, unit.owner)
        if validDepot then
            validSupplyZoneTiles[#validSupplyZoneTiles + 1] = consideringTile
            supplyLineFound = true
            validSupplyLine = consideringTilePath
            break
        elseif isValidSupplyLink(consideringTile, unit.owner) then
            validSupplyZoneTiles[#validSupplyZoneTiles + 1] = consideringTile
            local underCap = (MAX_SUPPLY_LINE_LENGTH == nil)
                or (MAX_SUPPLY_LINE_LENGTH < 0)
                or (consideringTileDistance < MAX_SUPPLY_LINE_LENGTH)
            if underCap then
                local adjDistance = consideringTileDistance + 1
                for _, adjTile in ipairs(adjacentTiles(consideringTile)) do
                    local id = tileKey(adjTile)
                    if tilesEncountered[id] == nil or tilesEncountered[id] > adjDistance then
                        tilesEncountered[id] = adjDistance
                        tilesNotYetConsidered[#tilesNotYetConsidered + 1] = {
                            tile = adjTile,
                            path = consideringTilePath,
                        }
                    end
                end
            end
        end
    end

    depotExtraFilter = nil
    return supplyLineFound
end

local function getSupplyLine()
    return validSupplyLine
end

local function getSupplyLineFound()
    return supplyLineFound
end

local function showSupplyLine()
    if SUPPLY_MARKER_UNITTYPE == nil then
        return
    end
    for unit in civ.iterateUnits() do
        if unit.type == SUPPLY_MARKER_UNITTYPE then
            local loc = unit.location
            civ.deleteUnit(unit)
            civ.ui.redrawTile(loc)
        end
    end
    if supplyLineFound == true then
        for _, tile in ipairs(validSupplyLine) do
            civ.createUnit(SUPPLY_MARKER_UNITTYPE, civ.getCurrentTribe(), tile)
            civ.ui.redrawTile(tile)
        end
    end
end

-- Convenience for the train mover:
-- first try extraFilter (zone silo), then any friendly silo.
-- returns path table or nil. path[1] = train tile, path[#path] = silo tile.
local function findRailPathToSilo(unit, zoneFilter)
    if hasSupplyLine(unit, zoneFilter) then
        return validSupplyLine
    end
    if zoneFilter and hasSupplyLine(unit, nil) then
        return validSupplyLine
    end
    return nil
end

local supplyLines = {
    SHOW_SUPPLY_LINE_KEYCODE = SHOW_SUPPLY_LINE_KEYCODE,
    SHOW_SUPPLY_LINE_KEYLABEL = SHOW_SUPPLY_LINE_KEYLABEL,
    hasSupplyLine = hasSupplyLine,
    getSupplyLine = getSupplyLine,
    getSupplyLineFound = getSupplyLineFound,
    showSupplyLine = showSupplyLine,
    findRailPathToSilo = findRailPathToSilo,
    isRail = isRail,
}

gen.versionFunctions(supplyLines, versionNumber, fileModified, "MechanicsFiles".."\\".."supplyLines.lua")

console.supplyLines = supplyLines

return supplyLines