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
    NPCEnabled = false,
    Range = 15,
    HeadChance = 20
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
    Name = "Enable KillAura (NPCs)",
    CurrentValue = false,
    Callback = function(v) config.NPCEnabled = v end,
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

--// Recursively find all valid NPCs from multiple folders
local function getAllNPCs()
    local sources = {
        workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild("Hostile"),
        workspace:FindFirstChild("ActiveTasks") and workspace.ActiveTasks:FindFirstChild("Location"),
        workspace:FindFirstChild("Arena")
    }

    local results = {}

    local function scan(folder)
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                table.insert(results, obj)
            elseif obj:IsA("Folder") or obj:IsA("Model") then
                scan(obj)
            end
        end
    end

    for _, src in ipairs(sources) do
        if src then scan(src) end
    end

    return results
end

--// Main Loop
local lastHit = 0
RunService.RenderStepped:Connect(function()
    if tick() - lastHit < 0.1 then return end
    lastHit = tick()

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- Player targets
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

    -- NPC targets (recursive)
    if config.NPCEnabled then
        for _, npc in ipairs(getAllNPCs()) do
            local root = npc:FindFirstChild("HumanoidRootPart")
            local hum = npc:FindFirstChild("Humanoid")
            if hum and root and hum.Health > 0 and (myRoot.Position - root.Position).Magnitude <= config.Range then
                fireHit(npc)
            end
        end
    end
end)
