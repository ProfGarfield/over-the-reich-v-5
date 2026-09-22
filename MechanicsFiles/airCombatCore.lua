--[[
OTR air combat core — 21 Sep 2026
Require from combatSettings.lua and call applyAirCombat() inside
computeCombatStatistics to fold multipliers into aCustomMult / dCustomMult
and firepower.

Does NOT replace the old coroutine yet. It computes the package so you can
see numbers with narration on before wiring escape/bounce-commit.

Install:
    local airCombat = require("airCombatCore")
    airCombat.installFlag()          -- once, discreteEvents.onScenarioLoaded
    -- inside computeCombatStatistics, after you have attacker/defender:
    airCombat.applyAirCombat(attacker, defender, combatModifierOverride, {
        originalDefenderZ = originalDefenderLocation and originalDefenderLocation.z,
    })

Toggle narration: key N (add in keyPressSettings) calls airCombat.toggleNarration()
]]

local traits = require("traits")
local object = require("object")
local text = require("text")

local flag
do
    local ok, f = pcall(require, "flag")
    flag = ok and f or nil
end

local FLAG_NAME = "combatNarration"
local FLAG_MODULE = "airCombat"

local ROLE = {
    airSuperiority = "airSuperiority",
    bomberDestroyer = "bomberDestroyer",
    jabo = "jabo",
    lightBomber = "lightBomber",
    mediumBomber = "mediumBomber",
    heavyBomber = "heavyBomber",
    wunderwaffe = "wunderwaffe",
}

-- Tight band. Bomber-as-attacker vs fighter is self-defense, not a plan.
-- Daylight bomber RETURN FIRE is gunFirepower on the defender, not this row.
local ROLE_MATRIX = {
    airSuperiority = {
        airSuperiority=1.00, bomberDestroyer=1.20, jabo=1.15,
        lightBomber=1.00, mediumBomber=0.90, heavyBomber=0.80, wunderwaffe=0.85,
    },
    bomberDestroyer = {
        airSuperiority=0.75, bomberDestroyer=0.90, jabo=0.85,
        lightBomber=1.15, mediumBomber=1.25, heavyBomber=1.35, wunderwaffe=0.80,
    },
    jabo = {
        airSuperiority=0.80, bomberDestroyer=0.85, jabo=1.00,
        lightBomber=0.90, mediumBomber=0.85, heavyBomber=0.80, wunderwaffe=0.75,
    },
    lightBomber = {
        airSuperiority=0.55, bomberDestroyer=0.50, jabo=0.70,
        lightBomber=0.80, mediumBomber=0.80, heavyBomber=0.80, wunderwaffe=0.45,
    },
    mediumBomber = {
        airSuperiority=0.50, bomberDestroyer=0.45, jabo=0.65,
        lightBomber=0.80, mediumBomber=0.80, heavyBomber=0.80, wunderwaffe=0.40,
    },
    heavyBomber = {
        airSuperiority=0.45, bomberDestroyer=0.40, jabo=0.60,
        lightBomber=0.80, mediumBomber=0.80, heavyBomber=0.80, wunderwaffe=0.35,
    },
    wunderwaffe = {
        airSuperiority=1.15, bomberDestroyer=1.20, jabo=1.20,
        lightBomber=1.20, mediumBomber=1.15, heavyBomber=1.10, wunderwaffe=1.00,
    },
}

local MAP = { LOW = 0, HIGH = 1, NIGHT = 2 }

local paramsByTypeId = {}

local function isNight(z) return z == MAP.NIGHT end
local function isHigh(z) return z == MAP.HIGH end
local function isLow(z) return z == MAP.LOW end

local function narrationOn()
    if flag and flag.value then
        local ok, v = pcall(flag.value, FLAG_NAME, FLAG_MODULE)
        if ok then return v and true or false end
    end
    return true -- default ON while testing if flag module isn't wired
end

local lastMsg = nil
local lastAnnounceKey = nil

local function pairKey(attacker, defender)
    if not (attacker and defender) then return nil end
    return tostring(attacker.id)..":"..tostring(defender.id)
end

local function say(msg)
    print("[combat] "..tostring(msg))
    if narrationOn() then
        civ.ui.text(tostring(msg))
    end
end

local function announceLast()
    if lastMsg and narrationOn() then
        civ.ui.text(lastMsg)
    end
end

local function installFlag()
    if not flag then return end
    if flag.define then
        pcall(flag.define, FLAG_NAME, true, FLAG_MODULE)
    end
end

local function toggleNarration()
    if flag and flag.toggle then
        flag.toggle(FLAG_NAME, FLAG_MODULE)
    elseif flag and flag.value and flag.setTrue then
        if flag.value(FLAG_NAME, FLAG_MODULE) then
            flag.setFalse(FLAG_NAME, FLAG_MODULE)
        else
            flag.setTrue(FLAG_NAME, FLAG_MODULE)
        end
    end
    say("Combat narration: "..(narrationOn() and "ON" or "OFF"))
end

local function registerParameters(tbl)
    for id, row in pairs(tbl) do
        if type(id) == "number" then
            paramsByTypeId[id] = row
        end
    end
end

-- airCombatTestSet.fillTestParameters writes into a table we can ingest
local function ingestTestSet()
    local ok, testSet = pcall(require, "airCombatTestSet")
    if not ok then return end
    local bag = {}
    testSet.fillTestParameters(bag, nil)
    -- fillTestParameters keys by unitType.id via object units
    -- Our put() used unit objects as keys. Flatten.
    for k, v in pairs(bag) do
        if type(k) == "userdata" and k.id then
            paramsByTypeId[k.id] = v
        elseif type(k) == "number" then
            paramsByTypeId[k] = v
        end
    end
end

local function hasTraitSafe(unit, name)
    if not (unit and traits and traits.hasTrait) then return false end
    local ok, result = pcall(traits.hasTrait, unit.type, name)
    return ok and result and true or false
end

local function inferRole(unit)
    local p = paramsByTypeId[unit.type.id]
    if p and p.role then return p.role end
    if hasTraitSafe(unit, "heavyBomber") then return "heavyBomber" end
    if hasTraitSafe(unit, "mediumBomber") then return "mediumBomber" end
    if hasTraitSafe(unit, "lightBomber") then return "lightBomber" end
    if hasTraitSafe(unit, "bomberDestroyer") then return "bomberDestroyer" end
    if hasTraitSafe(unit, "jabo") then return "jabo" end
    if hasTraitSafe(unit, "wunderwaffe") then return "wunderwaffe" end
    if hasTraitSafe(unit, "bomber") then return "heavyBomber" end
    return "airSuperiority"
end

local function preferredMap(unit)
    local p = paramsByTypeId[unit.type.id]
    if p and p.preferredMap then return p.preferredMap end
    if hasTraitSafe(unit, "nightFighter") then return "night" end
    if hasTraitSafe(unit, "highAltitude") then return "high" end
    if hasTraitSafe(unit, "lowAltitude") then return "low" end
    return "all"
end

local function isBomber(unit)
    local r = inferRole(unit)
    return r == "heavyBomber" or r == "mediumBomber" or r == "lightBomber"
end

local function isNightFighter(unit)
    return hasTraitSafe(unit, "nightFighter") or preferredMap(unit) == "night"
end

local function isDayFighter(unit)
    return hasTraitSafe(unit, "dayFighter")
end

local function dayNightMult(unit, z)
    if isNight(z) then
        if isDayFighter(unit) and not isNightFighter(unit) then
            return 0.70 -- Wilde Sau
        end
        return 1.00
    end
    -- day maps
    if isNightFighter(unit) then
        return 0.65 -- 110 by day is meat
    end
    return 1.00
end

local function heightMult(unit, z)
    if isNight(z) then return 1.00 end
    local pref = preferredMap(unit)
    if pref == "all" or pref == "night" then return 1.00 end
    if pref == "low" and isHigh(z) then return 0.85 end
    if pref == "high" and isLow(z) then return 0.70 end
    return 1.00
end

-- Bounce is NOT cross-map attacking. Civ2 cannot do that.
-- Bounce = a fighter on the HIGH map at this x,y dropping into a
-- fight that is already happening on the LOW map underneath it.
-- Defender who bounced in. 1.55 is a bounce, not a fair fight.
local BOUNCE_DEF = 1.55
-- Attacker who got jumped from above.
local BOUNCE_ATK = 0.70
local BOUNCE_RADIUS = 2
local COVER_LIMIT = 2
local coverUsed = {}

local function currentTurn()
    if civ.getTurn then return civ.getTurn() end
    return 0
end

local function coversSpent(unit)
    if not unit then return COVER_LIMIT end
    local rec = coverUsed[unit.id]
    if not rec or rec.turn ~= currentTurn() then return 0 end
    return rec.n
end

local function coversLeft(unit)
    return COVER_LIMIT - coversSpent(unit)
end

local function noteCoverUsed(unit)
    if not unit then return end
    local rec = coverUsed[unit.id]
    if not rec or rec.turn ~= currentTurn() then
        rec = {turn = currentTurn(), n = 0}
        coverUsed[unit.id] = rec
    end
    rec.n = rec.n + 1
end

local function bounceMult(ctx)
    if ctx and ctx.bounced then return BOUNCE_DEF end
    return 1.00
end

local function bounceAttackMult(ctx)
    if ctx and ctx.bounced then return BOUNCE_ATK end
    return 1.00
end

local function tileDist(a, b)
    if not (a and b) then return 99 end
    return (math.abs(a.x - b.x) + math.abs(a.y - b.y)) / 2
end

local function otherDayZ(z)
    if z == MAP.LOW then return MAP.HIGH end
    if z == MAP.HIGH then return MAP.LOW end
    return nil
end

local function isFighterUnit(unit)
    if not unit then return false end
    if hasTraitSafe(unit, "fighter") then return true end
    local p = paramsByTypeId[unit.type.id]
    if p and (p.role == "airSuperiority" or p.role == "bomberDestroyer"
           or p.role == "jabo" or p.role == "wunderwaffe") then
        return true
    end
    return unit.type.domain == 1 and not isBomber(unit)
end

-- Fight on LOW. Look on HIGH within BOUNCE_RADIUS of that column.
-- Per-type interceptionRange (default 2) can only shrink that, not grow it.
local function findBounceDefender(tile, attacker)
    ingestTestSet()
    if not tile or not attacker then return nil end
    if not isLow(tile.z) then return nil end
    local best, bestScore = nil, -1
    local r = BOUNCE_RADIUS * 2
    for dx = -r, r do
        for dy = -r, r do
            local t = civ.getTile(tile.x + dx, tile.y + dy, MAP.HIGH)
            if t then
                local dist = tileDist(tile, t)
                if dist <= BOUNCE_RADIUS then
                    for u in t.units do
                        if u.owner ~= attacker.owner and isFighterUnit(u)
                            and coversLeft(u) > 0 then
                            local p = paramsByTypeId[u.type.id]
                            local range = (p and p.interceptionRange) or BOUNCE_RADIUS
                            if dist <= range then
                                local score = (p and p.luaAttack) or 10
                                score = score - dist * 2
                                if preferredMap(u) == "high" then score = score + 3 end
                                if preferredMap(u) == "all" then score = score + 1 end
                                if dist == 0 then score = score + 2 end
                                if score > bestScore then
                                    best, bestScore = u, score
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function roleMult(atkRole, defRole)
    local row = ROLE_MATRIX[atkRole]
    if not row then return 1.00 end
    return row[defRole] or 1.00
end

local function vetMult(unit)
    if unit.veteran then return 1.10 end
    return 1.00
    -- expert/ace/named come later as real unit types
end

local function mapSuffix(z)
    if z == MAP.NIGHT then return "Night" end
    if z == MAP.HIGH then return "High" end
    return "Low"
end

local function speedPair(unit, z)
    local p = paramsByTypeId[unit.type.id]
    if not p then return 300, 300 end
    local suf = mapSuffix(z)
    local pur = p["pursuitSpeed"..suf] or p.pursuitSpeed or 300
    local esc = p["escapeSpeed"..suf] or p.escapeSpeed or 300
    return pur, esc
end

local INTERCEPT_BASE = 2
local INTERCEPT_SPEED_STEP = 50
local FORMATION_RADIUS = 2

local function interceptRangeVs(escort, attacker, z)
    local ePur = speedPair(escort, z)
    local _, aEsc = speedPair(attacker, z)
    local delta = ePur - aEsc
    local range = INTERCEPT_BASE + math.floor(delta / INTERCEPT_SPEED_STEP)
    if range < 0 then range = 0 end
    if range > 4 then range = 4 end
    return range
end

-- Same-map escort. Replaces the bomber (or other target) as defender.
-- Air-superiority preferred. Bombers never intercept.
local function findInterceptDefender(tile, attacker)
    ingestTestSet()
    if not tile or not attacker then return nil end
    local best, bestScore = nil, -1
    local r = 8
    for dx = -r, r do
        for dy = -r, r do
            local t = civ.getTile(tile.x + dx, tile.y + dy, tile.z)
            if t then
                local dist = tileDist(tile, t)
                for u in t.units do
                    if u ~= attacker and u.owner ~= attacker.owner
                        and isFighterUnit(u) and not isBomber(u)
                        and coversLeft(u) > 0 then
                        local range = interceptRangeVs(u, attacker, tile.z)
                        if dist <= range then
                            local p = paramsByTypeId[u.type.id]
                            local score = (p and p.luaAttack) or 10
                            score = score - dist
                            if inferRole(u) == "airSuperiority" then score = score + 4 end
                            if dist == 0 then score = score + 2 end
                            if score > bestScore then
                                best, bestScore = u, score
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- Extra bombers near the defender. They do not take the fight.
-- They add firepower. Cap so a 12-ship box is not a death ray.
local function formationGunBonus(defender)
    if not defender or not isBomber(defender) then return 0, 0 end
    local extras = 0
    local r = FORMATION_RADIUS * 2
    local tile = defender.location
    for dx = -r, r do
        for dy = -r, r do
            local t = civ.getTile(tile.x + dx, tile.y + dy, tile.z)
            if t and tileDist(tile, t) <= FORMATION_RADIUS then
                for u in t.units do
                    if u ~= defender and u.owner == defender.owner and isBomber(u) then
                        extras = extras + 1
                    end
                end
            end
        end
    end
    local fpAdd = 0
    if extras >= 1 then fpAdd = 1 end
    if extras >= 2 then fpAdd = 2 end
    if extras >= 4 then fpAdd = 3 end
    return fpAdd, extras
end

--[[
Escape chance per round. Night fighters at night get nightEscapeExtra
on top of combatParameters.nightEscapeScale (default 2).
]]
local function escapeChance(escaper, pursuer, z, globals)
    globals = globals or {}
    local scale = isNight(z) and (globals.nightEscapeScale or 2)
                  or (globals.dayEscapeScale or 1)
    local _, esc = speedPair(escaper, z)
    local pur, _ = speedPair(pursuer, z)
    local extra = 1
    local p = paramsByTypeId[escaper.type.id]
    if isNight(z) and isNightFighter(escaper) then
        extra = (p and p.nightEscapeExtra) or 1.35
    end
    if isNight(z) and isDayFighter(escaper) and not isNightFighter(escaper) then
        extra = 0.75 -- Wilde Sau also worse at leaving
    end
    if pur + esc <= 0 then return 0 end
    local chance = scale * extra * esc / (pur + esc)
    if chance > 0.95 then chance = 0.95 end
    return chance
end

--[[
Return-fire rule:
  Bombers ALWAYS shoot each round they are in the fight.
  Their gunFirepower is applied as defender firepower when they are
  the defender (the normal fighter-attacks-bomber case).
  Their role-matrix attack row is only used if a bomber is the
  initiating attacker (stray gun pass / collision). That row is
  deliberately weak (0.45 vs AS) so bombers do not hunt fighters.
  They still sting.
]]
local function gunFirepower(unit)
    local p = paramsByTypeId[unit.type.id]
    if p and p.gunFirepower then return p.gunFirepower end
    if isBomber(unit) then return 2 end
    return (p and p.luaFirepower) or 1
end

local function applyAirCombat(attacker, defender, override, ctx)
    ctx = ctx or {}
    ingestTestSet()

    local az = attacker.location.z
    local dz = (ctx.originalDefenderZ) or defender.location.z
    local fightZ = defender.location.z

    local atkRole = inferRole(attacker)
    local defRole = inferRole(defender)

    local aRole = roleMult(atkRole, defRole)
    local dRole = roleMult(defRole, atkRole) -- return-fire quality of the defender
    local aDN = dayNightMult(attacker, fightZ)
    local dDN = dayNightMult(defender, fightZ)
    local aHt = heightMult(attacker, fightZ)
    local dHt = heightMult(defender, fightZ)
    local aBn = bounceAttackMult(ctx)
    local dBn = bounceMult(ctx)
    -- Bounce pass uses energy from high. Do not also slap the
    -- "P-47 lives on the deck" tax onto that one pass.
    if ctx.bounced then
        dHt = 1.00
    end
    local aVet = vetMult(attacker)
    local dVet = vetMult(defender)

    -- Defender role-as-attacker is how hard the guns bite, not how
    -- well the Fortress dogfights. Floor it so guns never go away.
    if isBomber(defender) then
        dRole = math.max(dRole, 0.70)
    end

    local aP = paramsByTypeId[attacker.type.id]
    local dP = paramsByTypeId[defender.type.id]
    local suf = mapSuffix(fightZ)
    local aCrate = (aP and aP.luaAttack) or 10
    local dCrate = (dP and dP.luaDefense) or 10
    -- 10 is the "even crate" baseline. 11 vs 10 = 1.10
    local aCrateMult = aCrate / 10
    local dCrateMult = dCrate / 10
    local aMapAdd = (aP and (aP["attackMod"..suf] or 0)) or 0
    local dMapAdd = (dP and (dP["defenseMod"..suf] or 0)) or 0

    override.aCustomMult = (override.aCustomMult or 1) * aRole * aDN * aHt * aBn * aVet * aCrateMult
    override.dCustomMult = (override.dCustomMult or 1) * dRole * dDN * dHt * dBn * dVet * dCrateMult
    override.aCustomAdd = (override.aCustomAdd or 0) + aMapAdd
    override.dCustomAdd = (override.dCustomAdd or 0) + dMapAdd

    -- Firepower: bombers keep guns even while trying to escape.
    override.aAddFirepower = (override.aAddFirepower or 0)
    override.dAddFirepower = (override.dAddFirepower or 0)
    local formFP, formN = 0, 0
    if isBomber(defender) then
        override.dAddFirepower = override.dAddFirepower + math.max(0, gunFirepower(defender) - 1)
        formFP, formN = formationGunBonus(defender)
        override.dAddFirepower = override.dAddFirepower + formFP
    end
    if isBomber(attacker) then
        override.aAddFirepower = override.aAddFirepower + math.max(0, gunFirepower(attacker) - 1)
    end

    if narrationOn() then
        local bounceTxt = ctx.bounced and " BOUNCE from high" or ""
        local msg = string.format(
            "%s [%s crate %d] vs %s [%s crate %d]%s\nATK x%.2f (role %.2f crate %.2f day/night %.2f height %.2f bounce %.2f vet %.2f map+%d)\nDEF x%.2f (guns %.2f crate %.2f day/night %.2f height %.2f bounce %.2f vet %.2f map+%d)%s",
            attacker.type.name, atkRole, aCrate,
            defender.type.name, defRole, dCrate,
            bounceTxt,
            override.aCustomMult, aRole, aCrateMult, aDN, aHt, aBn, aVet, aMapAdd,
            override.dCustomMult, dRole, dCrateMult, dDN, dHt, dBn, dVet, dMapAdd,
            isBomber(defender) and (formN > 0
                and string.format("\nBomber returning fire. Formation +%d FP (%d extra).", formFP, formN)
                or "\nBomber returning fire.") or ""
        )
        if isNightFighter(defender) and isNight(fightZ) then
            msg = msg.."\nNF night escape chance vs this attacker: "
                ..string.format("%.0f%%", 100*escapeChance(defender, attacker, fightZ))
        end
        if isNightFighter(attacker) and isNight(fightZ) then
            msg = msg.."\nNF night escape chance if it wants out: "
                ..string.format("%.0f%%", 100*escapeChance(attacker, defender, fightZ))
        end
        lastMsg = msg
        local key = pairKey(attacker, defender)
        if key and key ~= lastAnnounceKey then
            lastAnnounceKey = key
            say(msg)
        else
            print("[combat] (suppressed duplicate) "..msg)
        end
    else
        lastMsg = nil
        print(string.format("[combat] %s x%.2f vs %s x%.2f",
            attacker.type.name, override.aCustomMult,
            defender.type.name, override.dCustomMult))
    end

    return override
end

local MIN_ROUNDS = 3
local MAX_ROUNDS = 10
local FIGHTER_ESCAPE_HITS = 3

local function hitsFromDeath(unit)
    return unit.hitpoints or 0
end

-- Call after each combat round from the coroutine.
-- Returns "continue", "attackerEscaped", or "defenderEscaped".
local function afterRound(round, attacker, defender)
    if not attacker or not defender then return "continue" end
    if attacker.hitpoints <= 0 or defender.hitpoints <= 0 then return "continue" end
    if round < MIN_ROUNDS then return "continue" end
    local z = defender.location.z

    local function tryEscape(escaper, pursuer, who)
        local wants = false
        if isBomber(escaper) then
            wants = true -- bomber always tries to leave a fighter
        elseif hitsFromDeath(escaper) <= FIGHTER_ESCAPE_HITS then
            wants = true
        end
        if not wants then return false end
        local chance = escapeChance(escaper, pursuer, z)
        local roll = math.random()
        if roll <= chance then
            say(string.format("%s ESCAPES (%.0f%%, rolled %.2f)",
                escaper.type.name, 100*chance, roll))
            return true
        end
        if narrationOn() then
            print(string.format("[combat] %s fail escape %.0f%% rolled %.2f",
                escaper.type.name, 100*chance, roll))
        end
        return false
    end

    -- Defender tries first (bomber running from the bounce).
    if tryEscape(defender, attacker, "defender") then return "defenderEscaped" end
    if tryEscape(attacker, defender, "attacker") then return "attackerEscaped" end
    return "continue"
end

local function maxAirRounds()
    return MAX_ROUNDS
end

-- Civ2 unit userdata will not accept extra keys. Store homes here.
local coverHome = {}

local function markBounceHome(unit, mode)
    if not unit then return end
    local loc = unit.location
    coverHome[unit.id] = {
        x = loc.x, y = loc.y, z = loc.z,
        mode = mode or "bounce",
        unit = unit,
    }
    noteCoverUsed(unit)
end

local function finishBounce(attacker, defender)
    local rec, u = nil, nil
    if defender and coverHome[defender.id] then
        rec, u = coverHome[defender.id], defender
    elseif attacker and coverHome[attacker.id] then
        rec, u = coverHome[attacker.id], attacker
    end
    if not rec or not u then return end
    coverHome[u.id] = nil

    if u.hitpoints <= 0 then return end

    local home = civ.getTile(rec.x, rec.y, rec.z)
    if not home then return end

    if rec.mode == "intercept" then
        civ.teleportUnit(u, home)
        say(u.type.name.." returns to CAP.")
        return
    end

    local preyDead = (u == defender and attacker.hitpoints <= 0)
                  or (u == attacker and defender.hitpoints <= 0)
    if not preyDead then
        say(u.type.name.." stays on the deck (bounce did not kill).")
        return
    end
    civ.teleportUnit(u, home)
    say(u.type.name.." climbs back to high after the bounce kill.")
end

-- Example numbers for the eight-ship, no engine required
local function expectedFeel()
    return {
        ["109G6 vs Spit IX, high"] = "near even, spit slightly better escape",
        ["190A5 vs Spit IX, low"] = "190 slight edge on attack, spit leaves if hurt",
        ["190A5 vs P-47D6, high"] = "190 pays 0.85 height; P-47 bounce if P-47 is attacker",
        ["P-47D6 bounce 190A5"] = "P-47 attack x1.20 bounce; 190 stays low",
        ["G6R6 vs B-17F"] = "BD 1.35 vs heavy; Fortress guns still fire (dRole floored 0.70)",
        ["109G6 vs B-17F"] = "AS 0.80 vs heavy — not a destroyer, box bites back",
        ["110G4 vs Lancaster, night"] = "BD 1.35 vs heavy + night home; 110 escape ~high 70s%",
        ["110G4 vs Spit IX, day"] = "110 x0.65 day meat; Spit farms it",
        ["109G6 vs Lancaster, night"] = "Wilde Sau x0.70 and poor night speeds",
    }
end

return {
    ROLE = ROLE,
    ROLE_MATRIX = ROLE_MATRIX,
    MAP = MAP,
    say = say,
    announceLast = announceLast,
    installFlag = installFlag,
    toggleNarration = toggleNarration,
    narrationOn = narrationOn,
    registerParameters = registerParameters,
    ingestTestSet = ingestTestSet,
    inferRole = inferRole,
    applyAirCombat = applyAirCombat,
    escapeChance = escapeChance,
    gunFirepower = gunFirepower,
    isBomber = isBomber,
    expectedFeel = expectedFeel,
    afterRound = afterRound,
    maxAirRounds = maxAirRounds,
    MIN_ROUNDS = MIN_ROUNDS,
    MAX_ROUNDS = MAX_ROUNDS,
    findBounceDefender = findBounceDefender,
    findInterceptDefender = findInterceptDefender,
    interceptRangeVs = interceptRangeVs,
    formationGunBonus = formationGunBonus,
    otherDayZ = otherDayZ,
    markBounceHome = markBounceHome,
    finishBounce = finishBounce,
}
