--//
--// * Events for Freya
--// | Extended events system which supports the standard Roblox API, without
--// | all the gotchas of the BindableEvent implementation
--//

local ^

ExtractionWrapper = (o) -> (f) -> (...) ->
  return f ... if o ~= ... else f select 2, ...

fastpack = (...) -> {select('#', ...), ...}

EventHandles = setmetatable {}, __mode: 'k'
Events = setmetatable {}, __mode: 'k'
Hold = setmetatable {}, __mode: 'k'

local foldd
foldd = (t, i, c, ...) ->
  if i >= #t
    t[i] c, ...
  else
    foldd t, i+1, c, t[i] c, ...

EventClass = {
  Connect: =>
    Events[@].Event\Connect ->
      ar = Hold[@]
      f unpack ar, 2, ar[1]
  Fire: (...) =>
    local ar
    ht = EventHandles[@]
    if ht
      udata = {
        Cancel: false
        Event: @
      }
      ar = fastpack foldd ht, 1, udata, ...
      return if udata.Cancel
    else
      ar = fastpack(...)
    Hold[@] = ar
    Events[@]\Fire!
  Wait: =>
    Events[@].Event\Wait!
    ar = Hold[@]
    unpack ar, 2, ar[1]
  -- Inspect is provided by Connect/Wait
  Handle: (f) =>
    -- Handle provides Modify/Cancel
    t = EventHandles[@]
    unless t
      t = {}
      EventHandles[@] = t
    t[#t+1] = f
    CreateConnection ->
      del = false
      for i=1, #t do
        if t[i] == f then del = true
        if del
          t[i] = t[i+1]
}

CreateConnection = (disconnectFunction) ->
  o = newproxy true
  connected = true
  dc = ExtractionWrapper(o) ->
    return error "Attempt to disconnect dead connection", 2 unless connected
    connected = false
    disconnectFunction!
  with getmetatable o
    .__index = (k) =>
      switch k
        when "Connected"
          connected
        when "Disconnect"
          dc
    .__tostring = -> "Freya event connection: #{connected and "Alive" or "Dead"}"
    .__metatable = "Locked Metatable: Freya Core"
    .__len = -> connected
  o

CreateEvent = ->
  ne = newproxy true
  with getmetatable ne
    .__index = EventClass
    .__metatable = "Locked Metatable: Freya Core"
    .__tostring = -> "Freya Event"
    .__call = EventClass.Fire
  Events[ne] = Instance.new "BindableEvent"
  ne

this = {
  Connection: CreateConnection
  Event: CreateEvent
  new: CreateEvent
}

np = newproxy true
with getmetatable np
  .__index = this
  .__tostring = -> "Freya Events"
  .__metatable = "Locked Metatable: Freya Core"

return np
