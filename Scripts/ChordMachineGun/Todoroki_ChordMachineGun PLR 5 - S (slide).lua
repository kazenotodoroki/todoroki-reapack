-- @noindex
-- ChordMachineGun — transformation néo-riemannienne S (slide) depuis l'ancrage courant
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
plrAction(5, true, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
