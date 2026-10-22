-- @noindex
-- RefLab : Isolation - bande 1 Graves ajouter-retirer
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 31)
reaper.defer(function() end)
