-- MechanicsFiles/resourceCost.lua
-- Rubber / steel / aluminum / bearings: living HP vs start HP
-- raises German aircraft build cost.
--
-- 750/1000 HP → +25% cost (missing fraction, not start/living).
-- Dead unit = 0 HP. Damaged unit = type.hitpoints - damage.
-- Not improvement-linked. German-owned factory units only.
-- Allied aircraft costs are not touched (unitType.cost is global,
-- so only German types are written).
--
-- INSTALL
--   MechanicsFiles/resourceCost.lua
--   events.lua:
--     attemptToRun('resourceCost',"WARNING: resourceCost.lua not found. Resource-factory cost multiplier will not run.")

local object         = require("object")
local param          = require("parameters")
local data           = require("data")
local discreteEvents = require("discreteEventsRegistrar")

local resourceCost = {}
local MODULE = "resourceCost"

data.defineModuleCounter(MODULE, "baselineHP", 0, 0, nil, "none", "never", nil, false)

local factoryType = {
    [object.uRubberFactory.id]   = true,
    [object.uSteelFactory.id]    = true,
    [object.uAluminumFactory.id] = true,
    [object.uBallBearingsFac.id] = true,
}

local germanAircraft = {}
local function mark(...)
    for i = 1, select("#", ...) do
        local ut = select(i, ...)
        if ut then germanAircraft[ut.id] = true end
    end
end

mark(
    object.uMS406,
    object.uBf109G6, object.uBf109G6R6, object.uBf109G10, object.uBf109G10R6,
    object.uBf109G14, object.uBf109G14R6, object.uBf109K4,
    object.uFw190A5, object.uFw190A6, object.uFw190A6R6,
    object.uFw190A8, object.uFw190A8R6, object.uFw190D9,
    object.uTa152, object.uBf110G2, object.uBf110G2R3,
    object.uMe210, object.uMe410B2, object.uMe410B2R3,
    object.uMe163, object.uMe262, object.uTa183,
    object.uFw190F, object.uDo335, object.uArado234, object.uGo229,
    object.uJu188PR, object.uHe162A,
    object.uBf110G4, object.uJu88C6, object.uJu88G, object.uHe219,
    object.uDo217N2, object.uHe177, object.uHe277
)

local baseCost = {}
local costsCaptured = false

local function remainingHP(unit)
    local maxHP = unit.type.hitpoints or 0
    local dmg = unit.damage or 0
    local hp = maxHP - dmg
    if hp < 0 then hp = 0 end
    return hp
end

local function livingHP()
    local sum = 0
    for unit in civ.iterateUnits() do
        if factoryType[unit.type.id] and unit.owner == object.pGermans then
            sum = sum + remainingHP(unit)
        end
    end
    return sum
end

local function getBaseline()
    if param.resourceCostBaselineHP and param.resourceCostBaselineHP > 0 then
        return param.resourceCostBaselineHP
    end
    return data.counterGetValue("baselineHP", MODULE) or 0
end

local function ensureBaseline(hp)
    if param.resourceCostBaselineHP and param.resourceCostBaselineHP > 0 then
        return param.resourceCostBaselineHP
    end
    local base = data.counterGetValue("baselineHP", MODULE) or 0
    if base <= 0 and hp > 0 then
        data.counterSetValue("baselineHP", hp, MODULE)
        return hp
    end
    return base
end

local function captureBaseCosts()
    if costsCaptured then
        return
    end
    for i = 0, 188 do
        local ut = civ.getUnitType(i)
        if ut and germanAircraft[ut.id] then
            baseCost[ut.id] = ut.cost
        end
    end
    costsCaptured = true
end

local function multiplier()
    local hp = livingHP()
    local base = ensureBaseline(hp)
    if base <= 0 then
        return 1
    end
    local ratio = hp / base
    if ratio > 1 then ratio = 1 end
    local mult = 1 + (1 - ratio)
    local cap = param.resourceCostCap or 1.75
    if mult > cap then mult = cap end
    return mult
end

local function applyCosts()
    captureBaseCosts()
    local mult = multiplier()
    for id, cost in pairs(baseCost) do
        local ut = civ.getUnitType(id)
        if ut then
            local newCost = math.floor(cost * mult + 0.5)
            if newCost < 1 then newCost = 1 end
            ut.cost = newCost
        end
    end
end

function discreteEvents.onScenarioLoaded()
    costsCaptured = false
    applyCosts()
end

function discreteEvents.onTribeTurnBegin(turn, tribe)
    if tribe == object.pGermans then
        applyCosts()
    end
end

resourceCost.livingHP   = livingHP
resourceCost.baselineHP = getBaseline
resourceCost.multiplier = multiplier
resourceCost.applyCosts = applyCosts

return resourceCost