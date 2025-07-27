
--// UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({ Name = "Lime.Cheat V.2 | Blackout: Revival | Killzone/Zombies", Icon = 141272932, LoadingTitle = "Loading Script...", LoadingSubtitle = "By @lime.bat", ShowText = "Lime.Cheat V.2", Theme = "Default", ToggleUIKeybind = "K", DisableRayfieldPrompts = false, DisableBuildWarnings = false, ConfigurationSaving = { Enabled = true, FolderName = nil, FileName = "Lime.Cheat V.2 | Blackout: Revival Script" }, Discord = { Enabled = false, Invite = "noinvitelink", RememberJoins = true }, KeySystem = true, KeySettings = { Title = "Lime.Cheat", Subtitle = "Key System", Note = "To get the key, ask @lime.bat for the key", FileName = "Lime.Cheat Key Folder", SaveKey = true, GrabKeyFromSite = false, Key = {"Blackout"} } })

local Tab 		= Window:CreateTab("KillAura", 4483362458)
local AimbotTab 	= Window:CreateTab("Aimbot", 4483362458)
local VisualsTab 	= Window:CreateTab("Visuals", 4483362458)

--// Aimbot
AimbotTab:CreateToggle({ Name = "Enable", CurrentValue = false, Callback = function(v) config.AimbotEnabled = v end })
AimbotTab:CreateToggle({ Name = "Include NPCs", CurrentValue = false, Callback = function(v) config.NPC_Aimbot = v end })
AimbotTab:CreateDropdown({ Name = "Target Part", Options = {"Head", "Torso"}, CurrentOption = "Head", Callback = function(v) config.AimPart = v end })
AimbotTab:CreateSlider({ Name = "Lockage", Range = {0.1, 1}, Increment = 0.05, Suffix = "s", CurrentValue = 0.1, Callback = function(v) config.Smoothness = v end })
AimbotTab:CreateToggle({ Name = "Wall Check", CurrentValue = true, Callback = function(v) config.WallCheck = v end })


--// Killaura
Tab:CreateToggle({ Name = "Enable KillAura (Players)", CurrentValue = false, Callback = function(v) config.Enabled = v end })
Tab:CreateToggle({ Name = "KillAura (All NPCs)", CurrentValue = false, Callback = function(v) config.NPC_KillAura = v end })
Tab:CreateToggle({ Name = "GunAura (All NPCs)", CurrentValue = false, Callback = function(v) config.NPC_GunAura = v end })
Tab:CreateSlider({ Name = "Aura Range", Range = {1, 30}, Increment = 1, Suffix = " studs", CurrentValue = 15, Callback = function(v) config.Range = v end })
Tab:CreateSlider({ Name = "Head Hit Chance (%)", Range = {0, 100}, Increment = 1, Suffix = "%", CurrentValue = 20, Callback = function(v) config.HeadChance = v end })
Tab:CreateSlider({ Name = "KillAura Delay (seconds)", Range = {0.1, 2}, Increment = 0.1, Suffix = "s", CurrentValue = 0.1, Callback = function(v) config.Delay = v end })


--// Visuals Tab Toggles (AFTER ESP functions)
VisualsTab:CreateToggle({ Name = "Enable ESP", CurrentValue = config.ESPEnabled, Callback = function(v) config.ESPEnabled = v UpdateESPVisibility() end })
VisualsTab:CreateToggle({ Name = "Show Boxes", CurrentValue = config.ESP_ShowBox, Callback = function(v) config.ESP_ShowBox = v UpdateESPVisibility() end })
VisualsTab:CreateToggle({ Name = "Show Tracers", CurrentValue = config.ESP_ShowTracer, Callback = function(v) config.ESP_ShowTracer = v UpdateESPVisibility() end })
VisualsTab:CreateToggle({ Name = "Show Health Bar", CurrentValue = config.ESP_ShowHealth, Callback = function(v) config.ESP_ShowHealth = v UpdateESPVisibility() end })
VisualsTab:CreateToggle({ Name = "Show Player Names", CurrentValue = config.ESP_ShowName, Callback = function(v) config.ESP_ShowName = v UpdateESPVisibility() end })

--// Services
local Players 		= game:GetService("Players")
local RunService 	= game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService 	= game:GetService("TweenService")
local UserInputService 	= game:GetService("UserInputService")

--// Vars
local LocalPlayer 	= Players.LocalPlayer
local Camera 		= workspace.CurrentCamera
local mouse 		= LocalPlayer:GetMouse()


--// Remotes
local MeleeStorage 	= ReplicatedStorage:WaitForChild("MeleeStorage")
local Events 		= MeleeStorage:WaitForChild("Events")
local HitRemote 	= Events:WaitForChild("Hit")
local SwingRemote 	= Events:WaitForChild("Swing")

local GunEvents 	= ReplicatedStorage:WaitForChild("GunStorage"):WaitForChild("Events")
local GunShoot 		= GunEvents:WaitForChild("Shoot")
local GunHit 		= GunEvents:WaitForChild("Hit")

--// R6 limbs
local r6Limbs 		= {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

--// Config
local config = {
    Enabled         = false,
    NPC_KillAura    = false,
    NPC_GunAura     = false,
    Range           = 15,
    HeadChance      = 20,
    Delay           = 0.1,

    AimbotEnabled = false,
    NPC_Aimbot = false,
    AimPart = "Head",
    Smoothness = 0.1,
    WallCheck = true,

    ESPEnabled = false,
    ESP_ShowBox = true,
    ESP_ShowTracer = true,
    ESP_ShowHealth = true,
    ESP_ShowName = true
}

local Settings = {
    Tracer_Thickness = 1,
    Tracer_Color = Color3.fromRGB(255,255,255),
    Box_Thickness = 1,
    Box_Color = Color3.fromRGB(255,255,255),
    Tracers = true,
    Tracer_FollowMouse = false,
    Tracer_Origin = "Bottom"
}

--// FUNCTIONS

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

--//Gunaura Function

local function fireGun(char)
	if not char or not char:IsA("Model") then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local part = char:FindFirstChild("Head") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
	if not part or not part:IsA("BasePart") then return end

	if GunShoot and GunHit then
		pcall(function()
			GunShoot:FireServer()
			GunHit:FireServer(part)
		end)
	end
end


--// Recursive scan NPC folder
local function scanFolder(folder, func)
	local didHit = false

	for _, obj in ipairs(folder:GetChildren()) do
		if obj:IsA("Folder") then
			if scanFolder(obj, func) then
				didHit = true
			end
		elseif obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
			local myChar = LocalPlayer.Character
			local root = obj.HumanoidRootPart
			if myChar and myChar:FindFirstChild("HumanoidRootPart") and obj.Humanoid.Health > 0 then
				local dist = (myChar.HumanoidRootPart.Position - root.Position).Magnitude
				if dist <= config.Range then
					func(obj)
					didHit = true
				end
			end
		end
	end

	return didHit
end

--// NPC targets
local function scanAllNPCs(callback)
	local folders = {}
	local didHit = false

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
		if folder and scanFolder(folder, callback) then
			didHit = true
		end
	end

	return didHit
end


--// Killaura/Gunaura Loop
local lastHit = 0
RunService.RenderStepped:Connect(function()
	local now = tick()
	if now - lastHit < config.Delay then return end

	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	local didHit = false

	-- Player KillAura
	if config.Enabled then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				if root and (myRoot.Position - root.Position).Magnitude <= config.Range then
					fireHit(plr.Character)
					didHit = true
				end
			end
		end
	end

	-- NPC KillAura
	if config.NPC_KillAura and scanAllNPCs(fireHit) then
		didHit = true
	end

	-- NPC GunAura
	if config.NPC_GunAura and scanAllNPCs(fireGun) then
		didHit = true
	end

	if didHit then
		lastHit = now
	end
end)


--// Aimbot Logic
local AimbotHolding = false

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonL2 then
		AimbotHolding = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonL2 then
		AimbotHolding = false
	end
end)

local lockedTarget = nil

local function isVisible(part, origin)
	if not part or not part:IsA("BasePart") or not origin then 
		return false 
	end

	local direction = part.Position - origin
	local distance = direction.Magnitude
	direction = direction.Unit * (distance)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist

	local ignoreList = {Camera}
	if LocalPlayer.Character then
		table.insert(ignoreList, LocalPlayer.Character)
	end
	local model = part:FindFirstAncestorOfClass("Model")
	if model then
		table.insert(ignoreList, model)
	end

	rayParams.FilterDescendantsInstances = ignoreList

	local result = workspace:Raycast(origin, direction, rayParams)
	if not result then return true end

	-- Accept if we hit part of the same model
	return part:IsDescendantOf(result.Instance.Parent)
end


-- Find closest valid target
local function getClosestAimbotTarget()
	local closest, shortest = nil, math.huge
	local mousePos = UserInputService:GetMouseLocation()
	local camPos = Camera.CFrame.Position

	local function evaluateTarget(part)
		if not part or not part:IsA("BasePart") then return end
		if config.WallCheck and not isVisible(part, camPos) then return end

		local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
		if not onScreen then return end

		local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
		if dist < shortest then
			closest = part
			shortest = dist
		end
	end

	-- Player targets
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local char = plr.Character
			if char then
				local human = char:FindFirstChild("Humanoid")
				local part = char:FindFirstChild(config.AimPart or "Head")
				if human and human.Health > 0 then
					evaluateTarget(part)
				end
			end
		end
	end

	-- NPC targets
	if config.NPC_Aimbot then
		scanAllNPCs(function(npc)
			if npc and npc:IsA("Model") then
				local human = npc:FindFirstChild("Humanoid")
				local part = npc:FindFirstChild(config.AimPart or "Head")
				if human and human.Health > 0 then
					evaluateTarget(part)
				end
			end
		end)
	end

	return closest
end


-- Lock-on Aimbot loop
RunService:BindToRenderStep("AimbotLock", Enum.RenderPriority.Camera.Value + 1, function()
	if config.AimbotEnabled and AimbotHolding then
		local camPos = Camera.CFrame.Position

		if not lockedTarget
			or not lockedTarget:IsA("BasePart")
			or not lockedTarget:IsDescendantOf(workspace)
			or (config.WallCheck and not isVisible(lockedTarget, camPos))
		then
			lockedTarget = getClosestAimbotTarget()
		end

		if lockedTarget then
			local smoothness = config.Smoothness
			local targetCF = CFrame.new(camPos, lockedTarget.Position)
			Camera.CFrame = Camera.CFrame:Lerp(targetCF, smoothness)
		end
	else
		lockedTarget = nil
	end
end)

--// ESP SYSTEM
local ESPObjects = {}

-- Utility Functions
local function NewLine(thickness, color)
    local line = Drawing.new("Line")
    line.Thickness = thickness
    line.Color = color
    line.Visible = false
    return line
end

local function NewQuad(thickness, color)
    local quad = Drawing.new("Quad")
    quad.Thickness = thickness
    quad.Color = color
    quad.Filled = false
    quad.Visible = false
    return quad
end

local function NewText(size, color)
    local text = Drawing.new("Text")
    text.Size = size
    text.Color = color
    text.Center = true
    text.Outline = true
    text.Visible = false
    return text
end

local function Visibility(state, library)
    for _, obj in pairs(library) do
        obj.Visible = state
    end
end

local function SafeSetVisibility(objects, state)
    for _, obj in ipairs(objects) do
        if obj then obj.Visible = state end
    end
end

local function ESP(plr)
    if plr == LocalPlayer then return end

    local lib = {
        tracerOutline = NewLine(Settings.Tracer_Thickness * 2, Color3.new(0, 0, 0)),
        tracer = NewLine(Settings.Tracer_Thickness, Settings.Tracer_Color),
        boxOutline = NewQuad(Settings.Box_Thickness * 2, Color3.new(0, 0, 0)),
        box = NewQuad(Settings.Box_Thickness, Settings.Box_Color),
        healthOutline = NewLine(3, Color3.new(0, 0, 0)),
        health = NewLine(1.5, Color3.new(0, 255, 0)),
        name = NewText(16, Color3.fromRGB(255, 255, 255)),
        distance = NewText(16, Color3.fromRGB(255, 255, 255))
    }

    ESPObjects[plr] = lib

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not config.ESPEnabled then
            Visibility(false, lib)
            return
        end

        if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or not plr.Character:FindFirstChild("Humanoid") or plr.Character.Humanoid.Health <= 0 then
            Visibility(false, lib)
            if not Players:FindFirstChild(plr.Name) then
                conn:Disconnect()
                ESPObjects[plr] = nil
            end
            return
        end

        local root = plr.Character.HumanoidRootPart
        local head = plr.Character:FindFirstChild("Head")
        local humanoid = plr.Character.Humanoid

        local HumPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            Visibility(false, lib)
            return
        end

        local headPos = Camera:WorldToViewportPoint(head.Position)
        local size = math.clamp((Vector2.new(headPos.X, headPos.Y) - Vector2.new(HumPos.X, HumPos.Y)).Magnitude, 2, 9999)

        -- Box
        lib.box.PointA = Vector2.new(HumPos.X + size, HumPos.Y - size * 2)
        lib.box.PointB = Vector2.new(HumPos.X - size, HumPos.Y - size * 2)
        lib.box.PointC = Vector2.new(HumPos.X - size, HumPos.Y + size * 2)
        lib.box.PointD = Vector2.new(HumPos.X + size, HumPos.Y + size * 2)

        lib.boxOutline.PointA, lib.boxOutline.PointB = lib.box.PointA, lib.box.PointB
        lib.boxOutline.PointC, lib.boxOutline.PointD = lib.box.PointC, lib.box.PointD

        -- Tracer
        if Settings.Tracers then
            local origin
            if Settings.Tracer_FollowMouse then
                origin = Vector2.new(mouse.X, mouse.Y + 36)
            elseif Settings.Tracer_Origin == "Middle" then
                origin = Camera.ViewportSize * 0.5
            else
                origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            end
            lib.tracer.From, lib.tracer.To = origin, Vector2.new(HumPos.X, HumPos.Y + size * 2)
            lib.tracerOutline.From, lib.tracerOutline.To = lib.tracer.From, lib.tracer.To
        end

        -- Health bar
        local fullHeight = (Vector2.new(HumPos.X - size, HumPos.Y - size * 2) - Vector2.new(HumPos.X - size, HumPos.Y + size * 2)).Magnitude
        local ratio = humanoid.Health / humanoid.MaxHealth
        local hpOffset = ratio * fullHeight

        lib.healthOutline.From = Vector2.new(HumPos.X - size - 4, HumPos.Y + size * 2)
        lib.healthOutline.To = Vector2.new(HumPos.X - size - 4, HumPos.Y - size * 2)

        lib.health.From = Vector2.new(HumPos.X - size - 4, HumPos.Y + size * 2)
        lib.health.To = Vector2.new(HumPos.X - size - 4, HumPos.Y + size * 2 - hpOffset)

        lib.health.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), ratio)

        -- Name & distance
        lib.name.Text = plr.DisplayName
        lib.name.Position = Vector2.new(HumPos.X, HumPos.Y - size - 20)
        lib.name.Size = math.clamp(size * 0.5, 13, 25)

        local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
        lib.distance.Text = dist .. " studs"
        lib.distance.Position = Vector2.new(HumPos.X, HumPos.Y + size + 10)
        lib.distance.Size = lib.name.Size

        -- Apply visibility based on toggles
        SafeSetVisibility({lib.box, lib.boxOutline}, config.ESP_ShowBox)
        SafeSetVisibility({lib.tracer, lib.tracerOutline}, config.ESP_ShowTracer)
        SafeSetVisibility({lib.health, lib.healthOutline}, config.ESP_ShowHealth)
        SafeSetVisibility({lib.name, lib.distance}, config.ESP_ShowName)
    end)
end

-- Update visibility for all ESP objects
function UpdateESPVisibility()
    for _, lib in pairs(ESPObjects) do
        if config.ESPEnabled then
            SafeSetVisibility({lib.box, lib.boxOutline}, config.ESP_ShowBox)
            SafeSetVisibility({lib.tracer, lib.tracerOutline}, config.ESP_ShowTracer)
            SafeSetVisibility({lib.health, lib.healthOutline}, config.ESP_ShowHealth)
            SafeSetVisibility({lib.name, lib.distance}, config.ESP_ShowName)
        else
            Visibility(false, lib)
        end
    end
end

-- Hook into players
for _, plr in ipairs(Players:GetPlayers()) do
    ESP(plr)
end
Players.PlayerAdded:Connect(ESP)

--//Load Configs
Rayfield:LoadConfiguration()
