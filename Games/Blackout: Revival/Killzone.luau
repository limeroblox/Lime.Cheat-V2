local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "Lime.Cheat | KillAura",
    LoadingTitle = "Lime.Cheat",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Lime.Cheat",
        FileName = "KillAura"
    }
})

local CombatTab = Window:CreateTab("Combat", 123456)

-- Settings with defaults
local Settings = {
    KillAuraEnabled = false,
    KillAuraRange = 10,
    KillAuraTargetPart = "Head",
    AttackCooldown = 0.3,
}

-- UI Elements
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

CombatTab:CreateToggle({
    Name = "Enable KillAura",
    CurrentValue = Settings.KillAuraEnabled,
    Flag = "KillAuraEnabled",
    Callback = function(Value)
        Settings.KillAuraEnabled = Value
        print("[KillAura] Enabled:", Value)
    end,
})

CombatTab:CreateSlider({
    Name = "KillAura Range",
    Range = {1, 25},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = Settings.KillAuraRange,
    Flag = "KillAuraRange",
    Callback = function(Value)
        Settings.KillAuraRange = Value
        print("[KillAura] Range set to:", Value)
    end,
})

CombatTab:CreateSlider({
    Name = "Attack Cooldown",
    Range = {0.1, 1},
    Increment = 0.05,
    Suffix = " seconds",
    CurrentValue = Settings.AttackCooldown,
    Flag = "AttackCooldown",
    Callback = function(Value)
        Settings.AttackCooldown = Value
        print("[KillAura] Attack cooldown set to:", Value)
    end,
})

-- Fetch Remotes (waitForChild to ensure they're loaded)
local MeleeStorage = ReplicatedStorage:WaitForChild("MeleeStorage")
local Events = MeleeStorage:WaitForChild("Events")
local HitRemote = Events:WaitForChild("Hit")
local SwingFunction = Events:WaitForChild("Swing") -- RemoteFunction

-- Attack state
local attacking = false

local function attackTarget(character, targetLimbName)
    if attacking then return false end
    local limb = character:FindFirstChild(targetLimbName)
    if not limb then return false end

    attacking = true

    local success, err = pcall(function()
        SwingFunction:InvokeServer()
    end)
    if not success then
        warn("[KillAura] Swing invoke failed:", err)
        attacking = false
        return false
    end

    task.wait(0.05) -- slight delay for swing animation

    success, err = pcall(function()
        HitRemote:FireServer(limb, limb.Position)
    end)
    if not success then
        warn("[KillAura] Hit remote failed:", err)
        attacking = false
        return false
    end

    task.spawn(function()
        task.wait(Settings.AttackCooldown)
        attacking = false
    end)

    print("[KillAura] Attacked " .. character.Name .. " at " .. targetLimbName)
    return true
end

-- Helper to get character's HumanoidRootPart position safely
local function getCharacterHRPPosition(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        return hrp.Position
    else
        return nil
    end
end

-- Main loop
RunService.RenderStepped:Connect(function()
    if not Settings.KillAuraEnabled then return end
    local myChar = LocalPlayer.Character
    if not myChar then return end

    local myPos = getCharacterHRPPosition(myChar)
    if not myPos then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetChar = player.Character
            local humanoid = targetChar:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local targetPart = targetChar:FindFirstChild(Settings.KillAuraTargetPart)
                if targetPart then
                    local dist = (myPos - targetPart.Position).Magnitude
                    if dist <= Settings.KillAuraRange then
                        attackTarget(targetChar, Settings.KillAuraTargetPart)
                        break -- attack only one target per frame
                    end
                end
            end
        end
    end
end)
