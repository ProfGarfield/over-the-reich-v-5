--
local versionNumber = 1
local fileModified = true -- set this to true if you change this file for your scenario
-- if another file requires this file, it checks the version number to ensure that the
-- version is recent enough to have all the expected functionality
-- if you set fileModified to true, the error generated if this file is out of date will
-- warn you that you've modified this file
--
--
-- Note: See strategicTargetsDocumentation.txt in the LuaDocumentation folder

---@module "generalLibrary"
---@diagnostic disable-next-line: undefined-field
local gen = require("generalLibrary"):minVersion(1)
local strat = require("strategicTargets")
local discreteEvents = require("discreteEventsRegistrar")
local object = require("object")
local traits = require("traits")
local tileData = require("tileData")
local cityData = require("cityData")
local helper = require("helper")
local param = require("parameters")
local keyboard = require("keyboard")

-- This function should return true if the
-- item is a strategicItem (has a target associated with
-- it), and false otherwise
local function isStrategicItem(item)
    return traits.hasTrait(item,"strategicImprovement")
end

-- targetSpecs[improvement.id]
-- targetSpecs[wonder.id+ 40] {
--[[
    * constructionBaseTerrainDayLow = baseTerrainObject or nil
    * constructionBaseTerrainDayHigh = baseTerrainObject or nil
    * constructionBaseTerrainNightLow = baseTerrainObject or nil
    * constructionBaseTerrainNightHigh = baseTerrainObject or nil
    * destructionBaseTerrainDayLow = baseTerrainObject or nil
    * destructionBaseTerrainDayHigh = baseTerrainObject or nil
    * destructionBaseTerrainNightLow = baseTerrainObject or nil
    * destructionBaseTerrainNightHigh = baseTerrainObject or nil
    * targetUnitType = unitTypeObject or true or function(tile,city):unitTypeObject|true
    * captureWithCity = bool or nil
    * targetMap = 0|1|2|3
    * extraTiles = integer|nil
    * inCityRadius = boolean|nil
    * weight = function(tile,city):number|table
    * createRR = boolean|nil
    * destroyRR = boolean|nil
]]

---@class targetSpec
---@field constructionBaseTerrainDayLow baseTerrainObject|nil
---@field constructionBaseTerrainDayHigh baseTerrainObject|nil
---@field constructionBaseTerrainNightLow baseTerrainObject|nil
---@field constructionBaseTerrainNightHigh baseTerrainObject|nil
---@field destructionBaseTerrainDayLow baseTerrainObject|nil
---@field destructionBaseTerrainDayHigh baseTerrainObject|nil
---@field destructionBaseTerrainNightLow baseTerrainObject|nil
---@field destructionBaseTerrainNightHigh baseTerrainObject|nil
---@field targetUnitType unitTypeObject|true|nil|fun(tileObject,cityObject):unitTypeObject|true|nil
---@field captureWithCity boolean|nil
---@field targetMap 0|1|2|3
---@field extraTiles 0|1|2|nil
---@field inCityRadius boolean|nil
---@field weight table|fun(tileObject,cityObject):(number|false)
---@field createRR boolean|nil
---@field destroyRR boolean|nil

---@type table<integer,targetSpec>
local targetSpecs = {}

-- Once a target has been built by a city on a tile, that tile
-- is reserved for that target.  If the target is destroyed,
-- no other target can be built on that tile.
tileData.defineCounter("targetCityID",-1)
tileData.defineCounter("targetImprovementID",-1)

local maxExtraTiles = 5

for improvementID = 0,(39+28) do
    ---@type improvementObject|wonderObject
    local item = civ.getImprovement(improvementID) --[[@as improvementObject]]
    if improvementID >= 40 then
        item = civ.getWonder(improvementID-40) --[[@as wonderObject]]
    end
    if isStrategicItem(item) then
        cityData.defineCounter("reservedTileIDFor"..improvementID,-1)
        for i = 1,maxExtraTiles do
            cityData.defineCounter("reservedTileIDFor"..improvementID.."+"..i,-1)
        end
    end
end

local function getExtendedImprovementID(item)
    if civ.isImprovement(item) then
        return item.id
    end
    if civ.isWonder(item) then
        return item.id+40
    end
    error("item must be an improvement or a wonder")
end

local function isReservedForAnotherTarget(tile,improvement,city)
    if tileData.counterIsNil(tile,"targetImprovementID") then
        return false
    end
    if tileData.counterGetValue(tile,"targetImprovementID") == improvement.id and
        tileData.counterGetValue(tile,"targetCityID") == city.id then
        return false
    end
    return true
end

local function isTileReservedForTarget(tile,item,city)
    if tileData.counterGetValue(tile,"targetImprovementID") == getExtendedImprovementID(item) and
        tileData.counterGetValue(tile,"targetCityID") == city.id then
        return true
    end
    return false
end

local function reserveTileForTarget(tile,improvement,city)
    if isReservedForAnotherTarget(tile,improvement,city) then
        error("tile is already reserved for another target")
    end
    local extendedId = getExtendedImprovementID(improvement)
    tileData.counterSetValue(tile,"targetImprovementID",extendedId)
    tileData.counterSetValue(tile,"targetCityID",city.id)
    if cityData.counterIsNil(city,"reservedTileIDFor"..extendedId) then
        cityData.counterSetValue(city,"reservedTileIDFor"..extendedId,gen.getTileId(tile)--[[@as integer]])
    else
        for i=1,maxExtraTiles do
            if cityData.counterIsNil(city,"reservedTileIDFor"..extendedId.."+"..i) then
                cityData.counterSetValue(city,"reservedTileIDFor"..extendedId.."+"..i,gen.getTileId(tile)--[[@as integer]])
                break
            end
        end
    end
end

local function unreserveTileForTarget(tile)
    if not tileData.counterIsNil(tile,"targetImprovementID") then
        local improvementID = tileData.counter(tile,"targetImprovementID")
        local cityID = tileData.counter(tile,"targetCityID")
        local city = civ.getCity(cityID) --[[@as cityObject]]
        local tileID = gen.getTileId(tile)--[[@as integer]]
        if cityData.counterGetValue(city,"reservedTileIDFor"..improvementID) == tileID then
            cityData.counterReset(city,"reservedTileIDFor"..improvementID)
        else
            for i=1,maxExtraTiles do
                if cityData.counterGetValue(city,"reservedTileIDFor"..improvementID.."+"..i) == tileID then
                    cityData.counterReset(city,"reservedTileIDFor"..improvementID.."+"..i)
                    break
                end
            end
        end
    end
    tileData.counterReset(tile,"targetImprovementID")
    tileData.counterReset(tile,"targetCityID")
end

---Returns a table of reserved tiles for the item
---@param city cityObject
---@param item improvementObject|wonderObject
---@return tileObject[]
local function getReservedTiles(city,item)
    if not isStrategicItem(item) then
        error("item must be a strategic item")
    end
    local extendedId = getExtendedImprovementID(item)
    if cityData.counterIsNil(city,"reservedTileIDFor"..extendedId) then
        return {}
    end
    local reservedTiles = {}
    reservedTiles[1] = gen.getTileFromID(cityData.counterGetValue(city,"reservedTileIDFor"..extendedId))
    for i=1,maxExtraTiles do
        if cityData.counterIsNil(city,"reservedTileIDFor"..extendedId.."+"..i) then
            break
        end
        reservedTiles[i+1] = gen.getTileFromID(cityData.counterGetValue(city,"reservedTileIDFor"..extendedId.."+"..i))
    end
    return reservedTiles
end

local function nearbyTilesOutsideCityRadius(tile,range)
    local possibleNearbyCities = {}
    for city in helper.OTRCityIterator() do
        if gen.tileDist(city.location,tile) <= range+2 then
            possibleNearbyCities[#possibleNearbyCities+1] = city
        end
    end
    local function inCityRadius(tileArg)
        for _,city in pairs(possibleNearbyCities) do
            if helper.isWithinCityRadius(tileArg,city.location) then
                return true
            end
        end
        return false
    end
    local list = {}
    local index = 1
    for _,nearTile in pairs(gen.getTilesInRadius(tile,range)) do
        if not (nearTile.city or inCityRadius(nearTile)) then
            list[index] = nearTile
            index = index + 1
        end
    end
    return list
end

---Chooses the tile(s) to be used for targets
---@param city cityObject
---@param item improvementObject|wonderObject
---@param number integer number of tiles to choose
---@param weightFnOrTable table|fun(tileObject,cityObject):number
---@return tileObject[]
local function chooseTilesForTarget(city,item,number,weightFnOrTable)
    local weightFunction = nil
    if type(weightFnOrTable) == "table" then
        local weightTable = gen.copyTable(weightFnOrTable)
        weightFunction = function(tile,cityArg)
            if isReservedForAnotherTarget(tile,item,cityArg) then
                return false
            end
            return gen.calculateWeight(tile,weightTable,cityArg)
        end
    elseif type(weightFnOrTable) == "function" then
        weightFunction = function(tile,cityArg)
            if isReservedForAnotherTarget(tile,item,cityArg) then
                return false
            end
            return weightFnOrTable(tile,cityArg)
        end
    else
        error("weightFnOrTable must be a function or a table")
    end
    local tileList = getReservedTiles(city,item)
    local numReservedTiles = #tileList
    if numReservedTiles >= number then
        return tileList
    end
    local extendedID = getExtendedImprovementID(item)
    local targetSpec = targetSpecs[extendedID]
    local tileChoice = nil
    if targetSpec.inCityRadius then
        tileChoice = gen.cityRadiusTiles(city)
    else
        tileChoice = nearbyTilesOutsideCityRadius(city.location,param.maxTargetDistanceFromCity)
    end
---@diagnostic disable-next-line: param-type-mismatch
    local bestTiles,weights = gen.getBiggestWeights(tileChoice,weightFunction,number-#tileList,city)
    for i=1,number-numReservedTiles do
        tileList[numReservedTiles+i] = bestTiles[i]
    end
    return tileList
end

local alliedPolygon ={{214,194},{214,172},{225,161},{225,151},{199,151},{199,123},{190,114},{190,98},{201,87},{201,75},{210,66},{210,0},{0,0},{0,194},doesNotCrossThisX=320}

local function cityAlliedAligned(city)
    if city == object.cPrague or city == object.cPilsen then
        return true
    end
    if gen.inPolygon(city.location,alliedPolygon) then
        return true
    end
    return false
end

local function urbanTargetUnitType(tile,city)
    if cityAlliedAligned(city) and city.owner == object.pAllies then
        return object.uUrbanArea
    end
    if not cityAlliedAligned(city) and city.owner == object.pGermans then
        return object.uUrbanArea
    end
    return true
end

local standardWeightFn = function(tile,city)
    if tile.baseTerrain == object.bGrasslandDayLow or
        tile.baseTerrain == object.bHighlandsDayLow then
        return 100
    end
    if tile.baseTerrain == object.bForestDayLow or
        tile.baseTerrain == object.bSwampDayLow or
        tile.baseTerrain == object.bHillsDayLow then
        return 50
    end
    return false
end

--======================================================
--[[ Begin Target Specs ]]--
--======================================================

---@type targetSpec
local housingSpec = {
    constructionBaseTerrainDayLow = object.bUrbanDayLow,
    constructionBaseTerrainDayHigh = object.bUrbanDayHigh,
    constructionBaseTerrainNightLow = object.bUrbanNightLow,
    constructionBaseTerrainNightHigh = object.bUrbanNightHigh,
    destructionBaseTerrainDayLow = object.bUrbanRubbleDayLow,
    destructionBaseTerrainDayHigh = object.bUrbanRubbleDayHigh,
    destructionBaseTerrainNightLow = object.bUrbanRubbleNightLow,
    destructionBaseTerrainNightHigh = object.bUrbanRubbleNightHigh,
    targetUnitType = urbanTargetUnitType,
    captureWithCity = true,
    targetMap = 3,
    extraTiles = 2,
    inCityRadius = true,
    weight = standardWeightFn,
}

targetSpecs[object.iHousingDistrictI.id] = housingSpec
targetSpecs[object.iHousingDistrictII.id] = housingSpec
targetSpecs[object.iHousingDistrictIII.id] = housingSpec

---@type targetSpec
local factorySpec = {
    constructionBaseTerrainDayLow = object.bIndustryDayLow,
    constructionBaseTerrainDayHigh = object.bIndustryDayHigh,
    constructionBaseTerrainNightLow = object.bIndustryNightLow,
    constructionBaseTerrainNightHigh = object.bIndustryNightHigh,
    destructionBaseTerrainDayLow = object.bRubbleDayLow,
    destructionBaseTerrainDayHigh = object.bRubbleDayHigh,
    destructionBaseTerrainNightLow = object.bRubbleNightLow,
    destructionBaseTerrainNightHigh = object.bRubbleNightHigh,
    targetUnitType = nil,
    captureWithCity = true,
    targetMap = 1,
    extraTiles = 0,
    inCityRadius = true,
    weight = standardWeightFn,
}

local engineFactorySpec = gen.copyTable(factorySpec)
engineFactorySpec.targetUnitType = object.uEngineFactory
targetSpecs[object.iEngineFactory.id] = engineFactorySpec

local aircraftFactorySpec = gen.copyTable(factorySpec)
aircraftFactorySpec.targetUnitType = object.uAircraftFactory
targetSpecs[object.iAircraftFactory.id] = aircraftFactorySpec

local avionicsFactorySpec = gen.copyTable(factorySpec)
avionicsFactorySpec.targetUnitType = object.uAvionicsFactory
targetSpecs[object.iAvionicsFactory.id] = avionicsFactorySpec

local powerPlantSpec = {
    constructionBaseTerrainDayLow = object.bPowerPlantDayLow,
    constructionBaseTerrainDayHigh = object.bPowerPlantDayHigh,
    constructionBaseTerrainNightLow = object.bPowerPlantNightLow,
    constructionBaseTerrainNightHigh = object.bPowerPlantNightHigh,
    destructionBaseTerrainDayLow = object.bRubbleDayLow,
    destructionBaseTerrainDayHigh = object.bRubbleDayHigh,
    destructionBaseTerrainNightLow = object.bRubbleNightLow,
    destructionBaseTerrainNightHigh = object.bRubbleNightHigh,
    targetUnitType = object.uElectricPowerPlant,
    captureWithCity = true,
    targetMap = 3,
    extraTiles = 0,
    inCityRadius = false,
    weight = standardWeightFn,
}

targetSpecs[object.iElectricPowerPlantI.id] = powerPlantSpec
targetSpecs[object.iElectricPowerPlantII.id] = powerPlantSpec
targetSpecs[object.iElectricPowerPlantIII.id] = powerPlantSpec

local heavyFlakSpec = {
    constructionBaseTerrainDayLow = nil,
    constructionBaseTerrainDayHigh = nil,
    constructionBaseTerrainNightLow = nil,
    constructionBaseTerrainNightHigh = nil,
    destructionBaseTerrainDayLow = nil,
    destructionBaseTerrainDayHigh = nil,
    destructionBaseTerrainNightLow = nil,
    destructionBaseTerrainNightHigh = nil,
    targetUnitType = function(tile,city)
        if city.owner == object.pGermans then
            return object.u128cmFlak40
        elseif city.owner == object.pAllies then
            return object.u37Flak
        else
            return nil
        end
    end,
    targetMap = 0,
    extraTiles = 0,
    inCityRadius = true,
    weight = standardWeightFn,
}
targetSpecs[object.iHeavyFlakBattery.id] = heavyFlakSpec

-- Only allows grassland/highland adjacent to railroads (on long edge)
-- and not adjacent to a railyard (on any edge)
local function railroadAdjacentWeights(tile,city)
    local x,y = tile.x,tile.y
    local adjacentTiles = {
        civ.getTile(x+1,y+1,0),
        civ.getTile(x+1,y-1,0),
        civ.getTile(x-1,y+1,0),
        civ.getTile(x-1,y-1,0),
    }
    if tile.baseTerrain ~= object.bGrasslandDayLow and
        tile.baseTerrain ~= object.bHighlandsDayLow then
        return false
    end
    for _,adjacentTile in pairs(gen.getAdjacentTiles(tile)) do
        if adjacentTile and tileData.counterGetValue(adjacentTile,"targetImprovementID") == object.iRailyards.id then
            return false
        end
    end
    for _,adjacentTile in pairs(adjacentTiles) do
        if adjacentTile and gen.hasRailroad(adjacentTile) then
            return 100
        end
    end
    return false
end

local function waterOnly(tile,city)
    if tile.baseTerrain ~= object.tWaterDayLow then
        return false
    end
    for _,adjTile in pairs(gen.getAdjacentTiles(tile)) do
        if adjTile.baseTerrain ~= object.tWaterDayLow then
            return 100
        end
    end
    return false
end

targetSpecs[object.iRailyards.id] = {
    targetMap = 0,
    extraTiles = 0,
    inCityRadius = true,
    weight = standardWeightFn,
    targetUnitType = object.uRailyards,
    createRR = true,
    destroyRR = true,
}

targetSpecs[object.iUBoatPens.id] = {
    targetMap = 1,
    extraTiles = 0,
    inCityRadius=false,
    weight = waterOnly,
    targetUnitType = object.uUBoatPens,
}

targetSpecs[object.iPortFacility.id] = {
    targetMap = 1,
    extraTiles = 0,
    inCityRadius=true,
    weight = waterOnly,
    targetUnitType = object.uPortFacility,
}

targetSpecs[object.iConvoyRoutes.id] = {
    targetMap = 0,
    extraTiles = 0,
    inCityRadius = false,
    weight = waterOnly,
    targetUnitType = object.uConvoyRoute,
}

targetSpecs[object.iVWeaponSite.id] = {
    targetMap = 0,
    extraTiles = 0,
    inCityRadius= false,
    weight = standardWeightFn,
    targetUnitType = object.uVWeaponsSite,
}

targetSpecs[object.iFuelStorageSilos.id] = {
    targetMap = 0,
    extraTiles = 0,
    inCityRadius= false,
    weight = railroadAdjacentWeights,
    createRR = true,
    targetUnitType = object.uFuelStorageSilos,
}

targetSpecs[object.iOilRefinery.id] = {
    targetMap = 1,
    extraTiles = 0,
    inCityRadius= false,
    weight = railroadAdjacentWeights,
    createRR = true,
    targetUnitType = object.uOilRefinery,
}

targetSpecs[object.iSyntheticFuelRefinery.id] = {
    targetMap = 1,
    extraTiles = 0,
    inCityRadius= false,
    weight = railroadAdjacentWeights,
    createRR = true,
    targetUnitType = object.uSyntheticFuelRef,
}

targetSpecs[object.iArmamentsFactory.id] = {
    targetMap = 1,
    extraTiles = 0,
    inCityRadius = false,
    weight = standardWeightFn,
    targetUnitType = object.uArmamentsFactory,
}

local mapToSuffix = {
    [0] = "DayLow",
    [1] = "DayHigh",
    [2] = "NightLow",
    [3] = "NightHigh",
}

local function isHousingItem(item)
    return item == object.iHousingDistrictI
        or item == object.iHousingDistrictII
        or item == object.iHousingDistrictIII
end

local function housingTileEffects(city, item)
    local reserved = getReservedTiles(city, item)
    if #reserved < 1 then
        return false
    end
    local listOfAffectedTiles = {}
    local tileIndex = 1
    for map0TileIndex = 1, #reserved do
        local map0Tile = reserved[map0TileIndex]
        for map = 0, 3 do
            local effectTable = {
                tile = civ.getTile(map0Tile.x, map0Tile.y, map),
                constructionBaseTerrain = housingSpec["constructionBaseTerrain" .. mapToSuffix[map]],
                destructionBaseTerrain = housingSpec["destructionBaseTerrain" .. mapToSuffix[map]],
                captureWithCity = true,
                targetUnitType = nil,
            }
            if map == housingSpec.targetMap and map0TileIndex == 1 then
                effectTable.targetUnitType = housingSpec.targetUnitType
                if type(effectTable.targetUnitType) == "function" then
                    effectTable.targetUnitType = effectTable.targetUnitType(effectTable.tile, city)
                end
            end
            listOfAffectedTiles[tileIndex] = effectTable
            tileIndex = tileIndex + 1
        end
    end
    return listOfAffectedTiles
end

local function tileEffectsFunction(city, item)
    if isHousingItem(item) then
        return housingTileEffects(city, item)
    end
    local listOfAffectedTiles = {}
    local extendedID = getExtendedImprovementID(item)
    local targetSpec = targetSpecs[extendedID]
    if not targetSpec then
        return false
    end
    local number = 1 + (targetSpec.extraTiles or 0)
    local map0Tiles = chooseTilesForTarget(city, item, number, targetSpec.weight)
    if #map0Tiles < number then
        return false
    end
    local tileIndex = 1
    for map0TileIndex = 1, number do
        local map0Tile = map0Tiles[map0TileIndex]
        for map = 0, 3 do
            local effectTable = {
                tile = civ.getTile(map0Tile.x, map0Tile.y, map),
            }
            effectTable.constructionBaseTerrain = targetSpec["constructionBaseTerrain" .. mapToSuffix[map]]
            effectTable.destructionBaseTerrain = targetSpec["destructionBaseTerrain" .. mapToSuffix[map]]
            effectTable.captureWithCity = targetSpec.captureWithCity
            effectTable.targetUnitType = nil
            if map == targetSpec.targetMap and map0TileIndex == 1 then
                effectTable.targetUnitType = targetSpec.targetUnitType
            end
            if type(effectTable.targetUnitType) == "function" then
                effectTable.targetUnitType = effectTable.targetUnitType(effectTable.tile, city)
            end
            listOfAffectedTiles[tileIndex] = effectTable
            tileIndex = tileIndex + 1
        end
    end
    return listOfAffectedTiles
end

local constructedTargetLostFunction,
    constructedTargetVerificationFunction,
    constructedRegisterSupplementalConditionsFunction,
    constructedCityProductionEventFunction =
    strat.basicStrategicFunctions(isStrategicItem,tileEffectsFunction)

local function reserveTileForNewTarget(target,city,item)
    local targetTile = target.targetLocation
    if isTileReservedForTarget(targetTile,item,city) then
        return
    end
    if targetTile.z ~= 0 then
        return
    end
    reserveTileForTarget(targetTile,item,city)
end

-- Runs only when YOU (or the AI) actually produce the improvement.
-- Bind scripts must never call gen.cityProduction.
function discreteEvents.onCityProduction(city,item)
    if not civ.isImprovement(item) and not civ.isWonder(item) then
        return
    end
    local ok, extendedID = pcall(getExtendedImprovementID, item)
    if not ok then
        return
    end
    local targetSpec = targetSpecs[extendedID]
    if not targetSpec then
        return
    end
    constructedCityProductionEventFunction(city,item)
    for target in strat.iterateTargets(city) do
        if target.improvement == item and target.targetLocation then
            reserveTileForNewTarget(target,city,item)
            if targetSpec.createRR then
                local x,y = target.targetLocation.x,target.targetLocation.y
                gen.placeRailroad(civ.getTile(x,y,0))
                gen.placeRailroad(civ.getTile(x,y,2))
            end
        end
    end
end

strat.registerTargetLostFn(function(target)
    local tile = target.targetLocation
    local improvement = target.improvement
    local extendedID = getExtendedImprovementID(improvement)
    if targetSpecs[extendedID] and targetSpecs[extendedID].destroyRR then
        if tile then
            local x,y = tile.x,tile.y
            gen.removeTransportation(civ.getTile(x,y,0))
            gen.removeTransportation(civ.getTile(x,y,2))
        end
    end
    constructedTargetLostFunction(target)
end)

strat.registerTargetVerificationFn(constructedTargetVerificationFunction)
constructedRegisterSupplementalConditionsFunction()

local function moveUnitsAfterTargetCreatedOrCapturedFunction(tile,target)
    local owner = target.owner
    for unit in tile.units do
        if unit.owner ~= owner then
            gen.moveUnitAdjacent(unit)
        end
    end
end

strat.registerMoveUnitsAfterTargetCreatedOrCapturedFn(moveUnitsAfterTargetCreatedOrCapturedFunction)

local targetSettings = {}
gen.versionFunctions(targetSettings,versionNumber,fileModified,"MechanicsFiles".."\\".."targetSettings.lua")

local unitToImprovement = {}
unitToImprovement[object.uVWeaponsSite.id] = object.iVWeaponSite
unitToImprovement[object.uFuelStorageSilos.id] = object.iFuelStorageSilos
unitToImprovement[object.uOilRefinery.id] = object.iOilRefinery
unitToImprovement[object.uSyntheticFuelRef.id] = object.iSyntheticFuelRefinery
unitToImprovement[object.uUBoatPens.id] = object.iUBoatPens
unitToImprovement[object.uPortFacility.id] = object.iPortFacility
unitToImprovement[object.uEngineFactory.id] = object.iEngineFactory
unitToImprovement[object.uAircraftFactory.id] = object.iAircraftFactory
unitToImprovement[object.uAvionicsFactory.id] = object.iAvionicsFactory
unitToImprovement[object.u128cmFlak40.id] = object.iHeavyFlakBattery
unitToImprovement[object.u37Flak.id]      = object.iHeavyFlakBattery
unitToImprovement[object.uRailyards.id] = object.iRailyards
unitToImprovement[object.uConvoyRoute.id] = object.iConvoyRoutes
unitToImprovement[object.uElectricPowerPlant.id] = object.iElectricPowerPlantI
unitToImprovement[object.uArmamentsFactory.id]   = object.iArmamentsFactory

local function interpretUnit(unit)
    if unit.type == object.uUrbanArea then
        error("Urban area unit should be interpreted differently")
    end
    if unit.type == object.uElectricPowerPlant then
        local city = unit.homeCity
        if not city then
            return nil
        end
        if cityData.counterIsNil(city,"reservedTileIDFor"..object.iElectricPowerPlantI.id) then
            return object.iElectricPowerPlantI
        end
        if cityData.counterIsNil(city,"reservedTileIDFor"..object.iElectricPowerPlantII.id) then
            return object.iElectricPowerPlantII
        end
        if cityData.counterIsNil(city,"reservedTileIDFor"..object.iElectricPowerPlantIII.id) then
            return object.iElectricPowerPlantIII
        end
    end
    if unitToImprovement[unit.type.id] then
        return unitToImprovement[unit.type.id]
    end
    return nil
end

local function getSetOfUrbanAreaUnits(firstUnit,number)
    local city = firstUnit.homeCity
    local unitList = {firstUnit}
    local index = 1
    for unit in civ.iterateUnits() do
        if unit.type == object.uUrbanArea and unit ~= firstUnit and
        unit.location.z == 0 and helper.isWithinCityRadius(city.location,unit.location) then
            index = index + 1
            unitList[index] = unit
            if index == number then
                return unitList
            end
        end
    end
    return unitList
end

-- z ~= 0 units are combat-layer targets / high-alt Werke. Scan never eats them.
local function isUnitTarget(unit)
    if unit.location.z ~= 0 then
        return true
    end
    for target in strat.iterateTargets() do
        if target.unit == unit then
            return true
        end
    end
    return false
end

-- Reserve tiles from hand-placed map-0 markers. Never produce the improvement.
local function processUnit(unit)
    if isUnitTarget(unit) then
        return
    end
    if unit.type == object.uUrbanArea then
        if not unit.homeCity then
            return
        end
        if not helper.isWithinCityRadius(unit.location,unit.homeCity.location) then
            for map=0,3 do
                local tile = civ.getTile(unit.location.x,unit.location.y,map) --[[@as tileObject]]
---@diagnostic disable-next-line: assign-type-mismatch
                tile.baseTerrain = housingSpec["constructionBaseTerrain"..mapToSuffix[map]]
            end
---@diagnostic disable-next-line: deprecated
            civ.deleteUnit(unit)
            return
        end
        local set = getSetOfUrbanAreaUnits(unit,housingSpec.extraTiles+1)
        local improvement = nil
        if cityData.counterIsNil(unit.homeCity,"reservedTileIDFor"..object.iHousingDistrictI.id) then
            improvement = object.iHousingDistrictI
        elseif cityData.counterIsNil(unit.homeCity,"reservedTileIDFor"..object.iHousingDistrictII.id) then
            improvement = object.iHousingDistrictII
        elseif cityData.counterIsNil(unit.homeCity,"reservedTileIDFor"..object.iHousingDistrictIII.id) then
            improvement = object.iHousingDistrictIII
        else
            for map=0,3 do
                local tile = civ.getTile(unit.location.x,unit.location.y,map) --[[@as tileObject]]
---@diagnostic disable-next-line: assign-type-mismatch
                tile.baseTerrain = housingSpec["constructionBaseTerrain"..mapToSuffix[map]]
            end
---@diagnostic disable-next-line: deprecated
            civ.deleteUnit(unit)
            return
        end
        for _,u in pairs(set) do
            reserveTileForTarget(u.location,improvement,unit.homeCity)
---@diagnostic disable-next-line: deprecated
            civ.deleteUnit(u)
        end
        return
    end
    local improvement = interpretUnit(unit)
    if not improvement then
        return
    end
    local city = unit.homeCity
    if not city then
        return
    end
    local tile = unit.location
    reserveTileForTarget(tile,improvement,city)
---@diagnostic disable-next-line: deprecated
    civ.deleteUnit(unit)
end

local function copyTileImprovements(source,destination)
    if not source.city then
        destination.improvements = source.improvements
    elseif source.city and not destination.city then
        local needsRoad = false
        for _,adjTile in pairs(gen.getAdjacentTiles(source)) do
            if gen.hasRailroad(adjTile) then
                gen.placeRailroad(destination)
                return
            end
            if gen.hasRoad(adjTile) then
                needsRoad = true
            end
        end
        if needsRoad then
            gen.placeRoad(destination)
            return
        end
    elseif source.city and destination.city then
        -- do nothing
    end
end

local function copyTile(x,y,sourceMap,destMap)
    if x % 2 ~= y % 2 then
        return
    end
    local sourceTile = civ.getTile(x,y,sourceMap)
    local destTile = civ.getTile(x,y,destMap)
    if not (sourceTile and destTile) then
        return
    end
    copyTileImprovements(sourceTile,destTile)
    if sourceTile.baseTerrain.type == 2 then
        return
    end
    if destTile.baseTerrain.type == 2 then
        return
    end
    local sourceResource = sourceTile.terrain.resource
    local destTerrain = destTile.baseTerrain:getTerrain(sourceResource)
    destTile.terrain = destTerrain
end

discreteEvents.onKeyPress(function(keyID)
    if keyID == keyboard.backspace then
        civ.getCurrentTile().units().damage = 9
    end
end)

function _G.console.copyMapScript()
    local width,height,maps = civ.getAtlasDimensions()
    for x=0,width-1 do
        if x%30 == 0 then
            print("Working")
        end
        for y=0,height-1 do
            for destMap = 1,3 do
                copyTile(x,y,0,destMap)
            end
        end
    end
end

function _G.console.initialTargetScript()
    for unit in civ.iterateUnits() do
        processUnit(unit)
    end
end

function _G.console.bindPreplacedHousing()
    local function collectUrbanUnitsByCity()
        local byCity = {}
        for unit in civ.iterateUnits() do
            if unit.type == object.uUrbanArea and unit.location.z == 0 and unit.homeCity then
                local id = unit.homeCity.id
                byCity[id] = byCity[id] or { city = unit.homeCity, units = {} }
                local list = byCity[id].units
                list[#list + 1] = unit
            end
        end
        return byCity
    end
    local function tileDist2(a, b)
        local dx = a.location.x - b.location.x
        local dy = a.location.y - b.location.y
        return dx * dx + dy * dy
    end
    local function splitIntoThreeGroups(units, tilesPerImp)
        local remaining = {}
        for i = 1, #units do remaining[i] = units[i] end
        table.sort(remaining, function(a, b)
            if a.location.y == b.location.y then
                return a.location.x < b.location.x
            end
            return a.location.y < b.location.y
        end)
        local groups = { {}, {}, {} }
        for g = 1, 3 do
            local seed = table.remove(remaining, 1)
            groups[g][1] = seed
            while #groups[g] < tilesPerImp and #remaining > 0 do
                table.sort(remaining, function(a, b)
                    return tileDist2(seed, a) < tileDist2(seed, b)
                end)
                groups[g][#groups[g] + 1] = table.remove(remaining, 1)
            end
        end
        return groups, remaining
    end
    local housingImps = {
        object.iHousingDistrictI,
        object.iHousingDistrictII,
        object.iHousingDistrictIII,
    }
    local byCity = collectUrbanUnitsByCity()
    local nCities, nLinked, nBad = 0, 0, 0
    for _, pack in pairs(byCity) do
        local city = pack.city
        local n = #pack.units
        nCities = nCities + 1
        if n % 3 ~= 0 or n < 3 or n > 18 then
            print(string.format("FAIL  %s has %d urban units (need 3, 6, 9, 12, or 18)", city.name, n))
            nBad = nBad + 1
        else
            local tilesPerImp = n / 3
            local groups = select(1, splitIntoThreeGroups(pack.units, tilesPerImp))
            local cityFailed = false
            for g = 1, 3 do
                local imp = housingImps[g]
                for _, u in ipairs(groups[g]) do
                    if isTileReservedForTarget(u.location, imp, city) then
                        civ.deleteUnit(u)
                    else
                        local reservedOk, err = pcall(reserveTileForTarget, u.location, imp, city)
                        if not reservedOk then
                            local existingImp = tileData.counterGetValue(u.location, "targetImprovementID")
                            local existingCity = tileData.counterGetValue(u.location, "targetCityID")
                            print(string.format(
                                "FAIL  %s housing %s at %d,%d already reserved impId=%s cityId=%s (%s)",
                                city.name, imp.name, u.location.x, u.location.y,
                                tostring(existingImp), tostring(existingCity), tostring(err)))
                            cityFailed = true
                            nBad = nBad + 1
                        else
                            civ.deleteUnit(u)
                        end
                    end
                end
                if not cityFailed then
                    nLinked = nLinked + 1
                end
            end
            if not cityFailed then
                print(string.format("OK    %s  %d units -> %d tile(s) reserved each for I/II/III (city NOT given the improvement)",
                    city.name, n, tilesPerImp))
            end
        end
    end
    print(string.format("Done. Cities: %d | reservation groups: %d | bad counts: %d",
        nCities, nLinked, nBad))
    print("No improvements added. Save, then dumpTargetBind.")
end

function _G.console.bindPreplacedOtherTargets()
    local ignoreName = {
        ["Polsten 20mm"] = true,
        ["2cm Flakvierling"] = true,
        ["Chain Home Radar"] = true,
        ["Freya Radar"] = true,
        ["Wurzburg Radar"] = true,
    }
    local nOk, nSkip, nFail = 0, 0, 0
    local toProcess = {}
    for unit in civ.iterateUnits() do
        if unit.location.z == 0 and unit.type ~= object.uUrbanArea then
            toProcess[#toProcess + 1] = unit
        end
    end
    for _, unit in ipairs(toProcess) do
        if ignoreName[unit.type.name] then
            nSkip = nSkip + 1
        else
            local city = unit.homeCity
            if not city then
                print(string.format("FAIL  %s at %d,%d has no homeCity",
                    unit.type.name, unit.location.x, unit.location.y))
                nFail = nFail + 1
            else
                local ok, improvement = pcall(interpretUnit, unit)
                if not ok or not improvement then
                    nSkip = nSkip + 1
                else
                    local reservedOk, err = pcall(reserveTileForTarget, unit.location, improvement, city)
                    if not reservedOk then
                        print(string.format("FAIL  %s %s: %s", city.name, unit.type.name, tostring(err)))
                        nFail = nFail + 1
                    else
                        civ.deleteUnit(unit)
                        nOk = nOk + 1
                    end
                end
            end
        end
    end
    print(string.format("Other targets reserved: %d | skipped: %d | fail: %d",
        nOk, nSkip, nFail))
    print("No improvements added. Save, then console.dumpTargetBind()")
end

function _G.console.dumpTargetBind()
    print("return {")
    for city in civ.iterateCities() do
        for impId = 0, 67 do
            for extra = 0, 5 do
                local key
                if extra == 0 then
                    key = "reservedTileIDFor"..impId
                else
                    key = "reservedTileIDFor"..impId.."+"..extra
                end
                local ok, val = pcall(function()
                    if cityData.counterIsNil(city, key) then
                        return nil
                    end
                    return cityData.counterGetValue(city, key)
                end)
                if ok and val and val >= 0 then
                    local tile = gen.getTileFromID(val)
                    if tile then
                        print(string.format(
                            "  {cityId=%d, city=%q, impId=%d, extra=%q, x=%d, y=%d, z=%d},",
                            city.id, city.name, impId, key, tile.x, tile.y, tile.z))
                    end
                end
            end
        end
    end
    print("}")
end

function _G.console.dumpTargetBindRange(idLo, idHi)
    print("return {")
    for city in civ.iterateCities() do
        if city.id >= idLo and city.id <= idHi then
            for impId = 0, 67 do
                for extra = 0, 5 do
                    local key = (extra == 0)
                        and ("reservedTileIDFor"..impId)
                        or  ("reservedTileIDFor"..impId.."+"..extra)
                    local ok, val = pcall(function()
                        if cityData.counterIsNil(city, key) then return nil end
                        return cityData.counterGetValue(city, key)
                    end)
                    if ok and val and val >= 0 then
                        local tile = gen.getTileFromID(val)
                        if tile then
                            print(string.format(
                                "  {cityId=%d, city=%q, impId=%d, extra=%q, x=%d, y=%d, z=%d},",
                                city.id, city.name, impId, key, tile.x, tile.y, tile.z))
                        end
                    end
                end
            end
        end
    end
    print("}")
end

local function applyTargetBind()
    local ok, bind = pcall(function()
        return require("targetBind")
    end)
    if not ok or type(bind) ~= "table" then
        return
    end
    for _, row in ipairs(bind) do
        local city = civ.getCity(row.cityId)
        local item = civ.getImprovement(row.impId)
        local tile = civ.getTile(row.x, row.y, 0)
        if city and item and tile then
            pcall(reserveTileForTarget, tile, item, city)
        end
    end
end

discreteEvents.onScenarioLoaded(function()
    applyTargetBind()
end)

function _G.console.applyTargetBind()
    applyTargetBind()
end

return targetSettings
