local VU = game:GetService("VirtualUser")
local LP = game:GetService("Players").LocalPlayer

_G.log = _G.log or function(t,m) 
    if t == "warn" then
        warn("[Space Hub]: "..tostring(m))
    else
        print("[Space Hub]: "..tostring(m))
    end
end

LP.Idled:Connect(function()
    VU:CaptureController()
    VU:ClickButton2(Vector2.new(0,0))
    _G.log("print","Anti-AFK prevented kick :D")
    if _G.Settings and _G.Settings.Debug == true and _G.Notify then
        pcall(function() 
            _G.Notify("Info","Anti AFK","Anti-AFK is active!",3) 
        end)
    end
end)

_G.log("print","Anti-AFK Enabled")
