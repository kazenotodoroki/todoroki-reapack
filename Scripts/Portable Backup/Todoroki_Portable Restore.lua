-- @noindex
-- Todoroki Portable Restore - bring back a backup made by Todoroki_Portable Backup (or the old .bat files)

local _, SELF = reaper.get_action_context()
local HERE = SELF:match("^(.*[\\/])")
local P = dofile(HERE .. "Todoroki_Portable_core.lua")
if not P.require_windows() then return end
P.install_icons(HERE)

local st = { sel = {}, avail = {}, sub = {} }
local src = P.last_backup()
local meta = ""
local relaunch = P.get("RELAUNCH", "1") == "1"

local function read_manifest(root)
  local f = io.open(P.join(root, P.MANIFEST), "r")
  if not f then return "" end
  local s = f:read("*a"); f:close()
  local created = s:match("created=([^\r\n]+)") or "?"
  local ver = s:match("reaper=([^\r\n]+)") or "?"
  return "Saved " .. created .. "  ·  REAPER " .. ver
end

local function scan()
  meta = ""
  for _, c in ipairs(P.COMPONENTS) do
    st.avail[c.id] = src ~= nil and P.available_backup(c, src) or false
    st.sel[c.id] = st.avail[c.id]                           -- All by default
    st.sub[c.id] = (c.kind == "ext") and ((st.avail[c.id] and "to " or "not in backup  ") .. P.live_path_label(c)) or nil
  end
  if src then meta = read_manifest(src) end
end
scan()

local function choose_recent()
  local list = P.list_backups()
  if #list == 0 then reaper.ShowMessageBox("No backup found in Temp, in the archive folder or in the recent list.", "Todoroki Portable", 0) return end
  local items = {}
  for i, b in ipairs(list) do
    items[i] = (b.date ~= "" and b.date or b.name) .. "   [" .. b.where .. "]   " .. b.path:gsub("|", "/")
    if i >= 30 then break end
  end
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local k = gfx.showmenu(table.concat(items, "|"))
  if k > 0 then src = list[k].path; scan() end
end

local function run()
  local n, reaper_side = P.count_sel(st)
  if n == 0 or not src then return false end

  local ops = {}
  for _, c in ipairs(P.COMPONENTS) do
    if st.sel[c.id] and st.avail[c.id] then
      if c.kind == "ini" then
        ops[#ops + 1] = { label = c.label, fn = "CopyIni", src = src, dst = P.RES }
      elseif c.kind == "rdir" then
        for _, d in ipairs(c.dirs) do
          if P.dir_exists(P.join(src, d)) then
            local xd = {}
            for _, x in ipairs(c.exclude or {}) do xd[#xd + 1] = P.join(src, x) end
            ops[#ops + 1] = { label = d, fn = "RoboDir", src = P.join(src, d), dst = P.join(P.RES, d), xd = xd }
          end
        end
      else
        ops[#ops + 1] = { label = c.label .. " (User)", fn = "RoboDir", src = P.join(src, c.plugin.bdir),
          dst = P.join(P.plugin_dir(c.plugin), "User") }
      end
    end
  end

  if reaper_side then
    local r = reaper.ShowMessageBox("REAPER will close now (you can still save open projects), the files are copied back, then "
      .. (relaunch and "REAPER relaunches." or "you can start REAPER again.") .. "\n\nContinue?", "Todoroki Portable - Restore", 1)
    if r ~= 1 then return false end
  end
  local ok = P.run_job("restore", ops, {
    title = "Restore",
    info = { "From: " .. src, "To:   " .. P.RES },
    wait_exe = reaper_side and P.reaper_exe() or nil,
    relaunch_exe = (reaper_side and relaunch) and P.reaper_exe() or nil,
  })
  if not ok then return false end
  P.set("RELAUNCH", relaunch and "1" or "0")
  if reaper_side then reaper.defer(function() reaper.Main_OnCommand(40004, 0) end) end   -- File: Quit REAPER
  return true
end

local ui = P.ui("Todoroki Portable - Restore", 640, 610)
local C = P.C

P.loop(function()
  if not ui:frame() then return false end
  ui:title("Restore", "Pick a backup, then what to bring back. Everything found is selected by default.")

  local x0, colw = 20, 290
  ui:header(x0, 70, ui.W - 40, "SOURCE")
  if ui:pathbox(x0, 96, ui.W - 270, 28, src or "No backup found - choose one") then
    local p = P.browse_folder("Backup to restore", src or P.archive_root())
    if p then src = p; scan() end
  end
  if ui:button(ui.W - 240, 96, 105, 28, "Recent  v") then choose_recent() end
  if ui:button(ui.W - 125, 96, 105, 28, "Browse...") then
    local p = P.browse_folder("Backup to restore", src or P.archive_root())
    if p then src = p; scan() end
  end
  if meta ~= "" then ui:text(x0, 130, meta, C.dim, 12) end

  P.draw_components(ui, st, x0, 154, colw)

  local x, y = x0 + colw + 20, 392
  ui:header(x, y, colw, "OPTIONS")
  y = y + 26
  if ui:checkbox(x, y, colw, "Relaunch REAPER when done", relaunch, true) then relaunch = not relaunch end
  local n, reaper_side = P.count_sel(st)
  if reaper_side then
    ui:text(x, y + 30, "REAPER items selected: REAPER closes", C.faint, 12)
    ui:text(x, y + 46, "during the restore.", C.faint, 12)
  else
    ui:text(x, y + 30, "No REAPER item: restored right away.", C.faint, 12)
  end

  local by = ui.H - 50
  ui:col(C.line); ui:rect(0, by - 12, ui.W, 1, true)
  ui:text(20, by + 8, n .. " item(s) selected", C.dim, 13)
  if ui:button(ui.W - 400, by, 110, 32, "Folders...") then
    if P.edit_settings() then scan() end
  end
  if ui:button(ui.W - 280, by, 110, 32, "Cancel") then return false end
  if ui:button(ui.W - 160, by, 140, 32, "Restore", "primary", n > 0) or (ui.char == 13 and n > 0) then
    if run() then return false end
  end
  gfx.update()
end)
