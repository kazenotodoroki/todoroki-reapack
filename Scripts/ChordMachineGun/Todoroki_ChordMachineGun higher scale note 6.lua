-- @noindex
-- ChordMachineGun — higher scale note 6
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
higherScaleNoteAction(6)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
