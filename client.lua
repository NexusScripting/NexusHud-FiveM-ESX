local ESX = nil
local hudHidden = false
local lastTalking = false

CreateThread(function()
    while ESX == nil do
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
        Wait(150)
        local talking = NetworkIsPlayerTalking(PlayerId()) or IsControlPressed(0, 249)

        if talking ~= lastTalking then
            lastTalking = talking
            SendNUIMessage({
                action = "updateMic",
                talking = talking
            })
        end
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local sleep = 500
        
        local health = GetEntityHealth(ped)
        local maxHealth = GetEntityMaxHealth(ped)
        local armor = GetPedArmour(ped)
        local shownHealth = 0

        if health > 100 then
            shownHealth = math.floor((health - 100) / (maxHealth - 100) * 100)
        end
        if IsEntityDead(ped) then shownHealth = 0 end

        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            sleep = 80
            local speed = math.floor(GetEntitySpeed(veh) * 3.6)
            local gear = GetVehicleCurrentGear(veh)
            local rpm = GetVehicleCurrentRpm(veh)

            if speed == 0 and gear <= 1 then gear = "N" end

            SendNUIMessage({
                action = "updateFast",
                inVehicle = true,
                speed = speed,
                gear = gear,
                rpm = rpm,
                health = shownHealth,
                armor = armor
            })
        else
            SendNUIMessage({
                action = "updateFast",
                inVehicle = false,
                health = shownHealth,
                armor = armor
            })
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while ESX == nil or not ESX.IsPlayerLoaded() do Wait(500) end

    while true do
        local data = ESX.GetPlayerData()
        local cash, bank = 0, 0

        if data.accounts then
            for _, acc in pairs(data.accounts) do
                if acc.name == 'money' or acc.name == 'cash' then
                    cash = acc.money
                elseif acc.name == 'bank' then
                    bank = acc.money
                end
            end
        end

        local hunger, thirst = 0, 0
        TriggerEvent('esx_status:getStatus', 'hunger', function(s) if s then hunger = s.getPercent() end end)
        TriggerEvent('esx_status:getStatus', 'thirst', function(s) if s then thirst = s.getPercent() end end)

        SendNUIMessage({
            action = "updateStatus",
            cash = cash,
            bank = bank,
            hunger = hunger,
            thirst = thirst,
            id = GetPlayerServerId(PlayerId())
        })
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        Wait(300)
        local active = IsPauseMenuActive()

        if active and not hudHidden then
            hudHidden = true
            SendNUIMessage({ action = "fade", state = true })
        elseif not active and hudHidden then
            hudHidden = false
            SendNUIMessage({ action = "fade", state = false })
        end
    end
end)