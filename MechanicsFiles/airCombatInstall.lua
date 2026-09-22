--[[
OTR air combat TEST hook
Copy this file AND airCombatCore.lua AND airCombatTestSet.lua into MechanicsFiles.

Then do the two small edits in INSTALL_AIR_COMBAT.txt.

This file:
  - defines flag combatNarration (default ON)
  - assigns the 8-ship traits (setTraits must already allow those trait names)
  - loads hidden parameters
  - binds key N to toggle narration boxes
]]

local flag = require("flag")
local discreteEvents = require("discreteEventsRegistrar")
local keyboard = require("keyboard")
local airCombat = require("airCombatCore")
local testSet = require("airCombatTestSet")

flag.define("combatNarration", true, "airCombat")

-- traits.allowedTraits can only run once. That edit lives in setTraits.lua.
-- Assignments can run from here AFTER setTraits has allowed the names.
local traitsAssigned = false
local function assignIfReady()
    if traitsAssigned then return end
    local ok, err = pcall(testSet.assignTestSetTraits)
    if ok then
        traitsAssigned = true
        print("airCombatInstall: test-set traits assigned")
    else
        print("airCombatInstall: traits not assigned yet ("..tostring(err)..")")
        print("Did you add the combat trait names to traits.allowedTraits in setTraits.lua?")
    end
end

discreteEvents.onScenarioLoaded(function()
    assignIfReady()
    airCombat.ingestTestSet()
    print("airCombatInstall: parameters ingested, narration="
        ..tostring(airCombat.narrationOn()))
end)

discreteEvents.onKeyPress(function(keyCode)
    if keyCode == keyboard.n or keyCode == keyboard.N then
        airCombat.toggleNarration()
    end
end)

assignIfReady()
airCombat.ingestTestSet()

return {
    airCombat = airCombat,
    testSet = testSet,
}
