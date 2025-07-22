
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
    Enabled = false,
    NPC_KillAura = false,
    NPC_GunAura = false,
    Range = 15,
    HeadChance = 20,
    Delay = 0.1,
    AimbotEnabled = false,
    Aimbot_Players = false,
    Aimbot_NPCs = false,
    Aimbot_Mode = "PC", -- Set default to PC
    TargetPart = "Head"
}

local Tab = Window:CreateTab("KillAura", 4483362458)
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)


--// Aimbot 
AimbotTab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = false, Callback = function(v) config.AimbotEnabled = v end })
AimbotTab:CreateToggle({ Name = "Player Check", CurrentValue = false, Callback = function(v) config.Aimbot_Players = v end })
AimbotTab:CreateToggle({ Name = "Npc Check", CurrentValue = false, Callback = function(v) config.Aimbot_NPCs = v end })
AimbotTab:CreateDropdown({ Name = "Input Mode", Options = {"PC", "Xbox"}, CurrentOption = config.Aimbot_Mode, Callback = function(option) config.Aimbot_Mode = option end })
AimbotTab:CreateDropdown({ Name = "Target Part", Options = {"Head", "Torso"}, CurrentOption = config.TargetPart, Callback = function(option) config.TargetPart = option end })



--// Killaura
Tab:CreateToggle({ Name = "Enable KillAura (Players)", CurrentValue = false, Callback = function(v) config.Enabled = v end })
Tab:CreateToggle({ Name = "KillAura (All NPCs)", CurrentValue = false, Callback = function(v) config.NPC_KillAura = v end })
Tab:CreateToggle({ Name = "GunAura (All NPCs)", CurrentValue = false, Callback = function(v) config.NPC_GunAura = v end })
Tab:CreateSlider({ Name = "Aura Range", Range = {1, 30}, Increment = 1, Suffix = " studs", CurrentValue = 15, Callback = function(v) config.Range = v end })
Tab:CreateSlider({ Name = "Head Hit Chance (%)", Range = {0, 100}, Increment = 1, Suffix = "%", CurrentValue = 20, Callback = function(v) config.HeadChance = v end })
Tab:CreateSlider({ Name = "KillAura Delay (seconds)", Range = {0.1, 2}, Increment = 0.1, Suffix = "s", CurrentValue = 0.1, Callback = function(v) config.Delay = v end })

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

--// Valid R6 limbs
local r6Limbs = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

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


local lockedTarget = nil

--// Input Hold Checker
local function checkAimbotInput()
	local inputType = UserInputService:GetLastInputType()
	if config.Aimbot_Mode == "PC" and inputType == Enum.UserInputType.MouseMovement then
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	elseif config.Aimbot_Mode == "Xbox" and inputType.Name:match("Gamepad") then
		return UserInputService:IsKeyDown(Enum.KeyCode.ButtonL2)
	end
	return false
end

--// Aimbot Target Finder
local function findClosestTarget()
	local mousePos = UserInputService:GetMouseLocation()
	local cam = workspace.CurrentCamera
	local bestTarget, closestDist = nil, math.huge

	local function tryTarget(char)
		local humanoid = char:FindFirstChild("Humanoid")
		local part = char:FindFirstChild(config.TargetPart)
		if not humanoid or humanoid.Health <= 0 or not part then return end

		local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
		if not onScreen then return end

		local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
		if dist < closestDist then
			bestTarget = part
			closestDist = dist
		end
	end

	if config.Aimbot_Players then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				tryTarget(plr.Character)
			end
		end
	end

	if config.Aimbot_NPCs then
		scanAllNPCs(tryTarget)
	end

	return bestTarget
end

--// Aimbot Lock + Aim
local function handleAimbot()
	if not config.AimbotEnabled then
		lockedTarget = nil
		return
	end

	if not checkAimbotInput() then
		lockedTarget = nil
		return
	end

	-- Validate target
	if lockedTarget and (
		not lockedTarget:IsDescendantOf(workspace) or
		not lockedTarget.Parent:FindFirstChild("Humanoid") or
		lockedTarget.Parent.Humanoid.Health <= 0
	) then
		lockedTarget = nil
	end

	-- Find new target if needed
	if not lockedTarget then
		lockedTarget = findClosestTarget()
	end

	-- Aim at target
	if lockedTarget then
		local cam = workspace.CurrentCamera
		cam.CFrame = CFrame.new(cam.CFrame.Position, lockedTarget.Position)
	end
end

--// Main Loop
local lastHit = 0
RunService.RenderStepped:Connect(function()
    local now = tick()

    -- Aimbot should run every frame (no delay)
    handleAimbot()

    -- Delay-based actions below
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


--//Load Configs
Rayfield:LoadConfiguration()
