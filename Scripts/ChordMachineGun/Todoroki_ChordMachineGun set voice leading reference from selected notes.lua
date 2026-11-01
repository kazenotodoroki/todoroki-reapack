-- @noindex
-- ChordMachineGun — set voice leading reference from selected notes
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
if not setReferenceFromSelectedNotes() then reaper.Help_Set("ChordMachineGun: no notes selected", false) end
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
