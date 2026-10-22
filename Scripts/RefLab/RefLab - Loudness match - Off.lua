-- @noindex
-- RefLab: Loudness match - Off
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 60)
reaper.defer(function() end)
