--!strict
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local config = localPlayer:WaitForChild("KitConfiguration")

local newScrollableList = require(script.ScrollableList)

local Framework = ReplicatedStorage.Framework
local Managers = Framework.Kit.Managers
local GuiManager = require(Managers.GuiManager)
local FlipManager = require(Managers.FlipManager)
local KitSettings = require(ReplicatedStorage.KitSettings)

local playerScripts = localPlayer:WaitForChild("PlayerScripts")
local PlayerModule = require(playerScripts:WaitForChild("PlayerModule"))

local root = script.Parent
local wrapper = root:WaitForChild("wrapper")
local items = wrapper.contents.items
local isOpen = false

local function bind(
	button: TextButton,
	optionList: newScrollableList.ScrollableList<any>,
	inputRefresh: boolean,
	refresh: () -> ()
)
	refresh()
	if inputRefresh then
		UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
	end

	button.MouseButton1Click:Connect(function()
		optionList:Scroll(1)
		refresh()
	end)
end

-- tip !
-- you can collapse each option section to navigate through the script easier

do --> Open / Close Button
	wrapper.button.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		TweenService:Create(
			wrapper,
			TweenInfo.new(
				0.25,
				Enum.EasingStyle.Quad,
				if isOpen then Enum.EasingDirection.Out else Enum.EasingDirection.In
			),
			{ AnchorPoint = if isOpen then Vector2.new(0, 1) else Vector2.new(1, 1) }
		):Play()
	end)
end

do --> Flip Bind
	local EDIT_COOLDOWN = 0.15
	local CANCEL_KEYS = {
		[Enum.KeyCode.Escape] = true,
		[Enum.KeyCode.ButtonSelect] = true,
		[Enum.KeyCode.Unknown] = true,
	}

	local frame = items.flip
	local inEditMode = false
	local lastEdited = 0
	local function inCooldown()
		return (os.clock() - lastEdited) < EDIT_COOLDOWN
	end

	local function getCurrentBindIndex(): string?
		local current = UserInputService.PreferredInput
		if current == Enum.PreferredInput.KeyboardAndMouse then
			return "Keyboard"
		elseif current == Enum.PreferredInput.Gamepad then
			return "Controller"
		end

		return nil
	end

	local function refreshDisplay()
		local currentBind = FlipManager.Binds[getCurrentBindIndex()]
		frame.Visible = currentBind ~= nil
		if currentBind then
			frame.button.Text = currentBind.Name
		end
	end

	refreshDisplay()
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refreshDisplay)
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if not inEditMode or inCooldown() then
			return
		end

		local currentIndex = getCurrentBindIndex()
		if FlipManager.Binds[currentIndex] == nil then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			FlipManager.Binds[currentIndex] = input.UserInputType
		elseif not CANCEL_KEYS[input.KeyCode] then
			FlipManager.Binds[currentIndex] = input.KeyCode
		end

		refreshDisplay()
		inEditMode = false
		lastEdited = os.clock()
	end)
	frame.button.MouseButton1Click:Connect(function()
		if inEditMode or inCooldown() then
			return
		end

		local currentIndex = getCurrentBindIndex()
		if currentIndex == "Keyboard" then
			frame.button.Text = "[Press a key / esc to cancel]"
		else
			frame.button.Text = "[Press a button / select to cancel]"
		end

		inEditMode = true
	end)
end

do --> Physics Fix Toggle
	local frame = items.physics
	local optionList = newScrollableList({
		{ display = "Off", value = false },
		{ display = "On", value = true },
	})

	local currentScript: LocalScript?
	local function refreshEnabled()
		local currentItem = optionList:Current()
		frame.button.Text = currentItem.display
		if currentScript then
			currentScript.Enabled = currentItem.value
		end
	end

	local function onCharacterAdded(character: Model)
		local fixScript = character:WaitForChild("PhysicsFixer", 5)
		if not fixScript:IsA("LocalScript") then
			return
		end

		currentScript = fixScript
		refreshEnabled()
	end

	task.spawn(function()
		onCharacterAdded(localPlayer.Character or localPlayer.CharacterAdded:Wait())
		localPlayer.CharacterAdded:Connect(onCharacterAdded)
	end)

	frame.button.MouseButton1Click:Connect(function()
		optionList:Scroll(1)
		refreshEnabled()
	end)
end

do --> Key Display Limit
	local frame = items.key
	local optionList = newScrollableList({
		{ display = "Off", value = 0 },
		{ display = "5", value = 5 },
		{ display = "10", value = 10 },
		{ display = "All", value = 1000 },
	}, 2)

	local function refreshText()
		local currentItem = optionList:Current()
		frame.button.Text = currentItem.display
		GuiManager.KeyDisplayLimit = currentItem.value
	end
	bind(frame.button, optionList, false, refreshText)
end

do --> Music Transition
	local frame = items.music
	local optionList = newScrollableList({
		"Smooth",
		"Classic",
	})

	local function refreshText()
		local currentItem = optionList:Current()
		frame.button.Text = currentItem
		-- TODO: make the music system not use _G
		_G.MusicUseSmoothTransition = currentItem == "Smooth"
	end
	bind(frame.button, optionList, false, refreshText)
end

do --> Utility Button
	local frame = items.util
	local utilityGui = root:WaitForChild("Utility")
	local optionList = newScrollableList({
		"Off",
		"Alignment",
		"Emote",
	})

	local function refreshText()
		local currentItem = optionList:Current()
		frame.button.Text = currentItem
		for _, frame in utilityGui:GetChildren() do
			if not frame:IsA("CanvasGroup") then
				continue
			end
			frame.Visible = currentItem == frame.Name
		end
	end
	bind(frame.button, optionList, false, refreshText)
end

do --> Alignment Dot
	local frame = items.dot
	local utilityGui = root:WaitForChild("AlignmentDot")
	local optionList = newScrollableList({
		{ display = "Off", value = false },
		{ display = "On", value = true },
	})

	local function refreshText()
		local currentItem = optionList:Current()
		frame.button.Text = currentItem.display
		utilityGui.Enabled = currentItem.value
	end
	bind(frame.button, optionList, false, refreshText)
end

do --> Mobile D-Pad
	local frame = items.dpad
	local optionList = newScrollableList({
		{ display = "Off", value = "off" },
		{ display = "Mode 1", value = "m1" },
		{ display = "Mode 2", value = "m2" },
	})

	local function refreshText()
		frame.Visible = UserInputService.PreferredInput == Enum.PreferredInput.Touch

		local currentItem = optionList:Current()
		frame.button.Text = currentItem.display
		config:SetAttribute("MobileDPad", currentItem.value)
		PlayerModule.controls:OnTouchMovementModeChange()
	end
	bind(frame.button, optionList, true, refreshText)
end

do --> Controller Movement Mode
	local frame = items.controller
	local optionList = newScrollableList({
		{ display = "Off", value = "off" },
		{ display = "Joystick", value = "m1" },
		{ display = "D-Pad", value = "m2" },
		{ display = "Both", value = "m3" },
	})

	local function refreshText()
		frame.Visible = UserInputService.PreferredInput == Enum.PreferredInput.Gamepad

		local currentItem = optionList:Current()
		frame.button.Text = currentItem.display
		config:SetAttribute("ControllerMovement", currentItem.value)
	end
	bind(frame.button, optionList, true, refreshText)
end

do --> Invisible Players
	local frame = items.invis
	local optionList = newScrollableList({
		{ display = "Off", value = false },
		{ display = "On", value = true },
	})

	local function refreshText()
		local currentItem = optionList:Current()
		frame.button.Text = currentItem.display
		config:SetAttribute("InvisPlayers", currentItem.value)
	end
	bind(frame.button, optionList, false, refreshText)
end

do --> Debug
	local frame = items.debug
	if KitSettings.DisplayDebugGuis then
		frame.Visible = false
	end

	frame.button.MouseButton1Click:Connect(function()
		frame.Visible = false
		GuiManager:DisplayGUI("debug", KitSettings.DisplayMemoryDebug)
	end)
end

do --> Rejoin
	local frame = items.rejoin
	frame.button.MouseButton1Click:Connect(function()
		Framework.Remotes.Rejoin:FireServer()
	end)
end
