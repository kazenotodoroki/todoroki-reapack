-- @noindex
-- RefLab : Isolation - bande 3 Medium ajouter-retirer
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 33)
reaper.defer(function() end)
