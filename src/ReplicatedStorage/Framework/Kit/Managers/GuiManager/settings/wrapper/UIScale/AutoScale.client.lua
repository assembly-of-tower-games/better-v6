--!strict

local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local BASE_SIZE = Vector2.new(1920, 1080)
local SCALE_FACTOR = 1.2

local uiScale = script.Parent
local camera = Workspace.CurrentCamera
local function update()
	local x, y = GuiService:GetGuiInset()
	local currentSize = BASE_SIZE / (camera.ViewportSize - (x + y))
    uiScale.Scale = SCALE_FACTOR / math.max(currentSize.X, currentSize.Y)
end

update()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
