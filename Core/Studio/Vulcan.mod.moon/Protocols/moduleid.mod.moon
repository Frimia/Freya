--//
--// * ModuleID protocol handler for Vulcan
--// | Deals with loading up packages and repositories from ModuleScript sources
--// | so that packages can be provided without Github access
--//

GetPackage = =>
  pak = require tonumber @
  unless pak.data
    return nil, "[Vulcan ModuleId Protocol] Module is missing its data"
  pak
  -- Due to restrictions, modules are expected to set data as script or similar

ReadRepo = =>
  require tonumber @
  -- ModuleScript repos are expected to define only aliases and no resources.
  -- Startlingly easy.
  -- Regard, ModuleScripts do allow arbitrary code execution

return {
  :GetPackage
  :ReadRepo
}
