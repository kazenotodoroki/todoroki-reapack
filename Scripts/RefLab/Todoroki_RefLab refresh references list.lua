-- @noindex
-- RefLab: asks the Todoroki Companion to read the references folder again
reaper.gmem_attach("RefLab")
reaper.gmem_write(1, 2)
reaper.defer(function() end)
