--[[
╔══════════════════════════════════════════════════════════════╗
║         KreinGui Key System  —  by @uniquadev               ║
║                    Version 1.0.0                             ║
╚══════════════════════════════════════════════════════════════╝

  CARA PAKAI:

    -- 1. Load library utama dulu
    local KreinGui = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/LippTz/KreinGuiLibrary/refs/heads/main/KreinGui.lua"
    ))()

    -- 2. Load key system
    local KeySystem = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/LippTz/KreinGuiLibrary/refs/heads/main/KreinGuiKey.lua"
    ))()

    -- 3. Cek key dulu, baru buka GUI setelah valid
    KeySystem:Check({
        KeyUrl  = "https://pastebin.com/raw/XXXXXXXX",
        KeyLink = "https://linkvertise.com/XXXXX",
        Theme   = KreinGui.CurrentTheme,  -- opsional, pakai tema yang sama

        OnSuccess = function()
            -- Isi kode GUI kamu di sini, dipanggil setelah key valid
            local Win = KreinGui:CreateWindow({ Title = "My Hub" })
            local Tab = Win:CreateTab("Main")
            Tab:CreateButton({ Title = "Test", Callback = function() end })
            Win:Notify("GUI loaded!", 3)
        end,
    })

  CARA BUAT FILE KEY DI PASTEBIN:
    1. Buka pastebin.com → New Paste
    2. Isi key valid, satu per baris:
         KREIN-ABC123
         KREIN-XYZ789
    3. Set ke Public/Unlisted → Create → klik RAW → copy URL
    4. Paste URL ke KeyUrl

  KEY BERLAKU 24 JAM setelah diinput.
  Setelah expired, user harus input key baru.
--]]

-- ================================================================
-- SERVICES
-- ================================================================
local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService= game:GetService("TweenService")
local UserInput   = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ================================================================
-- KONSTANTA
-- ================================================================
local SAVE_FILE   = "KreinGuiKey.json"
local EXPIRE_SECS = 86400  -- 24 jam

-- ================================================================
-- HELPERS
-- ================================================================
local function Tween(o, p, d)
    TweenService:Create(o, TweenInfo.new(d or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), p):Play()
end

local function Corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

local function Stroke(p, col, t)
    local s = Instance.new("UIStroke", p)
    s.Color = col or Color3.fromRGB(70,70,90)
    s.Thickness = t or 1
    return s
end

local function Pad(p, t, b, l, r)
    local u = Instance.new("UIPadding", p)
    u.PaddingTop    = UDim.new(0, t or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.PaddingLeft   = UDim.new(0, l or 0)
    u.PaddingRight  = UDim.new(0, r or 0)
end

-- OnClick: bekerja di PC dan Mobile tanpa delay
local function OnClick(btn, fn)
    local down, startPos = false, nil
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            down = true; startPos = inp.Position
        end
    end)
    btn.InputEnded:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseButton1
        or  inp.UserInputType == Enum.UserInputType.Touch) and down then
            down = false
            if startPos and (inp.Position - startPos).Magnitude <= 12 then fn() end
        end
    end)
    btn.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and startPos then
            if (inp.Position - startPos).Magnitude > 12 then down = false end
        end
    end)
end

-- ================================================================
-- KEY LOGIC
-- ================================================================
local function loadSavedKey()
    local ok, raw = pcall(readfile, SAVE_FILE)
    if not ok or not raw or raw == "" then return nil end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 or type(data) ~= "table" then return nil end
    if data.time and os.time() - data.time < EXPIRE_SECS then
        return data.key
    end
    return nil  -- expired
end

local function saveKey(key)
    pcall(writefile, SAVE_FILE, HttpService:JSONEncode({
        key  = key,
        time = os.time(),
    }))
end

local function validateKey(key, url)
    if url == "" or url == nil then return false end
    local ok, raw = pcall(game.HttpGet, game, url)
    if not ok or not raw then return false end
    for _, line in ipairs(string.split(raw, "\n")) do
        local trimmed = line:gsub("^%s*(.-)%s*$", "%1")
        if trimmed ~= "" and trimmed == key then
            return true
        end
    end
    return false
end

-- ================================================================
-- THEME (default, bisa di-override dari KreinGui)
-- ================================================================
local T = {
    WindowBG    = Color3.fromRGB(28, 28, 32),
    HeaderBG    = Color3.fromRGB(22, 22, 26),
    ElementBG   = Color3.fromRGB(40, 40, 48),
    ElementHov  = Color3.fromRGB(55, 55, 68),
    Accent      = Color3.fromRGB(99, 102, 241),
    AccentHov   = Color3.fromRGB(129, 132, 255),
    TextPrimary = Color3.fromRGB(240, 240, 248),
    TextMuted   = Color3.fromRGB(90, 90, 110),
    TextSec     = Color3.fromRGB(140, 140, 160),
    CloseRed    = Color3.fromRGB(255, 75, 75),
    Stroke      = Color3.fromRGB(70, 70, 90),
}

-- ================================================================
-- SHOW KEY WINDOW
-- ================================================================
local function showKeyWindow(cfg, onSuccess)
    local keyUrl  = cfg.KeyUrl  or ""
    local keyLink = cfg.KeyLink or "https://example.com"

    -- Terapkan tema dari KreinGui jika ada
    if cfg.Theme then
        for k, v in pairs(cfg.Theme) do T[k] = v end
    end

    local SG = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    SG.Name           = "KreinGuiKey"
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SG.ResetOnSpawn   = false
    SG.IgnoreGuiInset = true

    -- Overlay gelap
    local Overlay = Instance.new("Frame", SG)
    Overlay.Size                 = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3     = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.45
    Overlay.BorderSizePixel      = 0
    Overlay.ZIndex               = 1

    -- Window utama
    local KWin = Instance.new("Frame", SG)
    KWin.Size             = UDim2.new(0, 360, 0, 268)
    KWin.Position         = UDim2.new(0.5, -180, 0.5, -90)  -- start dari atas
    KWin.BackgroundColor3 = T.WindowBG
    KWin.BackgroundTransparency = 1
    KWin.BorderSizePixel  = 0
    KWin.ZIndex           = 2
    Corner(KWin, 14)
    Stroke(KWin, T.Stroke, 1)

    -- Gradient
    local grad = Instance.new("UIGradient", KWin)
    grad.Color    = ColorSequence.new(Color3.fromRGB(38,38,48), Color3.fromRGB(20,20,28))
    grad.Rotation = 135

    -- Header
    local KHeader = Instance.new("Frame", KWin)
    KHeader.Size             = UDim2.new(1, 0, 0, 58)
    KHeader.BackgroundColor3 = T.HeaderBG
    KHeader.BorderSizePixel  = 0
    KHeader.ZIndex           = 3
    Corner(KHeader, 14)

    -- Accent bar di bawah header
    local ABar = Instance.new("Frame", KWin)
    ABar.Size             = UDim2.new(1, 0, 0, 3)
    ABar.Position         = UDim2.new(0, 0, 0, 55)
    ABar.BackgroundColor3 = T.Accent
    ABar.BorderSizePixel  = 0
    ABar.ZIndex           = 3

    -- Icon 🔑
    local IconBg = Instance.new("Frame", KHeader)
    IconBg.Size                   = UDim2.new(0, 38, 0, 38)
    IconBg.Position               = UDim2.new(0, 14, 0.5, -19)
    IconBg.BackgroundColor3       = T.Accent
    IconBg.BackgroundTransparency = 0.75
    IconBg.BorderSizePixel        = 0
    IconBg.ZIndex                 = 4
    Corner(IconBg, 10)

    local IconLbl = Instance.new("TextLabel", IconBg)
    IconLbl.Size                   = UDim2.new(1, 0, 1, 0)
    IconLbl.BackgroundTransparency = 1
    IconLbl.BorderSizePixel        = 0
    IconLbl.Text                   = "🔑"
    IconLbl.TextSize               = 20
    IconLbl.Font                   = Enum.Font.GothamBold
    IconLbl.ZIndex                 = 5

    -- Title
    local KTitle = Instance.new("TextLabel", KHeader)
    KTitle.Size                   = UDim2.new(1, -110, 0, 22)
    KTitle.Position               = UDim2.new(0, 60, 0, 8)
    KTitle.BackgroundTransparency = 1
    KTitle.BorderSizePixel        = 0
    KTitle.Text                   = "Key Required"
    KTitle.TextSize               = 15
    KTitle.Font                   = Enum.Font.GothamBold
    KTitle.TextColor3             = T.TextPrimary
    KTitle.TextXAlignment         = Enum.TextXAlignment.Left
    KTitle.ZIndex                 = 4

    local KSub = Instance.new("TextLabel", KHeader)
    KSub.Size                   = UDim2.new(1, -110, 0, 16)
    KSub.Position               = UDim2.new(0, 60, 0, 32)
    KSub.BackgroundTransparency = 1
    KSub.BorderSizePixel        = 0
    KSub.Text                   = "Masukkan key untuk melanjutkan"
    KSub.TextSize               = 11
    KSub.Font                   = Enum.Font.Gotham
    KSub.TextColor3             = T.TextMuted
    KSub.TextXAlignment         = Enum.TextXAlignment.Left
    KSub.ZIndex                 = 4

    -- Close X
    local KClose = Instance.new("TextButton", KHeader)
    KClose.Size             = UDim2.new(0, 30, 0, 30)
    KClose.Position         = UDim2.new(1, -40, 0.5, -15)
    KClose.BackgroundColor3 = Color3.fromRGB(60, 35, 35)
    KClose.BorderSizePixel  = 0
    KClose.Text             = "✕"
    KClose.TextSize         = 13
    KClose.Font             = Enum.Font.GothamBold
    KClose.TextColor3       = T.CloseRed
    KClose.ZIndex           = 4
    KClose.AutoButtonColor  = false
    Corner(KClose, 7)
    OnClick(KClose, function() SG:Destroy() end)

    -- Body
    local KBody = Instance.new("Frame", KWin)
    KBody.Size                   = UDim2.new(1, 0, 1, -58)
    KBody.Position               = UDim2.new(0, 0, 0, 58)
    KBody.BackgroundTransparency = 1
    KBody.BorderSizePixel        = 0
    KBody.ZIndex                 = 3
    Pad(KBody, 14, 14, 16, 16)

    -- Info
    local Info = Instance.new("TextLabel", KBody)
    Info.Size                   = UDim2.new(1, 0, 0, 28)
    Info.BackgroundTransparency = 1
    Info.BorderSizePixel        = 0
    Info.Text                   = "Key berlaku 24 jam. Klik Copy Link untuk mendapatkan key baru."
    Info.TextSize               = 11
    Info.Font                   = Enum.Font.Gotham
    Info.TextColor3             = T.TextMuted
    Info.TextXAlignment         = Enum.TextXAlignment.Left
    Info.TextWrapped            = true
    Info.ZIndex                 = 4

    -- Input frame
    local InputFrame = Instance.new("Frame", KBody)
    InputFrame.Size             = UDim2.new(1, 0, 0, 40)
    InputFrame.Position         = UDim2.new(0, 0, 0, 36)
    InputFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    InputFrame.BorderSizePixel  = 0
    InputFrame.ZIndex           = 4
    Corner(InputFrame, 8)
    local iStroke = Stroke(InputFrame, T.Stroke, 1)

    local KeyInput = Instance.new("TextBox", InputFrame)
    KeyInput.Size                   = UDim2.new(1, 0, 1, 0)
    KeyInput.BackgroundTransparency = 1
    KeyInput.BorderSizePixel        = 0
    KeyInput.Text                   = ""
    KeyInput.PlaceholderText        = "Masukkan key di sini..."
    KeyInput.PlaceholderColor3      = T.TextMuted
    KeyInput.TextColor3             = T.TextPrimary
    KeyInput.TextSize               = 13
    KeyInput.Font                   = Enum.Font.GothamMedium
    KeyInput.TextXAlignment         = Enum.TextXAlignment.Center
    KeyInput.ClearTextOnFocus       = false
    KeyInput.ZIndex                 = 5
    Pad(KeyInput, 0, 0, 10, 10)

    KeyInput.Focused:Connect(function()  iStroke.Color = T.Accent end)
    KeyInput.FocusLost:Connect(function() iStroke.Color = T.Stroke end)

    -- Status
    local Status = Instance.new("TextLabel", KBody)
    Status.Size                   = UDim2.new(1, 0, 0, 18)
    Status.Position               = UDim2.new(0, 0, 0, 84)
    Status.BackgroundTransparency = 1
    Status.BorderSizePixel        = 0
    Status.Text                   = ""
    Status.TextSize               = 11
    Status.Font                   = Enum.Font.Gotham
    Status.TextColor3             = T.TextMuted
    Status.TextXAlignment         = Enum.TextXAlignment.Center
    Status.ZIndex                 = 4

    -- Tombol row
    local BtnRow = Instance.new("Frame", KBody)
    BtnRow.Size                   = UDim2.new(1, 0, 0, 38)
    BtnRow.Position               = UDim2.new(0, 0, 1, -38)
    BtnRow.BackgroundTransparency = 1
    BtnRow.BorderSizePixel        = 0
    BtnRow.ZIndex                 = 4

    local W     = 360 - 32   -- total lebar tombol area
    local GAP   = 6
    local wCopy = math.floor((W - GAP*2) * 0.36)
    local wApply= math.floor((W - GAP*2) * 0.38)
    local wClose= W - wCopy - wApply - GAP*2

    local function makeBtn(txt, bg, fg, x, w)
        local b = Instance.new("TextButton", BtnRow)
        b.Size             = UDim2.new(0, w, 1, 0)
        b.Position         = UDim2.new(0, x, 0, 0)
        b.BackgroundColor3 = bg
        b.BorderSizePixel  = 0
        b.Text             = txt
        b.TextSize         = 11
        b.Font             = Enum.Font.GothamBold
        b.TextColor3       = fg
        b.AutoButtonColor  = false
        b.ZIndex           = 5
        Corner(b, 7)
        return b
    end

    local BtnCopy  = makeBtn("📋 Copy Link", T.ElementBG,             T.TextSec,                         0,                    wCopy)
    local BtnApply = makeBtn("✓ Apply Key",  T.Accent,                Color3.fromRGB(255,255,255),        wCopy + GAP,          wApply)
    local BtnClose = makeBtn("✕ Close",      Color3.fromRGB(55,30,30),T.CloseRed,                        wCopy+wApply+GAP*2,   wClose)

    -- Hover
    BtnCopy.MouseEnter:Connect(function()  Tween(BtnCopy,  {BackgroundColor3=T.ElementHov}, 0.12) end)
    BtnCopy.MouseLeave:Connect(function()  Tween(BtnCopy,  {BackgroundColor3=T.ElementBG},  0.12) end)
    BtnApply.MouseEnter:Connect(function() Tween(BtnApply, {BackgroundColor3=T.AccentHov},  0.12) end)
    BtnApply.MouseLeave:Connect(function() Tween(BtnApply, {BackgroundColor3=T.Accent},     0.12) end)
    BtnClose.MouseEnter:Connect(function() Tween(BtnClose, {BackgroundColor3=Color3.fromRGB(80,35,35)}, 0.12) end)
    BtnClose.MouseLeave:Connect(function() Tween(BtnClose, {BackgroundColor3=Color3.fromRGB(55,30,30)}, 0.12) end)

    -- Copy
    OnClick(BtnCopy, function()
        setclipboard(keyLink)
        local old = BtnCopy.Text
        BtnCopy.Text      = "✓ Copied!"
        BtnCopy.TextColor3= Color3.fromRGB(80, 220, 120)
        task.delay(1.5, function()
            BtnCopy.Text      = old
            BtnCopy.TextColor3= T.TextSec
        end)
    end)

    -- Close
    OnClick(BtnClose, function() SG:Destroy() end)

    -- Apply
    local busy = false
    OnClick(BtnApply, function()
        if busy then return end
        local key = KeyInput.Text:gsub("^%s*(.-)%s*$", "%1")
        if key == "" then
            Status.Text      = "⚠ Key tidak boleh kosong!"
            Status.TextColor3= Color3.fromRGB(255,180,50)
            return
        end
        busy             = true
        BtnApply.Text    = "Checking..."
        Status.Text      = "Memvalidasi key..."
        Status.TextColor3= T.TextMuted

        task.spawn(function()
            local ok = validateKey(key, keyUrl)
            busy = false
            if ok then
                saveKey(key)
                BtnApply.Text     = "✓ Apply Key"
                Status.Text       = "✓ Key valid! Membuka GUI..."
                Status.TextColor3 = Color3.fromRGB(80, 220, 120)
                task.delay(0.7, function()
                    SG:Destroy()
                    task.spawn(onSuccess)
                end)
            else
                BtnApply.Text     = "✓ Apply Key"
                Status.Text       = "✗ Key tidak valid atau expired!"
                Status.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end)
    end)

    -- Animasi masuk
    Tween(KWin, { BackgroundTransparency = 0 }, 0.18)
    Tween(KWin, { Position = UDim2.new(0.5, -180, 0.5, -134) }, 0.3,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- ================================================================
-- KEY SYSTEM MODULE
-- ================================================================
local KeySystem = {}
KeySystem.__index = KeySystem

--[[
    KeySystem:Check(cfg)

    cfg = {
        KeyUrl    = "https://pastebin.com/raw/...",
        KeyLink   = "https://linkvertise.com/...",
        Theme     = {},         -- opsional, tabel warna dari KreinGui
        OnSuccess = function()  -- dipanggil setelah key valid
            ...
        end,
    }
]]
function KeySystem:Check(cfg)
    cfg = cfg or {}
    local onSuccess = cfg.OnSuccess or function() end

    -- Cek apakah sudah ada key tersimpan yang masih valid
    local saved = loadSavedKey()
    if saved then
        -- Key masih valid, langsung jalankan OnSuccess
        task.spawn(onSuccess)
        return
    end

    -- Belum ada / expired, tampilkan window key
    showKeyWindow(cfg, onSuccess)
end

return KeySystem
