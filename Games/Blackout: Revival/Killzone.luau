local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- UI and Settings
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

local Settings = {
    KillAuraEnabled = false,
    KillAuraRange = 10,
    KillAuraTargetPart = "Head",
}

-- Dropdown for target part
CombatTab:CreateDropdown({
    Name = "Target Body Part",
    Options = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    CurrentOption = "Head",
    Flag = "KillAuraTargetPart",
    Callback = function(Option)
        Settings.KillAuraTargetPart = Option
        print("[KillAura] Target body part set to:", Option)
    end,
})

-- Toggle KillAura
CombatTab:CreateToggle({
    Name = "Enable KillAura",
    CurrentValue = false,
    Flag = "KillAuraEnabled",
    Callback = function(Value)
        Settings.KillAuraEnabled = Value
        print("[KillAura] Enabled:", Value)
    end,
})

-- Range Slider
CombatTab:CreateSlider({
    Name = "KillAura Range",
    Range = {1, 25},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = Settings.KillAuraRange,
    Flag = "KillAuraRange",
    Callback = function(Value)
        Settings.KillAuraRange = Value
    end,
})

-- Remote (assuming same name as before)
local MeleeRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MeleeDamage")

-- KillAura main loop
RunService.RenderStepped:Connect(function()
    if not Settings.KillAuraEnabled then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart

    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= LocalPlayer then
            local targetChar = targetPlayer.Character
            if targetChar and targetChar:FindFirstChild("Humanoid") and targetChar:FindFirstChild(Settings.KillAuraTargetPart) then
                local humanoid = targetChar.Humanoid
                if humanoid.Health > 0 then
                    local targetPart = targetChar[Settings.KillAuraTargetPart]
                    local distance = (root.Position - targetPart.Position).Magnitude
                    if distance <= Settings.KillAuraRange then
                        MeleeRemote:FireServer(humanoid, false)
                    end
                end
            end
        end
    end
end)
