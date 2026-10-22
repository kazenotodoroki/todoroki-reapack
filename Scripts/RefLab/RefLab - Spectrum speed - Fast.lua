-- @noindex
-- RefLab: Spectrum speed - Fast
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 50)
reaper.defer(function() end)
