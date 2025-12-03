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

    local ancestryConnection: RBXScriptConnection?

    local function handleAncestryChange(child: Instance, parent: Instance?)
        if parent then
            if initialize then
                initialize(child)
            end
            if update then
                task.spawn(update, child)
            end
        else
            if finalize then
                finalize(child)
            end
            if update then
                task.spawn(update, child)
            end
        end
    end

    local class: WatcherClass<T> = {
        ['initiate'] = function()
            task.defer(function()
                handleAncestryChange(instance, instance.Parent)
            end)

            ancestryConnection = instance.AncestryChanged:Connect(function(_, parent)
                handleAncestryChange(instance, parent)
            end)
        end,

        ['terminate'] = function()
            if ancestryConnection then
                ancestryConnection:Disconnect()
                ancestryConnection = nil
            end
        end,
    }

    return class
end
