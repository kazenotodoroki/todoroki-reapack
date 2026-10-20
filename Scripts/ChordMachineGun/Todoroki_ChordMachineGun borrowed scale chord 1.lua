-- @noindex
-- ChordMachineGun — borrowed scale chord 1 (degré 1 de la gamme de l'accord sélectionné)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
borrowedChordAction(1, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
