-- @noindex
-- ChordMachineGun 2 — clear colors
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

clearColors()
reaper.Help_Set("ChordMachineGun 2: colors cleared", false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
