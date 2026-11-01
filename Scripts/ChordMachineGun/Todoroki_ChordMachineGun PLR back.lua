-- @noindex
-- ChordMachineGun — go back to the previous PLR anchor chord
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
plrBack(true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
