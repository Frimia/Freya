--//
--// * Uninstaller for Freya
--// | Quickly runs through and deletes everything it can from Freya. It tries
--// | to make sure that this is done cleanly, including cleaning up packages
--// | and their resources.
--//

SS = game.ServerStorage
SSS = game.ServerScriptService
RS = game.ReplicatedStorage
RF = game.ReplicatedFirst
SPS = game.StarterPlayer.StarterPlayerScripts

->
  -- Sanity check
  unless SS\FindFirstChild "Freya"
    error "[Freya Uninstaller] No Freya install found in the game.", 2

  print "[Freya Uninstaller] Uninstalling packages:"
  Vulcan = require SS.Freya.Components.Studio.Vulcan
  for *v in Vulcan.Packages
    print "[Freya Uninstaller] * #{v.name}"
    Vulcan.Uninstall v.source

  SS.Freya\Destroy!
  SSS.FreyaScripts\Destroy!
  RS.Freya\Destroy!
  RF.FreyaScripts\Destroy!
  SPS.FreyaScripts\Destroy!

  RF.FreyaLoader\Destroy!
  SSS.FreyaLoader\Destroy!
  SPS.FreyaLoader\Destroy!

  print "[Freya Uninstaller] Finished uninstalling Freya"
