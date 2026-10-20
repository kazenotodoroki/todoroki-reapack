-- @noindex
-- ChordMachineGun — borrowed scale chord 2 (degré 2 de la gamme de l'accord sélectionné)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
borrowedChordAction(2, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
