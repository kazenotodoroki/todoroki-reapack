-- @noindex
-- ChordMachineGun 2 — set voice leading reference from selected notes
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
if not setReferenceFromSelectedNotes() then reaper.Help_Set("ChordMachineGun 2: no notes selected", false) end
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
