
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
AimbotTab:CreateSlider({ Name = "Smoothness", Range = {0, 1}, Increment = 0.05, Suffix = "s", CurrentValue = 0.1, Callback = function(v) config.Smoothness = v end })
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

local function isVisible(part)
    -- Ensure we have a valid part and camera
    if not part or not Camera then 
        return false 
    end
    
    local origin = Camera.CFrame.Position
    local targetPosition = part.Position
    local direction = targetPosition - origin
    local distance = direction.Magnitude
    
    -- Normalize the direction vector
    direction = direction.Unit * (distance - 0.1) -- Slightly shorter to avoid hitting the target itself
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    -- Filter out the local player's character and camera
    local filterList = {Camera}
    if LocalPlayer.Character then
        table.insert(filterList, LocalPlayer.Character)
    end
    
    -- Also filter out the target part's model to avoid self-intersection
    local targetModel = part:FindFirstAncestorOfClass("Model")
    if targetModel then
        table.insert(filterList, targetModel)
    end
    
    rayParams.FilterDescendantsInstances = filterList
    
    local result = workspace:Raycast(origin, direction, rayParams)
    
    -- If no hit, the part is visible (no walls blocking)
    if not result then 
        return true 
    end
    
    -- If we hit something, check if it's closer than our target
    local hitDistance = (result.Position - origin).Magnitude
    return hitDistance >= distance - 0.1 -- Allow small margin for floating point errors
end

local function getClosestAimbotTarget()
    local closest, shortest = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    local function evaluateTarget(part, targetType, humanoid)
        if not part or not part:IsA("BasePart") then return end
        if config.WallCheck and not isVisible(part) then return end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then return end
        
        -- FOV check if configured
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if config.FOV and dist > config.FOV then return end
        
        -- Priority system: factor in health and target type
        local priority = dist
        
        -- Lower health targets get priority (multiply by health percentage)
        if humanoid and config.HealthPriority then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            priority = priority * (0.5 + healthPercent * 0.5) -- Range: 0.5x to 1.0x multiplier
        end
        
        -- Players get slight priority over NPCs
        if targetType == "player" and config.PlayerPriority then
            priority = priority * 0.9
        end
        
        if priority < shortest then
            closest = part
            shortest = priority
        end
    end
    
    -- Player targets
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Parent then -- Check player still exists
            local char = plr.Character
            if char and char.Parent then -- Ensure character exists
                local human = char:FindFirstChild("Humanoid")
                if human and human.Health > 0 and not human.PlatformStand then -- Avoid ragdolled players
                    -- Team check
                    if config.TeamCheck and plr.Team == LocalPlayer.Team then
                        -- Skip teammates
                    else
                        -- Try R6 body parts as fallback
                        local targetPart = char:FindFirstChild(config.AimPart or "Head")
                        if not targetPart then
                            -- R6 fallback parts in order of preference
                            local fallbackParts = {"Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm"}
                            for _, partName in ipairs(fallbackParts) do
                                targetPart = char:FindFirstChild(partName)
                                if targetPart then break end
                            end
                        end
                        
                        if targetPart then
                            evaluateTarget(targetPart, "player", human)
                        end
                    end
                end
            end
        end
    end
    
    -- NPC targets with improved detection for R6
    if config.NPC_Aimbot then
        scanAllNPCs(function(npc)
            if npc and npc:IsA("Model") and npc ~= LocalPlayer.Character then
                local human = npc:FindFirstChild("Humanoid") or npc:FindFirstChildOfClass("Humanoid")
                if human and human.Health > 0 and not human.PlatformStand then
                    -- Ensure it's actually an NPC and not a player character
                    local isPlayerCharacter = false
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr.Character == npc then
                            isPlayerCharacter = true
                            break
                        end
                    end
                    
                    if not isPlayerCharacter then
                        -- Try R6 body parts as fallback for NPCs too
                        local targetPart = npc:FindFirstChild(config.AimPart or "Head")
                        if not targetPart then
                            -- R6 fallback parts for NPCs
                            local fallbackParts = {"Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm"}
                            for _, partName in ipairs(fallbackParts) do
                                targetPart = npc:FindFirstChild(partName)
                                if targetPart then break end
                            end
                        end
                        
                        if targetPart then
                            evaluateTarget(targetPart, "npc", human)
                        end
                    end
                end
            end
        end)
    end
    
    return closest
end

-- Enhanced version with velocity prediction for R6
local function getClosestAimbotTargetWithPrediction()
    local closest, shortest = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    local function evaluateTargetWithPrediction(part, targetType, humanoid)
        if not part or not part:IsA("BasePart") then return end
        
        local targetPos = part.Position
        
        -- Velocity prediction if enabled (works better with Torso in R6)
        if config.Prediction and part.AssemblyLinearVelocity then
            local velocity = part.AssemblyLinearVelocity
            local distance = (targetPos - Camera.CFrame.Position).Magnitude
            local timeToTarget = distance / (config.BulletSpeed or 1000)
            targetPos = targetPos + (velocity * timeToTarget * (config.PredictionStrength or 1))
        end
        
        if config.WallCheck and not isVisible(part) then return end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
        if not onScreen then return end
        
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if config.FOV and dist > config.FOV then return end
        
        local priority = dist
        
        if humanoid and config.HealthPriority then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            priority = priority * (0.5 + healthPercent * 0.5)
        end
        
        if targetType == "player" and config.PlayerPriority then
            priority = priority * 0.9
        end
        
        if priority < shortest then
            closest = part
            shortest = priority
        end
    end
    
    -- Same player/NPC logic but with prediction for R6
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Parent then
            local char = plr.Character
            if char and char.Parent then
                local human = char:FindFirstChild("Humanoid")
                if human and human.Health > 0 and not human.PlatformStand then
                    if not (config.TeamCheck and plr.Team == LocalPlayer.Team) then
                        local targetPart = char:FindFirstChild(config.AimPart or "Head")
                        if not targetPart then
                            -- R6 specific fallback parts
                            local fallbackParts = {"Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm"}
                            for _, partName in ipairs(fallbackParts) do
                                targetPart = char:FindFirstChild(partName)
                                if targetPart then break end
                            end
                        end
                        
                        if targetPart then
                            evaluateTargetWithPrediction(targetPart, "player", human)
                        end
                    end
                end
            end
        end
    end
    
    if config.NPC_Aimbot then
        scanAllNPCs(function(npc)
            if npc and npc:IsA("Model") and npc ~= LocalPlayer.Character then
                local human = npc:FindFirstChild("Humanoid") or npc:FindFirstChildOfClass("Humanoid")
                if human and human.Health > 0 and not human.PlatformStand then
                    local isPlayerCharacter = false
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr.Character == npc then
                            isPlayerCharacter = true
                            break
                        end
                    end
                    
                    if not isPlayerCharacter then
                        local targetPart = npc:FindFirstChild(config.AimPart or "Head")
                        if not targetPart then
                            -- R6 fallback parts for NPCs
                            local fallbackParts = {"Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm"}
                            for _, partName in ipairs(fallbackParts) do
                                targetPart = npc:FindFirstChild(partName)
                                if targetPart then break end
                            end
                        end
                        
                        if targetPart then
                            evaluateTargetWithPrediction(targetPart, "npc", human)
                        end
                    end
                end
            end
        end)
    end
    
    return closest
end

-- R6 specific body part targeting function (bonus utility)
local function getR6BodyPart(character, preferredPart)
    if not character then return nil end
    
    -- R6 body parts in order of preference for different scenarios
    local bodyParts = {
        head = {"Head"},
        torso = {"Torso", "HumanoidRootPart"},
        arms = {"Left Arm", "Right Arm"},
        legs = {"Left Leg", "Right Leg"},
        all = {"Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
    }
    
    local partsToCheck = bodyParts[preferredPart] or bodyParts.all
    
    for _, partName in ipairs(partsToCheck) do
        local part = character:FindFirstChild(partName)
        if part then
            return part
        end
    end
    
    return nil
end

RunService.RenderStepped:Connect(function()
	if config.AimbotEnabled and AimbotHolding then
		local target = getClosestAimbotTarget()
		if target and target:IsA("BasePart") then
			local camCF = CFrame.new(Camera.CFrame.Position, target.Position)
			TweenService:Create(Camera, TweenInfo.new(config.Smoothness or 0.1, Enum.EasingStyle.Sine), {CFrame = camCF}):Play()
		end
	end
end)

--//Load Configs
Rayfield:LoadConfiguration()
