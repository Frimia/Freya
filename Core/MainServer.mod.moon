--//
--// * Main Module for Freya Server
--// | Utility entry point for everything not done manually
--// | Tracks all modules, components, libraries, etc.
--//

ni = newproxy true

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

BaseLib = require game.ReplicatedStorage.Freya.Core.BaseLib
LiteLib = require game.ReplicatedStorage.Freya.Core.LiteLib

Events = require game.ReplicatedStorage.Freya.Components.Shared.Events

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
      warn "[WARN][Freya Server] Yielding for #{ComponentName}"
      while ComponentAdded\wait! ~= ComponentName do STUB!
      return Components[ComponentName]
    SetComponent: Hybrid (ComponentName, ComponentValue) ->
      if Components[ComponentName]
        warn "[WARN][Freya Server] Overwriting component #{ComponentName}"
      Components[ComponentName] = ComponentValue
      ComponentAdded\Fire ComponentName
    GenerateWrapper: Hybrid (global) ->
      if global == nil
        global = true
      return BaseLib not global
    LoadLibrary: Hybrid (LibraryName) ->
      lib = Libraries[LibraryName]
      unless lib
        warn "[WARN][Freya Server] Yielding for #{LibraryName}"
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
        warn "[WARN][Freya Server] Yielding for #{name}"
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
    Init: ->
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
      for k,v in pairs dget game.ReplicatedStorage.Freya.Components.Shared
        spawn ->
          Components[k] = require v
          ComponentAdded\Fire k

      for k,v in pairs dget game.ServerStorage.Freya.Components
        spawn ->
          Components[k] = require v
          ComponentAdded\Fire k

      for k,v in pairs dget game.ReplicatedStorage.Freya.Libraries
        spawn ->
          Libraries[k] = require v
          LibAdded\Fire k

      for k,v in pairs dget game.ReplicatedStorage.Freya.LiteLibraries
        spawn ->
          LiteLibs[k] = require v
          LiteAdded\Fire k
  }
  .GetService = .GetComponent
  .SetService = .SetComponent
  .GetModule = .GetComponent
  .SetModule = .SetComponent

with getmetatable ni
  .__index = Controller
  .__tostring = -> "Freya Server Controller"
  .__metatable = "Locked metatable: Freya Server"
  
return ni
