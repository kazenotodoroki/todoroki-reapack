-- @noindex
-- Todoroki Companion: turns automatic start with REAPER on / off.
-- Writes a line in Scripts/__startup.lua, with a path relative to the REAPER folder
-- (works with portable REAPER even if the USB drive letter changes).

local SEP  = package.config:sub(1, 1)
local RES  = reaper.GetResourcePath()
local _, SELF, SECTION_ID, CMD_ID = reaper.get_action_context()
local HERE = SELF:match("^(.*[\\/])")
local COMP = HERE .. "Todoroki_Companion.lua"
local MARK = "-- Todoroki Companion autostart"
local STARTUP = RES .. SEP .. "Scripts" .. SEP .. "__startup.lua"

local function read(p) local f = io.open(p, "rb"); if not f then return nil end local d = f:read("*a"); f:close(); return d end
local function write(p, d) local f = io.open(p, "wb"); if not f then return false end f:write(d); f:close(); return true end

local lines, enabled, stale = {}, false, false
for l in ((read(STARTUP) or "") .. "\n"):gmatch("(.-)\r?\n") do
  if l:find(MARK, 1, true) then
    enabled = true
    -- line written by an older version (other script name): it is replaced, autostart stays ON
    if not l:find("Todoroki_Companion.lua", 1, true) then stale = true end
  elseif not l:find("RefLab Companion", 1, true) then          -- old RefLab v1.1 line
    lines[#lines + 1] = l
  end
end
while #lines > 0 and lines[#lines] == "" do lines[#lines] = nil end

local msg
if enabled and not stale then
  msg = "Todoroki Companion automatic start is now OFF."
else
  local rel = COMP:sub(1, #RES):lower() == RES:lower() and COMP:sub(#RES + 1) or nil   -- native separators: same action ID as ReaPack
  local expr = rel and ("reaper.GetResourcePath() .. [[" .. rel .. "]]") or ("[[" .. COMP .. "]]")
  lines[#lines + 1] = "do local id = reaper.AddRemoveReaScript(true, 0, " .. expr ..
                      ", true) if id ~= 0 then reaper.Main_OnCommand(id, 0) end end " .. MARK
  msg = stale and "Todoroki Companion automatic start updated (still ON)." or "Todoroki Companion automatic start is now ON."
  if not rel then msg = msg .. "\n\nWarning: the Companion is not inside the REAPER folder, an absolute path is used." end
  local hb = tonumber(reaper.GetExtState("Todoroki_Companion", "hb")) or 0
  if reaper.time_precise() - hb > 2 then
    local id = reaper.AddRemoveReaScript(true, 0, COMP, true)
    if id ~= 0 then reaper.Main_OnCommand(id, 0); msg = msg .. "\nCompanion started." end
  end
end

if not write(STARTUP, table.concat(lines, "\n") .. "\n") then
  msg = "Cannot write " .. STARTUP
else
  reaper.SetToggleCommandState(SECTION_ID, CMD_ID, (enabled and not stale) and 0 or 1)
  reaper.RefreshToolbar2(SECTION_ID, CMD_ID)
end
reaper.ShowMessageBox(msg, "Todoroki Companion", 0)
