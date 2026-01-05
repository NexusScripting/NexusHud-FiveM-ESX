local ESX = exports['es_extended']:getSharedObject()
local is_nui_ready = false
local hud_edit_active = false

function GetMinimapAnchor()
    local aspect_ratio = GetAspectRatio(0)
    local res_x, res_y = GetActiveScreenResolution()
    local xscale = 1.0 / res_x
    local yscale = 1.0 / res_y
    local Minimap = {}
    Minimap.width = xscale * (res_x / (4 * aspect_ratio))
    Minimap.height = yscale * (res_y / 5.674)
    Minimap.left_x = xscale * (res_x * (1.0 / 20.0))
    if aspect_ratio > 2 then Minimap.left_x = Minimap.left_x * 0.8 end
    Minimap.bottom_y = 1.0 - yscale * (res_y * (1.0 / 20.0))
    Minimap.top_y = Minimap.bottom_y - Minimap.height
    Minimap.x = Minimap.left_x
    Minimap.y = Minimap.top_y
    return Minimap
end

local function UpdateClientMoney()
    local xPlayer = ESX.GetPlayerData()
    if xPlayer and xPlayer.accounts then
        local cash, bank = 0, 0
        for _, acc in pairs(xPlayer.accounts) do
            if acc.name == 'money' or acc.name == 'cash' then cash = acc.money
            elseif acc.name == 'bank' then bank = acc.money end
        end
        SendNUIMessage({
            action = "status",
            cash = cash, 
            bank = bank,
            sid = GetPlayerServerId(PlayerId())
        })
    end
end

exports('SetHudVisible', function(state)
    SendNUIMessage({ action = "forceHide", state = not state })
end)

RegisterCommand('edithud', function()
    hud_edit_active = not hud_edit_active
    SetNuiFocus(hud_edit_active, hud_edit_active)
    SendNUIMessage({ action = "toggleEdit", state = hud_edit_active })
end)

RegisterCommand('hudreset', function() 
    SendNUIMessage({ action = "resetHud" }) 
end)

RegisterNUICallback('closeEdit', function(data, cb)
    hud_edit_active = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "toggleEdit", state = false })
    cb('ok')
end)

RegisterNUICallback('nuiReady', function(data, cb)
    is_nui_ready = true
    SendNUIMessage({ action = "init", colors = Config.Colors, branding = Config.Branding, settings = Config.Settings })
    UpdateClientMoney()
    cb('ok')
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account) 
    UpdateClientMoney() 
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    UpdateClientMoney()
end)

AddEventHandler('esx_status:onTick', function(stats)
    local h, t = 0, 0
    for i, s in pairs(stats) do
        if s.name == 'hunger' then h = s.percent
        elseif s.name == 'thirst' then t = s.percent end
    end
    SendNUIMessage({ action = "updateStats", h = h, t = t })
end)

CreateThread(function()
    local sync_timer = 0
    while true do
        local sleep = 1200
        if is_nui_ready then
            local p_ped = PlayerPedId()
            local p_veh = GetVehiclePedIsIn(p_ped, false)
            local driving = (p_veh ~= 0 and GetPedInVehicleSeat(p_veh, -1) == p_ped)
            
            if driving then 
                sleep = 50 
            elseif NetworkIsPlayerTalking(PlayerId()) then
                sleep = 200
            end
            
            sync_timer = sync_timer + sleep
            if sync_timer >= 4500 then 
                UpdateClientMoney()
                sync_timer = 0 
            end

            local map = GetMinimapAnchor()
            SendNUIMessage({
                action = "tick",
                inVeh = driving,
                spd = driving and math.floor(GetEntitySpeed(p_veh) * 3.6) or 0,
                gear = driving and (GetVehicleCurrentGear(p_veh) == 0 and "R" or GetVehicleCurrentGear(p_veh)) or "N",
                rpm = driving and GetVehicleCurrentRpm(p_veh) or 0,
                hp = GetEntityHealth(p_ped) - 100,
                arm = GetPedArmour(p_ped),
                talking = NetworkIsPlayerTalking(PlayerId()),
                paused = IsPauseMenuActive(),
                mapPos = { x = map.x * 100, w = map.width * 100, y = map.y * 100 }
            })
        end
        Wait(sleep)
    end
end)