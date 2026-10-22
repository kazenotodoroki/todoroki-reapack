-- @noindex
-- RefLab: output - Left
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 26)
reaper.defer(function() end)
