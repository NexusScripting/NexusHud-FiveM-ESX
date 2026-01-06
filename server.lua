local ESX = exports['es_extended']:getSharedObject()

ESX.RegisterServerCallback('nexushud:getMileage', function(source, cb, plate)
    if not plate then return cb(0.0) end
    local p = string.gsub(plate, '^%s*(.-)%s*$', '%1')
    exports.oxmysql:scalar('SELECT mileage FROM nexus_mileage WHERE plate = ?', {p}, function(res)
        cb(tonumber(res) or 0.0)
    end)
end)

RegisterNetEvent('nexushud:updateMileage')
AddEventHandler('nexushud:updateMileage', function(plate, mileage)
    if not plate or not mileage then return end
    local p = string.gsub(plate, '^%s*(.-)%s*$', '%1')
    exports.oxmysql:query('INSERT INTO nexus_mileage (plate, mileage) VALUES (?, ?) ON DUPLICATE KEY UPDATE mileage = ?', {p, mileage, mileage})
end)