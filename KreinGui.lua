--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ██╗  ██╗██████╗ ███████╗██╗███╗   ██╗ ██████╗ ██╗        ║
║   ██║ ██╔╝██╔══██╗██╔════╝██║████╗  ██║██╔════╝ ██║        ║
║   █████╔╝ ██████╔╝█████╗  ██║██╔██╗ ██║██║  ███╗██║        ║
║   ██╔═██╗ ██╔══██╗██╔══╝  ██║██║╚██╗██║██║   ██║██║        ║
║   ██║  ██╗██║  ██║███████╗██║██║ ╚████║╚██████╔╝██║        ║
║   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝        ║
║                                                              ║
║              GUI Library  —  by @uniquadev                   ║
║                      Version 3.0.0                           ║
╚══════════════════════════════════════════════════════════════╝

  CHANGELOG v3.0.0:
  ✓ ABar: tebal 4px + glow + animasi "ular" berjalan ke kanan
  ✓ Tambah Section Header (judul pemisah grup elemen)
  ✓ Tambah Input Number (angka dengan tombol + dan -)
  ✓ Tambah Progress Bar (bisa di-update dari luar)
  ✓ Key System: opsional, fetch URL + validasi harian
      - CreateWindow({ KeySystem=true, KeyUrl="...", KeyLink="..." })
      - Key disimpan lokal, expired setelah 24 jam

  QUICK START:

    local KreinGui = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/LippTz/KreinGuiLibrary/refs/heads/main/KreinGui.lua"
    ))()

    KreinGui:SetTheme({ Accent = Color3.fromRGB(99,102,241) })
    -- KreinGui:UsePreset("Rose"/"Emerald"/"Amber"/"Midnight")

    local Win = KreinGui:CreateWindow({
        Title      = "My Hub",
        SubTitle   = "v3.0",
        ConfigName = "MyHubConfig",

        -- Key System (hapus 3 baris ini kalau tidak pakai)
        KeySystem  = true,
        KeyUrl     = "https://pastebin.com/raw/XXXXXXXX",  -- isi key valid (1 per baris)
        KeyLink    = "https://linkvertise.com/XXXXX",       -- link untuk dapat key
    })

    local Tab1 = Win:CreateTab("Main")
    Tab1:CreateSectionHeader("Pengaturan Umum")
    Tab1:CreateButton({ Title="Kill All",   Callback=function() end })
    Tab1:CreateToggle({ Title="God Mode",   Flag="GodMode",  Default=false, Callback=function(v) end })
    Tab1:CreateSlider({ Title="WalkSpeed",  Flag="WS", Min=16, Max=100, Default=16, Callback=function(v) end })
    Tab1:CreateInputNumber({ Title="JumpPower", Flag="JP", Min=0, Max=200, Default=50, Step=5, Callback=function(v) end })
    Tab1:AddSeparator()
    Tab1:CreateSectionHeader("Target")
    Tab1:CreateTextBox({ Title="Nama", Flag="Target", Placeholder="Target...", Callback=function(v) end })
    Tab1:CreateDropdown({ Title="Tim", Flag="Team", Options={"Merah","Biru","Hijau"}, Default="Merah", Callback=function(v) end })

    local Tab2 = Win:CreateTab("Visual")
    Tab2:CreateSectionHeader("ESP")
    Tab2:CreateColorPicker({ Title="ESP Color", Flag="ESPColor", Default=Color3.fromRGB(255,0,0), Callback=function(c) end })
    Tab2:CreateToggle({ Title="Show ESP", Flag="ShowESP", Default=true, Callback=function(v) end })
    Tab2:AddSeparator()
    Tab2:CreateSectionHeader("Progress")
    local bar = Tab2:CreateProgressBar({ Title="Loading", Flag="LoadBar", Default=0 })
    bar:Set(75)  -- set ke 75%

    Tab2:CreateKeybind({ Title="Toggle GUI", Flag="GUIKey", Default=Enum.KeyCode.RightShift, Callback=function(k) end })

    Win:SaveConfig()
    Win:Notify("KreinGui v3.0 loaded!", 3)

--]]

-- ================================================================
-- SERVICES
-- ================================================================
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")
local HttpService  = game:GetService("HttpService")
local RunService   = game:GetService("RunService")
local LocalPlayer  = Players.LocalPlayer

-- ================================================================
-- INPUT HELPERS
-- ================================================================
local function isDown(inp)
    return inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch
end
local function isMove(inp)
    return inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch
end

-- OnClick dengan DRAG_THRESHOLD agar tidak konflik dengan scroll
local function OnClick(btn, fn)
    local down, startPos = false, nil
    local THRESHOLD = 10
    btn.InputBegan:Connect(function(inp)
        if isDown(inp) then down = true; startPos = inp.Position end
    end)
    btn.InputEnded:Connect(function(inp)
        if isDown(inp) and down then
            down = false
            if startPos and (inp.Position - startPos).Magnitude <= THRESHOLD then fn() end
        end
    end)
    btn.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and startPos then
            if (inp.Position - startPos).Magnitude > THRESHOLD then down = false end
        end
    end)
end

-- ================================================================
-- THEME
-- ================================================================
local Theme = {
    WindowBG       = Color3.fromRGB(28, 28, 32),
    HeaderBG       = Color3.fromRGB(22, 22, 26),
    TabPanelBG     = Color3.fromRGB(22, 22, 26),
    ElementBG      = Color3.fromRGB(40, 40, 48),
    ElementBGHover = Color3.fromRGB(50, 50, 60),
    ElementStroke  = Color3.fromRGB(60, 60, 72),
    TabDefault     = Color3.fromRGB(30, 30, 36),
    TabHover       = Color3.fromRGB(42, 42, 50),
    TabActive      = Color3.fromRGB(99, 102, 241),
    TabActiveText  = Color3.fromRGB(255, 255, 255),
    TabDefaultText = Color3.fromRGB(160, 160, 175),
    Accent         = Color3.fromRGB(99, 102, 241),
    AccentHover    = Color3.fromRGB(129, 132, 255),
    AccentDark     = Color3.fromRGB(60, 62, 160),
    ToggleOff      = Color3.fromRGB(55, 55, 68),
    ToggleOn       = Color3.fromRGB(99, 102, 241),
    TextPrimary    = Color3.fromRGB(240, 240, 248),
    TextSecondary  = Color3.fromRGB(140, 140, 160),
    TextMuted      = Color3.fromRGB(90, 90, 110),
    CloseRed       = Color3.fromRGB(255, 75, 75),
    MinimizeGray   = Color3.fromRGB(160, 160, 175),
    Separator      = Color3.fromRGB(45, 45, 55),
    WindowStroke   = Color3.fromRGB(70, 70, 90),
    SectionText    = Color3.fromRGB(120, 120, 145),
}

local Presets = {
    Default  = { Accent=Color3.fromRGB(99,102,241),  ToggleOn=Color3.fromRGB(99,102,241),  TabActive=Color3.fromRGB(99,102,241),  WindowBG=Color3.fromRGB(28,28,32),  HeaderBG=Color3.fromRGB(22,22,26) },
    Rose     = { Accent=Color3.fromRGB(244,63,94),   ToggleOn=Color3.fromRGB(244,63,94),   TabActive=Color3.fromRGB(244,63,94),   WindowBG=Color3.fromRGB(30,20,24),  HeaderBG=Color3.fromRGB(22,14,18) },
    Emerald  = { Accent=Color3.fromRGB(16,185,129),  ToggleOn=Color3.fromRGB(16,185,129),  TabActive=Color3.fromRGB(16,185,129),  WindowBG=Color3.fromRGB(18,28,24),  HeaderBG=Color3.fromRGB(12,20,18) },
    Amber    = { Accent=Color3.fromRGB(245,158,11),  ToggleOn=Color3.fromRGB(245,158,11),  TabActive=Color3.fromRGB(245,158,11),  WindowBG=Color3.fromRGB(28,24,16),  HeaderBG=Color3.fromRGB(22,18,10) },
    Midnight = { Accent=Color3.fromRGB(139,92,246),  ToggleOn=Color3.fromRGB(139,92,246),  TabActive=Color3.fromRGB(139,92,246),  WindowBG=Color3.fromRGB(15,15,25),  HeaderBG=Color3.fromRGB(10,10,18) },
}

-- ================================================================
-- HELPERS
-- ================================================================
local function Tween(o, p, d, s, dir)
    TweenService:Create(o, TweenInfo.new(d or 0.2, s or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), p):Play()
end
local function Corner(p, r)
    local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 8); return c
end
local function Stroke(p, col, t)
    local s = Instance.new("UIStroke", p); s.Color = col or Theme.WindowStroke; s.Thickness = t or 1; return s
end
local function Pad(p, t, b, l, r)
    local u = Instance.new("UIPadding", p)
    u.PaddingTop = UDim.new(0,t or 0); u.PaddingBottom = UDim.new(0,b or 0)
    u.PaddingLeft = UDim.new(0,l or 0); u.PaddingRight = UDim.new(0,r or 0)
end
local function Lbl(par, txt, sz, col, xa)
    local l = Instance.new("TextLabel", par)
    l.BackgroundTransparency = 1; l.BorderSizePixel = 0
    l.Size = sz or UDim2.new(1,0,1,0); l.Text = txt or ""
    l.TextSize = 13; l.TextColor3 = col or Theme.TextPrimary
    l.Font = Enum.Font.GothamMedium
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextWrapped = true
    return l
end

-- ================================================================
-- DRAG
-- ================================================================
local function EnableDrag(frame, handle)
    handle = handle or frame
    local dragging, startPos, startFrame, moved = false, nil, nil, false
    handle.InputBegan:Connect(function(inp)
        if isDown(inp) then dragging=true; moved=false; startPos=inp.Position; startFrame=frame.Position end
    end)
    handle.InputEnded:Connect(function(inp)
        if isDown(inp) then dragging=false end
    end)
    UserInput.InputChanged:Connect(function(inp)
        if not dragging or not startPos then return end
        if isMove(inp) then
            local d = inp.Position - startPos
            if d.Magnitude > 6 then moved = true end
            if moved then
                frame.Position = UDim2.new(startFrame.X.Scale, startFrame.X.Offset+d.X,
                                           startFrame.Y.Scale, startFrame.Y.Offset+d.Y)
            end
        end
    end)
    UserInput.InputEnded:Connect(function(inp)
        if isDown(inp) then dragging=false end
    end)
end

-- ================================================================
-- HSV
-- ================================================================
local function HSV(h,s,v) return Color3.fromHSV(h,s,v) end
local function toHSV(c)   return Color3.toHSV(c) end
local function toHex(c)
    return string.format("%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
end

-- ================================================================
-- ANIMASI ABAR (Ular berjalan ke kanan)
-- ================================================================
local function StartABarAnim(abar, accent)
    -- Glow frame di bawah ABar
    local Glow = Instance.new("Frame", abar.Parent)
    Glow.Name = "ABarGlow"
    Glow.Size = UDim2.new(1, 0, 0, 8)
    Glow.Position = UDim2.new(0, 0, 0, 48)
    Glow.BackgroundColor3 = accent
    Glow.BackgroundTransparency = 0.7
    Glow.BorderSizePixel = 0
    Glow.ZIndex = 2

    local glowCorner = Instance.new("UICorner", Glow)
    glowCorner.CornerRadius = UDim.new(1, 0)

    -- Snake: gradient yang bergerak ke kanan
    local Snake = Instance.new("Frame", abar)
    Snake.Size = UDim2.new(0.35, 0, 1, 0)  -- panjang ular = 35% lebar
    Snake.Position = UDim2.new(-0.35, 0, 0, 0)
    Snake.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Snake.BackgroundTransparency = 1
    Snake.BorderSizePixel = 0
    Snake.ZIndex = 6

    local snakeGrad = Instance.new("UIGradient", Snake)
    snakeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,255,255)),
    })
    snakeGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   1),    -- ujung kiri: transparan
        NumberSequenceKeypoint.new(0.4, 0.1),  -- tengah kiri: mulai terang
        NumberSequenceKeypoint.new(0.5, 0),    -- puncak: paling terang
        NumberSequenceKeypoint.new(0.6, 0.1),  -- tengah kanan: mulai redup
        NumberSequenceKeypoint.new(1,   1),    -- ujung kanan: transparan
    })

    -- Loop animasi: ular jalan dari kiri ke kanan terus menerus
    local t = 0
    local SPEED = 0.6  -- kecepatan (detik per loop)

    RunService.Heartbeat:Connect(function(dt)
        if not abar.Parent or not abar.Parent.Parent then return end
        t = t + dt / SPEED
        if t > 1 then t = t - 1 end
        Snake.Position = UDim2.new(t - 0.35, 0, 0, 0)

        -- Glow sinkron dengan posisi ular (pulsing)
        local pulse = math.abs(math.sin(t * math.pi * 2))
        Glow.BackgroundTransparency = 0.6 + pulse * 0.35
    end)
end

-- ================================================================
-- KEY SYSTEM WINDOW
-- ================================================================
local KEY_SAVE_FILE = "KreinGuiKey.json"

local function loadSavedKey()
    local ok, raw = pcall(readfile, KEY_SAVE_FILE)
    if not ok or not raw then return nil end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 or not data then return nil end
    -- Cek apakah masih dalam 24 jam
    if data.time and os.time() - data.time < 86400 then
        return data.key
    end
    return nil
end

local function saveKey(key)
    pcall(function()
        writefile(KEY_SAVE_FILE, HttpService:JSONEncode({ key = key, time = os.time() }))
    end)
end

local function validateKeyFromUrl(key, url)
    local ok, raw = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or not raw then return false end
    -- Cek tiap baris
    for _, line in ipairs(string.split(raw, "\n")) do
        local trimmed = line:gsub("^%s*(.-)%s*$", "%1")
        if trimmed == key then return true end
    end
    return false
end

local function ShowKeyWindow(cfg, onSuccess)
    local keyLink = cfg.KeyLink or "https://example.com"
    local keyUrl  = cfg.KeyUrl  or ""

    local SG = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    SG.Name = "KreinGuiKey"
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SG.ResetOnSpawn = false
    SG.IgnoreGuiInset = true

    -- Overlay blur background
    local Overlay = Instance.new("Frame", SG)
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.5
    Overlay.BorderSizePixel = 0
    Overlay.ZIndex = 1

    -- Key Window Frame
    local KWin = Instance.new("Frame", SG)
    KWin.Size = UDim2.new(0, 360, 0, 260)
    KWin.Position = UDim2.new(0.5, -180, 0.5, -130)
    KWin.BackgroundColor3 = Theme.WindowBG
    KWin.BorderSizePixel = 0
    KWin.ZIndex = 2
    Corner(KWin, 14)
    Stroke(KWin, Theme.WindowStroke, 1)

    -- Gradient background
    local kg = Instance.new("UIGradient", KWin)
    kg.Color = ColorSequence.new(Color3.fromRGB(38,38,48), Color3.fromRGB(20,20,28))
    kg.Rotation = 135

    -- Header strip
    local KHeader = Instance.new("Frame", KWin)
    KHeader.Size = UDim2.new(1, 0, 0, 56)
    KHeader.BackgroundColor3 = Theme.HeaderBG
    KHeader.BorderSizePixel = 0
    KHeader.ZIndex = 3
    Corner(KHeader, 14)

    -- Accent bar header
    local KABar = Instance.new("Frame", KWin)
    KABar.Size = UDim2.new(1, 0, 0, 3)
    KABar.Position = UDim2.new(0, 0, 0, 53)
    KABar.BackgroundColor3 = Theme.Accent
    KABar.BorderSizePixel = 0
    KABar.ZIndex = 3

    -- Icon kunci
    local IconBg = Instance.new("Frame", KHeader)
    IconBg.Size = UDim2.new(0, 36, 0, 36)
    IconBg.Position = UDim2.new(0, 14, 0.5, -18)
    IconBg.BackgroundColor3 = Theme.Accent
    IconBg.BackgroundTransparency = 0.7
    IconBg.BorderSizePixel = 0
    IconBg.ZIndex = 4
    Corner(IconBg, 10)

    local IconLbl = Instance.new("TextLabel", IconBg)
    IconLbl.Size = UDim2.new(1, 0, 1, 0)
    IconLbl.BackgroundTransparency = 1
    IconLbl.BorderSizePixel = 0
    IconLbl.Text = "🔑"
    IconLbl.TextSize = 18
    IconLbl.Font = Enum.Font.GothamBold
    IconLbl.ZIndex = 5

    -- Judul
    local KTitle = Instance.new("TextLabel", KHeader)
    KTitle.Size = UDim2.new(1, -70, 0, 22)
    KTitle.Position = UDim2.new(0, 58, 0, 8)
    KTitle.BackgroundTransparency = 1
    KTitle.BorderSizePixel = 0
    KTitle.Text = "Key Required"
    KTitle.TextSize = 15
    KTitle.Font = Enum.Font.GothamBold
    KTitle.TextColor3 = Theme.TextPrimary
    KTitle.TextXAlignment = Enum.TextXAlignment.Left
    KTitle.ZIndex = 4

    local KSub = Instance.new("TextLabel", KHeader)
    KSub.Size = UDim2.new(1, -70, 0, 16)
    KSub.Position = UDim2.new(0, 58, 0, 30)
    KSub.BackgroundTransparency = 1
    KSub.BorderSizePixel = 0
    KSub.Text = "Masukkan key untuk melanjutkan"
    KSub.TextSize = 11
    KSub.Font = Enum.Font.Gotham
    KSub.TextColor3 = Theme.TextMuted
    KSub.TextXAlignment = Enum.TextXAlignment.Left
    KSub.ZIndex = 4

    -- Close button
    local KClose = Instance.new("TextButton", KHeader)
    KClose.Size = UDim2.new(0, 28, 0, 28)
    KClose.Position = UDim2.new(1, -38, 0.5, -14)
    KClose.BackgroundColor3 = Color3.fromRGB(60, 35, 35)
    KClose.BorderSizePixel = 0
    KClose.Text = "✕"; KClose.TextSize = 12
    KClose.Font = Enum.Font.GothamBold
    KClose.TextColor3 = Theme.CloseRed
    KClose.ZIndex = 4; KClose.AutoButtonColor = false
    Corner(KClose, 6)
    OnClick(KClose, function() SG:Destroy() end)

    -- Body area
    local KBody = Instance.new("Frame", KWin)
    KBody.Size = UDim2.new(1, 0, 1, -56)
    KBody.Position = UDim2.new(0, 0, 0, 56)
    KBody.BackgroundTransparency = 1
    KBody.BorderSizePixel = 0
    KBody.ZIndex = 3
    Pad(KBody, 16, 16, 16, 16)

    -- Info teks
    local InfoLbl = Instance.new("TextLabel", KBody)
    InfoLbl.Size = UDim2.new(1, 0, 0, 32)
    InfoLbl.BackgroundTransparency = 1
    InfoLbl.BorderSizePixel = 0
    InfoLbl.Text = "Key berlaku selama 24 jam. Dapatkan key baru via link di bawah."
    InfoLbl.TextSize = 11
    InfoLbl.Font = Enum.Font.Gotham
    InfoLbl.TextColor3 = Theme.TextMuted
    InfoLbl.TextXAlignment = Enum.TextXAlignment.Left
    InfoLbl.TextWrapped = true
    InfoLbl.ZIndex = 4

    -- Input box
    local InputFrame = Instance.new("Frame", KBody)
    InputFrame.Size = UDim2.new(1, 0, 0, 38)
    InputFrame.Position = UDim2.new(0, 0, 0, 40)
    InputFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    InputFrame.BorderSizePixel = 0
    InputFrame.ZIndex = 4
    Corner(InputFrame, 8)
    local inputStroke = Stroke(InputFrame, Theme.ElementStroke, 1)

    local KeyInput = Instance.new("TextBox", InputFrame)
    KeyInput.Size = UDim2.new(1, 0, 1, 0)
    KeyInput.BackgroundTransparency = 1
    KeyInput.BorderSizePixel = 0
    KeyInput.Text = ""
    KeyInput.PlaceholderText = "Masukkan key di sini..."
    KeyInput.PlaceholderColor3 = Theme.TextMuted
    KeyInput.TextColor3 = Theme.TextPrimary
    KeyInput.TextSize = 13
    KeyInput.Font = Enum.Font.GothamMedium
    KeyInput.TextXAlignment = Enum.TextXAlignment.Center
    KeyInput.ClearTextOnFocus = false
    KeyInput.ZIndex = 5
    Pad(KeyInput, 0, 0, 10, 10)

    KeyInput.Focused:Connect(function() inputStroke.Color = Theme.Accent end)
    KeyInput.FocusLost:Connect(function() inputStroke.Color = Theme.ElementStroke end)

    -- Status label
    local StatusLbl = Instance.new("TextLabel", KBody)
    StatusLbl.Size = UDim2.new(1, 0, 0, 18)
    StatusLbl.Position = UDim2.new(0, 0, 0, 84)
    StatusLbl.BackgroundTransparency = 1
    StatusLbl.BorderSizePixel = 0
    StatusLbl.Text = ""
    StatusLbl.TextSize = 11
    StatusLbl.Font = Enum.Font.Gotham
    StatusLbl.TextColor3 = Theme.TextMuted
    StatusLbl.TextXAlignment = Enum.TextXAlignment.Center
    StatusLbl.ZIndex = 4

    -- 3 tombol bawah
    local BtnRow = Instance.new("Frame", KBody)
    BtnRow.Size = UDim2.new(1, 0, 0, 36)
    BtnRow.Position = UDim2.new(0, 0, 1, -36)
    BtnRow.BackgroundTransparency = 1
    BtnRow.BorderSizePixel = 0
    BtnRow.ZIndex = 4

    local function makeBtn(text, bgColor, textColor, posX, w)
        local b = Instance.new("TextButton", BtnRow)
        b.Size = UDim2.new(0, w, 1, 0)
        b.Position = UDim2.new(0, posX, 0, 0)
        b.BackgroundColor3 = bgColor
        b.BorderSizePixel = 0
        b.Text = text; b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = textColor
        b.AutoButtonColor = false; b.ZIndex = 5
        Corner(b, 7)
        return b
    end

    local totalW = 360 - 32  -- lebar BtnRow (padding 16 kiri-kanan)
    local gap = 6
    local w1 = math.floor((totalW - gap*2) * 0.38)  -- Copy Link
    local w2 = math.floor((totalW - gap*2) * 0.38)  -- Apply Key
    local w3 = totalW - w1 - w2 - gap*2             -- Close

    local CopyBtn  = makeBtn("📋 Copy Link", Color3.fromRGB(40,40,55),  Theme.TextSecondary, 0,         w1)
    local ApplyBtn = makeBtn("✓ Apply Key",  Theme.Accent,              Color3.fromRGB(255,255,255), w1+gap, w2)
    local CloseBtn2= makeBtn("✕ Close",      Color3.fromRGB(55,30,30),  Theme.CloseRed, w1+w2+gap*2, w3)

    -- Hover effects
    CopyBtn.MouseEnter:Connect(function() Tween(CopyBtn,{BackgroundColor3=Color3.fromRGB(55,55,70)},0.15) end)
    CopyBtn.MouseLeave:Connect(function() Tween(CopyBtn,{BackgroundColor3=Color3.fromRGB(40,40,55)},0.15) end)
    ApplyBtn.MouseEnter:Connect(function() Tween(ApplyBtn,{BackgroundColor3=Theme.AccentHover},0.15) end)
    ApplyBtn.MouseLeave:Connect(function() Tween(ApplyBtn,{BackgroundColor3=Theme.Accent},0.15) end)
    CloseBtn2.MouseEnter:Connect(function() Tween(CloseBtn2,{BackgroundColor3=Color3.fromRGB(80,35,35)},0.15) end)
    CloseBtn2.MouseLeave:Connect(function() Tween(CloseBtn2,{BackgroundColor3=Color3.fromRGB(55,30,30)},0.15) end)

    -- Copy link
    OnClick(CopyBtn, function()
        setclipboard(keyLink)
        local old = CopyBtn.Text
        CopyBtn.Text = "✓ Copied!"
        CopyBtn.TextColor3 = Color3.fromRGB(100,220,100)
        task.delay(1.5, function()
            CopyBtn.Text = old
            CopyBtn.TextColor3 = Theme.TextSecondary
        end)
    end)

    -- Close
    OnClick(CloseBtn2, function() SG:Destroy() end)

    -- Apply key
    local checking = false
    OnClick(ApplyBtn, function()
        if checking then return end
        local key = KeyInput.Text:gsub("^%s*(.-)%s*$", "%1")
        if key == "" then
            StatusLbl.Text = "⚠ Key tidak boleh kosong!"; StatusLbl.TextColor3 = Color3.fromRGB(255,180,50)
            return
        end
        checking = true
        ApplyBtn.Text = "Checking..."
        StatusLbl.Text = "Memvalidasi key..."; StatusLbl.TextColor3 = Theme.TextMuted

        task.spawn(function()
            local valid = validateKeyFromUrl(key, keyUrl)
            checking = false
            if valid then
                saveKey(key)
                ApplyBtn.Text = "✓ Apply Key"
                StatusLbl.Text = "✓ Key valid! Membuka GUI..."; StatusLbl.TextColor3 = Color3.fromRGB(80,220,120)
                task.delay(0.8, function()
                    SG:Destroy()
                    onSuccess()
                end)
            else
                ApplyBtn.Text = "✓ Apply Key"
                StatusLbl.Text = "✗ Key tidak valid atau sudah expired!"; StatusLbl.TextColor3 = Color3.fromRGB(255,80,80)
            end
        end)
    end)

    -- Animasi masuk
    KWin.Position = UDim2.new(0.5, -180, 0.5, -90)
    KWin.BackgroundTransparency = 1
    Tween(KWin, { BackgroundTransparency = 0 }, 0.2)
    Tween(KWin, { Position = UDim2.new(0.5, -180, 0.5, -130) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- ================================================================
-- LIBRARY
-- ================================================================
local KreinGui   = {}
KreinGui.__index = KreinGui
KreinGui.Flags   = {}
KreinGui.Presets = Presets

function KreinGui:SetTheme(ov)
    for k,v in pairs(ov) do Theme[k] = v end
    if ov.Accent then
        Theme.AccentHover = Color3.new(math.min(ov.Accent.R+0.1,1),math.min(ov.Accent.G+0.1,1),math.min(ov.Accent.B+0.1,1))
        Theme.AccentDark  = Color3.new(ov.Accent.R*0.6,ov.Accent.G*0.6,ov.Accent.B*0.6)
        Theme.ToggleOn    = ov.Accent
        Theme.TabActive   = ov.Accent
    end
end
function KreinGui:UsePreset(name)
    if Presets[name] then self:SetTheme(Presets[name]) end
end

-- ================================================================
-- CREATE WINDOW
-- ================================================================
function KreinGui:CreateWindow(cfg)
    cfg = cfg or {}
    local title      = cfg.Title      or "KreinGui"
    local subtitle   = cfg.SubTitle   or ""
    local configName = cfg.ConfigName or "KreinGuiConfig"
    local useKey     = cfg.KeySystem  or false

    -- Fungsi yang benar-benar buat GUI utama
    local function buildGUI()
        local SG = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
        SG.Name           = "KreinGui"
        SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        SG.ResetOnSpawn   = false
        SG.IgnoreGuiInset = true

        -- Window
        local Win = Instance.new("Frame", SG)
        Win.Name = "Window"
        Win.Size = UDim2.new(0, 560, 0, 340)
        Win.Position = UDim2.new(0.5, -280, 0.5, -170)
        Win.BackgroundColor3 = Theme.WindowBG
        Win.BorderSizePixel = 0
        Win.ClipsDescendants = true
        Corner(Win, 12); Stroke(Win, Theme.WindowStroke, 1)

        local grad = Instance.new("UIGradient", Win)
        grad.Color = ColorSequence.new(Color3.fromRGB(40,40,50), Color3.fromRGB(22,22,28))
        grad.Rotation = 135

        -- ── HEADER ──────────────────────────────────────────
        local Header = Instance.new("Frame", Win)
        Header.Name = "Header"
        Header.Size = UDim2.new(1, 0, 0, 52)
        Header.BackgroundColor3 = Theme.HeaderBG
        Header.BorderSizePixel = 0; Header.ZIndex = 4
        Corner(Header, 12)

        -- ── ABAR: Tebal 4px, glow, animasi ular ─────────────
        local ABar = Instance.new("Frame", Win)
        ABar.Name = "ABar"
        ABar.Size = UDim2.new(1, 0, 0, 4)
        ABar.Position = UDim2.new(0, 0, 0, 50)
        ABar.BackgroundColor3 = Theme.Accent
        ABar.BorderSizePixel = 0
        ABar.ZIndex = 3
        -- Mulai animasi ular
        StartABarAnim(ABar, Theme.Accent)

        local Dot = Instance.new("Frame", Header)
        Dot.Size = UDim2.new(0,7,0,7); Dot.Position = UDim2.new(0,14,0.5,-3)
        Dot.BackgroundColor3 = Theme.Accent; Dot.BorderSizePixel = 0; Dot.ZIndex = 5
        Corner(Dot, 4)

        local TL = Lbl(Header, title, UDim2.new(0,280,0,22), Theme.TextPrimary)
        TL.Position = subtitle ~= "" and UDim2.new(0,28,0,5) or UDim2.new(0,28,0,0)
        TL.Font = Enum.Font.GothamBold; TL.TextSize = 15; TL.ZIndex = 5

        if subtitle ~= "" then
            local SL = Lbl(Header, subtitle, UDim2.new(0,280,0,18), Theme.TextMuted)
            SL.Position = UDim2.new(0,28,0,28); SL.Font = Enum.Font.Gotham; SL.TextSize = 11; SL.ZIndex = 5
        end

        -- Close
        local CloseBtn = Instance.new("TextButton", Header)
        CloseBtn.Size = UDim2.new(0,34,0,34); CloseBtn.Position = UDim2.new(1,-42,0.5,-17)
        CloseBtn.BackgroundColor3 = Color3.fromRGB(60,35,35); CloseBtn.BorderSizePixel = 0
        CloseBtn.Text = "✕"; CloseBtn.TextSize = 14; CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.TextColor3 = Theme.CloseRed; CloseBtn.ZIndex = 6; CloseBtn.AutoButtonColor = false
        Corner(CloseBtn, 7)
        OnClick(CloseBtn, function() SG:Destroy() end)

        -- Minimize
        local MinBtn = Instance.new("TextButton", Header)
        MinBtn.Size = UDim2.new(0,34,0,34); MinBtn.Position = UDim2.new(1,-82,0.5,-17)
        MinBtn.BackgroundColor3 = Color3.fromRGB(40,40,50); MinBtn.BorderSizePixel = 0
        MinBtn.Text = "—"; MinBtn.TextSize = 14; MinBtn.Font = Enum.Font.GothamBold
        MinBtn.TextColor3 = Theme.MinimizeGray; MinBtn.ZIndex = 6; MinBtn.AutoButtonColor = false
        Corner(MinBtn, 7)

        local minimized = false
        OnClick(MinBtn, function()
            minimized = not minimized
            if minimized then
                Tween(Win, { Size = UDim2.new(0,560,0,52) }, 0.25)
                task.delay(0.1, function()
                    ABar.Visible = false
                    local glow = Win:FindFirstChild("ABarGlow")
                    if glow then glow.Visible = false end
                end)
            else
                ABar.Visible = true
                local glow = Win:FindFirstChild("ABarGlow")
                if glow then glow.Visible = true end
                Tween(Win, { Size = UDim2.new(0,560,0,340) }, 0.25)
            end
        end)

        EnableDrag(Win, Header)

        -- ── BODY ────────────────────────────────────────────
        local Body = Instance.new("Frame", Win)
        Body.Name = "Body"; Body.Size = UDim2.new(1,0,1,-54); Body.Position = UDim2.new(0,0,0,54)
        Body.BackgroundTransparency = 1; Body.BorderSizePixel = 0

        local TAB_W = 130

        local TabPanel = Instance.new("Frame", Body)
        TabPanel.Size = UDim2.new(0,TAB_W,1,0)
        TabPanel.BackgroundColor3 = Theme.TabPanelBG; TabPanel.BorderSizePixel = 0

        local SepLine = Instance.new("Frame", Body)
        SepLine.Size = UDim2.new(0,1,1,0); SepLine.Position = UDim2.new(0,TAB_W,0,0)
        SepLine.BackgroundColor3 = Theme.Separator; SepLine.BorderSizePixel = 0

        local TabScroll = Instance.new("ScrollingFrame", TabPanel)
        TabScroll.Size = UDim2.new(1,0,1,0); TabScroll.BackgroundTransparency = 1; TabScroll.BorderSizePixel = 0
        TabScroll.ScrollBarThickness = 2; TabScroll.ScrollBarImageColor3 = Theme.Accent
        TabScroll.CanvasSize = UDim2.new(0,0,0,0); TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Pad(TabScroll, 8,8,6,6)
        local TabLayout = Instance.new("UIListLayout", TabScroll)
        TabLayout.SortOrder = Enum.SortOrder.LayoutOrder; TabLayout.Padding = UDim.new(0,3)
        TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

        local ContentPanel = Instance.new("Frame", Body)
        ContentPanel.Size = UDim2.new(1,-(TAB_W+1),1,0); ContentPanel.Position = UDim2.new(0,TAB_W+1,0,0)
        ContentPanel.BackgroundTransparency = 1; ContentPanel.BorderSizePixel = 0
        ContentPanel.ClipsDescendants = false

        -- ── WINDOW OBJECT ────────────────────────────────────
        local WObj    = {}
        local tabBtns = {}
        local tabFrms = {}
        local active  = nil
        local flagMap = {}

        local function setActive(idx)
            if active == idx then return end
            active = idx
            for i, btn in ipairs(tabBtns) do
                local on = (i==idx)
                Tween(btn,{BackgroundColor3=on and Theme.TabActive or Theme.TabDefault},0.18)
                local lbl=btn:FindFirstChild("Lbl"); if lbl then Tween(lbl,{TextColor3=on and Theme.TabActiveText or Theme.TabDefaultText},0.18) end
                local bar=btn:FindFirstChild("Bar"); if bar then bar.Visible=on end
            end
            for i,f in ipairs(tabFrms) do f.Visible=(i==idx) end
        end

        -- Save / Load
        local function sCol(c) return {r=c.R,g=c.G,b=c.B} end
        local function dCol(t) return Color3.new(t.r,t.g,t.b) end

        function WObj:SaveConfig()
            local data={}
            for flag,api in pairs(flagMap) do
                local v=api:Get()
                if typeof(v)=="Color3" then data[flag]={__type="Color3",value=sCol(v)}
                elseif typeof(v)=="EnumItem" then data[flag]={__type="EnumItem",value=tostring(v)}
                else data[flag]=v end
            end
            local ok,err=pcall(function() writefile(configName..".json",HttpService:JSONEncode(data)) end)
            self:Notify(ok and "Config tersimpan!" or "Gagal: "..tostring(err),2)
        end

        function WObj:LoadConfig()
            local ok,raw=pcall(readfile,configName..".json")
            if not ok or not raw then self:Notify("Config tidak ditemukan.",2); return end
            local ok2,data=pcall(HttpService.JSONDecode,HttpService,raw)
            if not ok2 or not data then self:Notify("Config rusak.",2); return end
            for flag,val in pairs(data) do
                if flagMap[flag] then
                    if type(val)=="table" and val.__type=="Color3" then flagMap[flag]:Set(dCol(val.value))
                    elseif type(val)=="table" and val.__type=="EnumItem" then
                        local pts=string.split(val.value,"."); local ok3,en=pcall(function() return Enum[pts[2]][pts[3]] end)
                        if ok3 then flagMap[flag]:Set(en) end
                    else flagMap[flag]:Set(val) end
                end
            end
            self:Notify("Config dimuat!",2)
        end

        -- Notify
        function WObj:Notify(msg, dur)
            dur = dur or 3
            local N = Instance.new("Frame", SG)
            N.Size=UDim2.new(0,250,0,46); N.Position=UDim2.new(1,10,1,-64)
            N.BackgroundColor3=Theme.ElementBG; N.BorderSizePixel=0; N.ZIndex=200
            Corner(N,8); Stroke(N,Theme.Accent,1)
            local Bar=Instance.new("Frame",N)
            Bar.Size=UDim2.new(0,3,0.7,0); Bar.Position=UDim2.new(0,0,0.15,0)
            Bar.BackgroundColor3=Theme.Accent; Bar.BorderSizePixel=0; Bar.ZIndex=201; Corner(Bar,3)
            local nl=Lbl(N,msg,UDim2.new(1,-18,1,0),Theme.TextPrimary)
            nl.Position=UDim2.new(0,14,0,0); nl.Font=Enum.Font.Gotham; nl.TextSize=12; nl.ZIndex=201; nl.TextWrapped=true
            Tween(N,{Position=UDim2.new(1,-260,1,-64)},0.3)
            task.delay(dur,function()
                Tween(N,{Position=UDim2.new(1,10,1,-64)},0.3)
                task.delay(0.35,function() N:Destroy() end)
            end)
        end

        -- ── CREATE TAB ───────────────────────────────────────
        function WObj:CreateTab(name)
            local idx = #tabBtns + 1

            local Btn = Instance.new("TextButton", TabScroll)
            Btn.Name="Tab_"..idx; Btn.Size=UDim2.new(1,-4,0,40)
            Btn.BackgroundColor3=Theme.TabDefault; Btn.BorderSizePixel=0
            Btn.Text=""; Btn.LayoutOrder=idx; Btn.AutoButtonColor=false
            Corner(Btn,7)

            local Bar=Instance.new("Frame",Btn)
            Bar.Name="Bar"; Bar.Size=UDim2.new(0,3,0.55,0); Bar.Position=UDim2.new(0,0,0.225,0)
            Bar.BackgroundColor3=Theme.AccentHover; Bar.BorderSizePixel=0; Bar.Visible=false; Corner(Bar,2)

            local BL=Lbl(Btn,name,UDim2.new(1,-14,1,0),Theme.TabDefaultText)
            BL.Name="Lbl"; BL.Position=UDim2.new(0,10,0,0); BL.Font=Enum.Font.GothamMedium; BL.TextSize=12

            OnClick(Btn, function() setActive(idx) end)
            Btn.MouseEnter:Connect(function() if active~=idx then Tween(Btn,{BackgroundColor3=Theme.TabHover},0.15) end end)
            Btn.MouseLeave:Connect(function() if active~=idx then Tween(Btn,{BackgroundColor3=Theme.TabDefault},0.15) end end)
            tabBtns[idx] = Btn

            local Content = Instance.new("ScrollingFrame", ContentPanel)
            Content.Name="Content_"..idx; Content.Size=UDim2.new(1,0,1,0)
            Content.BackgroundTransparency=1; Content.BorderSizePixel=0
            Content.Visible=false; Content.ScrollBarThickness=3
            Content.ScrollBarImageColor3=Theme.Accent
            Content.CanvasSize=UDim2.new(0,0,0,0); Content.AutomaticCanvasSize=Enum.AutomaticSize.Y
            Content.ClipsDescendants=false
            Pad(Content,10,10,10,10)
            local EList=Instance.new("UIListLayout",Content)
            EList.SortOrder=Enum.SortOrder.LayoutOrder; EList.Padding=UDim.new(0,6)

            tabFrms[idx] = Content
            if idx == 1 then setActive(1) end

            -- TAB OBJECT
            local TObj  = {}
            local order = 0
            local function nxt() order=order+1; return order end

            local function Card(h)
                local c=Instance.new("Frame",Content)
                c.Size=UDim2.new(1,0,0,h or 44); c.BackgroundColor3=Theme.ElementBG
                c.BorderSizePixel=0; c.LayoutOrder=nxt(); c.ClipsDescendants=false
                Corner(c,8); Stroke(c,Theme.ElementStroke,1)
                return c
            end

            local function RegFlag(flag,api)
                if flag and flag~="" then flagMap[flag]=api; KreinGui.Flags[flag]=api end
            end

            -- ─── LABEL ──────────────────────────────────────
            function TObj:CreateLabel(text)
                local c=Card(36); Pad(c,0,0,12,12)
                local l=Lbl(c,text,UDim2.new(1,0,1,0),Theme.TextSecondary)
                l.Font=Enum.Font.Gotham; l.TextSize=12; return l
            end

            -- ─── SECTION HEADER ─────────────────────────────
            function TObj:CreateSectionHeader(text)
                local c = Instance.new("Frame", Content)
                c.Size = UDim2.new(1, 0, 0, 26)
                c.BackgroundTransparency = 1
                c.BorderSizePixel = 0
                c.LayoutOrder = nxt()

                -- Garis kiri accent
                local line = Instance.new("Frame", c)
                line.Size = UDim2.new(0, 3, 0.6, 0)
                line.Position = UDim2.new(0, 0, 0.2, 0)
                line.BackgroundColor3 = Theme.Accent
                line.BorderSizePixel = 0
                Corner(line, 2)

                local lbl = Lbl(c, text:upper(), UDim2.new(1,-10,1,0), Theme.SectionText)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 10
                lbl.LetterSpacing = 2
                return lbl
            end

            -- ─── BUTTON ─────────────────────────────────────
            function TObj:CreateButton(cfg2)
                cfg2=cfg2 or {}
                local c=Card(44); Pad(c,0,0,12,12)
                local hov=Instance.new("TextButton",c)
                hov.Size=UDim2.new(1,0,1,0); hov.BackgroundTransparency=1
                hov.BorderSizePixel=0; hov.Text=""; hov.AutoButtonColor=false
                Lbl(c,cfg2.Title or "Button",UDim2.new(1,-84,1,0))
                local rb=Instance.new("TextButton",c)
                rb.Size=UDim2.new(0,68,0,30); rb.Position=UDim2.new(1,-72,0.5,-15)
                rb.BackgroundColor3=Theme.Accent; rb.BorderSizePixel=0
                rb.Text="Run"; rb.TextSize=11; rb.Font=Enum.Font.GothamBold
                rb.TextColor3=Color3.fromRGB(255,255,255); rb.AutoButtonColor=false; Corner(rb,6)
                OnClick(rb,function()
                    Tween(rb,{BackgroundColor3=Theme.AccentDark},0.1)
                    task.delay(0.15,function() Tween(rb,{BackgroundColor3=Theme.Accent},0.15) end)
                    pcall(cfg2.Callback or function()end)
                end)
                rb.MouseEnter:Connect(function() Tween(rb,{BackgroundColor3=Theme.AccentHover},0.15) end)
                rb.MouseLeave:Connect(function() Tween(rb,{BackgroundColor3=Theme.Accent},0.15) end)
                hov.MouseEnter:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
                hov.MouseLeave:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBG},0.15) end)
            end

            -- ─── TOGGLE ─────────────────────────────────────
            function TObj:CreateToggle(cfg2)
                cfg2=cfg2 or {}
                local state=cfg2.Default or false
                local c=Card(44); Pad(c,0,0,12,12)
                Lbl(c,cfg2.Title or "Toggle",UDim2.new(1,-60,1,0))
                local Track=Instance.new("Frame",c)
                Track.Size=UDim2.new(0,44,0,24); Track.Position=UDim2.new(1,-48,0.5,-12)
                Track.BackgroundColor3=state and Theme.ToggleOn or Theme.ToggleOff; Track.BorderSizePixel=0; Corner(Track,12)
                local Knob=Instance.new("Frame",Track)
                Knob.Size=UDim2.new(0,18,0,18)
                Knob.Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
                Knob.BackgroundColor3=Color3.fromRGB(255,255,255); Knob.BorderSizePixel=0; Corner(Knob,9)
                local tb=Instance.new("TextButton",c)
                tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1; tb.BorderSizePixel=0; tb.Text=""; tb.AutoButtonColor=false
                local api={}
                local function upd()
                    Tween(Track,{BackgroundColor3=state and Theme.ToggleOn or Theme.ToggleOff},0.18)
                    Tween(Knob,{Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)},0.18)
                    pcall(cfg2.Callback or function()end,state)
                end
                function api:Set(v) state=v; upd() end
                function api:Get() return state end
                OnClick(tb,function() state=not state; upd() end)
                tb.MouseEnter:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
                tb.MouseLeave:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBG},0.15) end)
                RegFlag(cfg2.Flag,api); return api
            end

            -- ─── SLIDER ─────────────────────────────────────
            function TObj:CreateSlider(cfg2)
                cfg2=cfg2 or {}
                local mn=cfg2.Min or 0; local mx=cfg2.Max or 100
                local val=math.clamp(cfg2.Default or mn,mn,mx)
                local c=Card(58); Pad(c,8,8,12,12)
                local TopRow=Instance.new("Frame",c)
                TopRow.Size=UDim2.new(1,0,0,20); TopRow.BackgroundTransparency=1; TopRow.BorderSizePixel=0
                local tl=Lbl(TopRow,cfg2.Title or "Slider",UDim2.new(1,-42,1,0)); tl.Font=Enum.Font.GothamMedium; tl.TextSize=13
                local vl=Lbl(TopRow,tostring(val),UDim2.new(0,40,1,0),Theme.Accent,Enum.TextXAlignment.Right)
                vl.Position=UDim2.new(1,-40,0,0); vl.Font=Enum.Font.GothamBold
                local TBG=Instance.new("Frame",c)
                TBG.Size=UDim2.new(1,0,0,10); TBG.Position=UDim2.new(0,0,1,-18)
                TBG.BackgroundColor3=Theme.ToggleOff; TBG.BorderSizePixel=0; Corner(TBG,5)
                local p0=(val-mn)/(mx-mn)
                local TFill=Instance.new("Frame",TBG)
                TFill.Size=UDim2.new(p0,0,1,0); TFill.BackgroundColor3=Theme.Accent; TFill.BorderSizePixel=0; Corner(TFill,5)
                local Knob=Instance.new("Frame",TBG)
                Knob.Size=UDim2.new(0,20,0,20); Knob.Position=UDim2.new(p0,-10,0.5,-10)
                Knob.BackgroundColor3=Color3.fromRGB(255,255,255); Knob.BorderSizePixel=0; Knob.ZIndex=3; Corner(Knob,10); Stroke(Knob,Theme.Accent,2)
                local SBtn=Instance.new("TextButton",TBG)
                SBtn.Size=UDim2.new(1,0,0,40); SBtn.Position=UDim2.new(0,0,0.5,-20)
                SBtn.BackgroundTransparency=1; SBtn.BorderSizePixel=0; SBtn.Text=""; SBtn.ZIndex=4
                local sliding=false; local api={}
                local function updSlider(x)
                    local r=math.clamp((x-TBG.AbsolutePosition.X)/TBG.AbsoluteSize.X,0,1)
                    val=math.floor(mn+r*(mx-mn)+0.5); local p=(val-mn)/(mx-mn)
                    TFill.Size=UDim2.new(p,0,1,0); Knob.Position=UDim2.new(p,-10,0.5,-10); vl.Text=tostring(val)
                    pcall(cfg2.Callback or function()end,val)
                end
                function api:Set(v) val=math.clamp(v,mn,mx); local p=(val-mn)/(mx-mn); TFill.Size=UDim2.new(p,0,1,0); Knob.Position=UDim2.new(p,-10,0.5,-10); vl.Text=tostring(val); pcall(cfg2.Callback or function()end,val) end
                function api:Get() return val end
                SBtn.InputBegan:Connect(function(inp) if isDown(inp) then sliding=true; updSlider(inp.Position.X) end end)
                UserInput.InputChanged:Connect(function(inp) if sliding and isMove(inp) then updSlider(inp.Position.X) end end)
                UserInput.InputEnded:Connect(function(inp) if isDown(inp) then sliding=false end end)
                RegFlag(cfg2.Flag,api); return api
            end

            -- ─── TEXTBOX ────────────────────────────────────
            function TObj:CreateTextBox(cfg2)
                cfg2=cfg2 or {}
                local c=Card(70); Pad(c,8,8,12,12)
                local tl=Lbl(c,cfg2.Title or "TextBox",UDim2.new(1,0,0,20)); tl.Font=Enum.Font.GothamMedium; tl.TextSize=13
                local IF=Instance.new("Frame",c)
                IF.Size=UDim2.new(1,0,0,32); IF.Position=UDim2.new(0,0,1,-36)
                IF.BackgroundColor3=Theme.WindowBG; IF.BorderSizePixel=0; Corner(IF,6)
                local ifStroke=Stroke(IF,Theme.ElementStroke,1)
                local TB=Instance.new("TextBox",IF)
                TB.Size=UDim2.new(1,0,1,0); TB.BackgroundTransparency=1; TB.BorderSizePixel=0
                TB.Text=""; TB.PlaceholderText=cfg2.Placeholder or "Type here..."
                TB.PlaceholderColor3=Theme.TextMuted; TB.TextColor3=Theme.TextPrimary
                TB.TextSize=12; TB.Font=Enum.Font.Gotham; TB.TextXAlignment=Enum.TextXAlignment.Left; TB.ClearTextOnFocus=false
                Pad(TB,0,0,8,8)
                TB.Focused:Connect(function() ifStroke.Color=Theme.Accent end)
                TB.FocusLost:Connect(function(enter) ifStroke.Color=Theme.ElementStroke; if enter then pcall(cfg2.Callback or function()end,TB.Text) end end)
                local api={}; function api:Set(v) TB.Text=tostring(v) end; function api:Get() return TB.Text end
                RegFlag(cfg2.Flag,api); return api
            end

            -- ─── DROPDOWN ───────────────────────────────────
            function TObj:CreateDropdown(cfg2)
                cfg2=cfg2 or {}
                local opts=cfg2.Options or {}; local sel=cfg2.Default or (opts[1] or ""); local open=false
                local c=Card(44); Pad(c,0,0,12,12)
                local tl=Lbl(c,cfg2.Title or "Dropdown",UDim2.new(1,-100,1,0)); tl.Font=Enum.Font.GothamMedium; tl.TextSize=13
                local SF=Instance.new("Frame",c)
                SF.Size=UDim2.new(0,90,0,28); SF.Position=UDim2.new(1,-90,0.5,-14)
                SF.BackgroundColor3=Theme.WindowBG; SF.BorderSizePixel=0; Corner(SF,6); Stroke(SF,Theme.ElementStroke,1)
                local SL=Lbl(SF,sel,UDim2.new(1,-18,1,0),Theme.TextPrimary); SL.Position=UDim2.new(0,6,0,0); SL.Font=Enum.Font.Gotham; SL.TextSize=11
                local Arrow=Lbl(SF,"▾",UDim2.new(0,14,1,0),Theme.TextMuted,Enum.TextXAlignment.Center); Arrow.Position=UDim2.new(1,-16,0,0); Arrow.TextSize=12
                local DF=Instance.new("Frame",SG)
                DF.Size=UDim2.new(0,100,0,0); DF.BackgroundColor3=Theme.ElementBG; DF.BorderSizePixel=0
                DF.ClipsDescendants=true; DF.Visible=false; DF.ZIndex=160; Corner(DF,6); Stroke(DF,Theme.ElementStroke,1)
                local DList=Instance.new("UIListLayout",DF); DList.SortOrder=Enum.SortOrder.LayoutOrder; DList.Padding=UDim.new(0,2); Pad(DF,4,4,4,4)
                local optH=32
                local function closeDD()
                    if not open then return end; open=false
                    Tween(DF,{Size=UDim2.new(0,DF.Size.X.Offset,0,0)},0.15); Arrow.Text="▾"
                    task.delay(0.16,function() DF.Visible=false end)
                end
                for i,opt in ipairs(opts) do
                    local ob=Instance.new("TextButton",DF)
                    ob.Size=UDim2.new(1,0,0,optH-2); ob.BackgroundColor3=Theme.ElementBG; ob.BorderSizePixel=0
                    ob.Text=opt; ob.TextSize=12; ob.Font=Enum.Font.Gotham; ob.TextColor3=Theme.TextSecondary
                    ob.TextXAlignment=Enum.TextXAlignment.Left; ob.AutoButtonColor=false; ob.ZIndex=161; ob.LayoutOrder=i
                    Corner(ob,4); Pad(ob,0,0,8,0)
                    ob.MouseEnter:Connect(function() Tween(ob,{BackgroundColor3=Theme.TabHover},0.12) end)
                    ob.MouseLeave:Connect(function() Tween(ob,{BackgroundColor3=Theme.ElementBG},0.12) end)
                    OnClick(ob,function() sel=opt; SL.Text=opt; pcall(cfg2.Callback or function()end,sel); closeDD() end)
                end
                local totalH=#opts*optH+8
                local function openDD()
                    local ap=SF.AbsolutePosition; local as=SF.AbsoluteSize; local w=math.max(as.X+10,100)
                    DF.Position=UDim2.new(0,ap.X,0,ap.Y+as.Y+4); DF.Size=UDim2.new(0,w,0,0)
                    DF.Visible=true; open=true; Tween(DF,{Size=UDim2.new(0,w,0,totalH)},0.2); Arrow.Text="▴"
                end
                local TB2=Instance.new("TextButton",c)
                TB2.Size=UDim2.new(1,0,1,0); TB2.BackgroundTransparency=1; TB2.BorderSizePixel=0; TB2.Text=""; TB2.AutoButtonColor=false
                OnClick(TB2,function() if open then closeDD() else openDD() end end)
                TB2.MouseEnter:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
                TB2.MouseLeave:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBG},0.15) end)
                UserInput.InputBegan:Connect(function(inp)
                    if not open or not isDown(inp) then return end
                    task.defer(function()
                        if not open then return end
                        local pos=inp.Position; local dfP=DF.AbsolutePosition; local dfS=DF.AbsoluteSize; local cP=c.AbsolutePosition; local cS=c.AbsoluteSize
                        if not(pos.X>=dfP.X and pos.X<=dfP.X+dfS.X and pos.Y>=dfP.Y and pos.Y<=dfP.Y+dfS.Y) and
                           not(pos.X>=cP.X  and pos.X<=cP.X+cS.X   and pos.Y>=cP.Y  and pos.Y<=cP.Y+cS.Y) then closeDD() end
                    end)
                end)
                local api={}; function api:Set(v) sel=v; SL.Text=v; pcall(cfg2.Callback or function()end,v) end; function api:Get() return sel end
                RegFlag(cfg2.Flag,api); return api
            end

            -- ─── INPUT NUMBER ───────────────────────────────
            function TObj:CreateInputNumber(cfg2)
                cfg2 = cfg2 or {}
                local mn   = cfg2.Min     or 0
                local mx   = cfg2.Max     or 100
                local step = cfg2.Step    or 1
                local val  = math.clamp(cfg2.Default or mn, mn, mx)

                local c = Card(44); Pad(c, 0, 0, 12, 12)

                local tl = Lbl(c, cfg2.Title or "Number", UDim2.new(1, -130, 1, 0))
                tl.Font = Enum.Font.GothamMedium; tl.TextSize = 13

                -- Container tombol + angka
                local Row = Instance.new("Frame", c)
                Row.Size = UDim2.new(0, 118, 0, 30)
                Row.Position = UDim2.new(1, -122, 0.5, -15)
                Row.BackgroundTransparency = 1
                Row.BorderSizePixel = 0

                local MinusBtn = Instance.new("TextButton", Row)
                MinusBtn.Size = UDim2.new(0, 30, 1, 0)
                MinusBtn.BackgroundColor3 = Theme.ElementBGHover
                MinusBtn.BorderSizePixel = 0; MinusBtn.Text = "−"
                MinusBtn.TextSize = 16; MinusBtn.Font = Enum.Font.GothamBold
                MinusBtn.TextColor3 = Theme.TextPrimary; MinusBtn.AutoButtonColor = false
                Corner(MinusBtn, 6)

                local ValFrame = Instance.new("Frame", Row)
                ValFrame.Size = UDim2.new(0, 52, 1, 0)
                ValFrame.Position = UDim2.new(0, 34, 0, 0)
                ValFrame.BackgroundColor3 = Theme.WindowBG
                ValFrame.BorderSizePixel = 0
                Corner(ValFrame, 6); Stroke(ValFrame, Theme.ElementStroke, 1)

                local ValLbl = Lbl(ValFrame, tostring(val), UDim2.new(1,0,1,0), Theme.TextPrimary, Enum.TextXAlignment.Center)
                ValLbl.Font = Enum.Font.GothamBold; ValLbl.TextSize = 13

                local PlusBtn = Instance.new("TextButton", Row)
                PlusBtn.Size = UDim2.new(0, 30, 1, 0)
                PlusBtn.Position = UDim2.new(0, 90, 0, 0)
                PlusBtn.BackgroundColor3 = Theme.ElementBGHover
                PlusBtn.BorderSizePixel = 0; PlusBtn.Text = "+"
                PlusBtn.TextSize = 16; PlusBtn.Font = Enum.Font.GothamBold
                PlusBtn.TextColor3 = Theme.TextPrimary; PlusBtn.AutoButtonColor = false
                Corner(PlusBtn, 6)

                MinusBtn.MouseEnter:Connect(function() Tween(MinusBtn,{BackgroundColor3=Theme.TabHover},0.12) end)
                MinusBtn.MouseLeave:Connect(function() Tween(MinusBtn,{BackgroundColor3=Theme.ElementBGHover},0.12) end)
                PlusBtn.MouseEnter:Connect(function() Tween(PlusBtn,{BackgroundColor3=Theme.TabHover},0.12) end)
                PlusBtn.MouseLeave:Connect(function() Tween(PlusBtn,{BackgroundColor3=Theme.ElementBGHover},0.12) end)

                local api = {}
                local function updVal()
                    ValLbl.Text = tostring(val)
                    pcall(cfg2.Callback or function()end, val)
                end
                function api:Set(v) val=math.clamp(v,mn,mx); updVal() end
                function api:Get() return val end

                OnClick(MinusBtn, function()
                    val = math.clamp(val - step, mn, mx); updVal()
                    Tween(MinusBtn,{BackgroundColor3=Theme.AccentDark},0.1)
                    task.delay(0.15,function() Tween(MinusBtn,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
                end)
                OnClick(PlusBtn, function()
                    val = math.clamp(val + step, mn, mx); updVal()
                    Tween(PlusBtn,{BackgroundColor3=Theme.AccentDark},0.1)
                    task.delay(0.15,function() Tween(PlusBtn,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
                end)

                RegFlag(cfg2.Flag, api); return api
            end

            -- ─── PROGRESS BAR ───────────────────────────────
            function TObj:CreateProgressBar(cfg2)
                cfg2 = cfg2 or {}
                local val = math.clamp(cfg2.Default or 0, 0, 100)

                local c = Card(54); Pad(c, 8, 8, 12, 12)

                local TopRow = Instance.new("Frame", c)
                TopRow.Size = UDim2.new(1,0,0,20); TopRow.BackgroundTransparency=1; TopRow.BorderSizePixel=0

                local tl = Lbl(TopRow, cfg2.Title or "Progress", UDim2.new(1,-42,1,0))
                tl.Font = Enum.Font.GothamMedium; tl.TextSize = 13

                local pctLbl = Lbl(TopRow, val.."%", UDim2.new(0,40,1,0), Theme.Accent, Enum.TextXAlignment.Right)
                pctLbl.Position = UDim2.new(1,-40,0,0); pctLbl.Font = Enum.Font.GothamBold

                -- Track
                local Track = Instance.new("Frame", c)
                Track.Size = UDim2.new(1,0,0,12)
                Track.Position = UDim2.new(0,0,1,-18)
                Track.BackgroundColor3 = Theme.ToggleOff
                Track.BorderSizePixel = 0; Corner(Track, 6)

                -- Fill
                local Fill = Instance.new("Frame", Track)
                Fill.Size = UDim2.new(val/100, 0, 1, 0)
                Fill.BackgroundColor3 = Theme.Accent
                Fill.BorderSizePixel = 0; Corner(Fill, 6)

                -- Shine effect di fill
                local Shine = Instance.new("Frame", Fill)
                Shine.Size = UDim2.new(1,0,0.5,0)
                Shine.BackgroundColor3 = Color3.fromRGB(255,255,255)
                Shine.BackgroundTransparency = 0.85
                Shine.BorderSizePixel = 0; Corner(Shine, 6)

                local api = {}
                function api:Set(v)
                    val = math.clamp(v, 0, 100)
                    local p = val / 100
                    Tween(Fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.3)
                    pctLbl.Text = val .. "%"
                    -- Warna berubah: hijau saat penuh
                    if val >= 100 then
                        Tween(Fill, { BackgroundColor3 = Color3.fromRGB(34,197,94) }, 0.3)
                    elseif val >= 50 then
                        Tween(Fill, { BackgroundColor3 = Theme.Accent }, 0.3)
                    else
                        Tween(Fill, { BackgroundColor3 = Theme.Accent }, 0.3)
                    end
                    pcall(cfg2.Callback or function()end, val)
                end
                function api:Get() return val end

                RegFlag(cfg2.Flag, api); return api
            end

            -- ─── COLOR PICKER ───────────────────────────────
            function TObj:CreateColorPicker(cfg2)
                cfg2=cfg2 or {}
                local color=cfg2.Default or Color3.fromRGB(255,0,0)
                local cH,cS,cV=toHSV(color); local tH,tS,tV=cH,cS,cV; local open=false
                local c=Card(44); Pad(c,0,0,12,12)
                local tl=Lbl(c,cfg2.Title or "Color",UDim2.new(1,-60,1,0)); tl.Font=Enum.Font.GothamMedium; tl.TextSize=13
                local Swatch=Instance.new("Frame",c)
                Swatch.Size=UDim2.new(0,34,0,24); Swatch.Position=UDim2.new(1,-38,0.5,-12)
                Swatch.BackgroundColor3=color; Swatch.BorderSizePixel=0; Corner(Swatch,5); Stroke(Swatch,Theme.ElementStroke,1)
                local POP_W,POP_H=210,240
                local Pop=Instance.new("Frame",SG)
                Pop.Size=UDim2.new(0,POP_W,0,0); Pop.BackgroundColor3=Theme.ElementBG; Pop.BorderSizePixel=0
                Pop.ClipsDescendants=true; Pop.Visible=false; Pop.ZIndex=160; Corner(Pop,8); Stroke(Pop,Theme.ElementStroke,1)
                local SVBox=Instance.new("Frame",Pop)
                SVBox.Size=UDim2.new(1,-16,0,110); SVBox.Position=UDim2.new(0,8,0,8)
                SVBox.BackgroundColor3=HSV(tH,1,1); SVBox.BorderSizePixel=0; SVBox.ZIndex=161; Corner(SVBox,6)
                local WL=Instance.new("Frame",SVBox); WL.Size=UDim2.new(1,0,1,0); WL.BackgroundColor3=Color3.fromRGB(255,255,255); WL.BackgroundTransparency=0; WL.BorderSizePixel=0; WL.ZIndex=162; Corner(WL,6)
                local wg=Instance.new("UIGradient",WL); wg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}); wg.Rotation=0
                local BL=Instance.new("Frame",SVBox); BL.Size=UDim2.new(1,0,1,0); BL.BackgroundColor3=Color3.fromRGB(0,0,0); BL.BackgroundTransparency=0; BL.BorderSizePixel=0; BL.ZIndex=163; Corner(BL,6)
                local bg=Instance.new("UIGradient",BL); bg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}); bg.Rotation=90
                local SVCursor=Instance.new("Frame",SVBox); SVCursor.Size=UDim2.new(0,12,0,12); SVCursor.Position=UDim2.new(tS,-6,1-tV,-6); SVCursor.BackgroundColor3=Color3.fromRGB(255,255,255); SVCursor.BorderSizePixel=0; SVCursor.ZIndex=165; Corner(SVCursor,6); Stroke(SVCursor,Color3.fromRGB(0,0,0),1)
                local HueBar=Instance.new("Frame",Pop); HueBar.Size=UDim2.new(1,-16,0,16); HueBar.Position=UDim2.new(0,8,0,124); HueBar.BackgroundColor3=Color3.fromRGB(255,255,255); HueBar.BorderSizePixel=0; HueBar.ZIndex=161; Corner(HueBar,4)
                local HueImg=Instance.new("ImageLabel",HueBar); HueImg.Size=UDim2.new(1,0,1,0); HueImg.BackgroundTransparency=1; HueImg.BorderSizePixel=0; HueImg.Image="rbxassetid://698052001"; HueImg.ZIndex=162
                local HueCursor=Instance.new("Frame",HueBar); HueCursor.Size=UDim2.new(0,6,1,4); HueCursor.Position=UDim2.new(tH,-3,0,-2); HueCursor.BackgroundColor3=Color3.fromRGB(255,255,255); HueCursor.BorderSizePixel=0; HueCursor.ZIndex=163; Corner(HueCursor,3); Stroke(HueCursor,Color3.fromRGB(0,0,0),1)
                local HexFrame=Instance.new("Frame",Pop); HexFrame.Size=UDim2.new(1,-16,0,26); HexFrame.Position=UDim2.new(0,8,0,148); HexFrame.BackgroundColor3=Theme.WindowBG; HexFrame.BorderSizePixel=0; HexFrame.ZIndex=161; Corner(HexFrame,5); Stroke(HexFrame,Theme.ElementStroke,1)
                local HexPre=Lbl(HexFrame,"#",UDim2.new(0,16,1,0),Theme.TextMuted,Enum.TextXAlignment.Center); HexPre.TextSize=11; HexPre.Font=Enum.Font.GothamBold; HexPre.ZIndex=162
                local HexLbl=Lbl(HexFrame,toHex(color),UDim2.new(1,-18,1,0),Theme.TextPrimary); HexLbl.Position=UDim2.new(0,18,0,0); HexLbl.TextSize=11; HexLbl.Font=Enum.Font.GothamBold; HexLbl.ZIndex=162
                local BotPrev=Instance.new("Frame",Pop); BotPrev.Size=UDim2.new(1,-16,0,14); BotPrev.Position=UDim2.new(0,8,0,180); BotPrev.BackgroundColor3=color; BotPrev.BorderSizePixel=0; BotPrev.ZIndex=161; Corner(BotPrev,4)
                local BtnRow=Instance.new("Frame",Pop); BtnRow.Size=UDim2.new(1,-16,0,28); BtnRow.Position=UDim2.new(0,8,0,200); BtnRow.BackgroundTransparency=1; BtnRow.BorderSizePixel=0; BtnRow.ZIndex=161
                local OKBtn=Instance.new("TextButton",BtnRow); OKBtn.Size=UDim2.new(0.5,-3,1,0); OKBtn.BackgroundColor3=Theme.Accent; OKBtn.BorderSizePixel=0; OKBtn.Text="OK"; OKBtn.TextSize=12; OKBtn.Font=Enum.Font.GothamBold; OKBtn.TextColor3=Color3.fromRGB(255,255,255); OKBtn.AutoButtonColor=false; OKBtn.ZIndex=162; Corner(OKBtn,6)
                local CancelBtn=Instance.new("TextButton",BtnRow); CancelBtn.Size=UDim2.new(0.5,-3,1,0); CancelBtn.Position=UDim2.new(0.5,3,0,0); CancelBtn.BackgroundColor3=Theme.ElementBGHover; CancelBtn.BorderSizePixel=0; CancelBtn.Text="Batal"; CancelBtn.TextSize=12; CancelBtn.Font=Enum.Font.GothamBold; CancelBtn.TextColor3=Theme.TextSecondary; CancelBtn.AutoButtonColor=false; CancelBtn.ZIndex=162; Corner(CancelBtn,6)
                local api={}
                local function updatePreview() local tc=HSV(tH,tS,tV); SVBox.BackgroundColor3=HSV(tH,1,1); SVCursor.Position=UDim2.new(tS,-6,1-tV,-6); HueCursor.Position=UDim2.new(tH,-3,0,-2); HexLbl.Text=toHex(tc); BotPrev.BackgroundColor3=tc end
                local function updatePopPos() local vp=workspace.CurrentCamera.ViewportSize; local ap=Swatch.AbsolutePosition; local x=math.max(4,math.min(ap.X-POP_W+34,vp.X-POP_W-4)); local y=ap.Y+28; if y+POP_H>vp.Y-4 then y=ap.Y-POP_H-4 end; Pop.Position=UDim2.new(0,x,0,y) end
                local function closePop() open=false; Tween(Pop,{Size=UDim2.new(0,POP_W,0,0)},0.18); task.delay(0.2,function() Pop.Visible=false end) end
                OnClick(OKBtn,function() color=HSV(tH,tS,tV); cH,cS,cV=tH,tS,tV; Swatch.BackgroundColor3=color; pcall(cfg2.Callback or function()end,color); closePop() end)
                OnClick(CancelBtn,function() tH,tS,tV=cH,cS,cV; updatePreview(); closePop() end)
                local svDrag=false
                local SVBtn=Instance.new("TextButton",SVBox); SVBtn.Size=UDim2.new(1,0,1,0); SVBtn.BackgroundTransparency=1; SVBtn.BorderSizePixel=0; SVBtn.Text=""; SVBtn.ZIndex=166
                SVBtn.InputBegan:Connect(function(inp) if isDown(inp) then svDrag=true; tS=math.clamp((inp.Position.X-SVBox.AbsolutePosition.X)/SVBox.AbsoluteSize.X,0,1); tV=1-math.clamp((inp.Position.Y-SVBox.AbsolutePosition.Y)/SVBox.AbsoluteSize.Y,0,1); updatePreview() end end)
                UserInput.InputChanged:Connect(function(inp) if svDrag and isMove(inp) then tS=math.clamp((inp.Position.X-SVBox.AbsolutePosition.X)/SVBox.AbsoluteSize.X,0,1); tV=1-math.clamp((inp.Position.Y-SVBox.AbsolutePosition.Y)/SVBox.AbsoluteSize.Y,0,1); updatePreview() end end)
                UserInput.InputEnded:Connect(function(inp) if isDown(inp) then svDrag=false end end)
                local hueDrag=false
                local HueBtn=Instance.new("TextButton",HueBar); HueBtn.Size=UDim2.new(1,0,1,0); HueBtn.BackgroundTransparency=1; HueBtn.BorderSizePixel=0; HueBtn.Text=""; HueBtn.ZIndex=163
                HueBtn.InputBegan:Connect(function(inp) if isDown(inp) then hueDrag=true; tH=math.clamp((inp.Position.X-HueBar.AbsolutePosition.X)/HueBar.AbsoluteSize.X,0,1); updatePreview() end end)
                UserInput.InputChanged:Connect(function(inp) if hueDrag and isMove(inp) then tH=math.clamp((inp.Position.X-HueBar.AbsolutePosition.X)/HueBar.AbsoluteSize.X,0,1); updatePreview() end end)
                UserInput.InputEnded:Connect(function(inp) if isDown(inp) then hueDrag=false end end)
                local TogBtn=Instance.new("TextButton",c); TogBtn.Size=UDim2.new(1,0,1,0); TogBtn.BackgroundTransparency=1; TogBtn.BorderSizePixel=0; TogBtn.Text=""; TogBtn.AutoButtonColor=false
                OnClick(TogBtn,function() if open then tH,tS,tV=cH,cS,cV; updatePreview(); closePop() else tH,tS,tV=cH,cS,cV; updatePreview(); updatePopPos(); Pop.Visible=true; open=true; Tween(Pop,{Size=UDim2.new(0,POP_W,0,POP_H)},0.22) end end)
                TogBtn.MouseEnter:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
                TogBtn.MouseLeave:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBG},0.15) end)
                function api:Set(nc) color=nc; cH,cS,cV=toHSV(nc); Swatch.BackgroundColor3=nc; pcall(cfg2.Callback or function()end,nc) end
                function api:Get() return color end
                RegFlag(cfg2.Flag,api); return api
            end

            -- ─── KEYBIND ────────────────────────────────────
            function TObj:CreateKeybind(cfg2)
                cfg2=cfg2 or {}; local key=cfg2.Default or Enum.KeyCode.Unknown; local listening=false
                local c=Card(44); Pad(c,0,0,12,12)
                local tl=Lbl(c,cfg2.Title or "Keybind",UDim2.new(1,-90,1,0)); tl.Font=Enum.Font.GothamMedium; tl.TextSize=13
                local Badge=Instance.new("TextButton",c)
                Badge.Size=UDim2.new(0,82,0,30); Badge.Position=UDim2.new(1,-86,0.5,-15)
                Badge.BackgroundColor3=Theme.WindowBG; Badge.BorderSizePixel=0; Badge.TextSize=11; Badge.Font=Enum.Font.GothamBold; Badge.TextColor3=Theme.Accent; Badge.AutoButtonColor=false; Badge.ZIndex=5; Corner(Badge,5); Stroke(Badge,Theme.ElementStroke,1)
                local function keyName(k) local n=tostring(k):gsub("Enum.KeyCode.",""); return n=="Unknown" and "None" or n end
                Badge.Text="["..keyName(key).."]"
                local function stopListen() listening=false; Badge.TextColor3=Theme.Accent; Badge.Text="["..keyName(key).."]"; Tween(Badge,{BackgroundColor3=Theme.WindowBG},0.15) end
                OnClick(Badge,function() if listening then stopListen(); return end; listening=true; Badge.Text="[ ... ]"; Badge.TextColor3=Theme.AccentHover; Tween(Badge,{BackgroundColor3=Theme.TabHover},0.15) end)
                UserInput.InputBegan:Connect(function(inp,gp)
                    if not listening then if inp.UserInputType==Enum.UserInputType.Keyboard and inp.KeyCode==key then pcall(cfg2.Callback or function()end,key) end; return end
                    if gp then return end
                    if inp.UserInputType==Enum.UserInputType.Keyboard then if inp.KeyCode==Enum.KeyCode.Escape then stopListen(); return end; key=inp.KeyCode; stopListen(); pcall(cfg2.Callback or function()end,key) end
                end)
                Badge.MouseEnter:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
                Badge.MouseLeave:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBG},0.15) end)
                local api={}; function api:Set(k) key=k; if not listening then Badge.Text="["..keyName(k).."]" end end; function api:Get() return key end
                RegFlag(cfg2.Flag,api); return api
            end

            -- ─── SEPARATOR ──────────────────────────────────
            function TObj:AddSeparator()
                local s=Instance.new("Frame",Content)
                s.Size=UDim2.new(1,0,0,1); s.BackgroundColor3=Theme.Separator; s.BorderSizePixel=0; s.LayoutOrder=nxt()
            end

            return TObj
        end -- CreateTab

        return WObj
    end -- buildGUI

    -- ── KEY SYSTEM CHECK ────────────────────────────────────
    if useKey then
        local saved = loadSavedKey()
        if saved then
            -- Key masih valid, langsung buka GUI
            return buildGUI()
        else
            -- Tampilkan window key dulu
            local WObj = nil
            ShowKeyWindow(cfg, function()
                WObj = buildGUI()
            end)
            -- Return proxy object yang akan forward ke WObj asli setelah key valid
            -- Untuk simplicity, return dummy yang noop sampai GUI terbuka
            local proxy = setmetatable({}, {
                __index = function(_, k)
                    return function() end
                end
            })
            return proxy
        end
    else
        return buildGUI()
    end
end -- CreateWindow

return KreinGui
