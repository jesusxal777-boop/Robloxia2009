--[[
	ARGSystem.lua v0.5
	1) Hatch (E) -> sala PC
	2) PcARG (E) -> codigo
	3) Chat codigo -> mapa sangre
	4) Edd dialogo + Sword
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local MapConfig = require(script.Parent.MapConfig)
local ProximityPromptService = game:GetService("ProximityPromptService")

local ARGSystem = {}
local stage = "classic"
local classicRoot = nil
local playerCodesShown = {}
local eddFriendlySaid = {}

local function setClassicLighting()
	Lighting.Ambient = Color3.fromRGB(110, 105, 120)
	Lighting.Brightness = 1.6
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 95, 110)
	Lighting.FogColor = Color3.fromRGB(160, 155, 170)
	Lighting.FogEnd = 450
	Lighting.FogStart = 80
	Lighting.ClockTime = 16.5
	Lighting.GeographicLatitude = 20
end

local function setPCRoomLighting()
	Lighting.Ambient = Color3.fromRGB(20, 25, 40)
	Lighting.Brightness = 0.8
	Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 25)
	Lighting.FogEnd = 80
	Lighting.FogStart = 10
	Lighting.FogColor = Color3.fromRGB(10, 15, 30)
	Lighting.ClockTime = 0
end

local function setBloodLighting()
	Lighting.Ambient = MapConfig.ARG.AtmosphereColor
	Lighting.Brightness = 0.4
	Lighting.OutdoorAmbient = Color3.fromRGB(40, 10, 10)
	Lighting.FogColor = MapConfig.ARG.FogColor
	Lighting.FogEnd = MapConfig.ARG.FogEnd
	Lighting.FogStart = 20
	Lighting.ClockTime = 2
end

local function messageAll(text, seconds)
	seconds = seconds or 4
	local msg = Instance.new("Message")
	msg.Text = text
	msg.Parent = workspace
	task.delay(seconds, function()
		if msg.Parent then msg:Destroy() end
	end)
end

local function teleportPlayer(player, pos)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
end

local function cloneStorage(name, position, parent)
	local t = ServerStorage:FindFirstChild(name)
	if not t then warn("[ARG] No hay en ServerStorage: " .. name) return nil end
	local c = t:Clone()
	local parts = {}
	if c:IsA("BasePart") then table.insert(parts, c)
	else for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts, d) end end end
	if #parts > 0 then
		local minY, cx, cz = math.huge, 0, 0
		for _, p in ipairs(parts) do
			local y = p.Position.Y - p.Size.Y / 2
			if y < minY then minY = y end
			cx += p.Position.X
			cz += p.Position.Z
		end
		cx /= #parts
		cz /= #parts
		local offset = Vector3.new(position.X - cx, position.Y - minY, position.Z - cz)
		for _, p in ipairs(parts) do p.CFrame = p.CFrame + offset p.Anchored = true end
	end
	c.Parent = parent
	return c
end

local function createPCRoom()
	local existing = workspace:FindFirstChild(MapConfig.ARG.PCRoomName)
	if existing then existing:Destroy() end
	local room = Instance.new("Model")
	room.Name = MapConfig.ARG.PCRoomName
	room.Parent = workspace
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(40, 1, 40)
	floor.Position = Vector3.new(0, 200, 0)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(30, 30, 35)
	floor.Material = Enum.Material.Concrete
	floor.Parent = room
	for _, data in ipairs({ { Vector3.new(40, 12, 1), Vector3.new(0, 206, -20) }, { Vector3.new(40, 12, 1), Vector3.new(0, 206, 20) }, { Vector3.new(1, 12, 40), Vector3.new(-20, 206, 0) }, { Vector3.new(1, 12, 40), Vector3.new(20, 206, 0) } }) do
		local w = Instance.new("Part")
		w.Size = data[1]
		w.Position = data[2]
		w.Anchored = true
		w.Color = Color3.fromRGB(25, 25, 30)
		w.Parent = room
	end
	local ceil = Instance.new("Part")
	ceil.Size = Vector3.new(40, 1, 40)
	ceil.Position = Vector3.new(0, 212, 0)
	ceil.Anchored = true
	ceil.Color = Color3.fromRGB(20, 20, 25)
	ceil.Parent = room
	local pc = cloneStorage(MapConfig.ARG.StoragePC, Vector3.new(0, 200.5, -8), room)
	if not pc then
		pc = Instance.new("Part")
		pc.Name = "PcARG_Fallback"
		pc.Size = Vector3.new(4, 3, 2)
		pc.Position = Vector3.new(0, 202, -8)
		pc.Anchored = true
		pc.Color = Color3.fromRGB(40, 40, 50)
		pc.Parent = room
	end
	local promptPart = pc
	if pc:IsA("Model") then promptPart = pc.PrimaryPart or pc:FindFirstChildWhichIsA("BasePart", true) or pc end
	if promptPart and promptPart:IsA("BasePart") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PCInteractionPrompt"
		prompt.ActionText = "Examinar"
		prompt.ObjectText = "PC de 2009"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 16
		prompt.Style = Enum.ProximityPromptStyle.Default
		prompt.Enabled = true
		prompt.ClickablePrompt = true
		prompt.RequiresLineOfSight = false
		prompt.Parent = promptPart
		prompt.Triggered:Connect(function(player) ARGSystem.OnPCUsed(player) end)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PCRoomSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 201, 10)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = room
	return room
end

local function createBloodWorld()
	local existing = workspace:FindFirstChild(MapConfig.ARG.BloodMapName)
	if existing then existing:Destroy() end
	local blood = Instance.new("Model")
	blood.Name = MapConfig.ARG.BloodMapName
	blood.Parent = workspace
	local base = Instance.new("Part")
	base.Name = "BloodBase"
	base.Size = Vector3.new(400, 1, 400)
	base.Position = Vector3.new(0, -0.5, 0)
	base.Anchored = true
	base.Color = Color3.fromRGB(40, 5, 5)
	base.Material = Enum.Material.Asphalt
	base.Parent = blood
	for i = 1, 25 do
		local pool = Instance.new("Part")
		pool.Size = Vector3.new(math.random(4, 12), 0.2, math.random(4, 12))
		pool.Position = Vector3.new(math.random(-80, 80), 0.1, math.random(-80, 80))
		pool.Anchored = true
		pool.Color = Color3.fromRGB(120 + math.random(0, 40), 0, 0)
		pool.Material = Enum.Material.SmoothPlastic
		pool.Transparency = 0.2
		pool.Parent = blood
	end
	local function bp(name, size, pos, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = pos
		p.Anchored = true
		p.Color = color or Color3.fromRGB(50, 20, 20)
		p.Material = Enum.Material.Wood
		p.Parent = blood
	end
	bp("Floor", Vector3.new(24, 1, 20), Vector3.new(0, 0.5, 0))
	bp("WallF", Vector3.new(24, 10, 1), Vector3.new(0, 5.5, -10), Color3.fromRGB(70, 30, 30))
	bp("WallB", Vector3.new(24, 10, 1), Vector3.new(0, 5.5, 10), Color3.fromRGB(70, 30, 30))
	bp("WallL", Vector3.new(1, 10, 20), Vector3.new(-12, 5.5, 0), Color3.fromRGB(60, 25, 25))
	bp("WallR", Vector3.new(1, 10, 20), Vector3.new(12, 5.5, 0), Color3.fromRGB(60, 25, 25))
	bp("Roof", Vector3.new(26, 1, 22), Vector3.new(0, 11, 0), Color3.fromRGB(90, 15, 15))
	local function glitch(text, pos)
		local board = Instance.new("Part")
		board.Size = Vector3.new(12, 4, 0.5)
		board.Position = pos
		board.Anchored = true
		board.Color = Color3.fromRGB(10, 0, 0)
		board.Parent = blood
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(255, 40, 40)
		label.TextScaled = true
		label.Font = Enum.Font.Code
		label.Parent = gui
	end
	glitch("EDD WAS HERE", Vector3.new(0, 8, -15))
	glitch("THEY ALL LEFT", Vector3.new(-25, 6, 10))
	glitch("YOU ARE NEXT", Vector3.new(25, 6, 10))
	glitch("2009 NEVER ENDED", Vector3.new(0, 14, 0))
	local swordTemplate = ServerStorage:FindFirstChild(MapConfig.ARG.StorageSword)
	if swordTemplate then
		local sword = swordTemplate:Clone()
		local pedestal = Instance.new("Part")
		pedestal.Size = Vector3.new(2, 1, 2)
		pedestal.Position = Vector3.new(8, 0.5, -5)
		pedestal.Anchored = true
		pedestal.Color = Color3.fromRGB(30, 30, 30)
		pedestal.Parent = blood
		sword.Parent = workspace
		local handle = sword:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			handle.CFrame = CFrame.new(8, 2, -5)
			local swordPrompt = Instance.new("ProximityPrompt")
			swordPrompt.Name = "SwordInteractionPrompt"
			swordPrompt.ActionText = "Recoger"
			swordPrompt.ObjectText = "Espada"
			swordPrompt.KeyboardKeyCode = Enum.KeyCode.E
			swordPrompt.HoldDuration = 0
			swordPrompt.MaxActivationDistance = 16
			swordPrompt.Style = Enum.ProximityPromptStyle.Default
			swordPrompt.Enabled = true
			swordPrompt.ClickablePrompt = true
			swordPrompt.RequiresLineOfSight = false
			swordPrompt.Parent = handle
			swordPrompt.Triggered:Connect(function(player)
				if sword:IsA("Tool") and sword.Parent == workspace then
					sword.Parent = player:WaitForChild("Backpack")
				end
			end)
		end
		print("[ARG] Sword colocada")
	else
		warn("[ARG] No hay Sword en ServerStorage")
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BloodSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 1, -20)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(100, 0, 0)
	spawn.Parent = blood
	local lp = Instance.new("Part")
	lp.Size = Vector3.new(1, 1, 1)
	lp.Position = Vector3.new(0, 12, 0)
	lp.Anchored = true
	lp.Transparency = 1
	lp.CanCollide = false
	lp.Parent = blood
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 30, 30)
	pl.Brightness = 2
	pl.Range = 50
	pl.Parent = lp
	return blood
end

local function ensureEddInBloodWorld(blood)
	-- Edd belongs to the reveal map, not the classic map. Reuse a placed NPC if one exists.
	local edd = blood:FindFirstChild(MapConfig.ARG.EddName) or workspace:FindFirstChild(MapConfig.ARG.EddName, true)
	local target = Vector3.new(8, 1, -8)
	if edd then
		edd.Parent = blood
		if edd:IsA("Model") then
			pcall(function() edd:PivotTo(CFrame.new(target)) end)
		elseif edd:IsA("BasePart") then
			edd.CFrame = CFrame.new(target + Vector3.new(0, 2, 0))
		end
		return edd
	end

	-- Keep the ARG playable even when the place has no manually inserted Edd NPC.
	local model = Instance.new("Model")
	model.Name = MapConfig.ARG.EddName
	local function makePart(name, size, offset, color, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = target + offset
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.SmoothPlastic
		part.Color = color
		if shape then part.Shape = shape end
		part.Parent = model
		return part
	end
	local dark = Color3.fromRGB(35, 35, 40)
	local root = makePart("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 2, 0), dark)
	root.Transparency = 1
	local torso = makePart("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 2, 0), dark)
	local head = makePart("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 3.6, 0), Color3.fromRGB(190, 177, 150), Enum.PartType.Block)
	makePart("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 2, 0), dark)
	makePart("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 2, 0), dark)
	makePart("Left Leg", Vector3.new(1, 1.5, 1), Vector3.new(-0.5, 0.25, 0), Color3.fromRGB(20, 20, 25))
	makePart("Right Leg", Vector3.new(1, 1.5, 1), Vector3.new(0.5, 0.25, 0), Color3.fromRGB(20, 20, 25))
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = "Edd"
	humanoid.RequiresNeck = false
	humanoid.Parent = model
	model.PrimaryPart = root
	model.Parent = blood
	return model
end

local function setupEddDialogue()
	local edd = workspace:FindFirstChild(MapConfig.ARG.EddName)
	if not edd then warn("[ARG] Coloca un NPC llamado Edd en Workspace") return end
	local part = edd:IsA("BasePart") and edd or edd:FindFirstChild("HumanoidRootPart", true) or edd:FindFirstChild("Head", true) or edd:FindFirstChildWhichIsA("BasePart", true)
	if not part or not part:IsA("BasePart") then return end
	for _, c in ipairs(part:GetChildren()) do if c:IsA("ProximityPrompt") then c:Destroy() end end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EddDialoguePrompt"
	prompt.ActionText = "Hablar"
	prompt.ObjectText = "Edd"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Enabled = true
	prompt.ClickablePrompt = true
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		if stage == "blood" then
			messageAll("Edd: You found the truth. I killed everyone in Robloxia. I could not let them leave.", 5)
			task.delay(5, function() messageAll("Edd: 2009 was supposed to last forever. Now you know why this place is empty.", 4) end)
		else
			if not eddFriendlySaid[player.UserId] then
				eddFriendlySaid[player.UserId] = true
				messageAll("Edd: Hey... I used to have a family here.", 4)
				task.delay(4, function() messageAll("Edd: I miss them. And the other residents too...", 4) end)
				task.delay(8, function() messageAll("Edd: Robloxia was happier in 2009. Don't you think?", 4) end)
			else
				messageAll("Edd: If you find anything strange... maybe leave it alone.", 4)
			end
		end
	end)
	print("[ARG] Edd listo")
end

function ARGSystem.OnHatchUsed(player)
	if stage ~= "classic" then return end
	print("[ARG] Hatch: " .. player.Name)
	stage = "pcroom"
	setPCRoomLighting()
	createPCRoom()
	teleportPlayer(player, Vector3.new(0, 201, 10))
	messageAll("The air feels wrong...", 3)
	task.delay(3, function() messageAll("There is a computer here.", 3) end)
end

function ARGSystem.OnPCUsed(player)
	if stage ~= "pcroom" then return end
	playerCodesShown[player.UserId] = true
	local code = MapConfig.ARG.SecretCode
	messageAll("PC: FILES CORRUPTED - 2009 ARCHIVE", 4)
	task.delay(4, function() messageAll("PC: Access code: " .. code, 6) end)
	task.delay(10, function() messageAll("Type the code in chat to continue...", 5) end)
end

function ARGSystem.TryCode(player, message)
	if stage ~= "pcroom" then return false end
	if not playerCodesShown[player.UserId] then return false end
	local cleaned = string.gsub(string.upper(message), "%s+", "")
	local code = string.gsub(string.upper(MapConfig.ARG.SecretCode), "%s+", "")
	if cleaned ~= code then return false end
	print("[ARG] Codigo OK: " .. player.Name)
	stage = "blood"
	messageAll("Code accepted. Loading...", 2)
	if classicRoot and classicRoot.Parent then classicRoot:Destroy() end
	local pcroom = workspace:FindFirstChild(MapConfig.ARG.PCRoomName)
	if pcroom then pcroom:Destroy() end
	setBloodLighting()
	local blood = createBloodWorld()
	ensureEddInBloodWorld(blood)
	setupEddDialogue()
	task.wait(MapConfig.ARG.ResetDelay)
	player:LoadCharacter()
	task.delay(1.5, function()
		teleportPlayer(player, Vector3.new(0, 3, -20))
		messageAll("Something is wrong with Robloxia...", 4)
	end)
	task.delay(6, function() messageAll("Talk to Edd. Find the Sword.", 5) end)
	return true
end

function ARGSystem.Setup(classicMapRoot)
	ProximityPromptService.Enabled = true
	classicRoot = classicMapRoot
	stage = "classic"
	setClassicLighting()
	local function attachHatch(part)
		if not part:IsA("BasePart") then return end
		if part.Name == "Hatch" then
			if not part:FindFirstChildOfClass("ProximityPrompt") then
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "BasementInteractionPrompt"
				prompt.ActionText = "Entrar"
				prompt.ObjectText = "Sótano"
				prompt.KeyboardKeyCode = Enum.KeyCode.E
				prompt.HoldDuration = 0
				prompt.MaxActivationDistance = 16
				prompt.Style = Enum.ProximityPromptStyle.Default
				prompt.Enabled = true
				prompt.ClickablePrompt = true
				prompt.RequiresLineOfSight = false
				prompt.Parent = part
				prompt.Triggered:Connect(function(player) ARGSystem.OnHatchUsed(player) end)
			end
		end
	end
	for _, d in ipairs(classicMapRoot:GetDescendants()) do attachHatch(d) end
	classicMapRoot.DescendantAdded:Connect(attachHatch)
	local function hookChat(player)
		player.Chatted:Connect(function(msg) ARGSystem.TryCode(player, msg) end)
	end
	Players.PlayerAdded:Connect(hookChat)
	for _, p in ipairs(Players:GetPlayers()) do hookChat(p) end
	print("[ARG] Multi-etapa listo (classic -> pc -> blood)")
end

function ARGSystem.GetStage()
	return stage
end

return ARGSystem
