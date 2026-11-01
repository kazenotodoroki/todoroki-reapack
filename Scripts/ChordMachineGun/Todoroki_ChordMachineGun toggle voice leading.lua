-- @noindex
-- ChordMachineGun — toggle voice leading
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
setVoiceLeadingEnabled(not getVoiceLeadingEnabled())
reaper.Help_Set("ChordMachineGun: voice leading " .. (getVoiceLeadingEnabled() and "on" or "off"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
