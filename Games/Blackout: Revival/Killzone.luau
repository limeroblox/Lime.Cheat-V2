--// Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Remotes
local MeleeStorage = ReplicatedStorage:WaitForChild("MeleeStorage")
local Events = MeleeStorage:WaitForChild("Events")
local HitRemote = Events:WaitForChild("Hit")
local SwingRemote = Events:WaitForChild("Swing")

local GunEvents = ReplicatedStorage:WaitForChild("GunStorage"):WaitForChild("Events")
local GunShoot = GunEvents:WaitForChild("Shoot")
local GunHit = GunEvents:WaitForChild("Hit")


--// Invis Stuff
-- Variables
local platform
local tween
local seat
local cloneCharacter

-- Function to set transparency for character parts
local function setTransparency(char, value)
    if not char then return end
    
    local parts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
    
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and table.find(parts, v.Name) then
            v.Transparency = value
        elseif v:IsA("Decal") and v.Parent and table.find(parts, v.Parent.Name) then
            v.Transparency = value
        end
    end
end

-- Function to create a clone of the character
local function createClone()
    -- Remove existing clone first
    if cloneCharacter then
        cloneCharacter:Destroy()
        cloneCharacter = nil
    end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then 
        warn("Character or PrimaryPart not found")
        return 
    end
    
    cloneCharacter = char:Clone()
    cloneCharacter.Name = "Clone_" .. LocalPlayer.Name
    cloneCharacter.Parent = workspace
    cloneCharacter:SetPrimaryPartCFrame(char.PrimaryPart.CFrame)
    
    -- Configure clone parts
    for _, part in pairs(cloneCharacter:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
        elseif part:IsA("Script") or part:IsA("LocalScript") then
            part:Destroy()
        end
    end
end

-- Function to remove the clone
local function removeClone()
    if cloneCharacter then
        cloneCharacter:Destroy()
        cloneCharacter = nil
    end
end

-- Function to create the invisible platform
local function createPlatform()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    -- Clean up existing objects
    if platform then platform:Destroy() end
    if seat then seat:Destroy() end
    if tween then tween:Cancel() end
    
    removeClone()
    createClone()
    
    -- Create platform part
    platform = Instance.new("Part")
    platform.Size = Vector3.new(6, 1, 6)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 1
    platform.Position = hrp.Position - Vector3.new(0, 6, 0) -- 6 studs below
    platform.Name = "InvisPlatform"
    platform.Parent = workspace
    
    -- Add highlight to platform
    local highlight = Instance.new("Highlight")
    highlight.Adornee = platform
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.FillTransparency = 0.75
    highlight.OutlineTransparency = 1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = platform
    
    -- Create invisible seat on platform
    seat = Instance.new("Seat")
    seat.Name = "InvisSeat"
    seat.Anchored = true
    seat.CanCollide = false
    seat.Transparency = 1
    seat.Size = Vector3.new(2, 1, 2)
    seat.CFrame = platform.CFrame * CFrame.new(0, 1, 0) -- seat on top of platform
    seat.Parent = workspace
    
    -- Make character semi-transparent
    setTransparency(char, 0.5)
    
    -- Tween character to above platform
    if char.PrimaryPart then
        local goal = {CFrame = seat.CFrame * CFrame.new(0, 3, 0)} -- slightly above seat
        tween = TweenService:Create(
            char.PrimaryPart, 
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            goal
        )
        
        tween:Play()
        
        tween.Completed:Connect(function()
            -- Force sit on seat after tween
            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
            if humanoid and seat then
                humanoid.Sit = true
                
                -- Create weld constraint to keep player attached to seat
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = seat
                weld.Part1 = char:FindFirstChild("HumanoidRootPart")
                weld.Parent = seat
            end
        end)
    end
end

-- Function to remove the platform and reset character
local function removePlatform()
    local char = LocalPlayer.Character
    
    -- Reset character transparency and sitting state
    if char then
        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            humanoid.Sit = false
        end
        setTransparency(char, 0)
    end
    
    -- Cancel any active tweens
    if tween then
        tween:Cancel()
        tween = nil
    end
    
    -- Destroy seat and platform
    if seat then
        seat:Destroy()
        seat = nil
    end
    
    if platform then
        platform:Destroy()
        platform = nil
    end
    
    -- Remove clone
    removeClone()
end
--//

--// Config
local config = {
    Enabled = false,
    NPC_KillAura = false,
    NPC_GunAura = false,
    Range = 15,
    HeadChance = 20,
    Delay = 0.1
}

--// UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "Lime.Cheat 2.0 | Blackout: Revival Script (Killzone/Zombies)",
    LoadingTitle = "Loading...",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local Tab = Window:CreateTab("Combat", 4483362458)

local MiscTab = Window:CreateTab("Misc", 4483362458)

Tab:CreateToggle({ Name = "Enable KillAura (Players)", CurrentValue = false, Callback = function(v) config.Enabled = v end })
Tab:CreateToggle({ Name = "KillAura (All NPCs)", CurrentValue = false, Callback = function(v) config.NPC_KillAura = v end })
Tab:CreateToggle({ Name = "GunAura (All NPCs)", CurrentValue = false, Callback = function(v) config.NPC_GunAura = v end })

Tab:CreateSlider({ Name = "Aura Range", Range = {1, 30}, Increment = 1, Suffix = " studs", CurrentValue = 15, Callback = function(v) config.Range = v end })
Tab:CreateSlider({ Name = "Head Hit Chance (%)", Range = {0, 100}, Increment = 1, Suffix = "%", CurrentValue = 20, Callback = function(v) config.HeadChance = v end })
Tab:CreateSlider({ Name = "KillAura Delay (seconds)", Range = {0.1, 2}, Increment = 0.1, Suffix = "s", CurrentValue = 0.1, Callback = function(v) config.Delay = v end })

local followPlatformOn = True

MiscTab:CreateToggle({
    Name = "Invisible",
    CurrentValue = false,
    Callback = function(state)
        followPlatformOn = state
        if state then
            createPlatform()
        else
            removePlatform()
        end
    end
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
        GunHit:FireServer(part, math.random(1000, 9999))
    end)
end

--// Recursive scan NPC folder
local function scanFolder(folder, func)
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Folder") then
            scanFolder(obj, func)
        elseif obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local root = obj.HumanoidRootPart
            local myChar = LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") and obj.Humanoid.Health > 0 then
                local dist = (myChar.HumanoidRootPart.Position - root.Position).Magnitude
                if dist <= config.Range then
                    func(obj)
                end
            end
        end
    end
end

--// NPC targets
local function scanAllNPCs(callback)
    local folders = {}

    local npcs = workspace:FindFirstChild("NPCs")
    if npcs then
        table.insert(folders, npcs:FindFirstChild("Hostile"))
        table.insert(folders, npcs:FindFirstChild("Custom"))
    end

    local activeTasks = workspace:FindFirstChild("ActiveTasks")
    if activeTasks then
        table.insert(folders, activeTasks:FindFirstChild("Location"))
        table.insert(folders, activeTasks:FindFirstChild("Folder"))
    end

    table.insert(folders, workspace:FindFirstChild("Arena"))

    local waveSurvival = workspace:FindFirstChild("WaveSurvival")
    if waveSurvival then
        table.insert(folders, waveSurvival:FindFirstChild("NPCs"))
    end

    for _, folder in ipairs(folders) do
        if folder then
            scanFolder(folder, callback)
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

    -- Player KillAura
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

    -- NPC KillAura
    if config.NPC_KillAura then
        scanAllNPCs(fireHit)
    end

    -- NPC GunAura
    if config.NPC_GunAura then
        scanAllNPCs(fireGun)
    end
end)
