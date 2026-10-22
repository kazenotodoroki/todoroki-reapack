-- @noindex
-- RefLab : Trim reference 0 dB
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 67)
reaper.defer(function() end)
