-- @noindex
-- RefLab: band solo - band 1 Low add-remove
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 31)
reaper.defer(function() end)
