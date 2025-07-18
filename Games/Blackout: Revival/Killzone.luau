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

--// Config
local config = {
    Enabled = false,
    HostileNPCEnabled = false,
    ArenaNPCEnabled = false,
    ActiveTasksNPCEnabled = false,
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

--// Fire Hit
local function fireHit(char)
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end

    local part = nil
    local head = char:FindFirstChild("Head")

    if head and math.random(0, 100) <= config.HeadChance then
        part = head
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

--// Main Loop
local lastHit = 0
RunService.RenderStepped:Connect(function()
    if tick() - lastHit < config.Delay then return end
    lastHit = tick()

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- Players
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

    -- Hostile NPCs
    if config.HostileNPCEnabled then
        local hostileFolder = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild("Hostile")
        if hostileFolder then
            for _, npc in ipairs(hostileFolder:GetChildren()) do
                local hum = npc:FindFirstChild("Humanoid")
                local root = npc:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 and (myRoot.Position - root.Position).Magnitude <= config.Range then
                    fireHit(npc)
                end
            end
        end
    end

    -- Arena NPCs
    if config.ArenaNPCEnabled then
        local arenaFolder = workspace:FindFirstChild("Arena")
        if arenaFolder then
            for _, npc in ipairs(arenaFolder:GetChildren()) do
                local hum = npc:FindFirstChild("Humanoid")
                local root = npc:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 and (myRoot.Position - root.Position).Magnitude <= config.Range then
                    fireHit(npc)
                end
            end
        end
    end

    -- ActiveTasks NPCs
    if config.ActiveTasksNPCEnabled then
        local activeFolder = workspace:FindFirstChild("ActiveTasks")
        local taskFolder = activeFolder and activeFolder:FindFirstChild("Location")
        if taskFolder then
            for _, npc in ipairs(taskFolder:GetChildren()) do
                local hum = npc:FindFirstChild("Humanoid")
                local root = npc:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 and (myRoot.Position - root.Position).Magnitude <= config.Range then
                    fireHit(npc)
                end
            end
        end
    end
end)
