--//
--// * Freya Main (Client)
--// | Controller for everything Freya on the client.
--//

ni = newproxy true
Hybrid = (f) -> (...) -> return f ... if ... ~= ni else f select 2, ...

Events =  require game.ReplicatedStorage.Freya\WaitForChild("Components")\WaitForChild("Shared")\WaitForChild("Events")
ComponentAdded = Events.new!

Components = {}

nothing = -> -- Moonscript is bad

cxitio = {
  GetComponent: Hybrid =>
    return Components[@] if Components[@]
    warn("[Freya Client] Yielding for component #{@}")
    while ComponentAdded\Wait! ~= @ do nothing!
    Components[@]
  SetComponent: Hybrid (Component) =>
    error "[Freya Client] Overriding existing component #{@}", 3
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
with game.ReplicatedStorage.Freya.Components
  .Shared.DescendantAdded\Connect (obj) ->
    return unless obj\IsA "ModuleScript"
    name = {}
    t = obj
    while t ~= .Shared
      table.insert name, 1, t.Name
      t = t.Parent
    name = table.concat name, '/'
    Components[name] = require obj
    ComponentAdded\Fire name
    Components['Shared::'..name] = require obj
    ComponentAdded\Fire 'Shared::'..name
  .Client.DescendantAdded\Connect (obj) ->
    return unless obj\IsA "ModuleScript"
    name = {}
    t = obj
    while t ~= .Client
      table.insert name, 1, t.Name
      t = t.Parent
    name = table.concat name, '/'
    if Components[name]
      warn "[Freya Client] Component Client::#{name} overrides Shared::#{name}"
    Components[name] = require obj
    ComponentAdded\Fire name
    Components['Client::'..name] = require obj
    ComponentAdded\Fire 'Client::'..name
  for k, v in pairs dget .Shared
    spawn ->
      Components[k] = require v
      ComponentAdded\Fire k
      Components['Shared::'..k] = require v
      ComponentAdded\Fire 'Shared::'..k
  for k, v in pairs dget .Client
    spawn ->
      if Components[k]
        warn "[Freya Client] Component Client::#{name} overrides Shared::#{name}"
      Components[k] = require v
      ComponentAdded\Fire k
      Components['Client::'..k] = require v
      ComponentAdded\Fire 'Client::'..k

with getmetatable ni
  .__index = cxitio
  .__tostring = -> "Freya Main: Client"
  .__metatable = "Locked Metatable: Freya Core"

ni
