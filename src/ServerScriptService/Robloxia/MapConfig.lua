--[[
	MapConfig.lua
	Configuración central de Robloxia 2009
	Nunca hardcodear IDs fuera de aquí.
]]

local MapConfig = {}

-- === GENERAL ===
MapConfig.MapName = "Robloxia2009"
MapConfig.Version = "0.1.0"
MapConfig.ClassicYear = 2009

-- === ASSET IDs (verificados en investigación 2026-10-24) ===
-- Si un ID falla, el sistema usa la versión procedural automáticamente.
MapConfig.Assets = {
	HappyHome = {
		Primary = 2833495991,          -- Classic Happy Home
		FullMap = 141621248,           -- Classic Maps -- Happy Home In Robloxia
		HouseOnly = 4674924342,        -- Alternativa casa
		Old2010 = 82134451,            -- Old Happy home
	},
	Trees = {
		BasicRound = 13074489391,
		Classic = 29718921,
	},
	-- Añadir más solo si se verifican
}

-- === FLAGS DE SEGURIDAD ===
MapConfig.SafeLoad = true              -- Si true, intenta asset y cae a procedural
MapConfig.AllowScriptsInAssets = false -- Nunca ejecutar scripts de modelos externos sin revisar
MapConfig.AnchorEverything = true
MapConfig.MaxParts = 2500               -- Límite de rendimiento

-- === COLORES CLÁSICOS 2009 ===
MapConfig.Colors = {
	Baseplate = Color3.fromRGB(91, 154, 76),       -- Verde clásico
	Path = Color3.fromRGB(163, 162, 165),          -- Gris hormigón
	HouseWall = Color3.fromRGB(215, 197, 154),     -- Beige ladrillo
	HouseRoof = Color3.fromRGB(196, 40, 28),       -- Rojo tejado
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

-- === MATERIALES ===
MapConfig.Materials = {
	Default = Enum.Material.Plastic,
	Wood = Enum.Material.Wood,
	Grass = Enum.Material.Grass,
	Concrete = Enum.Material.Concrete,
	Brick = Enum.Material.Brick,
}

-- === LAYOUT (studs) ===
MapConfig.Layout = {
	BaseSize = Vector3.new(512, 1, 512),
	Spawn = Vector3.new(0, 5, 0),
	
	HappyHomePos = Vector3.new(-80, 0, -40),
	ConstructionYardPos = Vector3.new(60, 0, -30),
	RoleplayDistrictPos = Vector3.new(-120, 0, 80),
	ObbyStart = Vector3.new(120, 5, 40),
	NaturePos = Vector3.new(0, 0, 140),
	PlazaCenter = Vector3.new(0, 0, 20),
	
	SecretHouseIndex = 3, -- La 3ª casa del distrito RP tiene el sótano
}

-- === ARG ===
MapConfig.ARG = {
	Enabled = true,
	TriggerMessage = "Something feels wrong...",
	ResetDelay = 1.5,
	NewMapName = "Robloxia_Broken",
	AtmosphereColor = Color3.fromRGB(40, 20, 20),
	FogColor = Color3.fromRGB(30, 10, 10),
	FogEnd = 200,
}

-- === TEXTOS DE CARTELES ===
MapConfig.Signs = {
	{ Text = "WELCOME TO ROBLOXIA!", Size = Vector3.new(12, 6, 1) },
	{ Text = "HAVE FUN!", Size = Vector3.new(8, 4, 1) },
	{ Text = "FREE BRICKS", Size = Vector3.new(10, 5, 1) },
	{ Text = "BUILD HERE", Size = Vector3.new(8, 4, 1) },
	{ Text = "HAPPY HOME", Size = Vector3.new(8, 4, 1) },
	{ Text = "OBBY →", Size = Vector3.new(6, 3, 1) },
	{ Text = "VISIT THE TOWN", Size = Vector3.new(10, 4, 1) },
	{ Text = "HOW TO PLAY", Size = Vector3.new(8, 4, 1) },
	{ Text = "THANKS FOR VISITING!", Size = Vector3.new(12, 5, 1) },
	{ Text = "DO NOT ENTER", Size = Vector3.new(6, 3, 1) }, -- secreto
}

return MapConfig
