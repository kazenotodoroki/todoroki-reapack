-- @noindex
-- RefLab : Isolation - bande 2 Bas-medium ajouter-retirer
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 32)
reaper.defer(function() end)
