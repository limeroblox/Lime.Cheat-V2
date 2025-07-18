-- Fixed Admin Script with Proper Target Part Selection
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

-- FIXED: Use a proper settings table that gets updated
local Settings = {
    KillAura = false,
    KillAuraRange = 15,
    TargetBodyPart = "Head", -- This will be properly updated now
    KillAuraTargetType = "Players",
    AttackInterval = 0.1,
    MaxTargets = 3
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

-- FIXED: Now properly updates Settings.TargetBodyPart
CombatTab:CreateDropdown({
    Name = "Target Body Part",
    Options = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    CurrentOption = Settings.TargetBodyPart,
    Flag = "KillAuraTargetPart",
    Callback = function(Option)
        Settings.TargetBodyPart = Option -- FIXED: Update the settings table
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

CombatTab:CreateSlider({
    Name = "Max Targets",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = Settings.MaxTargets,
    Callback = function(val)
        Settings.MaxTargets = val
    end,
})

-- Wait for remotes with timeout
local function waitForRemotes()
    local timeout = 10
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

-- Debug function to see what parts are available
local function debugCharacterParts(character)
    print("[DEBUG] Parts available in character '" .. tostring(character.Name) .. "':")
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            print("  - " .. part.Name .. " (BasePart)")
        end
    end
end

-- FIXED: Now uses Settings.TargetBodyPart instead of the old variable
local function getTargetPart(character)
    -- Debug: Show what we're looking for and what's available
    print("[KillAura] Looking for part: '" .. Settings.TargetBodyPart .. "'")
    
    -- Try the selected target part first
    local part = character:FindFirstChild(Settings.TargetBodyPart)
    if part and part:IsA("BasePart") then
        print("[KillAura] Found target part: " .. part.Name)
        return part
    end
    
    print("[KillAura] Target part '" .. Settings.TargetBodyPart .. "' not found, trying fallbacks...")
    
    -- FIXED: Removed HumanoidRootPart from fallbacks since it doesn't exist in this game
    local fallbackParts = {
        "Head", 
        "Torso",
        "UpperTorso", 
        "LowerTorso"
    }
    
    for _, partName in ipairs(fallbackParts) do
        local fallback = character:FindFirstChild(partName)
        if fallback and fallback:IsA("BasePart") then
            print("[KillAura] Using fallback part: " .. fallback.Name)
            return fallback
        end
    end
    
    -- If still nothing found, debug the character
    print("[KillAura] No valid parts found! Debugging character...")
    debugCharacterParts(character)
    
    return nil
end

-- Utility Functions
local function isValidCharacter(character)
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    -- FIXED: Don't check for HumanoidRootPart, check for any valid part instead
    local hasValidPart = false
    
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            hasValidPart = true
            break
        end
    end
    
    return humanoid and hasValidPart and humanoid.Health > 0
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
        print("[KillAura] No target part found for character: " .. tostring(character.Name))
        return false
    end
    
    local success, err = pcall(function()
        SwingRemote:InvokeServer()
        HitRemote:FireServer(targetPart, targetPart.Position)
    end)
    
    if not success then
        warn("[KillAura] Attack failed:", err)
        return false
    end
    
    print("[KillAura] Successfully attacked " .. character.Name .. " at part: " .. targetPart.Name)
    return true
end

-- FIXED: Better position checking that doesn't rely on HumanoidRootPart
local function getCharacterPosition(character)
    -- Try common position parts in order of preference
    local positionParts = {"Torso", "UpperTorso", "LowerTorso", "Head"}
    
    for _, partName in ipairs(positionParts) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            return part.Position
        end
    end
    
    -- If none found, try any BasePart
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            return part.Position
        end
    end
    
    return nil
end

-- Target Collection Functions
local function getPlayerTargets(myPosition)
    local targets = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPos = getCharacterPosition(player.Character)
            if targetPos and isInRange(myPosition, targetPos) then
                table.insert(targets, player.Character)
                if #targets >= Settings.MaxTargets then break end
            end
        end
    end
    
    return targets
end

local function getNPCTargets(myPosition)
    local targets = {}
    local hostileFolder = workspace:FindFirstChild("NPCs")
    
    if hostileFolder then
        hostileFolder = hostileFolder:FindFirstChild("Hostile")
        if hostileFolder then
            for _, npc in pairs(hostileFolder:GetChildren()) do
                if npc:IsA("Model") and isValidCharacter(npc) then
                    local targetPos = getCharacterPosition(npc)
                    if targetPos and isInRange(myPosition, targetPos) then
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
local targetIndex = 1

local function killAuraLoop()
    if not Settings.KillAura then return end
    
    local currentTime = tick()
    if currentTime - lastAttackTime < Settings.AttackInterval then 
        return 
    end
    
    local myCharacter = LocalPlayer.Character
    if not isValidCharacter(myCharacter) then return end
    
    -- FIXED: Get position without relying on HumanoidRootPart
    local myPosition = getCharacterPosition(myCharacter)
    if not myPosition then return end
    
    local allTargets = {}
    
    -- Collect targets based on settings
    if Settings.KillAuraTargetType == "Players" or Settings.KillAuraTargetType == "Both" then
        local playerTargets = getPlayerTargets(myPosition)
        for _, target in ipairs(playerTargets) do
            table.insert(allTargets, target)
        end
    end
    
    if Settings.KillAuraTargetType == "NPCs (Hostile)" or Settings.KillAuraTargetType == "Both" then
        local npcTargets = getNPCTargets(myPosition)
        for _, target in ipairs(npcTargets) do
            table.insert(allTargets, target)
        end
    end
    
    -- Attack targets
    if #allTargets > 0 then
        targetIndex = ((targetIndex - 1) % #allTargets) + 1
        local success = attackTarget(allTargets[targetIndex])
        
        if success then
            lastAttackTime = currentTime
        end
    end
end

-- Connect to RenderStepped
local connection = RunService.RenderStepped:Connect(killAuraLoop)

-- Cleanup function
local function cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    print("[KillAura] Script cleaned up")
end

-- Add cleanup button
CombatTab:CreateButton({
    Name = "Disable Script",
    Callback = function()
        cleanup()
        print("[KillAura] Script disabled by user")
    end,
})

-- Add debug button to see character parts
CombatTab:CreateButton({
    Name = "Debug My Character",
    Callback = function()
        if LocalPlayer.Character then
            debugCharacterParts(LocalPlayer.Character)
        else
            print("[DEBUG] No character found")
        end
    end,
})

print("[KillAura] Fixed script loaded successfully!")
print("[KillAura] Current target part: " .. Settings.TargetBodyPart)
