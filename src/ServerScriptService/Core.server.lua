--[[
Module Loader
Loads all ModuleScripts in a folder, calls Init() then Start() on each.
Supports configurable function prefixes and optional debug prints.
]]

local CONFIG = {
	ModuleDirectory = game:GetService("ServerStorage").Modules,
	IsInDebugMode = false, -- debug prints for development
	InitFuncPrefix = "Init",
	StartFuncPrefix = "Start"
}

assert(CONFIG.ModuleDirectory, "[FATAL] No folder for modules found in config.")
assert(CONFIG.IsInDebugMode ~= nil, "[FATAL] IsInDebugMode not set in config.")
assert(CONFIG.InitFuncPrefix, "[FATAL] No init function prefix found in config.")
assert(CONFIG.StartFuncPrefix, "[FATAL] No start function prefix found in config.")

assert(typeof(CONFIG.ModuleDirectory) == "Instance", "[FATAL] ModuleDirectory must be an Instance")
assert(type(CONFIG.IsInDebugMode) == "boolean", "[FATAL] IsInDebugMode must be a boolean")
assert(type(CONFIG.InitFuncPrefix) == "string", "[FATAL] InitFuncPrefix must be a string")
assert(type(CONFIG.StartFuncPrefix) == "string", "[FATAL] StartFuncPrefix must be a string")

local moduleRegistry = {}

-- Load all ModuleScripts in ModuleDirectory
local function loadModules()
	for _, obj in ipairs(CONFIG.ModuleDirectory:GetDescendants()) do
		if obj:IsA("ModuleScript") then
			local module = require(obj)
			table.insert(moduleRegistry, module)
			if CONFIG.IsInDebugMode then
				local name = module.Name or obj.Name or "UnknownModule"
				print("Loaded: ", name)
			end
		end
	end
end

-- Call Init (or custom prefix) on each module
local function initializeModules()
	for _, module in ipairs(moduleRegistry) do
		if type(module) == "table" and type(module[CONFIG.InitFuncPrefix]) == "function" then
			local success, err = pcall(module[CONFIG.InitFuncPrefix], module)
			if success and CONFIG.IsInDebugMode then
				local name = module.Name or "UnknownModule"
				print("Init success: ", name)
			elseif not success then
				warn("Init failed: ", err)
			end
		end
	end
end

-- Call Start (or custom prefix) on each module
local function startModules()
	for _, module in ipairs(moduleRegistry) do
		if type(module) == "table" and type(module[CONFIG.StartFuncPrefix]) == "function" then
			local success, err = pcall(module[CONFIG.StartFuncPrefix], module)
			if success and CONFIG.IsInDebugMode then
				local name = module.Name or "UnknownModule"
				print("Start success: ", name)
			elseif not success then
				warn("Start failed:", err)
			end
		end
	end
end

-- RUN LOADER
loadModules()
initializeModules()
startModules()