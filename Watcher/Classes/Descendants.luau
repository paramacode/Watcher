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

    local connections: {[Instance]: RBXScriptConnection} = {}

    local function registerDescendant(descendant: Instance)
        if initialize then
            initialize(descendant)
        end
        if update then
            task.spawn(update, descendant)
        end

        connections[descendant] = descendant.DescendantAdded:Connect(function(child)
            registerDescendant(child)
        end)
    end

    local function unregisterDescendant(descendant: Instance)
        if connections[descendant] then
            connections[descendant]:Disconnect()
            connections[descendant] = nil
        end

        if finalize then
            finalize(descendant)
        end
        if update then
            task.spawn(update, descendant)
        end
    end

    local class: WatcherClass<T> = {
        ['initiate'] = function()
            task.defer(function()
                for _, descendant in ipairs(instance:GetDescendants()) do
                    registerDescendant(descendant)
                end
            end)

            connections[instance] = instance.DescendantAdded:Connect(function(descendant)
                registerDescendant(descendant)
            end)
        end,

        ['terminate'] = function()
            for _, connection in connections do
                connection:Disconnect()
            end
            table.clear(connections)
        end,
    }

    return class
end
