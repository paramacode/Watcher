--!strict
export type WatcherCallback<T = Instance> = (...any) -> ()

export type Definition<T = Instance> = {
    identifier: string,
    instance: Instance?,
    property: string?,
    [number]: WatcherCallback<T>
}

export type WatcherClass<T = Instance> = {
    initiate: () -> (),
    terminate: () -> ()
}

export type WatcherConstructor<T = Instance> = (definition: Definition<T>) -> WatcherClass<T>

export type AttributeCallback<T = any> = (instance: Instance, updatedValue: T, originalValue: T?) -> ()

export type AttributeDefinition<T = any> = {
    identifier: string, 
    [number]: AttributeCallback<T>,
}

return {}
