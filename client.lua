local ESX = exports['es_extended']:getSharedObject()
local is_nui_fertig = false
local im_edit_modus = false

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

local function UpdateMoneyHUD()
    local xPlayer = ESX.GetPlayerData()
    if xPlayer and xPlayer.accounts then
        local geld, bank = 0, 0
        for _, account in pairs(xPlayer.accounts) do
            if account.name == 'money' or account.name == 'cash' then geld = account.money
            elseif account.name == 'bank' then bank = account.money end
        end
        SendNUIMessage({
            action = "status",
            cash = geld, 
            bank = bank,
            sid = GetPlayerServerId(PlayerId())
        })
    end
end

exports('SetHudVisible', function(status)
    SendNUIMessage({ action = "forceHide", state = not status })
end)

RegisterCommand('edithud', function()
    im_edit_modus = not im_edit_modus
    SetNuiFocus(im_edit_modus, im_edit_modus)
    SendNUIMessage({ action = "toggleEdit", state = im_edit_modus })
end)

RegisterCommand('hudreset', function() 
    SendNUIMessage({ action = "resetHud" }) 
end)

RegisterNUICallback('closeEdit', function(data, cb)
    im_edit_modus = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "toggleEdit", state = false })
    cb('ok')
end)

RegisterNUICallback('nuiReady', function(data, cb)
    is_nui_fertig = true
    SendNUIMessage({ action = "init", colors = Config.Colors, branding = Config.Branding, settings = Config.Settings })
    UpdateMoneyHUD()
    cb('ok')
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account) 
    UpdateMoneyHUD() 
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    UpdateMoneyHUD()
end)

AddEventHandler('esx_status:onTick', function(stats)
    local hunger, durst = 0, 0
    for _, s in pairs(stats) do
        if s.name == 'hunger' then hunger = s.percent
        elseif s.name == 'thirst' then durst = s.percent end
    end
    SendNUIMessage({ action = "updateStats", h = hunger, t = durst })
end)

CreateThread(function()
    local dings_timer = 0
    while true do
        local schlafen = 1100
        if is_nui_fertig then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            local im_auto = (veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped)
            
            if im_auto then 
                schlafen = 50 
            elseif NetworkIsPlayerTalking(PlayerId()) then
                schlafen = 200
            end
            
            dings_timer = dings_timer + schlafen
            if dings_timer >= 4000 then 
                UpdateMoneyHUD()
                dings_timer = 0 
            end

            local map = GetMinimapAnchor()
            SendNUIMessage({
                action = "tick",
                inVeh = im_auto,
                spd = im_auto and math.floor(GetEntitySpeed(veh) * 3.6) or 0,
                gear = im_auto and (GetVehicleCurrentGear(veh) == 0 and "R" or GetVehicleCurrentGear(veh)) or "N",
                rpm = im_auto and GetVehicleCurrentRpm(veh) or 0,
                hp = GetEntityHealth(ped) - 100,
                arm = GetPedArmour(ped),
                talking = NetworkIsPlayerTalking(PlayerId()),
                paused = IsPauseMenuActive(),
                mapPos = { x = map.x * 100, w = map.width * 100, y = map.y * 100 }
            })
        end
        Wait(schlafen)
    end
end)