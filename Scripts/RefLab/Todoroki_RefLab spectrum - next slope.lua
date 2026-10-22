-- @noindex
-- RefLab: spectrum - next slope
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 63)
reaper.defer(function() end)
