--[[
	MapConfig.lua
	Configuracion central de Robloxia 2009
]]

local MapConfig = {}

MapConfig.MapName = "Robloxia2009"
MapConfig.Version = "0.6.0"
MapConfig.ClassicYear = 2009

MapConfig.Assets = {
	HappyHome = {
		Primary = 2833495991,
		FullMap = 141621248,
		HouseOnly = 4674924342,
		Old2010 = 82134451,
	},
	Trees = {
		BasicRound = 13074489391,
		Classic = 29718921,
	},
}

MapConfig.SafeLoad = true
MapConfig.AllowScriptsInAssets = false
MapConfig.AnchorEverything = true
MapConfig.MaxParts = 2500

MapConfig.Colors = {
	Baseplate = Color3.fromRGB(91, 154, 76),
	Path = Color3.fromRGB(163, 162, 165),
	HouseWall = Color3.fromRGB(215, 197, 154),
	HouseRoof = Color3.fromRGB(196, 40, 28),
	BrickYellow = Color3.fromRGB(245, 205, 48),
	BrickRed = Color3.fromRGB(196, 40, 28),
	BrickBlue = Color3.fromRGB(13, 105, 172),
	BrickGreen = Color3.fromRGB(75, 151, 75),
	BrickOrange = Color3.fromRGB(218, 133, 65),
	Wood = Color3.fromRGB(124, 92, 70),
	SignBG = Color3.fromRGB(27, 42, 53),
	SignText = Color3.fromRGB(248, 248, 248),
	Water = Color3.fromRGB(12, 84, 92),
	Danger = Color3.fromRGB(255, 0, 0),
}

MapConfig.Materials = {
	Default = Enum.Material.Plastic,
	Wood = Enum.Material.Wood,
	Grass = Enum.Material.Grass,
	Concrete = Enum.Material.Concrete,
	Brick = Enum.Material.Brick,
}

MapConfig.Layout = {
	BaseSize = Vector3.new(512, 1, 512),
	Spawn = Vector3.new(0, 0.5, 0),
	HappyHomePos = Vector3.new(-80, 0, -40),
	ConstructionYardPos = Vector3.new(60, 0, -30),
	RoleplayDistrictPos = Vector3.new(-120, 0, 80),
	ObbyStart = Vector3.new(120, 0.5, 40),
	NaturePos = Vector3.new(0, 0, 140),
	PlazaCenter = Vector3.new(0, 0, 20),
	SecretHouseIndex = 3,
}

MapConfig.ARG = {
	Enabled = true,
	TriggerMessage = "Something feels wrong...",
	ResetDelay = 1.5,
	NewMapName = "Robloxia_Broken",
	AtmosphereColor = Color3.fromRGB(40, 20, 20),
	FogColor = Color3.fromRGB(30, 10, 10),
	FogEnd = 200,
	SecretCode = "2009NEVERENDED",
	PCRoomName = "ARG_PCRoom",
	BloodMapName = "Robloxia_Blood",
	StoragePC = "PcARG",
	StorageSword = "Sword",
	EddName = "Edd",
}

MapConfig.Signs = {
	{ Text = "WELCOME TO ROBLOXIA!", Size = Vector3.new(12, 6, 1) },
	{ Text = "HAVE FUN!", Size = Vector3.new(8, 4, 1) },
	{ Text = "FREE BRICKS", Size = Vector3.new(10, 5, 1) },
	{ Text = "BUILD HERE", Size = Vector3.new(8, 4, 1) },
	{ Text = "HAPPY HOME", Size = Vector3.new(8, 4, 1) },
	{ Text = "OBBY ->", Size = Vector3.new(6, 3, 1) },
	{ Text = "VISIT THE TOWN", Size = Vector3.new(10, 4, 1) },
	{ Text = "DO NOT ENTER", Size = Vector3.new(6, 3, 1) },
}

return MapConfig
