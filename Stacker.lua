local stackTimes = 1
local stackHeight = 6
local remoteFunction = game:GetService("ReplicatedStorage").RemoteFunction
local playerMouse = game.Players.LocalPlayer:GetMouse()
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

local function fetchEquippedTroops()
    local equippedTroops = {}
    for troopName, troopData in next, remoteFunction:InvokeServer("Session", "Search", "Inventory.Troops") do
        if troopData.Equipped then
            table.insert(equippedTroops, troopName)
        end
    end
    return equippedTroops
end

local equippedTroopsList = fetchEquippedTroops()
local selectedTroopType = equippedTroopsList[1]

local function getTowerOwnerId(tower)
    local towerReplicator = tower:FindFirstChild("TowerReplicator")
    if towerReplicator then
        local ownerId = towerReplicator:GetAttribute("OwnerId")
        if ownerId then return ownerId end
    end
    local ownerValue = tower:FindFirstChild("Owner")
    if ownerValue then return ownerValue.Value end
    return nil
end

local function getTowerTypeName(tower)
    local towerReplicator = tower:FindFirstChild("TowerReplicator")
    if towerReplicator then
        return towerReplicator:GetAttribute("Name")
    end
    return nil
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local mainWindow = Rayfield:CreateWindow({
    Name = "TDS Auto Stack V3",
    Icon = 0,
    LoadingTitle = "TDS Auto Stack",
    LoadingSubtitle = "by Serial Designation N",
    Theme = "Default",
    ToggleUIKeybind = Enum.KeyCode.LeftControl,
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TDSAutoStack",
        FileName = "Config"
    },
    KeySystem = false
})

local mainTab = mainWindow:CreateTab("Main", 4483362458)

local stackModeEnabled = false
local stackPreviewSphere = nil

mainTab:CreateToggle({
    Name = "Stack Mode",
    CurrentValue = false,
    Flag = "StackModeToggle",
    Callback = function(toggled)
        stackModeEnabled = toggled
        if not toggled and stackPreviewSphere then
            stackPreviewSphere:Destroy()
            stackPreviewSphere = nil
        end
    end
})

mainTab:CreateSlider({
    Name = "Stack Amount",
    Range = {1, 15},
    Increment = 1,
    Suffix = " towers",
    CurrentValue = 1,
    Flag = "StackAmountSlider",
    Callback = function(sliderValue)
        stackTimes = sliderValue
    end
})

mainTab:CreateSlider({
    Name = "Stack Height",
    Range = {-8, 120},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 6,
    Flag = "StackHeightSlider",
    Callback = function(sliderValue)
        stackHeight = sliderValue
    end
})

local troopSelectionDropdown = mainTab:CreateDropdown({
    Name = "Select Tower",
    Options = equippedTroopsList,
    CurrentOption = {selectedTroopType or "None"},
    MultipleOptions = false,
    Flag = "TroopDropdown",
    Callback = function(selectedOptions)
        selectedTroopType = selectedOptions[1]
    end
})

mainTab:CreateButton({
    Name = "Refresh Towers",
    Callback = function()
        equippedTroopsList = fetchEquippedTroops()
        troopSelectionDropdown:Refresh(equippedTroopsList)
    end
})

mainTab:CreateButton({
    Name = "Upgrade All Towers",
    Callback = function()
        for _, tower in pairs(game.Workspace.Towers:GetChildren()) do
            if getTowerOwnerId(tower) == game.Players.LocalPlayer.UserId then
                remoteFunction:InvokeServer("Troops", "Upgrade", "Set", {["Troop"] = tower})
                wait()
            end
        end
    end
})

mainTab:CreateButton({
    Name = "Upgrade Selected Tower Type",
    Callback = function()
        for _, tower in pairs(game.Workspace.Towers:GetChildren()) do
            if getTowerOwnerId(tower) == game.Players.LocalPlayer.UserId and getTowerTypeName(tower) == selectedTroopType then
                remoteFunction:InvokeServer("Troops", "Upgrade", "Set", {["Troop"] = tower})
                wait()
            end
        end
    end
})

mainTab:CreateButton({
    Name = "⚠️ Sell All Towers (DANGER)",
    Callback = function()
        for _, tower in pairs(game.Workspace.Towers:GetChildren()) do
            if getTowerOwnerId(tower) == game.Players.LocalPlayer.UserId then
                remoteFunction:InvokeServer("Troops", "Sell", {["Troop"] = tower})
                wait()
            end
        end
    end
})

mainTab:CreateButton({
    Name = "Sell All Farms",
    Callback = function()
        for _, tower in pairs(game.Workspace.Towers:GetChildren()) do
            if getTowerOwnerId(tower) == game.Players.LocalPlayer.UserId and getTowerTypeName(tower) == "Farm" then
                remoteFunction:InvokeServer("Troops", "Sell", {["Troop"] = tower})
                wait()
            end
        end
    end
})

local infoTab = mainWindow:CreateTab("Info", 4483362458)

infoTab:CreateLabel("Serial Designation N", nil, Color3.fromRGB(255, 255, 255), false)

runService.RenderStepped:Connect(function()
    if stackModeEnabled then
        if not stackPreviewSphere then
            stackPreviewSphere = Instance.new("Part")
            stackPreviewSphere.Shape = Enum.PartType.Ball
            stackPreviewSphere.Size = Vector3.new(1, 1, 1)
            stackPreviewSphere.Color = Color3.fromRGB(0, 255, 0)
            stackPreviewSphere.Transparency = 0.5
            stackPreviewSphere.Anchored = true
            stackPreviewSphere.CanCollide = false
            stackPreviewSphere.Material = Enum.Material.Neon
            stackPreviewSphere.Parent = game.Workspace
            playerMouse.TargetFilter = stackPreviewSphere
        end
        
        local mouseHitPosition = playerMouse.Hit
        if mouseHitPosition then
            stackPreviewSphere.Position = mouseHitPosition.Position
        end
    elseif stackPreviewSphere then
        stackPreviewSphere:Destroy()
        stackPreviewSphere = nil
    end
end)

playerMouse.Button1Down:Connect(function()
    if stackModeEnabled and stackPreviewSphere then
        local basePosition = stackPreviewSphere.Position
        
        spawn(function()
            for i = 1, stackTimes do
                local stackedPosition = Vector3.new(basePosition.X, basePosition.Y + (stackHeight * i), basePosition.Z)
                remoteFunction:InvokeServer("Troops", "Pl\208\176ce", {Rotation = CFrame.new(), Position = stackedPosition}, selectedTroopType)
                wait(0.2)
            end
        end)
    end
end)
