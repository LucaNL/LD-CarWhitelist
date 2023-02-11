ESX = nil

Citizen.CreateThread(function()
	export, ESX = pcall(function()
        return exports.es_extended:getSharedObject()
    end)
	if not export then
        while not ESX do
			TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Wait(100)
        end
    end
	while not ESX.GetPlayerData().job do
		Citizen.Wait(10)
	end
	ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

Citizen.CreateThread(function()
	while ESX and ESX.PlayerData do
		local playerPed = PlayerPedId()
		if playerPed ~= 0 then
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if vehicle ~= 0 then
				local seat = GetPedInVehicleSeat(vehicle, -1)
				if seat == playerPed then
					local isEmergencyJob = getEmergencyJob()
					if not isEmergencyJob then
						local isVehicleBlacklisted = getVehicleBlacklist(GetEntityModel(vehicle))
						if isVehicleBlacklisted then
							TaskLeaveVehicle(playerPed, vehicle, 1)
							if Config.Notify then
								ESX.ShowNotification(Config.NotifyMessage)
							end
						end
					end
				end
			end
		end
		Citizen.Wait(Config.CheckTime)
	end
end)

function getEmergencyJob()
	for k,v in ipairs(Config.emergencyJobs) do
		if ESX.PlayerData.job.name == v then
			return true
		end
	end 
	return false
end

function getVehicleBlacklist(model)
	for k,v in ipairs(Config.emergencyVehicles) do
		if model == GetHashKey(v) then
			return true
		end
	end
	return false
end