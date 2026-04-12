local VU = game:GetService("VirtualUser");
local LP = game:GetService("Players").LocalPlayer;

_G.log = _G.log or function(t,m) (t=="warn" and warn or print)("[Space Hub]: "..tostring(m)); end;

LP.Idled:Connect(function();
    VU:CaptureController();
    VU:ClickButton2(Vector2.new(0,0));
    _G.log("print","Anti-AFK prevented kick :D");
    if _G.Settings.Debug == true and _G.NotificationLib and _G.NotificationLib.Notify then
        pcall(function(); _G.Notify("Info","Anti AFK","Enabled",3); end);
    end;
end);

_G.log("print","Anti-AFK Enabled");
