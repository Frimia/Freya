--//
--// * Github protocol provider for Vulcan
--//

local ^

TOML = _G.Freya\GetComponent "TOML"

Http = game\GetService "HttpService"
headers = {
  Accept: "application/vnd.github.v3+json"
  --["User-Agent"]: "CrescentCode/Freya (User #{game.CreatorId})"
}
GET =  (url) ->
  local s
  local r
  i = 1
  while (not s) and i < 3
    s, r = pcall Http.GetAsync, Http, url, true, headers
    i += 1
    unless s
      warn "HTTP GET failed. Trying again in 5 seconds (#{i} of 3)"
      wait(5)
  return error r unless s
  return r, (select 2, pcall Http.JSONDecode, Http, r)
TEST =  (url) ->
  s, r = pcall Http.GetAsync, Http, url, true, headers
  return s
POST =  (url, body) ->
  local s
  local r
  i = 1
  while (not s) and i < 3
    s, r = pcall Http.PostAsync, Http, url, Http\JSONEncode(body), nil, nil, headers
    i += 1
    unless s
      warn "HTTP POST failed. Trying again in 5 seconds (#{i} of 3)"
      wait(5)
  return error r unless s
  return r, (select 2, pcall Http.JSONDecode, Http, r)

ghroot = "https://api.github.com/"
ghraw = "https://raw.githubusercontent.com/"

extignore = {
  md: true
  properties: true
  gitnore: true
  gitkeep: true
  gitignore: true
}

Uncase = =>
  tmp = {}
  for k,v in pairs @
    tmp[type(k) == 'string' and k\lower! or k] = v
  tmp

GetPackage = =>
  _, _, path, version = @find "^([^#]+)#?(.*)"
  version = version ~= '' and version or nil
  _, _, p1, p2 = path\find "^([^/]+)/?(.*)"
  p2 = p2 ~= '' and p2 or nil
  _, j = GET "#{ghroot}repos/#{p1}", headers
  return nil, "Package repository does not exist: #{p1} (#{j.message})" if j.message
  if version and version\find "^@" -- Branch or hash indicator
    _, j = GET "#{ghroot}repos/#{repo}/commits?sha=#{version\sub(2)}"
  else
    _, j = GET "#{ghroot}repos/#{repo}/commits"
  return nil, "Failed to get commit details: #{j.message}" if j.message
  path = j[1].sha
  if p2
    s, def = pcall GET, "#{ghraw}#{repo}/#{sha}/VulcanRepo.toml"
    if s
      s, e = pcall TOML.parse, def
      if s
        path = "#{path}/#{e[p2] or p2}"
      else
        return nil, e
    else
      path = "#{path}/#{p2}"
  _, j = GET "#{ghroot}repos/#{repo}/git/trees/#{path}?recursive=1", headers
  return nil, "Failed to get repo tree: #{j.message}" if j.message
  return nil, "Truncated repository" if j.truncated
  def = GET "#{ghraw}#{repo}/#{path}/VulcanPackage.toml"
  s, e = pcall TOML.parse, def
  return nil, e unless s
  e = Uncase e
  return nil, "Malformed package definition" unless e.name and e.resources and e.version
  data = {}
  tree = j.tree
  for v in *tree
    -- Get content of object if it's not a directory.
    -- If it's a directory, check if it's masking an Instance.
    _,__,ext = v.path\find '^.*/.-%.(.+)$'
    ext or= select 3, v.path\find '^[^%.]+%.(.+)$'
    ext or= v.path -- There's probably no extension. Mostly regards root files.
    if extignore[ext]
      print "[Vulcan Github Protocol] Skipping #{v.path}"
      continue
    local inst
    if v.type == 'tree'
      -- Directory
      -- Masking?
      if v.path\find '%.lua$' -- No moon support
        print "[Vulcan Github Protocol] Building #{v.path} as a blank Instance"
        -- Masking.
        -- Create as Instance (blank)
        inst = switch ext
          when 'mod.lua' then Instance.new "ModuleScript"
          when 'loc.lua' then Instance.new "LocalScript"
          when 'lua' then Instance.new "Script"
        if inst
          inst.Name = do
            n = select 3, v.path\find '^.+/(.-)%..+$'
            n or= select 3, v.path\find '^([^%.]+)%..+$'
            n
        else
          warn "[Vulcan Github Protocol] .#{ext} extensions are not supported"
      else
        print "[Vulcan Github Protocol] Building #{v.path} as a Folder"
        inst = with Instance.new "Folder"
          .Name do
            n = select 3, v.path\find '^.+/(.-)%..+$'
            n or= select 3, v.path\find '^([^%.]+)%..+$'
            n
    else
      name = v.path\match '^.+/(.-)%..+$'
      if name == '_'
        print "[Vulcan Github Protocol] Building #{v.path} as the source to #{v.path\match('^(.+)/[^/]-$')}"
        inst = data
        for t in v.path\gmatch '[^/]+'
          n = t\match '^([^%.]+).+$'
          unless n == '_'
            inst = inst[n]
        inst.Source = GET "#{ghraw}#{repo}/#{path}/#{v.path}"
        inst = nil -- There is no need to parent the Instance later
      else
        print "[Vulcan Github Protocol] Building #{v.path}"
        inst = switch ext
          when 'mod.lua' then Instance.new "ModuleScript"
          when 'loc.lua' then Instance.new "LocalScript"
          when 'lua' then Instance.new "Script"
        if inst
          inst.Name = do
            n = select 3, v.path\find '^.+/(.-)%..+$'
            n or= select 3, v.path\find '^([^%.]+)%..+$'
            n
          inst.Source = GET "#{ghraw}#{repo}/#{path}/#{v.path}"
        else
          warn "[Vulcan Github Protocol] `.#{ext}` extensions are not supported"
    if inst
      p = data
      if v.path\find('^(.+)/[^/]-$')
        for t in v.path\match('^(.+)/[^/]-$')\gmatch '[^/]+'
          p = p[t\match '^([^%.]+).+$']
      if p == origin
        origin[data.Name] = data
      else
        inst.Parent = p
    else
      print "[Vulcan Github Protocol] Skipping #{v.path}"

  {
    :data
    name: def.name
    resources: def.resources
    version: def.version
    identifier: def.identifier
    description: def.description
    depends: def.depends
    preserve: def.preserve
  }

ReadRepo = =>
  paklist = {}
  _, _, p1, p2 = @find "^([^/]+)/?(.*)"
  p2 = p2 ~= '' and p2 or nil
  if p2
    s, data = pcall GET, "#{ghraw}#{@}/master/VulcanRepo.toml"
    return {} unless s
    s, data = pcall TOML.parse, data
    unless s
      warn "[Vulcan Github Protocol] Invalid repo metadata in `#{@}`"
      return {}
    data = Uncase data
    _, tree = GET "#{ghroot}repos/#{@}/git/trees/master"
    if tree.message or tree.truncated
      warn "[Vulcan Github Protocol] Bad repository tree for `#{@}`"
      return {}
    for t in *tree.tree
      continue unless t.type == 'tree'
      s = TEST "#{ghraw}#{@}/master/#{t.path}/VulcanPackage.toml"
      continue unless s
      nom = t.path
      paklist[nom] = "github:#{@}/#{nom}"
    for k,v in pairs (data.aliases or {})
      paklist[k] = v
    for k,v in pairs (data.include or {})
      paklist[k] = v
  else
    -- User as repo
    _, rlist = GET "#{ghroot}users/#{p1}/repos"
    s, data = pcall GET, "#{ghraw}#{r.full_name}/master/VulcanPackage.toml"
    continue unless s and data
    s, data = pcall TOML.parse, data
    continue unless s and data
    paklist[r.name] = "github:#{r.full_name}"
  paklist

return {
  :extignore
  :GetPackage
  :ReadRepo
}
