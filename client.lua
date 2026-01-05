local ESX = nil
local isTalking = false
local uiLoaded = false

CreateThread(function()
    while not ESX do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(100)
    end
end)

CreateThread(function()
    Wait(500)
    AddTextEntry('FE_THDR_GTAO', '~p~NEXUS ~w~ROLEPLAY')
end)

CreateThread(function()
    while true do
        local p = PlayerPedId()
        local sleep = 500
        
        local hp = GetEntityHealth(p) - 100
        local arm = GetPedArmour(p)
        if hp < 0 then hp = 0 end

        local v = GetVehiclePedIsIn(p, false)
        local inV = false
        local s, g, r = 0, 0, 0

        if v ~= 0 and GetPedInVehicleSeat(v, -1) == p then
            inV = true
            sleep = 100
            s = math.floor(GetEntitySpeed(v) * 3.6)
            g = GetVehicleCurrentGear(v)
            r = GetVehicleCurrentRpm(v)
            if s == 0 and g <= 1 then g = "N" end
        end

        local mic = NetworkIsPlayerTalking(PlayerId()) or IsControlPressed(0, 249)

        SendNUIMessage({
            action = "tick",
            inVeh = inV,
            spd = s,
            gear = g,
            rpm = r,
            hp = hp,
            arm = arm,
            talking = mic,
            paused = IsPauseMenuActive()
        })

        Wait(sleep)
    end
end)

CreateThread(function()
    while not ESX or not ESX.IsPlayerLoaded() do Wait(1000) end
    
    while true do
        local data = ESX.GetPlayerData()
        local m, b = 0, 0

        if data.accounts then
            for _, acc in pairs(data.accounts) do
                if acc.name == 'money' or acc.name == 'cash' then m = acc.money
                elseif acc.name == 'bank' then b = acc.money end
            end
        end

        local h, t = 0, 0
        TriggerEvent('esx_status:getStatus', 'hunger', function(s) if s then h = s.getPercent() end end)
        TriggerEvent('esx_status:getStatus', 'thirst', function(s) if s then t = s.getPercent() end end)

        SendNUIMessage({
            action = "status",
            cash = m,
            bank = b,
            h = h,
            t = t,
            sid = GetPlayerServerId(PlayerId())
        })
        Wait(2000)
    end
end)