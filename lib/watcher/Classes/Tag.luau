--!strict
local CollectionService = game:GetService('CollectionService')

local Types = require(script.Parent.Parent.Types)

type Definition<T = {}> = Types.Definition<T>
type WatcherClass<T = {}> = Types.WatcherClass<T>

return function<T>(definition: Definition<T>): WatcherClass<T>
    local identifier = definition.identifier
    
    local initialize = definition[1]  
    local finalize = definition[2]  
    local update = definition[3] 

    local connections: {[number]: RBXScriptConnection?} = {}

    local class: WatcherClass<T> = {
        ['initiate'] = function()
            connections[1] = CollectionService:GetInstanceAddedSignal(identifier):Connect(function(object)
                if initialize then
                    initialize(object)
                end
                if update then
                    task.spawn(update, object)
                end
            end)

            connections[2] = CollectionService:GetInstanceRemovedSignal(identifier):Connect(function(object)
                if finalize then
                    finalize(object)
                end
                if update then
                    task.spawn(update, object)
                end
            end)

            if initialize then
                task.defer(function()
                    for _, object in CollectionService:GetTagged(identifier) do
                        initialize(object)
                        if update then
                            task.spawn(update, object)
                        end
                    end
                end)
            end
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
