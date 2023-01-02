-- This module keeps track of aircraft factory tiles
-- and the airfields to which they are linked.
--
-- An airfield can only be linked to one factory, and
-- a factory can only be linked to one airfield.
-- Both factories and airfields do not have to be linked
-- to a counterpart.
--
-- An aircraft factory tile is never linked to an airfield
-- if it is within a proper city (has City I improvement)
--
-- These links help determine if an airfield has an aircraft
-- factory linked (e.g. to enable certain production)
-- and to try to place aircraft factories in good locations,
-- particularly to be placed near airfields without aircraft
-- factory "service".
--
-- An aircraft factory continues to be associated with 
-- an airfield even if it has been destroyed by strategic bombing

local tileData = require("tileData")
local object = require("object")
local cityData = require("cityData")
local gen = require("generalLibrary")
local helper = require("helper")
local discreteEvents = require("discreteEventsRegistrar")

local factoryAirfield = {}

-- the data factoryAirfieldLink keeps track of tileID numbers
-- if the tile is an airfield, it keeps track of the corresponding
-- aircraft factory tile.
-- if the tile is an aircraft factory, it has the tileID for the
-- airfield it is assigned to
-- nil means no link between airfield and aircraft factory
tileData.defineCounter("aircraftFactoryLinkedCityLocationID")
cityData.defineCounter("linkedAircraftFactoryLocationID")

-- if a tile is an aircraft factory with a linked
-- airfield, returns the airfied
-- otherwise, returns nil
function factoryAirfield.getLinkedAirfield(tile)
    if tileData.counterIsNil(tile,"aircraftFactoryLinkedCityLocationID") then
        return nil
    else
        return gen.getTileFromID(tileData.counterGetValue(tile,"aircraftFactoryLinkedCityLocationID")).city
    end
end

-- if an airfield has a linked aircraft factory, returns that
-- tile, otherwise, returns nil
function factoryAirfield.getLinkedFactory(city)
    if cityData.counterIsNil(city,"linkedAircraftFactoryLocationID") then
        return nil
    else
        return gen.getTileFromID(cityData.counterGetValue(city,"linkedAircraftFactoryLocationID"))
    end
end

-- returns true if the city is an airfield which does not
-- have an associated airfield, false otherwise, including
-- if the city is an OTRCity
function factoryAirfield.needsAircraftFactory(city)
    if not city then
        return false
    end
    if not helper.isOTRAirfield(city) then
        return false
    end
    if cityData.counterIsNil(city,"linkedAircraftFactoryLocationID") then
        return true
    end
    return false
end

-- returns true if a tile has industry terrain or bombed industry terrain,
-- has no airfield linked already, and is outside the radius
-- of an OTRCity
function factoryAirfield.needsAirfield(tile)
    if tile.baseTerrain ~= object.bIndustryLowBase and tile.baseTerrain ~= object.bBombedIndustryLowBase then
        return false
    end
    if factoryAirfield.getLinkedAirfield(tile) then
        return false
    end
    if helper.inOTRCityRadius(tile) then
        return false
    end
    return true
end

function factoryAirfield.linkFactoryToAirfield(industryTile,airfield)
    if not factoryAirfield.needsAirfield(industryTile) then
        error("factoryAirfield.linkFactoryToAirfield: argument 1 is not an industry tile needing an airfield.")
    end
    if not factoryAirfield.needsAircraftFactory(airfield) then
        error("factoryAirfield.linkFactoryToAirfield: argument 2 is not an airfield needing an aircraft factory.")
    end
    tileData.counterSetValue(industryTile,"aircraftFactoryLinkedCityLocationID",gen.getTileId(airfield.location))
    cityData.counterSetValue(airfield,"linkedAircraftFactoryLocationID",gen.getTileId(industryTile))
end

function factoryAirfield.unlinkFactoryFromAirfield(linkedItem)
    local industryTile = nil
    local airfield = nil
    if civ.isTile(linkedItem) then
        industryTile = linkedItem
        if tileData.counterIsNil(industryTile,"aircraftFactoryLinkedCityLocationID") then
            return
        end
        airfield = gen.getTileFromID(tileData.counterGetValue(industryTile,"aircraftFactoryLinkedCityLocationID")).city
    elseif civ.isCity(linkedItem) then
        airfield = linkedItem
        if cityData.counterIsNil(airfield,"linkedAircraftFactoryLocationID") then
            return
        end
        industryTile = gen.getTileFromID(cityData.counterGetValue(airfield,"linkedAircraftFactoryLocationID"))

    else
        error("factoryAirfield.unlinkFactoryFromAirfield: argument is not a tile or a city.")
    end
    tileData.counterReset(industryTile,"aircraftFactoryLinkedCityLocationID")
    cityData.counterReset(airfield,"linkedAircraftFactoryLocationID")
end

-- links a new airfield to an aircraft factory if one is available
function factoryAirfield.linkNewAirfieldToFactory(city)
    local defunctFactory = nil
    local activeFactory = nil
    local dFI = math.huge
    local aFI = math.huge
    for i,tile in pairs(gen.cityRadiusTiles(city)) do
        if factoryAirfield.needsAirfield(tile) then
            if tile.baseTerrain == object.bBombedIndustryLowBase and i < dFI then
                defunctFactory = tile
                dFI = i -- this way, the smallest index tile is chosen if there are more than 1
            elseif tile.baseTerrain == object.bIndustryLowBase and i <aFI then
                activeFactory = tile
                aFI = i
            end
        end
    end
    if activeFactory then
        linkFactoryToAirfield(activeFactory,city)
        return
    elseif defunctFactory then
        linkFactoryToAirfield(defunctFactory,city)
        return
    end
end

function discreteEvents.onCityDestroyed(city)
    factoryAirfield.unlinkFactoryFromAirfield(city)
end





return factoryAirfield
