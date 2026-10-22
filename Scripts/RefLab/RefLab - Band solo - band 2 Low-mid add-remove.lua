-- @noindex
-- RefLab: Band solo - band 2 Low-mid add-remove
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 32)
reaper.defer(function() end)
