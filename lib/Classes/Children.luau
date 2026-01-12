--!strict
local Types = require(script.Parent.Parent.Types)

type Definition<T = {}> = Types.Definition<T> & {
    instance: Instance
}

type WatcherClass<T = {}> = Types.WatcherClass<T>

return function<T>(definition: Definition<T>): WatcherClass<T>
    local instance = definition.instance

    local initialize = definition[1] 
    local finalize = definition[2]  
    local update = definition[3]

    if typeof(instance) ~= 'Instance' then
        warn(`"{script.Name}": 'instance' must be a valid Instance`)
    end

    local childConnections: {RBXScriptConnection?} = {}

    local function registerChild(child: Instance)
        if initialize then
            initialize(child)
        end
        if update then
            task.spawn(update, child)
        end
    end

    local function unregisterChild(child: Instance)
        if finalize then
            finalize(child)
        end
        if update then
            task.spawn(update, child)
        end
    end

    local class: WatcherClass<T> = {
        ['initiate'] = function()
            task.defer(function()
                for _, child in instance:GetChildren() do
                    registerChild(child)
                end
            end)

            childConnections[1] = instance.ChildAdded:Connect(registerChild)
            childConnections[2] = instance.ChildRemoved:Connect(unregisterChild)
        end,

        ['terminate'] = function()
            for _, connection in childConnections do
                if connection then
                    connection:Disconnect()
                end
            end
            table.clear(childConnections)
        end,
    }

    return class
end
