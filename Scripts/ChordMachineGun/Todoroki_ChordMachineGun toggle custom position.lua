-- @noindex
-- ChordMachineGun — toggle custom position
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
setCustomPositionEnabled(not getCustomPositionEnabled())
reaper.Help_Set("ChordMachineGun : position personnalisée " .. (getCustomPositionEnabled() and ("activée (" .. getCustomPosition() .. ")") or "désactivée"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
