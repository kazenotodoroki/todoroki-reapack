-- @noindex
-- ChordMachineGun — toggle custom position
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
setCustomPositionEnabled(not getCustomPositionEnabled())
reaper.Help_Set("ChordMachineGun: custom position " .. (getCustomPositionEnabled() and ("on (" .. getCustomPosition() .. ")") or "off"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
