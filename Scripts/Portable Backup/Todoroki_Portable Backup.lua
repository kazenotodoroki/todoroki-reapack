-- @description Todoroki Portable Backup - save, restore and clean the settings of a portable REAPER
-- @author Todoroki
-- @version 1.0
-- @changelog
--   - First version: replaces backup_reaper.bat / save_reaper.bat / restore_reaper.bat
--   - Pick what to save or restore (all selected by default) and where
--   - Includes RefLab references, RS Trig library and the User folders of NAM, Vital, Decent Sampler
--   - Restore waits for REAPER to quit, copies everything back, then relaunches REAPER
--   - Clean backups: delete old temporary / archived backups
--   - Minimal square toolbar icons (100 / 150 / 200 %), installed into Data/toolbar_icons on first run
-- @provides
--   [main] .
--   [main] Todoroki_Portable Restore.lua
--   [main] Todoroki_Portable Clean backups.lua
--   [nomain] Todoroki_Portable_core.lua
--   [nomain] Todoroki_Portable Backup.png
--   [nomain] Todoroki_Portable Backup (150).png
--   [nomain] Todoroki_Portable Backup (200).png
--   [nomain] Todoroki_Portable Restore.png
--   [nomain] Todoroki_Portable Restore (150).png
--   [nomain] Todoroki_Portable Restore (200).png
--   [nomain] Todoroki_Portable Clean backups.png
--   [nomain] Todoroki_Portable Clean backups (150).png
--   [nomain] Todoroki_Portable Clean backups (200).png
--   Todoroki_Portable README.md
-- @about
--   # Todoroki Portable Backup
--
--   Save / restore / clean the configuration of a portable REAPER (Windows), for updates
--   ("backup, overwrite the install, restore") and for archives.
--
--   - **Todoroki_Portable Backup**: choose components (All by default) and destination
--     (Temporary for an update, Archive, or any folder)
--   - **Todoroki_Portable Restore**: choose a backup and the components to bring back;
--     REAPER closes, files are restored, REAPER relaunches
--   - **Todoroki_Portable Clean backups**: delete old backups
--
--   Also covers RefLab references (`Data/references`), the RS Trig library (`Data/RSampler*`)
--   and the `User` folders of Neural Amp Modeler, Vital and Decent Sampler
--   (folders set with **Folders...**, default `<drive>\NAM`, `<drive>\Vital` and `<drive>\DS`).
--
--   Toolbar icons are copied into `Data/toolbar_icons` on first run.
--   Copies run in a PowerShell window (robocopy): REAPER never freezes.

local _, SELF = reaper.get_action_context()
local HERE = SELF:match("^(.*[\\/])")
local P = dofile(HERE .. "Todoroki_Portable_core.lua")
if not P.require_windows() then return end
P.install_icons(HERE)

local st = { sel = {}, avail = {}, sub = {} }
local function scan()
  for _, c in ipairs(P.COMPONENTS) do
    st.avail[c.id] = P.available_live(c)
    if c.kind == "ext" then
      st.sub[c.id] = (st.avail[c.id] and "" or "not found  ") .. P.live_path_label(c)
    else
      st.sub[c.id] = nil
    end
  end
end
scan()
for _, c in ipairs(P.COMPONENTS) do st.sel[c.id] = st.avail[c.id] end   -- All by default

local mode = P.get("DEST_MODE", "temp")
local custom = P.get("CUSTOM_DIR", nil)
local quit_first = false
local TS = P.timestamp()

local function destination()
  if mode == "archive" then return P.join(P.archive_root(), "REAPER_Save_" .. TS) end
  if mode == "custom" then return custom and P.join(custom, "REAPER_Save_" .. TS) or nil end
  return P.join(P.TEMP, "REAPER_Backup_" .. TS)
end

local function run()
  local dst = destination()
  if not dst then reaper.ShowMessageBox("Choose a destination folder first.", "Todoroki Portable", 0) return false end
  local n, reaper_side = P.count_sel(st)
  if n == 0 then return false end

  local ops, ids = {}, {}
  for _, c in ipairs(P.COMPONENTS) do
    if st.sel[c.id] and st.avail[c.id] then
      ids[#ids + 1] = c.id
      if c.kind == "ini" then
        ops[#ops + 1] = { label = c.label, fn = "CopyIni", src = P.RES, dst = dst }
      elseif c.kind == "rdir" then
        for _, d in ipairs(c.dirs) do
          if P.dir_exists(P.join(P.RES, d)) then
            local xd = {}
            for _, x in ipairs(c.exclude or {}) do xd[#xd + 1] = P.join(P.RES, x) end
            ops[#ops + 1] = { label = d, fn = "RoboDir", src = P.join(P.RES, d), dst = P.join(dst, d), xd = xd }
          end
        end
      else
        local src = P.join(P.plugin_dir(c.plugin), "User")
        ops[#ops + 1] = { label = c.label .. " (User)", fn = "RoboDir", src = src, dst = P.join(dst, c.plugin.bdir) }
      end
    end
  end

  local wait = quit_first and reaper_side
  local ok = P.run_job("backup", ops, {
    title = "Backup",
    info = { "From: " .. P.RES, "To:   " .. dst },
    wait_exe = wait and P.reaper_exe() or nil,
    mkdir = dst,
    manifest = { path = P.join(dst, P.MANIFEST), text = "created=" .. os.date("%Y-%m-%d %H:%M:%S") ..
      "\nreaper=" .. reaper.GetAppVersion() .. "\nsource=" .. P.RES .. "\ncomponents=" .. table.concat(ids, ",") },
    footer = { "Backup folder: " .. dst },
  })
  if not ok then return false end
  P.remember(dst)
  P.set("DEST_MODE", mode)
  if custom then P.set("CUSTOM_DIR", custom) end
  if wait then reaper.defer(function() reaper.Main_OnCommand(40004, 0) end) end   -- File: Quit REAPER
  return true
end

local ui = P.ui("Todoroki Portable - Backup", 640, 545)
local C = P.C

P.loop(function()
  if not ui:frame() then return false end
  ui:title("Backup", "Pick what to save and where. Everything is selected by default.")

  local x0, colw = 20, 290
  P.draw_components(ui, st, x0, 72, colw)

  -- destination (right column, under the plugin list)
  local x, y = x0 + colw + 20, 306
  ui:header(x, y, colw, "DESTINATION")
  y = y + 26
  if ui:radio(x, y, colw, "Temporary  (before a REAPER update)", mode == "temp") then mode = "temp" end
  y = y + 22
  if ui:radio(x, y, colw, "Archive", mode == "archive") then mode = "archive" end
  y = y + 22
  if ui:radio(x, y, colw, "Custom folder...", mode == "custom") then
    mode = "custom"
    if not custom then custom = P.browse_folder("Backup destination", P.DRIVE .. "\\") end
  end
  y = y + 28
  if ui:pathbox(x, y, colw, 26, destination() or "Click to choose a folder") then
    local p = P.browse_folder("Backup destination", custom or P.archive_root())
    if p then custom = p; mode = "custom" end
  end
  y = y + 36
  if ui:checkbox(x, y, colw, "Close REAPER before copying", quit_first, true) then quit_first = not quit_first end
  ui:text(x + 20, y + 21, "captures unsaved preferences, ready to update", C.faint, 12)

  -- bottom bar
  local by = ui.H - 50
  ui:col(C.line); ui:rect(0, by - 12, ui.W, 1, true)
  local n = P.count_sel(st)
  ui:text(20, by + 8, n .. " item(s) selected", C.dim, 13)
  if ui:button(ui.W - 400, by, 110, 32, "Folders...") then
    if P.edit_settings() then scan() end
  end
  if ui:button(ui.W - 280, by, 110, 32, "Cancel") then return false end
  if ui:button(ui.W - 160, by, 140, 32, "Backup", "primary", n > 0) or (ui.char == 13 and n > 0) then
    if run() then return false end
  end
  gfx.update()
end)
