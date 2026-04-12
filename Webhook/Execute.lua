local webhookUrl = "https://discord.com/api/webhooks/1492916791473737869/LIW8GtbnFxY1eLEg7JGtWo_CdUjmAaIUqZmMaYoroYAiu97mCtKCP-de_O0j_jG-2Kki";

local HttpService = game:GetService("HttpService");

if not isfolder("Space-Hub") then
    makefolder("Space-Hub");
end
if not isfolder("Space-Hub/Stats") then
    makefolder("Space-Hub/Stats");
end

local statsFile = "Space-Hub/Stats/Statistics.json";
local idFile = "Space-Hub/Stats/Id.json";

local statsData = {
    totalInjects = 0,
    lastInjectTime = "Never",
    lastGame = "None"
};

local function generateRandomId(length)
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    local randomId = "";
    for i = 1, length do
        local rand = math.random(1, #chars);
        randomId = randomId .. chars:sub(rand, rand);
    end
    return randomId;
end;

local function formatNumber(num)
    if num < 1000 then
        return tostring(num);
    elseif num < 10000 then
        return string.format("%.3f", num / 1000):gsub("%.?0+$", "") .. "k";
    elseif num < 1000000 then
        return string.format("%.1f", num / 1000) .. "k";
    else
        return string.format("%.1f", num / 1000000) .. "M";
    end
end;

if isfile(statsFile) then
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(statsFile));
    end);
    if success then
        statsData = result;
    else
        warn("Failed to load stats file: " .. tostring(result));
    end
end;

local userId;
local pingEveryone = false;

if isfile(idFile) then
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(idFile));
    end);

    if success and data and data.id then
        userId = tostring(data.id);
        if #userId ~= 32 then
            pingEveryone = true;
            userId = generateRandomId(32);
            writefile(idFile, HttpService:JSONEncode({id = userId}));
        end
    else
        userId = generateRandomId(32);
        writefile(idFile, HttpService:JSONEncode({id = userId}));
    end
else
    userId = generateRandomId(32);
    writefile(idFile, HttpService:JSONEncode({id = userId}));
end;

local gameName;
if getgenv().GameName then
    gameName = tostring(getgenv().GameName);
else
    local success, result = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name;
    end);
    gameName = success and tostring(result) or "Unknown Game";
end;

statsData.totalInjects = (statsData.totalInjects or 0) + 1;
statsData.lastInjectTime = os.date("%Y-%m-%d %H:%M:%S");
statsData.lastGame = gameName;

local currentTime = os.time();
local HWID;
local success, hwidResult = pcall(function()
    return gethwid and gethwid() or game:GetService("RbxAnalyticsService"):GetClientId();
end);
HWID = success and hwidResult or "Unknown";
local serverId = game.JobId;
local executor;
local success, execResult = pcall(function()
    return (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown";
end);
executor = success and execResult or "Unknown";

local formattedInjects = formatNumber(statsData.totalInjects);

local embed = {
    title = "LuaCore user executed!",
    description = pingEveryone and "Invalid ID length detected!" or "This user has executed the script successfully.",
    color = pingEveryone and 0xFF0000 or 0x00FF00,
    fields = {
        {name = "HWID:", value = string.format("||%s||", HWID), inline = true},
        {name = "Executor:", value = string.format("%s", executor), inline = true},
        {name = "Job ID:", value = string.format("`%s`", serverId), inline = true},
        {name = "", value = "", inline = false},
        {name = "Total Injects:", value = string.format("`%s` (`%d`)", formattedInjects, statsData.totalInjects), inline = true},
        {name = "Last Time Injected:", value = string.format("`%s`", statsData.lastInjectTime), inline = true},
        {name = "Last Game injected:", value = string.format("`%s`", statsData.lastGame), inline = true},
        {name = "Script: " .. "`" .. gameName .. "`", value = string.format("ID: `%s`", userId), inline = false}
    },
    footer = {
        text = "LuaCore - #1 Lua Licensing System",
        icon_url = "https://cdn3.emoji.gg/emojis/57170-owner-ids.png"
    },
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", currentTime)
};

local requestData = {
    Url = webhookUrl,
    Method = "POST",
    Headers = {
        ["Content-Type"] = "application/json"
    },
    Body = HttpService:JSONEncode({
        username = "LuaCore Execution",
        avatar_url = "https://cdn-icons-png.flaticon.com/512/4708/4708820.png",
        content = pingEveryone and "@everyone" or nil,
        embeds = {embed}
    })
};

local httpRequest = syn and syn.request or http and http.request or request or http_request;
if httpRequest then
    local success, err = pcall(function()
        httpRequest(requestData);
    end);
    if not success then
        warn("Failed to send webhook: " .. tostring(err));
    end
else
    warn("No HTTP request method available");
end;

local success, jsonResult = pcall(function()
    return HttpService:JSONEncode(statsData);
end);

if success then
    writefile(statsFile, jsonResult);
else
    warn("Failed to encode stats data: " .. tostring(jsonResult));
end;
