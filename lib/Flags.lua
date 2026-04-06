type FlagValue = boolean | number | any
type Flag = {
    Value: FlagValue,
    Label: string,
    Category: string,
    Callback: ((...any) -> ...any)?
}

type Flags = {
    [string]: Flag
}

type table = {
    [any]: any
}

local Module = {
    Flags = {
        --// Display Options
        NoComments = {
            Value = false,
            Label = "No comments in generated code",
            Category = "Generation"
        },
        SelectNewest = {
            Value = false,
            Label = "Auto select newest log",
            Category = "Display"
        },
        DecompilePopout = {
            Value = false,
            Label = "Pop-out decompiles",
            Category = "Display"
        },
        
        --// Filtering Options
        IgnoreNil = {
            Value = true,
            Label = "Ignore nil parents",
            Category = "Filtering"
        },
        LogExploit = {
            Value = true,
            Label = "Log exploit calls",
            Category = "Filtering"
        },
        LogReceives = {
            Value = true,
            Label = "Log receives",
            Category = "Filtering"
        },
        FindStringForName = {
            Value = true,
            Label = "Find arg for name",
            Category = "Display"
        },
        
        --// UI Options
        Paused = {
            Value = false,
            Label = "Paused",
            Category = "UI",
            Keybind = Enum.KeyCode.Q
        },
        KeybindsEnabled = {
            Value = true,
            Label = "Keybinds Enabled",
            Category = "UI"
        },
        UiVisible = {
            Value = true,
            Label = "UI Visible",
            Category = "UI",
            Keybind = Enum.KeyCode.P
        },
        
        --// Generation Options
        NoTreeNodes = {
            Value = false,
            Label = "No grouping (flat list)",
            Category = "Display"
        },
        TableArgs = {
            Value = false,
            Label = "Show args as table",
            Category = "Generation"
        },
        NoVariables = {
            Value = false,
            Label = "No compression (full paths)",
            Category = "Generation"
        },
        
        --// Debug Options (only visible in debug mode)
        DebugIntercept = {
            Value = false,
            Label = "Intercept all calls",
            Category = "Debug"
        },
        DebugModifyArgs = {
            Value = false,
            Label = "Enable arg modification",
            Category = "Debug"
        },
        DebugLogStack = {
            Value = false,
            Label = "Log stack traces",
            Category = "Debug"
        },
        DebugBlockAll = {
            Value = false,
            Label = "Block all remotes (test)",
            Category = "Debug"
        }
    }
}

function Module:GetFlagValue(Name: string): FlagValue
    local Flag = self:GetFlag(Name)
    return Flag.Value
end

function Module:SetFlagValue(Name: string, Value: FlagValue)
    local Flag = self:GetFlag(Name)
    Flag.Value = Value
    
    --// Invoke callback if exists
    if Flag.Callback then
        Flag.Callback(Value)
    end
end

function Module:SetFlagCallback(Name: string, Callback: (...any) -> ...any)
    local Flag = self:GetFlag(Name)
    Flag.Callback = Callback
end

function Module:SetFlagCallbacks(Dict: {})
    for Name, Callback in next, Dict do
        self:SetFlagCallback(Name, Callback)
    end
end

function Module:GetFlag(Name: string): Flag
    local AllFlags = self:GetFlags()
    local Flag = AllFlags[Name]
    assert(Flag, `Flag '{Name}' does not exist!`)
    return Flag
end

function Module:AddFlag(Name: string, Flag: Flag)
    local AllFlags = self:GetFlags()
    AllFlags[Name] = Flag
end

function Module:GetFlags(): Flags
    return self.Flags
end

function Module:GetFlagsByCategory(Category: string): Flags
    local Result = {}
    for Name, Flag in next, self.Flags do
        if Flag.Category == Category then
            Result[Name] = Flag
        end
    end
    return Result
end

return Module
