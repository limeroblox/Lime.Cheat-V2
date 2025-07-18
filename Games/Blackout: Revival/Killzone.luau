--// Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Remotes
local MeleeStorage = ReplicatedStorage:WaitForChild("MeleeStorage")
local Events = MeleeStorage:WaitForChild("Events")
local HitRemote = Events:WaitForChild("Hit")
local SwingRemote = Events:WaitForChild("Swing")

local GunEvents = ReplicatedStorage:WaitForChild("GunStorage"):WaitForChild("Events")
local GunShoot = GunEvents:WaitForChild("Shoot")
local GunHit = GunEvents:WaitForChild("Hit")

--// Config
local config = {
    Enabled = false,
    HostileNPCEnabled = false,
    ArenaNPCEnabled = false,
    ActiveTasksNPCEnabled = false,
    WaveSurvivalNPCEnabled = false,
    GunAuraEnabled = false,
    Range = 15,
    HeadChance = 20,
    Delay = 0.1
}

--// UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "KillAura (R6)",
    LoadingTitle = "Loading...",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})
local Tab = Window:CreateTab("Combat", 4483362458)

Tab:CreateToggle({
    Name = "Enable KillAura (Players)",
    CurrentValue = false,
    Callback = function(v) config.Enabled = v end,
})
Tab:CreateToggle({
    Name = "Enable KillAura (Hostile NPCs)",
    CurrentValue = false,
    Callback = function(v) config.HostileNPCEnabled = v end,
})
Tab:CreateToggle({
    Name = "Enable KillAura (Arena NPCs)",
    CurrentValue = false,
    Callback = function(v) config.ArenaNPCEnabled = v end,
})
Tab:CreateToggle({
    Name = "Enable KillAura (ActiveTasks NPCs)",
    CurrentValue = false,
    Callback = function(v) config.ActiveTasksNPCEnabled = v end,
})
Tab:CreateToggle({
    Name = "Enable KillAura (WaveSurvival NPCs)",
    CurrentValue = false,
    Callback = function(v) config.WaveSurvivalNPCEnabled = v end,
})
Tab:CreateToggle({
    Name = "Enable GunAura (Auto Gun Fire)",
    CurrentValue = false,
    Callback = function(v) config.GunAuraEnabled = v end,
})
Tab:CreateSlider({
    Name = "Aura Range",
    Range = {1, 30},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 15,
    Callback = function(v) config.Range = v end,
})
Tab:CreateSlider({
    Name = "Head Hit Chance (%)",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 20,
    Callback = function(v) config.HeadChance = v end,
})
Tab:CreateSlider({
    Name = "KillAura Delay (seconds)",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.1,
    Callback = function(v) config.Delay = v end,
})

--// Valid R6 limbs
local r6Limbs = {"Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

--// Fire Melee Hit
local function fireHit(char)
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end

    local part
    if math.random(0, 100) <= config.HeadChance and char:FindFirstChild("Head") then
        part = char.Head
    else
        local limbs = {}
        for _, name in ipairs(r6Limbs) do
            local limb = char:FindFirstChild(name)
            if limb then table.insert(limbs, limb) end
        end
        if #limbs > 0 then
            part = limbs[math.random(1, #limbs)]
        end
    end

    if part then
        pcall(function()
            SwingRemote:InvokeServer()
            HitRemote:FireServer(part, part.Position)
        end)
    end
end

--// Fire Gun Shot
local function fireGun(char)
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end

    local part = char:FindFirstChild("Head") or char:FindFirstChild("Torso")
    if not part then return end

    pcall(function()
        GunShoot:FireServer()
        GunHit:FireServer(part, math.random(1000, 9999)) -- Random ID to mimic real call
    end)
end

--// Helper to scan and attack NPCs
local function scanFolder(folder, attackFunc)
    for _, npc in ipairs(folder:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            local root = npc.HumanoidRootPart
            if npc.Humanoid.Health > 0 and (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude <= config.Range then
                attackFunc(npc)
            end
        end
    end
end

--// Main Loop
local lastHit = 0
RunService.RenderStepped:Connect(function()
    if tick() - lastHit < config.Delay then return end
    lastHit = tick()

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- Player melee
    if config.Enabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root and (myRoot.Position - root.Position).Magnitude <= config.Range then
                    fireHit(plr.Character)
                end
            end
        end
    end

    -- NPC folders
    if config.HostileNPCEnabled then
        local hostile = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild("Hostile")
        if hostile then scanFolder(hostile, fireHit) end
    end
    if config.ArenaNPCEnabled then
        local arena = workspace:FindFirstChild("Arena")
        if arena then scanFolder(arena, fireHit) end
    end
    if config.ActiveTasksNPCEnabled then
        local tasks = workspace:FindFirstChild("ActiveTasks")
        local loc = tasks and tasks:FindFirstChild("Location")
        if loc then scanFolder(loc, fireHit) end
    end
    if config.WaveSurvivalNPCEnabled then
        local wave = workspace:FindFirstChild("WaveSurvival")
        local waveNPCs = wave and wave:FindFirstChild("NPCs")
        if waveNPCs then scanFolder(waveNPCs, fireHit) end
    end

    -- GunAura
    if config.GunAuraEnabled then
        local hostile = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild("Hostile")
        if hostile then scanFolder(hostile, fireGun) end
    end
end)
