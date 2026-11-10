-- @noindex
-- ChordMachineGun 2 — toggle live pattern
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

setLivePattern(not getLivePattern())
reaper.Help_Set("ChordMachineGun 2: live pattern " .. (getLivePattern() and "on" or "off"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
