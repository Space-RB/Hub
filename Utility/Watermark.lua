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
]]

if not _G.WatermarkSettings then
    _G.WatermarkSettings = {}
end

local Settings = _G.WatermarkSettings

Settings.Enabled = Settings.Enabled ~= false
Settings.DisabledPlaceIds = Settings.DisabledPlaceIds or {}

Settings.Title = Settings.Title or "Space Hub"
Settings.Accent = Settings.Accent or "#BB66FF"

Settings.ShowFPS = Settings.ShowFPS ~= false
Settings.ShowPing = Settings.ShowPing ~= false
Settings.ShowRuntime = Settings.ShowRuntime ~= false

Settings.Position = Settings.Position or UDim2.new(1, -10, 0, 15)
Settings.Height = Settings.Height or 32
Settings.TextSize = Settings.TextSize or 16
Settings.CustomValues = Settings.CustomValues or {}

local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
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

    if self.Gui and self.Gui.Parent then
        self.Gui:Destroy()
    end

    self.Gui = nil
end

function Watermark:SetCustom(name, value)
    Settings.CustomValues[name] = value
end

function Watermark:Refresh()
    if not self.TextLabel or not self.Main then
        return
    end

    local parts = {}
    table.insert(parts, string.format('<font color="%s">%s</font>', Settings.Accent, Settings.Title))

    if Settings.ShowFPS then
        table.insert(parts, string.format("%d fps", self.FPS))
    end

    if Settings.ShowPing then
        table.insert(parts, string.format("%d ms", self.Ping))
    end

    if Settings.ShowRuntime then
        table.insert(parts, FormatTime(tick() - self.StartTime))
    end

    for name, value in pairs(Settings.CustomValues) do
        table.insert(parts, string.format("%s: %s", tostring(name), SafeCall(value)))
    end

    local finalText = table.concat(parts, " | ")
    self.TextLabel.Text = finalText

    local textSize = TextService:GetTextSize(
        self.TextLabel.ContentText,
        self.TextLabel.TextSize,
        self.TextLabel.Font,
        Vector2.new(math.huge, Settings.Height)
    )

    self.Main.Size = UDim2.new(0, textSize.X + 24, 0, Settings.Height)
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
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 10
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui
    self.Gui = ScreenGui

    local Main = Instance.new("Frame")
    Main.Name = RandomString()
    Main.AnchorPoint = Vector2.new(1, 0)
    Main.Position = Settings.Position
    Main.Size = UDim2.new(0, 220, 0, Settings.Height)
    Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    Main.BackgroundTransparency = 0.05
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui
    self.Main = Main

    local Corner = Instance.new("UICorner")
    Corner.Name = RandomString()
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Main

    local Stroke = Instance.new("UIStroke")
    Stroke.Name = RandomString()
    Stroke.Color = Color3.fromHex(Settings.Accent)
    Stroke.Thickness = 2
    Stroke.Transparency = 0.15
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Parent = Main

    local Padding = Instance.new("UIPadding")
    Padding.Name = RandomString()
    Padding.PaddingLeft = UDim.new(0, 10)
    Padding.PaddingRight = UDim.new(0, 12)
    Padding.PaddingTop = UDim.new(0, 5)
    Padding.PaddingBottom = UDim.new(0, 5)
    Padding.Parent = Main

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Name = RandomString()
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = ""
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Font = Enum.Font.GothamMedium
    TextLabel.TextSize = Settings.TextSize
    TextLabel.TextXAlignment = Enum.TextXAlignment.Right
    TextLabel.TextYAlignment = Enum.TextYAlignment.Center
    TextLabel.RichText = true
    TextLabel.Parent = Main
    self.TextLabel = TextLabel

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
    return self
end

if _G.WatermarkObject then
    _G.WatermarkObject:Destroy()
    _G.WatermarkObject = nil
end

_G.Watermark = CreateWatermark
_G.WatermarkObject = CreateWatermark()
