-- @noindex
-- RefLab : Basculer boucle
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 4)
reaper.defer(function() end)
