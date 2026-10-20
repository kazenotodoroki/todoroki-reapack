-- @noindex
-- ChordMachineGun — decrement chord inversion
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
decrementChordInversionAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
