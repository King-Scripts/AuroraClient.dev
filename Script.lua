-- EXPRESS LIBRARY
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Aurora-Script/UiLibSb/refs/heads/main/Uilib"
))()

-- SERVICES
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ============================================================
--  TAMAÑO UI — nil = autodetectar
-- ============================================================
local UISize = {
    Width = nil,
    Scale = nil,
}

-- ============================================================
--  TEMA UI — EDITA AQUÍ
-- ============================================================
local Theme = {
    Accent         = Color3.fromRGB(255,   255, 255),
    Background     = Color3.fromRGB( 17,  16,  20),
    Inline         = Color3.fromRGB( 26,  25,  31),
    Element        = Color3.fromRGB( 41,  40,  49),
    HoveredElement = Color3.fromRGB( 51,  50,  59),
    Text           = Color3.fromRGB(255, 255, 255),
    Border         = Color3.fromRGB( 36,  33,  42),
    Gradient       = Color3.fromRGB(218, 218, 218),
}

-- ============================================================
--  CONFIGURACIÓN AIMBOT — EDITA AQUÍ
-- ============================================================
local Settings = {
    Enabled        = false,
    RadioFOV       = 190,
    AlturaManual   = -1,
    VerticalOffset = -50,
    Smoothness     = 0.35,
    ShowFOV        = false,
    Transparency   = 0.5,
    NormalColor    = Color3.fromRGB(255, 255, 255),
    LockColor      = Color3.fromRGB( 55, 50, 55),
}

-- ============================================================
--  WHITELIST
-- ============================================================
local WhitelistNames = {}

local function isWhitelisted(player)
    return WhitelistNames[player.Name] == true
end

-- ============================================================
--  APLICAR TEMA
-- ============================================================
for key, color in pairs(Theme) do
    pcall(function() Library:ChangeTheme(key, color) end)
end

-- ============================================================
--  AUTODETECT TAMAÑO
-- ============================================================
do
    local vp = Camera.ViewportSize
    if UISize.Width == nil then
        if vp.X <= 320 then
            UISize.Width = 270; UISize.Scale = 0.68
        elseif vp.X <= 480 then
            UISize.Width = 310; UISize.Scale = 0.76
        elseif vp.X <= 768 then
            UISize.Width = 360; UISize.Scale = 0.85
        else
            UISize.Width = 500; UISize.Scale = 1.0
        end
    end
end

-- ============================================================
--  TABLA DE CAÍDA
-- ============================================================
local caidaTable = {
    {dist = 10, offset = -4.4},
    {dist = 20, offset = -5.5},
    {dist = 30, offset = -7.0},
    {dist = 40, offset = -8.8},
    {dist = 50, offset = -10.9},
    {dist = 60, offset = -12.6},
    {dist = 70, offset = -16.0},
}

local function getDynamicCaida(distancia)
    if distancia <= caidaTable[1].dist then return caidaTable[1].offset end
    if distancia >= caidaTable[#caidaTable].dist then return caidaTable[#caidaTable].offset end
    for i = 1, #caidaTable - 1 do
        local p1, p2 = caidaTable[i], caidaTable[i + 1]
        if distancia >= p1.dist and distancia <= p2.dist then
            local t = (distancia - p1.dist) / (p2.dist - p1.dist)
            return p1.offset + (p2.offset - p1.offset) * t
        end
    end
    return -4.4
end

-- ============================================================
--  FOV — ScreenGui (compatible Delta)
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ScreenGui"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder   = 999
pcall(function()
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end)

local fovFrame = Instance.new("Frame")
fovFrame.AnchorPoint            = Vector2.new(0.5, 0.5)
fovFrame.BackgroundTransparency = 1
fovFrame.BorderSizePixel        = 0
fovFrame.Size     = UDim2.fromOffset(Settings.RadioFOV * 2, Settings.RadioFOV * 2)
fovFrame.Position = UDim2.fromScale(0.5, 0.5)
fovFrame.Visible  = Settings.ShowFOV
fovFrame.Parent   = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0)
uiCorner.Parent       = fovFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color           = Settings.NormalColor
uiStroke.Thickness        = 1.5
uiStroke.Transparency     = Settings.Transparency
uiStroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
uiStroke.Parent           = fovFrame

local breathDirection = 1
local breathValue     = 1.5

RunService.RenderStepped:Connect(function()
    local vp = Camera.ViewportSize
    fovFrame.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2 + Settings.VerticalOffset)
    if not Settings.ShowFOV then fovFrame.Visible = false return end
    fovFrame.Visible = true
    breathValue = breathValue + (0.02 * breathDirection)
    if breathValue >= 2.3 then breathDirection = -1
    elseif breathValue <= 1.2 then breathDirection = 1 end
    uiStroke.Thickness = breathValue
end)

local function setFOVColor(c)        uiStroke.Color        = c end
local function setFOVRadius(r)       fovFrame.Size = UDim2.fromOffset(r*2, r*2) end
local function setFOVTransparency(t) uiStroke.Transparency = t end

-- ============================================================
--  HELPERS
-- ============================================================

-- ============================================================
--  VENTANA HUB
-- ============================================================
local Window = Library:MakeWindow({
    Name    = "Aurora Script",
    HomeTab = false,
    Size    = UDim2.fromOffset(UISize.Width, 300),
})

-- UIScale
task.defer(function()
    pcall(function()
        local holder = Library.Holder and Library.Holder.Instance
        if holder then
            local prev = holder:FindFirstChildOfClass("UIScale")
            if prev then prev:Destroy() end
            local s = Instance.new("UIScale")
            s.Scale  = UISize.Scale
            s.Parent = holder
        end
    end)
end)

-- ============================================================
--  TAB PRINCIPAL AIM
-- ============================================================
local MainTab = Window:MakeTab({
    Name = "AimMode",
    Icon = "rbxassetid://10723407389"
})

-- ════════════════════════════════════════════════════════════
--  SUBTAB 1 CONTROL
-- ════════════════════════════════════════════════════════════
local ControlSubTab = MainTab:AddSubTab({
    Name = "AimMode",
    Columns = 1
})

local ControlSection = ControlSubTab:AddSection({
    Name = "Config",
    Side = 1
})

ControlSection:AddToggle({
    Name = "Aim Mode", Flag = "AimMode", Default = Settings.Enabled,
    Callback = function(v) Settings.Enabled = v end
})

ControlSection:AddSlider({
    Name = "Smoothness", Flag = "Smoothness",
    Default = Settings.Smoothness, Min = 0.05, Max = 0.8, Increment = 0.01,
    ValueName = "smooth",
    Callback = function(v) Settings.Smoothness = v end
})

ControlSection:AddSlider({
    Name = "Altura Manual", Flag = "AlturaManual",
    Default = Settings.AlturaManual, Min = -8, Max = 8, Increment = 0.1,
    ValueName = "studs",
    Callback = function(v) Settings.AlturaManual = v end
})

-- ════════════════════════════════════════════════════════════
--  SUBTAB 2 FOV (CAMPO DE VISIÓN)
-- ════════════════════════════════════════════════════════════
local FOVSubTab = MainTab:AddSubTab({
    Name = "Fov",
    Columns = 1
})

local FOVSection = FOVSubTab:AddSection({
    Name = "Fov",
    Side = 1
})

FOVSection:AddToggle({
    Name = "Mostrar FOV", Flag = "ShowFOV", Default = Settings.ShowFOV,
    Callback = function(v) Settings.ShowFOV = v; fovFrame.Visible = v end
})


FOVSection:AddSlider({
    Name = "Radio FOV", Flag = "FOVRadius",
    Default = Settings.RadioFOV, Min = 30, Max = 300, Increment = 5,
    ValueName = "px",
    Callback = function(v) Settings.RadioFOV = v; setFOVRadius(v) end
})

FOVSection:AddSlider({
    Name = "Transparencia", Flag = "Transparency",
    Default = Settings.Transparency, Min = 0, Max = 1, Increment = 0.01,
    ValueName = "%",
    Callback = function(v) Settings.Transparency = v; setFOVTransparency(v) end
})

FOVSection:AddSlider({
    Name = "Offset Vertical", Flag = "VerticalOffset",
    Default = Settings.VerticalOffset, Min = -150, Max = 150, Increment = 1,
    ValueName = "px",
    Callback = function(v) Settings.VerticalOffset = v end
})

local aiming = false

FOVSection:AddColorpicker({
    Name = "Color Normal", Flag = "ColorNormal",
    Default = Settings.NormalColor,
    Callback = function(c)
        Settings.NormalColor = c
        if not aiming then setFOVColor(c) end
    end
})

FOVSection:AddColorpicker({
    Name = "Color Lock", Flag = "ColorLock",
    Default = Settings.LockColor,
    Callback = function(c)
        Settings.LockColor = c
        if aiming then setFOVColor(c) end
    end
})

-- ════════════════════════════════════════════════════════════
--  SUBTAB 3 WHITELIST
-- ════════════════════════════════════════════════════════════
local WhitelistSubTab = MainTab:AddSubTab({
    Name = "Whitelist",
    Columns = 1
})

local WLLeftSection = WhitelistSubTab:AddSection({
    Name = "Agregar Jugador",
    Side = 1
})

-- ── LISTA DE WHITELISTED ───────────────────────────────────
local WLRightSection = WhitelistSubTab:AddSection({
    Name = "Whitelisted",
    Side = 1
})

local wlDisplayLabel = WLRightSection:AddLabel("(vacío)")

-- Definir función ANTES de usarla
local function updateWLList()
    local list = {}
    for name in pairs(WhitelistNames) do table.insert(list, name) end
    table.sort(list)
    
    if #list == 0 then
        wlDisplayLabel:Set("(vacío)")
    else
        local formatted = ""
        for i, name in ipairs(list) do
            formatted = formatted .. "✓ " .. name
            if i < #list then formatted = formatted .. "\n" end
        end
        wlDisplayLabel:Set(formatted)
    end
    
    -- Expandir el label dinámicamente
    task.defer(function()
        pcall(function()
            if wlDisplayLabel and wlDisplayLabel.Instance then
                local labelObj = wlDisplayLabel.Instance
                local lineCount = #list
                if lineCount == 0 then lineCount = 1 end
                
                -- Intentar encontrar el contenedor y expandirlo
                local parent = labelObj.Parent
                while parent do
                    if parent:FindFirstChild("UIListLayout") then
                        parent.Parent.CanvasSize = UDim2.new(0, 0, 0, parent.AbsoluteSize.Y + (lineCount * 25))
                        break
                    end
                    parent = parent.Parent
                end
            end
        end)
    end)
end

local selectedPlayer = nil
local wlDropdown = WLLeftSection:AddDropdown({
    Name     = "Seleccionar Jugador",
    Flag     = "WLDropdown",
    Options  = {},
    Default  = "Cargar...",
    Multi    = false,
    Callback = function(v)
        selectedPlayer = (v ~= "(ninguno)") and v or nil
    end
})

local function refreshDropdown()
    local jugadores = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(jugadores, p.Name) end
    end
    if #jugadores == 0 then table.insert(jugadores, "(ninguno)") end
    wlDropdown:Refresh(jugadores, false)
end

WLLeftSection:AddButton({
    Name = "Agregar",
    Callback = function()
        if selectedPlayer and selectedPlayer ~= "(ninguno)" then
            WhitelistNames[selectedPlayer] = true
            updateWLList()
        end
    end
})

WLLeftSection:AddButton({
    Name = "Limpiar Todo",
    Callback = function()
        WhitelistNames = {}
        updateWLList()
    end
})

Players.PlayerAdded:Connect(function()
    task.wait(0.1)
    refreshDropdown()
end)

Players.PlayerRemoving:Connect(function(p)
    if WhitelistNames[p.Name] then
        WhitelistNames[p.Name] = nil
        updateWLList()
    end
    task.wait(0.1)
    refreshDropdown()
end)

refreshDropdown()
updateWLList()

-- ════════════════════════════════════════════════════════════
--  SUBTAB 4 CRÉDITOS
-- ════════════════════════════════════════════════════════════
local CreditsSubTab = MainTab:AddSubTab({
    Name = "Créditos",
    Columns = 2
})

local CreditsLeftSection = CreditsSubTab:AddSection({
    Name = "Acerca de",
    Side = 1
})

CreditsLeftSection:AddLabel("AimMode")
CreditsLeftSection:AddLabel("v2.0")
CreditsLeftSection:AddLabel("")
CreditsLeftSection:AddLabel("Características")
CreditsLeftSection:AddLabel("• FOV dinámico")
CreditsLeftSection:AddLabel("• Whitelist 50%")
CreditsLeftSection:AddLabel("• SemiAutomatico")
CreditsLeftSection:AddLabel("• Configurable")

local CreditsRightSection = CreditsSubTab:AddSection({
    Name = "Información",
    Side = 2
})

CreditsRightSection:AddLabel(" Versión 2.0")
CreditsRightSection:AddLabel(" Creador Gossd")
CreditsRightSection:AddLabel(" Actualizado 25/5/2026")
CreditsRightSection:AddLabel("")
CreditsRightSection:AddLabel(" Seguridad")
CreditsRightSection:AddLabel("BypassV1")
CreditsRightSection:AddLabel("Disfraz de OPc")

-- ============================================================
--  LÓGICA AIMBOT
-- ============================================================
local maxDist = caidaTable[#caidaTable].dist

RunService.RenderStepped:Connect(function()
    if not Settings.Enabled then
        aiming = false
        setFOVColor(Settings.NormalColor)
        return
    end

    local closestPlayer   = nil
    local closestDistance = Settings.RadioFOV
    local vp     = Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2) + Vector2.new(0, Settings.VerticalOffset)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if isWhitelisted(player) then continue end
        if not player.Character then continue end

        local head = player.Character:FindFirstChild("Head")
        if not head then continue end

        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        local pos, visible = Camera:WorldToViewportPoint(head.Position)
        if not visible then continue end

        local screenDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        local worldDist  = (Camera.CFrame.Position - head.Position).Magnitude

        if screenDist <= Settings.RadioFOV and worldDist <= maxDist then
            if screenDist < closestDistance then
                closestDistance = screenDist
                closestPlayer   = player
            end
        end
    end

    if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
        if not aiming then aiming = true; setFOVColor(Settings.LockColor) end
        local head     = closestPlayer.Character.Head
        local distance = (Camera.CFrame.Position - head.Position).Magnitude
        local caida    = getDynamicCaida(distance)
        local finalPos = head.Position + Vector3.new(0, caida + Settings.AlturaManual, 0)
        Camera.CFrame  = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, finalPos), Settings.Smoothness)
        setFOVColor(Settings.LockColor)
    else
        if aiming then aiming = false; setFOVColor(Settings.NormalColor) end
    end
end)
