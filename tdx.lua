--[[
    TDX Golden Mobster — Place Bounty, fully silent.

    F feuert die Ability an der Mausposition. Kein Keypress, kein Mausklick,
    kein Cursor-Move. Der Aufruf geht über den Ability-String
    (GoldenMobsterBounty1 / 2 / 3), nicht über H oder das Ability-Menü.

    Matcha schickt FireServer nur, wenn im Client Hybrid an ist.
    Das Script prüft _G.hybrid nicht mehr und blockiert F deshalb nicht.
]]

pcall(function()
    local env = getgenv()
    if env.MatchaTdxBountyUnload then
        env.MatchaTdxBountyUnload()
    end
end)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local F_KEY = 0x46
local PICK_RADIUS = 140

-- Bottom-Path X-3 / X-4 / X-5. Die Namen liegen als Module unter
-- ReplicatedStorage.TDX_Share.SFX.Bounty und sind die Ability-Ids.
local BOUNTY_NAME = {
    [3] = "GoldenMobsterBounty1",
    [4] = "GoldenMobsterBounty2",
    [5] = "GoldenMobsterBounty3",
}

local REMOTE_NAMES = {
    "UseAbility", "Ability", "TowerAbility", "RequestAbility",
    "ActivateAbility", "UseTowerAbility", "AbilityRequest", "CastAbility",
}

local alive = true
local busy = false
local abilityRemote = nil
local lookedForRemote = false

local function note(text)
    print("[tdx] " .. tostring(text))
    pcall(function()
        notify(tostring(text), "bounty", 2)
    end)
end

local function unload()
    alive = false
    pcall(function()
        local env = getgenv()
        if env.MatchaTdxBountyUnload == unload then
            env.MatchaTdxBountyUnload = nil
        end
    end)
end

pcall(function()
    getgenv().MatchaTdxBountyUnload = unload
end)

local function isPressed(vk)
    local down = false
    pcall(function()
        down = iskeypressed(vk) == true
    end)
    return down
end

local function robloxFocused()
    local on = true
    pcall(function()
        on = isrbxactive() == true
    end)
    return on
end

local function readNumber(inst, names)
    if not inst then return nil end
    for i = 1, #names do
        local name = names[i]
        local attr
        pcall(function()
            attr = inst:GetAttribute(name)
        end)
        if type(attr) == "number" then return attr end
        local child = inst:FindFirstChild(name)
        if child then
            local value
            pcall(function()
                value = child.Value
            end)
            if type(value) == "number" then return value end
        end
    end
    return nil
end

local function samePlayer(value)
    if value == nil then return false end
    if value == LocalPlayer then return true end
    local asString = tostring(value)
    if asString == LocalPlayer.Name then return true end
    local userId = LocalPlayer.UserId
    if userId ~= nil and (value == userId or asString == tostring(userId)) then
        return true
    end
    return false
end

local OWNER_KEYS = {
    "Owner", "owner", "Player", "UserId", "OwnerId",
    "OwnerUserId", "PlacedBy", "PlacedByUserId", "Creator", "OwnerName",
}

local function readOwnerValue(inst)
    if not inst then return nil end
    for i = 1, #OWNER_KEYS do
        local key = OWNER_KEYS[i]
        local attr
        pcall(function()
            attr = inst:GetAttribute(key)
        end)
        if attr ~= nil then return attr end
        local child = inst:FindFirstChild(key)
        if child then
            local value
            pcall(function()
                value = child.Value
            end)
            if value ~= nil then return value end
        end
    end
    return nil
end

local function playerFromValue(value)
    if value == nil then return nil end
    if value == LocalPlayer then return LocalPlayer end
    local className
    pcall(function()
        className = value.ClassName
    end)
    if className == "Player" then return value end
    local wanted = tostring(value)
    local list
    pcall(function()
        list = Players:GetPlayers()
    end)
    if not list then return nil end
    for i = 1, #list do
        local player = list[i]
        if player == value or player.Name == wanted or tostring(player.UserId) == wanted then
            return player
        end
    end
    return nil
end

local function sameTeam(player)
    if not player or player == LocalPlayer then return false end
    local mine, theirs
    pcall(function()
        mine = LocalPlayer.Team
    end)
    pcall(function()
        theirs = player.Team
    end)
    if mine ~= nil and theirs ~= nil then
        return mine == theirs
    end
    return true
end

-- "mine" / "teammate" / "other" / "unknown", plus Anzeigename.
local function classify(model)
    local value = readOwnerValue(model)
    if value == nil then
        local data = model:FindFirstChild("Data")
            or model:FindFirstChild("Config")
            or model:FindFirstChild("Info")
        value = readOwnerValue(data)
    end
    if value == nil then
        local node = model.Parent
        for _ = 1, 5 do
            if not node or node == Workspace or node == game then break end
            if samePlayer(node.Name) then
                return "mine", LocalPlayer.Name
            end
            local player = playerFromValue(node.Name)
            if player and player ~= LocalPlayer then
                if sameTeam(player) then return "teammate", player.Name end
                return "other", player.Name
            end
            node = node.Parent
        end
        return "unknown", "?"
    end
    if samePlayer(value) then return "mine", LocalPlayer.Name end
    local player = playerFromValue(value)
    if player and player ~= LocalPlayer then
        if sameTeam(player) then return "teammate", player.Name end
        return "other", player.Name
    end
    return "other", tostring(value)
end

local function modelPosition(model)
    if not model then return nil end
    local pos
    pcall(function()
        if model.ClassName == "Part" or model.ClassName == "MeshPart" or model.ClassName == "UnionOperation" then
            pos = model.Position
            return
        end
        local part = model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("Head")
            or model:FindFirstChildWhichIsA("BasePart")
        if part then pos = part.Position end
    end)
    return pos
end

local function textIsGoldenMobster(text)
    if text == nil then return false end
    local name = string.lower(tostring(text))
    local compact = string.gsub(name, "%s+", "")
    if string.find(compact, "goldenmobster", 1, true) then return true end
    return string.find(name, "golden", 1, true) ~= nil
        and string.find(name, "mobster", 1, true) ~= nil
end

local HINT_KEYS = {
    "TowerName", "Tower", "Type", "TowerType", "DisplayName",
    "UnitName", "Name", "Id", "TowerId",
}

local function isTowerInstance(obj)
    local className = obj.ClassName
    return className == "Model" or className == "Folder" or className == "Part"
        or className == "MeshPart" or className == "UnionOperation"
end

local function isGoldenMobster(model)
    if textIsGoldenMobster(model.Name) then return true end
    for i = 1, #HINT_KEYS do
        local key = HINT_KEYS[i]
        local attr
        pcall(function()
            attr = model:GetAttribute(key)
        end)
        if textIsGoldenMobster(attr) then return true end
        local child = model:FindFirstChild(key)
        if child then
            local value
            pcall(function()
                value = child.Value
            end)
            if textIsGoldenMobster(value) then return true end
        end
    end
    local data = model:FindFirstChild("Data")
        or model:FindFirstChild("Config")
        or model:FindFirstChild("Info")
        or model:FindFirstChild("Settings")
    if not data then return false end
    for i = 1, #HINT_KEYS do
        local child = data:FindFirstChild(HINT_KEYS[i])
        if child then
            local value
            pcall(function()
                value = child.Value
            end)
            if textIsGoldenMobster(value) or textIsGoldenMobster(child.Name) then
                return true
            end
        end
    end
    return false
end

local function visitValues(inst, fn, depth)
    if not inst or depth < 0 then return end
    pcall(function()
        local attrs = inst:GetAttributes()
        if type(attrs) == "table" then
            for key, value in pairs(attrs) do
                fn(tostring(key), value)
            end
        end
    end)
    local kids
    pcall(function()
        kids = inst:GetChildren()
    end)
    if not kids then return end
    for i = 1, #kids do
        local child = kids[i]
        local value
        local ok = pcall(function()
            value = child.Value
        end)
        if ok and value ~= nil then
            fn(tostring(child.Name), value)
        end
        local className = child.ClassName
        if depth > 0 and (className == "Folder" or className == "Configuration") then
            visitValues(child, fn, depth - 1)
        end
    end
end

-- Pfad ist oben-unten. 2-3 bedeutet 2 Upgrades oben und 3 unten.
-- Eine einzelne Model-Zahl zaehlt als oben, Base ist 0-0.
local function isDigits(s)
    if s == nil or s == "" then return false end
    local i = 1
    while true do
        local c = string.sub(s, i, i)
        if c == "" then return true end
        if c < "0" or c > "9" then return false end
        i = i + 1
        if i > 8 then return false end
    end
end

local function pairFromText(text)
    local s = tostring(text)
    local dash = string.find(s, "-", 1, true)
    if not dash or dash == 1 then return nil, nil, false end
    local left = string.sub(s, 1, dash - 1)
    local right = string.sub(s, dash + 1)
    if right == "" or string.find(right, "-", 1, true) then return nil, nil, false end
    if string.lower(left) == "x" and isDigits(right) then
        return nil, tonumber(right), true
    end
    if isDigits(left) and isDigits(right) then
        return tonumber(left), tonumber(right), true
    end
    return nil, nil, false
end

local function considerPathText(text, state)
    if state.explicit then return end
    local top, bot, ok = pairFromText(text)
    if not ok then return end
    if top ~= nil then state.top = top end
    if bot ~= nil then state.bot = bot end
    state.explicit = true
end

local function considerPathKey(name, value, state)
    local n = string.lower(tostring(name))
    if type(value) == "string" then
        considerPathText(value, state)
        return
    end
    if type(value) ~= "number" then return end
    local isTop = string.find(n, "top", 1, true) or n == "path1" or n == "upgrade1"
    local isBot = string.find(n, "bottom", 1, true) or n == "path2" or n == "upgrade2"
    if isTop and not isBot then
        state.top = value
        state.explicit = true
    elseif isBot and not isTop then
        state.bot = value
        state.explicit = true
    end
end

local function walkPath(inst, depth, state)
    if not inst or depth < 0 then return end
    considerPathText(inst.Name, state)
    pcall(function()
        local attrs = inst:GetAttributes()
        if type(attrs) == "table" then
            for key, value in pairs(attrs) do
                considerPathKey(key, value, state)
            end
        end
    end)
    local kids
    pcall(function()
        kids = inst:GetChildren()
    end)
    if not kids then return end
    for i = 1, #kids do
        local child = kids[i]
        local value
        local ok = pcall(function()
            value = child.Value
        end)
        if ok and value ~= nil then
            considerPathKey(child.Name, value, state)
        end
        local className = child.ClassName
        if className == "TextLabel" or className == "TextButton" or className == "TextBox" then
            local text
            pcall(function()
                text = child.Text
            end)
            if text then considerPathText(text, state) end
        end
        if depth > 0 and (className == "Model" or className == "Folder" or className == "Configuration" or className == "BillboardGui" or className == "SurfaceGui") then
            walkPath(child, depth - 1, state)
        end
    end
end

local function skinPath(model)
    local kids
    pcall(function()
        kids = model:GetChildren()
    end)
    if not kids then return nil, nil end
    for i = 1, #kids do
        if kids[i].ClassName == "Model" then
            local name = tostring(kids[i].Name)
            local top, bot, ok = pairFromText(name)
            if ok then return top or 0, bot or 0 end
            if string.lower(name) == "base" then return 0, 0 end
            if isDigits(name) then return tonumber(name), 0 end
        end
    end
    return nil, nil
end

local function readPath(model)
    local state = {}
    walkPath(model, 4, state)
    if not state.explicit then
        local skinTop, skinBot = skinPath(model)
        if state.top == nil then state.top = skinTop end
        if state.bot == nil then state.bot = skinBot end
    end
    if state.top ~= nil then state.top = math.floor(state.top) end
    if state.bot ~= nil then state.bot = math.floor(state.bot) end
    return state.top, state.bot
end

local function bountyString(model)
    local _, bot = readPath(model)
    if bot == nil then return nil end
    if bot >= 5 then return BOUNTY_NAME[5] end
    if bot >= 4 then return BOUNTY_NAME[4] end
    if bot >= 3 then return BOUNTY_NAME[3] end
    return nil
end

local MAP_SKIP = {
    map = true, terrain = true, baseplate = true, lighting = true,
    effects = true, debris = true,     enemies = true, enemy = true,
    zombies = true, projectiles = true, paths = true, path = true,
    pathentities = true, placementprobes = true, spaceoccupiers = true,
    staticentities = true, raycastignore = true, mapentities = true,
    soundfolder = true, map = true, cutscenes = true,
    environment = true, decor = true, decorations = true, lobby = true,
    camera = true, background = true, fx = true,
}

local function walk(root, depth, budget, visit, skip)
    if not root or depth < 0 or budget[1] <= 0 then return end
    local ok, kids = pcall(function()
        return root:GetChildren()
    end)
    if not ok or not kids then return end
    for i = 1, #kids do
        if budget[1] <= 0 then return end
        budget[1] = budget[1] - 1
        local child = kids[i]
        if child then
            visit(child)
            local className = child.ClassName
            local skipped = skip and skip[string.lower(tostring(child.Name))]
            if not skipped and (className == "Folder" or className == "Model" or className == "Configuration") then
                walk(child, depth - 1, budget, visit, skip)
            end
        end
    end
end

local function bountyInfo(model)
    local top, bot = readPath(model)
    local ability = bountyString(model)
    local tier
    if ability == BOUNTY_NAME[3] then tier = 1
    elseif ability == BOUNTY_NAME[4] then tier = 2
    elseif ability == BOUNTY_NAME[5] then tier = 3
    end
    return tier, ability, top, bot
end

local function logLine(text)
    print("[tdx] " .. tostring(text))
end

local function pathText(top, bot)
    if top == nil and bot == nil then return "?" end
    return tostring(top or 0) .. "-" .. tostring(bot or 0)
end

local function logScan(rows)
    local mine = {}
    local teammates = 0
    for i = 1, #rows do
        local row = rows[i]
        if row.kind == "mine" or row.kind == "unknown" then
            mine[#mine + 1] = row
        elseif row.kind == "teammate" then
            teammates = teammates + 1
        end
    end

    logLine("eigene Golden Mobster: " .. tostring(#mine))
    logLine("teammates: " .. tostring(teammates))
    for i = 1, #mine do
        local row = mine[i]
        local prefix = #mine == 1 and "eigener" or ("eigener " .. tostring(i))
        logLine(prefix .. ": " .. pathText(row.top, row.bot))
    end
end

local TOWER_FOLDERS = { "Towers", "TowerFolder", "PlacedTowers", "PlayerTowers", "Buildings" }
local reportedLayout = false
-- Explorer-Adresse aus dieser Session, nur um den echten Pfad zu finden.
local TARGET_ADDR = tonumber("1AFB915D800", 16)

local function readAddress(obj)
    local addr
    pcall(function()
        addr = obj.Address
    end)
    if type(addr) == "number" then return addr end
    if type(addr) == "string" then
        local hex = string.gsub(addr, "^0[xX]", "")
        return tonumber(hex, 16)
    end
    return nil
end

local function instancePath(obj)
    local parts = {}
    local node = obj
    for _ = 1, 14 do
        if not node then break end
        table.insert(parts, 1, tostring(node.Name))
        if node == Workspace or node == ReplicatedStorage or node == game then break end
        local parent
        pcall(function()
            parent = node.Parent
        end)
        node = parent
    end
    return table.concat(parts, ".")
end

local function childNames(root, limit)
    local names = {}
    local kids
    pcall(function()
        kids = root:GetChildren()
    end)
    if not kids then return "" end
    for i = 1, math.min(#kids, limit or 16) do
        names[#names + 1] = tostring(kids[i].Name)
    end
    return table.concat(names, ", ")
end

local function scanTowers()
    local rows, seen = {}, {}
    local function consider(obj)
        if not obj or seen[obj] then return end
        if not isTowerInstance(obj) then return end
        if obj == LocalPlayer.Character then return end
        if not isGoldenMobster(obj) then return end
        if obj.ClassName == "Folder" then
            local kids
            pcall(function()
                kids = obj:GetChildren()
            end)
            if kids then
                for i = 1, #kids do
                    local child = kids[i]
                    if child.ClassName == "Model" and isGoldenMobster(child) then
                        return
                    end
                end
            end
        end
        seen[obj] = true
        local kind, ownerName = classify(obj)
        if kind == "unknown" then
            local ownerValue
            visitValues(obj, function(name, value)
                if ownerValue ~= nil then return end
                local n = string.lower(name)
                if string.find(n, "owner", 1, true) or n == "userid" or n == "player" or n == "placedby" then
                    ownerValue = value
                end
            end, 2)
            if ownerValue ~= nil then
                if samePlayer(ownerValue) then
                    kind, ownerName = "mine", LocalPlayer.Name
                else
                    local player = playerFromValue(ownerValue)
                    if player and player ~= LocalPlayer and sameTeam(player) then
                        kind, ownerName = "teammate", player.Name
                    else
                        kind, ownerName = "other", tostring(player and player.Name or ownerValue)
                    end
                end
            end
        end
        local tier, ability, top, bot = bountyInfo(obj)
        rows[#rows + 1] = {
            model = obj,
            kind = kind,
            ownerName = ownerName,
            tier = tier,
            ability = ability,
            top = top,
            bot = bot,
        }
    end

    local gameFolder = Workspace:FindFirstChild("Game")
    local towersFolder = gameFolder and gameFolder:FindFirstChild("Towers")
    if towersFolder then
        local kids
        pcall(function()
            kids = towersFolder:GetChildren()
        end)
        if kids then
            for i = 1, #kids do
                consider(kids[i])
            end
        end
    end

    local unique = {}
    for i = 1, #rows do
        local pos = modelPosition(rows[i].model)
        local dup = false
        if pos then
            for j = 1, #unique do
                local other = modelPosition(unique[j].model)
                if other then
                    local dx = pos.X - other.X
                    local dy = pos.Y - other.Y
                    local dz = pos.Z - other.Z
                    if dx * dx + dy * dy + dz * dz < 1 then
                        dup = true
                        break
                    end
                end
            end
        end
        if not dup then
            unique[#unique + 1] = rows[i]
        end
    end
    rows = unique

    logScan(rows)

    local owned, unknown, foreign = nil, nil, false
    for i = 1, #rows do
        local row = rows[i]
        if row.kind == "mine" and row.tier then
            owned = row.model
            break
        end
        if row.kind == "mine" and not owned then
            owned = row.model
        elseif row.kind == "unknown" then
            unknown = unknown or row.model
        elseif row.kind == "teammate" or row.kind == "other" then
            foreign = true
        end
    end
    if owned then return owned end
    if unknown and not foreign then return unknown end
    if not reportedLayout and #rows == 0 and not gameFolder then
        reportedLayout = true
    end
    return nil
end

-- Mausposition, ohne den Cursor anzufassen.
-- Mouse.Hit ist in Matcha oft nicht da. Dann der Gegner, der auf dem
-- Bildschirm am nächsten am Cursor liegt.
local function mouseWorld(mouse)
    local hit
    pcall(function()
        hit = mouse.Hit
    end)
    if hit ~= nil then
        local pos
        pcall(function()
            pos = hit.Position
        end)
        if typeof(pos) == "Vector3" then return pos end
        if typeof(hit) == "Vector3" then return hit end
    end

    local mx, my = mouse.X, mouse.Y
    local best, bestDist
    walk(Workspace, 8, { 4000 }, function(obj)
        if obj.ClassName ~= "Model" or obj == LocalPlayer.Character then return end
        if isGoldenMobster(obj) then return end
        local hum = obj:FindFirstChild("Humanoid")
        if not hum then return end
        local hp = 1
        pcall(function()
            hp = hum.Health
        end)
        if hp ~= nil and hp <= 0 then return end
        local pos = modelPosition(obj)
        if not pos then return end
        local screen, onScreen = WorldToScreen(pos)
        if not onScreen or not screen then return end
        local dx, dy = screen.X - mx, screen.Y - my
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= PICK_RADIUS and (not bestDist or dist < bestDist) then
            bestDist = dist
            best = pos
        end
    end)
    return best
end

local function remoteByName(root, name)
    if not root then return nil end
    local direct = root:FindFirstChild(name)
    if direct and (direct.ClassName == "RemoteEvent" or direct.ClassName == "RemoteFunction") then
        return direct
    end
    local found
    walk(root, 8, { 4000 }, function(obj)
        if found then return end
        if obj.Name == name and (obj.ClassName == "RemoteEvent" or obj.ClassName == "RemoteFunction") then
            found = obj
        end
    end)
    return found
end

local function abilityCandidates()
    local list = {}
    local function consider(obj)
        if obj.ClassName ~= "RemoteEvent" and obj.ClassName ~= "RemoteFunction" then return end
        local name = string.lower(obj.Name)
        if string.find(name, "ability", 1, true) or string.find(name, "skill", 1, true) then
            list[#list + 1] = obj
        end
    end
    walk(ReplicatedStorage, 8, { 5000 }, consider)
    return list
end

local function getAbilityRemote()
    if abilityRemote then return abilityRemote end
    local roots = {
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("TDX_Share"),
        ReplicatedStorage,
    }
    for r = 1, #roots do
        for i = 1, #REMOTE_NAMES do
            local remote = remoteByName(roots[r], REMOTE_NAMES[i])
            if remote then
                abilityRemote = remote
                return remote
            end
        end
    end
    if not lookedForRemote then
        lookedForRemote = true
        local found = abilityCandidates()
        if #found == 1 then
            abilityRemote = found[1]
            return found[1]
        end
        if #found == 0 then
            note("kein Ability-Remote unter ReplicatedStorage")
        else
            local names = {}
            for i = 1, #found do
                names[i] = found[i].Name
            end
            note("Ability-Remote unklar: " .. table.concat(names, ", "))
        end
    end
    return nil
end

local function fireAbility(remote, tower, abilityName, position)
    local sent = false
    local err
    local function attempt(fn)
        if sent then return end
        local ok, callErr = pcall(fn)
        if ok then
            sent = true
        else
            err = callErr
        end
    end
    if remote.ClassName == "RemoteFunction" then
        attempt(function()
            remote:InvokeServer(tower, abilityName, position)
        end)
        attempt(function()
            remote:InvokeServer(abilityName, position, tower)
        end)
    else
        attempt(function()
            remote:FireServer(tower, abilityName, position)
        end)
        attempt(function()
            remote:FireServer(abilityName, position, tower)
        end)
    end
    return sent, err
end

local function castAtMouse()
    local tower = scanTowers()
    if not tower then
        return
    end
    local abilityName = bountyString(tower)
    if not abilityName then
        return
    end
    local position = mouseWorld(LocalPlayer:GetMouse())
    if not position then
        note("keine Mausposition")
        return
    end
    local remote = getAbilityRemote()
    if not remote then return end
    local sent, err = fireAbility(remote, tower, abilityName, position)
    if sent then
        note(abilityName .. " @ " .. remote.Name)
    else
        note("send fehlgeschlagen: " .. tostring(err))
    end
end

task.spawn(function()
    local lastDown = false
    while alive do
        local down = isPressed(F_KEY) and robloxFocused()
        if down and not lastDown and not busy then
            busy = true
            pcall(castAtMouse)
            busy = false
        end
        lastDown = down
        task.wait()
    end
end)
