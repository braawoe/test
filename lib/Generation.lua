type table = {
    [any]: any
}

type RemoteData = {
    Remote: Instance,
    IsReceive: boolean?,
    MetaMethod: string,
    Args: table,
    Method: string,
    TransferType: string,
    ValueReplacements: table,
    NoVariables: boolean?
}

--// Module
local Generation = {
    DumpBaseName = "AlphaSpy-Dump %s.lua",
    Header = "-- Generated with Alpha Spy\n-- GitHub: https://github.com/yourusername/Alpha-Spy\n\n",
    
    ScriptTemplates = {
        ["Remote"] = {
            {"%RemoteCall%"}
        },
        ["Spam"] = {
            {"while wait() do"},
            {"%RemoteCall%", 2},
            {"end"}
        },
        ["Repeat"] = {
            {"for Index = 1, 10 do"},
            {"%RemoteCall%", 2},
            {"end"}
        },
        ["Block"] = {
            ["__index"] = {
                {"local Old; Old = hookfunction(%Signal%, function(self, ...)"},
                {"if self == %Remote% then", 2},
                {"return", 3},
                {"end", 2},
                {"return Old(self, ...)", 2},
                {"end)"}
            },
            ["__namecall"] = {
                {"local Old; Old = hookmetamethod(game, \"__namecall\", function(self, ...)"},
                {"local Method = getnamecallmethod()", 2},
                {"if self == %Remote% and Method == \"%Method%\" then", 2},
                {"return", 3},
                {"end", 2},
                {"return Old(self, ...)", 2},
                {"end)"}
            },
            ["Connect"] = {
                {"for _, Connection in getconnections(%Signal%) do"},
                {"Connection:Disable()", 2},
                {"end"}
            }
        }
    }
}

--// Modules
local Config
local Hook
local ParserModule
local Flags

local function Merge(Base: table, New: table?)
    if not New then return end
    for Key, Value in next, New do
        Base[Key] = Value
    end
end

function Generation:Init(Data: table)
    local Modules = Data.Modules
    local Configuration = Data.Configuration
    
    Config = Modules.Config
    Hook = Modules.Hook
    Flags = Modules.Flags
    
    --// Import parser
    local ParserUrl = Configuration.ParserUrl
    if ParserUrl and ParserUrl ~= "" then
        self:LoadParser(ParserUrl)
    end
end

function Generation:LoadParser(ModuleUrl: string)
    local Success, Result = pcall(function()
        return loadstring(game:HttpGet(ModuleUrl), "Parser")()
    end)
    
    if Success then
        ParserModule = Result
        print("[Generation] Parser loaded successfully")
    else
        warn("[Generation] Failed to load parser:", Result)
    end
end

function Generation:MakePrintable(String: string): string
    if not ParserModule then return String end
    local Formatter = ParserModule.Modules.Formatter
    return Formatter:MakePrintable(String)
end

function Generation:TimeStampFile(FilePath: string): string
    local TimeStamp = os.date("%Y-%m-%d_%H-%M-%S")
    return FilePath:format(TimeStamp)
end

function Generation:WriteDump(Content: string): string
    local FilePath = self:TimeStampFile(self.DumpBaseName)
    writefile(FilePath, Content)
    return FilePath
end

function Generation:MakeValueSwapsTable(): table
    if not ParserModule then return {} end
    local Formatter = ParserModule.Modules.Formatter
    return Formatter:MakeReplacements()
end

function Generation:GetBase(Module): (string, boolean)
    local NoComments = Flags:GetFlagValue("NoComments")
    local Header = self.Header
    local Code = NoComments and "" or Header
    
    --// Generate variables code
    if Module and Module.Parser then
        local Variables = Module.Parser:MakeVariableCode({
            "Services", "Remote", "Variables"
        }, NoComments)
        
        local NoVariables = Variables == ""
        Code ..= Variables
        return Code, NoVariables
    end
    
    return Code, true
end

function Generation:GetSwaps()
    local Func = self.SwapsCallback
    local Swaps = {}
    local Interface = {}
    
    function Interface:AddSwap(Object: Instance, Data: table)
        if not Object then return end
        Swaps[Object] = Data
    end
    
    if Func then
        Func(Interface)
    end
    
    return Swaps
end

function Generation:PickVariableName(): string
    if not Config or not Config.VariableNames then
        return "Var%d"
    end
    
    local Names = Config.VariableNames
    return Names[math.random(1, #Names)]
end

function Generation:NewParser(Extra: table?)
    if not ParserModule then
        return self:SimpleParser()
    end
    
    local VariableName = self:PickVariableName()
    local Swaps = self:GetSwaps()
    
    local Configuration = {
        VariableBase = VariableName,
        Swaps = Swaps,
        IndexFunc = function(...)
            return Hook:Index(...)
        end
    }
    
    Merge(Configuration, Extra)
    
    return ParserModule:New(Configuration)
end

--// Simple parser fallback
function Generation:SimpleParser()
    return {
        Formatter = {
            Format = function(self, Value, Extra)
                local Type = typeof(Value)
                
                if Type == "Instance" then
                    return Value:GetFullName()
                elseif Type == "string" then
                    return `"{Value}"`
                elseif Type == "number" or Type == "boolean" then
                    return tostring(Value)
                elseif Type == "table" then
                    return self:FormatTable(Value)
                else
                    return `<{Type}: {tostring(Value)}>`
                end
            end,
            
            FormatTable = function(self, Table)
                local Parts = {}
                for k, v in pairs(Table) do
                    local Key = self:Format(k)
                    local Value = self:Format(v)
                    table.insert(Parts, `[{Key}] = {Value}`)
                end
                return `{{table.concat(Parts, ", ")}}`
            end
        },
        
        Parser = {
            ParseTableIntoString = function(self, Data)
                local Table = Data.Table
                local Formatter = Data.Formatter or self
                
                local Parts = {}
                for k, v in pairs(Table) do
                    table.insert(Parts, Formatter:Format(v))
                end
                
                return table.concat(Parts, ", ")
            end,
            
            MakePathString = function(self, Data)
                local Object = Data.Object
                return Object:GetFullName(), 1
            end,
            
            MakeVariableCode = function(self, Order, NoComments)
                return ""
            end
        },
        
        Variables = {
            MakeVariable = function(self, Data)
                return Data.Name or "Remote"
            end
        }
    }
end

function Generation:Indent(IndentString: string, Line: string)
    return `{IndentString}{Line}`
end

type CallInfo = {
    Arguments: table,
    Indent: number,
    RemoteVariable: string,
    Module: table
}

function Generation:CallRemoteScript(Data, Info: CallInfo): string
    local IsReceive = Data.IsReceive
    local Method = Data.Method
    local Args = Data.Args
    local RemoteVariable = Info.RemoteVariable
    local Indent = Info.Indent or 0
    local Module = Info.Module
    
    if not Module then
        --// Simple fallback
        local ArgsStr = ""
        for i, Arg in ipairs(Args) do
            if i > 1 then ArgsStr ..= ", " end
            ArgsStr ..= self:SimpleFormat(Arg)
        end
        return `{RemoteVariable}:{Method}({ArgsStr})`
    end
    
    local Variables = Module.Variables
    local Parser = Module.Parser
    local NoVariables = Data.NoVariables
    
    local IndentString = self:MakeIndent(Indent)
    
    --// Parse arguments
    local ParsedArgs, ItemsCount, IsArray = Parser:ParseTableIntoString({
        NoBrackets = true,
        NoVariables = NoVariables,
        Table = Args,
        Indent = Indent
    })
    
    --// Create table variable if not array
    if not IsArray or NoVariables then
        ParsedArgs = Variables:MakeVariable({
            Value = (`{%s}`):format(ParsedArgs),
            Comment = not IsArray and "Arguments aren't ordered" or nil,
            Name = "RemoteArgs",
            Class = "Remote"
        })
    end
    
    --// Wrap in unpack if dict
    if ItemsCount > 0 and not IsArray then
        ParsedArgs = `unpack({ParsedArgs}, 1, table.maxn({ParsedArgs}))`
    end
    
    --// Firesignal for receives
    if IsReceive then
        local Second = ItemsCount <= 0 and "" or `, {ParsedArgs}`
        local Signal = `{RemoteVariable}.{Method}`
        local Code = `-- This data was received from the server\n`
        Code ..= `{IndentString}firesignal({Signal}{Second})`
        return Code
    end
    
    --// Remote invoke
    return `{RemoteVariable}:{Method}({ParsedArgs})`
end

function Generation:SimpleFormat(Value)
    local Type = typeof(Value)
    
    if Type == "string" then
        return `"{Value}"`
    elseif Type == "number" or Type == "boolean" then
        return tostring(Value)
    elseif Type == "Instance" then
        return Value:GetFullName()
    elseif Type == "table" then
        local Parts = {}
        for k, v in pairs(Value) do
            table.insert(Parts, `[{self:SimpleFormat(k)}] = {self:SimpleFormat(v)}`)
        end
        return `{${table.concat(Parts, ", ")}}`
    else
        return tostring(Value)
    end
end

function Generation:ApplyVariables(String: string, Variables: table, ...): string
    for Variable, Value in Variables do
        if typeof(Value) == "function" then
            Value = Value(...)
        end
        
        String = String:gsub(`%%{Variable}%%`, function()
            return Value
        end)
    end
    
    return String
end

function Generation:MakeIndent(Indent: number)
    return string.rep("    ", Indent)
end

type ScriptData = {
    Variables: table,
    MetaMethod: string
}

function Generation:MakeCallCode(ScriptType: string, Data: ScriptData): string
    local ScriptTemplates = self.ScriptTemplates
    local Template = ScriptTemplates[ScriptType]
    
    assert(Template, `{ScriptType} is not a valid script type!`)
    
    local Variables = Data.Variables
    local MetaMethod = Data.MetaMethod
    local MetaMethods = {"__index", "__namecall", "Connect"}
    
    local function Compile(Template: table): string
        local Out = ""
        
        for Key, Value in next, Template do
            --// MetaMethod check
            local IsMetaTypeOnly = table.find(MetaMethods, Key)
            
            if IsMetaTypeOnly then
                if Key == MetaMethod then
                    local Line = Compile(Value)
                    Out ..= Line
                end
                continue
            end
            
            --// Information
            local Content, Indent = Value[1], Value[2] or 0
            Indent = math.clamp(Indent - 1, 0, 9999)
            
            --// Make line
            local Line = self:ApplyVariables(Content, Variables, Indent)
            local IndentString = self:MakeIndent(Indent)
            
            --// Append
            Out ..= `{IndentString}{Line}\n`
        end
        
        return Out
    end
    
    return Compile(Template)
end

function Generation:RemoteScript(Module, Data: RemoteData, ScriptType: string): string
    --// Unpack data
    local Remote = Data.Remote
    local Args = Data.Args
    local Method = Data.Method
    local MetaMethod = Data.MetaMethod
    
    --// Remote info
    local ClassName = Hook:Index(Remote, "ClassName")
    local IsNilParent = Hook:Index(Remote, "Parent") == nil
    
    local Variables = Module.Variables
    local Formatter = Module.Formatter
    
    --// Create remote variable
    local RemoteVariable = Variables:MakeVariable({
        Value = Formatter:Format(Remote, {NoVariables = true}),
        Comment = `{ClassName} {IsNilParent and "| Remote parent is nil" or ""}`,
        Name = Remote.Name,
        Lookup = Remote,
        Class = "Remote"
    })
    
    --// Generate call script
    local CallCode = self:MakeCallCode(ScriptType, {
        Variables = {
            ["RemoteCall"] = function(Indent: number)
                return self:CallRemoteScript(Data, {
                    RemoteVariable = RemoteVariable,
                    Indent = Indent,
                    Module = Module
                })
            end,
            ["Remote"] = RemoteVariable,
            ["Method"] = Method,
            ["Signal"] = `{RemoteVariable}.{Method}`
        },
        MetaMethod = MetaMethod
    })
    
    --// Make code
    local Code = self:GetBase(Module)
    return `{Code}\n{CallCode}`
end

function Generation:TableScript(Module, Table: table): string
    if not Module then
        return self:SimpleTableScript(Table)
    end
    
    --// Pre-render variables
    Module.Variables:PrerenderVariables(Table, {"Instance"})
    
    --// Parse
    local ParsedTable = Module.Parser:ParseTableIntoString({
        Table = Table
    })
    
    --// Generate
    local Code, NoVariables = self:GetBase(Module)
    local Separator = NoVariables and "" or "\n"
    Code ..= `{Separator}return {ParsedTable}`
    
    return Code
end

function Generation:SimpleTableScript(Table: table): string
    local Code = self.Header
    Code ..= `return {self:SimpleFormat(Table)}`
    return Code
end

function Generation:DumpLogs(Logs: table): string
    local BaseData
    local Parsed = {
        Remote = nil,
        Calls = {}
    }
    
    --// Create parser
    local Module = self:NewParser()
    
    for _, Data in Logs do
        local Calls = Parsed.Calls
        local Table = {
            Args = Data.Args,
            Timestamp = Data.Timestamp,
            ReturnValues = Data.ReturnValues,
            Method = Data.Method,
            MetaMethod = Data.MetaMethod,
            CallingScript = Data.CallingScript
        }
        
        table.insert(Calls, Table)
        
        if not BaseData then
            BaseData = Data
        end
    end
    
    --// Merge
    Parsed.Remote = BaseData and BaseData.Remote
    
    --// Compile and save
    local Output = self:TableScript(Module, Parsed)
    local FilePath = self:WriteDump(Output)
    
    return FilePath
end

return Generation
