local object = require("object")
local traits = require("traits")
require("setTraits")
---@module "generalLibrary"
local gen = require("generalLibrary"):minVersion(6)


--      Integer Keys for unit combat statistics
-- combatParameters[unitType.id] = {
--      These don't have to be 'real life' numbers, although 
--      real life numbers might be a good starting point.
--      For example, a radar equipped night fighter might have a
--      high pursuitSpeedNight to reduce the chance of an enemy
--      escaping
--
--      pursuitSpeed = number
--          helps determine how likely an enemy plane is to
--          escape from combat with this plane
--      escapeSpeed = number
--          helps determine how likely a plane is to escape
--          from combat if desired
--      pursuitSpeedLow = number
--      escapeSpeedLow = number
--      escapeSpeedHigh = number
--      pursuitSpeedHigh = number
--      pursuitSpeedNight = number
--      escapeSpeedNight = number
--          these keys override pursuitSpeed and escapeSpeed for certain maps
--      interceptionRange = integer
--          Fighter can defend units this many squares away
--      attackMoveCost = integer or nil
--          cost (in full movement points) for the aircraft to
--          make an attack.  nil means expend all movement


--      
local maxInterceptionRange = 4 -- no unit can have a larger interception range.
local numberSpec = {["number"] = true}
local specificKeyTable = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = {["number"]={minVal=0, maxVal = maxInterceptionRange, integer=true}},
    attackMoveCost = {["number"]={minVal=0,maxVal=255,integer=true}},
}
local generalKeyTable = {}

local defaultValueTable = {
    interceptionRange=0,
    attackMoveCost = 255,

}

local fixedKeyTable = {}

local baseMakeCombatParameter, isCombatParameter = gen.createDataType("combatParameter", specificKeyTable, generalKeyTable, defaultValueTable, fixedKeyTable)
local function makeCombatParameter(d)
    local data = gen.copyTable(d)
    data.pursuitSpeedLow = data.pursuitSpeedLow or data.pursuitSpeed
    data.pursuitSpeedHigh = data.pursuitSpeedHigh or data.pursuitSpeed
    data.pursuitSpeedNight = data.pursuitSpeedNight or data.pursuitSpeed
    data.escapeSpeedLow = data.escapeSpeedLow or data.escapeSpeed
    data.escapeSpeedHigh = data.escapeSpeedHigh or data.escapeSpeed
    data.escapeSpeedNight = data.escapeSpeedNight or data.escapeSpeed
    return baseMakeCombatParameter(data)
end
local combatParameters = {}
gen.makeDataTable(combatParameters)

-- Begin Generic Combat Parameters
combatParameters.lowEscapeScale = 1
combatParameters.highEscapeScale = 1
combatParameters.nightEscapeScale = 2
combatParameters.lowAceEscapeModifier = 1.25
combatParameters.highAceEscapeModifier = 1.25
combatParameters.nightAceEscapeModifier = 1.25
combatParameters.lowAcePursuitModifier = 0.66
combatParameters.highAcePursuitModifier = 0.66
combatParameters.nightAcePursuitModifier = 0.66
--      <time>EscapeScale = number
--          When an aircraft tries to escape combat with another aircraft, the chance per round is
--          (cP = combatParameters

--                                                     cP.<time>EscapeScale*cP[escapingUnit.type.id].escapeSpeed<map>
--  chance  = {escaperAceMod}*{pursuierAceMod}*   -----------------------------------------------------------------------------------------------
--                                                cP[pursuingUnit.type.id].pursuitSpeed<map>+ cP[escapingUnit.type.id].escapeSpeed<map>
--          
--          e.g. EscapeScale = 2 (night), escapeSpeed = 200 km/h, pursuitSpeed = 250 km/h pursuer is Ace, with pursuitMod 0.66, escaping unit not ace
--          chanceOfEscape = 0.66*1*2*200/(250+200) = 58.6% chance to escape per round
--      bomberEscapeScale = number
--          If a bomber tries to escape combat with a fighter, the chance per round of combat is

combatParameters.maxInterceptionRange = maxInterceptionRange
--  Defined above in local form, here to supply to other modules
--  No fighter can intercept from further away

combatParameters.minAirCombatRounds = 3
--  All air combat lasts at least this many rounds, even if one
--  plane wants to escape

combatParameters.maxAirCombatRounds = 10
--  Air combat doesn't last more than this many rounds

combatParameters.fighterEscapeThreshold = 3
--  If a fighter is in combat and can be destroyed in this many hits,
--  it will try to escape combat

combatParameters.maxEscapeStack = 2
--  A unit "escaping" from combat won't be placed on a stack that has more than this number of units already.

-- End Generic Combat Parameters
gen.restrictValues(combatParameters,isCombatParameter,makeCombatParameter)
-- Begin Aircraft Combat Parameters

combatParameters[object.uMe109G6.id] = {
    escapeSpeed = 200,
    pursuitSpeed = 200,
    interceptionRange = 2,
    attackMoveCost = 10,
}
combatParameters[object.uSpitfireIX.id] = {
    escapeSpeed = 200,
    pursuitSpeed = 200,
    interceptionRange = 2,
    attackMoveCost = 10,
}
combatParameters[object.uA20.id] = {
    escapeSpeed = 150,
    pursuitSpeed = 0,
}

return combatParameters