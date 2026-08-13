    --[[
        lurk.win - BedWars
        Inject:
        _G.hybrid = false -- set to true if ur on hybrid
        loadstring(game:HttpGet("https://raw.githubusercontent.com/90dvd/lurk.win/refs/heads/main/bedwars.lua"))()
    ]]

    if _G.hybrid == nil then
        _G.hybrid = false
    end

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
    def(BW, "BowAimbot", false)
    def(BW, "BowAimFov", 180)
    def(BW, "BowFovCircle", true)
    def(BW, "BowDebug", true)
    def(BW, "BowTargetNpcs", true)
    def(BW, "BowSmoothness", 1)
    def(BW, "BowSpeed", 240)
    def(BW, "BowGravity", 50)
    def(BW, "SilentBAimbot", false)
    def(BW, "SilentBAimFov", 220)
    def(BW, "ResourceEsp", false)
    def(BW, "EspIron", true)
    def(BW, "EspDiamonds", true)
    def(BW, "EspEmeralds", true)
    def(BW, "NpcEsp", false)
    def(BW, "NpcBhaa", true)
    def(BW, "NpcTitan", true)
    def(BW, "NpcDimGuard", true)
    def(BW, "KitEsp", false)
    def(BW, "KitMetal", true)
    def(BW, "KitStar", true)
    def(BW, "KitBee", true)
    def(BW, "KitEldertree", true)
    def(BW, "Fullbright", false)
    def(BW, "TimeOfDay", 14)
    def(BW, "NoFog", false)
    def(BW, "NoShadows", false)
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
        smartFps      = true,
        checkboxStyle = true,
        opacity       = 98,
        logo          = "https://raw.githubusercontent.com/90dvd/lurk.win/refs/heads/main/assets/icon.png",
        autoSave      = true,
        startOpen     = true,
        keybindOverlay = true,
    })

    win:AddSettingsTab("gear")
    Lib:Notify("lurk.win", "Press P to toggle the menu", 4, "info")

    --------------------------------------------------------------------------
    -- COMBAT
    --------------------------------------------------------------------------
    Lib:Category("COMBAT")
    local combat = win:Tab("Combat", "sword")

    local ka = combat:Section("Kill Aura", "Left", "melee hits in range")
    local kaToggle
    kaToggle = ka:Toggle("Enabled", BW.KillAura, function(on)
        if on and not _G.hybrid then
            BW.KillAura = false
            if kaToggle then kaToggle:Set(false) end
            Lib:Notify("Kill Aura", "needs Matcha hybrid mode - set _G.hybrid = true before inject", 5, "warning")
            return
        end
        BW.KillAura = on
        Lib:Notify("Kill Aura", on and "on" or "off", 1.5, on and "success" or "warning")
    end)
    kaToggle:AddKeybind(BW.KillAuraKey or "q", "Toggle")
    ka:Slider("Range", BW.KillAuraRange, 1, 5, 30, "studs", function(v) BW.KillAuraRange = v end)

    local bow = combat:Section("Bow Aimbot", "Right", "locks onto players while drawing")
    local bowOn = bow:Toggle("Enabled", BW.BowAimbot, function(on)
        BW.BowAimbot = on
        Lib:Notify("Bow Aimbot", on and "on" or "off", 1.5, on and "success" or "warning")
    end)
    bowOn:AddKeybind("e", "Toggle", function(on)
        BW.BowAimbot = on
        Lib:Notify("Bow Aimbot", on and "on" or "off", 1, on and "success" or "warning")
    end)
    bow:Slider("FOV", BW.BowAimFov, 1, 20, 400, "px", function(v) BW.BowAimFov = v end)
    bow:Slider("Smoothness", BW.BowSmoothness, 0.1, 0.1, 2, "x", function(v) BW.BowSmoothness = v end)
    bow:Toggle("FOV circle", BW.BowFovCircle, function(on) BW.BowFovCircle = on end)
    bow:Toggle("Debug", BW.BowDebug, function(on) BW.BowDebug = on end, "shows why aim is skipping")
    bow:Toggle("Target NPCs", BW.BowTargetNpcs, function(on)
        BW.BowTargetNpcs = on
    end, "also lock onto Dim Guards, Titans, Bhaa - no Matcha NPC register needed")

    local silent = combat:Section("Silent B-Aimbot", "Right", "silent bow aim, no visible snap")
    local silentOn
    silentOn = silent:Toggle("Enabled", BW.SilentBAimbot, function(on)
        if on and not _G.hybrid then
            BW.SilentBAimbot = false
            if silentOn then silentOn:Set(false) end
            Lib:Notify("Silent B-Aimbot", "needs Matcha hybrid mode - set _G.hybrid = true before inject", 5, "warning")
            return
        end
        BW.SilentBAimbot = on
        if on then
            Lib:Notify("Silent B-Aimbot", "on", 2, "success")
        else
            Lib:Notify("Silent B-Aimbot", "off", 1.5, "warning")
        end
    end)
    silentOn:AddKeybind("r", "Toggle", function(on)
        if on and not _G.hybrid then
            BW.SilentBAimbot = false
            if silentOn then silentOn:Set(false) end
            Lib:Notify("Silent B-Aimbot", "needs Matcha hybrid mode - set _G.hybrid = true before inject", 5, "warning")
            return
        end
        BW.SilentBAimbot = on
        if on then
            Lib:Notify("Silent B-Aimbot", "on", 2, "success")
        else
            Lib:Notify("Silent B-Aimbot", "off", 1, "warning")
        end
    end)
    silent:Slider("FOV", BW.SilentBAimFov, 1, 20, 500, "px", function(v) BW.SilentBAimFov = v end)

    --------------------------------------------------------------------------
    -- VISUALS
    --------------------------------------------------------------------------
    Lib:Category("VISUALS")
    local vis = win:Tab("Visuals", "eye")

    local res = vis:Section("Resource ESP", "Left", "generators and dropped ores")
    local resOn = res:Toggle("Enabled", BW.ResourceEsp, function(on) BW.ResourceEsp = on end)
    res:Divider("Ores")
    res:Toggle("Iron", BW.EspIron, function(on) BW.EspIron = on end):DependsOn(resOn)
    res:Toggle("Diamonds", BW.EspDiamonds, function(on) BW.EspDiamonds = on end):DependsOn(resOn)
    res:Toggle("Emeralds", BW.EspEmeralds, function(on) BW.EspEmeralds = on end):DependsOn(resOn)

    local npc = vis:Section("NPC ESP", "Right", "map bosses and guards")
    local npcOn = npc:Toggle("Enabled", BW.NpcEsp, function(on) BW.NpcEsp = on end)
    npc:Divider("Targets")
    npc:Toggle("Bhaa", BW.NpcBhaa, function(on) BW.NpcBhaa = on end):DependsOn(npcOn)
    npc:Toggle("Titan", BW.NpcTitan, function(on) BW.NpcTitan = on end):DependsOn(npcOn)
    npc:Toggle("Dim Guard", BW.NpcDimGuard, function(on) BW.NpcDimGuard = on end):DependsOn(npcOn)

    local kit = vis:Section("Kit ESP", "Left", "kit-specific world objects")
    local kitOn = kit:Toggle("Enabled", BW.KitEsp, function(on) BW.KitEsp = on end)
    kit:Divider("Kits")
    kit:Toggle("Metal ESP", BW.KitMetal, function(on) BW.KitMetal = on end):DependsOn(kitOn)
    kit:Toggle("Star ESP", BW.KitStar, function(on) BW.KitStar = on end):DependsOn(kitOn)
    kit:Toggle("Bee ESP", BW.KitBee, function(on) BW.KitBee = on end):DependsOn(kitOn)
    kit:Toggle("Eldertree ESP", BW.KitEldertree, function(on) BW.KitEldertree = on end):DependsOn(kitOn)

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
    local trackToggle = ptrack:Toggle("Track nearest", BW.TrackNearest, function(on) BW.TrackNearest = on end):AddKeybind("y", "Toggle")
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

    -- Standalone keybind rows. Their values live in the config FLAGS (like the
    -- menu key), so they reliably save/load with configs, and on change or
    -- config load they push the key into the toggle's keybind chip, which is
    -- what the feature poll actually reads.
    local function chipKey(handle, key)
        pcall(function()
            if handle and handle.keyHandle and key and key ~= "" then
                handle.keyHandle:Set(key)
            end
        end)
    end
    local binds = win:SettingsSection("Keybinds", "Left")
    binds:Keybind("Bow Aimbot", "e", function(k) chipKey(bowOn, k) end)
    binds:Keybind("Kill Aura", "q", function(k) chipKey(kaToggle, k) end)
    binds:Keybind("Silent B-Aimbot", "r", function(k) chipKey(silentOn, k) end)
    binds:Keybind("Fly", "g", function(k) chipKey(fly, k) end)
    binds:Keybind("Track nearest", "y", function(k) chipKey(trackToggle, k) end)

    --------------------------------------------------------------------------
    -- Floating stats
    --------------------------------------------------------------------------
    local box = Lib:CreateBox({ title = "Stats", position = Vector2.new(24, 150), width = 190 })
    box:Stat(function() return "Players: " .. #Players:GetPlayers() end)
    box:Stat(function() return "KA: " .. (BW.KillAura and "ON" or "OFF") end)
    box:Bar(0.7)

    local bowDbgLines = { "bow debug idle" }
    local calDbg = "cal: no shots yet"
    local dbgBox = Lib:CreateBox({ title = "Bow Debug", position = Vector2.new(24, 360), width = 260 })
    dbgBox:Text(function()
        return bowDbgLines[1] or ""
    end)
    dbgBox:Text(function()
        return bowDbgLines[2] or ""
    end)
    dbgBox:Text(function()
        return bowDbgLines[3] or ""
    end)
    dbgBox:Text(function()
        return bowDbgLines[4] or ""
    end)
    dbgBox:Text(function()
        return bowDbgLines[5] or ""
    end)
    dbgBox:Text(function()
        return calDbg
    end)

    --------------------------------------------------------------------------
    -- Runtime (Kill Aura / ESP / Bow aim from MatchaLuauVM Bedwars.lua)
    --------------------------------------------------------------------------
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Camera = Workspace.CurrentCamera

    local ismouse1 = envGet("ismouse1pressed")
    if type(ismouse1) ~= "function" then
        ismouse1 = function() return false end
    end

    local function pickFn(...)
        for i = 1, select("#", ...) do
            local f = select(i, ...)
            if type(f) == "function" then return f, true end
        end
        return function() end, false
    end

    local mousemoverel, hasMoveRel = pickFn(envGet("mousemoverel"), rawget(_G, "mousemoverel"))
    local mousemoveabs, hasMoveAbs = pickFn(envGet("mousemoveabs"), rawget(_G, "mousemoveabs"))
    local isrbxactive = pickFn(envGet("isrbxactive"), rawget(_G, "isrbxactive"), function() return true end)
    local setrobloxinput = pickFn(envGet("setrobloxinput"), rawget(_G, "setrobloxinput"))

    local function characterHumanoid()
        local char = LocalPlayer.Character
        if not char then return nil end
        return char:FindFirstChildOfClass("Humanoid")
    end

    local function findNetManaged()
        local node = ReplicatedStorage
        local path = { "rbxts_include", "node_modules", "@rbxts", "net", "out", "_NetManaged" }
        for i = 1, #path do
            if not node then return nil end
            node = node:FindFirstChild(path[i])
        end
        return node
    end

    local NetManaged, SwordHitEvent, ProjectileFire
    local function refreshRemotes()
        NetManaged = findNetManaged()
        if NetManaged then
            SwordHitEvent = NetManaged:FindFirstChild("SwordHit")
            ProjectileFire = NetManaged:FindFirstChild("ProjectileFire") or NetManaged:FindFirstChild("FireProjectile")
        end
    end
    refreshRemotes()

    local swordList = {
        "wood_sword", "stone_sword", "iron_sword", "diamond_sword", "og_diamond_sword", "ice_sword", "emerald_sword", "og_emerald_sword", "void_sword", "glitch_wood_sword", "glitch_void_sword",
        "wood_dao", "stone_dao", "iron_dao", "diamond_dao", "emerald_dao",
        "wood_dagger", "stone_dagger", "iron_dagger", "diamond_dagger", "mythic_dagger",
        "wood_scythe", "stone_scythe", "iron_scythe", "diamond_scythe", "mythic_scythe", "scythe", "reaper_scythe", "sky_scythe",
        "wood_gauntlets", "stone_gauntlets", "iron_gauntlets", "diamond_gauntlets", "mythic_gauntlets_plain", "mythic_gauntlets",
        "rageblade", "double_edge_sword", "spirit_dagger", "spirit_dagger_left", "pirate_sword_fp", "cutlass_ghost", "big_wood_sword", "heavenly_sword", "infernal_saber", "bear_claws", "baguette", "knockback_fish",
        "taser", "glitch_taser", "hot_potato", "frying_pan", "juggernaut_rage_blade", "battle_axe", "mass_hammer", "twirlblade", "noctium_blade", "noctium_blade_2", "noctium_blade_3", "noctium_blade_4",
        "laser_sword", "frosty_hammer", "sparkler", "toy_hammer", "rainbow_axe", "wizard_stick", "hero_magical_girl_rapier", "villain_magical_girl_rapier", "hero_scissor_sword", "villain_scissor_sword",
        "wood_gun_blade", "stone_gun_blade", "iron_gun_blade", "diamond_gun_blade", "emerald_gun_blade", "pillow", "iron_pickaxe_sword", "diamond_pickaxe_sword", "knight_shield", "tinkers_wrench", "whisper_feather",
        "super_guitar", "guards_spear"
    }

    local function getEquippedWeaponDirect()
        local char = LocalPlayer.Character
        if not char then return nil end
        for i = 1, #swordList do
            local found = char:FindFirstChild(swordList[i])
            if found and found:IsA("Tool") then
                return found
            end
        end
        return nil
    end

    local function getAttackWeapon()
        local weapon = getEquippedWeaponDirect()
        if weapon then return weapon end
        local char = LocalPlayer.Character
        return char and char:FindFirstChildWhichIsA("Tool")
    end

    local function getEquippedBow()
        local char = LocalPlayer.Character
        if not char then return nil end
        local kids = char:GetChildren()
        for i = 1, #kids do
            local child = kids[i]
            if child and child:IsA("Tool") then
                local n = string.lower(tostring(child.Name))
                if string.find(n, "bow", 1, true)
                    or string.find(n, "crossbow", 1, true)
                    or string.find(n, "headhunter", 1, true)
                    or string.find(n, "tactical", 1, true)
                    or string.find(n, "archer", 1, true)
                    or string.find(n, "firework", 1, true) then
                    return child
                end
            end
        end
        return char:FindFirstChildWhichIsA("Tool")
    end

    local function npcKind(obj)
        local n = string.lower(tostring(obj.Name))
        if string.find(n, "bhaa", 1, true) or string.find(n, "bahaa", 1, true) then
            return "Bhaa"
        end
        if string.find(n, "titan", 1, true) then
            return "Titan"
        end
        if string.find(n, "guard", 1, true)
            or string.find(n, "guardian", 1, true)
            or string.find(n, "diamond", 1, true)
            or string.find(n, "dimond", 1, true) then
            return "DimGuard"
        end
        return nil
    end

    local function getModelRoot(obj)
        if not obj then return nil end
        return obj:FindFirstChild("HumanoidRootPart")
            or obj:FindFirstChild("Torso")
            or obj:FindFirstChild("UpperTorso")
            or obj.PrimaryPart
    end

    local function isLocalModel(obj)
        local char = LocalPlayer.Character
        return obj == char or obj.Name == LocalPlayer.Name
    end

    local function isPlayerModel(obj)
        if not obj or not obj:IsA("Model") then return false end
        if not obj:FindFirstChild("HumanoidRootPart") or not obj:FindFirstChild("Humanoid") then return false end
        if isLocalModel(obj) then return false end
        local plr = Players:FindFirstChild(obj.Name)
        return plr ~= nil and plr ~= LocalPlayer
    end

    local function isEntityModel(obj)
        if not obj or obj.ClassName ~= "Model" then return false end
        if not obj:FindFirstChildOfClass("Humanoid") then return false end
        if not getModelRoot(obj) then return false end
        if isLocalModel(obj) then return false end
        if Players:FindFirstChild(obj.Name) ~= nil then return false end
        if npcKind(obj) then return true end
        return BW.BowTargetNpcs == true
    end

    local espConfigs = {
        Player = {
            validator = isPlayerModel,
            getTarget = function(obj) return getModelRoot(obj) end,
            text = function(obj) return obj.Name end,
            color = Color3.fromRGB(255, 255, 255),
            enabled = function() return BW.KillAura or BW.BowAimbot or BW.SilentBAimbot end,
            draw = function() return false end,
        },
        Entity = {
            validator = isEntityModel,
            getTarget = function(obj) return getModelRoot(obj) end,
            text = function(obj) return obj.Name end,
            color = Color3.fromRGB(255, 100, 100),
            enabled = function() return BW.KillAura or BW.NpcEsp or BW.BowAimbot or BW.SilentBAimbot end,
            draw = function(obj)
                if not BW.NpcEsp then return false end
                local kind = npcKind(obj)
                if kind == "Bhaa" then return BW.NpcBhaa end
                if kind == "Titan" then return BW.NpcTitan end
                if kind == "DimGuard" then return BW.NpcDimGuard end
                return false
            end,
        },
        Metal = {
            validator = function(obj)
                return obj:IsA("Model") and obj:FindFirstChild("hidden-metal-prompt") and obj:FindFirstChild("Part")
            end,
            getTarget = function(obj) return obj.Part end,
            text = "Metal",
            color = Color3.fromRGB(0, 255, 255),
            enabled = function() return BW.KitEsp and BW.KitMetal end,
            draw = function() return BW.KitEsp and BW.KitMetal end,
        },
        Bee = {
            validator = function(obj) return obj.Name == "Bee" and obj:FindFirstChild("Root") end,
            getTarget = function(obj) return obj.Root end,
            text = "Bee",
            color = Color3.fromRGB(255, 255, 0),
            enabled = function() return BW.KitEsp and BW.KitBee end,
            draw = function() return BW.KitEsp and BW.KitBee end,
        },
        Eldertree = {
            validator = function(obj) return obj.Name == "TreeOrb" and obj:FindFirstChild("Spirit") end,
            getTarget = function(obj) return obj.Spirit end,
            text = "Eldertree",
            color = Color3.fromRGB(0, 255, 0),
            enabled = function() return BW.KitEsp and BW.KitEldertree end,
            draw = function() return BW.KitEsp and BW.KitEldertree end,
        },
        Star = {
            validator = function(obj)
                return (obj.Name == "CritStar" or obj.Name == "VitalityStar") and obj:FindFirstChild("RootPart")
            end,
            getTarget = function(obj) return obj.RootPart end,
            text = function(obj) return obj.Name == "CritStar" and "Crit Star" or "Vitality Star" end,
            color = function(obj)
                return obj.Name == "CritStar" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(144, 238, 144)
            end,
            enabled = function() return BW.KitEsp and BW.KitStar end,
            draw = function() return BW.KitEsp and BW.KitStar end,
        },
        iron = {
            validator = function(obj) return obj:IsA("BasePart") and obj.Name == "iron" and obj.Parent and obj.Parent.Name == "ItemDrops" end,
            getTarget = function(obj) return obj end,
            text = "Iron",
            color = Color3.fromRGB(200, 200, 200),
            enabled = function() return BW.ResourceEsp and BW.EspIron end,
            draw = function() return BW.ResourceEsp and BW.EspIron end,
        },
        diamond = {
            validator = function(obj) return obj:IsA("BasePart") and obj.Name == "diamond" and obj.Parent and obj.Parent.Name == "ItemDrops" end,
            getTarget = function(obj) return obj end,
            text = "Diamond",
            color = Color3.fromRGB(0, 191, 255),
            enabled = function() return BW.ResourceEsp and BW.EspDiamonds end,
            draw = function() return BW.ResourceEsp and BW.EspDiamonds end,
        },
        emerald = {
            validator = function(obj) return obj:IsA("BasePart") and obj.Name == "emerald" and obj.Parent and obj.Parent.Name == "ItemDrops" end,
            getTarget = function(obj) return obj end,
            text = "Emerald",
            color = Color3.fromRGB(0, 230, 115),
            enabled = function() return BW.ResourceEsp and BW.EspEmeralds end,
            draw = function() return BW.ResourceEsp and BW.EspEmeralds end,
        },
    }

    local trackedObjects = {}

    local function getUniqueIdentifier(model)
        local addr
        pcall(function() addr = model.Address end)
        return addr or tostring(model)
    end

    local function hideDraw(data)
        if not data or data.noDraw then return end
        if data.box then data.box.Visible = false end
        if data.text then data.text.Visible = false end
        if data.amountText then data.amountText.Visible = false end
    end

    local TRACK_CAP = 48

    local function createESP(obj, espType, config)
        local id = getUniqueIdentifier(obj)
        if trackedObjects[id] then return end
        local part = config.getTarget(obj)
        if not part then return end

        local count = 0
        for _ in pairs(trackedObjects) do
            count = count + 1
            if count >= TRACK_CAP then return end
        end

        local wantsDraw = config.draw and config.draw(obj)
        if not wantsDraw then
            trackedObjects[id] = {
                noDraw = true,
                part = part,
                obj = obj,
                espType = espType,
                config = config,
            }
            return
        end

        local finalColor = type(config.color) == "function" and config.color(obj) or config.color
        local finalText = type(config.text) == "function" and config.text(obj) or config.text

        -- Name-only ESP: one colored text label, no box. Resources get the
        -- amount appended live in the render loop, e.g. "Iron (46)".
        local text = Drawing.new("Text")
        text.Visible = false
        text.Text = finalText
        text.Color = finalColor
        text.Center = true
        text.Outline = true
        pcall(function() text.FontSize = 13 end)

        trackedObjects[id] = {
            text = text,
            baseText = finalText,
            part = part,
            obj = obj,
            espType = espType,
            config = config,
        }
    end

    local function removeESP(id)
        local data = trackedObjects[id]
        if not data then return end
        if data.box then pcall(function() data.box:Remove() end) end
        if data.text then pcall(function() data.text:Remove() end) end
        if data.amountText then pcall(function() data.amountText:Remove() end) end
        trackedObjects[id] = nil
    end

    local function classify(obj)
        for espType, config in pairs(espConfigs) do
            if config.validator(obj) then
                return espType, config
            end
        end
        return nil, nil
    end

    local function consider(obj, currentScanIds)
        if not obj then return end
        local espType, config
        pcall(function()
            espType, config = classify(obj)
        end)
        if espType and config and config.enabled() then
            local id = getUniqueIdentifier(obj)
            -- If the entry was tracked without drawings (e.g. combat-only) and the
            -- ESP toggle changed since, rebuild it so boxes appear/disappear live.
            local existing = trackedObjects[id]
            if existing then
                local wantsDraw = (config.draw and config.draw(obj)) and true or false
                local hasDraw = existing.noDraw ~= true
                if wantsDraw ~= hasDraw then
                    removeESP(id)
                end
            end
            createESP(obj, espType, config)
            currentScanIds[id] = true
        end
    end

    local function scanShallow(folder, currentScanIds, depth)
        if not folder or depth < 0 then return end
        local ok, kids = pcall(function() return folder:GetChildren() end)
        if not ok or not kids then return end
        for i = 1, #kids do
            consider(kids[i], currentScanIds)
            if depth > 0 and kids[i] then
                local className = kids[i].ClassName
                if className == "Folder" or className == "Model" then
                    scanShallow(kids[i], currentScanIds, depth - 1)
                end
            end
        end
    end

    -- Walk Model/Folder trees only (skips map Parts). Finds nested NPCs like Diamond Guardian.
    local function scanNpcTree(root, currentScanIds, depth, budget)
        if not root or depth < 0 or not budget or budget[1] <= 0 then return end
        local ok, kids = pcall(function() return root:GetChildren() end)
        if not ok or not kids then return end
        for i = 1, #kids do
            if budget[1] <= 0 then return end
            local obj = kids[i]
            if obj then
                local cn = obj.ClassName
                if cn == "Model" then
                    local hum
                    pcall(function() hum = obj:FindFirstChild("Humanoid") end)
                    local kind = npcKind(obj)
                    if hum or kind then
                        consider(obj, currentScanIds)
                        budget[1] = budget[1] - 1
                    end
                    -- Don't walk into found NPCs or typical map-block models.
                    local n = string.lower(tostring(obj.Name))
                    local skipDeep = hum ~= nil
                        or n == "block" or n == "wool" or n == "stone" or n == "wood"
                        or n == "obsidian" or n == "glass" or n == "terracotta"
                    if not skipDeep then
                        scanNpcTree(obj, currentScanIds, depth - 1, budget)
                    end
                elseif cn == "Folder" or cn == "Configuration" then
                    scanNpcTree(obj, currentScanIds, depth - 1, budget)
                elseif cn == "Humanoid" and obj.Parent then
                    consider(obj.Parent, currentScanIds)
                    budget[1] = budget[1] - 1
                end
            end
        end
    end

    task.spawn(function()
        while true do
            local needCombat = BW.KillAura or BW.BowAimbot or BW.SilentBAimbot
            pcall(function()
                if not needCombat and bowOn and bowOn.IsActivated then
                    needCombat = bowOn:IsActivated() == true
                end
            end)
            local needEsp = BW.ResourceEsp or BW.NpcEsp or BW.KitEsp
            if needCombat or needEsp then
                local currentScanIds = {}

                local plist = Players:GetPlayers()
                for i = 1, #plist do
                    local plr = plist[i]
                    if plr ~= LocalPlayer and plr.Character then
                        consider(plr.Character, currentScanIds)
                    end
                end

                if BW.ResourceEsp then
                    local itemDropsFolder = Workspace:FindFirstChild("ItemDrops")
                    if itemDropsFolder then
                        scanShallow(itemDropsFolder, currentScanIds, 0)
                    end
                end

                if BW.KitEsp then
                    scanShallow(Workspace, currentScanIds, 0)
                    local extra = { "NPCs", "Mobs", "Entities", "LivingEntities" }
                    for i = 1, #extra do
                        local folder = Workspace:FindFirstChild(extra[i])
                        if folder then
                            scanShallow(folder, currentScanIds, 1)
                        end
                    end
                end

                if BW.NpcEsp or needCombat then
                    scanNpcTree(Workspace, currentScanIds, 10, { 80 })
                end

                for id, data in pairs(trackedObjects) do
                    if not currentScanIds[id] or not data.obj or not data.obj.Parent then
                        removeESP(id)
                    end
                end
            else
                for id in pairs(trackedObjects) do
                    removeESP(id)
                end
            end

            if needCombat and not SwordHitEvent then
                refreshRemotes()
            end

            task.wait(1.5)
        end
    end)

    local function screenCenter()
        local vs
        pcall(function() vs = Camera.ViewportSize end)
        if vs then
            return vs.X * 0.5, vs.Y * 0.5
        end
        return 960, 540
    end

    local UserInputService
    pcall(function() UserInputService = game:GetService("UserInputService") end)

    -- Same pixel space as WorldToScreen / mousemoveabs (viewport, top-left origin).
    local function mouseScreenPos()
        local loc
        pcall(function()
            if UserInputService and UserInputService.GetMouseLocation then
                loc = UserInputService:GetMouseLocation()
            end
        end)
        if loc and loc.X and loc.Y then
            return loc.X, loc.Y
        end
        local mx, my
        pcall(function()
            local m = LocalPlayer:GetMouse()
            mx, my = m.X, m.Y
        end)
        if mx then
            local insetY = 0
            pcall(function()
                local gs = game:GetService("GuiService")
                local inset = gs:GetGuiInset()
                if inset then insetY = inset.Y end
            end)
            return mx, my + insetY
        end
        return screenCenter()
    end

    local fovCircle, fovFill
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Filled = false
        fovCircle.Visible = false
        fovCircle.Color = Color3.fromRGB(120, 255, 140)
        fovCircle.Transparency = 0.9
        pcall(function() fovCircle.Thickness = 2 end)
        pcall(function() fovCircle.NumSides = 48 end)
    end)
    pcall(function()
        fovFill = Drawing.new("Circle")
        fovFill.Filled = false
        fovFill.Visible = false
        fovFill.Color = Color3.fromRGB(255, 80, 80)
        pcall(function() fovFill.Thickness = 2 end)
        pcall(function() fovFill.NumSides = 24 end)
        pcall(function() fovFill.Radius = 6 end)
    end)

    local function closestTargetInFov(maxFov, includeNpcs)
        local best, bestDist
        local cx, cy = mouseScreenPos()
        local char = LocalPlayer.Character
        for _, data in pairs(trackedObjects) do
            local isPlayer = data.espType == "Player"
            local isNpc = data.espType == "Entity"
            if (isPlayer or (includeNpcs and isNpc)) and data.part and data.part.Parent and data.obj ~= char then
                local hum
                pcall(function()
                    hum = data.obj:FindFirstChildWhichIsA("Humanoid") or data.part.Parent:FindFirstChildWhichIsA("Humanoid")
                end)
                local hp = 1
                pcall(function()
                    if hum then hp = hum.Health end
                end)
                if (not hum) or (hp and hp > 0) then
                    local skip = false
                    if isPlayer then
                        local plr = Players:FindFirstChild(data.obj.Name)
                        if plr and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
                            skip = true
                        end
                    end
                    if not skip then
                        local aimPart = data.part
                        if isPlayer then
                            pcall(function()
                                local head = data.obj:FindFirstChild("Head")
                                if head then aimPart = head end
                            end)
                        end
                        local pos, onScreen = WorldToScreen(aimPart.Position)
                        if onScreen then
                            local dx, dy = pos.X - cx, pos.Y - cy
                            local fov = math.sqrt(dx * dx + dy * dy)
                            if fov <= maxFov and (not bestDist or fov < bestDist) then
                                bestDist = fov
                                best = data
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function partVelocity(part)
        local vel = Vector3.new(0, 0, 0)
        pcall(function()
            vel = part.AssemblyLinearVelocity
        end)
        if vel.Magnitude < 0.01 then
            pcall(function()
                vel = part.Velocity
            end)
        end
        -- Matcha can return garbage velocities on NPCs; that aims into the sky.
        if vel.Magnitude > 90 or vel.Magnitude ~= vel.Magnitude then
            return Vector3.new(0, 0, 0)
        end
        return vel
    end

    -- Per-weapon ballistic profiles. Wood bow, crossbow, headhunter etc. all fly
    -- differently, so speed/gravity/bias are measured and stored per equipped
    -- tool name. Unknown weapons start from defaults and calibrate themselves
    -- within a few shots.
    local BOW_SEEDS = {
        -- Measured in-game, close + long range confirmed.
        wood_bow = { spd = 243.0, g = 35.58, bias = -0.027 },
        wood_crossbow = { spd = 401.4, g = 33.51, bias = -0.016 },
        headhunter = { spd = 503.2, g = 35.37, bias = -0.024 },
    }
    local DEFAULT_SPD, DEFAULT_G = 240, 35

    local calProfiles = {}
    local calFileOk = false
    local CAL_FILE = "lurk_bow_cal.txt"

    local wkCache, wkCacheAt = "wood_bow", 0
    local function bowWeaponKey()
        local now = tick()
        if now - wkCacheAt < 0.5 then return wkCache end
        wkCacheAt = now
        local key = "wood_bow"
        pcall(function()
            local tool = getEquippedBow()
            if tool then
                local n = string.lower(tostring(tool.Name)):gsub("%s+", "_")
                if n ~= "" then key = n end
            end
        end)
        wkCache = key
        return key
    end

    local function getProfile(key)
        local p = calProfiles[key]
        if p then return p end
        local seed = BOW_SEEDS[key]
        if not seed then
            for sk, s in pairs(BOW_SEEDS) do
                if string.find(key, sk, 1, true) or string.find(sk, key, 1, true) then
                    seed = s
                    break
                end
            end
        end
        if seed then
            p = { spd = seed.spd, g = seed.g, bias = seed.bias or 0, n = 1 }
        else
            p = { spd = DEFAULT_SPD, g = DEFAULT_G, bias = 0, n = 0 }
        end
        calProfiles[key] = p
        return p
    end

    -- Persistence, best effort in this order:
    --  1. file (writefile/readfile, survives Roblox restarts if the executor has it)
    --  2. getgenv (survives re-injects while Roblox/Matcha runs)
    --  3. BOW_SEEDS hardcoded above
    pcall(function()
        if type(readfile) ~= "function" then return end
        local raw = readfile(CAL_FILE)
        if type(raw) ~= "string" then return end
        for line in string.gmatch(raw, "[^\r\n]+") do
            local f = {}
            for tok in string.gmatch(line, "[^,]+") do f[#f + 1] = tok end
            local k = f[1]
            if k and string.match(k, "%a") and f[2] then
                calProfiles[k] = {
                    spd = tonumber(f[2]) or DEFAULT_SPD,
                    g = tonumber(f[3]) or DEFAULT_G,
                    bias = tonumber(f[4]) or 0,
                    n = tonumber(f[5]) or 1,
                }
            end
        end
    end)

    pcall(function()
        local saved = getgenv().LURK_BOW_CAL2
        if type(saved) == "table" then
            for k, p in pairs(saved) do
                if type(p) == "table" and p.spd then
                    calProfiles[k] = { spd = p.spd, g = p.g, bias = p.bias or 0, n = p.n or 1 }
                end
            end
        end
    end)

    local function saveCalibration()
        pcall(function()
            getgenv().LURK_BOW_CAL2 = calProfiles
        end)
        pcall(function()
            if type(writefile) ~= "function" then return end
            local lines = {}
            for k, p in pairs(calProfiles) do
                lines[#lines + 1] = string.format("%s,%.2f,%.3f,%.4f,%d", k, p.spd, p.g, p.bias, p.n)
            end
            writefile(CAL_FILE, table.concat(lines, "\n"))
            calFileOk = true
        end)
    end

    bow:Button("Copy calibration", function()
        local key = bowWeaponKey()
        local p = getProfile(key)
        local s = string.format(
            "%s = { spd = %.1f, g = %.2f, bias = %.3f }, -- n=%d",
            key, p.spd, p.g, p.bias, p.n
        )
        pcall(setclipboard, s)
        Lib:Notify("bow", "copied: " .. s, 4, "success")
    end, "copies the equipped weapon's measured ballistics")

    local function getShotOrigin()
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then return hrp.Position end
            local head = char:FindFirstChild("Head")
            if head then return head.Position end
        end
        if Camera then return Camera.Position end
        return nil
    end

    -- Dead-center torso. Any base offset made close shots fly over the head;
    -- range compensation comes only from the ballistic drop term.
    local function getHitPosition(part)
        return part.Position
    end

    -- Single compensation: low-arc ballistic to the hit point, dy included.
    -- Recalc every call from live origin/target. Never a distance table.
    local function bowAimWorld(origin, part)
        local prof = getProfile(bowWeaponKey())
        local speed, gravity, weaponBias = prof.spd, prof.g, prof.bias
        local hit = getHitPosition(part)
        local vel = partVelocity(part)
        local predicted = hit
        local tanTheta, dx, dy, dist = 0, 0, 0, 0

        for _ = 1, 4 do
            dist = (predicted - origin).Magnitude
            dx = Vector3.new(predicted.X - origin.X, 0, predicted.Z - origin.Z).Magnitude
            dy = predicted.Y - origin.Y
            if dx < 0.4 then
                return predicted, 0, dist, dy
            end

            local v2 = speed * speed
            local disc = v2 * v2 - gravity * (gravity * dx * dx + 2 * dy * v2)
            if disc >= 0 then
                -- exact low-arc angle; negative when the target is below us
                tanTheta = (v2 - math.sqrt(disc)) / (gravity * dx)
            else
                tanTheta = (dy / dx) + (gravity * dx) / (2 * v2)
            end
            -- The measured launch bias only shows up at range (it was calibrated from
            -- long shots); at close range applying it full strength aims over the head.
            -- Ramp it in smoothly from 0 at <=25 studs to full at >=100 studs.
            local biasScale = (dist - 25) / 75
            if biasScale < 0 then biasScale = 0 elseif biasScale > 1 then biasScale = 1 end
            tanTheta = tanTheta - weaponBias * biasScale
            -- Upward stays tight (0.35 was the proven working cap; more overshoots).
            -- Downward is wide open so steep shots from high ground still connect.
            if tanTheta > 0.35 then tanTheta = 0.35 end
            if tanTheta < -4 then tanTheta = -4 end

            local cosT = 1 / math.sqrt(1 + tanTheta * tanTheta)
            local t = dx / (speed * cosT)
            if t < 0.02 then t = 0.02 elseif t > 2 then t = 2 end
            predicted = hit + vel * t
        end

        local aim = Vector3.new(predicted.X, origin.Y + tanTheta * dx, predicted.Z)
        return aim, tanTheta, dist, dy
    end

    local lastMove = "none"
    local lastSkip = "init"
    local lastAimInfo = "aim: idle"
    local lastM1 = false
    local recoverUntil = 0
    local lastAimTan = 0
    local lastAimDist = 0
    local lastAimAt = 0
    local lastShotInfo = nil -- { t, aimTan, dist } set when mouse1 is released
    local silentNextFire = 0
    local silentFails = 0

    local function currentMousePos()
        return mouseScreenPos()
    end

    local function moveMouseToScreen(sx, sy, bodyY, maxUp)
        if not sx or not sy then
            lastSkip = "no screen pos"
            return false
        end
        if not isrbxactive() then
            lastSkip = "roblox not focused"
            return false
        end
        if Lib.IsOpen and Lib:IsOpen() then
            lastSkip = "menu open - close with P"
            return false
        end
        local mx, my = currentMousePos()
        if bodyY and my < bodyY - 80 then
            sy = bodyY
        end
        local dx = sx - mx
        local dy = sy - my
        if dx * dx + dy * dy < 4 then
            lastSkip = "already on target"
            return true
        end
        -- Smoothness scales the per-frame step caps: 0.1 = near-instant flick,
        -- 1 = default speed, 2 = half speed.
        local smooth = BW.BowSmoothness or 1
        if smooth < 0.1 then smooth = 0.1 end
        local capX = 22 / smooth
        local capDown = 26 / smooth
        if not maxUp then maxUp = 7 end
        maxUp = maxUp / smooth
        if dx > capX then dx = capX elseif dx < -capX then dx = -capX end
        if dy < -maxUp then dy = -maxUp end
        if dy > capDown then dy = capDown end
        pcall(setrobloxinput, true)
        if hasMoveRel then
            local okRel, errRel = pcall(mousemoverel, math.floor(dx + 0.5), math.floor(dy + 0.5))
            if okRel then
                lastMove = "rel " .. math.floor(dx) .. "," .. math.floor(dy)
                lastSkip = "moved"
                return true
            end
            lastSkip = "rel fail: " .. tostring(errRel)
            return false
        end
        lastSkip = "no mousemoverel"
        return false
    end

    local function aimBowCamera(part, isNpc)
        if not part or not Camera then
            lastSkip = "no part/camera"
            return
        end
        pcall(function() Camera = Workspace.CurrentCamera end)

        local origin = getShotOrigin()
        if not origin then
            lastSkip = "no origin"
            return
        end

        local hit = getHitPosition(part)
        local hitPos, hitOn = WorldToScreen(hit)
        if not hitOn or not hitPos then
            lastSkip = "target offscreen"
            return
        end

        local aimWorld, tanTheta, dist, dy = bowAimWorld(origin, part)
        local pos, onScreen = WorldToScreen(aimWorld)
        if not onScreen or not pos then
            pos = hitPos
        end

        lastAimTan = tanTheta or 0
        lastAimDist = dist or 0
        lastAimAt = tick()

        local m1 = false
        pcall(function() m1 = ismouse1() == true end)
        if lastM1 and not m1 then
            recoverUntil = tick() + 0.28
        end
        lastM1 = m1

        local sx, sy = pos.X, pos.Y
        if tick() < recoverUntil then
            sx, sy = hitPos.X, hitPos.Y
        end

        local vs
        pcall(function() vs = Camera.ViewportSize end)
        if vs then
            local top = vs.Y * 0.05
            if sy < top then sy = top end
            if sy > vs.Y * 0.97 then sy = vs.Y * 0.97 end
            -- Sky safety only. Do not pin to hit Y — shooting down must aim below.
            if hitPos.Y - sy > 42 then
                sy = hitPos.Y - 42
            end
        end

        local dbgProf = getProfile(bowWeaponKey())
        lastAimInfo = string.format(
            "d=%.0f th=%.2f spd=%.0f g=%.0f bias=%.2f",
            dist or 0, tanTheta or 0, dbgProf.spd, dbgProf.g, dbgProf.bias
        )

        if fovFill then
            fovFill.Position = Vector2.new(sx, sy)
            fovFill.Visible = BW.BowFovCircle == true
        end
        moveMouseToScreen(sx, sy, hitPos.Y, 10)
    end

    --------------------------------------------------------------------------
    -- Arrow calibration: sample our own arrows in flight and fit the real
    -- ballistics. y(t) = a + v0y*t - 0.5*g*t^2  ->  quadratic least squares.
    --------------------------------------------------------------------------
    local function quadFit(samples) -- samples: { {t, y}, ... } -> v0y, g
        local n = #samples
        if n < 4 then return nil end
        local S1, S2, S3, S4 = 0, 0, 0, 0
        local Sy, Sty, St2y = 0, 0, 0
        for i = 1, n do
            local t, y = samples[i][1], samples[i][2]
            local t2 = t * t
            S1 = S1 + t
            S2 = S2 + t2
            S3 = S3 + t2 * t
            S4 = S4 + t2 * t2
            Sy = Sy + y
            Sty = Sty + t * y
            St2y = St2y + t2 * y
        end
        local A = {
            { n, S1, S2, Sy },
            { S1, S2, S3, Sty },
            { S2, S3, S4, St2y },
        }
        for col = 1, 3 do
            local piv = A[col][col]
            if math.abs(piv) < 1e-9 then return nil end
            for r = col + 1, 3 do
                local f = A[r][col] / piv
                for c = col, 4 do
                    A[r][c] = A[r][c] - f * A[col][c]
                end
            end
        end
        local c2 = A[3][4] / A[3][3]
        local b = (A[2][4] - A[2][3] * c2) / A[2][2]
        return b, -2 * c2 -- v0y, gravity
    end

    local function applyCalibration(samples, shotTan, shotDist, weaponKey)
        local n = #samples
        if n < 4 then return end
        local dt = samples[n][1] - samples[1][1]
        if dt < 0.08 then return end

        local ys = {}
        for i = 1, n do
            ys[i] = { samples[i][1], samples[i][2].Y }
        end
        local v0y, g = quadFit(ys)
        if not v0y then return end

        local p0, pN = samples[1][2], samples[n][2]
        local vh = Vector3.new(pN.X - p0.X, 0, pN.Z - p0.Z).Magnitude / dt
        if vh < 20 or vh > 600 then return end

        local p = getProfile(weaponKey or "wood_bow")
        local mix
        if p.n == 0 then
            mix = 1
        elseif p.n < 4 then
            mix = 0.5
        else
            mix = 0.25
        end
        local speed = math.sqrt(vh * vh + v0y * v0y)
        p.spd = p.spd * (1 - mix) + speed * mix
        if g and g > 2 and g < 400 then
            p.g = p.g * (1 - mix) + g * mix
        end
        -- Bias only calibrates from long shots; it is applied distance-scaled and
        -- close shots would just drag it toward zero and ruin the far correction.
        if shotTan and shotDist and shotDist > 60 then
            local bias = (v0y / vh) - shotTan
            if bias > -0.5 and bias < 0.8 then
                p.bias = p.bias * (1 - mix) + bias * mix
            end
        end
        p.n = p.n + 1
        saveCalibration()
    end

    local arrowTracks = {}

    local function scanArrowContainer(container, root, now)
        if not container then return end
        local ok, kids = pcall(function() return container:GetChildren() end)
        if not ok or not kids then return end
        for i = 1, #kids do
            local obj = kids[i]
            if obj and string.find(string.lower(tostring(obj.Name)), "arrow", 1, true) then
                local part
                if obj.ClassName == "Model" then
                    part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                else
                    local okB = false
                    pcall(function() okB = obj:IsA("BasePart") end)
                    if okB then part = obj end
                end
                if part then
                    local pos
                    pcall(function() pos = part.Position end)
                    if pos then
                        local id = getUniqueIdentifier(obj)
                        local tr = arrowTracks[id]
                        if not tr then
                            -- only arrows that appear near us right after our shot
                            if lastShotInfo and now - lastShotInfo.t < 1.0
                                and (pos - root.Position).Magnitude < 30 then
                                arrowTracks[id] = {
                                    t0 = now,
                                    shotTan = lastShotInfo.aimTan,
                                    shotDist = lastShotInfo.dist,
                                    shotWeapon = lastShotInfo.weapon,
                                    samples = { { 0, pos } },
                                    done = false,
                                }
                            end
                        elseif not tr.done then
                            tr.samples[#tr.samples + 1] = { now - tr.t0, pos }
                            if #tr.samples >= 7 or (now - tr.t0) > 0.9 then
                                tr.done = true
                                applyCalibration(tr.samples, tr.shotTan, tr.shotDist, tr.shotWeapon)
                            end
                        end
                    end
                end
            end
        end
    end

    task.spawn(function()
        local prevM1 = false
        while true do
            local active = BW.BowAimbot or BW.SilentBAimbot
            if not active and bowOn and bowOn.IsActivated then
                pcall(function() active = bowOn:IsActivated() end)
            end
            if active then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local now = tick()

                    -- Detect any shot release here so test shots without a target
                    -- are measured too. aimTan only counts if we were aiming just now.
                    local m1 = false
                    pcall(function() m1 = ismouse1() == true end)
                    if prevM1 and not m1 then
                        local aimed = now - lastAimAt < 0.25
                        lastShotInfo = {
                            t = now,
                            aimTan = aimed and lastAimTan or nil,
                            dist = aimed and lastAimDist or nil,
                            weapon = bowWeaponKey(),
                        }
                    end
                    prevM1 = m1

                    -- Scanning the whole Workspace is expensive in Matcha, so only
                    -- do it in a short window after a shot or while a tracked
                    -- arrow is still in flight. Otherwise the GUI/binds lag.
                    local trk = 0
                    local tracking = false
                    for id, tr in pairs(arrowTracks) do
                        if now - tr.t0 > 3 then
                            arrowTracks[id] = nil
                        else
                            trk = trk + 1
                            if not tr.done then tracking = true end
                        end
                    end
                    -- After enough measured shots per weapon the ballistics are
                    -- locked in; stop scanning so shooting causes zero extra load.
                    local wantMore = false
                    if lastShotInfo and lastShotInfo.weapon then
                        wantMore = getProfile(lastShotInfo.weapon).n < 15
                    end
                    if tracking or (wantMore and lastShotInfo and now - lastShotInfo.t < 1.2) then
                        scanArrowContainer(Workspace, root, now)
                        scanArrowContainer(Workspace:FindFirstChild("Projectiles"), root, now)
                        scanArrowContainer(Workspace:FindFirstChild("Ignore"), root, now)
                        scanArrowContainer(Workspace:FindFirstChild("Debris"), root, now)
                    end
                    local wkey = bowWeaponKey()
                    local prof = getProfile(wkey)
                    calDbg = string.format(
                        "%s n=%d trk=%d spd=%.0f g=%.1f bias=%.2f%s",
                        wkey, prof.n, trk, prof.spd, prof.g, prof.bias,
                        calFileOk and " [saved]" or ""
                    )
                end
            end
            task.wait(0.05)
        end
    end)

    local function setBowDebug(a, b, c, d, e)
        bowDbgLines[1] = a or ""
        bowDbgLines[2] = b or ""
        bowDbgLines[3] = c or ""
        bowDbgLines[4] = d or ""
        bowDbgLines[5] = e or ""
        if dbgBox and dbgBox.SetVisible then
            dbgBox:SetVisible(BW.BowDebug == true)
        end
    end

    local function mainLoop()
        if BW.SpeedEnabled then
            local hum = characterHumanoid()
            if hum then
                pcall(function() hum.WalkSpeed = BW.WalkSpeed end)
            end
        end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        Camera = Workspace.CurrentCamera

        local espOn = BW.ResourceEsp or BW.NpcEsp or BW.KitEsp
        if espOn then
            for _, data in pairs(trackedObjects) do
                if data.noDraw or not data.text then
                    -- combat-only track, no drawings
                else
                    local shouldDraw = data.config and data.config.draw and data.config.draw(data.obj)
                    if not shouldDraw or not data.part or not data.part.Parent or not root then
                        hideDraw(data)
                    else
                        local distance = (data.part.Position - root.Position).Magnitude
                        if distance > 500 then
                            hideDraw(data)
                        else
                            local pos, onScreen = WorldToScreen(data.part.Position)
                            if onScreen then
                                local label = data.baseText or ""
                                if data.espType == "iron" or data.espType == "diamond" or data.espType == "emerald" then
                                    local amount = 1
                                    pcall(function() amount = data.obj:GetAttribute("Amount") or 1 end)
                                    label = label .. " (" .. tostring(amount) .. ")"
                                end
                                data.text.Text = label
                                data.text.Position = Vector2.new(pos.X, pos.Y - 7)
                                data.text.Visible = true
                            else
                                hideDraw(data)
                            end
                        end
                    end
                end
            end
        else
            -- ESP switched off: hide immediately instead of waiting for the
            -- slow scanner sweep to remove the entries.
            for _, data in pairs(trackedObjects) do
                hideDraw(data)
            end
        end

        local mx, my = mouseScreenPos()
        local showFov = BW.BowFovCircle == true and (BW.BowAimbot == true)
        if not showFov and bowOn and bowOn.IsActivated then
            pcall(function() showFov = BW.BowFovCircle == true and bowOn:IsActivated() end)
        end
        if fovCircle then
            local radius = BW.BowAimFov or 180
            fovCircle.Position = Vector2.new(mx, my)
            pcall(function() fovCircle.Radius = radius end)
            fovCircle.Visible = showFov == true
        end
        if fovFill and not (BW.BowAimbot or showFov) then
            fovFill.Visible = false
        end

        local bowActive = BW.BowAimbot
        if not bowActive and bowOn and bowOn.IsActivated then
            pcall(function() bowActive = bowOn:IsActivated() end)
        end

        local trackN, playerN, npcN = 0, 0, 0
        for _, data in pairs(trackedObjects) do
            trackN = trackN + 1
            if data.espType == "Player" then playerN = playerN + 1 end
            if data.espType == "Entity" then npcN = npcN + 1 end
        end

        if bowActive then
            local target = closestTargetInFov(BW.BowAimFov or 180, BW.BowTargetNpcs ~= false)
            if target then
                local tname = "?"
                pcall(function() tname = tostring(target.obj.Name) end)
                aimBowCamera(target.part, target.espType == "Entity")
                setBowDebug(
                    "ON  abs=" .. tostring(hasMoveAbs) .. " rel=" .. tostring(hasMoveRel),
                    "target: " .. tname,
                    lastAimInfo,
                    lastSkip .. " | " .. lastMove,
                    "tracked p:" .. playerN .. " npc:" .. npcN .. " npcs=" .. tostring(BW.BowTargetNpcs)
                )
            else
                lastSkip = "no target in FOV"
                if fovFill then fovFill.Visible = false end
                setBowDebug(
                    "ON  abs=" .. tostring(hasMoveAbs) .. " rel=" .. tostring(hasMoveRel),
                    "target: none  mouse=" .. math.floor(mx) .. "," .. math.floor(my),
                    "tracked p:" .. playerN .. " npc:" .. npcN .. " npcs=" .. tostring(BW.BowTargetNpcs),
                    lastSkip,
                    "menu=" .. tostring(Lib.IsOpen and Lib:IsOpen() or false)
                )
            end
        else
            if fovFill then fovFill.Visible = false end
            setBowDebug(
                "OFF  enable toggle or hold E",
                "abs=" .. tostring(hasMoveAbs) .. " rel=" .. tostring(hasMoveRel),
                "tracked p:" .. playerN .. " npc:" .. npcN,
                "rbx=" .. tostring(isrbxactive()),
                "menu=" .. tostring(Lib.IsOpen and Lib:IsOpen() or false)
            )
        end

        if BW.SilentBAimbot and getEquippedBow() then
            -- Matcha logs "FireServer requires hybrid mode" instead of raising a
            -- Lua error, so pcall can't detect the failure. Gate on _G.hybrid
            -- (set by the user in the inject snippet) and never fire without it.
            if not _G.hybrid then
                BW.SilentBAimbot = false
                pcall(function()
                    Lib:Notify("Silent B-Aimbot", "disabled - set _G.hybrid = true before inject (Matcha hybrid mode)", 5, "warning")
                end)
            else
                local target = closestTargetInFov(BW.SilentBAimFov or 220, BW.BowTargetNpcs ~= false)
                if target and ProjectileFire and root and tick() >= silentNextFire then
                    silentNextFire = tick() + 0.25
                    local origin = root.Position
                    local dir = (target.part.Position - origin)
                    if dir.Magnitude > 0.01 then
                        dir = dir.Unit
                        pcall(function()
                            ProjectileFire:FireServer(getEquippedBow(), "arrow", origin, dir)
                        end)
                    end
                elseif target and not ProjectileFire then
                    -- silent has no projectile remote on this build; do not snap the camera
                end
            end
        end
    end

    -- RenderStepped fires right before the frame is drawn, so ESP boxes are
    -- placed with the current camera. On Heartbeat they lag one frame behind
    -- and visibly shake while the camera moves.
    local mainHooked = false
    pcall(function()
        RunService.RenderStepped:Connect(mainLoop)
        mainHooked = true
    end)
    if not mainHooked then
        RunService.Heartbeat:Connect(mainLoop)
    end

    task.spawn(function()
        -- SwordHitEvent:FireServer needs Matcha hybrid mode. Matcha only logs
        -- the failure (no Lua error), so gate on _G.hybrid instead of pcall.
        while true do
            if BW.KillAura and not _G.hybrid then
                BW.KillAura = false
                pcall(function()
                    Lib:Notify("Kill Aura", "disabled - set _G.hybrid = true before inject (Matcha hybrid mode)", 5, "warning")
                end)
            end
            if BW.KillAura then
                local weapon = getAttackWeapon()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if weapon and root and SwordHitEvent then
                    local localfacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
                    local targetsList = {}
                    local range = BW.KillAuraRange or 18

                    for _, data in pairs(trackedObjects) do
                        if data.part and data.part.Parent and data.obj ~= char and data.obj.Name ~= LocalPlayer.Name then
                            local isPlayer = data.espType == "Player"
                            local isEntity = data.espType == "Entity"
                            if isPlayer or isEntity then
                                local humanoid = data.part.Parent:FindFirstChildWhichIsA("Humanoid")
                                if humanoid and humanoid.Health > 0 then
                                    local skip = false
                                    if isPlayer then
                                        local targetPlr = Players:FindFirstChild(data.obj.Name)
                                        if targetPlr and LocalPlayer.Team and targetPlr.Team == LocalPlayer.Team then
                                            skip = true
                                        end
                                    end
                                    if not skip then
                                        local delta = data.part.Position - root.Position
                                        local dist = delta.Magnitude
                                        if dist <= range then
                                            local flat = delta * Vector3.new(1, 0, 1)
                                            if flat.Magnitude > 0.01 then
                                                local angle = math.acos(localfacing:Dot(flat.Unit))
                                                if angle <= math.pi then
                                                    targetsList[#targetsList + 1] = {
                                                        instance = data.part.Parent,
                                                        part = data.part,
                                                        distance = dist,
                                                    }
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    table.sort(targetsList, function(a, b) return a.distance < b.distance end)

                    local targetData = targetsList[1]
                    if targetData then
                        local dir = (targetData.part.Position - root.Position)
                        if dir.Magnitude > 0.01 then
                            dir = dir.Unit
                        end
                        local pos = root.Position + dir * math.max(targetData.distance - 14.399, 0)
                        pcall(function()
                            SwordHitEvent:FireServer({
                                chargedAttack = { chargeRatio = 0 },
                                entityInstance = targetData.instance,
                                validate = {
                                    selfPosition = { value = pos },
                                    targetPosition = { value = targetData.part.Position },
                                },
                                weapon = weapon,
                            })
                        end)
                    end
                elseif BW.KillAura and not SwordHitEvent then
                    refreshRemotes()
                end
            end
            task.wait(0.05)
        end
    end)

    Lib:Notify("Loaded", "lurk.win BedWars ready", 3, "success")
