local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Lime.Cheat | Blackout Revival: Killzone | Mobile Edition",
	LoadingTitle = "Lime.Cheat",
	LoadingSubtitle = "by snowy :p",
	ConfigurationSaving = {
		Enabled = false,
	},
	Discord = {
		Enabled = false,
	},
	KeySystem = false,
})

local CombatTab = Window:CreateTab("Combat", 4483362458)

-- Settings
local Settings = {
	KillAura = false,
	KillAuraRange = 15,
	KillAuraTargetPart = "Head",
	KillAuraTargetType = "Players",
	AttackInterval = 0.1,
	MaxTargets = 3
}

-- KillAura logic
local function getTargetPart(character)
	local part = character:FindFirstChild(Settings.KillAuraTargetPart)
	if part and part:IsA("BasePart") then
		return part
	end
	return character:FindFirstChild("Head") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
end

local function getTargets()
	local targets = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local targetPart = getTargetPart(player.Character)
				if targetPart then
					local distance = (LocalPlayer.Character.HumanoidRootPart.Position - targetPart.Position).Magnitude
					if distance <= Settings.KillAuraRange then
						table.insert(targets, {Player = player, Distance = distance})
					end
				end
			end
		end
	end
	table.sort(targets, function(a, b) return a.Distance < b.Distance end)
	return targets
end

-- Attack function
local function attackTarget(player)
	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if humanoid then
		local remote = ReplicatedStorage:FindFirstChild("MeleeDamage")
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer(humanoid, false)
		end
	end
end

-- KillAura loop
task.spawn(function()
	local lastAttack = 0
	RunService.Heartbeat:Connect(function(dt)
		if Settings.KillAura and tick() - lastAttack >= Settings.AttackInterval then
			local targets = getTargets()
			for i = 1, math.min(Settings.MaxTargets, #targets) do
				attackTarget(targets[i].Player)
			end
			lastAttack = tick()
		end
	end)
end)

-- UI Toggles
CombatTab:CreateToggle({
	Name = "KillAura",
	CurrentValue = Settings.KillAura,
	Flag = "KillAuraEnabled",
	Callback = function(Value)
		Settings.KillAura = Value
	end,
})

CombatTab:CreateSlider({
	Name = "Range",
	Range = {1, 100},
	Increment = 1,
	Suffix = "studs",
	CurrentValue = Settings.KillAuraRange,
	Flag = "KillAuraRange",
	Callback = function(Value)
		Settings.KillAuraRange = Value
	end,
})

CombatTab:CreateDropdown({
	Name = "Target Body Part",
	Options = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
	CurrentOption = Settings.KillAuraTargetPart,
	Flag = "KillAuraTargetPart",
	Callback = function(Option)
		Settings.KillAuraTargetPart = Option
		print("[KillAura] Target body part set to:", Option)
	end,
})

CombatTab:CreateSlider({
	Name = "Attack Interval",
	Range = {0.05, 1},
	Increment = 0.05,
	Suffix = "seconds",
	CurrentValue = Settings.AttackInterval,
	Flag = "AttackInterval",
	Callback = function(Value)
		Settings.AttackInterval = Value
	end,
})

CombatTab:CreateSlider({
	Name = "Max Targets",
	Range = {1, 10},
	Increment = 1,
	CurrentValue = Settings.MaxTargets,
	Flag = "MaxTargets",
	Callback = function(Value)
		Settings.MaxTargets = Value
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
