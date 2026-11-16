local QuestService = {}
QuestService.__index = QuestService

function QuestService.new(remoteService)
    return setmetatable({
        RemoteService = remoteService,
        Progress = {},
    }, QuestService)
end

function QuestService:InitializePlayer(player)
    self.Progress[player] = {
        Id = "FirstHunt",
        Title = "The First Hunt",
        Description = "Defeat 5 Rift Stalkers.",
        Goal = 5,
        Current = 0,
        Complete = false,
        Reward = 75,
    }
    self:Send(player)
end

function QuestService:EnemyDefeated()
    for player, quest in pairs(self.Progress) do
        if not quest.Complete then
            quest.Current = math.min(quest.Current + 1, quest.Goal)
            if quest.Current >= quest.Goal then
                quest.Complete = true
                local leaderstats = player:FindFirstChild("leaderstats")
                local gold = leaderstats and leaderstats:FindFirstChild("Gold")
                if gold then
                    gold.Value += quest.Reward
                end
            end
            self:Send(player)
        end
    end
end

function QuestService:Send(player)
    local quest = self.Progress[player]
    if quest then
        self.RemoteService:Send(player, {Type = "Quest", Quest = quest})
    end
end

function QuestService:RemovePlayer(player)
    self.Progress[player] = nil
end

return QuestService
