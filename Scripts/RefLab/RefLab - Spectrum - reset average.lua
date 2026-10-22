-- @noindex
-- RefLab: Spectrum - reset average
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 9)
reaper.defer(function() end)
