-- Observers are special modifiers for functions
Controller = {}
ni = newproxy true
ObserverMt = {}
ObserverClass = {}
ObserverCallbacks = setmetatable {}, __mode: 'k'
ObserverEmitters = setmetatable {}, __mode: 'k'
ObserverRules = setmetatable {}, __mode: 'k'
ObserverArbiters = setmetatable {}, __mode: 'k'

Event = _G.Freya.GetComponent "Events"
Intent = _G.Freya.GetComponent "Intents"
Rules = _G.Freya.GetComponent "Rules"

Hybrid = (f) -> (...) ->
  return f ... if ... != ni else f select 2, ...
  
Controller.new = Hybrid (f) ->
  newobs = newproxy true
  omt = getmetatable newobs
  for k,v in pairs ObserverMt
    omt[k] = v
  ObserverCallbacks[newobs] = f
  ObserverEmitters[newobs] = Event.new!
  ObserverRules[newobs] = {}

with ObserverClass
  .Emit = (e) =>
    ObserverEmitters[@]\Connect (...) -> e\Fire ...
  .Inform = (i) =>
    ObserverEmitters[@]\Connect (...) -> Intent.Fire i, ...
  .Mutate = (f) =>
    of = ObserverCallbacks[@]
    ObserverCallbacks[@] = (...) ->
      udata = {
        args: {...}
        void: false
      }
      resp = {f udata}
      unless udata.void
        return of unpack udata.args
      return unpack resp
  .Umpire = (f) =>
    al = ObserverArbiters[@]
    al[#al+1] = f
    return Event.Connection ->
      for i=1, #al
        if al[i] == f
          table.remove al, i
          break
  .Conform = (r) =>
    rl = ObserverRules[@]
    rl[#rl+1] = r
    return Event.Connection ->
      for i=1, #rl
        if rl[i] == r
          table.remove rl, i
          break
  .Verify = .Conform
  .Arbit = .Umpire
  .Tell = .Inform
  .Handle = .Mutate
  .Process = .Mutate

with ObserverMt
  .__tostring = => tostring ObserverCallbacks[@]
  .__len = => ObserverCallbacks[@]
  .__call = (...) =>
    for v in *ObserverRules[@]
      return unless Rules.Try v, ...
    for v in *ObserverArbiters[@]
      return if v ...
    ObserverEmitters[@]\Fire ObserverCallbacks[@] ...

with getmetatable ni
  .__index = Controller
  .__metatable = "Locked Metatable: Freya"
  .__tostring = -> "Freya Observer controller"
  
return ni
