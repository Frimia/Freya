--//
--// * Init script for ReplicatedFirst Freya
--// | This is not going to go well. This will load any scripts which depend on
--// | Freya once Freya is detected. Everything else can just wish good luck
--// | upon itself because it will need all the luck it can get.
--//

RF = game.ReplicatedFirst
RFF = RF\WaitForChild "FreyaScripts"

-- As it stands, nobody should be placing stuff in User if it needs to load
-- before Freya. If something needs to load before Freya but it's in here, it's
-- because it's from a package and the package owner is respectable.

loadme = {}
-- Make sure we get newcomers
RFF.ChildAdded\Connect =>
  if @IsA "LocalScript"
    if v\FindFirstChild("Enabled") and v.Enabled.Value
      if v\FindFirstChild("LoadOrder") and v.LoadOrder.Value < 0
        v.Disabled = false
      else
        loadme[#loadme+1] = v

-- Make sure we get the early-birds
for v in *RFF\GetChildren!
  if v\IsA "LocalScript"
    if v\FindFirstChild("Enabled") and v.Enabled.Value
      if v\FindFirstChild("LoadOrder") and v.LoadOrder.Value < 0
        v.Disabled = false
      else
        loadme[#loadme+1] = v

-- Wait for Freya. Duh.
Freya = require game.ReplicatedStorage\WaitForChild("Freya")\WaitForChild("Main")
_G.Freya = Freya
_G.FreyaClient = Freya

-- Everything from ReplicatedFirst should exist by now, because Freya exists.
-- Sort the loadme
table.sort loadme, (a,b) ->
  loada = a\FindFirstChild("LoadOrder")
  loada = loada and loada.Value or 1
  loadb = b\FindFirstChild("LoadOrder")
  loadb = loadb and loadb.Value or 1
  return loada < loadb

for v in *loadme
  ready = v\FindFirstChild "Ready"
  v.Disabled = false
  if ready
    while not ready.Value do ready.Changed\Wait!

print "[Freya Client] Loaded package scripts (ReplicatedFirst)"

loadme = {}
for v in *RFF.User\GetChildren!
  if not v\FindFirstChild("Enabled") or v.Enabled.Value
    loadme[#loadme+1] = v

table.sort loadme, (a,b) ->
  loada = a\FindFirstChild("LoadOrder")
  loada = loada and loada.Value or 1000
  loadb = b\FindFirstChild("LoadOrder")
  loadb = loadb and loadb.Value or 1000
  return loada < loadb

for v in *loadme
  ready = v\FindFirstChild "Ready"
  v.Disabled = false
  if ready
    while not ready.Value do ready.Changed\Wait!

print "[Freya Client] Loaded user scripts (ReplicatedFirst)"
