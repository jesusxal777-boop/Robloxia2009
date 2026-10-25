--[[
	MapBuilder.lua  v0.4
	- ServerStorage: Bloxy Cola Vending (scripts OK) + Bloxy
	- Maquinas sobre el suelo
	- Sotano con hatch DOWN
	- Mas secretos y RP
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
	label.Font = Enum.Font.ArialBold
	label.Parent = gui
	local gui2 = gui:Clone()
	gui2.Face = Enum.NormalId.Back
	gui2.Parent = board
	return sign
end

local function makeTree(position, parent)
	local tree = makeModel("Tree", parent)
	makePart({ Name = "Trunk", Size = Vector3.new(1.4, 5.5, 1.4), Position = position + Vector3.new(0, 2.75, 0), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = tree })
	for i = 1, 3 do
		makePart({ Name = "Leaves" .. i, Size = Vector3.new(5 - i * 0.8, 1.8, 5 - i * 0.8), Position = position + Vector3.new(0, 5.5 + i * 1.3, 0), Color = Color3.fromRGB(40, 127, 71), Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Parent = tree })
	end
	return tree
end

local function makeChair(position, parent)
	local chair = makeModel("Chair", parent)
	makePart({ Name = "Seat", Size = Vector3.new(2.2, 0.4, 2.2), Position = position + Vector3.new(0, 1.8, 0), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = chair })
	makePart({ Name = "Back", Size = Vector3.new(2.2, 2.2, 0.35), Position = position + Vector3.new(0, 2.9, -0.95), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = chair })
	for _, off in ipairs({ Vector3.new(-0.8, 0.8, -0.8), Vector3.new(0.8, 0.8, -0.8), Vector3.new(-0.8, 0.8, 0.8), Vector3.new(0.8, 0.8, 0.8) }) do
		makePart({ Name = "Leg", Size = Vector3.new(0.3, 1.6, 0.3), Position = position + off, Color = Color3.fromRGB(90, 70, 50), Material = MapConfig.Materials.Wood, Parent = chair })
	end
	return chair
end

local function makeTable(position, parent, size)
	local tbl = makeModel("Table", parent)
	size = size or Vector3.new(5, 0.4, 3)
	makePart({ Name = "Top", Size = size, Position = position + Vector3.new(0, 2.2, 0), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = tbl })
	for _, off in ipairs({ Vector3.new(-size.X/2+0.4, 1, -size.Z/2+0.4), Vector3.new(size.X/2-0.4, 1, -size.Z/2+0.4), Vector3.new(-size.X/2+0.4, 1, size.Z/2-0.4), Vector3.new(size.X/2-0.4, 1, size.Z/2-0.4) }) do
		makePart({ Name = "Leg", Size = Vector3.new(0.35, 2, 0.35), Position = position + off, Color = Color3.fromRGB(90, 70, 50), Material = MapConfig.Materials.Wood, Parent = tbl })
	end
	return tbl
end

local function cloneFromStorage(name, position, parent)
	local template = ServerStorage:FindFirstChild(name)
	if not template then
		warn('[MapBuilder] No se encontro: "' .. name .. '" -> fallback')
		return nil
	end
	print("[MapBuilder] Usando modelo real: " .. name)
	local clone = template:Clone()
	local parts = {}
	if clone:IsA("BasePart") then table.insert(parts, clone)
	else for _, d in ipairs(clone:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts, d) end end end
	if #parts == 0 then clone.Parent = parent return clone end
	local minY, cx, cz = math.huge, 0, 0
	for _, p in ipairs(parts) do
		local y = p.Position.Y - p.Size.Y/2
		if y < minY then minY = y end
		cx = cx + p.Position.X
		cz = cz + p.Position.Z
	end
	cx, cz = cx/#parts, cz/#parts
	local offset = Vector3.new(position.X - cx, position.Y - minY, position.Z - cz)
	for _, p in ipairs(parts) do
		p.CFrame = p.CFrame + offset
		p.Anchored = true
	end
	clone.Parent = parent
	return clone
end

local function makeBloxyColaMachine(position, parent)
	local real = cloneFromStorage("Bloxy Cola Vending", position, parent)
	if real then return real end
	local machine = makeModel("BloxyColaMachine", parent)
	makePart({ Name = "Body", Size = Vector3.new(3.5, 6, 2.2), Position = position + Vector3.new(0, 3, 0), Color = Color3.fromRGB(180, 40, 40), Material = Enum.Material.Plastic, Parent = machine })
	makePart({ Name = "Top", Size = Vector3.new(3.7, 0.6, 2.4), Position = position + Vector3.new(0, 6.3, 0), Color = Color3.fromRGB(220, 50, 50), Parent = machine })
	return machine
end

local function makeBloxyColaCan(position, parent)
	local real = cloneFromStorage("Bloxy", position, parent)
	if real then return real end
	return makePart({ Name = "BloxyCola", Size = Vector3.new(1, 1.6, 1), Position = position + Vector3.new(0, 0.8, 0), Color = Color3.fromRGB(200, 80, 30), Material = Enum.Material.Plastic, Parent = parent })
end

local function makeNote(text, position, parent)
	local note = makePart({ Name = "Note", Size = Vector3.new(2, 1.2, 0.1), Position = position, Color = Color3.fromRGB(240, 230, 180), Material = Enum.Material.Cardboard, TopSurface = Enum.SurfaceType.Smooth, Parent = parent })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = note
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -4, 1, -4)
	label.Position = UDim2.new(0, 2, 0, 2)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(40, 30, 20)
	label.TextScaled = true
	label.Font = Enum.Font.Arial
	label.TextWrapped = true
	label.Parent = gui
	return note
end

function MapBuilder.CreateBaseAndPlaza(root)
	local terrainFolder = makeModel("Terrain", root)
	local roads = makeModel("Roads", root)
	local plaza = makeModel("Plaza", root)
	makePart({ Name = "Baseplate", Size = MapConfig.Layout.BaseSize, Position = Vector3.new(0, -0.5, 0), Color = MapConfig.Colors.Baseplate, Material = Enum.Material.Grass, TopSurface = Enum.SurfaceType.Studs, Parent = terrainFolder })
	makePart({ Name = "PlazaFloor", Size = Vector3.new(48, 1, 48), Position = MapConfig.Layout.PlazaCenter, Color = MapConfig.Colors.Path, Material = MapConfig.Materials.Concrete, TopSurface = Enum.SurfaceType.Studs, Parent = plaza })
	for i, d in ipairs({ { Size = Vector3.new(14, 1, 90), Pos = Vector3.new(0, 0, 55) }, { Size = Vector3.new(14, 1, 70), Pos = Vector3.new(0, 0, -45) }, { Size = Vector3.new(110, 1, 12), Pos = Vector3.new(-55, 0, 20) }, { Size = Vector3.new(110, 1, 12), Pos = Vector3.new(55, 0, 20) } }) do
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
	for _, offset in ipairs({ Vector3.new(-18, 0, 18), Vector3.new(18, 0, 18), Vector3.new(-18, 0, -12), Vector3.new(18, 0, -12) }) do makeTree(MapConfig.Layout.PlazaCenter + offset, plaza) end
	makeBloxyColaMachine(MapConfig.Layout.PlazaCenter + Vector3.new(-20, 0, -8), plaza)
	makeBloxyColaMachine(MapConfig.Layout.PlazaCenter + Vector3.new(20, 0, -8), plaza)
	makeTable(MapConfig.Layout.PlazaCenter + Vector3.new(0, 0.5, 8), plaza, Vector3.new(6, 0.4, 3.5))
	makeChair(MapConfig.Layout.PlazaCenter + Vector3.new(-2.5, 0.5, 6), plaza)
	makeChair(MapConfig.Layout.PlazaCenter + Vector3.new(2.5, 0.5, 6), plaza)
	makeChair(MapConfig.Layout.PlazaCenter + Vector3.new(-2.5, 0.5, 10), plaza)
	makeChair(MapConfig.Layout.PlazaCenter + Vector3.new(2.5, 0.5, 10), plaza)
	makeBloxyColaCan(MapConfig.Layout.PlazaCenter + Vector3.new(0, 2.9, 8), plaza)
	makeNote("The third house knows.", MapConfig.Layout.PlazaCenter + Vector3.new(-8, 1.5, -15), plaza)
	return plaza
end

function MapBuilder.CreateHappyHome(root)
	local folder = makeModel("HappyHome", root)
	local pos = MapConfig.Layout.HappyHomePos
	if not AssetRegistry.TryHappyHome(folder, pos) then
		makePart({ Name = "Floor", Size = Vector3.new(28, 1, 20), Position = pos + Vector3.new(0, 0.5, 0), Color = Color3.fromRGB(140, 140, 140), Parent = folder })
		local wallH = 10
		makePart({ Name = "FrontLeft", Size = Vector3.new(10, wallH, 1), Position = pos + Vector3.new(-9, wallH/2+0.5, -10), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "FrontRight", Size = Vector3.new(10, wallH, 1), Position = pos + Vector3.new(9, wallH/2+0.5, -10), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "FrontTop", Size = Vector3.new(8, 3, 1), Position = pos + Vector3.new(0, 8.5, -10), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "Back", Size = Vector3.new(28, wallH, 1), Position = pos + Vector3.new(0, wallH/2+0.5, 10), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "Left", Size = Vector3.new(1, wallH, 20), Position = pos + Vector3.new(-14, wallH/2+0.5, 0), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "Right", Size = Vector3.new(1, wallH, 20), Position = pos + Vector3.new(14, wallH/2+0.5, 0), Color = MapConfig.Colors.HouseWall, Material = MapConfig.Materials.Brick, Parent = folder })
		makePart({ Name = "RoofL", Size = Vector3.new(30, 1, 14), Position = pos + Vector3.new(0, 12, -5), Color = MapConfig.Colors.HouseRoof, Parent = folder })
		makePart({ Name = "RoofR", Size = Vector3.new(30, 1, 14), Position = pos + Vector3.new(0, 12, 5), Color = MapConfig.Colors.HouseRoof, Parent = folder })
		makePart({ Name = "Door", Size = Vector3.new(3.5, 6.5, 0.3), Position = pos + Vector3.new(0, 3.75, -10.2), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, CanCollide = false, Parent = folder })
		makePart({ Name = "Steps", Size = Vector3.new(6, 1, 3), Position = pos + Vector3.new(0, 0.5, -12.5), Color = Color3.fromRGB(160, 160, 160), Parent = folder })
		makeTable(pos + Vector3.new(0, 1, 2), folder, Vector3.new(5, 0.4, 3))
		makeChair(pos + Vector3.new(-2, 1, 0), folder)
		makeChair(pos + Vector3.new(2, 1, 0), folder)
		-- Interior details: a low television console and a simple classic CRT.
		makePart({ Name = "TVConsole", Size = Vector3.new(6, 1, 1.2), Position = pos + Vector3.new(0, 1.5, 7.2), Color = Color3.fromRGB(110, 75, 48), Material = MapConfig.Materials.Wood, Parent = folder })
		makePart({ Name = "CRT_TV", Size = Vector3.new(4, 2.5, 1.2), Position = pos + Vector3.new(0, 3.25, 6.8), Color = Color3.fromRGB(45, 45, 45), Material = Enum.Material.Plastic, Parent = folder })
		makePart({ Name = "CRT_Screen", Size = Vector3.new(3.2, 1.7, 0.08), Position = pos + Vector3.new(0, 3.3, 6.15), Color = Color3.fromRGB(100, 145, 155), Material = Enum.Material.Glass, CanCollide = false, Parent = folder })
		makePart({ Name = "Bookshelf", Size = Vector3.new(2, 5, 4), Position = pos + Vector3.new(-11.5, 3.5, 1), Color = Color3.fromRGB(110, 75, 48), Material = MapConfig.Materials.Wood, Parent = folder })
	end
	makeSign("HAPPY HOME", pos + Vector3.new(0, 5, -24), Vector3.new(10, 4, 1), folder)
	return folder
end

function MapBuilder.CreateConstructionYard(root)
	local folder = makeModel("ConstructionYard", root)
	local pos = MapConfig.Layout.ConstructionYardPos
	makePart({ Name = "YardFloor", Size = Vector3.new(55, 1, 45), Position = pos, Color = Color3.fromRGB(120, 120, 100), Material = Enum.Material.Concrete, TopSurface = Enum.SurfaceType.Studs, Parent = folder })
	local colors = { MapConfig.Colors.BrickYellow, MapConfig.Colors.BrickRed, MapConfig.Colors.BrickBlue, MapConfig.Colors.BrickGreen, MapConfig.Colors.BrickOrange, Color3.fromRGB(255,255,255), Color3.fromRGB(27,42,53) }
	local brickSizes = { Vector3.new(4,1,2), Vector3.new(2,1,4), Vector3.new(4,2,2), Vector3.new(1,1,1), Vector3.new(8,1,2), Vector3.new(2,2,2) }
	for i = 1, 7 do
		local pilePos = pos + Vector3.new(-20 + i * 6, 1, -12)
		for j = 1, 6 do
			local sz = brickSizes[((i+j) % #brickSizes) + 1]
			makePart({ Name = "Brick_"..i.."_"..j, Size = sz, Position = pilePos + Vector3.new(0, j*1.15, (j%3)-1), Color = colors[i], Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Anchored = false, Parent = folder })
		end
	end
	makeSign("FREE BRICKS", pos + Vector3.new(0, 6, -20), Vector3.new(12, 5, 1), folder)
	makeSign("BUILD HERE", pos + Vector3.new(18, 5, 0), Vector3.new(8, 4, 1), folder)
	return folder
end

function MapBuilder.CreateRoleplayDistrict(root)
	local folder = makeModel("RoleplayDistrict", root)
	local base = MapConfig.Layout.RoleplayDistrictPos
	local houseColors = { MapConfig.Colors.HouseWall, Color3.fromRGB(180,160,140), Color3.fromRGB(200,180,160), Color3.fromRGB(160,140,120), Color3.fromRGB(190,170,150) }
	for i = 1, 5 do
		local hx = base.X + (i - 3) * 32
		local hz = base.Z
		local house = makeModel("House_" .. i, folder)
		local isSecret = (i == MapConfig.Layout.SecretHouseIndex)
		local wallColor = houseColors[i]
		local wh = 8
		if isSecret then
			-- Four floor sections leave a real opening for the hatch; a single floor part
			-- underneath it would block the player from descending the stairs.
			makePart({ Name = "FloorFront", Size = Vector3.new(18, 1, 10), Position = Vector3.new(hx, 0.5, hz - 3), Color = Color3.fromRGB(140,140,140), Parent = house })
			makePart({ Name = "FloorBack", Size = Vector3.new(18, 1, 2), Position = Vector3.new(hx, 0.5, hz + 7), Color = Color3.fromRGB(140,140,140), Parent = house })
			makePart({ Name = "FloorLeft", Size = Vector3.new(12, 1, 4), Position = Vector3.new(hx - 3, 0.5, hz + 4), Color = Color3.fromRGB(140,140,140), Parent = house })
			makePart({ Name = "FloorRight", Size = Vector3.new(2, 1, 4), Position = Vector3.new(hx + 8, 0.5, hz + 4), Color = Color3.fromRGB(140,140,140), Parent = house })
		else
			makePart({ Name = "Floor", Size = Vector3.new(18, 1, 16), Position = Vector3.new(hx, 0.5, hz), Color = Color3.fromRGB(140,140,140), Parent = house })
		end
		makePart({ Name = "FrontLeft", Size = Vector3.new(6.5, wh, 1), Position = Vector3.new(hx-5.75, wh/2+0.5, hz-8), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "FrontRight", Size = Vector3.new(6.5, wh, 1), Position = Vector3.new(hx+5.75, wh/2+0.5, hz-8), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "FrontTop", Size = Vector3.new(5, 2.5, 1), Position = Vector3.new(hx, 7.25, hz-8), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Back", Size = Vector3.new(18, wh, 1), Position = Vector3.new(hx, wh/2+0.5, hz+8), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Left", Size = Vector3.new(1, wh, 16), Position = Vector3.new(hx-9, wh/2+0.5, hz), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Right", Size = Vector3.new(1, wh, 16), Position = Vector3.new(hx+9, wh/2+0.5, hz), Color = wallColor, Material = MapConfig.Materials.Brick, Parent = house })
		makePart({ Name = "Roof", Size = Vector3.new(20, 1, 18), Position = Vector3.new(hx, 9.5, hz), Color = isSecret and Color3.fromRGB(80,20,20) or MapConfig.Colors.HouseRoof, Parent = house })
		makePart({ Name = "Door", Size = Vector3.new(3.2, 5.8, 0.3), Position = Vector3.new(hx, 3.4, hz-8.2), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, CanCollide = false, Parent = house })
		makePart({ Name = "DoorKnob", Size = Vector3.new(0.22, 0.22, 0.22), Position = Vector3.new(hx + 1.05, 3.4, hz - 8.42), Color = Color3.fromRGB(205, 170, 70), Material = Enum.Material.Metal, CanCollide = false, Parent = house })
		makePart({ Name = "WinL", Size = Vector3.new(2.8, 2.8, 0.3), Position = Vector3.new(hx-5.5, 5, hz-8.15), Color = Color3.fromRGB(170,210,255), Material = Enum.Material.Glass, Parent = house })
		makePart({ Name = "WinR", Size = Vector3.new(2.8, 2.8, 0.3), Position = Vector3.new(hx+5.5, 5, hz-8.15), Color = Color3.fromRGB(170,210,255), Material = Enum.Material.Glass, Parent = house })
		makePart({ Name = "Steps", Size = Vector3.new(4.5, 0.8, 2.5), Position = Vector3.new(hx, 0.4, hz-10), Color = Color3.fromRGB(150,150,150), Parent = house })
		makeTable(Vector3.new(hx-3, 1, hz+2), house, Vector3.new(4, 0.4, 2.5))
		makeChair(Vector3.new(hx-3, 1, hz), house)
		makeChair(Vector3.new(hx-1, 1, hz), house)
		local bedZ = isSecret and (hz - 3) or (hz + 3)
		makePart({ Name = "BedFrame", Size = Vector3.new(5.4, 0.5, 3.4), Position = Vector3.new(hx+5, 1.25, bedZ), Color = Color3.fromRGB(105, 75, 50), Material = MapConfig.Materials.Wood, Parent = house })
		makePart({ Name = "Bed", Size = Vector3.new(5, 1, 3), Position = Vector3.new(hx+5, 1.75, bedZ), Color = Color3.fromRGB(100,120,160), Parent = house })
		makePart({ Name = "Pillow", Size = Vector3.new(2, 0.5, 2.5), Position = Vector3.new(hx+5, 2.5, bedZ - 0.15), Color = Color3.fromRGB(240,240,250), Parent = house })
		makePart({ Name = "Nightstand", Size = Vector3.new(1.8, 1.6, 1.8), Position = Vector3.new(hx+1.8, 1.8, bedZ), Color = Color3.fromRGB(115, 80, 52), Material = MapConfig.Materials.Wood, Parent = house })
		makePart({ Name = "NightstandLamp", Size = Vector3.new(0.7, 1, 0.7), Position = Vector3.new(hx+1.8, 3.1, bedZ), Color = Color3.fromRGB(235, 220, 160), Material = Enum.Material.Plastic, Parent = house })
		if isSecret then
			local basement = makeModel("SecretBasement", house)
			makePart({ Name = "Hatch", Size = Vector3.new(4, 0.3, 4), Position = Vector3.new(hx+5, 1.08, hz+4), Color = Color3.fromRGB(60,40,30), Material = Enum.Material.Wood, CanCollide = false, Parent = basement })
			makeSign("DOWN", Vector3.new(hx+1.5, 2, hz+4), Vector3.new(2.5, 1, 0.2), basement)
			for step = 1, 8 do
				makePart({ Name = "Stair"..step, Size = Vector3.new(3.5, 0.8, 1.6), Position = Vector3.new(hx+5, 0.5 - (step-1), hz+4 + step*1.2), Color = Color3.fromRGB(85,85,85), Material = Enum.Material.Concrete, Parent = basement })
			end
			local by, bz = -8, hz+14
			makePart({ Name = "BasementFloor", Size = Vector3.new(18, 1, 16), Position = Vector3.new(hx+5, by, bz), Color = Color3.fromRGB(50,50,50), Parent = basement })
			makePart({ Name = "BasementLanding", Size = Vector3.new(3.5, 0.6, 2.5), Position = Vector3.new(hx+5, by+0.9, bz), Color = Color3.fromRGB(70,70,70), Material = Enum.Material.Concrete, Parent = basement })
			-- Split the north wall around the stair opening instead of blocking the route.
			makePart({ Name = "BWallN_Left", Size = Vector3.new(7, 8, 1), Position = Vector3.new(hx-0.5, by+4, bz-8), Color = Color3.fromRGB(40,40,40), Parent = basement })
			makePart({ Name = "BWallN_Right", Size = Vector3.new(7, 8, 1), Position = Vector3.new(hx+10.5, by+4, bz-8), Color = Color3.fromRGB(40,40,40), Parent = basement })
			makePart({ Name = "BWallS", Size = Vector3.new(18, 8, 1), Position = Vector3.new(hx+5, by+4, bz+8), Color = Color3.fromRGB(40,40,40), Parent = basement })
			makePart({ Name = "BWallW", Size = Vector3.new(1, 8, 16), Position = Vector3.new(hx-4, by+4, bz), Color = Color3.fromRGB(40,40,40), Parent = basement })
			makePart({ Name = "BWallE", Size = Vector3.new(1, 8, 16), Position = Vector3.new(hx+14, by+4, bz), Color = Color3.fromRGB(40,40,40), Parent = basement })
			makeTable(Vector3.new(hx+10, by+0.5, bz+2), basement, Vector3.new(4, 0.4, 2.5))
			makeNote("2009 never ended.", Vector3.new(hx+10, by+2.8, bz+2), basement)
			local argDoor = makePart({ Name = "ARG_Door", Size = Vector3.new(3.5, 6, 0.5), Position = Vector3.new(hx+5, by+3.5, bz+8.2), Color = Color3.fromRGB(12,12,12), Material = Enum.Material.Metal, Parent = basement })
			argDoor:SetAttribute("IsARGTrigger", true)
			makeSign("DO NOT ENTER", Vector3.new(hx+5, by+7, bz+7), Vector3.new(5, 2, 0.3), basement)
			local light = Instance.new("PointLight")
			light.Brightness = 0.6
			light.Color = Color3.fromRGB(255, 80, 60)
			light.Range = 16
			light.Parent = argDoor
			makeSign("KEEP OUT", Vector3.new(hx, 5, hz-10.5), Vector3.new(6, 2.5, 0.4), house)
		elseif i == 1 then
			makeNote("Nice day for a build.", Vector3.new(hx, 2, hz+5), house)
		elseif i == 5 then
			makeNote("Someone moved in next door...", Vector3.new(hx, 2, hz+5), house)
		end
	end
	makePart({ Name = "Street", Size = Vector3.new(160, 1, 12), Position = base + Vector3.new(0, 0, -14), Color = MapConfig.Colors.Path, Material = MapConfig.Materials.Concrete, TopSurface = Enum.SurfaceType.Studs, Parent = folder })
	makeSign("VISIT THE TOWN", base + Vector3.new(0, 5, -22), Vector3.new(12, 4, 1), folder)
	local park = makeModel("Park", folder)
	makePart({ Name = "ParkFloor", Size = Vector3.new(32, 1, 22), Position = base + Vector3.new(70, 0, 30), Color = Color3.fromRGB(70,130,60), Material = Enum.Material.Grass, Parent = park })
	for i = 1, 5 do makeTree(base + Vector3.new(58 + i*6, 0, 28), park) end
	makeTable(base + Vector3.new(70, 0.5, 32), park, Vector3.new(5, 0.4, 3))
	makeChair(base + Vector3.new(67, 0.5, 30), park)
	makeChair(base + Vector3.new(73, 0.5, 30), park)
	makeBloxyColaMachine(base + Vector3.new(40, 0, -20), folder)
	local secretBox = makeModel("HiddenBox", folder)
	makePart({ Name = "Crate", Size = Vector3.new(3, 3, 3), Position = base + Vector3.new(-50, 1.5, 20), Color = Color3.fromRGB(120,90,50), Material = MapConfig.Materials.Wood, Parent = secretBox })
	makeNote("Look under the hatch.", base + Vector3.new(-50, 3.5, 20), secretBox)
	return folder
end

function MapBuilder.CreateObby(root)
	local folder = makeModel("Obby", root)
	local start = MapConfig.Layout.ObbyStart
	makeSign("OBBY ->", start + Vector3.new(0, 6, -12), Vector3.new(8, 4, 1), folder)
	local platforms = {
		{ Pos = start, Size = Vector3.new(8,1,8), Color = Color3.fromRGB(0,170,0) },
		{ Pos = start + Vector3.new(12,2,0), Size = Vector3.new(4,1,4), Color = Color3.fromRGB(0,120,200) },
		{ Pos = start + Vector3.new(20,4,4), Size = Vector3.new(3,1,3), Color = Color3.fromRGB(255,170,0) },
		{ Pos = start + Vector3.new(28,6,-2), Size = Vector3.new(3,1,3), Color = Color3.fromRGB(200,50,50) },
		{ Pos = start + Vector3.new(36,8,3), Size = Vector3.new(2.5,1,2.5), Color = Color3.fromRGB(170,0,170) },
		{ Pos = start + Vector3.new(44,10,0), Size = Vector3.new(2,1,6), Color = Color3.fromRGB(100,100,100) },
		{ Pos = start + Vector3.new(52,12,0), Size = Vector3.new(4,1,4), Color = Color3.fromRGB(0,200,100) },
		{ Pos = start + Vector3.new(60,14,5), Size = Vector3.new(3,1,3), Color = Color3.fromRGB(255,100,0) },
		{ Pos = start + Vector3.new(68,16,0), Size = Vector3.new(6,1,6), Color = Color3.fromRGB(0,255,100) },
	}
	for i, p in ipairs(platforms) do
		local part = makePart({ Name = "Platform_"..i, Size = p.Size, Position = p.Pos, Color = p.Color, Material = Enum.Material.Plastic, TopSurface = Enum.SurfaceType.Studs, Parent = folder })
		if i == #platforms then part:SetAttribute("IsFinish", true) makeSign("FINISH!", p.Pos + Vector3.new(0,5,0), Vector3.new(6,3,1), folder) end
	end
	for i = 1, 3 do
		local kill = makePart({ Name = "KillBrick_"..i, Size = Vector3.new(6,1,6), Position = start + Vector3.new(20+i*12, 1, -12), Color = MapConfig.Colors.Danger, Material = Enum.Material.Neon, Parent = folder })
		kill:SetAttribute("IsKillBrick", true)
	end
	return folder
end

function MapBuilder.CreateNature(root)
	local folder = makeModel("Nature", root)
	local pos = MapConfig.Layout.NaturePos
	makePart({ Name = "Lake", Size = Vector3.new(40, 2, 30), Position = pos + Vector3.new(0, -0.5, 0), Color = MapConfig.Colors.Water, Material = Enum.Material.Water, CanCollide = false, Parent = folder })
	for i = 1, 8 do makePart({ Name = "BridgePlank"..i, Size = Vector3.new(4, 0.6, 2), Position = pos + Vector3.new(-16+i*4, 1, 0), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = folder }) end
	for i = 1, 12 do
		local angle = (i/12)*math.pi*2
		local r = 28 + (i%3)
		makeTree(pos + Vector3.new(math.cos(angle)*r, 0, math.sin(angle)*r), folder)
	end
	makePart({ Name = "Bench1", Size = Vector3.new(5, 1, 2), Position = pos + Vector3.new(-20, 1, 20), Color = MapConfig.Colors.Wood, Material = MapConfig.Materials.Wood, Parent = folder })
	makeNote("Something waits below the third house.", pos + Vector3.new(0, 0.5, 3), folder)
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
	for i = 1, 5 do makePart({ Name = "Tower"..i, Size = Vector3.new(4, 3, 4), Position = Vector3.new(180, (i-1)*3 + 1.5, -80), Color = Color3.fromRGB(140,100,60), Material = MapConfig.Materials.Wood, Parent = lookout }) end
	makePart({ Name = "Platform", Size = Vector3.new(10, 1, 10), Position = Vector3.new(180, 15.5, -80), Color = Color3.fromRGB(160,120,80), Parent = lookout })
	makeSign("SECRET VIEW", Vector3.new(180, 18, -80), Vector3.new(6, 2, 1), lookout)
	makeNote("You can see everything from here... almost.", Vector3.new(180, 17, -78), lookout)
	return spawnFolder, secrets
end

function MapBuilder.BuildFullMap(parent)
	local root = makeModel(MapConfig.MapName, parent or workspace)
	print("[MapBuilder] Generando Robloxia 2009 v0.6...")
	MapBuilder.CreateBaseAndPlaza(root)
	MapBuilder.CreateHappyHome(root)
	MapBuilder.CreateConstructionYard(root)
	MapBuilder.CreateRoleplayDistrict(root)
	MapBuilder.CreateObby(root)
	MapBuilder.CreateNature(root)
	MapBuilder.CreateSpawnAndSecrets(root)
	print("[MapBuilder] Listo. Casa #3 = tejado oscuro + KEEP OUT + hatch DOWN.")
	return root
end

return MapBuilder
