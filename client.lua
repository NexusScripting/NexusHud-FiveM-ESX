local ESX = nil
local isNuiReady = false

CreateThread(function()
    while ESX == nil do
        local status, result = pcall(function() return exports['es_extended']:getSharedObject() end)
        if status then ESX = result else TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) end
        Wait(100)
    end
end)

function updateMoney()
    if not ESX then return end
    local data = ESX.GetPlayerData()
    local m, b = 0, 0
    if data and data.accounts then
        for _, acc in pairs(data.accounts) do
            if acc.name == 'money' or acc.name == 'cash' then m = acc.money
            elseif acc.name == 'bank' then b = acc.money end
        end
    end
    SendNUIMessage({
        action = "status",
        cash = m, 
        bank = b,
        sid = GetPlayerServerId(PlayerId())
    })
end

function triggerInit()
    if not isNuiReady or not ESX then return end
    SendNUIMessage({
        action = "init",
        colors = Config.Colors,
        branding = Config.Branding
    })
    updateMoney()
end

RegisterNUICallback('nuiReady', function(data, cb)
    isNuiReady = true
    cb('ok')
    CreateThread(function()
        while ESX == nil or not ESX.IsPlayerLoaded() do Wait(100) end
        triggerInit()
    end)
end)

AddEventHandler('onClientResourceStart', function(res)
    if GetCurrentResourceName() ~= res then return end
    if isNuiReady and ESX and ESX.IsPlayerLoaded() then triggerInit() end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(x)
    ESX.PlayerData = x
    if isNuiReady then triggerInit() end
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function() updateMoney() end)

AddEventHandler('esx_status:onTick', function(data)
    local h, t = 0, 0
    for _, s in pairs(data) do
        if s.name == 'hunger' then h = s.percent
        elseif s.name == 'thirst' then t = s.percent end
    end
    SendNUIMessage({ action = "updateStats", h = h, t = t })
end)

CreateThread(function()
    while true do
        local p = PlayerPedId()
        local sleep = 500
        if isNuiReady then
            local hp, arm = GetEntityHealth(p) - 100, GetPedArmour(p)
            if hp < 0 then hp = 0 end
            local v = GetVehiclePedIsIn(p, false)
            local inV, s, g, r = false, 0, 0, 0
            if v ~= 0 and GetPedInVehicleSeat(v, -1) == p then
                inV, sleep = true, 100
                s = math.floor(GetEntitySpeed(v) * 3.6)
                g, r = GetVehicleCurrentGear(v), GetVehicleCurrentRpm(v)
                if s == 0 and g <= 1 then g = "N" end
            end
            SendNUIMessage({
                action = "tick",
                inVeh = inV, spd = s, gear = g, rpm = r,
                hp = hp, arm = arm,
                talking = NetworkIsPlayerTalking(PlayerId()),
                paused = IsPauseMenuActive()
            })
        end
        Wait(sleep)
    end
end)