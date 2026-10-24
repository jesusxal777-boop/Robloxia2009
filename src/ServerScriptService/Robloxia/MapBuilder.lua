--[[
	MapBuilder.lua
	Construye todo el mapa de forma procedural (estilo 2009).
	Usa AssetRegistry cuando es posible, siempre tiene fallback.
]]

local MapConfig = require(script.Parent.MapConfig)
local AssetRegistry = require(script.Parent.AssetRegistry)

local MapBuilder = {}

local function makePart(props)
	local p = Instance.new("Part")
	p.Name = props.Name or "Part"
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.Position = props.Position or Vector3.new(0, 0, 0)
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or MapConfig.Materials.Default
	p.Color = props.Color or Color3.new(1, 1, 1)
	p.TopSurface = props.TopSurface or Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Studs
	if props.Parent then p.Parent = props.Parent end
	return p
end

local function makeModel(name, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function makeSign(text, position, size, parent)
	local sign = makeModel("Sign_" .. text:sub(1, 12), parent)
	local board = makePart({
		Name = "Board",
		Size = size or Vector3.new(8, 4, 0.5),
		Position = position,
		Color = MapConfig.Colors.SignBG,
		Material = Enum.Material.SmoothPlastic,
		TopSurface = Enum.SurfaceType.Smooth,
		Parent = sign,
	})
	makePart({
		Name = "Post",
		Size = Vector3.new(0.6, 6, 0.6),
		Position = position - Vector3.new(0, 5, 0),
		Color = MapConfig.Colors.Wood,
		Material = MapConfig.Materials.Wood,
		Parent = sign,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(400, 200)
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = MapConfig.Colors.SignText
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	local gui2 = gui:Clone()
	gui2.Face = Enum.NormalId.Back
	gui2.Parent = board
	return sign
end

local function makeTree(position, parent)
	local tree = makeModel("Tree", parent)
	makePart({
		Name = "Trunk",
		Size = Vector3.new(1.5, 6, 1.5),
		Position = position + Vector3.new(0, 3, 0),
		Color = MapConfig.Colors.Wood,
		Material = MapConfig.Materials.Wood,
		Parent = tree,
	})
	local leafColor = Color3.fromRGB(40, 127, 71)
	for i = 1, 3 do
		makePart({
			Name = "Leaves" .. i,
			Size = Vector3.new(5 - i, 2, 5 - i),
			Position = position + Vector3.new(0, 6 + i * 1.4, 0),
			Color = leafColor,
			Material = Enum.Material.Plastic,
			TopSurface = Enum.SurfaceType.Studs,
			Parent = tree,
		})
	end
	return tree
end

function MapBuilder.CreateBaseAndPlaza(root)
	local terrainFolder = makeModel("Terrain", root)
	local roads = makeModel("Roads", root)
	local plaza = makeModel("Plaza", root)
	makePart({
		Name = "Baseplate",
		Size = MapConfig.Layout.BaseSize,
		Position = Vector3.new(0, -0.5, 0),
		Color = MapConfig.Colors.Baseplate,
		Material = Enum.Material.Grass,
		TopSurface = Enum.SurfaceType.Studs,
		Parent = terrainFolder,
	})
	makePart({
		Name = "PlazaFloor",
		Size = Vector3.new(40, 1, 40),
		Position = MapConfig.Layout.PlazaCenter,
		Color = MapConfig.Colors.Path,
		Material = MapConfig.Materials.Concrete,
		TopSurface = Enum.SurfaceType.Studs,
		Parent = plaza,
	})
	local pathData = {
		{ Size = Vector3.new(12, 1, 80), Pos = Vector3.new(0, 0, 50) },
		{ Size = Vector3.new(12, 1, 60), Pos = Vector3.new(0, 0, -40) },
		{ Size = Vector3.new(100, 1, 10), Pos = Vector3.new(-50, 0, 20) },
		{ Size = Vector3.new(100, 1, 10), Pos = Vector3.new(50, 0, 20) },
	}
	for i, d in ipairs(pathData) do
		makePart({
			Name = "Path" .. i,
			Size = d.Size,
			Position = d.Pos,
			Color = MapConfig.Colors.Path,
			Material = MapConfig.Materials.Concrete,
			Parent = roads,
		})
	end
	makeSign("WELCOME TO ROBLOXIA!", MapConfig.Layout.PlazaCenter + Vector3.new(0, 8, -18), Vector3.new(16, 6, 1), plaza)
	for i = -1, 1, 2 do
		makePart({
			Name = "Bench",
			Size = Vector3.new(6, 1, 2),
			Position = MapConfig.Layout.PlazaCenter + Vector3.new(i * 12, 1, 8),
			Color = MapConfig.Colors.Wood,
			Material = MapConfig.Materials.Wood,
			Parent = plaza,
		})
		local lamp = makeModel("Lamp", plaza)
		makePart({ Name = "Pole", Size = Vector3.new(0.5, 10, 0.5), Position = MapConfig.Layout.PlazaCenter + Vector3.new(i * 14, 5, -8), Color = Color3.fromRGB(50, 50, 50), Parent = lamp })
		makePart({ Name = "Light", Size = Vector3.new(2, 1, 2), Position = MapConfig.Layout.PlazaCenter + Vector3.new(i * 14, 10.5, -8), Color = Color3.fromRGB(255, 255, 150), Material = Enum.Material.Neon, Parent = lamp })
	end
	for _, offset in ipairs({ Vector3.new(-15, 0, 15), Vector3.new(15, 0, 15), Vector3.new(-15, 0, -10), Vector3.new(15, 0, -10) }) do
		makeTree(MapConfig.Layout.PlazaCenter + offset, plaza)
	end
	return plaza
end

function MapBuilder.CreateHappyHome(root)
	local folder = makeModel("HappyHome", root)
	local pos = MapConfig.Layout.HappyHomePos
	local assetModel, status = AssetRegistry.TryHappyHome(folder)
	if assetModel then
		print("[MapBuilder] Happy Home cargado desde asset (" .. status .. ")")
	else
		print("[MapBuilder] Usando casa procedural clásica")
		makePart({ Name = "Floor", Size = Vector3.new(28, 1, 20), Position = pos + Vector3.new(0, 0.5, 0), Color = Color3.fromRGB(140, 140, 140), Parent = folder })
		local wallH = 10
		local walls = {
			{ Size = Vector3.new(28, wallH, 1), Pos = pos + Vector3.new(0, wallH/2 + 0.5, -10) },
			{ Size = Vector3.new(28, wallH, 1), Pos = pos + Vector3.new(0, wallH/2 + 0.5, 10) },
			{ Size = Vector3.new(1, wallH, 20), Pos = pos + Vector3.new(-14, wallH/2 + 0.5, 0) },
			{ Size = Vector3.new(1, wallH, 20), Pos = pos + Vector3.new(14, wallH/2 + 0.5, 0) },
		}
		for i, w in ipairs(walls) do
			makePart({ Name = "Wall" .. i, Size = w.Size, Position = w.Pos, Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		end
		makePart({ Name = "RoofL", Size = Vector3.new(30, 1, 14), Position = pos + Vector3.new(0, 12, -5), Color = MapConfig.Colors.HouseRoof, Material = Enum.Material.Plastic, Parent = folder })
		makePart({ Name = "RoofR", Size = Vector3.new(30, 1, 14), Position = pos + Vector3.new(0, 12, 5), Color = MapConfig.Colors.HouseRoof, Material = Enum.Material.Plastic, Parent = folder })
		makePart({ Name = "Chimney", Size = Vector3.new(3, 5, 3), Position = pos + Vector3.new(8, 15, 0), Color = Color3.fromRGB(120, 80, 60), Parent = folder })
		makePart({ Name = "Door", Size = Vector3.new(4, 7, 0.4), Position = pos + Vector3.new(0, 4, -10.3), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = folder })
		for _, wx in ipairs({ -8, 8 }) do
			makePart({ Name = "Window", Size = Vector3.new(4, 4, 0.3), Position = pos + Vector3.new(wx, 6, -10.2), Color = Color3.fromRGB(180, 220, 255), Material = Enum.Material.Glass, Parent = folder })
			makePart({ Name = "WindowBack", Size = Vector3.new(4, 4, 0.3), Position = pos + Vector3.new(wx, 6, 10.2), Color = Color3.fromRGB(180, 220, 255), Material = Enum.Material.Glass, Parent = folder })
		end
		makePart({ Name = "Steps", Size = Vector3.new(6, 1, 3), Position = pos + Vector3.new(0, 0.5, -12), Color = Color3.fromRGB(160, 160, 160), Parent = folder })
		makePart({ Name = "Garden", Size = Vector3.new(36, 0.5, 10), Position = pos + Vector3.new(0, 0.25, -16), Color = Color3.fromRGB(80, 140, 60), Material = Enum.Material.Grass, Parent = folder })
	end
	makeSign("HAPPY HOME", pos + Vector3.new(0, 4, -22), Vector3.new(10, 4, 1), folder)
	return folder
end

function MapBuilder.CreateConstructionYard(root)
	local folder = makeModel("ConstructionYard", root)
	local pos = MapConfig.Layout.ConstructionYardPos
	makePart({
		Name = "YardFloor",
		Size = Vector3.new(50, 1, 40),
		Position = pos,
		Color = Color3.fromRGB(120, 120, 100),
		Material = Enum.Material.Concrete,
		TopSurface = Enum.SurfaceType.Studs,
		Parent = folder,
	})
	local colors = {
		MapConfig.Colors.BrickYellow, MapConfig.Colors.BrickRed, MapConfig.Colors.BrickBlue,
		MapConfig.Colors.BrickGreen, MapConfig.Colors.BrickOrange,
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(27, 42, 53),
	}
	local brickSizes = {
		Vector3.new(4, 1, 2), Vector3.new(2, 1, 4), Vector3.new(4, 2, 2),
		Vector3.new(1, 1, 1), Vector3.new(8, 1, 2),
	}
	for i = 1, 7 do
		local pilePos = pos + Vector3.new(-18 + i * 6, 1, -10)
		for j = 1, 8 do
			local sz = brickSizes[((i + j) % #brickSizes) + 1]
			makePart({
				Name = "Brick_" .. i .. "_" .. j,
				Size = sz,
				Position = pilePos + Vector3.new(0, j * 1.1, (j % 3) - 1),
				Color = colors[i],
				Material = Enum.Material.Plastic,
				TopSurface = Enum.SurfaceType.Studs,
				Parent = folder,
			})
		end
	end
	for x = -1, 1 do
		for y = 1, 4 do
			makePart({
				Name = "ExampleWall",
				Size = Vector3.new(4, 2, 2),
				Position = pos + Vector3.new(x * 4, y * 2, 12),
				Color = MapConfig.Colors.BrickYellow,
				Parent = folder,
			})
		end
	end
	makeSign("FREE BRICKS", pos + Vector3.new(0, 6, -18), Vector3.new(12, 5, 1), folder)
	makeSign("BUILD HERE", pos + Vector3.new(15, 5, 0), Vector3.new(8, 4, 1), folder)
	makeSign("HAVE FUN!", pos + Vector3.new(-15, 5, 0), Vector3.new(8, 4, 1), folder)
	return folder
end

function MapBuilder.CreateRoleplayDistrict(root)
	local folder = makeModel("RoleplayDistrict", root)
	local base = MapConfig.Layout.RoleplayDistrictPos
	local houseColors = {
		MapConfig.Colors.HouseWall, Color3.fromRGB(180, 160, 140),
		Color3.fromRGB(200, 180, 160), Color3.fromRGB(160, 140, 120),
		Color3.fromRGB(190, 170, 150),
	}
	for i = 1, 5 do
		local hx = base.X + (i - 3) * 28
		local hz = base.Z
		local house = makeModel("House_" .. i, folder)
		local isSecret = (i == MapConfig.Layout.SecretHouseIndex)
		makePart({ Name = "Floor", Size = Vector3.new(16, 1, 14), Position = Vector3.new(hx, 0.5, hz), Color = Color3.fromRGB(140, 140, 140), Parent = house })
		local wh = 8
		makePart({ Name = "Front", Size = Vector3.new(16, wh, 1), Position = Vector3.new(hx, wh/2 + 0.5, hz - 7), Color = houseColors[i], Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Back", Size = Vector3.new(16, wh, 1), Position = Vector3.new(hx, wh/2 + 0.5, hz + 7), Color = houseColors[i], Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Left", Size = Vector3.new(1, wh, 14), Position = Vector3.new(hx - 8, wh/2 + 0.5, hz), Color = houseColors[i], Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Right", Size = Vector3.new(1, wh, 14), Position = Vector3.new(hx + 8, wh/2 + 0.5, hz), Color = houseColors[i], Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Roof", Size = Vector3.new(18, 1, 16), Position = Vector3.new(hx, 9.5, hz), Color = MapConfig.Colors.HouseRoof, Parent = house })
		makePart({ Name = "Door", Size = Vector3.new(3, 6, 0.4), Position = Vector3.new(hx, 3.5, hz - 7.3), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = house })
		makePart({ Name = "WinL", Size = Vector3.new(3, 3, 0.3), Position = Vector3.new(hx - 5, 5, hz - 7.2), Color = Color3.fromRGB(170, 210, 255), Material = Enum.Material.Glass, Parent = house })
		makePart({ Name = "WinR", Size = Vector3.new(3, 3, 0.3), Position = Vector3.new(hx + 5, 5, hz - 7.2), Color = Color3.fromRGB(170, 210, 255), Material = Enum.Material.Glass, Parent = house })
		if isSecret then
			local basement = makeModel("SecretBasement", house)
			for s = 1, 6 do
				makePart({
					Name = "Stair" .. s,
					Size = Vector3.new(4, 1, 2),
					Position = Vector3.new(hx, -s * 1.2, hz + 2 + s * 1.5),
					Color = Color3.fromRGB(80, 80, 80),
					Parent = basement,
				})
			end
			makePart({ Name = "BasementFloor", Size = Vector3.new(14, 1, 12), Position = Vector3.new(hx, -8, hz + 10), Color = Color3.fromRGB(60, 60, 60), Parent = basement })
			makePart({ Name = "BasementWallF", Size = Vector3.new(14, 7, 1), Position = Vector3.new(hx, -5, hz + 4), Color = Color3.fromRGB(50, 50, 50), Parent = basement })
			makePart({ Name = "BasementWallB", Size = Vector3.new(14, 7, 1), Position = Vector3.new(hx, -5, hz + 16), Color = Color3.fromRGB(50, 50, 50), Parent = basement })
			makePart({ Name = "BasementWallL", Size = Vector3.new(1, 7, 12), Position = Vector3.new(hx - 7, -5, hz + 10), Color = Color3.fromRGB(50, 50, 50), Parent = basement })
			makePart({ Name = "BasementWallR", Size = Vector3.new(1, 7, 12), Position = Vector3.new(hx + 7, -5, hz + 10), Color = Color3.fromRGB(50, 50, 50), Parent = basement })
			local argDoor = makePart({
				Name = "ARG_Door",
				Size = Vector3.new(4, 6, 0.5),
				Position = Vector3.new(hx, -5, hz + 16.3),
				Color = Color3.fromRGB(20, 20, 20),
				Material = Enum.Material.Metal,
				Parent = basement,
			})
			argDoor:SetAttribute("IsARGTrigger", true)
			makeSign("DO NOT ENTER", Vector3.new(hx, -2, hz + 15), Vector3.new(5, 2, 0.4), basement)
			local light = Instance.new("PointLight")
			light.Brightness = 0.4
			light.Color = Color3.fromRGB(255, 100, 80)
			light.Range = 12
			light.Parent = argDoor
		end
	end
	makePart({
		Name = "Street",
		Size = Vector3.new(140, 1, 10),
		Position = base + Vector3.new(0, 0, -12),
		Color = MapConfig.Colors.Path,
		Material = MapConfig.Materials.Concrete,
		Parent = folder,
	})
	makeSign("VISIT THE TOWN", base + Vector3.new(0, 5, -20), Vector3.new(12, 4, 1), folder)
	local park = makeModel("Park", folder)
	makePart({ Name = "ParkFloor", Size = Vector3.new(30, 1, 20), Position = base + Vector3.new(60, 0, 30), Color = Color3.fromRGB(70, 130, 60), Material = Enum.Material.Grass, Parent = park })
	for i = 1, 4 do
		makeTree(base + Vector3.new(50 + i * 6, 0, 30), park)
	end
	return folder
end

function MapBuilder.CreateObby(root)
	local folder = makeModel("Obby", root)
	local start = MapConfig.Layout.ObbyStart
	makeSign("OBBY →", start + Vector3.new(0, 6, -10), Vector3.new(8, 4, 1), folder)
	local platforms = {
		{ Pos = start, Size = Vector3.new(8, 1, 8), Color = Color3.fromRGB(0, 170, 0) },
		{ Pos = start + Vector3.new(12, 2, 0), Size = Vector3.new(4, 1, 4), Color = Color3.fromRGB(0, 120, 200) },
		{ Pos = start + Vector3.new(20, 4, 4), Size = Vector3.new(3, 1, 3), Color = Color3.fromRGB(255, 170, 0) },
		{ Pos = start + Vector3.new(28, 6, -2), Size = Vector3.new(3, 1, 3), Color = Color3.fromRGB(200, 50, 50) },
		{ Pos = start + Vector3.new(36, 8, 3), Size = Vector3.new(2.5, 1, 2.5), Color = Color3.fromRGB(170, 0, 170) },
		{ Pos = start + Vector3.new(44, 10, 0), Size = Vector3.new(2, 1, 6), Color = Color3.fromRGB(100, 100, 100) },
		{ Pos = start + Vector3.new(52, 12, 0), Size = Vector3.new(4, 1, 4), Color = Color3.fromRGB(0, 200, 100) },
		{ Pos = start + Vector3.new(60, 14, 5), Size = Vector3.new(3, 1, 3), Color = Color3.fromRGB(255, 100, 0) },
		{ Pos = start + Vector3.new(68, 16, 0), Size = Vector3.new(6, 1, 6), Color = Color3.fromRGB(0, 255, 100) },
	}
	for i, p in ipairs(platforms) do
		local part = makePart({
			Name = "Platform_" .. i,
			Size = p.Size,
			Position = p.Pos,
			Color = p.Color,
			Material = Enum.Material.Plastic,
			TopSurface = Enum.SurfaceType.Studs,
			Parent = folder,
		})
		if i == 1 then part:SetAttribute("Checkpoint", 1)
		elseif i == #platforms then
			part:SetAttribute("IsFinish", true)
			makeSign("FINISH!", p.Pos + Vector3.new(0, 5, 0), Vector3.new(6, 3, 1), folder)
		end
	end
	for i = 1, 3 do
		local kill = makePart({
			Name = "KillBrick_" .. i,
			Size = Vector3.new(6, 1, 6),
			Position = start + Vector3.new(20 + i * 12, 1, -10),
			Color = MapConfig.Colors.Danger,
			Material = Enum.Material.Neon,
			Parent = folder,
		})
		kill:SetAttribute("IsKillBrick", true)
	end
	return folder
end

function MapBuilder.CreateNature(root)
	local folder = makeModel("Nature", root)
	local pos = MapConfig.Layout.NaturePos
	makePart({
		Name = "Lake",
		Size = Vector3.new(40, 2, 30),
		Position = pos + Vector3.new(0, -0.5, 0),
		Color = MapConfig.Colors.Water,
		Material = Enum.Material.Water,
		CanCollide = false,
		Parent = folder,
	})
	for i = 1, 8 do
		makePart({
			Name = "BridgePlank" .. i,
			Size = Vector3.new(4, 0.6, 2),
			Position = pos + Vector3.new(-16 + i * 4, 1, 0),
			Color = MapConfig.Colors.Wood,
			Material = MapConfig.Materials.Wood,
			Parent = folder,
		})
	end
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local r = 28 + (i % 3)
		makeTree(pos + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r), folder)
	end
	makePart({ Name = "Bench1", Size = Vector3.new(5, 1, 2), Position = pos + Vector3.new(-20, 1, 20), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = folder })
	return folder
end

function MapBuilder.CreateSpawnAndSecrets(root)
	local spawnFolder = makeModel("SpawnPoints", root)
	local secrets = makeModel("Secrets", root)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = MapConfig.Layout.Spawn
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(0, 200, 0)
	spawn.Material = Enum.Material.Plastic
	spawn.TopSurface = Enum.SurfaceType.Studs
	spawn.Parent = spawnFolder
	local lookout = makeModel("Lookout", secrets)
	for i = 1, 5 do
		makePart({
			Name = "Tower" .. i,
			Size = Vector3.new(4, 3, 4),
			Position = Vector3.new(180, i * 3, -80),
			Color = Color3.fromRGB(140, 100, 60),
			Material = MapConfig.Materials.Wood,
			Parent = lookout,
		})
	end
	makePart({ Name = "Platform", Size = Vector3.new(10, 1, 10), Position = Vector3.new(180, 16, -80), Color = Color3.fromRGB(160, 120, 80), Parent = lookout })
	makeSign("SECRET VIEW", Vector3.new(180, 18, -80), Vector3.new(6, 2, 1), lookout)
	return spawnFolder, secrets
end

function MapBuilder.BuildFullMap(parent)
	local root = makeModel(MapConfig.MapName, parent or workspace)
	print("[MapBuilder] Generando Robloxia 2009...")
	MapBuilder.CreateBaseAndPlaza(root)
	MapBuilder.CreateHappyHome(root)
	MapBuilder.CreateConstructionYard(root)
	MapBuilder.CreateRoleplayDistrict(root)
	MapBuilder.CreateObby(root)
	MapBuilder.CreateNature(root)
	MapBuilder.CreateSpawnAndSecrets(root)
	print("[MapBuilder] Mapa clásico generado correctamente.")
	return root
end

return MapBuilder
