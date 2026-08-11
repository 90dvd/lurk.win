--[[
    lurk.win - BedWars
    Inject:
      loadstring(game:HttpGet("https://raw.githubusercontent.com/90dvd/lurk.win/refs/heads/main/bedwars.lua"))()
]]

-- Matcha notes:
-- - HttpGet never throws; 404/empty come back as body/"".
-- - loadstring drops chunk returns; INS-ui publishes global INSui.
-- - syntax errors from loadstring print on call and are not catchable -> only exec clean sources once.
local function envGet(key)
    local v
    pcall(function() v = getgenv()[key] end)
    if v ~= nil then return v end
    pcall(function() v = _G[key] end)
    return v
end

local function envSet(key, value)
    pcall(function() getgenv()[key] = value end)
    pcall(function() _G[key] = value end)
end

local function fetch(url)
    -- plain HttpGet only (MatchaScripts / INS-ui style). No headers table.
    local body = game:HttpGet(url)
    if type(body) ~= "string" or #body < 64 then
        return nil
    end
    -- strip UTF-8 BOM if present
    if string.byte(body, 1) == 0xEF and string.byte(body, 2) == 0xBB and string.byte(body, 3) == 0xBF then
        body = string.sub(body, 4)
    end
    local b1 = string.byte(body, 1)
    if not b1 or b1 < 32 or b1 == 127 then
        return nil
    end
    if string.sub(body, 1, 3) == "404" or string.sub(body, 1, 1) == "<" then
        return nil
    end
    -- must look like the real INS-ui payload
    if not string.find(body, "INSui", 1, true) then
        return nil
    end
    if string.sub(body, 1, 5) ~= "local" and string.sub(body, 1, 2) ~= "--" then
        return nil
    end
    return body
end

local function loadInsUi()
    local existing = envGet("INSui")
    if existing then
        return existing
    end

    local src = fetch("https://raw.githubusercontent.com/90dvd/lurk.win/refs/heads/main/lib/uilib.min.lua")
    if not src then
        src = fetch("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/refs/heads/main/uilib.min.lua")
    end
    if not src then
        return nil
    end

    local fn = loadstring(src, "INSui")
    if type(fn) == "function" then
        pcall(fn)
    end
    return envGet("INSui")
end

local Lib = loadInsUi()
if not Lib then
    error("[lurk.win] INS-ui failed to load")
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local CFG = envGet("Lurk")
if type(CFG) ~= "table" then
    CFG = {}
    envSet("Lurk", CFG)
end
CFG.BedWars = CFG.BedWars or {}
local BW = CFG.BedWars

local function def(tbl, key, value)
    if tbl[key] == nil then tbl[key] = value end
end

def(BW, "KillAura", false)
def(BW, "KillAuraRange", 18)
def(BW, "KillAuraKey", "q")
def(BW, "AimAssist", false)
def(BW, "AimFov", 120)
def(BW, "AimSmooth", 0.35)
def(BW, "AimPart", "Head")
def(BW, "AimReaction", 120)
def(BW, "StickyTarget", true)
def(BW, "TeamCheck", true)
def(BW, "WallCheck", true)
def(BW, "VisibleOnly", false)
def(BW, "AimDistLo", 0)
def(BW, "AimDistHi", 150)
def(BW, "Triggerbot", false)
def(BW, "TriggerDelay", 80)
def(BW, "TriggerChance", 100)
def(BW, "TriggerScoped", false)
def(BW, "NoRecoil", false)
def(BW, "NoSpread", false)
def(BW, "FireRate", 1.0)
def(BW, "FastReload", false)
def(BW, "InfAmmo", false)
def(BW, "AutoBlock", false)
def(BW, "AutoBuy", false)
def(BW, "EspEnabled", true)
def(BW, "EspBoxes", true)
def(BW, "EspBoxStyle", "Corner")
def(BW, "EspNames", true)
def(BW, "EspDistance", true)
def(BW, "EspHealth", true)
def(BW, "EspWeapon", false)
def(BW, "EspTextSize", 13)
def(BW, "EspBeds", true)
def(BW, "EspColor", Color3.fromRGB(122, 134, 255))
def(BW, "EspFill", Color3.fromRGB(122, 134, 255))
def(BW, "EspFillAlpha", 0.35)
def(BW, "EspMaxDist", 300)
def(BW, "EspTeamCheck", true)
def(BW, "Chams", false)
def(BW, "ChamsMaterial", "ForceField")
def(BW, "ChamsAlpha", 0.3)
def(BW, "Fullbright", false)
def(BW, "TimeOfDay", 14)
def(BW, "NoFog", false)
def(BW, "NoShadows", false)
def(BW, "Watermark", true)
def(BW, "FpsCounter", false)
def(BW, "HighlightFriends", true)
def(BW, "HighlightEnemies", false)
def(BW, "SortBy", "Distance")
def(BW, "ListRows", 10)
def(BW, "AutoRefresh", true)
def(BW, "TrackNearest", false)
def(BW, "OffscreenArrows", true)
def(BW, "UpdateRate", 30)
def(BW, "IgnoreTeammates", true)
def(BW, "LevelLo", 1)
def(BW, "LevelHi", 50)
def(BW, "Brightness", 2)
def(BW, "Wireframe", false)
def(BW, "RemoveGrass", false)
def(BW, "Skybox", "Default")
def(BW, "Weather", "Clear")
def(BW, "Wind", 0)
def(BW, "FreezeTime", false)
def(BW, "SpeedEnabled", false)
def(BW, "WalkSpeed", 16)
def(BW, "JumpPower", 50)
def(BW, "FlyEnabled", false)
def(BW, "FlySpeed", 60)
def(BW, "InfJump", false)
def(BW, "BunnyHop", false)
def(BW, "NoFall", false)
def(BW, "AntiAfk", true)
def(BW, "AutoRejoin", false)

-- Window options aligned with INS-ui showcase (lurk.win branding kept)
local win = Lib:CreateWindow({
    title         = "lurk.win",
    subtitle      = "BedWars",
    size          = Vector2.new(700, 520),
    menuKey       = "p",
    configName    = "default",
    configFolder  = "lurk_bedwars",
    smartFps      = false,
    checkboxStyle = true,
    opacity       = 98,
    logo          = "https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/assets/logo.png",
    autoSave      = true,
    startOpen     = true,
    keybindOverlay = true,
})

win:AddSettingsTab("gear")
Lib:Notify("lurk.win", "Press P to toggle the menu", 4, "info")

--------------------------------------------------------------------------
-- COMBAT (showcase layout + BedWars Kill Aura)
--------------------------------------------------------------------------
Lib:Category("COMBAT")
local combat = win:Tab("Combat", "sword")

local aim = combat:Section("Aimbot", "Left", "silent + legit aim assist")
local aimOn = aim:Toggle("Enabled", BW.AimAssist, function(on)
    BW.AimAssist = on
    Lib:Notify("Aimbot", on and "enabled" or "disabled", 2, on and "success" or "warning")
end)
aimOn:AddKeybind("e", "Hold")
aimOn:AddColorpicker("FOV color", Color3.fromRGB(120, 255, 140))

aim:Divider("Targeting")
aim:Dropdown("Target part", {BW.AimPart}, {"Head", "Torso", "Neck", "Random"}, false, function(v)
    BW.AimPart = v[1] or "Head"
end)
aim:Dropdown("Hitboxes", {"Head"}, {"Head", "Torso", "Neck", "Stomach", "Legs"}, true, function(v) end, "multi-select", true)
aim:Slider("FOV", BW.AimFov, 1, 10, 500, "px", function(v) BW.AimFov = v end)
aim:Toggle("Sticky target", BW.StickyTarget, function(on) BW.StickyTarget = on end, "keep the same target while it stays in FOV")

aim:Divider("Smoothing")
aim:Slider("Smoothness", BW.AimSmooth, 0.01, 0, 1, "", function(v) BW.AimSmooth = v end)
aim:Slider("Reaction time", BW.AimReaction, 5, 0, 400, "ms", function(v) BW.AimReaction = v end)

aim:Divider("Safety")
local wall = aim:Toggle("Wall check", BW.WallCheck, function(on) BW.WallCheck = on end)
aim:Toggle("Visible only", BW.VisibleOnly, function(on) BW.VisibleOnly = on end):DependsOn(wall)
aim:RangeSlider("Distance", BW.AimDistLo, BW.AimDistHi, 1, 0, 500, "m", function(lo, hi)
    BW.AimDistLo, BW.AimDistHi = lo, hi
end)

local trig = combat:Section("Triggerbot", "Right")
trig:Toggle("Enabled", BW.Triggerbot, function(on) BW.Triggerbot = on end):AddKeybind("t", "Toggle")

trig:Divider("Timing")
trig:Slider("Delay", BW.TriggerDelay, 1, 0, 500, "ms", function(v) BW.TriggerDelay = v end)
trig:Slider("Hit chance", BW.TriggerChance, 1, 1, 100, "%", function(v) BW.TriggerChance = v end)

trig:Divider("Filters")
trig:Toggle("Team check", BW.TeamCheck, function(on) BW.TeamCheck = on end)
trig:Toggle("Wall check", BW.WallCheck, function(on) BW.WallCheck = on end)
trig:Toggle("Scoped only", BW.TriggerScoped, function(on) BW.TriggerScoped = on end, "fire only while aiming down sights")

local wep = combat:Section("Weapon", "Right")
wep:Toggle("No recoil", BW.NoRecoil, function(on) BW.NoRecoil = on end)
wep:Toggle("No spread", BW.NoSpread, function(on) BW.NoSpread = on end)
wep:Slider("Fire rate", BW.FireRate, 0.1, 0.5, 3, "x", function(v) BW.FireRate = v end)

wep:Divider("Ammo")
wep:Toggle("Fast reload", BW.FastReload, function(on) BW.FastReload = on end)
wep:Toggle("Infinite ammo", BW.InfAmmo, function(on) BW.InfAmmo = on end):SetRisk():Tooltip("server-sided games will flag this")

local ka = combat:Section("Kill Aura", "Left", "BedWars melee aura")
local kaToggle = ka:Toggle("Enabled", BW.KillAura, function(on)
    BW.KillAura = on
    Lib:Notify("Kill Aura", on and "on" or "off", 1.5, on and "success" or "warning")
end)
kaToggle:AddKeybind(BW.KillAuraKey or "q", "Toggle")
ka:Slider("Range", BW.KillAuraRange, 1, 5, 30, "studs", function(v) BW.KillAuraRange = v end)
ka:Toggle("Auto block", BW.AutoBlock, function(on) BW.AutoBlock = on end)
ka:Toggle("Auto buy wool", BW.AutoBuy, function(on) BW.AutoBuy = on end)

--------------------------------------------------------------------------
-- VISUALS
--------------------------------------------------------------------------
Lib:Category("VISUALS")
local vis = win:Tab("Visuals", "eye")

local esp = vis:Section("Player ESP", "Left", "see players through walls")
esp:Toggle("Enabled", BW.EspEnabled, function(on) BW.EspEnabled = on end):AddKeybind("h", "Toggle")

esp:Divider("Boxes")
esp:Dropdown("Box style", {BW.EspBoxStyle}, {"2D", "Corner", "3D", "Off"}, false, function(v)
    BW.EspBoxStyle = v[1] or "Corner"
    BW.EspBoxes = BW.EspBoxStyle ~= "Off"
end)
esp:Colorpicker("Box color", BW.EspColor, function(c) BW.EspColor = c end, 1)
esp:Colorpicker("Fill color", BW.EspFill, function(c, a)
    BW.EspFill = c
    BW.EspFillAlpha = a
end, BW.EspFillAlpha)

esp:Divider("Info")
esp:Toggle("Name", BW.EspNames, function(on) BW.EspNames = on end)
esp:Toggle("Distance", BW.EspDistance, function(on) BW.EspDistance = on end)
esp:Toggle("Health bar", BW.EspHealth, function(on) BW.EspHealth = on end)
esp:Toggle("Weapon", BW.EspWeapon, function(on) BW.EspWeapon = on end)
esp:Slider("Text size", BW.EspTextSize, 1, 8, 24, "px", function(v) BW.EspTextSize = v end)

esp:Divider("Filters")
esp:RangeSlider("Render distance", 0, BW.EspMaxDist, 5, 0, 1000, "m", function(_, hi)
    BW.EspMaxDist = hi
end)
esp:Toggle("Team check", BW.EspTeamCheck, function(on) BW.EspTeamCheck = on end)

local hud = vis:Section("Overlay", "Left")
hud:Label(function() return "Local time: " .. os.date("%X") end)
hud:Toggle("Watermark", BW.Watermark, function(on) BW.Watermark = on end)
hud:Toggle("FPS counter", BW.FpsCounter, function(on) BW.FpsCounter = on end)
hud:Info("overlay drawings stay when the menu is closed")

local ch = vis:Section("Chams", "Right")
ch:Toggle("Enabled", BW.Chams, function(on) BW.Chams = on end)
ch:Dropdown("Material", {BW.ChamsMaterial}, {"ForceField", "Neon", "Flat"}, false, function(v)
    BW.ChamsMaterial = v[1] or "ForceField"
end)
ch:Colorpicker("Visible color", Color3.fromRGB(140, 255, 160))
ch:Colorpicker("Hidden color", Color3.fromRGB(255, 120, 120))
ch:Slider("Transparency", BW.ChamsAlpha, 0.05, 0, 1, "", function(v) BW.ChamsAlpha = v end)

local worldVis = vis:Section("World", "Right")
worldVis:Toggle("Fullbright", BW.Fullbright, function(on) BW.Fullbright = on end)
worldVis:Slider("Time of day", BW.TimeOfDay, 0.1, 0, 24, "h", function(v) BW.TimeOfDay = v end)
worldVis:Toggle("No fog", BW.NoFog, function(on) BW.NoFog = on end)
worldVis:Colorpicker("Ambient", Color3.fromRGB(255, 255, 255), function(c) end)

worldVis:Divider("Extras")
worldVis:Dropdown("Weather", {BW.Weather}, {"Clear", "Rain", "Snow"}, false, function(v)
    BW.Weather = v[1] or "Clear"
end)
worldVis:Toggle("No shadows", BW.NoShadows, function(on) BW.NoShadows = on end)

local beds = vis:Section("Beds", "Right", "BedWars bed markers")
beds:Toggle("Bed ESP", BW.EspBeds, function(on) BW.EspBeds = on end)
beds:Colorpicker("Bed color", Color3.fromRGB(255, 120, 140), function() end, 1)
beds:Info("Bed markers use Drawing - stay visible while the menu is closed.")

--------------------------------------------------------------------------
-- SYSTEM: World tab with Players + Environment subs (was missing)
--------------------------------------------------------------------------
Lib:Category("SYSTEM")
local world = win:Tab("World", "globe")

local wPlayers = world:Sub("Players", "users")
local plist = wPlayers:Section("Player list", "Left", "everyone in the server")
plist:Toggle("Highlight friends", BW.HighlightFriends, function(on) BW.HighlightFriends = on end)
plist:Toggle("Highlight enemies", BW.HighlightEnemies, function(on) BW.HighlightEnemies = on end)
plist:Dropdown("Sort by", {BW.SortBy}, {"Distance", "Name", "Team", "Health"}, false, function(v)
    BW.SortBy = v[1] or "Distance"
end)
plist:Slider("List rows", BW.ListRows, 1, 3, 30, "", function(v) BW.ListRows = v end)
plist:Divider("Actions")
plist:Button("Refresh list", function() Lib:Notify("Players", "list refreshed", 1) end)
    :AddButton("Copy IDs", function()
        local ids = {}
        for _, p in ipairs(Players:GetPlayers()) do
            ids[#ids + 1] = tostring(p.UserId)
        end
        pcall(function() setclipboard(table.concat(ids, ",")) end)
        Lib:Notify("Players", "copied", 1)
    end)
plist:Toggle("Auto refresh", BW.AutoRefresh, function(on) BW.AutoRefresh = on end, "repopulate as players join or leave")

local ptrack = wPlayers:Section("Tracking", "Right")
ptrack:Toggle("Track nearest", BW.TrackNearest, function(on) BW.TrackNearest = on end):AddKeybind("y", "Toggle")
ptrack:Toggle("Off-screen arrows", BW.OffscreenArrows, function(on) BW.OffscreenArrows = on end)
ptrack:Colorpicker("Friend color", Color3.fromRGB(120, 255, 140))
ptrack:Colorpicker("Enemy color", Color3.fromRGB(255, 110, 110))
ptrack:Slider("Update rate", BW.UpdateRate, 1, 5, 60, "hz", function(v) BW.UpdateRate = v end)
ptrack:Divider("Filters")
ptrack:Toggle("Ignore teammates", BW.IgnoreTeammates, function(on) BW.IgnoreTeammates = on end)
ptrack:RangeSlider("Level range", BW.LevelLo, BW.LevelHi, 1, 1, 100, "", function(lo, hi)
    BW.LevelLo, BW.LevelHi = lo, hi
end)

local wEnv = world:Sub("Environment", "sun")
local wl = wEnv:Section("Lighting", "Left", "time, brightness, fog")
wl:Toggle("Fullbright", BW.Fullbright, function(on) BW.Fullbright = on end)
wl:Slider("Brightness", BW.Brightness, 0.1, 0, 10, "", function(v) BW.Brightness = v end)
wl:Slider("Time of day", BW.TimeOfDay, 0.1, 0, 24, "h", function(v) BW.TimeOfDay = v end)
wl:Toggle("No fog", BW.NoFog, function(on) BW.NoFog = on end)
wl:Toggle("No shadows", BW.NoShadows, function(on) BW.NoShadows = on end)
wl:Colorpicker("Ambient", Color3.fromRGB(255, 255, 255), function(c) end)

local wt = wEnv:Section("Terrain", "Right")
wt:Toggle("Wireframe", BW.Wireframe, function(on) BW.Wireframe = on end)
wt:Toggle("Remove grass", BW.RemoveGrass, function(on) BW.RemoveGrass = on end)
wt:Dropdown("Skybox", {BW.Skybox}, {"Default", "Night", "Space", "Sunset"}, false, function(v)
    BW.Skybox = v[1] or "Default"
end)
wt:Divider("Weather")
wt:Dropdown("Weather", {BW.Weather}, {"Clear", "Rain", "Snow", "Storm"}, false, function(v)
    BW.Weather = v[1] or "Clear"
end)
wt:Slider("Wind", BW.Wind, 1, 0, 100, "%", function(v) BW.Wind = v end)
wt:Toggle("Freeze time", BW.FreezeTime, function(on) BW.FreezeTime = on end)

--------------------------------------------------------------------------
-- Misc (showcase: movement + server lived here, not under PLAYER)
--------------------------------------------------------------------------
local misc = win:Tab("Misc", "three-dots-horizontal")

local mv = misc:Section("Movement", "Left")
mv:Toggle("Speed", BW.SpeedEnabled, function(on) BW.SpeedEnabled = on end)
mv:Slider("Walk speed", BW.WalkSpeed, 1, 16, 250, "", function(v) BW.WalkSpeed = v end)
mv:Slider("Jump power", BW.JumpPower, 1, 50, 300, "", function(v) BW.JumpPower = v end)

mv:Divider("Air")
local fly = mv:Toggle("Fly", BW.FlyEnabled, function(on) BW.FlyEnabled = on end)
fly:AddKeybind("g", "Toggle", function(on)
    BW.FlyEnabled = on
    Lib:Notify("Fly", on and "on" or "off", 1)
end)
mv:Slider("Fly speed", BW.FlySpeed, 5, 10, 300, "", function(v) BW.FlySpeed = v end):DependsOn(fly)
mv:Toggle("Infinite jump", BW.InfJump, function(on) BW.InfJump = on end)

mv:Divider("Ground")
mv:Toggle("Bunny hop", BW.BunnyHop, function(on) BW.BunnyHop = on end)
mv:Toggle("No fall damage", BW.NoFall, function(on) BW.NoFall = on end)
mv:Keybind("Panic key", "k", function(key)
    Lib:Notify("Panic", "rebound to " .. tostring(key), 2)
end)

local srv = misc:Section("Server", "Right")
srv:Label(function() return "Players online: " .. #Players:GetPlayers() end)
srv:Button("Rejoin", function()
    Lib:Notify("Server", "rejoining...", 2)
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end)
end):AddButton("Server hop", function()
    Lib:Notify("Server", "hopping...", 2)
end)

srv:Dropdown("Teleport to", {}, function()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        names[#names + 1] = tostring(p.Name)
    end
    return names
end, false, function(v)
    local name = v[1]
    if not name then return end
    local target = Players:FindFirstChild(name)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
        Lib:Notify("Teleport", "to " .. name, 2, "success")
    end
end, "auto-refreshes: new players appear without reloading", true)

srv:Divider("Automation")
srv:Toggle("Anti afk", BW.AntiAfk, function(on) BW.AntiAfk = on end)
srv:Toggle("Auto rejoin", BW.AutoRejoin, function(on) BW.AutoRejoin = on end, "rejoin the same server after a kick")

srv:Divider("Danger zone")
srv:Button("Unload menu", function()
    Lib:Dialog({
        title     = "Unload?",
        text      = "Remove lurk.win BedWars from this session?",
        confirm   = "Unload",
        onConfirm = function() Lib:Destroy() end,
    })
end):SetRisk()

local share = misc:Section("Sharing", "Right")
share:Textbox("Webhook URL", "", function(text) end)
share:Textbox("Status text", "playing", function(text) end)
share:Button("Test webhook", function() Lib:Notify("Webhook", "test sent", 2, "success") end)

share:Divider("Config")
share:Info("configs save from the Settings tab")

--------------------------------------------------------------------------
-- Settings extras
--------------------------------------------------------------------------
local mine = win:SettingsSection("lurk.win", "Right")
mine:Toggle("Streamer mode", false, function(on)
    Lib:Notify("Streamer", on and "on" or "off", 1.5)
end)
mine:Slider("UI scale", 100, 5, 50, 150, "%", function(v) end)

--------------------------------------------------------------------------
-- Floating stats
--------------------------------------------------------------------------
local box = Lib:CreateBox({ title = "Stats", position = Vector2.new(24, 150), width = 190 })
box:Stat(function() return "Players: " .. #Players:GetPlayers() end)
box:Stat(function() return "KA: " .. (BW.KillAura and "ON" or "OFF") end)
box:Bar(0.7)

--------------------------------------------------------------------------
-- Lightweight runtime hooks
--------------------------------------------------------------------------
local function characterHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

RunService.Heartbeat:Connect(function()
    if BW.SpeedEnabled then
        local hum = characterHumanoid()
        if hum then
            pcall(function() hum.WalkSpeed = BW.WalkSpeed end)
        end
    end
end)

Lib:Notify("Loaded", "lurk.win BedWars ready", 3, "success")
