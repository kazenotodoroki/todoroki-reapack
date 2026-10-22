-- @noindex
-- RefLab : Isolation - bande 2 Bas-medium solo
-- Assignable a une touche ou un controleur MIDI depuis la liste d'actions.
reaper.gmem_attach("RefLab")
reaper.gmem_write(2, 42)
reaper.defer(function() end)
