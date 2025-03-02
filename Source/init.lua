--!strict
export type Event<T> = {
	Subscribe: (self: Event<T>, callback: (T) -> ()) -> T,
	Unsubscribe: (self: Event<T>, id: number) -> (),
	Set: (self: Event<T>, value: T) -> (),
	Get: (self: Event<T>) -> T?,
	Clear: (self: Event<T>) -> (),
	Destroy: (self: Event<T>) -> (),
}

-- Internal storage for observers
local _observers: { [string]: {
	value: any?,
	callbacks: { [number]: (any) -> () },
} } = {}

local function createEvent<T>(name: string): Event<T>
	local event = {} :: any

	function event:Subscribe(callback: (T) -> ())
		local id = #_observers[name].callbacks + 1
		_observers[name].callbacks[id] = callback

		if _observers[name].value ~= nil then
			callback(_observers[name].value :: T)
		end

		return id
	end

	function event:Unsubscribe(id: number)
		_observers[name].callbacks[id] = nil
	end

	function event:Set(value: T)
		_observers[name].value = value
		for _, callback in _observers[name].callbacks do
			callback(value)
		end
	end

	function event:Get(): T?
		return _observers[name].value :: T?
	end

	function event:Clear()
		_observers[name].value = nil
	end

	function event:Destroy()
		_observers[name] = nil
	end

	return event :: Event<T>
end

--[=[
	@class Observer

	- Wally Package: [Syscore](https://wally.run/package/naxious/syscore)

	A typed observer that notifies subscribers when its value changes.

	Here's an example of how to use the Observer class:
	```lua
	local Observer = require(path.to.Observer)

	local observerEvent = Observer.client.example

	local id = observerEvent:Subscribe(function(value: string)
		print("Value changed to", value)
	end)

	observerEvent:Set("Hello, world!") -- Value changed to Hello, world!

	observerEvent:Unsubscribe(id)
	```
]=]

local Observer = {}

--[=[
    Creates a new typed observer with the specified name.
]=]
function Observer.Create<T>(name: string): Event<T>
	assert(not _observers[name], `Observer '${name}' already exists`)

	_observers[name] = {
		value = nil,
		callbacks = {},
	}

	local event = createEvent(name)

	return event :: Event<T>
end

--[=[
    Gets an existing observer or creates a new one if it doesn't exist.
]=]
function Observer.Get<T>(name: string): Event<T>
	if not _observers[name] then
		return Observer.Create(name) :: Event<T>
	end

	local event = createEvent(name)

	return event :: Event<T>
end

return Observer
