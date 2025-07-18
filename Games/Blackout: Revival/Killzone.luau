local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeleeStorage = ReplicatedStorage:WaitForChild("MeleeStorage")
local EventsFolder = MeleeStorage:WaitForChild("Events")
local HitRemote = EventsFolder:WaitForChild("Hit")
local SwingRemote = EventsFolder:WaitForChild("Swing")

local config = {
    Enabled = false,
    Range = 15,
    HeadChance = 20, -- default 20%
}

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "KillAura (Improved Head Chance)",
    LoadingTitle = "Loading...",
    ConfigurationSaving = {
        Enabled = false,
    },
    KeySystem = false
})

local Tab = Window:CreateTab("Combat", 4483362458)

Tab:CreateToggle({
    Name = "Enable KillAura",
    CurrentValue = false,
    Callback = function(val)
        config.Enabled = val
    end,
})

Tab:CreateSlider({
    Name = "Aura Range",
    Range = {1, 30},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 15,
    Callback = function(val)
        config.Range = val
    end,
})

Tab:CreateSlider({
    Name = "Head Hit Chance (%)",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 20,
    Callback = function(val)
        config.HeadChance = val
    end,
})

local function fireHit(char)
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end

    local part = nil
    local hitHead = false

    for _ = 1, 3 do
        if math.random(0, 100) <= config.HeadChance then
            hitHead = true
            break
        end
    end

    if hitHead then
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            part = head
        end
    end

    if not part then
        local limbs = {"Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
        for _ = 1, #limbs do
            local limbName = limbs[math.random(1, #limbs)]
            local limb = char:FindFirstChild(limbName)
            if limb and limb:IsA("BasePart") then
                part = limb
                break
            end
        end
    end

    if part then
        pcall(function()
            SwingRemote:InvokeServer()
            HitRemote:FireServer(part, part.Position)
        end)
    end
end

local lastHit = 0

RunService.RenderStepped:Connect(function()
    if not config.Enabled then return end
    if tick() - lastHit < 0.1 then return end
    lastHit = tick()

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local enemyRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            if enemyRoot and (myRoot.Position - enemyRoot.Position).Magnitude <= config.Range then
                fireHit(plr.Character)
            end
        end
    end
end)
