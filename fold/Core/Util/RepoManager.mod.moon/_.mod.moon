--//
--// * RepoManager for Freya
--// | In charge of managing repositories for Freya.
--//

-- You didn't think this through.
-- Needs to manage adding, searching, removing, cleaning (?), updating.

GitFetch = require script.Parent.GitFetch

HttpService = game\GetService "HttpService"
hwarned = false
Togglet = (f) ->
  s,e = pcall -> HttpService.HttpEnabled
  if s
    unless e
      HttpService.HttpEnabled = true
    f!
    HttpService.HttpEnabled = e
  elseif not hwarned
    warn "[Warn][Freya RepoManager] Plugins may not read the HttpEnabled state.
Ensure that HttpEnabled is ticked to allow RepoManager to function properly."
    f!
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
        warn "[Warn][Freya RepoManager] Multiple packages found for #{name},"
        for nv in *v
          warn "[Warn][Freya RepoManager] * #{nv}"
        warn "[Warn][Freya RepoManager] Selecting #{v[1]}"
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
  RepoList.Packages = {}
  for v in *(RepoList.Repositories)
    switch type v
      when 'number'
        def = require v
        -- Packages are not repos
        unless type(def) == 'table'
          warn "[Warn][Freya RepoManager] Skipping ##{v} (Malformed)"
          continue
        print "[Info][Freya RepoManager] Reading ##{v}"
        for k,v in pairs def
          print "[Info][Freya RepoManager] * Found #{k} as #{v}"
          if RepoList.Packages[k]
            if type(RepoList.Packages[k]) == 'table'
              table.insert RepoList.Packages[k], v
            else
              RepoList.Packages[k] = {RepoList.Packages[k], v}
          else
            RepoList.Packages[k] = v
      when 'string'
        switch select 3, v\find '^(%w+):'
          when 'github'
            print "[Info][Freya RepoManager] Reading #{v}"
            for k,v in pairs GitFetch.ReadRepo v\match("^github:(.+)$")
              print "[Info][Freya RepoManager] * Found #{k} as #{v}"
              if RepoList.Packages[k]
                if type(RepoList.Packages[k]) == 'table'
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
