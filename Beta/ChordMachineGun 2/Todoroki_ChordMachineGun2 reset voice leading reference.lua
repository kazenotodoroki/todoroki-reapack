-- @noindex
-- ChordMachineGun 2 — reset voice leading reference
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

resetVoiceLeadingReference()
reaper.Help_Set("ChordMachineGun 2: voice leading reference cleared", false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
