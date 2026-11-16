local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({
        _listeners = {},
        _nextId = 0,
        _destroyed = false,
    }, Signal)
end

function Signal:Connect(callback)
    assert(type(callback) == "function", "Signal callback must be a function")
    assert(not self._destroyed, "Cannot connect to a destroyed Signal")

    self._nextId += 1
    local id = self._nextId
    local connection = {Connected = true}

    function connection:Disconnect()
        if not self.Connected then
            return
        end
        self.Connected = false
    end

    self._listeners[id] = {
        Callback = callback,
        Connection = connection,
    }

    return connection
end

function Signal:Once(callback)
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        callback(...)
    end)
    return connection
end

function Signal:Fire(...)
    if self._destroyed then
        return
    end

    local args = table.pack(...)
    for id, entry in pairs(self._listeners) do
        if entry.Connection.Connected then
            task.spawn(entry.Callback, table.unpack(args, 1, args.n))
        else
            self._listeners[id] = nil
        end
    end
end

function Signal:Destroy()
    self._destroyed = true
    table.clear(self._listeners)
end

return Signal
