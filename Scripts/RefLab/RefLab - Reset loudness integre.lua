-- @noindex
-- RefLab : Reset loudness integre
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 6)
reaper.defer(function() end)
