local IDS = {
    [5591597781] = "https://f.space-hub.cc/Scripts/TDS/UI.lua",           -- TDS | Game
    [3260590327] = "https://f.space-hub.cc/Scripts/TDS/UI.lua",           -- TDS | Lobby
    [77747658251236] = "https://f.space-hub.cc/Scripts/SailorPierce.lua",                -- Sailor Pierce
}

local Names = {
    ["TDS"] = "https://f.space-hub.cc/Scripts/TDS/UI.lua",                -- TDS
    ["Sailor Pierce"] = "https://f.space-hub.cc/Scripts/SailorPierce.lua",                -- Sailor Pierce
}

local function count(t)
    local c = 0
    for _, v in pairs(t) do if v and v ~= "" then c = c + 1 end end
    return c
end

print("[Space Hub]: IDS - " .. count(IDS) .. " | Names - " .. count(Names))

return IDS, Names
