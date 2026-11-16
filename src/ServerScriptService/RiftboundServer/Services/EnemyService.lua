local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Riftbound.Config)

local EnemyService = {}
EnemyService.__index = EnemyService

function EnemyService.new()
    return setmetatable({
        Enemies = {},
        Random = Random.new(),
        Folder = nil,
        OnEnemyDefeated = nil,
    }, EnemyService)
end

function EnemyService:_nearestPlayer(position)
    local nearestPlayer, nearestDistance
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health > 0 then
            local distance = (root.Position - position).Magnitude
            if distance <= Config.Enemy.DetectionRange and (not nearestDistance or distance < nearestDistance) then
                nearestPlayer = player
                nearestDistance = distance
            end
        end
    end
    return nearestPlayer, nearestDistance
end

function EnemyService:_createEnemy(position, index)
    local model = Instance.new("Model")
    model.Name = "RiftStalker_" .. index
    model.Parent = self.Folder

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(4, 5, 3)
    root.Color = Color3.fromRGB(115, 63, 180)
    root.Material = Enum.Material.Neon
    root.Position = position
    root.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(3, 2, 3)
    head.Color = Color3.fromRGB(38, 24, 58)
    head.Position = position + Vector3.new(0, 3.3, 0)
    head.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = head
    weld.Parent = root

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = Config.Enemy.MaxHealth
    humanoid.Health = humanoid.MaxHealth
    humanoid.WalkSpeed = Config.Enemy.MoveSpeed
    humanoid.DisplayName = "Rift Stalker"
    humanoid.Parent = model
    model.PrimaryPart = root

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(116, 67, 195)
    highlight.OutlineColor = Color3.fromRGB(204, 166, 255)
    highlight.FillTransparency = 0.55
    highlight.Parent = model

    local record = {
        Model = model,
        Humanoid = humanoid,
        Root = root,
        LastAttack = 0,
        LastPath = 0,
        State = "Wander",
        SpawnPosition = position,
        Dead = false,
    }
    self.Enemies[model] = record

    humanoid.Died:Connect(function()
        if record.Dead then
            return
        end
        record.Dead = true
        self.Enemies[model] = nil
        if self.OnEnemyDefeated then
            self.OnEnemyDefeated(model, root.Position)
        end
        task.delay(2, function()
            if model.Parent then
                model:Destroy()
            end
        end)
    end)

    return record
end

function EnemyService:Spawn(spawnPoints)
    self.Folder = Workspace:FindFirstChild("RiftboundEnemies")
    if self.Folder then
        self.Folder:Destroy()
    end
    self.Folder = Instance.new("Folder")
    self.Folder.Name = "RiftboundEnemies"
    self.Folder.Parent = Workspace

    for index, position in ipairs(spawnPoints) do
        self:_createEnemy(position, index)
    end
end

function EnemyService:_moveToward(record, targetPosition)
    if os.clock() - record.LastPath > 2.5 then
        record.LastPath = os.clock()
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
        })

        local success = pcall(function()
            path:ComputeAsync(record.Root.Position, targetPosition)
        end)

        if success and path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            local waypoint = waypoints[math.min(2, #waypoints)]
            if waypoint then
                record.Humanoid:MoveTo(waypoint.Position)
                return
            end
        end
    end

    record.Humanoid:MoveTo(targetPosition)
end

function EnemyService:Step()
    for _, record in pairs(self.Enemies) do
        if record.Humanoid.Health > 0 and record.Root.Parent then
            local player, distance = self:_nearestPlayer(record.Root.Position)

            if player and player.Character then
                local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if targetRoot and targetHumanoid then
                    if distance <= Config.Enemy.AttackRange then
                        record.State = "Attack"
                        record.Humanoid:MoveTo(record.Root.Position)
                        if os.clock() - record.LastAttack >= Config.Enemy.AttackCooldown then
                            record.LastAttack = os.clock()
                            targetHumanoid:TakeDamage(Config.Enemy.Damage)
                        end
                    else
                        record.State = "Chase"
                        self:_moveToward(record, targetRoot.Position)
                    end
                end
            else
                record.State = "Wander"
                if (record.Root.Position - record.SpawnPosition).Magnitude > 8 then
                    self:_moveToward(record, record.SpawnPosition)
                end
            end
        end
    end
end

function EnemyService:GetAliveCount()
    local count = 0
    for _ in pairs(self.Enemies) do
        count += 1
    end
    return count
end

return EnemyService
