-- @noindex
-- ChordMachineGun — higher scale note 5
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
higherScaleNoteAction(5)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
