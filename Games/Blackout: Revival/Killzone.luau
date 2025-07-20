--// Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// Remotes
local MeleeStorage = ReplicatedStorage:WaitForChild("MeleeStorage")
local Events = MeleeStorage:WaitForChild("Events")
local HitRemote = Events:WaitForChild("Hit")
local SwingRemote = Events:WaitForChild("Swing")

local GunEvents = ReplicatedStorage:WaitForChild("GunStorage"):WaitForChild("Events")
local GunShoot = GunEvents:WaitForChild("Shoot")
local GunHit = GunEvents:WaitForChild("Hit")

--//
-- Configuration
local CONFIG = {
    PLATFORM_SIZE = Vector3.new(6, 1, 6),
    MOVEMENT_SPEED = 16, -- studs per second
    CAMERA_OFFSET = Vector3.new(0, 10, 10),
    PLAYER_OFFSET = Vector3.new(0, -6, 0),
    MIN_HEIGHT = 5,
    HIGHLIGHT_COLOR = Color3.fromRGB(0, 255, 0),
    HIGHLIGHT_TRANSPARENCY = 0.75
}

-- State management
local InvisibilitySystem = {
    isActive = false,
    platform = nil,
    weld = nil,
    connections = {},
    moveVector = Vector3.zero,
    
    -- Input state
    inputState = {
        w = false, s = false,
        a = false, d = false
    }
}

-- Utility Functions
local function safeDestroy(instance)
    if instance and instance.Parent then
        instance:Destroy()
    end
end

local function getCharacterParts(character)
    local parts = {}
    for _, descendant in pairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            table.insert(parts, descendant)
        end
    end
    return parts
end

local function setCollisionForCharacter(character, canCollide)
    local parts = getCharacterParts(character)
    for _, part in pairs(parts) do
        part.CanCollide = canCollide
    end
end

-- Movement System
local function updateInputVector()
    local vector = Vector3.zero
    
    if InvisibilitySystem.inputState.w then vector = vector + Vector3.new(0, 0, -1) end
    if InvisibilitySystem.inputState.s then vector = vector + Vector3.new(0, 0, 1) end
    if InvisibilitySystem.inputState.a then vector = vector + Vector3.new(-1, 0, 0) end
    if InvisibilitySystem.inputState.d then vector = vector + Vector3.new(1, 0, 0) end
    
    InvisibilitySystem.moveVector = vector.Unit
end

local function getMobileInput()
    if not UserInputService.TouchEnabled then 
        return Vector3.zero 
    end
    
    local touches = UserInputService:GetTouches()
    if #touches == 0 then 
        return Vector3.zero 
    end
    
    -- Use first touch for movement
    local touch = touches[1]
    local screenCenter = Camera.ViewportSize * 0.5
    local touchPos = touch.Position
    local direction = (touchPos - screenCenter)
    
    -- Normalize and convert to world space
    if direction.Magnitude > 50 then -- Dead zone
        direction = direction.Unit
        return Vector3.new(direction.X, 0, -direction.Y)
    end
    
    return Vector3.zero
end

-- Camera Management
local function updateCamera()
    if not InvisibilitySystem.platform then return end
    
    Camera.CameraType = Enum.CameraType.Scriptable
    local targetPosition = InvisibilitySystem.platform.Position + CONFIG.CAMERA_OFFSET
    Camera.CFrame = CFrame.lookAt(targetPosition, InvisibilitySystem.platform.Position)
end

-- Platform Management
local function createPlatform(position)
    local platform = Instance.new("Part")
    platform.Name = "InvisibilityPlatform"
    platform.Size = CONFIG.PLATFORM_SIZE
    platform.Anchored = true
    platform.CanCollide = false
    platform.Transparency = 1
    platform.Position = position
    platform.Parent = workspace
    
    -- Add highlight
    local highlight = Instance.new("Highlight")
    highlight.Adornee = platform
    highlight.FillColor = CONFIG.HIGHLIGHT_COLOR
    highlight.FillTransparency = CONFIG.HIGHLIGHT_TRANSPARENCY
    highlight.OutlineTransparency = 1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = platform
    
    return platform
end

local function createWeldConstraint(part0, part1)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part0
    weld.Part1 = part1
    weld.Parent = part0
    return weld
end

-- Main Functions
function InvisibilitySystem:activate()
    if self.isActive then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoidRootPart or not humanoid then return end
    
    -- Prepare character
    humanoid.Sit = true
    task.wait(0.1)
    
    setCollisionForCharacter(character, false)
    
    -- Create platform
    self.platform = createPlatform(humanoidRootPart.Position)
    
    -- Position character
    character:MoveTo(humanoidRootPart.Position + CONFIG.PLAYER_OFFSET)
    task.wait(0.1)
    
    -- Create weld
    self.weld = createWeldConstraint(humanoidRootPart, self.platform)
    
    -- Setup camera
    Camera.CameraSubject = nil
    updateCamera()
    
    -- Start update loop
    self.connections.update = RunService.Heartbeat:Connect(function(deltaTime)
        self:update(deltaTime)
    end)
    
    self.isActive = true
end

function InvisibilitySystem:deactivate()
    if not self.isActive then return end
    
    -- Disconnect all connections
    for _, connection in pairs(self.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.connections = {}
    
    local character = LocalPlayer.Character
    if character then
        setCollisionForCharacter(character, true)
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            character:MoveTo(humanoidRootPart.Position + Vector3.new(0, 5, 0))
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Sit = false
            humanoid.Jump = true
        end
    end
    
    -- Cleanup objects
    safeDestroy(self.weld)
    safeDestroy(self.platform)
    self.weld = nil
    self.platform = nil
    
    -- Reset camera
    Camera.CameraSubject = character and character:FindFirstChild("Humanoid")
    Camera.CameraType = Enum.CameraType.Custom
    
    self.isActive = false
end

function InvisibilitySystem:update(deltaTime)
    if not self.platform then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Get movement input
    local moveVector = self.moveVector
    if UserInputService.TouchEnabled then
        local mobileInput = getMobileInput()
        if mobileInput.Magnitude > 0 then
            moveVector = mobileInput
        end
    end
    
    -- Apply movement
    if moveVector.Magnitude > 0 then
        local movement = moveVector * CONFIG.MOVEMENT_SPEED * deltaTime
        self.platform.Position = self.platform.Position + movement
    end
    
    -- Maintain minimum height
    local currentPos = self.platform.Position
    if currentPos.Y < CONFIG.MIN_HEIGHT then
        self.platform.Position = Vector3.new(currentPos.X, CONFIG.MIN_HEIGHT, currentPos.Z)
    end
    
    updateCamera()
end

-- Input Handling
local function setupInputHandling()
    InvisibilitySystem.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not InvisibilitySystem.isActive then return end
        
        local keyCode = input.KeyCode
        if keyCode == Enum.KeyCode.W then
            InvisibilitySystem.inputState.w = true
        elseif keyCode == Enum.KeyCode.S then
            InvisibilitySystem.inputState.s = true
        elseif keyCode == Enum.KeyCode.A then
            InvisibilitySystem.inputState.a = true
        elseif keyCode == Enum.KeyCode.D then
            InvisibilitySystem.inputState.d = true
        end
        
        updateInputVector()
    end)
    
    InvisibilitySystem.connections.inputEnded = UserInputService.InputEnded:Connect(function(input)
        if not InvisibilitySystem.isActive then return end
        
        local keyCode = input.KeyCode
        if keyCode == Enum.KeyCode.W then
            InvisibilitySystem.inputState.w = false
        elseif keyCode == Enum.KeyCode.S then
            InvisibilitySystem.inputState.s = false
        elseif keyCode == Enum.KeyCode.A then
            InvisibilitySystem.inputState.a = false
        elseif keyCode == Enum.KeyCode.D then
            InvisibilitySystem.inputState.d = false
        end
        
        updateInputVector()
    end)
end

-- Initialize
setupInputHandling()
-- Export the system
return InvisibilitySystem
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
local Misc = Window:CreateTab("Misc", 4483362458)
Tab:CreateToggle({ Name = "Enable KillAura (Players)", CurrentValue = false, Callback = function(v) config.Enabled = v end })
Tab:CreateToggle({ Name = "KillAura (All NPCs)", CurrentValue = false, Callback = function(v) config.NPC_KillAura = v end })
Tab:CreateToggle({ Name = "GunAura (All NPCs)", CurrentValue = false, Callback = function(v) config.NPC_GunAura = v end })

Tab:CreateSlider({ Name = "Aura Range", Range = {1, 30}, Increment = 1, Suffix = " studs", CurrentValue = 15, Callback = function(v) config.Range = v end })
Tab:CreateSlider({ Name = "Head Hit Chance (%)", Range = {0, 100}, Increment = 1, Suffix = "%", CurrentValue = 20, Callback = function(v) config.HeadChance = v end })
Tab:CreateSlider({ Name = "KillAura Delay (seconds)", Range = {0.1, 2}, Increment = 0.1, Suffix = "s", CurrentValue = 0.1, Callback = function(v) config.Delay = v end })

local InvisibilitySystem = require(script.InvisibilitySystem)

Misc:CreateToggle({
    Name = "Invisible",
    CurrentValue = false,
    Callback = function(state)
        if state then
            InvisibilitySystem:activate()
        else
            InvisibilitySystem:deactivate()
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
