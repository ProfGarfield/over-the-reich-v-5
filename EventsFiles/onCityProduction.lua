-- Airfield teleport on production
-- EventsFiles/onCityProduction.lua
--
-- Day aircraft  -> friendly airbase city on map 0 (low alt day)
-- Night aircraft -> friendly airbase city on map 2 (low alt night)
-- Prefers a random airfield within 15 tiles of the producing city
-- (same x/y, correct z). If none, radius grows by 15 until one is found.

local object = require("object")
local gen = require("generalLibrary")
local helper = require("helper")

local SEARCH_STEP = 15

-- German day -> map 0
local germanDay = {
    [object.uMS406.id] = true,
    [object.uBf109G6.id] = true,
    [object.uBf109G6R6.id] = true,
    [object.uBf109G10.id] = true,
    [object.uBf109G10R6.id] = true,
    [object.uBf109G14.id] = true,
    [object.uBf109G14R6.id] = true,
    [object.uBf109K4.id] = true,
    [object.uFw190A5.id] = true,
    [object.uFw190A6.id] = true,
    [object.uFw190A6R6.id] = true,
    [object.uFw190A8.id] = true,
    [object.uFw190A8R6.id] = true,
    [object.uFw190D9.id] = true,
    [object.uTa152.id] = true,
    [object.uBf110G2.id] = true,
    [object.uBf110G2R3.id] = true,
    [object.uMe210.id] = true,
    [object.uMe410B2.id] = true,
    [object.uMe410B2R3.id] = true,
    [object.uMe163.id] = true,
    [object.uMe262.id] = true,
    [object.uTa183.id] = true,
    [object.uFw190F.id] = true,
    [object.uDo335.id] = true,
    [object.uArado234.id] = true,
    [object.uGo229.id] = true,
    [object.uJu188PR.id] = true,
	[object.uHe162A.id] = true,
}

-- German night -> map 2
local germanNight = {
    [object.uBf110G4.id] = true,
    [object.uJu88C6.id] = true,
    [object.uJu88G.id] = true,
	[object.uHe219.id] = true,
    [object.uDo217N2.id] = true,
	[object.uHe177.id] = true,
    [object.uHe277.id] = true,
}

-- Allied day -> map 0
local alliedDay = {
    [object.uSpitfireMkV.id] = true,
    [object.uSpitfireMkIXLF.id] = true,
    [object.uSpitfireMkIX.id] = true,
    [object.uSpitfireMkXIV.id] = true,
    [object.uP47D6Thunderbolt.id] = true,
    [object.uP47D15Thunderbolt.id] = true,
    [object.uP47D20Thunderbolt.id] = true,
    [object.uP47D25Thunderbolt.id] = true,
    [object.uP47MThunderbolt.id] = true,
    [object.uP38HLightning.id] = true,
    [object.uP38JLightning.id] = true,
    [object.uP38LLightning.id] = true,
    [object.uP51BMustang.id] = true,
    [object.uMustangIII.id] = true,
    [object.uP51DMustang.id] = true,
    [object.uMustangIV.id] = true,
    [object.uP80ShootingStar.id] = true,
    [object.uMeteor.id] = true,
    [object.uWhirlwindIA.id] = true,
    [object.uHurricaneIV.id] = true,
    [object.uMustangI.id] = true,
    [object.uTyphoonIB.id] = true,
    [object.uTempestV.id] = true,
    [object.uP38JJabo.id] = true,
    [object.uP38LJabo.id] = true,
    [object.uP47D15Jabo.id] = true,
    [object.uP47D20Jabo.id] = true,
    [object.uP47D25Jabo.id] = true,
    [object.uP51BJabo.id] = true,
    [object.uMustangIIIJabo.id] = true,
    [object.uP51DJabo.id] = true,
    [object.uMustangIVJabo.id] = true,
    [object.uBaltimoreV.id] = true,
    [object.uBostonIII.id] = true,
    [object.uA20GHavoc.id] = true,
    [object.uA26BInvader.id] = true,
    [object.uB25Mitchell.id] = true,
    [object.uB26Marauder.id] = true,
    [object.uB17FFortress.id] = true,
    [object.uB17FDamaged.id] = true,
    [object.uB17GFortress.id] = true,
    [object.uB17GDamaged.id] = true,
    [object.uB24Liberator.id] = true,
    [object.uB17Pathfinder.id] = true,
    [object.uB24Pathfinder.id] = true,
    [object.uMosquitoPR.id] = true,
}

-- Allied night -> map 2
local alliedNight = {
    [object.uBeaufighter.id] = true,
    [object.uMosquitoNFII.id] = true,
    [object.uMosquitoNFXIX.id] = true,
    [object.uP61ABlackWidow.id] = true,
    [object.uWellington.id] = true,
    [object.uStirling.id] = true,
    [object.uHalifax.id] = true,
    [object.uLancaster.id] = true,
    [object.uMosquitoBIV.id] = true,
    [object.uWellingtonRCM.id] = true,
    [object.uLancasterPathfinder.id] = true,
}

local function destMapFor(unitType)
    local id = unitType.id
    if germanDay[id] or alliedDay[id] then
        return 0
    end
    if germanNight[id] or alliedNight[id] then
        return 2
    end
    return nil
end

local function distXY(tileA, tileB)
    return gen.tileDist(tileA, tileB)
end

local function collectAirfields(owner, destMap, fromTile, maxDist)
    local list = {}
    for city in civ.iterateCities() do
        if city.owner == owner
            and city.location.z == destMap
            and helper.isOTRAirfield(city)
        then
            local d = distXY(fromTile, city.location)
            if d <= maxDist then
                list[#list + 1] = {city = city, dist = d}
            end
        end
    end
    return list
end

local function pickRandom(list)
    if #list == 0 then return nil end
    return list[math.random(1, #list)]
end

local function alreadyHome(city, destMap)
    return city.location.z == destMap and helper.isOTRAirfield(city)
end

local function findNewUnit(city, unitType)
    local tile = city.location
    for unit in tile.units do
        if unit.type == unitType and unit.owner == city.owner then
            return unit
        end
    end
    for unit in civ.iterateUnits() do
        if unit.type == unitType
            and unit.owner == city.owner
            and unit.homeCity == city
            and unit.location == city.location
        then
            return unit
        end
    end
    return nil
end

local function teleportAircraft(city, unitType)
    local destMap = destMapFor(unitType)
    if not destMap then
        return
    end

    if alreadyHome(city, destMap) then
        return
    end

    local unit = findNewUnit(city, unitType)
    if not unit then
        return
    end

    local fromTile = city.location
    local radius = SEARCH_STEP
    local candidates = collectAirfields(city.owner, destMap, fromTile, radius)

    local guard = 0
    while #candidates == 0 and guard < 20 do
        radius = radius + SEARCH_STEP
        candidates = collectAirfields(city.owner, destMap, fromTile, radius)
        guard = guard + 1
    end

    if #candidates == 0 then
        return
    end

local pick = pickRandom(candidates)
    local dest = pick.city.location
    if dest and dest ~= unit.location then
        civ.teleportUnit(unit, dest)
    end
end

local onCityProduction = {}

function onCityProduction.onCityProduction(city, prod)
    if civ.isUnitType(prod) then
        teleportAircraft(city, prod)
    end
end

return onCityProduction