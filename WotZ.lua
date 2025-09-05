local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/refs/heads/main/source.lua"))()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Player = Players.LocalPlayer

local dropItems = {}
local nameToModelMap = {} -- Maps dropdown item names to original models
local currentSelected = nil -- Current selected item from dropdown
local chamsEnabled = false
local chamsColor = Color3.fromRGB(255, 0, 0)
local chamsBoxes = {}
local fullbrightEnabled = false
local originalLighting = {}

local function findDrops()
    local newDropItems = {}
    local newNameToModelMap = {}
    local nameCounts = {} -- Track duplicates
    local function scanFolder(folder)
        for _, obj in pairs(folder:GetDescendants()) do
            if obj:IsA("Folder") and obj.Name == "Items" then
                for _, item in pairs(obj:GetChildren()) do
                    if item:IsA("Model") then
                        local baseName = item.Name
                        local displayName = baseName
                        -- Handle duplicates
                        if nameCounts[baseName] then
                            nameCounts[baseName] = nameCounts[baseName] + 1
                            displayName = baseName .. "_" .. nameCounts[baseName]
                        else
                            nameCounts[baseName] = 1
                        end
                        table.insert(newDropItems, displayName)
                        newNameToModelMap[displayName] = item
                    end
                end
            end
        end
    end
    scanFolder(Workspace:WaitForChild("StaticSpawns", 9e9))
    table.sort(newDropItems) -- Sort items alphabetically
    return newDropItems, newNameToModelMap
end

local function createChams(obj, color)
    if chamsBoxes[obj] then return end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = obj
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    highlight.FillColor = color
    highlight.FillTransparency = 0.2
    highlight.OutlineColor = color
    highlight.OutlineTransparency = 0
    highlight.Parent = game.CoreGui
    chamsBoxes[obj] = highlight
end

local function clearChams()
    for obj, highlight in pairs(chamsBoxes) do
        if highlight then highlight:Destroy() end
    end
    chamsBoxes = {}
end

local function updateChams()
    if not chamsEnabled then
        clearChams()
        return
    end

    for _, obj in pairs(Workspace.StaticSpawns:GetDescendants()) do
        if obj:IsA("Model") and obj.Parent.Name == "Items" then
            createChams(obj, chamsColor)
            if chamsBoxes[obj] then
                chamsBoxes[obj].Enabled = true
                chamsBoxes[obj].Adornee = obj -- Ensure Adornee is still valid
            end
        elseif chamsBoxes[obj] then
            chamsBoxes[obj]:Destroy()
            chamsBoxes[obj] = nil
        end
    end
end

local function saveLighting()
    originalLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        GlobalShadows = Lighting.GlobalShadows,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Ambient = Lighting.Ambient
    }
end

local function applyFullbright()
    Lighting.Brightness = 3
    Lighting.ClockTime = 12
    Lighting.FogEnd = 1000000
    Lighting.FogStart = 0
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
end

local function restoreLighting()
    if originalLighting.Brightness then
        Lighting.Brightness = originalLighting.Brightness
    end
    if originalLighting.ClockTime then
        Lighting.ClockTime = originalLighting.ClockTime
    end
    if originalLighting.FogEnd then
        Lighting.FogEnd = originalLighting.FogEnd
    end
    if originalLighting.FogStart then
        Lighting.FogStart = originalLighting.FogStart
    end
    if originalLighting.GlobalShadows ~= nil then
        Lighting.GlobalShadows = originalLighting.GlobalShadows
    end
    if originalLighting.OutdoorAmbient then
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end
    if originalLighting.Ambient then
        Lighting.Ambient = originalLighting.Ambient
    end
end

-- Create UI
local Window = Library.CreateLib("Whispers of the Zone ESP by @ecl1pse_t", "DarkTheme")
local TeleportTab = Window:NewTab("Teleport")
local VisualsTab = Window:NewTab("Visuals")
local FullbrightTab = Window:NewTab("Fullbright")
local TeleportSection = TeleportTab:NewSection("Teleport Controls")
local VisualsSection = VisualsTab:NewSection("Visual Settings")
local FullbrightSection = FullbrightTab:NewSection("Fullbright Settings")

-- Initialize dropdown
local dropdown = TeleportSection:NewDropdown("Выберите предмет", "Выберите предмет для телепортации", dropItems, function(currentOption)
    currentSelected = currentOption
end)

-- Update items button
TeleportSection:NewButton("Update items", "Обновить список предметов", function()
    local newDropItems, newNameToModelMap = findDrops()
    dropItems = newDropItems
    nameToModelMap = newNameToModelMap
    dropdown:Refresh(dropItems, true)
end)

-- Teleport button
TeleportSection:NewButton("Teleport", "Телепортироваться к выбранному предмету", function()
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    if not currentSelected or not nameToModelMap[currentSelected] then
        return
    end
    local targetModel = nameToModelMap[currentSelected]
    if targetModel and targetModel.Parent and targetModel.Parent.Name == "Items" then
        local targetCFrame = targetModel:GetPivot() * CFrame.new(0, 2, 0) -- Смещение на 2 studs вверх
        Player.Character.HumanoidRootPart.CFrame = targetCFrame
    end
end)

-- Chams toggle
VisualsSection:NewToggle("Chams", "Включить/выключить подсветку дропов", function(value)
    chamsEnabled = value
    updateChams()
end)

-- Chams color picker
VisualsSection:NewColorPicker("Цвет Chams", "Выбрать цвет подсветки", Color3.fromRGB(255, 0, 0), function(value)
    chamsColor = value
    if chamsEnabled then updateChams() end
end)

-- Fullbright toggle
FullbrightSection:NewToggle("Fullbright", "Включить/выключить яркое освещение", function(value)
    fullbrightEnabled = value
    if value then
        saveLighting()
        applyFullbright()
    else
        restoreLighting()
    end
end)

-- Periodic chams update every 1 second
task.spawn(function()
    while true do
        if chamsEnabled then
            updateChams()
        end
        task.wait(1)
    end
end)

-- Automatic dropdown update every 1 second
task.spawn(function()
    local lastDropItems = {}
    while true do
        local newDropItems, newNameToModelMap = findDrops()
        -- Check if items have changed
        local itemsChanged = false
        if #newDropItems ~= #lastDropItems then
            itemsChanged = true
        else
            for i, item in ipairs(newDropItems) do
                if item ~= lastDropItems[i] then
                    itemsChanged = true
                    break
                end
            end
        end

        if itemsChanged then
            dropItems = newDropItems
            nameToModelMap = newNameToModelMap
            lastDropItems = newDropItems
            dropdown:Refresh(dropItems, true)
        end
        task.wait(1)
    end
end)

RunService.RenderStepped:Connect(function()
    if fullbrightEnabled then
        applyFullbright()
    end
end)

Workspace.StaticSpawns.DescendantAdded:Connect(function()
    if chamsEnabled then
        updateChams()
    end
end)

Workspace.StaticSpawns.DescendantRemoving:Connect(function(obj)
    if chamsBoxes[obj] then
        chamsBoxes[obj]:Destroy()
        chamsBoxes[obj] = nil
    end
end)

Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
    if fullbrightEnabled then
        applyFullbright()
    end
end)