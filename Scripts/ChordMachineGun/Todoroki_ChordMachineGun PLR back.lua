-- @noindex
-- ChordMachineGun — revenir à l'accord d'ancrage PLR précédent
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
plrBack(true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
