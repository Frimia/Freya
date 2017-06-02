--//
--// * Freya Studio util module
--//

local ^

ni = newproxy true
Hybrid = (f) -> (...) ->
  return f select 2, ... if ... == ni else f ...

Vulcan = require script.Parent.Util.Vulcan
RepoManager = require script.Parent.Util.RepoManager
plugin = PluginManager!\CreatePlugin!

Controller = with {
    InstallPackage: Hybrid (Package, Version) ->
      -- Install a package.
      s, err = pcall Vulcan.InstallPackage, Package, Version
      return error "[Error][Freya Studio] Unable to install package - '#{err}'" unless s
      print "[Info][Freya Studio] Successfully installed #{Package}"
    Update: ->
      -- Update Freya by reading the update source from the contained
      -- version manifest.
      return require(require(game.ServerStorage.Freya.VersionManifest).id)
    UpdatePackage: Hybrid (Package, Version) ->
      -- Update a package.
      s, err = pcall Vulcan.UpdatePackage, Package, Version
      return error "[Error][Freya Studio] Unable to update package - '#{err}'" unless s
      print "[Info][Freya Studio] Succcessfully updated #{Package}"
    GetPackages: ->
      -- Get the current packages list
      return nil
    Load: Hybrid (UtilPackage) ->
      -- Load something from Util
      -- Come back to extend this later when you know how the command bar env
      -- works and persists between calls.
      assert type(UtilPackage) == 'string',
        "You need to supply a string Package name to use",
        2
      mod = script.Parent.Util\FindFirstChild UtilPackage
      assert mod,
        "Invalid package to load",
        2
      return require mod
    UninstallPackage: Hybrid (Package) ->
      -- Use the package uninstall script or use metadata
      s, err = pcall Vulcan.UninstallPackage, Package
      return error "[Error][Freya Studio] Unable to remove package - '#{err}'" unless s
      print "[Info][Freya Studio] Succcessfully uninstalled #{Package}"
    Uninstall: ->
      -- Uninstall Freya.
      return require(game.ServerStorage.Freya.vanish)!
    Help: ->
      print "[Help][Freya Studio] Freya Studio help:"
      print "[Help][Freya Studio] Installing a package: `_G.Install(Package)`"
      print "[Help][Freya Studio] Updating a package: `_G.Update(Package)`"
      print "[Help][Freya Studio] Uninstalling a package: `_G.Uninstall(Package)`"
      print "[Help][Freya Studio] Updating Freya: `_G.UpdateFreya()`"
      print "[Help][Freya Studio] Adding repositories: `_G.AddRepo(Repository)`"
      print "[Help][Freya Studio] Removing repositories: `_G.DelRepo(Repository)`"
      print "[Help][Freya Studio] Updating package cache: `_G.UpdateRepo()`"
      print "[Help][Freya Studio] Don't want to use `_G`? Try `_G.Freya.Inject()`"
    AddRepo: Hybrid RepoManager.AddRepo
    DelRepo: Hybrid RepoManager.DelRepo
    UpdateRepo: Hybrid RepoManager.Update
    Plugin: plugin
    Inject: ->
      nenv = {
        Freya: Controller
        Install: Controller.InstallPackage
        Update: Controller.UpdatePackage
        Uninstall: Controller.UninstallPackage
        InstallPackage: Controller.InstallPackage
        UpdatePackage: Controller.UpdatePackage
        UninstallPacakge: Controller.UninstallPackge
        UpdateFreya: Controller.Update
        AddRepo: Controller.AddRepo
        DelRepo: Controller.DelRepo
        UpdateRepo: Controller.UpdateRepo
      }
      oenv = getfenv 2
      setfenv 2, setmetatable nenv, __index: oenv
      print "[Info][Freya Studio] Successfully injected Freya"
  }
  .UpdateFreya = .Update
  .LoadUtil = .Load
  .UninstallFreya = .Uninstall

with getmetatable ni
  .__index = Controller
  .__tostring = -> "FreyaStudio Controller"
  .__metatable = "Locked Metatable: Freya"

-- Load me in Scotty
_G.Freya = ni
_G.InstallPackage = ni.InstallPackage
_G.UpdatePackage = ni.UpdatePackage
_G.UninstallPackage = ni.UninstallPackage
_G.Install = ni.InstallPackage
_G.Update = ni.UpdatePackage
_G.Uninstall = ni.UninstallPackage
_G.UpdateFreya = ni.Update
_G.UpdateRepo = ni.UpdateRepo
_G.AddRepo = ni.AddRepo
_G.DelRepo = ni.DelRepo

print "[Info][Freya Studio] Freya Studio loaded. Try `_G.Freya.Help()` for more info."

return ni
