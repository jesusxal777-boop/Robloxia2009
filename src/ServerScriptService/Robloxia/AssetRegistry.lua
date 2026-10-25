--[[
	AssetRegistry.lua
	Carga segura de assets por ID con fallback procedural.
	Nunca ejecuta scripts externos si AllowScriptsInAssets = false.
]]

local InsertService = game:GetService("InsertService")
local MapConfig = require(script.Parent.MapConfig)

local AssetRegistry = {}
local cache = {}

local function stripScripts(model: Instance)
	if not MapConfig.AllowScriptsInAssets then
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
				desc:Destroy()
			end
		end
	end
end

local function anchorAll(model: Instance)
	if MapConfig.AnchorEverything then
		if model:IsA("BasePart") then
			model.Anchored = true
		end
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
	end
end

function AssetRegistry.Load(assetId: number, parent: Instance?): (Instance?, string)
	if cache[assetId] then
		local clone = cache[assetId]:Clone()
		if parent then clone.Parent = parent end
		return clone, "cached"
	end

	local success, result = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if success and result then
		local model = result:GetChildren()[1] or result
		stripScripts(model)
		anchorAll(model)
		cache[assetId] = model:Clone() -- cache limpio
		if parent then model.Parent = parent end
		return model, "loaded"
	else
		warn("[AssetRegistry] Falló carga de AssetId " .. tostring(assetId) .. " → usando fallback procedural")
		return nil, "failed"
	end
end

function AssetRegistry.TryHappyHome(parent: Instance, targetPosition: Vector3?): (Instance?, string)
	-- Intenta el mejor asset primero
	local ids = {
		MapConfig.Assets.HappyHome.Primary,
		MapConfig.Assets.HappyHome.HouseOnly,
		MapConfig.Assets.HappyHome.Old2010,
	}
	for _, id in ipairs(ids) do
		local model, status = AssetRegistry.Load(id, parent)
		if model then
			if targetPosition then
				local ok, boxCFrame, boxSize = pcall(function()
					if model:IsA("Model") then
						return model:GetBoundingBox()
					elseif model:IsA("BasePart") then
						return model.CFrame, model.Size
					end
					error("Happy Home asset has no placeable geometry")
				end)
				if ok and boxCFrame and boxSize then
					local bottomY = boxCFrame.Position.Y - boxSize.Y / 2
					local offset = Vector3.new(targetPosition.X - boxCFrame.Position.X, targetPosition.Y - bottomY, targetPosition.Z - boxCFrame.Position.Z)
					if model:IsA("Model") then
						model:PivotTo(model:GetPivot() + offset)
					elseif model:IsA("BasePart") then
						model.CFrame = model.CFrame + offset
					end
				end
			end
			return model, status
		end
	end
	return nil, "all_failed"
end

function AssetRegistry.ClearCache()
	cache = {}
end

return AssetRegistry
