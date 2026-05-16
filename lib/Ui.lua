-- Alpha Spy GUI
-- Font: Enum.Font.Code (Courier New equivalent)
-- Created by trident (+99999 AURA)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- COLORS
-- ============================================================
local C = {
    TitleBar  = Color3.fromHex("272222"),
    Toolbar   = Color3.fromHex("c0622a"),
    EditorBg  = Color3.fromHex("f5dfc8"),
    ButtonBg  = Color3.fromHex("d4743a"),
    ButtonHov = Color3.fromHex("b85e2a"),
    DupeName  = Color3.fromHex("4ecb71"),
    Text      = Color3.fromHex("1a0a00"),
    Border    = Color3.fromHex("8b3a1a"),
    Pink      = Color3.fromHex("f0b2d5"),
    TabActive = Color3.fromHex("d4743a"),
    TabInact  = Color3.fromHex("b85e2a"),
    BoxOn     = Color3.fromHex("c0622a"),
    BoxOff    = Color3.fromHex("a07060"),
    White     = Color3.fromRGB(255, 255, 255),
}

-- ============================================================
-- STATE
-- ============================================================
local isOpen         = true
local activeTab      = "Editor"
local selectedRemote = nil
local selectedDupe   = nil
local remoteButtons  = {}   -- { btn, dupeContainer, dupes[], expanded }
local settingStates  = {}   -- { label, toggled, keyLabel?, btn }

local SETTINGS = {
    { label = "No parenting",     toggled = false },
    { label = "No renaming",      toggled = false },
    { label = "Keybinds Enabled", toggled = true  },
    { label = "UI Visible",       toggled = true,  key = "P" },
    { label = "Ignore nil parents",toggled = true  },
    { label = "Paused",           toggled = false, key = "Q" },
    { label = "Ignore exploit cal",toggled = false },
    { label = "Log receives",     toggled = true  },
    { label = "No grouping",      toggled = false },
    { label = "Find arg for name",toggled = true  },
}

local INFO_LINES = {
    "Alpha Spy - Created by trident!",
    "Thank you to everyone for suggestions and testing",
    "I wish potassium wasn't so crudely produced",
    "Boiiiiiii what did you say about Alpha Spy (+99999 AURA)",
}

-- ============================================================
-- HELPERS
-- ============================================================
local function hex(h) return Color3.fromHex(h) end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function makeButton(text, parent, bgColor)
    local btn = make("TextButton", {
        Text              = text,
        Font              = Enum.Font.Code,
        TextSize          = 11,
        TextColor3        = C.White,
        BackgroundColor3  = bgColor or C.ButtonBg,
        BorderColor3      = C.Border,
        BorderSizePixel   = 1,
        AutomaticSize     = Enum.AutomaticSize.XY,
        BackgroundTransparency = 0,
    }, parent)

    local pad = make("UIPadding", {
        PaddingTop    = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft   = UDim.new(0, 10),
        PaddingRight  = UDim.new(0, 10),
    }, btn)

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = C.ButtonHov
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = bgColor or C.ButtonBg
    end)
    return btn
end

local function showNotif(gui, msg)
    -- Remove old notif if any
    local old = gui:FindFirstChild("_Notif")
    if old then old:Destroy() end

    local notif = make("TextLabel", {
        Name             = "_Notif",
        Text             = msg,
        Font             = Enum.Font.Code,
        TextSize         = 11,
        TextColor3       = C.Pink,
        BackgroundColor3 = C.TitleBar,
        BorderColor3     = C.Border,
        BorderSizePixel  = 1,
        AnchorPoint      = Vector2.new(0.5, 1),
        Position         = UDim2.new(0.5, 0, 1, -6),
        AutomaticSize    = Enum.AutomaticSize.XY,
        ZIndex           = 10,
    }, gui)
    make("UIPadding", {
        PaddingTop = UDim.new(0,3), PaddingBottom = UDim.new(0,3),
        PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10),
    }, notif)
    make("UICorner", { CornerRadius = UDim.new(0, 3) }, notif)

    task.delay(1.8, function()
        if notif and notif.Parent then notif:Destroy() end
    end)
end

-- ============================================================
-- DRAG (works for both Mini bar and could be reused)
-- ============================================================
local function makeDraggable(handle, root)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = root.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- BUILD GUI
-- ============================================================
local ScreenGui = make("ScreenGui", {
    Name           = "AlphaSpy",
    ResetOnSpawn   = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, LocalPlayer.PlayerGui)

-- ============================================================
-- MINI BAR (shown when closed)
-- ============================================================
local MiniBar = make("Frame", {
    Name             = "MiniBar",
    Size             = UDim2.new(0, 220, 0, 28),
    Position         = UDim2.new(0, 40, 0, 40),
    BackgroundColor3 = C.TitleBar,
    BorderColor3     = C.Border,
    BorderSizePixel  = 1,
    Visible          = false,
    Active           = true,
    Draggable        = false,
}, ScreenGui)

make("UICorner", { CornerRadius = UDim.new(0, 4) }, MiniBar)

make("TextLabel", {
    Text             = "Alpha Spy",
    Font             = Enum.Font.Code,
    TextSize         = 13,
    TextColor3       = C.White,
    BackgroundTransparency = 1,
    Size             = UDim2.new(1, -30, 1, 0),
    Position         = UDim2.new(0, 8, 0, 0),
    TextXAlignment   = Enum.TextXAlignment.Left,
}, MiniBar)

local MiniOpen = make("TextButton", {
    Text             = "",
    Size             = UDim2.new(0, 14, 0, 14),
    Position         = UDim2.new(1, -22, 0.5, -7),
    BackgroundColor3 = C.Toolbar,
    BackgroundTransparency = 0.2,
    BorderColor3     = C.Border,
    BorderSizePixel  = 1,
    ZIndex           = 2,
}, MiniBar)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, MiniOpen)

makeDraggable(MiniBar, MiniBar)

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local Main = make("Frame", {
    Name             = "Main",
    Size             = UDim2.new(0, 620, 0, 380),
    Position         = UDim2.new(0, 40, 0, 40),
    BackgroundColor3 = C.EditorBg,
    BorderColor3     = C.Border,
    BorderSizePixel  = 1,
    ClipsDescendants = true,
}, ScreenGui)
make("UICorner", { CornerRadius = UDim.new(0, 4) }, Main)

-- Title bar
local TitleBar = make("Frame", {
    Name             = "TitleBar",
    Size             = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = C.TitleBar,
    BorderSizePixel  = 0,
    ZIndex           = 2,
}, Main)

make("TextLabel", {
    Text           = "Alpha Spy",
    Font           = Enum.Font.Code,
    TextSize       = 13,
    TextColor3     = C.White,
    BackgroundTransparency = 1,
    Size           = UDim2.new(1, -30, 1, 0),
    Position       = UDim2.new(0, 8, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex         = 2,
}, TitleBar)

local CloseBtn = make("TextButton", {
    Text             = "",
    Size             = UDim2.new(0, 14, 0, 14),
    Position         = UDim2.new(1, -20, 0.5, -7),
    BackgroundColor3 = C.Toolbar,
    BackgroundTransparency = 0.2,
    BorderColor3     = C.Border,
    BorderSizePixel  = 1,
    ZIndex           = 3,
}, TitleBar)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, CloseBtn)

-- Body (below title bar)
local Body = make("Frame", {
    Name             = "Body",
    Size             = UDim2.new(1, 0, 1, -26),
    Position         = UDim2.new(0, 0, 0, 26),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
}, Main)

-- ============================================================
-- LEFT — Remote List
-- ============================================================
local LeftPanel = make("Frame", {
    Name             = "LeftPanel",
    Size             = UDim2.new(0, 155, 1, -32), -- leave room for bottom bar
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = C.Toolbar,
    BorderColor3     = C.Border,
    BorderSizePixel  = 1,
}, Body)

local RemoteScroll = make("ScrollingFrame", {
    Size                   = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    ScrollBarThickness     = 4,
    ScrollBarImageColor3   = C.Border,
    CanvasSize             = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize    = Enum.AutomaticSize.Y,
}, LeftPanel)

make("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding   = UDim.new(0, 0),
}, RemoteScroll)

make("UIPadding", { PaddingTop = UDim.new(0,2) }, RemoteScroll)

-- ============================================================
-- RIGHT — Tab Panel
-- ============================================================
local RightPanel = make("Frame", {
    Name             = "RightPanel",
    Size             = UDim2.new(1, -155, 1, -32),
    Position         = UDim2.new(0, 155, 0, 0),
    BackgroundColor3 = C.EditorBg,
    BorderSizePixel  = 0,
}, Body)

-- Tab bar
local TabBar = make("Frame", {
    Size             = UDim2.new(1, 0, 0, 24),
    BackgroundColor3 = C.Toolbar,
    BorderColor3     = C.Border,
    BorderSizePixel  = 1,
}, RightPanel)

make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder     = Enum.SortOrder.LayoutOrder,
}, TabBar)

-- Tab content area
local TabContent = make("ScrollingFrame", {
    Size                   = UDim2.new(1, 0, 1, -24),
    Position               = UDim2.new(0, 0, 0, 24),
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    ScrollBarThickness     = 4,
    ScrollBarImageColor3   = C.Border,
    CanvasSize             = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize    = Enum.AutomaticSize.Y,
    ClipsDescendants       = true,
}, RightPanel)

-- ============================================================
-- BOTTOM TOOLBAR
-- ============================================================
local BottomBar = make("Frame", {
    Name             = "BottomBar",
    Size             = UDim2.new(1, 0, 0, 28),
    Position         = UDim2.new(0, 0, 1, -32),
    BackgroundColor3 = C.Toolbar,
    BorderColor3     = C.Border,
    BorderSizePixel  = 1,
    ZIndex           = 2,
}, Body)

local BottomLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding       = UDim.new(0, 4),
    VerticalAlignment = Enum.VerticalAlignment.Center,
    SortOrder     = Enum.SortOrder.LayoutOrder,
}, BottomBar)

make("UIPadding", {
    PaddingLeft = UDim.new(0, 6),
}, BottomBar)

local ACTIONS = {"Copy", "Repeat call", "Get return", "Generate info", "Decompile script", "Build"}
for i, action in ipairs(ACTIONS) do
    local btn = makeButton(action, BottomBar)
    btn.LayoutOrder = i
    btn.ZIndex = 2
    btn.MouseButton1Click:Connect(function()
        showNotif(Main, action .. "...")
    end)
end

-- Status bar
local StatusBar = make("Frame", {
    Size             = UDim2.new(1, 0, 0, 16),
    Position         = UDim2.new(0, 0, 1, -16),
    BackgroundColor3 = C.TitleBar,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
    ZIndex           = 2,
}, Main)

-- Left label — anchored left, fixed offset from edge
make("TextLabel", {
    Text           = "-- welcome to alpha spy",
    Font           = Enum.Font.Code,
    TextSize       = 10,
    TextColor3     = Color3.fromRGB(136, 136, 136),
    BackgroundTransparency = 1,
    AnchorPoint    = Vector2.new(0, 0.5),
    Size           = UDim2.new(0, 160, 1, 0),
    Position       = UDim2.new(0, 8, 0.5, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate   = Enum.TextTruncate.AtEnd,
    ZIndex         = 2,
}, StatusBar)

-- Right label — anchored right, fixed offset from edge
make("TextLabel", {
    Text           = "-- made by trident",
    Font           = Enum.Font.Code,
    TextSize       = 10,
    TextColor3     = Color3.fromRGB(136, 136, 136),
    BackgroundTransparency = 1,
    AnchorPoint    = Vector2.new(1, 0.5),
    Size           = UDim2.new(0, 150, 1, 0),
    Position       = UDim2.new(1, -8, 0.5, 0),
    TextXAlignment = Enum.TextXAlignment.Right,
    TextTruncate   = Enum.TextTruncate.AtEnd,
    ZIndex         = 2,
}, StatusBar)

-- ============================================================
-- TAB PAGES
-- ============================================================
-- We create all three page frames inside TabContent and show/hide them

local function clearContent()
    for _, c in ipairs(TabContent:GetChildren()) do
        if c:IsA("GuiObject") then c.Visible = false end
    end
end

-- ---- EDITOR PAGE ----
local EditorPage = make("Frame", {
    Name          = "EditorPage",
    Size          = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible       = true,
}, TabContent)

local EditorBox = make("TextBox", {
    Name             = "EditorBox",
    Text             = "-- Generated with Alpha Spy BOIIIIIIIII (+99999 AURA)\n-- Services\nlocal ReplicatedStorage = game:GetService(\"ReplicatedStorage\")\n\n-- Remote\nlocal Set = ReplicatedStorage.packages._Index[\"ytrev_rep\"]\n\n-- This data was received from the server\nfiresignal(Set.OnClientEvent,\n  {\n    \"Stats\",\n    \"tracker_timeplayedStats\",\n  },\n  17213.41981738427\n)",
    Font             = Enum.Font.Code,
    TextSize         = 11,
    TextColor3       = C.Text,
    BackgroundColor3 = C.EditorBg,
    BorderSizePixel  = 0,
    Size             = UDim2.new(1, 0, 0, 260),
    MultiLine        = true,
    ClearTextOnFocus = false,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Top,
}, EditorPage)

make("UIPadding", {
    PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4),
    PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6),
}, EditorBox)

-- ---- OPTIONS PAGE ----
local OptionsPage = make("Frame", {
    Name          = "OptionsPage",
    Size          = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible       = false,
}, TabContent)

make("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding   = UDim.new(0, 8),
}, OptionsPage)

make("UIPadding", {
    PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,6),
    PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6),
}, OptionsPage)

local function sectionHeader(text, order, parent)
    local lbl = make("TextLabel", {
        Text             = text,
        Font             = Enum.Font.Code,
        TextSize         = 11,
        TextColor3       = C.Text,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 18),
        LayoutOrder      = order,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, parent)
    make("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
    }, lbl)
    return lbl
end

-- Logs section
local LogsSection = make("Frame", {
    Name          = "LogsSection",
    Size          = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    LayoutOrder   = 1,
}, OptionsPage)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4) }, LogsSection)

sectionHeader("-- Logs", 1, LogsSection)

local LogBtnRow = make("Frame", {
    Size          = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    LayoutOrder   = 2,
}, LogsSection)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0,5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, LogBtnRow)

for i, lbl in ipairs({"Clear logs", "Clear blocks", "Clear excludes"}) do
    local b = makeButton(lbl, LogBtnRow)
    b.LayoutOrder = i
    b.MouseButton1Click:Connect(function() showNotif(Main, lbl) end)
end

-- Settings section
local SettingsSection = make("Frame", {
    Name          = "SettingsSection",
    Size          = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    LayoutOrder   = 2,
}, OptionsPage)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4) }, SettingsSection)

sectionHeader("-- Settings", 1, SettingsSection)

-- Grid container (3 columns via UIGridLayout)
local SettingsGrid = make("Frame", {
    Name          = "SettingsGrid",
    Size          = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    LayoutOrder   = 2,
}, SettingsSection)

make("UIGridLayout", {
    CellSize      = UDim2.new(0, 143, 0, 28),
    CellPadding   = UDim2.new(0, 3, 0, 3),
    SortOrder     = Enum.SortOrder.LayoutOrder,
    FillDirection = Enum.FillDirection.Horizontal,
}, SettingsGrid)
-- UIGridLayout doesn't drive parent height — set explicitly
-- 10 items / 3 cols = 4 rows; row height = 28+3 = 31; total = 4*31-3 = 121px
SettingsGrid.Size = UDim2.new(1, 0, 0, 121)

for i, s in ipairs(SETTINGS) do
    local cell = make("TextButton", {
        Text             = (s.toggled and "\u{2713} " or "\u{2717} ") .. s.label .. (s.key and ("  ["..s.key.."]") or ""),
        Font             = Enum.Font.Code,
        TextSize         = 10,
        TextColor3       = C.Text,
        BackgroundColor3 = s.toggled and Color3.fromRGB(192,98,42) or Color3.fromRGB(60,30,10),
        BackgroundTransparency = s.toggled and 0.75 or 0.85,
        BorderColor3     = s.toggled and C.Border or C.BoxOff,
        BorderSizePixel  = 1,
        TextXAlignment   = Enum.TextXAlignment.Left,
        LayoutOrder      = i,
        ClipsDescendants = true,
    }, SettingsGrid)
    make("UICorner", { CornerRadius = UDim.new(0,3) }, cell)
    make("UIPadding", {
        PaddingLeft  = UDim.new(0,5),
        PaddingRight = UDim.new(0,5),
    }, cell)

    settingStates[i] = { toggled = s.toggled, btn = cell, label = s.label, key = s.key }

    cell.MouseButton1Click:Connect(function()
        local st = settingStates[i]
        st.toggled = not st.toggled
        st.btn.BackgroundTransparency = st.toggled and 0.75 or 0.85
        st.btn.BackgroundColor3 = st.toggled and Color3.fromRGB(192,98,42) or Color3.fromRGB(60,30,10)
        st.btn.BorderColor3 = st.toggled and C.Border or C.BoxOff
        st.btn.Text = (st.toggled and "\u{2713} " or "\u{2717} ") .. st.label .. (st.key and ("  ["..st.key.."]") or "")
    end)
end

-- Info section
local InfoSection = make("Frame", {
    Name          = "InfoSection",
    Size          = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    LayoutOrder   = 3,
}, OptionsPage)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4) }, InfoSection)

sectionHeader("-- Information", 1, InfoSection)

for i, line in ipairs(INFO_LINES) do
    local box = make("TextLabel", {
        Text             = "\u{2022} " .. line,
        Font             = Enum.Font.Code,
        TextSize         = 10,
        TextColor3       = C.Text,
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.88,
        BorderColor3     = C.BoxOff,
        BorderSizePixel  = 1,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        LayoutOrder      = i + 1,
    }, InfoSection)
    make("UICorner", { CornerRadius = UDim.new(0,3) }, box)
    make("UIPadding", {
        PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4),
        PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8),
    }, box)
end

-- ---- REMOTE INFO PAGE ----
local RemotePage = make("Frame", {
    Name          = "RemotePage",
    Size          = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible       = false,
}, TabContent)

make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,2) }, RemotePage)
make("UIPadding", { PaddingTop = UDim.new(0,6), PaddingLeft = UDim.new(0,6) }, RemotePage)

local remoteInfoRows = {}
local function setRemoteInfo(data)
    for _, r in ipairs(remoteInfoRows) do r:Destroy() end
    remoteInfoRows = {}
    if not data then return end
    local rows = {
        {"Remote",       data.path},
        {"MetaMethod",   "Connect"},
        {"Method",       "OnClientEvent"},
        {"CallingScript","CallingScript"},
        {"CallingActor", "--"},
        {"IsActor",      "false"},
        {"Id",           tostring(data.id) .. "_301174"},
    }
    for i, row in ipairs(rows) do
        local lbl = make("TextLabel", {
            Text           = string.format("<b>%s</b>: %s", row[1], row[2]),
            Font           = Enum.Font.Code,
            TextSize       = 11,
            TextColor3     = C.Text,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size           = UDim2.new(1, 0, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            RichText       = true,
            LayoutOrder    = i,
        }, RemotePage)
        table.insert(remoteInfoRows, lbl)
    end
end

-- ============================================================
-- TABS LOGIC
-- ============================================================
local TABS = {
    { name = "Editor",  page = EditorPage  },
    { name = "Options", page = OptionsPage },
    { name = "Remote:", page = RemotePage  },
}
local tabBtns = {}

for i, t in ipairs(TABS) do
    local btn = make("TextButton", {
        Text             = t.name,
        Font             = Enum.Font.Code,
        TextSize         = 12,
        TextColor3       = C.White,
        BackgroundColor3 = i == 1 and C.TabActive or C.TabInact,
        BorderColor3     = C.Border,
        BorderSizePixel  = 1,
        Size             = UDim2.new(0, 0, 1, 0),
        AutomaticSize    = Enum.AutomaticSize.X,
        LayoutOrder      = i,
    }, TabBar)
    make("UIPadding", {
        PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12),
    }, btn)
    tabBtns[i] = btn

    btn.MouseButton1Click:Connect(function()
        activeTab = t.name
        for j, tb in ipairs(tabBtns) do
            tb.BackgroundColor3 = j == i and C.TabActive or C.TabInact
        end
        for _, tbl in ipairs(TABS) do
            tbl.page.Visible = tbl.name == activeTab
        end
        if activeTab == "Remote:" then
            local data = selectedDupe or selectedRemote
            setRemoteInfo(data)
        end
    end)
end

-- ============================================================
-- REMOTE LIST POPULATION
-- ============================================================
local REMOTES = {}  -- populated at runtime by Ui:QueueLog()

local function getShortName(path)
    return path:match("[^%.]+$") or path:match("[^/]+$") or path
end

local function selectRemote(remote, dupe)
    selectedRemote = remote
    selectedDupe   = dupe
    if activeTab == "Remote:" then setRemoteInfo(dupe or remote) end
end

local function buildRemoteList()
    for _, child in ipairs(RemoteScroll:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    for order, remote in ipairs(REMOTES) do
        local hasDupes = #remote.dupes > 0
        local expanded = false

        -- Parent row
        local parentBtn = make("TextButton", {
            Text             = "\u{25B6} " .. getShortName(remote.path),
            Font             = Enum.Font.Code,
            TextSize         = 11,
            TextColor3       = C.White,
            BackgroundColor3 = C.Toolbar,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            Size             = UDim2.new(1, 0, 0, 22),
            TextXAlignment   = Enum.TextXAlignment.Left,
            LayoutOrder      = order * 100,
        }, RemoteScroll)
        make("UIPadding", { PaddingLeft = UDim.new(0,4) }, parentBtn)

        -- Dupe container (hidden by default)
        local dupeContainer = make("Frame", {
            Name             = "DupeContainer",
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            Visible          = false,
            LayoutOrder      = order * 100 + 1,
        }, RemoteScroll)
        make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,0) }, dupeContainer)

        for di, dupe in ipairs(remote.dupes) do
            local dupeBtn = make("TextButton", {
                Text             = "\u{25B6} Dupe " .. getShortName(dupe.path),
                Font             = Enum.Font.Code,
                TextSize         = 11,
                TextColor3       = C.DupeName,
                BackgroundColor3 = C.Toolbar,
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 22),
                TextXAlignment   = Enum.TextXAlignment.Left,
                LayoutOrder      = di,
            }, dupeContainer)
            make("UIPadding", { PaddingLeft = UDim.new(0,18) }, dupeBtn)

            dupeBtn.MouseButton1Click:Connect(function()
                selectRemote(remote, dupe)
                dupeBtn.BackgroundTransparency = 0.7
            end)
            dupeBtn.MouseEnter:Connect(function() dupeBtn.BackgroundTransparency = 0.75 end)
            dupeBtn.MouseLeave:Connect(function() dupeBtn.BackgroundTransparency = 1 end)
        end

        parentBtn.MouseButton1Click:Connect(function()
            selectRemote(remote, nil)
            -- Toggle dupes
            if hasDupes then
                expanded = not expanded
                dupeContainer.Visible = expanded
                parentBtn.Text = (expanded and "\u{25BC} " or "\u{25B6} ") .. getShortName(remote.path)
            end
        end)
        parentBtn.MouseEnter:Connect(function() parentBtn.BackgroundTransparency = 0.75 end)
        parentBtn.MouseLeave:Connect(function() parentBtn.BackgroundTransparency = 1 end)
    end
end

-- list starts empty, QueueLog() populates it at runtime

-- ============================================================
-- OPEN / CLOSE LOGIC
-- ============================================================
local function setOpen(open)
    isOpen = open
    Main.Visible = open
    MiniBar.Visible = not open
    if not open then
        -- Snap MiniBar to same X/Y as Main
        MiniBar.Position = UDim2.new(
            Main.Position.X.Scale, Main.Position.X.Offset,
            Main.Position.Y.Scale, Main.Position.Y.Offset
        )
    end
end

CloseBtn.MouseButton1Click:Connect(function() setOpen(false) end)
MiniOpen.MouseButton1Click:Connect(function() setOpen(true) end)

CloseBtn.MouseEnter:Connect(function() CloseBtn.BackgroundTransparency = 0 end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.BackgroundTransparency = 0.2 end)
MiniOpen.MouseEnter:Connect(function() MiniOpen.BackgroundTransparency = 0 end)
MiniOpen.MouseLeave:Connect(function() MiniOpen.BackgroundTransparency = 0.2 end)

-- ============================================================
-- KEYBIND TOGGLE
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        setOpen(not isOpen)
    end
end)

setOpen(true)

-- ============================================================
-- LOG STATE
-- ============================================================
local LiveRemotes = {}   -- ordered list of { id, path, method, output, script, dupes={} }
local RemoteIndex = {}   -- path -> LiveRemotes index, for dupe detection
local IsPaused    = false
local CommChannel = nil  -- set via Ui:SetCommChannel()

local function clearLogs()
    LiveRemotes = {}
    RemoteIndex = {}
    REMOTES     = {}
    buildRemoteList()
    EditorBox.Text = "-- Logs cleared"
    showNotif(Main, "Logs cleared")
end

-- Wire "Clear logs" button
for _, child in ipairs(LogBtnRow:GetChildren()) do
    if child:IsA("TextButton") and child.Text == "Clear logs" then
        child.MouseButton1Click:Connect(clearLogs)
    end
end

-- ============================================================
-- MODULE API
-- ============================================================
local Ui = {}

--[[
    Ui:QueueLog(Data)

    Called by Main/Communication with a fully-prepared log entry.
    Expected fields in Data:
        Data.Remote  -- RemoteEvent or RemoteFunction instance
        Data.Path    -- string, full path e.g. "ReplicatedStorage.MyRemote"
        Data.Method  -- string, e.g. "FireServer" | "OnClientEvent" | "InvokeServer"
        Data.Script  -- string, name of the calling script (optional)
        Data.Output  -- string, the generated Lua code from the parser
]]
function Ui:QueueLog(Data)
    if IsPaused then return end

    local path   = Data.Path   or (Data.Remote and Data.Remote:GetFullName()) or "Unknown"
    local method = Data.Method or "Unknown"
    local output = Data.Output or ("-- No output provided\n-- Remote: " .. path)
    local script = Data.Script or ""

    if RemoteIndex[path] then
        -- Already exists — push as a dupe under the parent
        local parent = LiveRemotes[RemoteIndex[path]]
        local dupeId = #parent.dupes + 1
        local dupe = {
            id     = parent.id * 1000 + dupeId,
            path   = path,
            method = method,
            output = output,
            script = script,
        }
        table.insert(parent.dupes, dupe)

        -- Append dupe row directly without full rebuild for performance
        local parentEntry = REMOTES[RemoteIndex[path]]
        if parentEntry then
            table.insert(parentEntry.dupes, dupe)
        end

        -- Find and update the existing dupe container in the scroll
        for _, child in ipairs(RemoteScroll:GetChildren()) do
            if child.Name == "DupeContainer"
            and child.LayoutOrder == RemoteIndex[path] * 100 + 1 then
                local dupeBtn = make("TextButton", {
                    Text             = "\u{25B6} Dupe " .. getShortName(path),
                    Font             = Enum.Font.Code,
                    TextSize         = 11,
                    TextColor3       = C.DupeName,
                    BackgroundColor3 = C.Toolbar,
                    BackgroundTransparency = 1,
                    BorderSizePixel  = 0,
                    Size             = UDim2.new(1, 0, 0, 22),
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    LayoutOrder      = dupeId,
                }, child)
                make("UIPadding", { PaddingLeft = UDim.new(0, 18) }, dupeBtn)

                dupeBtn.MouseButton1Click:Connect(function()
                    selectRemote(parentEntry, dupe)
                    EditorBox.Text = dupe.output
                    if activeTab == "Remote:" then setRemoteInfo(dupe) end
                end)
                dupeBtn.MouseEnter:Connect(function() dupeBtn.BackgroundTransparency = 0.75 end)
                dupeBtn.MouseLeave:Connect(function() dupeBtn.BackgroundTransparency = 1 end)

                child.Visible = true  -- show dupe container if first dupe
                break
            end
        end

        -- Refresh editor if this remote is selected
        if selectedRemote and selectedRemote.path == path then
            EditorBox.Text = output
        end
    else
        -- Brand new remote
        local id = #LiveRemotes + 1
        local entry = {
            id     = id,
            path   = path,
            method = method,
            output = output,
            script = script,
            dupes  = {},
        }
        table.insert(LiveRemotes, entry)
        RemoteIndex[path] = id

        -- Push to REMOTES display table
        table.insert(REMOTES, { id = id, path = path, dupes = {} })

        -- Add a single row to the scroll without full rebuild
        local order = id
        local expanded = false

        local parentBtn = make("TextButton", {
            Text             = "\u{25B6} " .. getShortName(path),
            Font             = Enum.Font.Code,
            TextSize         = 11,
            TextColor3       = C.White,
            BackgroundColor3 = C.Toolbar,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            Size             = UDim2.new(1, 0, 0, 22),
            TextXAlignment   = Enum.TextXAlignment.Left,
            LayoutOrder      = order * 100,
        }, RemoteScroll)
        make("UIPadding", { PaddingLeft = UDim.new(0, 4) }, parentBtn)

        local dupeContainer = make("Frame", {
            Name             = "DupeContainer",
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            Visible          = false,
            LayoutOrder      = order * 100 + 1,
        }, RemoteScroll)
        make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 0),
        }, dupeContainer)

        parentBtn.MouseButton1Click:Connect(function()
            selectRemote(REMOTES[id], nil)
            EditorBox.Text = entry.output
            if activeTab == "Remote:" then setRemoteInfo(REMOTES[id]) end

            if #entry.dupes > 0 then
                expanded = not expanded
                dupeContainer.Visible = expanded
                parentBtn.Text = (expanded and "\u{25BC} " or "\u{25B6} ") .. getShortName(path)
            end
        end)
        parentBtn.MouseEnter:Connect(function() parentBtn.BackgroundTransparency = 0.75 end)
        parentBtn.MouseLeave:Connect(function() parentBtn.BackgroundTransparency = 1 end)

        -- Auto-select the very first remote that comes in
        if id == 1 then
            selectedRemote = REMOTES[1]
            EditorBox.Text = output
        end
    end
end

-- Pause/resume log intake
function Ui:SetPaused(state)
    IsPaused = state
end

function Ui:IsPaused()
    return IsPaused
end

-- Store a reference to the comm channel so action buttons can talk back
function Ui:SetCommChannel(channel)
    CommChannel = channel
end

-- Wipe all logs
function Ui:ClearLogs()
    clearLogs()
end

return Ui
