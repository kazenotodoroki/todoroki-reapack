-- @noindex
-- RefLab : Reference 2
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 12)
reaper.defer(function() end)
