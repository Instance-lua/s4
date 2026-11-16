local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Riftbound.Config)

local EnemyService = {}
EnemyService.__index = EnemyService

function EnemyService.new()
    local self = setmetatable({}, EnemyService)

    self.Enemies = {}
    self.Folder = nil
    self.OnEnemyDefeated = nil

    return self
end

function EnemyService:_nearestPlayer(position)
    local nearestPlayer = nil
    local nearestDistance = Config.Enemy.DetectionRange

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if not character then
            continue
        end

        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if not root or not humanoid or humanoid.Health <= 0 then
            continue
        end

        local distance = (root.Position - position).Magnitude

        if distance < nearestDistance then
            nearestPlayer = player
            nearestDistance = distance
        end
    end

    return nearestPlayer, nearestPlayer and nearestDistance or nil
end

function EnemyService:_createEnemy(position, index)
    local model = Instance.new("Model")
    model.Name = "RiftStalker_" .. index

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(4, 5, 3)
    root.Position = position
    root.Color = Color3.fromRGB(115, 63, 180)
    root.Material = Enum.Material.Neon
    root.Anchored = false
    root.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(3, 2, 3)
    head.Position = position + Vector3.new(0, 3.3, 0)
    head.Color = Color3.fromRGB(38, 24, 58)
    head.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = head
    weld.Parent = root

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = Config.Enemy.MaxHealth
    humanoid.Health = Config.Enemy.MaxHealth
    humanoid.WalkSpeed = Config.Enemy.MoveSpeed
    humanoid.DisplayName = "Rift Stalker"
    humanoid.Parent = model

    model.PrimaryPart = root
    model.Parent = self.Folder

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(116, 67, 195)
    highlight.OutlineColor = Color3.fromRGB(204, 166, 255)
    highlight.FillTransparency = 0.55
    highlight.Parent = model

    local enemy = {
        Model = model,
        Root = root,
        Humanoid = humanoid,
        SpawnPosition = position,
        LastAttack = 0,
        LastPath = 0,
        State = "Wander",
        Dead = false,
    }

    self.Enemies[model] = enemy

    humanoid.Died:Connect(function()
        if enemy.Dead then
            return
        end

        enemy.Dead = true
        self.Enemies[model] = nil

        if self.OnEnemyDefeated then
            self.OnEnemyDefeated(model, root.Position)
        end

        task.delay(2, function()
            model:Destroy()
        end)
    end)

    return enemy
end

function EnemyService:Spawn(spawnPoints)
    if self.Folder then
        self.Folder:Destroy()
    end

    table.clear(self.Enemies)

    self.Folder = Instance.new("Folder")
    self.Folder.Name = "RiftboundEnemies"
    self.Folder.Parent = Workspace

    for index, position in ipairs(spawnPoints) do
        self:_createEnemy(position, index)
    end
end

function EnemyService:_moveToward(enemy, targetPosition)
    local now = os.clock()

    if now - enemy.LastPath < 2.5 then
        return
    end

    enemy.LastPath = now

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
    })

    local success = pcall(function()
        path:ComputeAsync(enemy.Root.Position, targetPosition)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        enemy.Humanoid:MoveTo(targetPosition)
        return
    end

    local waypoints = path:GetWaypoints()
    local waypoint = waypoints[2]

    if waypoint then
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            enemy.Humanoid.Jump = true
        end

        enemy.Humanoid:MoveTo(waypoint.Position)
    end
end

function EnemyService:Step()
    for _, enemy in pairs(self.Enemies) do
        local humanoid = enemy.Humanoid
        local root = enemy.Root

        if enemy.Dead or humanoid.Health <= 0 or not root.Parent then
            continue
        end

        local player, distance = self:_nearestPlayer(root.Position)

        if not player then
            enemy.State = "Wander"

            if (root.Position - enemy.SpawnPosition).Magnitude > 8 then
                self:_moveToward(enemy, enemy.SpawnPosition)
            end

            continue
        end

        local character = player.Character
        local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
            continue
        end

        if distance <= Config.Enemy.AttackRange then
            enemy.State = "Attack"
            humanoid:MoveTo(root.Position)

            if os.clock() - enemy.LastAttack >= Config.Enemy.AttackCooldown then
                enemy.LastAttack = os.clock()
                targetHumanoid:TakeDamage(Config.Enemy.Damage)
            end
        else
            enemy.State = "Chase"
            self:_moveToward(enemy, targetRoot.Position)
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
