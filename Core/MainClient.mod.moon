--//
--// * Main Module for Freya Client
--// | Utility entry point for everything not done manually
--// | Tracks all modules, components, libraries, etc.
--//

ni = newproxy true
_didinit = false

Hybrid = (f) -> (...) ->
  return f select 2, ... if ... == ni else f ...
  
IsInstance = do
  game = game
  gs = game.GetService
  type = type
  pcall = pcall
  (o using nil) ->
    type = type o
    return false if type ~= 'userdata'
    s,e = pcall gs, game, o
    return s and not e
  
Components = {}
Libraries = {}
LiteLibs = {}

BaseLib = require game.ReplicatedStorage.Freya\WaitForChild("Core")\WaitForChild "BaseLib"
LiteLib = require game.ReplicatedStorage.Freya.Core\WaitForChild "LiteLib"

Events = require game.ReplicatedStorage.Freya\WaitForChild("Components")\WaitForChild("Shared")\WaitForChild("Events")
ComponentAdded = Events.new!
LibAdded = Events.new!
LiteAdded = Events.new!
  
STUB = ->

loaded = setmetatable {}, __mode: 'k'
liteLoaded = setmetatable {}, __mode: 'k'

Controller = with {
    GetComponent: Hybrid (ComponentName) ->
      component = Components[ComponentName]
      if component
        if IsInstance(component)
          component = require component
        return component
      warn "[WARN][Freya Client] Yielding for #{ComponentName}"
      while ComponentAdded\wait! ~= ComponentName do STUB!
      return Components[ComponentName]
    SetComponent: Hybrid (ComponentName, ComponentValue) ->
      if Components[ComponentName]
        warn "[WARN][Freya Client] Overwriting component #{ComponentName}"
      Components[ComponentName] = ComponentValue
      ComponentAdded\Fire ComponentName
    GenerateWrapper: Hybrid (global) ->
      if global == nil
        global = true
      return BaseLib not global
    LoadLibrary: Hybrid (LibraryName) ->
      lib = Libraries[LibraryName]
      unless lib
        warn "[WARN][Freya Client] Yielding for #{LibraryName}"
        while not lib
          if LibAdded\wait! == LibraryName
            lib = Libraries[LibraryName]
      _ENV = getfenv 3
      wrapper = BaseLib!
      if liteLoaded[_ENV]
        warn "[WARN][Freya] Stacking BaseLib on LiteLib."
      if loaded[_ENV]
        setfenv(lib, _ENV) loaded[_ENV]
      else
        wrapper.wlist.ref[cxitio.LoadLibrary] = cxitio.LoadLibrary
        newEnv = setmetatable {}, {
          __index: (_,k) ->
            v = Wrapper.Overrides.Globals[k] or _ENV[k]
            return v if v
            s,v = pcall(game.GetService,game,k)
            return v if s
          __newindex: (_,k,v) ->
            warn("Settings global",k,"as",v)
            _ENV[k] = v
          __metatable: "Locked metatable: Freya Library Environment"
        }
        _ENV.wrapper = wrapper
        newEnv = wrapper(newEnv)
        loaded[_ENV] = wrapper
        loaded[newEnv] = wrapper
        setfenv 3, newEnv
        setfenv(lib, newEnv) wrapper
    GenerateLiteWrapper: Hybrid (global) ->
      if global == nil
        global = true
      return LiteLib not global
    LoadLiteLibrary: Hybrid (name) ->
      lib = LiteLibs[name]
      unless lib
        warn "[WARN][Freya Client] Yielding for #{name}"
        while not lib
          if LiteAdded\wait! == name
            lib = LiteLibs[name]
      _ENV = getfenv 3
      warn "[WARN][Freya] Stacking LiteLib on BaseLib." if loaded[_ENV]
      return setfenv(lib, _ENV) liteLoaded[_ENV] if liteLoaded[_ENV]
      wrapper = LiteLib!
      newENV = setmetatable {}, __index: _ENV
      _ENV.wrapper = wrapper
      newENV = wrapper newENV
      liteLoaded[_ENV] = wrapper
      liteLoaded[newENV] = wrapper
      setfenv 3, newENV
      setfenv(lib, newENV) wrapper
    Init: Hybrid (name) ->
      return if _didinit
      with game.ReplicatedStorage.Freya.Components
        for v in *.Shared\GetChildren!
          spawn ->
            Components[v.Name] = require v
            ComponentAdded\Fire v.Name
        for v in *.Client\GetChildren!
          spawn ->
            Components[v.Name] = require v
            ComponentAdded\Fire v.Name
      for v in *game.ReplicatedStorage.Freya.Libraries\GetChildren!
        spawn ->
          Libraries[v.Name] = require v
          LibAdded\Fire v.Name
      for v in *game.ReplicatedStorage.Freya.LiteLibraries\GetChildren!
        spawn ->
          LiteLibs[v.Name] = require v
          LiteAdded\Fire v.Name
      game.ReplicatedStorage.Freya.Components.DescendantAdded\connect (obj) ->
        return unless obj.Parent.Parent == game.ReplicatedStorage.Freya.Components
        Components[obj.Name] = require obj
        ComponentAdded\Fire obj.Name
      game.ReplicatedStorage.Freya.Libraries.ChildAdded\connect (obj) ->
        Libraries[obj.Name] = require obj
        LibAdded\Fire obj.Name
      game.ReplicatedStorage.Freya.LiteLibraries.ChildAdded\connect (obj) ->
        LiteLibs[obj.Name] = require obj
        LiteAdded\Fire obj.Name
  }
  .GetService = .GetComponent
  .SetService = .SetComponent
  .GetModule = .GetComponent
  .SetModule = .SetComponent

with getmetatable ni
  .__index = Controller
  .__tostring = -> "Freya Client Controller"
  .__metatable = "Locked metatable: Freya Client"
  
return ni
