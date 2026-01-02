-- Nexus Development - NexusHud Client
local ESX = nil
local isHudHidden = false
local lastTalking = false

-- Fix: Sicherer ESX Loader (ersetzt den fehlerhaften Export)
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
end)

-- Mic Update Loop
Citizen.CreateThread(function()
    while true do
        Wait(200) -- Erhöht auf 200ms für bessere Performance
        local isTalking = NetworkIsPlayerTalking(PlayerId()) or IsControlPressed(0, 249)
        if isTalking ~= lastTalking then
            lastTalking = isTalking
            SendNUIMessage({ action = "updateMic", talking = isTalking })
        end
    end
end)

-- Health, Armor & Speed Loop
Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local sleep = 500
        local health = GetEntityHealth(playerPed)
        local maxHealth = GetEntityMaxHealth(playerPed)
        local displayHealth = 0

        if health > 100 then
            displayHealth = math.floor(((health - 100) / (maxHealth - 100)) * 100)
        else
            displayHealth = 0
        end

        if IsEntityDead(playerPed) or health <= 0 then displayHealth = 0 end
        local armor = GetPedArmour(playerPed)
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        if vehicle ~= 0 then
            sleep = 50 
            SendNUIMessage({
                action = "updateFast",
                speed = math.ceil(GetEntitySpeed(vehicle) * 3.6),
                inVehicle = true,
                health = displayHealth,
                armor = armor
            })
        else
            SendNUIMessage({
                action = "updateFast",
                inVehicle = false,
                health = displayHealth,
                armor = armor
            })
        end
        Wait(sleep)
    end
end)

-- Status, Money & ID Loop
Citizen.CreateThread(function()
    -- Warten bis ESX geladen ist und der Player bereit ist
    while ESX == nil do Wait(100) end
    while not ESX.IsPlayerLoaded() do Wait(500) end

    while true do
        local PlayerData = ESX.GetPlayerData()
        local cash, bank = 0, 0

        if PlayerData.accounts then
            for _, acc in pairs(PlayerData.accounts) do
                if acc.name == 'money' or acc.name == 'cash' then cash = acc.money end
                if acc.name == 'bank' then bank = acc.money end
            end
        end

        local hunger, thirst = 0, 0
        TriggerEvent('esx_status:getStatus', 'hunger', function(s) if s then hunger = s.getPercent() end end)
        TriggerEvent('esx_status:getStatus', 'thirst', function(s) if s then thirst = s.getPercent() end end)

        SendNUIMessage({
            action = "updateStatus",
            hunger = hunger,
            thirst = thirst,
            cash = cash,
            bank = bank,
            id = GetPlayerServerId(PlayerId())
        })
        Wait(1000)
    end
end)

-- Pause Menu Fade
Citizen.CreateThread(function()
    while true do
        Wait(300)
        if IsPauseMenuActive() and not isHudHidden then
            isHudHidden = true
            SendNUIMessage({action = "fade", state = true})
        elseif not IsPauseMenuActive() and isHudHidden then
            isHudHidden = false
            SendNUIMessage({action = "fade", state = false})
        end
    end
end)