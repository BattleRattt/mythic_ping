local pendingPing = nil

function AddBlip(bData)
    bData.blip = AddBlipForCoord(bData.x, bData.y, bData.z)
    SetBlipSprite(bData.blip, bData.id)
    SetBlipAsShortRange(bData.blip, true)
    SetBlipScale(bData.blip, bData.scale)
    SetBlipColour(bData.blip, bData.color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(bData.name)
    EndTextCommandSetBlipName(bData.blip)
    SetBlipFlashes(bData.blip, true)

    pendingPing.count = 0
end

RegisterNetEvent('mythic_ping:client:SendPing')
AddEventHandler('mythic_ping:client:SendPing', function(sender, senderId)
    if pendingPing == nil then
        pendingPing = {}
        pendingPing.id = senderId
        pendingPing.name = sender

        Citizen.CreateThread(function()
            exports['mythic_notify']:DoCustomHudText('inform', pendingPing.name .. ' Sent You a Ping, Use /ping accept To Accept', (Config.Timeout * 1000))
            local count = 0
            while pendingPing ~= nil do
                count = count + 1
                if count >= Config.Timeout then
                    TriggerServerEvent('mythic_ping:server:SendPingResult', pendingPing.id, 'timeout')
                    pendingPing = nil
                end
                Citizen.Wait(1000)
            end
        end)
    else
        TriggerServerEvent('mythic_ping:server:SendPingResult', pendingPing.id, 'unable')
    end
end)

RegisterNetEvent('mythic_ping:client:AcceptPing')
AddEventHandler('mythic_ping:client:AcceptPing', function()
    if pendingPing ~= nil then
        local pos = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(pendingPing.id)), false)
        local playerBlip = { name = pendingPing.name, color = Config.BlipColor, id = Config.BlipIcon, scale = Config.BlipScale, x = pos.x, y = pos.y, z = pos.z }
        AddBlip(playerBlip)
        TriggerServerEvent('mythic_ping:server:SendPingResult', pendingPing.id, 'accept')
        pendingPing = nil
    else
        exports['mythic_notify']:DoHudText('inform', 'You Have No Pending Ping')
    end
end)

RegisterNetEvent('mythic_ping:client:RejectPing')
AddEventHandler('mythic_ping:client:RejectPing', function()
    if pendingPing ~= nil then
        TriggerServerEvent('mythic_ping:server:SendPingResult', pendingPing.id, 'reject')
        exports['mythic_notify']:DoHudText('inform', 'Rejected Ping From ' .. pendingPing.name)
        pendingPing = nil
    else
        exports['mythic_notify']:DoHudText('inform', 'You Have No Pending Ping')
    end
end)

Citizen.CreateThread(function()
    while true do
        if pendingPing.count ~= nil then
            if pendingPing.count >= Config.BlipDuration then
                RemoveBlip(pendingPing.blip)
                pendingPing = nil
            else
                pendingPing.count = pendingPing.count + 1
            end
        end
        Citizen.Wait(1000)
    end
end)
