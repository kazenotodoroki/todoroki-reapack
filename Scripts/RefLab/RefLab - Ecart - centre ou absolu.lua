-- @noindex
-- RefLab : Ecart - centre ou absolu
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 46)
reaper.defer(function() end)
