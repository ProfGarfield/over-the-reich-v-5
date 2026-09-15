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
    return city:hasImprovement(object.iCityI)
end

-- returns true if a tile is within the radius of an OTRCity,
-- and false otherwise
-- if city is specified, returns true only if the tile is within
-- the radius of a different city
function helper.inOTRCityRadius(queryTile,city)
    for _,tile in pairs(gen.cityRadiusTiles(queryTile)) do
        if tile.city and tile.city ~= city and helper.isOTRCity(tile.city) then
            return true
        end
    end
    return false
end

-- returns true if the query tile has an adjacent tile which
-- has the given base terrain, and false otherwise
-- does not check the queryTile itself
function helper.adjacentBaseTerrain(queryTile,baseTerrainObject)
    for _,tile in pairs(gen.getTilesInRadius(queryTile,1,1,nil)) do
        if queryTile.baseTerrain == baseTerrainObject then
            return true
        end
    end
    return false
end

-- if an airfield can not be built on the tile,
-- return an explanatory message
-- if an airfield can be built on the tile, return false
function helper.isAirfieldForbidden(tile)
    if tile.z > 0 then
        return "Airfields may only be built on the Low Altitude Daylight Map."
    end
    if not traits.hasTrait(tile.baseTerrain,"canBuildAirfield") then
        return "Airfields can not be built on "..tile.baseTerrain.name.." tiles."
    end
    for _,adjacentTile in pairs(gen.getTilesInRadius(tile,1)) do
        if gen.hasTransporter(adjacentTile) then
            return "Airfields can not be built next to Railyards."
        end
    end
    for _,radiusTile in pairs(gen.cityRadiusTiles(tile)) do
        if radiusTile.city and helper.isOTRCity(radiusTile.city) then
            return "Airfields can not be built within a city's radius."
        end
    end
    return false
end

--- Returns "Low","High","Night","Climb","Dive" based on the relative
--- and absolute positions of fromZ and toZ
---@param fromZ 0|1|2
---@param toZ 0|1|2
---@return "Low"|"High"|"Night"|"Climb"|"Dive"
function helper.getCombatSuffix(fromZ,toZ)
    if fromZ == 2 and toZ == 2 then
        return "Night"
    end
    if fromZ == 0 then
        if toZ == 0 then
            return "Low"
        elseif toZ == 1 then
            return "Climb"
        end
    end
    if fromZ == 1 then
        if toZ == 0 then
            return "Dive"
        elseif toZ == 1 then 
            return "High"
        end
    end
    error("helper.getCombatSuffix("..tostring(fromZ)..","..tostring(toZ)..") was called, but that doesn't make sense for this scenario.")
end

---Returns the number of squares an aircraft can move before it runs out of fuel.
---If the unit has range 0, math.huge is returned.
---@param unit unitObject
---@return integer
function helper.distanceToEmpty(unit)
    if unit.type.range == 0 then
        return math.huge
    end
    if unit.owner == civ.getCurrentTribe() then
        local turnsRemaining = unit.type.range - unit.domainSpec-1
        local movesRemaining = unit.type.move/totpp.movementMultipliers.aggregate       
        movesRemaining = movesRemaining*turnsRemaining
        movesRemaining = movesRemaining + math.max(0,gen.moveRemaining(unit)//totpp.movementMultipliers.aggregate)
        return movesRemaining
    else
        local turnsRemaining = unit.type.range - unit.domainSpec
        local movesRemaining = unit.type.move//totpp.movementMultipliers.aggregate       
        movesRemaining = movesRemaining*turnsRemaining
        return movesRemaining
    end
end


---Returns true if the unit has the range to return to an airbase,
---after reducing its movement by the reduction.
---Returns false if it can't.  Units with 0 range return true.
---@param unit unitObject
---@param reduction? integer # 0 if absent
---@return boolean
function helper.canReturnToAirbase(unit,reduction)
    reduction = reduction or 0
    if unit.type.range == 0 then
        return true
    end
    local distToEmpty = helper.distanceToEmpty(unit) - reduction
    local tribe = unit.owner
    for city in civ.iterateCities() do
        if city.owner == tribe and helper.isOTRAirfield(city) and
        gen.tileDist(city.location,unit.location) <= distToEmpty then
            return true
        end
    end
    if traits.hasTrait(unit.type,"useCarrier") then
        for possibleCarrier in civ.iterateUnits() do
            if possibleCarrier.owner == tribe and 
            traits.hasTrait(possibleCarrier.type,"carrier") then
                return true
            end
        end
    end
    return false
end


rawset(_G,"helper",helper)
return helper
