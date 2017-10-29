--//
--// * Init script for ServerScriptService Freya
--// | This is the one true script; all that Freya needs to work on the server.
--// | This is also a lie. There will be other scripts later, probably.
--//

SSS = game.ServerScriptService
SSSF = SSS.FreyaScripts

loadme = {}
for v in *SSSF\GetChildren!
  if v\IsA "LocalScript"
    if v\FindFirstChild("Enabled") and v.Enabled.Value
      loadme[#loadme+1] = v

-- Should Freya somehow not be here, reinstall Freya faster than you can say
-- "Whoops."
Freya = require game.ServerStorage.Freya.Main
_G.Freya = Freya
_G.FreyaServer = Freya

-- Sort the loadme
table.sort loadme, (a,b) ->
  loada = a:FindFirstChild("LoadOrder")
  loada = loada and loada.Value or 1
  loadb = b:FindFirstChild("LoadOrder")
  loadb = loadb and loadb.Value or 1
  return loada < loadb

for v in *loadme
  ready = v\FindFirstChild "Ready"
  v.Disabled = false
  if ready
    while not ready.Value do ready.Changed\Wait!

print "[Freya Server] Loaded package scripts (ServerScriptService)"

loadme = {}
for v in *SSSF.User\GetChildren!
  if not v\FindFirstChild("Enabled") or v.Enabled.Value
    loadme[#loadme+1] = v

table.sort loadme, (a,b) ->
  loada = a:FindFirstChild("LoadOrder")
  loada = loada and loada.Value or 1000
  loadb = b:FindFirstChild("LoadOrder")
  loadb = loadb and loadb.Value or 1000
  return loada < loadb

for v in *loadme
  ready = v\FindFirstChild "Ready"
  v.Disabled = false
  if ready
    while not ready.Value do ready.Changed\Wait!

print "[Freya Server] Loaded user scripts (ServerScriptService)"
