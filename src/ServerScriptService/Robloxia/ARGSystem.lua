--[[
	ARGSystem.lua
	Giro narrativo: al pasar por la puerta del sótano secreto
	el jugador "se reinicia" y el mundo cambia a una versión rota / ARG.
	Todo por código, sin UI compleja.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local MapConfig = require(script.Parent.MapConfig)

local ARGSystem = {}
local activated = false
local classicRoot = nil

local function setClassicLighting()
	Lighting.Ambient = Color3.fromRGB(140, 140, 140)
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	Lighting.FogColor = Color3.fromRGB(192, 192, 192)
	Lighting.FogEnd = 100000
	Lighting.ClockTime = 14
end

local function setARGLighting()
	Lighting.Ambient = MapConfig.ARG.AtmosphereColor
	Lighting.Brightness = 0.6
	Lighting.OutdoorAmbient = Color3.fromRGB(40, 20, 20)
	Lighting.FogColor = MapConfig.ARG.FogColor
	Lighting.FogEnd = MapConfig.ARG.FogEnd
	Lighting.ClockTime = 2 -- noche
end

local function createBrokenWorld(parent)
	local broken = Instance.new("Model")
	broken.Name = MapConfig.ARG.NewMapName
	broken.Parent = parent

	-- Base oscura
	local base = Instance.new("Part")
	base.Name = "BrokenBase"
	base.Size = Vector3.new(400, 1, 400)
	base.Position = Vector3.new(0, -0.5, 0)
	base.Anchored = true
	base.Color = Color3.fromRGB(25, 20, 20)
	base.Material = Enum.Material.Asphalt
	base.TopSurface = Enum.SurfaceType.Smooth
	base.Parent = broken

	-- Casa distorsionada (solo una, rota)
	local function makeBrokenPart(name, size, pos, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = pos
		p.Anchored = true
		p.Color = color or Color3.fromRGB(60, 40, 40)
		p.Material = Enum.Material.Wood
		p.Parent = broken
		return p
	end

	makeBrokenPart("BrokenHouseFloor", Vector3.new(20, 1, 16), Vector3.new(0, 0.5, 0))
	makeBrokenPart("BrokenWallF", Vector3.new(20, 10, 1), Vector3.new(0, 5.5, -8), Color3.fromRGB(80, 50, 40))
	makeBrokenPart("BrokenWallB", Vector3.new(20, 10, 1), Vector3.new(0, 5.5, 8), Color3.fromRGB(80, 50, 40))
	makeBrokenPart("BrokenWallL", Vector3.new(1, 10, 16), Vector3.new(-10, 5.5, 0), Color3.fromRGB(70, 40, 35))
	makeBrokenPart("BrokenWallR", Vector3.new(1, 10, 16), Vector3.new(10, 5.5, 0), Color3.fromRGB(70, 40, 35))
	makeBrokenPart("BrokenRoof", Vector3.new(22, 1, 18), Vector3.new(0, 11, 0), Color3.fromRGB(90, 20, 20))

	-- Carteles glitched
	local function makeGlitchSign(text, pos)
		local board = Instance.new("Part")
		board.Size = Vector3.new(10, 4, 0.5)
		board.Position = pos
		board.Anchored = true
		board.Color = Color3.fromRGB(10, 10, 10)
		board.Material = Enum.Material.SmoothPlastic
		board.Parent = broken

		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.Parent = board

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(255, 60, 60)
		label.TextScaled = true
		label.Font = Enum.Font.Code
		label.Parent = gui
	end

	makeGlitchSign("WELCOME TO ROBLOXIA?", Vector3.new(0, 8, -15))
	makeGlitchSign("HAVE FUN?", Vector3.new(-20, 6, 10))
	makeGlitchSign("THE BRICKS ARE GONE", Vector3.new(20, 6, 10))
	makeGlitchSign("YOU SHOULDN'T BE HERE", Vector3.new(0, 5, 20))
	makeGlitchSign("2009 NEVER ENDED", Vector3.new(0, 12, 0))

	-- Pilares rotos / escombros
	for i = 1, 15 do
		local r = Instance.new("Part")
		r.Size = Vector3.new(math.random(2, 6), math.random(1, 4), math.random(2, 5))
		r.Position = Vector3.new(math.random(-80, 80), r.Size.Y / 2, math.random(-80, 80))
		r.Anchored = true
		r.Color = Color3.fromRGB(40 + math.random(0, 30), 30, 25)
		r.Material = Enum.Material.Concrete
		r.Orientation = Vector3.new(math.random(-20, 20), math.random(0, 360), math.random(-15, 15))
		r.Parent = broken
	end

	-- Spawn ARG
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ARG_Spawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 1, -25)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(120, 0, 0)
	spawn.Parent = broken

	-- Luz roja central
	local lightPart = Instance.new("Part")
	lightPart.Size = Vector3.new(1, 1, 1)
	lightPart.Position = Vector3.new(0, 15, 0)
	lightPart.Anchored = true
	lightPart.Transparency = 1
	lightPart.CanCollide = false
	lightPart.Parent = broken
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 40, 40)
	pl.Brightness = 2
	pl.Range = 60
	pl.Parent = lightPart

	return broken
end

function ARGSystem.Activate(player: Player)
	if activated then return end
	activated = true

	print("[ARG] Activado por " .. player.Name)

	-- Feedback inmediato
	local character = player.Character
	if character and character:FindFirstChild("Humanoid") then
		local hum = character.Humanoid
		hum.WalkSpeed = 0
		task.wait(0.3)
	end

	-- Destruir mapa clásico
	if classicRoot and classicRoot.Parent then
		classicRoot:Destroy()
	end

	-- Cambiar iluminación
	setARGLighting()

	-- Crear mundo roto
	local broken = createBrokenWorld(workspace)

	-- Resetear al jugador
	task.wait(MapConfig.ARG.ResetDelay)
	player:LoadCharacter()

	-- Mensaje en chat (simple)
	task.delay(1, function()
		local msg = Instance.new("Message")
		msg.Text = "Something is wrong with Robloxia..."
		msg.Parent = workspace
		task.wait(4)
		msg:Destroy()
	end)

	task.delay(8, function()
		local msg2 = Instance.new("Message")
		msg2.Text = "2009 never ended."
		msg2.Parent = workspace
		task.wait(5)
		msg2:Destroy()
	end)
end

function ARGSystem.Setup(classicMapRoot)
	classicRoot = classicMapRoot
	setClassicLighting()

	local function onTouched(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player and not activated then
			if hit:GetAttribute("IsARGTrigger") then
				ARGSystem.Activate(player)
			end
		end
	end

	local function connectDoors(parent)
		for _, desc in ipairs(parent:GetDescendants()) do
			if desc:IsA("BasePart") and desc:GetAttribute("IsARGTrigger") then
				desc.Touched:Connect(onTouched)
			end
		end
	end

	connectDoors(classicMapRoot)

	classicMapRoot.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") and desc:GetAttribute("IsARGTrigger") then
			desc.Touched:Connect(onTouched)
		end
	end)
end

function ARGSystem.IsActivated()
	return activated
end

return ARGSystem
