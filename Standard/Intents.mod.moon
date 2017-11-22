--//
--// * Intents for Freya
--// | Simple, dependency-free, all-to-all events suitable for both IPC and
--// | standard event implementations. Provides powerful interfaces for both
--// | local and remote communication, including filtering incoming and
--// | outgoing intents.
--//
--// * New in v2
--// | Intents now broadcast to the server and all clients. This means that the
--// | `isLocal` parameter can be safely replaced with a `source` parameter,
--// | which contains the Player which sent the intent, or `nil` if the intent
--// | came from the server. Intents sent from the client will reach other
--// | clients if the server sets up a boomerang/replicator for it.
--// |
--// | Intents are optimized across the network to drop the string-based Intent
--// | name and rely on the RemoteEvent id to identify which intent is being
--// | broadcast.
--//

local ^

Events = _G.Freya\GetComponent "Events"

OutEvents = {}
InEvents = {}
AllowReflection = {}
RemoteCollection = game.ReplicatedFirst\WaitForChild "FreyaIntentCollection"

local IsClient
with game\GetService "RunService"
  if \IsClient! and \IsServer!
    warn "Intents are running in Studio test mode; behaviour can not be trusted"
  IsClient = \IsClient!

ThisSource = IsClient and game.Players.LocalPlayer or nil
GetPlayers = game.Players\GetPlayers

ni = newproxy true
Hybrid = (f) -> (...) -> return f ... if ... ~= ni else f select 2, ...

InitIntent = =>
  -- self: name
  unless OutEvents[@]
    oe = Events.new!
    OutEvents[@] = oe
    ie = Events.new!
    InEvents[@] = ie
    unless IsClient or RemoteCollection\FindFirstChild @
      with Instance.new "RemoteEvent"
        .Name = @
        .Parent = RemoteCollection
    if IsClient
      oe\Connect (target, ...) ->
        switch type target
          when 'string'
            switch target -- Ignore invalid targets
              when 'All'
                ie\Fire ThisSource, ...
                re = RemoteCollection\FindFirstChild @
                if re
                  re\FireServer {
                    ts: true
                    p: [v for v in *GetPlayers! when v ~= ThisSource]
                  }, ...
              when 'Others'
                re = RemoteCollection\FindFirstChild @
                if re
                  re\FireServer {
                    ts: true
                    p: [v for v in *GetPlayers! when v ~= ThisSource]
                  }, ...
              when 'Self'
                ie\Fire ThisSource, ...
              when 'Players'
                ie\Fire ThisSource, ...
                re = RemoteCollection\FindFirstChild @
                if re
                  re\FireServer {
                    ts: false
                    p: [v for v in *GetPlayers! when v ~= ThisSource]
                  }, ...
              when 'Server'
                re = RemoteCollection\FindFirstChild @
                if re
                  re\FireServer {
                    ts: true
                  }, ...
          when 'userdata'
            re = RemoteCollection\FindFirstChild @
            if re
              re\FireServer {
                ts: false
                p: {target}
              }, ...
          when 'nil'
            re = RemoteCollection\FindFirstChild @
            if re
              re\FireServer {
                ts: true
              }, ...
    else
      oe\Connect (target, ...) ->
        switch type target
          when 'string'
            switch target
              when 'All'
                ie\Fire ThisSource, ...
                re = RemoteCollection\FindFirstChild @
                re\FireAllClients nil, ...
              when 'Others'
                re = RemoteCollection\FindFirstChild @
                re\FireAllClients nil, ...
              when 'Self'
                ie\Fire ThisSource, ...
              when 'Players'
                re = RemoteCollection\FindFirstChild @
                re\FireAllClients nil, ...
              when 'Server'
                ie\Fire nil, ...
          when 'userdata'
            re\FireClient target, nil, ...
          when 'nil'
            ie\Fire nil, ...


Subscribe = Hybrid (f) =>
  InitIntent @
  InEvents[@]\Connect f

Broadcast = Hybrid (...) =>
  InitIntent @
  OutEvents\Fire 'All', ...

Whisper = Hybrid (target, ...) =>
  -- Cases for target:
  -- 'All': Basically Broadcast
  -- 'Other': Broadcast but not local
  -- 'Self': Local only
  -- 'Players': All players
  -- 'Server': Server only
  -- Source: Specific source (Player, server (nil))
  -- {Sources}: All sources according to list; 'Server' for server.
  if type(target) == 'table'
    for v in *target
      Whisper @, v, ... -- For good measure; people are stupid
  else
    OutEvents\Fire target, ...

HandleConnection = Hybrid (connHandle) => -- inbound
  InitIntent @
  InEvents[@]\Handle connHandle

HandleEmitter = Hybrid (emitHandle) => -- outbound
  InitIntent @
  OutEvents[@]\Handle emitHandle

AllowReflection = => AllowReflection[@] = true
-- Does nothing on the client but take up memory.

cxitio = {
  :Subscribe
  Connect: Subscribe
  Listen: Subscribe

  :Broadcast
  Fire: Broadcast

  :Whisper
  Tell: Whisper

  :HandleConnection
  HandleInbound: HandleConnection

  :HandleEmitter
  HandleOutbound: HandleEmitter

  :AllowReflection
  Boomerang: AllowReflection
}

if IsClient
  RemoteCollection.ChildAdded\Connect =>
    InitIntent @Name
    ie = InEvents[@Name]
    @OnClientEvent\Connect ie\Fire
  for v in *RemoteCollection\GetChildren!
    InitIntent v.Name
    ie = InEvents[v.Name]
    v.OnClientEvent\Connect ie\Fire
else
  RemoteCollection.ChildAdded\Connect =>
    r = @
    n = @Name
    ie = InEvents[n]
    @OnServerEvent\Connect (meta, ...) =>
      -- self: player source
      if meta.ts -- Targets Server
        ie\Fire @, ...
      if meta.p and AllowReflection[n]
        for v in *meta.p
          r\FireClient v, @, ... -- Firing to client requires a true source

with getmetatable ni
  .__index = cxitio
  .__tostring = -> "Freya Intents"
  .__metatable = "Locked Metatable: Freya Core"

ni
