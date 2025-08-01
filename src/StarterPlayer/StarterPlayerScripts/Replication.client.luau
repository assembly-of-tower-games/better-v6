local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicationNamespace = require(ReplicatedStorage.Namespaces.Replication)
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local Send = {
	MaxFramerate = 1 / 120,
	LastUpdate = os.clock() - 1000,
}

local FakePlayerParts = {} :: { [Player]: BasePart }
local LatestCFrame = {} :: { [Player]: CFrame }

function CreatePart()
	local DebugPart = Instance.new("Part")
	DebugPart.Size = Vector3.new(1, 1, 1)
	DebugPart.Anchored = true
	DebugPart.CanCollide = false
	DebugPart.Transparency = 1
	DebugPart.Parent = workspace.CurrentCamera
	return DebugPart
end

function DecodeAngle(Int: number)
	return (Int / 4294967295) * (2 * math.pi)
end
function EncodeAngle(Radian: number)
	return math.floor((Radian / (2 * math.pi)) % 1 * 4294967295)
end

function networkReceive(ThisPlayer: Player, ReceivedCFrame: CFrame)
	if ThisPlayer == LocalPlayer then
		return
	end
	if not FakePlayerParts[ThisPlayer] then
		FakePlayerParts[ThisPlayer] = CreatePart()
	end
	if not LatestCFrame[ThisPlayer] then
		LatestCFrame[ThisPlayer] = ReceivedCFrame
		return
	end
	LatestCFrame[ThisPlayer] = ReceivedCFrame
end

function characterAdded(Character: Model)
	local LastSentCFrame = nil
	local PositionThreshold = 0.01
	local RotationThreshold = 0.01

	RunService.Heartbeat:Connect(function()
		if Send.LastUpdate + Send.MaxFramerate >= os.clock() then
			return
		end
		Send.LastUpdate = os.clock()

		local CurrentCFrame: CFrame?
        local PrimaryPart = Character.PrimaryPart :: BasePart

        local _Success, _Error = pcall(function()
			CurrentCFrame = PrimaryPart.CFrame
		end)

		if not CurrentCFrame then
			return
		end

		local ShouldSend = false

		if not LastSentCFrame then
			ShouldSend = true
		else
			local PositionDelta = (CurrentCFrame.Position - LastSentCFrame.Position).Magnitude

			local RotationX1, RotationY1, RotationZ1 = CurrentCFrame.Rotation:ToOrientation()
			local RotationX2, RotationY2, RotationZ2 = LastSentCFrame.Rotation:ToOrientation()

			local RotationMagnitude = math.abs(RotationX1 - RotationX2) + math.abs(RotationY1 - RotationY2) + math.abs(RotationZ1 - RotationZ2)

			if PositionDelta > PositionThreshold or RotationMagnitude > RotationThreshold then
				ShouldSend = true
			end
		end

		if ShouldSend then
			LastSentCFrame = CurrentCFrame

			local Position = { CurrentCFrame.Position.X, CurrentCFrame.Position.Y, CurrentCFrame.Position.Z }
			local RotationX, RotationY, RotationZ = CurrentCFrame.Rotation:ToOrientation()

			local Rotation = {
				EncodeAngle(RotationX),
				EncodeAngle(RotationY),
				EncodeAngle(RotationZ),
			}

			ReplicationNamespace.packets.SendServer.send({
				Position = Position,
				Rotation = Rotation,
			})
		end
	end)

	ReplicationNamespace.packets.SendClient.listen(
		function(Data: { PlayerID: string, Position: { number }, Rotation: { number } })
			local Player = Players:GetPlayerByUserId(tonumber(Data.PlayerID))

			if Player then
				local Position = Vector3.new(unpack(Data.Position))
				local Rotation = CFrame.fromOrientation(
					DecodeAngle(Data.Rotation[1]),
					DecodeAngle(Data.Rotation[2]),
					DecodeAngle(Data.Rotation[3])
				)

				networkReceive(Player, CFrame.new(Position) * Rotation)
			end
		end
	)
	
	RunService.RenderStepped:Connect(function(DeltaTime)
		for ThisPlayer, DebugPart in pairs(FakePlayerParts) do
			local IsLocalPlayer = ThisPlayer == LocalPlayer
			if IsLocalPlayer and not RunService:IsStudio() then
				return
			end

			local LatestCFrame = LatestCFrame[ThisPlayer]
			local RawCFrameRotation = LatestCFrame.Rotation
			local Scaler = math.clamp((DeltaTime * 0.5 * 30), 0, 1)
			local LerpedPosition = DebugPart.CFrame:Lerp(LatestCFrame, Scaler).Position
			local FinalCFrame = CFrame.new(LerpedPosition) * RawCFrameRotation

			DebugPart.CFrame = FinalCFrame

			if ThisPlayer and ThisPlayer.Character and ThisPlayer.Character:IsA("Model") then
				if IsLocalPlayer then
					return
				end

				local ThisCharacter = ThisPlayer.Character
				local ThisHumanoid = ThisCharacter:FindFirstChildOfClass("Humanoid")

				if ThisHumanoid and ThisHumanoid.Health > 0 then
					ThisHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
					ThisCharacter.HumanoidRootPart.CFrame = FinalCFrame
				end
			end
		end
	end)
	
	Players.PlayerRemoving:Connect(function(RemovingPlayer: Player)
		if FakePlayerParts[RemovingPlayer] then
			FakePlayerParts[RemovingPlayer]:Destroy()
			FakePlayerParts[RemovingPlayer] = nil
		end

		LatestCFrame[RemovingPlayer] = nil
	end)
end

if LocalPlayer.Character then
	characterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(Character: Model)
	characterAdded(Character)
end)