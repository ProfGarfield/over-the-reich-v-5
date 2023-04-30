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
	pursuitSpeed = {["number"] = true, ["nil"]=true}
	escapeSpeed = {["number"] = true, ["nil"]=true}
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



--ESCORTS

combatParameters[object.uMe109G6.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 10,
}

combatParameters[object.uMe109G14.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 11,
}

combatParameters[object.uMe109K4.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 12,
}

--INTERCEPTORS

combatParameters[object.uFw190A5.id] = {
   pursuitSpeedLow = 300,
    pursuitSpeedHigh = 250,
    pursuitSpeedNight = 200,
    escapeSpeedLow = 300,
    escapeSpeedHigh = 250,
    escapeSpeedNight = 300,
    interceptionRange = 2,
    attackMoveCost = 10,
}

combatParameters[object.uFw190A8.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 11,
}

combatParameters[object.uFw190D9.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 12,
}

combatParameters[object.uTa152.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 3,
    attackMoveCost = 13,
}

--BOMBER DESTROYERS

combatParameters[object.uMe109G6Rocket.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 19,
}

combatParameters[object.uMe109G14Rocket.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 21,
}

combatParameters[object.uFw190A5Rocket.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 29,
}

combatParameters[object.uFw190A8Rocket.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 31,
}

combatParameters[object.uMe110.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 15,
}

combatParameters[object.uMe410.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 17,
}

--TRUE NIGHT FIGHTERS

combatParameters[object.uJu88C.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 11,
}

combatParameters[object.uJu88G.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 12,
}

combatParameters[object.uHe219.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 14,
}

--JET & ROCKET FIGHTERS

combatParameters[object.uHe162.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 5,
}

combatParameters[object.uMe163.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 10,
    attackMoveCost = 2,
}

combatParameters[object.uMe262.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 8,
}

--LIGHT BOMBERS

combatParameters[object.uJu87G.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    attackMoveCost = 15,
}

combatParameters[object.uFw190F8.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    attackMoveCost = 10,
}

combatParameters[object.uDo335.id] = {
   pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    attackMoveCost = 13,
}

--HEAVY BOMBERS

combatParameters[object.uHe111.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 100,
    escapeSpeedHigh = 150,
    escapeSpeedNight = 200,
	attackMoveCost = 18,

}

combatParameters[object.uDo217.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 100,
    escapeSpeedHigh = 150,
    escapeSpeedNight = 200,
	attackMoveCost = 20,

}

combatParameters[object.uHe277.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 125,
    escapeSpeedHigh = 175,
    escapeSpeedNight = 225,
	attackMoveCost = 23,

}

combatParameters[object.uArado234.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 400,
    escapeSpeedHigh = 425,
    escapeSpeedNight = 450,
	attackMoveCost = 10,

}

combatParameters[object.uGo229.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 12,

}

combatParameters[object.uFw200.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 60,
	interceptionRange = 2,
}

combatParameters[object.uJu188PR.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 60,
}

--EXPERTEN

combatParameters[object.uEgonMayer.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 9,
}

combatParameters[object.uHermannGraf.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 9,
}

combatParameters[object.uJosefPriller.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 10,
}

combatParameters[object.uAdolfGalland.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 8,
}

combatParameters[object.uGuntherRall.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 10,
}

combatParameters[object.uWalterNowotny.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 8,
}

combatParameters[object.uHWSchnaufer.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 9,
}

combatParameters[object.uErichHartmann.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 9,
}

combatParameters[object.uGerhardBarkhorn.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 10,
}

combatParameters[object.uExperten.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 9,
}

--ALLIED AIRCRAFT

--AIR SUPERIORITY FIGHTERS

combatParameters[object.uSpitfireIX.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 10,
}

combatParameters[object.uSpitfireXII.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 11,
}

combatParameters[object.uSpitfireXIV.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 12,
}

combatParameters[object.uYak3.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 8,
}

--FIGHTER BOMBERS

combatParameters[object.uHurricaneIV.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 1,
    attackMoveCost = 8,
}

combatParameters[object.uWhirlwind.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 1,
    attackMoveCost = 8,
}

combatParameters[object.uTyphoon.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 10,
}

combatParameters[object.uTempest.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 13,
}

--ESCORTS

combatParameters[object.uP47D11.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 15,
}

combatParameters[object.uP47D25.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 17,
}

combatParameters[object.uP47D40.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 17,
}

combatParameters[object.uP51B.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 20,
}

combatParameters[object.uP51D.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 20,
}

combatParameters[object.u332ndFG.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 13,
}

--INTERCEPTORS

combatParameters[object.uP38H.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 10,
}

combatParameters[object.uP38J.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 12,
}

combatParameters[object.uP38L.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 18,
}

--NIGHT FIGHTERS

combatParameters[object.uBeaufighter.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 20,
}

combatParameters[object.uMosquitoNFMkII.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 20,
}

combatParameters[object.uMosquitoNFMkXIII.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 23,
}

combatParameters[object.uP61.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 23,
}

--JET FIGHTERS

combatParameters[object.uP80.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 8,
}

combatParameters[object.uMeteor.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 8,
}

--TACTICAL BOMBERS

combatParameters[object.uIl2.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 8,

}

combatParameters[object.uB25.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 24,

}

combatParameters[object.uA20.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 0,

}

combatParameters[object.uB26.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 0,

}

combatParameters[object.uA26.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 0,

}

combatParameters[object.uSunderland.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 60,

}

combatParameters[object.uMosquitoPR.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 40,
}

--DAYLIGHT STRATEGIC BOMBERS

combatParameters[object.uB17F.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 20,

}

combatParameters[object.uDamagedB17F.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 20,

}

combatParameters[object.uB17G.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 22,

}

combatParameters[object.uDamagedB17G.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 22,
}

combatParameters[object.uB24J.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 30,
}

combatParameters[object.u15thAFBombers.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 22,
}

--NIGHT BOMBERS

combatParameters[object.uMosquitoBIV.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 0,
}

combatParameters[object.uPathfinder.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 25,
}

combatParameters[object.uStirling.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 20,
}

combatParameters[object.uHalifax.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 22,

}

combatParameters[object.uLancaster.id] = {
    pursuitSpeed = 0,
    escapeSpeedLow = 425,
    escapeSpeedHigh = 450,
    escapeSpeedNight = 475,
	attackMoveCost = 25,

}

--ACES

combatParameters[object.uFrancisGabreski.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 10,
}

combatParameters[object.uGeorgePreddy.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 15,
}

combatParameters[object.uJohnBraham.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 20,
}

combatParameters[object.uJohnnieJohnson.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 15,
}

combatParameters[object.uUSAAFAce.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 15,
}

combatParameters[object.uRAFAce.id] = {
    pursuitSpeed = numberSpec,
    escapeSpeed = numberSpec,
    pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = numberSpec,
    pursuitSpeedNight = numberSpec,
    escapeSpeedLow = numberSpec,
    escapeSpeedHigh = numberSpec,
    escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 10,
}



return combatParameters