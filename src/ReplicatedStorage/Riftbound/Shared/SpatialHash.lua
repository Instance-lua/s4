local SpatialHash = {}
SpatialHash.__index = SpatialHash

function SpatialHash.new(cellSize)
    assert(cellSize > 0, "Cell size must be positive")
    return setmetatable({
        CellSize = cellSize,
        Cells = {},
        Membership = {},
    }, SpatialHash)
end

function SpatialHash:_key(x, z)
    return tostring(x) .. ":" .. tostring(z)
end

function SpatialHash:_coordinates(position)
    return math.floor(position.X / self.CellSize), math.floor(position.Z / self.CellSize)
end

function SpatialHash:Insert(object, position)
    self:Remove(object)
    local x, z = self:_coordinates(position)
    local key = self:_key(x, z)
    local cell = self.Cells[key] or {}
    self.Cells[key] = cell
    cell[object] = true
    self.Membership[object] = key
end

function SpatialHash:Remove(object)
    local key = self.Membership[object]
    if not key then
        return
    end

    local cell = self.Cells[key]
    if cell then
        cell[object] = nil
        if next(cell) == nil then
            self.Cells[key] = nil
        end
    end
    self.Membership[object] = nil
end

function SpatialHash:Query(position, radius)
    local minX = math.floor((position.X - radius) / self.CellSize)
    local maxX = math.floor((position.X + radius) / self.CellSize)
    local minZ = math.floor((position.Z - radius) / self.CellSize)
    local maxZ = math.floor((position.Z + radius) / self.CellSize)
    local results = {}

    for x = minX, maxX do
        for z = minZ, maxZ do
            local cell = self.Cells[self:_key(x, z)]
            if cell then
                for object in pairs(cell) do
                    table.insert(results, object)
                end
            end
        end
    end

    return results
end

function SpatialHash:Clear()
    table.clear(self.Cells)
    table.clear(self.Membership)
end

return SpatialHash
