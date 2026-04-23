--[[
    KreinGui v5.3 – GUI Library by @uniquadev
    Fitur:
    - Close button "X" (pasti muncul)
    - Minimize ubah teks (-/+) dan nonaktifkan resize saat minimize
    - Tombol Settings (⚙) di header
    - Panel settings di kanan window (menempel, ikut drag)
    - Atur keybind toggle GUI & tema, tersimpan otomatis
    - Auto destroy GUI sebelumnya (no double)
    - Semua fitur sebelumnya (slider, dropdown, multi, color picker, dll)
--]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")
local HttpService  = game:GetService("HttpService")
local RunService   = game:GetService("RunService")
local LocalPlayer  = Players.LocalPlayer
local Mouse        = LocalPlayer:GetMouse()

-- ============================================================
-- GLOBAL CLEANUP
-- ============================================================
local activeConnections = {}
local snakeConnections = {}
local currentGui = nil

local function addConnection(conn)
    table.insert(activeConnections, conn)
    return conn
end

local function destroyAllConnections()
    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, data in ipairs(snakeConnections) do
        pcall(function() data[1]:Disconnect() end)
        pcall(function() if data[2] then data[2]:Destroy() end end)
        pcall(function() if data[3] then data[3]:Destroy() end end)
    end
    activeConnections = {}
    snakeConnections = {}
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
-- THEME (DEFAULT)
-- ============================================================
local T = {
    WindowBG    = Color3.fromRGB(10, 15, 20),
    HeaderBG    = Color3.fromRGB(15, 21, 28),
    TabBG       = Color3.fromRGB(20, 28, 36),
    ElementBG   = Color3.fromRGB(26, 36, 48),
    ElementHov  = Color3.fromRGB(32, 44, 58),
    ElementStr  = Color3.fromRGB(180, 220, 255),
    TabDef      = Color3.fromRGB(20, 28, 36),
    TabHov      = Color3.fromRGB(200, 235, 255),
    TabOn       = Color3.fromRGB(224, 244, 255),
    TabOnText   = Color3.fromRGB(10, 15, 20),
    TabOffText  = Color3.fromRGB(120, 170, 210),
    Accent      = Color3.fromRGB(200, 230, 255),
    AccentHov   = Color3.fromRGB(224, 244, 255),
    AccentDark  = Color3.fromRGB(100, 160, 210),
    ToggleOff   = Color3.fromRGB(30, 42, 56),
    ToggleOn    = Color3.fromRGB(200, 230, 255),
    TextPri     = Color3.fromRGB(220, 238, 255),
    TextSec     = Color3.fromRGB(160, 200, 235),
    TextMut     = Color3.fromRGB(90, 130, 170),
    SecText     = Color3.fromRGB(120, 165, 200),
    CloseRed    = Color3.fromRGB(255, 90, 90),
    MinGray     = Color3.fromRGB(140, 185, 220),
    Sep         = Color3.fromRGB(50, 75, 100),
    WinStr      = Color3.fromRGB(80, 130, 180),
    FontFace    = Enum.Font.GothamMedium,
    FontBold    = Enum.Font.GothamBold,
}

local Presets = {
    Ice      = {Accent=Color3.fromRGB(200,230,255), ToggleOn=Color3.fromRGB(200,230,255), TabOn=Color3.fromRGB(224,244,255), WindowBG=Color3.fromRGB(10,15,20),  HeaderBG=Color3.fromRGB(15,21,28)},
    Neon     = {Accent=Color3.fromRGB(0,255,180),   ToggleOn=Color3.fromRGB(0,255,180),   TabOn=Color3.fromRGB(0,255,180),   WindowBG=Color3.fromRGB(8,8,14),    HeaderBG=Color3.fromRGB(10,10,18)},
    Blood    = {Accent=Color3.fromRGB(255,51,85),   ToggleOn=Color3.fromRGB(255,51,85),   TabOn=Color3.fromRGB(255,51,85),   WindowBG=Color3.fromRGB(14,8,8),    HeaderBG=Color3.fromRGB(18,10,10)},
    Ocean    = {Accent=Color3.fromRGB(0,180,255),   ToggleOn=Color3.fromRGB(0,180,255),   TabOn=Color3.fromRGB(0,180,255),   WindowBG=Color3.fromRGB(6,12,20),   HeaderBG=Color3.fromRGB(8,15,28)},
    Purple   = {Accent=Color3.fromRGB(176,96,255),  ToggleOn=Color3.fromRGB(176,96,255),  TabOn=Color3.fromRGB(176,96,255),  WindowBG=Color3.fromRGB(12,8,15),   HeaderBG=Color3.fromRGB(16,12,20)},
    Gold     = {Accent=Color3.fromRGB(255,194,0),   ToggleOn=Color3.fromRGB(255,194,0),   TabOn=Color3.fromRGB(255,194,0),   WindowBG=Color3.fromRGB(14,12,6),   HeaderBG=Color3.fromRGB(20,16,8)},
    Rose     = {Accent=Color3.fromRGB(255,80,144),  ToggleOn=Color3.fromRGB(255,80,144),  TabOn=Color3.fromRGB(255,80,144),  WindowBG=Color3.fromRGB(15,8,12),   HeaderBG=Color3.fromRGB(20,11,16)},
    Matrix   = {Accent=Color3.fromRGB(0,224,64),    ToggleOn=Color3.fromRGB(0,224,64),    TabOn=Color3.fromRGB(0,224,64),    WindowBG=Color3.fromRGB(2,14,4),    HeaderBG=Color3.fromRGB(3,16,6)},
    Default  = {Accent=Color3.fromRGB(99,102,241),  ToggleOn=Color3.fromRGB(99,102,241),  TabOn=Color3.fromRGB(99,102,241),  WindowBG=Color3.fromRGB(28,28,32),  HeaderBG=Color3.fromRGB(22,22,26)},
}

-- ============================================================
-- HELPERS
-- ============================================================
local function Tw(o,p,d,s,dr)
    local t = TweenService:Create(o,TweenInfo.new(d or .2,s or Enum.EasingStyle.Quart,dr or Enum.EasingDirection.Out),p)
    t:Play()
    return t
end
local function Cor(p,r) local c=Instance.new("UICorner",p);c.CornerRadius=UDim.new(0,r or 8);return c end
local function Str(p,c,t) local s=Instance.new("UIStroke",p);s.Color=c or T.WinStr;s.Thickness=t or 1;return s end
local function Pad(p,a,b,l,r)
    local u=Instance.new("UIPadding",p)
    u.PaddingTop=UDim.new(0,a or 0);u.PaddingBottom=UDim.new(0,b or 0)
    u.PaddingLeft=UDim.new(0,l or 0);u.PaddingRight=UDim.new(0,r or 0)
end
local function Lbl(par,txt,sz,col,xa,font)
    local l=Instance.new("TextLabel",par)
    l.BackgroundTransparency=1;l.BorderSizePixel=0
    l.Size=sz or UDim2.new(1,0,1,0);l.Text=txt or ""
    l.TextSize=13;l.TextColor3=col or T.TextPri
    l.Font=font or T.FontFace
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Center
    l.TextWrapped=true
    return l
end

local dragEnabled = true
local function EnableDrag(f,h)
    h=h or f
    local drag,sp,sf,mv=false,nil,nil,false
    local con1 = h.InputBegan:Connect(function(i)
        if isDown(i) and dragEnabled then drag=true;mv=false;sp=i.Position;sf=f.Position end
    end)
    local con2 = UserInput.InputChanged:Connect(function(i)
        if not drag or not sp or not dragEnabled then return end
        if isMove(i) then
            local d=i.Position-sp
            if d.Magnitude>6 then mv=true end
            if mv then f.Position=UDim2.new(sf.X.Scale,sf.X.Offset+d.X,sf.Y.Scale,sf.Y.Offset+d.Y) end
        end
    end)
    local con3 = UserInput.InputEnded:Connect(function(i) if isDown(i) then drag=false end end)
    addConnection(con1); addConnection(con2); addConnection(con3)
end

local function HSV(h,s,v) return Color3.fromHSV(h,s,v) end
local function toHSV(c) return Color3.toHSV(c) end
local function toHex(c) return string.format("%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255)) end

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
    N.Size = UDim2.new(0,250,0,46)
    N.Position = UDim2.new(1,10,1,-64)
    N.BackgroundColor3 = T.ElementBG
    N.BorderSizePixel = 0
    N.ZIndex = 200
    Cor(N,8); Str(N,T.Accent,1)
    local Bar = Instance.new("Frame", N)
    Bar.Size = UDim2.new(0,3,0.7,0)
    Bar.Position = UDim2.new(0,0,0.15,0)
    Bar.BackgroundColor3 = T.Accent
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 201
    Cor(Bar,3)
    local nl = Lbl(N, data.msg, UDim2.new(1,-18,1,0), T.TextPri)
    nl.Position = UDim2.new(0,14,0,0)
    nl.Font = T.FontFace
    nl.TextSize = 12
    nl.ZIndex = 201
    nl.TextWrapped = true
    Tw(N, {Position = UDim2.new(1,-260,1,-64)}, 0.3)
    task.delay(data.dur or 3, function()
        Tw(N, {Position = UDim2.new(1,10,1,-64)}, 0.3)
        task.delay(0.35, function()
            N:Destroy()
            notifActive = false
            showNextNotification(SG)
        end)
    end)
end
local function Notify(SG, msg, dur)
    table.insert(notificationQueue, {msg = msg, dur = dur})
    showNextNotification(SG)
end

-- ============================================================
-- TOOLTIP SYSTEM
-- ============================================================
local activeTooltip = nil
local function ShowTooltip(text, parent, posOffset)
    if activeTooltip then activeTooltip:Destroy() end
    local tip = Instance.new("Frame", parent)
    tip.Size = UDim2.new(0,0,0,24)
    tip.BackgroundColor3 = T.ElementBG
    tip.BorderSizePixel = 0
    tip.ZIndex = 200
    Cor(tip, 6)
    Str(tip, T.Accent, 1)
    local lbl = Lbl(tip, text, UDim2.new(1,-10,1,0), T.TextPri)
    lbl.Position = UDim2.new(0,5,0,0)
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local ap = parent.AbsolutePosition
    local as = parent.AbsoluteSize
    local x = ap.X + (posOffset and posOffset.X or 0)
    local y = ap.Y - 30
    tip.Position = UDim2.new(0, x, 0, y)
    tip.Size = UDim2.new(0, lbl.TextBounds.X + 20, 0, 24)
    activeTooltip = tip
    tip.Destroying:Connect(function() if activeTooltip == tip then activeTooltip = nil end end)
    return tip
end
local function HideTooltip()
    if activeTooltip then activeTooltip:Destroy() end
end

-- ============================================================
-- SNAKE ANIMATION
-- ============================================================
local function StartSnake(abar, accent, win)
    local Glow = Instance.new("Frame", abar.Parent)
    Glow.Name = "ABarGlow"
    Glow.Size = UDim2.new(1,0,0,10)
    Glow.Position = UDim2.new(0,0,0,50)
    Glow.BackgroundColor3 = accent
    Glow.BackgroundTransparency = 0.7
    Glow.BorderSizePixel = 0
    Glow.ZIndex = 2
    Cor(Glow, 1)

    local Snake = Instance.new("Frame", abar)
    Snake.Size = UDim2.new(0.4,0,1,0)
    Snake.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Snake.BackgroundTransparency = 1
    Snake.BorderSizePixel = 0
    Snake.ZIndex = 6

    local sg = Instance.new("UIGradient", Snake)
    sg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   1),
        NumberSequenceKeypoint.new(0.35, 0.05),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.65, 0.05),
        NumberSequenceKeypoint.new(1,   1),
    })

    local t = 0
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not abar or not abar.Parent then conn:Disconnect(); return end
        t = (t + dt * 0.55) % 1
        Snake.Position = UDim2.new(t - 0.4, 0, 0, 0)
        Glow.BackgroundTransparency = 0.6 + math.abs(math.sin(t * math.pi * 2)) * 0.3
    end)
    addConnection(conn)
    table.insert(snakeConnections, {conn, Glow, Snake})
end

-- ============================================================
-- LOADING SCREEN
-- ============================================================
local function ShowLoading(SG, accent, title, onDone)
    local Overlay = Instance.new("Frame", SG)
    Overlay.Size = UDim2.new(1,0,1,0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
    Overlay.BackgroundTransparency = 0
    Overlay.BorderSizePixel = 0
    Overlay.ZIndex = 100

    local Box = Instance.new("Frame", Overlay)
    Box.Size = UDim2.new(0,300,0,160)
    Box.Position = UDim2.new(0.5,-150,0.5,-80)
    Box.BackgroundColor3 = Color3.fromRGB(8,8,14)
    Box.BorderSizePixel = 0
    Box.ZIndex = 101
    Cor(Box,16)
    local bs = Instance.new("UIStroke",Box)
    bs.Color = accent; bs.Thickness = 1.5

    local BGlow = Instance.new("UIStroke",Box)
    BGlow.Color = accent; BGlow.Thickness = 4
    BGlow.Transparency = 0.7

    local TitleLbl = Instance.new("TextLabel", Box)
    TitleLbl.Size = UDim2.new(1,0,0,36)
    TitleLbl.Position = UDim2.new(0,0,0,24)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = title
    TitleLbl.TextSize = 18
    TitleLbl.Font = T.FontBold
    TitleLbl.TextColor3 = accent
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Center

    local SubLbl = Instance.new("TextLabel", Box)
    SubLbl.Size = UDim2.new(1,0,0,20)
    SubLbl.Position = UDim2.new(0,0,0,58)
    SubLbl.BackgroundTransparency = 1
    SubLbl.Text = "Initializing..."
    SubLbl.TextSize = 11
    SubLbl.Font = T.FontFace
    SubLbl.TextColor3 = Color3.new(accent.R*0.6, accent.G*0.6, accent.B*0.6)
    SubLbl.TextXAlignment = Enum.TextXAlignment.Center

    local BarTrack = Instance.new("Frame", Box)
    BarTrack.Size = UDim2.new(0,220,0,4)
    BarTrack.Position = UDim2.new(0.5,-110,0,100)
    BarTrack.BackgroundColor3 = Color3.fromRGB(20,20,32)
    BarTrack.BorderSizePixel = 0
    Cor(BarTrack, 2)

    local BarFill = Instance.new("Frame", BarTrack)
    BarFill.Size = UDim2.new(0,0,1,0)
    BarFill.BackgroundColor3 = accent
    BarFill.BorderSizePixel = 0
    Cor(BarFill, 2)

    local BarSnake = Instance.new("Frame", BarFill)
    BarSnake.Size = UDim2.new(0.5,0,1,0)
    BarSnake.BackgroundColor3 = Color3.fromRGB(255,255,255)
    BarSnake.BackgroundTransparency = 0.5
    BarSnake.BorderSizePixel = 0
    Cor(BarSnake, 2)
    local bsg = Instance.new("UIGradient", BarSnake)
    bsg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(0.5,0.3),
        NumberSequenceKeypoint.new(1,1),
    })

    local PctLbl = Instance.new("TextLabel", Box)
    PctLbl.Size = UDim2.new(1,0,0,18)
    PctLbl.Position = UDim2.new(0,0,0,116)
    PctLbl.BackgroundTransparency = 1
    PctLbl.Text = "0%"
    PctLbl.TextSize = 10
    PctLbl.Font = T.FontBold
    PctLbl.TextColor3 = Color3.new(accent.R*0.7, accent.G*0.7, accent.B*0.7)
    PctLbl.TextXAlignment = Enum.TextXAlignment.Center

    local dots = {}
    local dotY = 138
    for i = 1,3 do
        local d = Instance.new("Frame", Box)
        d.Size = UDim2.new(0,5,0,5)
        d.Position = UDim2.new(0.5,(i-2)*14-2,0,dotY)
        d.BackgroundColor3 = accent
        d.BackgroundTransparency = 0.3
        d.BorderSizePixel = 0
        Cor(d, 5)
        dots[i] = d
    end

    local steps = {
        {pct=0.15,  txt="Loading modules..."},
        {pct=0.35,  txt="Setting up UI..."},
        {pct=0.55,  txt="Applying theme..."},
        {pct=0.75,  txt="Building elements..."},
        {pct=0.90,  txt="Almost ready..."},
        {pct=1.0,   txt="Done!"},
    }

    local dotIdx = 0
    local dotConn
    dotConn = RunService.Heartbeat:Connect(function()
        dotIdx = dotIdx + 1
        for i,d in ipairs(dots) do
            local phase = ((dotIdx + i*8) % 30) / 30
            d.BackgroundTransparency = 0.1 + math.abs(math.sin(phase*math.pi)) * 0.8
        end
    end)
    addConnection(dotConn)

    task.spawn(function()
        Box.BackgroundTransparency = 1
        Tw(Box, {BackgroundTransparency=0}, 0.3)
        task.wait(0.3)
        for _, step in ipairs(steps) do
            SubLbl.Text = step.txt
            Tw(BarFill, {Size=UDim2.new(step.pct,0,1,0)}, 0.22)
            PctLbl.Text = math.floor(step.pct * 100) .. "%"
            task.wait(0.22)
        end
        task.wait(0.15)
        dotConn:Disconnect()
        Tw(Overlay, {BackgroundTransparency=1}, 0.4)
        task.wait(0.42)
        Overlay:Destroy()
        if onDone then onDone() end
    end)
end

-- ============================================================
-- SETTINGS PANEL (seperti Rayfield)
-- ============================================================
local function CreateSettingsPanel(SG, mainWrapper, win, T, onSettingsChanged, getToggleKeyCallback, setToggleKeyCallback)
    local settingsVisible = false
    local panelWidth = 260
    local panel = Instance.new("Frame", SG)
    panel.Name = "SettingsPanel"
    panel.Size = UDim2.new(0, 0, 0, 0)
    panel.Position = UDim2.new(1, 0, 0, 0)
    panel.BackgroundColor3 = T.ElementBG
    panel.BorderSizePixel = 0
    panel.ZIndex = 150
    panel.ClipsDescendants = true
    Cor(panel, 8)
    Str(panel, T.Accent, 1)

    local header = Instance.new("Frame", panel)
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = T.HeaderBG
    header.BorderSizePixel = 0
    Cor(header, 8)

    local titleLbl = Lbl(header, "Settings", UDim2.new(1, -40, 1, 0), T.TextPri)
    titleLbl.Position = UDim2.new(0, 12, 0, 0)
    titleLbl.Font = T.FontBold
    titleLbl.TextSize = 14

    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
    closeBtn.BackgroundColor3 = T.ElementHov
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextSize = 12
    closeBtn.Font = T.FontBold
    closeBtn.TextColor3 = T.TextPri
    Cor(closeBtn, 6)
    OnClick(closeBtn, function() toggleSettings() end)

    local content = Instance.new("ScrollingFrame", panel)
    content.Size = UDim2.new(1, 0, 1, -40)
    content.Position = UDim2.new(0, 0, 0, 40)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 2
    content.ScrollBarImageColor3 = T.Accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Pad(content, 12, 12, 12, 12)
    local layout = Instance.new("UIListLayout", content)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)

    -- Pengaturan tersimpan
    local settingsFileName = "KreinGuiSettings.json"
    local currentToggleKey = Enum.KeyCode.RightShift
    local currentThemePreset = "Ice"

    local function saveSettings()
        local data = {
            toggleKey = tostring(currentToggleKey),
            themePreset = currentThemePreset,
            accentColor = {r = T.Accent.R, g = T.Accent.G, b = T.Accent.B}
        }
        local ok, err = pcall(function()
            writefile(settingsFileName, HttpService:JSONEncode(data))
        end)
        if not ok then warn("Failed to save settings: ", err) end
    end

    local function loadSettings()
        local ok, raw = pcall(readfile, settingsFileName)
        if not ok or not raw then return end
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok2 or not data then return end
        if data.toggleKey then
            local success, enumKey = pcall(function()
                return Enum.KeyCode[data.toggleKey:gsub("Enum.KeyCode.", "")]
            end)
            if success and enumKey then currentToggleKey = enumKey end
        end
        if data.themePreset and Presets[data.themePreset] then
            currentThemePreset = data.themePreset
            KreinGui:SetTheme(Presets[currentThemePreset])
            onSettingsChanged()
        elseif data.accentColor then
            currentThemePreset = "Custom"
            local col = Color3.new(data.accentColor.r, data.accentColor.g, data.accentColor.b)
            KreinGui:SetTheme({ Accent = col })
            onSettingsChanged()
        end
        if setToggleKeyCallback then setToggleKeyCallback(currentToggleKey) end
    end

    -- Keybind picker
    local keybindFrame = Instance.new("Frame", content)
    keybindFrame.Size = UDim2.new(1, 0, 0, 44)
    keybindFrame.BackgroundColor3 = T.ElementBG
    keybindFrame.BorderSizePixel = 0
    Cor(keybindFrame, 6)
    Str(keybindFrame, T.ElementStr, 1)

    local keybindLabel = Lbl(keybindFrame, "Toggle GUI Key:", UDim2.new(1, -80, 0, 20), T.TextSec)
    keybindLabel.Position = UDim2.new(0, 10, 0, 6)
    keybindLabel.TextSize = 11

    local keybindBtn = Instance.new("TextButton", keybindFrame)
    keybindBtn.Size = UDim2.new(0, 70, 0, 28)
    keybindBtn.Position = UDim2.new(1, -80, 0.5, -14)
    keybindBtn.BackgroundColor3 = T.WindowBG
    keybindBtn.BorderSizePixel = 0
    keybindBtn.Text = tostring(currentToggleKey):gsub("Enum.KeyCode.", "")
    keybindBtn.TextSize = 11
    keybindBtn.Font = T.FontBold
    keybindBtn.TextColor3 = T.Accent
    Cor(keybindBtn, 6)
    Str(keybindBtn, T.ElementStr, 1)

    local listening = false
    local function updateKeybindDisplay()
        keybindBtn.Text = tostring(currentToggleKey):gsub("Enum.KeyCode.", "")
    end
    OnClick(keybindBtn, function()
        if listening then
            listening = false
            keybindBtn.BackgroundColor3 = T.WindowBG
            updateKeybindDisplay()
            return
        end
        listening = true
        keybindBtn.BackgroundColor3 = T.TabHov
        keybindBtn.Text = "..."
        local conn
        conn = UserInput.InputBegan:Connect(function(i, gp)
            if not listening then if conn then conn:Disconnect() end return end
            if gp then return end
            if i.UserInputType == Enum.UserInputType.Keyboard then
                if i.KeyCode == Enum.KeyCode.Escape then
                    listening = false
                    keybindBtn.BackgroundColor3 = T.WindowBG
                    updateKeybindDisplay()
                    if conn then conn:Disconnect() end
                    return
                end
                currentToggleKey = i.KeyCode
                listening = false
                keybindBtn.BackgroundColor3 = T.WindowBG
                updateKeybindDisplay()
                if conn then conn:Disconnect() end
                saveSettings()
                if setToggleKeyCallback then setToggleKeyCallback(currentToggleKey) end
            end
        end)
        addConnection(conn)
    end)

    -- Theme preset dropdown
    local themeFrame = Instance.new("Frame", content)
    themeFrame.Size = UDim2.new(1, 0, 0, 44)
    themeFrame.BackgroundColor3 = T.ElementBG
    themeFrame.BorderSizePixel = 0
    Cor(themeFrame, 6)
    Str(themeFrame, T.ElementStr, 1)

    local themeLabel = Lbl(themeFrame, "Theme Preset:", UDim2.new(1, -80, 0, 20), T.TextSec)
    themeLabel.Position = UDim2.new(0, 10, 0, 6)
    themeLabel.TextSize = 11

    local themeDropdown = Instance.new("TextButton", themeFrame)
    themeDropdown.Size = UDim2.new(0, 70, 0, 28)
    themeDropdown.Position = UDim2.new(1, -80, 0.5, -14)
    themeDropdown.BackgroundColor3 = T.WindowBG
    themeDropdown.BorderSizePixel = 0
    themeDropdown.Text = currentThemePreset
    themeDropdown.TextSize = 11
    themeDropdown.Font = T.FontBold
    themeDropdown.TextColor3 = T.Accent
    Cor(themeDropdown, 6)
    Str(themeDropdown, T.ElementStr, 1)

    local themeOptions = {"Ice", "Neon", "Blood", "Ocean", "Purple", "Gold", "Rose", "Matrix", "Default", "Custom"}
    local themeOpen = false
    local themePop = Instance.new("Frame", SG)
    themePop.Size = UDim2.new(0, 120, 0, 0)
    themePop.BackgroundColor3 = T.ElementBG
    themePop.BorderSizePixel = 0
    themePop.ClipsDescendants = true
    themePop.Visible = false
    themePop.ZIndex = 200
    Cor(themePop, 6)
    Str(themePop, T.ElementStr, 1)
    local themeScroller = Instance.new("ScrollingFrame", themePop)
    themeScroller.Size = UDim2.new(1, 0, 1, 0)
    themeScroller.BackgroundTransparency = 1
    themeScroller.BorderSizePixel = 0
    themeScroller.ScrollBarThickness = 2
    themeScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
    themeScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Pad(themeScroller, 4, 4, 4, 4)
    local themeLayout = Instance.new("UIListLayout", themeScroller)
    themeLayout.SortOrder = Enum.SortOrder.LayoutOrder
    themeLayout.Padding = UDim.new(0, 2)

    for i, preset in ipairs(themeOptions) do
        local btn = Instance.new("TextButton", themeScroller)
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = T.ElementHov
        btn.BorderSizePixel = 0
        btn.Text = preset
        btn.TextSize = 11
        btn.Font = T.FontFace
        btn.TextColor3 = T.TextPri
        btn.LayoutOrder = i
        Cor(btn, 4)
        OnClick(btn, function()
            currentThemePreset = preset
            themeDropdown.Text = preset
            if preset ~= "Custom" then
                KreinGui:UsePreset(preset)
            else
                -- Biarkan custom, tidak berubah
            end
            onSettingsChanged()
            saveSettings()
            closeThemePop()
        end)
        btn.MouseEnter:Connect(function() Tw(btn, {BackgroundColor3 = T.TabHov}, 0.1) end)
        btn.MouseLeave:Connect(function() Tw(btn, {BackgroundColor3 = T.ElementHov}, 0.1) end)
    end
    local function closeThemePop()
        themeOpen = false
        Tw(themePop, {Size = UDim2.new(0, 120, 0, 0)}, 0.18)
        task.delay(0.2, function() themePop.Visible = false end)
    end
    local function openThemePop()
        local ap = themeDropdown.AbsolutePosition
        local w = 120
        local x = ap.X - w + 10
        local vp = workspace.CurrentCamera.ViewportSize
        x = math.max(4, math.min(x, vp.X - w - 4))
        local y = ap.Y + 36
        if y + 200 > vp.Y - 4 then y = ap.Y - 200 - 4 end
        themePop.Position = UDim2.new(0, x, 0, y)
        themePop.Size = UDim2.new(0, w, 0, 0)
        themePop.Visible = true
        themeOpen = true
        Tw(themePop, {Size = UDim2.new(0, w, 0, 200)}, 0.22)
    end
    OnClick(themeDropdown, function()
        if themeOpen then closeThemePop() else openThemePop() end
    end)
    UserInput.InputBegan:Connect(function(i)
        if not themeOpen or not isDown(i) then return end
        task.defer(function()
            if not themeOpen then return end
            local pos = i.Position
            local dp = themePop.AbsolutePosition
            local ds = themePop.AbsoluteSize
            local cp = themeDropdown.AbsolutePosition
            local cs = themeDropdown.AbsoluteSize
            if not (pos.X >= dp.X and pos.X <= dp.X+ds.X and pos.Y >= dp.Y and pos.Y <= dp.Y+ds.Y) and
               not (pos.X >= cp.X and pos.X <= cp.X+cs.X and pos.Y >= cp.Y and pos.Y <= cp.Y+cs.Y) then
                closeThemePop()
            end
        end)
    end)

    -- Custom accent color picker sederhana
    local customColorFrame = Instance.new("Frame", content)
    customColorFrame.Size = UDim2.new(1, 0, 0, 44)
    customColorFrame.BackgroundColor3 = T.ElementBG
    customColorFrame.BorderSizePixel = 0
    Cor(customColorFrame, 6)
    Str(customColorFrame, T.ElementStr, 1)
    local colorLabel = Lbl(customColorFrame, "Custom Accent:", UDim2.new(1, -80, 0, 20), T.TextSec)
    colorLabel.Position = UDim2.new(0, 10, 0, 6)
    colorLabel.TextSize = 11
    local colorSwatch = Instance.new("Frame", customColorFrame)
    colorSwatch.Size = UDim2.new(0, 28, 0, 24)
    colorSwatch.Position = UDim2.new(1, -80, 0.5, -12)
    colorSwatch.BackgroundColor3 = T.Accent
    colorSwatch.BorderSizePixel = 0
    Cor(colorSwatch, 6)
    Str(colorSwatch, T.ElementStr, 1)
    OnClick(colorSwatch, function()
        -- Menggunakan color picker sederhana
        local pickerFrame = Instance.new("Frame", SG)
        pickerFrame.Size = UDim2.new(0, 200, 0, 180)
        pickerFrame.Position = UDim2.new(0.5, -100, 0.5, -90)
        pickerFrame.BackgroundColor3 = T.ElementBG
        pickerFrame.BorderSizePixel = 0
        pickerFrame.ZIndex = 300
        Cor(pickerFrame, 8)
        Str(pickerFrame, T.Accent, 1)

        local hueBar = Instance.new("Frame", pickerFrame)
        hueBar.Size = UDim2.new(0.8, 0, 0, 16)
        hueBar.Position = UDim2.new(0.1, 0, 0.2, 0)
        hueBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
        local hueImg = Instance.new("ImageLabel", hueBar)
        hueImg.Size = UDim2.new(1,0,1,0)
        hueImg.Image = "rbxassetid://698052001"

        local satVal = Instance.new("Frame", pickerFrame)
        satVal.Size = UDim2.new(0.6, 0, 0.4, 0)
        satVal.Position = UDim2.new(0.1, 0, 0.45, 0)
        satVal.BackgroundColor3 = T.Accent

        local pickBtn = Instance.new("TextButton", pickerFrame)
        pickBtn.Size = UDim2.new(0.8, 0, 0, 28)
        pickBtn.Position = UDim2.new(0.1, 0, 0.75, 0)
        pickBtn.Text = "Pick from Screen"
        pickBtn.BackgroundColor3 = T.ElementHov
        pickBtn.Font = T.FontFace
        pickBtn.TextColor3 = T.TextPri
        Cor(pickBtn, 6)

        local okBtn = Instance.new("TextButton", pickerFrame)
        okBtn.Size = UDim2.new(0.35, 0, 0, 28)
        okBtn.Position = UDim2.new(0.1, 0, 0.75, 0)
        okBtn.Text = "OK"
        okBtn.BackgroundColor3 = T.Accent
        okBtn.Font = T.FontBold
        okBtn.TextColor3 = Color3.fromRGB(255,255,255)
        okBtn.Visible = false
        Cor(okBtn, 6)

        local currentHue = 0
        local currentSat = 1
        local currentVal = 1

        local function updateColor()
            local col = Color3.fromHSV(currentHue, currentSat, currentVal)
            satVal.BackgroundColor3 = col
            colorSwatch.BackgroundColor3 = col
            currentThemePreset = "Custom"
            themeDropdown.Text = "Custom"
            KreinGui:SetTheme({ Accent = col })
            onSettingsChanged()
            saveSettings()
        end

        hueBar.InputBegan:Connect(function(i)
            if isDown(i) then
                local x = math.clamp((i.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                currentHue = x
                updateColor()
            end
        end)
        local satConn
        local function startSatPick()
            satConn = UserInput.InputChanged:Connect(function(i)
                if isMove(i) then
                    local x = math.clamp((i.Position.X - satVal.AbsolutePosition.X) / satVal.AbsoluteSize.X, 0, 1)
                    local y = math.clamp((i.Position.Y - satVal.AbsolutePosition.Y) / satVal.AbsoluteSize.Y, 0, 1)
                    currentSat = x
                    currentVal = 1 - y
                    updateColor()
                end
            end)
            addConnection(satConn)
        end
        satVal.InputBegan:Connect(function(i)
            if isDown(i) then
                startSatPick()
                local x = math.clamp((i.Position.X - satVal.AbsolutePosition.X) / satVal.AbsoluteSize.X, 0, 1)
                local y = math.clamp((i.Position.Y - satVal.AbsolutePosition.Y) / satVal.AbsoluteSize.Y, 0, 1)
                currentSat = x
                currentVal = 1 - y
                updateColor()
            end
        end)
        UserInput.InputEnded:Connect(function(i)
            if isDown(i) then
                if satConn then satConn:Disconnect() end
            end
        end)

        pickBtn.MouseButton1Click:Connect(function()
            pickerFrame:Destroy()
            local eyeActive = true
            local connPick
            connPick = Mouse.Button1Down:Connect(function()
                if not eyeActive then return end
                local target = Mouse.Target
                local color = Color3.new(1,1,1)
                if target then
                    if target:IsA("BasePart") then color = target.Color
                    elseif target:IsA("GuiObject") then color = target.BackgroundColor3
                    else color = Color3.fromRGB(255,255,255) end
                end
                local h,s,v = Color3.toHSV(color)
                currentHue = h
                currentSat = s
                currentVal = v
                updateColor()
                eyeActive = false
                if connPick then connPick:Disconnect() end
            end)
            task.delay(5, function() if eyeActive then eyeActive=false; if connPick then connPick:Disconnect() end end end)
        end)

        pickerFrame.Parent = SG
    end)

    local function updatePanelPosition()
        local wrapperPos = mainWrapper.AbsolutePosition
        local wrapperSize = mainWrapper.AbsoluteSize
        panel.Position = UDim2.new(0, wrapperPos.X + wrapperSize.X + 4, 0, wrapperPos.Y)
        panel.Size = UDim2.new(0, panelWidth, 0, wrapperSize.Y)
    end

    local function toggleSettings()
        settingsVisible = not settingsVisible
        if settingsVisible then
            updatePanelPosition()
            panel.Visible = true
            panel.Size = UDim2.new(0, 0, 0, 0)
            Tw(panel, {Size = UDim2.new(0, panelWidth, 0, mainWrapper.AbsoluteSize.Y)}, 0.25)
        else
            Tw(panel, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
            task.delay(0.2, function() panel.Visible = false end)
        end
    end

    mainWrapper:GetPropertyChangedSignal("Position"):Connect(function()
        if settingsVisible then updatePanelPosition() end
    end)
    mainWrapper:GetPropertyChangedSignal("Size"):Connect(function()
        if settingsVisible then updatePanelPosition() end
    end)

    loadSettings()
    if getToggleKeyCallback then getToggleKeyCallback(currentToggleKey) end
    return toggleSettings, function() return currentToggleKey end, function(k) currentToggleKey = k; saveSettings() end
end

-- ============================================================
-- LIBRARY
-- ============================================================
local KreinGui = {}
KreinGui.__index = KreinGui
KreinGui.Flags = {}
KreinGui.Presets = Presets

function KreinGui:SetTheme(ov)
    for k,v in pairs(ov) do T[k]=v end
    if ov.Accent then
        T.AccentHov  = Color3.new(math.min(ov.Accent.R+0.12,1),math.min(ov.Accent.G+0.12,1),math.min(ov.Accent.B+0.12,1))
        T.AccentDark = Color3.new(ov.Accent.R*0.6,ov.Accent.G*0.6,ov.Accent.B*0.6)
        T.ToggleOn   = ov.Accent
        T.TabOn      = ov.Accent
    end
    if ov.FontFace then T.FontFace = ov.FontFace end
    if ov.FontBold then T.FontBold = ov.FontBold end
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
    local title   = cfg.Title      or "KreinGui"
    local sub     = cfg.SubTitle   or ""
    local cfgName = cfg.ConfigName or "KreinGuiConfig"

    local SG = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    SG.Name="KreinGui"
    SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    SG.ResetOnSpawn=false
    SG.IgnoreGuiInset=true
    currentGui = SG

    SG.AncestryChanged:Connect(function()
        if not SG.Parent then
            destroyAllConnections()
            if currentGui == SG then currentGui = nil end
        end
    end)

    local Wrapper = Instance.new("Frame", SG)
    Wrapper.Name = "Wrapper"
    Wrapper.Size = UDim2.new(0, 560+32, 0, 340)
    Wrapper.Position = UDim2.new(0.5, -280-32, 0.5, -170)
    Wrapper.BackgroundTransparency = 1
    Wrapper.BorderSizePixel = 0
    Wrapper.ClipsDescendants = false

    local Win = Instance.new("Frame", Wrapper)
    Win.Name="Window"
    Win.Size=UDim2.new(0,560,0,340)
    Win.Position=UDim2.new(0,32,0,0)
    Win.BackgroundColor3=T.WindowBG
    Win.BorderSizePixel=0
    Win.ClipsDescendants=true
    Cor(Win,12); Str(Win,T.WinStr,1)
    local g=Instance.new("UIGradient",Win)
    g.Color=ColorSequence.new(Color3.fromRGB(18,28,40),Color3.fromRGB(8,14,22))
    g.Rotation=135

    Win.BackgroundTransparency = 1
    Win.Visible = false

    -- Header
    local H=Instance.new("Frame",Win)
    H.Name="Header"; H.Size=UDim2.new(1,0,0,52)
    H.BackgroundColor3=T.HeaderBG; H.BorderSizePixel=0; H.ZIndex=4
    Cor(H,12)

    local ABar=Instance.new("Frame",Win)
    ABar.Name="ABar"; ABar.Size=UDim2.new(1,0,0,4)
    ABar.Position=UDim2.new(0,0,0,50)
    ABar.BackgroundColor3=T.Accent; ABar.BorderSizePixel=0; ABar.ZIndex=3
    StartSnake(ABar, T.Accent, Win)

    local LogoBg=Instance.new("Frame",H)
    LogoBg.Size=UDim2.new(0,34,0,34)
    LogoBg.Position=UDim2.new(0,10,0.5,-17)
    LogoBg.BackgroundColor3=T.Accent
    LogoBg.BackgroundTransparency=0.12
    LogoBg.BorderSizePixel=0
    LogoBg.ZIndex=5
    Cor(LogoBg,8)
    local LogoStr=Instance.new("UIStroke",LogoBg)
    LogoStr.Color=T.Accent; LogoStr.Thickness=1.5; LogoStr.Transparency=0.3

    local LogoK=Instance.new("TextLabel",LogoBg)
    LogoK.Size=UDim2.new(1,0,1,0)
    LogoK.BackgroundTransparency=1
    LogoK.Text="K"
    LogoK.TextSize=18
    LogoK.Font=T.FontBold
    LogoK.TextColor3=Color3.fromRGB(10,15,20)
    LogoK.TextXAlignment=Enum.TextXAlignment.Center

    local LogoDot=Instance.new("Frame",LogoBg)
    LogoDot.Size=UDim2.new(0,6,0,6)
    LogoDot.Position=UDim2.new(1,-5,1,-5)
    LogoDot.BackgroundColor3=Color3.fromRGB(8,8,14)
    LogoDot.BorderSizePixel=0
    Cor(LogoDot,3)

    local TL=Lbl(H,title,UDim2.new(0,260,0,22),T.TextPri)
    TL.Position=sub~="" and UDim2.new(0,52,0,5) or UDim2.new(0,52,0,15)
    TL.Font=T.FontBold; TL.TextSize=15
    if sub~="" then
        local SL=Lbl(H,sub,UDim2.new(0,260,0,18),T.TextMut)
        SL.Position=UDim2.new(0,52,0,28); SL.Font=T.FontFace; SL.TextSize=11
    end

    -- CLOSE BUTTON (X)
    local Cb = Instance.new("TextButton", H)
    Cb.Size = UDim2.new(0,32,0,32); Cb.Position = UDim2.new(1,-40,0.5,-16)
    Cb.BackgroundColor3 = Color3.fromRGB(60,35,35); Cb.BorderSizePixel = 0
    Cb.Text = "X"
    Cb.TextSize = 14
    Cb.Font = T.FontBold
    Cb.TextColor3 = T.CloseRed
    Cb.ZIndex = 6
    Cb.AutoButtonColor = false
    Cor(Cb,7)
    OnClick(Cb, function() SG:Destroy() end)

    -- MINIMIZE BUTTON
    local Mb = Instance.new("TextButton", H)
    Mb.Size = UDim2.new(0,32,0,32); Mb.Position = UDim2.new(1,-78,0.5,-16)
    Mb.BackgroundColor3 = Color3.fromRGB(40,40,50); Mb.BorderSizePixel = 0
    Mb.Text = "−"
    Mb.TextSize = 16
    Mb.Font = T.FontBold
    Mb.TextColor3 = T.MinGray
    Mb.ZIndex = 6
    Mb.AutoButtonColor = false
    Cor(Mb,7)

    -- SETTINGS BUTTON
    local SettingsBtn = Instance.new("TextButton", H)
    SettingsBtn.Size = UDim2.new(0,32,0,32); SettingsBtn.Position = UDim2.new(1,-116,0.5,-16)
    SettingsBtn.BackgroundColor3 = T.ElementHov
    SettingsBtn.BorderSizePixel = 0
    SettingsBtn.Text = "⚙"
    SettingsBtn.TextSize = 16
    SettingsBtn.Font = T.FontBold
    SettingsBtn.TextColor3 = T.TextPri
    SettingsBtn.ZIndex = 6
    SettingsBtn.AutoButtonColor = false
    Cor(SettingsBtn, 7)

    local function syncToggleBtnY(h)
        if ToggleBtn then ToggleBtn.Position = UDim2.new(0, 0, 0, h/2 - 40) end
    end

    local mini = false
    local resizeEnabled = true
    OnClick(Mb, function()
        mini = not mini
        if mini then
            Mb.Text = "+"
            resizeEnabled = false
            Tw(Win, {Size = UDim2.new(0,560,0,52)}, 0.3)
            Tw(Wrapper, {Size = UDim2.new(0,560+32,0,52)}, 0.3)
            task.delay(0.2, function()
                ABar.Visible = false
                local gl = Win:FindFirstChild("ABarGlow")
                if gl then gl.Visible = false end
                syncToggleBtnY(52)
                lastWrapperSize = Wrapper.Size
                lastWinSize = Win.Size
            end)
        else
            Mb.Text = "−"
            resizeEnabled = true
            ABar.Visible = true
            local gl = Win:FindFirstChild("ABarGlow")
            if gl then gl.Visible = true end
            Tw(Win, {Size = UDim2.new(0,560,0,340)}, 0.4, Enum.EasingStyle.Back)
            Tw(Wrapper, {Size = UDim2.new(0,560+32,0,340)}, 0.4, Enum.EasingStyle.Back)
            task.delay(0.35, function()
                syncToggleBtnY(340)
                lastWrapperSize = Wrapper.Size
                lastWinSize = Win.Size
            end)
        end
    end)

    EnableDrag(Wrapper, H)

    -- TOGGLE BUTTON (K)
    local ToggleBtn = Instance.new("TextButton", Wrapper)
    ToggleBtn.Name = "KreinToggleBtn"
    ToggleBtn.Size = UDim2.new(0, 28, 0, 80)
    ToggleBtn.Position = UDim2.new(0, 0, 0.5, -40)
    ToggleBtn.BackgroundColor3 = T.WindowBG
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = ""
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.ZIndex = 10
    Cor(ToggleBtn, 8)
    local TBStr = Instance.new("UIStroke", ToggleBtn)
    TBStr.Color = T.Accent; TBStr.Thickness = 1; TBStr.Transparency = 0.3

    local TBIcon = Instance.new("TextLabel", ToggleBtn)
    TBIcon.Size = UDim2.new(1,0,0,16)
    TBIcon.Position = UDim2.new(0,0,0.5,-26)
    TBIcon.BackgroundTransparency = 1
    TBIcon.Text = "◀"; TBIcon.TextSize = 10
    TBIcon.Font = T.FontBold
    TBIcon.TextColor3 = T.Accent
    TBIcon.TextXAlignment = Enum.TextXAlignment.Center

    local TBLabel = Instance.new("TextLabel", ToggleBtn)
    TBLabel.Size = UDim2.new(1,0,0,14)
    TBLabel.Position = UDim2.new(0,0,0.5,-7)
    TBLabel.BackgroundTransparency = 1
    TBLabel.Text = "K"
    TBLabel.TextSize = 13
    TBLabel.Font = T.FontBold
    TBLabel.TextColor3 = T.Accent
    TBLabel.TextXAlignment = Enum.TextXAlignment.Center

    local TBSub = Instance.new("TextLabel", ToggleBtn)
    TBSub.Size = UDim2.new(1,0,0,12)
    TBSub.Position = UDim2.new(0,0,0.5,14)
    TBSub.BackgroundTransparency = 1
    TBSub.Text = "GUI"
    TBSub.TextSize = 8
    TBSub.Font = T.FontBold
    TBSub.TextColor3 = Color3.new(T.Accent.R*0.65, T.Accent.G*0.65, T.Accent.B*0.65)
    TBSub.TextXAlignment = Enum.TextXAlignment.Center

    local TBGlow = Instance.new("Frame", ToggleBtn)
    TBGlow.Size = UDim2.new(0,3,0.65,0)
    TBGlow.Position = UDim2.new(1,-3,0.175,0)
    TBGlow.BackgroundColor3 = T.Accent
    TBGlow.BackgroundTransparency = 0.35
    TBGlow.BorderSizePixel = 0
    Cor(TBGlow, 2)

    local guiVisible = true
    local lastWrapperSize = Wrapper.Size
    local lastWinSize = Win.Size
    local lastWrapperPos = Wrapper.Position

    Wrapper:GetPropertyChangedSignal("Position"):Connect(function()
        if guiVisible then lastWrapperPos = Wrapper.Position end
    end)

    local function updateToggleBtn()
        if guiVisible then
            TBIcon.Text = "◀"
            TBStr.Transparency = 0.3
            TBGlow.BackgroundTransparency = 0.35
        else
            TBIcon.Text = "▶"
            TBStr.Transparency = 0.05
            TBStr.Color = T.AccentHov
            TBGlow.BackgroundTransparency = 0.1
        end
    end

    local function toggleGuiVisibility()
        guiVisible = not guiVisible
        local currentWinH = Win.Size.Y.Offset
        if guiVisible then
            Win.Visible = true
            Win.BackgroundTransparency = 0
            Win.Size = UDim2.new(0, 0, 0, currentWinH)
            Win.Position = UDim2.new(0, 32, 0, 0)
            Wrapper.Position = lastWrapperPos
            Tw(Win, {Size = lastWinSize}, 0.4)
            Wrapper.Size = lastWrapperSize
            syncToggleBtnY(lastWinSize.Y.Offset)
        else
            lastWrapperSize = Wrapper.Size
            lastWinSize = Win.Size
            lastWrapperPos = Wrapper.Position
            local currentY = Wrapper.Position.Y
            Tw(Win, {Size = UDim2.new(0, 0, 0, currentWinH)}, 0.35)
            task.delay(0.35, function()
                Win.Visible = false
                Win.Size = lastWinSize
            end)
            Tw(Wrapper, {Position = UDim2.new(0, -4, currentY.Scale, currentY.Offset)}, 0.35)
        end
        updateToggleBtn()
    end

    OnClick(ToggleBtn, toggleGuiVisibility)

    ToggleBtn.MouseEnter:Connect(function()
        Tw(ToggleBtn, {BackgroundColor3=T.ElementHov}, 0.12)
        TBStr.Transparency = 0
    end)
    ToggleBtn.MouseLeave:Connect(function()
        Tw(ToggleBtn, {BackgroundColor3=T.WindowBG}, 0.12)
        TBStr.Transparency = guiVisible and 0.3 or 0.05
    end)

    -- Body
    local Body=Instance.new("Frame",Win)
    Body.Size=UDim2.new(1,0,1,-54); Body.Position=UDim2.new(0,0,0,54)
    Body.BackgroundTransparency=1

    local TW=130
    local TP=Instance.new("Frame",Body)
    TP.Size=UDim2.new(0,TW,1,0); TP.BackgroundColor3=T.TabBG; TP.BorderSizePixel=0
    local SepL=Instance.new("Frame",Body)
    SepL.Size=UDim2.new(0,1,1,0); SepL.Position=UDim2.new(0,TW,0,0)
    SepL.BackgroundColor3=T.Sep

    local TSc=Instance.new("ScrollingFrame",TP)
    TSc.Size=UDim2.new(1,0,1,0); TSc.BackgroundTransparency=1; TSc.BorderSizePixel=0
    TSc.ScrollBarThickness=2; TSc.ScrollBarImageColor3=T.Accent
    TSc.CanvasSize=UDim2.new(0,0,0,0); TSc.AutomaticCanvasSize=Enum.AutomaticSize.Y
    Pad(TSc,8,8,6,6)
    local TL2=Instance.new("UIListLayout",TSc)
    TL2.SortOrder=Enum.SortOrder.LayoutOrder; TL2.Padding=UDim.new(0,3)
    TL2.HorizontalAlignment=Enum.HorizontalAlignment.Center

    local CP=Instance.new("Frame",Body)
    CP.Size=UDim2.new(1,-(TW+1),1,0); CP.Position=UDim2.new(0,TW+1,0,0)
    CP.BackgroundTransparency=1; CP.ClipsDescendants=true

    -- SEARCH BAR
    local SearchFrame = Instance.new("Frame", CP)
    SearchFrame.Size = UDim2.new(1,0,0,32)
    SearchFrame.BackgroundColor3 = T.ElementBG
    SearchFrame.BorderSizePixel = 0
    SearchFrame.ZIndex = 50
    Cor(SearchFrame, 6)
    local SearchBox = Instance.new("TextBox", SearchFrame)
    SearchBox.Size = UDim2.new(1,-16,0,24)
    SearchBox.Position = UDim2.new(0,8,0,4)
    SearchBox.BackgroundColor3 = T.WindowBG
    SearchBox.BorderSizePixel = 0
    SearchBox.PlaceholderText = "🔍 Search flags..."
    SearchBox.TextColor3 = T.TextPri
    SearchBox.PlaceholderColor3 = T.TextMut
    SearchBox.TextSize = 12
    SearchBox.Font = T.FontFace
    Cor(SearchBox, 4)
    Str(SearchBox, T.ElementStr, 1)

    local ContentContainer = Instance.new("Frame", CP)
    ContentContainer.Size = UDim2.new(1,0,1,-32)
    ContentContainer.Position = UDim2.new(0,0,0,32)
    ContentContainer.BackgroundTransparency = 1

    -- RESIZE GRIP (dengan pengecekan resizeEnabled)
    local ResizeGrip = Instance.new("TextButton", Win)
    ResizeGrip.Size = UDim2.new(0, 12, 0, 12)
    ResizeGrip.Position = UDim2.new(1, -14, 1, -14)
    ResizeGrip.BackgroundColor3 = T.Accent
    ResizeGrip.BackgroundTransparency = 0.5
    ResizeGrip.Text = ""
    ResizeGrip.ZIndex = 20
    Cor(ResizeGrip, 3)
    local resizeActive = false
    local resizeStartPos, resizeStartSize
    ResizeGrip.InputBegan:Connect(function(i)
        if isDown(i) and resizeEnabled then
            resizeActive = true
            resizeStartPos = i.Position
            resizeStartSize = Wrapper.Size
            dragEnabled = false
        end
    end)
    UserInput.InputChanged:Connect(function(i)
        if resizeActive and isMove(i) and resizeEnabled then
            local delta = i.Position - resizeStartPos
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
        if isDown(i) then resizeActive = false; dragEnabled = true end
    end)

    -- Settings Panel
    local function onThemeChanged()
        Win.BackgroundColor3 = T.WindowBG
        H.BackgroundColor3 = T.HeaderBG
        TP.BackgroundColor3 = T.TabBG
        SepL.BackgroundColor3 = T.Sep
        ABar.BackgroundColor3 = T.Accent
        LogoBg.BackgroundColor3 = T.Accent
        LogoStr.Color = T.Accent
        TBStr.Color = T.Accent
        TBIcon.TextColor3 = T.Accent
        TBLabel.TextColor3 = T.Accent
        TBSub.TextColor3 = Color3.new(T.Accent.R*0.65, T.Accent.G*0.65, T.Accent.B*0.65)
        TBGlow.BackgroundColor3 = T.Accent
        ResizeGrip.BackgroundColor3 = T.Accent
        for _, btn in ipairs(tBtns) do
            local on = (btn == tBtns[tActive])
            btn.BackgroundColor3 = on and T.TabOn or T.TabDef
            local l = btn:FindFirstChild("L")
            if l then l.TextColor3 = on and T.TabOnText or T.TabOffText end
            local bar = btn:FindFirstChild("B")
            if bar then bar.BackgroundColor3 = T.AccentHov end
        end
    end

    local toggleSettingsPanel, getKey, setKey = CreateSettingsPanel(SG, Wrapper, Win, T, onThemeChanged)
    OnClick(SettingsBtn, function() toggleSettingsPanel() end)

    -- Global keybind toggle GUI
    local currentKeybind = Enum.KeyCode.RightShift
    local keybindConnection
    local function applyKeybind()
        if keybindConnection then keybindConnection:Disconnect() end
        keybindConnection = UserInput.InputBegan:Connect(function(i, gp)
            if gp then return end
            if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == currentKeybind then
                toggleGuiVisibility()
            end
        end)
        addConnection(keybindConnection)
    end
    -- Override setKey untuk memperbarui keybind
    local oldSetKey = setKey
    setKey = function(k)
        oldSetKey(k)
        currentKeybind = k
        applyKeybind()
    end
    currentKeybind = getKey()
    applyKeybind()

    -- Window Object
    local W={}
    local tBtns,tFrms={},{}
    local tActive=nil

    local function setTab(idx)
        tActive=idx
        for i,b in ipairs(tBtns) do
            local on=(i==idx)
            Tw(b,{BackgroundColor3=on and T.TabOn or T.TabDef},0.2)
            local l=b:FindFirstChild("L")
            if l then Tw(l,{TextColor3=on and T.TabOnText or T.TabOffText},0.2) end
            local bar=b:FindFirstChild("B"); if bar then bar.Visible=on end
        end
        for i,f in ipairs(tFrms) do
            if i==idx then
                f.Size=UDim2.new(0,0,0,0)
                Tw(f,{Size=UDim2.new(1,0,1,0)},0.22)
            else
                f.Size=UDim2.new(0,0,0,0)
            end
        end
        SearchBox.Text = ""
        for _, api in pairs(KreinGui.Flags) do
            if api._element then api._element.Visible = true end
        end
    end

    local flags={}
    local function sCol(c) return{r=c.R,g=c.G,b=c.B} end
    local function dCol(t) return Color3.new(t.r,t.g,t.b) end

    function W:SaveConfig()
        local d={}
        for k,api in pairs(flags) do
            local v=api:Get()
            if typeof(v)=="Color3" then d[k]={__t="Color3",v=sCol(v)}
            elseif typeof(v)=="EnumItem" then d[k]={__t="Enum",v=tostring(v)}
            else d[k]=v end
        end
        local ok,e=pcall(function() writefile(cfgName..".json",HttpService:JSONEncode(d)) end)
        Notify(SG, ok and "Config saved!" or "Failed: "..tostring(e), 2)
    end

    function W:LoadConfig()
        local ok,raw=pcall(readfile,cfgName..".json")
        if not ok or not raw then Notify(SG,"Config not found.",2); return end
        local ok2,d=pcall(HttpService.JSONDecode,HttpService,raw)
        if not ok2 or not d then Notify(SG,"Config corrupted.",2); return end
        for k,val in pairs(d) do
            if flags[k] then
                if type(val)=="table" and val.__t=="Color3" then flags[k]:Set(dCol(val.v))
                elseif type(val)=="table" and val.__t=="Enum" then
                    local pts=string.split(val.v,".")
                    local ok3,en=pcall(function() return Enum[pts[2]][pts[3]] end)
                    if ok3 then flags[k]:Set(en) end
                else flags[k]:Set(val) end
            end
        end
        Notify(SG,"Config loaded!",2)
    end

    function W:ExportToClipboard()
        local d={}
        for k,api in pairs(flags) do
            local v=api:Get()
            if typeof(v)=="Color3" then d[k]={__t="Color3",v=sCol(v)}
            elseif typeof(v)=="EnumItem" then d[k]={__t="Enum",v=tostring(v)}
            else d[k]=v end
        end
        local json = HttpService:JSONEncode(d)
        if setclipboard then
            setclipboard(json)
            Notify(SG,"Config copied to clipboard!",2)
        else
            Notify(SG,"Clipboard not supported.",2)
        end
    end

    function W:ImportFromClipboard()
        if not getclipboard then Notify(SG,"Clipboard not supported.",2); return end
        local raw = getclipboard()
        local ok,d = pcall(HttpService.JSONDecode,HttpService,raw)
        if not ok then Notify(SG,"Invalid clipboard data.",2); return end
        for k,val in pairs(d) do
            if flags[k] then
                if type(val)=="table" and val.__t=="Color3" then flags[k]:Set(dCol(val.v))
                elseif type(val)=="table" and val.__t=="Enum" then
                    local pts=string.split(val.v,".")
                    local ok3,en=pcall(function() return Enum[pts[2]][pts[3]] end)
                    if ok3 then flags[k]:Set(en) end
                else flags[k]:Set(val) end
            end
        end
        Notify(SG,"Config imported from clipboard!",2)
    end

    function W:Notify(msg,dur) Notify(SG,msg,dur) end

    function W:ReloadTheme()
        onThemeChanged()
        Notify(SG,"Theme reloaded",2)
    end

    -- CREATE TAB
    function W:CreateTab(name)
        local idx=#tBtns+1

        local Btn=Instance.new("TextButton",TSc)
        Btn.Name="Tab"..idx; Btn.Size=UDim2.new(1,-4,0,40)
        Btn.BackgroundColor3=T.TabDef; Btn.BorderSizePixel=0
        Btn.Text=""; Btn.LayoutOrder=idx; Btn.AutoButtonColor=false
        Cor(Btn,7)

        local BBar=Instance.new("Frame",Btn)
        BBar.Name="B"; BBar.Size=UDim2.new(0,3,0.55,0); BBar.Position=UDim2.new(0,0,0.225,0)
        BBar.BackgroundColor3=T.AccentHov; BBar.BorderSizePixel=0; BBar.Visible=false; Cor(BBar,2)

        local BL=Lbl(Btn,name,UDim2.new(1,-14,1,0),T.TabOffText)
        BL.Name="L"; BL.Position=UDim2.new(0,10,0,0); BL.Font=T.FontFace; BL.TextSize=12

        OnClick(Btn,function() setTab(idx) end)
        Btn.MouseEnter:Connect(function() if tActive~=idx then Tw(Btn,{BackgroundColor3=T.TabHov},0.15) end end)
        Btn.MouseLeave:Connect(function() if tActive~=idx then Tw(Btn,{BackgroundColor3=T.TabDef},0.15) end end)
        tBtns[idx]=Btn

        local Con=Instance.new("ScrollingFrame",ContentContainer)
        Con.Name="C"..idx
        Con.BackgroundTransparency=1; Con.BorderSizePixel=0
        Con.ScrollBarThickness=3; Con.ScrollBarImageColor3=T.Accent
        Con.CanvasSize=UDim2.new(0,0,0,0)
        Con.AutomaticCanvasSize=Enum.AutomaticSize.Y
        Con.ClipsDescendants=true
        Con.Visible=true
        Con.Size=UDim2.new(0,0,0,0)
        Pad(Con,10,10,10,10)
        local EL=Instance.new("UIListLayout",Con)
        EL.SortOrder=Enum.SortOrder.LayoutOrder; EL.Padding=UDim.new(0,6)

        tFrms[idx]=Con
        if idx==1 then setTab(1) end

        -- Search filter
        SearchBox.Changed:Connect(function()
            if tActive ~= idx then return end
            local query = SearchBox.Text:lower()
            for _, api in pairs(KreinGui.Flags) do
                if api._element and api._flag then
                    if query == "" or api._flag:lower():find(query) then
                        api._element.Visible = true
                    else
                        api._element.Visible = false
                    end
                end
            end
        end)

        local Tab={}
        local ord=0
        local function nxt() ord=ord+1; return ord end
        local function rfl(flag,api,element)
            if flag and flag~="" then
                flags[flag]=api
                KreinGui.Flags[flag]=api
                api._flag = flag
                api._element = element
            end
        end

        local function Card(h)
            local c=Instance.new("Frame",Con)
            c.Size=UDim2.new(1,0,0,h or 44); c.BackgroundColor3=T.ElementBG
            c.BorderSizePixel=0; c.LayoutOrder=nxt(); c.ClipsDescendants=false
            Cor(c,8); Str(c,T.ElementStr,1)
            return c
        end

        local function addTooltip(element, text)
            if not text then return end
            element.MouseEnter:Connect(function() ShowTooltip(text, element) end)
            element.MouseLeave:Connect(function() HideTooltip() end)
        end

        -- ELEMENT METHODS
        function Tab:CreateLabel(txt, hint)
            local c=Card(36); Pad(c,0,0,12,12)
            local l=Lbl(c,txt,UDim2.new(1,0,1,0),T.TextSec)
            l.Font=T.FontFace; l.TextSize=12
            if hint then addTooltip(c, hint) end
            return l
        end

        function Tab:CreateSectionHeader(txt, hint)
            local c=Instance.new("Frame",Con)
            c.Size=UDim2.new(1,0,0,24); c.BackgroundTransparency=1
            c.BorderSizePixel=0; c.LayoutOrder=nxt()
            local line=Instance.new("Frame",c)
            line.Size=UDim2.new(0,3,0.6,0); line.Position=UDim2.new(0,0,0.2,0)
            line.BackgroundColor3=T.Accent; line.BorderSizePixel=0; Cor(line,2)
            local l=Lbl(c,txt:upper(),UDim2.new(1,-10,1,0),T.SecText)
            l.Position=UDim2.new(0,10,0,0); l.Font=T.FontBold; l.TextSize=10
            if hint then addTooltip(c, hint) end
            return l
        end

        function Tab:AddSeparator()
            local s=Instance.new("Frame",Con)
            s.Size=UDim2.new(1,0,0,1); s.BackgroundColor3=T.Sep
            s.BorderSizePixel=0; s.LayoutOrder=nxt()
        end

        function Tab:CreateButton(cfg2)
            cfg2=cfg2 or {}
            local c=Card(44); Pad(c,0,0,12,12)
            local hov=Instance.new("TextButton",c)
            hov.Size=UDim2.new(1,0,1,0); hov.BackgroundTransparency=1
            hov.BorderSizePixel=0; hov.Text=""; hov.AutoButtonColor=false
            Lbl(c,cfg2.Title or "Button",UDim2.new(1,-82,1,0))
            local rb=Instance.new("TextButton",c)
            rb.Size=UDim2.new(0,68,0,30); rb.Position=UDim2.new(1,-72,0.5,-15)
            rb.BackgroundColor3=T.Accent; rb.BorderSizePixel=0
            rb.Text="Run"; rb.TextSize=11; rb.Font=T.FontBold
            rb.TextColor3=Color3.fromRGB(255,255,255); rb.AutoButtonColor=false; Cor(rb,6)
            OnClick(rb,function()
                Tw(rb,{BackgroundColor3=T.AccentDark},0.1)
                task.delay(0.15,function() Tw(rb,{BackgroundColor3=T.Accent},0.15) end)
                pcall(cfg2.Callback or function()end)
            end)
            rb.MouseEnter:Connect(function() Tw(rb,{BackgroundColor3=T.AccentHov},0.15) end)
            rb.MouseLeave:Connect(function() Tw(rb,{BackgroundColor3=T.Accent},0.15) end)
            hov.MouseEnter:Connect(function() Tw(c,{BackgroundColor3=T.ElementHov},0.15) end)
            hov.MouseLeave:Connect(function() Tw(c,{BackgroundColor3=T.ElementBG},0.15) end)
            if cfg2.Hint then addTooltip(c, cfg2.Hint) end
        end

        function Tab:CreateToggle(cfg2)
            cfg2=cfg2 or {}
            local st=cfg2.Default or false
            local c=Card(44); Pad(c,0,0,12,12)
            Lbl(c,cfg2.Title or "Toggle",UDim2.new(1,-58,1,0))
            local Tr=Instance.new("Frame",c)
            Tr.Size=UDim2.new(0,44,0,24); Tr.Position=UDim2.new(1,-48,0.5,-12)
            Tr.BackgroundColor3=st and T.ToggleOn or T.ToggleOff; Tr.BorderSizePixel=0; Cor(Tr,12)
            local Kn=Instance.new("Frame",Tr)
            Kn.Size=UDim2.new(0,18,0,18)
            Kn.Position=st and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
            Kn.BackgroundColor3=Color3.fromRGB(255,255,255); Kn.BorderSizePixel=0; Cor(Kn,9)
            local tb=Instance.new("TextButton",c)
            tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1; tb.BorderSizePixel=0; tb.Text=""; tb.AutoButtonColor=false
            local api={}
            local function upd()
                Tw(Tr,{BackgroundColor3=st and T.ToggleOn or T.ToggleOff},0.18)
                Tw(Kn,{Position=st and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)},0.18)
                pcall(cfg2.Callback or function()end,st)
            end
            function api:Set(v) st=v; upd() end
            function api:Get() return st end
            OnClick(tb,function() st=not st; upd() end)
            tb.MouseEnter:Connect(function() Tw(c,{BackgroundColor3=T.ElementHov},0.15) end)
            tb.MouseLeave:Connect(function() Tw(c,{BackgroundColor3=T.ElementBG},0.15) end)
            rfl(cfg2.Flag,api,c)
            if cfg2.Hint then addTooltip(c, cfg2.Hint) end
            return api
        end

        function Tab:CreateSlider(cfg2)
            cfg2=cfg2 or {}
            local mn=cfg2.Min or 0; local mx=cfg2.Max or 100
            local val=math.clamp(cfg2.Default or mn,mn,mx)
            local c=Card(58); Pad(c,8,8,12,12)
            local TR=Instance.new("Frame",c)
            TR.Size=UDim2.new(1,0,0,20); TR.BackgroundTransparency=1
            local tl=Lbl(TR,cfg2.Title or "Slider",UDim2.new(1,-42,1,0))
            tl.Font=T.FontFace; tl.TextSize=13
            local vl=Lbl(TR,tostring(val),UDim2.new(0,40,1,0),T.Accent,Enum.TextXAlignment.Right)
            vl.Position=UDim2.new(1,-40,0,0); vl.Font=T.FontBold
            local TBG=Instance.new("Frame",c)
            TBG.Size=UDim2.new(1,0,0,10); TBG.Position=UDim2.new(0,0,1,-18)
            TBG.BackgroundColor3=T.ToggleOff; TBG.BorderSizePixel=0; Cor(TBG,5)
            local p0=(val-mn)/(mx-mn)
            local TF=Instance.new("Frame",TBG)
            TF.Size=UDim2.new(p0,0,1,0); TF.BackgroundColor3=T.Accent; TF.BorderSizePixel=0; Cor(TF,5)
            local Kn=Instance.new("Frame",TBG)
            Kn.Size=UDim2.new(0,20,0,20); Kn.Position=UDim2.new(p0,-10,0.5,-10)
            Kn.BackgroundColor3=Color3.fromRGB(255,255,255); Kn.BorderSizePixel=0; Kn.ZIndex=3; Cor(Kn,10); Str(Kn,T.Accent,2)
            local SB=Instance.new("TextButton",TBG)
            SB.Size=UDim2.new(1,0,0,40); SB.Position=UDim2.new(0,0,0.5,-20)
            SB.BackgroundTransparency=1; SB.BorderSizePixel=0; SB.Text=""; SB.ZIndex=4
            local slid=false; local api={}
            local function upd(x)
                if not TBG or not TBG.AbsolutePosition then return end
                local r = math.clamp((x - TBG.AbsolutePosition.X) / TBG.AbsoluteSize.X, 0, 1)
                val = math.floor(mn + r * (mx - mn) + 0.5)
                local p = (val - mn) / (mx - mn)
                TF.Size = UDim2.new(p, 0, 1, 0)
                Kn.Position = UDim2.new(p, -10, 0.5, -10)
                vl.Text = tostring(val)
                pcall(cfg2.Callback or function()end, val)
            end
            function api:Set(v) val=math.clamp(v,mn,mx); local p=(val-mn)/(mx-mn); TF.Size=UDim2.new(p,0,1,0); Kn.Position=UDim2.new(p,-10,0.5,-10); vl.Text=tostring(val); pcall(cfg2.Callback or function()end,val) end
            function api:Get() return val end
            SB.InputBegan:Connect(function(i) if isDown(i) then slid=true; upd(i.Position.X) end end)
            UserInput.InputChanged:Connect(function(i) if slid and isMove(i) then upd(i.Position.X) end end)
            UserInput.InputEnded:Connect(function(i) if isDown(i) then slid=false end end)
            rfl(cfg2.Flag,api,c)
            if cfg2.Hint then addTooltip(c, cfg2.Hint) end
            return api
        end

        function Tab:CreateSliderNumber(cfg2)
            cfg2=cfg2 or {}
            local mn=cfg2.Min or 0; local mx=cfg2.Max or 100
            local val=math.clamp(cfg2.Default or mn,mn,mx)
            local c=Card(70); Pad(c,8,8,12,12)
            local TR=Instance.new("Frame",c)
            TR.Size=UDim2.new(1,0,0,20); TR.BackgroundTransparency=1
            local tl=Lbl(TR,cfg2.Title or "Slider",UDim2.new(1,-42,1,0))
            tl.Font=T.FontFace; tl.TextSize=13
            local numBox = Instance.new("TextBox", TR)
            numBox.Size = UDim2.new(0,50,0,20)
            numBox.Position = UDim2.new(1,-52,0,0)
            numBox.BackgroundColor3 = T.WindowBG
            numBox.BorderSizePixel = 0
            numBox.Text = tostring(val)
            numBox.TextColor3 = T.Accent
            numBox.TextSize = 11
            numBox.Font = T.FontBold
            numBox.TextXAlignment = Enum.TextXAlignment.Center
            Cor(numBox, 4)
            Str(numBox, T.ElementStr, 1)
            local TBG=Instance.new("Frame",c)
            TBG.Size=UDim2.new(1,0,0,10); TBG.Position=UDim2.new(0,0,1,-18)
            TBG.BackgroundColor3=T.ToggleOff; TBG.BorderSizePixel=0; Cor(TBG,5)
            local p0=(val-mn)/(mx-mn)
            local TF=Instance.new("Frame",TBG)
            TF.Size=UDim2.new(p0,0,1,0); TF.BackgroundColor3=T.Accent; TF.BorderSizePixel=0; Cor(TF,5)
            local Kn=Instance.new("Frame",TBG)
            Kn.Size=UDim2.new(0,20,0,20); Kn.Position=UDim2.new(p0,-10,0.5,-10)
            Kn.BackgroundColor3=Color3.fromRGB(255,255,255); Kn.BorderSizePixel=0; Kn.ZIndex=3; Cor(Kn,10); Str(Kn,T.Accent,2)
            local SB=Instance.new("TextButton",TBG)
            SB.Size=UDim2.new(1,0,0,40); SB.Position=UDim2.new(0,0,0.5,-20)
            SB.BackgroundTransparency=1; SB.BorderSizePixel=0; SB.Text=""; SB.ZIndex=4
            local slid=false; local api={}
            local function updateVal(newVal)
                val = math.clamp(newVal, mn, mx)
                local p = (val-mn)/(mx-mn)
                TF.Size = UDim2.new(p,0,1,0)
                Kn.Position = UDim2.new(p,-10,0.5,-10)
                numBox.Text = tostring(val)
                pcall(cfg2.Callback or function()end, val)
            end
            local function upd(x)
                if not TBG or not TBG.AbsolutePosition then return end
                local r = math.clamp((x - TBG.AbsolutePosition.X) / TBG.AbsoluteSize.X, 0, 1)
                updateVal(math.floor(mn + r*(mx-mn) + 0.5))
            end
            function api:Set(v) updateVal(v) end
            function api:Get() return val end
            SB.InputBegan:Connect(function(i) if isDown(i) then slid=true; upd(i.Position.X) end end)
            UserInput.InputChanged:Connect(function(i) if slid and isMove(i) then upd(i.Position.X) end end)
            UserInput.InputEnded:Connect(function(i) if isDown(i) then slid=false end end)
            numBox.FocusLost:Connect(function(enter)
                if enter then
                    local n = tonumber(numBox.Text)
                    if n then updateVal(n) else numBox.Text = tostring(val) end
                else
                    numBox.Text = tostring(val)
                end
            end)
            rfl(cfg2.Flag,api,c)
            if cfg2.Hint then addTooltip(c, cfg2.Hint) end
            return api
        end

        function Tab:CreateTextBox(cfg2)
            cfg2=cfg2 or {}
            local c=Card(70); Pad(c,8,8,12,12)
            local tl=Lbl(c,cfg2.Title or "TextBox",UDim2.new(1,0,0,20)); tl.Font=T.FontFace; tl.TextSize=13
            local IF=Instance.new("Frame",c)
            IF.Size=UDim2.new(1,0,0,32); IF.Position=UDim2.new(0,0,1,-36)
            IF.BackgroundColor3=T.WindowBG; IF.BorderSizePixel=0; Cor(IF,6)
            local is=Str(IF,T.ElementStr,1)
            local TB=Instance.new("TextBox",IF)
            TB.Size=UDim2.new(1,0,1,0); TB.BackgroundTransparency=1; TB.BorderSizePixel=0
            TB.Text=""; TB.PlaceholderText=cfg2.Placeholder or "Type here..."
            TB.PlaceholderColor3=T.TextMut; TB.TextColor3=T.TextPri
            TB.TextSize=12; TB.Font=T.FontFace; TB.TextXAlignment=Enum.TextXAlignment.Left; TB.ClearTextOnFocus=false
            Pad(TB,0,0,8,8)
            TB.Focused:Connect(function() is.Color=T.Accent end)
            TB.FocusLost:Connect(function(e) is.Color=T.ElementStr; if e then pcall(cfg2.Callback or function()end,TB.Text) end end)
            local api={}; function api:Set(v) TB.Text=tostring(v) end; function api:Get() return TB.Text end
            rfl(cfg2.Flag,api,c)
            if cfg2.Hint then addTooltip(c, cfg2.Hint) end
            return api
        end

        function Tab:CreateDropdown(cfg2)
            cfg2=cfg2 or {}
            local opts=cfg2.Options or {}
            local sel=cfg2.Default or (opts[1] or "")
            local open=false
            local c=Card(44); Pad(c,0,0,12,12)
            Lbl(c,cfg2.Title or "Dropdown",UDim2.new(1,-100,1,0)).TextSize=13
            local SF=Instance.new("Frame",c)
            SF.Size=UDim2.new(0,90,0,28); SF.Position=UDim2.new(1,-90,0.5,-14)
            SF.BackgroundColor3=T.WindowBG; SF.BorderSizePixel=0; Cor(SF,6); Str(SF,T.ElementStr,1)
            local SL=Lbl(SF,sel,UDim2.new(1,-18,1,0),T.TextPri); SL.Position=UDim2.new(0,6,0,0); SL.Font=T.FontFace; SL.TextSize=11
            local Arr=Lbl(SF,"▼",UDim2.new(0,14,1,0),T.TextMut,Enum.TextXAlignment.Center); Arr.Position=UDim2.new(1,-16,0,0); Arr.TextSize=12

            local DF=Instance.new("Frame",SG)
            DF.Size=UDim2.new(0,100,0,0)
            DF.BackgroundColor3=T.ElementBG
            DF.BorderSizePixel=0
            DF.ClipsDescendants=true
            DF.Visible=false
            DF.ZIndex=160
            Cor(DF,6); Str(DF,T.ElementStr,1)

            local DSF=Instance.new("ScrollingFrame",DF)
            DSF.Size=UDim2.new(1,0,1,0)
            DSF.BackgroundTransparency=1
            DSF.BorderSizePixel=0
            DSF.ScrollBarThickness=3
            DSF.ScrollBarImageColor3=T.Accent
            DSF.CanvasSize=UDim2.new(0,0,0,0)
            DSF.AutomaticCanvasSize=Enum.AutomaticSize.Y
            DSF.ClipsDescendants=true
            DSF.ZIndex=161
            Pad(DSF,4,4,4,4)

            local DL=Instance.new("UIListLayout",DSF)
            DL.SortOrder=Enum.SortOrder.LayoutOrder
            DL.Padding=UDim.new(0,2)

            local oH=32
            local MAX_H=200

            for i, opt in ipairs(opts) do
                local ob=Instance.new("TextButton",DSF)
                ob.Size=UDim2.new(1,0,0,oH-2)
                ob.BackgroundColor3=T.ElementBG
                ob.BorderSizePixel=0
                ob.Text=opt
                ob.TextSize=12
                ob.Font=T.FontFace
                ob.TextColor3=T.TextSec
                ob.TextXAlignment=Enum.TextXAlignment.Left
                ob.AutoButtonColor=false
                ob.ZIndex=162
                ob.LayoutOrder=i
                Cor(ob,4); Pad(ob,0,0,8,0)
                ob.MouseEnter:Connect(function() Tw(ob,{BackgroundColor3=T.TabHov},0.12) end)
                ob.MouseLeave:Connect(function() Tw(ob,{BackgroundColor3=T.ElementBG},0.12) end)
                OnClick(ob,function()
                    sel=opt
                    SL.Text=opt
                    pcall(cfg2.Callback or function()end,sel)
                    closeDD()
                end)
            end

            local contentH=#opts*oH+8
            local dispH=math.min(contentH,MAX_H)
            DSF.ScrollBarThickness = contentH>MAX_H and 3 or 0

            local function closeDD()
                if not open then return end; open=false
                Tw(DF,{Size=UDim2.new(0,DF.Size.X.Offset,0,0)},0.18)
                Arr.Text="▼"
                task.delay(0.2,function() DF.Visible=false end)
            end

            local function openDD()
                local ap=SF.AbsolutePosition; local as=SF.AbsoluteSize
                local w=math.max(as.X+10,100)
                local vp=workspace.CurrentCamera.ViewportSize
                local x=math.min(ap.X, vp.X-w-4)
                local spaceBelow=vp.Y-(ap.Y+as.Y+4)
                local spaceAbove=ap.Y-4
                local posY=(spaceBelow>=dispH or spaceBelow>=spaceAbove) and (ap.Y+as.Y+4) or (ap.Y-dispH-4)
                DF.Position=UDim2.new(0,x,0,posY)
                DF.Size=UDim2.new(0,w,0,0)
                DF.Visible=true; open=true
                Tw(DF,{Size=UDim2.new(0,w,0,dispH)},0.22)
                Arr.Text="▲"
            end

            local TB2=Instance.new("TextButton",c)
            TB2.Size=UDim2.new(1,0,1,0); TB2.BackgroundTransparency=1; TB2.BorderSizePixel=0; TB2.Text=""; TB2.AutoButtonColor=false
            OnClick(TB2,function() if open then closeDD() else openDD() end end)
            TB2.MouseEnter:Connect(function() Tw(c,{BackgroundColor3=T.ElementHov},0.15) end)
            TB2.MouseLeave:Connect(function() Tw(c,{BackgroundColor3=T.ElementBG},0.15) end)

            UserInput.InputBegan:Connect(function(i)
                if not open or not isDown(i) then return end
                task.defer(function()
                    if not open then return end
                    local pos=i.Position
                    local dp=DF.AbsolutePosition; local ds=DF.AbsoluteSize
                    local cp2=c.AbsolutePosition; local cs=c.AbsoluteSize
                    if not(pos.X>=dp.X and pos.X<=dp.X+ds.X and pos.Y>=dp.Y and pos.Y<=dp.Y+ds.Y) and
                       not(pos.X>=cp2.X and pos.X<=cp2.X+cs.X and pos.Y>=cp2.Y and pos.Y<=cp2.Y+cs.Y) then
                        closeDD()
                    end
                end)
            end)

            local api={}
            function api:Set(v) sel=v; SL.Text=v; pcall(cfg2.Callback or function()end,v) end
            function api:Get() return sel end
            rfl(cfg2.Flag,api,c)
            if cfg2.Hint then addTooltip(c, cfg2.Hint) end
            return api
        end

        function Tab:CreateMultiDropdown(cfg2)
            cfg2=cfg2 or {}
            local opts=cfg2.Options or {}
            local selected={}
            for _,def in ipairs(cfg2.Default or {}) do selected[def]=true end
            local open=false
            local c=Card(44); Pad(c,0,0,12,12)
            Lbl(c,cfg2.Title or "Multi-Dropdown",UDim2.new(1,-100,1,0)).TextSize=13
            local SF=Instance.new("Frame",c)
            SF.Size=UDim2.new(0,100,0,28); SF.Position=UDim2.new(1,-100,0.5,-14)
            SF.BackgroundColor3=T.WindowBG; SF.BorderSizePixel=0; Cor(SF,6); Str(SF,T.ElementStr,1)
            local SL=Lbl(SF,table.concat(cfg2.Default or {},", "),UDim2.new(1,-18,1,0),T.TextPri)
            SL.Position=UDim2.new(0,6,0,0); SL.Font=T.FontFace; SL.TextSize=10
            local Arr=Lbl(SF,"▼",UDim2.new(0,14,1,0),T.TextMut,Enum.TextXAlignment.Center); Arr.Position=UDim2.new(1,-16,0,0); Arr.TextSize=12

            local DF=Instance.new("Frame",SG)
            DF.Size=UDim2.new(0,150,0,0)
            DF.BackgroundColor3=T.ElementBG
            DF.BorderSizePixel=0
            DF.ClipsDescendants=true
            DF.Visible=false
            DF.ZIndex=160
            Cor(DF,6); Str(DF,T.ElementStr,1)

            local DSF=Instance.new("ScrollingFrame",DF)
            DSF.Size=UDim2.new(1,0,1,0)
            DSF.BackgroundTransparency=1
            DSF.BorderSizePixel=0
            DSF.ScrollBarThickness=3
            DSF.ScrollBarImageColor3=T.Accent
            DSF.CanvasSize=UDim2.new(0,0,0,0)
            DSF.AutomaticCanvasSize=Enum.AutomaticSize.Y
            DSF.ClipsDescendants=true
            DSF.ZIndex=161
            Pad(DSF,4,4,4,4)
            local DL=Instance.new("UIListLayout",DSF)
            DL.SortOrder=Enum.SortOrder.LayoutOrder; DL.Padding=UDim.new(0,2)

            local oH=32
            local MAX_H=200

            local function updateSelectedText()
                local selList={}
                for k,v in pairs(selected) do if v then table.insert(selList,k) end end
                SL.Text = table.concat(selList,", ")
                pcall(cfg2.Callback or function()end, selList)
            end

            for i,opt in ipairs(opts) do
                local row=Instance.new("Frame",DSF)
                row.Size=UDim2.new(1,0,0,oH-2)
                row.BackgroundColor3=T.ElementBG
                row.BorderSizePixel=0
                row.LayoutOrder=i
                Cor(row,4); Pad(row,0,0,8,0)
                local chk=Instance.new("TextButton",row)
                chk.Size=UDim2.new(0,20,0,20)
                chk.Position=UDim2.new(0,6,0.5,-10)
                chk.BackgroundColor3=selected[opt] and T.Accent or T.ToggleOff
                chk.BorderSizePixel=0
                chk.Text=selected[opt] and "✓" or ""
                chk.TextColor3=Color3.fromRGB(255,255,255)
                chk.Font=T.FontBold
                chk.TextSize=12
                Cor(chk,4)
                local lbl=Lbl(row,opt,UDim2.new(1,-34,1,0),T.TextSec)
                lbl.Position=UDim2.new(0,34,0,0); lbl.Font=T.FontFace; lbl.TextSize=11
                OnClick(chk,function()
                    selected[opt]=not selected[opt]
                    chk.BackgroundColor3=selected[opt] and T.Accent or T.ToggleOff
                    chk.Text=selected[opt] and "✓" or ""
                    updateSelectedText()
                end)
                row.MouseEnter:Connect(function() Tw(row,{BackgroundColor3=T.TabHov},0.12) end)
                row.MouseLeave:Connect(function() Tw(row,{BackgroundColor3=T.ElementBG},0.12) end)
            end

            local contentH=#opts*oH+8
            local dispH=math.min(contentH,MAX_H)
            DSF.ScrollBarThickness = contentH>MAX_H and 3 or 0

            local function closeDD()
                if not open then return end; open=false
                Tw(DF,{Size=UDim2.new(0,DF.Size.X.Offset,0,0)},0.18)
                Arr.Text="▼"
                task.delay(0.2,function() DF.Visible=false end)
            end
            local function openDD()
                local ap=SF.AbsolutePosition; local as=SF.AbsoluteSize
                local w=math.max(as.X+10,150)
                local vp=workspace.CurrentCamera.ViewportSize
                local x=math.min(ap.X, vp.X-w-4)
                local spaceBelow=vp.Y-(ap.Y+as.Y+4)
                local spaceAbove=ap.Y-4
                local posY=(spaceBelow>=dispH or spaceBelow>=spaceAbove) and (ap.Y+as.Y+4) or (ap.Y-dispH-4)
                DF.Position=UDim2.new(0,x,0,posY)
                DF.Size=UDim2.new(0,w,0,0)
                DF.Visible=true; open=true
                Tw(DF,{Size=UDim2.new(0,w,0,dispH)},0.22)
                Arr.Text="▲"
            end
            local TB2=Instance.new("TextButton",c)
            TB2.Size=UDim2.new(1,0,1,0); TB2.BackgroundTransparency=1; TB2.BorderSizePixel=0; TB2.Text=""; TB2.AutoButtonColor=false
            OnClick(TB2,function() if open then closeDD() else openDD() end end)
            TB2.MouseEnter:Connect(function() Tw(c,{BackgroundColor3=T.ElementHov},0.15) end)
            TB2.MouseLeave:Connect(function() Tw(c,{BackgroundColor3=T.ElementBG},0.15) end)
            UserInput.InputBegan:Connect(function(i)
                if not open or not isDown(i) then return end
                task.defer(function()
                    if not open then return end
                    local pos=i.Position
                    local dp=DF.AbsolutePosition; local ds=DF.AbsoluteSize
                    local cp2=c.AbsolutePosition; local cs=c.AbsoluteSize
                    if not(pos.X>=dp.X and pos.X<=dp.X+ds.X and pos.Y>=dp.Y and pos.Y<=dp.Y+ds.Y) and
                       not(pos.X>=cp2.X and pos.X<=cp2.X+cs.X and pos.Y>=cp2.Y and pos.Y<=cp2.Y+cs.Y) then
                        closeDD()
                    end
                end)
            end)
            local api={}
            function api:Set(tbl) for k,_ in pairs(selected) do selected[k]=false end; for _,v in ipairs(tbl) do selected[v]=true end; updateSelectedText() end
            function api:Get() local r={}; for k,v in pairs(selected) do if v then table.insert(r,k) end end; return r end
            rfl(cfg2.Flag,api,c)
            if cfg2.Hint then addTooltip(c, cfg2.Hint) end
            return api
        end

        function Tab:CreateInputNumber(cfg2)
            cfg2=cfg2 or {}
            local mn=cfg2.Min or 0; local mx=cfg2.Max or 100; local step=cfg2.Step or 1
            local val=math.clamp(cfg2.Default or mn,mn,mx)
            local c=Card(44); Pad(c,0,0,12,12)
            Lbl(c,cfg2.Title or "Number",UDim2.new(1,-128,1,0)).TextSize=13
            local Row=Instance.new("Frame",c)
            Row.Size=UDim2.new(0,116,0,30); Row.Position=UDim2.new(1,-120,0.5,-15)
            Row.BackgroundTransparency=1
            local Mins=Instance.new("TextButton",Row)
            Mins.Size=UDim2.new(0,30,1,0); Mins.BackgroundColor3=T.ElementHov; Mins.BorderSizePixel=0
            Mins.Text="−"; Mins.TextSize=16; Mins.Font=T.FontBold; Mins.TextColor3=T.TextPri; Mins.AutoButtonColor=false; Cor(Mins,6)
            local VF=Instance.new("Frame",Row)
            VF.Size=UDim2.new(0,50,1,0); VF.Position=UDim2.new(0,34,0,0)
            VF.BackgroundColor3=T.WindowBG; VF.BorderSizePixel=0; Cor(VF,6); Str(VF,T.ElementStr,1)
            local VL=Lbl(VF,tostring(val),UDim2.new(1,0,1,0),T.TextPri,Enum.TextXAlignment.Center)
            VL.Font=T.FontBold; VL.TextSize=13
            local Plus=Instance.new("TextButton",Row)
            Plus.Size=UDim2.new(0,30,1,0); Plus.Position=UDim2.new(0,88,0,0)
            Plus.BackgroundColor3=T.ElementHov; Plus.BorderSizePixel=0
            Plus.Text="+"; Plus.TextSize=16; Plus.Font=T.FontBold; Plus.TextColor3=T.TextPri; Plus.AutoButtonColor=false; Cor(Plus,6)
            Mins.MouseEnter:Connect(function() Tw(Mins,{BackgroundColor3=T.TabHov},0.12) end)
            Mins.MouseLeave:Connect(function() Tw(Mins,{BackgroundColor3=T.ElementHov},0.12) end)
            Plus.MouseEnter:Connect(function() Tw(Plus,{BackgroundColor3=T.TabHov},0.12) end)
            Plus.MouseLeave:Connect(function() Tw(Plus,{BackgroundColor3=T.ElementHov},0.12) end)
            local api={}
            local function updN() VL.Text=tostring(val); pcall(cfg2.Callback or function()end,val) end
            function api:Set(v) val=math.clamp(v,mn,mx); updN() end
            function api:Get() return val end
            OnClick(Mins,function() val=math.clamp(val-step,mn,mx); updN(); Tw(Mins,{BackgroundColor3=T.AccentDark},0.1); task.delay(0.15,function() Tw(Mins,{BackgroundColor3=T.ElementHov},0.15) end) end)
            OnClick(Plus,function() val=math.clamp(val+step,mn,mx); updN(); Tw(Plus,{BackgroundColor3=T.AccentDark},0.1); task.delay(0.15,function() Tw(Plus,{BackgroundColor3=T.ElementHov},0.15) end) end)
            rfl(cfg2.Flag,api,c)
            if cfg2.Hint then addTooltip(c, cfg2.Hint) end
            return api
        end

        function Tab:CreateProgressBar(cfg2)
            cfg2=cfg2 or {}
            local val=math.clamp(cfg2.Default or 0,0,100)
            local c=Card(54); Pad(c,8,8,12,12)
            local TR=Instance.new("Frame",c); TR.Size=UDim2.new(1,0,0,20); TR.BackgroundTransparency=1
            local tl=Lbl(TR,cfg2.Title or "Progress",UDim2.new(1,-42,1,0)); tl.Font=T.FontFace; tl.TextSize=13
            local pl=Lbl(TR,val.."%",UDim2.new(0,40,1,0),T.Accent,Enum.TextXAlignment.Right)
            pl.Position=UDim2.new(1,-40,0,0); pl.Font=T.FontBold
            local Trk=Instance.new("Frame",c); Trk.Size=UDim2.new(1,0,0,12); Trk.Position=UDim2.new(0,0,1,-18); Trk.BackgroundColor3=T.ToggleOff; Trk.BorderSizePixel=0; Cor(Trk,6)
            local Fil=Instance.new("Frame",Trk); Fil.Size=UDim2.new(val/100,0,1,0); Fil.BackgroundColor3=T.Accent; Fil.BorderSizePixel=0; Cor(Fil,6)
            local Sh=Instance.new("Frame",Fil); Sh.Size=UDim2.new(1,0,0.5,0); Sh.BackgroundColor3=Color3.fromRGB(255,255,255); Sh.BackgroundTransparency=0.85; Sh.BorderSizePixel=0; Cor(Sh,6)
            local api={}
            function api:Set(v)
                val=math.clamp(v,0,100); local p=val/100
                Tw(Fil,{Size=UDim2.new(p,0,1,0)},0.3)
                pl.Text=val.."%"
                Tw(Fil,{BackgroundColor3=val>=100 and Color3.fromRGB(34,197,94) or T.Accent},0.3)
                pcall(cfg2.Callback or function()end,val)
            end
            function api:Get() return val end
            rfl(cfg2.Flag,api,c)
            if cfg2.Hint then addTooltip(c, cfg2.Hint) end
            return api
        end

        function Tab:CreateColorPicker(cfg2)
            cfg2=cfg2 or {}
            local col=cfg2.Default or Color3.fromRGB(255,0,0)
            local cH,cS,cV=toHSV(col); local tH,tS,tV=cH,cS,cV; local open=false
            local c=Card(44); Pad(c,0,0,12,12)
            Lbl(c,cfg2.Title or "Color",UDim2.new(1,-58,1,0)).TextSize=13
            local Sw=Instance.new("Frame",c); Sw.Size=UDim2.new(0,34,0,24); Sw.Position=UDim2.new(1,-38,0.5,-12); Sw.BackgroundColor3=col; Sw.BorderSizePixel=0; Cor(Sw,5); Str(Sw,T.ElementStr,1)
            local PW,PH=210,270
            local Pop=Instance.new("Frame",SG); Pop.Size=UDim2.new(0,PW,0,0); Pop.BackgroundColor3=T.ElementBG; Pop.BorderSizePixel=0; Pop.ClipsDescendants=true; Pop.Visible=false; Pop.ZIndex=160; Cor(Pop,8); Str(Pop,T.ElementStr,1)
            local SV=Instance.new("Frame",Pop); SV.Size=UDim2.new(1,-16,0,110); SV.Position=UDim2.new(0,8,0,8); SV.BackgroundColor3=HSV(tH,1,1); SV.BorderSizePixel=0; SV.ZIndex=161; Cor(SV,6)
            local WL=Instance.new("Frame",SV); WL.Size=UDim2.new(1,0,1,0); WL.BackgroundColor3=Color3.fromRGB(255,255,255); WL.BorderSizePixel=0; WL.ZIndex=162; Cor(WL,6)
            local wg=Instance.new("UIGradient",WL); wg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
            local BL=Instance.new("Frame",SV); BL.Size=UDim2.new(1,0,1,0); BL.BackgroundColor3=Color3.fromRGB(0,0,0); BL.BorderSizePixel=0; BL.ZIndex=163; Cor(BL,6)
            local bg=Instance.new("UIGradient",BL); bg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}); bg.Rotation=90
            local SVC=Instance.new("Frame",SV); SVC.Size=UDim2.new(0,12,0,12); SVC.Position=UDim2.new(tS,-6,1-tV,-6); SVC.BackgroundColor3=Color3.fromRGB(255,255,255); SVC.BorderSizePixel=0; SVC.ZIndex=165; Cor(SVC,6); Str(SVC,Color3.fromRGB(0,0,0),1)
            local HB=Instance.new("Frame",Pop); HB.Size=UDim2.new(1,-16,0,16); HB.Position=UDim2.new(0,8,0,124); HB.BackgroundColor3=Color3.fromRGB(255,255,255); HB.BorderSizePixel=0; HB.ZIndex=161; Cor(HB,4)
            local HI=Instance.new("ImageLabel",HB); HI.Size=UDim2.new(1,0,1,0); HI.BackgroundTransparency=1; HI.Image="rbxassetid://698052001"; HI.ZIndex=162
            local HC=Instance.new("Frame",HB); HC.Size=UDim2.new(0,6,1,4); HC.Position=UDim2.new(tH,-3,0,-2); HC.BackgroundColor3=Color3.fromRGB(255,255,255); HC.BorderSizePixel=0; HC.ZIndex=163; Cor(HC,3); Str(HC,Color3.fromRGB(0,0,0),1)
            local HxF=Instance.new("Frame",Pop); HxF.Size=UDim2.new(1,-16,0,26); HxF.Position=UDim2.new(0,8,0,148); HxF.BackgroundColor3=T.WindowBG; HxF.BorderSizePixel=0; HxF.ZIndex=161; Cor(HxF,5); Str(HxF,T.ElementStr,1)
            Lbl(HxF,"#",UDim2.new(0,16,1,0),T.TextMut,Enum.TextXAlignment.Center).ZIndex=162
            local HL=Lbl(HxF,toHex(col),UDim2.new(1,-18,1,0),T.TextPri); HL.Position=UDim2.new(0,18,0,0); HL.TextSize=11; HL.Font=T.FontBold; HL.ZIndex=162
            local BP=Instance.new("Frame",Pop); BP.Size=UDim2.new(1,-16,0,14); BP.Position=UDim2.new(0,8,0,180); BP.BackgroundColor3=col; BP.BorderSizePixel=0; BP.ZIndex=161; Cor(BP,4)
            local BR=Instance.new("Frame",Pop); BR.Size=UDim2.new(1,-16,0,28); BR.Position=UDim2.new(0,8,0,200); BR.BackgroundTransparency=1
            local OK=Instance.new("TextButton",BR); OK.Size=UDim2.new(0.5,-3,1,0); OK.BackgroundColor3=T.Accent; OK.BorderSizePixel=0; OK.Text="OK"; OK.TextSize=12; OK.Font=T.FontBold; OK.TextColor3=Color3.fromRGB(255,255,255); OK.AutoButtonColor=false; Cor(OK,6)
            local CL=Instance.new("TextButton",BR); CL.Size=UDim2.new(0.5,-3,1,0); CL.Position=UDim2.new(0.5,3,0,0); CL.BackgroundColor3=T.ElementHov; CL.BorderSizePixel=0; CL.Text="Batal"; CL.TextSize=12; CL.Font=T.FontBold; CL.TextColor3=T.TextSec; CL.AutoButtonColor=false; Cor(CL,6)
            local EyeBtn = Instance.new("TextButton", Pop)
            EyeBtn.Size = UDim2.new(0, 28, 0, 28)
            EyeBtn.Position = UDim2.new(1, -36, 0, 180)
            EyeBtn.BackgroundColor3 = T.ElementHov
            EyeBtn.BorderSizePixel = 0
            EyeBtn.Text = "🔍"
            EyeBtn.TextSize = 14
            EyeBtn.Font = T.FontFace
            EyeBtn.TextColor3 = T.TextPri
            Cor(EyeBtn, 6)
            local eyeActive = false
            local eyeConn
            EyeBtn.MouseButton1Click:Connect(function()
                if eyeActive then
                    eyeActive = false
                    if eyeConn then eyeConn:Disconnect() end
                    return
                end
                eyeActive = true
                Notify(SG, "Click on any part to pick color", 3)
                eyeConn = Mouse.Button1Down:Connect(function()
                    local target = Mouse.Target
                    if target then
                        local color = Color3.new(1,1,1)
                        if target:IsA("BasePart") then color = target.Color
                        elseif target:IsA("GuiObject") then color = target.BackgroundColor3
                        else color = Color3.fromRGB(255,255,255) end
                        tH,tS,tV = toHSV(color)
                        updPrev()
                        eyeActive = false
                        eyeConn:Disconnect()
                        Notify(SG, "Color picked!", 1)
                    end
                end)
            end)

            local api={}
            local function updPrev() local tc=HSV(tH,tS,tV); SV.BackgroundColor3=HSV(tH,1,1); SVC.Position=UDim2.new(tS,-6,1-tV,-6); HC.Position=UDim2.new(tH,-3,0,-2); HL.Text=toHex(tc); BP.BackgroundColor3=tc end
            local function updPos() local vp=workspace.CurrentCamera.ViewportSize; local ap=Sw.AbsolutePosition; local x=math.max(4,math.min(ap.X-PW+34,vp.X-PW-4)); local y=ap.Y+28; if y+PH>vp.Y-4 then y=ap.Y-PH-4 end; Pop.Position=UDim2.new(0,x,0,y) end
            local function closePop() open=false; Tw(Pop,{Size=UDim2.new(0,PW,0,0)},0.18); task.delay(0.2,function() Pop.Visible=false end) end
            OnClick(OK,function() col=HSV(tH,tS,tV); cH,cS,cV=tH,tS,tV; Sw.BackgroundColor3=col; pcall(cfg2.Callback or function()end,col); closePop() end)
            OnClick(CL,function() tH,tS,tV=cH,cS,cV; updPrev(); closePop() end)
            local svd=false
            local SVB=Instance.new("TextButton",SV); SVB.Size=UDim2.new(1,0,1,0); SVB.BackgroundTransparency=1; SVB.Text=""; SVB.ZIndex=166
            SVB.InputBegan:Connect(function(i) if isDown(i) then svd=true; tS=math.clamp((i.Position.X-SV.AbsolutePosition.X)/SV.AbsoluteSize.X,0,1); tV=1-math.clamp((i.Position.Y-SV.AbsolutePosition.Y)/SV.AbsoluteSize.Y,0,1); updPrev() end end)
            UserInput.InputChanged:Connect(function(i) if svd and isMove(i) then tS=math.clamp((i.Position.X-SV.AbsolutePosition.X)/SV.AbsoluteSize.X,0,1); tV=1-math.clamp((i.Position.Y-SV.AbsolutePosition.Y)/SV.AbsoluteSize.Y,0,1); updPrev() end end)
            UserInput.InputEnded:Connect(function(i) if isDown(i) then svd=false end end)
            local hud=false
            local HBtn=Instance.new("TextButton",HB); HBtn.Size=UDim2.new(1,0,1,0); HBtn.BackgroundTransparency=1; HBtn.Text=""; HBtn.ZIndex=163
            HBtn.InputBegan:Connect(function(i) if isDown(i) then hud=true; tH=math.clamp((i.Position.X-HB.AbsolutePosition.X)/HB.AbsoluteSize.X,0,1); updPrev() end end)
            UserInput.InputChanged:Connect(function(i) if hud and isMove(i) then tH=math.clamp((i.Position.X-HB.AbsolutePosition.X)/HB.AbsoluteSize.X,0,1); updPrev() end end)
            UserInput.InputEnded:Connect(function(i) if isDown(i) then hud=false end end)
            local TB3=Instance.new("TextButton",c); TB3.Size=UDim2.new(1,0,1,0); TB3.BackgroundTransparency=1; TB3.Text=""; TB3.AutoButtonColor=false
            OnClick(TB3,function() if open then tH,tS,tV=cH,cS,cV; updPrev(); closePop() else tH,tS,tV=cH,cS,cV; updPrev(); updPos(); Pop.Visible=true; open=true; Tw(Pop,{Size=UDim2.new(0,PW,0,PH)},0.22) end end)
            TB3.MouseEnter:Connect(function() Tw(c,{BackgroundColor3=T.ElementHov},0.15) end)
            TB3.MouseLeave:Connect(function() Tw(c,{BackgroundColor3=T.ElementBG},0.15) end)
            function api:Set(nc) col=nc; cH,cS,cV=toHSV(nc); Sw.BackgroundColor3=nc; pcall(cfg2.Callback or function()end,nc) end
            function api:Get() return col end
            rfl(cfg2.Flag,api,c)
            if cfg2.Hint then addTooltip(c, cfg2.Hint) end
            return api
        end

        function Tab:CreateKeybind(cfg2)
            cfg2=cfg2 or {}; local key=cfg2.Default or Enum.KeyCode.Unknown; local lstn=false
            local c=Card(44); Pad(c,0,0,12,12)
            Lbl(c,cfg2.Title or "Keybind",UDim2.new(1,-90,1,0)).TextSize=13
            local Bdg=Instance.new("TextButton",c)
            Bdg.Size=UDim2.new(0,82,0,30); Bdg.Position=UDim2.new(1,-86,0.5,-15)
            Bdg.BackgroundColor3=T.WindowBG; Bdg.BorderSizePixel=0; Bdg.TextSize=11; Bdg.Font=T.FontBold; Bdg.TextColor3=T.Accent; Bdg.AutoButtonColor=false; Bdg.ZIndex=5; Cor(Bdg,5); Str(Bdg,T.ElementStr,1)
            local function kN(k) local n=tostring(k):gsub("Enum.KeyCode.",""); return n=="Unknown" and "None" or n end
            Bdg.Text="["..kN(key).."]"
            local function stopL() lstn=false; Bdg.TextColor3=T.Accent; Bdg.Text="["..kN(key).."]"; Tw(Bdg,{BackgroundColor3=T.WindowBG},0.15) end
            OnClick(Bdg,function() if lstn then stopL(); return end; lstn=true; Bdg.Text="[ ... ]"; Bdg.TextColor3=T.AccentHov; Tw(Bdg,{BackgroundColor3=T.TabHov},0.15) end)
            UserInput.InputBegan:Connect(function(i,gp)
                if not lstn then if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode==key then pcall(cfg2.Callback or function()end,key) end; return end
                if gp then return end
                if i.UserInputType==Enum.UserInputType.Keyboard then if i.KeyCode==Enum.KeyCode.Escape then stopL(); return end; key=i.KeyCode; stopL(); pcall(cfg2.Callback or function()end,key) end
            end)
            Bdg.MouseEnter:Connect(function() Tw(c,{BackgroundColor3=T.ElementHov},0.15) end)
            Bdg.MouseLeave:Connect(function() Tw(c,{BackgroundColor3=T.ElementBG},0.15) end)
            local api={}; function api:Set(k) key=k; if not lstn then Bdg.Text="["..kN(k).."]" end end; function api:Get() return key end
            rfl(cfg2.Flag,api,c)
            if cfg2.Hint then addTooltip(c, cfg2.Hint) end
            return api
        end

        return Tab
    end

    -- Loading screen
    ShowLoading(SG, T.Accent, title, function()
        Win.Visible = true
        Win.BackgroundTransparency = 1
        Wrapper.Position = UDim2.new(0.5,-280-32,0.5,-130)
        Tw(Wrapper, {Position=UDim2.new(0.5,-280-32,0.5,-170)}, 0.55, Enum.EasingStyle.Back)
        task.delay(0.05, function()
            Tw(Win, {BackgroundTransparency=0}, 0.45)
        end)
        syncToggleBtnY(340)
        task.delay(0.6, function()
            lastWrapperPos = Wrapper.Position
        end)
    end)

    return W
end

return KreinGui
