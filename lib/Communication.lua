local Module = {
    CommCallbacks = {},
    Modules = nil,
    Services = nil
}

-- Create channel if not using custom channel
local function create_comm_channel()
    -- Placeholder implementation; replace with actual channel creation logic if available
    return 12345678, Instance.new("BindableEvent")
end

function Module:CreateChannel()
    local Force = Config.ForceUseCustomComm
    local Parent = self:GetHiddenParent()

    if not Parent then
        warn("Parent object not available for channel creation")
        return nil, nil
    end

    -- Try to use custom channel creation if it exists
    if type(create_comm_channel) == "function" and not Force then
        local success, id, event = pcall(create_comm_channel)
        if success then
            return id, event
        end
    end

    -- Fallback channel creation
    local ChannelId = math.random(1, 10000000)
    local Channel = Instance.new("BindableEvent", Parent)
    Channel.Name = tostring(ChannelId)

    -- Initialize debug handlers
    self:MakeDebugIdHandler()
    self.DebugIdRemote = DebugIdRemote
    self.DebugIdInvoke = DebugIdInvoke

    return ChannelId, Channel
end

function Module:GetHiddenParent()
    if not gethui then
        return CoreGui
    end
    return gethui()
end

function Module:Setup(Ui)
    self:Init({ Modules = self.Modules, Services = self.Services })
    
    local ChannelId, Channel = self:CreateChannel()
    if not Channel then
        warn("Failed to create communication channel")
        return
    end

    self:AddTypeCallbacks({
        ["QueueLog"] = function(Data)
            Ui:QueueLog(Data)
        end,
    })
end

return Module