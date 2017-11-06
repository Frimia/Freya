--//
--// * Freya MainModule
--// | Installs or updates Freya, and loads up the Studio util for Freya.
--//

if game.ServerStorage\FindFirstChild "Freya"
  -- Update
  require(script.Update)!
else
  -- Install
  require(script.Install) script

print "[Freya] Loading Freya Studio..."
require game.ServerStorage.Freya.FreyaStudio

-- That was easy.
