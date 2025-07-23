
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
 	Aimbot_Players = true,
    	Aimbot_NPCs = false, -- Reserved for future use
    	TargetPart = "Head",
    	SmoothTime = 0.08,
    	FOVRange = 120
}

local Tab 		= Window:CreateTab("KillAura", 4483362458)
local AimbotTab 	= Window:CreateTab("Aimbot", 4483362458)

AimbotTab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = false, Callback = function(v) config.AimbotEnabled = v end })
AimbotTab:CreateToggle({ Name = "Player Check", CurrentValue = true, Callback = function(v) config.Aimbot_Players = v end })
AimbotTab:CreateToggle({ Name = "NPC Check", CurrentValue = false, Callback = function(v) config.Aimbot_NPCs = v end })
AimbotTab:CreateDropdown({ Name = "Target Part", Options = {"Head", "Torso"}, CurrentOption = "Head", Callback = function(opt) config.TargetPart = opt end })
AimbotTab:CreateSlider({ Name = "FOV Range", Range = {20, 300}, Increment = 5, CurrentValue = 120, Callback = function(val) config.FOVRange = val end })
AimbotTab:CreateSlider({ Name = "Smoothness", Range = {0, 0.3}, Increment = 0.01, CurrentValue = 0.08, Callback = function(val) config.SmoothTime = val end })



--// Killaura
Tab:CreateToggle({ Name = "Enable KillAura (Players)", CurrentValue = false, Callback = function(v) config.Enabled = v end })
Tab:CreateToggle({ Name = "KillAura (All NPCs)", CurrentValue = false, Callback = function(v) config.NPC_KillAura = v end })
Tab:CreateToggle({ Name = "GunAura (All NPCs)", CurrentValue = false, Callback = function(v) config.NPC_GunAura = v end })
Tab:CreateSlider({ Name = "Aura Range", Range = {1, 30}, Increment = 1, Suffix = " studs", CurrentValue = 15, Callback = function(v) config.Range = v end })
Tab:CreateSlider({ Name = "Head Hit Chance (%)", Range = {0, 100}, Increment = 1, Suffix = "%", CurrentValue = 20, Callback = function(v) config.HeadChance = v end })
Tab:CreateSlider({ Name = "KillAura Delay (seconds)", Range = {0.1, 2}, Increment = 0.1, Suffix = "s", CurrentValue = 0.1, Callback = function(v) config.Delay = v end })

--// Services
local Players 		     = game:GetService("Players")
local RunService 	     = game:GetService("RunService")
local ReplicatedStorage      = game:GetService("ReplicatedStorage")
local TweenService 	     = game:GetService("TweenService")
local UserInputService 	     = game:GetService("UserInputService")

--// Vars
local LocalPlayer 	     = Players.LocalPlayer
local Camera 		     = workspace.CurrentCamera
local Chars 		     = workspace:WaitForChild("Chars")



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

--// Killaura/Gunaura Loop
local lastHit = 0
RunService.RenderStepped:Connect(function()
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

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// Variables
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Chars = workspace:WaitForChild("Chars")

--// Config
local config = {
    AimbotEnabled = false,
    Aimbot_Players = true,
    Aimbot_NPCs = false, -- Reserved for future use
    TargetPart = "Head",
    SmoothTime = 0.08,
    FOVRange = 120
}

--// State
local lockedTarget = nil

--// Helper: Check if input is held
local function isHoldingAimbot()
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or
           UserInputService:IsKeyDown(Enum.KeyCode.ButtonL2)
end

--// Helper: Get closest valid character
local function findClosestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closest, shortest = nil, math.huge

    for _, char in ipairs(Chars:GetChildren()) do
        local player = Players:GetPlayerFromCharacter(char)
        if player and player ~= LocalPlayer then
            local humanoid = char:FindFirstChild("Humanoid")
            local targetPart = char:FindFirstChild(config.TargetPart)

            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < config.FOVRange and dist < shortest then
                        closest = targetPart
                        shortest = dist
                    end
                end
            end
        end
    end

    return closest
end

--// Aimbot loop
RunService.RenderStepped:Connect(function()
    if config.AimbotEnabled and isHoldingAimbot() then
        if not lockedTarget or not lockedTarget:IsDescendantOf(workspace) then
            lockedTarget = findClosestTarget()
        end

        if lockedTarget then
            local camCF = CFrame.new(Camera.CFrame.Position, lockedTarget.Position)
            local tween = TweenService:Create(Camera, TweenInfo.new(config.SmoothTime, Enum.EasingStyle.Sine), {CFrame = camCF})
            tween:Play()
        end
    else
        lockedTarget = nil
    end
end)

--//Load Configs
Rayfield:LoadConfiguration()
