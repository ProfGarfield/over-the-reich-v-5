--[[
    OTR calendar
    T1 = 17 August 1943. 16 turns per month. Last month is May 1945
    (scenario ends 8 May 1945, about T332).

    On the first turn of each month a box shows the date. Hooked on
    discreteEvents.onTurn so a later winter-terrain swap can sit
    next to this.
]]

local discreteEvents = require("discreteEventsRegistrar")
local text           = require("text")
local object         = require("object")

local calendar = {}

local MONTH_NAME = {
    "January","February","March","April","May","June",
    "July","August","September","October","November","December",
}

-- monthsElapsed 0 = August 1943
local function monthYear(turn)
    turn = turn or civ.getTurn()
    local elapsed = (turn - 1) // 16
    local month = (7 + elapsed) % 12 + 1
    local year  = 1943 + (7 + elapsed) // 12
    return month, year, elapsed
end

function calendar.monthNumber(turn)
    local m = monthYear(turn)
    return m
end

function calendar.year(turn)
    local _, y = monthYear(turn)
    return y
end

function calendar.monthName(turn)
    local m = monthYear(turn)
    return MONTH_NAME[m]
end

function calendar.isWinter(turn)
    local m = monthYear(turn)
    return m == 12 or m == 1 or m == 2
end

function calendar.isMonthStart(turn)
    turn = turn or civ.getTurn()
    return ((turn - 1) % 16) == 0
end

function calendar.dateLine(turn)
    local month, year, elapsed = monthYear(turn)
    if elapsed == 0 then
        return "17 August 1943"
    end
    return "1 "..MONTH_NAME[month].." "..tostring(year)
end

-- Allies: Eaker commands 8th AF until Jan 1944, then Spaatz has USSTAF.
-- Germans: Galland for the whole campaign (JdJ). Optional Gollob at T273
-- after the Fighter Pilots' Revolt -- not wired unless you ask.
local SPAATZ_TURN = 81   -- 1 January 1944
local GOLLOB_TURN = 281  -- ~17 January 1945, Galland to JV 44, Gollob JdJ

local function applyLeaders(turn)
    turn = turn or civ.getTurn()
    local allies = object.pAllies
    local germans = object.pGermans
    if allies then
        if turn >= SPAATZ_TURN then
            allies.leader.name = "Carl Spaatz"
        else
            allies.leader.name = "Ira C. Eaker"
        end
    end
    if germans then
        if turn >= GOLLOB_TURN then
            germans.leader.name = "Gordon Gollob"
        else
            germans.leader.name = "Adolf Galland"
        end
    end
end

local function pastEnd(turn)
    local month, year = monthYear(turn)
    if year > 1945 then return true end
    if year == 1945 and month > 5 then return true end
    return false
end

local function spawnGallandJV44()
    local tile = civ.getTile(309, 55, 0)
    local ut = object.uAdolfGalland
    local tribe = object.pGermans
    if not tile or not ut or not tribe then
        return
    end
    local u = civ.createUnit(ut, tribe, tile)
    if u then
        u.veteran = true
        u.homeCity = nil
    end
end

discreteEvents.onTurn(function(turn)
    applyLeaders(turn)
    if turn == SPAATZ_TURN then
        text.simple(
            "Washington has reorganized the American bomber effort in Europe. "
            .."Lieutenant General Carl Spaatz now commands the United States Strategic Air Forces, "
            .."with the Eighth and the Fifteenth under one roof. Ira Eaker, who built the Eighth "
            .."from a handful of groups into a daily presence over Germany, leaves for the Mediterranean. "
            .."The doctrine does not change: the Combined Bomber Offensive continues.",
            "Change of Command")
    end
    if turn == GOLLOB_TURN then
        spawnGallandJV44()
        text.simple(
            "Galland is relieved as General der Jagdflieger "
            .."and sent to form Jagdverband 44, a small Me 262 unit of experts flying out of the south. "
            .."Gordon Gollob takes the JdJ desk in his place. The jet is no longer a briefing-room argument. "
            .."It is Galland's last command.",
            "JV 44")
    end
    if not calendar.isMonthStart(turn) then return end
    if pastEnd(turn) then return end
    local line = calendar.dateLine(turn)
    if turn == 1 then
        text.simple("The campaign opens. "..line..".","Calendar")
    elseif line == "1 May 1945" then
        text.simple(line..". The war in Europe has days left.","Calendar")
    else
        text.simple(line..".","Calendar")
    end
    -- winter terrain swap goes here later:
    -- if calendar.isWinter(turn) then ... end
end)

discreteEvents.onScenarioLoaded(function()
    applyLeaders(civ.getTurn())
end)

calendar.applyLeaders = applyLeaders
calendar.SPAATZ_TURN  = SPAATZ_TURN
calendar.GOLLOB_TURN  = GOLLOB_TURN

return calendar
