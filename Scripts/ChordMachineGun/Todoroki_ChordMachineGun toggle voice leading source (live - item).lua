-- @noindex
-- ChordMachineGun — toggle voice leading source (live / item)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

setReferenceSource(getReferenceSource() == "item" and "live" or "item")
reaper.Help_Set("ChordMachineGun : référence de conduite de voix = " .. (getReferenceSource() == "item" and "item MIDI" or "live"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
