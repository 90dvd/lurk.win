--[[
    Matcha Simple Autoclicker

    Voraussetzungen:
      - Matcha LuaVM
      - Drawing API

    Bedienung:
      1. "General" einschalten.
      2. Mit Min- und Max-Slider eine CPS-Spanne von 1 bis 100 wählen.
         Jeder Klick bekommt eine zufällige Rate dazwischen.
      3. Auf das Keybind-Feld klicken und eine Taste drücken.
      4. Die gewählte Taste schaltet den Autoclicker an/aus.
      5. P blendet dieses Fenster ein und aus.

    Wichtig:
      Der Autoclicker klickt nur, wenn General UND Keybind-Status aktiv sind.
]]

-- Bei erneutem Inject die vorherige Instanz sauber beenden.
pcall(function()
    local env = getgenv()
    if env.MatchaSimpleAutoclickerUnload then
        env.MatchaSimpleAutoclickerUnload()
    end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local MIN_CPS = 1
local MAX_CPS = 100
local cpsMin = 8
local cpsMax = 14
local bindKey = 0x75 -- F6
local UI_KEY = 0x50 -- P

local alive = true
local uiVisible = true
local generalEnabled = false
local bindEnabled = false
local listeningForBind = false
local draggingWindow = false
local draggingWhich = nil -- "min" oder "max"
local injectingClick = false

local windowX, windowY = 160, 120
local windowW, windowH = 400, 318
local dragOffsetX, dragOffsetY = 0, 0

local COLOR_BG = Color3.fromRGB(18, 20, 26)
local COLOR_PANEL = Color3.fromRGB(26, 29, 38)
local COLOR_ROW = Color3.fromRGB(34, 38, 49)
local COLOR_ACCENT = Color3.fromRGB(117, 92, 255)
local COLOR_ACCENT_DIM = Color3.fromRGB(73, 61, 145)
local COLOR_GREEN = Color3.fromRGB(76, 210, 139)
local COLOR_RED = Color3.fromRGB(235, 84, 96)
local COLOR_TEXT = Color3.fromRGB(240, 242, 248)
local COLOR_MUTED = Color3.fromRGB(151, 157, 174)
local COLOR_TRACK = Color3.fromRGB(49, 54, 68)

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function inside(px, py, rect)
    return px >= rect[1] and px <= rect[1] + rect[3]
        and py >= rect[2] and py <= rect[2] + rect[4]
end

local KEY_NAMES = {
    [0x08] = "BACKSPACE", [0x09] = "TAB", [0x0D] = "ENTER",
    [0x10] = "SHIFT", [0x11] = "CTRL", [0x12] = "ALT",
    [0x14] = "CAPS", [0x1B] = "ESC", [0x20] = "SPACE",
    [0x21] = "PAGE UP", [0x22] = "PAGE DOWN",
    [0x23] = "END", [0x24] = "HOME",
    [0x25] = "LEFT", [0x26] = "UP", [0x27] = "RIGHT", [0x28] = "DOWN",
    [0x2D] = "INSERT", [0x2E] = "DELETE",
    [0x70] = "F1", [0x71] = "F2", [0x72] = "F3", [0x73] = "F4",
    [0x74] = "F5", [0x75] = "F6", [0x76] = "F7", [0x77] = "F8",
    [0x78] = "F9", [0x79] = "F10", [0x7A] = "F11", [0x7B] = "F12",
}

local function keyName(vk)
    if not vk then return "NONE" end
    if KEY_NAMES[vk] then return KEY_NAMES[vk] end
    if vk >= 0x30 and vk <= 0x39 then return string.char(vk) end
    if vk >= 0x41 and vk <= 0x5A then return string.char(vk) end
    if vk >= 0x60 and vk <= 0x69 then return "NUM " .. tostring(vk - 0x60) end
    return "VK " .. tostring(vk)
end

-- Matcha liefert keine Textbreite. System-Schrift ist ungefähr so breit.
local function textWidth(value, size)
    return #tostring(value) * (size or 13) * 0.62
end

local drawings = {}

local function register(object)
    drawings[#drawings + 1] = object
    return object
end

local function square(color, z)
    local object = register(Drawing.new("Square"))
    object.Filled = true
    object.Color = color
    object.Transparency = 1
    object.ZIndex = z or 1
    object.Visible = true
    pcall(function() object.Corner = 8 end)
    return object
end

local function text(value, color, size, z)
    local object = register(Drawing.new("Text"))
    object.Text = value
    object.Color = color
    -- Matcha Text.Size ist die Schriftgröße. FontSize existiert hier nicht.
    object.Size = size or 13
    object.Outline = false
    object.Center = false
    object.ZIndex = z or 3
    object.Visible = true
    pcall(function() object.Font = Drawing.Fonts.System end)
    return object
end

local function circle(color, z)
    local object = register(Drawing.new("Circle"))
    object.Filled = true
    object.Color = color
    object.Transparency = 1
    object.NumSides = 24
    object.ZIndex = z or 4
    object.Visible = true
    return object
end

local shadow = square(Color3.fromRGB(8, 9, 12), 1)
shadow.Transparency = 0.55
local background = square(COLOR_BG, 2)
local header = square(COLOR_PANEL, 3)
local title = text("MATCHA AUTOCLICKER", COLOR_TEXT, 15, 5)
local subtitle = text("P toggles this window", COLOR_MUTED, 11, 5)
local closeButton = square(COLOR_ROW, 4)
local closeText = text("X", COLOR_MUTED, 13, 6)
closeText.Center = true

local generalRow = square(COLOR_ROW, 3)
local generalLabel = text("General", COLOR_TEXT, 14, 5)
local generalHint = text("Master switch", COLOR_MUTED, 11, 5)
local generalSwitch = square(COLOR_TRACK, 4)
local generalKnob = circle(COLOR_TEXT, 5)

local minLabel = text("Min CPS", COLOR_TEXT, 13, 5)
local minValue = text("8", COLOR_ACCENT, 13, 5)
local minTrack = square(COLOR_TRACK, 3)
local minFill = square(COLOR_ACCENT, 4)
local minKnob = circle(COLOR_TEXT, 5)

local maxLabel = text("Max CPS", COLOR_TEXT, 13, 5)
local maxValue = text("14", COLOR_ACCENT, 13, 5)
local maxTrack = square(COLOR_TRACK, 3)
local maxFill = square(COLOR_ACCENT, 4)
local maxKnob = circle(COLOR_TEXT, 5)

local bindLabel = text("Toggle key", COLOR_TEXT, 14, 5)
local bindButton = square(COLOR_ROW, 3)
local bindText = text("F6", COLOR_TEXT, 13, 6)
bindText.Center = true

local statusDot = circle(COLOR_RED, 5)
local statusText = text("DISABLED", COLOR_MUTED, 12, 5)
local footerText = text("Random CPS between min and max", COLOR_MUTED, 11, 5)

local function removeDrawings()
    for i = 1, #drawings do
        pcall(function() drawings[i]:Remove() end)
    end
end

local function unload()
    if not alive then return end
    alive = false
    generalEnabled = false
    bindEnabled = false
    removeDrawings()
    pcall(function()
        local env = getgenv()
        if env.MatchaSimpleAutoclickerUnload == unload then
            env.MatchaSimpleAutoclickerUnload = nil
        end
    end)
end

pcall(function()
    getgenv().MatchaSimpleAutoclickerUnload = unload
end)

local function setPosition(object, x, y)
    object.Position = Vector2.new(math.floor(x + 0.5), math.floor(y + 0.5))
end

local function setSize(object, w, h)
    object.Size = Vector2.new(math.max(1, math.floor(w + 0.5)), math.max(1, math.floor(h + 0.5)))
end

-- Ein Layout für Zeichnen und Klicks, damit Hitboxen an den Formen bleiben.
local function metrics()
    local x, y, w = windowX, windowY, windowW
    local pad = 16
    local trackX = x + pad
    local trackW = w - pad * 2
    local generalY = y + 64
    local generalH = 48
    local minLabelY = generalY + generalH + 16
    local minTrackY = minLabelY + 24
    local maxLabelY = minTrackY + 28
    local maxTrackY = maxLabelY + 24
    local bindY = maxTrackY + 28
    local bindH = 34
    local footY = bindY + bindH + 16
    return {
        close = { x + w - pad - 28, y + 12, 28, 28 },
        header = { x, y, w, 54 },
        general = { x + 14, generalY, w - 28, generalH },
        switch = { x + w - pad - 46, generalY + (generalH - 22) / 2, 46, 22 },
        minTrack = { trackX, minTrackY, trackW, 6 },
        minHit = { trackX - 10, minTrackY - 12, trackW + 20, 30 },
        maxTrack = { trackX, maxTrackY, trackW, 6 },
        maxHit = { trackX - 10, maxTrackY - 12, trackW + 20, 30 },
        bind = { x + w - pad - 118, bindY, 118, bindH },
        minLabelY = minLabelY,
        maxLabelY = maxLabelY,
        bindY = bindY,
        footY = footY,
    }
end

local function fraction(value)
    return (value - MIN_CPS) / (MAX_CPS - MIN_CPS)
end

local function cpsFromMouse(mx, track)
    local f = clamp((mx - track[1]) / track[3], 0, 1)
    return math.floor(MIN_CPS + f * (MAX_CPS - MIN_CPS) + 0.5)
end

local function drawSlider(trackObj, fillObj, knobObj, track, value)
    local f = fraction(value)
    setPosition(trackObj, track[1], track[2])
    setSize(trackObj, track[3], track[4])
    setPosition(fillObj, track[1], track[2])
    setSize(fillObj, math.max(2, track[3] * f), track[4])
    knobObj.Radius = 7
    -- Circle.Position ist die Mitte.
    setPosition(knobObj, track[1] + track[3] * f, track[2] + track[4] / 2)
end

local function render()
    local m = metrics()
    local show = uiVisible

    setPosition(shadow, windowX + 6, windowY + 8)
    setSize(shadow, windowW, windowH)
    setPosition(background, windowX, windowY)
    setSize(background, windowW, windowH)
    setPosition(header, m.header[1], m.header[2])
    setSize(header, m.header[3], m.header[4])

    setPosition(title, windowX + 16, windowY + 10)
    setPosition(subtitle, windowX + 16, windowY + 30)
    setPosition(closeButton, m.close[1], m.close[2])
    setSize(closeButton, m.close[3], m.close[4])
    setPosition(closeText, m.close[1] + m.close[3] / 2, m.close[2] + 6)

    setPosition(generalRow, m.general[1], m.general[2])
    setSize(generalRow, m.general[3], m.general[4])
    setPosition(generalLabel, windowX + 28, m.general[2] + 8)
    setPosition(generalHint, windowX + 28, m.general[2] + 26)
    setPosition(generalSwitch, m.switch[1], m.switch[2])
    setSize(generalSwitch, m.switch[3], m.switch[4])
    generalSwitch.Color = generalEnabled and COLOR_ACCENT or COLOR_TRACK
    generalKnob.Radius = 8
    local knobX = generalEnabled and (m.switch[1] + m.switch[3] - 12) or (m.switch[1] + 12)
    setPosition(generalKnob, knobX, m.switch[2] + m.switch[4] / 2)

    minValue.Text = tostring(cpsMin)
    setPosition(minLabel, windowX + 16, m.minLabelY)
    setPosition(minValue, windowX + windowW - 16 - textWidth(minValue.Text, 13), m.minLabelY)
    drawSlider(minTrack, minFill, minKnob, m.minTrack, cpsMin)

    maxValue.Text = tostring(cpsMax)
    setPosition(maxLabel, windowX + 16, m.maxLabelY)
    setPosition(maxValue, windowX + windowW - 16 - textWidth(maxValue.Text, 13), m.maxLabelY)
    drawSlider(maxTrack, maxFill, maxKnob, m.maxTrack, cpsMax)

    setPosition(bindLabel, windowX + 16, m.bindY + 8)
    setPosition(bindButton, m.bind[1], m.bind[2])
    setSize(bindButton, m.bind[3], m.bind[4])
    bindButton.Color = listeningForBind and COLOR_ACCENT_DIM or COLOR_ROW
    bindText.Text = listeningForBind and "PRESS A KEY" or keyName(bindKey)
    setPosition(bindText, m.bind[1] + m.bind[3] / 2, m.bind[2] + 9)

    if generalEnabled and bindEnabled then
        statusDot.Color = COLOR_GREEN
        statusText.Color = COLOR_GREEN
        statusText.Text = "CLICKING"
    elseif generalEnabled then
        statusDot.Color = COLOR_ACCENT
        statusText.Color = COLOR_ACCENT
        statusText.Text = "ARMED"
    else
        statusDot.Color = COLOR_RED
        statusText.Color = COLOR_MUTED
        statusText.Text = "DISABLED"
    end

    setPosition(statusDot, windowX + 22, m.footY + 7)
    statusDot.Radius = 4
    setPosition(statusText, windowX + 34, m.footY)
    setPosition(footerText, windowX + 34 + textWidth(statusText.Text, 12) + 14, m.footY + 1)

    for i = 1, #drawings do
        drawings[i].Visible = show
    end
end

local function pointerOverWindow(mx, my)
    if not uiVisible then return false end
    return mx >= windowX and mx <= windowX + windowW
        and my >= windowY and my <= windowY + windowH
end

local function allowedBind(vk)
    if vk == UI_KEY then return false end
    if vk >= 0x30 and vk <= 0x39 then return true end
    if vk >= 0x41 and vk <= 0x5A then return true end
    if vk >= 0x60 and vk <= 0x69 then return true end
    if vk >= 0x70 and vk <= 0x7B then return true end
    return vk == 0x09 or vk == 0x20 or (vk >= 0x21 and vk <= 0x28)
        or vk == 0x2D or vk == 0x2E
end

local function randomInterval()
    local lo, hi = cpsMin, cpsMax
    if hi < lo then lo, hi = hi, lo end
    local rate = lo
    if hi > lo then
        rate = lo + math.random() * (hi - lo)
    end
    if rate < 1 then rate = 1 end
    return 1 / rate
end

task.spawn(function()
    local lastMouseDown = false
    local lastUiKey = false
    local captureStartedAt = 0

    while alive do
        local mx, my = Mouse.X, Mouse.Y
        local mouseDown = false
        pcall(function() mouseDown = ismouse1pressed() == true end)
        if injectingClick then mouseDown = false end
        local mousePressed = mouseDown and not lastMouseDown

        local uiKey = false
        pcall(function() uiKey = iskeypressed(UI_KEY) == true end)
        local rbxOn = false
        pcall(function() rbxOn = isrbxactive() == true end)
        if uiKey and not lastUiKey and rbxOn then
            uiVisible = not uiVisible
            if not uiVisible then
                draggingWindow = false
                draggingWhich = nil
                listeningForBind = false
            end
        end
        lastUiKey = uiKey

        if uiVisible and listeningForBind then
            if tick() - captureStartedAt > 0.15 then
                if iskeypressed(0x1B) then
                    bindKey = nil
                    bindEnabled = false
                    listeningForBind = false
                else
                    for vk = 0x08, 0xFE do
                        if allowedBind(vk) and iskeypressed(vk) then
                            bindKey = vk
                            bindEnabled = false
                            listeningForBind = false
                            break
                        end
                    end
                end
            end
        end

        if uiVisible and mousePressed and not listeningForBind then
            local m = metrics()
            if inside(mx, my, m.close) then
                unload()
                break
            elseif inside(mx, my, m.header) then
                draggingWindow = true
                dragOffsetX = mx - windowX
                dragOffsetY = my - windowY
            elseif inside(mx, my, m.general) then
                generalEnabled = not generalEnabled
                if not generalEnabled then bindEnabled = false end
            elseif inside(mx, my, m.minHit) then
                draggingWhich = "min"
                cpsMin = math.min(cpsFromMouse(mx, m.minTrack), cpsMax)
            elseif inside(mx, my, m.maxHit) then
                draggingWhich = "max"
                cpsMax = math.max(cpsFromMouse(mx, m.maxTrack), cpsMin)
            elseif inside(mx, my, m.bind) then
                listeningForBind = true
                bindEnabled = false
                captureStartedAt = tick()
            end
        end

        if mouseDown and draggingWindow then
            windowX = mx - dragOffsetX
            windowY = my - dragOffsetY
        elseif not mouseDown then
            draggingWindow = false
        end

        if mouseDown and draggingWhich then
            local m = metrics()
            if draggingWhich == "min" then
                cpsMin = math.min(cpsFromMouse(mx, m.minTrack), cpsMax)
            else
                cpsMax = math.max(cpsFromMouse(mx, m.maxTrack), cpsMin)
            end
        elseif not mouseDown then
            draggingWhich = nil
        end

        render()
        lastMouseDown = mouseDown
        task.wait()
    end
end)

task.spawn(function()
    local lastBindDown = false
    local nextClickAt = tick()

    while alive do
        local bindDown = false
        if bindKey and not listeningForBind then
            pcall(function() bindDown = iskeypressed(bindKey) == true end)
        end

        if bindDown and not lastBindDown then
            if generalEnabled then
                bindEnabled = not bindEnabled
                nextClickAt = tick()
            else
                bindEnabled = false
            end
        end
        lastBindDown = bindDown

        local now = tick()
        local canClick = generalEnabled
            and bindEnabled
            and not listeningForBind
            and not draggingWindow
            and draggingWhich == nil
            and isrbxactive()
            and not pointerOverWindow(Mouse.X, Mouse.Y)

        if canClick then
            if now >= nextClickAt then
                injectingClick = true
                pcall(setrobloxinput, true)
                pcall(mouse1click)
                injectingClick = false
                nextClickAt = now + randomInterval()
            end
        else
            nextClickAt = now
        end

        task.wait(0.002)
    end
end)

render()
