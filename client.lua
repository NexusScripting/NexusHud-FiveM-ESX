local ESX = exports['es_extended']:getSharedObject()
local is_nui_ready = false
local hud_edit_mode = false

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

local function UpdatePlayerMoney()
    local pData = ESX.GetPlayerData()
    if pData and pData.accounts then
        local cash_amount, bank_amount = 0, 0
        for _, acc in pairs(pData.accounts) do
            if acc.name == 'money' or acc.name == 'cash' then cash_amount = acc.money
            elseif acc.name == 'bank' then bank_amount = acc.money end
        end
        SendNUIMessage({
            action = "status",
            cash = cash_amount, 
            bank = bank_amount,
            sid = GetPlayerServerId(PlayerId())
        })
    end
end

exports('SetHudVisible', function(state)
    SendNUIMessage({ action = "forceHide", state = not state })
end)

RegisterCommand('edithud', function()
    hud_edit_mode = not hud_edit_mode
    SetNuiFocus(hud_edit_mode, hud_edit_mode)
    SendNUIMessage({ action = "toggleEdit", state = hud_edit_mode })
end)

RegisterCommand('hudreset', function() 
    SendNUIMessage({ action = "resetHud" }) 
end)

RegisterNUICallback('closeEdit', function(data, cb)
    hud_edit_mode = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "toggleEdit", state = false })
    cb('ok')
end)

RegisterNUICallback('nuiReady', function(data, cb)
    is_nui_ready = true
    SendNUIMessage({ action = "init", colors = Config.Colors, branding = Config.Branding, settings = Config.Settings })
    UpdatePlayerMoney()
    cb('ok')
end)

-- Hier ist der Fix für "not safe for net"
RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account) 
    UpdatePlayerMoney() 
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    UpdatePlayerMoney()
end)

AddEventHandler('esx_status:onTick', function(all_stats)
    local h_perc, t_perc = 0, 0
    for i, s in pairs(all_stats) do
        if s.name == 'hunger' then h_perc = s.percent
        elseif s.name == 'thirst' then t_perc = s.percent end
    end
    SendNUIMessage({ action = "updateStats", h = h_perc, t = t_perc })
end)

CreateThread(function()
    local refresh_timer = 0
    while true do
        local sleep_time = 1200
        if is_nui_ready then
            local p_ped = PlayerPedId()
            local p_veh = GetVehiclePedIsIn(p_ped, false)
            local is_in_veh = (p_veh ~= 0 and GetPedInVehicleSeat(p_veh, -1) == p_ped)
            
            if is_in_veh then 
                sleep_time = 50 
            elseif NetworkIsPlayerTalking(PlayerId()) then
                sleep_time = 220
            end
            
            refresh_timer = refresh_timer + sleep_time
            if refresh_timer >= 5000 then -- Sync alle 5 Sek reicht dicke
                UpdatePlayerMoney()
                refresh_timer = 0 
            end

            local map_anchor = GetMinimapAnchor()
            SendNUIMessage({
                action = "tick",
                inVeh = is_in_veh,
                spd = is_in_veh and math.floor(GetEntitySpeed(p_veh) * 3.6) or 0,
                gear = is_in_veh and (GetVehicleCurrentGear(p_veh) == 0 and "R" or GetVehicleCurrentGear(p_veh)) or "N",
                rpm = is_in_veh and GetVehicleCurrentRpm(p_veh) or 0,
                hp = GetEntityHealth(p_ped) - 100,
                arm = GetPedArmour(p_ped),
                talking = NetworkIsPlayerTalking(PlayerId()),
                paused = IsPauseMenuActive(),
                mapPos = { x = map_anchor.x * 100, w = map_anchor.width * 100, y = map_anchor.y * 100 }
            })
        end
        Wait(sleep_time)
    end
end)