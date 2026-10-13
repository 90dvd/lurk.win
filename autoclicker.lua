--[[
    Matcha Simple Autoclicker

    Voraussetzungen:
      - Matcha LuaVM
      - Drawing API

    Bedienung:
      1. "General" einschalten.
      2. CPS mit dem Slider einstellen.
      3. Auf das Keybind-Feld klicken und eine Taste drücken.
      4. Die gewählte Taste schaltet den Autoclicker an/aus.

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

-- Konfiguration
local MIN_CPS = 1
local MAX_CPS = 20
local cps = 10
local bindKey = 0x75 -- F6 (Windows Virtual-Key-Code)

-- Laufzeitstatus
local alive = true
local generalEnabled = false
local bindEnabled = false
local listeningForBind = false
local draggingWindow = false
local draggingSlider = false
local injectingClick = false

-- Fensterposition und -größe
local windowX, windowY = 160, 160
local windowW, windowH = 340, 218
local dragOffsetX, dragOffsetY = 0, 0

-- Farben
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

local function inside(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

-- Lesbare Namen für häufig verwendete Windows-VK-Codes.
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

-- Drawing-Helfer
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
    pcall(function() object.Corner = 6 end)
    return object
end

local function text(value, color, size, z)
    local object = register(Drawing.new("Text"))
    object.Text = value
    object.Color = color
    object.FontSize = size or 13
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

-- UI-Elemente
local shadow = square(Color3.fromRGB(8, 9, 12), 1)
shadow.Transparency = 0.55
local background = square(COLOR_BG, 2)
local header = square(COLOR_PANEL, 3)
local title = text("MATCHA AUTOCLICKER", COLOR_TEXT, 15, 5)
local subtitle = text("Simple / external input", COLOR_MUTED, 11, 5)
local closeButton = square(COLOR_ROW, 4)
local closeText = text("X", COLOR_MUTED, 13, 5)

local generalRow = square(COLOR_ROW, 3)
local generalLabel = text("General", COLOR_TEXT, 13, 5)
local generalHint = text("Master switch", COLOR_MUTED, 10, 5)
local generalSwitch = square(COLOR_TRACK, 4)
local generalKnob = circle(COLOR_TEXT, 5)

local sliderLabel = text("Clicks per second", COLOR_TEXT, 13, 5)
local sliderValue = text("", COLOR_ACCENT, 13, 5)
local sliderTrack = square(COLOR_TRACK, 3)
local sliderFill = square(COLOR_ACCENT, 4)
local sliderKnob = circle(COLOR_TEXT, 5)

local bindLabel = text("Toggle key", COLOR_TEXT, 13, 5)
local bindButton = square(COLOR_ROW, 3)
local bindText = text("", COLOR_TEXT, 12, 5)
bindText.Center = true

local statusDot = circle(COLOR_RED, 5)
local statusText = text("DISABLED", COLOR_MUTED, 11, 5)
local footerText = text("General must be enabled before the bind works", COLOR_MUTED, 10, 5)

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
    object.Position = Vector2.new(x, y)
end

local function setSize(object, w, h)
    object.Size = Vector2.new(w, h)
end

-- Aktualisiert Positionen, Texte und Farben der gesamten Drawing-UI.
local function render()
    setPosition(shadow, windowX + 6, windowY + 7)
    setSize(shadow, windowW, windowH)
    setPosition(background, windowX, windowY)
    setSize(background, windowW, windowH)
    setPosition(header, windowX, windowY)
    setSize(header, windowW, 49)

    setPosition(title, windowX + 16, windowY + 10)
    setPosition(subtitle, windowX + 16, windowY + 29)
    setPosition(closeButton, windowX + windowW - 36, windowY + 11)
    setSize(closeButton, 24, 24)
    setPosition(closeText, windowX + windowW - 28, windowY + 15)

    setPosition(generalRow, windowX + 14, windowY + 60)
    setSize(generalRow, windowW - 28, 45)
    setPosition(generalLabel, windowX + 26, windowY + 68)
    setPosition(generalHint, windowX + 26, windowY + 86)
    setPosition(generalSwitch, windowX + windowW - 69, windowY + 70)
    setSize(generalSwitch, 42, 22)
    generalSwitch.Color = generalEnabled and COLOR_ACCENT or COLOR_TRACK
    generalKnob.Radius = 8
    setPosition(generalKnob, windowX + windowW - (generalEnabled and 38 or 58), windowY + 81)

    setPosition(sliderLabel, windowX + 18, windowY + 118)
    sliderValue.Text = string.format("%.1f CPS", cps)
    setPosition(sliderValue, windowX + windowW - 68, windowY + 118)

    local trackX = windowX + 18
    local trackY = windowY + 145
    local trackW = windowW - 36
    local fraction = (cps - MIN_CPS) / (MAX_CPS - MIN_CPS)
    setPosition(sliderTrack, trackX, trackY)
    setSize(sliderTrack, trackW, 5)
    setPosition(sliderFill, trackX, trackY)
    setSize(sliderFill, math.max(2, trackW * fraction), 5)
    sliderKnob.Radius = 7
    setPosition(sliderKnob, trackX + trackW * fraction, trackY + 2)

    setPosition(bindLabel, windowX + 18, windowY + 166)
    setPosition(bindButton, windowX + windowW - 117, windowY + 160)
    setSize(bindButton, 99, 28)
    bindButton.Color = listeningForBind and COLOR_ACCENT_DIM or COLOR_ROW
    bindText.Text = listeningForBind and "PRESS A KEY" or keyName(bindKey)
    setPosition(bindText, windowX + windowW - 67, windowY + 167)

    setPosition(statusDot, windowX + 21, windowY + 204)
    statusDot.Radius = 4
    setPosition(statusText, windowX + 32, windowY + 197)
    setPosition(footerText, windowX + 110, windowY + 198)

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
end

local function pointerOverWindow(mx, my)
    return inside(mx, my, windowX, windowY, windowW, windowH)
end

local function updateCpsFromMouse(mx)
    local trackX = windowX + 18
    local trackW = windowW - 36
    local fraction = clamp((mx - trackX) / trackW, 0, 1)
    -- 0,1-CPS-Schritte ergeben einen praktisch stufenlosen Slider.
    cps = math.floor((MIN_CPS + fraction * (MAX_CPS - MIN_CPS)) * 10 + 0.5) / 10
end

-- Eine kleine Whitelist vermeidet Sondertasten und Maustasten als Bind.
local function allowedBind(vk)
    if vk >= 0x30 and vk <= 0x39 then return true end -- 0-9
    if vk >= 0x41 and vk <= 0x5A then return true end -- A-Z
    if vk >= 0x60 and vk <= 0x69 then return true end -- Numpad 0-9
    if vk >= 0x70 and vk <= 0x7B then return true end -- F1-F12
    return vk == 0x09 or vk == 0x20 or (vk >= 0x21 and vk <= 0x28)
        or vk == 0x2D or vk == 0x2E
end

-- UI-/Input-Thread
task.spawn(function()
    local lastMouseDown = false
    local captureStartedAt = 0

    while alive do
        local mx, my = Mouse.X, Mouse.Y
        local mouseDown = false
        pcall(function() mouseDown = ismouse1pressed() == true end)

        -- Die von mouse1click() erzeugten Klicks dürfen die UI nicht bedienen.
        if injectingClick then mouseDown = false end
        local mousePressed = mouseDown and not lastMouseDown

        if listeningForBind then
            -- Kurze Pause nach dem Klick auf den Button verhindert Fehleingaben.
            if tick() - captureStartedAt > 0.15 then
                if iskeypressed(0x1B) then
                    -- ESC entfernt den Bind.
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

        if mousePressed and not listeningForBind then
            if inside(mx, my, windowX + windowW - 36, windowY + 11, 24, 24) then
                unload()
                break
            elseif inside(mx, my, windowX, windowY, windowW, 49) then
                draggingWindow = true
                dragOffsetX = mx - windowX
                dragOffsetY = my - windowY
            elseif inside(mx, my, windowX + 14, windowY + 60, windowW - 28, 45) then
                generalEnabled = not generalEnabled
                if not generalEnabled then
                    bindEnabled = false
                end
            elseif inside(mx, my, windowX + 12, windowY + 136, windowW - 24, 26) then
                draggingSlider = true
                updateCpsFromMouse(mx)
            elseif inside(mx, my, windowX + windowW - 117, windowY + 160, 99, 28) then
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

        if mouseDown and draggingSlider then
            updateCpsFromMouse(mx)
        elseif not mouseDown then
            draggingSlider = false
        end

        render()
        lastMouseDown = mouseDown
        task.wait()
    end
end)

-- Keybind- und Click-Thread
task.spawn(function()
    local lastBindDown = false
    local nextClickAt = tick()

    while alive do
        local bindDown = false
        if bindKey and not listeningForBind then
            pcall(function() bindDown = iskeypressed(bindKey) == true end)
        end

        -- Flankenerkennung: Eine gedrückte Taste schaltet nur einmal um.
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
            and not draggingSlider
            and isrbxactive()
            and not pointerOverWindow(Mouse.X, Mouse.Y)

        if canClick then
            if now >= nextClickAt then
                injectingClick = true
                pcall(setrobloxinput, true)
                pcall(mouse1click)
                injectingClick = false
                nextClickAt = now + (1 / cps)
            end
        else
            -- Nach einer Pause sofort wieder sauber starten, ohne Click-Burst.
            nextClickAt = now
        end

        task.wait(0.002)
    end
end)

render()

