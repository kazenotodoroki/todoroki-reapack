-- @noindex
-- ChordMachineGun — higher scale note 2
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
higherScaleNoteAction(2)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
