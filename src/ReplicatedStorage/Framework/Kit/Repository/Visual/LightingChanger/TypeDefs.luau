--!strict
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 

PLEASE, **DO NOT** make any script edits to this script.
To make a script edit, please read the following:
https://etohgame.github.io/kit/docs/misc#writingediting-repository-scripts

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

type DefaultData = "PlaceDefault" | "TowerDefault" | string
type constructorReturns = {
	Type: string,
	Configuration: { [string]: any? },
	TweenInfo: TweenInfo?,
}
-- this type decides to stop working if i use intersections so have fun reading
-- this xd
export type Constructor = ((
	type: "ColorCorrectionEffect"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		TweenInfo: TweenInfo?,
		Configuration: (ColorCorrectionEffect)?,
	}
) -> constructorReturns) & ((
	type: "BlurEffect"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: (BlurEffect)?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns) & ((
	type: "Lighting"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: Lighting?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns) & ((
	type: "BloomEffect"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: (BloomEffect)?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns) & ((
	type: "DepthOfFieldEffect"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: (DepthOfFieldEffect)?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns) & ((
	type: "Atmosphere"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: (Atmosphere & { Enabled: boolean? })?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns) & ((
	type: "Sky"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: (Sky)?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns)

local function constructor(type: string)
	return function(data: any)
		-- Only keep the properties we need in memory
		return {
			Type = type,
			Configuration = data.Configuration,
			TweenInfo = data.TweenInfo,
			SetDefault = data.SetDefault,
			UseDefault = data.UseDefault,
		}
	end
end
local typedConstructor = (constructor :: any) :: Constructor
return typedConstructor
