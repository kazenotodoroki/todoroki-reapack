-- @noindex
-- RefLab : Isolation - bande 3 Medium solo
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 43)
reaper.defer(function() end)
