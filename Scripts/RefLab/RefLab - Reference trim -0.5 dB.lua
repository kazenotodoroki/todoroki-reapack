-- @noindex
-- RefLab: Reference trim -0.5 dB
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 66)
reaper.defer(function() end)
