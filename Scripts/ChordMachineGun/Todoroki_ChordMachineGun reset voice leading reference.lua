-- @noindex
-- ChordMachineGun — reset voice leading reference
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

resetVoiceLeadingReference()
reaper.Help_Set("ChordMachineGun : référence de conduite de voix effacée", false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
