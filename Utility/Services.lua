local Services = {};
local VirtualInputManager = getvirtualinputmanager and getvirtualinputmanager();

function Services:Get(...)
    local count = select("#", ...);
    local result = table.create(count);

    for i = 1, count do
        result[i] = self[select(i, ...)];
    end;

    return table.unpack(result, 1, count);
end

setmetatable(Services, {
    __index = function(self, key)
        if key == "VirtualInputManager" then
            return VirtualInputManager;
        elseif key == "CurrentCamera" then
            return workspace.CurrentCamera;
        end;

        local ok, service = pcall(game.GetService, game, key);
        if ok then
            rawset(self, key, service);
            return service;
        end;

        error(("Service '%s' does not exist"):format(tostring(key)), 2);
    end;
});

return Services;
