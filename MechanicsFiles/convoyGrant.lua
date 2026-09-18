-- MechanicsFiles/convoyGrant.lua
local object         = require("object")
local helper         = require("helper")
local param          = require("parameters")
local text           = require("text")
local discreteEvents = require("discreteEventsRegistrar")

local convoyGrant = {}

local function pAlliedInterval() return param.convoyAlliedInterval     or 2  end
local function pAlliedDay()      return param.convoyAlliedDayCount     or 2  end
local function pAlliedNight()    return param.convoyAlliedNightCount   or 2  end
local function pGermanInterval() return param.convoyGermanInterval     or 3  end
local function pGermanCount()    return param.convoyGermanCount        or 2  end
local function pUboatFull()      return param.convoyUboatFullCount     or 11 end
local function pDayMap()         return param.convoyAlliedDayMap       or 0  end
local function pNightMap()       return param.convoyAlliedNightMap     or 2  end
local function pRequireRoute()
    if param.convoyRequireRoute == nil then return true end
    return param.convoyRequireRoute
end

local function tribeHasTech(tribe, tech)
    if not tribe or not tech then return false end
    return tribe:hasTech(tech)
end

local function countUnits(unitType, owner)
    local n = 0
    for unit in civ.iterateUnits() do
        if unit.type == unitType then
            if owner == nil or unit.owner == owner then
                n = n + 1
            end
        end
    end
    return n
end

local function tribeHasConvoyRoute(tribe)
    if not pRequireRoute() then return true end
    return countUnits(object.uConvoyRoute, tribe) > 0
end

local function alliedBonusFromPens()
    local pens = countUnits(object.uUBoatPens, object.pGermans)
    local missingPlus = (pUboatFull() - pens) + 2
    if missingPlus < 0 then missingPlus = 0 end
    return math.floor(missingPlus / 3)
end

local function alliedDayType(tribe)
    if tribeHasTech(tribe, object.aIncreasedPayload) then return object.uB24Liberator end
    if tribeHasTech(tribe, object.aImprovedHeavies) then return object.uB17GFortress end
    return object.uB17FFortress
end

local function alliedNightType(tribe)
    if tribeHasTech(tribe, object.aIncreasedPayload) then return object.uLancaster end
    if tribeHasTech(tribe, object.aImprovedHeavies) then return object.uHalifax end
    return object.uStirling
end

local function germanFighterType(tribe)
    if tribeHasTech(tribe, object.aRationalizedBf109Production) then return object.uBf109K4 end
    if tribeHasTech(tribe, object.aAttemptstoStandardize) then return object.uBf109G14 end
    if tribeHasTech(tribe, object.aStreamlinedCowlings) then return object.uBf109G10 end
    return object.uBf109G6
end

local function airfieldCities(tribe)
    local list = {}
    for city in civ.iterateCities() do
        if city.owner == tribe and helper.isOTRAirfield(city) then
            list[#list + 1] = city
        end
    end
    return list
end

local function spawnTile(city, mapZ)
    if not city then return nil end
    local t = civ.getTile(city.location.x, city.location.y, mapZ)
    if t then return t end
    return city.location
end

local function pickCity(cities)
    if #cities == 0 then return nil end
    return cities[math.random(1, #cities)]
end

local function placeUnit(unitType, tribe, cities, mapZ)
    if not unitType then return false end
    local city = pickCity(cities)
    if not city then return false end
    local tile = spawnTile(city, mapZ)
    if not tile then return false end
    local u = civ.createUnit(unitType, tribe, tile)
    if u then
        u.homeCity = city
        return true
    end
    return false
end

local function grantAllies(turn)
    local tribe = object.pAllies
    if not tribe or not tribeHasConvoyRoute(tribe) then return end
    local cities = airfieldCities(tribe)
    if #cities == 0 then return end
    local extra = alliedBonusFromPens()
    local placed = 0
    for i = 1, pAlliedDay() + extra do
        if placeUnit(alliedDayType(tribe), tribe, cities, pDayMap()) then placed = placed + 1 end
    end
    for i = 1, pAlliedNight() + extra do
        if placeUnit(alliedNightType(tribe), tribe, cities, pNightMap()) then placed = placed + 1 end
    end
    if placed > 0 and tribe.isHuman then
        text.simple(
            "Additional bomber aircraft arrive from the United States and the Empire.",
            "Reinforcements"
        )
    end
end

local function grantGermans(turn)
    local tribe = object.pGermans
    if not tribe or not tribeHasConvoyRoute(tribe) then return end
    local cities = airfieldCities(tribe)
    if #cities == 0 then return end
    local placed = 0
    for i = 1, pGermanCount() do
        if placeUnit(germanFighterType(tribe), tribe, cities, pDayMap()) then placed = placed + 1 end
    end
    if placed > 0 and tribe.isHuman then
        text.simple(
            "Additional fighter units are drawn from other theaters.",
            "Reinforcements"
        )
    end
end

discreteEvents.onTurn(function(turn)
    if not turn or turn < 1 then return end
    if pAlliedInterval() > 0 and (turn % pAlliedInterval() == 0) then
        grantAllies(turn)
    end
    if pGermanInterval() > 0 and (turn % pGermanInterval() == 0) then
        grantGermans(turn)
    end
end)

if rawget(_G, "console") then
    function console.convoyStatus()
        print("Allied routes", countUnits(object.uConvoyRoute, object.pAllies))
        print("German routes", countUnits(object.uConvoyRoute, object.pGermans))
        print("U-boat pens", countUnits(object.uUBoatPens, object.pGermans))
        print("Allied bonus", alliedBonusFromPens())
        print("Allied day", alliedDayType(object.pAllies).name)
        print("Allied night", alliedNightType(object.pAllies).name)
        print("German", germanFighterType(object.pGermans).name)
    end
    function console.convoyGrantNow()
        grantAllies(civ.getTurn())
        grantGermans(civ.getTurn())
    end
end

return convoyGrant