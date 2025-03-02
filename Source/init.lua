--!strict
--[=[
	@within Observer
	@interface Event<T>
	.Subscribe (callback: (T) -> ()) -> T -- Returns the subscription id
	.Unsubscribe (id: number) -> () -- Unsubscribes the callback
	.Set (value: T) -> () -- Sets the value of the event
	.Get () -> T? -- Gets the value of the event
	.Clear () -> () -- Clears the value of the event
	.Destroy () -> () -- Destroys the event

	Represents an event that can be subscribed to and triggered.
]=]
export type Event<T> = {
	Subscribe: (self: Event<T>, callback: (T) -> ()) -> T,
	Unsubscribe: (self: Event<T>, id: number) -> (),
	Set: (self: Event<T>, value: T) -> (),
	Get: (self: Event<T>) -> T?,
	Clear: (self: Event<T>) -> (),
	Destroy: (self: Event<T>) -> (),
}

local observers: { [string]: {
	value: any?,
	callbacks: { [number]: (any) -> () },
} } = {}

local function createEvent<T>(name: string): Event<T>
	local event = {} :: any

	function event:Subscribe(callback: (T) -> ())
		local id = #observers[name].callbacks + 1
		observers[name].callbacks[id] = callback

		if observers[name].value ~= nil then
			callback(observers[name].value :: T)
		end

		return id
	end

	function event:Unsubscribe(id: number)
		observers[name].callbacks[id] = nil
	end

	function event:Set(value: T)
		observers[name].value = value
		for _, callback in observers[name].callbacks do
			callback(value)
		end
	end

	function event:Get(): T?
		return observers[name].value :: T?
	end

	function event:Clear()
		observers[name].value = nil
	end

	function event:Destroy()
		observers[name] = nil
	end

	return event :: Event<T>
end

--[=[
	@class Observer

	- Wally Package: [Observer](https://wally.run/package/naxious/observer)

	A typed observer that notifies subscribers when its value changes.
	Observers can be created and subscribed to from any module.
	They are useful for decoupling modules and creating a more modular codebase.
	The Observer class is a singleton and should not be instantiated.
	The Observer class provides two methods for creating and getting observers.
	You can create an observer with a specific type and subscribe to it with a callback.
	When the observer's value changes, all subscribed callbacks are called with the new value.
	

	Here's an example of how to use the Observer class:
	`Firstly, Setup Event Module`
	```lua
	local Observer = require(path.to.Observer)

	local events = {
		["PlayerDamaged"] = Observer.Create("PlayerDamaged") :: Observer.Event<number>,
		["MorningTime"] = Observer.Create("PlayerJoined") :: Observer.Event<string>,
	}

	return events
	```
	`Secondly, Subscribe to an Event in any Module`
	```lua
	local events = require(path.to.Events)

	events.MorningTime:Subscribe(function(morningString: string)
		if morningString == "Good Morning" then
			print(`{morningString}! It's a awesome day!`)
		elseif morningString == "Bad Morning" then
			print(`{morningString}! It's what we get when it rains!`)
		end
	end)

	events.PlayerDamaged:Subscribe(function(damage: number)
		print(`Player took {damage} damage!`)
		player:ShakeScreen() -- example function
		particles:SpawnBlood(player.Position) -- example function
	end)
	```
	`Lastly, Set the Event Value in any Module`
	```lua
	local events = require(path.to.Events)

	events.MorningTime:Set("Good Morning")

	while player:IsStandingInFire() do
		events.PlayerDamaged:Set(10)
	end
	```

	:::note
		Observers are client/server specific and cannot be shared between them.
		You would need to create a separate observer for each side.
		OR create some sort of networked event system to communicate between them.
	:::
]=]

local Observer = {}

--[=[
	Creates a new typed observer with the specified name.

	```lua
	local Observer = require(path.to.Observer)

	local events = {
		["PlayerDamaged"] = Observer.Create("PlayerDamaged") :: Observer.Event<number>,
		["MorningTime"] = Observer.Create("PlayerJoined") :: Observer.Event<string>,
	}

	return events
	```
]=]
function Observer.Create<T>(name: string): Event<T>
	assert(not observers[name], `Observer '${name}' already exists`)

	observers[name] = {
		value = nil,
		callbacks = {},
	}

	local event = createEvent(name)

	return event :: Event<T>
end

--[=[
	Gets an existing observer or creates a new one if it doesn't exist.

	```lua
	local Observer = require(path.to.Observer)

	local events = {
		["PlayerDamaged"] = Observer.Get("PlayerDamaged") :: Observer.Event<number>,
		["MorningTime"] = Observer.Get("PlayerJoined") :: Observer.Event<string>,
	}

	return events
	```
]=]
function Observer.Get<T>(name: string): Event<T>
	if not observers[name] then
		return Observer.Create(name) :: Event<T>
	end

	local event = createEvent(name)

	return event :: Event<T>
end

return Observer
