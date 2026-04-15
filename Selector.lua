local IDS = {
    -- Tower Defense Simulator
    [5591597781] = "https://raw.githubusercontent.com/Space-RB/Premium/refs/heads/main/TDS-loader.lua", -- TDS | Game
    [3260590327] = "https://raw.githubusercontent.com/Space-RB/Premium/refs/heads/main/TDS-loader.lua", -- TDS | Lobby
}
local Names = {
    ["TDS"] = "https://raw.githubusercontent.com/Space-RB/Premium/refs/heads/main/TDS-loader.lua", -- Tower Defense Simulator
}

local activeCount = 0
for _, url in pairs(IDS) do
    if url and url ~= "" then
        activeCount = activeCount + 1
    end
end

print(string.format("[Space Hub]: Loaded %d active script mappings. Total entries: %d", activeCount, table.getn(IDS) or 0))

local activeCount = 0
local function countActiveScripts()
    for _, url in pairs(Names) do
        if url and url ~= "" then
            activeCount = activeCount + 1
        end
    end
    return activeCount
end

print(string.format("[Space Hub]: Loaded NAMES list with %d active scripts. Total entries: %d", countActiveScripts(), table.getn(Names) or 0))

function Names:getInfo(scriptName)
    local url = self[scriptName]
    if url and url ~= "" then
        return {
            name = scriptName,
            url = url,
            active = true
        }
    elseif url == "" then
        return {
            name = scriptName,
            url = nil,
            active = false,
            status = "disabled"
        }
    else
        return nil
    end
end

function Names:getActiveScripts()
    local active = {}
    for name, url in pairs(self) do
        if type(name) == "string" and url and url ~= "" then
            table.insert(active, name)
        end
    end
    return active
end

return IDS, Names
