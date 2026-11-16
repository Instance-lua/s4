local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Riftbound.Config)

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(enemyService, remoteService)
    return setmetatable({
        EnemyService = enemyService,
        RemoteService = remoteService,
        LastAction = {},
        LastBurst = {},
    }, CombatService)
end

function CombatService:_getCharacter(player)
    local character = player.Character
    if not character then
        return nil
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        return nil
    end
    return character, root, humanoid
end

function CombatService:_damageNearby(player, radius, damage)
    local character, root = self:_getCharacter(player)
    if not character then
        return 0
    end

    local hitCount = 0
    for model, record in pairs(self.EnemyService.Enemies) do
        if record.Humanoid.Health > 0 and (record.Root.Position - root.Position).Magnitude <= radius then
            record.Humanoid:TakeDamage(damage)
            hitCount += 1
        end
    end
    return hitCount
end

function CombatService:Handle(player, action, target)
    if type(action) ~= "string" then
        return
    end

    local now = os.clock()
    if now - (self.LastAction[player] or 0) < Config.Network.RequestInterval then
        return
    end
    self.LastAction[player] = now

    if action == "Attack" then
        local _, root = self:_getCharacter(player)
        if not root then
            return
        end

        local last = player:GetAttribute("LastBasicAttack") or 0
        if now - last < Config.Player.BasicCooldown then
            return
        end
        player:SetAttribute("LastBasicAttack", now)

        local bestRecord, bestDistance
        for _, record in pairs(self.EnemyService.Enemies) do
            local offset = record.Root.Position - root.Position
            local distance = offset.Magnitude
            if distance <= Config.Player.BasicRange and distance > 0 then
                local facing = root.CFrame.LookVector:Dot(offset.Unit)
                if facing > 0.1 and (not bestDistance or distance < bestDistance) then
                    bestRecord = record
                    bestDistance = distance
                end
            end
        end

        if bestRecord then
            bestRecord.Humanoid:TakeDamage(Config.Player.BasicDamage)
            self.RemoteService:Send(player, {Type = "Hit", Damage = Config.Player.BasicDamage})
        end
    elseif action == "RiftBurst" then
        if now - (self.LastBurst[player] or 0) < Config.Player.RiftBurstCooldown then
            return
        end
        self.LastBurst[player] = now
        local hitCount = self:_damageNearby(player, Config.Player.RiftBurstRadius, Config.Player.RiftBurstDamage)
        self.RemoteService:Send(player, {Type = "Ability", Ability = "RiftBurst", Hits = hitCount})
    elseif action == "Collect" then
        if typeof(target) == "Instance" and target:IsA("BasePart") and target.Parent then
            self.RemoteService.CollectLoot(player, target)
        end
    elseif action == "InteractExit" then
        local _, root = self:_getCharacter(player)
        local portal = Workspace.RiftboundDungeon and Workspace.RiftboundDungeon:FindFirstChild("ExitPortal")
        if root and portal and (root.Position - portal.Position).Magnitude <= 16 then
            self.RemoteService:Send(player, {Type = "RunComplete"})
        end
    end
end

function CombatService:RemovePlayer(player)
    self.LastAction[player] = nil
    self.LastBurst[player] = nil
end

return CombatService
