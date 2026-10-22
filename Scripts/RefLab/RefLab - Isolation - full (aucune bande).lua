-- @noindex
-- RefLab : Isolation - full (aucune bande)
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 40)
reaper.defer(function() end)
