
local versionNumber = 1
local fileModified = false -- set this to true if you change this file for your scenario
-- if another file requires this file, it checks the version number to ensure that the
-- version is recent enough to have all the expected functionality
-- if you set fileModified to true, the error generated if this file is out of date will
-- warn you that you've modified this file



-- This file is meant to group scenario parameters, so that there is a single
-- place where important values are recorded.  It is recommended that you define
-- a parameter value in one place and always refer to that place, so that if
-- you decide to make a change, only one value has to be changed instead of
-- searching for every possible place that value is relevant.

---@module "generalLibrary"
local gen = require("generalLibrary"):minVersion(1)
local text = require("text")
--local eventTools = require("eventTools")
---@module "discreteEvents"
local discreteEvents = require("discreteEventsRegistrar"):minVersion(1)

text.setMoney("%STRING1 gold")
-- text.setMoney("$%STRING1,000")
-- text.setMoneu("%STRING1 Pounds", "%STRING1 Pound")
-- used to determine how text.money(amount)--> string
-- will work
-- if second argument is supplied, that is used when the amount is 1

text.setDigitGroupSeparator(",")
-- text.setDigitGroupSeparator("")
-- text.setDigitGroupSeparator(".")
-- used to determine how text.groupDigits(integer)-->string
-- will work

text.setVeteranTitle("Veteran")
-- sets the string that is returned by text.getVeteranTitle()
--

text.setShortVeteranTitle("Vet")
-- sets the string that is returned by text.getShortVeteranTitle()



function discreteEvents.onScenarioLoaded()
    civ.scen.compatibility.activateUnitEveryMove = true
end


-- This function registers what happens when Lua code causes a
-- unit to be destroyed because it is 'out of range/fuel'.  This could be
-- because events expended the last movement points of an aircraft,
-- or because land/sea units have been given a range using Lua.  
-- (No code is run when the standard game detects an aircraft to be
-- out of range)<br><br>
-- If `textOrFunction` is a string, the text is shown when a unit is 
-- lost due to being out of range, with %STRING1 substitutes for the unit type's name.  `title` provides the title for the box.
--
-- If `textOrFunction` is a `function(unit) -> void`, the
-- function is exectued, and is trusted to generate the 
-- the function is trusted to generate a suitable message.
--gen.setOutOfRangeMessage(textOrFunction,title)
local message = 
[[Your aircraft has run out of fuel.
Fighter and Missile units must return to
a city or Carrier at the end of each
turn.  Bomber units must return at the end
of their second turn.]]
gen.setOutOfRangeMessage(message,"Civ Rules: Fuel")


local param = {}

-- If a target type is not placed within a city's radius, it
-- will be placed within this distance of the city
param.maxTargetDistanceFromCity = 6

-- Fuel-train economy
param.fuelTrainSyntheticCount       = 1
param.fuelTrainSyntheticInterval    = 2
param.fuelTrainOilCount             = 1
param.fuelTrainOilInterval          = 3
param.fuelTrainTilesPerTurn         = 5
param.fuelTrainDeliveryAmount       = 500
param.fuelMinToActivateAircraft     = 1
param.fuelStatusKey                 = "five"
param.fuelPerEngine                 = 10
param.fuelJetMultiplier             = 3

param.fuelZoneInitialStock          = 10000
param.fuelTierFull                  = 7500
param.fuelTierHigh                  = 5000
param.fuelTierLow                   = 2500
param.fuelFailChanceFull            = 0
param.fuelFailChanceHigh            = 25
param.fuelFailChanceMid             = 50
param.fuelFailChanceLow             = 75

-- Convoy System
param.convoyAlliedInterval          = 2
param.convoyAlliedDayCount          = 2
param.convoyAlliedNightCount        = 2
param.convoyGermanInterval          = 3
param.convoyGermanCount             = 2
param.convoyUboatFullCount          = 11
param.convoyAlliedDayMap            = 0
param.convoyAlliedNightMap          = 2
param.convoyRequireRoute            = true


gen.versionFunctions(param,versionNumber,fileModified,"LuaParameterFiles".."\\".."parameters.lua")


return param
