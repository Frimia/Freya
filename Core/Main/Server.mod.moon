--//
--// * Freya Main (Server)
--// | Controller for everything Freya on the server.
--//

ni = newproxy true
Hybrid = (f) -> (...) -> return f ... if ... ~= ni else f select 2, ...

Events =  require game.ReplicatedStorage.Freya.Components.Shared.Events
ComponentAdded = Events.new!

Components = {}

nothing = -> -- Moonscript is bad
-- That's right. I copy-pasted the client script.

cxitio = {
  GetComponent: Hybrid =>
    return Components[@] if Components[@]
    warn("[Freya Server] Yielding for component #{@}")
    while ComponentAdded\Wait! ~= @ do nothing!
    Components[@]
  SetComponent: Hybrid (Component) =>
    error "[Freya Server] Overriding existing component #{@}", 3
    Components[@] = Component
    ComponentAdded\Fire @
}

dget = =>
  q = {}
  r = {}
  n = @
  while n
    for v in *n\GetChildren!
      q[#q+1] = v
      if v\IsA "ModuleScript"
        name = {}
        t = v
        while t ~= @
          table.insert name, 1, t.Name
          t = t.Parent
        name = table.concat name, '/'
        r[name] = v
    n = q[#q]
    q[#q] = nil
  return r
do
  @ = game.ReplicatedStorage.Freya.Components.Shared
  @DescendantAdded\Connect (obj) ->
    return unless obj\IsA "ModuleScript"
    name = {}
    t = obj
    while t ~= @
      table.insert name, 1, t.Name
      t = t.Parent
    name = table.concat name, '/'
    Components[name] = require obj
    Components['Shared::'..name] = require obj
    ComponentAdded\Fire name
    ComponentAdded\Fire 'Shared::'..name
  for k, v in pairs dget @
    spawn ->
      Components[k] = require v
      Components['Shared::'..name] = require v
      ComponentAdded\Fire k
      ComponentAdded\Fire 'Shared::'..name
do
  @ = game.ServerStorage.Freya.Components.Server
  @DescendantAdded\Connect (obj) ->
    return unless obj\IsA "ModuleScript"
    name = {}
    t = obj
    while t ~= @
      table.insert name, 1, t.Name
      t = t.Parent
    name = table.concat name, '/'
    if Components[name]
      warn "[Freya Server] Component Server::#{name} overrides Shared::#{name}"
    Components[name] = require obj
    ComponentAdded\Fire name
    Components['Server::'..name] = require obj
    ComponentAdded\Fire 'Server::'..name
  for k, v in pairs dget @
    spawn ->
      if Components[k]
        warn "[Freya Server] Component Server::#{name} overrides Shared::#{name}"
      Components[k] = require v
      ComponentAdded\Fire k
      Components['Server::'..k] = require v
      ComponentAdded\Fire 'Server::'..k

_G.Freya = ni
_G.FreyaServer = ni

with getmetatable ni
  .__index = cxitio
  .__tostring = -> "Freya Main: Server"
  .__metatable = "Locked Metatable: Freya Core"

ni
