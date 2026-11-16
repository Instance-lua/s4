local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({_tasks = {}, _cleaning = false}, Maid)
end

function Maid:Give(taskObject)
    assert(not self._cleaning, "Cannot add tasks while cleaning")
    table.insert(self._tasks, taskObject)
    return taskObject
end

function Maid:Clean()
    if self._cleaning then
        return
    end

    self._cleaning = true
    for index = #self._tasks, 1, -1 do
        local taskObject = self._tasks[index]
        local kind = typeof(taskObject)

        if kind == "RBXScriptConnection" then
            taskObject:Disconnect()
        elseif kind == "Instance" then
            taskObject:Destroy()
        elseif type(taskObject) == "function" then
            taskObject()
        elseif type(taskObject) == "table" then
            if type(taskObject.Destroy) == "function" then
                taskObject:Destroy()
            elseif type(taskObject.Disconnect) == "function" then
                taskObject:Disconnect()
            end
        end
        self._tasks[index] = nil
    end
    self._cleaning = false
end

Maid.Destroy = Maid.Clean

return Maid
