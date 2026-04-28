local Ui = {
    DefaultEditorContent = [[-- Welcome to Alpha Spy!
-- Click on a remote log to see generated code here

print("Alpha Spy loaded!")
]],
    LogLimit = 100,
    Scales = {
        ["Mobile"] = UDim2.fromOffset(480, 280),
        ["Desktop"] = UDim2.fromOffset(700, 450)
    },
    BaseConfig = {
        Theme = "DarkTheme",
        NoScroll = true
    },
    OptionTypes = {
        boolean = "Checkbox"
    },
    DisplayRemoteInfo = {
        "MetaMethod",
        "Method",
        "Remote",
        "CallingScript",
        "IsActor",
        "Id"
    },
    Window = nil,
    RandomSeed = Random.new(tick()),
    Logs = setmetatable({}, {__mode = "k"}),
    LogQueue = setmetatable({}, {__mode = "v"})
}

type table = {
    [any]: any
}

type Log = {
    Remote: Instance,
    Method: string,
    Args: table,
    IsReceive: boolean?,
    MetaMethod: string?,
    OriginalFunc: ((...any) -> ...any)?,
    CallingScript: Instance?,
    CallingFunction: ((...any) -> ...any)?,
    ClassData: table?,
    ReturnValues: table?,
    RemoteData: table?,
    Id: string,
    Selectable: table,
    HeaderData: table,
    ValueSwaps: table,
    Timestamp: number,
    IsExploit: boolean
}

--// Compatibility
local SetClipboard = setclipboard or toclipboard or set_clipboard

--// Libraries
local ReGui = nil

--// Modules
local Flags
local Generation
local Process
local Hook
local Config
local Communication
local Debug
local ActiveData = nil
local RemotesCount = 0
local TextFont = Font.fromEnum(Enum.Font.Code)
local FontSuccess = false
local CommChannel

function Ui:Init(Data)
    local Modules = Data.Modules
    local Configuration = Data.Configuration
    
    --// Modules
    Flags = Modules.Flags
    Generation = Modules.Generation
    Process = Modules.Process
    Hook = Modules.Hook
    Config = Modules.Config
    Communication = Modules.Communication
    Debug = Modules.Debug
    
    --// Load ReGui
    local ReGuiUrl = Configuration.RepoUrl
    if ReGuiUrl and ReGuiUrl ~= "" then
        ReGui = loadstring(game:HttpGet(`{ReGuiUrl}/lib/ReGui.lua`), "ReGui")()
    else
        --// Fallback simple UI
        ReGui = self:SimpleUI()
    end
    
    self:LoadFont()
    self:LoadReGui()
    self:CheckScale()
end

function Ui:SetCommChannel(NewCommChannel: BindableEvent)
    CommChannel = NewCommChannel
end

function Ui:CheckScale()
    local BaseConfig = self.BaseConfig
    local Scales = self.Scales
    local IsMobile = ReGui:IsMobileDevice()
    local Device = IsMobile and "Mobile" or "Desktop"
    BaseConfig.Size = Scales[Device]
end

function Ui:SetClipboard(Content: string)
    if SetClipboard then
        SetClipboard(Content)
    end
end

function Ui:LoadFont()
    --// Try to load custom font
    if Config and Config.FontAssetId then
        local Success, NewFont = pcall(function()
            return Font.new(Config.FontAssetId)
        end)
        
        if Success then
            TextFont = NewFont
            FontSuccess = true
        end
    end
end

function Ui:FontWasSuccessful()
    if FontSuccess then return end
    
    self:ShowModal({
        "Font loading failed - using default font",
        "Some features may look different"
    })
end

function Ui:LoadReGui()
    local ThemeConfig = Config and Config.ThemeConfig or {}
    ThemeConfig.TextFont = TextFont
    
    --// Define theme
    ReGui:DefineTheme("AlphaSpy", ThemeConfig)
end

function Ui:CreateWindow(WindowConfig)
    local BaseConfig = self.BaseConfig
    local Config = Process:DeepCloneTable(BaseConfig)
    Process:Merge(Config, WindowConfig)
    
    --// Create Window
    local Window = ReGui:Window(Config)
    
    --// Switch theme if font failed
    if not FontSuccess then
        Window:SetTheme("DarkTheme")
    end
    
    return Window
end

function Ui:AskUser(Config): string
    local Window = self.Window
    local Answered = false
    
    --// Create modal
    local ModalWindow = Window:PopupModal({
        Title = Config.Title
    })
    
    ModalWindow:Label({
        Text = table.concat(Config.Content, "\n"),
        TextWrapped = true
    })
    
    ModalWindow:Separator()
    
    --// Answers
    local Row = ModalWindow:Row({Expanded = true})
    
    for _, Answer in next, Config.Options do
        Row:Button({
            Text = Answer,
            Callback = function()
                Answered = Answer
                ModalWindow:ClosePopup()
            end
        })
    end
    
    repeat wait() until Answered
    return Answered
end

function Ui:CreateMainWindow()
    local Window = self:CreateWindow({
        Title = "Alpha Spy",
        Size = self.BaseConfig.Size
    })
    
    self.Window = Window

    self:FontWasSuccessful()
    
    Flags:SetFlagCallback("UiVisible", function(Visible)
        Window:SetVisible(Visible)
    end)
    
    return Window
end

function Ui:ShowModal(Lines: table)
    local Window = self.Window
    if not Window then return end
    
    local Message = table.concat(Lines, "\n")
    
    local ModalWindow = Window:PopupModal({
        Title = "Alpha Spy"
    })
    
    ModalWindow:Label({
        Text = Message,
        RichText = true,
        TextWrapped = true
    })
    
    ModalWindow:Button({
        Text = "Okay",
        Callback = function()
            ModalWindow:ClosePopup()
        end
    })
end

function Ui:ShowUnsupportedExecutor(Name: string)
    self:ShowModal({
        "Alpha Spy is not supported on your executor",
        `Your executor: {Name}`
    })
end

function Ui:ShowUnsupported(FuncName: string)
    self:ShowModal({
        "Alpha Spy is not supported on your executor",
        `Missing function: {FuncName}`
    })
end

function Ui:CreateOptionsForDict(Parent, Dict: table, Callback)
    local Options = {}
    
    for Key, Value in next, Dict do
        Options[Key] = {
            Value = Value,
            Label = Key,
            Callback = function(_, Value)
                Dict[Key] = Value
                if Callback then
                    Callback()
                end
            end
        }
    end
    
    self:CreateElements(Parent, Options)
end

function Ui:CreateElements(Parent, Options)
    local OptionTypes = self.OptionTypes
    
    for Name, Data in Options do
        local Value = Data.Value
        local Type = typeof(Value)
        
        --// Check config
        if not Data.Class then
            Data.Class = OptionTypes[Type]
        end
        
        if not Data.Label then
            Data.Label = Name
        end
        
        --// Create element
        local Class = Data.Class
        if Class and Parent[Class] then
            Parent[Class](Parent, Data)
        end
    end
end

function Ui:CreateWindowContent()
    local Window = self.Window
    
    --// Layout
    local Layout = Window:List({
        UiPadding = 2,
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        VerticalFlex = Enum.UIFlexAlignment.Fill,
        FillDirection = Enum.FillDirection.Vertical,
        Fill = true
    })
    
    --// Remotes list
    self.RemotesList = Layout:Canvas({
        Scroll = true,
        UiPadding = 5,
        AutomaticSize = Enum.AutomaticSize.None,
        FlexMode = Enum.UIFlexMode.None,
        Size = UDim2.new(0, 150, 1, 0)
    })
    
    --// Tab selector
    local InfoSelector = Layout:TabSelector({
        NoAnimation = true,
        Size = UDim2.new(1, -150, 0.4, 0)
    })
    
    self.InfoSelector = InfoSelector
    self.CanvasLayout = Layout
    
    --// Make tabs
    self:MakeEditorTab(InfoSelector)
    self:MakeOptionsTab(InfoSelector)
    
    --// Debug tab (only if debug mode)
    if Debug then
        self:MakeDebugTab(InfoSelector)
    end
    
    --// Console tab
    self:ConsoleTab(InfoSelector)
end

function Ui:ConsoleTab(InfoSelector)
    local Tab = InfoSelector:CreateTab({
        Name = "Console"
    })
    
    local Console
    
    local ButtonsRow = Tab:Row()
    ButtonsRow:Button({
        Text = "Clear",
        Callback = function()
            Console:Clear()
        end
    })
    
    ButtonsRow:Button({
        Text = "Copy",
        Callback = function()
            self:SetClipboard(Console:GetValue())
        end
    })
    
    ButtonsRow:Expand()
    
    --// Create console
    Console = Tab:Console({
        Text = "-- Alpha Spy Console",
        ReadOnly = true,
        Border = false,
        Fill = true,
        Enabled = true,
        AutoScroll = true,
        RichText = true,
        MaxLines = 100
    })
    
    self.Console = Console
end

function Ui:ConsoleLog(...: string?)
    local Console = self.Console
    if not Console then return end
    
    local Args = {...}
    local Message = ""
    
    for i, Arg in ipairs(Args) do
        if i > 1 then Message ..= " " end
        Message ..= tostring(Arg)
    end
    
    Console:AppendText(Message)
end

function Ui:MakeOptionsTab(InfoSelector)
    local Tab = InfoSelector:CreateTab({
        Name = "Options"
    })
    
    --// Log options
    Tab:Separator({Text = "Log Options"})
    
    local LogOptions = Flags:GetFlagsByCategory("Display")
    self:CreateElements(Tab, LogOptions)
    
    --// Generation options
    Tab:Separator({Text = "Generation Options"})
    
    local GenOptions = Flags:GetFlagsByCategory("Generation")
    self:CreateElements(Tab, GenOptions)
    
    --// Filtering options
    Tab:Separator({Text = "Filtering"})
    
    local FilterOptions = Flags:GetFlagsByCategory("Filtering")
    self:CreateElements(Tab, FilterOptions)
    
    --// Actions
    Tab:Separator({Text = "Actions"})
    
    local ActionsRow = Tab:Row()
    
    ActionsRow:Button({
        Text = "Clear Logs",
        Callback = function()
            self:ClearLogs()
        end
    })
    
    ActionsRow:Button({
        Text = "Clear Blocks",
        Callback = function()
            Process:UpdateAllRemoteData("Blocked", false)
        end
    })
    
    ActionsRow:Button({
        Text = "Copy GitHub",
        Callback = function()
            self:SetClipboard("https://github.com/yourusername/Alpha-Spy")
        end
    })
end

function Ui:MakeDebugTab(InfoSelector)
    local Tab = InfoSelector:CreateTab({
        Name = "Debug"
    })
    
    Tab:Label({
        Text = "Debug Tools for Bypass Development",
        TextColor3 = Color3.fromRGB(255, 200, 0)
    })
    
    Tab:Separator({Text = "Debug Options"})
    
    local DebugOptions = Flags:GetFlagsByCategory("Debug")
    self:CreateElements(Tab, DebugOptions)
    
    Tab:Separator({Text = "Actions"})
    
    local ActionsRow = Tab:Row()
    
    ActionsRow:Button({
        Text = "Clear History",
        Callback = function()
            if Debug then
                Debug:ClearHistory()
            end
        end
    })
    
    ActionsRow:Button({
        Text = "Reset Stats",
        Callback = function()
            if Debug then
                Debug:ResetStats()
            end
        end
    })
    
    ActionsRow:Button({
        Text = "Export History",
        Callback = function()
            if Debug then
                local Export = Debug:ExportCallHistory()
                self:SetClipboard(Export)
                self:ShowModal({"Call history exported to clipboard!"})
            end
        end
    })
    
    ActionsRow:Expand()
    
    --// Stats display
    Tab:Separator({Text = "Statistics"})
    
    local StatsLabel = Tab:Label({
        Text = "Loading stats..."
    })
    
    --// Update stats
    task.spawn(function()
        while true do
            wait(1)
            if Debug then
                local Stats = Debug:GetStats()
                StatsLabel.Text = `Total Calls: {Stats.TotalCalls} | Modified: {Stats.ModifiedCalls}`
            end
        end
    end)
end

function Ui:MakeEditorTab(InfoSelector)
    local Default = self.DefaultEditorContent
    
    --// Create tab
    local EditorTab = InfoSelector:CreateTab({
        Name = "Editor"
    })
    
    --// Code editor
    local CodeEditor = EditorTab:CodeEditor({
        Fill = true,
        Editable = true,
        FontSize = 13,
        FontFace = TextFont,
        Text = Default
    })
    
    --// Buttons
    local ButtonsRow = EditorTab:Row()
    
    ButtonsRow:Button({
        Text = "Copy",
        Callback = function()
            local Script = CodeEditor:GetText()
            self:SetClipboard(Script)
        end
    })
    
    ButtonsRow:Button({
        Text = "Run",
        Callback = function()
            local Script = CodeEditor:GetText()
            local Func, Error = loadstring(Script, "AlphaSpy-UserScript")
            
            if not Func then
                self:ShowModal({"Error running script!\n", Error})
                return
            end
            
            Func()
        end
    })
    
    ButtonsRow:Button({
        Text = "Save",
        Callback = function()
            if ActiveData then
                ActiveData:SaveScript()
            end
        end
    })
    
    self.CodeEditor = CodeEditor
end

function Ui:ShouldFocus(Tab): boolean
    local InfoSelector = self.InfoSelector
    local ActiveTab = InfoSelector.ActiveTab
    
    if not ActiveTab then
        return true
    end
    
    return InfoSelector:CompareTabs(ActiveTab, Tab)
end

function Ui:SetFocusedRemote(Data)
    --// Unpack
    local Remote = Data.Remote
    local Method = Data.Method
    local Args = Data.Args
    local Id = Data.Id
    
    --// Flags
    local TableArgs = Flags:GetFlagValue("TableArgs")
    local NoVariables = Flags:GetFlagValue("NoVariables")
    
    --// Get data
    local RemoteData = Process:GetRemoteData(Id)
    local RemoteName = tostring(Remote):sub(1, 50)
    
    --// UI elements
    local CodeEditor = self.CodeEditor
    local InfoSelector = self.InfoSelector
    
    --// Remove previous
    local TabFocused = self:RemovePreviousTab()
    
    --// Create new tab
    local Tab = InfoSelector:CreateTab({
        Name = `Remote: {RemoteName}`,
        Focused = TabFocused
    })
    
    --// Create parser
    local Module = Generation:NewParser({
        NoVariables = NoVariables
    })
    
    --// Set active
    ActiveData = Data
    Data.Tab = Tab
    
    local function SetIDEText(Content: string, Task: string?)
        Data.Task = Task or "Alpha Spy"
        CodeEditor:SetText(Content)
    end
    
    --// Functions
    function Data:SaveScript()
        local FilePath = Generation:TimeStampFile(self.Task .. " %s.lua")
        writefile(FilePath, CodeEditor:GetText())
        Ui:ShowModal({"Saved script to", FilePath})
    end
    
    function Data:MakeScript(ScriptType: string)
        local Script = Generation:RemoteScript(Module, self, ScriptType)
        SetIDEText(Script, `Editing: {RemoteName}.lua`)
    end
    
    --// Remote options
    self:CreateOptionsForDict(Tab, RemoteData, function()
        Process:UpdateRemoteData(Id, RemoteData)
    end)
    
    --// Buttons
    local ButtonsRow = Tab:Row()
    
    ButtonsRow:Button({
        Text = "Copy Remote Path",
        Callback = function()
            self:SetClipboard(Remote:GetFullName())
        end
    })
    
    ButtonsRow:Button({
        Text = "Remove Log",
        Callback = function()
            InfoSelector:RemoveTab(Tab)
            Data.Selectable:Remove()
            Data.HeaderData:Remove()
            ActiveData = nil
        end
    })
    
    ButtonsRow:Expand()
    
    --// Generate script
    if TableArgs then
        local Parsed = Generation:TableScript(Module, Args)
        SetIDEText(Parsed, `Arguments for {RemoteName}`)
    else
        Data:MakeScript("Remote")
    end
end

function Ui:RemovePreviousTab(): boolean
    if not ActiveData then
        return false
    end
    
    local InfoSelector = self.InfoSelector
    local PreviousTab = ActiveData.Tab
    
    local TabFocused = self:ShouldFocus(PreviousTab)
    InfoSelector:RemoveTab(PreviousTab)
    
    return TabFocused
end

function Ui:GetRemoteHeader(Data: Log)
    local LogLimit = self.LogLimit
    local Logs = self.Logs
    local RemotesList = self.RemotesList
    
    --// Info
    local Id = Data.Id
    local Remote = Data.Remote
    local RemoteName = tostring(Remote):sub(1, 30)
    
    --// Check existing
    local Existing = Logs[Id]
    if Existing then return Existing end
    
    --// Header data
    local HeaderData = {
        LogCount = 0,
        Data = Data,
        Entries = {}
    }
    
    --// Increment
    RemotesCount += 1
    
    --// Create TreeNode
    HeaderData.TreeNode = RemotesList:TreeNode({
        LayoutOrder = -1 * RemotesCount,
        Title = RemoteName
    })
    
    function HeaderData:CheckLimit()
        local Entries = self.Entries
        if #Entries < LogLimit then return end
        
        local Log = table.remove(Entries, 1)
        Log.Selectable:Remove()
    end
    
    function HeaderData:LogAdded(Data)
        self.LogCount += 1
        self:CheckLimit()
        
        table.insert(self.Entries, Data)
        return self
    end
    
    function HeaderData:Remove()
        if self.TreeNode then
            self.TreeNode:Remove()
        end
        
        Logs[Id] = nil
        table.clear(HeaderData)
    end
    
    Logs[Id] = HeaderData
    return HeaderData
end

function Ui:ClearLogs()
    local Logs = self.Logs
    local RemotesList = self.RemotesList
    
    RemotesCount = 0
    RemotesList:ClearChildElements()
    table.clear(Logs)
end

function Ui:QueueLog(Data)
    local LogQueue = self.LogQueue
    
    Process:Merge(Data, {
        Args = Process:DeepCloneTable(Data.Args)
    })
    
    if Data.ReturnValues then
        Data.ReturnValues = Process:DeepCloneTable(Data.ReturnValues)
    end
    
    table.insert(LogQueue, Data)
end

function Ui:ProcessLogQueue()
    local Queue = self.LogQueue
    if #Queue <= 0 then return end
    
    for Index, Data in next, Queue do
        self:CreateLog(Data)
        table.remove(Queue, Index)
    end
end

function Ui:BeginLogService()
    coroutine.wrap(function()
        while true do
            self:ProcessLogQueue()
            task.wait()
        end
    end)()
end

function Ui:FilterName(Name: string, CharacterLimit: number?): string
    local Trimmed = Name:sub(1, CharacterLimit or 20)
    local Filtered = Trimmed:gsub("[\n\r]", "")
    return Filtered
end

function Ui:CreateLog(Data: Log)
    --// Unpack
    local Remote = Data.Remote
    local Method = Data.Method
    local Args = Data.Args
    local Id = Data.Id
    local IsExploit = Data.IsExploit
    local IsNilParent = Hook:Index(Remote, "Parent") == nil
    local RemoteData = Process:GetRemoteData(Id)
    
    --// Paused check
    local Paused = Flags:GetFlagValue("Paused")
    if Paused then return end
    
    --// Exploit check
    local LogExploit = Flags:GetFlagValue("LogExploit")
    if not LogExploit and IsExploit then return end
    
    --// Ignore nil
    local IgnoreNil = Flags:GetFlagValue("IgnoreNil")
    if IgnoreNil and IsNilParent then return end
    
    --// Log receives
    local LogReceives = Flags:GetFlagValue("LogReceives")
    if not LogReceives and Data.IsReceive then return end
    
    local SelectNewest = Flags:GetFlagValue("SelectNewest")
    
    --// Excluded check
    if RemoteData.Excluded then return end
    
    --// Deserialize
    Args = Communication:DeserializeTable(Args)
    Data.Args = Process:DeepCloneTable(Args)
    Data.ValueSwaps = Generation:MakeValueSwapsTable()
    
    --// Log title
    local Text = `{Method}`
    
    --// Find string for name
    local FindString = Flags:GetFlagValue("FindStringForName")
    if FindString then
        for _, Arg in next, Args do
            if typeof(Arg) == "string" then
                Text = `{Arg:sub(1, 20)} | {Text}`
                break
            end
        end
    end
    
    --// Get header
    local Header = self:GetRemoteHeader(Data)
    local RemotesList = self.RemotesList
    local LogCount = Header.LogCount
    local TreeNode = Header.TreeNode
    local Parent = TreeNode or RemotesList
    
    --// Create selectable
    Data.HeaderData = Header
    Data.Selectable = Parent:Selectable({
        Text = Text,
        LayoutOrder = -1 * LogCount,
        TextXAlignment = Enum.TextXAlignment.Left,
        Callback = function()
            self:SetFocusedRemote(Data)
        end
    })
    
    Header:LogAdded(Data)
    
    --// Auto select
    local GroupSelected = ActiveData and ActiveData.HeaderData == Header
    if SelectNewest and GroupSelected then
        self:SetFocusedRemote(Data)
    end
end

--// Simple UI fallback
function Ui:SimpleUI()
    return {
        IsMobileDevice = function() return false end,
        DefineTheme = function() end,
        Window = function(Config)
            return {
                SetVisible = function() end,
                SetTheme = function() end,
                PopupModal = function() return {} end,
                Label = function() return {} end,
                Button = function() return {} end,
                Row = function() return {} end,
                List = function() return {} end,
                Canvas = function() return {} end,
                TabSelector = function() return {} end,
                CodeEditor = function() return {} end,
                Console = function() return {} end,
                TreeNode = function() return {} end,
                Selectable = function() return {} end,
                Separator = function() end,
                Checkbox = function() end
            }
        end
    }
end

return Ui
