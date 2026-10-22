-- @noindex
-- RefLab: Spectrum - next smoothing
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 64)
reaper.defer(function() end)
