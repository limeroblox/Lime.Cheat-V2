
--// UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({ Name = "Lime.Cheat V.2 | Blackout: Revival | Killzone/Zombies", Icon = 141272932, LoadingTitle = "Loading Script...", LoadingSubtitle = "By @lime.bat", ShowText = "Lime.Cheat V.2", Theme = "Default", ToggleUIKeybind = "K", DisableRayfieldPrompts = false, DisableBuildWarnings = false, ConfigurationSaving = { Enabled = true, FolderName = nil, FileName = "Lime.Cheat V.2 | Blackout: Revival Script" }, Discord = { Enabled = false, Invite = "noinvitelink", RememberJoins = true }, KeySystem = true, KeySettings = { Title = "Lime.Cheat", Subtitle = "Key System", Note = "To get the key, ask @lime.bat for the key", FileName = "Lime.Cheat Key Folder", SaveKey = true, GrabKeyFromSite = false, Key = {"Blackout"} } })

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
local UpdateESPVisibility = function() end


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

--// Settings for config, ig :P
local Settings = {
    Tracer_Thickness = 1,
    Tracer_Color = Color3.fromRGB(255,255,255),
    Box_Thickness = 1,
    Box_Color = Color3.fromRGB(255,255,255),
    Tracers = true,
    Tracer_FollowMouse = false,
    Tracer_Origin = "Bottom"
}

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


--// UTILITY
local function NewQuad(thickness, color)
    local quad = Drawing.new("Quad")
    quad.Visible = false
    quad.Color = color
    quad.Filled = false
    quad.Thickness = thickness
    quad.Transparency = 1
    return quad
end

local function NewLine(thickness, color)
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = color
    line.Thickness = thickness
    line.Transparency = 1
    return line
end

local function NewText(size, color, font)
    local text = Drawing.new("Text")
    text.Visible = false
    text.Size = size
    text.Color = color
    text.Font = font or Drawing.Fonts.UI
    text.Text = ""
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.fromRGB(0, 0, 0)
    return text
end

local function Visibility(state, lib)
    for _, x in pairs(lib) do
        x.Visible = state
    end
end

local function SafeSetVisibility(elements, condition)
    for _, element in ipairs(elements) do
        if element then
            element.Visible = condition
        end
    end
end

--// TRACKED ESP OBJECTS
local ESPObjects = {}

--// ESP GENERATOR
local function ESP(plr)
    if plr == player then return end

    local black = Color3.fromRGB(0, 0, 0)
    local library = {
        blacktracer = NewLine(Settings.Tracer_Thickness * 2, black),
        tracer = NewLine(Settings.Tracer_Thickness, Settings.Tracer_Color),
        black = NewQuad(Settings.Box_Thickness * 2, black),
        box = NewQuad(Settings.Box_Thickness, Settings.Box_Color),
        healthbar = NewLine(3, black),
        greenhealth = NewLine(1.5, black),
        username = NewText(16, Color3.fromRGB(255, 255, 255)),
        distance = NewText(16, Color3.fromRGB(255, 255, 255))
    }

    ESPObjects[plr] = library

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or not plr.Character:FindFirstChild("Humanoid") or plr.Character.Humanoid.Health <= 0 or not plr.Character:FindFirstChild("Head") then
            Visibility(false, library)
            if not Players:FindFirstChild(plr.Name) then
                connection:Disconnect()
                ESPObjects[plr] = nil
            end
            return
        end

        local HumPos, OnScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
        if not OnScreen then
            Visibility(false, library)
            return
        end

        local head = camera:WorldToViewportPoint(plr.Character.Head.Position)
        local DistanceY = math.clamp((Vector2.new(head.X, head.Y) - Vector2.new(HumPos.X, HumPos.Y)).magnitude, 2, math.huge)

        -- BOX
        local function Size(item)
            item.PointA = Vector2.new(HumPos.X + DistanceY, HumPos.Y - DistanceY * 2)
            item.PointB = Vector2.new(HumPos.X - DistanceY, HumPos.Y - DistanceY * 2)
            item.PointC = Vector2.new(HumPos.X - DistanceY, HumPos.Y + DistanceY * 2)
            item.PointD = Vector2.new(HumPos.X + DistanceY, HumPos.Y + DistanceY * 2)
        end
        Size(library.box)
        Size(library.black)

        -- TRACERS
        if Settings.Tracers then
            if Settings.Tracer_FollowMouse then
                library.tracer.From = Vector2.new(mouse.X, mouse.Y + 36)
                library.blacktracer.From = Vector2.new(mouse.X, mouse.Y + 36)
            elseif Settings.Tracer_Origin == "Middle" then
                local center = camera.ViewportSize * 0.5
                library.tracer.From = center
                library.blacktracer.From = center
            else
                local bottom = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y)
                library.tracer.From = bottom
                library.blacktracer.From = bottom
            end
            library.tracer.To = Vector2.new(HumPos.X, HumPos.Y + DistanceY * 2)
            library.blacktracer.To = Vector2.new(HumPos.X, HumPos.Y + DistanceY * 2)
        else
            library.tracer.From = Vector2.new(0, 0)
            library.tracer.To = Vector2.new(0, 0)
            library.blacktracer.From = Vector2.new(0, 0)
            library.blacktracer.To = Vector2.new(0, 0)
        end

        -- HEALTHBAR
        local d = (Vector2.new(HumPos.X - DistanceY, HumPos.Y - DistanceY * 2) - Vector2.new(HumPos.X - DistanceY, HumPos.Y + DistanceY * 2)).magnitude
        local hp_ratio = plr.Character.Humanoid.Health / plr.Character.Humanoid.MaxHealth
        local healthoffset = hp_ratio * d

        library.greenhealth.From = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY * 2)
        library.greenhealth.To = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY * 2 - healthoffset)
        library.healthbar.From = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY * 2)
        library.healthbar.To = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y - DistanceY * 2)

        local green = Color3.fromRGB(0, 255, 0)
        local red = Color3.fromRGB(255, 0, 0)
        library.greenhealth.Color = red:lerp(green, hp_ratio)

        -- NAME & DISTANCE
        library.username.Text = plr.DisplayName
        library.username.Position = Vector2.new(HumPos.X, HumPos.Y - DistanceY - 20)
        library.username.Size = math.clamp(DistanceY * 0.5, 13, 25)

        local dist = math.floor((camera.CFrame.Position - plr.Character.HumanoidRootPart.Position).Magnitude)
        library.distance.Text = tostring(dist) .. " studs"
        library.distance.Position = Vector2.new(HumPos.X, HumPos.Y + DistanceY + 10)
        library.distance.Size = math.clamp(DistanceY * 0.5, 13, 25)

        -- Apply Config Toggles
        if config.ESPEnabled then
            SafeSetVisibility({library.box, library.black}, config.ESP_ShowBox)
            SafeSetVisibility({library.tracer, library.blacktracer}, config.ESP_ShowTracer)
            SafeSetVisibility({library.greenhealth, library.healthbar}, config.ESP_ShowHealth)
            SafeSetVisibility({library.username, library.distance}, config.ESP_ShowName)
        else
            Visibility(false, library)
        end
    end)
end

UpdateESPVisibility = function()
    for _, lib in pairs(ESPObjects) do
        if config.ESPEnabled then
            SafeSetVisibility({lib.box, lib.black}, config.ESP_ShowBox)
            SafeSetVisibility({lib.tracer, lib.blacktracer}, config.ESP_ShowTracer)
            SafeSetVisibility({lib.greenhealth, lib.healthbar}, config.ESP_ShowHealth)
            SafeSetVisibility({lib.username, lib.distance}, config.ESP_ShowName)
        else
            Visibility(false, lib)
        end
    end
end

-- Hook Players
for _, plr in ipairs(Players:GetPlayers()) do
    ESP(plr)
end
Players.PlayerAdded:Connect(ESP)

--//Load Configs
Rayfield:LoadConfiguration()
