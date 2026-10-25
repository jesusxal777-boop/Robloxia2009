--[[
	RPClient.client.lua
	Small, mobile-friendly notifications for RP interactions.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("RPNotice")

local gui = Instance.new("ScreenGui")
gui.Name = "RobloxiaRPNotifications"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Notice"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 16)
panel.Size = UDim2.new(0.88, 0, 0, 54)
panel.BackgroundColor3 = Color3.fromRGB(25, 35, 45)
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(120, 190, 220)
stroke.Thickness = 1
stroke.Parent = panel

local text = Instance.new("TextLabel")
text.Name = "Message"
text.Size = UDim2.new(1, -18, 1, -10)
text.Position = UDim2.new(0, 9, 0, 5)
text.BackgroundTransparency = 1
text.Font = Enum.Font.Code
text.TextColor3 = Color3.fromRGB(245, 245, 235)
text.TextSize = 16
text.TextWrapped = true
text.TextScaled = false
text.Text = ""
text.Parent = panel

local sequence = 0
local function show(message)
	sequence += 1
	local current = sequence
	text.Text = tostring(message)
	panel.Visible = true
	panel.BackgroundTransparency = 0.08
	panel.Position = UDim2.new(0.5, 0, 0, 10)
	TweenService:Create(panel, TweenInfo.new(0.18), {
		Position = UDim2.new(0.5, 0, 0, 16)
	}):Play()
	task.delay(4, function()
		if current ~= sequence then return end
		local tween = TweenService:Create(panel, TweenInfo.new(0.2), {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0, 8)
		})
		tween:Play()
		tween.Completed:Wait()
		if current == sequence then panel.Visible = false end
	end)
end

event.OnClientEvent:Connect(show)
