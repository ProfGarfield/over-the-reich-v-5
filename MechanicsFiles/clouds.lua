--[[
    OTR Clouds
    Maps 1 (high day) and 3 (high night) only. Separate storm fields.
    Clouds replace any terrain except coastline (land touching ocean or
    ocean touching land). Cities and airfield terrain also stay clear
    so pads remain readable. Interior ocean is fair game.

    Terrain type 15 is the cloud graphic:
        object.tCloudCoverDayHigh0  = civ.getTerrain(1,15,0)
        object.tCloudCoverNightHigh0 = civ.getTerrain(3,15,0)

    Each turn storms drift west -> east. Press K to step once more
    without ending the turn.
]]

local gen            = require("generalLibrary")
local discreteEvents = require("discreteEventsRegistrar")
local keyboard       = require("keyboard")
local object         = require("object")
local text           = require("text")

local clouds = {}
local state

local CLOUD_TYPE = 15
local MAP_DAY    = 1
local MAP_NIGHT  = 3
local DRIFT_X    = 66         -- ~33 civ tiles east per tick; ~10 turns to cross a 334-tile map
local MAX_STORMS_PER_MAP = 40

-- T1 = 17 Aug 1943, 16 turns per month.
function clouds.monthNumber(turn)
    turn = turn or civ.getTurn()
    local monthsFromAug = (turn - 1) // 16
    return (7 + monthsFromAug) % 12 + 1
end

function clouds.seasonName(turn)
    local m = clouds.monthNumber(turn)
    if m == 12 or m == 1 or m == 2 then return "winter" end
    if m == 11 or m == 3 then return "late" end
    if m == 6 or m == 7 or m == 8 then return "summer" end
    return "mild"
end

local SEASON = {
    winter = { min=21, max=36, spawn=0.95, small=0.12, super=0.22 },
    late   = { min=15, max=27, spawn=0.85, small=0.18, super=0.14 },
    mild   = { min=12, max=21, spawn=0.75, small=0.22, super=0.10 },
    summer = { min=6,  max=15, spawn=0.60, small=0.32, super=0.06 },
}

local function seasonSpec(turn)
    return SEASON[clouds.seasonName(turn)]
end

local function obj(key)
    local ok, val = pcall(function() return object[key] end)
    if ok then return val end
    return nil
end

local function tileId(tile)
    if not tile then return nil end
    local w, h = civ.getMapDimensions()
    return tile.z * w * h + tile.x + tile.y * w
end

local function baseType(tile)
    return tile.terrainType & 0x0F
end

local function isCloudTile(tile)
    if not tile then return false end
    local z = tile.z
    if z ~= MAP_DAY and z ~= MAP_NIGHT then return false end
    return baseType(tile) == CLOUD_TYPE
end

local NEIGHBOR = {
    { 2, 0}, {-2, 0}, { 0, 2}, { 0,-2},
    { 1, 1}, { 1,-1}, {-1, 1}, {-1,-1},
}

local function originalType(tile)
    if not tile then return nil end
    local s = state()
    local id = tileId(tile)
    if s.original[id] ~= nil then
        return s.original[id]
    end
    local t = baseType(tile)
    if t == CLOUD_TYPE then
        return nil
    end
    return t
end

local function isOceanOrig(tile)
    return originalType(tile) == 10
end

-- Built once from the virgin map. Clouds never consult live terrain
-- for coast, so painting a cloud cannot create a fake shoreline.
local function snapshotMap()
    local s = state()
    if s.snapshotted then return end
    local w, h = civ.getMapDimensions()
    for _, z in ipairs({MAP_DAY, MAP_NIGHT}) do
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                if ((x + y) % 2) == 0 then
                    local t = civ.getTile(x, y, z)
                    if t then
                        local typ = baseType(t)
                        if typ ~= CLOUD_TYPE then
                            s.original[tileId(t)] = typ
                        end
                    end
                end
            end
        end
    end
    for _, z in ipairs({MAP_DAY, MAP_NIGHT}) do
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                if ((x + y) % 2) == 0 then
                    local t = civ.getTile(x, y, z)
                    if t then
                        local typ = originalType(t)
                        if typ ~= nil then
                            local ocean = (typ == 10)
                            for i = 1, #NEIGHBOR do
                                local n = civ.getTile(x + NEIGHBOR[i][1], y + NEIGHBOR[i][2], z)
                                local nt = originalType(n)
                                if nt ~= nil and ((nt == 10) ~= ocean) then
                                    s.noCloud[tileId(t)] = true
                                    break
                                end
                            end
                            if t.city or typ == 9 then
                                s.noCloud[tileId(t)] = true
                            end
                        end
                    end
                end
            end
        end
    end
    s.snapshotted = true
    print("clouds: coastline snapshot done")
end

local function canPlace(tile)
    if not tile then return false end
    local z = tile.z
    if z ~= MAP_DAY and z ~= MAP_NIGHT then return false end
    if tile.city then return false end
    if state().noCloud[tileId(tile)] then return false end
    return true
end

------------------------------------------------------------------------
-- Persistent state
------------------------------------------------------------------------

function state()
    local s = rawget(_G, "_otrClouds")
    if not s then
        s = {
            saved = {},
            original = {},
            noCloud = {},
            storms = { [MAP_DAY] = {}, [MAP_NIGHT] = {} },
            primed = false,
            snapshotted = false,
        }
        rawset(_G, "_otrClouds", s)
    end
    if not s.original then s.original = {} end
    if not s.noCloud then s.noCloud = {} end
    return s
end

------------------------------------------------------------------------
-- Place / restore
------------------------------------------------------------------------

local function saveAndSetCloud(tile)
    if not canPlace(tile) then return false end
    if isCloudTile(tile) then return true end
    local id = tileId(tile)
    local s = state()
    if not s.saved[id] then
        s.saved[id] = baseType(tile)
    end
    tile.terrainType = CLOUD_TYPE
    return true
end

local function restoreTile(tile)
    if not tile then return end
    local id = tileId(tile)
    local s = state()
    local saved = s.saved[id]
    if saved ~= nil then
        tile.terrainType = saved & 0x0F
        s.saved[id] = nil
    elseif isCloudTile(tile) then
        -- no save (load mid-storm): fall back to grassland = 0
        tile.terrainType = 0
    end
end

function clouds.clearAll()
    local s = state()
    local w, h = civ.getMapDimensions()
    for z = 0, 3 do
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                if ((x + y) % 2) == 0 then
                    local t = civ.getTile(x, y, z)
                    if t and isCloudTile(t) then
                        restoreTile(t)
                    end
                end
            end
        end
    end
    s.saved = {}
end

------------------------------------------------------------------------
-- Storm shapes: diamond rings, enough clump to read as weather
------------------------------------------------------------------------

local function stampStorm(storm)
    local z = storm.z
    local seed = storm.seed or 1
    for i = 1, #storm.blobs do
        local b = storm.blobs[i]
        local cx = storm.x + b.ox
        local cy = storm.y + b.oy
        local rx = math.max(2, b.rx)
        local ry = math.max(2, b.ry)
        for dx = -rx * 2, rx * 2 do
            for dy = -ry * 2, ry * 2 do
                if ((cx + dx) + (cy + dy)) % 2 == 0 then
                    local nx = dx / (rx * 2)
                    local ny = dy / (ry * 2)
                    local r2 = nx * nx + ny * ny
                    if r2 <= 1.0 then
                        local place = true
                        if r2 > 0.72 then
                            local h = (math.abs((cx + dx) * 13 + (cy + dy) * 7 + seed * 3)) % 11
                            if h < 4 then place = false end
                        end
                        if place then
                            saveAndSetCloud(civ.getTile(cx + dx, cy + dy, z))
                        end
                    end
                end
            end
        end
    end
end

local function makeBlobs(kind)
    local blobs = {}
    local n, spreadX, spreadY, rxLo, rxHi, ryLo, ryHi
    if kind == "small" then
        n, spreadX, spreadY, rxLo, rxHi, ryLo, ryHi = math.random(1, 2), 3, 2, 2, 4, 2, 3
    elseif kind == "super" then
        n, spreadX, spreadY, rxLo, rxHi, ryLo, ryHi = math.random(5, 8), 10, 7, 7, 14, 5, 10
    elseif kind == "large" then
        n, spreadX, spreadY, rxLo, rxHi, ryLo, ryHi = math.random(3, 5), 7, 5, 5, 10, 4, 7
    else
        n, spreadX, spreadY, rxLo, rxHi, ryLo, ryHi = math.random(2, 4), 5, 4, 3, 7, 3, 6
    end
    for i = 1, n do
        blobs[i] = {
            ox = math.random(-spreadX, spreadX) * 2,
            oy = math.random(-spreadY, spreadY) * 2,
            rx = math.random(rxLo, rxHi),
            ry = math.random(ryLo, ryHi),
        }
    end
    return blobs
end

local function pickKind()
    local spec = seasonSpec()
    local r = math.random()
    if r < spec.super then return "super" end
    if r < spec.super + spec.small then return "small" end
    if r < spec.super + spec.small + 0.18 then return "large" end
    return "medium"
end

local function randomStorm(z, fromWest)
    local w, h = civ.getMapDimensions()
    local x
    if fromWest then
        x = 2 + math.random(0, 8) * 2
    else
        x = math.random(0, math.max(2, (w // 2) - 1)) * 2
    end
    local y = math.random(2, math.max(3, (h // 2) - 2)) * 2
    if (x + y) % 2 ~= 0 then
        y = y + 1
    end
    local kind = pickKind()
    return {
        x = x,
        y = y,
        z = z,
        kind = kind,
        blobs = makeBlobs(kind),
        seed = math.random(1, 9999),
        life = math.random(12, 16),
        driftY = ({-2, 0, 0, 0, 2})[math.random(5)],
    }
end

local function seedMap(z)
    local list = state().storms[z]
    for i = #list, 1, -1 do list[i] = nil end
    local spec = seasonSpec()
    local n = math.random(spec.min, spec.max)
    for _ = 1, n do
        list[#list + 1] = randomStorm(z, false)
    end
end

local function paintAll()
    clouds.clearAll()
    local s = state()
    for _, z in ipairs({MAP_DAY, MAP_NIGHT}) do
        for _, storm in ipairs(s.storms[z]) do
            stampStorm(storm)
        end
    end
end

function clouds.advance()
    snapshotMap()
    local s = state()
    local w, h = civ.getMapDimensions()
    if not s.primed then
        seedMap(MAP_DAY)
        seedMap(MAP_NIGHT)
        s.primed = true
        paintAll()
        return
    end
    for _, z in ipairs({MAP_DAY, MAP_NIGHT}) do
        local list = s.storms[z]
        local keep = {}
        for _, storm in ipairs(list) do
            storm.x = storm.x + DRIFT_X
            storm.y = storm.y + storm.driftY
            if storm.y < 2 then storm.y = 2 storm.driftY = 2 end
            if storm.y > h - 4 then storm.y = h - 4 storm.driftY = -2 end
            if (storm.x + storm.y) % 2 ~= 0 then
                storm.y = storm.y + 1
            end
            storm.life = storm.life - 1
            if math.random() < 0.30 then
                local b = storm.blobs[math.random(#storm.blobs)]
                b.rx = math.max(2, math.min(9, b.rx + math.random(-1, 1)))
                b.ry = math.max(2, math.min(7, b.ry + math.random(-1, 1)))
            end
            if storm.life > 0 and storm.x < w + 20 then
                keep[#keep + 1] = storm
            end
        end
        local spec = seasonSpec()
        local westCount = 0
        for i = 1, #keep do
            if keep[i].x < w * 0.40 then
                westCount = westCount + 1
            end
        end
        local need = spec.min - westCount
        if need < 0 then need = 0 end
        if need > 3 then need = 3 end
        for _ = 1, need do
            if #keep < spec.max then
                keep[#keep + 1] = randomStorm(z, true)
            end
        end
        if #keep < spec.max and math.random() < spec.spawn * 0.40 then
            keep[#keep + 1] = randomStorm(z, true)
        end
        s.storms[z] = keep
    end
    paintAll()
end

function clouds.inClouds(unit)
    if not unit then return false end
    return isCloudTile(unit.location)
end

function clouds.tileIsCloud(tile)
    return isCloudTile(tile)
end

------------------------------------------------------------------------
-- Hooks
------------------------------------------------------------------------

discreteEvents.linkStateToModules(function(stateTable, stateTableKeys)
    if stateTableKeys.otrClouds then
        error("otrClouds state key used twice")
    end
    stateTableKeys.otrClouds = true
    stateTable.otrClouds = stateTable.otrClouds or {
        saved = {},
        original = {},
        noCloud = {},
        storms = { [MAP_DAY] = {}, [MAP_NIGHT] = {} },
        primed = false,
        snapshotted = false,
    }
    rawset(_G, "_otrClouds", stateTable.otrClouds)
end)

discreteEvents.onScenarioLoaded(function()
    local s = state()
    if not s.primed then
        clouds.advance()
    else
        paintAll()
    end
end)

discreteEvents.onTurn(function(turn)
    clouds.advance()
end)

discreteEvents.onKeyPress(function(keyID)
    if keyID == keyboard.k or keyID == keyboard.K then
        clouds.advance()
        local names = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}
        text.simple("Clouds advance. "..names[clouds.monthNumber()].." ("..clouds.seasonName()..").","Weather")
    end
end)

return clouds
