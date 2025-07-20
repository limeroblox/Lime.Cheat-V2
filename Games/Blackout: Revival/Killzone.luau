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


--// Invis Stuff
local platform, weld, updateConnection
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer

local isHidden = false
local moveDirection = Vector3.new(0,0,0)
local offset = Vector3.new(0, -6, 0)

-- Update camera manually to stay above platform
local function updateCamera()
	if not platform then return end
	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.CFrame = CFrame.new(platform.Position + Vector3.new(0, 10, 10), platform.Position)
end

-- PC Movement (WASD)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not isHidden then return end
	if input.KeyCode == Enum.KeyCode.W then moveDirection = Vector3.new(0, 0, -1) end
	if input.KeyCode == Enum.KeyCode.S then moveDirection = Vector3.new(0, 0, 1) end
	if input.KeyCode == Enum.KeyCode.A then moveDirection = Vector3.new(-1, 0, 0) end
	if input.KeyCode == Enum.KeyCode.D then moveDirection = Vector3.new(1, 0, 0) end
end)

UserInputService.InputEnded:Connect(function(input)
	if not isHidden then return end
	-- Stop movement when keys released
	if input.KeyCode == Enum.KeyCode.W or
	   input.KeyCode == Enum.KeyCode.S or
	   input.KeyCode == Enum.KeyCode.A or
	   input.KeyCode == Enum.KeyCode.D then
		moveDirection = Vector3.new(0,0,0)
	end
end)

local function getMobileMoveVector()
    -- If using a virtual thumbstick, you would read its input here.
    -- For a basic example, just read touches on screen and calculate a direction relative to center.

    if not UserInputService.TouchEnabled then return Vector3.zero end

    local touches = UserInputService:GetTouches()
    if #touches == 0 then return Vector3.zero end

    local moveVector = Vector3.zero
    for _, touch in pairs(touches) do
        local pos = touch.Position
        -- Convert screen pos to direction - this is very basic
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local dir2d = (pos - center).Unit
        moveVector = Vector3.new(dir2d.X, 0, -dir2d.Y)
        break -- only use first touch for simplicity
    end
    return moveVector
end


local function noclip(char)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

local function enableCollision(char)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end
end

local function hidePlayer()
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hrp = char.HumanoidRootPart
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid.Sit = true
	task.wait(0.1)

	noclip(char)

	if platform then platform:Destroy() end
	platform = Instance.new("Part")
	platform.Size = Vector3.new(6, 1, 6)
	platform.Anchored = true
	platform.CanCollide = false
	platform.Transparency = 1
	platform.Name = "FakePlatform"
	platform.Position = hrp.Position
	platform.Parent = workspace

	local highlight = Instance.new("Highlight")
	highlight.Adornee = platform
	highlight.FillColor = Color3.fromRGB(0, 255, 0)
	highlight.FillTransparency = 0.75
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = platform

	char:MoveTo(hrp.Position + offset)
	task.wait(0.1)

	weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = platform
	weld.Parent = hrp

	isHidden = true
	Camera.CameraSubject = nil
	Camera.CameraType = Enum.CameraType.Scriptable
	updateCamera()

	updateConnection = RunService.RenderStepped:Connect(function(dt)
		if hrp and platform then
			local moveVec = moveDirection
			if UserInputService.TouchEnabled then
				moveVec = getMobileMoveVector()
			end
			if moveVec.Magnitude > 0 then
				platform.Position += moveVec.Unit * 0.5 -- movement speed
			end

			local pos = hrp.Position - offset
			platform.Position = Vector3.new(pos.X, math.max(pos.Y, 5), pos.Z)

			updateCamera()
		end
	end)
end

local function unhidePlayer()
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end

	local char = LocalPlayer.Character
	if char then
		enableCollision(char)

		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			char:MoveTo(hrp.Position + Vector3.new(0, 5, 0)) -- move back up
		end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Sit = false
			humanoid.Jump = true
		end
	end

	if weld then
		weld:Destroy()
		weld = nil
	end

	if platform then
		platform:Destroy()
		platform = nil
	end

	isHidden = false
	Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
	Camera.CameraType = Enum.CameraType.Custom
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

MiscTab:CreateToggle({
    Name = "Invisible",
    CurrentValue = false,
    Callback = function(state)
        if state then
            local success, err = pcall(hidePlayer)
            if not success then warn("hidePlayer error:", err) end
        else
            local success, err = pcall(unhidePlayer)
            if not success then warn("unhidePlayer error:", err) end
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
