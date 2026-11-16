local TaskScheduler = {}
TaskScheduler.__index = TaskScheduler

function TaskScheduler.new()
    return setmetatable({
        _tasks = {},
        _nextId = 0,
        _clock = 0,
    }, TaskScheduler)
end

function TaskScheduler:Schedule(delaySeconds, callback, repeatInterval)
    assert(delaySeconds >= 0, "Delay cannot be negative")
    assert(type(callback) == "function", "Callback must be a function")

    self._nextId += 1
    local id = self._nextId
    self._tasks[id] = {
        At = self._clock + delaySeconds,
        Callback = callback,
        Interval = repeatInterval,
        Cancelled = false,
    }
    return id
end

function TaskScheduler:Cancel(id)
    local scheduled = self._tasks[id]
    if scheduled then
        scheduled.Cancelled = true
        self._tasks[id] = nil
        return true
    end
    return false
end

function TaskScheduler:Step(deltaTime)
    self._clock += deltaTime
    local due = {}

    for id, scheduled in pairs(self._tasks) do
        if scheduled.At <= self._clock then
            table.insert(due, {Id = id, Task = scheduled})
        end
    end

    table.sort(due, function(a, b)
        return a.Task.At < b.Task.At
    end)

    for _, entry in ipairs(due) do
        local scheduled = self._tasks[entry.Id]
        if scheduled and not scheduled.Cancelled then
            local success, message = pcall(scheduled.Callback)
            if not success then
                warn("[Riftbound Scheduler]", message)
            end

            if scheduled.Interval and scheduled.Interval > 0 then
                scheduled.At = self._clock + scheduled.Interval
            else
                self._tasks[entry.Id] = nil
            end
        end
    end
end

return TaskScheduler
