-- @noindex
-- Todoroki Portable Backup - shared core (components, settings, PowerShell runner, gfx UI)
-- Loaded with dofile() by the Todoroki_Portable actions. Pure Lua, no extension required
-- (js_ReaScriptAPI is used for the folder browser when installed).

local M = {}

M.SEP  = "\\"
M.RES  = reaper.GetResourcePath()
M.EXT  = "Todoroki_Portable"
M.MANIFEST = "Todoroki_Portable.manifest"
M.IS_WIN = reaper.GetOS():find("Win") ~= nil
M.DRIVE = M.RES:match("^(%a:)") or "C:"
M.TEMP = (os.getenv("TEMP") or os.getenv("TMP") or (M.RES .. "\\temp")):gsub("[\\/]+$", "")
M.LAST_FILE = M.TEMP .. "\\todoroki_portable_last_backup.txt"

----------------------------------------------------------------------------------------------
-- small helpers
----------------------------------------------------------------------------------------------
function M.join(...)
  local t = {}
  for _, p in ipairs({ ... }) do
    if p and p ~= "" then t[#t + 1] = (#t == 0) and p:gsub("[\\/]+$", "") or p:gsub("^[\\/]+", ""):gsub("[\\/]+$", "") end
  end
  return (table.concat(t, "\\"):gsub("/", "\\"))
end

function M.dir_exists(p)
  if not p or p == "" then return false end
  reaper.EnumerateSubdirectories(p, -1)        -- clear cache
  reaper.EnumerateFiles(p, -1)
  if reaper.EnumerateSubdirectories(p, 0) or reaper.EnumerateFiles(p, 0) then return true end
  local ok, _, code = os.rename(p, p)            -- empty folder
  return ok or code == 13
end

function M.file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close() return true end
  return false
end

function M.has_ini(p)
  reaper.EnumerateFiles(p, -1)
  local i = 0
  while true do
    local f = reaper.EnumerateFiles(p, i)
    if not f then return false end
    if f:lower():match("%.ini$") then return true end
    i = i + 1
  end
end

function M.subdirs(p)
  local t = {}
  reaper.EnumerateSubdirectories(p, -1)
  local i = 0
  while true do
    local d = reaper.EnumerateSubdirectories(p, i)
    if not d then break end
    t[#t + 1] = d
    i = i + 1
  end
  return t
end

function M.get(key, default)
  local v = reaper.GetExtState(M.EXT, key)
  if v == nil or v == "" then return default end
  return v
end

function M.set(key, val) reaper.SetExtState(M.EXT, key, tostring(val or ""), true) end

function M.timestamp() return os.date("%Y%m%d_%H%M%S") end

function M.pretty_ts(name)
  local y, mo, d, h, mi = (name or ""):match("(%d%d%d%d)(%d%d)(%d%d)_(%d%d)(%d%d)")
  if not y then return "" end
  return string.format("%s-%s-%s %s:%s", y, mo, d, h, mi)
end

----------------------------------------------------------------------------------------------
-- settings: where the plugins and the archives live (defaults follow the portable drive)
----------------------------------------------------------------------------------------------
M.PLUGINS = {
  { id = "nam",   key = "NAM_DIR",   label = "Neural Amp Modeler", def = "NAM",   bdir = "NAM_User"   },
  { id = "vital", key = "VITAL_DIR", label = "Vital",              def = "Vital", bdir = "Vital_User" },
  { id = "ds",    key = "DS_DIR",    label = "Decent Sampler",     def = "DS",    bdir = "DS_User"    },
}

function M.plugin_dir(p) return M.get(p.key, M.DRIVE .. "\\" .. p.def) end
function M.archive_root() return M.get("ARCHIVE_DIR", M.DRIVE .. "\\REAPER_Saves") end

function M.edit_settings()
  local caps, vals = {}, {}
  for _, p in ipairs(M.PLUGINS) do
    caps[#caps + 1] = p.label .. " folder:"
    vals[#vals + 1] = M.plugin_dir(p)
  end
  caps[#caps + 1] = "Archive folder:"
  vals[#vals + 1] = M.archive_root()
  local ok, out = reaper.GetUserInputs("Todoroki Portable - folders (each one holds a 'User' folder)",
    #caps, table.concat(caps, ",") .. ",extrawidth=380,separator=|", table.concat(vals, "|"))
  if not ok then return false end
  local i = 0
  for raw in (out .. "|"):gmatch("(.-)|") do
    i = i + 1
    local v = raw:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\\/]+$", "")
    if i <= #M.PLUGINS then M.set(M.PLUGINS[i].key, v) elseif i == #M.PLUGINS + 1 then M.set("ARCHIVE_DIR", v) end
  end
  return true
end

function M.browse_folder(title, start)
  if reaper.JS_Dialog_BrowseForFolder then
    local rv, p = reaper.JS_Dialog_BrowseForFolder(title, start or "")
    if rv == 1 and p ~= "" then return (p:gsub("[\\/]+$", "")) end
    return nil
  end
  local ok, p = reaper.GetUserInputs(title, 1, "Folder:,extrawidth=420,separator=|", start or "")
  if ok and p ~= "" then return (p:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\\/]+$", "")) end
  return nil
end

----------------------------------------------------------------------------------------------
-- components
--   kind "ini"  : every *.ini at the root of the REAPER folder
--   kind "rdir" : folder(s) inside the REAPER folder, same relative path in the backup
--   kind "ext"  : <plugin folder>\User  <->  <backup>\<bdir>
----------------------------------------------------------------------------------------------
local TODOROKI_DIRS = { "Data\\references", "Data\\RSampler", "Data\\RSampler_TCI_WAV", "Data\\RSampler_Unpacked" }

M.COMPONENTS = {
  { id = "ini", group = "REAPER", label = "Settings files (*.ini)", kind = "ini", reaper = true },
}
for _, d in ipairs({ "ColorThemes", "Data", "Effects", "FXChains", "KeyMaps", "LangPack", "MenuSets", "presets",
  "ProjectTemplates", "ReaPack", "Scripts", "TrackTemplates", "User", "UserPlugins" }) do
  local c = { id = d, group = "REAPER", label = d, kind = "rdir", dirs = { d }, reaper = true }
  if d == "Data" then c.label = "Data (without Todoroki libraries)"; c.exclude = TODOROKI_DIRS end
  M.COMPONENTS[#M.COMPONENTS + 1] = c
end
M.COMPONENTS[#M.COMPONENTS + 1] = { id = "reflab", group = "Todoroki", label = "RefLab references",
  kind = "rdir", dirs = { "Data\\references" } }
M.COMPONENTS[#M.COMPONENTS + 1] = { id = "rstrig", group = "Todoroki", label = "RS Trig library",
  kind = "rdir", dirs = { "Data\\RSampler", "Data\\RSampler_TCI_WAV", "Data\\RSampler_Unpacked" } }
for _, p in ipairs(M.PLUGINS) do
  M.COMPONENTS[#M.COMPONENTS + 1] = { id = p.id, group = "Plugins", label = p.label, kind = "ext", plugin = p }
end

M.GROUPS = {
  { id = "REAPER",   label = "REAPER" },
  { id = "Todoroki", label = "TODOROKI DATA" },
  { id = "Plugins",  label = "PLUGIN USER FOLDERS" },
}

-- is the component present in the live installation?
function M.available_live(c)
  if c.kind == "ini" then return M.has_ini(M.RES) end
  if c.kind == "rdir" then
    for _, d in ipairs(c.dirs) do if M.dir_exists(M.join(M.RES, d)) then return true end end
    return false
  end
  return M.dir_exists(M.join(M.plugin_dir(c.plugin), "User"))
end

-- is the component present in a backup folder?
function M.available_backup(c, root)
  if c.kind == "ini" then return M.has_ini(root) end
  if c.kind == "rdir" then
    for _, d in ipairs(c.dirs) do if M.dir_exists(M.join(root, d)) then return true end end
    return false
  end
  return M.dir_exists(M.join(root, c.plugin.bdir))
end

function M.live_path_label(c)
  if c.kind == "ext" then return M.join(M.plugin_dir(c.plugin), "User") end
  if c.kind == "ini" then return M.RES end
  return M.join(M.RES, c.dirs[1])
end

----------------------------------------------------------------------------------------------
-- backups list (temp, archive, custom history)
----------------------------------------------------------------------------------------------
function M.is_backup_dir(p)
  local leaf = p:match("([^\\/]+)$") or ""
  return leaf:match("^REAPER_Backup_") or leaf:match("^REAPER_Save_") or M.file_exists(M.join(p, M.MANIFEST))
end

function M.history()
  local t = {}
  for p in (M.get("HISTORY", "") .. "|"):gmatch("(.-)|") do if p ~= "" then t[#t + 1] = p end end
  return t
end

function M.remember(path)
  M.set("LAST", path)
  local f = io.open(M.LAST_FILE, "w")
  if f then f:write(path) f:close() end
  local h, seen = { path }, { [path:lower()] = true }
  for _, p in ipairs(M.history()) do
    if not seen[p:lower()] and #h < 40 then h[#h + 1] = p; seen[p:lower()] = true end
  end
  M.set("HISTORY", table.concat(h, "|"))
end

function M.last_backup()
  local p = M.get("LAST", nil)
  if p and M.dir_exists(p) then return p end
  for _, f in ipairs({ M.LAST_FILE, M.TEMP .. "\\reaper_last_backup.txt" }) do   -- 2nd = old .bat workflow
    local h = io.open(f, "r")
    if h then
      local s = (h:read("*l") or ""):gsub("^%s+", ""):gsub("%s+$", "")
      h:close()
      if s ~= "" and M.dir_exists(s) then return s end
    end
  end
  return nil
end

function M.list_backups()
  local out, seen = {}, {}
  local function add(path, where)
    if seen[path:lower()] or not M.dir_exists(path) then return end
    seen[path:lower()] = true
    local name = path:match("([^\\/]+)$") or path
    out[#out + 1] = { path = path, name = name, where = where, date = M.pretty_ts(name), key = name:match("(%d%d%d%d%d%d%d%d_%d%d%d%d%d%d)") or "" }
  end
  for _, d in ipairs(M.subdirs(M.TEMP)) do
    if d:match("^REAPER_Backup_") then add(M.join(M.TEMP, d), "Temp") end
  end
  local ar = M.archive_root()
  for _, d in ipairs(M.subdirs(ar)) do
    local p = M.join(ar, d)
    if M.is_backup_dir(p) then add(p, "Archive") end
  end
  for _, p in ipairs(M.history()) do
    if M.is_backup_dir(p) then add(p, "Custom") end
  end
  table.sort(out, function(a, b) return a.key > b.key end)
  return out
end

----------------------------------------------------------------------------------------------
-- PowerShell job (runs in its own console window, so REAPER never freezes and a restore can
-- wait for REAPER to quit)
----------------------------------------------------------------------------------------------
local function q(s) return "'" .. tostring(s):gsub("'", "''") .. "'" end

local PS_HEAD = [[
$ErrorActionPreference = 'Continue'
$script:errors = 0
function Title($t) { Write-Host ''; Write-Host ('  ' + $t) -ForegroundColor Cyan; Write-Host ('  ' + ('-' * $t.Length)) -ForegroundColor DarkCyan }
function Info($t) { Write-Host ('  ' + $t) -ForegroundColor Gray }
function Step($t) { Write-Host ('  > ' + $t) -ForegroundColor White }
function Skip($t) { Write-Host ('    skipped: ' + $t) -ForegroundColor DarkGray }
function Fail($t) { $script:errors++; Write-Host ('    ERROR: ' + $t) -ForegroundColor Red }
function RoboDir($src, $dst, $xd) {
  if (-not (Test-Path -LiteralPath $src -PathType Container)) { Skip ('not found ' + $src); return }
  $a = @($src, $dst, '/E', '/R:2', '/W:2', '/NFL', '/NDL', '/NJH', '/NJS', '/NP')
  if ($xd -and $xd.Count -gt 0) { $a += '/XD'; $a += $xd }
  & robocopy @a | Out-Null
  if ($LASTEXITCODE -ge 8) { Fail ('robocopy code ' + $LASTEXITCODE + ' for ' + $src) }
}
function CopyIni($src, $dst) {
  if (-not (Test-Path -LiteralPath $src -PathType Container)) { Skip ('not found ' + $src); return }
  New-Item -ItemType Directory -Force -Path $dst | Out-Null
  try { Get-ChildItem -LiteralPath $src -Filter *.ini -File | Copy-Item -Destination $dst -Force -ErrorAction Stop }
  catch { Fail $_.Exception.Message }
}
function WaitReaper($exe) {
  $p = Get-Process -Name reaper -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }
  if ($p) {
    Info 'Waiting for REAPER to close... (close this window to cancel)'
    while (Get-Process -Name reaper -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }) { Start-Sleep -Milliseconds 400 }
    Start-Sleep -Milliseconds 800
  }
}
]]

-- ops: list of { label=, fn="RoboDir"|"CopyIni", src=, dst=, xd={...} }
-- opts: title, wait_exe, relaunch_exe, footer, manifest = { path=, text= }
function M.run_job(name, ops, opts)
  local L = { PS_HEAD }
  L[#L + 1] = "$Host.UI.RawUI.WindowTitle = " .. q("Todoroki Portable - " .. opts.title)
  L[#L + 1] = "Title " .. q("Todoroki Portable - " .. opts.title)
  for _, s in ipairs(opts.info or {}) do L[#L + 1] = "Info " .. q(s) end
  if opts.wait_exe then L[#L + 1] = "WaitReaper " .. q(opts.wait_exe) end
  if opts.mkdir then L[#L + 1] = "New-Item -ItemType Directory -Force -Path " .. q(opts.mkdir) .. " | Out-Null" end
  for _, o in ipairs(ops) do
    L[#L + 1] = "Step " .. q(o.label)
    if o.fn == "CopyIni" then
      L[#L + 1] = "CopyIni " .. q(o.src) .. " " .. q(o.dst)
    else
      local xd = {}
      for _, x in ipairs(o.xd or {}) do xd[#xd + 1] = q(x) end
      L[#L + 1] = "RoboDir " .. q(o.src) .. " " .. q(o.dst) .. " @(" .. table.concat(xd, ",") .. ")"
    end
  end
  for _, line in ipairs(opts.extra or {}) do L[#L + 1] = line end
  if opts.manifest then
    L[#L + 1] = "Set-Content -LiteralPath " .. q(opts.manifest.path) .. " -Value " .. q(opts.manifest.text) .. " -Encoding UTF8"
  end
  L[#L + 1] = "Write-Host ''"
  L[#L + 1] = "if ($script:errors -gt 0) { Write-Host ('  Finished with ' + $script:errors + ' error(s).') -ForegroundColor Red } else { Write-Host '  Done.' -ForegroundColor Green }"
  for _, s in ipairs(opts.footer or {}) do L[#L + 1] = "Info " .. q(s) end
  if opts.relaunch_exe then
    L[#L + 1] = "Info 'Relaunching REAPER...'"
    L[#L + 1] = "Start-Process -FilePath " .. q(opts.relaunch_exe)
  end
  L[#L + 1] = "if ($script:errors -gt 0) { Write-Host ''; Read-Host '  Press Enter to close' | Out-Null } else { Write-Host ''; Info 'This window closes in 6 s.'; Start-Sleep -Seconds 6 }"
  L[#L + 1] = "Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue"

  local ps1 = M.TEMP .. "\\todoroki_portable_" .. name .. "_" .. M.timestamp() .. ".ps1"
  local f = io.open(ps1, "wb")
  if not f then
    reaper.ShowMessageBox("Cannot write the job file:\n" .. ps1, "Todoroki Portable", 0)
    return false
  end
  f:write("\239\187\191" .. table.concat(L, "\r\n") .. "\r\n")   -- UTF-8 BOM: accents in paths stay intact
  f:close()
  reaper.ExecProcess('cmd.exe /C start "Todoroki Portable" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' .. ps1 .. '"', -1)
  return true
end

function M.reaper_exe() return M.join(reaper.GetExePath(), "reaper.exe") end

----------------------------------------------------------------------------------------------
-- toolbar icons: copied into <REAPER>/Data/toolbar_icons (+ 150 / 200 for HiDPI)
----------------------------------------------------------------------------------------------
local function copy_file(src, dst)
  local a = io.open(src, "rb"); if not a then return false end
  local data = a:read("*a"); a:close()
  local b = io.open(dst, "rb")
  if b then
    local same = b:read("*a") == data; b:close()
    if same then return true end
  end
  b = io.open(dst, "wb"); if not b then return false end
  b:write(data); b:close()
  return true
end

function M.install_icons(here)
  local base = M.join(M.RES, "Data", "toolbar_icons")
  for _, n in ipairs({ "Todoroki_Portable Backup", "Todoroki_Portable Restore", "Todoroki_Portable Clean backups" }) do
    for _, v in ipairs({ { "", base }, { " (150)", M.join(base, "150") }, { " (200)", M.join(base, "200") } }) do
      local src = here .. n .. v[1] .. ".png"
      if M.file_exists(src) then
        reaper.RecursiveCreateDirectory(v[2], 0)
        copy_file(src, M.join(v[2], n .. ".png"))
      end
    end
  end
end

----------------------------------------------------------------------------------------------
-- minimal flat gfx UI (square shapes, dark)
----------------------------------------------------------------------------------------------
local C = {
  bg = { 0.118, 0.122, 0.133 }, panel = { 0.157, 0.161, 0.176 }, line = { 0.235, 0.243, 0.259 },
  text = { 0.90, 0.91, 0.92 }, dim = { 0.53, 0.55, 0.58 }, faint = { 0.36, 0.37, 0.40 },
  accent = { 0.31, 0.765, 0.969 }, danger = { 0.93, 0.33, 0.31 }, hover = { 0.21, 0.22, 0.24 },
}
M.C = C

local UI = {}
UI.__index = UI

function M.ui(title, w, h)
  local self = setmetatable({ wtitle = title, w = w, h = h, wasdown = false, S = 1, wheel = 0 }, UI)
  local mx, my = reaper.GetMousePosition()
  gfx.ext_retina = 1
  gfx.init(title, w, h, 0, math.max(0, mx - w // 2), math.max(0, my - 60))
  if reaper.JS_Window_Find then
    local hwnd = reaper.JS_Window_Find(title, true)
    if hwnd and reaper.JS_Window_AttachTopmostPin then reaper.JS_Window_AttachTopmostPin(hwnd) end
  end
  return self
end

function UI:col(c, a) gfx.set(c[1], c[2], c[3], a or 1) end

function UI:font(sz, flags)
  gfx.setfont(1, "Segoe UI", math.floor(sz * self.S + 0.5), flags and string.byte(flags) or nil)
end

function UI:frame()
  local S = gfx.ext_retina or 1
  if S < 1 then S = 1 end
  self.S = S
  self.W, self.H = gfx.w / S, gfx.h / S
  self.mx, self.my = gfx.mouse_x / S, gfx.mouse_y / S
  local down = gfx.mouse_cap & 1 == 1
  self.click = down and not self.wasdown
  self.wasdown = down
  self.wheel = gfx.mouse_wheel; gfx.mouse_wheel = 0
  self.char = gfx.getchar()
  self:col(C.bg); gfx.rect(0, 0, gfx.w, gfx.h, 1)
  return self.char >= 0 and self.char ~= 27
end

function UI:rect(x, y, w, h, fill)
  local S = self.S
  gfx.rect(math.floor(x * S), math.floor(y * S), math.floor(w * S), math.floor(h * S), fill and 1 or 0)
end

function UI:line(x1, y1, x2, y2)
  local S = self.S
  gfx.line(x1 * S, y1 * S, x2 * S, y2 * S, 1)
end

function UI:text(x, y, s, c, sz, flags, maxw)
  self:col(c or C.text); self:font(sz or 14, flags)
  if maxw then s = self:fit(s, maxw) end
  gfx.x, gfx.y = math.floor(x * self.S), math.floor(y * self.S)
  gfx.drawstr(s)
end

function UI:tw(s) return gfx.measurestr(s) / self.S end

function UI:fit(s, maxw)
  if self:tw(s) <= maxw then return s end
  local keep = #s
  while keep > 4 and self:tw("..." .. s:sub(-keep)) > maxw do keep = keep - 1 end
  return "..." .. s:sub(-keep)
end

function UI:over(x, y, w, h) return self.mx >= x and self.mx < x + w and self.my >= y and self.my < y + h end

function UI:checkbox(x, y, w, label, on, enabled, sub)
  local h = 20
  local hot = enabled and self:over(x - 4, y - 1, w + 4, h + 2)
  if hot then self:col(C.hover); self:rect(x - 4, y - 1, w + 4, h + 2, true) end
  local bx, by, bs = x, y + 4, 12
  if on and enabled then
    self:col(C.accent); self:rect(bx, by, bs, bs, true)
    self:col(C.bg)
    self:line(bx + 2.5, by + 6, bx + 5, by + 8.5); self:line(bx + 5, by + 8.5, bx + 9.5, by + 3.5)
    self:line(bx + 2.5, by + 6.8, bx + 5, by + 9.3); self:line(bx + 5, by + 9.3, bx + 9.5, by + 4.3)
  else
    self:col(enabled and C.dim or C.faint); self:rect(bx, by, bs, bs, false)
  end
  self:text(x + 20, y + 2, label, enabled and C.text or C.faint, 14)
  if sub then
    self:font(14); local lw = self:tw(label)
    self:text(x + 28 + lw, y + 3, sub, C.faint, 12, nil, w - lw - 34)
  end
  return hot and self.click
end

function UI:button(x, y, w, h, label, kind, enabled)
  if enabled == nil then enabled = true end
  local hot = enabled and self:over(x, y, w, h)
  if kind == "primary" then
    self:col(C.accent, enabled and (hot and 1 or 0.85) or 0.25); self:rect(x, y, w, h, true)
    self:font(14, "b"); local tw = self:tw(label)
    self:text(x + (w - tw) / 2, y + (h - 16) / 2, label, enabled and C.bg or C.dim, 14, "b")
  elseif kind == "danger" then
    self:col(C.danger, enabled and (hot and 1 or 0.85) or 0.25); self:rect(x, y, w, h, true)
    self:font(14, "b"); local tw = self:tw(label)
    self:text(x + (w - tw) / 2, y + (h - 16) / 2, label, enabled and C.bg or C.dim, 14, "b")
  else
    self:col(hot and C.hover or C.panel); self:rect(x, y, w, h, true)
    self:col(C.line); self:rect(x, y, w, h, false)
    self:font(14); local tw = self:tw(label)
    self:text(x + (w - tw) / 2, y + (h - 16) / 2, label, enabled and C.text or C.faint, 14)
  end
  return hot and self.click
end

function UI:radio(x, y, w, label, on)
  local hot = self:over(x - 4, y - 1, w + 4, 22)
  if hot then self:col(C.hover); self:rect(x - 4, y - 1, w + 4, 22, true) end
  self:col(on and C.accent or C.dim); self:rect(x, y + 4, 12, 12, false)
  if on then self:rect(x + 3, y + 7, 6, 6, true) end
  self:text(x + 20, y + 2, label, on and C.text or C.dim, 14)
  return hot and self.click
end

function UI:header(x, y, w, label)
  self:text(x, y, label, C.dim, 11, "b")
  self:col(C.line); self:rect(x, y + 17, w, 1, true)
end

function UI:pathbox(x, y, w, h, path)
  local hot = self:over(x, y, w, h)
  self:col(C.panel); self:rect(x, y, w, h, true)
  self:col(hot and C.accent or C.line); self:rect(x, y, w, h, false)
  self:text(x + 8, y + (h - 16) / 2, path or "(none)", path and C.text or C.faint, 13, nil, w - 16)
  return hot and self.click
end

function UI:title(s, sub)
  self:col(C.accent); self:rect(0, 0, self.W, 3, true)
  self:text(20, 16, s, C.text, 19, "b")
  if sub then self:text(20, 42, sub, C.dim, 13, nil, self.W - 40) end
end

function UI:close() gfx.quit() end

-- shared component list with "All" master toggle. returns new y.
-- state: { sel = {id=bool}, avail = {id=bool}, sub = {id=string} }
function M.draw_components(ui, st, x0, y0, colw)
  local all = true
  for _, c in ipairs(M.COMPONENTS) do if st.avail[c.id] and not st.sel[c.id] then all = false end end
  if ui:checkbox(x0, y0, 200, "All", all, true) then
    for _, c in ipairs(M.COMPONENTS) do st.sel[c.id] = (not all) and st.avail[c.id] or false end
  end
  local top = y0 + 32
  local cols = { { x = x0, y = top }, { x = x0 + colw + 20, y = top } }
  for gi, g in ipairs(M.GROUPS) do
    local col = (gi == 1) and cols[1] or cols[2]
    ui:header(col.x, col.y, colw, g.label)
    col.y = col.y + 26
    for _, c in ipairs(M.COMPONENTS) do
      if c.group == g.id then
        local en = st.avail[c.id]
        local sub = st.sub and st.sub[c.id] or (not en and "not found" or nil)
        if ui:checkbox(col.x, col.y, colw, c.label, st.sel[c.id], en, sub) and en then st.sel[c.id] = not st.sel[c.id] end
        col.y = col.y + 22
      end
    end
    col.y = col.y + 12
  end
  return math.max(cols[1].y, cols[2].y)
end

function M.count_sel(st)
  local n, reaper_side = 0, false
  for _, c in ipairs(M.COMPONENTS) do
    if st.sel[c.id] and st.avail[c.id] then
      n = n + 1
      if c.reaper then reaper_side = true end
    end
  end
  return n, reaper_side
end

function M.loop(fn)
  local function step()
    if fn() ~= false then reaper.defer(step) else gfx.quit() end
  end
  step()
end

function M.require_windows()
  if not M.IS_WIN then
    reaper.ShowMessageBox("Todoroki Portable Backup is made for a portable REAPER on Windows.", "Todoroki Portable", 0)
    return false
  end
  return true
end

return M
