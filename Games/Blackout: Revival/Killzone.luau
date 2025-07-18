-- Improved Admin Script with Better Error Handling and Performance
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load Rayfield UI Library with error handling
local Rayfield
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success then
    warn("Failed to load Rayfield UI library:", err)
    return
end

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "Lime.Cheat | Blackout Revival: Killzone | Mobile Edition",
    LoadingTitle = "Lime.Cheat",
    LoadingSubtitle = "by Snowy",
    ConfigurationSaving = {
        Enabled = false,
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

local CombatTab = Window:CreateTab("Combat", 4483362458)

-- Local settings variables
local Settings = {
    KillAura = false,
    KillAuraRange = 15,
    TargetBodyPart = "Head",
    KillAuraTargetType = "Players",
    AttackInterval = 0.1, -- Configurable attack speed
    MaxTargets = 3 -- Limit simultaneous targets for performance
}

-- UI Components
CombatTab:CreateToggle({
    Name = "KillAura",
    CurrentValue = Settings.KillAura,
    Flag = "KillAura",
    Callback = function(Value)
        Settings.KillAura = Value
        print("[KillAura] Toggled:", Value and "ON" or "OFF")
    end,
})

CombatTab:CreateSlider({
    Name = "Aura Range",
    Range = {1, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = Settings.KillAuraRange,
    Flag = "KillAuraRange",
    Callback = function(Value)
        Settings.KillAuraRange = Value
        print("[KillAura] Range set to:", Value)
    end,
})

CombatTab:CreateSlider({
    Name = "Attack Speed",
    Range = {0.05, 1},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = Settings.AttackInterval,
    Flag = "AttackInterval",
    Callback = function(Value)
        Settings.AttackInterval = Value
        print("[KillAura] Attack interval set to:", Value)
    end,
})

CombatTab:CreateDropdown({
    Name = "Target Body Part",
    Options = {"Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    CurrentOption = Settings.TargetBodyPart,
    Flag = "KillAuraTargetPart",
    Callback = function(Option)
        Settings.TargetBodyPart = Option
        print("[KillAura] Target body part set to:", Option)
    end,
})

CombatTab:CreateDropdown({
    Name = "KillAura Target",
    Options = {"Players", "NPCs (Hostile)", "Both"},
    CurrentOption = Settings.KillAuraTargetType,
    Flag = "KillAuraTargetType",
    Callback = function(Option)
        Settings.KillAuraTargetType = Option
        print("[KillAura] Target type set to:", Option)
    end,
})

-- Wait for remotes with timeout
local function waitForRemotes()
    local timeout = 10 -- seconds
    local startTime = tick()
    
    while tick() - startTime < timeout do
        local meleeStorage = ReplicatedStorage:FindFirstChild("MeleeStorage")
        if meleeStorage then
            local eventsFolder = meleeStorage:FindFirstChild("Events")
            if eventsFolder then
                local hitRemote = eventsFolder:FindFirstChild("Hit")
                local swingRemote = eventsFolder:FindFirstChild("Swing")
                if hitRemote and swingRemote then
                    return hitRemote, swingRemote
                end
            end
        end
        wait(0.1)
    end
    
    warn("[KillAura] Failed to find required remotes within timeout period")
    return nil, nil
end

local HitRemote, SwingRemote = waitForRemotes()

if not HitRemote or not SwingRemote then
    warn("[KillAura] Script cannot function without required remotes")
    return
end

-- Utility Functions
local function isValidCharacter(character)
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    return humanoid and rootPart and humanoid.Health > 0
end

local function getTargetPart(character)
    -- Try primary target first
    local part = character:FindFirstChild(Settings.TargetBodyPart)
    if part and part:IsA("BasePart") then
        return part
    end
    
    -- Fallback hierarchy for different character types
    local fallbackParts = {
        "Head", 
        "UpperTorso", 
        "Torso", 
        "HumanoidRootPart"
    }
    
    for _, partName in ipairs(fallbackParts) do
        local fallback = character:FindFirstChild(partName)
        if fallback and fallback:IsA("BasePart") then
            return fallback
        end
    end
    
    return nil
end

local function isInRange(pos1, pos2, range)
    return (pos1 - pos2).Magnitude <= (range or Settings.KillAuraRange)
end

local function attackTarget(character)
    if not isValidCharacter(character) then 
        return false
    end
    
    local targetPart = getTargetPart(character)
    if not targetPart then 
        return false
    end
    
    local success, err = pcall(function()
        -- Fire swing first, then hit (proper order)
        SwingRemote:InvokeServer()
        HitRemote:FireServer(targetPart, targetPart.Position)
    end)
    
    if not success then
        warn("[KillAura] Attack failed:", err)
        return false
    end
    
    return true
end

-- Target Collection Functions
local function getPlayerTargets(myRootPart)
    local targets = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart and isInRange(myRootPart.Position, rootPart.Position) then
                table.insert(targets, player.Character)
                if #targets >= Settings.MaxTargets then break end
            end
        end
    end
    
    return targets
end

local function getNPCTargets(myRootPart)
    local targets = {}
    local hostileFolder = workspace:FindFirstChild("NPCs")
    
    if hostileFolder then
        hostileFolder = hostileFolder:FindFirstChild("Hostile")
        if hostileFolder then
            for _, npc in pairs(hostileFolder:GetChildren()) do
                if npc:IsA("Model") and isValidCharacter(npc) then
                    local rootPart = npc:FindFirstChild("HumanoidRootPart")
                    if rootPart and isInRange(myRootPart.Position, rootPart.Position) then
                        table.insert(targets, npc)
                        if #targets >= Settings.MaxTargets then break end
                    end
                end
            end
        end
    end
    
    return targets
end

-- Main KillAura Logic
local lastAttackTime = 0
local targetIndex = 1 -- For cycling through multiple targets

local function killAuraLoop()
    if not Settings.KillAura then return end
    
    -- Throttle attacks
    local currentTime = tick()
    if currentTime - lastAttackTime < Settings.AttackInterval then 
        return 
    end
    
    -- Validate local player
    local myCharacter = LocalPlayer.Character
    if not isValidCharacter(myCharacter) then return end
    
    local myRootPart = myCharacter.HumanoidRootPart
    local allTargets = {}
    
    -- Collect targets based on settings
    if Settings.KillAuraTargetType == "Players" or Settings.KillAuraTargetType == "Both" then
        local playerTargets = getPlayerTargets(myRootPart)
        for _, target in ipairs(playerTargets) do
            table.insert(allTargets, target)
        end
    end
    
    if Settings.KillAuraTargetType == "NPCs (Hostile)" or Settings.KillAuraTargetType == "Both" then
        local npcTargets = getNPCTargets(myRootPart)
        for _, target in ipairs(npcTargets) do
            table.insert(allTargets, target)
        end
    end
    
    -- Attack targets (cycle through them for fairness)
    if #allTargets > 0 then
        targetIndex = ((targetIndex - 1) % #allTargets) + 1
        local success = attackTarget(allTargets[targetIndex])
        
        if success then
            lastAttackTime = currentTime
        end
    end
end

-- Connect to RenderStepped for smooth operation
local connection = RunService.RenderStepped:Connect(killAuraLoop)

-- Cleanup function (optional, for when script needs to be disabled)
local function cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    print("[KillAura] Script cleaned up")
end

-- Optional: Add cleanup button to UI
CombatTab:CreateButton({
    Name = "Disable Script",
    Callback = function()
        cleanup()
        print("[KillAura] Script disabled by user")
    end,
})

print("[KillAura] Script loaded successfully!")
