-- @noindex
-- RefLab: Band solo - band 2 Low-mid solo
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 42)
reaper.defer(function() end)
