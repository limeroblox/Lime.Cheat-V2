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

-- Main KillAura logic
RunService.RenderStepped:Connect(function()
    if not Settings.KillAuraEnabled then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local myRoot = LocalPlayer.Character.HumanoidRootPart

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            if humanoid.Health > 0 then
                local part = player.Character:FindFirstChild(Settings.KillAuraTargetPart)
                if part then
                    local dist = (myRoot.Position - part.Position).Magnitude
                    if dist <= Settings.KillAuraRange then
                        -- Attack using the chosen body part
                        MeleeRemote:FireServer(humanoid, false)
                    end
                end
            end
        end
    end
end)
