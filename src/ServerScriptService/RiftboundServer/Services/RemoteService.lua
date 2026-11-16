local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = {}
RemoteService.__index = RemoteService

function RemoteService.new()
    local self = setmetatable({}, RemoteService)
    local folder = ReplicatedStorage:FindFirstChild("RiftboundRemotes")

    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "RiftboundRemotes"
        folder.Parent = ReplicatedStorage
    end

    self.Folder = folder
    self.Action = self:_getRemote("Action")
    self.State = self:_getRemote("State")
    return self
end

function RemoteService:_getRemote(name)
    local remote = self.Folder:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = self.Folder
    end
    return remote
end

function RemoteService:Send(player, payload)
    self.State:FireClient(player, payload)
end

return RemoteService
