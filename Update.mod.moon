--//
--// * Updater for Freya
--// | Upgrades an existing Freya installation.
--//

SS = game.ServerStorage
SSS = game.ServerScriptService
RS = game.ReplicatedStorage
RF = game.ReplicatedFirst
SPS = game.StarterPlayer.StarterPlayerScripts

=>
  -- Sanity check
  unless SS\FindFirstChild "Freya"
    error "[Freya Updater] No Freya install found in the game.", 2

  -- Check the Freya version
  VersionData = require SS.Freya.VersionManifest
  if VersionData.Version == nil
    -- Legacy (v1) Freya
    print "[Freya Updater] Legacy Freya installation detected"
    print "[Freya Updater] You're advised to take a copy of what you need and uninstall Freya"
    print "[Freya Updater] Then reinstall a non-legacy version of Freya."
    warn  "[Freya Updater] Scripts targeting legacy Freya may not work after updating."
    -- If somebody wants to make an updater for Legacy Freya they can be my
    -- guest. I don't want to do it.
  else
    maj, min, patch = string.match VersionData.Version, "^(%d+)%.(%d+)%.(%d+)"
    -- Major ticks on breaking changes
    -- Minor ticks on non-breaking API changes
    -- Patch ticks on internal changes not affecting the API.

    if maj == '2'
      if min == '0'
        -- Jk there's nothing to update
        print "[Freya Updater] Nothing to update!"
