--!strict
local Types = require(script.Parent.Parent.Types)

type Definition<T = {}> = Types.Definition<T> & {
    target: Instance,
    event: string,       
    arguments: {any}?        
}

type WatcherClass<T = {}> = Types.WatcherClass<T>

return function<T>(definition: Definition<T>): WatcherClass<T>
    local target = definition.target
    local eventName = definition.event
    local arguments = definition.arguments or {}

    local initialize = definition[1]
    local finalize = definition[2]
    local update = definition[3]

    local connections: {[number]: RBXScriptConnection?} = {}

    local function resolveSignal(instance: Instance, name: string, methodArgs: {any}): RBXScriptSignal?
        local member = (instance :: any)[name]
        if typeof(member) == 'RBXScriptSignal' then
            return member
        end

        if type(member) == 'function' then
            local success, result = pcall(function()
                local callback = member :: (...any) -> any
                return callback(instance, table.unpack(methodArgs))
            end)
            if success and typeof(result) == 'RBXScriptSignal' then
                return result
            end
        end

        warn(`'{script.Name}': '{name}' is not a valid event {instance:GetFullName()}`)

        return nil
    end

    local class: WatcherClass<T> = {
        ['initiate'] = function()
            local signal = resolveSignal(target, eventName, arguments)
            if not signal then return end

            connections[1] = signal:Connect(function(...)
                local eventArguments = {...}

                if initialize then
                    initialize(table.unpack(eventArguments))
                end

                if update then
                    task.spawn(update, table.unpack(eventArguments))
                end
            end)
        end,

        ['terminate'] = function()
            for _, connection in connections do
                if connection then
                    connection:Disconnect()
                end
            end
            table.clear(connections)
        end,
    }

    return class
end
