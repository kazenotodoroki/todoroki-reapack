-- @noindex
-- RefLab : Retour au debut de boucle au Play on-off
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 68)
reaper.defer(function() end)
