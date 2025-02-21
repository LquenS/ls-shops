local LS_CORE = exports['ls-core']:GetCoreObject()

RegisterNetEvent('qb-shops:server:UpdateShopItems', function(shop, itemData, amount)
    Config.Locations[shop]["products"][itemData.slot].amount = Config.Locations[shop]["products"][itemData.slot].amount - amount
    if Config.Locations[shop]["products"][itemData.slot].amount <= 0 then
        Config.Locations[shop]["products"][itemData.slot].amount = 0
    end
    TriggerClientEvent('qb-shops:client:SetShopItems', -1, shop, Config.Locations[shop]["products"])
end)

RegisterNetEvent('qb-shops:server:RestockShopItems', function(shop)
    if Config.Locations[shop]["products"] ~= nil then
        local randAmount = math.random(10, 50)
        for k in pairs(Config.Locations[shop]["products"]) do
            Config.Locations[shop]["products"][k].amount = Config.Locations[shop]["products"][k].amount + randAmount
        end
        TriggerClientEvent('qb-shops:client:RestockShopItems', -1, shop, randAmount)
    end
end)

LS_CORE.Callback.Functions.CreateCallback('qb-shops:server:getLicenseStatus', function(source, cb)
    local src = source
    local Player = LS_CORE.Functions.GetPlayer(src)
    local licenseItem = Player.Functions.GetItem("weaponlicense")
    cb(licenseItem)
end)

local ItemList = {
    ["casinochips"] = 1,
}

RegisterNetEvent('qb-shops:server:sellChips', function()
    local src = source
    local Player = LS_CORE.Functions.GetPlayer(src)
    local xItem = Player.Functions.GetItem("casinochips")
    if xItem ~= nil then
        for k in pairs(Player.DATA.items) do
            if Player.DATA.items[k] ~= nil then
                if ItemList[Player.DATA.items[k].name] ~= nil then
                    local price = ItemList[Player.DATA.items[k].name] * Player.DATA.items[k].amount
                    Player.Functions.RemoveItem(Player.DATA.items[k].name, Player.DATA.items[k].amount, k)
                    
                    Player.Functions.AddMoney("cash", price, "sold-casino-chips")
                    TriggerClientEvent('QBCore:Notify', src, "You sold your chips for $" .. price)
                    TriggerEvent("qb-log:server:CreateLog", "casino", "Chips", "blue", "**" .. GetPlayerName(src) .. "** got $" .. price .. " for selling the Chips")
                end
            end
        end
    end
end)