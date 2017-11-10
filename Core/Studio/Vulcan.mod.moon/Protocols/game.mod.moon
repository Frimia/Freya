--//
--// * Game protocol provider for Vulcan
--// | Exists solely to identify packages which are already installed, and
--// | therefore have their package data within the game already, minus the
--// | data table.
--//

Vulcan = _G.Freya.GetComponent "Vulcan"

GetPackage = =>
  pak = Vulcan.Packages[@]
  pak.data = {} -- Dummy data, just incase
  pak

ReadRepo = => {} -- Who are you trying to kid?

return {
  :GetPackage
  :ReadRepo
}
