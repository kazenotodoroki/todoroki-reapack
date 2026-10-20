-- @noindex
-- RefLab : demande au Todoroki Companion de relire le dossier des references
reaper.gmem_attach("RefLab")
reaper.gmem_write(1, 2)
reaper.defer(function() end)
