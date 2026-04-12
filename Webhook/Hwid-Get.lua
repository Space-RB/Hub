local webhookUrl = "https://discord.com/api/webhooks/1492794887991591015/dTZkhdRL8Zk0xrWtPOS3kQTymGiJqoq64yInSc3n48CDxfmkC4T4tUaa-EvQhw7xzAT9"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local currentTime = os.time()
local player = Players.LocalPlayer
pcall(function()
    local HWID = gethwid()
    setclipboard(HWID)
end)
local HardWare = game:GetService("RbxAnalyticsService"):GetClientId()
local executor = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"

local embed = {
    title = "LuaCore | Hwid copier!",
    description = "This user has executed the script successfully.",
    color = 0x00FF00,
    fields = {
        {name = "HWID:", value = string.format("||%s||", HWID), inline = true},
        {name = "HardWare:", value = string.format("||%s||", HardWare), inline = true},
        {name = "Executor:", value = string.format("%s", executor), inline = false},
    },
    footer = {
        text = "LuaCore - #1 Lua Licensing System",
        icon_url = "https://cdn3.emoji.gg/emojis/57170-owner-ids.png"
    },
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", currentTime)
}

local requestData = {
    Url = webhookUrl,
    Method = "POST",
    Headers = {
        ["Content-Type"] = "application/json"
    },
    Body = HttpService:JSONEncode({
        username = "LuaCore Execution",
        avatar_url = "https://tenor.com/view/milana-milana-star-star-eiffel-tower-tower-gif-10792295651488081671",
        embeds = {embed}
    })
}

local httpRequest = syn and syn.request or http and http.request or request or http_request
if httpRequest then
    pcall(httpRequest, requestData)
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local HWID = pcall(function() return gethwid() or "Not Available" end) and gethwid() or "Not Available"
local executor = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"

pcall(function() setclipboard(HWID) end)

local embed = {
    title = "LuaCore | Hwid copier!",
    description = "This user has executed the script successfully.",
    color = 0x00FF00,
    fields = {
        {name = "HWID:", value = string.format("||%s||", HWID), inline = true},
        {name = "Executor:", value = executor, inline = true},
        {name = "Player:", value = player.Name, inline = true}
    },
    footer = {text = "LuaCore - #1 Lua Licensing System"},
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
}

local request = {
    Url = "",
    Method = "POST",
    Headers = {["Content-Type"] = "application/json"},
    Body = HttpService:JSONEncode({embeds = {embed}})
}

local httpRequest = syn and syn.request or http and http.request or request
if httpRequest then pcall(httpRequest, request) end

player:Kick("HWID copied\nSend it as a reply to the bot")
