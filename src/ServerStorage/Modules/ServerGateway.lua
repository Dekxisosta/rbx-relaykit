local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local RemoteEvent = RS.Remotes.RemoteEvent
local RemoteFunction = RS.Remotes.RemoteFunction
local ServerGateway = {}

local controllers = {
	PickaxeEvent = require(SS.Controllers.Mine.PickaxeController)
}

function ServerGateway.Init()
	RemoteEvent.OnServerEvent:Connect(function(player: Player, eventName: string, ...)
		local controller = controllers[eventName]
		if not controller then
			warn(`Invalid controller call "{eventName}" from {player.Name}`)
			return
		end
		if type(controller) ~= "table" or type(controller.HandleEvent) ~= "function" then
			return
		end
		controller:HandleEvent(player, ...)
	end)
	
	RemoteFunction.OnServerInvoke = function(player: Player, eventName: string, ...)
		local controller = controllers[eventName]

		if not controller then
			warn(string.format('Invalid controller call "%s" from %s', eventName, player.Name))
			return nil
		end

		if type(controller) ~= "table" or type(controller.HandleEvent) ~= "function" then
			return nil
		end

		return controller:HandleEvent(player, ...)
	end
end

return ServerGateway
