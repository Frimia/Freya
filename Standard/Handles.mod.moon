--//
--// * Handles for Freya
--// | Generic APIs providing implementations of the Inspect/Modify/Cancel
--// | patterns for Freya.
--//
--// * What's new?
--// | Freya Handles replace Arbiters by providing an object-level generic
--// | implementation of the standard Freya patterns
--//

Intents = _G.Freya\GetComponent "Intents"
Events = _G.Freya\GetComponent "Events"

HybridGenerator = (o) -> (f) -> (...) ->
  return f ... if ... ~= o else f select 2, ...

ni = newproxy true
Hybrid = HybridGenerator ni

Emitters = setmetatable {}, __mode: 'k'
Handlers = setmetatable {}, __mode: 'k'

fastpack = (...) -> {select('#', ...), ...}
local foldd
foldd = (t, i, c, ...) ->
  if i >= #t
    t[i] c, ...
  else
    foldd t, i+1, c, t[i] c, ...

-- APIs to provide: Inspect, Modify, Cancel
-- Object handle
ArbiterClass = {
  -- Variations of the inspect pattern for events and intents
  Emit: (e) =>
    Emitters[@]\Connect e\Fire
  Inform: (i) =>
    Emitters[@]\Connect (...) -> Intents.Broadcast i, ...
  -- Modify/cancel (simple)
  Handle: (f) =>
    t = Handlers[@]
    t[#t+1] = f
    Events.Connection ->
      del = false
      for i=1, #t do
        if t[i] == f then del = true
        if del
          t[i] = t[i+1]
}

CreateArbiter = Hybrid =>
  newArbiter = newproxy true
  newEmitter = Events.new!
  newHandlers = {}
  name = tostring @
  with getmetatable newArbiter
    reroute = (t, ...) ->
      if t.Cancel
        if t.PassThrough
          return ...
        return unpack t.EmulatedReturns -- No size preservation
      else
        return @ ...
    .__index = ArbiterClass
    .__call = (this, ...) ->
      t = {
        Cancel: false
        PassThrough: false
        EmulatedReturns: {}
        Arbiter: this
        RawFunction: @
      }
      return reroute t, foldd newHandlers, 1, t, ...
    .__tostring = -> "Freya Arbiter: [#{name}]"
    .__metatable = "Locked Metatable: Freya Core"
    .__len = @
  Emitters[newArbiter] = newEmitter
  Handlers[newArbiter] = newHandlers
  newArbiter

-- Object readonly
ObserverClass = {
  Emit: (e) =>
    Emitters[@]\Connect e\Fire
  Inform: (i) =>
    Emitters[@]\Connect (...) -> Intents.Broadcast i, ...
}

CreateObserver = Hybrid =>
  newObserver = newproxy true
  newEmitter = Events.new!
  name = tostring @
  with getmetatable newObserver
    .__index = ObserverClass
    .__call = (...) =>
      newEmitter\Fire ...
      @ ...
    .__tostring = -> "Freya Observer: [#{name}]"
    .__metatable = "Locked Metatable: Freya Core"
    .__len = @
  Emitters[newObserver] = newEmitter
  newObserver


cxitio = {
  :CreateObserver
  Observer: CreateObserver

  :CreateArbiter
  Arbiter: CreateArbiter
}

with getmetatable ni
  .__index = cxitio
  .__tostring = -> "Freya Core: Handles"
  .__metatable = "Locked Metatable: Freya Core"

ni
