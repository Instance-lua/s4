local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Riftbound.Config)

local PlayerService = {}
PlayerService.__index = PlayerService

function PlayerService.new(remoteService)
    return setmetatable({RemoteService = remoteService}, PlayerService)
end

function PlayerService:Initialize(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local gold = Instance.new("IntValue")
    gold.Name = "Gold"
    gold.Value = 0
    gold.Parent = leaderstats

    local defeats = Instance.new("IntValue")
    defeats.Name = "Defeats"
    defeats.Value = 0
    defeats.Parent = leaderstats

    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid then
            humanoid.MaxHealth = Config.Player.MaxHealth
            humanoid.Health = Config.Player.MaxHealth
            humanoid.WalkSpeed = Config.Player.WalkSpeed
        end
    end)
end

function PlayerService:AwardDefeat(player)
    local stats = player:FindFirstChild("leaderstats")
    local defeats = stats and stats:FindFirstChild("Defeats")
    if defeats then
        defeats.Value += 1
    end
end

return PlayerService
