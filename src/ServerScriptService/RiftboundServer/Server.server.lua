local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ServicesFolder = script.Parent.Services
local RemoteService = require(ServicesFolder.RemoteService).new()
local DungeonService = require(ServicesFolder.DungeonService).new()
local EnemyService = require(ServicesFolder.EnemyService).new()
local LootService = require(ServicesFolder.LootService).new()
local QuestService = require(ServicesFolder.QuestService).new(RemoteService)
local PlayerService = require(ServicesFolder.PlayerService).new(RemoteService)
local CombatService = require(ServicesFolder.CombatService).new(EnemyService, RemoteService)

RemoteService.CollectLoot = function(player, orb)
    local success, result = LootService:Collect(player, orb)
    if success then
        local stats = player:FindFirstChild("leaderstats")
        local gold = stats and stats:FindFirstChild("Gold")
        if gold then
            gold.Value += 5
        end
        RemoteService:Send(player, {Type = "Loot", Item = result})
    else
        RemoteService:Send(player, {Type = "Notice", Message = result})
    end
end

DungeonService:Generate()
LootService:Start()
EnemyService:Spawn(DungeonService:GetEnemySpawnPoints())

EnemyService.OnEnemyDefeated = function(model, position)
    LootService:Drop(position)
    QuestService:EnemyDefeated()
    for _, player in ipairs(Players:GetPlayers()) do
        PlayerService:AwardDefeat(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    PlayerService:Initialize(player)
    QuestService:InitializePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    QuestService:RemovePlayer(player)
    CombatService:RemovePlayer(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    PlayerService:Initialize(player)
    QuestService:InitializePlayer(player)
end

RemoteService.Action.OnServerEvent:Connect(function(player, action, target)
    CombatService:Handle(player, action, target)
end)

local enemyAccumulator = 0
RunService.Heartbeat:Connect(function(deltaTime)
    enemyAccumulator += deltaTime
    if enemyAccumulator >= 0.25 then
        enemyAccumulator = 0
        EnemyService:Step()
    end
end)

print("[Riftbound] Dungeon generated. Systems online.")
