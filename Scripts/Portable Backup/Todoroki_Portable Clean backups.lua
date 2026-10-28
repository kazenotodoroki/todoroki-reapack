-- @noindex
-- Todoroki Portable Clean backups - delete old backups (Temp, archive folder, custom folders)

local _, SELF = reaper.get_action_context()
local HERE = SELF:match("^(.*[\\/])")
local P = dofile(HERE .. "Todoroki_Portable_core.lua")
if not P.require_windows() then return end
P.install_icons(HERE)

local list, sel, scroll = {}, {}, 0
local function scan() list = P.list_backups(); sel = {}; scroll = 0 end
scan()

local function safe(p)
  local n = p:gsub("[\\/]+$", ""):lower()
  if n == P.RES:lower() or n:match("^%a:$") or #n < 6 then return false end
  return P.is_backup_dir(p)
end

local function run()
  local paths = {}
  for i, b in ipairs(list) do if sel[i] and safe(b.path) then paths[#paths + 1] = b.path end end
  if #paths == 0 then return false end
  local r = reaper.ShowMessageBox("Permanently delete " .. #paths .. " backup folder(s)?\nThis cannot be undone.",
    "Todoroki Portable - Clean backups", 1)
  if r ~= 1 then return false end
  local extra = {}
  for _, p in ipairs(paths) do
    local q = "'" .. p:gsub("'", "''") .. "'"
    extra[#extra + 1] = "Step " .. q
    extra[#extra + 1] = "try { Remove-Item -LiteralPath " .. q .. " -Recurse -Force -ErrorAction Stop } catch { Fail $_.Exception.Message }"
  end
  -- leftovers of interrupted jobs
  extra[#extra + 1] = "Get-ChildItem -LiteralPath $env:TEMP -Filter 'todoroki_portable_*.ps1' -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -ne $PSCommandPath } | Remove-Item -Force -ErrorAction SilentlyContinue"
  return P.run_job("clean", {}, { title = "Clean backups", info = { #paths .. " folder(s) to delete" }, extra = extra })
end

local ui = P.ui("Todoroki Portable - Clean backups", 640, 520)
local C = P.C
local ROW = 24

P.loop(function()
  if not ui:frame() then return false end
  ui:title("Clean backups", "Select the backups to delete. Nothing is selected by default.")

  local x0, w = 20, ui.W - 40
  local top, bottom = 104, ui.H - 74
  ui:header(x0, 70, w, "BACKUPS  (" .. #list .. ")")

  local nsel = 0
  for i = 1, #list do if sel[i] then nsel = nsel + 1 end end

  local visible = math.floor((bottom - top) / ROW)
  local maxscroll = math.max(0, #list - visible)
  if ui.wheel ~= 0 and ui:over(x0, top, w, bottom - top) then
    scroll = math.max(0, math.min(maxscroll, scroll - (ui.wheel > 0 and 2 or -2)))
  end

  if #list == 0 then
    ui:text(x0, top + 6, "No backup found in Temp, in " .. P.archive_root() .. " or in the recent list.", C.faint, 13, nil, w)
  end
  for r = 1, visible do
    local i = r + scroll
    local b = list[i]
    if not b then break end
    local y = top + (r - 1) * ROW
    if ui:checkbox(x0 + 4, y + 1, w - 8, b.date ~= "" and b.date or b.name, sel[i], true,
      "[" .. b.where .. "]  " .. b.path) then sel[i] = not sel[i] end
  end
  if maxscroll > 0 then
    local th = (bottom - top) * visible / #list
    local ty = top + (bottom - top - th) * scroll / maxscroll
    ui:col(C.line); ui:rect(ui.W - 16, ty, 3, th, true)
  end

  local by = ui.H - 50
  ui:col(C.line); ui:rect(0, by - 12, ui.W, 1, true)
  if ui:button(20, by, 110, 32, "Select all") then for i = 1, #list do sel[i] = true end end
  if ui:button(140, by, 110, 32, "Temp only") then for i, b in ipairs(list) do sel[i] = (b.where == "Temp") end end
  if ui:button(ui.W - 280, by, 110, 32, "Cancel") then return false end
  if ui:button(ui.W - 160, by, 140, 32, nsel > 0 and ("Delete " .. nsel) or "Delete", "danger", nsel > 0) then
    if run() then return false end
  end
  gfx.update()
end)
