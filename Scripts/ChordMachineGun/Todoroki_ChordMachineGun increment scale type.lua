-- @noindex
-- ChordMachineGun — increment scale type
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
incrementScaleTypeAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
