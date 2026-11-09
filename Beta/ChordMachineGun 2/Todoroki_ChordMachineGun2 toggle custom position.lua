-- @noindex
-- ChordMachineGun 2 — toggle custom position
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
setCustomPositionEnabled(not getCustomPositionEnabled())
reaper.Help_Set("ChordMachineGun 2: custom position " .. (getCustomPositionEnabled() and ("on (" .. getCustomPosition() .. ")") or "off"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
