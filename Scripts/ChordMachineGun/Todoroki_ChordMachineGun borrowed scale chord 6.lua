-- @noindex
-- ChordMachineGun — borrowed scale chord 6 (degré 6 de la gamme de l'accord sélectionné)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
borrowedChordAction(6, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
