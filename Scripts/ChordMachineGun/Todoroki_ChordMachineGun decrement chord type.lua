-- @noindex
-- ChordMachineGun — decrement chord type
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
decrementChordTypeAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
