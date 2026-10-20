-- @noindex
-- ChordMachineGun — halve grid size
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

halveGridSize()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
