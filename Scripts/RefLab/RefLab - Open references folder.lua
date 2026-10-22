-- @noindex
-- RefLab: opens <REAPER>/Data/references in the file explorer (also works without the Companion)
local SEP = package.config:sub(1, 1)
local DIR = reaper.GetResourcePath() .. SEP .. "Data" .. SEP .. "references"
reaper.RecursiveCreateDirectory(DIR, 0)
local os_name = reaper.GetOS():lower()
if SEP == "\\" then
  reaper.ExecProcess('explorer.exe "' .. DIR .. '"', -1)
elseif os_name:find("osx") or os_name:find("mac") then
  os.execute('open "' .. DIR .. '"')
else
  os.execute('xdg-open "' .. DIR .. '" &')
end
reaper.gmem_attach("RefLab")
reaper.gmem_write(1, 2)
reaper.defer(function() end)
