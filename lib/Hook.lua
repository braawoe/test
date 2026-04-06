local Hook = {
    OriginalNamecall = nil,
    OriginalIndex = nil,
    PreviousFunctions = {},
    DefaultConfig = {
        FunctionPatches = true
    }
}

type table = {
    [any]: any
}

type MetaFunc = (Instance, ...any) -> ...any
type UnkFunc = (...any) -> ...any

--// Modules
local Modules
local Process
local Configuration
local Config
local Communication

local ExeENV = getfenv(1)

function Hook:Init(Data)
    Modules = Data.Modules
    Process = Modules.Process
    Communication = Modules.Communication or Communication
    Config = Modules.Config or Config
    Configuration = Modules.Configuration or Configuration
end

--// Hook middleman function
local HookMiddle = newcclosure(function(OriginalFunc, Callback, AlwaysTable: boolean?, ...)
    --// Invoke callback
    local ReturnValues = Callback(...)
    
    if ReturnValues then
        --// Unpack
        if not AlwaysTable then
            return Process:Unpack(ReturnValues)
        end
        
        --// Return packed
        return ReturnValues
    end
    
    --// Return packed original
    if AlwaysTable then
        return {OriginalFunc(...)}
    end
    
    --// Unpacked
    return OriginalFunc(...)
end)

local function Merge(Base: table, New: table)
    for Key, Value in next, New do
        Base[Key] = Value
    end
end

function Hook:Index(Object: Instance, Key: string)
    local identity = getthreadidentity()
    setthreadidentity(8)
    local returned = Object[Key]
    setthreadidentity(identity)
    return returned
end

function Hook:PushConfig(Overwrites)
    Merge(self, Overwrites)
end

--// getrawmetatable replacement
function Hook:ReplaceMetaMethod(Object: Instance, Call: string, Callback: MetaFunc): MetaFunc
    local Metatable = getrawmetatable(Object)
    local OriginalFunc = clonefunction(Metatable[Call])
    
    --// Replace function
    setreadonly(Metatable, false)
    Metatable[Call] = newcclosure(function(...)
        return HookMiddle(OriginalFunc, Callback, false, ...)
    end)
    setreadonly(Metatable, true)
    
    return OriginalFunc
end

--// hookfunction
function Hook:HookFunction(Func: UnkFunc, Callback: UnkFunc)
    local OriginalFunc
    local WrappedCallback = newcclosure(Callback)
    
    OriginalFunc = clonefunction(hookfunction(Func, function(...)
        return HookMiddle(OriginalFunc, WrappedCallback, false, ...)
    end))
    
    return OriginalFunc
end

--// hookmetamethod
function Hook:HookMetaCall(Object: Instance, Call: string, Callback: MetaFunc): MetaFunc
    local Metatable = getrawmetatable(Object)
    local Unhooked
    
    Unhooked = self:HookFunction(Metatable[Call], function(...)
        return HookMiddle(Unhooked, Callback, true, ...)
    end)
    
    return Unhooked
end

function Hook:HookMetaMethod(Object: Instance, Call: string, Callback: MetaFunc): MetaFunc
    local Func = newcclosure(Callback)
    
    --// getrawmetatable
    if Config and Config.ReplaceMetaCallFunc then
        return self:ReplaceMetaMethod(Object, Call, Func)
    end
    
    --// hookmetamethod
    return self:HookMetaCall(Object, Call, Func)
end

--// Function patches for detection prevention
function Hook:PatchFunctions()
    --// Check if disabled
    if Config and Config.NoFunctionPatching then return end
    
    local Patches = {
        --// Error detection patch
        [pcall] = function(OldFunc, Func, ...)
            local Response = {OldFunc(Func, ...)}
            local Success, Error = Response[1], Response[2]
            local IsC = iscclosure(Func)
            
            --// Patch c-closure error detection
            if Success == false and IsC then
                local NewError = Process:CleanCError(Error)
                Response[2] = NewError
            end
            
            --// Stack overflow detection patch
            if Success == false and not IsC and Error:find("C stack overflow") then
                local TraceTable = Error:split(":")
                local Caller, Line = TraceTable[1], TraceTable[2]
                local Count = Process:CountMatches(Error, Caller)
                
                if Count == 196 then
                    Communication:ConsolePrint(`C stack overflow patched, count: {Count}`)
                    Response[2] = Error:gsub(`{Caller}:{Line}: `
