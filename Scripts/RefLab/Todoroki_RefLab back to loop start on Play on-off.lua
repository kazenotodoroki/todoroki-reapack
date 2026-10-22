-- @noindex
-- RefLab: back to loop start on Play on-off
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 68)
reaper.defer(function() end)
