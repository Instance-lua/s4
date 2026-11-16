local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Riftbound.Config)

local DungeonService = {}
DungeonService.__index = DungeonService

local ROOM_COLORS = {
    Color3.fromRGB(47, 54, 75),
    Color3.fromRGB(53, 63, 82),
    Color3.fromRGB(61, 53, 78),
}

function DungeonService.new()
    return setmetatable({
        Rooms = {},
        Folder = nil,
        Random = Random.new(Config.World.Seed),
        ExitPosition = Vector3.zero,
    }, DungeonService)
end

function DungeonService:_part(parent, name, size, cframe, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.Slate
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function DungeonService:_makeRoom(index, gridPosition)
    local size = Config.World.RoomSize
    local height = Config.World.WallHeight
    local center = Vector3.new(gridPosition.X * size, 0, gridPosition.Y * size)
    local model = Instance.new("Model")
    model.Name = "Room_" .. index
    model.Parent = self.Folder

    local floorColor = ROOM_COLORS[self.Random:NextInteger(1, #ROOM_COLORS)]
    self:_part(model, "Floor", Vector3.new(size, 2, size), CFrame.new(center), floorColor, Enum.Material.Slate)

    local wallColor = Color3.fromRGB(25, 29, 43)
    local wallY = height / 2
    local wallThickness = 3
    local opening = 17

    self:_part(model, "NorthWallLeft", Vector3.new((size - opening) / 2, height, wallThickness),
        CFrame.new(center + Vector3.new(-(size + opening) / 4, wallY, -size / 2)), wallColor)
    self:_part(model, "NorthWallRight", Vector3.new((size - opening) / 2, height, wallThickness),
        CFrame.new(center + Vector3.new((size + opening) / 4, wallY, -size / 2)), wallColor)
    self:_part(model, "SouthWallLeft", Vector3.new((size - opening) / 2, height, wallThickness),
        CFrame.new(center + Vector3.new(-(size + opening) / 4, wallY, size / 2)), wallColor)
    self:_part(model, "SouthWallRight", Vector3.new((size - opening) / 2, height, wallThickness),
        CFrame.new(center + Vector3.new((size + opening) / 4, wallY, size / 2)), wallColor)
    self:_part(model, "EastWall", Vector3.new(wallThickness, height, size),
        CFrame.new(center + Vector3.new(size / 2, wallY, 0)), wallColor)
    self:_part(model, "WestWall", Vector3.new(wallThickness, height, size),
        CFrame.new(center + Vector3.new(-size / 2, wallY, 0)), wallColor)

    local pillarOffset = size / 2 - 8
    for _, x in ipairs({-pillarOffset, pillarOffset}) do
        for _, z in ipairs({-pillarOffset, pillarOffset}) do
            self:_part(model, "Pillar", Vector3.new(5, height, 5),
                CFrame.new(center + Vector3.new(x, wallY, z)), Color3.fromRGB(37, 42, 59))
        end
    end

    local crystal = self:_part(model, "RiftCrystal", Vector3.new(3, 8, 3),
        CFrame.new(center + Vector3.new(0, 5, 0)) * CFrame.Angles(0, math.rad(45), 0),
        Color3.fromRGB(108, 75, 255), Enum.Material.Neon)
    crystal.Shape = Enum.PartType.Block

    table.insert(self.Rooms, {
        Index = index,
        Center = center,
        Model = model,
        Crystal = crystal,
    })

    return center
end

function DungeonService:_connectRooms(from, to)
    local midpoint = (from + to) / 2
    local delta = to - from
    local length = delta.Magnitude
    local width = Config.World.CorridorWidth
    local size = delta.X ~= 0 and Vector3.new(length, 2, width) or Vector3.new(width, 2, length)
    self:_part(self.Folder, "Corridor", size, CFrame.new(midpoint), Color3.fromRGB(40, 46, 65))
end

function DungeonService:Generate()
    local existing = Workspace:FindFirstChild("RiftboundDungeon")
    if existing then
        existing:Destroy()
    end

    self.Folder = Instance.new("Folder")
    self.Folder.Name = "RiftboundDungeon"
    self.Folder.Parent = Workspace

    local positions = {{X = 0, Y = 0}}
    local occupied = {["0:0"] = true}
    local directions = {{X = 1, Y = 0}, {X = -1, Y = 0}, {X = 0, Y = 1}, {X = 0, Y = -1}}

    while #positions < Config.World.RoomCount do
        local base = positions[self.Random:NextInteger(1, #positions)]
        local direction = directions[self.Random:NextInteger(1, #directions)]
        local candidate = {X = base.X + direction.X, Y = base.Y + direction.Y}
        local key = candidate.X .. ":" .. candidate.Y

        if not occupied[key] then
            occupied[key] = true
            table.insert(positions, candidate)
        end
    end

    local previousCenters = {}
    for index, gridPosition in ipairs(positions) do
        local center = self:_makeRoom(index, gridPosition)
        previousCenters[index] = center

        if index > 1 then
            local nearestIndex = 1
            local nearestDistance = math.huge
            for otherIndex = 1, index - 1 do
                local distance = (previousCenters[otherIndex] - center).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestIndex = otherIndex
                end
            end
            self:_connectRooms(previousCenters[nearestIndex], center)
        end
    end

    self.ExitPosition = previousCenters[#previousCenters] + Vector3.new(0, 3, 0)
    local exit = self:_part(self.Folder, "ExitPortal", Vector3.new(10, 1, 10),
        CFrame.new(self.ExitPosition), Color3.fromRGB(65, 230, 190), Enum.Material.Neon)
    exit.CanCollide = false
    exit:SetAttribute("Interactable", "Exit")
    exit:SetAttribute("RoomIndex", #positions)

    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    if not spawn then
        spawn = Instance.new("SpawnLocation")
        spawn.Name = "RiftboundSpawn"
        spawn.Size = Vector3.new(8, 1, 8)
        spawn.Parent = Workspace
    end
    spawn.CFrame = CFrame.new(previousCenters[1] + Vector3.new(0, 4, 0))
    spawn.Neutral = true

    return self.Rooms
end

function DungeonService:GetEnemySpawnPoints()
    local points = {}
    for index = 2, #self.Rooms do
        local center = self.Rooms[index].Center
        table.insert(points, center + Vector3.new(12, 4, 0))
        table.insert(points, center + Vector3.new(-12, 4, 0))
    end
    return points
end

return DungeonService
