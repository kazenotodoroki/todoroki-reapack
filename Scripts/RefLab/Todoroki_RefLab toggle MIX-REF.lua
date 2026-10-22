-- @noindex
-- RefLab: toggle MIX-REF
-- Can be mapped to a key or a MIDI controller from the action list.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 1)
reaper.defer(function() end)
