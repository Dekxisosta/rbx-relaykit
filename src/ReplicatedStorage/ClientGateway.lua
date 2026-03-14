-- Client/NetworkHandler.lua
local RS = game:GetService("ReplicatedStorage")
local remoteEvent = RS.Remotes.RemoteEvent

local NetworkHandler = {}

-- Internal tables
local handlers        = {} -- key → function(data, requestId?)
local pendingRequests = {} -- requestId → { callback, timeoutThread }

-- Monotonic counter — safe on Roblox's single-threaded scheduler;
-- no lock needed because coroutine switches only happen at yield points,
-- and this increment is a single atomic step.
local requestCounter = 0
 
local function nextRequestId(): number
	requestCounter += 1
	return requestCounter
end

-- How long (seconds) before a pending request is considered timed out
local REQUEST_TIMEOUT = 10

-- ── Public API ──────────────────────────────────────────────────────────────

-- Register a handler for a server-fired event key.
-- Warns on overwrite so silent shadowing is always visible.
function NetworkHandler.Register(key: string, fn: (...any) -> ())
	if handlers[key] then
		warn(string.format(
			"[NetworkHandler] Overwriting existing handler for key '%s'.\n%s",
			key,
			debug.traceback("", 2)
		))
	end
	handlers[key] = fn
end
 
-- Fire a one-way event to the server — no response expected, no ID attached.
function NetworkHandler.Fire(key: string, data: any)
	remoteEvent:FireServer(key, data)
end
 
-- Fire a request and invoke `callback(result)` when the server responds.
-- Automatically times out after REQUEST_TIMEOUT seconds.
function NetworkHandler.Request(key: string, data: any, callback: (any) -> ())
	local id = nextRequestId()
 
	local timeoutThread = task.delay(REQUEST_TIMEOUT, function()
		if pendingRequests[id] then
			pendingRequests[id] = nil
			warn(string.format(
				"[NetworkHandler] Request '%s' (id=%d) timed out after %ds — no response received.\n%s",
				key, id, REQUEST_TIMEOUT,
				debug.traceback("", 2)
			))
		end
	end)
 
	pendingRequests[id] = { callback = callback, timeoutThread = timeoutThread }
 
	remoteEvent:FireServer(key, data, id)
end
 
-- Reply to a server-initiated request (server → client request/response pattern).
function NetworkHandler.Reply(requestId: number, result: any)
	remoteEvent:FireServer("Response", result, requestId)
end
 
-- Initialize the handler with an optional map of predefined keys → functions.
function NetworkHandler.Init(predefinedHandlers: { [string]: (...any) -> () })
	for key, fn in predefinedHandlers do
		NetworkHandler.Register(key, fn)
	end
 
	remoteEvent.OnClientEvent:Connect(function(key: string, data: any, requestId: number?)
		task.spawn(function()
			-- Response to a previous NetworkHandler.Request call
			if key == "Response" and requestId then
				local entry = pendingRequests[requestId]
				if entry then
					task.cancel(entry.timeoutThread)
					pendingRequests[requestId] = nil
					entry.callback(data)
				end
				return
			end
 
			-- Normal server-fired event
			local handler = handlers[key]
			if not handler then
				warn(string.format(
					"[NetworkHandler] No handler registered for key '%s'.\n%s",
					key,
					debug.traceback("", 2)
				))
				return
			end
 
			local success, err = pcall(handler, data, requestId)
			if not success then
				warn(string.format(
					"[NetworkHandler] Error in handler '%s': %s\n%s",
					key, err,
					debug.traceback("", 2)
				))
			end
		end)
	end)
end
 
return NetworkHandler