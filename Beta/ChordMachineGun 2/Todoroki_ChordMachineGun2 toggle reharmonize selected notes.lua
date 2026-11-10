-- @noindex
-- ChordMachineGun 2 — toggle reharmonize selected notes
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

setSelectionMode(getSelectionMode() == "reharm" and "replace" or "reharm")
reaper.Help_Set("ChordMachineGun 2: selected notes are " .. (getSelectionMode() == "reharm" and "reharmonized (rhythm kept)" or "replaced"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
