-- @noindex
-- RefLab: Output - next mode
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 22)
reaper.defer(function() end)
