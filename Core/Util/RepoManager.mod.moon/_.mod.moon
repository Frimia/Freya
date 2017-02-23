--//
--// * RepoManager for Freya
--// | In charge of managing repositories for Freya.
--//

-- You didn't think this through.
-- Needs to manage adding, searching, removing, cleaning (?), updating.

GitFetch = require script.Parent.GitFetch

HttpService = game\GetService "HttpService"
Togglet = (f) ->
  olden = HttpService.HttpEnabled
  pcall ->
    HttpService.HttpEnabled = true
  if HttpService.HttpEnabled
    f!
    pcall -> HttpService.HttpEnabled = olden
  else
    error "[Error][Freya RepoManager] HTTP requests are disabled."
RepoList = HttpService\JSONDecode require script.RepoList
RepoList or= {
  Repositories: {}
  Packages: {}
}

Flush = -> script.RepoList.Source = "return [===[#{HttpService\JSONEncode RepoList}]===]"
Check = (name) ->
  v = RepoList.Packages[name]
  if v
    return switch type v
      when 'table'
        warn "[Warn][Freya RepoManager] Multiple packages found for #{name}, selecting the first."
        v[1]
      else
        v
  else
    warn "[Warn][Freya RepoManager] Found no package for #{name}, consider updating the package cache?"
    return nil
AddRepo = (repo) ->
  -- Check for duplicates
  for v in *(RepoList.Repositories)
    if v == repo
      warn "[Warn][Freya RepoManager] Not adding #{repo} to the repo list as it already exists"
      return
  table.insert RepoList.Repositories, repo
  Flush!
DelRepo = (repo) ->
  for k,v in pairs RepoList.Repositories
    if v == repo
      table.remove RepoList.Repositories, k
      return
  warn "[Warn][Freya RepoManager] #{repo} appears to not be present in the repo list."
  Flush!
Update = -> Togglet ->
  for v in *(RepoList.Repositories)
    switch type v
      when 'number'
        def = require v
        nme = def.Name or def.Package.Name
        if RepoList.Packages[nme]
          if type RepoList.Packages[nme] == 'table'
            table.insert RepoList.Packages[nme], v
          else
            RepoList.Packages[nme] = {RepoList.Packages[nme], v}
        else
          RepoList.Packages[nme] = v
      when 'string'
        switch select 3, Package\find '^(%w+):'
          when 'github'
            for k,v in pairs GitFetch.ReadRepo v
              if RepoList.Packages[k]
                if type RepoList.Packages[k] == 'table'
                  table.insert RepoList.Packages[k], v
                else
                  RepoList.Packages[k] = {RepoList.Packages[k], v}
              else
                RepoList.Packages[k] = v
          when 'freya'
            warn "[Warn][Freya RepoManager] Unable to read Freya repos yet"
          else
            warn "[Warn][Freya RepoManager] Malformed repo #{v}"
  Flush!


Interface = {
  :Flush
  :Check
  :AddRepo
  :DelRepo
  :Update
  :RepoList
}

ni = newproxy true
with getmetatable ni
  .__index = Interface
  .__tostring = -> "RepoManager for Freya"
  .__metatable = "Locked metatable: Freya"

for k,v in pairs Interface
  Interface[k] = (...) ->
    return v ... if ni != ... else v select 2, ...

return ni
