-- @noindex
-- RefLab : Sortie - Gauche
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 26)
reaper.defer(function() end)
