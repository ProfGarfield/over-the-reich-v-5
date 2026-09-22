-- MechanicsFiles/groundCombat.lua
-- Air vs ground multipliers. Flak not included.
-- events.lua: attemptToRun('groundCombat',"WARNING: groundCombat.lua not found. Air-to-ground role/HP mods will not run.")

local object    = require("object")
local gen       = require("generalLibrary")
local combatMod = require("combatModifiers")
local text      = require("text")

local groundCombat = {}

local ABORT_BELOW = 0.15
local JABO_TRAIN_FLOOR = 0.15
local VET_MOD = 1.10
local SHOW_TOAST = true

local ROLE_TARGET = {
    heavyBomber     = { high = 1.00, low = 0.45, train = 0.55, parked = 0.40 },
    mediumBomber    = { high = 0.75, low = 1.15, train = 0.90, parked = 0.80 },
    jabo            = { high = 0.55, low = 1.20, train = 1.40, parked = 1.45 },
    airSuperiority  = { high = 0.20, low = 0.70, train = 0.90, parked = 1.10 },
    bomberDestroyer = { high = 0.20, low = 0.70, train = 0.90, parked = 1.10 },
}

local PARKED_DEF = {
    jabo            = 0.35,
    mediumBomber    = 0.75,
    heavyBomber     = 0.55,
    airSuperiority  = 0.40,
    bomberDestroyer = 0.40,
}

local function addIds(set, ...)
    for i = 1, select("#", ...) do
        local ut = select(i, ...)
        if ut then set[ut.id] = true end
    end
end

local heavyBomber = {}
addIds(heavyBomber,
    object.uHe177, object.uHe277,
    object.uStirling, object.uHalifax, object.uLancaster, object.uLancasterPathfinder,
    object.uB17FFortress, object.uB17FDamaged, object.uB17GFortress, object.uB17GDamaged,
    object.uB24Liberator, object.uB17Pathfinder, object.uB24Pathfinder,
    object.u15thAFB24
)

local mediumBomber = {}
addIds(mediumBomber,
    object.uBaltimoreV, object.uBostonIII, object.uWellington, object.uMosquitoBIV,
    object.uWellingtonRCM, object.uA20GHavoc, object.uA26BInvader,
    object.uB25Mitchell, object.uB26Marauder,
    object.u15thAFB25, object.uMedAirWellington,
    object.uJu88C6, object.uJu88G, object.uDo217N2, object.uMe210, object.uMe410B2, object.uMe410B2R3,
    object.uArado234
)

local jabo = {}
addIds(jabo,
    object.uFw190F,
    object.uP38JJabo, object.uP38LJabo,
    object.uP47D15Jabo, object.uP47D20Jabo, object.uP47D25Jabo,
    object.uP51BJabo, object.uMustangIIIJabo, object.uP51DJabo, object.uMustangIVJabo,
    object.uHurricaneIV, object.uMustangI, object.uTyphoonIB, object.uTempestV,
    object.uIl2, object.uWhirlwindIA
)

local bomberDestroyer = {}
addIds(bomberDestroyer,
    object.uBf109G6R6, object.uBf109G10R6, object.uBf109G14R6,
    object.uFw190A6R6, object.uFw190A8R6,
    object.uBf110G2R3
)

local trainType = {}
addIds(trainType, object.uFreightTrain, object.uFuelTrain)

local fighterType = {}
addIds(fighterType,
    object.uMS406,
    object.uBf109G6, object.uBf109G6R6, object.uBf109G10, object.uBf109G10R6,
    object.uBf109G14, object.uBf109G14R6, object.uBf109K4,
    object.uFw190A5, object.uFw190A6, object.uFw190A6R6, object.uFw190A8,
    object.uFw190A8R6, object.uFw190D9, object.uTa152,
    object.uSpitfireMkV, object.uSpitfireMkIXLF, object.uSpitfireMkIX, object.uSpitfireMkXIV,
    object.uP47D6Thunderbolt, object.uP47D15Thunderbolt, object.uP47D20Thunderbolt,
    object.uP47D25Thunderbolt, object.uP47MThunderbolt,
    object.uP51BMustang, object.uMustangIII, object.uP51DMustang, object.uMustangIV,
    object.uP38HLightning, object.uP38JLightning, object.uP38LLightning,
    object.uYak3, object.uLa7,
    object.uHe162A, object.uMe163, object.uTa183, object.uP80ShootingStar,
    object.uMe262, object.uGo229, object.uMeteor,
    object.uExperten, object.uUSAce, object.uUKAce,
    object.uEgonMayer, object.uHermannGraf, object.uJosefPriller,
    object.uGuntherRall, object.uErichHartmann,
    object.uFrancisGabreski, object.uGeorgePreddy,
    object.uJohnBraham, object.uJohnnieJohnson,
    object.uAdolfGalland, object.uWalterNowotny,
    object.u332ndFighterGroup
)

local function roleOf(unit)
    local id = unit.type.id
    if heavyBomber[id] then return "heavyBomber" end
    if mediumBomber[id] then return "mediumBomber" end
    if jabo[id] then return "jabo" end
    if bomberDestroyer[id] then return "bomberDestroyer" end
    if unit.type.domain == 1 then return "airSuperiority" end
    return nil
end

local function isAir(unit)
    return unit and unit.type and unit.type.domain == 1
end

local function tileIsHigh(tile)
    return tile and (tile.z == 1 or tile.z == 3)
end

local function tileIsAirfield(tile)
    if not tile then return false end
    if gen.hasAirbase and gen.hasAirbase(tile) then return true end
    local bt = tile.baseTerrain
    if not bt then return false end
    return bt == object.bAirfieldDayLow
        or bt == object.bAirfieldDayHigh
        or bt == object.bAirfieldNightLow
        or (object.bAirfieldNightHigh and bt == object.bAirfieldNightHigh)
        or bt.type == 6
end

local function isParkedFighter(unit)
    if not unit then return false end
    if not fighterType[unit.type.id] then return false end
    return tileIsAirfield(unit.location)
end

local function targetColumn(defender)
    if trainType[defender.type.id] then return "train" end
    if isParkedFighter(defender) then return "parked" end
    if tileIsHigh(defender.location) then return "high" end
    return "low"
end

local lastToastKey = nil

local function maybeToast(attacker, defender, atkMult, defMult, role, col, frac, vetMod, aborted)
    if not SHOW_TOAST then return end
    local key = tostring(civ.getTurn()).."#"..tostring(attacker.id).."#"..tostring(defender.id)
    if lastToastKey == key then return end
    lastToastKey = key
    local hpStr = string.format("%.2f", frac)
    local msg
    if aborted then
        msg = attacker.type.name.." crew aborted (HP "..hpStr..")"
    else
        msg = attacker.type.name.." ["..role.."] vs "..defender.type.name
            .." ["..col.."] ATK x"..string.format("%.2f", atkMult)
            .." (role"..col.." "..string.format("%.2f", ROLE_TARGET[role][col])
            .." hp "..hpStr
            .." vet "..string.format("%.2f", vetMod)
            ..") DEF x"..string.format("%.2f", defMult)
    end
    text.simple(msg, "Ground Attack")
end

local function hpFrac(unit)
    if not unit or not unit.type or unit.type.hitpoints < 1 then return 1 end
    return unit.hitpoints / unit.type.hitpoints
end

combatMod.registerCombatModificationRule({
    customCheck = function(attacker, defender)
        if not attacker or not defender then return false end
        if not isAir(attacker) then return false end
        if isAir(defender) and not isParkedFighter(defender) then return false end
        if roleOf(attacker) == nil then return false end
        return true
    end,
    aCustomMult = function(attacker, defender)
        local role = roleOf(attacker)
        local col = targetColumn(defender)
        local roleMod = ROLE_TARGET[role][col] or 1
        local frac = hpFrac(attacker)
        local aborted = false
        if frac < ABORT_BELOW then
            if role == "jabo" and col == "train" then
                frac = JABO_TRAIN_FLOOR
            else
                aborted = true
                frac = 0.01
            end
        end
        local vetMod = attacker.veteran and VET_MOD or 1.00
        local product = roleMod * frac * vetMod
        maybeToast(attacker, defender, product, 1, role, col, hpFrac(attacker), vetMod, aborted)
        return product
    end,
    dCustomMult = function(attacker, defender)
        if not isParkedFighter(defender) then return 1 end
        local role = roleOf(attacker)
        return PARKED_DEF[role] or 1
    end,
})

return groundCombat