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

local gen = require("generalLibrary"):minVersion(1)
local strat = require("strategicTargets")
local discreteEvents = require("discreteEventsRegistrar")
local object = require("object")
local traits = require("traits")
local factoryAirfield = require("factoryAirfield")
local helper = require("helper")



-- This function should return true if the
-- item is a strategicItem (has a target associated with
-- it), and false otherwise

local function isStrategicItem(item)
    if item == object.iCriticalIndustry or civ.isUnit(item) then
        return false
    end
    return traits.hasTrait(item,"strategicImprovement")
end

-- strategicItemTerrainWeights[improvement.id]
--  strategicItemTerrainWeights[wonder.id+40]
-- gives the weight tables
-- for each terrain square, the weight tables satisfying gen.calculateWeight:
-- Largest weight(s) get the terrain change/improvement
-- extraArgument is the city
--
-- gen.calculateWeight(item,weightTable,extraArgument=nil) --> number or false
-- weightTable has functions as keys, and numbers or false as values
--      {[keyFunc(item,extraArgument)-->boolean] = number or boolean or string or function(item) -> number}
--      for each key in the weight table, apply keyFunc to the item
--      if keyFunc(item,extraArgument) then
--          if the value is a number, add the number to the weight
--          if the value is a string add item[value] to the weight
--          if the value is a function, add value(item,extraArgument) to the weight
--          if the value is false, return 'false' as the weight
--          if the value is true, do nothing
--      else
--          if the value is a number, do nothing
--          if the value is false, do nothing
--          if the value is a string, do nothing
--          if the value is true, return 'false' as the weight
--      
--      That is, false means that keyFunc must not apply to the item
--      while true means that keyFunc must apply to the item
--
--      default weight is 0
--
local function makeIsBaseTerrain(bTerrain)
    return function(tile,extraArg) return tile.baseTerrain == bTerrain end
end
local function hasSwitchyard(tile,extraArg)
    return gen.hasTransporter(tile)
end
local function hasFuelDump(tile,extraArg)
    return gen.hasRoad(tile)
end
--  Breaks ties between tiles
local tieBreakerMemo = {[0]={[0]=false}}
local function makeTieBreakerMemo(lastI,radius,lastIndex,maxRadius)
    local i=lastI+1
    if i >= radius then
        i=0
        radius = radius+2
        if radius > maxRadius then
            return
        end
    end
    tieBreakerMemo[radius-i] = tieBreakerMemo[radius-i] or {}
    tieBreakerMemo[-i] = tieBreakerMemo[-i] or {}
    tieBreakerMemo[-radius+i] = tieBreakerMemo[-radius+i] or {}
    tieBreakerMemo[i] = tieBreakerMemo[i] or {}
    tieBreakerMemo[radius-i][i] = lastIndex+1
    tieBreakerMemo[-i][radius-i] = lastIndex+2
    tieBreakerMemo[-radius+i][-i] = lastIndex+3
    tieBreakerMemo[i][-radius+i] = lastIndex+4
    return makeTieBreakerMemo(i,radius,lastIndex+4,maxRadius)
end
makeTieBreakerMemo(0,0,0,10) -- nothing will be more than 5 squares from city

local function tieBreaker(tile,city)
    local x = city.x - tile.x
    local y = city.y - tile.y
    --local tbm = tieBreakerMemo[x][y]
    --print(tbm,x,y)
    return tieBreakerMemo[x][y] and -tieBreakerMemo[x][y]
end
local function returnTrue(tile,city) return true end

local strategicItemTerrainWeightTables = {}



-- Civilian Population Target Data

local civilianPopulationWeightTable = {
    [makeIsBaseTerrain(object.bCityLowBase)] = false,
    [makeIsBaseTerrain(object.bRailtrackLowBase)] = 1000,
    [makeIsBaseTerrain(object.bGrasslandLowBase)] = 2000,
    [makeIsBaseTerrain(object.bForestLowBase)] = 1000,
    [makeIsBaseTerrain(object.bUrbanLowBase)] = 500,
    [makeIsBaseTerrain(object.bHillsLowBase)] = 500,
    [makeIsBaseTerrain(object.bRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bInstallationLowBase)] = false,
    [makeIsBaseTerrain(object.bIndustryLowBase)] = false,
    [makeIsBaseTerrain(object.bAirfieldLowBase)] = false,
    [makeIsBaseTerrain(object.bWaterLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRRLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedUrbanLowBase)] = 10000,
    [makeIsBaseTerrain(object.bBombedIndustryLowBase)] = false,
    [makeIsBaseTerrain(object.bResidentialLowBase)] = false,
    [hasSwitchyard] = false,
    [hasFuelDump] = -2000,
    [returnTrue] = tieBreaker,
    [helper.inOTRCityRadius] = -5000,
}
strategicItemTerrainWeightTables[object.iCivilianPopulationI.id] = civilianPopulationWeightTable
strategicItemTerrainWeightTables[object.iCivilianPopulationII.id] = civilianPopulationWeightTable
strategicItemTerrainWeightTables[object.iCivilianPopulationIII.id] = civilianPopulationWeightTable




-- Refinery Target Data

local refineryWeightTable = {
    [makeIsBaseTerrain(object.bCityLowBase)] = false,
    [makeIsBaseTerrain(object.bRailtrackLowBase)] = 3000,
    [makeIsBaseTerrain(object.bGrasslandLowBase)] = 2000,
    [makeIsBaseTerrain(object.bForestLowBase)] = 2000,
    [makeIsBaseTerrain(object.bUrbanLowBase)] = 500,
    [makeIsBaseTerrain(object.bHillsLowBase)] = 500,
    [makeIsBaseTerrain(object.bRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bInstallationLowBase)] = false,
    [makeIsBaseTerrain(object.bIndustryLowBase)] = false,
    [makeIsBaseTerrain(object.bAirfieldLowBase)] = false,
    [makeIsBaseTerrain(object.bWaterLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRRLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRefineryLowBase)] = 10000,
    [makeIsBaseTerrain(object.bBombedUrbanLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedIndustryLowBase)] = false,
    [makeIsBaseTerrain(object.bResidentialLowBase)] = false,
    [hasSwitchyard] = false,
    [hasFuelDump] = 2000,
    [returnTrue] = tieBreaker,
    [helper.inOTRCityRadius] = -5000,
}
strategicItemTerrainWeightTables[object.iFuelRefineryI.id] = refineryWeightTable
strategicItemTerrainWeightTables[object.iFuelRefineryII.id] = refineryWeightTable
strategicItemTerrainWeightTables[object.iFuelRefineryIII.id] = refineryWeightTable






-- Industry Target Data
--
local industryWeightTable = {
    [makeIsBaseTerrain(object.bCityLowBase)] = false,
    [makeIsBaseTerrain(object.bRailtrackLowBase)] = 3000,
    [makeIsBaseTerrain(object.bGrasslandLowBase)] = 2000,
    [makeIsBaseTerrain(object.bForestLowBase)] = 2000,
    [makeIsBaseTerrain(object.bUrbanLowBase)] = 500,
    [makeIsBaseTerrain(object.bHillsLowBase)] = 500,
    [makeIsBaseTerrain(object.bRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bInstallationLowBase)] = false,
    [makeIsBaseTerrain(object.bIndustryLowBase)] = false,
    [makeIsBaseTerrain(object.bAirfieldLowBase)] = false,
    [makeIsBaseTerrain(object.bWaterLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRRLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedUrbanLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedIndustryLowBase)] = 10000,
    [makeIsBaseTerrain(object.bResidentialLowBase)] = false,
    [hasSwitchyard] = false,
    [hasFuelDump] = -2000,
    [returnTrue] = tieBreaker,
    [helper.inOTRCityRadius] = -5000,
}
strategicItemTerrainWeightTables[object.iIndustryI.id] = industryWeightTable
strategicItemTerrainWeightTables[object.iIndustryII.id] = industryWeightTable
strategicItemTerrainWeightTables[object.iIndustryIII.id] = industryWeightTable



local railyardTiles = {
[gen.getTileID(object.lBerlin)] = civ.getTile(356,68,0),
[gen.getTileID(object.lDresden)] = civ.getTile(368,82,0),
[gen.getTileID(object.lPrague)] = civ.getTile(370,98,0),
[gen.getTileID(object.lVienna)] = civ.getTile(394,116,0),
[gen.getTileID(object.lLeipzig)] = civ.getTile(358,90,0),
[gen.getTileID(object.lMerseburg)] = civ.getTile(342,84,0),
[gen.getTileID(object.lRostock)] = civ.getTile(346,60,0),
[gen.getTileID(object.lLneburg)] = civ.getTile(329,71,0),
[gen.getTileID(object.lHannover)] = civ.getTile(314,80,0),
[gen.getTileID(object.lBremen)] = civ.getTile(305,63,0),
[gen.getTileID(object.lWilhelmshaven)] = civ.getTile(294,66,0),
[gen.getTileID(object.lDsseldorf)] = civ.getTile(264,72,0),
[gen.getTileID(object.lCologne)] = civ.getTile(269,89,0),
[gen.getTileID(object.lEssen)] = civ.getTile(286,74,0),
[gen.getTileID(object.lDortmund)] = civ.getTile(283,91,0),
[gen.getTileID(object.lHamburg)] = civ.getTile(315,63,0),
[gen.getTileID(object.lKiel)] = civ.getTile(327,53,0),
[gen.getTileID(object.lLbeck)] = civ.getTile(336,62,0),
[gen.getTileID(object.lNurnburg)] = civ.getTile(329,99,0),
[gen.getTileID(object.lMunich)] = civ.getTile(336,116,0),
[gen.getTileID(object.lFriedrichshaven)] = civ.getTile(305,121,0),
[gen.getTileID(object.lSchweinfurt)] = civ.getTile(312,104,0),
[gen.getTileID(object.lFrankfurt)] = civ.getTile(294,88,0),
[gen.getTileID(object.lAarhus)] = civ.getTile(320,32,0),
[gen.getTileID(object.lFreiburg)] = civ.getTile(282,110,0),
[gen.getTileID(object.lKarlsruhe)] = civ.getTile(283,99,0),
[gen.getTileID(object.lMannheim)] = civ.getTile(295,103,0),
[gen.getTileID(object.lStuttgart)] = civ.getTile(298,116,0),
[gen.getTileID(object.lRegensburg)] = civ.getTile(337,109,0),
[gen.getTileID(object.lLinz)] = civ.getTile(378,122,0),
[gen.getTileID(object.lBrest)] = civ.getTile(102,98,0),
[gen.getTileID(object.lStNazaire)] = civ.getTile(122,102,0),
[gen.getTileID(object.lNantes)] = civ.getTile(131,105,0),
[gen.getTileID(object.lLaRochelle)] = civ.getTile(126,118,0),
[gen.getTileID(object.lBordeaux)] = civ.getTile(144,136,0),
[gen.getTileID(object.lCherbourg)] = civ.getTile(146,96,0),
[gen.getTileID(object.lLeHavre)] = civ.getTile(170,90,0),
[gen.getTileID(object.lTours)] = civ.getTile(165,111,0),
[gen.getTileID(object.lRouen)] = civ.getTile(183,93,0),
[gen.getTileID(object.lParis)] = civ.getTile(199,93,0),
[gen.getTileID(object.lBrussels)] = civ.getTile(240,84,0),
[gen.getTileID(object.lAmsterdam)] = civ.getTile(241,67,0),
[gen.getTileID(object.lTheHague)] = civ.getTile(236,74,0),
[gen.getTileID(object.lRotterdam)] = civ.getTile(252,68,0),
[gen.getTileID(object.lAntwerp)] = civ.getTile(223,83,0),
[gen.getTileID(object.lLille)] = civ.getTile(206,88,0),
[gen.getTileID(object.lCalais)] = civ.getTile(200,86,0),
[gen.getTileID(object.lLyon)] = civ.getTile(225,123,0),
[gen.getTileID(object.lBrunswick)] = civ.getTile(343,69,0),
[gen.getTileID(object.lPeenemnde)] = civ.getTile(371,63,0),
[gen.getTileID(object.lLondon)] = civ.getTile(170,56,0),
[gen.getTileID(object.lPortsmouth)] = civ.getTile(151,69,0),
[gen.getTileID(object.lBristol)] = civ.getTile(138,70,0),
[gen.getTileID(object.lSwansea)] = civ.getTile(123,61,0),
[gen.getTileID(object.lPlymouth)] = civ.getTile(120,70,0),
[gen.getTileID(object.lCardiff)] = civ.getTile(136,62,0),
[gen.getTileID(object.lLiverpool)] = civ.getTile(141,49,0),
[gen.getTileID(object.lBirmingham)] = civ.getTile(162,56,0),
[gen.getTileID(object.lManchester)] = civ.getTile(158,46,0),
[gen.getTileID(object.lNottingham)] = civ.getTile(175,51,0),
[gen.getTileID(object.lSheffield)] = civ.getTile(174,40,0),
[gen.getTileID(object.lColchester)] = civ.getTile(187,65,0),
[gen.getTileID(object.lHull)] = civ.getTile(177,41,0),
[gen.getTileID(object.lNewcastle)] = civ.getTile(167,21,0),
[gen.getTileID(object.lEdinburgh)] = civ.getTile(158,14,0),
[gen.getTileID(object.lGlasgow)] = civ.getTile(142,12,0),
[gen.getTileID(object.lBelfast)] = civ.getTile(108,20,0),
[gen.getTileID(object.lCarlisle)] = civ.getTile(155,21,0),
[gen.getTileID(object.lLeeds)] = civ.getTile(164,36,0),
[gen.getTileID(object.lDover)] = civ.getTile(181,73,0),
[gen.getTileID(object.lVerdun)] = civ.getTile(258,106,0),
}

-- Military Port Target Data
--
local MilitaryPortWeightTable = {
    [makeIsBaseTerrain(object.bCityLowBase)] = false,
    [makeIsBaseTerrain(object.bRailtrackLowBase)] = false,
    [makeIsBaseTerrain(object.bGrasslandLowBase)] = false,
    [makeIsBaseTerrain(object.bForestLowBase)] = false,
    [makeIsBaseTerrain(object.bUrbanLowBase)] = false,
    [makeIsBaseTerrain(object.bHillsLowBase)] = false,
    [makeIsBaseTerrain(object.bRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bInstallationLowBase)] = false,
    [makeIsBaseTerrain(object.bIndustryLowBase)] = false,
    [makeIsBaseTerrain(object.bAirfieldLowBase)] = false,
    [makeIsBaseTerrain(object.bWaterLowBase)] = 100,
    [makeIsBaseTerrain(object.bBombedRRLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedUrbanLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedIndustryLowBase)] = false,
    [makeIsBaseTerrain(object.bResidentialLowBase)] = false,
    [hasSwitchyard] = false,
    [hasFuelDump] = 0,
    [returnTrue] = tieBreaker,
    [helper.inOTRCityRadius] = -5000,
}
strategicItemTerrainWeightTables[object.iMilitaryPort.id] = MilitaryPortWeightTable


-- Aircraft Factory Target Data

-- aircraftFactoryInCityRadius[gen.getTileID(city.location)] = number
--      The number is the number of aircraft factories that should be in
--      the normal city radius
--      nil means all aircraft factories outside the radius
local aircraftFactoryInCityRadius = {
[gen.getTileID(object.lCologne)] = 2,
[gen.getTileID(object.lKiel)] = 1,
[gen.getTileID(object.lLbeck)] = 1,
[gen.getTileID(object.lFriedrichshaven)] = 3,
[gen.getTileID(object.lSchweinfurt)] = 2,
[gen.getTileID(object.lFrankfurt)] = 2,
[gen.getTileID(object.lKarlsruhe)] = 3,
[gen.getTileID(object.lStuttgart)] = 3,
[gen.getTileID(object.lBrest)] = 1,
[gen.getTileID(object.lRouen)] = 2,
[gen.getTileID(object.lParis)] = 3,
[gen.getTileID(object.lBrussels)] = 3,
[gen.getTileID(object.lTheHague)] = 3,
[gen.getTileID(object.lRotterdam)] = 3,
[gen.getTileID(object.lAntwerp)] = 3,
[gen.getTileID(object.lPeenemnde)] = 1,
[gen.getTileID(object.lLondon)] = 3,
[gen.getTileID(object.lBirmingham)] = 2,
[gen.getTileID(object.lSheffield)] = 2,
[gen.getTileID(object.lCarlisle)] = 1,
}

local AircraftFactoryInRadiusWeightTable = {
    [makeIsBaseTerrain(object.bCityLowBase)] = false,
    [makeIsBaseTerrain(object.bRailtrackLowBase)] = 500,
    [makeIsBaseTerrain(object.bGrasslandLowBase)] = 1000,
    [makeIsBaseTerrain(object.bForestLowBase)] = 1000,
    [makeIsBaseTerrain(object.bUrbanLowBase)] = 400,
    [makeIsBaseTerrain(object.bHillsLowBase)] = 800,
    [makeIsBaseTerrain(object.bRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bInstallationLowBase)] = false,
    [makeIsBaseTerrain(object.bIndustryLowBase)] = false,
    [makeIsBaseTerrain(object.bAirfieldLowBase)] = false,
    [makeIsBaseTerrain(object.bWaterLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRRLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedUrbanLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedIndustryLowBase)] = 10000,
    [makeIsBaseTerrain(object.bResidentialLowBase)] = false,
    [hasSwitchyard] = false,
    [hasFuelDump] = -200,
    [returnTrue] = tieBreaker,
    [helper.inOTRCityRadius] = false,
}




local function aircraftFactorySpecialWeight(tile,constructingCity)
    if type(tieBreaker(tile,constructingCity) ) ~= "number" then
        return false
    end
    if tile.baseTerrain == object.bBombedIndustryLowBase and
        factoryAirfield.getLinkedAirfield(tile) then
        return 10000000+tieBreaker(tile,constructingCity)
    end

    local airfieldWeight = 0 -- value of nearby airfield/potential airfield (max)
    local otherWeight = 0 -- value of other features of the tile (additive)
    if gen.hasMine(tile) or gen.hasAgriculture(tile) then
        otherWeight = otherWeight - 5000 -- discourage placing aircraft factories on decorated tiles
    end
    if tile.baseTerrain == object.bBombedIndustryLowBase then
        otherWeight = otherWeight + 100000
    end
    for _,nearbyTile in pairs(gen.cityRadiusTiles(tile)) do
        if factoryAirfield.needsAircraftFactory(nearbyTile.city) then
            if helper.adjacentBaseTerrain(nearbyTile,object.bRailtrackLowBase) then
                airfieldWeight = math.max(airfieldWeight,200000) -- existing airfield with railroad access
            else
                airfieldWeight = math.max(airfieldWeight,100000) -- existing airfield without railroad access
            end
        elseif not nearbyTile.city and not helper.isAirfieldForbidden(nearbyTile) then
            if helper.adjacentBaseTerrain(nearbyTile,object.bRailtrackLowBase) then
                airfieldWeight = math.max(airfieldWeight,90000) -- possible airfield with railroad access
                --otherWeight = otherWeight+500
            else
                airfieldWeight = math.max(airfieldWeight,10000) -- possible airfield without railroad access
            end
        elseif nearbyTile.city then
            -- not an OTRCity, since that is excluded elsewhere
            -- try to place AC factories away from airfields that don't need them
            otherWeight = otherWeight - 1000
        elseif nearbyTile.baseTerrain == object.bIndustryLowBase 
        or nearbyTile.baseTerrain == object.bBombedIndustryLowBase then
            -- try to place AC factories away from other factories
            otherWeight = otherWeight - 1000
        --elseif helper.isAirfieldForbidden(nearbyTile) then
        --    otherWeight = otherWeight - 500
        end
    end
    return airfieldWeight+otherWeight+tieBreaker(tile,constructingCity)
end

local AircraftFactoryOutsideRadiusWeightTable = {
    [makeIsBaseTerrain(object.bCityLowBase)] = false,
    [makeIsBaseTerrain(object.bRailtrackLowBase)] = false,
    [makeIsBaseTerrain(object.bGrasslandLowBase)] = 3000,
    [makeIsBaseTerrain(object.bForestLowBase)] = 2000,
    [makeIsBaseTerrain(object.bUrbanLowBase)] = 0,
    [makeIsBaseTerrain(object.bHillsLowBase)] = 2000,
    [makeIsBaseTerrain(object.bRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bInstallationLowBase)] = false,
    [makeIsBaseTerrain(object.bIndustryLowBase)] = false,
    [makeIsBaseTerrain(object.bAirfieldLowBase)] = false,
    [makeIsBaseTerrain(object.bWaterLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRRLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedUrbanLowBase)] = false,
    --[makeIsBaseTerrain(object.bBombedIndustryLowBase)] = 10000,
    [makeIsBaseTerrain(object.bResidentialLowBase)] = false,
    [hasSwitchyard] = false,
    [hasFuelDump] = -2000,
    [returnTrue] = aircraftFactorySpecialWeight,
    [helper.inOTRCityRadius] = false,
}

local aircraftFactoryMaxRadius = 5

--strategicItemTerrainWeightTables[object.iAircraftFactoryI.id] = AircraftFactoryWeightTable
--strategicItemTerrainWeightTables[object.iAircraftFactoryII.id] = AircraftFactoryWeightTable
--strategicItemTerrainWeightTables[object.iAircraftFactoryIII.id] = AircraftFactoryWeightTable


--[[
local emptyWeightTable = {
    [makeIsBaseTerrain(object.bCityLowBase)] = false,
    [makeIsBaseTerrain(object.bRailtrackLowBase)] = false,
    [makeIsBaseTerrain(object.bGrasslandLowBase)] = false,
    [makeIsBaseTerrain(object.bForestLowBase)] = false,
    [makeIsBaseTerrain(object.bUrbanLowBase)] = false,
    [makeIsBaseTerrain(object.bHillsLowBase)] = false,
    [makeIsBaseTerrain(object.bRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bInstallationLowBase)] = false,
    [makeIsBaseTerrain(object.bIndustryLowBase)] = false,
    [makeIsBaseTerrain(object.bAirfieldLowBase)] = false,
    [makeIsBaseTerrain(object.bWaterLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRRLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedRefineryLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedUrbanLowBase)] = false,
    [makeIsBaseTerrain(object.bBombedIndustryLowBase)] = false,
    [makeIsBaseTerrain(object.bResidentialLowBase)] = false,
    [hasSwitchyard] = false,
    [hasFuelDump] = false,
    [returnTrue] = tieBreaker,
}
--]]


-- Extra Tiles changed for improvement
local extraTileTargets = {
    [object.iCivilianPopulationI.id] = 1,
    [object.iCivilianPopulationII.id] = 1,
    [object.iCivilianPopulationIII.id] = 1,
}

local aircraftFactories = {
    [object.iAircraftFactoryI.id] = 1,
    [object.iAircraftFactoryII.id] = 2,
    [object.iAircraftFactoryIII.id] = 3,
}

local function getMapZeroTargetTiles(city,item)
    -- railyards are special
    if item == object.iRailyards then
        return {railyardTiles[gen.getTileID(city.location)]}
    end
    local itemID = item.id
    if civ.isWonder(item) then
        itemID = itemID+40
    end
    local weightTable = {}
    local extraTiles = extraTileTargets[item.id] or 0
    local searchTiles = {}
    if aircraftFactories[item.id] then
        local factoriesInRadius = aircraftFactoryInCityRadius[gen.getTileID(city.location)] or 0
        if aircraftFactories[item.id] > factoriesInRadius then
            weightTable = AircraftFactoryOutsideRadiusWeightTable
            searchTiles = gen.getTilesInRadius(city.location,aircraftFactoryMaxRadius,3,0)
        else
            weightTable = AircraftFactoryInRadiusWeightTable
            searchTiles = gen.cityRadiusTiles(city)
        end
    else
        weightTable = strategicItemTerrainWeightTables[item.id]
        if item == object.iMilitaryPort then
            searchTiles = gen.getTilesInRadius(city.location,1,1,0)
        else
            searchTiles = gen.cityRadiusTiles(city)
        end
    end
    local baseTiles = gen.getBiggestWeights(searchTiles,weightTable,1+extraTiles,city)
    return baseTiles
end

local targetEffects = {}
-- targetEffects[improvement.id]
-- targetEffects[wonder.id+40] = {
--      constructionBaseTerrainLow = baseTerrainObject or nil
--      constructionBaseTerrainHigh = baseTerrainObject or nil
--      constructionBaseTerrainNight = baseTerrainObject or nil
--        change the base terrain to this upon construction
--        nil means no change to terrain
--      destructionBaseTerrainLow = baseTerrainObject or nil
--      destructionBaseTerrainHigh = baseTerrainObject or nil
--      destructionBaseTerrainNight = baseTerrainObject or nil
--        change the base terrain of the tile to this
--        when the target is destroyed
--        nil means no change to the terrain
--      targetUnitType = unitTypeObject or true or nil
--        if unitTypeObject, create a target with that unit type
--        on this tile.  nil means no target on this tile.
--        true means create a 'target' without a unit, for example
--        if you want to tie a terrain change to whether or not
--        the item is still in the city
--      targetMap = 0,1,2
--          the map on which to place the target unit 
--      captureWithCity = bool or nil
--        if true, the target on this tile is caputured with the city
--        provided the item is still intact.  False or nil means it
--        is destroyed instead.  
--[[
targetEffects[sampleID] = {
    constructionBaseTerrainLow = object.b,
    destructionBaseTerrainLow = object.b,
    constructionBaseTerrainHigh = object.b,
    destructionBaseTerrainHigh = object.b,
    constructionBaseTerrainNight = object.b,
    destructionBaseTerrainNight = object.b,
    targetUnitType = object.u,
    targetMap = 1,
    captureWithCity = false,}
    --]]

targetEffects[object.iCivilianPopulationI.id] = {
    constructionBaseTerrainLow = object.bResidentialLowBase,
    destructionBaseTerrainLow = object.bBombedUrbanLowBase,
    constructionBaseTerrainHigh = object.bUrbanHighBase,
    destructionBaseTerrainHigh = object.bRubbleHighBase,
    constructionBaseTerrainNight = object.bUrbanNightBase,
    destructionBaseTerrainNight = object.bFirestormNightBase,
    targetUnitType = object.uUrbanCenter,
    targetMap = 2,
    captureWithCity = false,}
targetEffects[object.iCivilianPopulationII.id] = targetEffects[object.iCivilianPopulationI.id]
targetEffects[object.iCivilianPopulationIII.id] = targetEffects[object.iCivilianPopulationI.id]


targetEffects[object.iIndustryI.id] = {
    constructionBaseTerrainLow = object.bIndustryLowBase,
    destructionBaseTerrainLow = object.bBombedIndustryLowBase,
    constructionBaseTerrainHigh = object.bIndustryHighBase,
    destructionBaseTerrainHigh = object.bBombedIndustryHighBase,
    constructionBaseTerrainNight = object.bUrbanNightBase,
    destructionBaseTerrainNight = object.bBombedIndustryNightBase,
    targetUnitType = object.uIndustry,
    targetMap = 1,
    captureWithCity = false,}
targetEffects[object.iIndustryII.id] = targetEffects[object.iIndustryI.id]
targetEffects[object.iIndustryIII.id] = targetEffects[object.iIndustryI.id]


targetEffects[object.iFuelRefineryI.id] = {
    constructionBaseTerrainLow = object.bRefineryLowBase,
    destructionBaseTerrainLow = object.bBombedRefineryLowBase,
    constructionBaseTerrainHigh = object.bRefineryHighBase,
    destructionBaseTerrainHigh = object.bBombedRefineryHighBase,
    constructionBaseTerrainNight = object.bUrbanNightBase,
    destructionBaseTerrainNight = object.bBombedIndustryNightBase,
    targetUnitType = object.uRefinery,
    targetMap = 1,
    captureWithCity = false,}
targetEffects[object.iFuelRefineryII.id] = targetEffects[object.iFuelRefineryI.id]
targetEffects[object.iFuelRefineryIII.id] = targetEffects[object.iFuelRefineryI.id]

targetEffects[object.iAircraftFactoryI.id] = {
    constructionBaseTerrainLow = object.bIndustryLowBase,
    destructionBaseTerrainLow = object.bBombedIndustryLowBase,
    constructionBaseTerrainHigh = object.bIndustryHighBase,
    destructionBaseTerrainHigh = object.bBombedIndustryHighBase,
    constructionBaseTerrainNight = object.bUrbanNightBase,
    destructionBaseTerrainNight = object.bBombedIndustryNightBase,
    targetUnitType = object.uAircraftFactory,
    targetMap = 1,
    captureWithCity = false,}
targetEffects[object.iAircraftFactoryII.id] = targetEffects[object.iAircraftFactoryI.id]
targetEffects[object.iAircraftFactoryIII.id] = targetEffects[object.iAircraftFactoryI.id]

targetEffects[object.iMilitaryPort.id] = {
    constructionBaseTerrainLow = nil,
    destructionBaseTerrainLow = nil,
    constructionBaseTerrainHigh = nil,
    destructionBaseTerrainHigh = nil,
    constructionBaseTerrainNight = nil,
    destructionBaseTerrainNight = nil,
    targetUnitType = object.uMilitaryPort,
    targetMap = 1,
    captureWithCity = false,}

targetEffects[object.iRailyards.id] = {
    constructionBaseTerrainLow = object.bRailtrackLowBase,
    destructionBaseTerrainLow = object.bBombedRRLowBase,
    constructionBaseTerrainHigh = nil,
    destructionBaseTerrainHigh = nil,
    constructionBaseTerrainNight = object.bRailtrackNightBase,
    destructionBaseTerrainNight = object.bBombedRRNightBase,
    targetUnitType = object.uRailyard,
    targetMap = 1,
    captureWithCity = false,}











-- tileEffectsFnunction(city,item) --> false or table of
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
--        to be capured, all the targets for the item should be true
--    }
--  return false if the item can't be constructed in the city
--  (this will only be called on items where isStrategicItemFn(item) returns true)

local function tileEffectsFunction(city,item)
    local itemID = item.id
    if civ.isWonder(item) then
        itemID = itemID+40
    end
    local affectedBaseTiles = getMapZeroTargetTiles(city,item)
    local totalBaseTiles = (extraTileTargets[itemID] or 0)+1
    if #affectedBaseTiles < totalBaseTiles then
        return false
    end
    local outputTable = {}
    for i=1,totalBaseTiles do
        local tE = targetEffects[itemID]
        local bT = affectedBaseTiles[i]
        local tableValueLow = {
            tile = civ.getTile(bT.x,bT.y,0),
            constructionBaseTerrain = tE.constructionBaseTerrainLow,
            destructionBaseTerrain = tE.destructionBaseTerrainLow,
        }
        if i == 1 and tE.targetMap == 0 then
            tableValueLow.targetUnitType = tE.targetUnitType
            tableValueLow.captureWithCity = tE.captureWithCity
        end
        local tableValueHigh = {
            tile = civ.getTile(bT.x,bT.y,1),
            constructionBaseTerrain = tE.constructionBaseTerrainHigh,
            destructionBaseTerrain = tE.destructionBaseTerrainHigh,
        }
        if i == 1 and tE.targetMap == 1 then
            tableValueHigh.targetUnitType = tE.targetUnitType
            tableValueHigh.captureWithCity = tE.captureWithCity
        end
        local tableValueNight = {
            tile = civ.getTile(bT.x,bT.y,2),
            constructionBaseTerrain = tE.constructionBaseTerrainNight,
            destructionBaseTerrain = tE.destructionBaseTerrainNight,
        }
        if i == 1 and tE.targetMap == 2 then
            tableValueNight.targetUnitType = tE.targetUnitType
            tableValueNight.captureWithCity = tE.captureWithCity
        end
        local startIndex = 3*(i-1)
        outputTable[startIndex+1] = tableValueLow
        outputTable[startIndex+2] = tableValueHigh
        outputTable[startIndex+3] = tableValueNight
    end
    return outputTable
end



--[=[
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
  return false
end
--]=]



-- use the basic constructor
local constructedTargetLostFunction,
  constructedTargetVerificationFunction,
  constructedRegisterSupplementalConditionsFunction,
  constructedCityProductionEventFunction =
  strat.basicStrategicFunctions(isStrategicItem,tileEffectsFunction)



-- We need to create the target when an item is
-- produced (perhaps at other times as well)
function discreteEvents.onCityProduction(city,item)
    constructedCityProductionEventFunction(city,item)
    if civ.isImprovement(item) and aircraftFactories[item.id] then
        local target = nil
        for possibleTarget in strat.iterateTargets(city) do
            if possibleTarget.improvement == item and possibleTarget.targetLocation then
                target = possibleTarget
                break
            end
        end
        -- a target will always be found, since it was created in
        -- constructedCityProductionEventFunction
        local industryTile = civ.getTile(target.targetLocation.x,target.targetLocation.y,0)
        for _,tile in pairs(gen.cityRadiusTiles(industryTile)) do
            if factoryAirfield.needsAircraftFactory(tile.city) then
                factoryAirfield.linkFactoryToAirfield(industryTile,tile.city)
                break
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

strat.registerTargetLostFn(constructedTargetLostFunction)



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

return targetSettings

