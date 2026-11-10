-- @noindex
-- ChordMachineGun 2 — next chord change mode (now - beat - bar - 2 bars)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

local m = cycleChangeMode(1)
reaper.Help_Set("ChordMachineGun 2: chord change — " .. m.name .. " (" .. m.hint .. ")", false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
