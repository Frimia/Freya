--//
--// * Light intents for Studio
--// | No, really. They're super light.
--//

emitter = Instance.new "BindableEvent"
emitterE = emitter.Event

fastpack = (...) -> {select('#', ...), ...}
Hold = {}

Broadcast = (...) =>
  Hold[@] = fastpack ...
  emitter\Fire!

Listen = (f) =>
  emitterE\Connect ->
    t = Hold[@]
    f unpack t, 2, t[1]

Wait = (f) =>
  emitterE\Wait!
  t = Hold[@]
  f unpack t, 2, t[1]

ni = newproxy true
with getmetatable ni
  __index = {
    :Broadcast
    :Listen
    :Wait
  }
  __tostring = -> "Freya Studio IPC"
  __metatable = "Locked Metatable: Freya Studio"

ni
