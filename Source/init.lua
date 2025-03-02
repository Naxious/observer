local Observer = require(script.Observer)

local Events = {}

Events.client = {
	example = Observer.Create("ClientExample") :: Observer.Event<string>,
}

Events.server = {
	example = Observer.Create("ServerExample") :: Observer.Event<number>,
}

return Events
