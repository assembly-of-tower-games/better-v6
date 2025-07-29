--!optimize 2

--[=[
    @class GuiManager
    @client
    
    Manager module for GUIs (mainly EffectGui), used for things such as the boost & key display.
]=]

--[[
---------------------------------------------------------------------------
Services, modules and other objects
---------------------------------------------------------------------------
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Framework = ReplicatedStorage.Framework
local _TDefs = require(script.TypeDefs)

local Kit = Framework.Kit
local Log = require(Framework.Log)
local CharacterManager_Types = require(Kit.Managers.CharacterManager.TypeDefs)

--[[
---------------------------------------------------------------------------
Main table
---------------------------------------------------------------------------
]]

local GuiManager = {
	__initialized = false,

	KeyDisplayLimit = 5,
	__keyCaches = {},
} :: _TDefs.GuiManager

--[[
---------------------------------------------------------------------------
Variables, types and constants
---------------------------------------------------------------------------
]]

local boostID = 0 -- used for LayoutOrder of boost timers

local BOOST_TIMER_DATA = {
	Speed = {
		color = Color3.fromRGB(255, 255, 0),
		icon = "rbxassetid://13492318225",
	},
	Jump = {
		color = Color3.fromRGB(175, 255, 0),
		icon = "rbxassetid://14549056586",
	},
}

local BOOST_FRAME_INACTIVE_SIZE =
	UDim2.fromScale(0, ReplicatedStorage.Assets.Managers.GuiManager.BoostFrame.Size.Y.Scale)
local BOOST_FRAME_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local KEY_CAMERA = Instance.new("Camera")
KEY_CAMERA.CFrame = CFrame.new(Vector3.zAxis * 4)

local PickupSound = 'rbxassetid://424002310'
local UnlockSound = 'rbxassetid://4381793351'

local OwnedKeys = {}

local KeyTrails = {}
local KeyIncrement = 20

local KeyTrailPosition
local KeyTrailLogLimit = 100
local KeyTrailThreshold = 2 / KeyIncrement

function PlaySound(Part, id)
	if Part:FindFirstChild("ReplaceSound") then
		Part.ReplaceSound:Play()
	else
		local Sound = Instance.new('Sound')

		Sound.SoundId = id
		Sound.Volume = 4
		Sound.Parent = Part
		Sound:Play()

		Debris:AddItem(Sound, 5)
	end
end

function GetTrailPosition(Position)
	local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	local Character = Player.Character or Player.CharacterAdded:Wait()

	return KeyTrails[math.floor((Position * KeyIncrement) / 3)]
		or KeyTrails[#KeyTrails]
		or (Character and Character:FindFirstChild("HumanoidRootPart") and Character.HumanoidRootPart.Position)
		or Vector3.new()
end

function FindKey(ID)
	local Number
	local KeyInfo

	for Index, Key in pairs(OwnedKeys) do
		if Key.ID == ID then
			KeyInfo = Key
			Number = Index

			break
		end
	end

	return KeyInfo, Number
end

function IsKeyInList(Key)
	for Index, KeyInfo in pairs(OwnedKeys) do
		if KeyInfo.Key == Key then
			return KeyInfo, Index
		end
	end

	return nil, nil
end

function AddKey(ID, Key, Clone)
	local KeysID = #OwnedKeys + 1

	OwnedKeys[KeysID] = { ID = ID, Key = Key }

	return OwnedKeys[KeysID]
end

function RemoveKey(ID, KeyReturn)
	local KeyInfo, Number

	if type(ID) == "userdata" then
		KeyInfo, Number = IsKeyInList(ID)
	else
		KeyInfo, Number = FindKey(ID)
	end

	if KeyInfo then
		if not KeyReturn then
			Debris:AddItem(KeyInfo.Key, 0.2)
			
			KeyInfo.Key.KeyID:Destroy()
		else
			local Cooldown = Instance.new("BoolValue")

			Cooldown.Name = "Cooldown"
			Cooldown.Parent = KeyInfo.Key

			Debris:AddItem(Cooldown, 2)
		end

		table.remove(OwnedKeys, Number)
		return KeyInfo.Key
	end

	return false
end

function KeyStep(DeltaTime)
	local Trail = KeyTrails

	local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	local Character = Player.Character or Player.CharacterAdded:Wait()

	if Character and Character:FindFirstChild("HumanoidRootPart") then
		local HumanoidRootPart = Character.HumanoidRootPart

		if not KeyTrailPosition or (HumanoidRootPart.Position - KeyTrailPosition).Magnitude > KeyTrailThreshold then
			Trail = {}

			table.insert(Trail, 1, KeyTrailPosition)

			for Number, TrailPos in pairs(KeyTrails) do
				if Number <= KeyTrailLogLimit * KeyIncrement then
					table.insert(Trail, Number + 1, TrailPos)
				end
			end

			KeyTrailPosition = HumanoidRootPart.Position
		end
	end

	KeyTrails = Trail
end

function CheckDescendant(Descendant)
	local Parent = Descendant.Parent

	if Descendant.Name == "KeyID" and Parent then
		local KeyHitbox = Parent:FindFirstChild("KeyHitbox")

		if KeyHitbox then
			KeyHitbox.Transparency = 1

			local Debounce = true

			if Descendant:FindFirstChild("Door") then
				KeyHitbox.Touched:Connect(function(Hit)
					if Debounce and Players:GetPlayerFromCharacter(Hit.Parent) == Players.LocalPlayer then
						local Key = RemoveKey(Descendant.Value)

						if not Key then
							return
						end

						if Key then
							local Value = Instance.new("Vector3Value")

							Value.Name = "MoveToPosition"
							Value.Value = KeyHitbox.Position

							Value.Parent = Key
						end

						Debounce = false
						PlaySound(KeyHitbox, UnlockSound)

						for _, Descendant in pairs(Parent:GetDescendants()) do
							if Descendant:IsA("BasePart") then
								if Descendant.Name == "Fall" then
									Descendant.Anchored = false
									Descendant.CanCollide = false

									Descendant.RotVelocity =
										Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
									Descendant.Velocity =
										Vector3.new(math.random(-30, 30), math.random(-30, 30), math.random(-30, 30))

									Descendant:BreakJoints()
								elseif Descendant.Name == "Vanish" then
									TweenService:Create(
										Descendant,
										TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
										{ Transparency = 1 }
									):Play()
									Descendant.CanCollide = false

									Debris:AddItem(Descendant, 0.5)
								end
							end
						end
					end
				end)
			else
				local Key = Parent
				local KeyClone = Parent:Clone()

				local Parts = {}
				local DefinitivePosition = KeyHitbox.Position

				Key:PivotTo(CFrame.new(DefinitivePosition))

				for _, KeyPart in pairs(Key:GetDescendants()) do
					if KeyPart:IsA("BasePart") and KeyPart ~= KeyHitbox then
						Parts[KeyPart] = KeyPart.CFrame * KeyHitbox.CFrame:Inverse()
						KeyPart.CanCollide = false
					end
				end

				local CurrentRotation = 0
				local RotationSpeed = 180
				local MoveSpeed = 10

				local KeyConnection

				KeyConnection = RunService.RenderStepped:Connect(function(DeltaTime)
					local MoveTo = DefinitivePosition
					local _KeyInfo, KeyNumber = IsKeyInList(Key)

					if not KeyNumber then
						Debounce = true
					end

					if not Descendant or not Key or not KeyHitbox or not KeyHitbox.Parent then
						KeyConnection:Disconnect()

						return
					end

					if Key:FindFirstChild("MoveToPosition") then
						MoveTo = Key.MoveToPosition.Value
					else
						if KeyNumber then
							MoveTo = GetTrailPosition(KeyNumber)
						end
					end

					CurrentRotation += math.min(RotationSpeed * DeltaTime, 1)

					if CurrentRotation > 360 then
						CurrentRotation = 0
					end

					if (MoveTo - workspace.CurrentCamera.CFrame.Position).Magnitude < 100 or KeyNumber then
						Key:PivotTo(
							CFrame.new(KeyHitbox.Position:Lerp(MoveTo, math.min(MoveSpeed * DeltaTime, 1)))
								* CFrame.Angles(0, math.rad(CurrentRotation), 0)
						)
					end

					for Part, PartOffset in pairs(Parts) do
						Part.CFrame = KeyHitbox.CFrame * PartOffset
					end
				end)

				KeyHitbox.Touched:Connect(function(Hit)
					if
						Descendant
						and Descendant.Parent
						and Debounce
						and Players:GetPlayerFromCharacter(Hit.Parent) == Players.LocalPlayer
						and not IsKeyInList(Key)
						and not Key:FindFirstChild("Cooldown")
					then
						Debounce = false

						local HitboxClone = KeyHitbox:Clone()
						HitboxClone.Parent = KeyClone

						local Effect = ReplicatedStorage.Assets.Effects.Key:Clone()
						Effect.Parent = KeyHitbox
						Effect:Emit(math.random(20, 50))

						PlaySound(KeyHitbox, PickupSound)
						AddKey(Descendant.Value, Key, KeyClone)
					end
				end)
			end
		end
	end

	if Descendant:FindFirstChild("ReturnKey") and Descendant.ReturnKey:IsA("StringValue") then 
		Descendant.Touched:Connect(function(Hit)
			if not Hit.Parent or Players:GetPlayerFromCharacter(Hit.Parent) ~= Players.LocalPlayer then 
				return
			end

			RemoveKey(Descendant.ReturnKey.Value, true)
		end)
	end
end

--[[
---------------------------------------------------------------------------
Functions
---------------------------------------------------------------------------
]]

function roundDecimals(value: number, decimals: number): number
	local mult = 10 ^ decimals
	return math.round(value * mult) / mult
end

--[=[
	@within GuiManager
	
	Creates and returns a boost timer frame for the given `boostType`.
	The visual data for every type is defined in the `BOOST_TIMER_DATA` table.
]=]
function GuiManager:CreateBoostFrame(boostData: CharacterManager_Types.BoostData): _TDefs.BoostTimerFrame
	if boostData.hideGUI then
		return -- don't make one if they disabled it
	end

	boostID += 1

	local boostTimerData = BOOST_TIMER_DATA[boostData.type]

	local frame = ReplicatedStorage.Assets.Managers.GuiManager.BoostFrame:Clone()
	frame.Size = BOOST_FRAME_INACTIVE_SIZE
	frame.Name = boostData.type

	-- timer
	frame.Timer.Visible = not boostData.isPad
	frame.Timer.Fill.BackgroundColor3 = boostTimerData.color
	frame.Timer.Remaining.TextColor3 = boostTimerData.color

	-- icon
	frame.Icon.ImageColor3 = boostTimerData.color
	frame.Icon.Image = boostTimerData.icon

	-- power text
	frame.Icon.Power.TextColor3 = boostTimerData.color

	frame.LayoutOrder = boostID
	frame.Parent = GuiManager.Gui.Boosts

	boostData.frame = frame
	TweenService
		:Create(frame, BOOST_FRAME_TWEEN_INFO, { Size = ReplicatedStorage.Assets.Managers.GuiManager.BoostFrame.Size })
		:Play()

	GuiManager:UpdateBoostFrame(boostData)
	return frame
end

--[=[
	@within GuiManager
	
	Updates a boost's timer frame.
]=]
function GuiManager:UpdateBoostFrame(boostData: CharacterManager_Types.BoostData)
	local frame = boostData.frame
	if not frame then
		return
	end

	-- timer text
	frame.Timer.Remaining.Text = GuiManager:FormatBoostTimer(boostData)

	-- timer bar
	local fraction = math.clamp(boostData.timeLeft / boostData.duration, 0, 1)
	frame.Timer.Fill.Size = UDim2.fromScale(fraction, 1)

	-- power text
	frame.Icon.Power.Text = `{tostring(roundDecimals(boostData.multiplier, 2))}x`
end

--[=[
	@within GuiManager
	
	Helper function that formats a boost's remaining time into a string.
]=]
function GuiManager:FormatBoostTimer(boostData: CharacterManager_Types.BoostData): string
	return if boostData.infinite then "∞" else tostring(roundDecimals(boostData.timeLeft, boostData.timerDecimals))
end

--[=[
	@within GuiManager
	
	Destroys the given boost's timer frame, fading it out and deleting it when finished
]=]
function GuiManager:DestroyBoostFrame(boostData: CharacterManager_Types.BoostData)
	local frame = boostData.frame
	if not frame then
		return
	end

	local tween = TweenService:Create(frame, BOOST_FRAME_TWEEN_INFO, { Size = BOOST_FRAME_INACTIVE_SIZE })
	tween:Play()
	tween.Completed:Once(function()
		frame:Destroy()
	end)
end

--[=[
	@within GuiManager
	
	Binds the given `cache` to the key cache.
]=]
function GuiManager:BindKeyCache(cache: _TDefs.KeyCache)
	self.__keyCaches[cache.id] = cache
end

--[=[
	@within GuiManager
	
	Unbinds the given `cache` from the key cache.
]=]
function GuiManager:UnbindKeyCache(cache: _TDefs.KeyCache)
	self.__keyCaches[cache.id] = nil
end

function GuiManager:__updateKeyDisplay()
	debug.profilebegin("GuiManager > Key Display")
	local keyFrame = self.Gui.Keys

	local characterCFrame
	local character = Players.LocalPlayer.Character
	if character then
		characterCFrame = character:GetPivot()
	end

	local displayLimit = self.KeyDisplayLimit
	for cacheId, cache in self.__keyCaches do
		for keyId, key in cache.keys do
			debug.profilebegin("GuiManager > Key Display > Manage Key")

			if not key or not key.__private then
				debug.profileend()
				continue
			end

			local keyData = key.__private

			if not key.instance or not keyData.viewport then
				debug.profileend()
				continue
			end

			local viewport = keyData.viewport

			if viewport.Parent ~= keyFrame then
				viewport.Parent = keyFrame
			end

			if not viewport.CurrentCamera then
				viewport.CurrentCamera = KEY_CAMERA
			end

			local keyIndex = table.find(cache.activeKeys, keyId)
			if keyIndex ~= nil and keyIndex >= displayLimit and not keyData.used then
				if viewport.LayoutOrder ~= keyIndex then
					viewport.LayoutOrder = keyIndex
				end

				if key.instance.Parent ~= viewport then
					key.instance.Parent = viewport

					if not keyData.isViewportDisplayed then
						keyData.isViewportDisplayed = true
						key.instance:PivotTo(key.config.ViewportOffset or CFrame.identity)
					end
				end

				local timerLabel = key.timerLabel

				if keyData.startTimer and timerLabel then
					viewport.Time.Text = timerLabel.Text
				end

				if not viewport.Visible then
					viewport.Visible = true
				end
			else
				if viewport.Visible then
					viewport.Visible = false
				end

				local currentParent = key.instance.Parent

				if currentParent and currentParent ~= keyData.parent then
					key.instance.Parent = keyData.parent
				end

				if keyData.isViewportDisplayed then
					keyData.isViewportDisplayed = false
					key.instance:PivotTo(characterCFrame or key.originalCFrame)
				end
			end

			debug.profileend()
		end
	end

	debug.profileend()
end

--[=[
	@within GuiManager
	
	Displays the GUI with the given `guiName` on the player's screen.
]=]
function GuiManager:DisplayGUI(guiName: string, ...: any)
	local gui = script:FindFirstChild(guiName)

	if not gui then
		Log({
			`{guiName} GUI not found or already visible!!`,
			type = "warn",
		})

		return true
	end

	gui.Enabled = true
	gui.Parent = GuiManager.PlayerGui

	return true
end

function GuiManager:Init()
	if self.__initialized then
		return GuiManager
	end
	self.__initialized = true

	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	GuiManager.Gui = playerGui:WaitForChild("EffectGUI")
	GuiManager.PlayerGui = playerGui

	--> Start Key display loop
	RunService.Heartbeat:Connect(function()
		self:__updateKeyDisplay()
	end)

	for _, Descendant in pairs(workspace:WaitForChild("ClientParts"):GetDescendants()) do
		CheckDescendant(Descendant)
	end

	workspace:WaitForChild("ClientParts").DescendantAdded:Connect(CheckDescendant)
	RunService.RenderStepped:Connect(KeyStep)

	return GuiManager
end

return GuiManager
