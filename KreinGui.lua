--[[
╔══════════════════════════════════════════════════════════════╗
║   ██╗  ██╗██████╗ ███████╗██╗███╗   ██╗ ██████╗ ██╗        ║
║   ██║ ██╔╝██╔══██╗██╔════╝██║████╗  ██║██╔════╝ ██║        ║
║   █████╔╝ ██████╔╝█████╗  ██║██╔██╗ ██║██║  ███╗██║        ║
║   ██╔═██╗ ██╔══██╗██╔══╝  ██║██║╚██╗██║██║   ██║██║        ║
║   ██║  ██╗██║  ██║███████╗██║██║ ╚████║╚██████╔╝██║        ║
║   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝        ║
║           GUI Library  —  by @uniquadev  v4.1.0              ║
╚══════════════════════════════════════════════════════════════╝

  QUICK START:

    local KreinGui = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/LippTz/KreinGuiLibrary/refs/heads/main/KreinGui.lua"
    ))()

    -- Opsional tema
    KreinGui:SetTheme({ Accent = Color3.fromRGB(99,102,241) })
    -- KreinGui:UsePreset("Rose") -- Rose/Emerald/Amber/Midnight

    local Win = KreinGui:CreateWindow({
        Title      = "My Hub",
        SubTitle   = "v1.0",
        ConfigName = "MyHubConfig",
    })

    local Tab = Win:CreateTab("Main")
    Tab:CreateSectionHeader("Settings")
    Tab:CreateButton({ Title="Do Something", Callback=function() end })
    Tab:CreateToggle({ Title="God Mode", Flag="god", Default=false, Callback=function(v) end })
    Tab:CreateSlider({ Title="WalkSpeed", Flag="ws", Min=16, Max=100, Default=16, Callback=function(v) end })
    Tab:CreateInputNumber({ Title="JumpPower", Flag="jp", Min=0, Max=200, Default=50, Step=5, Callback=function(v) end })
    Tab:CreateTextBox({ Title="Target", Flag="target", Placeholder="Nama...", Callback=function(v) end })
    Tab:CreateDropdown({ Title="Team", Flag="team", Options={"Red","Blue","Green"}, Default="Red", Callback=function(v) end })

    local Tab2 = Win:CreateTab("Visual")
    Tab2:CreateColorPicker({ Title="Color", Flag="col", Default=Color3.fromRGB(255,0,0), Callback=function(c) end })
    Tab2:CreateKeybind({ Title="Toggle GUI", Flag="key", Default=Enum.KeyCode.RightShift, Callback=function(k) end })

    local bar = Tab2:CreateProgressBar({ Title="Progress", Default=0 })
    bar:Set(75)

    Win:Notify("Loaded!", 3)

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
    btn.InputBegan:Connect(function(i)
        if isDown(i) then down=true; sp=i.Position end
    end)
    btn.InputEnded:Connect(function(i)
        if isDown(i) and down then
            down=false
            if sp and (i.Position-sp).Magnitude <= 12 then fn() end
        end
    end)
    btn.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch and sp then
            if (i.Position-sp).Magnitude > 12 then down=false end
        end
    end)
end

-- ============================================================
-- THEME
-- ============================================================
-- ICE WHITE THEME
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
    TweenService:Create(o,TweenInfo.new(d or .2,s or Enum.EasingStyle.Quart,dr or Enum.EasingDirection.Out),p):Play()
end
local function Cor(p,r) local c=Instance.new("UICorner",p);c.CornerRadius=UDim.new(0,r or 8);return c end
local function Str(p,c,t) local s=Instance.new("UIStroke",p);s.Color=c or T.WinStr;s.Thickness=t or 1;return s end
local function Pad(p,a,b,l,r)
    local u=Instance.new("UIPadding",p)
    u.PaddingTop=UDim.new(0,a or 0);u.PaddingBottom=UDim.new(0,b or 0)
    u.PaddingLeft=UDim.new(0,l or 0);u.PaddingRight=UDim.new(0,r or 0)
end
local function Lbl(par,txt,sz,col,xa)
    local l=Instance.new("TextLabel",par)
    l.BackgroundTransparency=1;l.BorderSizePixel=0
    l.Size=sz or UDim2.new(1,0,1,0);l.Text=txt or ""
    l.TextSize=13;l.TextColor3=col or T.TextPri
    l.Font=Enum.Font.GothamMedium
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Center
    l.TextWrapped=true
    return l
end
local function EnableDrag(f,h)
    h=h or f
    local drag,sp,sf,mv=false,nil,nil,false
    h.InputBegan:Connect(function(i)
        if isDown(i) then drag=true;mv=false;sp=i.Position;sf=f.Position end
    end)
    UserInput.InputChanged:Connect(function(i)
        if not drag or not sp then return end
        if isMove(i) then
            local d=i.Position-sp
            if d.Magnitude>6 then mv=true end
            if mv then f.Position=UDim2.new(sf.X.Scale,sf.X.Offset+d.X,sf.Y.Scale,sf.Y.Offset+d.Y) end
        end
    end)
    UserInput.InputEnded:Connect(function(i) if isDown(i) then drag=false end end)
end
local function HSV(h,s,v) return Color3.fromHSV(h,s,v) end
local function toHSV(c) return Color3.toHSV(c) end
local function toHex(c) return string.format("%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255)) end

-- ============================================================
-- SNAKE ABAR ANIMATION
-- ============================================================
local function StartSnake(abar, accent)
    -- Glow di bawah abar
    local Glow = Instance.new("Frame", abar.Parent)
    Glow.Name = "ABarGlow"
    Glow.Size = UDim2.new(1,0,0,10)
    Glow.Position = UDim2.new(0,0,0,50)
    Glow.BackgroundColor3 = accent
    Glow.BackgroundTransparency = 0.7
    Glow.BorderSizePixel = 0
    Glow.ZIndex = 2
    Instance.new("UICorner",Glow).CornerRadius = UDim.new(1,0)

    -- Snake highlight yang berjalan
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
    RunService.Heartbeat:Connect(function(dt)
        if not abar or not abar.Parent then return end
        t = (t + dt * 0.55) % 1
        Snake.Position = UDim2.new(t - 0.4, 0, 0, 0)
        Glow.BackgroundTransparency = 0.6 + math.abs(math.sin(t * math.pi * 2)) * 0.3
    end)
end

-- ============================================================
-- LOADING SCREEN ANIMATION
-- ============================================================
local function ShowLoading(SG, accent, title, onDone)
    -- Overlay gelap penuh
    local Overlay = Instance.new("Frame", SG)
    Overlay.Size = UDim2.new(1,0,1,0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
    Overlay.BackgroundTransparency = 0
    Overlay.BorderSizePixel = 0
    Overlay.ZIndex = 100

    -- Container tengah
    local Box = Instance.new("Frame", Overlay)
    Box.Size = UDim2.new(0,300,0,160)
    Box.Position = UDim2.new(0.5,-150,0.5,-80)
    Box.BackgroundColor3 = Color3.fromRGB(8,8,14)
    Box.BorderSizePixel = 0
    Box.ZIndex = 101
    Instance.new("UICorner",Box).CornerRadius = UDim.new(0,16)
    local bs = Instance.new("UIStroke",Box)
    bs.Color = accent; bs.Thickness = 1.5

    -- Glow effect di border
    local BGlow = Instance.new("UIStroke",Box)
    BGlow.Color = accent; BGlow.Thickness = 4
    BGlow.Transparency = 0.7

    -- Logo / Title teks
    local TitleLbl = Instance.new("TextLabel", Box)
    TitleLbl.Size = UDim2.new(1,0,0,36)
    TitleLbl.Position = UDim2.new(0,0,0,24)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.BorderSizePixel = 0
    TitleLbl.Text = title
    TitleLbl.TextSize = 18
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextColor3 = accent
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Center
    TitleLbl.ZIndex = 102

    -- Subtitle
    local SubLbl = Instance.new("TextLabel", Box)
    SubLbl.Size = UDim2.new(1,0,0,20)
    SubLbl.Position = UDim2.new(0,0,0,58)
    SubLbl.BackgroundTransparency = 1
    SubLbl.BorderSizePixel = 0
    SubLbl.Text = "Initializing..."
    SubLbl.TextSize = 11
    SubLbl.Font = Enum.Font.Gotham
    SubLbl.TextColor3 = Color3.new(accent.R*0.6, accent.G*0.6, accent.B*0.6)
    SubLbl.TextXAlignment = Enum.TextXAlignment.Center
    SubLbl.ZIndex = 102

    -- Progress bar track
    local BarTrack = Instance.new("Frame", Box)
    BarTrack.Size = UDim2.new(0,220,0,4)
    BarTrack.Position = UDim2.new(0.5,-110,0,100)
    BarTrack.BackgroundColor3 = Color3.fromRGB(20,20,32)
    BarTrack.BorderSizePixel = 0
    BarTrack.ZIndex = 102
    Instance.new("UICorner",BarTrack).CornerRadius = UDim.new(1,0)

    -- Progress bar fill
    local BarFill = Instance.new("Frame", BarTrack)
    BarFill.Size = UDim2.new(0,0,1,0)
    BarFill.BackgroundColor3 = accent
    BarFill.BorderSizePixel = 0
    BarFill.ZIndex = 103
    Instance.new("UICorner",BarFill).CornerRadius = UDim.new(1,0)

    -- Snake glow pada progress bar
    local BarSnake = Instance.new("Frame", BarFill)
    BarSnake.Size = UDim2.new(0.5,0,1,0)
    BarSnake.BackgroundColor3 = Color3.fromRGB(255,255,255)
    BarSnake.BackgroundTransparency = 0.5
    BarSnake.BorderSizePixel = 0
    BarSnake.ZIndex = 104
    Instance.new("UICorner",BarSnake).CornerRadius = UDim.new(1,0)
    local bsg = Instance.new("UIGradient", BarSnake)
    bsg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(0.5,0.3),
        NumberSequenceKeypoint.new(1,1),
    })

    -- Percent label
    local PctLbl = Instance.new("TextLabel", Box)
    PctLbl.Size = UDim2.new(1,0,0,18)
    PctLbl.Position = UDim2.new(0,0,0,116)
    PctLbl.BackgroundTransparency = 1
    PctLbl.BorderSizePixel = 0
    PctLbl.Text = "0%"
    PctLbl.TextSize = 10
    PctLbl.Font = Enum.Font.GothamBold
    PctLbl.TextColor3 = Color3.new(accent.R*0.7, accent.G*0.7, accent.B*0.7)
    PctLbl.TextXAlignment = Enum.TextXAlignment.Center
    PctLbl.ZIndex = 102

    -- Dots animasi (3 titik berkedip)
    local dots = {}
    local dotY = 138
    for i = 1,3 do
        local d = Instance.new("Frame", Box)
        d.Size = UDim2.new(0,5,0,5)
        d.Position = UDim2.new(0.5,(i-2)*14-2,0,dotY)
        d.BackgroundColor3 = accent
        d.BackgroundTransparency = 0.3
        d.BorderSizePixel = 0
        d.ZIndex = 102
        Instance.new("UICorner",d).CornerRadius = UDim.new(1,0)
        dots[i] = d
    end

    -- Animasi loading
    local steps = {
        {pct=0.15,  txt="Loading modules..."},
        {pct=0.35,  txt="Setting up UI..."},
        {pct=0.55,  txt="Applying theme..."},
        {pct=0.75,  txt="Building elements..."},
        {pct=0.90,  txt="Almost ready..."},
        {pct=1.0,   txt="Done!"},
    }

    local TwS = TweenService
    local function twBar(p)
        TwS:Create(BarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size=UDim2.new(p,0,1,0)}):Play()
    end

    -- Dot pulse loop
    local dotIdx = 0
    local dotConn
    dotConn = RunService.Heartbeat:Connect(function()
        dotIdx = dotIdx + 1
        for i,d in ipairs(dots) do
            local phase = ((dotIdx + i*8) % 30) / 30
            d.BackgroundTransparency = 0.1 + math.abs(math.sin(phase*math.pi)) * 0.8
        end
    end)

    -- Jalankan animasi step by step
    task.spawn(function()
        -- Fade in box
        Box.BackgroundTransparency = 1
        TwS:Create(Box, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {BackgroundTransparency=0}):Play()
        task.wait(0.3)

        for _, step in ipairs(steps) do
            SubLbl.Text = step.txt
            twBar(step.pct)
            PctLbl.Text = math.floor(step.pct * 100) .. "%"
            task.wait(0.22)
        end

        task.wait(0.15)
        dotConn:Disconnect()

        -- Fade out
        TwS:Create(Overlay, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {BackgroundTransparency=1}):Play()
        task.wait(0.42)
        Overlay:Destroy()
        if onDone then onDone() end
    end)
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
end
function KreinGui:UsePreset(name)
    if Presets[name] then self:SetTheme(Presets[name]) end
end

-- ============================================================
-- CREATE WINDOW
-- ============================================================
function KreinGui:CreateWindow(cfg)
    cfg = cfg or {}
    local title   = cfg.Title      or "KreinGui"
    local sub     = cfg.SubTitle   or ""
    local cfgName = cfg.ConfigName or "KreinGuiConfig"

    local SG = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    SG.Name="KreinGui"; SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    SG.ResetOnSpawn=false; SG.IgnoreGuiInset=true

    -- Wrapper: parent dari Win + ToggleBtn
    -- Tidak clip supaya ToggleBtn bisa keluar di sisi kiri
    -- Ukuran = Win + lebar tombol (32px) di kiri
    local Wrapper = Instance.new("Frame", SG)
    Wrapper.Name = "Wrapper"
    Wrapper.Size = UDim2.new(0, 560+32, 0, 340)
    Wrapper.Position = UDim2.new(0.5, -280-32, 0.5, -170)
    Wrapper.BackgroundTransparency = 1
    Wrapper.BorderSizePixel = 0
    Wrapper.ClipsDescendants = false

    -- Window (di dalam Wrapper, offset 32px dari kiri)
    local Win = Instance.new("Frame", Wrapper)
    Win.Name="Window"; Win.Size=UDim2.new(0,560,0,340)
    Win.Position=UDim2.new(0,32,0,0)
    Win.BackgroundColor3=T.WindowBG; Win.BorderSizePixel=0
    Win.ClipsDescendants=true
    Cor(Win,12); Str(Win,T.WinStr,1)
    local g=Instance.new("UIGradient",Win)
    g.Color=ColorSequence.new(Color3.fromRGB(18,28,40),Color3.fromRGB(8,14,22))
    g.Rotation=135

    -- Sembunyikan window sampai loading selesai
    Win.BackgroundTransparency = 1
    Win.Visible = false

    -- Header
    local H=Instance.new("Frame",Win)
    H.Name="Header"; H.Size=UDim2.new(1,0,0,52)
    H.BackgroundColor3=T.HeaderBG; H.BorderSizePixel=0; H.ZIndex=4
    Cor(H,12)

    -- ABar - tebal 4px dengan animasi snake
    local ABar=Instance.new("Frame",Win)
    ABar.Name="ABar"; ABar.Size=UDim2.new(1,0,0,4)
    ABar.Position=UDim2.new(0,0,0,50)
    ABar.BackgroundColor3=T.Accent; ABar.BorderSizePixel=0; ABar.ZIndex=3
    StartSnake(ABar, T.Accent)

    -- ── LOGO K (ciri khas @uniquadev) ─────────────────────────
    local LogoBg=Instance.new("Frame",H)
    LogoBg.Size=UDim2.new(0,34,0,34)
    LogoBg.Position=UDim2.new(0,10,0.5,-17)
    LogoBg.BackgroundColor3=T.Accent
    LogoBg.BackgroundTransparency=0.12
    LogoBg.BorderSizePixel=0
    LogoBg.ZIndex=5
    Cor(LogoBg,8)
    -- Border neon di logo
    local LogoStr=Instance.new("UIStroke",LogoBg)
    LogoStr.Color=T.Accent; LogoStr.Thickness=1.5; LogoStr.Transparency=0.3

    -- Huruf K
    local LogoK=Instance.new("TextLabel",LogoBg)
    LogoK.Size=UDim2.new(1,0,1,0)
    LogoK.BackgroundTransparency=1
    LogoK.BorderSizePixel=0
    LogoK.Text="K"
    LogoK.TextSize=18
    LogoK.Font=Enum.Font.GothamBold
    LogoK.TextColor3=Color3.fromRGB(10,15,20)  -- gelap agar kontras dengan accent
    LogoK.TextXAlignment=Enum.TextXAlignment.Center
    LogoK.TextYAlignment=Enum.TextYAlignment.Center
    LogoK.ZIndex=6

    -- Dot aksen kecil di pojok kanan bawah logo
    local LogoDot=Instance.new("Frame",LogoBg)
    LogoDot.Size=UDim2.new(0,6,0,6)
    LogoDot.Position=UDim2.new(1,-5,1,-5)
    LogoDot.BackgroundColor3=Color3.fromRGB(8,8,14)
    LogoDot.BorderSizePixel=0
    LogoDot.ZIndex=7
    Cor(LogoDot,3)

    -- Title (geser kanan karena ada logo)
    local TL=Lbl(H,title,UDim2.new(0,260,0,22),T.TextPri)
    TL.Position=sub~="" and UDim2.new(0,52,0,5) or UDim2.new(0,52,0,15)
    TL.Font=Enum.Font.GothamBold; TL.TextSize=15; TL.ZIndex=5
    if sub~="" then
        local SL=Lbl(H,sub,UDim2.new(0,260,0,18),T.TextMut)
        SL.Position=UDim2.new(0,52,0,28); SL.Font=Enum.Font.Gotham; SL.TextSize=11; SL.ZIndex=5
    end

    -- Close
    local Cb=Instance.new("TextButton",H)
    Cb.Size=UDim2.new(0,32,0,32); Cb.Position=UDim2.new(1,-40,0.5,-16)
    Cb.BackgroundColor3=Color3.fromRGB(60,35,35); Cb.BorderSizePixel=0
    Cb.Text="✕"; Cb.TextSize=13; Cb.Font=Enum.Font.GothamBold
    Cb.TextColor3=T.CloseRed; Cb.ZIndex=6; Cb.AutoButtonColor=false
    Cor(Cb,7)
    OnClick(Cb,function() SG:Destroy() end)

    -- Minimize
    local Mb=Instance.new("TextButton",H)
    Mb.Size=UDim2.new(0,32,0,32); Mb.Position=UDim2.new(1,-78,0.5,-16)
    Mb.BackgroundColor3=Color3.fromRGB(40,40,50); Mb.BorderSizePixel=0
    Mb.Text="—"; Mb.TextSize=13; Mb.Font=Enum.Font.GothamBold
    Mb.TextColor3=T.MinGray; Mb.ZIndex=6; Mb.AutoButtonColor=false
    Cor(Mb,7)
    -- Helper: update posisi vertikal ToggleBtn agar center di Wrapper
    local function syncToggleBtnY(h)
        ToggleBtn.Position = UDim2.new(0, 0, 0, h/2 - 40)
    end

    local mini=false
    OnClick(Mb,function()
        mini=not mini
        if mini then
            -- Minimize: squeeze ke atas dengan Quart easing
            Tw(Win,    {Size=UDim2.new(0,560,0,52)},   0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            Tw(Wrapper,{Size=UDim2.new(0,560+32,0,52)},0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            task.delay(0.2,function()
                ABar.Visible=false
                local gl=Win:FindFirstChild("ABarGlow")
                if gl then gl.Visible=false end
                syncToggleBtnY(52)
            end)
        else
            -- Restore: expand ke bawah dengan Back easing (sedikit bounce)
            ABar.Visible=true
            local gl=Win:FindFirstChild("ABarGlow")
            if gl then gl.Visible=true end
            Tw(Win,    {Size=UDim2.new(0,560,0,340)},   0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            Tw(Wrapper,{Size=UDim2.new(0,560+32,0,340)},0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            task.delay(0.35,function()
                syncToggleBtnY(340)
            end)
        end
    end)

    EnableDrag(Wrapper,H)

    -- ── TOGGLE VISIBILITY BUTTON ────────────────────────────
    -- Parent ke Wrapper (bukan SG) → otomatis ikut saat drag
    -- Posisi: di kiri Win (X=0), vertikal tengah Wrapper
    -- Wrapper tidak clip → tombol kelihatan walau di luar Win
    local ToggleBtn = Instance.new("TextButton", Wrapper)
    ToggleBtn.Name = "KreinToggleBtn"
    ToggleBtn.Size = UDim2.new(0, 28, 0, 80)
    -- Posisi: X=0 (paling kiri Wrapper), Y tengah Wrapper
    ToggleBtn.Position = UDim2.new(0, 0, 0.5, -40)
    ToggleBtn.BackgroundColor3 = T.WindowBG
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = ""
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.ZIndex = 10
    Cor(ToggleBtn, 8)
    local TBStr = Instance.new("UIStroke", ToggleBtn)
    TBStr.Color = T.Accent; TBStr.Thickness = 1; TBStr.Transparency = 0.3

    -- Panah
    local TBIcon = Instance.new("TextLabel", ToggleBtn)
    TBIcon.Size = UDim2.new(1,0,0,16)
    TBIcon.Position = UDim2.new(0,0,0.5,-26)
    TBIcon.BackgroundTransparency = 1; TBIcon.BorderSizePixel = 0
    TBIcon.Text = "◀"; TBIcon.TextSize = 10
    TBIcon.Font = Enum.Font.GothamBold
    TBIcon.TextColor3 = T.Accent
    TBIcon.TextXAlignment = Enum.TextXAlignment.Center
    TBIcon.ZIndex = 11

    -- Logo K
    local TBLabel = Instance.new("TextLabel", ToggleBtn)
    TBLabel.Size = UDim2.new(1,0,0,14)
    TBLabel.Position = UDim2.new(0,0,0.5,-7)
    TBLabel.BackgroundTransparency = 1; TBLabel.BorderSizePixel = 0
    TBLabel.Text = "K"; TBLabel.TextSize = 13
    TBLabel.Font = Enum.Font.GothamBold
    TBLabel.TextColor3 = T.Accent
    TBLabel.TextXAlignment = Enum.TextXAlignment.Center
    TBLabel.ZIndex = 11

    -- Teks GUI
    local TBSub = Instance.new("TextLabel", ToggleBtn)
    TBSub.Size = UDim2.new(1,0,0,12)
    TBSub.Position = UDim2.new(0,0,0.5,14)
    TBSub.BackgroundTransparency = 1; TBSub.BorderSizePixel = 0
    TBSub.Text = "GUI"; TBSub.TextSize = 8
    TBSub.Font = Enum.Font.GothamBold
    TBSub.TextColor3 = Color3.new(T.Accent.R*0.65, T.Accent.G*0.65, T.Accent.B*0.65)
    TBSub.TextXAlignment = Enum.TextXAlignment.Center
    TBSub.ZIndex = 11

    -- Strip accent kanan tombol
    local TBGlow = Instance.new("Frame", ToggleBtn)
    TBGlow.Size = UDim2.new(0,3,0.65,0)
    TBGlow.Position = UDim2.new(1,-3,0.175,0)
    TBGlow.BackgroundColor3 = T.Accent
    TBGlow.BackgroundTransparency = 0.35
    TBGlow.BorderSizePixel = 0; TBGlow.ZIndex = 11
    Cor(TBGlow, 2)

    -- State & Logic
    local lastWrapperPos = Wrapper.Position  -- posisi default, diupdate saat loading selesai
    local guiVisible = true

    -- Update lastWrapperPos setiap kali Wrapper di-drag
    Wrapper:GetPropertyChangedSignal("Position"):Connect(function()
        if guiVisible then
            lastWrapperPos = Wrapper.Position
        end
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

    OnClick(ToggleBtn, function()
        guiVisible = not guiVisible
        if guiVisible then
            -- ── SHOW: Wrapper slide dari kiri kembali ke posisi asli ──
            Win.Visible = true
            -- Mulai dari pojok kiri, fade in sambil slide ke kanan
            Tw(Win, {BackgroundTransparency = 0}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            Tw(Wrapper, {
                Position = UDim2.new(
                    lastWrapperPos.X.Scale, lastWrapperPos.X.Offset,
                    lastWrapperPos.Y.Scale, lastWrapperPos.Y.Offset
                )
            }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            -- ── HIDE: Window shrink + fade, tombol slide ke kiri ──
            lastWrapperPos = Wrapper.Position
            local currentY = Wrapper.Position.Y
            -- Window scale down sedikit sambil fade out
            Tw(Win, {BackgroundTransparency = 1},
                0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.delay(0.25, function()
                Win.Visible = false
            end)
            -- Wrapper geser ke pojok kiri dengan spring
            Tw(Wrapper, {
                Position = UDim2.new(0, -4, currentY.Scale, currentY.Offset)
            }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.InOut)
        end
        updateToggleBtn()
    end)

    -- Hover
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
    Body.BackgroundTransparency=1; Body.BorderSizePixel=0

    local TW=130

    -- Tab panel kiri
    local TP=Instance.new("Frame",Body)
    TP.Size=UDim2.new(0,TW,1,0); TP.BackgroundColor3=T.TabBG; TP.BorderSizePixel=0

    local SepL=Instance.new("Frame",Body)
    SepL.Size=UDim2.new(0,1,1,0); SepL.Position=UDim2.new(0,TW,0,0)
    SepL.BackgroundColor3=T.Sep; SepL.BorderSizePixel=0

    local TSc=Instance.new("ScrollingFrame",TP)
    TSc.Size=UDim2.new(1,0,1,0); TSc.BackgroundTransparency=1; TSc.BorderSizePixel=0
    TSc.ScrollBarThickness=2; TSc.ScrollBarImageColor3=T.Accent
    TSc.CanvasSize=UDim2.new(0,0,0,0); TSc.AutomaticCanvasSize=Enum.AutomaticSize.Y
    Pad(TSc,8,8,6,6)
    local TL2=Instance.new("UIListLayout",TSc)
    TL2.SortOrder=Enum.SortOrder.LayoutOrder; TL2.Padding=UDim.new(0,3)
    TL2.HorizontalAlignment=Enum.HorizontalAlignment.Center

    -- Content panel kanan
    -- ClipsDescendants=true agar tab Size=0 tidak overflow
    local CP=Instance.new("Frame",Body)
    CP.Size=UDim2.new(1,-(TW+1),1,0); CP.Position=UDim2.new(0,TW+1,0,0)
    CP.BackgroundTransparency=1; CP.BorderSizePixel=0
    CP.ClipsDescendants=true

    -- Window Object
    local W={}
    local tBtns,tFrms,tActive={},{},nil

    local function setTab(idx)
        tActive=idx
        for i,b in ipairs(tBtns) do
            local on=(i==idx)
            Tw(b,{BackgroundColor3=on and T.TabOn or T.TabDef},0.2,
                Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            local l=b:FindFirstChild("L")
            if l then Tw(l,{TextColor3=on and T.TabOnText or T.TabOffText},0.2) end
            local bar=b:FindFirstChild("B"); if bar then bar.Visible=on end
        end
        -- Hide non-active tabs dengan Size=0
        -- Active tab: Size 0→normal dengan animasi
        for i,f in ipairs(tFrms) do
            if i==idx then
                f.Size=UDim2.new(0,0,0,0)
                -- Expand ke full size dengan Quart smooth
                Tw(f,{Size=UDim2.new(1,0,1,0)},0.22,
                    Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            else
                f.Size=UDim2.new(0,0,0,0)
            end
        end
    end

    -- Save/Load
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
        self:Notify(ok and "Config tersimpan!" or "Gagal: "..tostring(e),2)
    end

    function W:LoadConfig()
        local ok,raw=pcall(readfile,cfgName..".json")
        if not ok or not raw then self:Notify("Config tidak ditemukan.",2);return end
        local ok2,d=pcall(HttpService.JSONDecode,HttpService,raw)
        if not ok2 or not d then self:Notify("Config rusak.",2);return end
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
        self:Notify("Config dimuat!",2)
    end

    function W:Notify(msg,dur)
        dur=dur or 3
        local N=Instance.new("Frame",SG)
        N.Size=UDim2.new(0,250,0,46); N.Position=UDim2.new(1,10,1,-64)
        N.BackgroundColor3=T.ElementBG; N.BorderSizePixel=0; N.ZIndex=200
        Cor(N,8); Str(N,T.Accent,1)
        local Bar=Instance.new("Frame",N)
        Bar.Size=UDim2.new(0,3,0.7,0); Bar.Position=UDim2.new(0,0,0.15,0)
        Bar.BackgroundColor3=T.Accent; Bar.BorderSizePixel=0; Bar.ZIndex=201; Cor(Bar,3)
        local nl=Lbl(N,msg,UDim2.new(1,-18,1,0),T.TextPri)
        nl.Position=UDim2.new(0,14,0,0); nl.Font=Enum.Font.Gotham; nl.TextSize=12; nl.ZIndex=201; nl.TextWrapped=true
        Tw(N,{Position=UDim2.new(1,-260,1,-64)},0.3)
        task.delay(dur,function()
            Tw(N,{Position=UDim2.new(1,10,1,-64)},0.3)
            task.delay(0.35,function() N:Destroy() end)
        end)
    end

    -- ============================================================
    -- CREATE TAB
    -- ============================================================
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
        BL.Name="L"; BL.Position=UDim2.new(0,10,0,0); BL.Font=Enum.Font.GothamMedium; BL.TextSize=12

        OnClick(Btn,function() setTab(idx) end)
        Btn.MouseEnter:Connect(function() if tActive~=idx then Tw(Btn,{BackgroundColor3=T.TabHov},0.15) end end)
        Btn.MouseLeave:Connect(function() if tActive~=idx then Tw(Btn,{BackgroundColor3=T.TabDef},0.15) end end)
        tBtns[idx]=Btn

        -- Content ScrollingFrame
        -- PENTING: Visible=true SELALU, hide dengan Size=0
        local Con=Instance.new("ScrollingFrame",CP)
        Con.Name="C"..idx
        Con.BackgroundTransparency=1; Con.BorderSizePixel=0
        Con.ScrollBarThickness=3; Con.ScrollBarImageColor3=T.Accent
        Con.CanvasSize=UDim2.new(0,0,0,0)
        Con.AutomaticCanvasSize=Enum.AutomaticSize.Y
        Con.ClipsDescendants=true
        Con.Visible=true          -- SELALU true
        Con.Size=UDim2.new(0,0,0,0)  -- mulai Size=0
        Pad(Con,10,10,10,10)
        local EL=Instance.new("UIListLayout",Con)
        EL.SortOrder=Enum.SortOrder.LayoutOrder; EL.Padding=UDim.new(0,6)

        tFrms[idx]=Con

        -- Tab pertama langsung aktif
        if idx==1 then setTab(1) end

        -- Tab Object
        local Tab={}
        local ord=0
        local function nxt() ord=ord+1; return ord end
        local function rfl(flag,api)
            if flag and flag~="" then flags[flag]=api; KreinGui.Flags[flag]=api end
        end
        local function Card(h)
            local c=Instance.new("Frame",Con)
            c.Size=UDim2.new(1,0,0,h or 44); c.BackgroundColor3=T.ElementBG
            c.BorderSizePixel=0; c.LayoutOrder=nxt(); c.ClipsDescendants=false
            Cor(c,8); Str(c,T.ElementStr,1)
            return c
        end

        -- LABEL
        function Tab:CreateLabel(txt)
            local c=Card(36); Pad(c,0,0,12,12)
            local l=Lbl(c,txt,UDim2.new(1,0,1,0),T.TextSec)
            l.Font=Enum.Font.Gotham; l.TextSize=12; return l
        end

        -- SECTION HEADER
        function Tab:CreateSectionHeader(txt)
            local c=Instance.new("Frame",Con)
            c.Size=UDim2.new(1,0,0,24); c.BackgroundTransparency=1
            c.BorderSizePixel=0; c.LayoutOrder=nxt()
            local line=Instance.new("Frame",c)
            line.Size=UDim2.new(0,3,0.6,0); line.Position=UDim2.new(0,0,0.2,0)
            line.BackgroundColor3=T.Accent; line.BorderSizePixel=0; Cor(line,2)
            local l=Lbl(c,txt:upper(),UDim2.new(1,-10,1,0),T.SecText)
            l.Position=UDim2.new(0,10,0,0); l.Font=Enum.Font.GothamBold; l.TextSize=10
            return l
        end

        -- SEPARATOR
        function Tab:AddSeparator()
            local s=Instance.new("Frame",Con)
            s.Size=UDim2.new(1,0,0,1); s.BackgroundColor3=T.Sep
            s.BorderSizePixel=0; s.LayoutOrder=nxt()
        end

        -- BUTTON
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
            rb.Text="Run"; rb.TextSize=11; rb.Font=Enum.Font.GothamBold
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
        end

        -- TOGGLE
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
            rfl(cfg2.Flag,api); return api
        end

        -- SLIDER
        function Tab:CreateSlider(cfg2)
            cfg2=cfg2 or {}
            local mn=cfg2.Min or 0; local mx=cfg2.Max or 100
            local val=math.clamp(cfg2.Default or mn,mn,mx)
            local c=Card(58); Pad(c,8,8,12,12)
            local TR=Instance.new("Frame",c)
            TR.Size=UDim2.new(1,0,0,20); TR.BackgroundTransparency=1; TR.BorderSizePixel=0
            local tl=Lbl(TR,cfg2.Title or "Slider",UDim2.new(1,-42,1,0))
            tl.Font=Enum.Font.GothamMedium; tl.TextSize=13
            local vl=Lbl(TR,tostring(val),UDim2.new(0,40,1,0),T.Accent,Enum.TextXAlignment.Right)
            vl.Position=UDim2.new(1,-40,0,0); vl.Font=Enum.Font.GothamBold
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
                local r=math.clamp((x-TBG.AbsolutePosition.X)/TBG.AbsoluteSize.X,0,1)
                val=math.floor(mn+r*(mx-mn)+0.5); local p=(val-mn)/(mx-mn)
                TF.Size=UDim2.new(p,0,1,0); Kn.Position=UDim2.new(p,-10,0.5,-10); vl.Text=tostring(val)
                pcall(cfg2.Callback or function()end,val)
            end
            function api:Set(v) val=math.clamp(v,mn,mx); local p=(val-mn)/(mx-mn); TF.Size=UDim2.new(p,0,1,0); Kn.Position=UDim2.new(p,-10,0.5,-10); vl.Text=tostring(val); pcall(cfg2.Callback or function()end,val) end
            function api:Get() return val end
            SB.InputBegan:Connect(function(i) if isDown(i) then slid=true; upd(i.Position.X) end end)
            UserInput.InputChanged:Connect(function(i) if slid and isMove(i) then upd(i.Position.X) end end)
            UserInput.InputEnded:Connect(function(i) if isDown(i) then slid=false end end)
            rfl(cfg2.Flag,api); return api
        end

        -- TEXTBOX
        function Tab:CreateTextBox(cfg2)
            cfg2=cfg2 or {}
            local c=Card(70); Pad(c,8,8,12,12)
            local tl=Lbl(c,cfg2.Title or "TextBox",UDim2.new(1,0,0,20)); tl.Font=Enum.Font.GothamMedium; tl.TextSize=13
            local IF=Instance.new("Frame",c)
            IF.Size=UDim2.new(1,0,0,32); IF.Position=UDim2.new(0,0,1,-36)
            IF.BackgroundColor3=T.WindowBG; IF.BorderSizePixel=0; Cor(IF,6)
            local is=Str(IF,T.ElementStr,1)
            local TB=Instance.new("TextBox",IF)
            TB.Size=UDim2.new(1,0,1,0); TB.BackgroundTransparency=1; TB.BorderSizePixel=0
            TB.Text=""; TB.PlaceholderText=cfg2.Placeholder or "Type here..."
            TB.PlaceholderColor3=T.TextMut; TB.TextColor3=T.TextPri
            TB.TextSize=12; TB.Font=Enum.Font.Gotham; TB.TextXAlignment=Enum.TextXAlignment.Left; TB.ClearTextOnFocus=false
            Pad(TB,0,0,8,8)
            TB.Focused:Connect(function() is.Color=T.Accent end)
            TB.FocusLost:Connect(function(e) is.Color=T.ElementStr; if e then pcall(cfg2.Callback or function()end,TB.Text) end end)
            local api={}; function api:Set(v) TB.Text=tostring(v) end; function api:Get() return TB.Text end
            rfl(cfg2.Flag,api); return api
        end

        -- DROPDOWN
        function Tab:CreateDropdown(cfg2)
            cfg2=cfg2 or {}
            local opts=cfg2.Options or {}; local sel=cfg2.Default or (opts[1] or ""); local open=false
            local c=Card(44); Pad(c,0,0,12,12)
            Lbl(c,cfg2.Title or "Dropdown",UDim2.new(1,-100,1,0)).TextSize=13
            local SF=Instance.new("Frame",c)
            SF.Size=UDim2.new(0,90,0,28); SF.Position=UDim2.new(1,-90,0.5,-14)
            SF.BackgroundColor3=T.WindowBG; SF.BorderSizePixel=0; Cor(SF,6); Str(SF,T.ElementStr,1)
            local SL=Lbl(SF,sel,UDim2.new(1,-18,1,0),T.TextPri); SL.Position=UDim2.new(0,6,0,0); SL.Font=Enum.Font.Gotham; SL.TextSize=11
            local Arr=Lbl(SF,"▾",UDim2.new(0,14,1,0),T.TextMut,Enum.TextXAlignment.Center); Arr.Position=UDim2.new(1,-16,0,0); Arr.TextSize=12
            local DF=Instance.new("Frame",SG)
            DF.Size=UDim2.new(0,100,0,0); DF.BackgroundColor3=T.ElementBG; DF.BorderSizePixel=0
            DF.ClipsDescendants=true; DF.Visible=false; DF.ZIndex=160; Cor(DF,6); Str(DF,T.ElementStr,1)
            local DL=Instance.new("UIListLayout",DF); DL.SortOrder=Enum.SortOrder.LayoutOrder; DL.Padding=UDim.new(0,2); Pad(DF,4,4,4,4)
            local oH=32
            local function closeDD()
                if not open then return end; open=false
                Tw(DF,{Size=UDim2.new(0,DF.Size.X.Offset,0,0)},0.15); Arr.Text="▾"
                task.delay(0.16,function() DF.Visible=false end)
            end
            for i,opt in ipairs(opts) do
                local ob=Instance.new("TextButton",DF)
                ob.Size=UDim2.new(1,0,0,oH-2); ob.BackgroundColor3=T.ElementBG; ob.BorderSizePixel=0
                ob.Text=opt; ob.TextSize=12; ob.Font=Enum.Font.Gotham; ob.TextColor3=T.TextSec
                ob.TextXAlignment=Enum.TextXAlignment.Left; ob.AutoButtonColor=false; ob.ZIndex=161; ob.LayoutOrder=i
                Cor(ob,4); Pad(ob,0,0,8,0)
                ob.MouseEnter:Connect(function() Tw(ob,{BackgroundColor3=T.TabHov},0.12) end)
                ob.MouseLeave:Connect(function() Tw(ob,{BackgroundColor3=T.ElementBG},0.12) end)
                OnClick(ob,function() sel=opt; SL.Text=opt; pcall(cfg2.Callback or function()end,sel); closeDD() end)
            end
            local totH=#opts*oH+8
            local function openDD()
                local ap=SF.AbsolutePosition; local as=SF.AbsoluteSize; local w=math.max(as.X+10,100)
                DF.Position=UDim2.new(0,ap.X,0,ap.Y+as.Y+4); DF.Size=UDim2.new(0,w,0,0)
                DF.Visible=true; open=true; Tw(DF,{Size=UDim2.new(0,w,0,totH)},0.2); Arr.Text="▴"
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
                    local pos=i.Position; local dp=DF.AbsolutePosition; local ds=DF.AbsoluteSize; local cp2=c.AbsolutePosition; local cs=c.AbsoluteSize
                    if not(pos.X>=dp.X and pos.X<=dp.X+ds.X and pos.Y>=dp.Y and pos.Y<=dp.Y+ds.Y) and
                       not(pos.X>=cp2.X and pos.X<=cp2.X+cs.X and pos.Y>=cp2.Y and pos.Y<=cp2.Y+cs.Y) then closeDD() end
                end)
            end)
            local api={}; function api:Set(v) sel=v; SL.Text=v; pcall(cfg2.Callback or function()end,v) end; function api:Get() return sel end
            rfl(cfg2.Flag,api); return api
        end

        -- INPUT NUMBER
        function Tab:CreateInputNumber(cfg2)
            cfg2=cfg2 or {}
            local mn=cfg2.Min or 0; local mx=cfg2.Max or 100; local step=cfg2.Step or 1
            local val=math.clamp(cfg2.Default or mn,mn,mx)
            local c=Card(44); Pad(c,0,0,12,12)
            Lbl(c,cfg2.Title or "Number",UDim2.new(1,-128,1,0)).TextSize=13
            local Row=Instance.new("Frame",c)
            Row.Size=UDim2.new(0,116,0,30); Row.Position=UDim2.new(1,-120,0.5,-15)
            Row.BackgroundTransparency=1; Row.BorderSizePixel=0
            local Mins=Instance.new("TextButton",Row)
            Mins.Size=UDim2.new(0,30,1,0); Mins.BackgroundColor3=T.ElementHov; Mins.BorderSizePixel=0
            Mins.Text="−"; Mins.TextSize=16; Mins.Font=Enum.Font.GothamBold; Mins.TextColor3=T.TextPri; Mins.AutoButtonColor=false; Cor(Mins,6)
            local VF=Instance.new("Frame",Row)
            VF.Size=UDim2.new(0,50,1,0); VF.Position=UDim2.new(0,34,0,0)
            VF.BackgroundColor3=T.WindowBG; VF.BorderSizePixel=0; Cor(VF,6); Str(VF,T.ElementStr,1)
            local VL=Lbl(VF,tostring(val),UDim2.new(1,0,1,0),T.TextPri,Enum.TextXAlignment.Center)
            VL.Font=Enum.Font.GothamBold; VL.TextSize=13
            local Plus=Instance.new("TextButton",Row)
            Plus.Size=UDim2.new(0,30,1,0); Plus.Position=UDim2.new(0,88,0,0)
            Plus.BackgroundColor3=T.ElementHov; Plus.BorderSizePixel=0
            Plus.Text="+"; Plus.TextSize=16; Plus.Font=Enum.Font.GothamBold; Plus.TextColor3=T.TextPri; Plus.AutoButtonColor=false; Cor(Plus,6)
            Mins.MouseEnter:Connect(function() Tw(Mins,{BackgroundColor3=T.TabHov},0.12) end)
            Mins.MouseLeave:Connect(function() Tw(Mins,{BackgroundColor3=T.ElementHov},0.12) end)
            Plus.MouseEnter:Connect(function() Tw(Plus,{BackgroundColor3=T.TabHov},0.12) end)
            Plus.MouseLeave:Connect(function() Tw(Plus,{BackgroundColor3=T.ElementHov},0.12) end)
            local api={}
            local function updN() VL.Text=tostring(val); pcall(cfg2.Callback or function()end,val) end
            function api:Set(v) val=math.clamp(v,mn,mx); updN() end; function api:Get() return val end
            OnClick(Mins,function() val=math.clamp(val-step,mn,mx); updN(); Tw(Mins,{BackgroundColor3=T.AccentDark},0.1); task.delay(0.15,function() Tw(Mins,{BackgroundColor3=T.ElementHov},0.15) end) end)
            OnClick(Plus,function() val=math.clamp(val+step,mn,mx); updN(); Tw(Plus,{BackgroundColor3=T.AccentDark},0.1); task.delay(0.15,function() Tw(Plus,{BackgroundColor3=T.ElementHov},0.15) end) end)
            rfl(cfg2.Flag,api); return api
        end

        -- PROGRESS BAR
        function Tab:CreateProgressBar(cfg2)
            cfg2=cfg2 or {}
            local val=math.clamp(cfg2.Default or 0,0,100)
            local c=Card(54); Pad(c,8,8,12,12)
            local TR=Instance.new("Frame",c); TR.Size=UDim2.new(1,0,0,20); TR.BackgroundTransparency=1; TR.BorderSizePixel=0
            local tl=Lbl(TR,cfg2.Title or "Progress",UDim2.new(1,-42,1,0)); tl.Font=Enum.Font.GothamMedium; tl.TextSize=13
            local pl=Lbl(TR,val.."%",UDim2.new(0,40,1,0),T.Accent,Enum.TextXAlignment.Right)
            pl.Position=UDim2.new(1,-40,0,0); pl.Font=Enum.Font.GothamBold
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
            rfl(cfg2.Flag,api); return api
        end

        -- COLOR PICKER
        function Tab:CreateColorPicker(cfg2)
            cfg2=cfg2 or {}
            local col=cfg2.Default or Color3.fromRGB(255,0,0)
            local cH,cS,cV=toHSV(col); local tH,tS,tV=cH,cS,cV; local open=false
            local c=Card(44); Pad(c,0,0,12,12)
            Lbl(c,cfg2.Title or "Color",UDim2.new(1,-58,1,0)).TextSize=13
            local Sw=Instance.new("Frame",c); Sw.Size=UDim2.new(0,34,0,24); Sw.Position=UDim2.new(1,-38,0.5,-12); Sw.BackgroundColor3=col; Sw.BorderSizePixel=0; Cor(Sw,5); Str(Sw,T.ElementStr,1)
            local PW,PH=210,240
            local Pop=Instance.new("Frame",SG); Pop.Size=UDim2.new(0,PW,0,0); Pop.BackgroundColor3=T.ElementBG; Pop.BorderSizePixel=0; Pop.ClipsDescendants=true; Pop.Visible=false; Pop.ZIndex=160; Cor(Pop,8); Str(Pop,T.ElementStr,1)
            local SV=Instance.new("Frame",Pop); SV.Size=UDim2.new(1,-16,0,110); SV.Position=UDim2.new(0,8,0,8); SV.BackgroundColor3=HSV(tH,1,1); SV.BorderSizePixel=0; SV.ZIndex=161; Cor(SV,6)
            local WL=Instance.new("Frame",SV); WL.Size=UDim2.new(1,0,1,0); WL.BackgroundColor3=Color3.fromRGB(255,255,255); WL.BackgroundTransparency=0; WL.BorderSizePixel=0; WL.ZIndex=162; Cor(WL,6)
            local wg=Instance.new("UIGradient",WL); wg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
            local BL=Instance.new("Frame",SV); BL.Size=UDim2.new(1,0,1,0); BL.BackgroundColor3=Color3.fromRGB(0,0,0); BL.BackgroundTransparency=0; BL.BorderSizePixel=0; BL.ZIndex=163; Cor(BL,6)
            local bg=Instance.new("UIGradient",BL); bg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}); bg.Rotation=90
            local SVC=Instance.new("Frame",SV); SVC.Size=UDim2.new(0,12,0,12); SVC.Position=UDim2.new(tS,-6,1-tV,-6); SVC.BackgroundColor3=Color3.fromRGB(255,255,255); SVC.BorderSizePixel=0; SVC.ZIndex=165; Cor(SVC,6); Str(SVC,Color3.fromRGB(0,0,0),1)
            local HB=Instance.new("Frame",Pop); HB.Size=UDim2.new(1,-16,0,16); HB.Position=UDim2.new(0,8,0,124); HB.BackgroundColor3=Color3.fromRGB(255,255,255); HB.BorderSizePixel=0; HB.ZIndex=161; Cor(HB,4)
            local HI=Instance.new("ImageLabel",HB); HI.Size=UDim2.new(1,0,1,0); HI.BackgroundTransparency=1; HI.BorderSizePixel=0; HI.Image="rbxassetid://698052001"; HI.ZIndex=162
            local HC=Instance.new("Frame",HB); HC.Size=UDim2.new(0,6,1,4); HC.Position=UDim2.new(tH,-3,0,-2); HC.BackgroundColor3=Color3.fromRGB(255,255,255); HC.BorderSizePixel=0; HC.ZIndex=163; Cor(HC,3); Str(HC,Color3.fromRGB(0,0,0),1)
            local HxF=Instance.new("Frame",Pop); HxF.Size=UDim2.new(1,-16,0,26); HxF.Position=UDim2.new(0,8,0,148); HxF.BackgroundColor3=T.WindowBG; HxF.BorderSizePixel=0; HxF.ZIndex=161; Cor(HxF,5); Str(HxF,T.ElementStr,1)
            Lbl(HxF,"#",UDim2.new(0,16,1,0),T.TextMut,Enum.TextXAlignment.Center).ZIndex=162
            local HL=Lbl(HxF,toHex(col),UDim2.new(1,-18,1,0),T.TextPri); HL.Position=UDim2.new(0,18,0,0); HL.TextSize=11; HL.Font=Enum.Font.GothamBold; HL.ZIndex=162
            local BP=Instance.new("Frame",Pop); BP.Size=UDim2.new(1,-16,0,14); BP.Position=UDim2.new(0,8,0,180); BP.BackgroundColor3=col; BP.BorderSizePixel=0; BP.ZIndex=161; Cor(BP,4)
            local BR=Instance.new("Frame",Pop); BR.Size=UDim2.new(1,-16,0,28); BR.Position=UDim2.new(0,8,0,200); BR.BackgroundTransparency=1; BR.BorderSizePixel=0; BR.ZIndex=161
            local OK=Instance.new("TextButton",BR); OK.Size=UDim2.new(0.5,-3,1,0); OK.BackgroundColor3=T.Accent; OK.BorderSizePixel=0; OK.Text="OK"; OK.TextSize=12; OK.Font=Enum.Font.GothamBold; OK.TextColor3=Color3.fromRGB(255,255,255); OK.AutoButtonColor=false; OK.ZIndex=162; Cor(OK,6)
            local CL=Instance.new("TextButton",BR); CL.Size=UDim2.new(0.5,-3,1,0); CL.Position=UDim2.new(0.5,3,0,0); CL.BackgroundColor3=T.ElementHov; CL.BorderSizePixel=0; CL.Text="Batal"; CL.TextSize=12; CL.Font=Enum.Font.GothamBold; CL.TextColor3=T.TextSec; CL.AutoButtonColor=false; CL.ZIndex=162; Cor(CL,6)
            local api={}
            local function updPrev() local tc=HSV(tH,tS,tV); SV.BackgroundColor3=HSV(tH,1,1); SVC.Position=UDim2.new(tS,-6,1-tV,-6); HC.Position=UDim2.new(tH,-3,0,-2); HL.Text=toHex(tc); BP.BackgroundColor3=tc end
            local function updPos() local vp=workspace.CurrentCamera.ViewportSize; local ap=Sw.AbsolutePosition; local x=math.max(4,math.min(ap.X-PW+34,vp.X-PW-4)); local y=ap.Y+28; if y+PH>vp.Y-4 then y=ap.Y-PH-4 end; Pop.Position=UDim2.new(0,x,0,y) end
            local function closePop() open=false; Tw(Pop,{Size=UDim2.new(0,PW,0,0)},0.18); task.delay(0.2,function() Pop.Visible=false end) end
            OnClick(OK,function() col=HSV(tH,tS,tV); cH,cS,cV=tH,tS,tV; Sw.BackgroundColor3=col; pcall(cfg2.Callback or function()end,col); closePop() end)
            OnClick(CL,function() tH,tS,tV=cH,cS,cV; updPrev(); closePop() end)
            local svd=false
            local SVB=Instance.new("TextButton",SV); SVB.Size=UDim2.new(1,0,1,0); SVB.BackgroundTransparency=1; SVB.BorderSizePixel=0; SVB.Text=""; SVB.ZIndex=166
            SVB.InputBegan:Connect(function(i) if isDown(i) then svd=true; tS=math.clamp((i.Position.X-SV.AbsolutePosition.X)/SV.AbsoluteSize.X,0,1); tV=1-math.clamp((i.Position.Y-SV.AbsolutePosition.Y)/SV.AbsoluteSize.Y,0,1); updPrev() end end)
            UserInput.InputChanged:Connect(function(i) if svd and isMove(i) then tS=math.clamp((i.Position.X-SV.AbsolutePosition.X)/SV.AbsoluteSize.X,0,1); tV=1-math.clamp((i.Position.Y-SV.AbsolutePosition.Y)/SV.AbsoluteSize.Y,0,1); updPrev() end end)
            UserInput.InputEnded:Connect(function(i) if isDown(i) then svd=false end end)
            local hud=false
            local HBtn=Instance.new("TextButton",HB); HBtn.Size=UDim2.new(1,0,1,0); HBtn.BackgroundTransparency=1; HBtn.BorderSizePixel=0; HBtn.Text=""; HBtn.ZIndex=163
            HBtn.InputBegan:Connect(function(i) if isDown(i) then hud=true; tH=math.clamp((i.Position.X-HB.AbsolutePosition.X)/HB.AbsoluteSize.X,0,1); updPrev() end end)
            UserInput.InputChanged:Connect(function(i) if hud and isMove(i) then tH=math.clamp((i.Position.X-HB.AbsolutePosition.X)/HB.AbsoluteSize.X,0,1); updPrev() end end)
            UserInput.InputEnded:Connect(function(i) if isDown(i) then hud=false end end)
            local TB3=Instance.new("TextButton",c); TB3.Size=UDim2.new(1,0,1,0); TB3.BackgroundTransparency=1; TB3.BorderSizePixel=0; TB3.Text=""; TB3.AutoButtonColor=false
            OnClick(TB3,function()
                if open then tH,tS,tV=cH,cS,cV; updPrev(); closePop()
                else tH,tS,tV=cH,cS,cV; updPrev(); updPos(); Pop.Visible=true; open=true; Tw(Pop,{Size=UDim2.new(0,PW,0,PH)},0.22) end
            end)
            TB3.MouseEnter:Connect(function() Tw(c,{BackgroundColor3=T.ElementHov},0.15) end)
            TB3.MouseLeave:Connect(function() Tw(c,{BackgroundColor3=T.ElementBG},0.15) end)
            function api:Set(nc) col=nc; cH,cS,cV=toHSV(nc); Sw.BackgroundColor3=nc; pcall(cfg2.Callback or function()end,nc) end
            function api:Get() return col end
            rfl(cfg2.Flag,api); return api
        end

        -- KEYBIND
        function Tab:CreateKeybind(cfg2)
            cfg2=cfg2 or {}; local key=cfg2.Default or Enum.KeyCode.Unknown; local lstn=false
            local c=Card(44); Pad(c,0,0,12,12)
            Lbl(c,cfg2.Title or "Keybind",UDim2.new(1,-90,1,0)).TextSize=13
            local Bdg=Instance.new("TextButton",c)
            Bdg.Size=UDim2.new(0,82,0,30); Bdg.Position=UDim2.new(1,-86,0.5,-15)
            Bdg.BackgroundColor3=T.WindowBG; Bdg.BorderSizePixel=0; Bdg.TextSize=11; Bdg.Font=Enum.Font.GothamBold; Bdg.TextColor3=T.Accent; Bdg.AutoButtonColor=false; Bdg.ZIndex=5; Cor(Bdg,5); Str(Bdg,T.ElementStr,1)
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
            rfl(cfg2.Flag,api); return api
        end

        return Tab
    end -- CreateTab

    -- Tampilkan loading screen, lalu reveal window dengan animasi
    ShowLoading(SG, T.Accent, title, function()
        Win.Visible = true
        Win.BackgroundTransparency = 1
        -- Mulai dari bawah layar, scale masuk
        Wrapper.Position = UDim2.new(0.5,-280-32,0.5,-130)
        -- Slide ke atas ke posisi normal dengan Back bounce
        Tw(Wrapper, {Position=UDim2.new(0.5,-280-32,0.5,-170)},
            0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        -- Fade in sedikit delayed agar terasa bertahap
        task.delay(0.05, function()
            Tw(Win, {BackgroundTransparency=0},
                0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end)
        syncToggleBtnY(340)
        task.delay(0.6, function()
            lastWrapperPos = Wrapper.Position
        end)
    end)

    return W
end -- CreateWindow

return KreinGui
