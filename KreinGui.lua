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
║                      Version 2.0.0                           ║
╚══════════════════════════════════════════════════════════════╝

  FITUR v2.0:
  ✓ Button, Toggle, Slider, TextBox, Dropdown, Label
  ✓ ColorPicker  (HSV picker + hex preview)
  ✓ Keybind      (tekan tombol keyboard)
  ✓ Custom Theme (ganti tema sebelum CreateWindow)
  ✓ Save / Load Config (via writefile/readfile)
  ✓ Notify, Separator, Drag, Minimize, Close

─────────────────────────────────────────────────────────────

  QUICK START:

    local KreinGui = loadstring(game:HttpGet("URL"))()

    -- (Opsional) Custom theme sebelum CreateWindow
    KreinGui:SetTheme({
        Accent    = Color3.fromRGB(255, 100, 50),
        WindowBG  = Color3.fromRGB(20, 20, 20),
    })

    local Win = KreinGui:CreateWindow({
        Title      = "My Hub",
        SubTitle   = "v2.0",
        ConfigName = "MyHubConfig",   -- nama file config (opsional)
    })

    local Tab = Win:CreateTab("Main")

    Tab:CreateLabel("Selamat datang!")

    Tab:CreateButton({
        Title    = "Kill All",
        Callback = function() end,
    })

    local tog = Tab:CreateToggle({
        Title    = "God Mode",
        Flag     = "GodMode",        -- key untuk save/load
        Default  = false,
        Callback = function(v) end,
    })

    local sld = Tab:CreateSlider({
        Title    = "Walk Speed",
        Flag     = "WalkSpeed",
        Min      = 16, Max = 100, Default = 16,
        Callback = function(v)
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
        end,
    })

    Tab:CreateTextBox({
        Title       = "Target",
        Flag        = "TargetName",
        Placeholder = "Nama...",
        Callback    = function(v) end,
    })

    Tab:CreateDropdown({
        Title    = "Tim",
        Flag     = "Team",
        Options  = {"Merah","Biru","Hijau"},
        Default  = "Merah",
        Callback = function(v) end,
    })

    local cp = Tab:CreateColorPicker({
        Title    = "Warna ESP",
        Flag     = "ESPColor",
        Default  = Color3.fromRGB(255, 0, 0),
        Callback = function(color) end,
    })

    Tab:CreateKeybind({
        Title    = "Toggle GUI",
        Flag     = "ToggleKey",
        Default  = Enum.KeyCode.RightShift,
        Callback = function(key) end,
    })

    Tab:AddSeparator()

    -- Save & Load manual
    Win:SaveConfig()
    Win:LoadConfig()

    -- Auto-load saat start (jika ConfigName diset)
    -- Win:LoadConfig()

    Win:Notify("GUI loaded!", 3)

--]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")
local HttpService  = game:GetService("HttpService")

local LocalPlayer  = Players.LocalPlayer

-- ============================================================
-- DEFAULT THEME
-- ============================================================
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
}

-- Preset tema bawaan
local Presets = {
    Default = {
        Accent   = Color3.fromRGB(99, 102, 241),
        ToggleOn = Color3.fromRGB(99, 102, 241),
        TabActive= Color3.fromRGB(99, 102, 241),
        WindowBG = Color3.fromRGB(28, 28, 32),
        HeaderBG = Color3.fromRGB(22, 22, 26),
    },
    Rose = {
        Accent   = Color3.fromRGB(244, 63, 94),
        ToggleOn = Color3.fromRGB(244, 63, 94),
        TabActive= Color3.fromRGB(244, 63, 94),
        WindowBG = Color3.fromRGB(30, 20, 24),
        HeaderBG = Color3.fromRGB(22, 14, 18),
    },
    Emerald = {
        Accent   = Color3.fromRGB(16, 185, 129),
        ToggleOn = Color3.fromRGB(16, 185, 129),
        TabActive= Color3.fromRGB(16, 185, 129),
        WindowBG = Color3.fromRGB(18, 28, 24),
        HeaderBG = Color3.fromRGB(12, 20, 18),
    },
    Amber = {
        Accent   = Color3.fromRGB(245, 158, 11),
        ToggleOn = Color3.fromRGB(245, 158, 11),
        TabActive= Color3.fromRGB(245, 158, 11),
        WindowBG = Color3.fromRGB(28, 24, 16),
        HeaderBG = Color3.fromRGB(22, 18, 10),
    },
    Midnight = {
        Accent   = Color3.fromRGB(139, 92, 246),
        ToggleOn = Color3.fromRGB(139, 92, 246),
        TabActive= Color3.fromRGB(139, 92, 246),
        WindowBG = Color3.fromRGB(15, 15, 25),
        HeaderBG = Color3.fromRGB(10, 10, 18),
    },
}

-- ============================================================
-- HELPERS
-- ============================================================
local function Tween(obj, props, dur, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function Corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

local function Stroke(p, col, thick)
    local s = Instance.new("UIStroke", p)
    s.Color     = col   or Theme.WindowStroke
    s.Thickness = thick or 1
    return s
end

local function Pad(p, t, b, l, r)
    local u = Instance.new("UIPadding", p)
    u.PaddingTop    = UDim.new(0, t or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.PaddingLeft   = UDim.new(0, l or 0)
    u.PaddingRight  = UDim.new(0, r or 0)
end

local function Lbl(parent, text, size, color, xa)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.BorderSizePixel        = 0
    l.Size                   = size or UDim2.new(1, 0, 1, 0)
    l.Text                   = text or ""
    l.TextSize               = 13
    l.TextColor3             = color or Theme.TextPrimary
    l.Font                   = Enum.Font.GothamMedium
    l.TextXAlignment         = xa or Enum.TextXAlignment.Left
    l.TextYAlignment         = Enum.TextYAlignment.Center
    l.TextWrapped            = true
    return l
end

local function EnableDrag(frame, handle)
    local dragging, dragStart, startPos
    handle = handle or frame
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position; startPos = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInput.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                       startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- HSV <-> RGB helpers
local function HSVtoRGB(h, s, v)
    return Color3.fromHSV(h, s, v)
end

local function RGBtoHSV(color)
    return Color3.toHSV(color)
end

local function ColorToHex(color)
    return string.format("%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255))
end

-- ============================================================
-- LIBRARY TABLE
-- ============================================================
local KreinGui    = {}
KreinGui.__index  = KreinGui
KreinGui.Flags    = {}   -- global flag store untuk save/load
KreinGui.Presets  = Presets

-- ============================================================
-- SET THEME  (panggil sebelum CreateWindow)
-- ============================================================
function KreinGui:SetTheme(overrides)
    for k, v in pairs(overrides) do
        Theme[k] = v
    end
    -- sync ToggleOn & TabActive dengan Accent jika tidak di-override terpisah
    if overrides.Accent then
        Theme.ToggleOn  = Theme.ToggleOn  == Theme.Accent and overrides.Accent or Theme.ToggleOn
        Theme.TabActive = Theme.TabActive == Theme.Accent and overrides.Accent or Theme.TabActive
        Theme.AccentHover = Color3.new(
            math.min(overrides.Accent.R + 0.1, 1),
            math.min(overrides.Accent.G + 0.1, 1),
            math.min(overrides.Accent.B + 0.1, 1)
        )
        Theme.AccentDark = Color3.new(
            overrides.Accent.R * 0.6,
            overrides.Accent.G * 0.6,
            overrides.Accent.B * 0.6
        )
    end
end

function KreinGui:UsePreset(name)
    local preset = Presets[name]
    if preset then self:SetTheme(preset) end
end

-- ============================================================
-- CREATE WINDOW
-- ============================================================
function KreinGui:CreateWindow(cfg)
    cfg = cfg or {}
    local title      = cfg.Title      or "KreinGui"
    local subtitle   = cfg.SubTitle   or ""
    local configName = cfg.ConfigName or "KreinGuiConfig"

    -- ScreenGui
    local SG = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    SG.Name           = "KreinGui"
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SG.ResetOnSpawn   = false

    -- Window Frame
    local Win = Instance.new("Frame", SG)
    Win.Name             = "Window"
    Win.Size             = UDim2.new(0, 580, 0, 350)
    Win.Position         = UDim2.new(0.5, -290, 0.5, -175)
    Win.BackgroundColor3 = Theme.WindowBG
    Win.BorderSizePixel  = 0
    Win.ClipsDescendants = true
    Corner(Win, 12)
    Stroke(Win, Theme.WindowStroke, 1)

    local grad = Instance.new("UIGradient", Win)
    grad.Color    = ColorSequence.new(Color3.fromRGB(40,40,50), Color3.fromRGB(22,22,28))
    grad.Rotation = 135

    -- ── HEADER ──────────────────────────────────────────────────
    local Header = Instance.new("Frame", Win)
    Header.Name             = "Header"
    Header.Size             = UDim2.new(1, 0, 0, 52)
    Header.BackgroundColor3 = Theme.HeaderBG
    Header.BorderSizePixel  = 0
    Header.ZIndex           = 4
    Corner(Header, 12)

    local ABar = Instance.new("Frame", Header)
    ABar.Size             = UDim2.new(1, 0, 0, 2)
    ABar.Position         = UDim2.new(0, 0, 1, -2)
    ABar.BackgroundColor3 = Theme.Accent
    ABar.BorderSizePixel  = 0
    ABar.ZIndex           = 5

    local Dot = Instance.new("Frame", Header)
    Dot.Size             = UDim2.new(0, 7, 0, 7)
    Dot.Position         = UDim2.new(0, 14, 0.5, -3)
    Dot.BackgroundColor3 = Theme.Accent
    Dot.BorderSizePixel  = 0
    Dot.ZIndex           = 5
    Corner(Dot, 4)

    local TitlePos = subtitle ~= "" and UDim2.new(0, 28, 0, 5) or UDim2.new(0, 28, 0, 0)
    local TL = Lbl(Header, title, UDim2.new(0, 300, 0, 22), Theme.TextPrimary)
    TL.Position  = TitlePos
    TL.Font      = Enum.Font.GothamBold
    TL.TextSize  = 15
    TL.ZIndex    = 5

    if subtitle ~= "" then
        local SL = Lbl(Header, subtitle, UDim2.new(0, 300, 0, 18), Theme.TextMuted)
        SL.Position = UDim2.new(0, 28, 0, 28)
        SL.Font     = Enum.Font.Gotham
        SL.TextSize = 11
        SL.ZIndex   = 5
    end

    -- Close
    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size             = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position         = UDim2.new(1, -40, 0.5, -14)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 35, 35)
    CloseBtn.BorderSizePixel  = 0
    CloseBtn.Text             = "✕"
    CloseBtn.TextSize         = 13
    CloseBtn.Font             = Enum.Font.GothamBold
    CloseBtn.TextColor3       = Theme.CloseRed
    CloseBtn.ZIndex           = 6
    CloseBtn.AutoButtonColor  = false
    Corner(CloseBtn, 6)
    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn,{BackgroundColor3=Color3.fromRGB(90,40,40)},0.15) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn,{BackgroundColor3=Color3.fromRGB(60,35,35)},0.15) end)
    CloseBtn.MouseButton1Click:Connect(function() SG:Destroy() end)

    -- Minimize
    local MinBtn = Instance.new("TextButton", Header)
    MinBtn.Size             = UDim2.new(0, 28, 0, 28)
    MinBtn.Position         = UDim2.new(1, -76, 0.5, -14)
    MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    MinBtn.BorderSizePixel  = 0
    MinBtn.Text             = "—"
    MinBtn.TextSize         = 13
    MinBtn.Font             = Enum.Font.GothamBold
    MinBtn.TextColor3       = Theme.MinimizeGray
    MinBtn.ZIndex           = 6
    MinBtn.AutoButtonColor  = false
    Corner(MinBtn, 6)
    MinBtn.MouseEnter:Connect(function() Tween(MinBtn,{BackgroundColor3=Color3.fromRGB(55,55,68)},0.15) end)
    MinBtn.MouseLeave:Connect(function() Tween(MinBtn,{BackgroundColor3=Color3.fromRGB(40,40,50)},0.15) end)
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(Win, { Size = minimized and UDim2.new(0,580,0,52) or UDim2.new(0,580,0,350) }, 0.25)
    end)

    EnableDrag(Win, Header)

    -- ── BODY ────────────────────────────────────────────────────
    local Body = Instance.new("Frame", Win)
    Body.Name               = "Body"
    Body.Size               = UDim2.new(1, 0, 1, -52)
    Body.Position           = UDim2.new(0, 0, 0, 52)
    Body.BackgroundTransparency = 1
    Body.BorderSizePixel    = 0

    local TAB_W = 135

    local TabPanel = Instance.new("Frame", Body)
    TabPanel.Size             = UDim2.new(0, TAB_W, 1, 0)
    TabPanel.BackgroundColor3 = Theme.TabPanelBG
    TabPanel.BorderSizePixel  = 0

    local Sep = Instance.new("Frame", Body)
    Sep.Size             = UDim2.new(0, 1, 1, 0)
    Sep.Position         = UDim2.new(0, TAB_W, 0, 0)
    Sep.BackgroundColor3 = Theme.Separator
    Sep.BorderSizePixel  = 0

    local TabScroll = Instance.new("ScrollingFrame", TabPanel)
    TabScroll.Size                   = UDim2.new(1, 0, 1, 0)
    TabScroll.BackgroundTransparency = 1
    TabScroll.BorderSizePixel        = 0
    TabScroll.ScrollBarThickness     = 2
    TabScroll.ScrollBarImageColor3   = Theme.Accent
    TabScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    TabScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    Pad(TabScroll, 8, 8, 6, 6)

    local TabListLayout = Instance.new("UIListLayout", TabScroll)
    TabListLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding             = UDim.new(0, 3)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ContentPanel = Instance.new("Frame", Body)
    ContentPanel.Size               = UDim2.new(1, -(TAB_W+1), 1, 0)
    ContentPanel.Position           = UDim2.new(0, TAB_W+1, 0, 0)
    ContentPanel.BackgroundTransparency = 1
    ContentPanel.BorderSizePixel    = 0
    ContentPanel.ClipsDescendants   = true

    -- ── WINDOW OBJECT ────────────────────────────────────────────
    local WObj      = {}
    local tabBtns   = {}
    local tabFrames = {}
    local active    = nil
    local flagMap   = {}   -- flag -> { Get, Set } API

    local function setActive(idx)
        if active == idx then return end
        active = idx
        for i, btn in ipairs(tabBtns) do
            local on = (i == idx)
            Tween(btn, { BackgroundColor3 = on and Theme.TabActive or Theme.TabDefault }, 0.18)
            Tween(btn:FindFirstChild("Lbl"), { TextColor3 = on and Theme.TabActiveText or Theme.TabDefaultText }, 0.18)
            local bar = btn:FindFirstChild("Bar")
            if bar then bar.Visible = on end
        end
        for i, f in ipairs(tabFrames) do f.Visible = (i == idx) end
    end

    -- ── SAVE / LOAD CONFIG ───────────────────────────────────────
    local function serializeColor(c)
        return { r = c.R, g = c.G, b = c.B }
    end
    local function deserializeColor(t)
        return Color3.new(t.r, t.g, t.b)
    end

    function WObj:SaveConfig()
        local data = {}
        for flag, api in pairs(flagMap) do
            local v = api:Get()
            if typeof(v) == "Color3" then
                data[flag] = { __type = "Color3", value = serializeColor(v) }
            elseif typeof(v) == "EnumItem" then
                data[flag] = { __type = "EnumItem", value = tostring(v) }
            else
                data[flag] = v
            end
        end
        local ok, err = pcall(function()
            writefile(configName .. ".json", HttpService:JSONEncode(data))
        end)
        if ok then
            self:Notify("Config tersimpan!", 2)
        else
            self:Notify("Gagal simpan: " .. tostring(err), 3)
        end
    end

    function WObj:LoadConfig()
        local ok, raw = pcall(readfile, configName .. ".json")
        if not ok or not raw then
            self:Notify("Config tidak ditemukan.", 2)
            return
        end
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok2 or not data then
            self:Notify("Config rusak.", 2)
            return
        end
        for flag, val in pairs(data) do
            if flagMap[flag] then
                if type(val) == "table" and val.__type == "Color3" then
                    flagMap[flag]:Set(deserializeColor(val.value))
                elseif type(val) == "table" and val.__type == "EnumItem" then
                    -- parse EnumItem dari string, contoh "Enum.KeyCode.E"
                    local parts = string.split(val.value, ".")
                    local ok3, en = pcall(function()
                        return Enum[parts[2]][parts[3]]
                    end)
                    if ok3 then flagMap[flag]:Set(en) end
                else
                    flagMap[flag]:Set(val)
                end
            end
        end
        self:Notify("Config dimuat!", 2)
    end

    -- ── NOTIFY ───────────────────────────────────────────────────
    function WObj:Notify(msg, duration)
        duration = duration or 3
        local N = Instance.new("Frame", SG)
        N.Size             = UDim2.new(0, 250, 0, 46)
        N.Position         = UDim2.new(1, 10, 1, -60)
        N.BackgroundColor3 = Theme.ElementBG
        N.BorderSizePixel  = 0
        N.ZIndex           = 100
        Corner(N, 8)
        Stroke(N, Theme.Accent, 1)

        local Bar = Instance.new("Frame", N)
        Bar.Size             = UDim2.new(0, 3, 0.7, 0)
        Bar.Position         = UDim2.new(0, 0, 0.15, 0)
        Bar.BackgroundColor3 = Theme.Accent
        Bar.BorderSizePixel  = 0
        Bar.ZIndex           = 101
        Corner(Bar, 3)

        local nl = Lbl(N, msg, UDim2.new(1, -18, 1, 0), Theme.TextPrimary)
        nl.Position    = UDim2.new(0, 14, 0, 0)
        nl.Font        = Enum.Font.Gotham
        nl.TextSize    = 12
        nl.ZIndex      = 101
        nl.TextWrapped = true

        Tween(N, { Position = UDim2.new(1, -260, 1, -60) }, 0.3)
        task.delay(duration, function()
            Tween(N, { Position = UDim2.new(1, 10, 1, -60) }, 0.3)
            task.delay(0.35, function() N:Destroy() end)
        end)
    end

    -- ── CREATE TAB ───────────────────────────────────────────────
    function WObj:CreateTab(name)
        local idx = #tabBtns + 1

        local Btn = Instance.new("TextButton", TabScroll)
        Btn.Name             = "Tab_" .. idx
        Btn.Size             = UDim2.new(1, -4, 0, 38)
        Btn.BackgroundColor3 = Theme.TabDefault
        Btn.BorderSizePixel  = 0
        Btn.Text             = ""
        Btn.LayoutOrder      = idx
        Btn.AutoButtonColor  = false
        Corner(Btn, 7)

        local Bar = Instance.new("Frame", Btn)
        Bar.Name             = "Bar"
        Bar.Size             = UDim2.new(0, 3, 0.55, 0)
        Bar.Position         = UDim2.new(0, 0, 0.225, 0)
        Bar.BackgroundColor3 = Theme.AccentHover
        Bar.BorderSizePixel  = 0
        Bar.Visible          = false
        Corner(Bar, 2)

        local BtnLbl = Lbl(Btn, name, UDim2.new(1, -14, 1, 0), Theme.TabDefaultText)
        BtnLbl.Name     = "Lbl"
        BtnLbl.Position = UDim2.new(0, 10, 0, 0)
        BtnLbl.Font     = Enum.Font.GothamMedium
        BtnLbl.TextSize = 12

        Btn.MouseEnter:Connect(function() if active ~= idx then Tween(Btn,{BackgroundColor3=Theme.TabHover},0.15) end end)
        Btn.MouseLeave:Connect(function() if active ~= idx then Tween(Btn,{BackgroundColor3=Theme.TabDefault},0.15) end end)
        Btn.MouseButton1Click:Connect(function() setActive(idx) end)
        tabBtns[idx] = Btn

        local Content = Instance.new("ScrollingFrame", ContentPanel)
        Content.Name                   = "Content_" .. idx
        Content.Size                   = UDim2.new(1, 0, 1, 0)
        Content.BackgroundTransparency = 1
        Content.BorderSizePixel        = 0
        Content.Visible                = false
        Content.ScrollBarThickness     = 3
        Content.ScrollBarImageColor3   = Theme.Accent
        Content.CanvasSize             = UDim2.new(0, 0, 0, 0)
        Content.AutomaticCanvasSize    = Enum.AutomaticSize.Y
        Pad(Content, 10, 10, 10, 10)

        local EList = Instance.new("UIListLayout", Content)
        EList.SortOrder = Enum.SortOrder.LayoutOrder
        EList.Padding   = UDim.new(0, 6)

        tabFrames[idx] = Content
        if idx == 1 then setActive(1) end

        -- ── TAB OBJECT ───────────────────────────────────────────
        local TObj  = {}
        local order = 0
        local function nxt() order = order + 1; return order end

        local function Card(h, noClip)
            local c = Instance.new("Frame", Content)
            c.Size             = UDim2.new(1, 0, 0, h or 44)
            c.BackgroundColor3 = Theme.ElementBG
            c.BorderSizePixel  = 0
            c.LayoutOrder      = nxt()
            c.ClipsDescendants = not noClip
            Corner(c, 8)
            Stroke(c, Theme.ElementStroke, 1)
            return c
        end

        local function RegFlag(flag, api)
            if flag and flag ~= "" then
                flagMap[flag] = api
                KreinGui.Flags[flag] = api
            end
        end

        -- ══════════════════════════════════════════════════════
        -- LABEL
        -- ══════════════════════════════════════════════════════
        function TObj:CreateLabel(text)
            local c = Card(36)
            Pad(c, 0, 0, 12, 12)
            local l = Lbl(c, text, UDim2.new(1,0,1,0), Theme.TextSecondary)
            l.Font     = Enum.Font.Gotham
            l.TextSize = 12
            return l
        end

        -- ══════════════════════════════════════════════════════
        -- BUTTON
        -- ══════════════════════════════════════════════════════
        function TObj:CreateButton(cfg2)
            cfg2 = cfg2 or {}
            local c = Card(44)
            Pad(c, 0, 0, 12, 12)

            local hov = Instance.new("TextButton", c)
            hov.Size = UDim2.new(1,0,1,0); hov.BackgroundTransparency=1
            hov.BorderSizePixel=0; hov.Text=""; hov.AutoButtonColor=false

            Lbl(c, cfg2.Title or "Button", UDim2.new(1,-84,1,0))

            local rb = Instance.new("TextButton", c)
            rb.Size             = UDim2.new(0, 68, 0, 28)
            rb.Position         = UDim2.new(1, -72, 0.5, -14)
            rb.BackgroundColor3 = Theme.Accent
            rb.BorderSizePixel  = 0
            rb.Text             = "Run"
            rb.TextSize         = 11
            rb.Font             = Enum.Font.GothamBold
            rb.TextColor3       = Color3.fromRGB(255,255,255)
            rb.AutoButtonColor  = false
            Corner(rb, 6)

            rb.MouseEnter:Connect(function() Tween(rb,{BackgroundColor3=Theme.AccentHover},0.15) end)
            rb.MouseLeave:Connect(function() Tween(rb,{BackgroundColor3=Theme.Accent},0.15) end)
            rb.MouseButton1Click:Connect(function()
                Tween(rb,{BackgroundColor3=Theme.AccentDark},0.1)
                task.delay(0.15,function() Tween(rb,{BackgroundColor3=Theme.Accent},0.15) end)
                pcall(cfg2.Callback or function() end)
            end)
            hov.MouseEnter:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
            hov.MouseLeave:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBG},0.15) end)
        end

        -- ══════════════════════════════════════════════════════
        -- TOGGLE
        -- ══════════════════════════════════════════════════════
        function TObj:CreateToggle(cfg2)
            cfg2 = cfg2 or {}
            local state = cfg2.Default or false
            local c     = Card(44)
            Pad(c, 0, 0, 12, 12)

            Lbl(c, cfg2.Title or "Toggle", UDim2.new(1,-60,1,0))

            local Track = Instance.new("Frame", c)
            Track.Size             = UDim2.new(0, 42, 0, 22)
            Track.Position         = UDim2.new(1, -46, 0.5, -11)
            Track.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
            Track.BorderSizePixel  = 0
            Corner(Track, 11)

            local Knob = Instance.new("Frame", Track)
            Knob.Size             = UDim2.new(0, 16, 0, 16)
            Knob.Position         = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
            Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            Knob.BorderSizePixel  = 0
            Corner(Knob, 8)

            local tb = Instance.new("TextButton", c)
            tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1
            tb.BorderSizePixel=0; tb.Text=""; tb.AutoButtonColor=false

            local api = {}
            local function upd()
                Tween(Track,{BackgroundColor3=state and Theme.ToggleOn or Theme.ToggleOff},0.18)
                Tween(Knob,{Position=state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)},0.18)
                pcall(cfg2.Callback or function() end, state)
            end
            function api:Set(v) state=v; upd() end
            function api:Get() return state end

            tb.MouseButton1Click:Connect(function() state=not state; upd() end)
            tb.MouseEnter:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
            tb.MouseLeave:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBG},0.15) end)

            RegFlag(cfg2.Flag, api)
            return api
        end

        -- ══════════════════════════════════════════════════════
        -- SLIDER
        -- ══════════════════════════════════════════════════════
        function TObj:CreateSlider(cfg2)
            cfg2 = cfg2 or {}
            local mn  = cfg2.Min     or 0
            local mx  = cfg2.Max     or 100
            local val = math.clamp(cfg2.Default or mn, mn, mx)
            local c   = Card(58)
            Pad(c, 8, 8, 12, 12)

            local TopRow = Instance.new("Frame", c)
            TopRow.Size=UDim2.new(1,0,0,20); TopRow.BackgroundTransparency=1; TopRow.BorderSizePixel=0

            local tl = Lbl(TopRow, cfg2.Title or "Slider", UDim2.new(1,-42,1,0))
            tl.Font=Enum.Font.GothamMedium; tl.TextSize=13

            local vl = Lbl(TopRow, tostring(val), UDim2.new(0,40,1,0), Theme.Accent, Enum.TextXAlignment.Right)
            vl.Position=UDim2.new(1,-40,0,0); vl.Font=Enum.Font.GothamBold

            local TBG = Instance.new("Frame", c)
            TBG.Size=UDim2.new(1,0,0,8); TBG.Position=UDim2.new(0,0,1,-16)
            TBG.BackgroundColor3=Theme.ToggleOff; TBG.BorderSizePixel=0
            Corner(TBG, 4)

            local p0 = (val-mn)/(mx-mn)
            local TFill = Instance.new("Frame", TBG)
            TFill.Size=UDim2.new(p0,0,1,0); TFill.BackgroundColor3=Theme.Accent; TFill.BorderSizePixel=0
            Corner(TFill, 4)

            local Knob = Instance.new("Frame", TBG)
            Knob.Size=UDim2.new(0,14,0,14); Knob.Position=UDim2.new(p0,-7,0.5,-7)
            Knob.BackgroundColor3=Color3.fromRGB(255,255,255); Knob.BorderSizePixel=0; Knob.ZIndex=3
            Corner(Knob, 7); Stroke(Knob, Theme.Accent, 2)

            local SBtn = Instance.new("TextButton", TBG)
            SBtn.Size=UDim2.new(1,0,0,24); SBtn.Position=UDim2.new(0,0,0.5,-12)
            SBtn.BackgroundTransparency=1; SBtn.BorderSizePixel=0; SBtn.Text=""; SBtn.ZIndex=4

            local sliding = false
            local api = {}
            local function updSlider(x)
                local r = math.clamp((x - TBG.AbsolutePosition.X) / TBG.AbsoluteSize.X, 0, 1)
                val = math.floor(mn + r*(mx-mn) + 0.5)
                local p = (val-mn)/(mx-mn)
                TFill.Size=UDim2.new(p,0,1,0); Knob.Position=UDim2.new(p,-7,0.5,-7)
                vl.Text=tostring(val)
                pcall(cfg2.Callback or function() end, val)
            end
            function api:Set(v)
                val=math.clamp(v,mn,mx)
                local p=(val-mn)/(mx-mn)
                TFill.Size=UDim2.new(p,0,1,0); Knob.Position=UDim2.new(p,-7,0.5,-7)
                vl.Text=tostring(val)
                pcall(cfg2.Callback or function()end, val)
            end
            function api:Get() return val end

            SBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true; updSlider(i.Position.X) end end)
            UserInput.InputChanged:Connect(function(i) if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then updSlider(i.Position.X) end end)
            UserInput.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end end)

            RegFlag(cfg2.Flag, api)
            return api
        end

        -- ══════════════════════════════════════════════════════
        -- TEXTBOX
        -- ══════════════════════════════════════════════════════
        function TObj:CreateTextBox(cfg2)
            cfg2 = cfg2 or {}
            local c = Card(70)
            Pad(c, 8, 8, 12, 12)

            local tl = Lbl(c, cfg2.Title or "TextBox", UDim2.new(1,0,0,20))
            tl.Font=Enum.Font.GothamMedium; tl.TextSize=13

            local IF = Instance.new("Frame", c)
            IF.Size=UDim2.new(1,0,0,30); IF.Position=UDim2.new(0,0,1,-34)
            IF.BackgroundColor3=Theme.WindowBG; IF.BorderSizePixel=0
            Corner(IF, 6)
            local ifStroke = Stroke(IF, Theme.ElementStroke, 1)

            local TB = Instance.new("TextBox", IF)
            TB.Size=UDim2.new(1,0,1,0); TB.BackgroundTransparency=1; TB.BorderSizePixel=0
            TB.Text=""; TB.PlaceholderText=cfg2.Placeholder or "Type here..."
            TB.PlaceholderColor3=Theme.TextMuted; TB.TextColor3=Theme.TextPrimary
            TB.TextSize=12; TB.Font=Enum.Font.Gotham
            TB.TextXAlignment=Enum.TextXAlignment.Left; TB.ClearTextOnFocus=false
            Pad(TB, 0, 0, 8, 8)

            TB.Focused:Connect(function() ifStroke.Color = Theme.Accent end)
            TB.FocusLost:Connect(function(enter) ifStroke.Color=Theme.ElementStroke; if enter then pcall(cfg2.Callback or function()end, TB.Text) end end)

            local api = {}
            function api:Set(v) TB.Text = tostring(v) end
            function api:Get() return TB.Text end

            RegFlag(cfg2.Flag, api)
            return api
        end

        -- ══════════════════════════════════════════════════════
        -- DROPDOWN
        -- ══════════════════════════════════════════════════════
        function TObj:CreateDropdown(cfg2)
            cfg2 = cfg2 or {}
            local opts = cfg2.Options or {}
            local sel  = cfg2.Default or (opts[1] or "")
            local open = false

            local c = Card(44, true)
            c.ZIndex = 10
            Pad(c, 0, 0, 12, 12)

            local tl = Lbl(c, cfg2.Title or "Dropdown", UDim2.new(1,-100,1,0))
            tl.Font=Enum.Font.GothamMedium; tl.TextSize=13; tl.ZIndex=11

            local SF = Instance.new("Frame", c)
            SF.Size=UDim2.new(0,90,0,28); SF.Position=UDim2.new(1,-90,0.5,-14)
            SF.BackgroundColor3=Theme.WindowBG; SF.BorderSizePixel=0; SF.ZIndex=11
            Corner(SF, 6); Stroke(SF, Theme.ElementStroke, 1)

            local SL = Lbl(SF, sel, UDim2.new(1,-18,1,0), Theme.TextPrimary)
            SL.Position=UDim2.new(0,6,0,0); SL.Font=Enum.Font.Gotham; SL.TextSize=11; SL.ZIndex=12

            local Arrow = Lbl(SF, "▾", UDim2.new(0,14,1,0), Theme.TextMuted, Enum.TextXAlignment.Center)
            Arrow.Position=UDim2.new(1,-16,0,0); Arrow.TextSize=12; Arrow.ZIndex=12

            local optH = 28
            local DF = Instance.new("Frame", c)
            DF.Size=UDim2.new(0,90,0,0); DF.Position=UDim2.new(1,-90,1,4)
            DF.BackgroundColor3=Theme.ElementBG; DF.BorderSizePixel=0
            DF.ClipsDescendants=true; DF.Visible=false; DF.ZIndex=20
            Corner(DF, 6); Stroke(DF, Theme.ElementStroke, 1)

            local DL=Instance.new("UIListLayout",DF)
            DL.SortOrder=Enum.SortOrder.LayoutOrder; DL.Padding=UDim.new(0,2)
            Pad(DF, 4, 4, 4, 4)

            for i, opt in ipairs(opts) do
                local ob = Instance.new("TextButton", DF)
                ob.Size=UDim2.new(1,0,0,optH-2); ob.BackgroundColor3=Theme.ElementBG
                ob.BorderSizePixel=0; ob.Text=opt; ob.TextSize=11; ob.Font=Enum.Font.Gotham
                ob.TextColor3=Theme.TextSecondary; ob.TextXAlignment=Enum.TextXAlignment.Left
                ob.AutoButtonColor=false; ob.ZIndex=21; ob.LayoutOrder=i
                Corner(ob, 4); Pad(ob, 0, 0, 6, 0)
                ob.MouseEnter:Connect(function() Tween(ob,{BackgroundColor3=Theme.TabHover},0.12) end)
                ob.MouseLeave:Connect(function() Tween(ob,{BackgroundColor3=Theme.ElementBG},0.12) end)
                ob.MouseButton1Click:Connect(function()
                    sel=opt; SL.Text=opt; open=false; DF.Visible=false; Arrow.Text="▾"
                    pcall(cfg2.Callback or function()end, sel)
                end)
            end

            local totalH = #opts * optH + 8

            local TB2 = Instance.new("TextButton", c)
            TB2.Size=UDim2.new(1,0,1,0); TB2.BackgroundTransparency=1
            TB2.BorderSizePixel=0; TB2.Text=""; TB2.ZIndex=12; TB2.AutoButtonColor=false

            TB2.MouseButton1Click:Connect(function()
                open = not open
                if open then DF.Visible=true; Tween(DF,{Size=UDim2.new(0,90,0,totalH)},0.2); Arrow.Text="▴"
                else Tween(DF,{Size=UDim2.new(0,90,0,0)},0.15); Arrow.Text="▾"; task.delay(0.16,function() DF.Visible=false end)
                end
            end)
            TB2.MouseEnter:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
            TB2.MouseLeave:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBG},0.15) end)

            local api = {}
            function api:Set(v) sel=v; SL.Text=v; pcall(cfg2.Callback or function()end,v) end
            function api:Get() return sel end

            RegFlag(cfg2.Flag, api)
            return api
        end

        -- ══════════════════════════════════════════════════════
        -- COLOR PICKER
        -- ══════════════════════════════════════════════════════
        function TObj:CreateColorPicker(cfg2)
            cfg2 = cfg2 or {}
            local color   = cfg2.Default or Color3.fromRGB(255, 0, 0)
            local h, s, v = RGBtoHSV(color)
            local open    = false

            -- Card utama (collapsed)
            local c = Card(44, true)
            c.ZIndex = 15
            Pad(c, 0, 0, 12, 12)

            local tl = Lbl(c, cfg2.Title or "Color", UDim2.new(1,-60,1,0))
            tl.Font=Enum.Font.GothamMedium; tl.TextSize=13; tl.ZIndex=16

            -- Preview swatch
            local Swatch = Instance.new("Frame", c)
            Swatch.Size             = UDim2.new(0, 32, 0, 22)
            Swatch.Position         = UDim2.new(1, -38, 0.5, -11)
            Swatch.BackgroundColor3 = color
            Swatch.BorderSizePixel  = 0
            Swatch.ZIndex           = 16
            Corner(Swatch, 5)
            Stroke(Swatch, Theme.ElementStroke, 1)

            -- ── Picker popup ───────────────────────────────────
            local POP_W, POP_H = 200, 195
            local Pop = Instance.new("Frame", c)
            Pop.Name             = "Popup"
            Pop.Size             = UDim2.new(0, POP_W, 0, 0)
            Pop.Position         = UDim2.new(1, -POP_W, 1, 6)
            Pop.BackgroundColor3 = Theme.ElementBG
            Pop.BorderSizePixel  = 0
            Pop.ClipsDescendants = true
            Pop.Visible          = false
            Pop.ZIndex           = 30
            Corner(Pop, 8)
            Stroke(Pop, Theme.ElementStroke, 1)

            -- SV Gradient box (Saturation-Value)
            local SVBox = Instance.new("Frame", Pop)
            SVBox.Size             = UDim2.new(1, -16, 0, 110)
            SVBox.Position         = UDim2.new(0, 8, 0, 8)
            SVBox.BackgroundColor3 = HSVtoRGB(h, 1, 1)
            SVBox.BorderSizePixel  = 0
            SVBox.ZIndex           = 31
            Corner(SVBox, 6)

            -- White gradient (left-right: sat 0→1)
            local wg = Instance.new("UIGradient", SVBox)
            wg.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255,0) ~= Color3.fromRGB(255,255,255) and Color3.fromRGB(255,255,255) or Color3.fromRGB(255,255,255))
            -- actually we build two overlapping frames:
            local SVWhite = Instance.new("Frame", SVBox)
            SVWhite.Size=UDim2.new(1,0,1,0); SVWhite.BackgroundTransparency=1; SVWhite.BorderSizePixel=0; SVWhite.ZIndex=32
            local wGrad = Instance.new("UIGradient", SVWhite)
            wGrad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.new(1,1,1))
            -- override with proper white->transparent
            wGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
                ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
            })
            -- we use two frames with gradients to simulate HSV box
            local SVBlack = Instance.new("Frame", SVBox)
            SVBlack.Size=UDim2.new(1,0,1,0); SVBlack.BackgroundTransparency=1; SVBlack.BorderSizePixel=0; SVBlack.ZIndex=33
            local bGrad = Instance.new("UIGradient", SVBlack)
            bGrad.Rotation = 90
            bGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
            })

            -- Rebuild SV box properly
            SVWhite:Destroy(); SVBlack:Destroy()
            wg:Destroy()

            -- Proper SV square using ImageLabel trick
            local SVImg = Instance.new("ImageLabel", SVBox)
            SVImg.Size=UDim2.new(1,0,1,0); SVImg.BackgroundTransparency=1; SVImg.BorderSizePixel=0
            SVImg.Image="rbxassetid://4155801252"  -- white->transparent gradient
            SVImg.ZIndex=32

            local SVDark = Instance.new("ImageLabel", SVBox)
            SVDark.Size=UDim2.new(1,0,1,0); SVDark.BackgroundTransparency=1; SVDark.BorderSizePixel=0
            SVDark.Image="rbxassetid://4155801252"
            SVDark.ImageColor3=Color3.new(0,0,0)
            SVDark.Rotation=90
            SVDark.ZIndex=33

            -- SV cursor
            local SVCursor = Instance.new("Frame", SVBox)
            SVCursor.Size=UDim2.new(0,10,0,10)
            SVCursor.Position=UDim2.new(s,-5,1-v,-5)
            SVCursor.BackgroundColor3=Color3.fromRGB(255,255,255)
            SVCursor.BorderSizePixel=0; SVCursor.ZIndex=34
            Corner(SVCursor, 5)
            Stroke(SVCursor, Color3.fromRGB(0,0,0), 1)

            -- Hue bar
            local HueBar = Instance.new("Frame", Pop)
            HueBar.Size=UDim2.new(1,-16,0,14); HueBar.Position=UDim2.new(0,8,0,124)
            HueBar.BackgroundColor3=Color3.fromRGB(255,255,255); HueBar.BorderSizePixel=0; HueBar.ZIndex=31
            Corner(HueBar, 4)

            local HueImg = Instance.new("ImageLabel", HueBar)
            HueImg.Size=UDim2.new(1,0,1,0); HueImg.BackgroundTransparency=1; HueImg.BorderSizePixel=0
            HueImg.Image="rbxassetid://698052001"  -- hue rainbow bar
            HueImg.ZIndex=32

            -- Hue cursor
            local HueCursor = Instance.new("Frame", HueBar)
            HueCursor.Size=UDim2.new(0,6,1,4); HueCursor.Position=UDim2.new(h,-3,0,-2)
            HueCursor.BackgroundColor3=Color3.fromRGB(255,255,255); HueCursor.BorderSizePixel=0; HueCursor.ZIndex=33
            Corner(HueCursor, 3)
            Stroke(HueCursor, Color3.fromRGB(0,0,0), 1)

            -- Hex display
            local HexFrame = Instance.new("Frame", Pop)
            HexFrame.Size=UDim2.new(1,-16,0,24); HexFrame.Position=UDim2.new(0,8,0,144)
            HexFrame.BackgroundColor3=Theme.WindowBG; HexFrame.BorderSizePixel=0; HexFrame.ZIndex=31
            Corner(HexFrame, 5)
            Stroke(HexFrame, Theme.ElementStroke, 1)

            local HexPre = Lbl(HexFrame, "#", UDim2.new(0,14,1,0), Theme.TextMuted, Enum.TextXAlignment.Center)
            HexPre.TextSize=11; HexPre.Font=Enum.Font.GothamBold; HexPre.ZIndex=32

            local HexLbl = Lbl(HexFrame, ColorToHex(color), UDim2.new(1,-18,1,0), Theme.TextPrimary)
            HexLbl.Position=UDim2.new(0,18,0,0); HexLbl.TextSize=11; HexLbl.Font=Enum.Font.GothamBold; HexLbl.ZIndex=32

            -- Preview bottom
            local BotPrev = Instance.new("Frame", Pop)
            BotPrev.Size=UDim2.new(1,-16,0,16); BotPrev.Position=UDim2.new(0,8,0,172)
            BotPrev.BackgroundColor3=color; BotPrev.BorderSizePixel=0; BotPrev.ZIndex=31
            Corner(BotPrev, 4)

            -- ── Update function ─────────────────────────────────
            local api = {}
            local function updateColor()
                color = HSVtoRGB(h, s, v)
                Swatch.BackgroundColor3   = color
                SVBox.BackgroundColor3    = HSVtoRGB(h, 1, 1)
                SVCursor.Position         = UDim2.new(s, -5, 1-v, -5)
                HueCursor.Position        = UDim2.new(h, -3, 0, -2)
                HexLbl.Text               = ColorToHex(color)
                BotPrev.BackgroundColor3  = color
                pcall(cfg2.Callback or function() end, color)
            end

            -- SV interaction
            local svDragging = false
            local SVBtn = Instance.new("TextButton", SVBox)
            SVBtn.Size=UDim2.new(1,0,1,0); SVBtn.BackgroundTransparency=1
            SVBtn.BorderSizePixel=0; SVBtn.Text=""; SVBtn.ZIndex=35

            SVBtn.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    svDragging=true
                    local rx=math.clamp((i.Position.X-SVBox.AbsolutePosition.X)/SVBox.AbsoluteSize.X,0,1)
                    local ry=math.clamp((i.Position.Y-SVBox.AbsolutePosition.Y)/SVBox.AbsoluteSize.Y,0,1)
                    s=rx; v=1-ry; updateColor()
                end
            end)
            UserInput.InputChanged:Connect(function(i)
                if svDragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                    local rx=math.clamp((i.Position.X-SVBox.AbsolutePosition.X)/SVBox.AbsoluteSize.X,0,1)
                    local ry=math.clamp((i.Position.Y-SVBox.AbsolutePosition.Y)/SVBox.AbsoluteSize.Y,0,1)
                    s=rx; v=1-ry; updateColor()
                end
            end)
            UserInput.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then svDragging=false end
            end)

            -- Hue interaction
            local hueDragging = false
            local HueBtn = Instance.new("TextButton", HueBar)
            HueBtn.Size=UDim2.new(1,0,1,0); HueBtn.BackgroundTransparency=1
            HueBtn.BorderSizePixel=0; HueBtn.Text=""; HueBtn.ZIndex=34

            HueBtn.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    hueDragging=true
                    h=math.clamp((i.Position.X-HueBar.AbsolutePosition.X)/HueBar.AbsoluteSize.X,0,1)
                    updateColor()
                end
            end)
            UserInput.InputChanged:Connect(function(i)
                if hueDragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                    h=math.clamp((i.Position.X-HueBar.AbsolutePosition.X)/HueBar.AbsoluteSize.X,0,1)
                    updateColor()
                end
            end)
            UserInput.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then hueDragging=false end
            end)

            -- Toggle open/close
            local TogBtn = Instance.new("TextButton", c)
            TogBtn.Size=UDim2.new(1,0,1,0); TogBtn.BackgroundTransparency=1
            TogBtn.BorderSizePixel=0; TogBtn.Text=""; TogBtn.ZIndex=17; TogBtn.AutoButtonColor=false

            TogBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    Pop.Visible=true
                    Tween(Pop,{Size=UDim2.new(0,POP_W,0,POP_H)},0.22)
                else
                    Tween(Pop,{Size=UDim2.new(0,POP_W,0,0)},0.18)
                    task.delay(0.2,function() Pop.Visible=false end)
                end
            end)
            TogBtn.MouseEnter:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
            TogBtn.MouseLeave:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBG},0.15) end)

            function api:Set(newColor)
                color=newColor; h,s,v=RGBtoHSV(newColor); updateColor()
            end
            function api:Get() return color end

            RegFlag(cfg2.Flag, api)
            return api
        end

        -- ══════════════════════════════════════════════════════
        -- KEYBIND
        -- ══════════════════════════════════════════════════════
        function TObj:CreateKeybind(cfg2)
            cfg2 = cfg2 or {}
            local key      = cfg2.Default  or Enum.KeyCode.Unknown
            local listening= false

            local c = Card(44)
            Pad(c, 0, 0, 12, 12)

            local tl = Lbl(c, cfg2.Title or "Keybind", UDim2.new(1,-90,1,0))
            tl.Font=Enum.Font.GothamMedium; tl.TextSize=13

            -- Key display badge
            local Badge = Instance.new("TextButton", c)
            Badge.Size             = UDim2.new(0, 78, 0, 26)
            Badge.Position         = UDim2.new(1, -82, 0.5, -13)
            Badge.BackgroundColor3 = Theme.WindowBG
            Badge.BorderSizePixel  = 0
            Badge.TextSize         = 11
            Badge.Font             = Enum.Font.GothamBold
            Badge.TextColor3       = Theme.Accent
            Badge.AutoButtonColor  = false
            Badge.ZIndex           = 5
            Corner(Badge, 5)
            Stroke(Badge, Theme.ElementStroke, 1)

            local function keyName(k)
                local n = tostring(k):gsub("Enum.KeyCode.","")
                return n == "Unknown" and "None" or n
            end
            Badge.Text = "[" .. keyName(key) .. "]"

            local function stopListen()
                listening = false
                Badge.TextColor3 = Theme.Accent
                Badge.Text = "[" .. keyName(key) .. "]"
                Tween(Badge, {BackgroundColor3=Theme.WindowBG}, 0.15)
            end

            Badge.MouseButton1Click:Connect(function()
                if listening then stopListen(); return end
                listening = true
                Badge.Text = "[ ... ]"
                Badge.TextColor3 = Theme.AccentHover
                Tween(Badge, {BackgroundColor3=Theme.TabHover}, 0.15)
            end)

            UserInput.InputBegan:Connect(function(inp, gp)
                if not listening then
                    -- trigger callback when key pressed
                    if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key then
                        pcall(cfg2.Callback or function() end, key)
                    end
                    return
                end
                if gp then return end
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    if inp.KeyCode == Enum.KeyCode.Escape then
                        stopListen(); return
                    end
                    key = inp.KeyCode
                    stopListen()
                    pcall(cfg2.Callback or function() end, key)
                end
            end)

            Badge.MouseEnter:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBGHover},0.15) end)
            Badge.MouseLeave:Connect(function() Tween(c,{BackgroundColor3=Theme.ElementBG},0.15) end)

            local api = {}
            function api:Set(k) key=k; if not listening then Badge.Text="["..keyName(k).."]" end end
            function api:Get() return key end

            RegFlag(cfg2.Flag, api)
            return api
        end

        -- ══════════════════════════════════════════════════════
        -- SEPARATOR
        -- ══════════════════════════════════════════════════════
        function TObj:AddSeparator()
            local s = Instance.new("Frame", Content)
            s.Size=UDim2.new(1,0,0,1); s.BackgroundColor3=Theme.Separator
            s.BorderSizePixel=0; s.LayoutOrder=nxt()
        end

        return TObj
    end -- CreateTab

    return WObj
end -- CreateWindow

return KreinGui
