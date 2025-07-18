local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
	Name = "Lime.Cheat | Blackout Revival: Killzone | Mobile Edition",
	LoadingTitle = "Lime.Cheat",
	LoadingSubtitle = "by Snowy",
	ConfigurationSaving = {
		Enabled = false,
	},
	Discord = {
		Enabled = false,
	},
	KeySystem = false,
})

local CombatTab = Window:CreateTab("Combat", 4483362458)

-- Settings
getgenv().KillAura = false
getgenv().KillAuraRange = 15
getgenv().KillAuraTargetPart = "Head"
getgenv().KillAuraTargetType = "Players"

-- UI
CombatTab:CreateToggle({
	Name = "KillAura",
	CurrentValue = false,
	Flag = "KillAura",
	Callback = function(Value)
		getgenv().KillAura = Value
	end,
})

CombatTab:CreateSlider({
	Name = "Aura Range",
	Range = {1, 30},
	Increment = 1,
	Suffix = "studs",
	CurrentValue = 15,
	Flag = "KillAuraRange",
	Callback = function(Value)
		getgenv().KillAuraRange = Value
	end,
})

CombatTab:CreateDropdown({
	Name = "Target Body Part",
	Options = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
	CurrentOption = "Head",
	Flag = "KillAuraTargetPart",
	Callback = function(Option)
		getgenv().KillAuraTargetPart = Option
	end,
})

CombatTab:CreateDropdown({
	Name = "KillAura Target",
	Options = {"Players", "NPCs (Hostile)", "Both"},
	CurrentOption = "Players",
	Flag = "KillAuraTargetType",
	Callback = function(Option)
		getgenv().KillAuraTargetType = Option
	end,
})

-- Remotes
local HitRemote = ReplicatedStorage:WaitForChild("MeleeStorage"):WaitForChild("Events"):WaitForChild("Hit")
local SwingRemote = ReplicatedStorage:WaitForChild("MeleeStorage"):WaitForChild("Events"):WaitForChild("Swing")

-- Helper Functions
local function getTargetPart(character)
	local partName = getgenv().KillAuraTargetPart
	local part = character:FindFirstChild(partName)

	-- Fallback to head if selected part is missing
	if not part or not part:IsA("BasePart") then
		part = character:FindFirstChild("Head") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
	end

	return part
end

local function attackTarget(char)
	if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end

	local part = getTargetPart(char)
	if not part then return end

	pcall(function()
		SwingRemote:InvokeServer()
		HitRemote:FireServer(part, part.Position)
	end)
end

local function isInRange(pos1, pos2)
	return (pos1 - pos2).Magnitude <= getgenv().KillAuraRange
end

-- Main KillAura Loop
RunService.RenderStepped:Connect(function()
	if not getgenv().KillAura then return end

	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	local targetType = getgenv().KillAuraTargetType

	-- Players
	if targetType == "Players" or targetType == "Both" then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				local root = player.Character:FindFirstChild("HumanoidRootPart")
				if root and isInRange(myRoot.Position, root.Position) then
					attackTarget(player.Character)
				end
			end
		end
	end

	-- NPCs (Hostile)
	if targetType == "NPCs (Hostile)" or targetType == "Both" then
		local hostileFolder = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild("Hostile")
		if hostileFolder then
			for _, npc in pairs(hostileFolder:GetChildren()) do
				if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
					if npc.Humanoid.Health > 0 and isInRange(myRoot.Position, npc.HumanoidRootPart.Position) then
						attackTarget(npc)
					end
				end
			end
		end
	end
end)
