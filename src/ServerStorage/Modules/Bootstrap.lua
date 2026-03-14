local Bootstrap = {}

local function getOrCreateRemotesDir(): Folder
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes or not remotes:IsA("Folder") then
        remotes = Instance.new("Folder")
        remotes.Name = "Remotes"
        remotes.Parent = ReplicatedStorage
    end
    return remotes
end

local function getOrCreateRemoteEvent(folder: Folder): RemoteEvent
    local remoteEvent = folder:FindFirstChild("RemoteEvent")
    if not remoteEvent or not remoteEvent:IsA("RemoteEvent") then
        remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = "RemoteEvent"
        remoteEvent.Parent = folder
    end
    return remoteEvent
end

local function getOrCreateRemoteFunction(folder: Folder): RemoteFunction
    local remoteFunc = folder:FindFirstChild("RemoteFunction")
    if not remoteFunc or not remoteFunc:IsA("RemoteFunction") then
        remoteFunc = Instance.new("RemoteFunction")
        remoteFunc.Name = "RemoteFunction"
        remoteFunc.Parent = folder
    end
    return remoteFunc
end

local function getOrCreateUnreliableRemoteEvent(folder: Folder): UnreliableRemoteEvent
    local unreliableEvent = folder:FindFirstChild("UnreliableRemoteEvent")
    if not unreliableEvent or not unreliableEvent:IsA("UnreliableRemoteEvent") then
        unreliableEvent = Instance.new("UnreliableRemoteEvent")
        unreliableEvent.Name = "UnreliableRemoteEvent"
        unreliableEvent.Parent = folder
    end
    return unreliableEvent
end

function Bootstrap.Init()
    local folder = getOrCreateRemotesDir()
    getOrCreateRemoteEvent(folder)
    getOrCreateRemoteFunction(folder)
    getOrCreateUnreliableRemoteEvent(folder)
end

return Bootstrap