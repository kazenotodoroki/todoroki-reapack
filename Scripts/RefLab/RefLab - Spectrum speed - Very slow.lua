-- @noindex
-- RefLab: Spectrum speed - Very slow
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 53)
reaper.defer(function() end)
