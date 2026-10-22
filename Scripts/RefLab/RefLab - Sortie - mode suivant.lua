-- @noindex
-- RefLab : Sortie - mode suivant
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 22)
reaper.defer(function() end)
