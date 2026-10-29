-- @noindex
--[[
  Todoroki Companion - API for Lua scripts

  Loading it from any script:

    local api_path = reaper.GetExtState("Todoroki_Companion", "dir")
    if api_path == "" then
      api_path = reaper.GetResourcePath() .. "/Scripts/Todoroki/Scripts/Todoroki Companion/"
    end
    local TC = dofile(api_path .. "Todoroki_Companion_API.lua")

  Functions:
    TC.running()                      -> true if the Companion is running
    TC.start()                        -> starts the Companion if it is not running (true if ok)
    TC.modules()                      -> { "RefLab", ... } loaded modules
    TC.has(name)                      -> true if the module is loaded
    TC.call(module, cmd, arg)         -> request id (asynchronous)
    TC.result(id)                     -> "pending" | "ok", value | "error", message
    TC.request(module, cmd, arg, cb, timeout)
                                      -> calls cb(ok, value) when the reply arrives
                                         (uses reaper.defer, timeout in s, 3 by default)
    TC.open_folder(path)              -> opens a folder in the file explorer (through the Companion)
    TC.install_toolbar_icons(only_new)
                                      -> copies the "toolbar_icons" folders of every Todoroki package
                                         into <REAPER>/Data/toolbar_icons (100 %, 150 %, 200 %).
                                         only_new = true: only missing or changed files. Returns the count.

  module = "core" for the Companion's own commands: ping, version, reload, modules,
  open_folder, log.
]]

local TC = {}
local SEC = "Todoroki_Companion"

local function enc(s) return (tostring(s or ""):gsub("[%%\t\r\n]", function(c) return string.format("%%%02X", c:byte()) end)) end
local function dec(s) return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)) end

function TC.running()
  local hb = tonumber(reaper.GetExtState(SEC, "hb")) or 0
  return hb > 0 and reaper.time_precise() - hb < 2
end

function TC.start()
  if TC.running() then return true end
  local id = reaper.NamedCommandLookup(reaper.GetExtState(SEC, "cmd"))
  if id == 0 then
    local dir = reaper.GetExtState(SEC, "dir")
    if dir == "" then dir = reaper.GetResourcePath() .. "/Scripts/Todoroki/Scripts/Todoroki Companion/" end
    id = reaper.AddRemoveReaScript(true, 0, dir .. "Todoroki_Companion.lua", true)
  end
  if id ~= 0 then reaper.Main_OnCommand(id, 0); return true end
  return false
end

function TC.modules()
  local t = {}
  for m in reaper.GetExtState(SEC, "modules"):gmatch("[^,]+") do t[#t + 1] = m end
  return t
end

function TC.has(name)
  for _, m in ipairs(TC.modules()) do if m == name then return true end end
  return false
end

local counter = 0
function TC.call(module, cmd, arg)
  counter = counter + 1
  local id = string.format("%d%04d", math.floor(reaper.time_precise() * 1000) % 100000000, counter % 10000)
  local line = id .. "\t" .. enc(module) .. "\t" .. enc(cmd) .. "\t" .. enc(arg)
  local inbox = reaper.GetExtState(SEC, "inbox")
  reaper.SetExtState(SEC, "inbox", inbox == "" and line or (inbox .. "\n" .. line), false)
  return id
end

function TC.result(id)
  local r = reaper.GetExtState(SEC, "r_" .. id)
  if r == "" then return "pending" end
  reaper.DeleteExtState(SEC, "r_" .. id, false)
  local status, val = r:match("^(%a+)\t?(.*)$")
  return status or "error", dec(val or "")
end

function TC.request(module, cmd, arg, cb, timeout)
  if not TC.running() then
    if cb then cb(false, "Todoroki Companion not running") end
    return
  end
  local id = TC.call(module, cmd, arg)
  local t_end = reaper.time_precise() + (timeout or 3)
  local function poll()
    local status, val = TC.result(id)
    if status ~= "pending" then
      if cb then cb(status == "ok", val) end
    elseif reaper.time_precise() > t_end then
      if cb then cb(false, "timeout") end
    else
      reaper.defer(poll)
    end
  end
  reaper.defer(poll)
end

function TC.open_folder(path)
  return TC.call("core", "open_folder", path)
end

-- toolbar icons --------------------------------------------------------------------------
local API_DIR = (debug.getinfo(1, "S").source:sub(2)):match("^(.*[\\/])") or ""

local function list(dir, dirs)
  local out, i = {}, 0
  if dirs then reaper.EnumerateSubdirectories(dir, -1) else reaper.EnumerateFiles(dir, -1) end
  while true do
    local f = dirs and reaper.EnumerateSubdirectories(dir, i) or reaper.EnumerateFiles(dir, i)
    if not f then break end
    out[#out + 1] = f; i = i + 1
  end
  return out
end

local function read_all(p) local f = io.open(p, "rb"); if not f then return nil end local d = f:read("*a"); f:close(); return d end

function TC.install_toolbar_icons(only_new)
  local SEP = package.config:sub(1, 1)
  local res = reaper.GetResourcePath()
  -- repository root = two levels above the Companion folder (.../Scripts/Todoroki)
  local here = API_DIR:gsub("[\\/]$", "")
  local root = here:match("^(.*)[\\/][^\\/]+[\\/][^\\/]+$") or here
  local dest = res .. SEP .. "Data" .. SEP .. "toolbar_icons"
  local count, stack = 0, { { root, 0 } }
  while #stack > 0 do
    local top = table.remove(stack)
    for _, d in ipairs(list(top[1], true)) do
      local full = top[1] .. SEP .. d
      if d == "toolbar_icons" then
        for _, sub in ipairs({ "", "150", "200" }) do
          local src = sub == "" and full or (full .. SEP .. sub)
          local dst = sub == "" and dest or (dest .. SEP .. sub)
          reaper.RecursiveCreateDirectory(dst, 0)
          for _, f in ipairs(list(src, false)) do
            if f:lower():match("%.png$") then
              local data = read_all(src .. SEP .. f)
              local old = only_new and read_all(dst .. SEP .. f)
              if data and data ~= old then
                local o = io.open(dst .. SEP .. f, "wb")
                if o then o:write(data); o:close(); count = count + 1 end
              end
            end
          end
        end
      elseif top[2] < 4 then
        stack[#stack + 1] = { full, top[2] + 1 }
      end
    end
  end
  return count
end

return TC
