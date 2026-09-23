--[[
    Flying Fortress wrecks
    B-17F / B-17G that die become the burning Damaged type on the same tile.
    A second kill on the wreck is final.
    Human or AI: activate on an airfield city -> veteran original type.
    AI: each turn pick a Britain-box airfield in range (25 first, else max).
]]

local discreteEvents = require("discreteEventsRegistrar")
local object         = require("object")
local helper         = require("helper")
local gen            = require("generalLibrary")

local ff = {}

-- TEST: true = human wrecks also get a goto on activate.
-- Set false before shipping.
local TEST_HUMAN_GOTO = true

local RANGE_NEAR = 25
local RANGE_F    = 100
local RANGE_G    = 108

local wreckOf = {}
if object.uB17FFortress and object.uB17FDamaged then
    wreckOf[object.uB17FFortress.id] = {
        damaged = object.uB17FDamaged,
        original = object.uB17FFortress,
        range = RANGE_F,
    }
end
if object.uB17GFortress and object.uB17GDamaged then
    wreckOf[object.uB17GFortress.id] = {
        damaged = object.uB17GDamaged,
        original = object.uB17GFortress,
        range = RANGE_G,
    }
end

local repairOf = {}
for _, spec in pairs(wreckOf) do
    repairOf[spec.damaged.id] = spec
end

local spawnedFrom = {}

local function tileOk(tile)
    return tile and tile.x and tile.x >= 0
end

local function spawnWreck(dead, tile)
    if not dead or not tileOk(tile) then return end
    local spec = wreckOf[dead.type.id]
    if not spec then return end
    if spawnedFrom[dead.id] then return end
    spawnedFrom[dead.id] = true
    local u = civ.createUnit(spec.damaged, dead.owner, tile)
    if u then
        u.veteran = false
        u.homeCity = dead.homeCity
        u.damage = 0
    end
    return u
end

local function cityOnAirfield(tile)
    if not tile then return nil end
    for z = 0, 3 do
        local t = civ.getTile(tile.x, tile.y, z)
        if t and t.city and helper.isOTRAirfield(t.city) then
            return t.city
        end
    end
    return nil
end

local function repairIfHome(unit)
    local spec = repairOf[unit.type.id]
    if not spec then return false end
    local city = cityOnAirfield(unit.location)
    if not city then return false end
    local tile = unit.location
    local owner = unit.owner
    local home = unit.homeCity
    civ.deleteUnit(unit)
    local u = civ.createUnit(spec.original, owner, tile)
    if u then
        u.veteran = true
        u.homeCity = home
        u.damage = 0
    end
    return true
end

local function britainAirfields()
    local list = {}
    for city in civ.iterateCities() do
        if helper.isOTRAirfield(city) then
            local name = helper.airZoneFor(city.location.x, city.location.y)
            if name == "Britain" then
                list[#list + 1] = city
            end
        end
    end
    return list
end

local function pickField(unit)
    local spec = repairOf[unit.type.id]
    if not spec then return nil end
    local fields = britainAirfields()
    local near, far = {}, {}
    for i = 1, #fields do
        local d = gen.distance(unit.location, fields[i].location)
        if d <= RANGE_NEAR then
            near[#near + 1] = fields[i]
        elseif d <= spec.range then
            far[#far + 1] = fields[i]
        end
    end
    local pool = (#near > 0) and near or far
    if #pool == 0 then return nil end
    return pool[math.random(#pool)]
end

local function dropToLow(unit)
    local z = unit.location.z
    local lowZ = nil
    if z == 1 then lowZ = 0 end
    if z == 3 then lowZ = 2 end
    if lowZ == nil then return false end
    local dest = civ.getTile(unit.location.x, unit.location.y, lowZ)
    if not dest then return false end
    civ.teleportUnit(unit, dest)
    return true
end

local function sendHome(unit)
    if unit.owner.isHuman and not TEST_HUMAN_GOTO then return end
    local city = pickField(unit)
    if not city then return end
    local dest = civ.getTile(city.location.x, city.location.y, unit.location.z)
    if dest then
        unit.gotoTile = dest
    end
end

discreteEvents.onUnitKilled(function(loser, winner, aggressor, victim, loserLocation)
    spawnWreck(loser, loserLocation)
end)

discreteEvents.onUnitDeleted(function(deletedUnit, replacingUnit)
    if replacingUnit then return end
    if not deletedUnit then return end
    if repairOf[deletedUnit.type.id] then return end
    spawnWreck(deletedUnit, deletedUnit.location)
end)

discreteEvents.onActivateUnit(function(unit)
    if not unit then return end
    if not repairOf[unit.type.id] then return end
    dropToLow(unit)
    if repairIfHome(unit) then return end
    sendHome(unit)
end)

discreteEvents.onTribeTurnBegin(function(turn, tribe)
    if tribe ~= object.pAllies then return end
    for u in civ.iterateUnits() do
        if repairOf[u.type.id] and u.owner == tribe then
            dropToLow(u)
        end
    end
end)

discreteEvents.onTurn(function(turn)
    spawnedFrom = {}
    for u in civ.iterateUnits() do
        if repairOf[u.type.id] and not u.owner.isHuman then
            sendHome(u)
        end
    end
end)

return ff
