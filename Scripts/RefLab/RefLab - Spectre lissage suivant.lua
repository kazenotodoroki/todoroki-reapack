-- @noindex
-- RefLab : Spectre lissage suivant
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 64)
reaper.defer(function() end)
