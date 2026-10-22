-- @noindex
-- RefLab: spectrum speed - Slow
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 52)
reaper.defer(function() end)
