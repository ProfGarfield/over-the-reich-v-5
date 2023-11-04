--
local versionNumber = 2
local fileModified = true -- set this to true if you change this file for your scenario
-- if another file requires this file, it checks the version number to ensure that the
-- version is recent enough to have all the expected functionality
-- if you set fileModified to true, the error generated if this file is out of date will
-- warn you that you've modified this file
--
--
--      combatSettings.lua
--
--  This file consists of three related parts.
--
--  The first part is the "combat calculation," which determines
--  The final attack and defense values of the units involved in combat
--  By default, this section calls upon the combatCalculator module, which 
--  was developed by Knighttime (with some changes made by me, Prof. Garfield)
--
--  The second part is the "on choose defender" event, which determines, given
--  an attacking unit, what unit will defend the tile in combat.  By default, it is set up
--  to choose the unit with defensiveStat*currentHP/maxHP (round down)
--  This seems to be the default function for choosing a defender
--      https://forums.civfanatics.com/threads/defending-unit-choice.667673/
--  The actual default choice function is not used here, to take into account a modified combat calculator
--
--  The last part of this file is the "on initiate combat" event, which actually governs
--  how combat works.  If you want to stop combat early, for example, you would do it in this section.
--  It is also the place where you can change the way combat behaves.

local register = {}

---@module "generalLibrary"
local gen = require("generalLibrary"):minVersion(1)
gen.versionFunctions(register,versionNumber,fileModified,"MechanicsFiles".."\\".."combatSettings.lua")
--
local combatCalculator = require("combatCalculator"):recommendedVersion(2)
local rules = require("rules"):minVersion(1)
local text = require("text")
local simpleSettings = require("simpleSettings"):recommendedVersion(1)
local combatModifiers = require("combatModifiers"):minVersion(1)
local combatParameters = require("combatParametersOTR")
local traits = require("traits")
local discreteEvents = require("discreteEventsRegistrar")
local changeRules = require("changeRules")
local helper = require("helper")


local domain = {ground = 0, air = 1, sea = 2}
---Finds units that are able to defend the `tile` from the `attacker`
---@param tile tileObject
---@param attacker unitTypeObject
---@return iterator
local function potentialDefenders(tile,attacker)
    if attacker.domain == domain.ground or attacker.domain == domain.sea then
        return tile.units
    end

    local tribe = tile.defender
    local searchMaps = {}
    if tile.z == 2 then
        searchMaps[1] = 2
    else
        searchMaps[1] = 0
        searchMaps[2] = 1
    end
    local searchRadius = combatParameters.maxInterceptionRange
    local function isQualifiedDefender(unit)
        -- units on the tile must always be qualified to defend
        if unit.location == tile then
            return true
        end
        if unit.owner ~= tribe then
            return false
        end
        if not gen.isAllowedOnMap(unit.type,tile.z) then
            return false
        end
        local cParam = combatParameters[unit.type.id]
        if not cParam then
            return false
        end
        if gen.tileDist(unit.location,tile) > combatParameters[unit.type.id].interceptionRange then
            return false
        end
        if not helper.canReturnToAirbase(unit) then
            return false
        end
        return true
    end

---@diagnostic disable-next-line: return-type-mismatch
    return coroutine.wrap(function ()
        for nearbyUnit in gen.nearbyUnits(tile, searchRadius, searchMaps) do
            if isQualifiedDefender(nearbyUnit) then
                coroutine.yield(nearbyUnit)
            end
        end
    end)
end

---Computes the "combat support" that the attacker and defender
---receive from nearby units.  Note, the attacker and defender
---each receive 1 support from themselves in order to make
---the math easier in later steps. 
---@param attacker unitObject
---@param defender unitObject
---@param combatTile tileObject
---@return integer # Support the attacker receives
---@return integer # Support the defender receives
local function computeSupportValues(attacker,defender,combatTile)
    local attackTribe = attacker.owner
    local defenseTribe = defender.owner
    local function computeUnitSupport(possibleSupporter)
        local typeInfo = combatParameters[possibleSupporter.type.id]
        if not typeInfo then 
            return 0,0
        end
        if possibleSupporter.owner == attackTribe then
            if possibleSupporter == attacker then
                return 1,0
            end
            local range = typeInfo.attackSupportRange
            if range < gen.tileDist(combatTile,possibleSupporter.location) or not helper.canReturnToAirbase(possibleSupporter) then
                return 0,0
            end
            if possibleSupporter.location.z ~= combatTile.z then
                return 0,0
            end
            local support = typeInfo["attackSupport"..helper.getCombatSuffix(possibleSupporter.location.z,combatTile.z)] or 0
            return support,0
        elseif possibleSupporter.owner == defenseTribe then
            if possibleSupporter == defender then
                return 0,1
            end
            local range = typeInfo.defenseSupportRange
            if range < gen.tileDist(combatTile,possibleSupporter.location) 
            or not helper.canReturnToAirbase(possibleSupporter) then 
                return 0,0
            end
            local support = typeInfo["defenseSupport"..helper.getCombatSuffix(possibleSupporter.location.z,combatTile.z)] or 0
            return 0,support
        end
        return 0,0
    end
    local attackerSupport,defenderSupport = 0,0
    local searchMaps = {}
    if combatTile.z == 2 then
        searchMaps[1] = 2
    else
        searchMaps[1] = 0
        searchMaps[2] = 1
    end
    for possibleSupporter in gen.nearbyUnits(combatTile, combatParameters.maxInterceptionRange, searchMaps) do
        local newAttackSupport,newDefenseSupport = computeUnitSupport(possibleSupporter)
        attackerSupport = attackerSupport+ newAttackSupport
        defenderSupport = defenderSupport+ newDefenseSupport
    end
    return math.max(1,attackerSupport),math.max(1,defenderSupport)
end



--      combat calculation
--  Here, you can modify the combat statistics of units
--  By default, an implementation of the standard combat calculator is used
--  The combatModifier table has the following keys:
--[[
Modifiers that can be disabled by setting their value to "1" (the numeric value, without quotes):
	aVeteran
	aPartisans
	aParadrop
	aSneakAttack
	aEasiestLevelHumanAttacker
	aEasyLevelsHumanDefender
	aBarbarianAttackerVsHumanDefender
	aBarbarianAttackerVsAiDefender
	aBarbarianAttackerVsDefendersOnlyCity
	aBarbarianAttackerVsDefendersCapitalCity
	aBarbarianAttackerVsDefenderWithGreatWall
	aGreatWallVsBarbarianDefender
	aFirepowerCaughtInPort
	dVeteran
	dScramblingFighterVsBomber
	dScramblingFighterVsFighter
	dHelicopter
	dCityWalls
	dFortress
	dFortified
	dPikemenFlag
	dAegisFlagVsMissile
	dAegisFlagVsOtherAir
	dSdiDefenseVsMissile
	dSamMissileBattery
	dCoastalFortress
	dBarbarianDefenderArchers
	dBarbarianDefenderLegion

Modifiers that can be disabled by setting their value to "false" (the boolean value, without quotes):
	aMovesRemainingCheck
	aFirepowerShoreBombardmentCheck
	dBaseTerrainCheck
	dFirepowerHelicopterCheck
	dFirepowerShoreBombardmentCheck
	dFirepowerCaughtInPortCheck
	dFirepowerSubmarineFlagCheck

Modifiers that can be disabled by setting their value to "0" (the numeric value, without quotes):
	dRiverAddition
]]

-- These modifiers can be overridden by setting assigning a value to the same key in
-- the table combatModifierOverride.
--
-- By default, the modifiers use the standard Civ II value, or read the value from the active
-- rules.txt file in the scenario's folder.  If you wish to change these values on a more permanent
-- basis (until the scenario is loaded again -- treat as an 'ephemeral' TOTPP setting),
-- use the function
-- combatCalculator.setCombatModifier(modifierKey,value), e.g.
-- combatCalculator.setCombatModifier("dCityWalls",2)
--
-- You can also check the modifier's value by using
-- combatCalculator.getCombatModifier(modifierKey)
--
-- You can reset all the values by using
-- combatCalculator.initializeCombatModifiers()

-- In addition to the combat modifier keys, six additional keys can
-- be added to combatModifierOverride to change values
-- These can be used to add extra bonuses or penalties based on your own logic
--      aCustomAdd -- add this to attack before multipliers are applied (negative number to subtract,
--                              attack will be set to 1 if this would set it lower)
--      dCustomAdd -- add this to defense before multipliers are applied (negative number to subract,
--                              defense will be set to 0 if this would set it lower)
--      aCustomMult -- multiply the attacker's strength by this much (to supply a custom bonus or penalty)
--      dCustomMult -- multiply the defender's strength by this much (to supply a custom bonus or penalty)
--      aAddFirepower -- add this to the attacker's firepower before any other calculations (negative number to
--                          subtract, but min firepower will be 1)
--      dAddFirepower -- add this to the defender's firepower before any other calculations (negative number to
--                          subtract, but min firepower will be 1)
--      dTerrainDefenseValue -- overrides the terrain defense bonus (normally calculated by baseTerrain.defense/2) 
--          requires combatCalculator version 2 to have any effect

local function computeCombatStatistics(attacker, defender, isSneakAttack,originalDefenderLocation,tileToDefend)
    
    local defenderSuffix = helper.getCombatSuffix(originalDefenderLocation.z,tileToDefend.z)
    local attackerSuffix = helper.getCombatSuffix(attacker.location.z,tileToDefend.z)
    local attackerParams = combatParameters[attacker.type.id]
    local defenderParams = combatParameters[defender.type.id]

    local attackSupport,defenseSupport = computeSupportValues(attacker, defender, tileToDefend)
    attackSupport = math.log(attackSupport,2)
    defenseSupport = math.log(defenseSupport,2)
    local combatModifierOverride = {
        aCustomMult=1,
        dCustomMult=1,
        dTerrainDefenseValue=tileToDefend.baseTerrain.defense/2,
        aCustomAdd = attackerParams["attackMod"..attackerSuffix]+attackSupport,
        dCustomAdd = defenderParams["defenseMod"..defenderSuffix]+defenseSupport,
    }
    -- Modifier from rules files:
    local aMult, dMult = rules.combatGroupCustomModifiers(attacker,defender)
    combatModifierOverride.aCustomMult = combatModifierOverride.aCustomMult*aMult
    combatModifierOverride.dCustomMult = combatModifierOverride.dCustomMult*dMult
    combatModifiers.applyRegisteredRules(attacker,defender,combatModifierOverride)



	local attackerStrength, attackerFirepower, defenderStrength, defenderFirepower,
		   attackerStrengthModifiersApplied, attackerFirepowerModifiersApplied, 
           defenderStrengthModifiersApplied, defenderFirepowerModifiersApplied
                = combatCalculator.getCombatValues(attacker,defender, isSneakAttack,combatModifierOverride)
	
    -- if you want to do something after the standard computations, you can do it here

    -- if you need to log modifiers for debugging, set this to true
    if false then
        print(attackerStrengthModifiersApplied)
        print(attackerFirepowerModifiersApplied)
        print(defenderStrengthModifiersApplied)
        print(defenderFirepowerModifiersApplied)
    end
    

    return attackerStrength, attackerFirepower, defenderStrength, defenderFirepower
end


-- this is useful for defenderValueModifier
local function tileHasCarrierUnit(tile)
    for unit in tile.units do
        if gen.isCarryAir(unit.type) then
            return true
        end
    end
    return false
end
-- use this function to add to (or subtract from) the calculated
-- defender value in order to change onChooseDefender
-- e.g. if you add 1e8 (100 million) to all air in air protected stacks
-- when attacked by a fighter, air units will always defend first if they
-- are available.
-- If the combat calculator gives an attacker an attack value of 0,
-- this is converted to a defenderValue of 1e7 (10 million)
-- If you want this to defend (and cancel the attack) instead of the air unit
-- (presuming it isn't an air unit itself), you could add 1e6 (1 million) instead
-- calculated defenderValues are defenderStrength/attackerStrength*healthPercentage.
-- This should be less than 10,000 (127*8 = 1016), unless you have defense multipliers 
-- of 10 or more, and an attacker with 1 attack and facing a 1/8 penalty.
local function defenderValueModifier(defender,tile,attacker)
    if simpleSettings.fightersAttackAirFirst and
        gen.isAttackAir(attacker.type) and defender.type.domain == domain.air 
        and defender.type.range >= 2 and
        not gen.hasAirbase(tile) and not tile.city and
        not tileHasCarrierUnit(tile) then
        return 1e8
    end
    if defender.type.domain == domain.ground and tile.baseTerrain.type == 10 then
        return -1e8
    end
    return 0
end
--[[
-- a sample function for making fighters attack air protected
-- stacks first.  Replaces above function if simpleSettings
-- key is set to true
if simpleSettings.fightersAttackAirFirst then
    local function tileHasCarrierUnit(tile)
        for unit in tile.units do
            if gen.isCarryAir(unit.type) then
                return true
            end
        end
        return false
    end
    defenderValueModifier = function(defender,tile,attacker)
        if gen.isAttackAir(attacker.type) and defender.type.domain == 1 
            and defender.type.range >= 2 and
            not gen.hasAirbase(tile) and not tile.city and
            not tileHasCarrierUnit(tile) then
            return 1e8
        else
            return 0
        end

    end
end
--]]


-- register.onChooseDefender
--Registers a function that is called every time a unit is chosen to defend a tile.
--The first parameter is the default function as implemented by the game.
--It takes `tile` and `attacker` as parameters. You can call this to produce a 
--result for cases you don't need to handle yourself. The second parameter 
--is the tile that's being considered, the third is the attacking unit, and the 
--fourth, `isCombat`, is a boolean that indicates if this invocation will be 
--followed by combat. This function is also called by the AI to determine its 
--goals, in which case `isCombat` is false.
local defendedTile = nil
function register.onChooseDefender(defaultFunction,tile,attacker,isCombat)
    if isCombat then
        defendedTile = tile
    end
    local bestDefenderValue = -math.huge
    local bestDefender = nil
    for possibleDefender in potentialDefenders(tile, attacker) do
        local attackerStrength, attackerFirepower, defenderStrength, defenderFirepower
            = computeCombatStatistics(attacker,possibleDefender,false,possibleDefender.location,tile)
        -- below is what appears to be the standard civ II calculation
        --local defenderValue = defenderStrength*possibleDefender.hitpoints//possibleDefender.type.hitpoints
        -- instead of defender strength, however, defenderStrength/attackerStrength is used to account
        -- for attack buffs/debuffs (which are very few in original game)
        local defenderValue = nil
        if attackerStrength == 0 then
            defenderValue = 1e7 -- 10 million
        else
            defenderValue = (defenderStrength/attackerStrength)*possibleDefender.hitpoints/possibleDefender.type.hitpoints
        end
        defenderValue = defenderValue + defenderValueModifier(possibleDefender,tile,attacker)
        if defenderValue > bestDefenderValue or 
            (defenderValue == bestDefenderValue and possibleDefender.id < bestDefender.id) then
            bestDefenderValue = defenderValue
            bestDefender = possibleDefender
        end
    end
    return bestDefender
    --return defaultFunction(tile,attacker)
end

--- Increments attacker's move spent, and changes the
--- aircraft range to 1 so the game doesn't automatically spend all
--- the remaining movement points (unless the aircraft has used them all up).
---@param attacker unitObject The attacking aircraft
---@param attackerMoveCost? integer the movement cost to spend (default uses the combatParameters)
local function aircraftMovementAfterAttack(attacker,attackerMoveCost)
    attackerMoveCost = attackerMoveCost or  combatParameters[attacker.type.id].attackMoveCost
    attacker.moveSpent = math.min(255,attacker.moveSpent +attackerMoveCost*totpp.movementMultipliers.aggregate)
    -- did not use gen.spendMovementPoints since that would automatically
    -- increment domainSpec if all movement points were used up, 
    -- and it would be incremented again autmatically by the game if range
    -- is not set to 1.
    if gen.moveRemaining(attacker) > 0 then
        attacker.type.range = 1
    end
end

---Puts aircraft where they should be when combat ends.
---Escaping aircraft won't be placed in a city or in a stack that already has 3 aircraft.
---@param winningAircraft unitObject|nil The unit which defeated or chased away the other aircraft.  If combat ended due to the maximum number of combat rounds, use nil.
---@param escapingAircraft unitObject|nil This is the unit which 'escaped' the combat, or nil if combat ended due to defeat or maximum combat rounds.
---@param defender unitObject The unit which was the defender/victim of the combat.
---@param origDefenderLocation tileObject The tile where the defender was before the attack.
local function aircraftEscapeCleanUp(winningAircraft,escapingAircraft,defender,origDefenderLocation)
    if winningAircraft == defender or 
        (winningAircraft == nil and defender.hitpoints > 0)  then
        defender:teleport(origDefenderLocation)
    end
    if escapingAircraft then
        local escapeDist = combatParameters[escapingAircraft.type.id].interceptionRange + 1 --[[@as integer]]
        local function allowedTiles(possibleTile)
            if gen.distance(escapingAircraft,possibleTile) < escapeDist or
                possibleTile.city then
                return false
            end
            local tileCount = 0
            for unit in possibleTile.units do
                tileCount = tileCount+1
                if tileCount > combatParameters.maxEscapeStack then
                    return false
                end
            end
            return true
        end
        local escapeTile = nil -- The tile the escapingAircraft will go to
        local escapeRadius = escapeDist + 1 -- The radius of tiles to search for an escape tile.  Increments until an open tile is found
        repeat
            escapeTile = gen.getRandomNearbyOpenTileForTribe(escapingAircraft.location, escapeRadius, allowedTiles, escapingAircraft.owner)
            escapeRadius = escapeRadius+1
        until civ.isTile(escapeTile)
        escapingAircraft:teleport(escapeTile --[[@as tileObject]])
    end
end

function register.onInitiateCombatMakeCoroutine(attacker,defender,attackerDie,attackerPower,defenderDie,defenderPower,isSneakAttack)

    local originalDefenderLocation = defender.location
    if originalDefenderLocation ~= defendedTile then
        defender:teleport(defendedTile)
    end
    defendedTile = nil

    local attackerStrength, attackerFirepower, defenderStrength, defenderFirepower = computeCombatStatistics(attacker, defender, isSneakAttack,originalDefenderLocation,defender.location)
    local maxCombatRounds = math.huge -- If you want to limit combat to a specific number of
                                        -- turns, set this variable
    local minCombatRounds = 0 -- combat must last at least this long (unless
    -- a defender has been killed).  This is changed below
    local defenderStackSize = 0
    local unitsOnTile = 0
    for u in defender.location.units do
        unitsOnTile = unitsOnTile+1
    end
    local combatType = nil
    local attackerParams = combatParameters[attacker.type.id]
    local defenderParams = combatParameters[defender.type.id]
    local attackerEscapeChance = 0
    local defenderEscapeChance = 0
    -- combat takes place on the attacker's map
    local mapTitle = "low"
    local MapTitle = "Low"
    if attacker.location.z == 0 then
        mapTitle = "low"
        MapTitle = "Low"
    elseif attacker.location.z == 1 then
        mapTitle = "high"
        MapTitle = "High"
    elseif attacker.location.z == 2 then
        mapTitle = "night"
        MapTitle = "Night"
    end
    attackerEscapeChance = combatParameters[mapTitle.."EscapeScale"]
    defenderEscapeChance = combatParameters[mapTitle.."EscapeScale"]
    if attacker.veteran then
        attackerEscapeChance = attackerEscapeChance * 
        combatParameters[mapTitle.."AceEscapeModifier"]
        defenderEscapeChance = defenderEscapeChance *
        combatParameters[mapTitle.."AcePursuitModifier"]
    end
    if defender.veteran then
        defenderEscapeChance = defenderEscapeChance * combatParameters[mapTitle.."AceEscapeModifier"]
        attackerEscapeChance = attackerEscapeChance * combatParameters[mapTitle.."AcePursuitModifier"]
    end
    attackerEscapeChance = attackerEscapeChance*attackerParams["escapeSpeed"..MapTitle]/(attackerParams["escapeSpeed"..MapTitle]+defenderParams["escapeSpeed"..MapTitle])
    defenderEscapeChance = defenderEscapeChance*defenderParams["escapeSpeed"..MapTitle]/(attackerParams["escapeSpeed"..MapTitle]+defenderParams["escapeSpeed"..MapTitle])
    civ.ui.text("Attacker Escape Probability: "..tostring(attackerEscapeChance),
        "^Defender Escape Chance: "..tostring(defenderEscapeChance),"^Attacker Strength: "..tostring(attackerStrength/8),"Defender Strength: "..tostring(defenderStrength/8))
    if traits.hasAnyTrait(defender.type,"fighter","fighterBomber") and traits.hasAnyTrait(attacker.type,"fighter","fighterBomber") then
        combatType = "FighterAttackingFighter"
        maxCombatRounds = combatParameters.maxAirCombatRounds
        minCombatRounds = combatParameters.minAirCombatRounds + 
        unitsOnTile*combatParameters.minAirCombatRoundIncrement
    elseif traits.hasAnyTrait(attacker.type,"fighter","fighterBomber")
    and traits.hasAnyTrait(defender.type,"bomber") then
        combatType = "FighterAttackingBomber"
        maxCombatRounds = combatParameters.maxAirCombatRounds
        minCombatRounds = combatParameters.minAirCombatRounds + 
        unitsOnTile*combatParameters.minAirCombatRoundIncrement
    end

    if combatType == "FighterAttackingFighter" then
        return coroutine.create(function()
            local round = 0
            while true do
                if round >= maxCombatRounds then
                    aircraftMovementAfterAttack(attacker)
                    aircraftEscapeCleanUp(nil,nil,defender,originalDefenderLocation)
                    return
                elseif attacker.hitpoints <= 0 then
                    aircraftEscapeCleanUp(defender,nil,defender,originalDefenderLocation)
                    return
                elseif defender.hitpoints <= 0 then
                    aircraftMovementAfterAttack(attacker)
                    aircraftEscapeCleanUp(attacker,nil,defender,originalDefenderLocation)
                    return
                elseif attacker.hitpoints < combatParameters.fighterEscapeThreshold * defenderFirepower 
                    and round >= minCombatRounds
                    and math.random() < attackerEscapeChance then
                    aircraftMovementAfterAttack(attacker)
                    aircraftEscapeCleanUp(defender,attacker,defender,originalDefenderLocation)
                    return
                elseif defender.hitpoints < combatParameters.fighterEscapeThreshold * attackerFirepower 
                    and round >= minCombatRounds
                    and math.random() < defenderEscapeChance then
                    aircraftMovementAfterAttack(attacker)
                    aircraftEscapeCleanUp(attacker,defender,defender,originalDefenderLocation)
                    return
                end
                local result = coroutine.yield(false,
                    attackerStrength,attackerFirepower,
                    defenderStrength,defenderFirepower)
                round = round + 1
            end
        end)
    elseif combatType == "FighterAttackingBomber" then
        return coroutine.create(function()
            local round = 0
            while true do
                if round >= maxCombatRounds then
                    aircraftMovementAfterAttack(attacker)
                    aircraftEscapeCleanUp(nil,nil,defender,originalDefenderLocation)
                    return
                elseif attacker.hitpoints <= 0 then
                    aircraftEscapeCleanUp(defender,nil,defender,originalDefenderLocation)
                    return
                elseif defender.hitpoints <= 0 then
                    aircraftMovementAfterAttack(attacker)
                    aircraftEscapeCleanUp(attacker,nil,defender,originalDefenderLocation)
                    return
                elseif attacker.hitpoints < combatParameters.fighterEscapeThreshold * defenderFirepower 
                    and round >= minCombatRounds
                    and math.random() < attackerEscapeChance then
                    aircraftMovementAfterAttack(attacker)
                    aircraftEscapeCleanUp(defender,attacker,defender,originalDefenderLocation)
                    return
                elseif math.random() < defenderEscapeChance 
                    and round >= minCombatRounds
                    then
                    aircraftMovementAfterAttack(attacker)
                    aircraftEscapeCleanUp(attacker,defender,defender,originalDefenderLocation)
                    return
                end
                local result = coroutine.yield(false,
                    attackerStrength,attackerFirepower,
                    defenderStrength,defenderFirepower)
                round = round + 1
            end
        end)

    else
        -- Regular Combat
        return coroutine.create(function()
            local round = 0
            while(round < maxCombatRounds and attacker.hitpoints >0 and defender.hitpoints > 0) do
                local result = coroutine.yield(false,attackerStrength,
                attackerFirepower,defenderStrength,defenderFirepower)
            end
        end)
    end
end
--[[
    return coroutine.create(function()
        local round = 0
        while(round < maxCombatRounds and attacker.hitpoints >0 and defender.hitpoints > 0) do

            if false then
                -- If the coroutine yields true as its first value, 
                -- the game's default combat resolution is skipped for that round 
                -- and the designer is responsible for updating damage. 
                -- The second value yielded is either the attacker or the defender, 
                -- this is used to render animations etc. 
                -- In this case the coroutine resumes without any values.

                coroutine.yield(true,defender)
            elseif combatType == "FighterAttackingFighter" then
                if round > combatParameters.minAirCombatRounds then
                    if attacker.hitpoints < combatParameters.fighterEscapeThreshold * defenderFirepower 
                    and math.random() < attackerEscapeChance then
                        aircraftMovementAfterAttack(attacker)
                        return
                    elseif defender.hitpoints < combatParameters.fighterEscapeThreshold * attackerFirepower 
                    and math.random() < defenderEscapeChance then
                        aircraftMovementAfterAttack(attacker)
                        return
                    else
                        local aRoll = math.random(0,attackerStrength)
                        local dRoll = math.random(0,defenderStrength)
                        if aRoll > dRoll then
                            defender.damage = defender.damage+attackerFirepower
                            coroutine.yield(true,defender)

                        else
                            attacker.damage = attacker.damage+defenderFirepower
                            coroutine.yield(true,attacker)
                        end
                        --local result = coroutine.yield(false,attackerStrength,attackerFirepower,defenderStrength,defenderFirepower)
                   end
                else
                        local aRoll = math.random(0,attackerStrength)
                        local dRoll = math.random(0,defenderStrength)
                        if aRoll > dRoll then
                            defender.damage = defender.damage+attackerFirepower
                            coroutine.yield(true,defender)

                        else
                            attacker.damage = attacker.damage+defenderFirepower
                            coroutine.yield(true,attacker)
                        end
                    --local result = coroutine.yield(false,attackerStrength,attackerFirepower,defenderStrength,defenderFirepower)
                end
            elseif combatType == "FighterAttackingBomber" then
                if round > combatParameters.minAirCombatRounds then
                    if attacker.hitpoints < combatParameters.fighterEscapeThreshold * defenderFirepower 
                    and math.random() < attackerEscapeChance then
                        aircraftMovementAfterAttack(attacker)
                        return
                    elseif math.random() < defenderEscapeChance then
                        aircraftMovementAfterAttack(attacker)
                        return
                    else
                        local result = coroutine.yield(false,attackerStrength,attackerFirepower,defenderStrength,defenderFirepower)
                   end
                else
                    local result = coroutine.yield(false,attackerStrength,attackerFirepower,defenderStrength,defenderFirepower)
                end
            elseif combatType == "BombingAttack" then

            elseif combatType == "BombingAttackIntercepted" then

            elseif combatType == "GroundCombat" then

            elseif combatType == "SubmarineAttack" then

            elseif combatType == "AntiSubAttack" then


            else

                --If the coroutine yields false as its first value, 
                --the game runs its default combat algorithm. The designer 
                --can additionally yield modified values for attackerDie, 
                --attackerPower, defenderDie and defenderPower (in this order) 
                --which will be used by the game for that round.

                local newAttackerDie = calculatedAttackerStrength
                local newAttackerFirepower = calculatedAttackerFirepower
                local newDefenderDie = calculatedDefenderStrength
                local newDefenderFirepower = calculatedDefenderFirepower
                local result = coroutine.yield(false,newAttackerDie,newAttackerFirepower,newDefenderDie,newDefenderFirepower)

                --In this case the coroutine resumes with the result of the round, 
                --a table containing four values:
                    -- winner, this is either attacker or defender.
                    -- attackerRoll, the result of the attacker's die roll
                    -- defenderRoll, the result of the defender's die roll
                    -- reroll, true if a reroll happened. This can happen only 
                         -- if the attacker is tribe 0, the defender is a unit 
                         -- guarding a city, and the city is the capital or 
                         -- the tribe has less than 8 cities in total and 
                         -- the attacker's die roll is higher than the 
                         -- defender's. A reroll can happen at most once.


            end
            round = round+1
        end
        -- once we get here, combat stops
        if combatType == "FighterAttackingFighter" or combatType == "FighterAttackingBomber" then
            gen.spendMovementPoints(attacker,attackerMoveCost, 
                totpp.movementMultipliers.aggregate, 
                math.min(255,attackerMoveSpent+attackerMoveCost*totpp.movementMultipliers.aggregate))
            if gen.moveRemaining(attacker) > 0 then
                attacker.type.range = 1
            else
                attacker.domainSpec = attacker.domainSpec-1
            end
        end

    end)
end
]]

discreteEvents.onActivateUnit(function(unit,source,repeatMove)
    unit.type.range = changeRules.authoritativeDefaultRules[unit.type].range
end)


--[[
function register.onInitiateCombatMakeCoroutine(attacker,defender,attackerDie,attackerPower,defenderDie,defenderPower,isSneakAttack)

    local maxCombatRounds = math.huge -- If you want to limit combat to a specific number of
                                        -- turns, set this variable

    local calculatedAttackerStrength, 
            calculatedAttackerFirepower,
            calculatedDefenderStrength, 
            calculatedDefenderFirepower = computeCombatStatistics(attacker,defender,isSneakAttack)
    --if calculatedAttackerStrength ~= attackerDie then
    --    civ.ui.text("Attacker: calculated: "..calculatedAttackerStrength.." actual: "..attackerDie)
    --end
    --if calculatedDefenderStrength ~= defenderDie then
    --    civ.ui.text("Defender: calculated: "..calculatedDefenderStrength.." actual: "..defenderDie)
    --end
    --if calculatedAttackerFirepower ~= attackerPower then
    --    civ.ui.text("AttackerFP: calculated: "..calculatedAttackerFirepower.." actual: "..attackerPower)
    --end
    --if calculatedDefenderFirepower ~= defenderPower then
    --    civ.ui.text("DefenderFP: calculated: "..calculatedDefenderFirepower.." actual: "..defenderPower)
    --end
    if calculatedAttackerStrength == 0 then
        maxCombatRounds = 0
        if attacker.owner.isHuman then
            text.simple("Our "..attacker.type.name.." unit can't fight the defending "..defender.type.name..".  The attack has been cancelled.","Defense Minister")
        end
    end
    -- %Report Combat Strength%
    --civ.ui.text("Attacker: "..tostring(calculatedAttackerStrength/8).." FP:"..calculatedAttackerFirepower.." Defender: "..tostring(calculatedDefenderStrength/8).." FP:"..calculatedDefenderFirepower)
            
    return coroutine.create(function()
        local round = 0
        while(round < maxCombatRounds and attacker.hitpoints >0 and defender.hitpoints > 0) do

            if false then
                -- If the coroutine yields true as its first value, 
                -- the game's default combat resolution is skipped for that round 
                -- and the designer is responsible for updating damage. 
                -- The second value yielded is either the attacker or the defender, 
                -- this is used to render animations etc. 
                -- In this case the coroutine resumes without any values.

                coroutine.yield(true,defender)
            else

                --If the coroutine yields false as its first value, 
                --the game runs its default combat algorithm. The designer 
                --can additionally yield modified values for attackerDie, 
                --attackerPower, defenderDie and defenderPower (in this order) 
                --which will be used by the game for that round.

                local newAttackerDie = calculatedAttackerStrength
                local newAttackerFirepower = calculatedAttackerFirepower
                local newDefenderDie = calculatedDefenderStrength
                local newDefenderFirepower = calculatedDefenderFirepower
                local result = coroutine.yield(false,newAttackerDie,newAttackerFirepower,newDefenderDie,newDefenderFirepower)

                --In this case the coroutine resumes with the result of the round, 
                --a table containing four values:
                    -- winner, this is either attacker or defender.
                    -- attackerRoll, the result of the attacker's die roll
                    -- defenderRoll, the result of the defender's die roll
                    -- reroll, true if a reroll happened. This can happen only 
                         -- if the attacker is tribe 0, the defender is a unit 
                         -- guarding a city, and the city is the capital or 
                         -- the tribe has less than 8 cities in total and 
                         -- the attacker's die roll is higher than the 
                         -- defender's. A reroll can happen at most once.


            end
            round = round+1
        end
        -- once we get here, combat stops
    end)
end
--]]




return register