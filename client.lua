local ESX = exports['es_extended']:getSharedObject()
local is_nui_ready, is_edit, is_loaded = false, false, false
local cur_mileage, cur_plate, session_mileage = 0.0, nil, 0.0

function GetMinimapAnchor()
    local ratio = GetAspectRatio(0)
    local resX, resY = GetActiveScreenResolution()
    local xscale, yscale = 1.0 / resX, 1.0 / resY
    local m = {}
    m.width = xscale * (resX / (4 * ratio))
    m.height = yscale * (resY / 5.674)
    m.left_x = xscale * (resX * (1.0 / 20.0))
    if ratio > 2 then m.left_x = m.left_x * 0.8 end
    m.bottom_y = 1.0 - yscale * (resY * (1.0 / 20.0))
    m.top_y = m.bottom_y - m.height
    m.x, m.y = m.left_x, m.top_y
    return m
end

local function UpdateMoney()
    local data = ESX.GetPlayerData()
    if data and data.accounts then
        local cash, bank = 0, 0
        for _, a in pairs(data.accounts) do
            if a.name == 'money' or a.name == 'cash' then cash = a.money
            elseif a.name == 'bank' then bank = a.money end
        end
        SendNUIMessage({action = "status", cash = cash, bank = bank, sid = GetPlayerServerId(PlayerId())})
    end
end

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function() UpdateMoney() end)

RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function() UpdateMoney() end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function() UpdateMoney() end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer) 
    ESX.PlayerData = xPlayer
    UpdateMoney() 
end)

RegisterNUICallback('nuiReady', function(data, cb)
    is_nui_ready = true
    SendNUIMessage({action = "init", colors = Config.Colors, branding = Config.Branding, settings = Config.Settings})
    UpdateMoney()
    cb('ok')
end)

RegisterCommand('edithud', function()
    is_edit = not is_edit
    SetNuiFocus(is_edit, is_edit)
    SendNUIMessage({action = "toggleEdit", state = is_edit})
end)

RegisterCommand('hudreset', function() SendNUIMessage({action = "resetHud"}) end)

RegisterNUICallback('closeEdit', function(data, cb)
    is_edit = false
    SetNuiFocus(false, false)
    SendNUIMessage({action = "toggleEdit", state = false})
    cb('ok')
end)

AddEventHandler('esx_status:onTick', function(s)
    local h, t = 0, 0
    for _, v in pairs(s) do
        if v.name == 'hunger' then h = v.percent
        elseif v.name == 'thirst' then t = v.percent end
    end
    SendNUIMessage({action = "updateStats", h = h, t = t})
end)

CreateThread(function()
    local save_timer = 0
    local money_check = 0
    while true do
        local wait = 100 
        if is_nui_ready then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            local in_veh = (veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped)

            money_check = money_check + wait
            if money_check >= 500 then
                UpdateMoney()
                money_check = 0
            end

            if in_veh then
                local plate = ESX.Math.Trim(GetVehicleNumberPlateText(veh))
                if plate ~= cur_plate then
                    if cur_plate and is_loaded then TriggerServerEvent('nexushud:updateMileage', cur_plate, cur_mileage + session_mileage) end
                    cur_plate, cur_mileage, session_mileage, is_loaded = plate, 0.0, 0.0, false
                    ESX.TriggerServerCallback('nexushud:getMileage', function(m) cur_mileage = m or 0.0 is_loaded = true end, plate)
                end
                if is_loaded then
                    local speed = GetEntitySpeed(veh)
                    if speed > 0.5 then session_mileage = session_mileage + (speed * 0.1 / 1000.0) end
                end
                save_timer = save_timer + wait
                if save_timer >= 5000 then
                    if is_loaded then TriggerServerEvent('nexushud:updateMileage', cur_plate, cur_mileage + session_mileage) end
                    save_timer = 0
                end
            else
                if cur_plate then
                    if is_loaded then TriggerServerEvent('nexushud:updateMileage', cur_plate, cur_mileage + session_mileage) end
                    cur_plate, cur_mileage, session_mileage, is_loaded = nil, 0.0, 0.0, false
                end
            end

            local map = GetMinimapAnchor()
            SendNUIMessage({
                action = "tick",
                inVeh = in_veh,
                spd = in_veh and math.floor(GetEntitySpeed(veh) * 3.6) or 0,
                gear = in_veh and (GetVehicleCurrentGear(veh) == 0 and "R" or GetVehicleCurrentGear(veh)) or "N",
                rpm = in_veh and GetVehicleCurrentRpm(veh) or 0,
                mileage = cur_mileage + session_mileage,
                hp = GetEntityHealth(ped) - 100,
                arm = GetPedArmour(ped),
                talking = NetworkIsPlayerTalking(PlayerId()),
                paused = IsPauseMenuActive(),
                mapPos = {x = map.x * 100, y = map.y * 100, w = map.width * 100}
            })
        end
        Wait(wait)
    end
end)