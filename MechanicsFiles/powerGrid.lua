-- MechanicsFiles/powerGrid.lua
local object         = require("object")
local helper         = require("helper")
local param          = require("parameters")
local data           = require("data")
local discreteEvents = require("discreteEventsRegistrar")

local powerGrid = {}
local MODULE = "powerGrid"

data.defineModuleCounter(MODULE, "baseline", 0, 0, nil, "none", "never", nil, false)

local cachedTurn = -1
local cachedLiving = 0
local cachedMult = 1

local function countLivingGermanPlants()
    local n = 0
    for unit in civ.iterateUnits() do
        if unit.type == object.uElectricPowerPlant
            and unit.owner == object.pGermans then
            n = n + 1
        end
    end
    return n
end

local function getBaseline()
    return data.counterGetValue("baseline", MODULE) or 0
end

local function ensureBaseline(living)
    if param.powerGridBaseline and param.powerGridBaseline > 0 then
        return param.powerGridBaseline
    end
    local base = getBaseline()
    if base <= 0 and living > 0 then
        data.counterSetValue("baseline", living, MODULE)
        return living
    end
    return base
end

local function refresh()
    local turn = civ.getTurn()
    if turn == cachedTurn then
        return
    end
    cachedTurn = turn
    cachedLiving = countLivingGermanPlants()
    local base = ensureBaseline(cachedLiving)
    if base <= 0 then
        cachedMult = 1
        return
    end
    local ratio = cachedLiving / base
    local midCut = param.powerGridMidRatio or 0.75
    local lowCut = param.powerGridLowRatio or 0.50
    if ratio >= midCut then
        cachedMult = 1
    elseif ratio >= lowCut then
        cachedMult = param.powerGridMidMult or 0.85
    else
        cachedMult = param.powerGridLowMult or 0.70
    end
end

function powerGrid.multiplier()
    refresh()
    return cachedMult
end

function powerGrid.living()
    refresh()
    return cachedLiving
end

function powerGrid.baseline()
    refresh()
    return getBaseline()
end

function powerGrid.shieldChange(city, currentShields, existingBeforeWaste)
    if city.owner ~= object.pGermans or not helper.isOTRCity(city) then
        return 0
    end
    local mult = powerGrid.multiplier()
    if mult >= 1 then
        return 0
    end
    local afterUrban = currentShields + (existingBeforeWaste or 0)
    if afterUrban <= 0 then
        return 0
    end
    return -math.floor(afterUrban * (1 - mult))
end

function discreteEvents.onScenarioLoaded()
    cachedTurn = -1
    refresh()
end

function discreteEvents.onTribeTurnBegin(turn, tribe)
    if tribe == object.pGermans then
        cachedTurn = -1
        refresh()
    end
end

return powerGrid