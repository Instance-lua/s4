local EntityRegistry = {}
EntityRegistry.__index = EntityRegistry

function EntityRegistry.new()
    return setmetatable({
        _nextId = 0,
        _entities = {},
        _components = {},
    }, EntityRegistry)
end

function EntityRegistry:Create()
    self._nextId += 1
    local id = self._nextId
    self._entities[id] = true
    return id
end

function EntityRegistry:Destroy(id)
    if not self._entities[id] then
        return false
    end

    self._entities[id] = nil
    for _, componentMap in pairs(self._components) do
        componentMap[id] = nil
    end
    return true
end

function EntityRegistry:Add(id, componentName, value)
    assert(self._entities[id], "Unknown entity")
    local componentMap = self._components[componentName] or {}
    self._components[componentName] = componentMap
    componentMap[id] = value
end

function EntityRegistry:Get(id, componentName)
    local componentMap = self._components[componentName]
    return componentMap and componentMap[id]
end

function EntityRegistry:Query(...)
    local names = {...}
    local results = {}

    for id in pairs(self._entities) do
        local matches = true
        for _, name in ipairs(names) do
            local componentMap = self._components[name]
            if not componentMap or componentMap[id] == nil then
                matches = false
                break
            end
        end

        if matches then
            table.insert(results, id)
        end
    end

    return results
end

function EntityRegistry:Count()
    local count = 0
    for _ in pairs(self._entities) do
        count += 1
    end
    return count
end

return EntityRegistry
