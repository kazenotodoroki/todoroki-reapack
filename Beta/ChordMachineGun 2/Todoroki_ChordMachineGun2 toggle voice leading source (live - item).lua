-- @noindex
-- ChordMachineGun 2 — toggle voice leading source (live / item)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

setReferenceSource(getReferenceSource() == "item" and "live" or "item")
reaper.Help_Set("ChordMachineGun 2: voice leading reference = " .. (getReferenceSource() == "item" and "MIDI item" or "live"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
