--[[
    Clouds vs combat
    Numbers live in parameters.lua under param.cloud.
]]

local combatMod = require("combatModifiers")
local param     = require("parameters")

local cloudCombat = {}

local CLOUD_TYPE = 15
local P = param.cloud or {}
local STRIKE_IN_CLOUD = P.strikeInCloud or 0.55
local ESCAPE_IN_CLOUD = P.escapeInCloud or 1.80
cloudCombat.STRIKE_IN_CLOUD = STRIKE_IN_CLOUD
cloudCombat.ESCAPE_IN_CLOUD = ESCAPE_IN_CLOUD

local function tileIsCloud(tile)
    if not tile then return false end
    if tile.z ~= 1 and tile.z ~= 3 then return false end
    return (tile.terrainType & 0x0F) == CLOUD_TYPE
end

function cloudCombat.tileIsCloud(tile)
    return tileIsCloud(tile)
end

function cloudCombat.unitInCloud(unit)
    return unit and tileIsCloud(unit.location)
end

local function isAir(unit)
    return unit and unit.type and unit.type.domain == 1
end

combatMod.registerCombatModificationRule({
    customCheck = function(attacker, defender)
        if not isAir(attacker) then return false end
        if not defender then return false end
        if isAir(defender) then return false end
        return tileIsCloud(defender.location)
    end,
    aCustomMult = function(attacker, defender)
        return STRIKE_IN_CLOUD
    end,
})

return cloudCombat
