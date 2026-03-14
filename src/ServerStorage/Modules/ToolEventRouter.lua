local PLRS = game:GetService("Players")
local SS = game:GetService("ServerStorage")
local CS = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")

local destroySound = RS.Assets.SFX.DestroySound

local BindableEvent = SS.Bindables.BindableEvent
local RemoteEvent = RS.Remotes.RemoteEvent
local ErrorCodes = require(SS.Log.ErrorCodes)

local ToolEventRouter = {}
local registry: {[Player]: {Tool}} = {}
local connections = {}

local toolTypes = {
	Pickaxe = {
		Name = "Pickaxe",
		Config = require(SS.Configs.PickaxeServerConfigs)
	},
	Bomb = {
		Name = "Bomb",
		Config = require(SS.Configs.BombServerConfigs)
	},
}

local function invalidToolUsed(
	player: Player, 
	tool: Tool,
	errorCode: number
)
	errorCode = errorCode or 1001
	
	warn(`{player.Name}: {ErrorCodes[errorCode]}`)
	RemoteEvent:FireClient(player, "PlaySound", { Sound = destroySound, IsConstant = true })
	
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end
	
	local kickMsg = `Kicked {player.Name} for suspected cheating: Code {errorCode}. If you think this is a mistake, contact the developer`
	if not game:GetService("RunService"):IsStudio() then
		player:Kick(kickMsg)
	else
		warn(kickMsg)
	end
end

local function getConfigFromTool(
	player: Player,
	tool: Tool
)
	assert(player and player:IsA("Player"), "validateTool: invalid player")
	assert(tool and tool:IsA("Tool"), "validateTool: invalid tool")
	
	local toolTypeMap :{Name:string, Config:{[string] : any}} = nil
	
	local isValidToolType = false
	for _, toolType in pairs(toolTypes) do
		if CS:HasTag(tool, toolType.Name) then
			isValidToolType = true
			toolTypeMap = toolType
			break
		end
	end
	
	if not isValidToolType then
		invalidToolUsed(player, tool, 3001)
		return nil
	end
	
	local toolId = tool:GetAttribute(toolTypeMap.Name .. "_ID")
	if not toolId or typeof(toolId) ~= "string" then
		invalidToolUsed(player, tool, 3002)
		return nil
	end

	local config = toolTypeMap.Config[toolId]
	if not config then 
		invalidToolUsed(player, tool, 3003)
		return nil
	end

	return {
		Name = toolTypeMap.Name,
		Config = toolTypeMap.Config
	}
end

local function onToolEquipped(player, tool)
	if connections[tool] then
		for _, conn in pairs(connections[tool]) do
			conn:Disconnect()
		end
	end
	connections[tool] = {}

	-- might think of a use for these connections later,
	-- currently migrated pickaxe activation to client remote event
	local actConn = tool.Activated:Connect(function()
	end)
	table.insert(connections[tool], actConn)

	local deactConn = tool.Deactivated:Connect(function()
	end)
	table.insert(connections[tool], deactConn)
end

local function onToolUnequipped(player, tool)
	if not connections[tool] then return end
	for _, conn in pairs(connections[tool]) do
		conn:Disconnect()
	end
	connections[tool] = nil
end

-- TODO: make bindable event fireable based on tool type
-- Make a dynamic connection for each tool type
local function onToolAdded(tool: Tool)
	local character = tool.Parent
	
	tool.Equipped:Connect(function()
		local player = PLRS:GetPlayerFromCharacter(character)
		if not player then return end
		
		local config = getConfigFromTool(player, tool)
		if not config then return end
		
		BindableEvent:Fire(`{config.Name}Equipped`, player, tool)
		onToolEquipped(player, tool)
	end)

	tool.Unequipped:Connect(function()
		local player = PLRS:GetPlayerFromCharacter(character)
		if not player then return end
		onToolUnequipped(player, tool)
	end)
end

function ToolEventRouter.Init()
	for _, player in pairs(PLRS:GetPlayers()) do
		player.CharacterAdded:Connect(function(char)
			char.ChildAdded:Connect(function(child)
				if not registry[player] then
					registry[player] = {}
				end
				if not table.find(registry[player], child) then
					table.insert(registry[player], child)
					onToolAdded(child)
				end
			end)
		end)
	end

	PLRS.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			char.ChildAdded:Connect(function(child)
				if child:IsA("Tool") then
					if not registry[player] then
						registry[player] = {}
					end
					if not table.find(registry[player], child) then
						table.insert(registry[player], child)
						onToolAdded(child)
					end
				end
			end)
		end)
	end)
end

return ToolEventRouter
