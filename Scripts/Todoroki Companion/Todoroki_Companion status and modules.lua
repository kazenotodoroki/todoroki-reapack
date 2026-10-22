-- @noindex
-- Todoroki Companion: shows the service status, reloads the modules and prints the log.
local HERE = ({ reaper.get_action_context() })[2]:match("^(.*[\\/])")
local TC = dofile(HERE .. "Todoroki_Companion_API.lua")

if not TC.running() then
  local r = reaper.ShowMessageBox("The Todoroki Companion is not running.\nStart it now?", "Todoroki Companion", 4)
  if r == 6 then TC.start() end
  return
end

TC.request("core", "reload", "", function(ok, mods)
  TC.request("core", "log", "", function(ok2, log)
    reaper.ClearConsole()
    reaper.ShowConsoleMsg("Todoroki Companion " .. reaper.GetExtState("Todoroki_Companion", "version") .. ": running\n")
    reaper.ShowConsoleMsg("Modules reloaded: " .. (ok and (mods ~= "" and mods or "none") or ("error: " .. tostring(mods))) .. "\n\n")
    reaper.ShowConsoleMsg("Log:\n" .. (ok2 and log or "") .. "\n")
  end)
end)
