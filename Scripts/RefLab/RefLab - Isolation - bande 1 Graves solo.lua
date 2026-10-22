-- @noindex
-- RefLab : Isolation - bande 1 Graves solo
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 41)
reaper.defer(function() end)
