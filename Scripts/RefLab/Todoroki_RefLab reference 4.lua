-- @noindex
-- RefLab: reference 4
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 14)
reaper.defer(function() end)
