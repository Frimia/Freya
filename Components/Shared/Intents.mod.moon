--//
--// * Intents for Freya
--// | Simple, dependency-free, all-to-all events suitable for both IPC and
--// | standard event implementations. Provides powerful interfaces for both
--// | local and remote communication, including filtering incoming and
--// | outgoing intents.
--//

RIntent = game.ReplicatedStorage\WaitForChild("Freya")\WaitForChild("Intent")

Events = require script.Parent.Events

cxitio = {}
ni = newproxy true

IIntercept = {}
OIntercept = {}

Intent = Events.new!
Intent\Intercept (name, ...) -> IIntercept[name] and IIntercept[name] ...

IsClient = do
  RunService = game\GetService "RunService"
  if RunService\IsRunMode!
    warn "Intents running in Studio Run mode. Behaviour can not be trusted."
  RunService\IsClient!

extract = (...) ->
  return select 2, ... if ... == ni else ...

cxitio.Subscribe = (...) ->
  name, f = extract ...
  Intent\connect (Name, ...) -> f ... if Name == name
cxitio.connect = cxitio.Subscribe
cxitio.Register = cxitio.Subscribe
cxitio.Connect = cxitio.Subscribe

cxitio.Fire = (...) ->
  name = extract ...
  return if OIntercept[name] and OIntercept[name] extract ...
  Intent\Fire name, true, select 2, extract ...
  if IsClient
    RIntent\FireServer extract ...
  else
    RIntent\FireAllClients extract ...
cxitio.Broadcast = cxitio.Fire

cxitio.Whisper = (...) ->
  -- Local only (Outgoing)
  name = extract ...
  return if OIntercept[name] and OIntercept[name] extract ...
  Intent\Fire name, true, select 2, extract ...

cxitio.Tell = (...) ->
  -- Remote only (Outgoing)
  -- Only way to tell a certain client
  name, player = extract ...
  return if OIntercept[name] and OIntercept[name] extract ...
  if IsClient
    RIntent\FireServer extract ...
  else
    if player == 'All'
      RIntent\FireAllClients name, select 3, extract ...
    elseif type(player) == 'table'
      for p in *player
        RIntent\FireClient p, name, select 3, extract ...
    else
      RIntent\FireClient player, name, select 3, extract ...

cxitio.Intercept = (...) ->
  -- Local intercept (Outgoing)
  name, f = extract ...
  o = OIntercept[name]
  OIntercept[name] = f
  return o
cxitio.Tap = cxitio.Intercept

cxitio.Listen = (...) ->
  -- Wait
  local tmp, e
  promise = Instance.new "BindableEvent"
  e = cxitio.Subscribe extract(...), (...) ->
    tmp = {...}
    promise\Fire!
  promise.Event\wait!
  e\disconnect!
  unpack tmp
cxitio.Wait = cxitio.Listen
cxitio.wait = cxitio.Listen

cxitio.Hold = (...) ->
  -- Local intercept (Incoming)
  name, f = extract ...
  o = IIntercept[name]
  IIntercept[name] = f
  return o
cxitio.Filter = cxitio.Hold

cxitio.SubscribeLocal = (...) ->
  -- Local only (Incoming)
  name, f = extract(...)
  cxitio.Subscribe name, (IsLocal, ...) -> f ... if IsLocal
cxitio.RegisterLocal = cxitio.SubscribeLocal
cxitio.ConnectLocal = cxitio.SubscribeLocal

cxitio.SubscribeRemote =  (...) ->
  -- Remote only (Incoming)
  name, f = extract(...)
  cxitio.Subscribe name, (IsLocal, ...) -> f ... unless IsLocal
cxitio.RegisterRemote = cxitio.SubscribeRemote
cxitio.ConnectRemote = cxitio.SubscribeRemote

if IsClient
  RIntent.OnClientEvent\connect (name, ...) ->
    Intent\Fire name, false, ...
else
  RIntent.OnServerEvent\connect (player, name, ...) ->
    Intent\Fire name, false, player, ...

cxitio.Intent = Intent
cxitio.RIntent = RIntent

with getmetatable ni
  .__index = cxitio
  .__tostring = -> "Freya Intents component"
  .__metatable = "Locked Metatable: Freya"

return ni
