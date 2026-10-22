-- @description Todoroki Companion (shared background service)
-- @author Todoroki
-- @version 1.1
-- @changelog
--   - Everything in English (messages, actions, documentation)
--   - "Etat et modules" action renamed "Status and modules"
-- @provides
--   [main] .
--   [main] Todoroki Companion - Autostart (on-off).lua
--   [main] Todoroki Companion - Status and modules.lua
--   [nomain] Todoroki_Companion_API.lua
--   Todoroki Companion README.md
-- @about
--   # Todoroki Companion
--
--   A single background service shared by the Todoroki scripts and JSFX.
--   It loads **modules** (`Todoroki_Companion_Module_*.lua`) installed by the
--   other packages of the repository, and offers a **Lua API** to scripts.
--
--   - Run the **Todoroki Companion** action (run it again = stop)
--   - **Todoroki Companion - Autostart (on-off)**: start together with REAPER
--   - Works with portable REAPER (paths relative to the REAPER folder)
--
--   Developer documentation: `Todoroki Companion README.md`.

local VERSION = "1.0"
local SEC     = "Todoroki_Companion"          -- ExtState section
local SEP     = package.config:sub(1, 1)
local RES     = reaper.GetResourcePath()
local _, SELF, SECTION_ID, CMD_ID = reaper.get_action_context()
local HERE    = SELF:match("^(.*[\\/])") or (RES .. SEP)

----------------------------------------------------------------------------------------------
-- single instance
----------------------------------------------------------------------------------------------
if reaper.set_action_options then reaper.set_action_options(1) end   -- run again = stop
local TOKEN = string.format("%.6f-%d", reaper.time_precise(), math.random(1, 1000000000))
reaper.SetExtState(SEC, "token", TOKEN, false)
reaper.SetExtState("RefLab", "companion", "todoroki", false)          -- stops the old RefLab_Companion v1.1

if CMD_ID and CMD_ID > 0 then
  local named = reaper.ReverseNamedCommandLookup(CMD_ID)
  if named then reaper.SetExtState(SEC, "cmd", "_" .. named, true) end
  reaper.SetToggleCommandState(SECTION_ID, CMD_ID, 1)
  reaper.RefreshToolbar2(SECTION_ID, CMD_ID)
end
reaper.SetExtState(SEC, "dir", HERE, true)
reaper.SetExtState(SEC, "version", VERSION, false)

----------------------------------------------------------------------------------------------
-- toolbox passed to the modules (C)
----------------------------------------------------------------------------------------------
local C = { version = VERSION, sep = SEP, res = RES, dir = HERE, section = SEC }
local logs = {}

function C.now() return reaper.time_precise() end

function C.path(...)
  local p = table.concat({ ... }, SEP)
  p = p:gsub("[\\/]+", SEP)
  return p
end

function C.log(who, msg)
  local line = string.format("[%s] %s", tostring(who), tostring(msg))
  logs[#logs + 1] = line
  if #logs > 200 then table.remove(logs, 1) end
  if reaper.GetExtState(SEC, "debug") == "1" then reaper.ShowConsoleMsg(line .. "\n") end
end

function C.get(key, default)
  local v = reaper.GetExtState(SEC, key)
  if v == "" then return default end
  return v
end

function C.set(key, value, persist)
  reaper.SetExtState(SEC, key, tostring(value), persist and true or false)
end

function C.open_folder(dir)
  reaper.RecursiveCreateDirectory(dir, 0)
  local os_name = reaper.GetOS():lower()
  if SEP == "\\" then
    reaper.ExecProcess('explorer.exe "' .. dir .. '"', -1)
  elseif os_name:find("osx") or os_name:find("mac") then
    os.execute('open "' .. dir .. '"')
  else
    os.execute('xdg-open "' .. dir .. '" &')
  end
end

local function ext_ok(name, exts)
  if not exts then return true end
  local e = name:match("%.([^%.]+)$")
  return e ~= nil and exts[e:lower()] == true
end

-- (non recursive) sorted list of the files of a folder, REAPER cache cleared
function C.list_files(dir, exts)
  local out, i = {}, 0
  reaper.EnumerateFiles(dir, -1)
  while true do
    local f = reaper.EnumerateFiles(dir, i)
    if not f then break end
    if ext_ok(f, exts) then out[#out + 1] = f end
    i = i + 1
  end
  table.sort(out, function(a, b) return a:lower() < b:lower() end)
  return out
end

function C.list_dirs(dir)
  local out, i = {}, 0
  reaper.EnumerateSubdirectories(dir, -1)
  while true do
    local d = reaper.EnumerateSubdirectories(dir, i)
    if not d then break end
    out[#out + 1] = d
    i = i + 1
  end
  return out
end

-- common audio extensions
C.AUDIO_EXT = { wav = true, flac = true, mp3 = true, ogg = true, aif = true, aiff = true, wv = true, opus = true }

-- ASYNCHRONOUS recursive scan (never blocks REAPER): for big sample libraries.
--   opts = { exts = C.AUDIO_EXT, max_depth = 12, on_file = function(path, name) end,
--            on_done = function(files, job) end }
--   returns a job: job.done, job.files (full paths), job.dirs_done, job.cancel()
local jobs = {}
function C.scan(root, opts)
  opts = opts or {}
  local job = { root = root, files = {}, done = false, dirs_done = 0, cancelled = false }
  job.stack = { { root, 0 } }
  function job.cancel() job.cancelled = true end
  job.opts = opts
  jobs[#jobs + 1] = job
  return job
end

local function run_jobs(budget)
  local t_end = reaper.time_precise() + budget
  local k = 1
  while k <= #jobs do
    local job = jobs[k]
    while not job.cancelled and #job.stack > 0 and reaper.time_precise() < t_end do
      local top = table.remove(job.stack)
      local dir, depth = top[1], top[2]
      for _, f in ipairs(C.list_files(dir, job.opts.exts)) do
        local full = dir .. SEP .. f
        job.files[#job.files + 1] = full
        if job.opts.on_file then job.opts.on_file(full, f) end
      end
      if depth < (job.opts.max_depth or 12) then
        for _, d in ipairs(C.list_dirs(dir)) do job.stack[#job.stack + 1] = { dir .. SEP .. d, depth + 1 } end
      end
      job.dirs_done = job.dirs_done + 1
    end
    if job.cancelled or #job.stack == 0 then
      job.done = true
      table.remove(jobs, k)
      if not job.cancelled and job.opts.on_done then job.opts.on_done(job.files, job) end
    else
      k = k + 1
    end
  end
end

-- gmem: strings (1 character per slot, 0 terminated)
function C.gmem_write_string(base, s, maxlen)
  maxlen = maxlen or 256
  local n = math.min(#s, maxlen - 1)
  for i = 1, n do reaper.gmem_write(base + i - 1, s:byte(i)) end
  reaper.gmem_write(base + n, 0)
end

function C.gmem_read_string(base, maxlen)
  local t = {}
  for i = 0, (maxlen or 256) - 1 do
    local c = math.floor(reaper.gmem_read(base + i))
    if c <= 0 then break end
    t[#t + 1] = string.char(c % 256)
  end
  return table.concat(t)
end

----------------------------------------------------------------------------------------------
-- modules
----------------------------------------------------------------------------------------------
local modules, order = {}, {}

-- search root: the repository folder (.../Scripts/Todoroki), otherwise the Companion folder
local function search_root()
  local r = HERE:gsub("[\\/]$", "")
  local up2 = r:match("^(.*)[\\/][^\\/]+[\\/][^\\/]+$")
  local scripts = (RES .. SEP .. "Scripts"):lower():gsub("[\\/]", SEP)
  if up2 and #up2 > #scripts and up2:lower():gsub("[\\/]", SEP):sub(1, #scripts) == scripts then
    return up2
  end
  return r
end

local function find_module_files()
  local found, stack = {}, { { search_root(), 0 } }
  while #stack > 0 do
    local top = table.remove(stack)
    for _, f in ipairs(C.list_files(top[1], { lua = true })) do
      if f:match("^Todoroki_Companion_Module_.+%.lua$") then found[#found + 1] = top[1] .. SEP .. f end
    end
    if top[2] < 4 then
      for _, d in ipairs(C.list_dirs(top[1])) do stack[#stack + 1] = { top[1] .. SEP .. d, top[2] + 1 } end
    end
  end
  table.sort(found)
  return found
end

local function safe(M, fname, ...)
  local fn = M[fname]
  if type(fn) ~= "function" then return true end
  if M.gmem then reaper.gmem_attach(M.gmem) end
  local ok, a = pcall(fn, C, ...)
  if not ok then
    C.log(M.name, fname .. ": " .. tostring(a))
    M._errors = (M._errors or 0) + 1
    if M._errors >= 20 then M._disabled = true; C.log(M.name, "disabled after 20 errors") end
  end
  return ok, a
end

local function unload_all()
  for i = #order, 1, -1 do safe(order[i], "exit") end
  modules, order = {}, {}
end

local function load_modules()
  unload_all()
  for _, path in ipairs(find_module_files()) do
    local ok, M = pcall(dofile, path)
    if ok and type(M) == "table" and M.name and not modules[M.name] then
      M._path, M._next_slow = path, 0
      modules[M.name] = M
      order[#order + 1] = M
      safe(M, "init")
      C.log("core", "module loaded: " .. M.name)
    elseif not ok then
      C.log("core", "loading error " .. path .. ": " .. tostring(M))
    end
  end
  local names = {}
  for _, M in ipairs(order) do names[#names + 1] = M.name end
  reaper.SetExtState(SEC, "modules", table.concat(names, ","), false)
end
C.reload = load_modules
C.module = function(name) return modules[name] end

----------------------------------------------------------------------------------------------
-- Lua messaging (API): ExtState "inbox" -> replies "r_<id>"
----------------------------------------------------------------------------------------------
local function dec(s) return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)) end
local function enc(s) return (tostring(s):gsub("[%%\t\r\n]", function(c) return string.format("%%%02X", c:byte()) end)) end

local core_cmd = {
  ping        = function() return "pong" end,
  version     = function() return VERSION end,
  reload      = function() load_modules(); return reaper.GetExtState(SEC, "modules") end,
  modules     = function() return reaper.GetExtState(SEC, "modules") end,
  open_folder = function(_, arg) C.open_folder(arg); return "ok" end,
  log         = function() return table.concat(logs, "\n") end,
}

local function handle_inbox()
  local inbox = reaper.GetExtState(SEC, "inbox")
  if inbox == "" then return end
  reaper.SetExtState(SEC, "inbox", "", false)
  for line in inbox:gmatch("[^\n]+") do
    local id, mod, cmd, arg = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t?(.*)$")
    if id then
      mod, cmd, arg = dec(mod), dec(cmd), dec(arg)
      local fn, ok, res
      if mod == "core" then
        fn = core_cmd[cmd]
        if fn then ok, res = pcall(fn, C, arg) end
      else
        local M = modules[mod]
        fn = M and M.commands and M.commands[cmd]
        if fn then
          if M.gmem then reaper.gmem_attach(M.gmem) end
          ok, res = pcall(fn, C, arg)
        end
      end
      local reply
      if not fn then reply = "error\tunknown command: " .. mod .. "." .. cmd
      elseif ok then reply = "ok\t" .. enc(res == nil and "" or res)
      else reply = "error\t" .. enc(res) end
      if id ~= "" then reaper.SetExtState(SEC, "r_" .. id, reply, false) end
    end
  end
end

----------------------------------------------------------------------------------------------
-- main loop
----------------------------------------------------------------------------------------------
local function shutdown()
  unload_all()
  if reaper.GetExtState(SEC, "token") == TOKEN then
    reaper.SetExtState(SEC, "hb", "0", false)
    reaper.SetExtState(SEC, "modules", "", false)
    if CMD_ID and CMD_ID > 0 then
      reaper.SetToggleCommandState(SECTION_ID, CMD_ID, 0)
      reaper.RefreshToolbar2(SECTION_ID, CMD_ID)
    end
  end
end

local function loop()
  if reaper.GetExtState(SEC, "token") ~= TOKEN then return end     -- another instance took over
  local now = reaper.time_precise()
  reaper.SetExtState(SEC, "hb", string.format("%.3f", now), false)

  handle_inbox()
  for _, M in ipairs(order) do
    if not M._disabled then
      safe(M, "tick")
      if M.slow and now >= M._next_slow then
        M._next_slow = now + (M.interval or 1.5)
        safe(M, "slow")
      end
    end
  end
  if #jobs > 0 then run_jobs(0.004) end
  reaper.defer(loop)
end

reaper.atexit(shutdown)
load_modules()
loop()
