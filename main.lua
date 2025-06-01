-- Переписано с Turtle UI Lib на Rayfield UI Lib
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/mujarino/test/refs/heads/main/Rayfield%20Lib%20Source.lua"))()

local Window = Rayfield:CreateWindow({
    Name = "Island Automation",
    LoadingTitle = "Island Script Loader",
    LoadingSubtitle = "by Rayfield",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "IslandScriptData",
        FileName = "Settings"
    },
    KeySystem = false
})

local BuildTab = Window:CreateTab("Build", 4483362458)
local BuyTab = Window:CreateTab("Buy", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local FilterTab = Window:CreateTab("Filter", 4483362458)

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Lib/main/source.lua"))()
local m = lib:Window("Build An Island")
local bi = lib:Window("Buy Items")
local s = lib:Window("Settings")
local res = lib:Window("Resource Filter")

local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local plot = game:GetService("Workspace"):WaitForChild("Plots"):WaitForChild(plr.Name)

local land = plot:FindFirstChild("Land")
local resources = plot:WaitForChild("Resources")
local expand = plot:WaitForChild("Expand")

local TurtleLib = game:GetService("CoreGui"):FindFirstChild("TurtleUiLib")
local MAX_CONCURRENT_REQUESTS = 25

getgenv().resourceSettings = {}

getgenv().settings = {
    farm = false,
    farmAll = false,
    farmAllInstant = false,
    instantFarm = false,
    instantFarmDelay = 18,
    instantFarmBursts = 5,
    expand = false,
    craft = false,
    sell = false,
    gold = false,
    collect = false,
    harvest = false,
    hive = false,
    auto_buy = false
}

local expand_delay = 1
local craft_delay = 1

-- Автоматическое определение типов ресурсов
local function scanResourceTypes()
    local resourceTypes = {}
    local plots = game:GetService("Workspace"):WaitForChild("Plots")
    
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:FindFirstChild("Resources") then
            for _, resource in ipairs(plot.Resources:GetChildren()) do
                if not table.find(resourceTypes, resource.Name) then
                    table.insert(resourceTypes, resource.Name)
                    if resourceSettings[resource.Name] == nil then
                        resourceSettings[resource.Name] = true -- По умолчанию включен
                    end
                end
            end
        end
    end
    
    return resourceTypes
end

local availableResources = scanResourceTypes()
for _, resName in ipairs(availableResources) do
    res:Toggle(resName, resourceSettings[resName], function(state)
        resourceSettings[resName] = state
    end
})
end

local function getFilteredResources()
    local filteredResources = {}
    local plots = game:GetService("Workspace"):WaitForChild("Plots")
    
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:FindFirstChild("Resources") then
            for _, resource in ipairs(plot.Resources:GetChildren()) do
                if resourceSettings[resource.Name] then
                    table.insert(filteredResources, resource)
                end
            end
        end
    end
    
    -- Дополнительно ищем ресурсы вне островов (если есть)
    local worldResources = workspace:FindFirstChild("WorldResources") or workspace:FindFirstChild("GlobalResources")
    if worldResources then
        for _, resource in ipairs(worldResources:GetChildren()) do
            if resourceSettings[resource.Name] then
                table.insert(filteredResources, resource)
            end
        end
    end
    
    return filteredResources
end

-- Функция для получения всех ресурсов в мире
local function instantFarmAll()
    local MAX_CONCURRENT = 25
    local resourcesToFarm = getFilteredResources()
    local activeTasks = 0
    
    for _, r in ipairs(resourcesToFarm) do
        while activeTasks >= MAX_CONCURRENT do
            task.wait()
        end
        
        activeTasks += 1
        task.spawn(function()
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("HitResource"):FireServer(r)
            end
})
            activeTasks -= 1
        end
})
    end
    
    while activeTasks > 0 do
        task.wait()
    end
end

BuildTab:CreateToggle({
    Name = "Burst Farm (5x)",
    CurrentValue = settings.instantFarm,
    Flag = "Burst Farm (5x)",
    Callback = function(b)
    settings.instantFarm = b
    if b then
        task.spawn(function()
            while settings.instantFarm do
                -- Выполняем серию из 5 быстрых сборов
                for i = 1, settings.instantFarmBursts do
                    if not settings.instantFarm then break end
                    instantFarmAll() -- Используем исправленную функцию
                    task.wait(0.3) -- Уменьшенная задержка между волнами
                end
                
                -- Большая пауза после серии сборов
                local waitTime = settings.instantFarmDelay
                while waitTime > 0 and settings.instantFarm do
                    task.wait(1)
                    waitTime = waitTime - 1
                end
            end
        end
})
    end
end
})

BuildTab:CreateToggle({
    Name = "INSTANT Farm All",
    CurrentValue = settings.instantFarm,
    Flag = "INSTANT Farm All",
    Callback = function(b)
    settings.instantFarm = b
    if b then
        task.spawn(function()
            while settings.instantFarm do
                instantFarmAll()
                -- Ждем указанное количество секунд перед следующей волной
                local waitTime = settings.instantFarmDelay
                while waitTime > 0 and settings.instantFarm do
                    task.wait(1)
                    waitTime = waitTime - 1
                end
            end
        end
})
    end
end
})

-- Оригинальная функция добычи (только ваш остров)
BuildTab:CreateToggle({
    Name = "Auto Farm Resources",
    CurrentValue = settings.farm,
    Flag = "Auto Farm Resources",
    Callback = function(b)
    settings.farm = b
    task.spawn(function()
        while settings.farm do
            for _, r in ipairs(resources:GetChildren()) do
                game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("HitResource"):FireServer(r)
                task.wait(.01)
            end
            task.wait(.1)
        end
    end
})
end
})

-- Новая функция добычи всех ресурсов
BuildTab:CreateToggle({
    Name = "Auto Farm ALL Resources",
    CurrentValue = settings.farmAll,
    Flag = "Auto Farm ALL Resources",
    Callback = function(b)
    settings.farmAll = b
    task.spawn(function()
        while settings.farmAll do
            local filteredResources = getFilteredResources() -- Используем фильтрацию
            for _, r in ipairs(filteredResources) do
                game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("HitResource"):FireServer(r)
                task.wait(.01)
            end
            task.wait(.1)
        end
    end
})
end
})

-- Остальные функции остаются без изменений
BuildTab:CreateToggle({
    Name = "Auto Expand Land",
    CurrentValue = settings.expand,
    Flag = "Auto Expand Land",
    Callback = function(b)
    settings.expand = b
    task.spawn(function()
        while settings.expand do
            for _, exp in ipairs(expand:GetChildren()) do
                local top = exp:FindFirstChild("Top")
                if top then
                    local bGui = top:FindFirstChild("BillboardGui")
                    if bGui then
                        for _, contribute in ipairs(bGui:GetChildren()) do
                            if contribute:IsA("Frame") and contribute.Name ~= "Example" then
                                local args = {
                                    exp.Name,
                                    contribute.Name,
                                    1
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("ContributeToExpand"):FireServer(unpack(args))
                            end
                        end
                    end
                end
                task.wait(0.01)
            end
            task.wait(expand_delay)
        end
    end
})
end
})

BuildTab:CreateToggle({
    Name = "Auto Crafter",
    CurrentValue = settings.craft,
    Flag = "Auto Crafter",
    Callback = function(b)
    settings.craft = b
    task.spawn(function()
        while settings.craft do
            for _, c in pairs(plot:GetDescendants()) do
                if c.Name == "Crafter" then
                    local attachment = c:FindFirstChildOfClass("Attachment")
                    if attachment then
                        game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("Craft"):FireServer(attachment)
                    end
                end
            end
            task.wait(craft_delay)
        end
    end
})
end
})

BuildTab:CreateToggle({
    Name = "Auto Gold Mine",
    CurrentValue = settings.gold,
    Flag = "Auto Gold Mine",
    Callback = function(b)
    settings.gold = b
    task.spawn(function()
        while settings.gold do
            for _, mine in pairs(land:GetDescendants()) do
                if mine:IsA("Model") and mine.Name == "GoldMineModel" then
                    game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("Goldmine"):FireServer(mine.Parent.Name, 1)
                end
            end
            task.wait(1)
        end
    end
})
end
})

BuildTab:CreateToggle({
    Name = "Auto Collect Gold",
    CurrentValue = settings.collect,
    Flag = "Auto Collect Gold",
    Callback = function(b)
    settings.collect = b
    task.spawn(function()
        while settings.collect do
            for _, mine in pairs(land:GetDescendants()) do
                if mine:IsA("Model") and mine.Name == "GoldMineModel" then
                    game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("Goldmine"):FireServer(mine.Parent.Name, 2)
                end
            end
            task.wait(1)
        end
    end
})
end
})

BuildTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = settings.sell,
    Flag = "Auto Sell",
    Callback = function(b)
    settings.sell = b
    task.spawn(function()
        while settings.sell do
            for _, crop in pairs(plr.Backpack:GetChildren()) do
                if crop:GetAttribute("Sellable") then
                    -- Проверяем, что это не зелье (может быть несколько условий)
                    local isPotion = false
                    
                    -- Проверка по названию (если зелья содержат "Potion" в названии)
                    if crop.Name:match("Potion") then
                        isPotion = true
                    end
                    
                    -- Продаем только если это не зелье
                    if not isPotion then
                        local a = {
                            false,
                            {
                                crop:GetAttribute("Hash")
                            }
                        }
                        game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("SellToMerchant"):FireServer(unpack(a))
                    end
                end
            end
            task.wait(1)
        end
    end
})
end
})

BuildTab:CreateToggle({
    Name = "Auto Harvest",
    CurrentValue = settings.harvest,
    Flag = "Auto Harvest",
    Callback = function(b)
    settings.harvest = b
    task.spawn(function()
        while settings.harvest do
            for _, crop in pairs(plot:FindFirstChild("Plants"):GetChildren()) do
                game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("Harvest"):FireServer(crop.Name)
            end
            task.wait(1)
        end
    end
})
end
})

BuildTab:CreateToggle({
    Name = "Auto Collect Hive",
    CurrentValue = settings.hive,
    Flag = "Auto Collect Hive",
    Callback = function(b)
    settings.hive = b
    task.spawn(function()
        while settings.hive do
            for _, spot in ipairs(land:GetDescendants()) do
                if spot:IsA("Model") and spot.Name:match("Spot") then
                    game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("Hive"):FireServer(spot.Parent.Name, spot.Name, 2)
                end
            end
            task.wait(1)
        end
    end
})
end
})

local items = {}
for _, item in ipairs(plr.PlayerGui.Main.Menus.Merchant.Inner.ScrollingFrame.Hold:GetChildren()) do
    if item:IsA("Frame") and item.Name ~= "Example" then
        table.insert(items, item.Name)
    end
end

local item = nil
BuyTab:CreateDropdown({
    Name = "Items",
    Options = items,
    CurrentOption = items[1],
    Flag = "Items",
    Callback = function(name)
    item = name
end
})

BuyTab:CreateButton({
    Name = "Buy Item",
    Callback = function()
    if item ~= nil then
        local a = {
            item,
            false
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("BuyFromMerchant"):FireServer(unpack(a))
    end
end
})

BuyTab:CreateToggle({
    Name = "Auto Buy Item",
    CurrentValue = false,
    Flag = "Auto Buy Item",
    Callback = function(b)
    settings.auto_buy = b
    task.spawn(function()
        while settings.auto_buy do
            if item then
                local a = {
                    item,
                    false
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("BuyFromMerchant"):FireServer(unpack(a))
            end
            task.wait(0.25)
        end
    end
})
end
})

BuyTab:CreateLabel("New Items In 00:00")

local timerUI = nil
for _, child in ipairs(TurtleLib:GetDescendants()) do
    if child:IsA("Frame") and child.Name == "Header" then
        if child:FindFirstChildOfClass("TextLabel") and child:FindFirstChildOfClass("TextLabel").Text == "Buy Items" then
            timerUI = child
            break
        end
    end
end

pcall(function()
    game:GetService("RunService").RenderStepped:Connect(function()
        if timerUI then
            local timer = plr.PlayerGui.Main.Menus.Merchant.Inner.Timer
            if timer then
                timerUI:FindFirstChild("Window"):FindFirstChild("Label").Text = timer.Text
            end
        end
    end
})
end
})

SettingsTab:CreateButton({
    Name = "Anti AFK",
    Callback = function()
    local bb = game:GetService("VirtualUser")
    plr.Idled:connect(function()
        bb:CaptureController()
        bb:ClickButton2(Vector2.new())
    end
})
end
})

SettingsTab:CreateInput({
    Name = "Burst Count",
    PlaceholderText = "Burst Count",
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
    local num = tonumber(t)
    if num and num > 0 then
        settings.instantFarmBursts = num
    end
end
})

SettingsTab:CreateInput({
    Name = "Burst Delay (sec)",
    PlaceholderText = "Burst Delay (sec)",
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
    local num = tonumber(t)
    if num and num >= 0 then
        settings.instantFarmDelay = num
    end
end
})

SettingsTab:CreateInput({
    Name = "Expand Delay",
    PlaceholderText = "Expand Delay",
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
    expand_delay = t
end
})

SettingsTab:CreateInput({
    Name = "Craft Delay",
    PlaceholderText = "Craft Delay",
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
    craft_delay = t
end
})

s:Label("Press LeftControl to Hide UI", Color3.fromRGB(127, 143, 166))

SettingsTab:CreateButton({
    Name = "Destroy Gui",
    Callback = function()
    for k in pairs(settings) do
        settings[k] = false
    end
    lib:Destroy()
end
})

s:Label("~ t.me/arceusxscripts", Color3.fromRGB(127, 143, 166))

res:Button("Update Resources", function()
    local newResources = scanResourceTypes()
    for _, resName in ipairs(newResources) do
        if not resourceSettings[resName] then
            resourceSettings[resName] = true
            res:Toggle(resName, true, function(state)
                resourceSettings[resName] = state
            end
})
        end
    end
end
})

lib:Keybind("LeftControl")