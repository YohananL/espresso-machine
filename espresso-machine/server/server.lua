local QBCore = exports['qb-core']:GetCoreObject()

RegisterCommand('espresso', function(source, _, _)
    TriggerClientEvent('espresso:client:start', source)
end, false)

RegisterCommand('removeespresso', function(source, _, _)
    TriggerClientEvent('espresso:client:removeespresso', source)
end, false)

--- Set the function when using the latte item
QBCore.Functions.CreateUseableItem('latte', function(source, item)
    local playerId = source
    local player = QBCore.Functions.GetPlayer(playerId)
    if player.Functions.GetItemByName(item.name) then
        TriggerClientEvent('espresso:client:drinkLatte', playerId)
        player.Functions.RemoveItem('latte', 1)
    end

    -- local player = QBCore.Functions.GetPlayer(playerId)
    -- if not player.Functions.RemoveItem(item.name, 1, item.slot) then return end
    -- TriggerClientEvent('espresso:client:drinkLatte', playerId)
end)

--- Add a latte to the player's inventory
RegisterNetEvent('espresso:server:createLatte', function()
    local playerId = source
    local player = QBCore.Functions.GetPlayer(playerId)
    player.Functions.AddItem('latte', 1)
end)

--- Delete entity from server using net id from client
--- @param netId integer - The net id of the entity to delete
RegisterNetEvent('espresso:server:deleteEntity', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end)

--[[
Add to qb-core\shared\items.lua
    latte = { name = "latte", label = "Latte", weight = 10, type = "item", image = "latte.png", unique = false, useable = true, shouldClose = true, combinable = nil, description = "A latte to warm your soul <3" },

Add latte.png to qb-inventory\html\images
--]]
