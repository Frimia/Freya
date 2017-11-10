--//
--// * RepoManager for Vulcan
--// | Manages repositories from various sources, providing an interface and
--// | central database for repository sources and package aliases.
--//

local ^

ni = newproxy true
Hybrid = (f) -> (...) =>
  return f ... if @ == ni else f @, ...

{:JSONEncode, :JSONDecode} = game\GetService "HttpService"

Aliases = {}
Repositories = {}
{:Protocols} = script.Parent

if script\FindFirstChild "Data"
  {:Aliases, :Repositories} = JSONDecode script.Data.Source

Flush = ->
  with script\FindFirstChild("Data") or Instance.new "ModuleScript"
    .Source = JSONEncode {:Aliases, :Repositories}
    .Parent = script

ResolveAlias = Hybrid => Aliases[@]

AddRepository = Hybrid =>
  assert type(@) == 'string', "[Vulcan RepoManager] Expected a repo string", 3
  _, _, protocol, body = @find "^([^:]):(.+)"
  assert protocol and body, "[Vulcan RepoManager] Malformed repo string `#{@}`", 3
  for v in *Repositories
    if v == @
      return error "[Vulcan RepoManager] Repository `#{@}` is already added", 3
  Repositories[#Repositories+1] = @

RemoveRepository = Hybrid =>
  del = false
  for i=1, #Repositories
    if Repositories[i] == @
      del = true
    if del
      Repositories[i] = Repositories[i+1]
  unless del
    error "[Vulcan RepoManager] Repository `#{@}` was not present", 3

Update = Hybrid =>
  for v in *Repositories
    _, _, protocol, body = v\find "^([^:]):(.+)"
    protocol = Protocols\FindFirstChild protocol
    if protocol
      protocol = require protocol
    else
      error "[Vulcan RepoManager] Repository `#{v}` uses an unknown protocol", 3
    rlist, err = protocol.ReadRepo body
    unless rlist
      error "[Vulcan RepoManager] Protocol failure for `#{@}`: #{err}", 3
    for a, p in pairs rlist
      al = Aliases[a]
      switch type al
        when 'nil'
          Aliases[a] = p
        when 'string'
          Aliases[a] = {Aliases[a], p}
        when 'table'
          al[#al+1] = p
  for k,v in pairs Aliases
    if type(v) == 'table'
      warn "[Vulcan RepoManager] Conflicting packages exist for `#{k}`"
      for p in *v
        warn "[Vulcan RepoManager] * `#{p}`"

cxitio = {
  :ResolveAlias
  :AddRepository
  :RemoveRepository
  :Update
  :Flush
}
