-- @noindex
-- Todoroki Portable Clear user data - empty your personal data so the next person gets a clean REAPER
-- (then they run Todoroki_Portable Restore with their own backup)

local _, SELF = reaper.get_action_context()
local HERE = SELF:match("^(.*[\\/])")
local P = dofile(HERE .. "Todoroki_Portable_core.lua")
if not P.require_windows() then return end
P.install_icons(HERE)

local HERE_DIR = HERE:gsub("[\\/]+$", ""):gsub("/", "\\")

-- shared tools: kept unless ticked by hand (so the next person still has ReaPack and these scripts)
local TOOLS = { Effects = true, LangPack = true, ReaPack = true, Scripts = true, UserPlugins = true }

local st = { sel = {}, avail = {}, sub = {} }
local function scan()
  for _, c in ipairs(P.COMPONENTS) do
    st.avail[c.id] = P.available_live(c)
    if c.kind == "ext" then
      st.sub[c.id] = (st.avail[c.id] and "" or "not found  ") .. P.live_path_label(c)
    elseif TOOLS[c.id] then
      st.sub[c.id] = st.avail[c.id] and "installed tools" or "not found"
    else
      st.sub[c.id] = nil
    end
  end
end
scan()
for _, c in ipairs(P.COMPONENTS) do st.sel[c.id] = st.avail[c.id] and not TOOLS[c.id] end

local save_first = P.get("CLEAR_SAVE", "1") == "1"
local relaunch = P.get("RELAUNCH", "1") == "1"
local TS = P.timestamp()
local function save_dir() return P.join(P.archive_root(), "REAPER_Save_" .. TS .. "_before_clear") end

local function clear_ops()
  local ops = {}
  for _, c in ipairs(P.COMPONENTS) do
    if st.sel[c.id] and st.avail[c.id] then
      if c.kind == "ini" then
        ops[#ops + 1] = { label = "Clear " .. c.label, fn = "ClearIni", dst = P.RES,
          keep_reapack = not st.sel.ReaPack, all_scr = not st.sel.Scripts }
      elseif c.kind == "rdir" then
        for _, d in ipairs(c.dirs) do
          local keep, keep_like = {}, {}
          for _, x in ipairs(c.exclude or {}) do keep[#keep + 1] = P.join(P.RES, x) end
          if d == "Scripts" then keep[#keep + 1] = HERE_DIR end                 -- these tools themselves
          if d == "UserPlugins" then keep_like[#keep_like + 1] = "reaper_reapack*" end
          if P.dir_exists(P.join(P.RES, d)) then
            ops[#ops + 1] = { label = "Clear " .. d, fn = "ClearDir", dst = P.join(P.RES, d), keep = keep, keep_like = keep_like }
          end
        end
      else
        ops[#ops + 1] = { label = "Clear " .. c.label .. " (User)", fn = "ClearDir", dst = P.join(P.plugin_dir(c.plugin), "User") }
      end
    end
  end
  return ops
end

local function run()
  local n, reaper_side = P.count_sel(st)
  if n == 0 then return false end
  for _, c in ipairs(P.COMPONENTS) do
    if st.sel[c.id] and st.avail[c.id] and c.kind ~= "ext" then reaper_side = true end
  end

  local msg = "Delete the content of " .. n .. " item(s)?\n\n"
  if save_first then
    msg = msg .. "A copy is saved first to:\n" .. save_dir() .. "\n\n"
  else
    msg = msg .. "No copy will be saved: this cannot be undone.\n\n"
  end
  if reaper_side then msg = msg .. "REAPER closes now (save your projects), the data is cleared, then " ..
    (relaunch and "REAPER relaunches clean." or "you can start REAPER again.") end
  local r = reaper.ShowMessageBox(msg, "Todoroki Portable - Clear user data", 1)
  if r ~= 1 then return false end

  local ops, opts = {}, { title = "Clear user data", info = { "REAPER: " .. P.RES } }
  if save_first then
    local dst = save_dir()
    local b, ids = P.backup_ops(st, dst)
    opts.mkdir = dst
    ops = b
    opts.manifest = { path = P.join(dst, P.MANIFEST), text = P.manifest_text(ids) }
    opts.info[#opts.info + 1] = "Copy:   " .. dst
    -- the manifest goes in right after the copy, before anything is deleted
    ops[#ops + 1] = { label = "Write manifest", fn = "Raw",
      raw = "Set-Content -LiteralPath '" .. opts.manifest.path:gsub("'", "''") .. "' -Value '" ..
        opts.manifest.text:gsub("'", "''") .. "' -Encoding UTF8" }
    opts.manifest = nil
    -- never delete anything if the copy failed
    ops[#ops + 1] = { label = "Check copy", fn = "Raw", raw =
      "if ($script:errors -gt 0) { Write-Host ''; Write-Host '  The copy failed: nothing was deleted.' -ForegroundColor Red; Read-Host '  Press Enter to close' | Out-Null; exit 1 }" }
    P.history_add(dst)
  end
  for _, o in ipairs(clear_ops()) do ops[#ops + 1] = o end
  opts.wait_exe = reaper_side and P.reaper_exe() or nil
  opts.relaunch_exe = (reaper_side and relaunch) and P.reaper_exe() or nil
  opts.footer = { "Ready for the next person: Todoroki_Portable Restore brings back their own backup." }

  if not P.run_job("clear", ops, opts) then return false end
  P.forget_last()                                        -- next Restore does not preselect your backup
  P.set("CLEAR_SAVE", save_first and "1" or "0")
  P.set("RELAUNCH", relaunch and "1" or "0")
  if reaper_side then reaper.defer(function() reaper.Main_OnCommand(40004, 0) end) end   -- File: Quit REAPER
  return true
end

local ui = P.ui("Todoroki Portable - Clear user data", 640, 600)
local C = P.C

P.loop(function()
  if not ui:frame() then return false end
  ui:title("Clear user data", "Empty your personal data before handing this REAPER to someone else.")

  local x0, colw = 20, 290
  P.draw_components(ui, st, x0, 72, colw)

  local x, y = x0 + colw + 20, 330
  ui:header(x, y, colw, "OPTIONS")
  y = y + 26
  if ui:checkbox(x, y, colw, "Save a copy to the archive first", save_first, true) then save_first = not save_first end
  ui:text(x + 20, y + 21, P.archive_root(), save_first and C.faint or C.danger, 12, nil, colw - 20)
  y = y + 46
  if ui:checkbox(x, y, colw, "Relaunch REAPER when done", relaunch, true) then relaunch = not relaunch end
  y = y + 30
  ui:text(x, y, "Always kept: portable mode, ReaPack and", C.faint, 12)
  ui:text(x, y + 16, "these Todoroki_Portable actions.", C.faint, 12)

  local by = ui.H - 50
  ui:col(C.line); ui:rect(0, by - 12, ui.W, 1, true)
  local n = P.count_sel(st)
  ui:text(20, by + 8, n .. " item(s) to clear", C.dim, 13)
  if ui:button(ui.W - 400, by, 110, 32, "Folders...") then
    if P.edit_settings() then scan() end
  end
  if ui:button(ui.W - 280, by, 110, 32, "Cancel") then return false end
  if ui:button(ui.W - 160, by, 140, 32, "Clear", "danger", n > 0) then
    if run() then return false end
  end
  gfx.update()
end)
