
-- This file contains 'helper functions' which are specific
-- to Over the Reich, but not to any particular module.
--

local object = require("object")
local traits = require("traits")
local gen = require("generalLibrary")
local helper = {}

-- returns true if the city has the airbase improvement,
-- false otherwise
function helper.isOTRAirfield(city)
    return city:hasImprovement(object.iAirbase)
end

-- returns true if the city has the city I improvement
-- false otherwise
function helper.isOTRCity(city)
    return city:hasImprovement(object.iCity)
end

local cityList = {}
local cityIndex = 1
local airfieldList = {}
local airfieldIndex = 1
-- list all cities and airfields
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

-- iterate over OTR Cities
function helper.OTRCityIterator()
    return coroutine.wrap(function()
        for _,city in pairs(cityList) do
            coroutine.yield(city)
        end
    end)
end
    
-- iterate over OTR Airfields
function helper.OTRAirfieldIterator()
    return coroutine.wrap(function()
        for _,city in pairs(airfieldList) do
            coroutine.yield(city)
        end
    end)
end

-- returns true if a tile would be within a city
-- radius of the other tile, and false otherwise
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
    
--Attempt at coming up with air zones that will have a silo attributed to it.
helper.airZones = {
    Britain    = {x0=0,   x1=111, y0=0,   y1=108, silo=false},
    France     = {x0=0,   x1=165, y0=109, y1=194, silo=true},
    NWGermany  = {x0=166, x1=222, y0=0,   y1=97,  silo=true},
    SWGermany  = {x0=166, x1=222, y0=98,  y1=194, silo=true},
    NEGermany  = {x0=223, x1=334, y0=0,   y1=97,  silo=true},
    SEGermany  = {x0=223, x1=334, y0=98,  y1=194, silo=true},
}

function helper.airZoneFor(x, y)
    for name, z in pairs(helper.airZones) do
        if x >= z.x0 and x <= z.x1 and y >= z.y0 and y <= z.y1 then
            return name, z
        end
    end
    return nil
end


function helper.airZoneForTile(tile)
    local x, y = tile.x, tile.y
    for name, zone in pairs(helper.airZones) do
        if x >= zone.x0 and x <= zone.x1 and y >= zone.y0 and y <= zone.y1 then
            return name, zone
        end
    end
    return nil
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
    local order = {"Britain", "France", "NWGermany", "SWGermany", "NEGermany", "SEGermany"}
    for _, key in ipairs(order) do
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