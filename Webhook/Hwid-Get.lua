local webhookUrl = "https://discord.com/api/webhooks/1492822012639580200/p3e8fKiQ1Zgpbvq3QeCTFeIsRnL23p7_uTnCQJynwUQcBc1NLZbVZzrjACm1_kBtOOtK"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local currentTime = os.time()
local player = Players.LocalPlayer

local HWID = "Not Available"
pcall(function()
    HWID = gethwid() or "Not Available"
    setclipboard(HWID)
end)

local HardWare = "Not Available"
pcall(function()
    HardWare = game:GetService("RbxAnalyticsService"):GetClientId()
end)

local executor = "Unknown"
pcall(function()
    executor = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"
end)

local embed = {
    title = "LuaCore | Hwid copier!",
    description = "This user has executed the script successfully.",
    color = 0x00FF00,
    fields = {
        {name = "Executor:", value = string.format("%s", executor), inline = true},
        {name = "Player:", value = player.Name, inline = true},
        {name = "", value = "", inline = false},
        {name = "HWID:", value = string.format("||%s||", HWID), inline = true},
        {name = "HardWare:", value = string.format("||%s||", HardWare), inline = true},
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
        embeds = {embed}
    })
}

local httpRequest = syn and syn.request or http and http.request or request or http_request
if httpRequest then
    pcall(function()
        httpRequest(requestData)
    end)
end

pcall(function()
    player:Kick("HWID copied\nSend it as a reply to the bot")
end)
