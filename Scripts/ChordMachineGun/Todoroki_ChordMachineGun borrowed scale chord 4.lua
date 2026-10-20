-- @noindex
-- ChordMachineGun — borrowed scale chord 4 (degré 4 de la gamme de l'accord sélectionné)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
borrowedChordAction(4, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
