--!strict
local Types = require(script.Parent.Parent.Types)

type Definition<T = {}> = Types.AttributeDefinition<T>
type WatcherClass<T = {}> = Types.WatcherClass<T>

return function<T>(definition: Definition<T>): WatcherClass<T>
    local identifier = definition.identifier
    
    local initialize = definition[1]  
    local finalize = definition[2]  
    local update = definition[3]

    local connections: {[number]: RBXScriptConnection?} = {}
    local previousValues: {[Instance]: any} = {}

    local function handleAttributeChanged(instance: Instance)
        local updatedValue = instance:GetAttribute(identifier)
        local originalValue = previousValues[instance]
        if updatedValue == originalValue then return end

        previousValues[instance] = updatedValue

        if update then
            task.spawn(function()
                update(instance, updatedValue, originalValue)
            end)
        end

        if updatedValue == nil and finalize then
            finalize(instance, updatedValue, originalValue)
        end
    end

    local class: WatcherClass<T> = {
        ['initiate'] = function()
            connections[1] = game.DescendantAdded:Connect(function(object)
                previousValues[object] = object:GetAttribute(identifier)
                object:GetAttributeChangedSignal(identifier):Connect(function()
                    handleAttributeChanged(object)
                end)
            end)

            if initialize then
                task.defer(function()
                    for _, object in game:GetDescendants() do
                        previousValues[object] = object:GetAttribute(identifier)
                        object:GetAttributeChangedSignal(identifier):Connect(function()
                            handleAttributeChanged(object)
                        end)
                        local initialValue = object:GetAttribute(identifier)
                        if initialValue ~= nil then
                            initialize(object, initialValue, nil)
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
            table.clear(previousValues)
        end,
    }

    return class
end
