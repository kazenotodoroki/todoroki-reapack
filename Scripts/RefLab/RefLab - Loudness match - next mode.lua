-- @noindex
-- RefLab: Loudness match - next mode
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 7)
reaper.defer(function() end)
