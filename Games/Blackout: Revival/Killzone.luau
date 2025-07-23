
--// UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
   Name = "Lime.Cheat V.2 | Blackout: Revival | Killzone/Zombies",
   Icon = 141272932, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Loading Script...",
   LoadingSubtitle = "By @lime.bat",
   ShowText = "Lime.Cheat V.2", -- for mobile users to unhide rayfield, change if you'd like
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Lime.Cheat V.2 | Blackout: Revival Script"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = true, -- Set this to true to use our key system
   KeySettings = {
      Title = "Lime.Cheat",
      Subtitle = "Key System",
      Note = "To get the key, ask @lime.bat for the key", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Blackout"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

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
	WallCheck = true
}

local Tab 		= Window:CreateTab("KillAura", 4483362458)
local AimbotTab 	= Window:CreateTab("Aimbot", 4483362458)

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

--// Services
local Players 		= game:GetService("Players")
local RunService 	= game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService 	= game:GetService("TweenService")
local UserInputService 	= game:GetService("UserInputService")

--// Vars
local LocalPlayer 	= Players.LocalPlayer
local Camera 		= workspace.CurrentCamera



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

--// Killaura/Gunaura Loop
local lastHit = 0
RunService.RenderStepped:Connect(function()
	local now = tick()
	-- Delay-based Logic
	if now - lastHit < config.Delay then return end
	lastHit = now

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


--//Load Configs
Rayfield:LoadConfiguration()
