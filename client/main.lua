local LS_CORE = exports["ls-core"]:GetCoreObject()
local inChips = false
local currentShop, currentData
local pedSpawned = false
local ShopPed = {}

local function GetPlayerJob()
    return LS_CORE.Functions.GetPlayerData().PlayerData.job.name
end

local function ShowHelpText(string)	
    BeginTextCommandDisplayHelp("STRING")
	AddTextComponentSubstringPlayerName(string)
    EndTextCommandDisplayHelp(0, 0, 1, -1)
end


-- Functions
local function SetupItems(shop)
    local products = Config.Locations[shop].products
    local playerJob = GetPlayerJob()
    local items = {}
    for i = 1, #products do
        if not products[i].requiredJob then
            items[#items + 1] = products[i]
        else
            for i2 = 1, #products[i].requiredJob do
                if playerJob == products[i].requiredJob[i2] then
                    items[#items + 1] = products[i]
                end
            end
        end
    end
    return items
end

local function createBlips()
    for store, _ in pairs(Config.Locations) do
        if Config.Locations[store]["showblip"] then
            local StoreBlip = AddBlipForCoord(Config.Locations[store]["coords"]["x"], Config.Locations[store]["coords"]["y"], Config.Locations[store]["coords"]["z"])
            SetBlipSprite(StoreBlip, Config.Locations[store]["blipsprite"])
            SetBlipScale(StoreBlip, 0.6)
            SetBlipDisplay(StoreBlip, 4)
            SetBlipColour(StoreBlip, Config.Locations[store]["blipcolor"])
            SetBlipAsShortRange(StoreBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Config.Locations[store]["label"])
            EndTextCommandSetBlipName(StoreBlip)
        end
    end
end

-- Events
RegisterNetEvent("qb-shops:client:UpdateShop", function(shop, itemData, amount)
    TriggerServerEvent("qb-shops:server:UpdateShopItems", shop, itemData, amount)
end)

RegisterNetEvent("qb-shops:client:SetShopItems", function(shop, shopProducts)
    Config.Locations[shop]["products"] = shopProducts
end)

RegisterNetEvent("qb-shops:client:RestockShopItems", function(shop, amount)
    if Config.Locations[shop]["products"] ~= nil then
        for k in pairs(Config.Locations[shop]["products"]) do
            Config.Locations[shop]["products"][k].amount = Config.Locations[shop]["products"][k].amount + amount
        end
    end
end)

local function openShop(shop, data)
    local products = data.products
    local ShopItems = {}
    ShopItems.items = {}
    LS_CORE.Callback.Functions.TriggerCallback("qb-shops:server:getLicenseStatus", function(hasLicense, hasLicenseItem)
        ShopItems.label = data["label"]
        if data.type == "weapon" then
            if  hasLicenseItem then
                ShopItems.items = SetupItems(shop)
                Wait(500)
            else
                for i = 1, #products do
                    if not products[i].requiredJob then
                        if not products[i].requiresLicense then
                            ShopItems.items[#ShopItems.items + 1] = products[i]
                        end
                    else
                        for i2 = 1, #products[i].requiredJob do
                            if GetPlayerJob() == products[i].requiredJob[i2] and not products[i].requiresLicense then
                                ShopItems.items[#ShopItems.items + 1] = products[i]
                            end
                        end
                    end
                end
                Wait(1000)
            end
        else
            ShopItems.items = SetupItems(shop)
        end
        for k in pairs(ShopItems.items) do
            ShopItems.items[k].slot = k
        end
        ShopItems.slots = 30
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "itemshop_" .. shop, ShopItems)
    end)
end

local listen = false
local function Listen4Control()
    CreateThread(function()
        listen = true
        while listen do
            ShowHelpText("Press [E] key to open shop") 
            if IsControlJustPressed(0, 38) then -- E
                if inChips then
                    TriggerServerEvent("qb-shops:server:sellChips")
                else
                    openShop(currentShop, currentData)
                end
                listen = false
                break
            end
            Wait(1)
        end
    end)
end

local function createPeds()
    if pedSpawned then return end
    for k, v in pairs(Config.Locations) do
        if not ShopPed[k] then ShopPed[k] = {} end
        local current = v["ped"]
        current = type(current) == 'string' and GetHashKey(current) or current
        RequestModel(current)

        while not HasModelLoaded(current) do
            Wait(0)
        end
        ShopPed[k] = CreatePed(0, current, v["coords"].x, v["coords"].y, v["coords"].z-1, v["coords"].w, false, false)
        TaskStartScenarioInPlace(ShopPed[k], v["scenario"], true)
        FreezeEntityPosition(ShopPed[k], true)
        SetEntityInvincible(ShopPed[k], true)
        SetBlockingOfNonTemporaryEvents(ShopPed[k], true)
    end

    if not ShopPed["casino"] then ShopPed["casino"] = {} end
    local current = Config.SellCasinoChips.ped
    current = type(current) == 'string' and GetHashKey(current) or current
    RequestModel(current)

    while not HasModelLoaded(current) do
        Wait(0)
    end
    ShopPed["casino"] = CreatePed(0, current, Config.SellCasinoChips.coords.x, Config.SellCasinoChips.coords.y, Config.SellCasinoChips.coords.z-1, Config.SellCasinoChips.coords.w, false, false)
    FreezeEntityPosition(ShopPed["casino"], true)
    SetEntityInvincible(ShopPed["casino"], true)
    SetBlockingOfNonTemporaryEvents(ShopPed["casino"], true)

    pedSpawned = true
end

local function deletePeds()
    if pedSpawned then
        for _, v in pairs(ShopPed) do
            DeletePed(v)
        end
    end
end

-- Threads

local NewZones = {}
CreateThread(function()
    while true do
        local sleep = 500
        local playerCoords = GetEntityCoords(PlayerPedId())

        for k in pairs( Config.Locations ) do
            local shopCoords = vector3(Config.Locations[k]["coords"]["x"], Config.Locations[k]["coords"]["y"], Config.Locations[k]["coords"]["z"])

            local distance = #(playerCoords - shopCoords)
            if distance <= Config.Locations[k]["radius"] and not listen then
                currentShop = k
                currentData = Config.Locations[k]
                Listen4Control()
                sleep = 5
            end

            if distance >= Config.Locations[k]["radius"] and listen and currentShop == k then
                listen = false
            end

            if distance <= Config.Locations[k]["radius"] and listen then sleep = 5 end
        end

        local chipCoords = vector3(Config.SellCasinoChips["coords"]["x"], Config.SellCasinoChips["coords"]["y"], Config.SellCasinoChips["coords"]["z"])
        local distance = #(playerCoords - chipCoords)
        if distance <= Config.SellCasinoChips["radius"] then
            inChips = true
            sleep = 5
        else
            inChips = false
        end

        Wait( sleep )
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createBlips()
    createPeds()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    deletePeds()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        createBlips()
        createPeds()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        deletePeds()
    end
end)
