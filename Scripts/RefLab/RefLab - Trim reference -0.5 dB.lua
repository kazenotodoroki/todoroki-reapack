-- @noindex
-- RefLab : Trim reference -0.5 dB
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 66)
reaper.defer(function() end)
