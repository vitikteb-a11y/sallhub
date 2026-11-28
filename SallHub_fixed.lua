-- SALL HUB | AXIOM MONO EDITION (FULL · AIM REWRITE)
-- Silent aim: история позиций, упреждение на RTT + интерполяцию, авто-wallbang, повторные выстрелы.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local DEFAULT_SPEED = 16
local DEFAULT_JUMP = 50

local Theme = {
    Bg        = Color3.fromRGB(12, 12, 16),
    Surface   = Color3.fromRGB(18, 18, 24),
    Card      = Color3.fromRGB(24, 24, 32),
    CardHover = Color3.fromRGB(32, 32, 42),
    Stroke    = Color3.fromRGB(44, 44, 56),
    Accent    = Color3.fromRGB(255, 255, 255),
    AccentDim = Color3.fromRGB(160, 160, 170),
    Green     = Color3.fromRGB(80, 220, 130),
    Red       = Color3.fromRGB(230, 70, 70),
    Text      = Color3.fromRGB(235, 235, 242),
    TextDim   = Color3.fromRGB(120, 120, 135),
}

local ROLE_COLORS = {
    Innocent = Color3.fromRGB(0, 255, 80),
    Sheriff  = Color3.fromRGB(0, 0, 255),
    Hero     = Color3.fromRGB(0, 0, 255),
    Murderer = Color3.fromRGB(225, 0, 0),
    Unknown  = Color3.fromRGB(200, 200, 200),
}

local W, H = 340, 280
local SIDEBAR = 82
local PAD = 8
local MIN_W, MAX_W = 300, 900
local MIN_H, MAX_H = 220, 700
local currentW, currentH = W, H -- меняется ручкой растяжения
local function startPosFor(w, h) return UDim2.new(0.5, -w/2, 0.5, -h/2) end
local START_POS = startPosFor(W, H)

-- Флаги
local SilentAimEnabled  = true
local WallbangEnabled   = true
local PredictionEnabled = true
local SpinEnabled  = false
local SpinSpeed    = 10
local BhopEnabled  = false

-- ============================================================
-- GUI ROOT
-- ============================================================
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
for _, gui in ipairs(PlayerGui:GetChildren()) do
    if gui.Name == "SallCheatUI" or gui.Name == "SallAnim" or gui.Name == "SallCrosshair" then
        gui:Destroy()
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SallCheatUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 2147483647
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local BtnLayer = Instance.new("Frame")
BtnLayer.Name = "SallBtnLayer"
BtnLayer.Size = UDim2.new(1, 0, 1, 0)
BtnLayer.BackgroundTransparency = 1
BtnLayer.ZIndex = 100
BtnLayer.Parent = ScreenGui

local Trigger = Instance.new("TextButton")
Trigger.Size = UDim2.new(0, 200, 0, 4)
Trigger.Position = UDim2.new(0.5, 20, 1, -6)
Trigger.AnchorPoint = Vector2.new(0.5, 1)
Trigger.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Trigger.BackgroundTransparency = 0.15
Trigger.Text = ""
Trigger.AutoButtonColor = false
Trigger.Active = true
Trigger.ZIndex = 101
Trigger.Parent = BtnLayer
Instance.new("UICorner", Trigger).CornerRadius = UDim.new(1, 0)

local ShotBtn = Instance.new("TextButton")
ShotBtn.Size = UDim2.new(0, 200, 0, 56)
ShotBtn.Position = UDim2.new(0.5, -100, 0.5, -70)
ShotBtn.BackgroundColor3 = Theme.Surface
ShotBtn.BackgroundTransparency = 0.15
ShotBtn.Text = "SHOT MURDER"
ShotBtn.TextColor3 = Theme.Text
ShotBtn.TextSize = 16
ShotBtn.Font = Enum.Font.GothamBold
ShotBtn.AutoButtonColor = false
ShotBtn.Active = true
ShotBtn.Visible = false
ShotBtn.ZIndex = 101
ShotBtn.Parent = BtnLayer
Instance.new("UICorner", ShotBtn).CornerRadius = UDim.new(0, 8)

local KnifeBtn = Instance.new("TextButton")
KnifeBtn.Size = UDim2.new(0, 200, 0, 56)
KnifeBtn.Position = UDim2.new(0.5, -100, 0.5, 10)
KnifeBtn.BackgroundColor3 = Theme.Surface
KnifeBtn.BackgroundTransparency = 0.15
KnifeBtn.Text = "THROW KNIFE"
KnifeBtn.TextColor3 = Theme.Text
KnifeBtn.TextSize = 16
KnifeBtn.Font = Enum.Font.GothamBold
KnifeBtn.AutoButtonColor = false
KnifeBtn.Active = true
KnifeBtn.Visible = false
KnifeBtn.ZIndex = 101
KnifeBtn.Parent = BtnLayer
Instance.new("UICorner", KnifeBtn).CornerRadius = UDim.new(0, 8)

-- Снег в меню
local MenuSnowCanvas = Instance.new("Frame")
MenuSnowCanvas.Size = UDim2.new(1, 0, 1, 0)
MenuSnowCanvas.BackgroundTransparency = 1
MenuSnowCanvas.ClipsDescendants = true
MenuSnowCanvas.ZIndex = 0
MenuSnowCanvas.Parent = nil

local snowDots = {}
local function createSnowDot()
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, math.random(2, 5), 0, math.random(2, 5))
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BackgroundTransparency = math.random(30, 85) / 100
    dot.BorderSizePixel = 0
    dot.ZIndex = 0
    dot.Position = UDim2.new(math.random(), 0, -0.05, 0)
    dot.Parent = MenuSnowCanvas
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    snowDots[#snowDots+1] = {
        frame = dot,
        speed = math.random(15, 70) / 1000,
        drift = math.random(-6, 6) / 1000,
    }
end

task.spawn(function()
    while true do
        task.wait(0.12)
        if #snowDots < 80 then createSnowDot() end
        if #snowDots < 80 then createSnowDot() end
    end
end)

RunService.RenderStepped:Connect(function()
    for i = #snowDots, 1, -1 do
        local d = snowDots[i]
        if not d.frame or not d.frame.Parent then
            table.remove(snowDots, i)
        else
            local pos = d.frame.Position
            local newY = pos.Y.Scale + d.speed
            local newX = pos.X.Scale + d.drift
            if newY > 1.05 then
                d.frame:Destroy()
                table.remove(snowDots, i)
            else
                d.frame.Position = UDim2.new(newX, 0, newY, 0)
            end
        end
    end
end)

-- ============================================================
-- ГЛАВНОЕ МЕНЮ
-- ============================================================
local Menu = Instance.new("Frame")
Menu.Size = UDim2.new(0, W, 0, H)
Menu.Position = START_POS
Menu.Visible = false
Menu.Active = true
Menu.Draggable = true
Menu.ClipsDescendants = true
Menu.Parent = ScreenGui
Menu.BackgroundColor3 = Theme.Bg
Menu.BorderSizePixel = 0
Menu.ZIndex = 200
Instance.new("UICorner", Menu).CornerRadius = UDim.new(0, 12)
local menuStroke = Instance.new("UIStroke", Menu)
menuStroke.Color = Theme.Stroke
menuStroke.Thickness = 1

MenuSnowCanvas.Parent = Menu
MenuSnowCanvas.ZIndex = 0

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 32)
Header.BackgroundTransparency = 1
Header.Active = true
Header.ZIndex = 202
Header.Parent = Menu

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SALL HUB"
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 203
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -70, 1, 0)
SubTitle.Position = UDim2.new(0, 12, 0, 12)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "clean · axiom"
SubTitle.TextColor3 = Theme.TextDim
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 8
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.ZIndex = 203
SubTitle.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Theme.TextDim
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.AutoButtonColor = false
CloseBtn.BackgroundTransparency = 1
CloseBtn.ZIndex = 203
CloseBtn.Parent = Header
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Theme.Red end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Theme.TextDim end)

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -24, 0, 1)
Divider.Position = UDim2.new(0, 12, 0, 32)
Divider.BackgroundColor3 = Theme.Stroke
Divider.BorderSizePixel = 0
Divider.ZIndex = 202
Divider.Parent = Menu

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, SIDEBAR, 1, -42)
Sidebar.Position = UDim2.new(0, PAD, 0, 38)
Sidebar.BackgroundTransparency = 1
Sidebar.ZIndex = 202
Sidebar.Parent = Menu

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 3)
SidebarLayout.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -SIDEBAR - PAD*3, 1, -42)
Content.Position = UDim2.new(0, SIDEBAR + PAD*2, 0, 38)
Content.BackgroundTransparency = 1
Content.ZIndex = 202
Content.Parent = Menu

-- ============================================================
-- РАСТЯЖЕНИЕ ОКНА (ручка в углу)
-- ============================================================
local ResizeHandle = Instance.new("Frame")
ResizeHandle.Size = UDim2.new(0, 18, 0, 18)
ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.Active = true
ResizeHandle.ZIndex = 210
ResizeHandle.Parent = Menu

local grip = Instance.new("TextLabel")
grip.Size = UDim2.new(1, 0, 1, 0)
grip.BackgroundTransparency = 1
grip.Text = "⋰"
grip.Rotation = 90
grip.TextColor3 = Theme.TextDim
grip.Font = Enum.Font.GothamBold
grip.TextSize = 16
grip.ZIndex = 210
grip.Parent = ResizeHandle
ResizeHandle.MouseEnter:Connect(function() grip.TextColor3 = Theme.Accent end)
ResizeHandle.MouseLeave:Connect(function() grip.TextColor3 = Theme.TextDim end)

local resizing = false
local resizeStart, sizeStart
ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        sizeStart = Vector2.new(currentW, currentH)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStart
        currentW = math.clamp(sizeStart.X + delta.X, MIN_W, MAX_W)
        currentH = math.clamp(sizeStart.Y + delta.Y, MIN_H, MAX_H)
        Menu.Size = UDim2.new(0, currentW, 0, currentH)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

-- ============================================================
-- ПЕРЕТАСКИВАНИЕ
-- ============================================================
local dragging = false
local dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Menu.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ============================================================
-- ХЕЛПЕРЫ
-- ============================================================
local function makeCard(parent, title)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, 0, 0, 0)
    Card.AutomaticSize = Enum.AutomaticSize.Y
    Card.BackgroundColor3 = Theme.Surface
    Card.BorderSizePixel = 0
    Card.ZIndex = 203
    Card.Parent = parent
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", Card); stroke.Color = Theme.Stroke; stroke.Thickness = 1
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 5); layout.Parent = Card
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8); padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 10); padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = Card
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 14); lbl.BackgroundTransparency = 1
    lbl.Text = title; lbl.TextColor3 = Theme.TextDim
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 204; lbl.Parent = Card
    return Card
end

local function makeToggle(parent, text, default, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 22); Row.BackgroundTransparency = 1; Row.ZIndex = 204; Row.Parent = parent
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -40, 1, 0); Label.BackgroundTransparency = 1
    Label.Text = text; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.Gotham
    Label.TextSize = 10; Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 204; Label.Parent = Row
    local state = default
    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 26, 0, 14); Switch.Position = UDim2.new(1, -26, 0.5, -7)
    Switch.BackgroundColor3 = state and Theme.Accent or Theme.Stroke
    Switch.Text = ""; Switch.AutoButtonColor = false; Switch.ZIndex = 204; Switch.Parent = Row
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 10, 0, 10)
    Knob.Position = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
    Knob.BackgroundColor3 = Theme.Bg; Knob.ZIndex = 205; Knob.Parent = Switch
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
    Switch.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(Switch, TweenInfo.new(0.15), {BackgroundColor3 = state and Theme.Accent or Theme.Stroke}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)}):Play()
        callback(state)
    end)
    return Row
end

local function makeSlider(parent, text, min, max, default, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 30); Row.BackgroundTransparency = 1; Row.ZIndex = 204; Row.Parent = parent
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -44, 0, 11); Label.BackgroundTransparency = 1
    Label.Text = text; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.Gotham
    Label.TextSize = 10; Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 204; Label.Parent = Row
    local ValueLbl = Instance.new("TextLabel")
    ValueLbl.Size = UDim2.new(0, 40, 0, 11); ValueLbl.Position = UDim2.new(1, -40, 0, 0)
    ValueLbl.BackgroundTransparency = 1; ValueLbl.Text = tostring(default)
    ValueLbl.TextColor3 = Theme.Accent; ValueLbl.Font = Enum.Font.GothamBold
    ValueLbl.TextSize = 10; ValueLbl.TextXAlignment = Enum.TextXAlignment.Right
    ValueLbl.ZIndex = 204; ValueLbl.Parent = Row
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, 0, 0, 2); Track.Position = UDim2.new(0, 0, 0, 20)
    Track.BackgroundColor3 = Theme.Stroke; Track.ZIndex = 204; Track.Parent = Row
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent; Fill.ZIndex = 204; Fill.Parent = Track
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    local SliderKnob = Instance.new("Frame")
    SliderKnob.Size = UDim2.new(0, 8, 0, 8); SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    SliderKnob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    SliderKnob.BackgroundColor3 = Theme.Accent; SliderKnob.ZIndex = 205; SliderKnob.Parent = Track
    Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)
    local sliderDragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel + 0.5)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        SliderKnob.Position = UDim2.new(rel, 0, 0.5, 0)
        ValueLbl.Text = tostring(val)
        callback(val)
    end
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging = true; updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging = false
        end
    end)
    return Row
end

local function makeButton(parent, text, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 24); Btn.BackgroundColor3 = color or Theme.Card
    Btn.BorderSizePixel = 0; Btn.Text = text; Btn.TextColor3 = Theme.Text
    Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 9
    Btn.AutoButtonColor = false; Btn.ZIndex = 204; Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)
    Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.CardHover}):Play() end)
    Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.12), {BackgroundColor3 = color or Theme.Card}):Play() end)
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

local function makeInput(parent, placeholder)
    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(1, 0, 0, 24); Box.BackgroundColor3 = Theme.Card
    Box.BorderSizePixel = 0; Box.Text = ""; Box.PlaceholderText = placeholder
    Box.TextColor3 = Theme.Text; Box.PlaceholderColor3 = Theme.TextDim
    Box.Font = Enum.Font.Gotham; Box.TextSize = 9; Box.ClearTextOnFocus = false
    Box.ZIndex = 204; Box.Parent = parent
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 5)
    local stroke = Instance.new("UIStroke", Box); stroke.Color = Theme.Stroke; stroke.Thickness = 1
    return Box
end

local function makeFlingBtn(parent, text, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 32); Btn.BackgroundColor3 = color
    Btn.BorderSizePixel = 0; Btn.Text = text; Btn.TextColor3 = Theme.Text
    Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 11
    Btn.AutoButtonColor = false; Btn.ZIndex = 204; Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Btn.MouseButton1Click:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.08), {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Bg}):Play()
        task.delay(0.2, function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = color, TextColor3 = Theme.Text}):Play()
        end)
        callback()
    end)
    return Btn
end

-- ТАБЫ
local Tabs = {}
local ActiveTab = nil

local function createTab(id, label)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 26); Btn.Text = "  " .. label
    Btn.Font = Enum.Font.Gotham; Btn.TextSize = 10
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.AutoButtonColor = false; Btn.ZIndex = 204; Btn.Parent = Sidebar
    Btn.BackgroundColor3 = Theme.Surface; Btn.TextColor3 = Theme.TextDim
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 14); indicator.Position = UDim2.new(0, -7, 0.5, -7)
    indicator.BackgroundColor3 = Theme.Accent; indicator.BorderSizePixel = 0
    indicator.Visible = false; indicator.ZIndex = 205; indicator.Parent = Btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 2; Page.ScrollBarImageColor3 = Theme.Accent
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.Visible = false; Page.ZIndex = 203; Page.Parent = Content
    local PageLayout = Instance.new("UIListLayout")
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, 6); PageLayout.Parent = Page
    Tabs[id] = { Button = Btn, Page = Page, Indicator = indicator }
    Btn.MouseEnter:Connect(function() if ActiveTab ~= id then Btn.BackgroundColor3 = Theme.CardHover end end)
    Btn.MouseLeave:Connect(function() if ActiveTab ~= id then Btn.BackgroundColor3 = Theme.Surface end end)
end

local function selectTab(id)
    if ActiveTab == id then return end
    if ActiveTab and Tabs[ActiveTab] then
        Tabs[ActiveTab].Page.Visible = false
        Tabs[ActiveTab].Button.BackgroundColor3 = Theme.Surface
        Tabs[ActiveTab].Button.TextColor3 = Theme.TextDim
        Tabs[ActiveTab].Indicator.Visible = false
    end
    ActiveTab = id
    local tab = Tabs[id]
    tab.Page.Visible = true
    tab.Button.BackgroundColor3 = Theme.Card
    tab.Button.TextColor3 = Theme.Text
    tab.Indicator.Visible = true
end

createTab("Visuals", "Визуалы")
createTab("Combat", "Бой")
createTab("Utility", "Утилиты")

for id, tab in pairs(Tabs) do
    tab.Button.MouseButton1Click:Connect(function() selectTab(id) end)
end

-- РОЛИ
local roles = {}
local Murder, Sheriff, Hero

local function IsAlive(Player)
    if not Player then return false end
    for i, v in pairs(roles) do
        if Player.Name == i then return not v.Killed and not v.Dead end
    end
    return false
end

local function GetRoles()
    local ok, result = pcall(function()
        return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    end)
    if ok and result then
        roles = result
        Murder, Sheriff, Hero = nil, nil, nil
        for i, v in pairs(roles) do
            if v.Role == "Murderer" then Murder = i
            elseif v.Role == "Sheriff" then Sheriff = i
            elseif v.Role == "Hero" then Hero = i end
        end
    end
end

local function getMurderer()
    if Murder then
        local p = Players:FindFirstChild(Murder)
        if p and p.Character then return p end
    end
    return nil
end

local function getSheriff()
    if Sheriff then
        local p = Players:FindFirstChild(Sheriff)
        if p and p.Character then return p end
    end
    return nil
end

task.spawn(function() while true do GetRoles(); task.wait(1) end end)

-- ============================================================
-- ВИЗУАЛЫ
-- ============================================================
local VisualsPage = Tabs["Visuals"].Page
local ESPEnabled = false

local espCard = makeCard(VisualsPage, "ESP")
makeToggle(espCard, "ESP (Роли)", false, function(state)
    ESPEnabled = state
    if not state then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                local hl = plr.Character:FindFirstChild("Highlight")
                if hl then hl:Destroy() end
            end
        end
    end
end)

local function HighlightPlayer(player)
    if not (player and player:IsA("Player") and player.Character) then return end
    local color = ROLE_COLORS.Innocent
    if Sheriff and player.Name == Sheriff and IsAlive(player) then color = ROLE_COLORS.Sheriff
    elseif Murder and player.Name == Murder and IsAlive(player) then color = ROLE_COLORS.Murderer
    elseif Hero and player.Name == Hero and IsAlive(player) then color = ROLE_COLORS.Hero end
    local HL = player.Character:FindFirstChild("Highlight")
    if not HL then
        HL = Instance.new("Highlight", player.Character)
        HL.OutlineTransparency = 1
        HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
    HL.FillColor = color; HL.OutlineColor = color
end

RunService.RenderStepped:Connect(function()
    if not ESPEnabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then HighlightPlayer(plr) end
    end
end)

local TracersEnabled = false
local TracersCache = {}
local tracersCard = makeCard(VisualsPage, "ТРЕЙСЕРЫ")
makeToggle(tracersCard, "Tracers (Постоянные)", false, function(state)
    TracersEnabled = state
    if not state then
        for _, t in pairs(TracersCache) do if t and t.Remove then t:Remove() end end
        TracersCache = {}
    end
end)
RunService.RenderStepped:Connect(function()
    if not TracersEnabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    if not TracersCache[plr] then
                        local t = Drawing.new("Line")
                        t.Thickness = 1.5; t.Color = Color3.fromRGB(200, 200, 200); t.Transparency = 1
                        TracersCache[plr] = t
                    end
                    TracersCache[plr].From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                    TracersCache[plr].To = Vector2.new(pos.X, pos.Y)
                    TracersCache[plr].Visible = true
                elseif TracersCache[plr] then TracersCache[plr].Visible = false end
            end
        end
    end
end)

-- ============================================================
-- НЕОНОВЫЕ ОРБЫ ВОКРУГ ИГРОКА (локально, видишь только ты)
-- ============================================================
local ORB_MAX = 4
local OrbsEnabled = true
local OrbCount = 2
local OrbRadius = 4.5
local OrbSpeed = 2.5
local OrbFolder = Instance.new("Folder")
OrbFolder.Name = "SallOrbs"
OrbFolder.Parent = workspace
local OrbList = {}
local orbAngle = 0

local function clearOrbs()
    for _, part in ipairs(OrbList) do
        if part and part.Parent then part:Destroy() end
    end
    OrbList = {}
end

local function rebuildOrbs()
    clearOrbs()
    if not OrbsEnabled then return end
    if not OrbFolder.Parent then OrbFolder.Parent = workspace end
    local count = math.clamp(OrbCount, 0, ORB_MAX)
    for i = 1, count do
        local orb = Instance.new("Part")
        orb.Name = "SallOrb_" .. i
        orb.Shape = Enum.PartType.Ball
        orb.Material = Enum.Material.Neon
        orb.Color = Color3.fromRGB(255, 255, 255)
        orb.Transparency = 0.05
        orb.Size = Vector3.new(1.2, 1.2, 1.2)
        orb.Anchored = true
        orb.CanCollide = false
        orb.CanTouch = false
        orb.CanQuery = false
        orb.CastShadow = false
        orb.Massless = true
        orb.TopSurface = Enum.SurfaceType.Smooth
        orb.BottomSurface = Enum.SurfaceType.Smooth
        orb.CFrame = CFrame.new(0, -1000, 0)
        orb.Parent = OrbFolder
        OrbList[i] = orb
    end
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if not OrbFolder.Parent then OrbFolder.Parent = workspace end
end)

RunService.RenderStepped:Connect(function(dt)
    if not OrbsEnabled or #OrbList == 0 then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        for _, orb in ipairs(OrbList) do
            if orb and orb.Parent then orb.CFrame = CFrame.new(0, -1000, 0) end
        end
        return
    end
    orbAngle = orbAngle + dt * OrbSpeed
    local center = hrp.Position + Vector3.new(0, 2.6, 0)
    local n = #OrbList
    for i, orb in ipairs(OrbList) do
        if orb and orb.Parent then
            local a = orbAngle + (i - 1) * (math.pi * 2 / n)
            local bob = math.sin(orbAngle * 2 + i * 1.7) * 0.35
            orb.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * OrbRadius, bob, math.sin(a) * OrbRadius))
        end
    end
end)

local orbCard = makeCard(VisualsPage, "ОРБЫ")
makeToggle(orbCard, "Неоновые орбы", true, function(state) OrbsEnabled = state; rebuildOrbs() end)
makeSlider(orbCard, "Количество орбов (макс " .. ORB_MAX .. ")", 1, ORB_MAX, 2, function(v) OrbCount = v; rebuildOrbs() end)
makeSlider(orbCard, "Радиус орбиты", 2, 10, 4, function(v) OrbRadius = v end)
makeSlider(orbCard, "Скорость вращения ×10", 5, 60, 25, function(v) OrbSpeed = v / 10 end)
rebuildOrbs()

local worldCard = makeCard(VisualsPage, "МИР")
local originalFog = Lighting.FogEnd
makeToggle(worldCard, "No Fog", false, function(s) Lighting.FogEnd = s and 9e9 or originalFog end)
makeSlider(worldCard, "Time of Day", 0, 24, 14, function(v) Lighting.TimeOfDay = string.format("%02d:00:00", v) end)

-- "Растяжка экрана": разрешение Roblox менять не даёт (это система/драйвер),
-- но широкий угол обзора реально растягивает картинку мира.
-- Меню — отдельный ScreenGui, камера его не трогает, поэтому оно не растягивается.
local DesiredFOV = 70
local ScreenStretch = 0
local function applyCamera()
    local cam = workspace.CurrentCamera
    if not cam then return end
    cam.FieldOfViewMode = Enum.FieldOfViewMode.Vertical
    local fov = DesiredFOV + (ScreenStretch / 100) * (120 - DesiredFOV)
    cam.FieldOfView = math.clamp(fov, 1, 120)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(applyCamera)
makeSlider(worldCard, "FOV / Обзор", 30, 120, 70, function(v) DesiredFOV = v; applyCamera() end)
makeSlider(worldCard, "Растяжка экрана (0-100)", 0, 100, 0, function(v) ScreenStretch = v; applyCamera() end)

local CrosshairEnabled = false
local CrosshairGui = Instance.new("ScreenGui", PlayerGui)
CrosshairGui.Name = "SallCrosshair"; CrosshairGui.ResetOnSpawn = false; CrosshairGui.IgnoreGuiInset = true
local CrosshairDot = Instance.new("Frame", CrosshairGui)
CrosshairDot.Size = UDim2.new(0, 4, 0, 4); CrosshairDot.Position = UDim2.new(0.5, -2, 0.5, -2)
CrosshairDot.BackgroundColor3 = Theme.Accent; CrosshairDot.BorderSizePixel = 0; CrosshairDot.Visible = false
Instance.new("UICorner", CrosshairDot).CornerRadius = UDim.new(1, 0)
makeToggle(worldCard, "Custom Crosshair", false, function(s) CrosshairEnabled = s; CrosshairDot.Visible = s end)

-- Снег в мире
local SnowEnabled = false
local SnowParticles = 200
local SnowSpeed = 1
local SnowSizeMultiplier = 1
local SnowFolder = Instance.new("Folder"); SnowFolder.Name = "SallSnowFX"; SnowFolder.Parent = workspace

local function spawnSnowflake()
    if not SnowEnabled then return end
    local cam = workspace.CurrentCamera
    local pos = cam.CFrame.Position + Vector3.new(math.random(-60,60), math.random(20,60), math.random(-60,60))
    local finalSize = (math.random(4,10)/10) * SnowSizeMultiplier
    local flake = Instance.new("Part")
    flake.Size = Vector3.new(finalSize, finalSize, finalSize)
    flake.Shape = Enum.PartType.Ball; flake.Material = Enum.Material.SmoothPlastic
    flake.Color = Color3.fromRGB(255,255,255); flake.Transparency = math.random(10,40)/100
    flake.CanCollide = false; flake.Anchored = true
    flake.CFrame = CFrame.new(pos) * CFrame.Angles(math.random()*math.pi, math.random()*math.pi, math.random()*math.pi)
    flake.Parent = SnowFolder
    local fallDist = math.random(40,80)
    local fallTime = math.random(30,60)/10/SnowSpeed
    local driftX = math.random(-5,5); local driftZ = math.random(-5,5); local spin = math.random(-2,2)
    local startCF = flake.CFrame; local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not SnowEnabled or not flake or not flake.Parent then
            if conn then conn:Disconnect() end; return
        end
        local t = (tick()-startTime)/fallTime
        if t >= 1 then conn:Disconnect(); if flake then flake:Destroy() end; return end
        flake.CFrame = CFrame.new(startCF.Position + Vector3.new(driftX*t, -fallDist*t, driftZ*t)) * (startCF - startCF.Position) * CFrame.Angles(0, spin*t, 0)
        if t > 0.6 then flake.Transparency = math.clamp((t-0.6)/0.4, 0, 1) end
    end)
end
task.spawn(function()
    while true do
        task.wait(0.05)
        if SnowEnabled then
            local cur = #SnowFolder:GetChildren()
            if cur < SnowParticles then for _ = 1, math.min(5, SnowParticles - cur) do spawnSnowflake() end end
        end
    end
end)

local snowCard = makeCard(VisualsPage, "СНЕГ")
makeToggle(snowCard, "Snow Effect", false, function(state)
    SnowEnabled = state
    if not state then for _, f in ipairs(SnowFolder:GetChildren()) do f:Destroy() end end
end)
makeSlider(snowCard, "Количество снежинок", 50, 1000, 200, function(v) SnowParticles = v end)
makeSlider(snowCard, "Скорость снега ×10", 5, 30, 10, function(v) SnowSpeed = v/10 end)
makeSlider(snowCard, "Размер снега ×10", 5, 50, 10, function(v) SnowSizeMultiplier = v/10 end)

-- Шлейфы
local LegTrailsEnabled = false
local legTrails = {}
local function setupLegTrails(character)
    if not character then return end
    local leftLeg  = character:FindFirstChild("Left Leg")  or character:FindFirstChild("LeftFoot")
    local rightLeg = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightFoot")
    if not leftLeg or not rightLeg then return end
    for _, t in ipairs(character:GetDescendants()) do
        if t:IsA("Trail") and t.Name:find("SallLegTrail") then t:Destroy() end
        if t:IsA("Attachment") and t.Name:find("SallLegAtt") then t:Destroy() end
    end
    local function makeTrail(part, side)
        local a0 = Instance.new("Attachment"); a0.Name="SallLegAtt0_"..side; a0.Position=Vector3.new(0,0.45,0); a0.Parent=part
        local a1 = Instance.new("Attachment"); a1.Name="SallLegAtt1_"..side; a1.Position=Vector3.new(0,-0.45,0); a1.Parent=part
        local trail = Instance.new("Trail")
        trail.Name="SallLegTrail_"..side; trail.Attachment0=a0; trail.Attachment1=a1
        trail.Lifetime=0.45; trail.MinLength=0.1
        trail.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0.6),NumberSequenceKeypoint.new(1,0)})
        trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(0.4,0.35),NumberSequenceKeypoint.new(1,1)})
        trail.Color=ColorSequence.new(Color3.fromRGB(255,255,255))
        trail.LightEmission=1; trail.LightInfluence=0; trail.FaceCamera=true
        trail.Parent=part
        return trail
    end
    legTrails[character] = { left=makeTrail(leftLeg,"L"), right=makeTrail(rightLeg,"R") }
end
local function removeLegTrails(character)
    if not character then return end
    for _, t in ipairs(character:GetDescendants()) do
        if t:IsA("Trail") and t.Name:find("SallLegTrail") then t:Destroy() end
        if t:IsA("Attachment") and t.Name:find("SallLegAtt") then t:Destroy() end
    end
    legTrails[character] = nil
end
local legTrailCard = makeCard(VisualsPage, "ШЛЕЙФЫ ЗА НОГАМИ")
makeToggle(legTrailCard, "Неоновые шлейфы (только на меня)", false, function(state)
    LegTrailsEnabled = state
    if state then
        if LocalPlayer.Character then setupLegTrails(LocalPlayer.Character) end
    else
        for char in pairs(legTrails) do removeLegTrails(char) end
    end
end)
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if LegTrailsEnabled then setupLegTrails(char) end
end)

-- Дезинтеграция
local DisintegrationEnabled = false
local DisintegrationParticles = 150
local DisintegrationColor = Color3.fromRGB(255,255,255)
local function spawnDisintegration(character)
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local originCFrame = hrp.CFrame
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then part.Transparency=1; part.CanCollide=false
        elseif part:IsA("Decal") or part:IsA("Texture") then part.Transparency=1
        elseif part:IsA("BillboardGui") then part.Enabled=false end
    end
    local folder = Instance.new("Folder"); folder.Name="DisintegrationFX"; folder.Parent=workspace
    for _ = 1, DisintegrationParticles do
        local size = math.random(3,8)/10
        local particle = Instance.new("Part")
        particle.Size=Vector3.new(size,size,size); particle.Material=Enum.Material.Neon
        particle.Color=DisintegrationColor; particle.Transparency=0.1
        particle.CanCollide=false; particle.Anchored=false; particle.Massless=true
        particle.CFrame=originCFrame*CFrame.new(math.random(-15,15)/10,math.random(-25,25)/10,math.random(-15,15)/10)
        particle.Shape=Enum.PartType.Ball; particle.Parent=folder
        local dir=Vector3.new(math.random(-100,100)/100,math.random(-50,150)/100,math.random(-100,100)/100).Unit
        local vel=Instance.new("BodyVelocity"); vel.Velocity=dir*math.random(15,45); vel.MaxForce=Vector3.new(math.huge,math.huge,math.huge); vel.Parent=particle
        local ang=Instance.new("BodyAngularVelocity"); ang.AngularVelocity=Vector3.new(math.random(-10,10),math.random(-10,10),math.random(-10,10)); ang.MaxTorque=Vector3.new(math.huge,math.huge,math.huge); ang.Parent=particle
        task.delay(0.15, function() if vel then vel:Destroy() end; if particle then particle.CanCollide=true end end)
        local ft=math.random(80,150)/100
        TweenService:Create(particle,TweenInfo.new(ft,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=1,Size=Vector3.new(0.05,0.05,0.05)}):Play()
        task.delay(ft+0.1, function() if particle then particle:Destroy() end end)
    end
    local flash=Instance.new("Part"); flash.Size=Vector3.new(1,1,1); flash.CFrame=originCFrame; flash.Material=Enum.Material.Neon; flash.Color=DisintegrationColor; flash.Transparency=0; flash.CanCollide=false; flash.Anchored=true; flash.Shape=Enum.PartType.Ball; flash.Parent=folder
    TweenService:Create(flash,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(15,15,15),Transparency=1}):Play()
    task.delay(0.5, function() if flash then flash:Destroy() end end)
    local snd=Instance.new("Sound"); snd.SoundId="rbxassetid://9118823109"; snd.Volume=3; snd.PlaybackSpeed=math.random(90,110)/100; snd.Parent=folder; snd:Play()
    task.delay(3, function() if snd then snd:Destroy() end end)
    local lt=Instance.new("PointLight"); lt.Color=DisintegrationColor; lt.Brightness=5; lt.Range=25; lt.Parent=flash
    TweenService:Create(lt,TweenInfo.new(0.5),{Brightness=0}):Play()
    task.delay(4, function() if folder then folder:Destroy() end end)
end
local disCard = makeCard(VisualsPage, "ДЕЗИНТЕГРАЦИЯ")
makeToggle(disCard, "Murderer Disintegration", false, function(state) DisintegrationEnabled = state end)
makeSlider(disCard, "Количество частиц", 50, 300, 150, function(v) DisintegrationParticles = v end)

-- ============================================================
-- МАГИЧЕСКИЕ ТРЕЙСЕРЫ ВЫСТРЕЛА (4 стиля на Beam, не на коробках)
-- ============================================================
local ShotTracersEnabled = false
local ShotSoundEnabled   = false
local ShotSoundId        = "rbxassetid://99906252350143"
local TracerStyle        = 1    -- 1 Огонь, 2 Лёд, 3 Молния, 4 Арканa
local TracerLifeScale    = 1.0  -- множитель времени жизни (слайдер ×10)

local TRACER_STYLES = {
    [1] = { -- Огонь
        colors = {Color3.fromRGB(255,235,170), Color3.fromRGB(255,120,30), Color3.fromRGB(120,20,0)},
        width = 0.32, life = 0.32, light = Color3.fromRGB(255,140,40), spark = true,
    },
    [2] = { -- Лёд
        colors = {Color3.fromRGB(255,255,255), Color3.fromRGB(150,220,255), Color3.fromRGB(60,140,255)},
        width = 0.22, life = 0.5,  light = Color3.fromRGB(170,220,255), frost = true,
    },
    [3] = { -- Молния
        colors = {Color3.fromRGB(255,255,255), Color3.fromRGB(190,150,255), Color3.fromRGB(90,40,200)},
        width = 0.16, life = 0.18, light = Color3.fromRGB(190,150,255), jagged = true,
    },
    [4] = { -- Арканa
        colors = {Color3.fromRGB(255,80,200), Color3.fromRGB(150,80,255), Color3.fromRGB(80,200,255)},
        width = 0.3,  life = 0.45, light = Color3.fromRGB(200,120,255), rings = true,
    },
}

local function makeAnchor(pos)
    local p = Instance.new("Part")
    p.Size = Vector3.new(0.05,0.05,0.05)
    p.Transparency = 1
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CFrame = CFrame.new(pos)
    p.Parent = workspace
    local att = Instance.new("Attachment")
    att.Parent = p
    return p, att
end

local function spawnSparks(pos, color, count, speedMin, speedMax)
    for _ = 1, count do
        local s = Instance.new("Part")
        s.Size = Vector3.new(0.12,0.12,0.12)
        s.Shape = Enum.PartType.Ball
        s.Material = Enum.Material.Neon
        s.Color = color
        s.CanCollide = false
        s.Anchored = false
        s.Massless = true
        s.CFrame = CFrame.new(pos)
        s.Parent = workspace
        local dir = Vector3.new(math.random(-100,100), math.random(-100,100), math.random(-100,100))
        if dir.Magnitude < 0.01 then dir = Vector3.new(0,1,0) end
        dir = dir.Unit
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = dir * math.random(speedMin, speedMax)
        bv.MaxForce = Vector3.new(1e5,1e5,1e5)
        bv.Parent = s
        task.delay(0.08, function() if bv then bv:Destroy() end end)
        local ft = math.random(15,30)/100
        TweenService:Create(s, TweenInfo.new(ft,Enum.EasingStyle.Quad,Enum.EasingDirection.In), {Transparency=1, Size=Vector3.new(0.02,0.02,0.02)}):Play()
        task.delay(ft+0.05, function() if s then s:Destroy() end end)
    end
end

local function spawnRing(pos, color)
    local ring = Instance.new("Part")
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.05, 1, 1)
    ring.CFrame = CFrame.lookAt(pos, Camera.CFrame.Position) * CFrame.Angles(0, math.rad(90), 0)
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = 0.2
    ring.Anchored = true
    ring.CanCollide = false
    ring.Parent = workspace
    TweenService:Create(ring, TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {Size=Vector3.new(0.05,4,4), Transparency=1}):Play()
    task.delay(0.4, function() if ring then ring:Destroy() end end)
end

local function createShotTracer(startPos, endPos)
    local distance = (startPos - endPos).Magnitude
    if distance < 0.5 then return end
    local style = TRACER_STYLES[TracerStyle] or TRACER_STYLES[1]
    local life = style.life * TracerLifeScale

    local anchor0, a0 = makeAnchor(startPos)
    local anchor1, a1 = makeAnchor(endPos)

    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Width0 = style.width
    beam.Width1 = style.width * 0.25
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Segments = style.jagged and 12 or 1
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, style.colors[1]),
        ColorSequenceKeypoint.new(0.5, style.colors[2]),
        ColorSequenceKeypoint.new(1, style.colors[3]),
    })
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.85, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    if style.jagged then
        beam.CurveSize0 = math.random(-4, 4)
        beam.CurveSize1 = math.random(-4, 4)
    end
    beam.Parent = anchor0

    local light = Instance.new("PointLight")
    light.Color = style.light
    light.Brightness = 4
    light.Range = 14
    light.Parent = anchor1
    TweenService:Create(light, TweenInfo.new(life), {Brightness = 0}):Play()

    if style.spark then spawnSparks(endPos, style.colors[2], 6, 8, 20) end
    if style.frost then spawnSparks(endPos, style.colors[1], 4, 4, 10) end
    if style.rings then spawnRing(endPos, style.colors[1]) end

    TweenService:Create(beam, TweenInfo.new(life,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {Width0=0, Width1=0}):Play()

    task.delay(life + 0.08, function()
        if anchor0 then anchor0:Destroy() end
        if anchor1 then anchor1:Destroy() end
    end)
end

local function playShotSound()
    if not ShotSoundEnabled then return end
    local s=Instance.new("Sound"); s.SoundId=ShotSoundId; s.Volume=3; s.Parent=ScreenGui; s:Play()
    task.delay(2, function() if s then s:Destroy() end end)
end

local function makeStyleSelector(parent, options, default, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 24); Row.BackgroundTransparency = 1; Row.ZIndex = 204; Row.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 4)
    layout.Parent = Row
    local buttons = {}
    local selected = default
    local function refresh()
        for j, b in ipairs(buttons) do
            b.BackgroundColor3 = (j == selected) and Theme.Accent or Theme.Card
            b.TextColor3 = (j == selected) and Theme.Bg or Theme.Text
        end
    end
    for i, label in ipairs(options) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.25, -3, 1, 0)
        btn.Text = label; btn.Font = Enum.Font.GothamBold; btn.TextSize = 8
        btn.AutoButtonColor = false; btn.BorderSizePixel = 0; btn.ZIndex = 204
        btn.Parent = Row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        buttons[i] = btn
        btn.MouseButton1Click:Connect(function() selected = i; refresh(); callback(selected) end)
    end
    refresh()
    return Row
end

local shotFxCard = makeCard(VisualsPage, "ЭФФЕКТЫ ВЫСТРЕЛА")
makeToggle(shotFxCard, "Трейсеры при выстреле", false, function(state) ShotTracersEnabled=state end)
makeToggle(shotFxCard, "Shot Sound", false, function(state) ShotSoundEnabled=state end)
makeStyleSelector(shotFxCard, {"Огонь","Лёд","Молния","Арканa"}, 1, function(i) TracerStyle = i end)
makeSlider(shotFxCard, "Время жизни трейсера ×10", 5, 50, 10, function(v) TracerLifeScale=v/10 end)

-- ============================================================
-- БОЙ
-- ============================================================
local CombatPage = Tabs["Combat"].Page
local ShotBtnDraggable = false
local KnifeBtnDraggable = false

local function EquipGun()
    local char = LocalPlayer.Character
    if not char then return nil end
    local gun = char:FindFirstChild("Gun")
    if gun then return gun end
    local bg = LocalPlayer.Backpack:FindFirstChild("Gun")
    if bg then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:EquipTool(bg); task.wait(0.1) end
        return char:FindFirstChild("Gun")
    end
    return nil
end

local lastShotTime = 0
local SHOT_COOLDOWN = 0.5

local function FindShootRemote(gun)
    local d = gun:FindFirstChild("Shoot")
    if d and d:IsA("RemoteEvent") then return d end
    for _, v in ipairs(gun:GetDescendants()) do
        if v:IsA("RemoteEvent") then return v end
    end
    return nil
end

local function GetGunMuzzlePosition()
    local char = LocalPlayer.Character
    if not char then return nil end
    local gun = char:FindFirstChildWhichIsA("Tool")
    if gun then
        local handle = gun:FindFirstChild("Handle")
        if handle then return handle.CFrame * CFrame.new(0,0,-handle.Size.Z/2) end
    end
    local rh = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
    if rh then return rh.CFrame end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.CFrame or nil
end

-- ============================================================
-- AIM CORE: точная оценка скорости, упреждение, wallbang
-- ============================================================
local AIM_CONFIG = {
    historyWindow   = 0.12,  -- окно истории позиций (сек)
    minSpeed        = 1.5,   -- ниже считаем цель стоящей (студ/с)
    maxSpeed        = 250,   -- выше считаем телепортом/респавном
    interpDelay     = 0.10,  -- задержка интерполяции чужих персонажей
    serverDelay     = 0.015, -- запас на обработку выстрела сервером
    maxLead         = 0.60,  -- потолок упреждения (сек)
    predictionScale = 1.0,   -- авто-режим: множитель не трогаем
    smoothing       = 0.20,  -- сглаживание скорости между кадрами
    maxAccel        = 120,   -- потолок ускорения цели (студ/с²)
    accelDamping    = 0.5,   -- насколько доверяем ускорению
    jitterComp      = 0.5,   -- компенсация джиттера пинга
    knifeSpeed      = 120,   -- скорость полёта ножа (студ/с)
    wallbangBack    = 2.0,   -- отступ origin от цели при wallbang
}
local GetPredictedPosition, GetAimPart, GetShotOrigin, FireInstant, ChooseArm, TrackShot, GetAutoStatus

do
    local ZERO = Vector3.new(0, 0, 0)
    local positionHistory = {}
    local smoothedVelocity = {}
    local smoothedAccel = {}

    local function clearHistory(plr)
        positionHistory[plr] = nil
        smoothedVelocity[plr] = nil
        smoothedAccel[plr] = nil
    end

    local function hookPlayer(plr)
        plr.CharacterAdded:Connect(function() clearHistory(plr) end)
    end
    for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
    Players.PlayerAdded:Connect(hookPlayer)
    Players.PlayerRemoving:Connect(clearHistory)

    -- Сглаженный пинг + джиттер: авто-компенсация скачков сети
    local smoothedPing = 0.08
    local pingJitter = 0.0
    local function readPing()
        local ping = 0.08
        pcall(function()
            ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
        end)
        return math.clamp(ping, 0.02, 0.5)
    end
    RunService.Heartbeat:Connect(function(dt)
        local p = readPing()
        local delta = math.abs(p - smoothedPing)
        pingJitter = pingJitter + (delta - pingJitter) * math.clamp(dt * 2, 0, 1)
        smoothedPing = smoothedPing + (p - smoothedPing) * math.clamp(dt * 6, 0, 1)
    end)

    -- История позиций: только HRP, он стабильнее остальных частей
    RunService.Heartbeat:Connect(function()
        local now = tick()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local hist = positionHistory[plr]
                    if not hist then hist = {}; positionHistory[plr] = hist end
                    hist[#hist + 1] = { t = now, p = hrp.Position }
                    while #hist > 0 and now - hist[1].t > AIM_CONFIG.historyWindow do
                        table.remove(hist, 1)
                    end
                else
                    positionHistory[plr] = nil
                end
            end
        end
    end)

    -- Взвешенная линейная регрессия: свежие точки весят больше
    local function historyVelocity(hist)
        local n = #hist
        if n < 2 then return nil end
        local t0 = hist[1].t
        local sumW, sumT, sumTT = 0, 0, 0
        local sumP, sumTP = ZERO, ZERO
        for i = 1, n do
            local w = 1 + (i / n) * 2
            local dt = hist[i].t - t0
            local p = hist[i].p
            sumW = sumW + w
            sumT = sumT + w * dt
            sumTT = sumTT + w * dt * dt
            sumP = sumP + p * w
            sumTP = sumTP + p * w * dt
        end
        local denom = sumW * sumTT - sumT * sumT
        if math.abs(denom) < 1e-6 then return nil end
        return (sumW * sumTP - sumT * sumP) / denom
    end

    local function computeVelocity(target, part)
        local hist = positionHistory[target]
        local histVel = hist and historyVelocity(hist) or nil
        local av = part.AssemblyLinearVelocity

        -- Скорость по последним двум точкам: быстрее реагирует на остановку
        local recentVel = nil
        if hist and #hist >= 2 then
            local a, b = hist[#hist - 1], hist[#hist]
            local dt = b.t - a.t
            if dt > 0.001 then recentVel = (b.p - a.p) / dt end
        end

        -- Отбрасываем телепорты/респавны
        if histVel and histVel.Magnitude > AIM_CONFIG.maxSpeed then histVel = nil end
        if av.Magnitude > AIM_CONFIG.maxSpeed then av = ZERO end
        if recentVel and recentVel.Magnitude > AIM_CONFIG.maxSpeed then recentVel = nil end

        local vel
        if av.Magnitude >= AIM_CONFIG.minSpeed then
            -- AssemblyLinearVelocity — самый свежий и точный источник
            vel = av
            if histVel and histVel.Magnitude >= AIM_CONFIG.minSpeed then
                -- Подмешиваем историю только если она не противоречит резко
                local diff = (histVel - av).Magnitude
                if diff <= math.max(8, av.Magnitude * 0.75) then
                    vel = av:Lerp(histVel, 0.25)
                end
            end
        elseif recentVel and recentVel.Magnitude >= AIM_CONFIG.minSpeed then
            -- Цель движется через CFrame/физику, av может быть нулевым
            vel = recentVel
            if histVel and histVel.Magnitude >= AIM_CONFIG.minSpeed then
                local diff = (histVel - recentVel).Magnitude
                if diff <= math.max(8, recentVel.Magnitude * 0.75) then
                    vel = recentVel:Lerp(histVel, 0.35)
                end
            end
        elseif recentVel then
            -- Последний кадр без движения и av нулевой: цель стоит
            vel = ZERO
        elseif histVel and histVel.Magnitude >= AIM_CONFIG.minSpeed then
            vel = histVel
        else
            vel = ZERO
        end

        -- Лёгкое сглаживание убирает дрожание, но не убивает смену направления
        local prev = smoothedVelocity[target]
        if prev then
            vel = prev:Lerp(vel, 1 - AIM_CONFIG.smoothing)
        end

        if vel.Magnitude < AIM_CONFIG.minSpeed then
            vel = ZERO
        else
            local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.FloorMaterial ~= Enum.Material.Air then
                vel = Vector3.new(vel.X, 0, vel.Z)
            end
        end

        smoothedVelocity[target] = vel

        -- Горизонтальное ускорение: цель только начала/закончила движение
        local accel = ZERO
        if histVel and recentVel and hist and #hist >= 4 then
            local dt = AIM_CONFIG.historyWindow * 0.5
            if dt > 0.01 then
                accel = (recentVel - histVel) / dt
                accel = Vector3.new(accel.X, 0, accel.Z)
                if accel.Magnitude > AIM_CONFIG.maxAccel then
                    accel = accel.Unit * AIM_CONFIG.maxAccel
                end
            end
        end
        local prevAccel = smoothedAccel[target]
        if prevAccel then
            accel = prevAccel:Lerp(accel, 0.3)
        end
        smoothedAccel[target] = accel

        return vel
    end

    -- Обновляем скорость каждый кадр, чтобы сглаживание не устаревало между выстрелами
    RunService.Heartbeat:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then computeVelocity(plr, hrp) end
            end
        end
    end)

    local function getTargetVelocity(target, part)
        local vel = smoothedVelocity[target]
        if not vel then
            -- Запасной вариант, если Heartbeat ещё не успел посчитать
            vel = part.AssemblyLinearVelocity
            if vel.Magnitude < AIM_CONFIG.minSpeed then return ZERO end
        end
        return vel
    end

    -- Авто-калибровка: 3 варианта силы упреждения, UCB1 сам выбирает лучший
    local AUTO = {
        arms = {
            { scale = 0.90, shots = 0, hits = 0 },
            { scale = 1.00, shots = 0, hits = 0 },
            { scale = 1.10, shots = 0, hits = 0 },
        },
        totalShots = 0,
    }

    ChooseArm = function()
        local total = AUTO.totalShots
        local best, bestScore
        for _, arm in ipairs(AUTO.arms) do
            local score
            if arm.shots == 0 then
                score = math.huge
            else
                local avg = arm.hits / arm.shots
                score = avg + math.sqrt(2 * math.log(total + 1) / arm.shots)
            end
            if not bestScore or score > bestScore then
                best, bestScore = arm, score
            end
        end
        best.shots = best.shots + 1
        AUTO.totalShots = AUTO.totalShots + 1
        return best
    end

    TrackShot = function(target, arm)
        local char = target and target.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local startChar = char
        local startHealth = hum.Health
        task.delay(0.7, function()
            if not target or not target.Parent then return end
            local c = target.Character
            if c ~= startChar then
                arm.hits = arm.hits + 1 -- цель умерла/респавнилась
                return
            end
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if not h or h.Health < startHealth - 0.5 then
                arm.hits = arm.hits + 1
            end
        end)
    end

    -- Статус авто-калибровки для UI
    GetAutoStatus = function()
        local best, bestRate = AUTO.arms[1], 0
        for _, arm in ipairs(AUTO.arms) do
            if arm.shots > 0 then
                local rate = arm.hits / arm.shots
                if rate > bestRate then best, bestRate = arm, rate end
            end
        end
        return best.scale, bestRate, best.shots, AUTO.totalShots
    end

    -- Авто-упреждение: RTT + интерполяция + джиттер + ускорение + гравитация
    GetPredictedPosition = function(target, part, extraLead, scaleOverride)
        if not PredictionEnabled then return part.Position, ZERO end
        local velocity = getTargetVelocity(target, part)
        if velocity.Magnitude < AIM_CONFIG.minSpeed then return part.Position, velocity end

        local latencyLead = smoothedPing + AIM_CONFIG.interpDelay + AIM_CONFIG.serverDelay
        latencyLead = latencyLead + pingJitter * AIM_CONFIG.jitterComp
        latencyLead = latencyLead * AIM_CONFIG.predictionScale * (scaleOverride or 1.0)
        latencyLead = math.clamp(latencyLead, 0, AIM_CONFIG.maxLead)

        local totalLead = latencyLead + (extraLead or 0)
        local t2 = totalLead * totalLead

        local accel = smoothedAccel[target] or ZERO
        local predicted = part.Position + velocity * totalLead
        predicted = predicted + accel * (0.5 * t2 * AIM_CONFIG.accelDamping)

        -- Компенсация гравитации для цели в воздухе
        local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.FloorMaterial == Enum.Material.Air then
            predicted = predicted + Vector3.new(0, -0.5 * workspace.Gravity * t2, 0)
        end
        return predicted, velocity
    end

    local function isTargetValid(target)
        local char = target and target.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        local info = roles[target.Name]
        if info and (info.Killed or info.Dead) then return false end
        return true
    end

    GetAimPart = function(char)
        for _, name in ipairs({"HumanoidRootPart", "Torso", "UpperTorso", "Head"}) do
            local part = char:FindFirstChild(name)
            if part then return part end
        end
        return nil
    end

    -- Origin за целью на линии камера -> цель: стена между нами не перехватит луч.
    -- Отступаем назад, чтобы луч точно вошёл в хитбокс, а не стартовал внутри него.
    GetShotOrigin = function(targetPos, muzzleCF)
        if WallbangEnabled then
            local cam = workspace.CurrentCamera
            local camPos = cam and cam.CFrame.Position or targetPos
            local dir = targetPos - camPos
            if dir.Magnitude < 0.001 then dir = Vector3.new(0, 0, 1) end
            local back = math.min(AIM_CONFIG.wallbangBack, dir.Magnitude * 0.5)
            return targetPos - dir.Unit * back
        end
        return muzzleCF and muzzleCF.Position or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position) or targetPos
    end

    -- Один клик = один выстрел. Жмёшь — стреляет, не жмёшь — тишина.
    FireInstant = function(target)
        if not SilentAimEnabled then return false end
        if tick() - lastShotTime < SHOT_COOLDOWN then return false end
        if not isTargetValid(target) then return false end

        local part = GetAimPart(target.Character)
        if not part then return false end

        local gun = EquipGun()
        if not gun then return false end
        local shoot = FindShootRemote(gun)
        if not shoot then return false end

        local arm = ChooseArm()
        local targetPos = GetPredictedPosition(target, part, 0, arm.scale)
        local muzzleCF = GetGunMuzzlePosition()
        local originPos = GetShotOrigin(targetPos, muzzleCF)

        lastShotTime = tick()
        pcall(function() shoot:FireServer(CFrame.new(originPos), CFrame.new(targetPos)) end)
        TrackShot(target, arm)

        if ShotTracersEnabled then
            createShotTracer(muzzleCF and muzzleCF.Position or originPos, targetPos)
        end
        if ShotSoundEnabled then playShotSound() end
        return true
    end
end

-- ============================================================
-- THROW KNIFE
-- ============================================================
local lastKnifeTime = 0
local KNIFE_COOLDOWN = 0.6

local function FindKnifeTool()
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local ln = tool.Name:lower()
                if ln:find("knife") or ln:find("saw") or ln:find("serial") then return tool end
            end
        end
    end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local ln = tool.Name:lower()
            if ln:find("knife") or ln:find("saw") or ln:find("serial") then return tool end
        end
    end
    return nil
end

local function EquipKnifeTool(tool)
    local char = LocalPlayer.Character
    if not char then return nil end
    if tool.Parent == char then return tool end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum:EquipTool(tool); task.wait(0.12) end
    return char:FindFirstChildWhichIsA("Tool") or tool
end

local function FindThrowRemote(tool)
    for _, name in ipairs({"KnifeStabbed","Throw","ThrowKnife","Fire","Shoot"}) do
        local re = tool:FindFirstChild(name)
        if re and re:IsA("RemoteEvent") then return re end
    end
    for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("RemoteEvent") then return v end
    end
    return nil
end

local function GetNearestAlivePlayer()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myPos = hrp.Position
    local target, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local tHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local tHum = plr.Character:FindFirstChildOfClass("Humanoid")
            if tHrp and tHum and tHum.Health > 0 then
                local dist = (tHrp.Position - myPos).Magnitude
                if dist < bestDist then target=plr; bestDist=dist end
            end
        end
    end
    return target
end

local function ThrowKnife()
    local char = LocalPlayer.Character
    if not char then return false end
    local now = tick()
    if now - lastKnifeTime < KNIFE_COOLDOWN then return false end
    lastKnifeTime = now
    local target = GetNearestAlivePlayer()
    if not target then return false end
    local targetChar = target.Character
    local targetPart = GetAimPart(targetChar)
    if not targetPart then return false end
    local knifeTool = FindKnifeTool()
    if not knifeTool then return false end
    task.spawn(function()
        local equipped = EquipKnifeTool(knifeTool)
        if not equipped then return end
        local throwRE = FindThrowRemote(equipped)
        if not throwRE then task.wait(0.1); throwRE=FindThrowRemote(equipped) end
        if not throwRE then return end
        local arm = ChooseArm()
        local targetPos, velocity = GetPredictedPosition(target, targetPart, 0, arm.scale)
        local muzzleCF = GetGunMuzzlePosition()
        local originPos = GetShotOrigin(targetPos, muzzleCF)
        -- Нож — снаряд: добавляем время полёта от реального origin до цели
        if velocity.Magnitude > 0 and AIM_CONFIG.knifeSpeed > 0 then
            local travel = (targetPos - originPos).Magnitude / AIM_CONFIG.knifeSpeed
            targetPos = GetPredictedPosition(target, targetPart, travel, arm.scale)
            originPos = GetShotOrigin(targetPos, muzzleCF)
            -- второй проход для сходимости
            travel = (targetPos - originPos).Magnitude / AIM_CONFIG.knifeSpeed
            targetPos = GetPredictedPosition(target, targetPart, travel, arm.scale)
            originPos = GetShotOrigin(targetPos, muzzleCF)
        end
        pcall(function() throwRE:FireServer(CFrame.new(originPos), CFrame.new(targetPos)) end)
        TrackShot(target, arm)
        if ShotTracersEnabled then
            local rp = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("HumanoidRootPart")
            createShotTracer(rp and rp.Position or originPos, targetPos)
        end
    end)
    return true
end

-- ============================================================
-- ФЛИНГ
-- ============================================================
local function FlingPlayer(target)
    if not target or not target.Character then return end
    local targetChar = target.Character
    local targetHrp  = targetChar:FindFirstChild("HumanoidRootPart")
    local myChar     = LocalPlayer.Character
    local myHrp      = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not targetHrp or not myHrp then return end
    targetHrp.CFrame = myHrp.CFrame * CFrame.new(0, 0, -2)
    for _, v in ipairs(targetHrp:GetChildren()) do
        if v.Name == "SallFlingVel" or v.Name == "SallFlingPos" then v:Destroy() end
    end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "SallFlingVel"
    bv.Velocity = Vector3.new(math.random(-1,1) * math.random(800,1200), math.random(600,1000), math.random(-1,1) * math.random(800,1200))
    bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
    bv.Parent = targetHrp
    local bp = Instance.new("BodyPosition")
    bp.Name = "SallFlingPos"
    bp.Position = targetHrp.Position
    bp.MaxForce = Vector3.new(0,0,0)
    bp.Parent = targetHrp
    task.delay(0.08, function()
        if bv and bv.Parent then bv:Destroy() end
        if bp and bp.Parent then bp:Destroy() end
    end)
end

-- СПИН
local spinConn = nil
local function startSpin()
    if spinConn then spinConn:Disconnect(); spinConn=nil end
    spinConn = RunService.RenderStepped:Connect(function(dt)
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SpinSpeed * dt * 60), 0) end
    end)
end
local function stopSpin() if spinConn then spinConn:Disconnect(); spinConn=nil end end

-- БАНИХОП
local bhopConn = nil
local function startBhop()
    if bhopConn then bhopConn:Disconnect(); bhopConn=nil end
    bhopConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if hum:GetState() == Enum.HumanoidStateType.Landed or hum:GetState() == Enum.HumanoidStateType.Running then
            hum.Jump = true
        end
    end)
end
local function stopBhop() if bhopConn then bhopConn:Disconnect(); bhopConn=nil end end

-- UI: SILENT AIM
local aimCard = makeCard(CombatPage, "SILENT AIM")
makeToggle(aimCard, "Silent Aim", true, function(state) SilentAimEnabled=state end)
makeToggle(aimCard, "Prediction (упреждение движения)", true, function(state) PredictionEnabled=state end)
makeToggle(aimCard, "Shot Murder (Кнопка)", false, function(state) ShotBtn.Visible=state end)
makeToggle(aimCard, "Двигать кнопку", false, function(state) ShotBtnDraggable=state end)
local aimInfoLabel = Instance.new("TextLabel")
aimInfoLabel.Size = UDim2.new(1, 0, 0, 16); aimInfoLabel.BackgroundTransparency = 1
aimInfoLabel.Font = Enum.Font.Gotham; aimInfoLabel.TextSize = 8; aimInfoLabel.TextWrapped = true
aimInfoLabel.TextColor3 = Theme.Green
aimInfoLabel.Text = "🎯 Авто-упреждение: RTT + интерполяция + джиттер + ускорение"
aimInfoLabel.TextXAlignment = Enum.TextXAlignment.Left; aimInfoLabel.ZIndex = 204; aimInfoLabel.Parent = aimCard

-- Живой статус авто-калибровки
task.spawn(function()
    while aimInfoLabel.Parent do
        local scale, rate, armShots, total = GetAutoStatus()
        if total and total > 0 then
            aimInfoLabel.Text = string.format("🎯 Авто-упреждение ×%.2f · попаданий %d%% (%d выстр.)", scale, math.floor(rate * 100 + 0.5), total)
        else
            aimInfoLabel.Text = "🎯 Авто-упреждение: RTT + интерполяция + джиттер + ускорение"
        end
        task.wait(2)
    end
end)

-- UI: WALLBANG
local wallbangCard = makeCard(CombatPage, "WALLBANG")
local wbInfoLabel = Instance.new("TextLabel")
wbInfoLabel.Size = UDim2.new(1, 0, 0, 16); wbInfoLabel.BackgroundTransparency = 1
wbInfoLabel.Font = Enum.Font.Gotham; wbInfoLabel.TextSize = 8
wbInfoLabel.TextXAlignment = Enum.TextXAlignment.Left; wbInfoLabel.ZIndex = 204; wbInfoLabel.Parent = wallbangCard
local function updateWbLabel()
    if WallbangEnabled then
        wbInfoLabel.TextColor3 = Theme.Green
        wbInfoLabel.Text = "⚡ Луч нулевой длины — стены не мешают"
    else
        wbInfoLabel.TextColor3 = Theme.TextDim
        wbInfoLabel.Text = "🔒 Реальный origin — стены блокируют"
    end
end
makeToggle(wallbangCard, "Wallbang", true, function(state) WallbangEnabled=state; updateWbLabel() end)
updateWbLabel()

-- UI: THROW KNIFE
local knifeCard = makeCard(CombatPage, "THROW KNIFE")
makeToggle(knifeCard, "Throw Knife (Кнопка)", false, function(state) KnifeBtn.Visible=state end)
makeToggle(knifeCard, "Двигать кнопку", false, function(state) KnifeBtnDraggable=state end)

-- UI: ФЛИНГ
local flingCard = makeCard(CombatPage, "ФЛИНГ")
makeFlingBtn(flingCard, "FLING SHERIFF", Color3.fromRGB(0,0,180), function() FlingPlayer(getSheriff()) end)
makeFlingBtn(flingCard, "FLING MURDERER", Color3.fromRGB(180,0,0), function() FlingPlayer(getMurderer()) end)

-- ХОТКЕИ
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E then local m=getMurderer(); if m then FireInstant(m) end end
    if input.KeyCode == Enum.KeyCode.Q then ThrowKnife() end
end)

-- ПУЛЬС
local function pulseBtn(btn, baseSize)
    TweenService:Create(btn, TweenInfo.new(0.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {
        Size=UDim2.new(0,baseSize.X.Offset+20,0,baseSize.Y.Offset+6),
        BackgroundColor3=Theme.Accent, TextColor3=Theme.Bg
    }):Play()
    task.delay(0.12, function()
        TweenService:Create(btn, TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {
            Size=baseSize, BackgroundColor3=Theme.Surface, TextColor3=Theme.Text
        }):Play()
    end)
end

local sDragging,sDragStart,sStartPos,sMoved,sPressed=false,nil,nil,false,false
ShotBtn.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        sPressed=true; sMoved=false
        if ShotBtnDraggable then sDragging=true; sDragStart=input.Position; sStartPos=ShotBtn.Position end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if sDragging and ShotBtnDraggable and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local d=input.Position-sDragStart
        if math.abs(d.X)>5 or math.abs(d.Y)>5 then sMoved=true; ShotBtn.Position=UDim2.new(sStartPos.X.Scale,sStartPos.X.Offset+d.X,sStartPos.Y.Scale,sStartPos.Y.Offset+d.Y) end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        sDragging=false
        if sPressed and not sMoved then pulseBtn(ShotBtn,UDim2.new(0,200,0,56)); local m=getMurderer(); if m then FireInstant(m) end end
        sPressed=false
    end
end)

local kDragging,kDragStart,kStartPos,kMoved,kPressed=false,nil,nil,false,false
KnifeBtn.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        kPressed=true; kMoved=false
        if KnifeBtnDraggable then kDragging=true; kDragStart=input.Position; kStartPos=KnifeBtn.Position end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if kDragging and KnifeBtnDraggable and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local d=input.Position-kDragStart
        if math.abs(d.X)>5 or math.abs(d.Y)>5 then kMoved=true; KnifeBtn.Position=UDim2.new(kStartPos.X.Scale,kStartPos.X.Offset+d.X,kStartPos.Y.Scale,kStartPos.Y.Offset+d.Y) end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        kDragging=false
        if kPressed and not kMoved then pulseBtn(KnifeBtn,UDim2.new(0,200,0,56)); ThrowKnife() end
        kPressed=false
    end
end)

-- ============================================================
-- УТИЛИТЫ
-- ============================================================
local UtilityPage = Tabs["Utility"].Page
local NoclipEnabled = false
local SlideEnabled  = false
local SlideSpeed    = 45
local AutoGunEnabled= false
local SpeedEnabled, SpeedValue = false, DEFAULT_SPEED
local JumpEnabled,  JumpValue  = false, DEFAULT_JUMP

local moveCard = makeCard(UtilityPage, "ДВИЖЕНИЕ")
makeToggle(moveCard, "Speed Hack", false, function(s) SpeedEnabled=s end)
makeSlider(moveCard, "Speed", 16, 200, 16, function(v) SpeedValue=v end)
makeToggle(moveCard, "Jump Hack", false, function(s) JumpEnabled=s end)
makeSlider(moveCard, "Jump", 50, 500, 50, function(v) JumpValue=v end)
makeToggle(moveCard, "Noclip", false, function(s) NoclipEnabled=s end)
makeToggle(moveCard, "Slide Glitch", false, function(s) SlideEnabled=s end)
makeSlider(moveCard, "Скорость слайда", 10, 150, 45, function(v) SlideSpeed=v end)

local spinCard = makeCard(UtilityPage, "СПИН")
makeToggle(spinCard, "Крутилка", false, function(state)
    SpinEnabled = state
    if state then startSpin() else stopSpin() end
end)
makeSlider(spinCard, "Скорость спина", 1, 50, 10, function(v) SpinSpeed=v end)

local bhopCard = makeCard(UtilityPage, "БАНИХОП")
makeToggle(bhopCard, "Bunny Hop", false, function(state)
    BhopEnabled = state
    if state then startBhop() else stopBhop() end
end)

RunService.Stepped:Connect(function()
    if not NoclipEnabled then return end
    local char = LocalPlayer.Character
    if char then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
end)
RunService.Heartbeat:Connect(function(dt)
    if not SlideEnabled then return end
    local char=LocalPlayer.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if hrp and hum and hum.MoveDirection.Magnitude>0 then hrp.CFrame=hrp.CFrame+hum.MoveDirection*(SlideSpeed*dt) end
end)
RunService.Heartbeat:Connect(function()
    local char=LocalPlayer.Character
    if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = SpeedEnabled and SpeedValue or DEFAULT_SPEED
    if not hum.UseJumpPower then hum.UseJumpPower=true end
    hum.JumpPower = JumpEnabled and JumpValue or DEFAULT_JUMP
end)

makeToggle(UtilityPage, "Auto Gun Grab", false, function(state)
    AutoGunEnabled=state
    if state then
        task.spawn(function()
            while AutoGunEnabled do
                task.wait(0.5)
                local function getGunDrop()
                    for _,v in pairs(workspace:GetDescendants()) do
                        if v.Name=="GunDrop" then return v:IsA("Model") and v:FindFirstChild("Handle") or v end
                    end
                end
                local gp=getGunDrop()
                local ch=LocalPlayer.Character
                local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
                if gp and hrp then
                    local t0=tick()
                    repeat
                        if not gp or not gp.Parent or not ch or not ch.Parent then break end
                        if gp:IsA("BasePart") then gp.CFrame=hrp.CFrame else gp:PivotTo(hrp.CFrame) end
                        if firetouchinterest then pcall(function() firetouchinterest(hrp,gp,0); firetouchinterest(hrp,gp,1) end) end
                        task.wait(0.05)
                    until LocalPlayer.Backpack:FindFirstChild("Gun") or tick()-t0>3
                end
            end
        end)
    end
end)

local grabCard = makeCard(UtilityPage, "ПУШКИ")
makeButton(grabCard, "🚀 Притянуть GunDrop сейчас", Theme.Card, function()
    local function getGunDrop()
        for _,v in pairs(workspace:GetDescendants()) do
            if v.Name=="GunDrop" then return v:IsA("Model") and v:FindFirstChild("Handle") or v end
        end
    end
    local gp=getGunDrop()
    local ch=LocalPlayer.Character
    local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
    if gp and hrp then
        if gp:IsA("BasePart") then gp.CFrame=hrp.CFrame else gp:PivotTo(hrp.CFrame) end
        if firetouchinterest then pcall(function() firetouchinterest(hrp,gp,0); firetouchinterest(hrp,gp,1) end) end
    end
end)

local skinCard = makeCard(UtilityPage, "СКИНЫ")
local SkinInput = makeInput(skinCard, "Введи ник игрока...")
local function copySkin(targetName)
    local targetPlr
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(targetName:lower()) then targetPlr=p; break end
    end
    if not targetPlr or not targetPlr.Character then return end
    local myChar=LocalPlayer.Character
    if not myChar then return end
    for _,obj in ipairs(targetPlr.Character:GetDescendants()) do
        if obj:IsA("Shirt") then
            local s=myChar:FindFirstChildOfClass("Shirt") or Instance.new("Shirt",myChar)
            s.ShirtTemplate=obj.ShirtTemplate
        elseif obj:IsA("Pants") then
            local p=myChar:FindFirstChildOfClass("Pants") or Instance.new("Pants",myChar)
            p.PantsTemplate=obj.PantsTemplate
        elseif obj:IsA("Accessory") then
            if not myChar:FindFirstChild(obj.Name) then obj:Clone().Parent=myChar end
        elseif obj:IsA("BodyColors") then
            local bc=myChar:FindFirstChildOfClass("BodyColors")
            if bc then
                bc.HeadColor3=obj.HeadColor3; bc.TorsoColor3=obj.TorsoColor3
                bc.LeftArmColor3=obj.LeftArmColor3; bc.RightArmColor3=obj.RightArmColor3
                bc.LeftLegColor3=obj.LeftLegColor3; bc.RightLegColor3=obj.RightLegColor3
            end
        end
    end
end
makeButton(skinCard, "👕 Применить скин", Theme.Accent, function()
    if SkinInput.Text~="" then copySkin(SkinInput.Text) end
end)

-- ============================================================
-- ОСКОЛКИ ПРИ ЗАКРЫТИИ
-- ============================================================
local function spawnShards()
    local absPos  = Menu.AbsolutePosition
    local absSize = Menu.AbsoluteSize
    for _ = 1, 14 do
        local sw = math.random(30,90); local sh = math.random(20,60)
        local sx = absPos.X + math.random(0, math.max(1, absSize.X-sw))
        local sy = absPos.Y + math.random(0, math.max(1, absSize.Y-sh))
        local shard = Instance.new("Frame")
        shard.Size = UDim2.new(0,sw,0,sh); shard.Position = UDim2.new(0,sx,0,sy)
        shard.BackgroundColor3 = math.random()>0.5 and Theme.Surface or Theme.Card
        shard.BackgroundTransparency = 0.1; shard.BorderSizePixel = 0; shard.ZIndex = 300
        shard.Parent = ScreenGui
        Instance.new("UICorner", shard).CornerRadius = UDim.new(0,4)
        local shine = Instance.new("Frame")
        shine.Size = UDim2.new(1,0,0,1); shine.Position = UDim2.new(0,0,0.3,0)
        shine.BackgroundColor3 = Theme.Accent; shine.BackgroundTransparency = 0.6
        shine.BorderSizePixel = 0; shine.ZIndex = 301; shine.Parent = shard
        local cx = absPos.X + absSize.X/2; local cy = absPos.Y + absSize.Y/2
        local dx = (sx+sw/2)-cx; local dy = (sy+sh/2)-cy
        local len = math.sqrt(dx*dx+dy*dy); if len < 1 then len=1 end
        local nx,ny = dx/len, dy/len
        local speed = math.random(80,220); local spread = math.random(-40,40)
        local targetX = sx + nx*speed + spread
        local targetY = sy + ny*speed + spread + math.random(30,80)
        local duration = math.random(28,55)/100
        TweenService:Create(shard, TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {
            Position=UDim2.new(0,targetX,0,targetY),
            BackgroundTransparency=1,
            Size=UDim2.new(0,sw*math.random(60,110)/100,0,sh*math.random(60,110)/100),
        }):Play()
        TweenService:Create(shine, TweenInfo.new(duration), {BackgroundTransparency=1}):Play()
        task.delay(duration+0.05, function() if shard then shard:Destroy() end end)
    end
end

-- ============================================================
-- ОТКРЫТИЕ / ЗАКРЫТИЕ
-- ============================================================
local isOpen = false
local function openMenu()
    isOpen = true
    Menu.Visible = true
    Menu.Size = UDim2.new(0,currentW,0,0)
    Menu.Position = UDim2.new(0.5,-currentW/2,0.5,0)
    TweenService:Create(Menu, TweenInfo.new(0.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out), {
        Size=UDim2.new(0,currentW,0,currentH), Position=startPosFor(currentW, currentH)
    }):Play()
end
local function closeMenu()
    if not isOpen then return end
    isOpen = false
    spawnShards()
    local tween = TweenService:Create(Menu, TweenInfo.new(0.13,Enum.EasingStyle.Quad,Enum.EasingDirection.In), {
        Size=UDim2.new(0,currentW,0,0), Position=UDim2.new(0.5,-currentW/2,0.5,0), BackgroundTransparency=0.6,
    })
    tween:Play()
    tween.Completed:Connect(function()
        Menu.Visible=false; Menu.BackgroundTransparency=0
        Menu.Size=UDim2.new(0,currentW,0,currentH); Menu.Position=startPosFor(currentW, currentH)
    end)
end
Trigger.MouseButton1Click:Connect(function() if isOpen then closeMenu() else openMenu() end end)
Trigger.MouseEnter:Connect(function() TweenService:Create(Trigger,TweenInfo.new(0.15),{BackgroundTransparency=0.0}):Play() end)
Trigger.MouseLeave:Connect(function() TweenService:Create(Trigger,TweenInfo.new(0.15),{BackgroundTransparency=0.15}):Play() end)
CloseBtn.MouseButton1Click:Connect(closeMenu)

selectTab("Visuals")
print("[SALL HUB · AXIOM MONO] Загружено. Точный выстрел по реальной позиции + 4 магических трейсера.")
