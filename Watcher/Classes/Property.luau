--!strict
local Types = require(script.Parent.Parent.Types)

type Definition<T = {}> = Types.Definition<T> & {
    instance: Instance,
    property: string,
}

type WatcherClass<T = {}> = Types.WatcherClass<T>

return function<T>(definition: Definition<T>): WatcherClass<T>
    local instance = definition.instance
    local property = definition.property

    local initialize = definition[1]
    local finalize = definition[2]
    local update = definition[3]

    if typeof(instance) ~= 'Instance' then
        warn(`"{script.Name}": 'instance' must be a valid Instance`)
    end

    if type(property) ~= 'string' then
        warn(`"{script.Name}": 'property' must be a string`)
    end

    local success = pcall(function()
        local _ = (instance :: any)[property]
    end)
    if not success then
        warn(`"{script.Name}": property '{property}' does not exist in {instance.ClassName}`)
    end

    local propertyConnection: RBXScriptConnection?
    
    local class: WatcherClass<T> = {
        ['initiate'] = function()
            if initialize then
                initialize(instance)
            end
            
            propertyConnection = instance:GetPropertyChangedSignal(property):Connect(function()
                if update then
                    task.spawn(update, instance, (instance :: any)[property])
                end
            end)
        end,

        ['terminate'] = function()
            if propertyConnection then
                propertyConnection:Disconnect()
                propertyConnection = nil
            end
            
            if finalize then
                finalize(instance)
            end
        end,
    }

    return class
end