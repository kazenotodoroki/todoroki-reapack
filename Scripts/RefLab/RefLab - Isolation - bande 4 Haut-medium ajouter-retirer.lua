-- @noindex
-- RefLab : Isolation - bande 4 Haut-medium ajouter-retirer
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 34)
reaper.defer(function() end)
