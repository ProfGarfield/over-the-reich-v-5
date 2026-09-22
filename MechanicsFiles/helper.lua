-- This file contains 'helper functions' which are specific
-- to Over the Reich, but not to any particular module.
--

local object = require("object")
local traits = require("traits")
local gen = require("generalLibrary")
local helper = {}

function helper.isOTRAirfield(city)
    return city:hasImprovement(object.iAirbase)
end

function helper.isOTRCity(city)
    return city:hasImprovement(object.iCity)
end

local cityList = {}
local cityIndex = 1
local airfieldList = {}
local airfieldIndex = 1
for city in civ.iterateCities() do
    if helper.isOTRCity(city) then
        cityList[cityIndex] = city
        cityIndex = cityIndex + 1
    end
    if helper.isOTRAirfield(city) then
        airfieldList[airfieldIndex] = city
        airfieldIndex = airfieldIndex + 1
    end
end

function helper.OTRCityIterator()
    return coroutine.wrap(function()
        for _,city in pairs(cityList) do
            coroutine.yield(city)
        end
    end)
end

function helper.OTRAirfieldIterator()
    return coroutine.wrap(function()
        for _,city in pairs(airfieldList) do
            coroutine.yield(city)
        end
    end)
end

function helper.isWithinCityRadius(tile, otherTile)
    local dist = gen.tileDist(tile, otherTile)
    if dist <= 1 then
        return true
    elseif dist >= 3 then
        return false
    elseif math.abs(tile.x - otherTile.x) == 4 or
            math.abs(tile.y - otherTile.y) == 4 then
        return false
    else
        return true
    end
end

function helper.dumpTargetPlacements()
    local cityData = require("cityData")
    local gen = require("generalLibrary")
    local object = require("object")
    local items = {
        object.iHousingDistrictI, object.iHousingDistrictII, object.iHousingDistrictIII,
        object.iAircraftFactory, object.iEngineFactory, object.iAvionicsFactory,
        object.iElectricPowerPlantI, object.iElectricPowerPlantII, object.iElectricPowerPlantIII,
        object.iArmamentsFactory, object.iOilRefinery, object.iSyntheticFuelRefinery,
        object.iFuelStorageSilos, object.iVWeaponSite, object.iHeavyFlakBattery,
        object.iRailyards, object.iUBoatPens, object.iPortFacility, object.iConvoyRoutes,
    }
    local path = [[D:\Test of Time\Scenario\over-the-reich-v-5\targetPlacements_dump.txt]]
    print("writing", path)
    local f, err = io.open(path, "w")
    print("open", f, err)
    if not f then
        return
    end
    f:write("local object = require(\"object\")\nlocal targetPlacements = {\n")
    for city in helper.OTRCityIterator() do
        for _, item in ipairs(items) do
            local key = "reservedTileIDFor"..item.id
            if not cityData.counterIsNil(city, key) then
                local tile = gen.getTileFromID(cityData.counterGetValue(city, key))
                f:write(string.format("    {cityName = %q, itemName = %q, x = %d, y = %d},\n",
                    city.name, item.name, tile.x, tile.y))
            end
        end
    end
    f:write("}\nreturn targetPlacements\n")
    f:close()
    print("wrote", path)
end

-- Rectangles still used for Germany and as silo flags.
helper.airZones = {
    Britain    = {x0=0,   x1=111, y0=0,   y1=121, silo=false},
    France     = {x0=0,   x1=165, y0=100, y1=194, silo=true},
    NWGermany  = {x0=166, x1=222, y0=0,   y1=97,  silo=true},
    SWGermany  = {x0=166, x1=222, y0=98,  y1=194, silo=true},
    NEGermany  = {x0=223, x1=334, y0=0,   y1=97,  silo=true},
    SEGermany  = {x0=223, x1=334, y0=98,  y1=194, silo=true},
}

-- Britain / France only. Trace more points later if the Channel is still ugly.
-- Britain first in ZONE_ORDER so the 0-111 / y100-121 overlap stays British.
helper.airPolygons = {
    Britain = {
        {0,128},
        {42,128},
        {42,116},
        {108,116},
        {108,100},
        {118,100},
        {118,92},
        {130,92},
        {130,0},
        {0,0},
    },
    France = {
        {0,128},
        {42,128},
        {42,116},
        {108,116},
        {108,100},
        {118,100},
        {118,92},
        {130,92},
        {130,0},
        {165,0},
        {165,194},
        {0,194},
    },
}

local ZONE_ORDER = {
    "Britain", "France", "NWGermany", "SWGermany", "NEGermany", "SEGermany",
}

local function pointInPoly(x, y, poly)
    local inside = false
    local n = #poly
    local j = n
    for i = 1, n do
        local xi, yi = poly[i][1], poly[i][2]
        local xj, yj = poly[j][1], poly[j][2]
        if ((yi > y) ~= (yj > y))
            and (x < (xj - xi) * (y - yi) / ((yj - yi) + 0.0) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

function helper.airZoneFor(x, y)
    for _, name in ipairs(ZONE_ORDER) do
        local poly = helper.airPolygons[name]
        if poly then
            if pointInPoly(x, y, poly) then
                return name, helper.airZones[name]
            end
        else
            local z = helper.airZones[name]
            if z and x >= z.x0 and x <= z.x1 and y >= z.y0 and y <= z.y1 then
                return name, z
            end
        end
    end
    return nil
end

function helper.airZoneForTile(tile)
    return helper.airZoneFor(tile.x, tile.y)
end

function helper.radarHpByZone()
    local out = {}
    for name, z in pairs(helper.airZones) do
        out[name] = {
            freya = 0, freyaMax = 0,
            wurz = 0, wurzMax = 0,
            ch = 0, chMax = 0,
            n = 0,
        }
    end
    for u in civ.iterateUnits() do
        if u.location.z == 0 then
            local name = helper.airZoneFor(u.location.x, u.location.y)
            if name then
                local row = out[name]
                local hp = u.type.hitpoints - u.damage
                local mx = u.type.hitpoints
                local id = u.type.id
                row.n = row.n + 1
                if id == 2 then
                    row.freya = row.freya + hp
                    row.freyaMax = row.freyaMax + mx
                elseif id == 3 then
                    row.wurz = row.wurz + hp
                    row.wurzMax = row.wurzMax + mx
                elseif id == 0 then
                    row.ch = row.ch + hp
                    row.chMax = row.chMax + mx
                end
            end
        end
    end
    return out
end

function _G.console.dumpRadarBoxes()
    local t = civ.getCurrentTile()
    local name = helper.airZoneFor(t.x, t.y)
    print(string.format("cursor %d,%d zone=%s", t.x, t.y, name or "NONE"))
    local data = helper.radarHpByZone()
    for _, key in ipairs(ZONE_ORDER) do
        local row = data[key]
        if row then
            print(string.format(
                "%s  Freya %d/%d  Wurz %d/%d  CH %d/%d  allUnits=%d",
                key, row.freya, row.freyaMax, row.wurz, row.wurzMax,
                row.ch, row.chMax, row.n))
        end
    end
end

return helper