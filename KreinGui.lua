--[[
    KreinGUI v5.3 - Complete GUI Library
    by @uniquadev
    All features: Toggle, Slider, SliderNumber, TextBox, Dropdown, MultiDropdown,
    InputNumber, ProgressBar, ColorPicker, Keybind, Settings Panel (Keybind & Theme),
    Save/Load Config, Resize, Minimize, Hide/Show, Auto-destroy previous GUI
--]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInput = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- GLOBAL CLEANUP
-- ============================================================
local activeConnections = {}
local currentGui = nil

local function addConnection(conn)
    table.insert(activeConnections, conn)
    return conn
end

local function destroyAllConnections()
    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    activeConnections = {}
end

-- ============================================================
-- INPUT HELPERS
-- ============================================================
local function isMouseDown(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
end

local function OnClick(button, callback)
    local down = false
    local startPos = nil
    local con1 = button.InputBegan:Connect(function(input)
        if isMouseDown(input) then
            down = true
            startPos = input.Position
        end
    end)
    local con2 = button.InputEnded:Connect(function(input)
        if isMouseDown(input) and down then
            down = false
            if startPos and (input.Position - startPos).Magnitude <= 10 then
                callback()
            end
        end
    end)
    addConnection(con1)
    addConnection(con2)
end

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    WindowBG = Color3.fromRGB(18, 22, 28),
    HeaderBG = Color3.fromRGB(24, 28, 36),
    TabBG = Color3.fromRGB(28, 32, 40),
    ElementBG = Color3.fromRGB(32, 38, 48),
    ElementHov = Color3.fromRGB(40, 48, 60),
    ElementStroke = Color3.fromRGB(60, 70, 85),
    TabInactive = Color3.fromRGB(28, 32, 40),
    TabHover = Color3.fromRGB(50, 60, 75),
    TabActive = Color3.fromRGB(99, 102, 241),
    TabInactiveText = Color3.fromRGB(140, 155, 175),
    TabActiveText = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(99, 102, 241),
    AccentHover = Color3.fromRGB(120, 125, 255),
    AccentDark = Color3.fromRGB(70, 72, 180),
    ToggleOff = Color3.fromRGB(45, 52, 65),
    ToggleOn = Color3.fromRGB(99, 102, 241),
    TextPrimary = Color3.fromRGB(220, 230, 245),
    TextSecondary = Color3.fromRGB(165, 180, 200),
    TextMuted = Color3.fromRGB(110, 125, 145),
    SectionText = Color3.fromRGB(130, 145, 170),
    CloseRed = Color3.fromRGB(240, 80, 80),
    MinGray = Color3.fromRGB(150, 165, 185),
    Separator = Color3.fromRGB(50, 58, 70),
    StrokeColor = Color3.fromRGB(80, 95, 115),
    FontMain = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
}

local Presets = {
    Default = { Accent = Color3.fromRGB(99, 102, 241) },
    Neon = { Accent = Color3.fromRGB(0, 255, 180) },
    Blood = { Accent = Color3.fromRGB(255, 51, 85) },
    Ocean = { Accent = Color3.fromRGB(0, 180, 255) },
    Purple = { Accent = Color3.fromRGB(176, 96, 255) },
    Gold = { Accent = Color3.fromRGB(255, 194, 0) },
    Rose = { Accent = Color3.fromRGB(255, 80, 144) },
}

-- ============================================================
-- UI HELPERS
-- ============================================================
local function Tween(obj, props, duration, style, direction)
    local tween = TweenService:Create(obj, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

local function Corner(frame, radius)
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, radius or 8)
    return corner
end

local function Stroke(frame, color, thickness)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = color or Theme.StrokeColor
    stroke.Thickness = thickness or 1
    return stroke
end

local function Padding(frame, top, bottom, left, right)
    local pad = Instance.new("UIPadding", frame)
    pad.PaddingTop = UDim.new(0, top or 0)
    pad.PaddingBottom = UDim.new(0, bottom or 0)
    pad.PaddingLeft = UDim.new(0, left or 0)
    pad.PaddingRight = UDim.new(0, right or 0)
end

local function Label(parent, text, size, color, alignX, font)
    local label = Instance.new("TextLabel", parent)
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Size = size or UDim2.new(1, 0, 1, 0)
    label.Text = text or ""
    label.TextSize = 13
    label.TextColor3 = color or Theme.TextPrimary
    label.Font = font or Theme.FontMain
    label.TextXAlignment = alignX or Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    return label
end

local function HSV(h, s, v) return Color3.fromHSV(h, s, v) end
local function ToHSV(c) return Color3.toHSV(c) end
local function ToHex(c) return string.format("%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)) end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local notifQueue = {}
local notifBusy = false
local notifParent = nil

local function ShowNextNotif()
    if notifBusy or #notifQueue == 0 or not notifParent then return end
    notifBusy = true
    local data = table.remove(notifQueue, 1)
    local frame = Instance.new("Frame", notifParent)
    frame.Size = UDim2.new(0, 260, 0, 44)
    frame.Position = UDim2.new(1, 10, 1, -60)
    frame.BackgroundColor3 = Theme.ElementBG
    frame.BorderSizePixel = 0
    frame.ZIndex = 200
    Corner(frame, 8)
    Stroke(frame, Theme.Accent, 1)
    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(0, 3, 0.7, 0)
    bar.Position = UDim2.new(0, 0, 0.15, 0)
    bar.BackgroundColor3 = Theme.Accent
    bar.BorderSizePixel = 0
    Corner(bar, 3)
    local msg = Label(frame, data.msg, UDim2.new(1, -18, 1, 0), Theme.TextPrimary)
    msg.Position = UDim2.new(0, 14, 0, 0)
    msg.TextSize = 12
    Tween(frame, { Position = UDim2.new(1, -270, 1, -60) }, 0.3)
    task.delay(data.dur or 3, function()
        Tween(frame, { Position = UDim2.new(1, 10, 1, -60) }, 0.3)
        task.delay(0.35, function()
            frame:Destroy()
            notifBusy = false
            ShowNextNotif()
        end)
    end)
end

local function Notify(parent, msg, dur)
    notifParent = parent
    table.insert(notifQueue, { msg = msg, dur = dur or 3 })
    ShowNextNotif()
end

-- ============================================================
-- TOOLTIP SYSTEM
-- ============================================================
local activeTip = nil
local function ShowTip(text, parent)
    if activeTip then activeTip:Destroy() end
    local tip = Instance.new("Frame", parent)
    tip.Size = UDim2.new(0, 0, 0, 26)
    tip.BackgroundColor3 = Theme.ElementBG
    tip.BorderSizePixel = 0
    tip.ZIndex = 200
    Corner(tip, 6)
    Stroke(tip, Theme.Accent, 1)
    local lbl = Label(tip, text, UDim2.new(1, -12, 1, 0), Theme.TextPrimary)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.TextSize = 11
    local pos = parent.AbsolutePosition
    tip.Position = UDim2.new(0, pos.X, 0, pos.Y - 32)
    tip.Size = UDim2.new(0, lbl.TextBounds.X + 20, 0, 26)
    activeTip = tip
    tip.Destroying:Connect(function() if activeTip == tip then activeTip = nil end end)
end

local function HideTip()
    if activeTip then activeTip:Destroy() end
end

-- ============================================================
-- LOADING SCREEN
-- ============================================================
local function ShowLoading(sg, accent, title, callback)
    local overlay = Instance.new("Frame", sg)
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 100
    local box = Instance.new("Frame", overlay)
    box.Size = UDim2.new(0, 280, 0, 130)
    box.Position = UDim2.new(0.5, -140, 0.5, -65)
    box.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    box.BorderSizePixel = 0
    Corner(box, 12)
    Stroke(box, accent, 1.5)
    local titleLbl = Label(box, title, UDim2.new(1, 0, 0, 36), accent)
    titleLbl.Position = UDim2.new(0, 0, 0, 18)
    titleLbl.Font = Theme.FontBold
    titleLbl.TextSize = 18
    titleLbl.TextXAlignment = Enum.TextXAlignment.Center
    local subLbl = Label(box, "Loading...", UDim2.new(1, 0, 0, 20), Theme.TextMuted)
    subLbl.Position = UDim2.new(0, 0, 0, 58)
    subLbl.TextSize = 11
    subLbl.TextXAlignment = Enum.TextXAlignment.Center
    local track = Instance.new("Frame", box)
    track.Size = UDim2.new(0, 220, 0, 4)
    track.Position = UDim2.new(0.5, -110, 0, 90)
    track.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
    track.BorderSizePixel = 0
    Corner(track, 2)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = accent
    fill.BorderSizePixel = 0
    Corner(fill, 2)
    local steps = {
        { pct = 0.15, txt = "Loading modules..." },
        { pct = 0.35, txt = "Setting up UI..." },
        { pct = 0.55, txt = "Applying theme..." },
        { pct = 0.75, txt = "Building elements..." },
        { pct = 0.9, txt = "Almost ready..." },
        { pct = 1.0, txt = "Done!" },
    }
    task.spawn(function()
        for _, step in ipairs(steps) do
            subLbl.Text = step.txt
            Tween(fill, { Size = UDim2.new(step.pct, 0, 1, 0) }, 0.22)
            task.wait(0.22)
        end
        task.wait(0.2)
        Tween(overlay, { BackgroundTransparency = 1 }, 0.4)
        task.wait(0.42)
        overlay:Destroy()
        if callback then callback() end
    end)
end

-- ============================================================
-- SETTINGS PANEL
-- ============================================================
local function CreateSettingsPanel(sg, mainWrapper, onThemeChange)
    local panelWidth = 230
    local panel = Instance.new("Frame", sg)
    panel.Size = UDim2.new(0, 0, 0, 0)
    panel.Position = UDim2.new(1, 0, 0, 0)
    panel.BackgroundColor3 = Theme.ElementBG
    panel.BorderSizePixel = 0
    panel.ZIndex = 150
    panel.ClipsDescendants = true
    Corner(panel, 8)
    Stroke(panel, Theme.Accent, 1)
    panel.Visible = false

    local header = Instance.new("Frame", panel)
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Theme.HeaderBG
    header.BorderSizePixel = 0
    Corner(header, 8)

    local titleLbl = Label(header, "Settings", UDim2.new(1, -30, 1, 0), Theme.TextPrimary)
    titleLbl.Position = UDim2.new(0, 12, 0, 0)
    titleLbl.Font = Theme.FontBold
    titleLbl.TextSize = 14

    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -32, 0.5, -13)
    closeBtn.BackgroundColor3 = Theme.ElementHov
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextSize = 12
    closeBtn.Font = Theme.FontBold
    closeBtn.TextColor3 = Theme.TextPrimary
    Corner(closeBtn, 6)

    local content = Instance.new("ScrollingFrame", panel)
    content.Size = UDim2.new(1, 0, 1, -38)
    content.Position = UDim2.new(0, 0, 0, 38)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 2
    content.ScrollBarImageColor3 = Theme.Accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Padding(content, 10, 10, 10, 10)
    local layout = Instance.new("UIListLayout", content)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)

    local settingsFile = "KreinGuiSettings.json"
    local currentKey = Enum.KeyCode.RightShift
    local currentTheme = "Default"

    local function save()
        local data = { key = tostring(currentKey), theme = currentTheme }
        pcall(function() writefile(settingsFile, HttpService:JSONEncode(data)) end)
    end

    local function load()
        local ok, raw = pcall(readfile, settingsFile)
        if not ok or not raw then return end
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok2 then return end
        if data.key then
            local success, k = pcall(function() return Enum.KeyCode[data.key:gsub("Enum.KeyCode.", "")] end)
            if success and k then currentKey = k end
        end
        if data.theme and Presets[data.theme] then
            currentTheme = data.theme
            for k, v in pairs(Presets[currentTheme]) do Theme[k] = v end
            onThemeChange()
        end
    end

    -- Keybind row
    local keyRow = Instance.new("Frame", content)
    keyRow.Size = UDim2.new(1, 0, 0, 44)
    keyRow.BackgroundColor3 = Theme.WindowBG
    keyRow.BorderSizePixel = 0
    Corner(keyRow, 6)
    Stroke(keyRow, Theme.ElementStroke, 1)

    local keyLabel = Label(keyRow, "Toggle GUI Key", UDim2.new(1, -70, 0, 20), Theme.TextSecondary)
    keyLabel.Position = UDim2.new(0, 10, 0, 5)
    keyLabel.TextSize = 11

    local keyBtn = Instance.new("TextButton", keyRow)
    keyBtn.Size = UDim2.new(0, 60, 0, 26)
    keyBtn.Position = UDim2.new(1, -70, 0.5, -13)
    keyBtn.BackgroundColor3 = Theme.ElementBG
    keyBtn.BorderSizePixel = 0
    keyBtn.Text = tostring(currentKey):gsub("Enum.KeyCode.", "")
    keyBtn.TextSize = 11
    keyBtn.Font = Theme.FontBold
    keyBtn.TextColor3 = Theme.Accent
    Corner(keyBtn, 6)
    Stroke(keyBtn, Theme.ElementStroke, 1)

    local listening = false
    local function updateKeyDisplay()
        keyBtn.Text = tostring(currentKey):gsub("Enum.KeyCode.", "")
    end
    OnClick(keyBtn, function()
        if listening then
            listening = false
            keyBtn.BackgroundColor3 = Theme.ElementBG
            updateKeyDisplay()
            return
        end
        listening = true
        keyBtn.BackgroundColor3 = Theme.TabHover
        keyBtn.Text = "..."
        local conn
        conn = UserInput.InputBegan:Connect(function(i, gp)
            if not listening then if conn then conn:Disconnect() end return end
            if gp then return end
            if i.UserInputType == Enum.UserInputType.Keyboard then
                if i.KeyCode == Enum.KeyCode.Escape then
                    listening = false
                    keyBtn.BackgroundColor3 = Theme.ElementBG
                    updateKeyDisplay()
                    if conn then conn:Disconnect() end
                    return
                end
                currentKey = i.KeyCode
                listening = false
                keyBtn.BackgroundColor3 = Theme.ElementBG
                updateKeyDisplay()
                if conn then conn:Disconnect() end
                save()
            end
        end)
        addConnection(conn)
    end)

    -- Theme row
    local themeRow = Instance.new("Frame", content)
    themeRow.Size = UDim2.new(1, 0, 0, 44)
    themeRow.BackgroundColor3 = Theme.WindowBG
    themeRow.BorderSizePixel = 0
    Corner(themeRow, 6)
    Stroke(themeRow, Theme.ElementStroke, 1)

    local themeLabel = Label(themeRow, "Theme", UDim2.new(1, -70, 0, 20), Theme.TextSecondary)
    themeLabel.Position = UDim2.new(0, 10, 0, 5)
    themeLabel.TextSize = 11

    local themeBtn = Instance.new("TextButton", themeRow)
    themeBtn.Size = UDim2.new(0, 70, 0, 26)
    themeBtn.Position = UDim2.new(1, -80, 0.5, -13)
    themeBtn.BackgroundColor3 = Theme.ElementBG
    themeBtn.BorderSizePixel = 0
    themeBtn.Text = currentTheme
    themeBtn.TextSize = 11
    themeBtn.Font = Theme.FontBold
    themeBtn.TextColor3 = Theme.Accent
    Corner(themeBtn, 6)
    Stroke(themeBtn, Theme.ElementStroke, 1)

    local themeOpts = { "Default", "Neon", "Blood", "Ocean", "Purple", "Gold", "Rose" }
    local themePopupOpen = false
    local themePopup = Instance.new("Frame", sg)
    themePopup.Size = UDim2.new(0, 110, 0, 0)
    themePopup.BackgroundColor3 = Theme.ElementBG
    themePopup.BorderSizePixel = 0
    themePopup.ClipsDescendants = true
    themePopup.Visible = false
    themePopup.ZIndex = 200
    Corner(themePopup, 6)
    Stroke(themePopup, Theme.Accent, 1)
    local themeScroller = Instance.new("ScrollingFrame", themePopup)
    themeScroller.Size = UDim2.new(1, 0, 1, 0)
    themeScroller.BackgroundTransparency = 1
    themeScroller.ScrollBarThickness = 2
    themeScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
    themeScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Padding(themeScroller, 4, 4, 4, 4)
    local themeList = Instance.new("UIListLayout", themeScroller)
    themeList.SortOrder = Enum.SortOrder.LayoutOrder
    themeList.Padding = UDim.new(0, 2)

    for _, name in ipairs(themeOpts) do
        local btn = Instance.new("TextButton", themeScroller)
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Theme.ElementHov
        btn.BorderSizePixel = 0
        btn.Text = name
        btn.TextSize = 11
        btn.TextColor3 = Theme.TextPrimary
        Corner(btn, 4)
        OnClick(btn, function()
            currentTheme = name
            themeBtn.Text = name
            for k, v in pairs(Presets[name]) do Theme[k] = v end
            onThemeChange()
            save()
            themePopupOpen = false
            themePopup.Visible = false
        end)
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Theme.TabHover end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Theme.ElementHov end)
    end

    local function closePopup()
        if not themePopupOpen then return end
        themePopupOpen = false
        Tween(themePopup, { Size = UDim2.new(0, 110, 0, 0) }, 0.18)
        task.delay(0.2, function() themePopup.Visible = false end)
    end

    local function openPopup()
        local pos = themeBtn.AbsolutePosition
        local w = 110
        local x = pos.X - w + 10
        local vp = workspace.CurrentCamera.ViewportSize
        x = math.max(4, math.min(x, vp.X - w - 4))
        local y = pos.Y + 36
        if y + 150 > vp.Y - 4 then y = pos.Y - 150 - 4 end
        themePopup.Position = UDim2.new(0, x, 0, y)
        themePopup.Size = UDim2.new(0, w, 0, 0)
        themePopup.Visible = true
        themePopupOpen = true
        Tween(themePopup, { Size = UDim2.new(0, w, 0, 140) }, 0.22)
    end

    OnClick(themeBtn, function() if themePopupOpen then closePopup() else openPopup() end end)
    UserInput.InputBegan:Connect(function(i)
        if not themePopupOpen or not isMouseDown(i) then return end
        task.defer(function()
            if not themePopupOpen then return end
            local pos = i.Position
            local pp = themePopup.AbsolutePosition
            local ps = themePopup.AbsoluteSize
            local bp = themeBtn.AbsolutePosition
            local bs = themeBtn.AbsoluteSize
            local inPopup = pos.X >= pp.X and pos.X <= pp.X + ps.X and pos.Y >= pp.Y and pos.Y <= pp.Y + ps.Y
            local inBtn = pos.X >= bp.X and pos.X <= bp.X + bs.X and pos.Y >= bp.Y and pos.Y <= bp.Y + bs.Y
            if not inPopup and not inBtn then closePopup() end
        end)
    end)

    local function updatePos()
        local wp = mainWrapper.AbsolutePosition
        local ws = mainWrapper.AbsoluteSize
        panel.Position = UDim2.new(0, wp.X + ws.X + 4, 0, wp.Y)
        panel.Size = UDim2.new(0, panelWidth, 0, ws.Y)
    end

    local visible = false
    local function toggle()
        visible = not visible
        if visible then
            updatePos()
            panel.Visible = true
            panel.Size = UDim2.new(0, 0, 0, 0)
            Tween(panel, { Size = UDim2.new(0, panelWidth, 0, mainWrapper.AbsoluteSize.Y) }, 0.25)
        else
            Tween(panel, { Size = UDim2.new(0, 0, 0, 0) }, 0.2)
            task.delay(0.2, function() panel.Visible = false end)
        end
    end

    mainWrapper:GetPropertyChangedSignal("Position"):Connect(function() if visible then updatePos() end end)
    mainWrapper:GetPropertyChangedSignal("Size"):Connect(function() if visible then updatePos() end end)
    OnClick(closeBtn, toggle)

    load()
    return toggle, function() return currentKey end
end

-- ============================================================
-- LIBRARY
-- ============================================================
local KreinGui = {}
KreinGui.Flags = {}
KreinGui.Presets = Presets

function KreinGui:SetTheme(overrides)
    for k, v in pairs(overrides) do
        if k == "Accent" then
            Theme.Accent = v
            Theme.AccentHover = Color3.new(math.min(v.R + 0.12, 1), math.min(v.G + 0.12, 1), math.min(v.B + 0.12, 1))
            Theme.AccentDark = Color3.new(v.R * 0.6, v.G * 0.6, v.B * 0.6)
            Theme.ToggleOn = v
            Theme.TabActive = v
        else
            Theme[k] = v
        end
    end
end

function KreinGui:UsePreset(name)
    if Presets[name] then self:SetTheme(Presets[name]) end
end

-- ============================================================
-- CREATE WINDOW
-- ============================================================
function KreinGui:CreateWindow(config)
    if currentGui then
        destroyAllConnections()
        currentGui:Destroy()
    end

    config = config or {}
    local title = config.Title or "KreinGui"
    local subtitle = config.SubTitle or ""
    local cfgName = config.ConfigName or "KreinGuiConfig"

    local SG = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    SG.Name = "KreinGui"
    SG.ResetOnSpawn = false
    SG.IgnoreGuiInset = true
    currentGui = SG

    SG.AncestryChanged:Connect(function()
        if not SG.Parent then
            destroyAllConnections()
            if currentGui == SG then currentGui = nil end
        end
    end)

    local Wrapper = Instance.new("Frame", SG)
    Wrapper.Size = UDim2.new(0, 560 + 32, 0, 340)
    Wrapper.Position = UDim2.new(0.5, -280 - 32, 0.5, -170)
    Wrapper.BackgroundTransparency = 1
    Wrapper.ClipsDescendants = false

    local Win = Instance.new("Frame", Wrapper)
    Win.Size = UDim2.new(0, 560, 0, 340)
    Win.Position = UDim2.new(0, 32, 0, 0)
    Win.BackgroundColor3 = Theme.WindowBG
    Win.BorderSizePixel = 0
    Win.ClipsDescendants = true
    Corner(Win, 12)
    Stroke(Win, Theme.StrokeColor, 1)
    Win.BackgroundTransparency = 1
    Win.Visible = false

    local Header = Instance.new("Frame", Win)
    Header.Size = UDim2.new(1, 0, 0, 52)
    Header.BackgroundColor3 = Theme.HeaderBG
    Header.BorderSizePixel = 0
    Corner(Header, 12)

    local ABar = Instance.new("Frame", Win)
    ABar.Size = UDim2.new(1, 0, 0, 4)
    ABar.Position = UDim2.new(0, 0, 0, 50)
    ABar.BackgroundColor3 = Theme.Accent
    ABar.BorderSizePixel = 0

    local Logo = Instance.new("Frame", Header)
    Logo.Size = UDim2.new(0, 34, 0, 34)
    Logo.Position = UDim2.new(0, 10, 0.5, -17)
    Logo.BackgroundColor3 = Theme.Accent
    Logo.BackgroundTransparency = 0.12
    Logo.BorderSizePixel = 0
    Corner(Logo, 8)
    Stroke(Logo, Theme.Accent, 1.5)

    local LogoText = Label(Logo, "K", UDim2.new(1, 0, 1, 0), Color3.fromRGB(10, 15, 20))
    LogoText.Font = Theme.FontBold
    LogoText.TextSize = 18
    LogoText.TextXAlignment = Enum.TextXAlignment.Center

    local TitleLabel = Label(Header, title, UDim2.new(0, 260, 0, 22), Theme.TextPrimary)
    TitleLabel.Position = (subtitle ~= "") and UDim2.new(0, 52, 0, 5) or UDim2.new(0, 52, 0, 15)
    TitleLabel.Font = Theme.FontBold
    TitleLabel.TextSize = 15
    if subtitle ~= "" then
        local SubLabel = Label(Header, subtitle, UDim2.new(0, 260, 0, 18), Theme.TextMuted)
        SubLabel.Position = UDim2.new(0, 52, 0, 28)
        SubLabel.TextSize = 11
    end

    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 35, 35)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "X"
    CloseBtn.TextSize = 14
    CloseBtn.Font = Theme.FontBold
    CloseBtn.TextColor3 = Theme.CloseRed
    Corner(CloseBtn, 7)
    OnClick(CloseBtn, function() SG:Destroy() end)

    local MinBtn = Instance.new("TextButton", Header)
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -78, 0.5, -15)
    MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    MinBtn.BorderSizePixel = 0
    MinBtn.Text = "−"
    MinBtn.TextSize = 16
    MinBtn.Font = Theme.FontBold
    MinBtn.TextColor3 = Theme.MinGray
    Corner(MinBtn, 7)

    local SettingsBtn = Instance.new("TextButton", Header)
    SettingsBtn.Size = UDim2.new(0, 30, 0, 30)
    SettingsBtn.Position = UDim2.new(1, -116, 0.5, -15)
    SettingsBtn.BackgroundColor3 = Theme.ElementHov
    SettingsBtn.BorderSizePixel = 0
    SettingsBtn.Text = "⚙"
    SettingsBtn.TextSize = 16
    SettingsBtn.Font = Theme.FontBold
    SettingsBtn.TextColor3 = Theme.TextPrimary
    Corner(SettingsBtn, 7)

    local ToggleBtn = Instance.new("TextButton", Wrapper)
    ToggleBtn.Size = UDim2.new(0, 28, 0, 80)
    ToggleBtn.Position = UDim2.new(0, 0, 0.5, -40)
    ToggleBtn.BackgroundColor3 = Theme.WindowBG
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = ""
    Corner(ToggleBtn, 8)
    Stroke(ToggleBtn, Theme.Accent, 1)

    local ToggleIcon = Label(ToggleBtn, "◀", UDim2.new(1, 0, 0, 16), Theme.Accent)
    ToggleIcon.Position = UDim2.new(0, 0, 0.5, -26)
    ToggleIcon.Font = Theme.FontBold
    ToggleIcon.TextSize = 10
    ToggleIcon.TextXAlignment = Enum.TextXAlignment.Center

    local ToggleLetter = Label(ToggleBtn, "K", UDim2.new(1, 0, 0, 14), Theme.Accent)
    ToggleLetter.Position = UDim2.new(0, 0, 0.5, -7)
    ToggleLetter.Font = Theme.FontBold
    ToggleLetter.TextSize = 13
    ToggleLetter.TextXAlignment = Enum.TextXAlignment.Center

    local ToggleSub = Label(ToggleBtn, "GUI", UDim2.new(1, 0, 0, 12), Color3.new(Theme.Accent.R * 0.65, Theme.Accent.G * 0.65, Theme.Accent.B * 0.65))
    ToggleSub.Position = UDim2.new(0, 0, 0.5, 14)
    ToggleSub.Font = Theme.FontBold
    ToggleSub.TextSize = 8
    ToggleSub.TextXAlignment = Enum.TextXAlignment.Center

    local ToggleGlow = Instance.new("Frame", ToggleBtn)
    ToggleGlow.Size = UDim2.new(0, 3, 0.65, 0)
    ToggleGlow.Position = UDim2.new(1, -3, 0.175, 0)
    ToggleGlow.BackgroundColor3 = Theme.Accent
    ToggleGlow.BackgroundTransparency = 0.35
    ToggleGlow.BorderSizePixel = 0
    Corner(ToggleGlow, 2)

    local Body = Instance.new("Frame", Win)
    Body.Size = UDim2.new(1, 0, 1, -54)
    Body.Position = UDim2.new(0, 0, 0, 54)
    Body.BackgroundTransparency = 1

    local TabPanel = Instance.new("Frame", Body)
    TabPanel.Size = UDim2.new(0, 130, 1, 0)
    TabPanel.BackgroundColor3 = Theme.TabBG
    TabPanel.BorderSizePixel = 0

    local TabSep = Instance.new("Frame", Body)
    TabSep.Size = UDim2.new(0, 1, 1, 0)
    TabSep.Position = UDim2.new(0, 130, 0, 0)
    TabSep.BackgroundColor3 = Theme.Separator
    TabSep.BorderSizePixel = 0

    local TabScroller = Instance.new("ScrollingFrame", TabPanel)
    TabScroller.Size = UDim2.new(1, 0, 1, 0)
    TabScroller.BackgroundTransparency = 1
    TabScroller.ScrollBarThickness = 2
    TabScroller.ScrollBarImageColor3 = Theme.Accent
    TabScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Padding(TabScroller, 8, 8, 6, 6)
    local TabLayout = Instance.new("UIListLayout", TabScroller)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 3)
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ContentArea = Instance.new("Frame", Body)
    ContentArea.Size = UDim2.new(1, -131, 1, 0)
    ContentArea.Position = UDim2.new(0, 131, 0, 0)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = true

    local SearchBox = Instance.new("TextBox", ContentArea)
    SearchBox.Size = UDim2.new(1, -20, 0, 28)
    SearchBox.Position = UDim2.new(0, 10, 0, 6)
    SearchBox.BackgroundColor3 = Theme.ElementBG
    SearchBox.BorderSizePixel = 0
    SearchBox.PlaceholderText = "🔍 Search flags..."
    SearchBox.TextColor3 = Theme.TextPrimary
    SearchBox.PlaceholderColor3 = Theme.TextMuted
    SearchBox.TextSize = 12
    SearchBox.Font = Theme.FontMain
    Corner(SearchBox, 6)
    Stroke(SearchBox, Theme.ElementStroke, 1)

    local ContentContainer = Instance.new("Frame", ContentArea)
    ContentContainer.Size = UDim2.new(1, 0, 1, -40)
    ContentContainer.Position = UDim2.new(0, 0, 0, 40)
    ContentContainer.BackgroundTransparency = 1

    local ResizeGrip = Instance.new("TextButton", Win)
    ResizeGrip.Size = UDim2.new(0, 12, 0, 12)
    ResizeGrip.Position = UDim2.new(1, -14, 1, -14)
    ResizeGrip.BackgroundColor3 = Theme.Accent
    ResizeGrip.BackgroundTransparency = 0.5
    ResizeGrip.Text = ""
    Corner(ResizeGrip, 3)

    local guiVisible = true
    local isMinimized = false
    local resizeEnabled = true
    local lastWrapperSize = Wrapper.Size
    local lastWinSize = Win.Size
    local lastWrapperPos = Wrapper.Position

    local function syncToggleBtnY(h)
        ToggleBtn.Position = UDim2.new(0, 0, 0, h / 2 - 40)
    end

    local function updateToggleIcon()
        if guiVisible then
            ToggleIcon.Text = "◀"
            ToggleGlow.BackgroundTransparency = 0.35
        else
            ToggleIcon.Text = "▶"
            ToggleGlow.BackgroundTransparency = 0.1
        end
    end

    local function toggleGui()
        guiVisible = not guiVisible
        local curH = Win.Size.Y.Offset
        if guiVisible then
            Win.Visible = true
            Win.BackgroundTransparency = 0
            Win.Size = UDim2.new(0, 0, 0, curH)
            Win.Position = UDim2.new(0, 32, 0, 0)
            Wrapper.Position = lastWrapperPos
            Tween(Win, { Size = lastWinSize }, 0.4)
            Wrapper.Size = lastWrapperSize
            syncToggleBtnY(lastWinSize.Y.Offset)
        else
            lastWrapperSize = Wrapper.Size
            lastWinSize = Win.Size
            lastWrapperPos = Wrapper.Position
            local curY = Wrapper.Position.Y
            Tween(Win, { Size = UDim2.new(0, 0, 0, curH) }, 0.35)
            task.delay(0.35, function()
                Win.Visible = false
                Win.Size = lastWinSize
            end)
            Tween(Wrapper, { Position = UDim2.new(0, -4, curY.Scale, curY.Offset) }, 0.35)
        end
        updateToggleIcon()
    end

    OnClick(ToggleBtn, toggleGui)

    OnClick(MinBtn, function()
        isMinimized = not isMinimized
        if isMinimized then
            MinBtn.Text = "+"
            resizeEnabled = false
            Tween(Win, { Size = UDim2.new(0, 560, 0, 52) }, 0.3)
            Tween(Wrapper, { Size = UDim2.new(0, 560 + 32, 0, 52) }, 0.3)
            task.delay(0.2, function()
                ABar.Visible = false
                syncToggleBtnY(52)
                lastWrapperSize = Wrapper.Size
                lastWinSize = Win.Size
            end)
        else
            MinBtn.Text = "−"
            resizeEnabled = true
            ABar.Visible = true
            Tween(Win, { Size = UDim2.new(0, 560, 0, 340) }, 0.4, Enum.EasingStyle.Back)
            Tween(Wrapper, { Size = UDim2.new(0, 560 + 32, 0, 340) }, 0.4, Enum.EasingStyle.Back)
            task.delay(0.35, function()
                syncToggleBtnY(340)
                lastWrapperSize = Wrapper.Size
                lastWinSize = Win.Size
            end)
        end
    end)

    local resizing = false
    local resizeStart, resizeStartSize
    ResizeGrip.InputBegan:Connect(function(i)
        if isMouseDown(i) and resizeEnabled then
            resizing = true
            resizeStart = i.Position
            resizeStartSize = Wrapper.Size
        end
    end)
    UserInput.InputChanged:Connect(function(i)
        if resizing and i.UserInputType == Enum.UserInputType.MouseMovement and resizeEnabled then
            local delta = i.Position - resizeStart
            local newW = math.max(400, resizeStartSize.X.Offset + delta.X)
            local newH = math.max(200, resizeStartSize.Y.Offset + delta.Y)
            Wrapper.Size = UDim2.new(0, newW, 0, newH)
            Win.Size = UDim2.new(0, newW - 32, 0, newH)
            syncToggleBtnY(newH)
            lastWrapperSize = Wrapper.Size
            lastWinSize = Win.Size
        end
    end)
    UserInput.InputEnded:Connect(function(i)
        if isMouseDown(i) then resizing = false end
    end)

    local dragEnabled = true
    local function EnableDrag(frame, handle)
        handle = handle or frame
        local dragging = false
        local dragStart, frameStart
        handle.InputBegan:Connect(function(i)
            if isMouseDown(i) and dragEnabled then
                dragging = true
                dragStart = i.Position
                frameStart = frame.Position
            end
        end)
        UserInput.InputChanged:Connect(function(i)
            if dragging and dragStart and dragEnabled and i.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = i.Position - dragStart
                if delta.Magnitude > 6 then
                    frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
                end
            end
        end)
        UserInput.InputEnded:Connect(function(i)
            if isMouseDown(i) then dragging = false end
        end)
    end
    EnableDrag(Wrapper, Header)

    local function onThemeChanged()
        Win.BackgroundColor3 = Theme.WindowBG
        Header.BackgroundColor3 = Theme.HeaderBG
        TabPanel.BackgroundColor3 = Theme.TabBG
        TabSep.BackgroundColor3 = Theme.Separator
        ABar.BackgroundColor3 = Theme.Accent
        Logo.BackgroundColor3 = Theme.Accent
        ToggleGlow.BackgroundColor3 = Theme.Accent
        ToggleIcon.TextColor3 = Theme.Accent
        ToggleLetter.TextColor3 = Theme.Accent
        ToggleSub.TextColor3 = Color3.new(Theme.Accent.R * 0.65, Theme.Accent.G * 0.65, Theme.Accent.B * 0.65)
        SearchBox.BackgroundColor3 = Theme.ElementBG
        for _, btn in ipairs(tabButtons) do
            local active = (btn == tabButtons[activeTab])
            btn.BackgroundColor3 = active and Theme.TabActive or Theme.TabInactive
            local lbl = btn:FindFirstChild("Label")
            if lbl then lbl.TextColor3 = active and Theme.TabActiveText or Theme.TabInactiveText end
            local bar = btn:FindFirstChild("Bar")
            if bar then bar.BackgroundColor3 = Theme.AccentHover end
        end
        for _, f in ipairs(tabFrames) do
            f.ScrollBarImageColor3 = Theme.Accent
        end
    end

    local toggleSettings, getKey = CreateSettingsPanel(SG, Wrapper, onThemeChanged)
    OnClick(SettingsBtn, toggleSettings)

    local currentKeybind = getKey()
    local keybindConn
    local function applyKeybind()
        if keybindConn then keybindConn:Disconnect() end
        keybindConn = UserInput.InputBegan:Connect(function(i, gp)
            if gp then return end
            if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == currentKeybind then
                toggleGui()
            end
        end)
        addConnection(keybindConn)
    end
    applyKeybind()
    task.spawn(function()
        while SG and SG.Parent do
            local newKey = getKey()
            if newKey ~= currentKeybind then
                currentKeybind = newKey
                applyKeybind()
            end
            task.wait(0.5)
        end
    end)

    local tabButtons = {}
    local tabFrames = {}
    local activeTab = nil

    local function setActiveTab(idx)
        activeTab = idx
        for i, btn in ipairs(tabButtons) do
            local active = (i == idx)
            btn.BackgroundColor3 = active and Theme.TabActive or Theme.TabInactive
            local lbl = btn:FindFirstChild("Label")
            if lbl then lbl.TextColor3 = active and Theme.TabActiveText or Theme.TabInactiveText end
            local bar = btn:FindFirstChild("Bar")
            if bar then bar.Visible = active end
        end
        for i, f in ipairs(tabFrames) do
            if i == idx then
                f.Size = UDim2.new(0, 0, 0, 0)
                Tween(f, { Size = UDim2.new(1, 0, 1, 0) }, 0.22)
            else
                f.Size = UDim2.new(0, 0, 0, 0)
            end
        end
        SearchBox.Text = ""
        for _, api in pairs(KreinGui.Flags) do
            if api._element then api._element.Visible = true end
        end
    end

    SearchBox.Changed:Connect(function()
        local query = SearchBox.Text:lower()
        for _, api in pairs(KreinGui.Flags) do
            if api._element and api._flag then
                api._element.Visible = (query == "" or api._flag:lower():find(query))
            end
        end
    end)

    local Window = {}
    local flags = {}

    function Window:Notify(msg, dur) Notify(SG, msg, dur) end

    function Window:SaveConfig()
        local data = {}
        for k, api in pairs(flags) do
            local v = api:Get()
            if typeof(v) == "Color3" then
                data[k] = { __t = "Color3", r = v.R, g = v.G, b = v.B }
            elseif typeof(v) == "EnumItem" then
                data[k] = { __t = "Enum", v = tostring(v) }
            else
                data[k] = v
            end
        end
        local ok, err = pcall(function() writefile(cfgName .. ".json", HttpService:JSONEncode(data)) end)
        self:Notify(ok and "Config saved" or "Save failed: " .. tostring(err), 2)
    end

    function Window:LoadConfig()
        local ok, raw = pcall(readfile, cfgName .. ".json")
        if not ok or not raw then self:Notify("No config found", 2) return end
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok2 then self:Notify("Corrupted config", 2) return end
        for k, val in pairs(data) do
            if flags[k] then
                if type(val) == "table" and val.__t == "Color3" then
                    flags[k]:Set(Color3.new(val.r, val.g, val.b))
                elseif type(val) == "table" and val.__t == "Enum" then
                    local parts = string.split(val.v, ".")
                    local success, en = pcall(function() return Enum[parts[2]][parts[3]] end)
                    if success then flags[k]:Set(en) end
                else
                    flags[k]:Set(val)
                end
            end
        end
        self:Notify("Config loaded", 2)
    end

    function Window:ExportToClipboard()
        local data = {}
        for k, api in pairs(flags) do
            local v = api:Get()
            if typeof(v) == "Color3" then
                data[k] = { __t = "Color3", r = v.R, g = v.G, b = v.B }
            elseif typeof(v) == "EnumItem" then
                data[k] = { __t = "Enum", v = tostring(v) }
            else
                data[k] = v
            end
        end
        local json = HttpService:JSONEncode(data)
        if setclipboard then
            setclipboard(json)
            self:Notify("Copied to clipboard", 2)
        else
            self:Notify("Clipboard not supported", 2)
        end
    end

    function Window:ImportFromClipboard()
        if not getclipboard then self:Notify("Clipboard not supported", 2) return end
        local raw = getclipboard()
        local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok then self:Notify("Invalid clipboard data", 2) return end
        for k, val in pairs(data) do
            if flags[k] then
                if type(val) == "table" and val.__t == "Color3" then
                    flags[k]:Set(Color3.new(val.r, val.g, val.b))
                elseif type(val) == "table" and val.__t == "Enum" then
                    local parts = string.split(val.v, ".")
                    local success, en = pcall(function() return Enum[parts[2]][parts[3]] end)
                    if success then flags[k]:Set(en) end
                else
                    flags[k]:Set(val)
                end
            end
        end
        self:Notify("Imported from clipboard", 2)
    end

    function Window:ReloadTheme()
        onThemeChanged()
        self:Notify("Theme reloaded", 1)
    end

    function Window:CreateTab(name)
        local idx = #tabButtons + 1

        local btn = Instance.new("TextButton", TabScroller)
        btn.Size = UDim2.new(1, -4, 0, 40)
        btn.BackgroundColor3 = Theme.TabInactive
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = idx
        btn.AutoButtonColor = false
        Corner(btn, 7)

        local bar = Instance.new("Frame", btn)
        bar.Name = "Bar"
        bar.Size = UDim2.new(0, 3, 0.55, 0)
        bar.Position = UDim2.new(0, 0, 0.225, 0)
        bar.BackgroundColor3 = Theme.AccentHover
        bar.BorderSizePixel = 0
        bar.Visible = false
        Corner(bar, 2)

        local label = Label(btn, name, UDim2.new(1, -10, 1, 0), Theme.TabInactiveText)
        label.Name = "Label"
        label.Position = UDim2.new(0, 10, 0, 0)
        label.Font = Theme.FontMain
        label.TextSize = 12

        OnClick(btn, function() setActiveTab(idx) end)
        btn.MouseEnter:Connect(function()
            if activeTab ~= idx then btn.BackgroundColor3 = Theme.TabHover end
        end)
        btn.MouseLeave:Connect(function()
            if activeTab ~= idx then btn.BackgroundColor3 = Theme.TabInactive end
        end)
        tabButtons[idx] = btn

        local content = Instance.new("ScrollingFrame", ContentContainer)
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.ScrollBarThickness = 3
        content.ScrollBarImageColor3 = Theme.Accent
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        content.ClipsDescendants = true
        content.Visible = true
        content.Size = UDim2.new(0, 0, 0, 0)
        Padding(content, 10, 10, 10, 10)
        local list = Instance.new("UIListLayout", content)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 6)
        tabFrames[idx] = content

        if idx == 1 then setActiveTab(1) end

        local Tab = {}
        local order = 0
        local function nextOrder() order = order + 1; return order end
        local function registerFlag(flag, api, element)
            if flag and flag ~= "" then
                flags[flag] = api
                KreinGui.Flags[flag] = api
                api._flag = flag
                api._element = element
            end
        end

        local function Card(h)
            local card = Instance.new("Frame", content)
            card.Size = UDim2.new(1, 0, 0, h or 44)
            card.BackgroundColor3 = Theme.ElementBG
            card.BorderSizePixel = 0
            card.LayoutOrder = nextOrder()
            Corner(card, 8)
            Stroke(card, Theme.ElementStroke, 1)
            return card
        end

        local function addHint(elem, text)
            if not text then return end
            elem.MouseEnter:Connect(function() ShowTip(text, elem) end)
            elem.MouseLeave:Connect(function() HideTip() end)
        end

        -- Label
        function Tab:CreateLabel(text, hint)
            local c = Card(36)
            Padding(c, 0, 0, 12, 12)
            local lbl = Label(c, text, UDim2.new(1, 0, 1, 0), Theme.TextSecondary)
            lbl.Font = Theme.FontMain
            lbl.TextSize = 12
            if hint then addHint(c, hint) end
            return lbl
        end

        -- Section Header
        function Tab:CreateSectionHeader(text, hint)
            local f = Instance.new("Frame", content)
            f.Size = UDim2.new(1, 0, 0, 24)
            f.BackgroundTransparency = 1
            f.LayoutOrder = nextOrder()
            local line = Instance.new("Frame", f)
            line.Size = UDim2.new(0, 3, 0.6, 0)
            line.Position = UDim2.new(0, 0, 0.2, 0)
            line.BackgroundColor3 = Theme.Accent
            line.BorderSizePixel = 0
            Corner(line, 2)
            local lbl = Label(f, string.upper(text), UDim2.new(1, -10, 1, 0), Theme.SectionText)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.Font = Theme.FontBold
            lbl.TextSize = 10
            if hint then addHint(f, hint) end
            return lbl
        end

        -- Separator
        function Tab:AddSeparator()
            local s = Instance.new("Frame", content)
            s.Size = UDim2.new(1, 0, 0, 1)
            s.BackgroundColor3 = Theme.Separator
            s.BorderSizePixel = 0
            s.LayoutOrder = nextOrder()
        end

        -- Button
        function Tab:CreateButton(cfg)
            cfg = cfg or {}
            local c = Card(44)
            Padding(c, 0, 0, 12, 12)
            Label(c, cfg.Title or "Button", UDim2.new(1, -82, 1, 0))
            local runBtn = Instance.new("TextButton", c)
            runBtn.Size = UDim2.new(0, 68, 0, 30)
            runBtn.Position = UDim2.new(1, -72, 0.5, -15)
            runBtn.BackgroundColor3 = Theme.Accent
            runBtn.BorderSizePixel = 0
            runBtn.Text = "Run"
            runBtn.TextSize = 11
            runBtn.Font = Theme.FontBold
            runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Corner(runBtn, 6)
            OnClick(runBtn, function()
                Tween(runBtn, { BackgroundColor3 = Theme.AccentDark }, 0.1)
                task.delay(0.15, function() Tween(runBtn, { BackgroundColor3 = Theme.Accent }, 0.15) end)
                pcall(cfg.Callback or function() end)
            end)
            runBtn.MouseEnter:Connect(function() runBtn.BackgroundColor3 = Theme.AccentHover end)
            runBtn.MouseLeave:Connect(function() runBtn.BackgroundColor3 = Theme.Accent end)
            if cfg.Hint then addHint(c, cfg.Hint) end
        end

        -- Toggle
        function Tab:CreateToggle(cfg)
            cfg = cfg or {}
            local state = cfg.Default or false
            local c = Card(44)
            Padding(c, 0, 0, 12, 12)
            Label(c, cfg.Title or "Toggle", UDim2.new(1, -58, 1, 0))
            local track = Instance.new("Frame", c)
            track.Size = UDim2.new(0, 44, 0, 24)
            track.Position = UDim2.new(1, -48, 0.5, -12)
            track.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
            track.BorderSizePixel = 0
            Corner(track, 12)
            local knob = Instance.new("Frame", track)
            knob.Size = UDim2.new(0, 18, 0, 18)
            knob.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            Corner(knob, 9)
            local hit = Instance.new("TextButton", c)
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            local api = {}
            local function update()
                Tween(track, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff }, 0.18)
                Tween(knob, { Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) }, 0.18)
                pcall(cfg.Callback or function() end, state)
            end
            function api:Set(v) state = v; update() end
            function api:Get() return state end
            OnClick(hit, function() state = not state; update() end)
            hit.MouseEnter:Connect(function() Tween(c, { BackgroundColor3 = Theme.ElementHov }, 0.15) end)
            hit.MouseLeave:Connect(function() Tween(c, { BackgroundColor3 = Theme.ElementBG }, 0.15) end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        -- Slider
        function Tab:CreateSlider(cfg)
            cfg = cfg or {}
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local val = math.clamp(cfg.Default or min, min, max)
            local c = Card(58)
            Padding(c, 8, 8, 12, 12)
            local top = Instance.new("Frame", c)
            top.Size = UDim2.new(1, 0, 0, 20)
            top.BackgroundTransparency = 1
            Label(top, cfg.Title or "Slider", UDim2.new(1, -42, 1, 0))
            local valLabel = Label(top, tostring(val), UDim2.new(0, 40, 1, 0), Theme.Accent, Enum.TextXAlignment.Right)
            valLabel.Position = UDim2.new(1, -40, 0, 0)
            valLabel.Font = Theme.FontBold
            local track = Instance.new("Frame", c)
            track.Size = UDim2.new(1, 0, 0, 10)
            track.Position = UDim2.new(0, 0, 1, -18)
            track.BackgroundColor3 = Theme.ToggleOff
            track.BorderSizePixel = 0
            Corner(track, 5)
            local fill = Instance.new("Frame", track)
            fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Theme.Accent
            fill.BorderSizePixel = 0
            Corner(fill, 5)
            local knob = Instance.new("Frame", track)
            knob.Size = UDim2.new(0, 20, 0, 20)
            knob.Position = UDim2.new((val - min) / (max - min), -10, 0.5, -10)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.ZIndex = 3
            Corner(knob, 10)
            Stroke(knob, Theme.Accent, 2)
            local hit = Instance.new("TextButton", track)
            hit.Size = UDim2.new(1, 0, 0, 40)
            hit.Position = UDim2.new(0, 0, 0.5, -20)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            local dragging = false
            local api = {}
            local function updateValue(x)
                if not track.AbsolutePosition then return end
                local r = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                val = math.floor(min + r * (max - min) + 0.5)
                local p = (val - min) / (max - min)
                fill.Size = UDim2.new(p, 0, 1, 0)
                knob.Position = UDim2.new(p, -10, 0.5, -10)
                valLabel.Text = tostring(val)
                pcall(cfg.Callback or function() end, val)
            end
            function api:Set(v) val = math.clamp(v, min, max); local p = (val - min) / (max - min); fill.Size = UDim2.new(p, 0, 1, 0); knob.Position = UDim2.new(p, -10, 0.5, -10); valLabel.Text = tostring(val); pcall(cfg.Callback or function() end, val) end
            function api:Get() return val end
            hit.InputBegan:Connect(function(i) if isMouseDown(i) then dragging = true; updateValue(i.Position.X) end end)
            UserInput.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then updateValue(i.Position.X) end end)
            UserInput.InputEnded:Connect(function(i) if isMouseDown(i) then dragging = false end end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        -- SliderNumber
        function Tab:CreateSliderNumber(cfg)
            cfg = cfg or {}
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local val = math.clamp(cfg.Default or min, min, max)
            local c = Card(70)
            Padding(c, 8, 8, 12, 12)
            local top = Instance.new("Frame", c)
            top.Size = UDim2.new(1, 0, 0, 20)
            top.BackgroundTransparency = 1
            Label(top, cfg.Title or "Slider", UDim2.new(1, -52, 1, 0))
            local numBox = Instance.new("TextBox", top)
            numBox.Size = UDim2.new(0, 50, 0, 20)
            numBox.Position = UDim2.new(1, -52, 0, 0)
            numBox.BackgroundColor3 = Theme.WindowBG
            numBox.BorderSizePixel = 0
            numBox.Text = tostring(val)
            numBox.TextColor3 = Theme.Accent
            numBox.TextSize = 11
            numBox.Font = Theme.FontBold
            numBox.TextXAlignment = Enum.TextXAlignment.Center
            Corner(numBox, 4)
            Stroke(numBox, Theme.ElementStroke, 1)
            local track = Instance.new("Frame", c)
            track.Size = UDim2.new(1, 0, 0, 10)
            track.Position = UDim2.new(0, 0, 1, -18)
            track.BackgroundColor3 = Theme.ToggleOff
            track.BorderSizePixel = 0
            Corner(track, 5)
            local fill = Instance.new("Frame", track)
            fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Theme.Accent
            fill.BorderSizePixel = 0
            Corner(fill, 5)
            local knob = Instance.new("Frame", track)
            knob.Size = UDim2.new(0, 20, 0, 20)
            knob.Position = UDim2.new((val - min) / (max - min), -10, 0.5, -10)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.ZIndex = 3
            Corner(knob, 10)
            Stroke(knob, Theme.Accent, 2)
            local hit = Instance.new("TextButton", track)
            hit.Size = UDim2.new(1, 0, 0, 40)
            hit.Position = UDim2.new(0, 0, 0.5, -20)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            local dragging = false
            local api = {}
            local function updateVal(newVal)
                val = math.clamp(newVal, min, max)
                local p = (val - min) / (max - min)
                fill.Size = UDim2.new(p, 0, 1, 0)
                knob.Position = UDim2.new(p, -10, 0.5, -10)
                numBox.Text = tostring(val)
                pcall(cfg.Callback or function() end, val)
            end
            local function updateFromPos(x)
                if not track.AbsolutePosition then return end
                local r = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                updateVal(math.floor(min + r * (max - min) + 0.5))
            end
            function api:Set(v) updateVal(v) end
            function api:Get() return val end
            hit.InputBegan:Connect(function(i) if isMouseDown(i) then dragging = true; updateFromPos(i.Position.X) end end)
            UserInput.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then updateFromPos(i.Position.X) end end)
            UserInput.InputEnded:Connect(function(i) if isMouseDown(i) then dragging = false end end)
            numBox.FocusLost:Connect(function(enter)
                if enter then
                    local n = tonumber(numBox.Text)
                    if n then updateVal(n) else numBox.Text = tostring(val) end
                else
                    numBox.Text = tostring(val)
                end
            end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        -- TextBox
        function Tab:CreateTextBox(cfg)
            cfg = cfg or {}
            local c = Card(70)
            Padding(c, 8, 8, 12, 12)
            Label(c, cfg.Title or "TextBox", UDim2.new(1, 0, 0, 20))
            local inputFrame = Instance.new("Frame", c)
            inputFrame.Size = UDim2.new(1, 0, 0, 32)
            inputFrame.Position = UDim2.new(0, 0, 1, -36)
            inputFrame.BackgroundColor3 = Theme.WindowBG
            inputFrame.BorderSizePixel = 0
            Corner(inputFrame, 6)
            local stroke = Stroke(inputFrame, Theme.ElementStroke, 1)
            local box = Instance.new("TextBox", inputFrame)
            box.Size = UDim2.new(1, 0, 1, 0)
            box.BackgroundTransparency = 1
            box.BorderSizePixel = 0
            box.Text = ""
            box.PlaceholderText = cfg.Placeholder or "Type here..."
            box.PlaceholderColor3 = Theme.TextMuted
            box.TextColor3 = Theme.TextPrimary
            box.TextSize = 12
            box.Font = Theme.FontMain
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            Padding(box, 0, 0, 8, 8)
            local api = {}
            function api:Set(v) box.Text = tostring(v) end
            function api:Get() return box.Text end
            box.Focused:Connect(function() stroke.Color = Theme.Accent end)
            box.FocusLost:Connect(function(enter)
                stroke.Color = Theme.ElementStroke
                if enter then pcall(cfg.Callback or function() end, box.Text) end
            end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        -- Dropdown
        function Tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local opts = cfg.Options or {}
            local sel = cfg.Default or (opts[1] or "")
            local open = false
            local c = Card(44)
            Padding(c, 0, 0, 12, 12)
            Label(c, cfg.Title or "Dropdown", UDim2.new(1, -100, 1, 0)).TextSize = 13
            local selFrame = Instance.new("Frame", c)
            selFrame.Size = UDim2.new(0, 90, 0, 28)
            selFrame.Position = UDim2.new(1, -90, 0.5, -14)
            selFrame.BackgroundColor3 = Theme.WindowBG
            selFrame.BorderSizePixel = 0
            Corner(selFrame, 6)
            Stroke(selFrame, Theme.ElementStroke, 1)
            local selLabel = Label(selFrame, sel, UDim2.new(1, -18, 1, 0), Theme.TextPrimary)
            selLabel.Position = UDim2.new(0, 6, 0, 0)
            selLabel.Font = Theme.FontMain
            selLabel.TextSize = 11
            local arrow = Label(selFrame, "▼", UDim2.new(0, 14, 1, 0), Theme.TextMuted, Enum.TextXAlignment.Center)
            arrow.Position = UDim2.new(1, -16, 0, 0)
            arrow.TextSize = 12

            local popup = Instance.new("Frame", SG)
            popup.Size = UDim2.new(0, 100, 0, 0)
            popup.BackgroundColor3 = Theme.ElementBG
            popup.BorderSizePixel = 0
            popup.ClipsDescendants = true
            popup.Visible = false
            popup.ZIndex = 160
            Corner(popup, 6)
            Stroke(popup, Theme.ElementStroke, 1)

            local scroller = Instance.new("ScrollingFrame", popup)
            scroller.Size = UDim2.new(1, 0, 1, 0)
            scroller.BackgroundTransparency = 1
            scroller.ScrollBarThickness = 2
            scroller.ScrollBarImageColor3 = Theme.Accent
            scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
            scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
            Padding(scroller, 4, 4, 4, 4)
            local list = Instance.new("UIListLayout", scroller)
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.Padding = UDim.new(0, 2)

            for i, opt in ipairs(opts) do
                local ob = Instance.new("TextButton", scroller)
                ob.Size = UDim2.new(1, 0, 0, 30)
                ob.BackgroundColor3 = Theme.ElementHov
                ob.BorderSizePixel = 0
                ob.Text = opt
                ob.TextSize = 11
                ob.Font = Theme.FontMain
                ob.TextColor3 = Theme.TextSecondary
                ob.TextXAlignment = Enum.TextXAlignment.Left
                ob.AutoButtonColor = false
                ob.LayoutOrder = i
                Corner(ob, 4)
                Padding(ob, 0, 0, 8, 0)
                OnClick(ob, function()
                    sel = opt
                    selLabel.Text = opt
                    pcall(cfg.Callback or function() end, sel)
                    closePop()
                end)
                ob.MouseEnter:Connect(function() ob.BackgroundColor3 = Theme.TabHover end)
                ob.MouseLeave:Connect(function() ob.BackgroundColor3 = Theme.ElementHov end)
            end

            local function closePop()
                if not open then return end
                open = false
                Tween(popup, { Size = UDim2.new(0, 100, 0, 0) }, 0.18)
                arrow.Text = "▼"
                task.delay(0.2, function() popup.Visible = false end)
            end

            local function openPop()
                local pos = selFrame.AbsolutePosition
                local w = math.max(selFrame.AbsoluteSize.X + 10, 100)
                local vp = workspace.CurrentCamera.ViewportSize
                local x = math.min(pos.X, vp.X - w - 4)
                local below = vp.Y - (pos.Y + selFrame.AbsoluteSize.Y + 4)
                local above = pos.Y - 4
                local maxH = math.min(#opts * 32 + 8, 160)
                local y = (below >= maxH or below >= above) and (pos.Y + selFrame.AbsoluteSize.Y + 4) or (pos.Y - maxH - 4)
                popup.Position = UDim2.new(0, x, 0, y)
                popup.Size = UDim2.new(0, w, 0, 0)
                popup.Visible = true
                open = true
                Tween(popup, { Size = UDim2.new(0, w, 0, maxH) }, 0.22)
                arrow.Text = "▲"
            end

            local hit = Instance.new("TextButton", c)
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            OnClick(hit, function() if open then closePop() else openPop() end end)
            hit.MouseEnter:Connect(function() Tween(c, { BackgroundColor3 = Theme.ElementHov }, 0.15) end)
            hit.MouseLeave:Connect(function() Tween(c, { BackgroundColor3 = Theme.ElementBG }, 0.15) end)

            UserInput.InputBegan:Connect(function(i)
                if not open or not isMouseDown(i) then return end
                task.defer(function()
                    if not open then return end
                    local pos = i.Position
                    local pp = popup.AbsolutePosition
                    local ps = popup.AbsoluteSize
                    local cp = c.AbsolutePosition
                    local cs = c.AbsoluteSize
                    local inPopup = pos.X >= pp.X and pos.X <= pp.X + ps.X and pos.Y >= pp.Y and pos.Y <= pp.Y + ps.Y
                    local inBtn = pos.X >= cp.X and pos.X <= cp.X + cs.X and pos.Y >= cp.Y and pos.Y <= cp.Y + cs.Y
                    if not inPopup and not inBtn then closePop() end
                end)
            end)

            local api = {}
            function api:Set(v) sel = v; selLabel.Text = v; pcall(cfg.Callback or function() end, v) end
            function api:Get() return sel end
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        -- MultiDropdown
        function Tab:CreateMultiDropdown(cfg)
            cfg = cfg or {}
            local opts = cfg.Options or {}
            local selected = {}
            for _, d in ipairs(cfg.Default or {}) do selected[d] = true end
            local open = false
            local c = Card(44)
            Padding(c, 0, 0, 12, 12)
            Label(c, cfg.Title or "Multi-Dropdown", UDim2.new(1, -100, 1, 0)).TextSize = 13
            local selFrame = Instance.new("Frame", c)
            selFrame.Size = UDim2.new(0, 100, 0, 28)
            selFrame.Position = UDim2.new(1, -100, 0.5, -14)
            selFrame.BackgroundColor3 = Theme.WindowBG
            selFrame.BorderSizePixel = 0
            Corner(selFrame, 6)
            Stroke(selFrame, Theme.ElementStroke, 1)
            local selLabel = Label(selFrame, table.concat(cfg.Default or {}, ", "), UDim2.new(1, -18, 1, 0), Theme.TextPrimary)
            selLabel.Position = UDim2.new(0, 6, 0, 0)
            selLabel.Font = Theme.FontMain
            selLabel.TextSize = 10
            local arrow = Label(selFrame, "▼", UDim2.new(0, 14, 1, 0), Theme.TextMuted, Enum.TextXAlignment.Center)
            arrow.Position = UDim2.new(1, -16, 0, 0)
            arrow.TextSize = 12

            local popup = Instance.new("Frame", SG)
            popup.Size = UDim2.new(0, 150, 0, 0)
            popup.BackgroundColor3 = Theme.ElementBG
            popup.BorderSizePixel = 0
            popup.ClipsDescendants = true
            popup.Visible = false
            popup.ZIndex = 160
            Corner(popup, 6)
            Stroke(popup, Theme.ElementStroke, 1)

            local scroller = Instance.new("ScrollingFrame", popup)
            scroller.Size = UDim2.new(1, 0, 1, 0)
            scroller.BackgroundTransparency = 1
            scroller.ScrollBarThickness = 2
            scroller.ScrollBarImageColor3 = Theme.Accent
            scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
            scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
            Padding(scroller, 4, 4, 4, 4)
            local list = Instance.new("UIListLayout", scroller)
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.Padding = UDim.new(0, 2)

            local function updateText()
                local t = {}
                for k, v in pairs(selected) do if v then table.insert(t, k) end end
                selLabel.Text = table.concat(t, ", ")
                pcall(cfg.Callback or function() end, t)
            end

            for i, opt in ipairs(opts) do
                local row = Instance.new("Frame", scroller)
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundColor3 = Theme.ElementHov
                row.BorderSizePixel = 0
                row.LayoutOrder = i
                Corner(row, 4)
                local chk = Instance.new("TextButton", row)
                chk.Size = UDim2.new(0, 20, 0, 20)
                chk.Position = UDim2.new(0, 6, 0.5, -10)
                chk.BackgroundColor3 = selected[opt] and Theme.Accent or Theme.ToggleOff
                chk.BorderSizePixel = 0
                chk.Text = selected[opt] and "✓" or ""
                chk.TextColor3 = Color3.fromRGB(255, 255, 255)
                chk.Font = Theme.FontBold
                chk.TextSize = 12
                Corner(chk, 4)
                local lbl = Label(row, opt, UDim2.new(1, -34, 1, 0), Theme.TextSecondary)
                lbl.Position = UDim2.new(0, 34, 0, 0)
                lbl.Font = Theme.FontMain
                lbl.TextSize = 11
                OnClick(chk, function()
                    selected[opt] = not selected[opt]
                    chk.BackgroundColor3 = selected[opt] and Theme.Accent or Theme.ToggleOff
                    chk.Text = selected[opt] and "✓" or ""
                    updateText()
                end)
                row.MouseEnter:Connect(function() row.BackgroundColor3 = Theme.TabHover end)
                row.MouseLeave:Connect(function() row.BackgroundColor3 = Theme.ElementHov end)
            end

            local function closePop()
                if not open then return end
                open = false
                Tween(popup, { Size = UDim2.new(0, 150, 0, 0) }, 0.18)
                arrow.Text = "▼"
                task.delay(0.2, function() popup.Visible = false end)
            end

            local function openPop()
                local pos = selFrame.AbsolutePosition
                local w = math.max(selFrame.AbsoluteSize.X + 10, 150)
                local vp = workspace.CurrentCamera.ViewportSize
                local x = math.min(pos.X, vp.X - w - 4)
                local below = vp.Y - (pos.Y + selFrame.AbsoluteSize.Y + 4)
                local above = pos.Y - 4
                local maxH = math.min(#opts * 32 + 8, 180)
                local y = (below >= maxH or below >= above) and (pos.Y + selFrame.AbsoluteSize.Y + 4) or (pos.Y - maxH - 4)
                popup.Position = UDim2.new(0, x, 0, y)
                popup.Size = UDim2.new(0, w, 0, 0)
                popup.Visible = true
                open = true
                Tween(popup, { Size = UDim2.new(0, w, 0, maxH) }, 0.22)
                arrow.Text = "▲"
            end

            local hit = Instance.new("TextButton", c)
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            OnClick(hit, function() if open then closePop() else openPop() end end)
            hit.MouseEnter:Connect(function() Tween(c, { BackgroundColor3 = Theme.ElementHov }, 0.15) end)
            hit.MouseLeave:Connect(function() Tween(c, { BackgroundColor3 = Theme.ElementBG }, 0.15) end)

            UserInput.InputBegan:Connect(function(i)
                if not open or not isMouseDown(i) then return end
                task.defer(function()
                    if not open then return end
                    local pos = i.Position
                    local pp = popup.AbsolutePosition
                    local ps = popup.AbsoluteSize
                    local cp = c.AbsolutePosition
                    local cs = c.AbsoluteSize
                    local inPopup = pos.X >= pp.X and pos.X <= pp.X + ps.X and pos.Y >= pp.Y and pos.Y <= pp.Y + ps.Y
                    local inBtn = pos.X >= cp.X and pos.X <= cp.X + cs.X and pos.Y >= cp.Y and pos.Y <= cp.Y + cs.Y
                    if not inPopup and not inBtn then closePop() end
                end)
            end)

            local api = {}
            function api:Set(tbl)
                for k in pairs(selected) do selected[k] = false end
                for _, v in ipairs(tbl) do selected[v] = true end
                updateText()
            end
            function api:Get()
                local r = {}
                for k, v in pairs(selected) do if v then table.insert(r, k) end end
                return r
            end
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        -- InputNumber
        function Tab:CreateInputNumber(cfg)
            cfg = cfg or {}
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local step = cfg.Step or 1
            local val = math.clamp(cfg.Default or min, min, max)
            local c = Card(44)
            Padding(c, 0, 0, 12, 12)
            Label(c, cfg.Title or "Number", UDim2.new(1, -128, 1, 0)).TextSize = 13
            local row = Instance.new("Frame", c)
            row.Size = UDim2.new(0, 116, 0, 30)
            row.Position = UDim2.new(1, -120, 0.5, -15)
            row.BackgroundTransparency = 1
            local minus = Instance.new("TextButton", row)
            minus.Size = UDim2.new(0, 30, 1, 0)
            minus.BackgroundColor3 = Theme.ElementHov
            minus.BorderSizePixel = 0
            minus.Text = "−"
            minus.TextSize = 16
            minus.Font = Theme.FontBold
            minus.TextColor3 = Theme.TextPrimary
            minus.AutoButtonColor = false
            Corner(minus, 6)
            local valFrame = Instance.new("Frame", row)
            valFrame.Size = UDim2.new(0, 50, 1, 0)
            valFrame.Position = UDim2.new(0, 34, 0, 0)
            valFrame.BackgroundColor3 = Theme.WindowBG
            valFrame.BorderSizePixel = 0
            Corner(valFrame, 6)
            Stroke(valFrame, Theme.ElementStroke, 1)
            local valLabel = Label(valFrame, tostring(val), UDim2.new(1, 0, 1, 0), Theme.TextPrimary, Enum.TextXAlignment.Center)
            valLabel.Font = Theme.FontBold
            valLabel.TextSize = 13
            local plus = Instance.new("TextButton", row)
            plus.Size = UDim2.new(0, 30, 1, 0)
            plus.Position = UDim2.new(0, 88, 0, 0)
            plus.BackgroundColor3 = Theme.ElementHov
            plus.BorderSizePixel = 0
            plus.Text = "+"
            plus.TextSize = 16
            plus.Font = Theme.FontBold
            plus.TextColor3 = Theme.TextPrimary
            plus.AutoButtonColor = false
            Corner(plus, 6)
            local api = {}
            local function update()
                valLabel.Text = tostring(val)
                pcall(cfg.Callback or function() end, val)
            end
            function api:Set(v) val = math.clamp(v, min, max); update() end
            function api:Get() return val end
            OnClick(minus, function()
                val = math.clamp(val - step, min, max)
                update()
                Tween(minus, { BackgroundColor3 = Theme.AccentDark }, 0.1)
                task.delay(0.15, function() Tween(minus, { BackgroundColor3 = Theme.ElementHov }, 0.15) end)
            end)
            OnClick(plus, function()
                val = math.clamp(val + step, min, max)
                update()
                Tween(plus, { BackgroundColor3 = Theme.AccentDark }, 0.1)
                task.delay(0.15, function() Tween(plus, { BackgroundColor3 = Theme.ElementHov }, 0.15) end)
            end)
            minus.MouseEnter:Connect(function() minus.BackgroundColor3 = Theme.TabHover end)
            minus.MouseLeave:Connect(function() minus.BackgroundColor3 = Theme.ElementHov end)
            plus.MouseEnter:Connect(function() plus.BackgroundColor3 = Theme.TabHover end)
            plus.MouseLeave:Connect(function() plus.BackgroundColor3 = Theme.ElementHov end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        -- ProgressBar
        function Tab:CreateProgressBar(cfg)
            cfg = cfg or {}
            local val = math.clamp(cfg.Default or 0, 0, 100)
            local c = Card(54)
            Padding(c, 8, 8, 12, 12)
            local top = Instance.new("Frame", c)
            top.Size = UDim2.new(1, 0, 0, 20)
            top.BackgroundTransparency = 1
            Label(top, cfg.Title or "Progress", UDim2.new(1, -42, 1, 0))
            local pctLabel = Label(top, val .. "%", UDim2.new(0, 40, 1, 0), Theme.Accent, Enum.TextXAlignment.Right)
            pctLabel.Position = UDim2.new(1, -40, 0, 0)
            pctLabel.Font = Theme.FontBold
            local track = Instance.new("Frame", c)
            track.Size = UDim2.new(1, 0, 0, 12)
            track.Position = UDim2.new(0, 0, 1, -18)
            track.BackgroundColor3 = Theme.ToggleOff
            track.BorderSizePixel = 0
            Corner(track, 6)
            local fill = Instance.new("Frame", track)
            fill.Size = UDim2.new(val / 100, 0, 1, 0)
            fill.BackgroundColor3 = Theme.Accent
            fill.BorderSizePixel = 0
            Corner(fill, 6)
            local shine = Instance.new("Frame", fill)
            shine.Size = UDim2.new(1, 0, 0.5, 0)
            shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            shine.BackgroundTransparency = 0.85
            shine.BorderSizePixel = 0
            Corner(shine, 6)
            local api = {}
            function api:Set(v)
                val = math.clamp(v, 0, 100)
                local p = val / 100
                Tween(fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.3)
                pctLabel.Text = val .. "%"
                local color = val >= 100 and Color3.fromRGB(34, 197, 94) or Theme.Accent
                Tween(fill, { BackgroundColor3 = color }, 0.3)
                pcall(cfg.Callback or function() end, val)
            end
            function api:Get() return val end
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        -- ColorPicker (simplified but working)
        function Tab:CreateColorPicker(cfg)
            cfg = cfg or {}
            local col = cfg.Default or Color3.fromRGB(255, 255, 255)
            local r, g, b = col.R, col.G, col.B
            local c = Card(44)
            Padding(c, 0, 0, 12, 12)
            Label(c, cfg.Title or "Color", UDim2.new(1, -58, 1, 0)).TextSize = 13
            local swatch = Instance.new("Frame", c)
            swatch.Size = UDim2.new(0, 34, 0, 24)
            swatch.Position = UDim2.new(1, -38, 0.5, -12)
            swatch.BackgroundColor3 = col
            swatch.BorderSizePixel = 0
            Corner(swatch, 5)
            Stroke(swatch, Theme.ElementStroke, 1)
            local pickerFrame = nil
            local api = {}
            function api:Set(nc) col = nc; swatch.BackgroundColor3 = nc; pcall(cfg.Callback or function() end, nc) end
            function api:Get() return col end
            OnClick(swatch, function()
                if pickerFrame then pickerFrame:Destroy() end
                pickerFrame = Instance.new("Frame", SG)
                pickerFrame.Size = UDim2.new(0, 200, 0, 170)
                pickerFrame.Position = UDim2.new(0.5, -100, 0.5, -85)
                pickerFrame.BackgroundColor3 = Theme.ElementBG
                pickerFrame.BorderSizePixel = 0
                pickerFrame.ZIndex = 300
                Corner(pickerFrame, 8)
                Stroke(pickerFrame, Theme.Accent, 1)
                local redSlider = Instance.new("Frame", pickerFrame)
                redSlider.Size = UDim2.new(0.8, 0, 0, 16)
                redSlider.Position = UDim2.new(0.1, 0, 0.15, 0)
                redSlider.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                Corner(redSlider, 4)
                local redFill = Instance.new("Frame", redSlider)
                redFill.Size = UDim2.new(r, 0, 1, 0)
                redFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                redFill.BorderSizePixel = 0
                Corner(redFill, 4)
                local greenSlider = Instance.new("Frame", pickerFrame)
                greenSlider.Size = UDim2.new(0.8, 0, 0, 16)
                greenSlider.Position = UDim2.new(0.1, 0, 0.35, 0)
                greenSlider.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                Corner(greenSlider, 4)
                local greenFill = Instance.new("Frame", greenSlider)
                greenFill.Size = UDim2.new(g, 0, 1, 0)
                greenFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                greenFill.BorderSizePixel = 0
                Corner(greenFill, 4)
                local blueSlider = Instance.new("Frame", pickerFrame)
                blueSlider.Size = UDim2.new(0.8, 0, 0, 16)
                blueSlider.Position = UDim2.new(0.1, 0, 0.55, 0)
                blueSlider.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
                Corner(blueSlider, 4)
                local blueFill = Instance.new("Frame", blueSlider)
                blueFill.Size = UDim2.new(b, 0, 1, 0)
                blueFill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
                blueFill.BorderSizePixel = 0
                Corner(blueFill, 4)
                local preview = Instance.new("Frame", pickerFrame)
                preview.Size = UDim2.new(0.8, 0, 0, 24)
                preview.Position = UDim2.new(0.1, 0, 0.75, 0)
                preview.BackgroundColor3 = col
                preview.BorderSizePixel = 0
                Corner(preview, 6)
                Stroke(preview, Theme.ElementStroke, 1)
                local okBtn = Instance.new("TextButton", pickerFrame)
                okBtn.Size = UDim2.new(0.35, 0, 0, 26)
                okBtn.Position = UDim2.new(0.55, 0, 0.88, 0)
                okBtn.Text = "OK"
                okBtn.BackgroundColor3 = Theme.Accent
                okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                okBtn.Font = Theme.FontBold
                Corner(okBtn, 6)
                local cancelBtn = Instance.new("TextButton", pickerFrame)
                cancelBtn.Size = UDim2.new(0.35, 0, 0, 26)
                cancelBtn.Position = UDim2.new(0.1, 0, 0.88, 0)
                cancelBtn.Text = "Cancel"
                cancelBtn.BackgroundColor3 = Theme.ElementHov
                cancelBtn.TextColor3 = Theme.TextPrimary
                cancelBtn.Font = Theme.FontMain
                Corner(cancelBtn, 6)
                local function updateColor()
                    local nc = Color3.new(r, g, b)
                    preview.BackgroundColor3 = nc
                    swatch.BackgroundColor3 = nc
                    redFill.Size = UDim2.new(r, 0, 1, 0)
                    greenFill.Size = UDim2.new(g, 0, 1, 0)
                    blueFill.Size = UDim2.new(b, 0, 1, 0)
                end
                local function startDrag(slider, fill, channel)
                    local dragging = false
                    slider.InputBegan:Connect(function(i)
                        if isMouseDown(i) then
                            dragging = true
                            local x = math.clamp((i.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                            if channel == "r" then r = x elseif channel == "g" then g = x else b = x end
                            updateColor()
                        end
                    end)
                    UserInput.InputChanged:Connect(function(i)
                        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                            local x = math.clamp((i.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                            if channel == "r" then r = x elseif channel == "g" then g = x else b = x end
                            updateColor()
                        end
                    end)
                    UserInput.InputEnded:Connect(function(i)
                        if isMouseDown(i) then dragging = false end
                    end)
                end
                startDrag(redSlider, redFill, "r")
                startDrag(greenSlider, greenFill, "g")
                startDrag(blueSlider, blueFill, "b")
                OnClick(okBtn, function()
                    col = Color3.new(r, g, b)
                    swatch.BackgroundColor3 = col
                    pcall(cfg.Callback or function() end, col)
                    pickerFrame:Destroy()
                end)
                OnClick(cancelBtn, function() pickerFrame:Destroy() end)
            end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        -- Keybind
        function Tab:CreateKeybind(cfg)
            cfg = cfg or {}
            local key = cfg.Default or Enum.KeyCode.RightShift
            local listening = false
            local c = Card(44)
            Padding(c, 0, 0, 12, 12)
            Label(c, cfg.Title or "Keybind", UDim2.new(1, -90, 1, 0)).TextSize = 13
            local btn = Instance.new("TextButton", c)
            btn.Size = UDim2.new(0, 82, 0, 30)
            btn.Position = UDim2.new(1, -86, 0.5, -15)
            btn.BackgroundColor3 = Theme.WindowBG
            btn.BorderSizePixel = 0
            btn.TextSize = 11
            btn.Font = Theme.FontBold
            btn.TextColor3 = Theme.Accent
            btn.AutoButtonColor = false
            Corner(btn, 6)
            Stroke(btn, Theme.ElementStroke, 1)
            local function keyName(k)
                local n = tostring(k):gsub("Enum.KeyCode.", "")
                return n == "Unknown" and "None" or n
            end
            btn.Text = "[" .. keyName(key) .. "]"
            local api = {}
            function api:Set(k) key = k; if not listening then btn.Text = "[" .. keyName(k) .. "]" end end
            function api:Get() return key end
            OnClick(btn, function()
                if listening then
                    listening = false
                    btn.BackgroundColor3 = Theme.WindowBG
                    btn.Text = "[" .. keyName(key) .. "]"
                    return
                end
                listening = true
                btn.BackgroundColor3 = Theme.TabHover
                btn.Text = "[ ... ]"
                local conn
                conn = UserInput.InputBegan:Connect(function(i, gp)
                    if not listening then if conn then conn:Disconnect() end return end
                    if gp then return end
                    if i.UserInputType == Enum.UserInputType.Keyboard then
                        if i.KeyCode == Enum.KeyCode.Escape then
                            listening = false
                            btn.BackgroundColor3 = Theme.WindowBG
                            btn.Text = "[" .. keyName(key) .. "]"
                            if conn then conn:Disconnect() end
                            return
                        end
                        key = i.KeyCode
                        listening = false
                        btn.BackgroundColor3 = Theme.WindowBG
                        btn.Text = "[" .. keyName(key) .. "]"
                        if conn then conn:Disconnect() end
                        pcall(cfg.Callback or function() end, key)
                    end
                end)
                addConnection(conn)
            end)
            btn.MouseEnter:Connect(function() Tween(c, { BackgroundColor3 = Theme.ElementHov }, 0.15) end)
            btn.MouseLeave:Connect(function() Tween(c, { BackgroundColor3 = Theme.ElementBG }, 0.15) end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        return Tab
    end

    ShowLoading(SG, Theme.Accent, title, function()
        Win.Visible = true
        Win.BackgroundTransparency = 1
        Wrapper.Position = UDim2.new(0.5, -280 - 32, 0.5, -130)
        Tween(Wrapper, { Position = UDim2.new(0.5, -280 - 32, 0.5, -170) }, 0.55, Enum.EasingStyle.Back)
        task.delay(0.05, function() Tween(Win, { BackgroundTransparency = 0 }, 0.45) end)
        syncToggleBtnY(340)
        task.delay(0.6, function() lastWrapperPos = Wrapper.Position end)
    end)

    return Window
end

return KreinGui
