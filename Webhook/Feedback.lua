_G.Feedback = loadstring(game:HttpGet("https://your-link/Feedback.lua"))()

--[[
_G.Feedback("Free", "Hello, this is my feedback")
_G.Feedback("Premium", "Bug in autofarm")
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1445752405156298792/9j3uii_sWHphuiEuzPR84z20LUjO6jxqDa3m1IBRs1gjZBOoezm4FIkdRb5Ohh4JCy2C"

local function requestWebhook(url, body)
    if syn and syn.request then
        return syn.request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })
    elseif http_request then
        return http_request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })
    elseif request then
        return request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })
    elseif fluxus and fluxus.request then
        return fluxus.request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })
    else
        HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
        return {Success = true, StatusCode = 204}
    end
end

local function getGameName(placeId)
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(placeId)
    end)

    if ok and info and info.Name then
        return info.Name
    end

    return "Unknown"
end

local function generateFeedbackId()
    return string.format("FB-%d-%d", os.time(), math.random(100000, 999999))
end

return function(status, text)
    status = tostring(status or "Free")
    text = tostring(text or "")

    if text == "" then
        return false, "Text is empty"
    end

    local player = Players.LocalPlayer
    local playerName = player and player.Name or "Unknown"
    local userId = player and tostring(player.UserId) or "Unknown"

    local placeId = game.PlaceId
    local jobId = game.JobId
    local gameName = getGameName(placeId)
    local feedbackId = generateFeedbackId()

    local data = {
        embeds = {{
            title = "🚀 Space Hub Feedback #" .. feedbackId,
            description = text,
            color = 5793266,
            fields = {
                {
                    name = "👤 User",
                    value = "`" .. playerName .. "`\n (" .. userId .. ")",
                    inline = true
                },
                {
                    name = "Status",
                    value = "`" .. status .. "`",
                    inline = true
                },
                {
                    name = "",
                    value = "",
                    inline = false
                },
                {
                    name = "🎮 Game",
                    value = "`" .. gameName .. "`",
                    inline = true
                },
                {
                    name = "📍 Place",
                    value = "`" .. tostring(placeId) .. "`",
                    inline = true
                }
            },
            footer = {
                text = "Space Hub - Feedback System"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    local body = HttpService:JSONEncode(data)

    local ok, response = pcall(function()
        return requestWebhook(WEBHOOK_URL, body)
    end)

    if not ok then
        return false, response
    end

    if type(response) == "table" then
        if response.Success == true then
            return true, feedbackId
        end

        local code = tonumber(response.StatusCode)
        if code == 200 or code == 204 then
            return true, feedbackId
        end
    end

    return false, response
end
