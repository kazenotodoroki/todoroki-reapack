-- @noindex
-- Todoroki Companion : affiche l'etat du service, recharge les modules et montre le journal.
local HERE = ({ reaper.get_action_context() })[2]:match("^(.*[\\/])")
local TC = dofile(HERE .. "Todoroki_Companion_API.lua")

if not TC.running() then
  local r = reaper.ShowMessageBox("Le Todoroki Companion ne tourne pas.\nLe demarrer maintenant ?", "Todoroki Companion", 4)
  if r == 6 then TC.start() end
  return
end

TC.request("core", "reload", "", function(ok, mods)
  TC.request("core", "log", "", function(ok2, log)
    reaper.ClearConsole()
    reaper.ShowConsoleMsg("Todoroki Companion " .. reaper.GetExtState("Todoroki_Companion", "version") .. " : actif\n")
    reaper.ShowConsoleMsg("Modules recharges : " .. (ok and (mods ~= "" and mods or "aucun") or ("erreur : " .. tostring(mods))) .. "\n\n")
    reaper.ShowConsoleMsg("Journal :\n" .. (ok2 and log or "") .. "\n")
  end)
end)
