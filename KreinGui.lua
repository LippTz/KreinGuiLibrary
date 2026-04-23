--[[
    KreinGui v5.3 – GUI Library by @uniquadev (Stable)
    - All file/clipboard functions protected with pcall
    - No errors on executors without writefile/readfile support
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
local waveConnections = {}
local currentGui = nil

local function addConnection(conn)
    table.insert(activeConnections, conn)
    return conn
end

local function destroyAllConnections()
    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, conn in ipairs(waveConnections) do
        pcall(function() conn:Disconnect() end)
    end
    activeConnections = {}
    waveConnections = {}
end

-- ============================================================
-- INPUT HELPERS
-- ============================================================
local function isDown(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch
end

local function OnClick(btn, fn)
    local down, sp = false, nil
    local con1 = btn.InputBegan:Connect(function(i)
        if isDown(i) then down=true; sp=i.Position end
    end)
    local con2 = btn.InputEnded:Connect(function(i)
        if isDown(i) and down then
            down=false
            if sp and (i.Position-sp).Magnitude <= 12 then fn() end
        end
    end)
    local con3 = btn.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch and sp then
            if (i.Position-sp).Magnitude > 12 then down=false end
        end
    end)
    addConnection(con1); addConnection(con2); addConnection(con3)
end

-- ============================================================
-- THEME (Soft & Modern)
-- ============================================================
local Theme = {
    WindowBG = Color3.fromRGB(18, 22, 28),
    HeaderBG = Color3.fromRGB(22, 26, 34),
    TabBG = Color3.fromRGB(20, 24, 31),
    ElementBG = Color3.fromRGB(26, 30, 38),
    ElementHov = Color3.fromRGB(34, 39, 48),
    ElementStroke = Color3.fromRGB(48, 54, 66),
    TabInactive = Color3.fromRGB(20, 24, 31),
    TabHover = Color3.fromRGB(42, 48, 60),
    TabActive = Color3.fromRGB(20, 184, 166),
    TabInactiveText = Color3.fromRGB(140, 152, 170),
    TabActiveText = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(20, 184, 166),
    AccentHover = Color3.fromRGB(45, 212, 191),
    AccentDark = Color3.fromRGB(15, 138, 125),
    ToggleOff = Color3.fromRGB(45, 50, 60),
    ToggleOn = Color3.fromRGB(20, 184, 166),
    TextPrimary = Color3.fromRGB(240, 243, 250),
    TextSecondary = Color3.fromRGB(170, 180, 200),
    TextMuted = Color3.fromRGB(110, 120, 140),
    SectionText = Color3.fromRGB(20, 184, 166),
    CloseRed = Color3.fromRGB(255, 90, 90),
    MinGray = Color3.fromRGB(180, 190, 210),
    Separator = Color3.fromRGB(45, 50, 60),
    StrokeColor = Color3.fromRGB(50, 56, 70),
    FontMain = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
}

local Presets = {
    Default = { Accent = Color3.fromRGB(20, 184, 166) },
    Neon = { Accent = Color3.fromRGB(0, 255, 180) },
    Blood = { Accent = Color3.fromRGB(255, 51, 85) },
    Ocean = { Accent = Color3.fromRGB(0, 150, 255) },
    Purple = { Accent = Color3.fromRGB(176, 96, 255) },
    Gold = { Accent = Color3.fromRGB(255, 194, 0) },
    Rose = { Accent = Color3.fromRGB(255, 80, 144) },
}

-- ============================================================
-- UI HELPERS
-- ============================================================
local function Tween(obj, props, duration, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function SmoothTween(obj, props, duration, style, dir)
    return Tween(obj, props, duration or 0.25, style or Enum.EasingStyle.Cubic, dir or Enum.EasingDirection.Out)
end

local function Corner(frame, radius)
    local c = Instance.new("UICorner", frame)
    c.CornerRadius = UDim.new(0, radius or 12)
    return c
end

local function Stroke(frame, color, thickness)
    local s = Instance.new("UIStroke", frame)
    s.Color = color or Theme.StrokeColor
    s.Thickness = thickness or 1
    return s
end

local function Padding(frame, t, b, l, r)
    local p = Instance.new("UIPadding", frame)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
end

local function Label(parent, text, size, color, alignX, font)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Size = size or UDim2.new(1, 0, 1, 0)
    l.Text = text or ""
    l.TextSize = 13
    l.TextColor3 = color or Theme.TextPrimary
    l.Font = font or Theme.FontMain
    l.TextXAlignment = alignX or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextWrapped = true
    return l
end

local function HSV(h, s, v) return Color3.fromHSV(h, s, v) end
local function ToHSV(c) return Color3.toHSV(c) end
local function ToHex(c) return string.format("%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)) end

-- ============================================================
-- NOTIFICATION QUEUE
-- ============================================================
local notificationQueue = {}
local notifActive = false
local function showNextNotification(SG)
    if notifActive or #notificationQueue == 0 then return end
    notifActive = true
    local data = table.remove(notificationQueue, 1)
    local N = Instance.new("Frame", SG)
    N.Size = UDim2.new(0, 280, 0, 48)
    N.Position = UDim2.new(1, 10, 1, -64)
    N.BackgroundColor3 = Theme.ElementBG
    N.BackgroundTransparency = 0.05
    N.BorderSizePixel = 0
    N.ZIndex = 200
    Corner(N, 10)
    Stroke(N, Theme.Accent, 1)
    local Bar = Instance.new("Frame", N)
    Bar.Size = UDim2.new(0, 3, 0.7, 0)
    Bar.Position = UDim2.new(0, 0, 0.15, 0)
    Bar.BackgroundColor3 = Theme.Accent
    Bar.BorderSizePixel = 0
    Corner(Bar, 3)
    local nl = Label(N, data.msg, UDim2.new(1, -18, 1, 0), Theme.TextPrimary)
    nl.Position = UDim2.new(0, 14, 0, 0)
    nl.Font = Theme.FontMain
    nl.TextSize = 12
    nl.TextWrapped = true
    SmoothTween(N, { Position = UDim2.new(1, -290, 1, -64) }, 0.3)
    task.delay(data.dur or 3, function()
        SmoothTween(N, { Position = UDim2.new(1, 10, 1, -64) }, 0.3)
        task.delay(0.35, function()
            N:Destroy()
            notifActive = false
            showNextNotification(SG)
        end)
    end)
end
local function Notify(SG, msg, dur)
    table.insert(notificationQueue, { msg = msg, dur = dur or 3 })
    showNextNotification(SG)
end

-- ============================================================
-- TOOLTIP SYSTEM
-- ============================================================
local activeTooltip = nil
local function ShowTooltip(text, parent)
    if activeTooltip then activeTooltip:Destroy() end
    local tip = Instance.new("Frame", parent)
    tip.Size = UDim2.new(0, 0, 0, 28)
    tip.BackgroundColor3 = Theme.ElementBG
    tip.BackgroundTransparency = 0.1
    tip.BorderSizePixel = 0
    tip.ZIndex = 200
    tip.Visible = false
    Corner(tip, 8)
    Stroke(tip, Theme.Accent, 1)
    local lbl = Label(tip, text, UDim2.new(1, -12, 1, 0), Theme.TextPrimary)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local ap = parent.AbsolutePosition
    local x = ap.X
    local y = ap.Y - 34
    tip.Position = UDim2.new(0, x, 0, y)
    tip.Size = UDim2.new(0, lbl.TextBounds.X + 20, 0, 28)
    tip.Visible = true
    tip.BackgroundTransparency = 1
    tip.Size = UDim2.new(0, tip.Size.X.Offset, 0, 0)
    SmoothTween(tip, { BackgroundTransparency = 0.1, Size = UDim2.new(0, tip.Size.X.Offset, 0, 28) }, 0.15)
    activeTooltip = tip
    tip.Destroying:Connect(function()
        if activeTooltip == tip then activeTooltip = nil end
    end)
end
local function HideTooltip()
    if activeTooltip then
        SmoothTween(activeTooltip, { BackgroundTransparency = 1, Size = UDim2.new(0, activeTooltip.Size.X.Offset, 0, 0) }, 0.1)
        task.delay(0.12, function() if activeTooltip then activeTooltip:Destroy() end end)
    end
end

-- ============================================================
-- WAVE ANIMATION (Header)
-- ============================================================
local function StartWaveAnimation(abar, accent)
    local BaseLine = Instance.new("Frame", abar)
    BaseLine.Size = UDim2.new(1, 0, 1, 0)
    BaseLine.BackgroundColor3 = accent
    BaseLine.BackgroundTransparency = 0.6
    BaseLine.BorderSizePixel = 0
    BaseLine.ZIndex = 2

    local Wave = Instance.new("Frame", abar)
    Wave.Size = UDim2.new(0.4, 0, 1, 0)
    Wave.BackgroundTransparency = 1
    Wave.BorderSizePixel = 0
    Wave.ZIndex = 4

    local grad = Instance.new("UIGradient", Wave)
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.3, 0.1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.7, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    grad.Color = ColorSequence.new(accent, Color3.fromRGB(255, 255, 255))

    local t = 0
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not abar or not abar.Parent then conn:Disconnect(); return end
        t = (t + dt * 0.4) % 1
        Wave.Position = UDim2.new(t - 0.4, 0, 0, 0)
    end)
    addConnection(conn)
    table.insert(waveConnections, conn)
end

-- ============================================================
-- LOADING SCREEN
-- ============================================================
local function ShowLoading(SG, accent, title, onDone)
    local Overlay = Instance.new("Frame", SG)
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0
    Overlay.BorderSizePixel = 0
    Overlay.ZIndex = 100

    local Box = Instance.new("Frame", Overlay)
    Box.Size = UDim2.new(0, 320, 0, 140)
    Box.Position = UDim2.new(0.5, -160, 0.5, -70)
    Box.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    Box.BackgroundTransparency = 0.05
    Box.BorderSizePixel = 0
    Corner(Box, 16)
    Stroke(Box, accent, 1.5)

    local TitleLbl = Label(Box, title, UDim2.new(1, 0, 0, 38), accent)
    TitleLbl.Position = UDim2.new(0, 0, 0, 20)
    TitleLbl.Font = Theme.FontBold
    TitleLbl.TextSize = 18
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Center

    local SubLbl = Label(Box, "Initializing...", UDim2.new(1, 0, 0, 20), Theme.TextMuted)
    SubLbl.Position = UDim2.new(0, 0, 0, 62)
    SubLbl.TextSize = 11
    SubLbl.TextXAlignment = Enum.TextXAlignment.Center

    local BarTrack = Instance.new("Frame", Box)
    BarTrack.Size = UDim2.new(0, 240, 0, 4)
    BarTrack.Position = UDim2.new(0.5, -120, 0, 96)
    BarTrack.BackgroundColor3 = Theme.ToggleOff
    BarTrack.BorderSizePixel = 0
    Corner(BarTrack, 2)

    local BarFill = Instance.new("Frame", BarTrack)
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = accent
    BarFill.BorderSizePixel = 0
    Corner(BarFill, 2)

    local steps = {
        { pct = 0.15, txt = "Loading modules..." },
        { pct = 0.35, txt = "Setting up UI..." },
        { pct = 0.55, txt = "Applying theme..." },
        { pct = 0.75, txt = "Building elements..." },
        { pct = 0.9,  txt = "Almost ready..." },
        { pct = 1.0,  txt = "Done!" },
    }

    task.spawn(function()
        Box.BackgroundTransparency = 0.05
        for _, step in ipairs(steps) do
            SubLbl.Text = step.txt
            SmoothTween(BarFill, { Size = UDim2.new(step.pct, 0, 1, 0) }, 0.22)
            task.wait(0.22)
        end
        task.wait(0.2)
        SmoothTween(Overlay, { BackgroundTransparency = 1 }, 0.4)
        task.wait(0.42)
        Overlay:Destroy()
        if onDone then onDone() end
    end)
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
            Theme.SectionText = v
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
function KreinGui:CreateWindow(cfg)
    if currentGui and currentGui.Parent then
        destroyAllConnections()
        currentGui:Destroy()
    end

    cfg = cfg or {}
    local title = cfg.Title or "KreinGui"
    local subtitle = cfg.SubTitle or ""
    local cfgName = cfg.ConfigName or "KreinGuiConfig"

    local SG = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    SG.Name = "KreinGui"
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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
    Wrapper.Size = UDim2.new(0, 560 + 32, 0, 380)
    Wrapper.Position = UDim2.new(0.5, -280 - 32, 0.5, -190)
    Wrapper.BackgroundTransparency = 1
    Wrapper.BorderSizePixel = 0
    Wrapper.ClipsDescendants = false

    local Win = Instance.new("Frame", Wrapper)
    Win.Size = UDim2.new(0, 560, 0, 380)
    Win.Position = UDim2.new(0, 32, 0, 0)
    Win.BackgroundColor3 = Theme.WindowBG
    Win.BackgroundTransparency = 0.08
    Win.BorderSizePixel = 0
    Win.ClipsDescendants = true
    Corner(Win, 16)
    Stroke(Win, Theme.Accent, 1.2)

    local Header = Instance.new("Frame", Win)
    Header.Size = UDim2.new(1, 0, 0, 56)
    Header.BackgroundColor3 = Theme.HeaderBG
    Header.BackgroundTransparency = 0.4
    Header.BorderSizePixel = 0
    Corner(Header, 16)

    local ABar = Instance.new("Frame", Win)
    ABar.Size = UDim2.new(1, 0, 0, 3)
    ABar.Position = UDim2.new(0, 0, 0, 56)
    ABar.BackgroundColor3 = Theme.Accent
    ABar.BackgroundTransparency = 0
    ABar.BorderSizePixel = 0
    StartWaveAnimation(ABar, Theme.Accent)

    local LogoBg = Instance.new("Frame", Header)
    LogoBg.Size = UDim2.new(0, 36, 0, 36)
    LogoBg.Position = UDim2.new(0, 12, 0.5, -18)
    LogoBg.BackgroundColor3 = Theme.Accent
    LogoBg.BackgroundTransparency = 0.2
    LogoBg.BorderSizePixel = 0
    Corner(LogoBg, 10)
    Stroke(LogoBg, Theme.Accent, 1)

    local LogoK = Label(LogoBg, "K", UDim2.new(1, 0, 1, 0), Color3.fromRGB(255, 255, 255))
    LogoK.Font = Theme.FontBold
    LogoK.TextSize = 20
    LogoK.TextXAlignment = Enum.TextXAlignment.Center

    local TitleLabel = Label(Header, title, UDim2.new(0, 260, 0, 24), Theme.TextPrimary)
    TitleLabel.Position = (subtitle ~= "") and UDim2.new(0, 58, 0, 8) or UDim2.new(0, 58, 0, 16)
    TitleLabel.Font = Theme.FontBold
    TitleLabel.TextSize = 16
    if subtitle ~= "" then
        local SubLabel = Label(Header, subtitle, UDim2.new(0, 260, 0, 18), Theme.TextMuted)
        SubLabel.Position = UDim2.new(0, 58, 0, 32)
        SubLabel.TextSize = 11
    end

    -- Close button
    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size = UDim2.new(0, 32, 0, 32)
    CloseBtn.Position = UDim2.new(1, -44, 0.5, -16)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 35, 35)
    CloseBtn.BackgroundTransparency = 0.2
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "X"
    CloseBtn.TextSize = 16
    CloseBtn.Font = Theme.FontBold
    CloseBtn.TextColor3 = Theme.CloseRed
    Corner(CloseBtn, 8)
    OnClick(CloseBtn, function() SG:Destroy() end)

    -- Minimize button
    local MinBtn = Instance.new("TextButton", Header)
    MinBtn.Size = UDim2.new(0, 32, 0, 32)
    MinBtn.Position = UDim2.new(1, -84, 0.5, -16)
    MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    MinBtn.BackgroundTransparency = 0.2
    MinBtn.BorderSizePixel = 0
    MinBtn.Text = "−"
    MinBtn.TextSize = 20
    MinBtn.Font = Theme.FontBold
    MinBtn.TextColor3 = Theme.MinGray
    Corner(MinBtn, 8)

    -- Toggle button (left side)
    local ToggleBtn = Instance.new("TextButton", Wrapper)
    ToggleBtn.Size = UDim2.new(0, 28, 0, 80)
    ToggleBtn.Position = UDim2.new(0, 0, 0.5, -40)
    ToggleBtn.BackgroundColor3 = Theme.WindowBG
    ToggleBtn.BackgroundTransparency = 0.2
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = ""
    Corner(ToggleBtn, 10)
    Stroke(ToggleBtn, Theme.Accent, 1)

    local ToggleIcon = Label(ToggleBtn, "◀", UDim2.new(1, 0, 0, 16), Theme.Accent)
    ToggleIcon.Position = UDim2.new(0, 0, 0.5, -26)
    ToggleIcon.Font = Theme.FontBold
    ToggleIcon.TextSize = 10
    ToggleIcon.TextXAlignment = Enum.TextXAlignment.Center

    local ToggleLetter = Label(ToggleBtn, "K", UDim2.new(1, 0, 0, 16), Theme.Accent)
    ToggleLetter.Position = UDim2.new(0, 0, 0.5, -5)
    ToggleLetter.Font = Theme.FontBold
    ToggleLetter.TextSize = 14
    ToggleLetter.TextXAlignment = Enum.TextXAlignment.Center

    local ToggleSub = Label(ToggleBtn, "GUI", UDim2.new(1, 0, 0, 12), Theme.TextMuted)
    ToggleSub.Position = UDim2.new(0, 0, 0.5, 14)
    ToggleSub.Font = Theme.FontBold
    ToggleSub.TextSize = 8
    ToggleSub.TextXAlignment = Enum.TextXAlignment.Center

    local ToggleGlow = Instance.new("Frame", ToggleBtn)
    ToggleGlow.Size = UDim2.new(0, 3, 0.65, 0)
    ToggleGlow.Position = UDim2.new(1, -3, 0.175, 0)
    ToggleGlow.BackgroundColor3 = Theme.Accent
    ToggleGlow.BackgroundTransparency = 0.4
    ToggleGlow.BorderSizePixel = 0
    Corner(ToggleGlow, 2)

    local Body = Instance.new("Frame", Win)
    Body.Size = UDim2.new(1, 0, 1, -56)
    Body.Position = UDim2.new(0, 0, 0, 56)
    Body.BackgroundTransparency = 1

    local TabPanel = Instance.new("Frame", Body)
    TabPanel.Size = UDim2.new(0, 140, 1, 0)
    TabPanel.BackgroundColor3 = Theme.TabBG
    TabPanel.BackgroundTransparency = 0.2
    TabPanel.BorderSizePixel = 0

    local TabSep = Instance.new("Frame", Body)
    TabSep.Size = UDim2.new(0, 1, 1, 0)
    TabSep.Position = UDim2.new(0, 140, 0, 0)
    TabSep.BackgroundColor3 = Theme.Separator
    TabSep.BorderSizePixel = 0

    local TabScroller = Instance.new("ScrollingFrame", TabPanel)
    TabScroller.Size = UDim2.new(1, 0, 1, 0)
    TabScroller.BackgroundTransparency = 1
    TabScroller.ScrollBarThickness = 2
    TabScroller.ScrollBarImageColor3 = Theme.Accent
    TabScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Padding(TabScroller, 12, 12, 8, 8)
    local TabLayout = Instance.new("UIListLayout", TabScroller)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 6)
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ContentArea = Instance.new("Frame", Body)
    ContentArea.Size = UDim2.new(1, -141, 1, 0)
    ContentArea.Position = UDim2.new(0, 141, 0, 0)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = true

    local SearchBox = Instance.new("TextBox", ContentArea)
    SearchBox.Size = UDim2.new(1, -20, 0, 32)
    SearchBox.Position = UDim2.new(0, 10, 0, 8)
    SearchBox.BackgroundColor3 = Theme.WindowBG
    SearchBox.BackgroundTransparency = 0.3
    SearchBox.BorderSizePixel = 0
    SearchBox.PlaceholderText = "🔍 Search flags..."
    SearchBox.TextColor3 = Theme.TextPrimary
    SearchBox.PlaceholderColor3 = Theme.TextMuted
    SearchBox.TextSize = 12
    SearchBox.Font = Theme.FontMain
    Corner(SearchBox, 10)
    Stroke(SearchBox, Theme.ElementStroke, 1)

    local ContentContainer = Instance.new("Frame", ContentArea)
    ContentContainer.Size = UDim2.new(1, 0, 1, -48)
    ContentContainer.Position = UDim2.new(0, 0, 0, 48)
    ContentContainer.BackgroundTransparency = 1

    local ResizeGrip = Instance.new("TextButton", Win)
    ResizeGrip.Size = UDim2.new(0, 14, 0, 14)
    ResizeGrip.Position = UDim2.new(1, -18, 1, -18)
    ResizeGrip.BackgroundColor3 = Theme.Accent
    ResizeGrip.BackgroundTransparency = 0.3
    ResizeGrip.Text = ""
    Corner(ResizeGrip, 4)

    -- State management
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
            ToggleGlow.BackgroundTransparency = 0.4
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
            Win.BackgroundTransparency = 0.08
            Win.Size = UDim2.new(0, 0, 0, curH)
            Win.Position = UDim2.new(0, 32, 0, 0)
            Wrapper.Position = lastWrapperPos
            SmoothTween(Win, { Size = lastWinSize }, 0.4)
            Wrapper.Size = lastWrapperSize
            syncToggleBtnY(lastWinSize.Y.Offset)
        else
            lastWrapperSize = Wrapper.Size
            lastWinSize = Win.Size
            lastWrapperPos = Wrapper.Position
            local curY = Wrapper.Position.Y
            SmoothTween(Win, { Size = UDim2.new(0, 0, 0, curH) }, 0.35)
            task.delay(0.35, function()
                Win.Visible = false
                Win.Size = lastWinSize
            end)
            SmoothTween(Wrapper, { Position = UDim2.new(0, -4, curY.Scale, curY.Offset) }, 0.35)
        end
        updateToggleIcon()
    end

    OnClick(ToggleBtn, toggleGui)

    OnClick(MinBtn, function()
        isMinimized = not isMinimized
        if isMinimized then
            MinBtn.Text = "+"
            resizeEnabled = false
            SmoothTween(Win, { Size = UDim2.new(0, 560, 0, 56) }, 0.3)
            SmoothTween(Wrapper, { Size = UDim2.new(0, 592, 0, 56) }, 0.3)
            task.delay(0.2, function()
                ABar.Visible = false
                syncToggleBtnY(56)
                lastWrapperSize = Wrapper.Size
                lastWinSize = Win.Size
            end)
        else
            MinBtn.Text = "−"
            resizeEnabled = true
            ABar.Visible = true
            SmoothTween(Win, { Size = UDim2.new(0, 560, 0, 380) }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            SmoothTween(Wrapper, { Size = UDim2.new(0, 592, 0, 380) }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            task.delay(0.35, function()
                syncToggleBtnY(380)
                lastWrapperSize = Wrapper.Size
                lastWinSize = Win.Size
            end)
        end
    end)

    local dragEnabled = true
    local function EnableDrag(frame, handle)
        handle = handle or frame
        local dragging = false
        local dragStart, frameStart
        handle.InputBegan:Connect(function(i)
            if isDown(i) and dragEnabled then
                dragging = true
                dragStart = i.Position
                frameStart = frame.Position
            end
        end)
        UserInput.InputChanged:Connect(function(i)
            if dragging and dragStart and dragEnabled and isMove(i) then
                local delta = i.Position - dragStart
                if delta.Magnitude > 6 then
                    frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
                end
            end
        end)
        UserInput.InputEnded:Connect(function(i)
            if isDown(i) then dragging = false end
        end)
    end
    EnableDrag(Wrapper, Header)

    local resizing = false
    local resizeStart, resizeStartSize
    ResizeGrip.InputBegan:Connect(function(i)
        if isDown(i) and resizeEnabled then
            resizing = true
            resizeStart = i.Position
            resizeStartSize = Wrapper.Size
            dragEnabled = false
        end
    end)
    UserInput.InputChanged:Connect(function(i)
        if resizing and isMove(i) and resizeEnabled then
            local delta = i.Position - resizeStart
            local newW = math.max(450, resizeStartSize.X.Offset + delta.X)
            local newH = math.max(250, resizeStartSize.Y.Offset + delta.Y)
            SmoothTween(Wrapper, { Size = UDim2.new(0, newW, 0, newH) }, 0.15)
            SmoothTween(Win, { Size = UDim2.new(0, newW - 32, 0, newH) }, 0.15)
            syncToggleBtnY(newH)
            lastWrapperSize = Wrapper.Size
            lastWinSize = Win.Size
        end
    end)
    UserInput.InputEnded:Connect(function(i)
        if isDown(i) then resizing = false; dragEnabled = true end
    end)

    -- Tabs management
    local tabButtons = {}
    local tabFrames = {}
    local activeTab = nil

    local function setActiveTab(idx)
        activeTab = idx
        for i, btn in ipairs(tabButtons) do
            local active = (i == idx)
            SmoothTween(btn, { BackgroundColor3 = active and Theme.TabActive or Theme.TabInactive }, 0.15)
            local lbl = btn:FindFirstChild("Label")
            if lbl then SmoothTween(lbl, { TextColor3 = active and Theme.TabActiveText or Theme.TabInactiveText }, 0.15) end
            local bar = btn:FindFirstChild("Bar")
            if bar then bar.Visible = active end
        end
        for i, f in ipairs(tabFrames) do
            if i == idx then
                f.Size = UDim2.new(0, 0, 0, 0)
                SmoothTween(f, { Size = UDim2.new(1, 0, 1, 0) }, 0.25)
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

    -- Window methods
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
        local success, err = pcall(function()
            writefile(cfgName .. ".json", HttpService:JSONEncode(data))
        end)
        if success then
            self:Notify("Config saved", 2)
        else
            self:Notify("Save failed: " .. tostring(err), 2)
        end
    end

    function Window:LoadConfig()
        local success, raw = pcall(readfile, cfgName .. ".json")
        if not success or not raw then
            self:Notify("No config found", 2)
            return
        end
        local success2, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not success2 or not data then
            self:Notify("Corrupted config", 2)
            return
        end
        for k, val in pairs(data) do
            if flags[k] then
                if type(val) == "table" and val.__t == "Color3" then
                    flags[k]:Set(Color3.new(val.r, val.g, val.b))
                elseif type(val) == "table" and val.__t == "Enum" then
                    local parts = string.split(val.v, ".")
                    local ok, en = pcall(function() return Enum[parts[2]][parts[3]] end)
                    if ok then flags[k]:Set(en) end
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
            local success, err = pcall(setclipboard, json)
            if success then
                self:Notify("Copied to clipboard", 2)
            else
                self:Notify("Clipboard error: " .. tostring(err), 2)
            end
        else
            self:Notify("Clipboard not supported", 2)
        end
    end

    function Window:ImportFromClipboard()
        if not getclipboard then
            self:Notify("Clipboard not supported", 2)
            return
        end
        local success, raw = pcall(getclipboard)
        if not success or not raw then
            self:Notify("Clipboard error", 2)
            return
        end
        local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok then
            self:Notify("Invalid clipboard data", 2)
            return
        end
        for k, val in pairs(data) do
            if flags[k] then
                if type(val) == "table" and val.__t == "Color3" then
                    flags[k]:Set(Color3.new(val.r, val.g, val.b))
                elseif type(val) == "table" and val.__t == "Enum" then
                    local parts = string.split(val.v, ".")
                    local ok2, en = pcall(function() return Enum[parts[2]][parts[3]] end)
                    if ok2 then flags[k]:Set(en) end
                else
                    flags[k]:Set(val)
                end
            end
        end
        self:Notify("Imported from clipboard", 2)
    end

    function Window:ReloadTheme()
        Win.BackgroundColor3 = Theme.WindowBG
        Header.BackgroundColor3 = Theme.HeaderBG
        TabPanel.BackgroundColor3 = Theme.TabBG
        ABar.BackgroundColor3 = Theme.Accent
        LogoBg.BackgroundColor3 = Theme.Accent
        ToggleGlow.BackgroundColor3 = Theme.Accent
        ToggleIcon.TextColor3 = Theme.Accent
        ToggleLetter.TextColor3 = Theme.Accent
        ResizeGrip.BackgroundColor3 = Theme.Accent
        for _, btn in ipairs(tabButtons) do
            local active = (btn == tabButtons[activeTab])
            btn.BackgroundColor3 = active and Theme.TabActive or Theme.TabInactive
            local lbl = btn:FindFirstChild("Label")
            if lbl then lbl.TextColor3 = active and Theme.TabActiveText or Theme.TabInactiveText end
            local bar = btn:FindFirstChild("Bar")
            if bar then bar.BackgroundColor3 = Theme.AccentHover end
        end
        self:Notify("Theme reloaded", 1)
    end

    function Window:CreateTab(name)
        local idx = #tabButtons + 1

        local btn = Instance.new("TextButton", TabScroller)
        btn.Size = UDim2.new(1, -8, 0, 44)
        btn.BackgroundColor3 = Theme.TabInactive
        btn.BackgroundTransparency = 0.1
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = idx
        btn.AutoButtonColor = false
        Corner(btn, 10)

        local bar = Instance.new("Frame", btn)
        bar.Name = "Bar"
        bar.Size = UDim2.new(0, 3, 0.55, 0)
        bar.Position = UDim2.new(0, 0, 0.225, 0)
        bar.BackgroundColor3 = Theme.AccentHover
        bar.BorderSizePixel = 0
        bar.Visible = false
        Corner(bar, 2)

        local label = Label(btn, name, UDim2.new(1, -12, 1, 0), Theme.TabInactiveText)
        label.Name = "Label"
        label.Position = UDim2.new(0, 12, 0, 0)
        label.Font = Theme.FontMain
        label.TextSize = 13

        OnClick(btn, function() setActiveTab(idx) end)
        btn.MouseEnter:Connect(function()
            if activeTab ~= idx then SmoothTween(btn, { BackgroundColor3 = Theme.TabHover }, 0.08)
        end)
        btn.MouseLeave:Connect(function()
            if activeTab ~= idx then SmoothTween(btn, { BackgroundColor3 = Theme.TabInactive }, 0.08)
        end)
        tabButtons[idx] = btn

        local content = Instance.new("ScrollingFrame", ContentContainer)
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.ScrollBarThickness = 4
        content.ScrollBarImageColor3 = Theme.Accent
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        content.ClipsDescendants = true
        content.Visible = true
        content.Size = UDim2.new(0, 0, 0, 0)
        Padding(content, 12, 12, 16, 16)
        local list = Instance.new("UIListLayout", content)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 10)
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

        local function Card(height)
            local card = Instance.new("Frame", content)
            card.Size = UDim2.new(1, 0, 0, height or 48)
            card.BackgroundColor3 = Theme.ElementBG
            card.BackgroundTransparency = 0.15
            card.BorderSizePixel = 0
            card.LayoutOrder = nextOrder()
            Corner(card, 12)
            Stroke(card, Theme.ElementStroke, 1)
            return card
        end

        local function addHint(elem, text)
            if not text then return end
            elem.MouseEnter:Connect(function() ShowTooltip(text, elem) end)
            elem.MouseLeave:Connect(function() HideTooltip() end)
        end

        -- ====================================================================
        -- ELEMENT CREATION METHODS
        -- ====================================================================
        function Tab:CreateLabel(text, hint)
            local c = Card(38)
            Padding(c, 0, 0, 14, 14)
            local lbl = Label(c, text, UDim2.new(1, 0, 1, 0), Theme.TextSecondary)
            lbl.Font = Theme.FontMain
            lbl.TextSize = 12
            if hint then addHint(c, hint) end
            return lbl
        end

        function Tab:CreateSectionHeader(text, hint)
            local f = Instance.new("Frame", content)
            f.Size = UDim2.new(1, 0, 0, 28)
            f.BackgroundTransparency = 1
            f.LayoutOrder = nextOrder()
            local line = Instance.new("Frame", f)
            line.Size = UDim2.new(0, 3, 0.6, 0)
            line.Position = UDim2.new(0, 0, 0.2, 0)
            line.BackgroundColor3 = Theme.Accent
            line.BorderSizePixel = 0
            Corner(line, 2)
            local lbl = Label(f, string.upper(text), UDim2.new(1, -12, 1, 0), Theme.SectionText)
            lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.Font = Theme.FontBold
            lbl.TextSize = 11
            if hint then addHint(f, hint) end
            return lbl
        end

        function Tab:AddSeparator()
            local s = Instance.new("Frame", content)
            s.Size = UDim2.new(1, 0, 0, 1)
            s.BackgroundColor3 = Theme.Separator
            s.BackgroundTransparency = 0.5
            s.BorderSizePixel = 0
            s.LayoutOrder = nextOrder()
        end

        function Tab:CreateButton(cfg)
            cfg = cfg or {}
            local c = Card(48)
            Padding(c, 0, 0, 14, 14)
            Label(c, cfg.Title or "Button", UDim2.new(1, -82, 1, 0))
            local runBtn = Instance.new("TextButton", c)
            runBtn.Size = UDim2.new(0, 70, 0, 32)
            runBtn.Position = UDim2.new(1, -78, 0.5, -16)
            runBtn.BackgroundColor3 = Theme.Accent
            runBtn.BorderSizePixel = 0
            runBtn.Text = "Run"
            runBtn.TextSize = 12
            runBtn.Font = Theme.FontBold
            runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Corner(runBtn, 8)
            OnClick(runBtn, function()
                SmoothTween(runBtn, { BackgroundColor3 = Theme.AccentDark }, 0.1)
                task.delay(0.15, function() SmoothTween(runBtn, { BackgroundColor3 = Theme.Accent }, 0.15) end)
                pcall(cfg.Callback or function() end)
            end)
            runBtn.MouseEnter:Connect(function() SmoothTween(runBtn, { BackgroundColor3 = Theme.AccentHover }, 0.08) end)
            runBtn.MouseLeave:Connect(function() SmoothTween(runBtn, { BackgroundColor3 = Theme.Accent }, 0.08) end)
            local hov = Instance.new("TextButton", c)
            hov.Size = UDim2.new(1, 0, 1, 0)
            hov.BackgroundTransparency = 1
            hov.Text = ""
            hov.MouseEnter:Connect(function() SmoothTween(c, { BackgroundColor3 = Theme.ElementHov }, 0.08) end)
            hov.MouseLeave:Connect(function() SmoothTween(c, { BackgroundColor3 = Theme.ElementBG }, 0.08) end)
            if cfg.Hint then addHint(c, cfg.Hint) end
        end

        function Tab:CreateToggle(cfg)
            cfg = cfg or {}
            local state = cfg.Default or false
            local c = Card(48)
            Padding(c, 0, 0, 14, 14)
            Label(c, cfg.Title or "Toggle", UDim2.new(1, -62, 1, 0))
            local track = Instance.new("Frame", c)
            track.Size = UDim2.new(0, 46, 0, 24)
            track.Position = UDim2.new(1, -54, 0.5, -12)
            track.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
            track.BorderSizePixel = 0
            Corner(track, 12)
            local knob = Instance.new("Frame", track)
            knob.Size = UDim2.new(0, 20, 0, 20)
            knob.Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            Corner(knob, 10)
            local hit = Instance.new("TextButton", c)
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            local api = {}
            local function update()
                SmoothTween(track, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff }, 0.18)
                SmoothTween(knob, { Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10) }, 0.18)
                pcall(cfg.Callback or function() end, state)
            end
            function api:Set(v) state = v; update() end
            function api:Get() return state end
            OnClick(hit, function() state = not state; update() end)
            hit.MouseEnter:Connect(function() SmoothTween(c, { BackgroundColor3 = Theme.ElementHov }, 0.08) end)
            hit.MouseLeave:Connect(function() SmoothTween(c, { BackgroundColor3 = Theme.ElementBG }, 0.08) end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        function Tab:CreateSlider(cfg)
            cfg = cfg or {}
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local val = math.clamp(cfg.Default or min, min, max)
            local c = Card(68)
            Padding(c, 10, 10, 14, 14)
            local top = Instance.new("Frame", c)
            top.Size = UDim2.new(1, 0, 0, 24)
            top.BackgroundTransparency = 1
            Label(top, cfg.Title or "Slider", UDim2.new(1, -50, 1, 0))
            local valLabel = Label(top, tostring(val), UDim2.new(0, 45, 1, 0), Theme.Accent, Enum.TextXAlignment.Right)
            valLabel.Position = UDim2.new(1, -50, 0, 0)
            valLabel.Font = Theme.FontBold
            local track = Instance.new("Frame", c)
            track.Size = UDim2.new(1, 0, 0, 10)
            track.Position = UDim2.new(0, 0, 1, -16)
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
                SmoothTween(knob, { Position = UDim2.new(p, -10, 0.5, -10) }, 0.1)
                valLabel.Text = tostring(val)
                pcall(cfg.Callback or function() end, val)
            end
            function api:Set(v) val = math.clamp(v, min, max); local p = (val - min) / (max - min); fill.Size = UDim2.new(p, 0, 1, 0); SmoothTween(knob, { Position = UDim2.new(p, -10, 0.5, -10) }, 0.15); valLabel.Text = tostring(val); pcall(cfg.Callback or function() end, val) end
            function api:Get() return val end
            hit.InputBegan:Connect(function(i) if isDown(i) then dragging = true; updateValue(i.Position.X) end end)
            UserInput.InputChanged:Connect(function(i) if dragging and isMove(i) then updateValue(i.Position.X) end end)
            UserInput.InputEnded:Connect(function(i) if isDown(i) then dragging = false end end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        function Tab:CreateSliderNumber(cfg)
            cfg = cfg or {}
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local val = math.clamp(cfg.Default or min, min, max)
            local c = Card(76)
            Padding(c, 10, 10, 14, 14)
            local top = Instance.new("Frame", c)
            top.Size = UDim2.new(1, 0, 0, 24)
            top.BackgroundTransparency = 1
            Label(top, cfg.Title or "Slider", UDim2.new(1, -60, 1, 0))
            local numBox = Instance.new("TextBox", top)
            numBox.Size = UDim2.new(0, 55, 0, 24)
            numBox.Position = UDim2.new(1, -60, 0, 0)
            numBox.BackgroundColor3 = Theme.WindowBG
            numBox.BackgroundTransparency = 0.3
            numBox.BorderSizePixel = 0
            numBox.Text = tostring(val)
            numBox.TextColor3 = Theme.Accent
            numBox.TextSize = 12
            numBox.Font = Theme.FontBold
            numBox.TextXAlignment = Enum.TextXAlignment.Center
            Corner(numBox, 8)
            Stroke(numBox, Theme.ElementStroke, 1)
            local track = Instance.new("Frame", c)
            track.Size = UDim2.new(1, 0, 0, 10)
            track.Position = UDim2.new(0, 0, 1, -16)
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
                SmoothTween(knob, { Position = UDim2.new(p, -10, 0.5, -10) }, 0.1)
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
            hit.InputBegan:Connect(function(i) if isDown(i) then dragging = true; updateFromPos(i.Position.X) end end)
            UserInput.InputChanged:Connect(function(i) if dragging and isMove(i) then updateFromPos(i.Position.X) end end)
            UserInput.InputEnded:Connect(function(i) if isDown(i) then dragging = false end end)
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

        function Tab:CreateTextBox(cfg)
            cfg = cfg or {}
            local c = Card(78)
            Padding(c, 10, 10, 14, 14)
            Label(c, cfg.Title or "TextBox", UDim2.new(1, 0, 0, 22))
            local inputFrame = Instance.new("Frame", c)
            inputFrame.Size = UDim2.new(1, 0, 0, 34)
            inputFrame.Position = UDim2.new(0, 0, 1, -38)
            inputFrame.BackgroundColor3 = Theme.WindowBG
            inputFrame.BackgroundTransparency = 0.3
            inputFrame.BorderSizePixel = 0
            Corner(inputFrame, 10)
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
            Padding(box, 0, 0, 12, 12)
            local api = {}
            function api:Set(v) box.Text = tostring(v) end
            function api:Get() return box.Text end
            box.Focused:Connect(function() stroke.Color = Theme.Accent; SmoothTween(inputFrame, { BackgroundColor3 = Theme.WindowBG }, 0.1) end)
            box.FocusLost:Connect(function(enter)
                stroke.Color = Theme.ElementStroke
                SmoothTween(inputFrame, { BackgroundColor3 = Theme.WindowBG }, 0.1)
                if enter then pcall(cfg.Callback or function() end, box.Text) end
            end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        function Tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local opts = cfg.Options or {}
            local sel = cfg.Default or (opts[1] or "")
            local open = false
            local c = Card(48)
            Padding(c, 0, 0, 14, 14)
            Label(c, cfg.Title or "Dropdown", UDim2.new(1, -100, 1, 0))
            local selFrame = Instance.new("Frame", c)
            selFrame.Size = UDim2.new(0, 96, 0, 30)
            selFrame.Position = UDim2.new(1, -104, 0.5, -15)
            selFrame.BackgroundColor3 = Theme.WindowBG
            selFrame.BackgroundTransparency = 0.3
            selFrame.BorderSizePixel = 0
            Corner(selFrame, 8)
            Stroke(selFrame, Theme.ElementStroke, 1)
            local selLabel = Label(selFrame, sel, UDim2.new(1, -20, 1, 0), Theme.TextPrimary)
            selLabel.Position = UDim2.new(0, 10, 0, 0)
            selLabel.Font = Theme.FontMain
            selLabel.TextSize = 12
            local arrow = Label(selFrame, "▼", UDim2.new(0, 16, 1, 0), Theme.TextMuted, Enum.TextXAlignment.Center)
            arrow.Position = UDim2.new(1, -18, 0, 0)
            arrow.TextSize = 12

            local popup = Instance.new("Frame", SG)
            popup.Size = UDim2.new(0, 100, 0, 0)
            popup.BackgroundColor3 = Theme.ElementBG
            popup.BackgroundTransparency = 0.05
            popup.BorderSizePixel = 0
            popup.ClipsDescendants = true
            popup.Visible = false
            popup.ZIndex = 160
            Corner(popup, 10)
            Stroke(popup, Theme.ElementStroke, 1)

            local scroller = Instance.new("ScrollingFrame", popup)
            scroller.Size = UDim2.new(1, 0, 1, 0)
            scroller.BackgroundTransparency = 1
            scroller.ScrollBarThickness = 2
            scroller.ScrollBarImageColor3 = Theme.Accent
            scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
            scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
            Padding(scroller, 6, 6, 6, 6)
            local list = Instance.new("UIListLayout", scroller)
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.Padding = UDim.new(0, 4)

            for i, opt in ipairs(opts) do
                local ob = Instance.new("TextButton", scroller)
                ob.Size = UDim2.new(1, 0, 0, 32)
                ob.BackgroundColor3 = Theme.ElementHov
                ob.BackgroundTransparency = 0.2
                ob.BorderSizePixel = 0
                ob.Text = opt
                ob.TextSize = 12
                ob.Font = Theme.FontMain
                ob.TextColor3 = Theme.TextSecondary
                ob.TextXAlignment = Enum.TextXAlignment.Left
                ob.AutoButtonColor = false
                ob.LayoutOrder = i
                Corner(ob, 6)
                Padding(ob, 0, 0, 10, 0)
                OnClick(ob, function()
                    sel = opt
                    selLabel.Text = opt
                    pcall(cfg.Callback or function() end, sel)
                    closePop()
                end)
                ob.MouseEnter:Connect(function() SmoothTween(ob, { BackgroundColor3 = Theme.TabHover }, 0.08) end)
                ob.MouseLeave:Connect(function() SmoothTween(ob, { BackgroundColor3 = Theme.ElementHov }, 0.08) end)
            end

            local function closePop()
                if not open then return end
                open = false
                SmoothTween(popup, { Size = UDim2.new(0, 100, 0, 0) }, 0.18)
                arrow.Text = "▼"
                task.delay(0.2, function() popup.Visible = false end)
            end

            local function openPop()
                local pos = selFrame.AbsolutePosition
                local w = math.max(selFrame.AbsoluteSize.X + 8, 110)
                local vp = workspace.CurrentCamera.ViewportSize
                local x = math.min(pos.X, vp.X - w - 4)
                local below = vp.Y - (pos.Y + selFrame.AbsoluteSize.Y + 4)
                local above = pos.Y - 4
                local maxH = math.min(#opts * 36 + 8, 180)
                local y = (below >= maxH or below >= above) and (pos.Y + selFrame.AbsoluteSize.Y + 4) or (pos.Y - maxH - 4)
                popup.Position = UDim2.new(0, x, 0, y)
                popup.Size = UDim2.new(0, w, 0, 0)
                popup.Visible = true
                open = true
                SmoothTween(popup, { Size = UDim2.new(0, w, 0, maxH) }, 0.22)
                arrow.Text = "▲"
            end

            local hit = Instance.new("TextButton", c)
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            OnClick(hit, function() if open then closePop() else openPop() end end)
            hit.MouseEnter:Connect(function() SmoothTween(c, { BackgroundColor3 = Theme.ElementHov }, 0.08) end)
            hit.MouseLeave:Connect(function() SmoothTween(c, { BackgroundColor3 = Theme.ElementBG }, 0.08) end)

            UserInput.InputBegan:Connect(function(i)
                if not open or not isDown(i) then return end
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

        function Tab:CreateMultiDropdown(cfg)
            cfg = cfg or {}
            local opts = cfg.Options or {}
            local selected = {}
            for _, d in ipairs(cfg.Default or {}) do selected[d] = true end
            local open = false
            local c = Card(48)
            Padding(c, 0, 0, 14, 14)
            Label(c, cfg.Title or "Multi-Dropdown", UDim2.new(1, -100, 1, 0))
            local selFrame = Instance.new("Frame", c)
            selFrame.Size = UDim2.new(0, 105, 0, 30)
            selFrame.Position = UDim2.new(1, -113, 0.5, -15)
            selFrame.BackgroundColor3 = Theme.WindowBG
            selFrame.BackgroundTransparency = 0.3
            selFrame.BorderSizePixel = 0
            Corner(selFrame, 8)
            Stroke(selFrame, Theme.ElementStroke, 1)
            local selLabel = Label(selFrame, table.concat(cfg.Default or {}, ", "), UDim2.new(1, -20, 1, 0), Theme.TextPrimary)
            selLabel.Position = UDim2.new(0, 10, 0, 0)
            selLabel.Font = Theme.FontMain
            selLabel.TextSize = 11
            local arrow = Label(selFrame, "▼", UDim2.new(0, 16, 1, 0), Theme.TextMuted, Enum.TextXAlignment.Center)
            arrow.Position = UDim2.new(1, -18, 0, 0)
            arrow.TextSize = 12

            local popup = Instance.new("Frame", SG)
            popup.Size = UDim2.new(0, 150, 0, 0)
            popup.BackgroundColor3 = Theme.ElementBG
            popup.BackgroundTransparency = 0.05
            popup.BorderSizePixel = 0
            popup.ClipsDescendants = true
            popup.Visible = false
            popup.ZIndex = 160
            Corner(popup, 10)
            Stroke(popup, Theme.ElementStroke, 1)

            local scroller = Instance.new("ScrollingFrame", popup)
            scroller.Size = UDim2.new(1, 0, 1, 0)
            scroller.BackgroundTransparency = 1
            scroller.ScrollBarThickness = 2
            scroller.ScrollBarImageColor3 = Theme.Accent
            scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
            scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
            Padding(scroller, 6, 6, 6, 6)
            local list = Instance.new("UIListLayout", scroller)
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.Padding = UDim.new(0, 4)

            local function updateText()
                local t = {}
                for k, v in pairs(selected) do if v then table.insert(t, k) end end
                selLabel.Text = table.concat(t, ", ")
                pcall(cfg.Callback or function() end, t)
            end

            for i, opt in ipairs(opts) do
                local row = Instance.new("Frame", scroller)
                row.Size = UDim2.new(1, 0, 0, 32)
                row.BackgroundColor3 = Theme.ElementHov
                row.BackgroundTransparency = 0.2
                row.BorderSizePixel = 0
                row.LayoutOrder = i
                Corner(row, 6)
                local chk = Instance.new("TextButton", row)
                chk.Size = UDim2.new(0, 22, 0, 22)
                chk.Position = UDim2.new(0, 8, 0.5, -11)
                chk.BackgroundColor3 = selected[opt] and Theme.Accent or Theme.ToggleOff
                chk.BorderSizePixel = 0
                chk.Text = selected[opt] and "✓" or ""
                chk.TextColor3 = Color3.fromRGB(255, 255, 255)
                chk.Font = Theme.FontBold
                chk.TextSize = 12
                Corner(chk, 6)
                local lbl = Label(row, opt, UDim2.new(1, -42, 1, 0), Theme.TextSecondary)
                lbl.Position = UDim2.new(0, 38, 0, 0)
                lbl.Font = Theme.FontMain
                lbl.TextSize = 12
                OnClick(chk, function()
                    selected[opt] = not selected[opt]
                    SmoothTween(chk, { BackgroundColor3 = selected[opt] and Theme.Accent or Theme.ToggleOff }, 0.1)
                    chk.Text = selected[opt] and "✓" or ""
                    updateText()
                end)
                row.MouseEnter:Connect(function() SmoothTween(row, { BackgroundColor3 = Theme.TabHover }, 0.08) end)
                row.MouseLeave:Connect(function() SmoothTween(row, { BackgroundColor3 = Theme.ElementHov }, 0.08) end)
            end

            local function closePop()
                if not open then return end
                open = false
                SmoothTween(popup, { Size = UDim2.new(0, 150, 0, 0) }, 0.18)
                arrow.Text = "▼"
                task.delay(0.2, function() popup.Visible = false end)
            end

            local function openPop()
                local pos = selFrame.AbsolutePosition
                local w = math.max(selFrame.AbsoluteSize.X + 8, 160)
                local vp = workspace.CurrentCamera.ViewportSize
                local x = math.min(pos.X, vp.X - w - 4)
                local below = vp.Y - (pos.Y + selFrame.AbsoluteSize.Y + 4)
                local above = pos.Y - 4
                local maxH = math.min(#opts * 36 + 8, 200)
                local y = (below >= maxH or below >= above) and (pos.Y + selFrame.AbsoluteSize.Y + 4) or (pos.Y - maxH - 4)
                popup.Position = UDim2.new(0, x, 0, y)
                popup.Size = UDim2.new(0, w, 0, 0)
                popup.Visible = true
                open = true
                SmoothTween(popup, { Size = UDim2.new(0, w, 0, maxH) }, 0.22)
                arrow.Text = "▲"
            end

            local hit = Instance.new("TextButton", c)
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            OnClick(hit, function() if open then closePop() else openPop() end end)
            hit.MouseEnter:Connect(function() SmoothTween(c, { BackgroundColor3 = Theme.ElementHov }, 0.08) end)
            hit.MouseLeave:Connect(function() SmoothTween(c, { BackgroundColor3 = Theme.ElementBG }, 0.08) end)

            UserInput.InputBegan:Connect(function(i)
                if not open or not isDown(i) then return end
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

        function Tab:CreateInputNumber(cfg)
            cfg = cfg or {}
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local step = cfg.Step or 1
            local val = math.clamp(cfg.Default or min, min, max)
            local c = Card(48)
            Padding(c, 0, 0, 14, 14)
            Label(c, cfg.Title or "Number", UDim2.new(1, -130, 1, 0))
            local row = Instance.new("Frame", c)
            row.Size = UDim2.new(0, 120, 0, 32)
            row.Position = UDim2.new(1, -128, 0.5, -16)
            row.BackgroundTransparency = 1
            local minus = Instance.new("TextButton", row)
            minus.Size = UDim2.new(0, 32, 1, 0)
            minus.BackgroundColor3 = Theme.ElementHov
            minus.BorderSizePixel = 0
            minus.Text = "−"
            minus.TextSize = 18
            minus.Font = Theme.FontBold
            minus.TextColor3 = Theme.TextPrimary
            minus.AutoButtonColor = false
            Corner(minus, 8)
            local valFrame = Instance.new("Frame", row)
            valFrame.Size = UDim2.new(0, 52, 1, 0)
            valFrame.Position = UDim2.new(0, 36, 0, 0)
            valFrame.BackgroundColor3 = Theme.WindowBG
            valFrame.BackgroundTransparency = 0.3
            valFrame.BorderSizePixel = 0
            Corner(valFrame, 8)
            Stroke(valFrame, Theme.ElementStroke, 1)
            local valLabel = Label(valFrame, tostring(val), UDim2.new(1, 0, 1, 0), Theme.TextPrimary, Enum.TextXAlignment.Center)
            valLabel.Font = Theme.FontBold
            valLabel.TextSize = 14
            local plus = Instance.new("TextButton", row)
            plus.Size = UDim2.new(0, 32, 1, 0)
            plus.Position = UDim2.new(0, 92, 0, 0)
            plus.BackgroundColor3 = Theme.ElementHov
            plus.BorderSizePixel = 0
            plus.Text = "+"
            plus.TextSize = 18
            plus.Font = Theme.FontBold
            plus.TextColor3 = Theme.TextPrimary
            plus.AutoButtonColor = false
            Corner(plus, 8)
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
                SmoothTween(minus, { BackgroundColor3 = Theme.AccentDark }, 0.1)
                task.delay(0.15, function() SmoothTween(minus, { BackgroundColor3 = Theme.ElementHov }, 0.15) end)
            end)
            OnClick(plus, function()
                val = math.clamp(val + step, min, max)
                update()
                SmoothTween(plus, { BackgroundColor3 = Theme.AccentDark }, 0.1)
                task.delay(0.15, function() SmoothTween(plus, { BackgroundColor3 = Theme.ElementHov }, 0.15) end)
            end)
            minus.MouseEnter:Connect(function() SmoothTween(minus, { BackgroundColor3 = Theme.TabHover }, 0.08) end)
            minus.MouseLeave:Connect(function() SmoothTween(minus, { BackgroundColor3 = Theme.ElementHov }, 0.08) end)
            plus.MouseEnter:Connect(function() SmoothTween(plus, { BackgroundColor3 = Theme.TabHover }, 0.08) end)
            plus.MouseLeave:Connect(function() SmoothTween(plus, { BackgroundColor3 = Theme.ElementHov }, 0.08) end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        function Tab:CreateProgressBar(cfg)
            cfg = cfg or {}
            local val = math.clamp(cfg.Default or 0, 0, 100)
            local c = Card(62)
            Padding(c, 10, 10, 14, 14)
            local top = Instance.new("Frame", c)
            top.Size = UDim2.new(1, 0, 0, 24)
            top.BackgroundTransparency = 1
            Label(top, cfg.Title or "Progress", UDim2.new(1, -50, 1, 0))
            local pctLabel = Label(top, val .. "%", UDim2.new(0, 45, 1, 0), Theme.Accent, Enum.TextXAlignment.Right)
            pctLabel.Position = UDim2.new(1, -50, 0, 0)
            pctLabel.Font = Theme.FontBold
            local track = Instance.new("Frame", c)
            track.Size = UDim2.new(1, 0, 0, 10)
            track.Position = UDim2.new(0, 0, 1, -16)
            track.BackgroundColor3 = Theme.ToggleOff
            track.BorderSizePixel = 0
            Corner(track, 5)
            local fill = Instance.new("Frame", track)
            fill.Size = UDim2.new(val / 100, 0, 1, 0)
            fill.BackgroundColor3 = Theme.Accent
            fill.BorderSizePixel = 0
            Corner(fill, 5)
            local shine = Instance.new("Frame", fill)
            shine.Size = UDim2.new(1, 0, 0.5, 0)
            shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            shine.BackgroundTransparency = 0.85
            shine.BorderSizePixel = 0
            Corner(shine, 5)
            local api = {}
            function api:Set(v)
                val = math.clamp(v, 0, 100)
                local p = val / 100
                SmoothTween(fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.3)
                pctLabel.Text = val .. "%"
                local color = val >= 100 and Color3.fromRGB(34, 197, 94) or Theme.Accent
                SmoothTween(fill, { BackgroundColor3 = color }, 0.3)
                pcall(cfg.Callback or function() end, val)
            end
            function api:Get() return val end
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        function Tab:CreateColorPicker(cfg)
            cfg = cfg or {}
            local col = cfg.Default or Color3.fromRGB(255, 255, 255)
            local r, g, b = col.R, col.G, col.B
            local c = Card(48)
            Padding(c, 0, 0, 14, 14)
            Label(c, cfg.Title or "Color", UDim2.new(1, -60, 1, 0))
            local swatch = Instance.new("Frame", c)
            swatch.Size = UDim2.new(0, 36, 0, 26)
            swatch.Position = UDim2.new(1, -48, 0.5, -13)
            swatch.BackgroundColor3 = col
            swatch.BorderSizePixel = 0
            Corner(swatch, 8)
            Stroke(swatch, Theme.ElementStroke, 1)
            local pickerFrame = nil
            local api = {}
            function api:Set(nc) col = nc; swatch.BackgroundColor3 = nc; pcall(cfg.Callback or function() end, nc) end
            function api:Get() return col end
            OnClick(swatch, function()
                if pickerFrame then pickerFrame:Destroy() end
                pickerFrame = Instance.new("Frame", SG)
                pickerFrame.Size = UDim2.new(0, 220, 0, 190)
                pickerFrame.Position = UDim2.new(0.5, -110, 0.5, -95)
                pickerFrame.BackgroundColor3 = Theme.ElementBG
                pickerFrame.BackgroundTransparency = 0.05
                pickerFrame.BorderSizePixel = 0
                pickerFrame.ZIndex = 300
                Corner(pickerFrame, 12)
                Stroke(pickerFrame, Theme.Accent, 1)

                local redSlider = Instance.new("Frame", pickerFrame)
                redSlider.Size = UDim2.new(0.8, 0, 0, 14)
                redSlider.Position = UDim2.new(0.1, 0, 0.2, 0)
                redSlider.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                Corner(redSlider, 4)
                local redFill = Instance.new("Frame", redSlider)
                redFill.Size = UDim2.new(r, 0, 1, 0)
                redFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                redFill.BorderSizePixel = 0
                Corner(redFill, 4)
                local greenSlider = Instance.new("Frame", pickerFrame)
                greenSlider.Size = UDim2.new(0.8, 0, 0, 14)
                greenSlider.Position = UDim2.new(0.1, 0, 0.4, 0)
                greenSlider.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                Corner(greenSlider, 4)
                local greenFill = Instance.new("Frame", greenSlider)
                greenFill.Size = UDim2.new(g, 0, 1, 0)
                greenFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                greenFill.BorderSizePixel = 0
                Corner(greenFill, 4)
                local blueSlider = Instance.new("Frame", pickerFrame)
                blueSlider.Size = UDim2.new(0.8, 0, 0, 14)
                blueSlider.Position = UDim2.new(0.1, 0, 0.6, 0)
                blueSlider.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
                Corner(blueSlider, 4)
                local blueFill = Instance.new("Frame", blueSlider)
                blueFill.Size = UDim2.new(b, 0, 1, 0)
                blueFill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
                blueFill.BorderSizePixel = 0
                Corner(blueFill, 4)
                local preview = Instance.new("Frame", pickerFrame)
                preview.Size = UDim2.new(0.8, 0, 0, 28)
                preview.Position = UDim2.new(0.1, 0, 0.78, 0)
                preview.BackgroundColor3 = col
                preview.BorderSizePixel = 0
                Corner(preview, 8)
                Stroke(preview, Theme.ElementStroke, 1)
                local okBtn = Instance.new("TextButton", pickerFrame)
                okBtn.Size = UDim2.new(0.35, 0, 0, 28)
                okBtn.Position = UDim2.new(0.55, 0, 0.88, 0)
                okBtn.Text = "OK"
                okBtn.BackgroundColor3 = Theme.Accent
                okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                okBtn.Font = Theme.FontBold
                Corner(okBtn, 8)
                local cancelBtn = Instance.new("TextButton", pickerFrame)
                cancelBtn.Size = UDim2.new(0.35, 0, 0, 28)
                cancelBtn.Position = UDim2.new(0.1, 0, 0.88, 0)
                cancelBtn.Text = "Cancel"
                cancelBtn.BackgroundColor3 = Theme.ElementHov
                cancelBtn.TextColor3 = Theme.TextPrimary
                cancelBtn.Font = Theme.FontMain
                Corner(cancelBtn, 8)

                local function updateColor()
                    local nc = Color3.new(r, g, b)
                    preview.BackgroundColor3 = nc
                    swatch.BackgroundColor3 = nc
                    redFill.Size = UDim2.new(r, 0, 1, 0)
                    greenFill.Size = UDim2.new(g, 0, 1, 0)
                    blueFill.Size = UDim2.new(b, 0, 1, 0)
                end

                local function startDrag(slider, channel)
                    local dragging = false
                    slider.InputBegan:Connect(function(i)
                        if isDown(i) then
                            dragging = true
                            local x = math.clamp((i.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                            if channel == "r" then r = x elseif channel == "g" then g = x else b = x end
                            updateColor()
                        end
                    end)
                    UserInput.InputChanged:Connect(function(i)
                        if dragging and isMove(i) then
                            local x = math.clamp((i.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                            if channel == "r" then r = x elseif channel == "g" then g = x else b = x end
                            updateColor()
                        end
                    end)
                    UserInput.InputEnded:Connect(function(i)
                        if isDown(i) then dragging = false end
                    end)
                end
                startDrag(redSlider, "r")
                startDrag(greenSlider, "g")
                startDrag(blueSlider, "b")
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

        function Tab:CreateKeybind(cfg)
            cfg = cfg or {}
            local key = cfg.Default or Enum.KeyCode.RightShift
            local listening = false
            local c = Card(48)
            Padding(c, 0, 0, 14, 14)
            Label(c, cfg.Title or "Keybind", UDim2.new(1, -92, 1, 0))
            local btn = Instance.new("TextButton", c)
            btn.Size = UDim2.new(0, 86, 0, 30)
            btn.Position = UDim2.new(1, -94, 0.5, -15)
            btn.BackgroundColor3 = Theme.WindowBG
            btn.BackgroundTransparency = 0.3
            btn.BorderSizePixel = 0
            btn.TextSize = 12
            btn.Font = Theme.FontBold
            btn.TextColor3 = Theme.Accent
            btn.AutoButtonColor = false
            Corner(btn, 8)
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
                            SmoothTween(btn, { BackgroundColor3 = Theme.WindowBG }, 0.1)
                            btn.Text = "[" .. keyName(key) .. "]"
                            if conn then conn:Disconnect() end
                            return
                        end
                        key = i.KeyCode
                        listening = false
                        SmoothTween(btn, { BackgroundColor3 = Theme.WindowBG }, 0.1)
                        btn.Text = "[" .. keyName(key) .. "]"
                        if conn then conn:Disconnect() end
                        pcall(cfg.Callback or function() end, key)
                    end
                end)
                addConnection(conn)
            end)
            btn.MouseEnter:Connect(function() SmoothTween(c, { BackgroundColor3 = Theme.ElementHov }, 0.08) end)
            btn.MouseLeave:Connect(function() SmoothTween(c, { BackgroundColor3 = Theme.ElementBG }, 0.08) end)
            registerFlag(cfg.Flag, api, c)
            if cfg.Hint then addHint(c, cfg.Hint) end
            return api
        end

        return Tab
    end

    ShowLoading(SG, Theme.Accent, title, function()
        Win.Visible = true
        Win.BackgroundTransparency = 0.08
        Wrapper.Position = UDim2.new(0.5, -280 - 32, 0.5, -190)
        SmoothTween(Wrapper, { Position = UDim2.new(0.5, -280 - 32, 0.5, -190) }, 0.55, Enum.EasingStyle.Back)
        syncToggleBtnY(380)
        lastWrapperPos = Wrapper.Position
    end)

    return Window
end

return KreinGui
