--[[
	MapBuilder.lua  v0.3
	ServerStorage: "Bloxy Cola Vending" y "Bloxy"
	Puertas sin colision, casa sotano marcada, maquinas fuera de puertas
]]

local MapConfig = require(script.Parent.MapConfig)
local AssetRegistry = require(script.Parent.AssetRegistry)
local ServerStorage = game:GetService("ServerStorage")

local MapBuilder = {}

local function makePart(props)
	local p = Instance.new("Part")
	p.Name = props.Name or "Part"
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.Position = props.Position or Vector3.new(0, 0, 0)
	p.Anchored = props.Anchored ~= false
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or MapConfig.Materials.Default
	p.Color = props.Color or Color3.new(1, 1, 1)
	p.TopSurface = props.TopSurface or Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Studs
	if props.Transparency then p.Transparency = props.Transparency end
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
	local sign = makeModel("Sign_" .. text:sub(1, 10):gsub("%s", "_"), parent)
	local board = makePart({ Name = "Board", Size = size or Vector3.new(8, 4, 0.5), Position = position, Color = MapConfig.Colors.SignBG, Material = Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth, Parent = sign })
	makePart({ Name = "Post", Size = Vector3.new(0.6, 5, 0.6), Position = position - Vector3.new(0, 4.5, 0), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = sign })
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
	makePart({ Name = "Trunk", Size = Vector3.new(1.4, 5.5, 1.4), Position = position + Vector3.new(0, 2.75, 0), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = tree })
	local leafColor = Color3.fromRGB(40, 127, 71)
	for i = 1, 3 do
		makePart({ Name = "Leaves" .. i, Size = Vector3.new(5 - i * 0.8, 1.8, 5 - i * 0.8), Position = position + Vector3.new(0, 5.5 + i * 1.3, 0), Color = leafColor, Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Parent = tree })
	end
	return tree
end

local function makeChair(position, parent)
	local chair = makeModel("Chair", parent)
	makePart({ Name = "Seat", Size = Vector3.new(2.2, 0.4, 2.2), Position = position + Vector3.new(0, 1.2, 0), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = chair })
	makePart({ Name = "Back", Size = Vector3.new(2.2, 2.2, 0.35), Position = position + Vector3.new(0, 2.3, -0.95), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = chair })
	for _, off in ipairs({ Vector3.new(-0.8, 0.5, -0.8), Vector3.new(0.8, 0.5, -0.8), Vector3.new(-0.8, 0.5, 0.8), Vector3.new(0.8, 0.5, 0.8) }) do
		makePart({ Name = "Leg", Size = Vector3.new(0.3, 1, 0.3), Position = position + off, Color = Color3.fromRGB(90, 70, 50), Material = MapConfig.Materials.Wood, Parent = chair })
	end
	return chair
end

local function makeTable(position, parent, size)
	local tbl = makeModel("Table", parent)
	size = size or Vector3.new(5, 0.4, 3)
	makePart({ Name = "Top", Size = size, Position = position + Vector3.new(0, 2.2, 0), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = tbl })
	for _, off in ipairs({ Vector3.new(-size.X/2 + 0.4, 1, -size.Z/2 + 0.4), Vector3.new(size.X/2 - 0.4, 1, -size.Z/2 + 0.4), Vector3.new(-size.X/2 + 0.4, 1, size.Z/2 - 0.4), Vector3.new(size.X/2 - 0.4, 1, size.Z/2 - 0.4) }) do
		makePart({ Name = "Leg", Size = Vector3.new(0.35, 2, 0.35), Position = position + off, Color = Color3.fromRGB(90, 70, 50), Material = MapConfig.Materials.Wood, Parent = tbl })
	end
	return tbl
end

local function cloneFromStorage(name, position, parent)
	local template = ServerStorage:FindFirstChild(name)
	if not template then
		warn("[MapBuilder] No se encontro en ServerStorage: \"" .. name .. "\" -> fallback")
		return nil
	end
	print("[MapBuilder] Usando modelo real: " .. name)
	local clone = template:Clone()
	clone.Parent = parent
	if clone:IsA("Model") then
		local part = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
		if part then
			local offset = position - part.Position
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CFrame = d.CFrame + offset
				end
			end
		end
	elseif clone:IsA("BasePart") then
		clone.Anchored = true
		clone.Position = position
	end
	return clone
end

local function makeBloxyColaMachine(position, parent)
	local real = cloneFromStorage("Bloxy Cola Vending", position, parent)
	if real then return real end
	local machine = makeModel("BloxyColaMachine", parent)
	makePart({ Name = "Body", Size = Vector3.new(3.5, 6, 2.2), Position = position + Vector3.new(0, 3, 0), Color = Color3.fromRGB(180, 40, 40), Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Parent = machine })
	makePart({ Name = "Top", Size = Vector3.new(3.7, 0.6, 2.4), Position = position + Vector3.new(0, 6.3, 0), Color = Color3.fromRGB(220, 50, 50), Material = Enum.Material.Plastic, Parent = machine })
	makePart({ Name = "Glass", Size = Vector3.new(2.8, 3.5, 0.3), Position = position + Vector3.new(0, 3.5, -1.1), Color = Color3.fromRGB(150, 200, 255), Material = Enum.Material.Glass, Transparency = 0.4, Parent = machine })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = machine.Body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.25, 0)
	label.Position = UDim2.new(0, 0, 0.05, 0)
	label.BackgroundTransparency = 1
	label.Text = "BLOXY COLA"
	label.TextColor3 = Color3.fromRGB(255, 220, 0)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return machine
end

local function makeBloxyColaCan(position, parent)
	local real = cloneFromStorage("Bloxy", position, parent)
	if real then return real end
	return makePart({ Name = "BloxyCola", Size = Vector3.new(1, 1.6, 1), Position = position + Vector3.new(0, 0.8, 0), Color = Color3.fromRGB(200, 80, 30), Material = Enum.Material.Plastic, Parent = parent })
end

function MapBuilder.CreateBaseAndPlaza(root)
	local terrainFolder = makeModel("Terrain", root)
	local roads = makeModel("Roads", root)
	local plaza = makeModel("Plaza", root)
	makePart({ Name = "Baseplate", Size = MapConfig.Layout.BaseSize, Position = Vector3.new(0, -0.5, 0), Color = MapConfig.Colors.Baseplate, Material = Enum.Material.Grass, TopSurface = Enum.SurfaceType.Studs, Parent = terrainFolder })
	makePart({ Name = "PlazaFloor", Size = Vector3.new(48, 1, 48), Position = MapConfig.Layout.PlazaCenter, Color = MapConfig.Colors.Path, Material = MapConfig.Materials.Concrete, TopSurface = Enum.SurfaceType.Studs, Parent = plaza })
	local pathData = { { Size = Vector3.new(14, 1, 90), Pos = Vector3.new(0, 0, 55) }, { Size = Vector3.new(14, 1, 70), Pos = Vector3.new(0, 0, -45) }, { Size = Vector3.new(110, 1, 12), Pos = Vector3.new(-55, 0, 20) }, { Size = Vector3.new(110, 1, 12), Pos = Vector3.new(55, 0, 20) } }
	for i, d in ipairs(pathData) do
		makePart({ Name = "Path" .. i, Size = d.Size, Position = d.Pos, Color = MapConfig.Colors.Path, Material = MapConfig.Materials.Concrete, TopSurface = Enum.SurfaceType.Studs, Parent = roads })
	end
	makeSign("WELCOME TO ROBLOXIA!", MapConfig.Layout.PlazaCenter + Vector3.new(0, 9, -22), Vector3.new(18, 7, 1), plaza)
	makeSign("HAVE FUN?", MapConfig.Layout.PlazaCenter + Vector3.new(-20, 5, 5), Vector3.new(7, 3, 0.5), plaza)
	makeSign("DONT LOOK BACK", MapConfig.Layout.PlazaCenter + Vector3.new(22, 4, -5), Vector3.new(8, 3, 0.5), plaza)
	for i = -1, 1, 2 do
		makePart({ Name = "Bench", Size = Vector3.new(6, 1, 2), Position = MapConfig.Layout.PlazaCenter + Vector3.new(i * 14, 1, 10), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = plaza })
		local lamp = makeModel("Lamp", plaza)
		makePart({ Name = "Pole", Size = Vector3.new(0.5, 10, 0.5), Position = MapConfig.Layout.PlazaCenter + Vector3.new(i * 16, 5, -10), Color = Color3.fromRGB(50, 50, 50), Parent = lamp })
		makePart({ Name = "Light", Size = Vector3.new(2, 1, 2), Position = MapConfig.Layout.PlazaCenter + Vector3.new(i * 16, 10.5, -10), Color = Color3.fromRGB(255, 240, 180), Material = Enum.Material.Neon, Parent = lamp })
	end
	for _, offset in ipairs({ Vector3.new(-18, 0, 18), Vector3.new(18, 0, 18), Vector3.new(-18, 0, -12), Vector3.new(18, 0, -12) }) do
		makeTree(MapConfig.Layout.PlazaCenter + offset, plaza)
	end
	makeBloxyColaMachine(MapConfig.Layout.PlazaCenter + Vector3.new(-18, 0, 0), plaza)
	makeBloxyColaMachine(MapConfig.Layout.PlazaCenter + Vector3.new(18, 0, 0), plaza)
	makeTable(MapConfig.Layout.PlazaCenter + Vector3.new(0, 0, 8), plaza, Vector3.new(6, 0.4, 3.5))
	makeChair(MapConfig.Layout.PlazaCenter + Vector3.new(-2.5, 0, 6), plaza)
	makeChair(MapConfig.Layout.PlazaCenter + Vector3.new(2.5, 0, 6), plaza)
	makeChair(MapConfig.Layout.PlazaCenter + Vector3.new(-2.5, 0, 10), plaza)
	makeChair(MapConfig.Layout.PlazaCenter + Vector3.new(2.5, 0, 10), plaza)
	makeBloxyColaCan(MapConfig.Layout.PlazaCenter + Vector3.new(0, 2.4, 8), plaza)
	makeBloxyColaCan(MapConfig.Layout.PlazaCenter + Vector3.new(1, 2.4, 8.5), plaza)
	return plaza
end

function MapBuilder.CreateHappyHome(root)
	local folder = makeModel("HappyHome", root)
	local pos = MapConfig.Layout.HappyHomePos
	local assetModel = AssetRegistry.TryHappyHome(folder)
	if not assetModel then
		makePart({ Name = "Floor", Size = Vector3.new(28, 1, 20), Position = pos + Vector3.new(0, 0.5, 0), Color = Color3.fromRGB(140, 140, 140), Parent = folder })
		local wallH = 10
		makePart({ Name = "FrontLeft", Size = Vector3.new(10, wallH, 1), Position = pos + Vector3.new(-9, wallH/2 + 0.5, -10), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "FrontRight", Size = Vector3.new(10, wallH, 1), Position = pos + Vector3.new(9, wallH/2 + 0.5, -10), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "FrontTop", Size = Vector3.new(8, 3, 1), Position = pos + Vector3.new(0, 8.5, -10), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "Back", Size = Vector3.new(28, wallH, 1), Position = pos + Vector3.new(0, wallH/2 + 0.5, 10), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "Left", Size = Vector3.new(1, wallH, 20), Position = pos + Vector3.new(-14, wallH/2 + 0.5, 0), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "Right", Size = Vector3.new(1, wallH, 20), Position = pos + Vector3.new(14, wallH/2 + 0.5, 0), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "RoofL", Size = Vector3.new(30, 1, 14), Position = pos + Vector3.new(0, 12, -5), Color = MapConfig.Colors.HouseRoof, Parent = folder })
		makePart({ Name = "RoofR", Size = Vector3.new(30, 1, 14), Position = pos + Vector3.new(0, 12, 5), Color = MapConfig.Colors.HouseRoof, Parent = folder })
		makePart({ Name = "Chimney", Size = Vector3.new(3, 5, 3), Position = pos + Vector3.new(8, 15, 0), Color = Color3.fromRGB(120, 80, 60), Parent = folder })
		makePart({ Name = "Door", Size = Vector3.new(3.5, 6.5, 0.3), Position = pos + Vector3.new(0, 3.75, -10.2), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, CanCollide = false, Parent = folder })
		for _, wx in ipairs({ -9, 9 }) do
			makePart({ Name = "Window", Size = Vector3.new(3.5, 3.5, 0.3), Position = pos + Vector3.new(wx, 6, -10.15), Color = Color3.fromRGB(180, 220, 255), Material = Enum.Material.Glass, Parent = folder })
		end
		makePart({ Name = "Steps", Size = Vector3.new(6, 1, 3), Position = pos + Vector3.new(0, 0.5, -12.5), Color = Color3.fromRGB(160, 160, 160), Parent = folder })
		makePart({ Name = "Garden", Size = Vector3.new(36, 0.5, 10), Position = pos + Vector3.new(0, 0.25, -17), Color = Color3.fromRGB(80, 140, 60), Material = Enum.Material.Grass, Parent = folder })
		makeTable(pos + Vector3.new(0, 0, 2), folder, Vector3.new(5, 0.4, 3))
		makeChair(pos + Vector3.new(-2, 0, 0), folder)
		makeChair(pos + Vector3.new(2, 0, 0), folder)
	end
	makeSign("HAPPY HOME", pos + Vector3.new(0, 5, -24), Vector3.new(10, 4, 1), folder)
	return folder
end

function MapBuilder.CreateConstructionYard(root)
	local folder = makeModel("ConstructionYard", root)
	local pos = MapConfig.Layout.ConstructionYardPos
	makePart({ Name = "YardFloor", Size = Vector3.new(55, 1, 45), Position = pos, Color = Color3.fromRGB(120, 120, 100), Material = Enum.Material.Concrete, TopSurface = Enum.SurfaceType.Studs, Parent = folder })
	local colors = { MapConfig.Colors.BrickYellow, MapConfig.Colors.BrickRed, MapConfig.Colors.BrickBlue, MapConfig.Colors.BrickGreen, MapConfig.Colors.BrickOrange, Color3.fromRGB(255, 255, 255), Color3.fromRGB(27, 42, 53) }
	local brickSizes = { Vector3.new(4, 1, 2), Vector3.new(2, 1, 4), Vector3.new(4, 2, 2), Vector3.new(1, 1, 1), Vector3.new(8, 1, 2), Vector3.new(2, 2, 2) }
	for i = 1, 7 do
		local pilePos = pos + Vector3.new(-20 + i * 6, 1, -12)
		for j = 1, 6 do
			local sz = brickSizes[((i + j) % #brickSizes) + 1]
			makePart({ Name = "Brick_" .. i .. "_" .. j, Size = sz, Position = pilePos + Vector3.new(0, j * 1.15, (j % 3) - 1), Color = colors[i], Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Anchored = false, Parent = folder })
		end
	end
	for x = -1, 1 do
		for y = 1, 3 do
			makePart({ Name = "ExampleWall", Size = Vector3.new(4, 2, 2), Position = pos + Vector3.new(x * 4, y * 2, 14), Color = MapConfig.Colors.BrickYellow, Parent = folder })
		end
	end
	makeSign("FREE BRICKS", pos + Vector3.new(0, 6, -20), Vector3.new(12, 5, 1), folder)
	makeSign("BUILD HERE", pos + Vector3.new(18, 5, 0), Vector3.new(8, 4, 1), folder)
	makeSign("HAVE FUN!", pos + Vector3.new(-18, 5, 0), Vector3.new(8, 4, 1), folder)
	return folder
end

function MapBuilder.CreateRoleplayDistrict(root)
	local folder = makeModel("RoleplayDistrict", root)
	local base = MapConfig.Layout.RoleplayDistrictPos
	local houseColors = { MapConfig.Colors.HouseWall, Color3.fromRGB(180, 160, 140), Color3.fromRGB(200, 180, 160), Color3.fromRGB(160, 140, 120), Color3.fromRGB(190, 170, 150) }
	for i = 1, 5 do
		local hx = base.X + (i - 3) * 32
		local hz = base.Z
		local house = makeModel("House_" .. i, folder)
		local isSecret = (i == MapConfig.Layout.SecretHouseIndex)
		local wallColor = houseColors[i]
		local wh = 8
		makePart({ Name = "Floor", Size = Vector3.new(18, 1, 16), Position = Vector3.new(hx, 0.5, hz), Color = Color3.fromRGB(140, 140, 140), Parent = house })
		makePart({ Name = "FrontLeft", Size = Vector3.new(6.5, wh, 1), Position = Vector3.new(hx - 5.75, wh/2 + 0.5, hz - 8), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "FrontRight", Size = Vector3.new(6.5, wh, 1), Position = Vector3.new(hx + 5.75, wh/2 + 0.5, hz - 8), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "FrontTop", Size = Vector3.new(5, 2.5, 1), Position = Vector3.new(hx, 7.25, hz - 8), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Back", Size = Vector3.new(18, wh, 1), Position = Vector3.new(hx, wh/2 + 0.5, hz + 8), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Left", Size = Vector3.new(1, wh, 16), Position = Vector3.new(hx - 9, wh/2 + 0.5, hz), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Right", Size = Vector3.new(1, wh, 16), Position = Vector3.new(hx + 9, wh/2 + 0.5, hz), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Roof", Size = Vector3.new(20, 1, 18), Position = Vector3.new(hx, 9.5, hz), Color = isSecret and Color3.fromRGB(80, 20, 20) or MapConfig.Colors.HouseRoof, Parent = house })
		makePart({ Name = "Door", Size = Vector3.new(3.2, 5.8, 0.3), Position = Vector3.new(hx, 3.4, hz - 8.2), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, CanCollide = false, Parent = house })
		makePart({ Name = "WinL", Size = Vector3.new(2.8, 2.8, 0.3), Position = Vector3.new(hx - 5.5, 5, hz - 8.15), Color = Color3.fromRGB(170, 210, 255), Material = Enum.Material.Glass, Parent = house })
		makePart({ Name = "WinR", Size = Vector3.new(2.8, 2.8, 0.3), Position = Vector3.new(hx + 5.5, 5, hz - 8.15), Color = Color3.fromRGB(170, 210, 255), Material = Enum.Material.Glass, Parent = house })
		makePart({ Name = "Steps", Size = Vector3.new(4.5, 0.8, 2.5), Position = Vector3.new(hx, 0.4, hz - 10), Color = Color3.fromRGB(150, 150, 150), Parent = house })
		makeTable(Vector3.new(hx, 0, hz + 1), house, Vector3.new(4.5, 0.35, 2.8))
		makeChair(Vector3.new(hx - 2, 0, hz - 1), house)
		makeChair(Vector3.new(hx + 2, 0, hz - 1), house)
		if isSecret then
			local basement = makeModel("SecretBasement", house)
			for s = 1, 7 do
				makePart({ Name = "Stair" .. s, Size = Vector3.new(4, 0.9, 1.8), Position = Vector3.new(hx + 4, 0.5 - s * 1.1, hz + 2 + s * 1.4), Color = Color3.fromRGB(90, 90, 90), Material = Enum.Material.Concrete, Parent = basement })
			end
			makePart({ Name = "BasementFloor", Size = Vector3.new(16, 1, 14), Position = Vector3.new(hx + 4, -8.5, hz + 12), Color = Color3.fromRGB(55, 55, 55), Parent = basement })
			makePart({ Name = "BWallF", Size = Vector3.new(16, 7, 1), Position = Vector3.new(hx + 4, -5, hz + 5.5), Color = Color3.fromRGB(45, 45, 45), Parent = basement })
			makePart({ Name = "BWallB", Size = Vector3.new(16, 7, 1), Position = Vector3.new(hx + 4, -5, hz + 18.5), Color = Color3.fromRGB(45, 45, 45), Parent = basement })
			makePart({ Name = "BWallL", Size = Vector3.new(1, 7, 14), Position = Vector3.new(hx - 3.5, -5, hz + 12), Color = Color3.fromRGB(45, 45, 45), Parent = basement })
			makePart({ Name = "BWallR", Size = Vector3.new(1, 7, 14), Position = Vector3.new(hx + 11.5, -5, hz + 12), Color = Color3.fromRGB(45, 45, 45), Parent = basement })
			local argDoor = makePart({ Name = "ARG_Door", Size = Vector3.new(3.5, 5.5, 0.5), Position = Vector3.new(hx + 4, -5.2, hz + 18.7), Color = Color3.fromRGB(15, 15, 15), Material = Enum.Material.Metal, Parent = basement })
			argDoor:SetAttribute("IsARGTrigger", true)
			makeSign("DO NOT ENTER", Vector3.new(hx + 4, -2.5, hz + 17), Vector3.new(5, 2, 0.4), basement)
			local light = Instance.new("PointLight")
			light.Brightness = 0.5
			light.Color = Color3.fromRGB(255, 90, 70)
			light.Range = 14
			light.Parent = argDoor
			makeSign("KEEP OUT", Vector3.new(hx, 5, hz - 10.5), Vector3.new(6, 2.5, 0.4), house)
		end
	end
	makePart({ Name = "Street", Size = Vector3.new(160, 1, 12), Position = base + Vector3.new(0, 0, -14), Color = MapConfig.Colors.Path, Material = MapConfig.Materials.Concrete, TopSurface = Enum.SurfaceType.Studs, Parent = folder })
	makeSign("VISIT THE TOWN", base + Vector3.new(0, 5, -22), Vector3.new(12, 4, 1), folder)
	local park = makeModel("Park", folder)
	makePart({ Name = "ParkFloor", Size = Vector3.new(32, 1, 22), Position = base + Vector3.new(70, 0, 30), Color = Color3.fromRGB(70, 130, 60), Material = Enum.Material.Grass, Parent = park })
	for i = 1, 5 do makeTree(base + Vector3.new(58 + i * 6, 0, 28), park) end
	makeTable(base + Vector3.new(70, 0, 32), park, Vector3.new(5, 0.35, 3))
	makeChair(base + Vector3.new(67, 0, 30), park)
	makeChair(base + Vector3.new(73, 0, 30), park)
	makeBloxyColaMachine(base + Vector3.new(25, 0, -18), folder)
	return folder
end

function MapBuilder.CreateObby(root)
	local folder = makeModel("Obby", root)
	local start = MapConfig.Layout.ObbyStart
	makeSign("OBBY ->", start + Vector3.new(0, 6, -12), Vector3.new(8, 4, 1), folder)
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
		local part = makePart({ Name = "Platform_" .. i, Size = p.Size, Position = p.Pos, Color = p.Color, Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Parent = folder })
		if i == #platforms then
			part:SetAttribute("IsFinish", true)
			makeSign("FINISH!", p.Pos + Vector3.new(0, 5, 0), Vector3.new(6, 3, 1), folder)
		end
	end
	for i = 1, 3 do
		local kill = makePart({ Name = "KillBrick_" .. i, Size = Vector3.new(6, 1, 6), Position = start + Vector3.new(20 + i * 12, 1, -12), Color = MapConfig.Colors.Danger, Material = Enum.Material.Neon, Parent = folder })
		kill:SetAttribute("IsKillBrick", true)
	end
	return folder
end

function MapBuilder.CreateNature(root)
	local folder = makeModel("Nature", root)
	local pos = MapConfig.Layout.NaturePos
	makePart({ Name = "Lake", Size = Vector3.new(40, 2, 30), Position = pos + Vector3.new(0, -0.5, 0), Color = MapConfig.Colors.Water, Material = Enum.Material.Water, CanCollide = false, Parent = folder })
	for i = 1, 8 do
		makePart({ Name = "BridgePlank" .. i, Size = Vector3.new(4, 0.6, 2), Position = pos + Vector3.new(-16 + i * 4, 1, 0), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = folder })
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
		makePart({ Name = "Tower" .. i, Size = Vector3.new(4, 3, 4), Position = Vector3.new(180, i * 3, -80), Color = Color3.fromRGB(140, 100, 60), Material = MapConfig.Materials.Wood, Parent = lookout })
	end
	makePart({ Name = "Platform", Size = Vector3.new(10, 1, 10), Position = Vector3.new(180, 16, -80), Color = Color3.fromRGB(160, 120, 80), Parent = lookout })
	makeSign("SECRET VIEW", Vector3.new(180, 18, -80), Vector3.new(6, 2, 1), lookout)
	return spawnFolder, secrets
end

function MapBuilder.BuildFullMap(parent)
	local root = makeModel(MapConfig.MapName, parent or workspace)
	print("[MapBuilder] Generando Robloxia 2009 v0.3...")
	MapBuilder.CreateBaseAndPlaza(root)
	MapBuilder.CreateHappyHome(root)
	MapBuilder.CreateConstructionYard(root)
	MapBuilder.CreateRoleplayDistrict(root)
	MapBuilder.CreateObby(root)
	MapBuilder.CreateNature(root)
	MapBuilder.CreateSpawnAndSecrets(root)
	print("[MapBuilder] Listo. Busca ServerStorage: Bloxy Cola Vending + Bloxy")
	return root
end

return MapBuilder
