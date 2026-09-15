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
        - change the base terrain on the Low Day Map to this upon construction
        - nil means no change to terrain
    * constructionBaseTerrainDayHigh = baseTerrainObject or nil
        - change the base terrain on the High Day Map to this upon construction
        - nil means no change to terrain
    * constructionBaseTerrainNightLow = baseTerrainObject or nil
        - change the base terrain on the Low Night Map to this upon construction
        - nil means no change to terrain
    * constructionBaseTerrainNightHigh = baseTerrainObject or nil
        - change the base terrain on the High Night Map to this upon construction
        - nil means no change to terrain
    * destructionBaseTerrainDayLow = baseTerrainObject or nil
        - change the base terrain on the Low Day Map to this upon destruction
        - nil means no change to terrain
    * destructionBaseTerrainDayHigh = baseTerrainObject or nil
        - change the base terrain on the High Day Map to this upon destruction
        - nil means no change to terrain
    * destructionBaseTerrainNightLow = baseTerrainObject or nil
        - change the base terrain on the Low Night Map to this upon destruction
        - nil means no change to terrain
    * destructionBaseTerrainNightHigh = baseTerrainObject or nil
        - change the base terrain on the High Night Map to this upon destruction
        - nil means no change to terrain
    * targetUnitType = unitTypeObject or true or function(tile,city):unitTypeObject|true
        - if unitTypeObject, create a target with that unit type
          on this tile.
        - true means create a 'target' without a unit, for example
          if you want to tie a terrain change to whether or not
          the item is still in the city
        - function(tile,city):unitTypeObject|true
          if a function, returns the unitTypeObject or true
          for the target on this tile
    * captureWithCity = bool or nil
        - if true, the target on this tile is captured with the city
          provided the item is still intact.  False or nil means it
          is destroyed instead.
    * targetMap = 0|1|2|3
        - the map on which the target is placed
    * extraTiles = integer|nil
        - this many extra tiles will have their terrain changed with the target
    * inCityRadius = boolean|nil
        - If true, the target is placed in the city radius,
        - If false or nil, the target is placed outside the city radius
    * weight = function(tile,city):number|table
        - Used to calculate the "weight" of a tile (higher is better) when choosing
          a tile for the target.  The weight is used to choose the tile for the target
        - if a function, returns the weight of the tile for the target
        - if a table, the table is passed to gen.calculateWeight
        - if nil, the weight is 0
    * createRR = boolean|nil
        - if true, a railroad is created on the tile when the target is built
    * destroyRR = boolean|nil
        - if true, a railroad is destroyed on the tile when the target is destroyed
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
-- ID number of the city that built the target
tileData.defineCounter("targetCityID",-1)
-- ID number of the improvement that was the target; -1 if no target; wonderID+40 if wonder
tileData.defineCounter("targetImprovementID",-1)

local maxExtraTiles = 2

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
        tileData.counter(tile,"targetCityID") == city.id then
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
    for _,tile in pairs(gen.getTilesInRadius(tile,range)) do
        if not (tile.city or inCityRadius(tile)) then
            list[index] = tile
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

-- Returns true if the city is "aligned" with the Allies,
-- and so would be occupied if the Germans own it.
-- Returns false if the city is "aligned" with the Germans,
-- and so would be occupied if the Allies own it.
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
--======================================================


--[[ Begin Target Specs ]]--


--======================================================
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
            error("Someone other than the Allies or Germany is building a heavy flak battery")
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
        if tileData.counterGetValue(tile,"targetImprovementID") == object.iRailyards.id then
            return false
        end
    end
    for _,adjacentTile in pairs(adjacentTiles) do
        if gen.hasRailroad(adjacentTile) then
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

 
-- tileEffectsFunction(city,item) --> false or table of
--    {
--      tile = tileObject
--        a tile where something will happen
--      constructionBaseTerrain = baseTerrainObject or nil
--        change the base terrain to this upon construction
--        nil means no change to terrain
--      constructionResource = 0,1,2 or nil
--        change the terrain resource to this upon construction
--        nil means no change to the resource
--        (ignored if grassland is the baseTerrain of the tile,
--         after the constructionBaseTerrain change is made)
--      destructionBaseTerrain = baseTerrainObject or nil
--        change the base terrain of the tile to this
--        when the target is destroyed
--        nil means no change to the terrain
--      destructionResource = 0,1,2, or nil
--        change the terrain resource to this upon target destruction
--        nil means no change to the resource
--        (ignored if grassland is the baseTerrain of the tile,
--         after the destructionBaseTerrain change is made)
--      targetUnitType = unitTypeObject or true or nil
--        if unitTypeObject, create a target with that unit type
--        on this tile.  nil means no target on this tile.
--        true means create a 'target' without a unit, for example
--        if you want to tie a terrain change to whether or not
--        the item is still in the city
--      captureWithCity = bool or nil
--        if true, the target on this tile is caputured with the city
--        provided the item is still intact.  False or nil means it
--        is destroyed instead.  For basicStrategicFunctions,
--        if any target is destroyed, the item is removed, so all
--        other targets will be destroyed.  If you want a target
--        to be captured, all the targets for the item should be true
--    }
--  return false if the item can't be constructed in the city
--  (this will only be called on items where isStrategicItemFn(item) returns true)

local mapToSuffix = {
    [0] = "DayLow",
    [1] = "DayHigh",
    [2] = "NightLow",
    [3] = "NightHigh",
}

local function tileEffectsFunction(city,item)
    local listOfAffectedTiles = {}
    local extendedID = getExtendedImprovementID(item)
    local targetSpec = targetSpecs[extendedID]
    local number = 1 + (targetSpec.extraTiles or 0)
    local map0Tiles = chooseTilesForTarget(city,item,number,targetSpec.weight)
    if #map0Tiles < number then
        return false
    end
    local tileIndex = 1
    for map0TileIndex=1,number do
        local map0Tile = map0Tiles[map0TileIndex]
        for map = 0,3 do
            local effectTable = {
                tile = civ.getTile(map0Tile.x,map0Tile.y,map),
            }
            effectTable.constructionBaseTerrain = targetSpec["constructionBaseTerrain"..mapToSuffix[map]]
            effectTable.destructionBaseTerrain = targetSpec["destructionBaseTerrain"..mapToSuffix[map]]
            effectTable.captureWithCity = targetSpec.captureWithCity
            effectTable.targetUnitType = nil
            if map == targetSpec.targetMap and map0TileIndex == 1 then
                effectTable.targetUnitType = targetSpec.targetUnitType
            end
            if type(effectTable.targetUnitType) == "function" then
                effectTable.targetUnitType = effectTable.targetUnitType(effectTable.tile,city)
            end
            listOfAffectedTiles[tileIndex] = effectTable
            tileIndex = tileIndex + 1
        end
    end
    return listOfAffectedTiles


    --[[
    return {
        {
            tile = civ.getTile(0,0,0),
            constructionBaseTerrain = civ.getBaseTerrain(0,0),
            constructionResource = nil,
            destructionBaseTerrain = civ.getBaseTerrain(0,1),
            destructionResource = nil,
            targetUnitType = civ.getUnitType(0),
            captureWithCity = false,
        },
        {
            tile = civ.getTile(0,0,0),
            constructionBaseTerrain = nil,
            constructionResource = 1,
            destructionBaseTerrain = nil,
            destructionResource = 0,
            targetUnitType = nil,
            captureWithCity = false,
        },
    }
    --]]
end



-- use the basic constructor
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


-- We need to create the target when an item is
-- produced (perhaps at other times as well)
function discreteEvents.onCityProduction(city,item)
    constructedCityProductionEventFunction(city,item)
    local extendedID = getExtendedImprovementID(item)
    local targetSpec = targetSpecs[extendedID]
    for target in strat.iterateTargets(city) do
        if target.improvement == item and target.targetLocation then
            reserveTileForNewTarget(target,city,item)
            if targetSpec.createRR then
                local x,y = target.targetLocation.x,target.targetLocation.y
                for i=0,3 do
                    gen.placeRailroad(civ.getTile(x,y,i)--[[@as tileObject]])

                end
            end
        end
    end
end



-- The registered is run (once) when a target
-- is destroyed
--[[
local function targetLostFunction(target)
  
end
]]

strat.registerTargetLostFn(function(target)
    local tile = target.targetLocation
    local improvement = target.improvement
    local extendedID = getExtendedImprovementID(improvement)
    if targetSpecs[extendedID].destroyRR then
        if tile then
            local x,y = tile.x,tile.y
            for i=0,3 do
                gen.removeTransportation(civ.getTile(x,y,i)--[[@as tileObject]])
            end
        end
    end
    constructedTargetLostFunction(target)
end)



-- strat.verifyTarget(target) reviews a target, and determines if it is
-- still "valid". Returns true if it is, and false if it is not.
-- If false is returned, the target is destroyed.
-- The target is automatically destroyed if the target unit is missing,
-- a city is registered for the target, but the city doesn't exist,
-- if there is an improvement (or wonder) registered, but the registered
-- city no longer has that improvement or if the registered city has
-- a different owner than the target, and the target is not captured
-- with the city (if it is captured with the city, but ownerhsip hasn't
-- changed yet, it is done at this time).

-- Add additional target verification steps in the function below
-- return true if the target should remain in place, and
-- return false if it should be destroyed
--[[
local function targetVerificationFunction(target)
    return true
end
--]]
strat.registerTargetVerificationFn(constructedTargetVerificationFunction)

-- register the supplemental building conditions
constructedRegisterSupplementalConditionsFunction()

-- This function governs what happens when a target is
-- created or captured
-- while there are other units on the tile
-- The targets have changed owners when this function is executed
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


local function interpretUnit(unit)
    if unit.type == object.uUrbanArea then
        error("Urban area unit should be interpreted differently")
    end
    if unit.type == object.uElectricPowerPlant then
        local city = unit.homeCity
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

-- checks if a unit is a target (or otherwise shouldn't
-- be processed)
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

local function processUnit(unit)
    if isUnitTarget(unit) then
        return
    end
    if unit.type == object.uUrbanArea then
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
        gen.cityProduction(unit.homeCity,improvement)
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
    if unit.damage > 0 or unit.veteran then
---@diagnostic disable-next-line: deprecated
        civ.deleteUnit(unit)
        return
    end
    gen.cityProduction(city,improvement)
---@diagnostic disable-next-line: deprecated
    civ.deleteUnit(unit)
end



local function copyTileImprovements(source,destination)
    if not source.city then
        -- in this game, no city on source tile means non on dest tile
        destination.improvements = source.improvements
    elseif source.city and not destination.city then
        -- must copy road/rail if there are any on adjacent tiles
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


return targetSettings

