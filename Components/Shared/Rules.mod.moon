--//
--// * Rules for Freya
--// | Rules provide a central way to pre-emptively and non-destructively check
--// | whether an action can take place, using try/contest/capture/deny APIs
--// | similarly to permissions and intents.
--//

-- Try: Check if you can do a rule, returning true if nothing denies it on
--      contesting. Passive, performs no actions.

-- Contest: Allows you to set a callback function to be run when the rule is
--          being checked, so that you can choose to deny the rule.

-- Umpire: Takes a function as a mutator wrapper, allowing it to preprocess
--          the arguments and prevent propagation. Designed to act as a
--          validator, to prevent bad tries from propagating to naive contesting
--          callbacks.
--          Currently not included because I cba

-- Deny: Automatically deny the rule and stop it from propagating for a given
--       amount of time.

-- ? Consider allowing automatic callbacks for when a rule is tried and valid
--   via Intent names.

local ^
now = tick
local IntentService = require script.Parent.Intents

--CaptureState = {}
TimeState = {}
DenyState = {}
ContestState = {}

Try = (...) =>
  -- self = rule
  --  if CaptureState[@]
  --    CaptureState[@](...)
  if (TimeState[@] or 0) < now()
    DenyState[@] = false
    -- Contest
    for f in *(ContestState[@] or {})
      f(...)
  unless DenyState[@]
    for i in *(IntentState[@] or {})
      IntentService.Whisper i, ...
    return true
  return false

Contest = (f) =>
  ContestState[@] or= {}
  table.insert ContestState[@], f
  ->
    rem = false
    for i=1, #ContestState
      v = ContestState[i]
      if rem
        ContestState[i-1] = v
        continue
      if v == f
        ContestState[i] = nil
        rem = true

--Umpire = (f) =>

Deny = (t=0) =>
  ct = TimeState[@] or 0
  ct = math.max ct, now()+t
  TimeState[@] = ct
  DenyState[@] = true

Listen = (i) =>
  IntentState[@] or= {}
  table.insert IntentState[@], i

Clean = =>
  -- Release everything!
  --CaptureState[@] = nil
  TimeState[@] = nil
  DenyState[@] = nil
  ContestState[@] = nil

np = newproxy true
this = {
  :Deny
  :Contest
  :Listen
  :Clean
  :Try
}
for k,v in pairs this
  this[k] = (...) ->
    return v ... if ... ~= np else v select 2, ...
with this
  .Attempt = .Try
  .Check = .Try
  --.Capture = .Umpire
  .Watch = .Listen
  .Clear = .Clean

with getmetatable np
  .__metatable = "Locked metatable: Freya rules"
  .__index = this
  .__tostring = -> "Freya Rules"

return np
