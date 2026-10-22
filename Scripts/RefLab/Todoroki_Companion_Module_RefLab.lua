-- @description RefLab - actions and Companion module
-- @author Todoroki
-- @version 1.4
-- @changelog
--   - Everything in English; the actions were renamed (re-assign the shortcuts made in 1.3)
--   - Spectrum speed actions: Fast, Medium, Slow, Very slow, Infinite average
-- @provides
--   [nomain] .
--   [main] RefLab - Back to loop start on Play on-off.lua
--   [main] RefLab - Band solo - band 1 Low add-remove.lua
--   [main] RefLab - Band solo - band 1 Low solo.lua
--   [main] RefLab - Band solo - band 2 Low-mid add-remove.lua
--   [main] RefLab - Band solo - band 2 Low-mid solo.lua
--   [main] RefLab - Band solo - band 3 Mid add-remove.lua
--   [main] RefLab - Band solo - band 3 Mid solo.lua
--   [main] RefLab - Band solo - band 4 High-mid add-remove.lua
--   [main] RefLab - Band solo - band 4 High-mid solo.lua
--   [main] RefLab - Band solo - band 5 High add-remove.lua
--   [main] RefLab - Band solo - band 5 High solo.lua
--   [main] RefLab - Band solo - full (no band).lua
--   [main] RefLab - Band solo on-off.lua
--   [main] RefLab - Difference - centered or absolute.lua
--   [main] RefLab - Difference - next scale.lua
--   [main] RefLab - Difference - next smoothing.lua
--   [main] RefLab - Independent playback on-off.lua
--   [main] RefLab - Listen to MIX.lua
--   [main] RefLab - Listen to REF.lua
--   [main] RefLab - Loudness match - Integrated.lua
--   [main] RefLab - Loudness match - Off.lua
--   [main] RefLab - Loudness match - Short-term.lua
--   [main] RefLab - Loudness match - next mode.lua
--   [main] RefLab - Next reference.lua
--   [main] RefLab - Open references folder.lua
--   [main] RefLab - Output - Left.lua
--   [main] RefLab - Output - Mono.lua
--   [main] RefLab - Output - Right.lua
--   [main] RefLab - Output - Side.lua
--   [main] RefLab - Output - Stereo.lua
--   [main] RefLab - Output - next mode.lua
--   [main] RefLab - Previous reference.lua
--   [main] RefLab - Reference 1.lua
--   [main] RefLab - Reference 2.lua
--   [main] RefLab - Reference 3.lua
--   [main] RefLab - Reference 4.lua
--   [main] RefLab - Reference trim +0.5 dB.lua
--   [main] RefLab - Reference trim -0.5 dB.lua
--   [main] RefLab - Reference trim 0 dB.lua
--   [main] RefLab - Refresh references list.lua
--   [main] RefLab - Reset integrated loudness.lua
--   [main] RefLab - Spectrum - next slope.lua
--   [main] RefLab - Spectrum - next smoothing.lua
--   [main] RefLab - Spectrum - reset average.lua
--   [main] RefLab - Spectrum speed - Fast.lua
--   [main] RefLab - Spectrum speed - Infinite average.lua
--   [main] RefLab - Spectrum speed - Medium.lua
--   [main] RefLab - Spectrum speed - Slow.lua
--   [main] RefLab - Spectrum speed - Very slow.lua
--   [main] RefLab - Spectrum speed - next.lua
--   [main] RefLab - Toggle MIX-REF.lua
--   [main] RefLab - Toggle loop.lua
--   RefLab README.md
-- @about
--   # RefLab - actions and Companion module
--
--   Install together with the **RefLab** (JSFX) and **Todoroki Companion** packages.
--
--   - "RefLab - ..." actions: map them to keys or to a MIDI controller
--   - Companion module: opens `<REAPER>/Data/references`, keeps the file list up to date
--     and remembers the references of each project

-- "RefLab" gmem protocol (shared with RefLab.jsfx):
--   [0] heartbeat              [1] request from the plugin (1 open folder, 2 refresh, 3 project state)
--   [2] command from actions   [3] list version   [4] number of files
--   [10] publish counter (plugin)   [11] selected ref (0-3)
--   [12] restore counter (module)   [13] ref to select   [15] plugin acknowledgment
--   [16] 1 = data to restore present
--   [20 + 4k ..] published state: active, loop on, start, end   [70000 + k*256] published name
--   [40 + 4k ..] state to restore                                [71024 + k*256] name to restore
--   [100 + i*256 ...] file list (1 character per slot, 0 terminated)

local M = { name = "RefLab", gmem = "RefLab", interval = 1.5 }
local MAXF, NAMEW, BASE = 250, 256, 100
local EXT_SEC, EXT_KEY = "RefLab", "state"

local dir, last_sig, hb = nil, nil, 0
local last_proj, last_pub, stored_body, last_push = nil, nil, nil, 0

----------------------------------------------------------------------------------------------
-- reference file list
----------------------------------------------------------------------------------------------
local function publish(C, force)
  local list = {}
  for _, f in ipairs(C.list_files(dir, C.AUDIO_EXT)) do
    if #f < NAMEW then list[#list + 1] = f end
  end
  local sig = table.concat(list, "\n")
  if sig == last_sig and not force then return #list end
  last_sig = sig
  local n = math.min(#list, MAXF)
  for k = 1, n do C.gmem_write_string(BASE + (k - 1) * NAMEW, list[k], NAMEW) end
  reaper.gmem_write(4, n)
  reaper.gmem_write(3, reaper.gmem_read(3) + 1)
  return n
end

----------------------------------------------------------------------------------------------
-- per-project memory
--   format: "v1|<ref>|<active>,<loop>,<start>,<end>,<name>;... (4 slots)"
----------------------------------------------------------------------------------------------
local function pct(s) return (s:gsub("[%%|;,\r\n]", function(c) return string.format("%%%02X", c:byte()) end)) end
local function unpct(s) return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)) end

local function read_published(C)
  local parts = {}
  for k = 0, 3 do
    local b = 20 + 4 * k
    local act = reaper.gmem_read(b) > 0.5 and 1 or 0
    local name = act == 1 and C.gmem_read_string(70000 + k * 256, 256) or ""
    parts[#parts + 1] = string.format("%d,%d,%.3f,%.3f,%s", act, reaper.gmem_read(b + 1) > 0.5 and 1 or 0,
                                      reaper.gmem_read(b + 2), reaper.gmem_read(b + 3), pct(name))
  end
  return table.concat(parts, ";"), math.floor(reaper.gmem_read(11) + 0.5)
end

local function get_stored()
  local _, s = reaper.GetProjExtState(0, EXT_SEC, EXT_KEY)
  return s or ""
end

-- pushes the current project state to the plugin
local function push(C)
  local s = get_stored()
  local sel, body = s:match("^v1|(%-?%d+)|(.*)$")
  if body then
    local k = 0
    for item in (body .. ";"):gmatch("([^;]*);") do
      if k > 3 then break end
      local act, lo, ls, le, name = item:match("^(%d),(%d),([%-%d%.]+),([%-%d%.]+),(.*)$")
      if act then
        local b = 40 + 4 * k
        reaper.gmem_write(b, tonumber(act))
        reaper.gmem_write(b + 1, tonumber(lo))
        reaper.gmem_write(b + 2, tonumber(ls))
        reaper.gmem_write(b + 3, tonumber(le))
        C.gmem_write_string(71024 + k * 256, unpct(name), 256)
      end
      k = k + 1
    end
    reaper.gmem_write(13, tonumber(sel) or 0)
    reaper.gmem_write(16, 1)
    stored_body = body
  else
    reaper.gmem_write(16, 0)
    stored_body = nil
  end
  reaper.gmem_write(12, reaper.gmem_read(12) + 1)
  last_push = C.now()
end

-- stores in the project what the plugin publishes
local function poll_published(C)
  local pub = reaper.gmem_read(10)
  if pub == last_pub then return end
  last_pub = pub
  -- only accept what follows the last restore (avoids writing the state of a previous project)
  if reaper.gmem_read(15) ~= reaper.gmem_read(12) then return end
  local body, sel = read_published(C)
  local s = "v1|" .. sel .. "|" .. body
  if s ~= get_stored() then
    reaper.SetProjExtState(0, EXT_SEC, EXT_KEY, s)
    -- mark the project "modified" only for a real user change (not the echo of a restore)
    if body ~= stored_body and C.now() - last_push > 2 then reaper.MarkProjectDirty(0) end
    stored_body = body
  end
end

local function project_key()
  local proj, fn = reaper.EnumProjects(-1)
  return tostring(proj) .. "|" .. tostring(fn or "")
end

----------------------------------------------------------------------------------------------
function M.init(C)
  dir = C.path(C.res, "Data", "references")
  reaper.RecursiveCreateDirectory(dir, 0)
  publish(C, true)
  last_pub = reaper.gmem_read(10)
  last_proj = project_key()
  push(C)
end

function M.tick(C)
  hb = (hb + 1) % 1000000
  reaper.gmem_write(0, hb)

  local req = reaper.gmem_read(1)
  if req ~= 0 then
    reaper.gmem_write(1, 0)
    if req == 3 then
      push(C)
    else
      if req == 1 then C.open_folder(dir) end
      publish(C, true)
    end
  end

  local key = project_key()
  if key ~= last_proj then
    last_proj = key
    push(C)
  end

  poll_published(C)
end

function M.slow(C) publish(C, false) end

M.commands = {
  refresh     = function(C) return tostring(publish(C, true)) end,
  open_folder = function(C) C.open_folder(dir); publish(C, true); return dir end,
  folder      = function() return dir end,
  send        = function(C, arg) reaper.gmem_write(2, tonumber(arg) or 0); return "ok" end,
  state       = function() return get_stored() end,
  restore     = function(C) push(C); return "ok" end,
}

return M
