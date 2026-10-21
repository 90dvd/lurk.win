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

local function ownedByMe(model)
    local names = { "Owner", "owner", "Player", "UserId", "OwnerId" }
    for i = 1, #names do
        local attr
        pcall(function()
            attr = model:GetAttribute(names[i])
        end)
        if samePlayer(attr) then return true end
        local child = model:FindFirstChild(names[i])
        if child then
            local value
            pcall(function()
                value = child.Value
            end)
            if samePlayer(value) then return true end
        end
    end
    return false
end

local function modelPosition(model)
    if not model then return nil end
    local pos
    pcall(function()
        local part = model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("Head")
            or model:FindFirstChildWhichIsA("BasePart")
        if part then pos = part.Position end
    end)
    return pos
end

local function isGoldenMobster(model)
    local name = string.lower(tostring(model.Name))
    return string.find(name, "golden", 1, true) ~= nil
        and string.find(name, "mobster", 1, true) ~= nil
end

local function bountyString(model)
    local level = readNumber(model, {
        "BottomPath", "Bottom", "Path2", "Upgrade2", "PathB", "BottomLevel",
    })
    if not level then
        local config = model:FindFirstChild("Config") or model:FindFirstChild("Upgrades")
        level = readNumber(config, {
            "BottomPath", "Bottom", "Path2", "Upgrade2", "PathB",
        })
    end
    level = math.floor(tonumber(level) or 0)
    if level >= 5 then return BOUNTY_NAME[5], level end
    if level >= 4 then return BOUNTY_NAME[4], level end
    if level >= 3 then return BOUNTY_NAME[3], level end
    return nil, level
end

local function walk(root, depth, budget, visit)
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
            if className == "Folder" or className == "Model" or className == "Configuration" then
                walk(child, depth - 1, budget, visit)
            end
        end
    end
end

local function findTower()
    local owned, any = nil, nil
    walk(Workspace, 6, { 2500 }, function(obj)
        if obj.ClassName == "Model" and isGoldenMobster(obj) then
            any = obj
            if ownedByMe(obj) then
                owned = obj
            end
        end
    end)
    return owned or any
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
    local tower = findTower()
    if not tower then
        note("kein Golden Mobster")
        return
    end
    local abilityName, level = bountyString(tower)
    if not abilityName then
        note("Bottom-Path zu niedrig (" .. tostring(level) .. "), Bounty ab X-3")
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
