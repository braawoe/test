# Alpha Spy - Folder Structure

Complete folder structure and setup guide for the multi-module Alpha Spy.

## ðŸ“ Directory Structure

```
AlphaSpy/
â”œâ”€â”€ Main.lua                 # Entry point - load this file
â”œâ”€â”€ FOLDER_STRUCTURE.md      # This documentation
â”‚
â”œâ”€â”€ lib/                     # Core modules
â”‚   â”œâ”€â”€ Files.lua           # File management & module loading
â”‚   â”œâ”€â”€ Flags.lua           # Feature flags & settings
â”‚   â”œâ”€â”€ Communication.lua   # Inter-module communication
â”‚   â”œâ”€â”€ Process.lua         # Remote processing & detection
â”‚   â”œâ”€â”€ Hook.lua            # Hooking system (__namecall, __index)
â”‚   â”œâ”€â”€ Generation.lua      # Code generation
â”‚   â”œâ”€â”€ Ui.lua              # User interface
â”‚   â””â”€â”€ Debug.lua           # Debug tools for bypass development
â”‚
â”œâ”€â”€ templates/               # User configuration templates
â”‚   â”œâ”€â”€ Config.lua          # Main configuration
â”‚   â””â”€â”€ Return Spoofs.lua   # Return value spoofing
â”‚
â””â”€â”€ assets/                  # Assets (fonts, images)
    â””â”€â”€ (empty - for custom fonts)
```

## ðŸš€ Installation

### Method 1: Direct Load (GitHub Raw)

1. Upload all files to your GitHub repository
2. Get the raw URL for `Main.lua`
3. Update the `RepoUrl` in Main.lua:

```lua
local Configuration = {
    RepoUrl = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/AlphaSpy",
    ParserUrl = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/Roblox-parser/dist/Main.luau",
    DebugMode = false, -- Set to true for bypass tools
}
```

4. Load in Roblox:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/AlphaSpy/Main.lua"))()
```

### Method 2: With Debug Mode

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/AlphaSpy/Main.lua"))({
    DebugMode = true,  -- Enable debug/bypass tools
    NoActors = false,  -- Use actor hooks (if supported)
})
```

### Method 3: Workspace Mode (Offline)

1. Download all files to your executor's workspace
2. Set `UseWorkspace = true` in Config.lua
3. Update folder path in Main.lua

## ðŸ“‹ Module Descriptions

### Core Modules

| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **Files.lua** | Module loading, HTTP requests, folder management | `LoadLibraries()`, `GetFile()`, `UrlFetch()` |
| **Flags.lua** | Feature toggles and settings | `GetFlagValue()`, `SetFlagValue()` |
| **Communication.lua** | Module communication via BindableEvents | `QueueLog()`, `SerializeTable()` |
| **Process.lua** | Remote detection, filtering, decompilation | `ProcessRemote()`, `Decompile()`, `CheckIsSupported()` |
| **Hook.lua** | __namecall and __index hooking | `HookMetaMethod()`, `BeginHooks()`, `PatchFunctions()` |
| **Generation.lua** | Code generation from remote calls | `RemoteScript()`, `TableScript()`, `DumpLogs()` |
| **Ui.lua** | User interface with ReGui | `CreateMainWindow()`, `CreateLog()`, `ConsoleLog()` |
| **Debug.lua** | **Bypass development tools** | `InterceptCall()`, `RegisterModifier()`, `GetStats()` |

## ðŸ› ï¸ Debug Features (Debug Mode)

When `DebugMode = true`, you get access to:

### 1. **Call Interception**
```lua
-- In Debug Tab: Enable "Intercept all calls"
-- All remote calls will be intercepted
```

### 2. **Argument Modification**
```lua
-- Register a modifier for a specific remote
Debug:RegisterModifier(Remote, "FireServer", function(Args)
    -- Modify arguments before sending
    Args[1] = "Modified!"
    return Args
end)
```

### 3. **Call History**
- View all intercepted calls
- Export to JSON
- Stack trace logging

### 4. **Breakpoints**
```lua
-- Set conditional breakpoints
Debug:SetBreakpoint(Remote, "FireServer", function(Args)
    return Args[1] == "Trigger" -- Break when condition met
end)
```

### 5. **Statistics**
- Total calls intercepted
- Modified calls count
- Calls per remote

### 6. **Bypass Script Generation**
```lua
-- Generate bypass scripts
local Script = Debug:GenerateBypassScript(Remote, "FireServer", "block")
```

## âš™ï¸ Configuration Options

### Main Config (templates/Config.lua)

```lua
return {
    -- Hooking
    ForceUseCustomComm = false,    -- Force custom communication
    ReplaceMetaCallFunc = false,   -- Use getrawmetatable instead of hookmetamethod
    NoReceiveHooking = false,      -- Disable OnClientEvent hooks
    NoFunctionPatching = false,    -- Disable detection patches
    
    -- Processing
    ForceKonstantDecompiler = false, -- Use Konstant API for decompilation
    
    -- Editor
    VariableNames = {...},         -- Variable naming patterns
    SyntaxColors = {...},          -- Code editor colors
    
    -- UI
    MethodColors = {...},          -- Remote method colors
    ThemeConfig = {...}            -- UI theme settings
}
```

### Return Spoofs (templates/Return Spoofs.lua)

```lua
return {
    [game.ReplicatedStorage.Remotes.Example] = {
        Method = "InvokeServer",
        Return = {"Spoofed!"}
    }
}
```

## ðŸŽ® Usage Guide

### Basic Usage
1. Load the script
2. UI appears with 4 tabs: Editor, Options, Debug, Console
3. Click on remote logs in the left panel
4. Generated code appears in the Editor tab

### Using Debug Tools
1. Enable "Debug Mode" when loading
2. Go to Debug tab
3. Enable desired options:
   - **Intercept all calls** - Catch every remote call
   - **Enable arg modification** - Modify arguments
   - **Log stack traces** - See call origins
4. Use action buttons to export data

### Creating Bypasses
1. Find the remote you want to bypass
2. Click "Generate Bypass Script" in Debug tab
3. Choose pattern: block, spoof, or log
4. Copy the generated script
5. Modify as needed

## ðŸ”§ Troubleshooting

### "Module not found" errors
- Check that `RepoUrl` is correct
- Ensure all files are uploaded
- Verify raw GitHub URLs work

### UI not appearing
- Check executor supports `gethui()` or `CoreGui`
- Try setting `NoActors = true`
- Check console for errors

### Hooks not working
- Verify executor supports `hookmetamethod`
- Try `ReplaceMetaCallFunc = true`
- Check `CheckIsSupported()` output

### Debug mode not working
- Ensure `DebugMode = true` in load parameters
- Check Debug module loaded successfully
- Verify `Flags.lua` has debug flags

## ðŸ“¦ Dependencies

### Required (Executor Functions)
- `hookmetamethod` or `getrawmetatable` + `setreadonly`
- `hookfunction`
- `newcclosure`
- `cloneref`
- `gethui()` or `CoreGui` access
- `identifyexecutor()`
- `checkcaller()`
- `getcallingscript()`

### Optional (Enhanced Features)
- `decompile` - Built-in decompiler
- `getscriptbytecode` - For Konstant API
- `getactors` + `run_on_actor` - Actor hooks
- `getcustomasset` - Custom fonts
- `getconnections` - Connection inspection
- `firesignal` - Fire client events

## ðŸ“ Notes

- The Debug module is **only loaded when DebugMode = true**
- All modules are loaded dynamically via HTTP
- Templates are auto-created if missing
- Call history is limited to 1000 entries
- Log queue processes every frame

## ðŸ”— Related Files

- **Roblox-parser**: For advanced code generation (optional)
- **ReGui**: UI framework (included in lib/)

---

**Need help?** Check the Debug tab's statistics panel for real-time monitoring!
