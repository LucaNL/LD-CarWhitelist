-- LD CarWhitelist (server): works out who may use which group, enforces it, logs, checks for updates.

local RESOURCE = GetCurrentResourceName()
local VERSION = GetResourceMetadata(RESOURCE, 'version', 0) or '0.0.0'
local PREFIX = '^5LD CarWhitelist^7'
local STATE = 'ldcwAccess'          -- Player(src).state: { bypass = bool, groups = { group indexes } }
local BYPASS_VEHICLE = 'ldCarwhitelistBypass'

local function log(tag, fmt, ...) print(('%s %s %s^0'):format(PREFIX, tag, fmt:format(...))) end
local function ok(...) log('^2  OK ^7', ...) end
local function info(...) log('^7 INFO^7', ...) end
local function warn(...) log('^3 WARN^7', ...) end
local function hint(...) log('^6 HINT^7', ...) end
local function debug(...) if Config.Debug then log('^8DEBUG^7', ...) end end

local function started(res)
    local s = GetResourceState(res)
    return s == 'started' or s == 'starting'
end

----------------------------------------------------------------------------------------------------
-- Framework: the player's job as { name, grade, onDuty }
----------------------------------------------------------------------------------------------------
local framework, ESX, QBCore

local function detect()
    if started('es_extended') then
        local okExport, obj = pcall(function() return exports.es_extended:getSharedObject() end)
        if okExport and obj then ESX = obj; return 'esx' end
    end
    if started('qbx_core') then return 'qbx' end
    if started('qb-core') then
        local okExport, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if okExport and obj then QBCore = obj; return 'qb' end
    end
    return 'none'
end

local function jobOf(src)
    local okJob, job = pcall(function()
        if framework == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(src)
            local j = xPlayer and xPlayer.job
            if j then return { name = j.name, grade = j.grade, onDuty = j.onDuty } end
        elseif framework == 'qbx' then
            local player = exports.qbx_core:GetPlayer(src)
            local j = player and player.PlayerData and player.PlayerData.job
            if j then return { name = j.name, grade = type(j.grade) == 'table' and j.grade.level or j.grade, onDuty = j.onduty } end
        elseif framework == 'qb' then
            local player = QBCore.Functions.GetPlayer(src)
            local j = player and player.PlayerData and player.PlayerData.job
            if j then return { name = j.name, grade = type(j.grade) == 'table' and j.grade.level or j.grade, onDuty = j.onduty } end
        end
    end)
    if okJob then return job end
    debug('Could not read the job of %s: %s', tostring(src), tostring(job))
end

----------------------------------------------------------------------------------------------------
-- Access per player
----------------------------------------------------------------------------------------------------
local access = {}   -- src -> { bypass = bool, set = { [gi] = true }, groups = { gi, ... } }

local function compute(src)
    local bypass = Config.BypassAce and IsPlayerAceAllowed(src, Config.BypassAce) or false
    local job = jobOf(src)
    local set, list = {}, {}
    for gi, group in ipairs(Config.Groups or {}) do
        local allowed = bypass or Rules.jobAllows(group, job) or (group.ace and IsPlayerAceAllowed(src, group.ace))
        if allowed then set[gi] = true; list[#list + 1] = gi end
    end
    return { bypass = bypass, set = set, groups = list }
end

--- Work out the player's access again and share it with their game.
local function refresh(src)
    src = tonumber(src)
    if not src or not GetPlayerName(src) then return end
    local a = compute(src)
    local prev = access[src]
    access[src] = a
    if not prev or prev.bypass ~= a.bypass or table.concat(prev.groups, ',') ~= table.concat(a.groups, ',') then
        Player(src).state:set(STATE, { bypass = a.bypass, groups = a.groups }, true)
        debug('Access of %s: %s%s', GetPlayerName(src), a.bypass and 'bypass ' or '', table.concat(a.groups, ','))
    end
end

local function refreshAll()
    for _, id in ipairs(GetPlayers()) do refresh(id) end
end

-- job and duty changes (and loading a character) update right away
AddEventHandler('esx:setJob', function(src) refresh(src) end)
AddEventHandler('esx:playerLoaded', function(src) refresh(src) end)
AddEventHandler('QBCore:Server:OnJobUpdate', function(src) refresh(src) end)
AddEventHandler('QBCore:Server:SetDuty', function(src) refresh(src) end)
AddEventHandler('QBCore:Server:OnPlayerUpdated', function(src, key) -- newer qb-core versions
    if key == 'job' or key == nil then refresh(src) end
end)
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    refresh(type(player) == 'table' and player.PlayerData and player.PlayerData.source or player)
end)
AddEventHandler('playerJoining', function()
    local src = source -- `source` is gone inside the timeout
    SetTimeout(1000, function() refresh(src) end)
end)
local lastLog, removing = {}, {}
AddEventHandler('playerDropped', function()
    access[source], lastLog[source], removing[source] = nil, nil, nil -- server ids are reused
end)

--- Groups with `classes`: the server can't read a vehicle's class, so it can't tell whether such a group covers
--- the vehicle. If the player has access to one of them, the server lets the game decide. That way the server
--- never removes someone the game would allow.
local function hasClassGroup(set)
    for gi in pairs(set) do
        local g = Config.Groups[gi]
        if g and type(g.classes) == 'table' and #g.classes > 0 then return true end
    end
    return false
end

--- May this player use this vehicle seat? Returns true, or false plus the group that locks it.
local function mayUse(src, vehicle, seat)
    if Entity(vehicle).state[BYPASS_VEHICLE] then return true end
    local a = access[src] or compute(src)
    if a.bypass then return true end
    local group = Rules.lockedBy(Rules.groupsFor(GetEntityModel(vehicle)), a.set, seat)
    if group and hasClassGroup(a.set) then return true end
    if group then return false, group end
    return true
end

----------------------------------------------------------------------------------------------------
-- Discord log
----------------------------------------------------------------------------------------------------
local function webhook(src, group, what)
    local url = GetConvar('ldcwl_webhook', '')
    if url == '' then url = (Config.Webhook and Config.Webhook.Url) or '' end
    if url == '' then return end
    local now = os.time()
    if lastLog[src] and now - lastLog[src] < ((Config.Webhook and Config.Webhook.Cooldown) or 60) then return end
    lastLog[src] = now

    local job = jobOf(src)
    PerformHttpRequest(url, function() end, 'POST', json.encode({
        username = 'LD CarWhitelist',
        embeds = { {
            title = what,
            color = 15105570,
            fields = {
                { name = 'Player', value = ('%s (%d)'):format(GetPlayerName(src) or 'unknown', src), inline = true },
                { name = 'Vehicle group', value = Rules.label(group), inline = true },
                { name = 'Job', value = job and ('%s %s'):format(tostring(job.name), tostring(job.grade)) or 'unknown', inline = true },
            },
            footer = { text = 'LD CarWhitelist' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    }), { ['Content-Type'] = 'application/json' })
end

-- The game reports a blocked attempt (only used for the log; checked again here, never trusted).
RegisterNetEvent('ld_carwhitelist:attempt', function(netId, seat)
    local src = source
    if not (Config.Webhook and Config.Webhook.LogAttempts) then return end
    local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    local allowed, group = mayUse(src, vehicle, tonumber(seat) or -1)
    if not allowed then webhook(src, group, 'Tried to get into a locked vehicle') end
end)

----------------------------------------------------------------------------------------------------
-- Server check: remove players without access from locked seats
----------------------------------------------------------------------------------------------------
local function seatOf(ped, vehicle)
    for seat = -1, 15 do
        if GetPedInVehicleSeat(vehicle, seat) == ped then return seat end
    end
end

local AIRCRAFT = { heli = true, plane = true, blimp = true }
local SAFE_SPEED = 3.0 -- m/s: only remove someone from a vehicle that is (nearly) standing still

local function enforce()
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        local ped = GetPlayerPed(src)
        local vehicle = ped and ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0
        local seat = vehicle ~= 0 and seatOf(ped, vehicle)
        local allowed, group = true, nil
        if seat then allowed, group = mayUse(src, vehicle, seat) end

        if allowed then
            removing[src] = nil
        else
            -- never throw someone out of a flying aircraft or a moving car; wait until it stops
            local moving = GetEntitySpeed(vehicle) > SAFE_SPEED
            local aircraft = AIRCRAFT[tostring(GetVehicleType(vehicle))]
            if not moving and not (aircraft and GetEntitySpeed(vehicle) > 0.5) then
                TaskLeaveVehicle(ped, vehicle, 0)
            end
            if removing[src] ~= vehicle then -- log and notify once per vehicle, not every check
                removing[src] = vehicle
                TriggerClientEvent('ld_carwhitelist:removed', src, Rules.label(group))
                info('%s (%d) is in a locked %s vehicle without access%s.', GetPlayerName(src) or '?', src,
                    Rules.label(group), moving and ', removed once it stops' or '')
                webhook(src, group, 'In a locked vehicle without access')
            end
        end
    end
end

----------------------------------------------------------------------------------------------------
-- Exports
----------------------------------------------------------------------------------------------------
--- exports.ld_carwhitelist:hasAccess(source, modelOrVehicle) -> true | false, groupLabel
exports('hasAccess', function(src, model)
    src = tonumber(src)
    if not src or not GetPlayerName(src) then return false end
    if type(model) == 'string' then model = joaat(model) end
    if model and DoesEntityExist(model) and GetEntityType(model) == 2 then -- a vehicle entity
        local allowed, group = mayUse(src, model, -1)
        return allowed, group and group.label
    end
    local a = access[src] or compute(src)
    if a.bypass then return true end
    local group = Rules.lockedBy(Rules.groupsFor(model), a.set, -1)
    return group == nil, group and group.label
end)

--- exports.ld_carwhitelist:refreshPlayer(source) - after you changed a job or permission yourself
exports('refreshPlayer', function(src) refresh(src) end)

----------------------------------------------------------------------------------------------------
-- Update check: reads the latest release from GitHub once a day. Nothing about your server is sent.
----------------------------------------------------------------------------------------------------
local RELEASES = 'https://api.github.com/repos/LucaNL/LD-CarWhitelist/releases/latest'
local DOWNLOAD = 'https://github.com/LucaNL/LD-CarWhitelist/releases/latest'
local announced

local function parse(v)
    local a, b, c = tostring(v or ''):match('^v?(%d+)%.(%d+)%.?(%d*)')
    if a then return { tonumber(a), tonumber(b), tonumber(c) or 0 } end
end

local function newer(latest, current)
    local x, y = parse(latest), parse(current)
    if not x or not y then return false end
    for i = 1, 3 do if x[i] ~= y[i] then return x[i] > y[i] end end
    return false
end

local function checkVersion()
    PerformHttpRequest(RELEASES, function(status, body)
        if status ~= 200 or type(body) ~= 'string' then return end
        local okDecode, data = pcall(json.decode, body)
        local latest = okDecode and type(data) == 'table' and data.tag_name
        if latest and newer(latest, VERSION) and announced ~= latest then
            announced = latest
            warn('Update available: v%s → %s', VERSION, latest)
            hint('Download: %s (keep your config.lua).', DOWNLOAD)
        end
    end, 'GET', '', { ['Accept'] = 'application/vnd.github+json', ['User-Agent'] = RESOURCE })
end

----------------------------------------------------------------------------------------------------
-- Startup
----------------------------------------------------------------------------------------------------
CreateThread(function()
    Wait(0)
    framework = detect()
    Rules.build()
    local models = 0
    for _ in pairs(Rules.build().byModel) do models = models + 1 end
    ok('v%s started: %d group(s), %d model(s) · framework %s · server check %s', VERSION, #(Config.Groups or {}), models,
        framework == 'none' and 'none (ACE only)' or framework, Config.ServerCheck ~= false and 'on' or 'off')
    refreshAll()

    if Config.VersionCheck ~= false then SetTimeout(5000, checkVersion) end

    local sinceRefresh, sinceVersion = 0, 0
    local interval = math.max(500, tonumber(Config.ServerCheckInterval) or 1500)
    while true do
        Wait(interval)
        sinceRefresh = sinceRefresh + interval
        sinceVersion = sinceVersion + interval
        if sinceRefresh >= 15000 then sinceRefresh = 0; refreshAll() end -- catches job changes without events
        if Config.ServerCheck ~= false then
            local okRun, err = pcall(enforce)
            if not okRun then warn('Server check failed: %s', tostring(err)) end
        end
        if Config.VersionCheck ~= false and sinceVersion >= 86400000 then sinceVersion = 0; checkVersion() end
    end
end)

-- a restart of the framework resets the shared object
AddEventHandler('onResourceStart', function(res)
    if res == 'es_extended' or res == 'qb-core' or res == 'qbx_core' then
        SetTimeout(2000, function() framework = detect(); refreshAll() end)
    end
end)
