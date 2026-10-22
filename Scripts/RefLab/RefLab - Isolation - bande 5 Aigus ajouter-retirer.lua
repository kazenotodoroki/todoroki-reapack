-- @noindex
-- RefLab : Isolation - bande 5 Aigus ajouter-retirer
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 35)
reaper.defer(function() end)
