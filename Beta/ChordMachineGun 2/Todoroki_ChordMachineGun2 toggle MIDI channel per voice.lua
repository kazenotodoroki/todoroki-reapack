-- @noindex
-- ChordMachineGun 2 — toggle MIDI channel per voice
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
setSplitChannels(not getSplitChannels())
reaper.Help_Set("ChordMachineGun 2: one channel per voice " .. (getSplitChannels() and "on" or "off"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
