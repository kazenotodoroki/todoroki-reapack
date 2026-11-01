-- @noindex
-- ChordMachineGun — toggle MIDI channel per voice
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
setSplitChannels(not getSplitChannels())
reaper.Help_Set("ChordMachineGun: one channel per voice " .. (getSplitChannels() and "on" or "off"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
