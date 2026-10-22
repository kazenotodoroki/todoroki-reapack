-- @noindex
-- RefLab: loudness match - Short-term
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 62)
reaper.defer(function() end)
