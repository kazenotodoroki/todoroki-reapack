-- @noindex
-- RefLab: Band solo - band 3 Mid add-remove
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 33)
reaper.defer(function() end)
