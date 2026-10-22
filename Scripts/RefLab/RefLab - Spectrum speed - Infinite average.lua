-- @noindex
-- RefLab: Spectrum speed - Infinite average
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 54)
reaper.defer(function() end)
