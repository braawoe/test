 --[[
    Alpha Spy
    Author: trident
--]]

local Configuration = {
    UseWorkspace = false,
    NoActors = false,
    FolderName = "Alpha Spy",
    RepoUrl = "https://raw.githubusercontent.com/trident-bit/test/main",
    ParserUrl = "",
    Directory = "Alpha Spy",
    DebugMode = false,
}

-- SECURITY: Validate configuration keys
local ALLOWED_CONFIG_KEYS = {
    "UseWorkspace", "NoActors", "FolderName", "RepoUrl", "ParserUrl",
    "Directory", "DebugMode", "LogLimit", "Theme"
}

local function ValidateConfig(Key, Value)
    for _, AllowedKey in ipairs(ALLOWED_CONFIG_KEYS) do
        if Key == AllowedKey then
            return true
        end
    end
    return false
end

local Parameters = {...}
local Overwrites = Parameters[1]
if typeof(Overwrites) == "table" then
    for Key, Value in Overwrites do
        if ValidateConfig(Key, Value) then
            Configuration[Key] = Value
        else
            warn(`[Security] Blocked unauthorized config key: {Key}`)
        end
    end
end

local Services = setmetatable({}, {
    __index = function(self, Name: string): Instance
        local Service = game:GetService(Name)
        return cloneref(Service)
    end,
})

local Files = loadstring(game:HttpGet(`{Configuration.RepoUrl}/lib/Files.lua`))()
Files:PushConfig(Configuration)
Files:Init({
    Services = Services
})

local Folder = Files.FolderName
local Scripts = {
    Config = Files:GetModule(`{Folder}/Config`, "Config"),
    ReturnSpoofs = Files:GetModule(`{Folder}/Return spoofs`, "Return Spoofs"),
    Configuration = Configuration,
    Files = Files,
    
    Process = game:HttpGet(`{Configuration.RepoUrl}/lib/Process.lua`),
    Hook = game:HttpGet(`{Configuration.RepoUrl}/lib/Hook.lua`),
    Flags = game:HttpGet(`{Configuration.RepoUrl}/lib/Flags.lua`),
    Ui = game:HttpGet(`{Configuration.RepoUrl}/lib/Ui.lua`),
    Generation = game:HttpGet(`{Configuration.RepoUrl}/lib/Generation.lua`),
    Communication = game:HttpGet(`{Configuration.RepoUrl}/lib/Communication.lua`),
    Debug = game:HttpGet(`{Configuration.RepoUrl}/lib/Debug.lua`),
}

local Players: Players = Services.Players
local Modules = Files:LoadLibraries(Scripts)
if typeof(Modules.Config) == "string" then
    Modules.Config = loadstring(Modules.Config)()
end

if typeof(Modules.ReturnSpoofs) == "string" then
    Modules.ReturnSpoofs = loadstring(Modules.ReturnSpoofs)()
end

local Process = Modules.Process
local Hook = Modules.Hook
local Ui = Modules.Ui
local Debug = Modules.Debug

if Configuration.DebugMode and Debug then
    Debug:Init({
        Modules = Modules,
        Services = Services,
        Configuration = Configuration
    })
    print("[Alpha Spy] Debug mode enabled - Bypass tools loaded")
end

if not Process:CheckIsSupported() then
    return
end

Ui:Init({
    Modules = Modules,
    Services = Services,
    Configuration = Configuration
})

Ui:CreateMainWindow()
Ui:CreateWindowContent()

local Communication = Modules.Communication

Communication:Init({
    Modules = Modules,
    Services = Services
})

local ChannelId, Channel = Communication:CreateChannel()

Process:Init({
    Modules = Modules,
    Services = Services
})

Hook:Init({
    Modules = Modules,
    Services = Services
})

Communication:AddTypeCallbacks({
    ["QueueLog"] = function(Data)
        Ui:QueueLog(Data)
    end,
    ["Print"] = function(...)
        Ui:ConsoleLog(...)
    end,
    ["RemoteData"] = function(Id, RemoteData)
        Process:SetRemoteData(Id, RemoteData)
    end,
    ["AllRemoteData"] = function(Key, Value)
        Process:SetAllRemoteData(Key, Value)
    end,
    ["UpdateSpoofs"] = function(Content)
        local Spoofs = loadstring(Content)()
        Process:SetNewReturnSpoofs(Spoofs)
    end,
})

Modules.Generation:Init({
    Modules = Modules,
    Configuration = Configuration
})

Ui:BeginLogService()

local ActorCode = Files:MakeActorScript(Scripts, ChannelId)
Hook:LoadHooks(ActorCode, ChannelId)

Ui:SetCommChannel(Channel)

if Configuration.DebugMode then
    Ui:ShowModal({
        "[DEBUG MODE ENABLED]",
        "",
        "Debug features active:",
        "- Hook inspection",
        "- Call interception",
        "- Argument modification",
        "- Return value spoofing",
        "- Stack trace analysis",
        "",
        "Use the Debug tab in the UI for bypass tools."
    })
end

print("Alpha Spy Loaded Successfully!")

return Modules
