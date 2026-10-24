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
