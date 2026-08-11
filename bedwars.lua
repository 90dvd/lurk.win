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
    if not string.find(body, 'INSui', 1, true) then
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

    -- single primary URL to avoid repeating Matcha parse spam on bad bodies
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
def(BW, "TeamCheck", true)
def(BW, "WallCheck", false)
def(BW, "AutoBlock", false)
def(BW, "AutoBuy", false)
def(BW, "EspEnabled", true)
def(BW, "EspBoxes", true)
def(BW, "EspNames", true)
def(BW, "EspDistance", true)
def(BW, "EspBeds", true)
def(BW, "EspColor", Color3.fromRGB(122, 134, 255))
def(BW, "EspFill", Color3.fromRGB(122, 134, 255))
def(BW, "EspFillAlpha", 0.3)
def(BW, "EspMaxDist", 400)
def(BW, "SpeedEnabled", false)
def(BW, "WalkSpeed", 16)
def(BW, "FlyEnabled", false)
def(BW, "FlySpeed", 60)
def(BW, "InfJump", false)
def(BW, "NoFall", false)
def(BW, "AntiAfk", true)

local win = Lib:CreateWindow({
    title        = "lurk.win",
    subtitle     = "BedWars",
    size         = Vector2.new(720, 540),
    menuKey      = "p",
    configName   = "default",
    configFolder = "lurk_bedwars",
    accentA      = Color3.fromRGB(90, 200, 255),
    accentB      = Color3.fromRGB(140, 110, 255),
    font         = "Proxima",
    opacity      = 0.96,
    rounding     = 1,
    rowLines     = true,
    smartFps     = true,
    autoSave     = true,
    startOpen    = true,
    keybindOverlay = true,
})

win:AddSettingsTab("cog")
Lib:Notify("lurk.win", "BedWars loaded - press P to toggle", 4, "success")

--------------------------------------------------------------------------
-- Combat
--------------------------------------------------------------------------
Lib:Category("COMBAT")
local combat = win:Tab("Combat", "swords")

local ka = combat:Section("Kill Aura", "Left", "hit players in range")
local kaToggle = ka:Toggle("Enabled", BW.KillAura, function(on)
    BW.KillAura = on
    Lib:Notify("Kill Aura", on and "on" or "off", 1.5, on and "success" or "warning")
end)
kaToggle:AddKeybind(BW.KillAuraKey or "q", "Toggle")
ka:Slider("Range", BW.KillAuraRange, 1, 5, 30, "studs", function(v)
    BW.KillAuraRange = v
end)
ka:Toggle("Team check", BW.TeamCheck, function(on) BW.TeamCheck = on end)
ka:Toggle("Wall check", BW.WallCheck, function(on) BW.WallCheck = on end)

local aim = combat:Section("Aim Assist", "Right", "soft aim toward targets")
local aimToggle = aim:Toggle("Enabled", BW.AimAssist, function(on)
    BW.AimAssist = on
end)
aimToggle:AddKeybind("e", "Hold")
aim:Dropdown("Target part", {BW.AimPart}, {"Head", "HumanoidRootPart", "UpperTorso"}, false, function(v)
    BW.AimPart = v[1] or "Head"
end)
aim:Slider("FOV", BW.AimFov, 1, 20, 400, "px", function(v) BW.AimFov = v end)
aim:Slider("Smoothness", BW.AimSmooth, 0.01, 0.05, 1, "", function(v) BW.AimSmooth = v end)
aim:Colorpicker("FOV color", Color3.fromRGB(120, 255, 140), function() end, 0.8)

local defn = combat:Section("Defense", "Right")
defn:Toggle("Auto block", BW.AutoBlock, function(on) BW.AutoBlock = on end)
defn:Toggle("Auto buy wool", BW.AutoBuy, function(on) BW.AutoBuy = on end)

--------------------------------------------------------------------------
-- Visuals
--------------------------------------------------------------------------
Lib:Category("VISUALS")
local visuals = win:Tab("Visuals", "eye")

local esp = visuals:Section("Player ESP", "Left", "see players through walls")
esp:Toggle("Enabled", BW.EspEnabled, function(on) BW.EspEnabled = on end):AddKeybind("h", "Toggle")
esp:Divider("Boxes")
esp:Toggle("Boxes", BW.EspBoxes, function(on) BW.EspBoxes = on end)
esp:Colorpicker("Box color", BW.EspColor, function(c) BW.EspColor = c end, 1)
esp:Colorpicker("Fill color", BW.EspFill, function(c, a)
    BW.EspFill = c
    BW.EspFillAlpha = a
end, BW.EspFillAlpha)

esp:Divider("Info")
esp:Toggle("Names", BW.EspNames, function(on) BW.EspNames = on end)
esp:Toggle("Distance", BW.EspDistance, function(on) BW.EspDistance = on end)
esp:RangeSlider("Render distance", 0, BW.EspMaxDist, 10, 0, 1000, "m", function(_, hi)
    BW.EspMaxDist = hi
end)

local beds = visuals:Section("Beds", "Right", "bed locations")
beds:Toggle("Bed ESP", BW.EspBeds, function(on) BW.EspBeds = on end)
beds:Colorpicker("Bed color", Color3.fromRGB(255, 120, 140), function() end, 1)
beds:Info("Bed markers use Drawing - stay visible while the menu is closed.")

local hud = visuals:Section("HUD", "Right")
hud:Label(function()
    return "Players: " .. #Players:GetPlayers()
end)
hud:Toggle("Watermark", true, function() end)
hud:Toggle("Keybind overlay", true, function(on)
    Lib:SetKeybindOverlay(on)
end)

--------------------------------------------------------------------------
-- Movement
--------------------------------------------------------------------------
Lib:Category("PLAYER")
local player = win:Tab("Player", "user")

local move = player:Section("Movement", "Left")
move:Toggle("Speed", BW.SpeedEnabled, function(on)
    BW.SpeedEnabled = on
end)
move:Slider("Walk speed", BW.WalkSpeed, 1, 16, 120, "", function(v)
    BW.WalkSpeed = v
end)

local fly = move:Toggle("Fly", BW.FlyEnabled, function(on)
    BW.FlyEnabled = on
end)
fly:AddKeybind("g", "Toggle", function(on)
    BW.FlyEnabled = on
    Lib:Notify("Fly", on and "on" or "off", 1)
end)
move:Slider("Fly speed", BW.FlySpeed, 5, 10, 250, "", function(v)
    BW.FlySpeed = v
end):DependsOn(fly)

move:Divider("Extras")
move:Toggle("Infinite jump", BW.InfJump, function(on) BW.InfJump = on end)
move:Toggle("No fall damage", BW.NoFall, function(on) BW.NoFall = on end)

local util = player:Section("Utility", "Right")
util:Toggle("Anti AFK", BW.AntiAfk, function(on) BW.AntiAfk = on end)
util:Keybind("Panic key", "k", function(key)
    Lib:Notify("Panic", "rebound to " .. tostring(key), 2)
end)
util:Divider("Server")
util:Button("Rejoin", function()
    Lib:Notify("Server", "rejoining...", 2)
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end)
end):AddButton("Copy job id", function()
    pcall(function()
        setclipboard(tostring(game.JobId))
    end)
    Lib:Notify("Server", "JobId copied", 2, "success")
end)

util:Dropdown("Teleport to", {}, function()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            names[#names + 1] = p.Name
        end
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
end, "live player list", true)

util:Divider("Danger")
util:Button("Unload menu", function()
    Lib:Dialog({
        title   = "Unload?",
        text    = "Remove lurk.win BedWars from this session?",
        confirm = "Unload",
        onConfirm = function()
            Lib:Destroy()
        end,
    })
end):SetRisk()

--------------------------------------------------------------------------
-- Settings extras
--------------------------------------------------------------------------
local mine = win:SettingsSection("lurk.win", "Right")
mine:Toggle("Streamer mode", false, function(on)
    Lib:Notify("Streamer", on and "on" or "off", 1.5)
end)
mine:Slider("UI scale note", 100, 5, 50, 150, "%", function() end)
mine:Info("Configs save under INSui folder lurk_bedwars/")

--------------------------------------------------------------------------
-- Floating stats
--------------------------------------------------------------------------
local box = Lib:CreateBox({
    title    = "Session",
    position = Vector2.new(24, 140),
    width    = 190,
})
box:Stat(function()
    return "Players: " .. #Players:GetPlayers()
end)
box:Stat(function()
    return "KA: " .. (BW.KillAura and "ON" or "OFF")
end)
box:Stat(function()
    return "ESP: " .. (BW.EspEnabled and "ON" or "OFF")
end)

--------------------------------------------------------------------------
-- Lightweight runtime hooks (config-driven)
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

Lib:Notify("Ready", "BedWars hub is up", 3, "success")
