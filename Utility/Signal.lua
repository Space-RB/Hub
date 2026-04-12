local Signal = {};
Signal.__index = Signal;

function Signal.new()
    return setmetatable({
        _connections = {};
        _waiting = {};
        _destroyed = false;
    }, Signal);
end

local function disconnectConnection(connection)
    if connection and not connection._disconnected then
        connection._disconnected = true;
        connection._handler = nil;
        connection._signal = nil;
    end;
end

function Signal:Connect(handler)
    assert(not self._destroyed, "Cannot connect to destroyed Signal");
    assert(type(handler) == "function", "Handler must be a function");

    local connection = {
        _signal = self;
        _handler = handler;
        _disconnected = false;
    };

    function connection:Disconnect()
        disconnectConnection(connection);
    end

    table.insert(self._connections, connection);
    return connection;
end

function Signal:Once(handler)
    assert(not self._destroyed, "Cannot connect to destroyed Signal");
    assert(type(handler) == "function", "Handler must be a function");

    local connection;
    connection = self:Connect(function(...)
        if connection then
            connection:Disconnect();
        end;
        handler(...);
    end);

    return connection;
end

function Signal:Fire(...)
    if self._destroyed then
        return;
    end;

    local args = table.pack(...);

    for i = #self._connections, 1, -1 do
        local connection = self._connections[i];

        if connection._disconnected then
            table.remove(self._connections, i);
        elseif connection._handler then
            task.spawn(connection._handler, table.unpack(args, 1, args.n));
        end;
    end;

    for i = #self._waiting, 1, -1 do
        local thread = table.remove(self._waiting, i);
        task.spawn(thread, table.unpack(args, 1, args.n));
    end;
end

function Signal:Wait()
    assert(not self._destroyed, "Cannot wait on destroyed Signal");

    local thread = coroutine.running();
    assert(thread, "Signal:Wait must be called from a coroutine");

    table.insert(self._waiting, thread);
    return coroutine.yield();
end

function Signal:DisconnectAll()
    for i = #self._connections, 1, -1 do
        disconnectConnection(self._connections[i]);
        self._connections[i] = nil;
    end;

    table.clear(self._connections);
end

function Signal:Destroy()
    if self._destroyed then
        return;
    end;

    self._destroyed = true;
    self:DisconnectAll();
    table.clear(self._waiting);
end

return Signal;
