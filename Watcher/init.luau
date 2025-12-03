--!strict
local Types = require(script.Types)

local Classes = script.Classes

type Definition<T = {}> = Types.Definition<T>
type WatcherClass<T = {}> = Types.WatcherClass<T>
type WatcherConstructor<T = {}> = Types.WatcherConstructor<T>

local classes: {[string]: WatcherConstructor<any>} = {}
local cache: {[string]: WatcherClass<any>} = {}

local function fetchClass(identifier: string): (boolean, WatcherConstructor<any> | string)
    local existing = classes[identifier]
    if existing then return true, existing end

    local classRoute = Classes:FindFirstChild(identifier)
    if not classRoute then
        return false, `"{script.Name}": Class "{identifier}" not found"`
    end

    local success: boolean, imported: WatcherConstructor<any> = pcall(require, classRoute)
    if not success then
        return false, `"{script.Name}": Error loading class "{identifier}": {imported}"`
    end

    if type(imported) ~= 'function' then
        return false, `"{script.Name}": Import "{identifier}" must return a function"`
    end 

    local constructor = imported :: WatcherConstructor<any>
    classes[identifier] = constructor

    return true, constructor
end

return function<T>(identifier: string, definition: Definition<T>): (boolean, string?)
    local success: boolean, imported: any = fetchClass(identifier)
    if not success then return false, imported end

    local constructor = imported :: WatcherConstructor<T>

    if type(definition) ~= 'table' then
        return false, `"{script.Name}": definition must be a table`
    end
    
    if not definition.identifier then
        return false, `"{script.Name}": definition missing 'identifier'`
    end

    local watcher: WatcherClass<T> = constructor(definition)
    cache[definition.identifier] = watcher

    if watcher.initiate then
        task.defer(watcher.initiate)
    end

    return true, 'Watcher initialized'
end
