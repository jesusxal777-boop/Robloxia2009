--[[
	Open Cloud iPad bundle for Robloxia2009.
	This is a combined source for the existing ServerScriptService/Robloxia/MapBootstrap Script.
	It inlines RPExpansion so the beta Engine Instances API does not need to create new instances.
	Generated from MapBootstrap.server.lua + RPExpansion.lua. Regenerate after changing either source.
	Do not use this file as a Rojo project source; use it only for the documented Open Cloud update route.
]]

--[[
	MapBootstrap.lua
	Script principal. Colócalo como Script en ServerScriptService/Robloxia/
	o como el script que se ejecuta al iniciar el servidor.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Esperar a que los módulos estén listos
local RobloxiaFolder = script.Parent
local MapConfig = require(RobloxiaFolder:WaitForChild("MapConfig"))
local MapBuilder = require(RobloxiaFolder:WaitForChild("MapBuilder"))
local ARGSystem = require(RobloxiaFolder:WaitForChild("ARGSystem"))
local AssetRegistry = require(RobloxiaFolder:WaitForChild("AssetRegistry"))
local RPExpansion = (function()
--[[
	RPExpansion.lua
	Roleplay systems for Robloxia 2009.
	All purchases, money changes, home ownership and inventory changes are server-authoritative.
	Models are cloned from ServerStorage by their exact names; missing assets use safe procedural fallbacks.
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")

local RPExpansion = {}

local CONFIG = {
	StartingMoney = 100,
	WorkPay = 35,
	WorkCooldown = 45,
	BagCapacity = 5,
	FridgeCapacity = 8,
	TornadoInterval = 900,
	TornadoChance = 0.08,
	TornadoAssetId = 7019541974,
	TornadoSirenId = 90738042,
	TVChannelSoundId = 15930255433,
	TVImageId = 301987447, -- Provided by the project owner; only used if confirmed in Studio.
}

local HOME_SLOTS = {
	{ template = "House",  name = "RP_House1", position = Vector3.new(-195, 0, 175) },
	{ template = "House2", name = "RP_House2", position = Vector3.new(-145, 0, 175) },
	{ template = "House3", name = "RP_House3", position = Vector3.new(-95, 0, 175) },
}

local BUILDINGS = {
	{ template = "Grocery Store", name = "RP_GroceryStore", position = Vector3.new(160, 0, -170), job = "Grocery Store" },
	{ template = "Dealership", name = "RP_Dealership", position = Vector3.new(70, 0, -170), job = "Dealership" },
	{ template = "Car Repair Shop", name = "RP_CarRepairShop", position = Vector3.new(145, 0, 150) },
	{ template = "CarWash", name = "RP_CarWash", position = Vector3.new(65, 0, 190) },
	{ template = "Police station", name = "RP_PoliceStation", position = Vector3.new(200, 0, 65) },
}

local FOOD = {
	Apple = { price = 5, fridge = true, heal = 8 },
	Milk = { price = 10, fridge = true, heal = 12 },
	Bread = { price = 6, fridge = false, heal = 7 },
	Cheese = { price = 9, fridge = true, heal = 10 },
	Cereal = { price = 8, fridge = false, heal = 9 },
}

local dataByUser = {}
local homeByUser = {}
local homePrompts = {}
local tvStates = {}
local tvList = {}
local allFridges = {}
local allCars = {}
local workLastAt = {}
local noticeEvent
local expansionRoot

local function notify(player, text)
	if player and player.Parent == Players then
		player:SetAttribute("RPNotice", text)
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if not playerGui then
			local ok, result = pcall(function() return player:WaitForChild("PlayerGui", 3) end)
			if ok then playerGui = result end
		end
		if playerGui then
			local previous = playerGui:FindFirstChild("RobloxiaRPNotice")
			if previous then previous:Destroy() end
			local gui = Instance.new("ScreenGui")
			gui.Name = "RobloxiaRPNotice"
			gui.ResetOnSpawn = false
			gui.DisplayOrder = 20
			gui.Parent = playerGui
			local frame = Instance.new("Frame")
			frame.AnchorPoint = Vector2.new(0.5, 0)
			frame.Position = UDim2.new(0.5, 0, 0, 16)
			frame.Size = UDim2.new(0.88, 0, 0, 54)
			frame.BackgroundColor3 = Color3.fromRGB(25, 35, 45)
			frame.BackgroundTransparency = 0.08
			frame.Parent = gui
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = frame
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -18, 1, -10)
			label.Position = UDim2.new(0, 9, 0, 5)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.Code
			label.TextColor3 = Color3.fromRGB(245, 245, 235)
			label.TextSize = 16
			label.TextWrapped = true
			label.Text = tostring(text)
			label.Parent = frame
			task.delay(4, function() if gui.Parent then gui:Destroy() end end)
		end
		print("[Robloxia RP] " .. player.Name .. ": " .. text)
	end
end

local function notifyAll(text)
	for _, player in ipairs(Players:GetPlayers()) do
		notify(player, text)
	end
end

local function getData(player)
	local data = dataByUser[player.UserId]
	if not data then
		data = {
			bag = {},
			fridge = {},
			pendingDelivery = nil,
			bagModel = nil,
			ownedCars = {},
		}
		dataByUser[player.UserId] = data
	end
	return data
end

local function moneyValue(player)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Money")
end

local function changeMoney(player, amount)
	local money = moneyValue(player)
	if not money then return false end
	if amount < 0 and money.Value < -amount then
		notify(player, "No tienes suficiente dinero.")
		return false
	end
	money.Value = math.max(0, money.Value + amount)
	return true
end

local function setupPlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	local money = leaderstats:FindFirstChild("Money")
	if not money then
		money = Instance.new("IntValue")
		money.Name = "Money"
		money.Value = CONFIG.StartingMoney
		money.Parent = leaderstats
	end
	if player:GetAttribute("RPJob") == nil then player:SetAttribute("RPJob", "Unemployed") end
	getData(player)
end

local function getParts(instance)
	local parts = {}
	if instance:IsA("BasePart") then
		table.insert(parts, instance)
	end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then table.insert(parts, descendant) end
	end
	return parts
end

local function firstPart(instance)
	if instance:IsA("BasePart") then return instance end
	if instance:IsA("Model") and instance.PrimaryPart then return instance.PrimaryPart end
	local preferred = { "Door", "Display", "Screen", "Body", "Handle", "Main", "HumanoidRootPart" }
	for _, name in ipairs(preferred) do
		local found = instance:FindFirstChild(name, true)
		if found and found:IsA("BasePart") then return found end
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function stripScripts(instance)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		end
	end
	if instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
		instance:Destroy()
	end
end

local function moveBottomTo(instance, target)
	local ok, boxCFrame, boxSize = pcall(function()
		if instance:IsA("Model") then
			return instance:GetBoundingBox()
		elseif instance:IsA("BasePart") then
			return instance.CFrame, instance.Size
		end
		error("No se puede colocar este objeto")
	end)
	if not ok or not boxCFrame or not boxSize then return false end
	local bottomY = boxCFrame.Position.Y - boxSize.Y / 2
	local offset = Vector3.new(target.X - boxCFrame.Position.X, target.Y - bottomY, target.Z - boxCFrame.Position.Z)
	if instance:IsA("Model") then
		instance:PivotTo(instance:GetPivot() + offset)
	else
		instance.CFrame = instance.CFrame + offset
	end
	return true
end

local function cloneStatic(templateName, target, parent, newName)
	local template = ServerStorage:FindFirstChild(templateName)
	if not template then
		warn("[Robloxia RP] Falta ServerStorage." .. templateName)
		return nil
	end
	local clone = template:Clone()
	stripScripts(clone)
	clone.Name = newName or templateName
	clone.Parent = parent
	moveBottomTo(clone, target)
	for _, part in ipairs(getParts(clone)) do
		part.Anchored = true
		part.CanTouch = true
	end
	return clone
end

local function makePart(name, size, position, color, parent, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color or Color3.fromRGB(120, 120, 120)
	part.Material = material or Enum.Material.Plastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Studs
	part.BottomSurface = Enum.SurfaceType.Studs
	part.Parent = parent
	return part
end

local function addPrompt(part, name, action, objectText, callback, distance)
	if not part or not part:IsA("BasePart") then return nil end
	local old = part:FindFirstChild(name)
	if old and old:IsA("ProximityPrompt") then old:Destroy() end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = action
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = distance or 12
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	prompt.Enabled = true
	prompt.Parent = part
	prompt.Triggered:Connect(callback)
	return prompt
end

local function makeLabel(part, name, text, color)
	local gui = part:FindFirstChild(name)
	if gui then gui:Destroy() end
	gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(512, 256)
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(25, 35, 45)
	label.BackgroundTransparency = 0.12
	label.TextColor3 = color or Color3.fromRGB(245, 245, 235)
	label.Text = text
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.Code
	label.Parent = gui
	return label
end

local function setAnchored(instance, anchored)
	for _, part in ipairs(getParts(instance)) do
		part.Anchored = anchored
		part.CanCollide = not anchored
	end
end

local function weldModelToRoot(model, rootPart, carrier)
	local target = carrier.CFrame * CFrame.new(0, -0.2, -1.8)
	if model:IsA("Model") then
		model:PivotTo(target)
	else
		model.CFrame = target
	end
	local parts = getParts(model)
	for _, part in ipairs(parts) do
		part.Anchored = false
		part.CanCollide = false
		part.Massless = true
		if part ~= rootPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rootPart
			weld.Part1 = part
			weld.Parent = rootPart
		end
	end
	local carryWeld = Instance.new("WeldConstraint")
	carryWeld.Name = "RPCarryWeld"
	carryWeld.Part0 = carrier
	carryWeld.Part1 = rootPart
	carryWeld.Parent = rootPart
end

local function bagCount(data)
	return #data.bag
end

local function refreshBagVisual(player)
	local data = getData(player)
	player:SetAttribute("RPGroceryCount", #data.bag)
	if #data.bag == 0 then
		if data.bagModel then data.bagModel:Destroy() data.bagModel = nil end
		return
	end
	if data.bagModel and data.bagModel.Parent then return end
	local template = ServerStorage:FindFirstChild("Grocery Bag")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not template or not root then return end
	local bag = template:Clone()
	bag.Name = "GroceryBag_" .. player.UserId
	bag.Anchored = false
	bag.CanCollide = false
	bag.Massless = true
	bag.CFrame = root.CFrame * CFrame.new(1.1, -0.35, -1.1)
	bag.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = bag
	weld.Parent = bag
	data.bagModel = bag
	addPrompt(bag, "EatFoodPrompt", "Comer alimento", "Bolsa de compras", function()
		local itemName = table.remove(data.bag, 1)
		if not itemName then return end
		local characterNow = player.Character
		local humanoid = characterNow and characterNow:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (FOOD[itemName].heal or 8)) end
		notify(player, "Comiste: " .. itemName .. ". Quedan " .. #data.bag .. " productos.")
		refreshBagVisual(player)
	end, 8)
	player:SetAttribute("RPGroceryCount", #data.bag)
end

local function addFood(player, itemName)
	local data = getData(player)
	if not FOOD[itemName] then return end
	if bagCount(data) >= CONFIG.BagCapacity then
		notify(player, "La bolsa está llena. Guarda alimentos en el refrigerador o come algo.")
		return
	end
	if not changeMoney(player, -FOOD[itemName].price) then return end
	table.insert(data.bag, itemName)
	refreshBagVisual(player)
	notify(player, itemName .. " comprado. Bolsa: " .. #data.bag .. "/" .. CONFIG.BagCapacity)
end

local function findOwnedHouse(player)
	return homeByUser[player.UserId]
end

local function houseContains(house, position)
	if not house or not house.Parent then return false end
	local ok, box, size = pcall(function() return house:GetBoundingBox() end)
	if not ok then return false end
	local localPosition = box:PointToObjectSpace(position)
	return math.abs(localPosition.X) < size.X / 2 - 2
		and math.abs(localPosition.Z) < size.Z / 2 - 2
		and localPosition.Y > -size.Y / 2
		and localPosition.Y < size.Y / 2
end

local function markPlaced(instance)
	instance:SetAttribute("RPPlacedObject", true)
	for _, part in ipairs(getParts(instance)) do
		part:SetAttribute("RPPlacedObject", true)
	end
end

local function placementClear(house, target)
	for _, part in ipairs(house:GetDescendants()) do
		if part:IsA("BasePart") and part:GetAttribute("RPPlacedObject") then
			if (part.Position - target).Magnitude < 4 then
				return false
			end
		end
	end
	return true
end

local function attachTV(tv)
	local part = firstPart(tv)
	if not part then return end
	local display = tv:FindFirstChild("Display", true) or tv:FindFirstChild("Screen", true)
	if not (display and display:IsA("BasePart")) then display = part end
	local label = makeLabel(display, "RP-TV-Screen", "ROBLOXIA 2009\nRETRO CHANNEL", Color3.fromRGB(125, 255, 150))
	local state = { instance = tv, speaker = display, label = label, isOn = false, mode = "off", sound = nil }
	tvStates[tv] = state
	table.insert(tvList, state)
	local prompt = addPrompt(part, "TVPowerPrompt", "Encender TV", "Televisor", function(player)
		if not tv.Parent then return end
		if state.sound then state.sound:Stop() state.sound:Destroy() state.sound = nil end
		state.isOn = not state.isOn
		if state.isOn then
			local template = ServerStorage:FindFirstChild("RetroRobloxChannel")
			local sound = template and template:Clone() or Instance.new("Sound")
			sound.Name = "RP-TV-Audio"
			sound.SoundId = "rbxassetid://" .. tostring(CONFIG.TVChannelSoundId)
			sound.Looped = true
			sound.Volume = 0.55
			sound.RollOffMaxDistance = 65
			sound.Parent = display
			sound:Play()
			state.sound = sound
			state.mode = "channel"
			label.Text = "ROBLOXIA 2009\nRETRO CHANNEL"
			prompt.ActionText = "Apagar TV"
			notify(player, "RetroRobloxChannel está encendido.")
		else
			state.mode = "off"
			label.Text = "TV APAGADA"
			prompt.ActionText = "Encender TV"
			notify(player, "Televisor apagado.")
		end
	end, 10)
	return state
end

local function createPC(parent, target)
	local pc = Instance.new("Model")
	pc.Name = "HomePC"
	pc.Parent = parent
	local base = target
	local tower = makePart("PC_Tower", Vector3.new(1.3, 2.4, 1.8), base + Vector3.new(1.5, 1.2, 0), Color3.fromRGB(55, 55, 60), pc)
	local monitor = makePart("PC_Monitor", Vector3.new(3.2, 2.2, 0.35), base + Vector3.new(-0.2, 2.3, 0), Color3.fromRGB(45, 45, 50), pc)
	local screen = makePart("PC_Screen", Vector3.new(2.7, 1.65, 0.08), base + Vector3.new(-0.2, 2.35, -0.22), Color3.fromRGB(35, 80, 100), pc)
	screen.CanCollide = false
	makeLabel(screen, "RP-PC-Screen", "ROBLOXIA\nDESKTOP 2009", Color3.fromRGB(150, 230, 255))
	makePart("Keyboard", Vector3.new(2.4, 0.18, 0.8), base + Vector3.new(-0.2, 1.1, 1.1), Color3.fromRGB(35, 35, 40), pc)
	markPlaced(pc)
	addPrompt(monitor, "PCUsePrompt", "Usar", "PC doméstico", function(player)
		if findOwnedHouse(player) ~= parent then
			notify(player, "Este PC no está en tu casa.")
			return
		end
		notify(player, "PC doméstico: escritorio clásico de Robloxia 2009.")
	end, 8)
	return pc
end

local function placeAssetInHouse(templateName, house, dx, dz, newName)
	local box, size = house:GetBoundingBox()
	local target = Vector3.new(box.Position.X + size.X * dx, box.Position.Y - size.Y / 2, box.Position.Z + size.Z * dz)
	local clone = cloneStatic(templateName, target, house, newName)
	if clone then markPlaced(clone) end
	return clone
end

local function attachFridge(fridge, house)
	local part = firstPart(fridge)
	if not part then return end
	local houseData = { inventory = {}, prompts = {} }
	allFridges[house] = houseData
	addPrompt(part, "StoreGroceriesPrompt", "Guardar alimentos", "Refrigerador", function(player)
		if findOwnedHouse(player) ~= house then notify(player, "Este refrigerador pertenece a otra casa.") return end
		local data = getData(player)
		local moved = 0
		for index = #data.bag, 1, -1 do
			local itemName = data.bag[index]
			if FOOD[itemName] and FOOD[itemName].fridge then
				local total = 0
				for _, count in pairs(houseData.inventory) do total += count end
				if total >= CONFIG.FridgeCapacity then break end
				houseData.inventory[itemName] = (houseData.inventory[itemName] or 0) + 1
				table.remove(data.bag, index)
				moved += 1
			end
		end
		refreshBagVisual(player)
		notify(player, moved > 0 and ("Guardaste " .. moved .. " alimento(s).") or "No hay alimentos refrigerables en la bolsa o el refrigerador está lleno.")
		for itemName, prompt in pairs(houseData.prompts) do
			prompt.Enabled = (houseData.inventory[itemName] or 0) > 0
		end
	end, 8)
	for itemName, itemInfo in pairs(FOOD) do
		if itemInfo.fridge then
			local prompt = addPrompt(part, "Take_" .. itemName, "Retirar " .. itemName, "Refrigerador", function(player)
				if findOwnedHouse(player) ~= house then notify(player, "Este refrigerador pertenece a otra casa.") return end
				local data = getData(player)
				if (houseData.inventory[itemName] or 0) <= 0 then notify(player, "No queda " .. itemName .. " en el refrigerador.") return end
				if #data.bag >= CONFIG.BagCapacity then notify(player, "La bolsa está llena.") return end
				houseData.inventory[itemName] -= 1
				if houseData.inventory[itemName] <= 0 then houseData.inventory[itemName] = nil end
				table.insert(data.bag, itemName)
				refreshBagVisual(player)
				notify(player, "Retiraste " .. itemName .. ".")
				for name, p in pairs(houseData.prompts) do p.Enabled = (houseData.inventory[name] or 0) > 0 end
			end, 8)
			prompt.Enabled = false
			houseData.prompts[itemName] = prompt
		end
	end
end

local function randomSofaColor()
	local colors = {
		Color3.fromRGB(170, 45, 45), Color3.fromRGB(35, 90, 155),
		Color3.fromRGB(55, 125, 65), Color3.fromRGB(210, 170, 95),
		Color3.fromRGB(90, 75, 120), Color3.fromRGB(95, 95, 95),
	}
	return colors[math.random(1, #colors)]
end

local function attachSofa(sofa, house)
	local part = firstPart(sofa)
	if not part then return end
	addPrompt(part, "SofaColorPrompt", "Cambiar color", "Sofá", function(player)
		if findOwnedHouse(player) ~= house then notify(player, "Este sofá pertenece a otra casa.") return end
		local color = randomSofaColor()
		local chosen, largest = nil, 0
		for _, p in ipairs(getParts(sofa)) do
			local lower = string.lower(p.Name)
			if not string.find(lower, "leg") and not string.find(lower, "foot") and not string.find(lower, "wood") then
				local volume = p.Size.X * p.Size.Y * p.Size.Z
				if volume > largest then chosen, largest = p, volume end
			end
		end
		if chosen then chosen.Color = color end
		notify(player, "Color del sofá actualizado.")
	end, 8)
end

local function claimHouse(player, house)
	if homeByUser[player.UserId] then
		notify(player, "Ya tienes una casa. Libérala antes de reclamar otra.")
		return
	end
	local owner = house:GetAttribute("OwnerUserId") or 0
	if owner ~= 0 and owner ~= player.UserId then
		notify(player, "Esta casa ya tiene dueño.")
		return
	end
	house:SetAttribute("OwnerUserId", player.UserId)
	house:SetAttribute("OwnerName", player.Name)
	homeByUser[player.UserId] = house
	player:SetAttribute("RPHome", house.Name)
	local prompt = homePrompts[house]
	if prompt then
		prompt.ActionText = "Casa de " .. player.Name
		prompt.ObjectText = house.Name
		prompt.Enabled = false
	end
	-- These are the owner's default furniture and television. They are children of the house model.
	local sofa = placeAssetInHouse("Sofa", house, -0.2, 0.15, "OwnerSofa")
	if sofa then attachSofa(sofa, house) end
	local fridge = placeAssetInHouse("Fridge", house, 0.23, 0.15, "OwnerFridge")
	if fridge then attachFridge(fridge, house) end
	local tv = placeAssetInHouse("TV1", house, 0, -0.18, "OwnerTV")
	if tv then attachTV(tv) end
	notify(player, "¡Casa reclamada! Recibiste sofá, refrigerador y TV1.")
end

local function addJobPrompt(model, jobName)
	local part = firstPart(model)
	if not part then return end
	addPrompt(part, "WorkShiftPrompt", "Trabajar (+$" .. CONFIG.WorkPay .. ")", jobName, function(player)
		local now = os.clock()
		local last = workLastAt[player.UserId] or 0
		if now - last < CONFIG.WorkCooldown then
			notify(player, "Siguiente turno disponible en " .. math.ceil(CONFIG.WorkCooldown - (now - last)) .. " s.")
			return
		end
		workLastAt[player.UserId] = now
		player:SetAttribute("RPJob", jobName)
		if changeMoney(player, CONFIG.WorkPay) then
			notify(player, "Turno completado en " .. jobName .. ": +$" .. CONFIG.WorkPay .. ".")
		end
	end, 12)
end

local spawnDeliveryCrate

local function createTechStore(position, parent)
	local model = Instance.new("Model")
	model.Name = "RP_TechStore"
	model.Parent = parent
	local floor = makePart("Floor", Vector3.new(42, 1, 32), position + Vector3.new(0, 0.5, 0), Color3.fromRGB(155, 155, 150), model, Enum.Material.Concrete)
	makePart("BackWall", Vector3.new(42, 10, 1), position + Vector3.new(0, 5.5, 16), Color3.fromRGB(180, 190, 195), model)
	makePart("LeftWall", Vector3.new(1, 10, 32), position + Vector3.new(-21, 5.5, 0), Color3.fromRGB(180, 190, 195), model)
	makePart("RightWall", Vector3.new(1, 10, 32), position + Vector3.new(21, 5.5, 0), Color3.fromRGB(180, 190, 195), model)
	local sign = makePart("TechSign", Vector3.new(18, 5, 0.6), position + Vector3.new(0, 9, -16.2), Color3.fromRGB(25, 45, 65), model)
	makeLabel(sign, "TechSignGui", "TECH STORE\nROBLOXIA 2009", Color3.fromRGB(130, 220, 255))
	local counter = makePart("Counter", Vector3.new(30, 2, 3), position + Vector3.new(0, 1.5, -5), Color3.fromRGB(90, 100, 110), model)
	addJobPrompt(model, "Tech Store")
	local tvStand = makePart("TVStand", Vector3.new(4, 1, 3), position + Vector3.new(-8, 1, 2), Color3.fromRGB(90, 70, 50), model)
	local pcStand = makePart("PCStand", Vector3.new(4, 1, 3), position + Vector3.new(8, 1, 2), Color3.fromRGB(90, 70, 50), model)
	addPrompt(tvStand, "BuyTVPrompt", "Comprar TV ($120)", "Televisor", function(player)
		local data = getData(player)
		if data.pendingDelivery then notify(player, "Primero entrega la caja que llevas.") return end
		if changeMoney(player, -120) then
			data.pendingDelivery = { kind = "TV", template = "TV", crateTemplate = "Wood Crate" }
			task.defer(function() if spawnDeliveryCrate then spawnDeliveryCrate(player) end end)
			notify(player, "TV comprado. Recoge la caja y llévala a tu casa.")
		end
	end)
	addPrompt(pcStand, "BuyPCPrompt", "Comprar PC ($200)", "Computadora", function(player)
		local data = getData(player)
		if data.pendingDelivery then notify(player, "Primero entrega la caja que llevas.") return end
		if changeMoney(player, -200) then
			data.pendingDelivery = { kind = "PC", template = "PC", crateTemplate = "Crate" }
			task.defer(function() if spawnDeliveryCrate then spawnDeliveryCrate(player) end end)
			notify(player, "PC comprado. Recoge la caja y llévala a tu casa.")
		end
	end)
	return model
end

local function createCrateFallback(name, parent)
	local part = makePart(name, Vector3.new(3, 3, 3), Vector3.new(0, 0, 0), Color3.fromRGB(125, 90, 55), parent, Enum.Material.Wood)
	return part
end

spawnDeliveryCrate = function(player)
	local data = getData(player)
	if not data.pendingDelivery or data.pendingDelivery.crate then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local delivery = data.pendingDelivery
	local template = ServerStorage:FindFirstChild(delivery.crateTemplate)
	local crate
	if template then
		crate = template:Clone()
		stripScripts(crate)
		crate.Name = "DeliveryCrate_" .. player.UserId
		crate.Parent = expansionRoot
		moveBottomTo(crate, root.Position + Vector3.new(0, -2, -3))
		for _, part in ipairs(getParts(crate)) do part.Anchored = true end
	else
		crate = createCrateFallback("DeliveryCrate_" .. player.UserId, expansionRoot)
		crate.Position = root.Position + Vector3.new(0, -1, -3)
	end
	local promptPart = firstPart(crate)
	if not promptPart then crate:Destroy() return end
	delivery.crate = crate
	addPrompt(promptPart, "PickupDeliveryPrompt", "Recoger caja", delivery.kind == "TV" and "Caja de TV" or "Caja de PC", function(p)
		if p ~= player then notify(p, "Esta caja pertenece a otro jugador.") return end
		if not crate.Parent or not p.Character then return end
		local carrier = p.Character:FindFirstChild("HumanoidRootPart")
		if not carrier then return end
		local currentData = getData(p)
		local current = currentData.pendingDelivery
		if not current or current.crate ~= crate then return end
		local rootPart = firstPart(crate)
		if not rootPart then return end
		weldModelToRoot(crate, rootPart, carrier)
		local pickup = rootPart:FindFirstChild("PickupDeliveryPrompt")
		if pickup then pickup:Destroy() end
		addPrompt(rootPart, "InstallDeliveryPrompt", "Instalar en casa", "Caja de " .. current.kind, function(owner)
			if owner ~= player then return end
			local house = findOwnedHouse(owner)
			if not house then notify(owner, "Primero reclama una casa.") return end
			local char = owner.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp or not houseContains(house, hrp.Position) then
				notify(owner, "Entra en tu casa para colocar el objeto.")
				return
			end
			local target = hrp.Position + hrp.CFrame.LookVector * 3
			if not houseContains(house, target) then notify(owner, "Acércate a una zona libre dentro de la casa.") return end
			if not placementClear(house, target) then
				notify(owner, "Ese espacio está ocupado. Muévete a otra zona de la casa.")
				return
			end
			if current.kind == "TV" then
				local tv = cloneStatic(current.template, Vector3.new(target.X, 0, target.Z), house, "PurchasedTV")
				if tv then markPlaced(tv) attachTV(tv) end
			elseif current.kind == "PC" then
				createPC(house, Vector3.new(target.X, 0, target.Z))
			end
			crate:Destroy()
			currentData.pendingDelivery = nil
			notify(owner, current.kind .. " instalado en tu casa.")
		end, 8)
		notify(player, "Caja recogida. Entra en tu casa y usa Instalar en casa.")
	end, 10)
end

local function createGroceryShelves(groceryModel, position)
	local base = position + Vector3.new(0, 0, 9)
	local index = 0
	for itemName, info in pairs(FOOD) do
		index += 1
		local x = (index - 3) * 5
		local stand = makePart("Shelf_" .. itemName, Vector3.new(3, 2, 3), base + Vector3.new(x, 1, 0), Color3.fromRGB(135, 95, 55), expansionRoot, Enum.Material.Wood)
		local label = makePart("Label_" .. itemName, Vector3.new(3, 1.1, 0.2), base + Vector3.new(x, 2.7, -1.6), Color3.fromRGB(30, 45, 55), expansionRoot)
		makeLabel(label, "ShelfLabel", itemName .. "\n$" .. info.price, Color3.fromRGB(245, 245, 235))
		addPrompt(stand, "Buy_" .. itemName, "Comprar $" .. info.price, itemName, function(player)
			addFood(player, itemName)
		end, 8)
	end
	if groceryModel then addJobPrompt(groceryModel, "Grocery Store") end
end

local function createCarStands(position)
	local folder = Instance.new("Folder")
	folder.Name = "CarPurchaseStands"
	folder.Parent = expansionRoot
	for index = 1, 4 do
		local carName = tostring(index)
		local stand = makePart("CarStand" .. index, Vector3.new(5, 1, 5), position + Vector3.new((index - 2.5) * 10, 0.5, 18), Color3.fromRGB(90, 100, 110), folder, Enum.Material.Concrete)
		local label = makePart("CarLabel" .. index, Vector3.new(5, 2, 0.3), position + Vector3.new((index - 2.5) * 10, 2, 15.3), Color3.fromRGB(25, 45, 65), folder)
		makeLabel(label, "CarLabelGui", "CAR " .. index .. "\n$" .. (index * 150), Color3.fromRGB(245, 245, 235))
		addPrompt(stand, "BuyCar" .. index, "Comprar Car " .. index .. " ($" .. (index * 150) .. ")", "Concesionaria", function(player)
			local price = index * 150
			if not changeMoney(player, -price) then return end
			local carsFolder = ServerStorage:FindFirstChild("2009Cars")
			local template = carsFolder and carsFolder:FindFirstChild(carName)
			if not template then
				changeMoney(player, price)
				notify(player, "No se encontró el modelo Car " .. index .. "; se devolvió tu dinero.")
				return
			end
			local car = template:Clone()
			car.Name = "Car " .. index .. " - " .. player.Name
			car:SetAttribute("OwnerUserId", player.UserId)
			car:SetAttribute("CarNumber", index)
			car:SetAttribute("Condition", 100)
			car:SetAttribute("Washed", false)
			car.Parent = expansionRoot
			local spawnPosition = position + Vector3.new((index - 2.5) * 10, 0, 28)
			moveBottomTo(car, spawnPosition)
			for _, part in ipairs(getParts(car)) do
				part.Anchored = false
			end
			table.insert(allCars, car)
			table.insert(getData(player).ownedCars, car)
			local carPart = firstPart(car)
			addPrompt(carPart, "RepaintCarPrompt", "Cambiar pintura", "Car " .. index, function(owner)
				if car:GetAttribute("OwnerUserId") ~= owner.UserId then notify(owner, "No eres dueño de este vehículo.") return end
				local palette = { Color3.fromRGB(196, 40, 28), Color3.fromRGB(13, 105, 172), Color3.fromRGB(75, 151, 75), Color3.fromRGB(245, 205, 48), Color3.fromRGB(245, 245, 245), Color3.fromRGB(40, 40, 40) }
				local colorIndex = (car:GetAttribute("PaintIndex") or 0) % #palette + 1
				local changed = 0
				for _, part in ipairs(getParts(car)) do
					local name = string.lower(part.Name)
					local excluded = string.find(name, "wheel") or string.find(name, "tire") or string.find(name, "glass") or string.find(name, "window") or string.find(name, "light") or string.find(name, "seat") or string.find(name, "interior") or string.find(name, "trim")
					local paintable = string.find(name, "body") or string.find(name, "paint") or string.find(name, "door") or string.find(name, "hood") or string.find(name, "roof") or string.find(name, "bumper") or string.find(name, "fender")
					if paintable and not excluded then part.Color = palette[colorIndex] changed += 1 end
				end
				car:SetAttribute("PaintIndex", colorIndex)
				notify(owner, changed > 0 and "Pintura del vehículo actualizada." or "Este modelo no tiene piezas de carrocería identificadas para recolorear.")
			end, 8)
			notify(player, "Compraste " .. car.Name .. ". Usa su asiento de vehículo si el modelo lo incluye.")
		end, 10)
	end
end

local function findNearestOwnedCar(player, position, maxDistance)
	local best, bestDistance
	for _, car in ipairs(allCars) do
		if car.Parent and car:GetAttribute("OwnerUserId") == player.UserId then
			local part = firstPart(car)
			if part then
				local distance = (part.Position - position).Magnitude
				if distance <= maxDistance and (not bestDistance or distance < bestDistance) then best, bestDistance = car, distance end
			end
		end
	end
	return best
end

local function addServicePrompt(model, serviceName)
	local part = firstPart(model)
	if not part then return end
	addPrompt(part, "ServicePrompt", serviceName == "CarWash" and "Lavar vehículo ($10)" or "Reparar vehículo ($25)", serviceName == "CarWash" and "Autolavado" or "Vulcanizadora", function(player)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local car = findNearestOwnedCar(player, root.Position, 65)
		if not car then notify(player, "Acerca tu propio vehículo al servicio.") return end
		local price = serviceName == "CarWash" and 10 or 25
		if not changeMoney(player, -price) then return end
		if serviceName == "CarWash" then
			car:SetAttribute("Washed", true)
			notify(player, "Vehículo lavado.")
		else
			car:SetAttribute("Condition", 100)
			notify(player, "Vehículo reparado.")
		end
	end, 12)
end

local function createTornadoVisual(position)
	local model
	local ok, asset = pcall(function() return InsertService:LoadAsset(CONFIG.TornadoAssetId) end)
	if ok and asset then
		model = asset:GetChildren()[1] or asset
		model.Parent = expansionRoot
		stripScripts(model)
		for _, part in ipairs(getParts(model)) do part.Anchored = true part.CanCollide = false end
		moveBottomTo(model, position)
		return model
	end
	model = Instance.new("Model")
	model.Name = "ProceduralTornado"
	model:SetAttribute("SourceAssetId", CONFIG.TornadoAssetId)
	model.Parent = expansionRoot
	for index = 1, 7 do
		local width = 2.5 + index * 1.3
		local height = 3.5
		local part = Instance.new("Part")
		part.Name = "FunnelLayer" .. index
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(height, width, width)
		part.CFrame = CFrame.new(position + Vector3.new(0, index * 3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		part.Color = Color3.fromRGB(100 + index * 5, 100 + index * 5, 105 + index * 5)
		part.Transparency = 0.28
		part.Anchored = true
		part.CanCollide = false
		part.Parent = model
		if index == 1 then model.PrimaryPart = part end
	end
	return model
end

local function startTornadoEvent()
	if not expansionRoot or not expansionRoot.Parent then return end
	local start = Vector3.new(math.random(-100, 130), 0, math.random(-150, 120))
	local tornado = createTornadoVisual(start)
	local soundPart = firstPart(tornado)
	if soundPart then
		local template = ServerStorage:FindFirstChild("Tornado Siren")
		local siren = template and template:Clone() or Instance.new("Sound")
		siren.Name = "TornadoWarning"
		siren.SoundId = "rbxassetid://" .. tostring(CONFIG.TornadoSirenId)
		siren.Volume = 0.9
		siren.RollOffMaxDistance = 250
		siren.Parent = soundPart
		siren:Play()
	end
	notifyAll("ALERTA: ¡Tornado en Robloxia! Refúgiate y escucha las televisiones.")
	for _, state in ipairs(tvList) do
		if state.instance and state.instance.Parent and state.speaker then
			if state.sound then state.sound:Stop() state.sound:Destroy() end
			local template = ServerStorage:FindFirstChild("Tornado Siren")
			local siren = template and template:Clone() or Instance.new("Sound")
			siren.Name = "RP-TV-TornadoSiren"
			siren.SoundId = "rbxassetid://" .. tostring(CONFIG.TornadoSirenId)
			siren.Volume = 0.7
			siren.Looped = false
			siren.Parent = state.speaker
			siren:Play()
			state.sound = siren
			state.mode = "alert"
			state.label.Text = "EMERGENCY ALERT\nTORNADO WARNING"
		end
	end
	task.spawn(function()
		for step = 1, 70 do
			if not tornado.Parent then break end
			pcall(function() tornado:PivotTo(tornado:GetPivot() + Vector3.new(-2, 0, 1.3)) end)
			task.wait(0.5)
		end
		if tornado.Parent then tornado:Destroy() end
		for _, state in ipairs(tvList) do
			if state.instance and state.instance.Parent and state.label then
				state.label.Text = state.isOn and "ROBLOXIA 2009\nRETRO CHANNEL" or "TV APAGADA"
				if state.mode == "alert" then
					if state.sound then state.sound:Stop() state.sound:Destroy() state.sound = nil end
					state.mode = state.isOn and "channel" or "off"
					if state.isOn then
						local template = ServerStorage:FindFirstChild("RetroRobloxChannel")
						local sound = template and template:Clone() or Instance.new("Sound")
						sound.Name = "RP-TV-Audio"
						sound.SoundId = "rbxassetid://" .. tostring(CONFIG.TVChannelSoundId)
						sound.Looped = true
						sound.Volume = 0.55
						sound.Parent = state.speaker
						sound:Play()
						state.sound = sound
					end
				end
			end
		end
		notifyAll("La alerta de tornado ha terminado.")
	end)
end

local function buildHomes()
	local homesFolder = Instance.new("Folder")
	homesFolder.Name = "RP_Homes"
	homesFolder.Parent = expansionRoot
	for _, slot in ipairs(HOME_SLOTS) do
		local house = cloneStatic(slot.template, slot.position, homesFolder, slot.name)
		if house then
			house:SetAttribute("OwnerUserId", 0)
			house:SetAttribute("OwnerName", "")
			local part = firstPart(house)
			local prompt = addPrompt(part, "ClaimHomePrompt", "Reclamar casa", slot.name, function(player)
				claimHouse(player, house)
			end, 12)
			homePrompts[house] = prompt
		end
	end
end

local function buildBuildings()
	local built = {}
	for _, entry in ipairs(BUILDINGS) do
		local model = cloneStatic(entry.template, entry.position, expansionRoot, entry.name)
		built[entry.template] = model
		if model and entry.job then addJobPrompt(model, entry.job) end
	end
	local groceryPos = Vector3.new(160, 0, -170)
	createGroceryShelves(built["Grocery Store"], groceryPos)
	if built["Dealership"] then
		addJobPrompt(built["Dealership"], "Dealership")
		createCarStands(Vector3.new(70, 0, -170))
	end
	if built["Car Repair Shop"] then addServicePrompt(built["Car Repair Shop"], "CarRepairShop") end
	if built["CarWash"] then addServicePrompt(built["CarWash"], "CarWash") end
	createTechStore(Vector3.new(-20, 0, -170), expansionRoot)
end

function RPExpansion.Init(classicMap)
	if not classicMap or not classicMap.Parent then error("RPExpansion necesita el mapa clásico ya creado") end
	local old = classicMap:FindFirstChild("RPExpansion")
	if old then old:Destroy() end
	expansionRoot = Instance.new("Model")
	expansionRoot.Name = "RPExpansion"
	expansionRoot.Parent = classicMap

	noticeEvent = ReplicatedStorage:FindFirstChild("RPNotice")
	if not noticeEvent then
		noticeEvent = Instance.new("RemoteEvent")
		noticeEvent.Name = "RPNotice"
		noticeEvent.Parent = ReplicatedStorage
	end

	for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		local house = homeByUser[player.UserId]
		if house and house.Parent then
			house:SetAttribute("OwnerUserId", 0)
			house:SetAttribute("OwnerName", "")
			local prompt = homePrompts[house]
			if prompt then
				prompt.Enabled = true
				prompt.ActionText = "Reclamar casa"
			end
		end
		local data = dataByUser[player.UserId]
		if data then
			if data.bagModel then data.bagModel:Destroy() end
			if data.pendingDelivery and data.pendingDelivery.crate then data.pendingDelivery.crate:Destroy() end
			for _, car in ipairs(data.ownedCars) do
				if car and car.Parent then car:Destroy() end
			end
		end
		if house and house.Parent then
			for _, child in ipairs(house:GetChildren()) do
				if child:GetAttribute("RPPlacedObject") then
					local state = tvStates[child]
					if state and state.sound then
						state.sound:Stop()
						state.sound:Destroy()
					end
					tvStates[child] = nil
					child:Destroy()
				end
			end
			allFridges[house] = nil
		end
		homeByUser[player.UserId] = nil
		dataByUser[player.UserId] = nil
		workLastAt[player.UserId] = nil
	end)

	buildHomes()
	buildBuildings()

	task.spawn(function()
		while expansionRoot and expansionRoot.Parent do
			task.wait(CONFIG.TornadoInterval)
			if #Players:GetPlayers() > 0 and math.random() < CONFIG.TornadoChance then
				startTornadoEvent()
			end
		end
	end)

	print("[Robloxia RP] RP Expansion inicializada: casas, trabajos, tiendas, vehículos, comida, televisiones y eventos.")
end

return RPExpansion

end)()

print("========================================")
print("  ROBLOXIA 2009 — Map Bootstrap v" .. MapConfig.Version)
print("========================================")

-- Limpiar cualquier mapa anterior del mismo nombre (por si se reinicia el script)
local existing = workspace:FindFirstChild(MapConfig.MapName)
if existing then
	warn("[Bootstrap] Se encontró un mapa anterior. Eliminando para regenerar...")
	existing:Destroy()
	task.wait(0.5)
end

-- Construir el mapa clásico
local classicMap = MapBuilder.BuildFullMap(workspace)

-- Roleplay Expansion (kept separate from the optional ARG).
local rpOk, rpError = pcall(function()
	RPExpansion.Init(classicMap)
end)
if not rpOk then
	warn("[Bootstrap] RP Expansion no pudo iniciar: " .. tostring(rpError))
end

-- Configurar sistema ARG (el sótano secreto)
if MapConfig.ARG.Enabled then
	ARGSystem.Setup(classicMap)
	print("[Bootstrap] Sistema ARG listo. Busca la casa #3 del Roleplay District.")
end

-- Killbricks del obby
local function setupKillBricks(root)
	for _, part in ipairs(root:GetDescendants()) do
		if part:IsA("BasePart") and part:GetAttribute("IsKillBrick") then
			part.Touched:Connect(function(hit)
				local char = hit.Parent
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					hum.Health = 0
				end
			end)
		end
	end
end
setupKillBricks(classicMap)

-- Checkpoints simples del obby (opcional, solo marca)
print("[Bootstrap] Mapa listo. Explora, construye, rolea y... ten cuidado con los sótanos.")

-- Mensaje de bienvenida clásico (solo una vez)
local function onPlayerAdded(player)
	task.wait(2)
	-- Puedes reemplazar esto por tu propio sistema de UI
	print("[Robloxia] " .. player.Name .. " ha entrado a Robloxia 2009")
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end
