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
local maxInterceptionRange = 10 -- no unit can have a larger interception range.
local numberSpec = {["number"] = true}
local specificKeyTable = {
	pursuitSpeed = {["number"] = true, ["nil"]=true},
	escapeSpeed = {["number"] = true, ["nil"]=true},
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
    pursuitSpeed = 383,
    escapeSpeed = 383,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 10,
}

combatParameters[object.uMe109G14.id] = {
   pursuitSpeed = 404,
    escapeSpeed = 404,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 11,
}

combatParameters[object.uMe109K4.id] = {
   pursuitSpeed = 446,
    escapeSpeed = 446,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 471,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 471,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 12,
}

--INTERCEPTORS

combatParameters[object.uFw190A5.id] = {
	pursuitSpeed = 400,
    escapeSpeed = 400,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 375,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 375,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 10,
}

combatParameters[object.uFw190A8.id] = {
   pursuitSpeed = 405,
    escapeSpeed = 405,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 380,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 380,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 11,
}

combatParameters[object.uFw190D9.id] = {
   pursuitSpeed = 426,
    escapeSpeed = 426,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 451,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 451,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 12,
}

combatParameters[object.uTa152.id] = {
   pursuitSpeed = 469,
    escapeSpeed = 469,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 494,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 494,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 3,
    attackMoveCost = 13,
}

--BOMBER DESTROYERS

combatParameters[object.uMe109G6Rocket.id] = {
   pursuitSpeed = 358,
    escapeSpeed = 358,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 19,
}

combatParameters[object.uMe109G14Rocket.id] = {
   pursuitSpeed = 379,
    escapeSpeed = 379,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 21,
}

combatParameters[object.uFw190A5Rocket.id] = {
   pursuitSpeed = 375,
    escapeSpeed = 375,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 350,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 350,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 29,
}

combatParameters[object.uFw190A8Rocket.id] = {
   pursuitSpeed = 380,
    escapeSpeed = 380,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 355,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 355,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 31,
}

combatParameters[object.uMe110.id] = {
   pursuitSpeed = 336,
    escapeSpeed = 336,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 15,
}

combatParameters[object.uMe410.id] = {
   pursuitSpeed = 388,
    escapeSpeed = 388,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 17,
}

--TRUE NIGHT FIGHTERS

combatParameters[object.uJu88C.id] = {
   pursuitSpeed = 306,
    escapeSpeed = 306,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 11,
}

combatParameters[object.uJu88G.id] = {
   pursuitSpeed = 344,
    escapeSpeed = 344,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 12,
}

combatParameters[object.uHe219.id] = {
   pursuitSpeed = 422,
    escapeSpeed = 422,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 14,
}

--JET & ROCKET FIGHTERS

combatParameters[object.uHe162.id] = {
   pursuitSpeed = 470,
    escapeSpeed = 470,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 5,
}

combatParameters[object.uMe163.id] = {
   pursuitSpeed = 624,
    escapeSpeed = 624,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 10,
    attackMoveCost = 2,
}

combatParameters[object.uMe262.id] = {
   pursuitSpeed = 540,
    escapeSpeed = 540,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 8,
}

--LIGHT BOMBERS

combatParameters[object.uJu87G.id] = {
   pursuitSpeed = 160,
    escapeSpeed = 160,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    attackMoveCost = 15,
}

combatParameters[object.uFw190F8.id] = {
   pursuitSpeed = 376,
    escapeSpeed = 376,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    attackMoveCost = 10,
}

combatParameters[object.uDo335.id] = {
   pursuitSpeed = 474,
    escapeSpeed = 474,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    attackMoveCost = 13,
}

--HEAVY BOMBERS

combatParameters[object.uHe111.id] = {
    pursuitSpeed = 193,
    escapeSpeed = 193,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 18,

}

combatParameters[object.uDo217.id] = {
     pursuitSpeed = 323,
    escapeSpeed = 323,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 20,

}

combatParameters[object.uHe277.id] = {
     pursuitSpeed = 284,
    escapeSpeed = 284,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 23,

}

combatParameters[object.uArado234.id] = {
     pursuitSpeed = 459,
    escapeSpeed = 459,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 10,

}

combatParameters[object.uGo229.id] = {
     pursuitSpeed = 620,
    escapeSpeed = 620,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 12,

}

combatParameters[object.uFw200.id] = {
     pursuitSpeed = 223,
    escapeSpeed = 223,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	interceptionRange = 2,
}

combatParameters[object.uJu188PR.id] = {
     pursuitSpeed = 325,
    escapeSpeed = 325,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 60,
}

--EXPERTEN

combatParameters[object.uEgonMayer.id] = {
    pursuitSpeed = 500,
    escapeSpeed = 500,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 9,
}

combatParameters[object.uHermannGraf.id] = {
    pursuitSpeed = 500,
    escapeSpeed = 500,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 9,
}

combatParameters[object.uJosefPriller.id] = {
    pursuitSpeed = 500,
    escapeSpeed = 500,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 10,
}

combatParameters[object.uAdolfGalland.id] = {
    pursuitSpeed = 600,
    escapeSpeed = 600,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 8,
}

combatParameters[object.uGuntherRall.id] = {
    pursuitSpeed = 500,
    escapeSpeed = 500,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 10,
}

combatParameters[object.uWalterNowotny.id] = {
    pursuitSpeed = 600,
    escapeSpeed = 600,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 8,
}

combatParameters[object.uHWSchnaufer.id] = {
    pursuitSpeed = 500,
    escapeSpeed = 500,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 9,
}

combatParameters[object.uErichHartmann.id] = {
    pursuitSpeed = 500,
    escapeSpeed = 500,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 9,
}

combatParameters[object.uGerhardBarkhorn.id] = {
    pursuitSpeed = 500,
    escapeSpeed = 500,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 10,
}

combatParameters[object.uExperten.id] = {
    pursuitSpeed = 475,
    escapeSpeed = 475,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 9,
}

--ALLIED AIRCRAFT

--AIR SUPERIORITY FIGHTERS

combatParameters[object.uSpitfireIX.id] = {
    pursuitSpeed = 380,
    escapeSpeed = 380,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 10,
}

combatParameters[object.uSpitfireXII.id] = {
    pursuitSpeed = 394,
    escapeSpeed = 394,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 11,
}

combatParameters[object.uSpitfireXIV.id] = {
    pursuitSpeed = 446,
    escapeSpeed = 446,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 12,
}

combatParameters[object.uYak3.id] = {
    pursuitSpeed = 401,
    escapeSpeed = 401,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 8,
}

--FIGHTER BOMBERS

combatParameters[object.uHurricaneIV.id] = {
    pursuitSpeed = 310,
    escapeSpeed = 310,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 1,
    attackMoveCost = 8,
}

combatParameters[object.uWhirlwind.id] = {
    pursuitSpeed = 360,
    escapeSpeed = 360,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 1,
    attackMoveCost = 8,
}

combatParameters[object.uTyphoon.id] = {
    pursuitSpeed = 405,
    escapeSpeed = 405,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 10,
}

combatParameters[object.uTempest.id] = {
    pursuitSpeed = 442,
    escapeSpeed = 442,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 13,
}

--ESCORTS

combatParameters[object.uP47D11.id] = {
    pursuitSpeed = 410,
    escapeSpeed = 410,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 435,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 435,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 15,
}

combatParameters[object.uP47D25.id] = {
    pursuitSpeed = 420,
    escapeSpeed = 420,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 445,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 445,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 17,
}

combatParameters[object.uP47D40.id] = {
    pursuitSpeed = 430,
    escapeSpeed = 430,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 455,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 455,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 17,
}

combatParameters[object.uP51B.id] = {
    pursuitSpeed = 440,
    escapeSpeed = 440,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 20,
}

combatParameters[object.uP51D.id] = {
    pursuitSpeed = 440,
    escapeSpeed = 440,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 20,
}

combatParameters[object.u332ndFG.id] = {
    pursuitSpeed = 440,
    escapeSpeed = 440,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 13,
}

--INTERCEPTORS

combatParameters[object.uP38H.id] = {
    pursuitSpeed = 401,
    escapeSpeed = 401,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 376,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 376,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 10,
}

combatParameters[object.uP38J.id] = {
    pursuitSpeed = 414,
    escapeSpeed = 414,
    --pursuitSpeedLow = numberSpec,
    pursuitSpeedHigh = 389,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    escapeSpeedHigh = 389,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 12,
}

combatParameters[object.uP38L.id] = {
    pursuitSpeed = 420,
    escapeSpeed = 420,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 18,
}

--NIGHT FIGHTERS

combatParameters[object.uBeaufighter.id] = {
    pursuitSpeed = 335,
    escapeSpeed = 335,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 20,
}

combatParameters[object.uMosquitoNFMkII.id] = {
    pursuitSpeed = 366,
    escapeSpeed = 366,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 20,
}

combatParameters[object.uMosquitoNFMkXIII.id] = {
    pursuitSpeed = 374,
    escapeSpeed = 374,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 23,
}

combatParameters[object.uP61.id] = {
    pursuitSpeed = 369,
    escapeSpeed = 369,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 2,
    attackMoveCost = 23,
}

--JET FIGHTERS

combatParameters[object.uP80.id] = {
    pursuitSpeed = 502,
    escapeSpeed = 502,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 8,
}

combatParameters[object.uMeteor.id] = {
    pursuitSpeed = 460,
    escapeSpeed = 460,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 6,
    attackMoveCost = 8,
}

--TACTICAL BOMBERS

combatParameters[object.uIl2.id] = {
     pursuitSpeed = 250,
    escapeSpeed = 250,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 8,

}

combatParameters[object.uB25.id] = {
     pursuitSpeed = 275,
    escapeSpeed = 275,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 24,

}

combatParameters[object.uA20.id] = {
     pursuitSpeed = 317,
    escapeSpeed = 317,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 0,

}

combatParameters[object.uB26.id] = {
    pursuitSpeed = 315,
    escapeSpeed = 315,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 0,

}

combatParameters[object.uA26.id] = {
     pursuitSpeed = 355,
    escapeSpeed = 355,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 0,

}

combatParameters[object.uSunderland.id] = {
     pursuitSpeed = 210,
    escapeSpeed = 210,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 60,

}

combatParameters[object.uMosquitoPR.id] = {
     pursuitSpeed = 374,
    escapeSpeed = 374,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 40,
}

--DAYLIGHT STRATEGIC BOMBERS

combatParameters[object.uB17F.id] = {
     pursuitSpeed = 287,
    escapeSpeed = 287,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 20,

}

combatParameters[object.uDamagedB17F.id] = {
     pursuitSpeed = 182,
    escapeSpeed = 182,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 20,

}

combatParameters[object.uB17G.id] = {
     pursuitSpeed = 287,
    escapeSpeed = 287,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 22,

}

combatParameters[object.uDamagedB17G.id] = {
     pursuitSpeed = 182,
    escapeSpeed = 182,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 22,
}

combatParameters[object.uB24J.id] = {
     pursuitSpeed = 290,
    escapeSpeed = 290,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 30,
}

combatParameters[object.u15thAFBombers.id] = {
     pursuitSpeed = 290,
    escapeSpeed = 290,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 22,
}

--NIGHT BOMBERS

combatParameters[object.uMosquitoBIV.id] = {
     pursuitSpeed = 374,
    escapeSpeed = 374,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 0,
}

combatParameters[object.uPathfinder.id] = {
     pursuitSpeed = 292,
    escapeSpeed = 292,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 25,
}

combatParameters[object.uStirling.id] = {
     pursuitSpeed = 270,
    escapeSpeed = 270,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 20,
}

combatParameters[object.uHalifax.id] = {
     pursuitSpeed = 265,
    escapeSpeed = 265,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 22,

}

combatParameters[object.uLancaster.id] = {
    pursuitSpeed = 282,
    escapeSpeed = 282,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
	attackMoveCost = 25,

}

--ACES

combatParameters[object.uFrancisGabreski.id] = {
    pursuitSpeed = 500,
    escapeSpeed = 500,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 10,
}

combatParameters[object.uGeorgePreddy.id] = {
    pursuitSpeed = 500,
    escapeSpeed = 500,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 15,
}

combatParameters[object.uJohnBraham.id] = {
    pursuitSpeed = 500,
    escapeSpeed = 500,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 20,
}

combatParameters[object.uJohnnieJohnson.id] = {
    pursuitSpeed = 500,
    escapeSpeed = 500,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 15,
}

combatParameters[object.uUSAAFAce.id] = {
    pursuitSpeed = 475,
    escapeSpeed = 475,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 15,
}

combatParameters[object.uRAFAce.id] = {
    pursuitSpeed = 475,
    escapeSpeed = 475,
    --pursuitSpeedLow = numberSpec,
    --pursuitSpeedHigh = numberSpec,
    --pursuitSpeedNight = numberSpec,
    --escapeSpeedLow = numberSpec,
    --escapeSpeedHigh = numberSpec,
    --escapeSpeedNight = numberSpec,
    interceptionRange = 4,
    attackMoveCost = 10,
}



return combatParameters