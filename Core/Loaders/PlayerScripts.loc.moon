--//
--// * Init script for StarterPlayerScripts Freya
--// | This loads stuff from SPS, which is actually inside PlayerScripts,
--// | because SPS gets put into PlayerScripts.
--//

Player = game.Players.LocalPlayer
PS = Player.PlayerScripts
PSF = PS\WaitForChild "FreyaScripts"

loadme = {}
for v in *PSF\GetChildren!
  if v\IsA "LocalScript"
    if v\FindFirstChild("Enabled") and v.Enabled.Value
      loadme[#loadme+1] = v

-- Should Freya somehow not be here, consult a doctor.
Freya = require game.ReplicatedStorage\WaitForChild("Freya")\WaitForChild("Main")
_G.Freya = Freya
_G.FreyaClient = Freya

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

print "[Freya Client] Loaded package scripts (PlayerScripts)"

loadme = {}
for v in *PSF.User\GetChildren!
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

print "[Freya Client] Loaded user scripts (PlayerScripts)"
