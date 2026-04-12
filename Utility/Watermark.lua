--[[ Example to create
_G.WatermarkSettings = {
    Enabled = true,
    DisabledPlaceIds = {123, 456, 789},
    Title = "Space Hub",
    Accent = "#BB66FF",
    ShowFPS = true,
    ShowPing = true,
    ShowRuntime = true,
    CustomValues = {
        ["Balls"] = function()
            return "x"
        end,
        ["Coins"] = function()
            return math.random(1, 999)
        end
    }
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/Space-RB/Hub/refs/heads/main/Utility/Watermark.lua"))()
_G.WatermarkObject:Refresh()
_G.WatermarkObject:SetCustom("Level", 25)
_G.WatermarkObject:SetCustom("Mode", "Auto Farm")
_G.WatermarkObject:SetCustom("User", function()
    return game.Players.LocalPlayer.Name
end)
local coins = 0
_G.WatermarkObject:SetCustom("Coins", function()
    return coins
end)
coins = coins + 10
]]

_G.WatermarkSettings = {
    Enabled = true,
    DisabledPlaceIds = {123, 456, 789},
    Title = "Space Hub",
    Accent = "#BB66FF",
    ShowFPS = true,
    ShowPing = true,
    ShowRuntime = true,
    CustomValues = {}
}

if not _G.WatermarkSettings then
    _G.WatermarkSettings = {}
end

local Settings = _G.WatermarkSettings

Settings.Enabled = Settings.Enabled ~= false
Settings.DisabledPlaceIds = Settings.DisabledPlaceIds or {}

Settings.Title = Settings.Title or "Space Hub"
Settings.Accent = Settings.Accent or "#BB66FF"
Settings.SecondAccent = Settings.SecondAccent or "#7A5CFF"

Settings.ShowFPS = Settings.ShowFPS ~= false
Settings.ShowPing = Settings.ShowPing ~= false
Settings.ShowRuntime = Settings.ShowRuntime ~= false

Settings.Position = Settings.Position or UDim2.new(1, -5, 0, -5)
Settings.Height = Settings.Height or 34
Settings.TextSize = Settings.TextSize or 14
Settings.CustomValues = Settings.CustomValues or {}

local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local function RandomString(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local out = ""
    for i = 1, len or 12 do
        local r = math.random(1, #chars)
        out = out .. chars:sub(r, r)
    end
    return out
end

local function IsDisabledPlace()
    return table.find(Settings.DisabledPlaceIds, game.PlaceId) ~= nil
end

local function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)

    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, secs)
    elseif minutes > 0 then
        return string.format("%d:%02d", minutes, secs)
    else
        return tostring(secs)
    end
end

local function SafeCall(value)
    if typeof(value) == "function" then
        local ok, result = pcall(value)
        if ok then
            return tostring(result)
        end
        return "error"
    end
    if value == nil then
        return nil
    end
    return tostring(value)
end

local Watermark = {}
Watermark.__index = Watermark

function Watermark:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end

    if self.FPSConnection then
        self.FPSConnection:Disconnect()
        self.FPSConnection = nil
    end

    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end
end

function Watermark:SetCustom(name, value)
    if value == nil then
        Settings.CustomValues[name] = nil
    else
        Settings.CustomValues[name] = value
    end
    self:Refresh()
end

function Watermark:Refresh()
    if not self.TextLabel or not self.Main then
        return
    end

    local parts = {}
    table.insert(parts, string.format('<font color="%s">%s</font>', Settings.Accent, Settings.Title))

    if Settings.ShowFPS then
        table.insert(parts, string.format("fps: %d", self.FPS))
    end

    if Settings.ShowPing then
        table.insert(parts, string.format("ping: %d", self.Ping))
    end

    if Settings.ShowRuntime then
        table.insert(parts, string.format("%s", FormatTime(tick() - self.StartTime)))
    end

    for name, value in pairs(Settings.CustomValues) do
        local result = SafeCall(value)
        if result ~= nil then
            table.insert(parts, string.format('%s: <font color="%s">%s</font>', tostring(name), Settings.Accent, result))
        end
    end

    local finalText = table.concat(parts, "   |   ")
    self.TextLabel.Text = finalText

    local textSize = TextService:GetTextSize(
        self.TextLabel.ContentText,
        self.TextLabel.TextSize,
        self.TextLabel.Font,
        Vector2.new(math.huge, Settings.Height)
    )

    local targetWidth = textSize.X + 28
    self.Main.Size = UDim2.new(0, targetWidth, 0, Settings.Height)
    self.Glow.Size = UDim2.new(0, targetWidth + 12, 0, Settings.Height + 10)
end

local function CreateWatermark()
    if not Settings.Enabled then
        return nil
    end

    if IsDisabledPlace() then
        return nil
    end

    local old = CoreGui:FindFirstChild("WatermarkGui")
    if old then
        old:Destroy()
    end

    local self = setmetatable({}, Watermark)
    self.StartTime = tick()
    self.FPS = 0
    self.Ping = 0
    self.FrameCounter = 0
    self.LastFPSUpdate = tick()
    self.LastPingUpdate = 0

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WatermarkGui"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 50
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Gui = ScreenGui

    local Holder = Instance.new("Frame")
    Holder.Name = RandomString()
    Holder.BackgroundTransparency = 1
    Holder.AnchorPoint = Vector2.new(1, 0)
    Holder.Position = Settings.Position
    Holder.Size = UDim2.new(0, 220, 0, Settings.Height + 10)
    Holder.Parent = ScreenGui
    self.Holder = Holder

    local Glow = Instance.new("Frame")
    Glow.Name = RandomString()
    Glow.AnchorPoint = Vector2.new(1, 0)
    Glow.Position = UDim2.new(1, 6, 0, 2)
    Glow.Size = UDim2.new(0, 232, 0, Settings.Height + 10)
    Glow.BackgroundColor3 = Color3.fromHex(Settings.Accent)
    Glow.BackgroundTransparency = 0.86
    Glow.BorderSizePixel = 0
    Glow.Parent = Holder
    self.Glow = Glow

    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(0, 12)
    GlowCorner.Parent = Glow

    local Main = Instance.new("Frame")
    Main.Name = RandomString()
    Main.AnchorPoint = Vector2.new(1, 0)
    Main.Position = UDim2.new(1, 0, 0, 5)
    Main.Size = UDim2.new(0, 220, 0, Settings.Height)
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    Main.BackgroundTransparency = 0.08
    Main.BorderSizePixel = 0
    Main.Parent = Holder
    self.Main = Main

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = Main

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromHex(Settings.Accent)
    Stroke.Thickness = 1.4
    Stroke.Transparency = 0.35
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Parent = Main

    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 28)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 22, 38))
    })
    Gradient.Rotation = 0
    Gradient.Parent = Main

    local TopBar = Instance.new("Frame")
    TopBar.Name = RandomString()
    TopBar.BackgroundColor3 = Color3.fromHex(Settings.Accent)
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 2)
    TopBar.Parent = Main

    local TopBarGradient = Instance.new("UIGradient")
    TopBarGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex(Settings.Accent)),
        ColorSequenceKeypoint.new(1, Color3.fromHex(Settings.SecondAccent))
    })
    TopBarGradient.Parent = TopBar

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 10)
    TopBarCorner.Parent = TopBar

    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 10)
    Padding.PaddingRight = UDim.new(0, 10)
    Padding.PaddingTop = UDim.new(0, 5)
    Padding.PaddingBottom = UDim.new(0, 5)
    Padding.Parent = Main

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Name = RandomString()
    TextLabel.BackgroundTransparency = 1
    TextLabel.Size = UDim2.new(1, 0, 1, -1)
    TextLabel.Position = UDim2.new(0, 0, 0, 1)
    TextLabel.Font = Enum.Font.GothamSemibold
    TextLabel.TextSize = Settings.TextSize
    TextLabel.TextXAlignment = Enum.TextXAlignment.Right
    TextLabel.TextYAlignment = Enum.TextYAlignment.Center
    TextLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
    TextLabel.RichText = true
    TextLabel.TextTransparency = 1
    TextLabel.BackgroundTransparency = 1
    TextLabel.Parent = Main
    self.TextLabel = TextLabel

    Main.BackgroundTransparency = 1
    Glow.BackgroundTransparency = 1
    Stroke.Transparency = 1
    TopBar.BackgroundTransparency = 1

    self.FPSConnection = RunService.RenderStepped:Connect(function()
        self.FrameCounter += 1
        local now = tick()

        if now - self.LastFPSUpdate >= 1 then
            self.FPS = self.FrameCounter
            self.FrameCounter = 0
            self.LastFPSUpdate = now
        end
    end)

    self.Connection = RunService.Heartbeat:Connect(function()
        local now = tick()

        if now - self.LastPingUpdate >= 1 then
            self.Ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
            self.LastPingUpdate = now
        end

        self:Refresh()
    end)

    self:Refresh()

    TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.08
    }):Play()

    TweenService:Create(Glow, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.86
    }):Play()

    TweenService:Create(Stroke, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 0.35
    }):Play()

    TweenService:Create(TopBar, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    }):Play()

    TweenService:Create(TextLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()

    return self
end

if _G.WatermarkObject then
    _G.WatermarkObject:Destroy()
    _G.WatermarkObject = nil
end

_G.Watermark = CreateWatermark
_G.WatermarkObject = CreateWatermark()
