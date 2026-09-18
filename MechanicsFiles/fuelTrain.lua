-- MechanicsFiles/fuelTrain.lua
-- Off-screen fuel economy for Over the Reich.

local object          = require("object")
local helper          = require("helper")
local param           = require("parameters")
local gen             = require("generalLibrary")
local aStarCiv        = require("aStarCiv")
local text            = require("text")
local data            = require("data")
local discreteEvents  = require("discreteEventsRegistrar")
local keyboard        = require("keyboard")

local fuelTrain = {}
local MODULE = "fuelTrain"

local ZONE_ORDER = {
    "Britain", "France", "NWGermany", "SWGermany", "NEGermany", "SEGermany",
}
local GERMAN_VIEW = {
    France = true, NWGermany = true, SWGermany = true,
    NEGermany = true, SEGermany = true,
}
local SILO_CITIES = {
    object.cTours, object.cNantes,
    object.cMunster, object.cAntwerp,
    object.cKoblenz, object.cStrasbourg,
    object.cHamburg, object.cBerlin,
    object.cMunchen, object.cNurnberg,
    object.cLondon, object.cBirmingham, object.cLeeds,
}

local function pSynthCount()    return param.fuelTrainSyntheticCount    or 1     end
local function pSynthInterval() return param.fuelTrainSyntheticInterval or 2     end
local function pOilCount()      return param.fuelTrainOilCount          or 1     end
local function pOilInterval()   return param.fuelTrainOilInterval       or 3     end
local function pDelivery()      return param.fuelTrainDeliveryAmount    or 500   end
local function pInitial()       return param.fuelZoneInitialStock       or 10000 end
local function pMinActivate()   return param.fuelMinToActivateAircraft  or 1     end
local function pFuelPerEngine() return param.fuelPerEngine              or 10    end
local function pJetMult()      return param.fuelJetMultiplier          or 3     end
local function pTierFull()     return param.fuelTierFull               or 7500  end
local function pTierHigh()     return param.fuelTierHigh               or 5000  end
local function pTierLow()      return param.fuelTierLow                or 2500  end
local function pFailFull()     return param.fuelFailChanceFull         or 0     end
local function pFailHigh()     return param.fuelFailChanceHigh         or 25    end
local function pFailMid()      return param.fuelFailChanceMid          or 50    end
local function pFailLow()      return param.fuelFailChanceLow          or 75    end
local function pStatusKey()
    local name = param.fuelStatusKey or "five"
    return keyboard[name] or keyboard.five
end

local pistonEngines = {}
local jetEngines = {}
local malusExempt = {}

local function piston(n, ...)
    for i = 1, select("#", ...) do
        local ut = select(i, ...)
        if ut then pistonEngines[ut.id] = n end
    end
end
local function jet(n, ...)
    for i = 1, select("#", ...) do
        local ut = select(i, ...)
        if ut then jetEngines[ut.id] = n end
    end
end
local function noMalus(...)
    for i = 1, select("#", ...) do
        local ut = select(i, ...)
        if ut then malusExempt[ut.id] = true end
    end
end

piston(1,
    object.uMS406,
    object.uBf109G6, object.uBf109G6R6, object.uBf109G10, object.uBf109G10R6,
    object.uBf109G14, object.uBf109G14R6, object.uBf109K4,
    object.uFw190A5, object.uFw190A6, object.uFw190A6R6, object.uFw190A8,
    object.uFw190A8R6, object.uFw190D9, object.uTa152, object.uFw190F,
    object.uSpitfireMkV, object.uSpitfireMkIXLF, object.uSpitfireMkIX, object.uSpitfireMkXIV,
    object.uP47D6Thunderbolt, object.uP47D15Thunderbolt, object.uP47D20Thunderbolt,
    object.uP47D25Thunderbolt, object.uP47MThunderbolt,
    object.uP51BMustang, object.uMustangIII, object.uP51DMustang, object.uMustangIV,
    object.uHurricaneIV, object.uMustangI, object.uTyphoonIB, object.uTempestV,
    object.uP47D15Jabo, object.uP47D20Jabo, object.uP47D25Jabo,
    object.uP51BJabo, object.uMustangIIIJabo, object.uP51DJabo, object.uMustangIVJabo,
    object.u332ndFighterGroup,
    object.uYak3, object.uLa7, object.uIl2,
    object.uExperten,
    object.uEgonMayer, object.uHermannGraf, object.uJosefPriller,
    object.uGuntherRall, object.uErichHartmann,
    object.uFrancisGabreski, object.uGeorgePreddy,
    object.uJohnBraham, object.uJohnnieJohnson,
    object.uUSAce, object.uUKAce
)
piston(2,
    object.uBf110G2, object.uBf110G2R3, object.uBf110G4,
    object.uMe210, object.uMe410B2, object.uMe410B2R3,
    object.uHe219, object.uDo217N2, object.uJu88C6, object.uJu88G,
    object.uDo335, object.uJu188PR,
    object.uBeaufighter, object.uMosquitoNFII, object.uMosquitoNFXIX,
    object.uP61ABlackWidow, object.uWhirlwindIA,
    object.uP38HLightning, object.uP38JLightning, object.uP38LLightning,
    object.uP38JJabo, object.uP38LJabo,
    object.uBaltimoreV, object.uBostonIII, object.uWellington, object.uMosquitoBIV,
    object.uWellingtonRCM, object.uA20GHavoc, object.uA26BInvader,
    object.uB25Mitchell, object.uB26Marauder,
    object.u15thAFB25, object.uMedAirBeaufighter, object.uMedAirWellington,
    object.uMosquitoPR,
    object.uHWSchnaufer
)
piston(4,
    object.uHe177, object.uHe277,
    object.uStirling, object.uHalifax, object.uLancaster,
    object.uB17FFortress, object.uB17FDamaged, object.uB17GFortress, object.uB17GDamaged,
    object.uB24Liberator, object.uB17Pathfinder, object.uB24Pathfinder,
    object.u15thAFB24, object.uLancasterPathfinder
)
jet(1, object.uHe162A, object.uMe163, object.uTa183, object.uP80ShootingStar)
jet(2, object.uMe262, object.uArado234, object.uGo229, object.uMeteor,
    object.uAdolfGalland, object.uWalterNowotny)

noMalus(
    object.uExperten,
    object.uEgonMayer, object.uHermannGraf, object.uJosefPriller,
    object.uAdolfGalland, object.uGuntherRall, object.uWalterNowotny,
    object.uHWSchnaufer, object.uErichHartmann,
    object.uFrancisGabreski, object.uGeorgePreddy,
    object.uJohnBraham, object.uJohnnieJohnson,
    object.uUSAce, object.uUKAce
)

local billedThisTurn = rawget(_G, "_fuelBilledThisTurn")
if not billedThisTurn then
    billedThisTurn = {}
    rawset(_G, "_fuelBilledThisTurn", billedThisTurn)
end
local rolledThisTurn = rawget(_G, "_fuelRolledThisTurn")
if not rolledThisTurn then
    rolledThisTurn = {}
    rawset(_G, "_fuelRolledThisTurn", rolledThisTurn)
end

local function billKey(unit)
    return tostring(civ.getTurn()).."#"..tostring(unit.id)
end

function fuelTrain.takeoffCost(unitType)
    if not unitType then return 0 end
    if jetEngines[unitType.id] then
        return jetEngines[unitType.id] * pFuelPerEngine() * pJetMult()
    end
    if pistonEngines[unitType.id] then
        return pistonEngines[unitType.id] * pFuelPerEngine()
    end
    return 0
end

function fuelTrain.failChance(stock)
    stock = stock or 0
    if stock >= pTierFull() then return pFailFull() end
    if stock >= pTierHigh() then return pFailHigh() end
    if stock >= pTierLow()  then return pFailMid()  end
    return pFailLow()
end

local function groundAircraft(unit)
    unit.moveSpent = 99
end

local function counterName(zoneName)
    return "fuel_"..zoneName
end

for _, zoneName in ipairs(ZONE_ORDER) do
    data.defineModuleCounter(MODULE, counterName(zoneName), pInitial(), 0, nil, "none", "never", nil, false)
end

function fuelTrain.getFuel(zoneName)
    if not zoneName then return 0 end
    return data.counterGetValue(counterName(zoneName), MODULE) or 0
end

function fuelTrain.addFuel(zoneName, amount)
    if not zoneName then return 0 end
    data.counterAdd(counterName(zoneName), amount, 0, nil, MODULE)
    return fuelTrain.getFuel(zoneName)
end

function fuelTrain.setFuel(zoneName, amount)
    if not zoneName then return end
    data.counterSetValue(counterName(zoneName), amount, MODULE)
end

function fuelTrain.zoneCanLaunch(zoneName)
    return fuelTrain.getFuel(zoneName) >= pMinActivate()
end

local function hasRR(tile)
    return tile and gen.hasRailroad(tile)
end

local function tileHasSilo(tile)
    if not tile then return false end
    for unit in tile.units do
        if unit.type == object.uFuelStorageSilos then
            return true
        end
    end
    return false
end

local function isLegalRailTile(tile)
    if not tile then return false end
    if hasRR(tile) then return true end
    if tile.city then return true end
    if tileHasSilo(tile) then return true end
    return false
end

local function neighboursOnRail(tile)
    local out = {}
    for _, adj in pairs(gen.getAdjacentTiles(tile)) do
        if adj and adj.z == tile.z and isLegalRailTile(adj) then
            out[#out + 1] = {adj, 1}
        end
    end
    return out
end

local function railHeuristic(fromTile, goal)
    if civ.isTile(goal) then
        return gen.tileDist(fromTile, goal)
    end
    local best = math.huge
    for _, g in pairs(goal) do
        local d = gen.tileDist(fromTile, g)
        if d < best then best = d end
    end
    return best
end

local function pathCost(path)
    return #path - 1
end

local function findRailPath(startTile, goalTiles)
    if not startTile or not goalTiles or #goalTiles == 0 then
        return false
    end
    local goal = (#goalTiles == 1) and goalTiles[1] or goalTiles
    return aStarCiv.aStar(startTile, goal, railHeuristic, neighboursOnRail, pathCost, 400)
end

local function silosInZone(zoneName, mapZ)
    local list = {}
    for unit in civ.iterateUnits() do
        if unit.type == object.uFuelStorageSilos then
            if mapZ == nil or unit.location.z == mapZ then
                local zName = helper.airZoneFor(unit.location.x, unit.location.y)
                if zName == zoneName then list[#list + 1] = unit end
            end
        end
    end
    return list
end

local function tribeHasSiloInZone(tribe, zoneName)
    for unit in civ.iterateUnits() do
        if unit.type == object.uFuelStorageSilos and unit.owner == tribe then
            if helper.airZoneFor(unit.location.x, unit.location.y) == zoneName then
                return true
            end
        end
    end
    return false
end

local function cityNameForSilo(siloUnit)
    if siloUnit.homeCity then return siloUnit.homeCity.name end
    local tile = siloUnit.location
    if tile.city then return tile.city.name end
    local best, bestDist = nil, math.huge
    for _, city in ipairs(SILO_CITIES) do
        if city and city.location then
            local d = gen.tileDist(tile, city.location)
            if d < bestDist then bestDist = d best = city end
        end
    end
    if best then return best.name end
    return "the depot"
end

local function allSilosOnMap(mapZ)
    local list = {}
    for unit in civ.iterateUnits() do
        if unit.type == object.uFuelStorageSilos then
            if mapZ == nil or unit.location.z == mapZ then
                list[#list + 1] = unit
            end
        end
    end
    return list
end

local function zoneForSilo(siloUnit)
    local tile = siloUnit.location
    local bestCity, bestDist = nil, math.huge
    for _, city in ipairs(SILO_CITIES) do
        if city and city.location then
            local d = gen.tileDist(tile, city.location)
            if d < bestDist then bestDist = d bestCity = city end
        end
    end
    if bestCity then
        return helper.airZoneFor(bestCity.location.x, bestCity.location.y)
    end
    return helper.airZoneFor(tile.x, tile.y)
end

local function closestReachableSilo(startTile)
    local silos = allSilosOnMap(startTile.z)
    if #silos == 0 then return nil, nil end
    table.sort(silos, function(a, b)
        return gen.tileDist(startTile, a.location) < gen.tileDist(startTile, b.location)
    end)
    local bestUnit, bestPath, bestCost = nil, nil, math.huge
    for _, silo in ipairs(silos) do
        local cost, path = findRailPath(startTile, {silo.location})
        if cost and path and cost < bestCost then
            bestCost = cost
            bestPath = path
            bestUnit = silo
        end
    end
    return bestUnit, bestPath
end

local function arrivalMessage(siloUnit, zoneName, amount)
    text.simple(
        "Fuel train arrives near "..cityNameForSilo(siloUnit)..". The fuel stores in "..zoneName
        .." have increased by "..tostring(amount)..".",
        "Fuel Train"
    )
end

local function disbandMessage()
    text.simple(
        "Enemy air activity has degraded the fuel and/or transportation system in the area, leaving our fuel train with no way to reach a storage silo. It has been disbanded.",
        "Fuel Train"
    )
end

local function deleteTrain(unit)
    if unit and civ.isUnit(unit) then gen.deleteUnit(unit) end
end

local stepTable = rawget(_G, "_fuelTrainSteps")
if not stepTable then
    stepTable = {}
    rawset(_G, "_fuelTrainSteps", stepTable)
end

local function isBusy()
    return rawget(_G, "_fuelTrainBusy") == true
end
local function setBusy(v)
    rawset(_G, "_fuelTrainBusy", v)
end
local function stepKey(unit)
    return tostring(civ.getTurn()).."#"..tostring(unit.id)
end
local function tilesPerTurn()
    return param.fuelTrainTilesPerTurn or 5
end
local function remainingSteps(unit)
    local left = tilesPerTurn() - (stepTable[stepKey(unit)] or 0)
    if left < 1 then return 0 end
    return left
end
local function noteSteps(unit, n)
    if not unit or n < 1 then return end
    local key = stepKey(unit)
    stepTable[key] = (stepTable[key] or 0) + n
    unit.moveSpent = unit.type.move or tilesPerTurn()
end

local function arriveAndDeliver(unit, silo)
    local zoneName = zoneForSilo(silo) or helper.airZoneFor(silo.location.x, silo.location.y)
    fuelTrain.addFuel(zoneName, pDelivery())
    arrivalMessage(silo, zoneName, pDelivery())
    deleteTrain(unit)
end

local function resolveTrain(unit)
    if not unit or not civ.isUnit(unit) then return end
    if isBusy() then return end
    setBusy(true)
    local ok, err = pcall(function()
        local tile = unit.location
        if not isLegalRailTile(tile) then
            disbandMessage()
            deleteTrain(unit)
            return
        end
        if tileHasSilo(tile) then
            local here = nil
            for u in tile.units do
                if u.type == object.uFuelStorageSilos then here = u break end
            end
            if here then arriveAndDeliver(unit, here) return end
        end
        local silo, path = closestReachableSilo(tile)
        if not silo or not path or #path < 2 then
            if silo and path and #path == 1 and tileHasSilo(tile) then
                arriveAndDeliver(unit, silo)
                return
            end
            disbandMessage()
            deleteTrain(unit)
            return
        end
        local steps = remainingSteps(unit)
        if steps < 1 then return end
        local walked, arrived = 0, false
        for i = 2, #path do
            if walked >= steps then break end
            if not civ.isUnit(unit) then break end
            civ.teleportUnit(unit, path[i])
            walked = walked + 1
            if path[i].x == silo.location.x and path[i].y == silo.location.y and path[i].z == silo.location.z then
                arrived = true
                break
            end
        end
        if walked > 0 and civ.isUnit(unit) then noteSteps(unit, walked) end
        if arrived and civ.isUnit(unit) then arriveAndDeliver(unit, silo) end
    end)
    setBusy(false)
    if not ok then print("fuelTrain.resolveTrain error: "..tostring(err)) end
end

discreteEvents.onActivateUnit(function(unit, source, repeatMove)
    if not unit or unit.type ~= object.uFuelTrain then return end
    if repeatMove then return end
    resolveTrain(unit)
end)
local function isFuelAirfield(unit)
    local city = unit.location.city
    if not city then return false end
    if helper.isOTRAirfield(city) then return true end
    if unit.location.z == 2 or unit.location.z == 3 then return true end
    return false
end

discreteEvents.onActivateUnit(function(unit, source, repeatMove)
    if not unit or not civ.isUnit(unit) then return end
    local key = billKey(unit)
    local zoneName = helper.airZoneFor(unit.location.x, unit.location.y)
    if not repeatMove then
        if not isFuelAirfield(unit) then return end
        if malusExempt[unit.type.id] then return end
        if rolledThisTurn[key] == "fail" then
            groundAircraft(unit)
            return
        end
        if rolledThisTurn[key] ~= nil then return end
        local chance = fuelTrain.failChance(fuelTrain.getFuel(zoneName))
        rolledThisTurn[key] = "ok"
        if chance > 0 and math.random(1, 100) <= chance then
            rolledThisTurn[key] = "fail"
            groundAircraft(unit)
            if unit.owner and unit.owner.isHuman then
                if rawget(_G, "_fuelShortageMsg") ~= key then
                    rawset(_G, "_fuelShortageMsg", key)
                    local city = unit.location.city
                    local where
                    if city and city.name then
                        where = city.name
                    else
                        local t = unit.location
                        where = tostring(t.x)..","..tostring(t.y)..","..tostring(t.z)
                    end
                    text.simple(
                        "Fuel shortages have grounded this aircraft at "..where
                        .." for the rest of the turn.",
                        "Fuel Shortage"
                    )
                end
            end
        end
        return
    end
    if rolledThisTurn[key] == "fail" then
        groundAircraft(unit)
        return
    end
    if billedThisTurn[key] then return end
    local cost = fuelTrain.takeoffCost(unit.type)
    if cost < 1 then return end
    billedThisTurn[key] = true
    if zoneName then fuelTrain.addFuel(zoneName, -cost) end
end)

local function spawnTrainsAtCity(city, count)
    if count < 1 then return end
    for i = 1, count do
        local u = civ.createUnit(object.uFuelTrain, city.owner, city.location)
        if u then u.homeCity = city end
    end
end
local function cityHas(city, improvement)
    return city:hasImprovement(improvement)
end

discreteEvents.onTurn(function(turn)
    if not turn or turn < 1 then return end
    local doSynth = (pSynthInterval() > 0) and (turn % pSynthInterval() == 0)
    local doOil   = (pOilInterval()   > 0) and (turn % pOilInterval()   == 0)
    if not doSynth and not doOil then return end
    for city in civ.iterateCities() do
        if doSynth and cityHas(city, object.iSyntheticFuelRefinery) then
            spawnTrainsAtCity(city, pSynthCount())
        end
        if doOil and cityHas(city, object.iOilRefinery) then
            spawnTrainsAtCity(city, pOilCount())
        end
    end
end)

local function visibleZonesFor(tribe)
    local visible = {}
    if tribe == object.pGermans then
        for _, name in ipairs(ZONE_ORDER) do
            if GERMAN_VIEW[name] then visible[#visible + 1] = name end
        end
        return visible
    end
    if tribe == object.pAllies then
        for _, name in ipairs(ZONE_ORDER) do
            if tribeHasSiloInZone(tribe, name) then visible[#visible + 1] = name end
        end
    end
    return visible
end

function fuelTrain.showStatus(tribe)
    tribe = tribe or civ.getCurrentTribe()
    local zones = visibleZonesFor(tribe)
    if #zones == 0 then
        text.simple("No fuel-storage reports are available.", "Fuel Status")
        return
    end
    local lines = {"Off-screen fuel stocks:", ""}
    for _, name in ipairs(zones) do
        local stock = fuelTrain.getFuel(name)
        local silos = silosInZone(name)
        local extra = (#silos == 0) and "  (no silo — no new deliveries)" or ""
        lines[#lines + 1] = string.format("%-12s  %s%s", name, text.groupDigits(stock), extra)
    end
    text.simple(table.concat(lines, "\n"), "Fuel Status")
end

discreteEvents.onKeyPress(function(keyCode)
    if keyCode == pStatusKey() then
        fuelTrain.showStatus(civ.getCurrentTribe())
    end
end)

if rawget(_G, "console") then
    function console.dumpFuel()
        for _, name in ipairs(ZONE_ORDER) do
            print(string.format("  %-12s %d", name, fuelTrain.getFuel(name)))
        end
    end
    function console.addFuel(zoneName, amount)
        fuelTrain.addFuel(zoneName, amount or pDelivery())
        print(zoneName, fuelTrain.getFuel(zoneName))
    end
    function console.setFuel(zoneName, amount)
        fuelTrain.setFuel(zoneName, amount)
        print(zoneName, fuelTrain.getFuel(zoneName))
    end
    function console.spawnFuelTrains()
        for city in civ.iterateCities() do
            if cityHas(city, object.iSyntheticFuelRefinery) then
                spawnTrainsAtCity(city, pSynthCount())
            end
            if cityHas(city, object.iOilRefinery) then
                spawnTrainsAtCity(city, pOilCount())
            end
        end
    end
end

return fuelTrain