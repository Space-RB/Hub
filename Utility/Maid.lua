local Maid = {};
Maid.__index = Maid;

local function cleanupTask(task)
    if task == nil then
        return;
    end;

    local taskType = typeof(task);

    if taskType == "function" then
        task();
    elseif taskType == "RBXScriptConnection" then
        if task.Connected then
            task:Disconnect();
        end;
    elseif taskType == "Instance" then
        pcall(function()
            task:Destroy();
        end);
    elseif taskType == "thread" then
        if coroutine.status(task) ~= "dead" then
            pcall(coroutine.close, task);
        end;
    elseif taskType == "table" then
        if typeof(task.Destroy) == "function" then
            task:Destroy();
        elseif typeof(task.Disconnect) == "function" then
            task:Disconnect();
        elseif typeof(task.Clean) == "function" then
            task:Clean();
        elseif typeof(task.Cleanup) == "function" then
            task:Cleanup();
        elseif typeof(task.Cancel) == "function" then
            task:Cancel();
        elseif typeof(task.destroy) == "function" then
            task:destroy();
        elseif typeof(task.disconnect) == "function" then
            task:disconnect();
        elseif typeof(task.clean) == "function" then
            task:clean();
        elseif typeof(task.cancel) == "function" then
            task:cancel();
        end;
    end;
end

function Maid.new()
    return setmetatable({
        _tasks = {};
        _features = {};
        _indices = {};
    }, Maid);
end

function Maid:_track(task, feature)
    assert(task ~= nil, "Task cannot be nil");

    table.insert(self._tasks, task);

    if feature ~= nil then
        assert(type(feature) == "string" or type(feature) == "number", "Feature must be a string or number");

        local bucket = self._features[feature];
        if not bucket then
            bucket = {};
            self._features[feature] = bucket;
        end;

        table.insert(bucket, task);
    end;

    return task;
end

function Maid:AddTask(task, feature)
    return self:_track(task, feature);
end

function Maid:Add(task)
    return self:_track(task);
end

function Maid:GiveTask(task)
    return self:_track(task);
end

function Maid:GivePromise(promise)
    assert(promise ~= nil, "Promise cannot be nil");

    if promise.Status == "Rejected" or promise.Status == "Resolved" then
        return promise;
    end;

    local connection;
    connection = promise:Finally(function()
        self:Remove(connection);
    end);

    self:_track(connection);
    return promise;
end

function Maid:__newindex(index, task)
    local oldTask = rawget(self._indices, index);

    if oldTask ~= nil then
        self:Remove(oldTask);
    end;

    if task == nil then
        rawset(self._indices, index, nil);
        return;
    end;

    rawset(self._indices, index, task);
    self:_track(task);
end

function Maid:__index(index)
    if Maid[index] then
        return Maid[index];
    end;

    return rawget(self._indices, index);
end

function Maid:Remove(task)
    if task == nil then
        return false;
    end;

    local removed = false;

    for i = #self._tasks, 1, -1 do
        if self._tasks[i] == task then
            table.remove(self._tasks, i);
            removed = true;
            break;
        end;
    end;

    for feature, tasks in pairs(self._features) do
        for i = #tasks, 1, -1 do
            if tasks[i] == task then
                table.remove(tasks, i);
                break;
            end;
        end;

        if #tasks == 0 then
            self._features[feature] = nil;
        end;
    end;

    for index, value in pairs(self._indices) do
        if value == task then
            self._indices[index] = nil;
        end;
    end;

    if removed then
        cleanupTask(task);
    end;

    return removed;
end

function Maid:Cleanup(feature)
    if feature ~= nil then
        assert(type(feature) == "string" or type(feature) == "number", "Feature must be a string or number");

        local tasks = self._features[feature];
        if not tasks then
            return;
        end;

        for i = #tasks, 1, -1 do
            local task = tasks[i];

            for j = #self._tasks, 1, -1 do
                if self._tasks[j] == task then
                    table.remove(self._tasks, j);
                    break;
                end;
            end;

            for index, value in pairs(self._indices) do
                if value == task then
                    self._indices[index] = nil;
                end;
            end;

            cleanupTask(task);
            tasks[i] = nil;
        end;

        self._features[feature] = nil;
        return;
    end;

    for i = #self._tasks, 1, -1 do
        cleanupTask(self._tasks[i]);
        self._tasks[i] = nil;
    end;

    table.clear(self._tasks);
    table.clear(self._features);
    table.clear(self._indices);
end

function Maid:Clean()
    self:Cleanup();
end

function Maid:DoCleaning()
    self:Cleanup();
end

function Maid:Destroy()
    self:Cleanup();
end

return Maid;
