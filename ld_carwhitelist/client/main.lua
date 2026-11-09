-- LD CarWhitelist (client): stops players from getting into a locked seat. The server checks it again.

local STATE = 'ldcwAccess'
local BYPASS_VEHICLE = 'ldCarwhitelistBypass'

Rules.build()

--- What the server says this player may use: bypass, and a set of group indexes.
local function myAccess()
    local s = LocalPlayer.state[STATE]
    local set = {}
    if type(s) == 'table' and type(s.groups) == 'table' then
        for _, gi in pairs(s.groups) do set[tonumber(gi)] = true end
    end
    return type(s) == 'table' and s.bypass == true, set
end

--- Returns nil when the player may use this seat, otherwise the group that locks it.
local function lockedBy(vehicle, seat)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    if Entity(vehicle).state[BYPASS_VEHICLE] then return nil end
    -- right after joining the server hasn't sent the access yet: don't block (the server still checks)
    if LocalPlayer.state[STATE] == nil then return nil end
    local bypass, set = myAccess()
    if bypass then return nil end
    return Rules.lockedBy(Rules.groupsFor(GetEntityModel(vehicle), GetVehicleClass(vehicle)), set, seat)
end

----------------------------------------------------------------------------------------------------
-- Notifications
----------------------------------------------------------------------------------------------------
local function started(res) return GetResourceState(res) == 'started' end

local function notify(message)
    local t = Config.Notify or 'auto'
    if t == 'none' then return end
    if t == 'auto' then
        t = started('ox_lib') and 'ox_lib' or started('es_extended') and 'esx'
            or (started('qb-core') or started('qbx_core')) and 'qb' or 'chat'
    end
    if t == 'ox_lib' then
        TriggerEvent('ox_lib:notify', { title = 'Vehicle', description = message, type = 'error' })
    elseif t == 'esx' then
        TriggerEvent('esx:showNotification', message, 'error')
    elseif t == 'qb' then
        TriggerEvent('QBCore:Notify', message, 'error')
    else
        TriggerEvent('chat:addMessage', { color = { 255, 90, 90 }, args = { 'Vehicle', message } })
    end
end

local lastNotify, lastReport = 0, 0
local function deny(vehicle, seat, group, key)
    local now = GetGameTimer()
    if now - lastNotify > 3000 then
        lastNotify = now
        notify(LDCWLText(key, Rules.label(group)))
    end
    if key == 'denied' and now - lastReport > 10000 and NetworkGetEntityIsNetworked(vehicle) then
        lastReport = now
        TriggerServerEvent('ld_carwhitelist:attempt', NetworkGetNetworkIdFromEntity(vehicle), seat)
    end
end

RegisterNetEvent('ld_carwhitelist:removed', function(label)
    lastNotify = GetGameTimer()
    notify(LDCWLText('removed', tostring(label)))
end)

----------------------------------------------------------------------------------------------------
-- The check
----------------------------------------------------------------------------------------------------
local function seatOf(ped, vehicle)
    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if GetPedInVehicleSeat(vehicle, seat) == ped then return seat end
    end
end

CreateThread(function()
    while true do
        local wait = 300
        local ped = PlayerPedId()

        -- trying to get in: stop it before the door opens
        local target = GetVehiclePedIsTryingToEnter(ped)
        if target ~= 0 then
            wait = 50
            local seat = GetSeatPedIsTryingToEnter(ped)
            local group = lockedBy(target, seat)
            if group then
                ClearPedTasks(ped)
                deny(target, seat, group, 'denied')
            end
        end

        -- already inside (warped in by a script, access just taken away, ...): get out
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 then
            local seat = seatOf(ped, vehicle)
            local group = seat and lockedBy(vehicle, seat)
            if group then
                -- never out of a flying aircraft or a moving car: wait until it (nearly) stands still
                if GetEntitySpeed(vehicle) < 3.0 and not IsEntityInAir(vehicle) then
                    TaskLeaveVehicle(ped, vehicle, 0)
                end
                deny(vehicle, seat, group, 'removed')
                wait = 1000
            end
        end

        Wait(wait)
    end
end)

----------------------------------------------------------------------------------------------------
-- Exports
----------------------------------------------------------------------------------------------------
--- exports.ld_carwhitelist:canUse(vehicle, seat) -> true | false, groupLabel   (seat default -1 = driver)
exports('canUse', function(vehicle, seat)
    local group = lockedBy(vehicle, seat or -1)
    return group == nil, group and group.label
end)
