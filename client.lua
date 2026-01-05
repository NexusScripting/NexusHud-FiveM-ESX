local ESX = exports['es_extended']:getSharedObject()
local p, inV = nil, false

function updateMoney()
    local x = ESX.GetPlayerData()
    local m, b = 0, 0
    if x and x.accounts then
        for _, acc in pairs(x.accounts) do
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
    Wait(500)
    SendNUIMessage({
        action = "init",
        colors = Config.Colors,
        branding = Config.Branding
    })
    updateMoney()
end

CreateThread(function()
    while not Config do Wait(0) end
    AddTextEntry('FE_THDR_GTAO', Config.Branding.menu)
end)

AddEventHandler('onClientResourceStart', function(res)
    if GetCurrentResourceName() ~= res then return end
    if ESX.IsPlayerLoaded() then triggerInit() end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(x)
    ESX.PlayerData = x
    triggerInit()
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function()
    updateMoney()
end)

AddEventHandler('esx_status:onTick', function(data)
    local h, t = 0, 0
    for _, s in pairs(data) do
        if s.name == 'hunger' then h = s.percent
        elseif s.name == 'thirst' then t = s.percent end
    end
    SendNUIMessage({
        action = "updateStats",
        h = h,
        t = t
    })
end)

CreateThread(function()
    while true do
        p = PlayerPedId()
        local sleep = 500
        local hp = GetEntityHealth(p) - 100
        local arm = GetPedArmour(p)
        if hp < 0 then hp = 0 end
        
        local v = GetVehiclePedIsIn(p, false)
        local s, g, r = 0, 0, 0
        
        if v ~= 0 and GetPedInVehicleSeat(v, -1) == p then
            inV = true
            sleep = 100
            s = math.floor(GetEntitySpeed(v) * 3.6)
            g = GetVehicleCurrentGear(v)
            r = GetVehicleCurrentRpm(v)
            if s == 0 and g <= 1 then g = "N" end
        else
            inV = false
        end

        SendNUIMessage({
            action = "tick",
            inVeh = inV,
            spd = s,
            gear = g,
            rpm = r,
            hp = hp,
            arm = arm,
            talking = NetworkIsPlayerTalking(PlayerId()),
            paused = IsPauseMenuActive()
        })
        Wait(sleep)
    end
end)