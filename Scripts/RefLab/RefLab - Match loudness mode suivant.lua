-- @noindex
-- RefLab : Match loudness mode suivant
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 7)
reaper.defer(function() end)
