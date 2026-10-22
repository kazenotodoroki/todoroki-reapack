-- @noindex
-- RefLab: reference trim +0.5 dB
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 65)
reaper.defer(function() end)
