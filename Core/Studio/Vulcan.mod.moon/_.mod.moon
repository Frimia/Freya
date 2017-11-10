--//
--// * Vulcan for Freya
--// | Package management made simple, now with repository management built-in
--// | because splitting stuff up is for normal people.
--//
--// * New in v2
--// | Package management is no longer super crap.
--// | Also static resource management is pretty awesome you should try it.
--//

-- NOTE: Data for packages may not have to be stripped. It can be experimentally
-- serialized as a member of the Data Instance, in a folder by the name of the
-- package identifier.

local ^

ni = newproxy true
Hybrid = (f) -> (...) =>
  return f ... if @ == ni else f @, ...

local safecarrier
Safely = (f) -> (...) ->
  was = safecarrier
  safecarrier = true
  r = {pcall f, ...}
  if r[1]
    -- No error
    safecarrier = was
    return unpack r, 2
  else
    if was
      error r[2], 2
    else
      safecarrier = false
      if type(r[2]) == 'table'
        with r[2]
          error .why, .to + 1
      else
        error r[2], 2

{:JSONEncode, :JSONDecode} = game\GetService "HttpService"

Packages = {}
Dependants = {}
{:Protocols} = script

if script\FindFirstChild "Data"
  {:Packages, :Dependants} = JSONDecode script.Data.Source

packcache = {}
GetPackage = Safely Hybrid =>
  if packcache[@] then return packcache[@]
  @ = switch type @
    when 'number'
      "moduleid:#{@}"
    when 'string'
      @
    else
      error
        why: "[Freya Vulcan] Invalid package type provided: #{type @}"
        to: 3
  _, _, protocol, body = @find "^([^:]):(.+)"
  unless protocol and body
    -- Assume repo name
  unless Protocols\FindFirstChild protocol
    error
      why: "[Freya Vulcan] No handler for the `#{protocol}` protocol exists"
      to: 3
  packmeta, err = require(Protocols\FindFirstChild protocol).FetchPackage body
  unless packmeta
    error
      why: "[Freya Vulcan] Protocol failure for `#{@}`: #{err}"
      to: 3
  unless packmeta.name and packmeta.resources and packmeta.version
    error
      why: "[Freya Vulcan] Package `#{@}` is malformed"
      to: 3
  packmeta

Flush = Safely Hybrid ->
  -- Flush Dependants and Packages to a file. JSON-safe formats.
  with script\FindFirstChild("Data") or Instance.new "ModuleScript"
    .Source = JSONEncode {:Packages, :Dependants}
    .Parent = script

IntoPath = Safely Hybrid =>
  _, _, source = @find "^([^#:]+)#"
  local root, path
  if source
    _, _, source, root, path = @find "^([^#]-)#([^:]+):(.+)"
  else
    _, _, root, path = @find "^([^:]+):(.+)"
  unless root and path
    error
      why: "[Freya Vulcan] Malformed resource path `#{@}`"
      to: 3
  path = do
    tmp = {}
    path\gsub '[^/]+', => tmp[#tmp+1] = @
    tmp
  root = switch root
    when 'studiocomponent'
      game.ServerStorage.Freya.Components.Studio
    when 'sharedcomponent'
      game.ReplicatedFirst.Freya.Components.Shared
    when 'clientcomponent'
      game.ReplicatedFirst.Freya.Components.Client
    when 'servercomponent'
      game.ServerStorage.Freya.Components.Server
    when 'component'
      -- All of the above; regard the path carefully
      pat = table.remove(path, 1)
      switch pat
        when 'Shared'
          game.ReplicatedFirst.Freya.Components.Shared
        when 'Server'
          game.ServerStorage.Freya.Components.Server
        when 'Client'
          game.ReplicatedFirst.Freya.Components.Client
        when 'Studio'
          game.ServerStorage.Freya.Components.Studio
    when 'serverscript'
      game.ServerScriptService.Freya
    when 'playerscript'
      game.StarterPlayer.StarterPlayerScripts.Freya
    when 'initscript'
      game.ReplicatedFirst.Freya
    when 'game'
      game
  unless root
    error
      why: "[Freya Vulcan] The path `#{@}` uses an invalid root"
      to: 3
  if path[1] == 'User'
    error
      why: "[Freya Vulcan] The path `#{@}` tries to use a Freya User folder"
      to: 3
  for i=1, #path-1
    root = root\FindFirstChild path[i]
    unless root
      error
        why: "[Freya Vulcan] The path `#{@}` is invalid or incomplete"
        to: 3
  -- The last part of the path is the name of the new object
  return root, path[#path], source

working = {}
Upsert = Safely Hybrid =>
  -- Install, ignoring if the package already exists
  -- When version checking is added, you need to make sure that the package is
  -- updated if a required version is supplied.
  packmeta = GetPackage @
  if Packages[packmeta.identifier]
    -- It's already installed
    return packmeta.identifier
  else
    return Install @

Install = Safely Hybrid =>
  packmeta = GetPackage @
  -- !name
  -- !resources
  -- !version
  -- ?identifier
  -- ?description
  -- ?depends
  -- ?callback [install, update, uninstall]  # regard callback settings
  -- ?preserve

  -- # If the identifier is present, use it instead of the name when determining
  -- # existance of the package
  if working[packmeta.identifier]
    print "[Freya Vulcan] Already working on `#{packmeta.identifier}`; skipping"
  else
    working[packmeta.identifier] = true

    if Packages[packmeta.identifier]
      -- It exists already!
      error
        why: "[Freya Vulcan] Package `#{packmeta.identifier}` is already installed"
        to: 3

    if packmeta.depends
      for v in *packmeta.depends
        t_id = Upsert v -- Later, a table handler can be added to GetPackage
        t = Dependants[t_id] or {}
        t[#t+1] = packmeta.identifier
        Dependants[t_id] = t

    -- Dep sort by depth
    resources = packmeta.resources
    table.sort resources, (a,b) ->
      _, cnta = a\gsub '/', ''
      _, cntb = b\gsub '/', ''
      cnta < cntb

    print "[Freya Vulcan] Installing #{packmeta.name}"
    if @description
      print "[Freya Vulcan] Description: #{packmeta.description}"

    data = packmeta.data
    for v in *resources
      p,n,s = IntoPath v
      obj = data[s or n]
      obj.Name = n
      obj.Parent = p

    Packages[packmeta.identifier] = packmeta
    packmeta.data = nil

    Flush!

    working[packmeta.identifier] = nil
  return packmeta.identifier

Uninstall = Safely Hybrid =>
  packmeta = GetPackage @
  if working[packmeta.identifier]
    print "[Freya Vulcan] Already working on `#{packmeta.identifier}`; skipping"
  else
    working[packmeta.identifier] = true

    unless Packages[packmeta.identifier]
      -- Not installed
      error
        why: "[Freya Vulcan] Package `#{packmeta.identifier}` is not installed"
        to: 3

    for v in *Dependants[packmeta.identifier]
      Uninstall "game:v"

    resources = packmeta.resources
    table.sort resources, (a,b) ->
      _, cnta = a\gsub '/', ''
      _, cntb = b\gsub '/', ''
      cnta > cntb

    for v in *resources
      s,p,n = pcall IntoPath, v
      if s
        o = p\FindFirstChild n
        o\Destroy! if o

    Packages[packmeta.identifier] = nil
    Dependants[packmeta.identifier] = nil

    Flush!

    working[packmeta.identifier] = nil

Update = Safely Hybrid =>
  packmeta = GetPackage @
  if working[packmeta.identifier]
    print "[Freya Vulcan] Already working on `#{packmeta.identifier}`; skipping"
  else
    working[packmeta.identifier] = true

    unless Packages[packmeta.identifier]
      -- Not installed
      error
        why: "[Freya Vulcan] Package `#{packmeta.identifier}` is not installed"
        to: 3

    -- Read preserve from new package,
    -- Store according to preserve, top-down
    -- Read resources from old package
    -- Destroy according to old package, top-down
    -- Read resources from new package
    -- Insert from new package, bottom-up
    -- Restore from preseve, bottom-up

    PreserveList = {}
    preserve = packmeta.preserve
    table.sort preserve, (a,b) ->
      _, cnta = a\gsub '/', ''
      _, cntb = b\gsub '/', ''
      cnta > cntb

    for v in *preserve
      s, p, n = pcall IntoPath, v
      if s
        -- Ignore any paths which just don't exist
        o = p\FindFirstChild n
        if o
          PreserveList[#PreserveList+1] = {v, o}
          o.Parent = nil

    oldresources = Packages[packmeta.identifier].resources
    table.sort oldresources, (a,b) ->
      _, cnta = a\gsub '/', ''
      _, cntb = b\gsub '/', ''
      cnta > cntb

    for v in *oldresources
      s, p, n = pcall IntoPath, v
      if s
        -- Ignore any paths which just don't exist
        o = p\FindFirstChild n
        o\Destroy! if o

    resources = packmeta.resources
    table.sort resources, (a,b) ->
      _, cnta = a\gsub '/', ''
      _, cntb = b\gsub '/', ''
      cnta < cntb

    data = packmeta.data
    for v in *resources
      p,n,s = IntoPath v
      obj = data[s or n]
      obj.Name = n
      obj.Parent = p

    table.sort PreserveList, (a,b) ->
      _, cnta = a[1]\gsub '/', ''
      _, cntb = b[1]\gsub '/', ''
      cnta < cntb

    for v in *preservelist
      s,p,n = pcall IntoPath, v[1]
      if s
        o = p\FindFirstChild n
        if o then o\Destroy!
        v[2].Parent = p
      else
        print "[Freya Vulcan] Not restoring #{v[1]}; Nowhere to place it"

    Packages[packmeta.identifier] = packmeta
    packmeta.data = nil

    Flush!

cxitio = {
  :Flush
  :Packages
  :Dependants
  :Upsert
  :Install
  :Update
  :Uninstall
  :IntoPath
  :GetPackage
}

with getmetatable ni
  .__index = cxitio
  .__metatable = "Locked Metatable: Freya Core"
  .__tostring = "Freya Vulcan"

ni
