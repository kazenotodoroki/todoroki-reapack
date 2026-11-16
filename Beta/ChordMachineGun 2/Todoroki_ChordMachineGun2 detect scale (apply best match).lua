-- @noindex
-- ChordMachineGun 2 — detect scale (apply best match)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

local d = detectScale(3)
local best = d.results[1]
if best then
  setScaleTonicAndType(best.tonic, best.scaleType)
  reaper.Help_Set("ChordMachineGun 2: " .. keyLabel(best.tonic, best.scaleType) .. " (" .. math.floor(best.fit * 100 + 0.5) .. "% of " .. d.source .. ")", false)
else
  reaper.Help_Set("ChordMachineGun 2: nothing to analyse (select notes or open a MIDI item)", false)
end
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
