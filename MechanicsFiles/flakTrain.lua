-- MechanicsFiles/flakTrain.lua
-- Flakzug cap 20. Engine will not walk this unit (static-gun flags),
-- so movement is Lua teleport along a hasRailroad + city path.
-- Human: on activate, text.menu of cities in the same air zone that
--         still have a rail path, plus "Leave it here."
--         text.menu supplies Next/Previous when the list overflows.
-- German AI: each turn teleport to an uncovered reachable German city.

local object         = require("object")
local helper         = require("helper")
local gen            = require("generalLibrary")
local aStarCiv       = require("aStarCiv")
local discreteEvents = require("discreteEventsRegistrar")
local text           = require("text")

local flakTrain = {}

local CAP = 20
local COVER_RADIUS = 10

local function isFlakzug(unit)
    return unit and unit.type == object.uFlakzug
end

function flakTrain.count(owner)
    local n = 0
    for unit in civ.iterateUnits() do
        if unit.type == object.uFlakzug then
            if owner == nil or unit.owner == owner then
                n = n + 1
            end
        end
    end
    return n
end

function flakTrain.atCap(owner)
    return flakTrain.count(owner) >= CAP
end

local function hasRR(tile)
    return tile and gen.hasRailroad(tile)
end

-- Same rule as movement: overlay or city. Not terrain type 9.
local function isLegalTile(tile)
    if not tile then return false end
    if hasRR(tile) then return true end
    if tile.city then return true end
    return false
end

local function neighboursOnRail(tile)
    local out = {}
    if not tile then return out end
    for _, adj in pairs(gen.getAdjacentTiles(tile)) do
        if adj and adj.z == tile.z and isLegalTile(adj) then
            out[#out + 1] = {adj, 1}
        end
    end
    return out
end

local function railHeuristic(fromTile, goal)
    if civ.isTile(goal) then
        return gen.tileDist(fromTile, goal)
    end
    local best = math.huge
    for _, g in pairs(goal) do
        local d = gen.tileDist(fromTile, g)
        if d < best then best = d end
    end
    return best
end

local function pathCost(path)
    return #path - 1
end

local function hasRailPath(startTile, destTile)
    if not startTile or not destTile then return false end
    if startTile == destTile then return true end
    if startTile.x == destTile.x and startTile.y == destTile.y and startTile.z == destTile.z then
        return true
    end
    if not isLegalTile(startTile) then return false end
    if not isLegalTile(destTile) then return false end
    return aStarCiv.aStar(startTile, destTile, railHeuristic, neighboursOnRail, pathCost, 400)
end

local function kickToAccumulate(city)
    if not city or not object.iAccumulateResources then return end
    city.production = object.iAccumulateResources
end

discreteEvents.onCityProcessed(function(city)
    if city and city.production == object.uFlakzug and flakTrain.atCap(city.owner) then
        kickToAccumulate(city)
    end
end)

discreteEvents.onCityProduction(function(city, item)
    if item ~= object.uFlakzug then return end
    if flakTrain.count(city.owner) > CAP then
        kickToAccumulate(city)
    end
end)

local function citiesInZone(tribe, zoneName)
    local list = {}
    for city in civ.iterateCities() do
        if city.owner == tribe and helper.isOTRCity(city) and city.location then
            if helper.airZoneFor(city.location.x, city.location.y) == zoneName then
                list[#list + 1] = city
            end
        end
    end
    table.sort(list, function(a, b)
        return a.name < b.name
    end)
    return list
end

local function reachableCities(unit)
    local zoneName = helper.airZoneFor(unit.location.x, unit.location.y)
    local reachable = {}
    for _, city in ipairs(citiesInZone(unit.owner, zoneName)) do
        if hasRailPath(unit.location, city.location) then
            reachable[#reachable + 1] = city
        end
    end
    return reachable, zoneName
end

local prompting = false

local function humanChooseDest(unit)
    if prompting then return end
    prompting = true
    local cities = reachableCities(unit)
    local menuTable = {}
    menuTable[1] = "Leave it here."
    for i, city in ipairs(cities) do
        menuTable[i + 1] = city.name
    end
    local choice = text.menu(
        menuTable,
        "Where should we move this Flakzug?",
        "Flak Trains",
        false
    )
    if choice and choice >= 2 then
        local destCity = cities[choice - 1]
        if destCity and destCity.location and destCity.location ~= unit.location then
            civ.teleportUnit(unit, destCity.location)
        end
    end
    unit.moveSpent = 99
    prompting = false
end

discreteEvents.onActivateUnit(function(unit, source, repeatMove)
    if repeatMove then return end
    if not isFlakzug(unit) then return end
    if not unit.owner or not unit.owner.isHuman then return end
    if civ.getCurrentTribe() ~= unit.owner then return end
    humanChooseDest(unit)
end)

local destByUnit = rawget(_G, "_flakzugDest")
if not destByUnit then
    destByUnit = {}
    rawset(_G, "_flakzugDest", destByUnit)
end

local function cityCovered(city)
    if not city or not city.location then return true end
    for unit in civ.iterateUnits() do
        if unit.type == object.uFlakzug and unit.owner == city.owner then
            if gen.tileDist(unit.location, city.location) <= COVER_RADIUS then
                return true
            end
        end
    end
    return false
end

local function germanCities(tribe)
    local list = {}
    for city in civ.iterateCities() do
        if city.owner == tribe and helper.isOTRCity(city) then
            list[#list + 1] = city
        end
    end
    return list
end

local function pickDest(unit, cities)
    if #cities == 0 then return nil end
    local hereZone = helper.airZoneFor(unit.location.x, unit.location.y)
    local uncoveredOtherZone, uncoveredSameZone, covered = {}, {}, {}
    for _, city in ipairs(cities) do
        if hasRailPath(unit.location, city.location) then
            local z = helper.airZoneFor(city.location.x, city.location.y)
            if not cityCovered(city) and z ~= hereZone then
                uncoveredOtherZone[#uncoveredOtherZone + 1] = city
            elseif not cityCovered(city) then
                uncoveredSameZone[#uncoveredSameZone + 1] = city
            else
                covered[#covered + 1] = city
            end
        end
    end
    local pool = uncoveredOtherZone
    if #pool == 0 then pool = uncoveredSameZone end
    if #pool == 0 then pool = covered end
    if #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

local function destStillValid(unit, destCity, tribe)
    if not destCity or not destCity.location then return false end
    if destCity.owner ~= tribe then return false end
    return hasRailPath(unit.location, destCity.location)
end

local function aiMoveOne(unit, cities)
    local id = unit.id
    local dest = destByUnit[id]
    if dest and dest.location and gen.tileDist(unit.location, dest.location) <= 1 then
        dest = nil
        destByUnit[id] = nil
    end
    if not destStillValid(unit, dest, unit.owner) then
        dest = pickDest(unit, cities)
        destByUnit[id] = dest
    end
    if dest and dest.location and dest.location ~= unit.location then
        civ.teleportUnit(unit, dest.location)
    end
    unit.moveSpent = 99
end

discreteEvents.onTribeTurnBegin(function(turn, tribe)
    if tribe ~= object.pGermans then return end
    if tribe.isHuman then return end
    local cities = germanCities(tribe)
    for unit in civ.iterateUnits() do
        if unit.type == object.uFlakzug and unit.owner == tribe then
            aiMoveOne(unit, cities)
        end
    end
end)

return flakTrain
