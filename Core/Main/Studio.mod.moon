--//
--// * Freya Main for Studio
--// | Provides Freya utility for Studio. That's about it really. Combines all
--// | component sources, meaning that some components may be available in
--// | Studio even though they may not necessarily work.
--//

local ^

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
    warn("[Freya Studio] Yielding for component #{@}")
    while ComponentAdded\Wait! ~= @ do nothing!
    Components[@]
  SetComponent: Hybrid (Component) =>
    error "[Freya Studio] Overriding existing component #{@}", 3
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
do @ = game.ReplicatedStorage.Freya.Components.Shared
  @DescendantAdded\Connect (obj) ->
    return unless obj\IsA "ModuleScript"
    name = {}
    t = obj
    while t ~= @
      table.insert name, 1, t.Name
      t = t.Parent
    name = table.concat name, '/'
    Components[name] = require obj
    ComponentAdded\Fire name
    Components["Shared::"..name] = require obj
    ComponentAdded\Fire "Shared::"..name
  for k, v in pairs dget @
    spawn ->
      Components[k] = require v
      ComponentAdded\Fire k
      Components["Shared::"..k] = require v
      ComponentAdded\Fire "Shared::"..k
do @ = game.ServerStorage.Freya.Components.Server
  @DescendantAdded\Connect (obj) ->
    return unless obj\IsA "ModuleScript"
    name = {}
    t = obj
    while t ~= @
      table.insert name, 1, t.Name
      t = t.Parent
    name = table.concat name, '/'
    Components[name] = require obj
    ComponentAdded\Fire name
    Components["Server::"..name] = require obj
    ComponentAdded\Fire "Server::"..name
  for k, v in pairs dget @
    spawn ->
      Components[k] = require v
      ComponentAdded\Fire k
      Components["Server::"..k] = require v
      ComponentAdded\Fire "Server::"..k
do @ = game.ReplicatedStorage.Freya.Components.Client
  @DescendantAdded\Connect (obj) ->
    return unless obj\IsA "ModuleScript"
    name = {}
    t = obj
    while t ~= @
      table.insert name, 1, t.Name
      t = t.Parent
    name = table.concat name, '/'
    Components[name] = require obj
    ComponentAdded\Fire name
    Components["Client::"..name] = require obj
    ComponentAdded\Fire "Client::"..name
  for k, v in pairs dget @
    spawn ->
      Components[k] = require v
      ComponentAdded\Fire k
      Components["Client::"..k] = require v
      ComponentAdded\Fire "Client::"..k
do @ = game.ServerStorage.Freya.Components.Studio
  @DescendantAdded\Connect (obj) ->
    return unless obj\IsA "ModuleScript"
    name = {}
    t = obj
    while t ~= @
      table.insert name, 1, t.Name
      t = t.Parent
    name = table.concat name, '/'
    Components[name] = require obj
    ComponentAdded\Fire name
    Components["Studio::"..name] = require obj
    ComponentAdded\Fire "Studio::"..name
  for k, v in pairs dget @
    spawn ->
      Components[k] = require v
      ComponentAdded\Fire k
      Components["Studio::"..k] = require v
      ComponentAdded\Fire "Studio::"..k

Vulcan = cxitio.GetComponent "Studio::Vulcan"
RepoManager = cxitio.GetComponent "Studio::Vulcan/RepoManager"

with getmetatable ni
  .__index = cxitio
  .__tostring = -> "Freya Main: Studio"
  .__metatable = "Locked Metatable: Freya Core"

ni
