-- @description RefLab - actions et module Companion
-- @author Todoroki
-- @version 1.2
-- @changelog
--   - Actions pour tous les reglages de RefLab (assignables clavier / MIDI)
--   - Nouvelles actions : vitesse du spectre suivante, reset de la moyenne du spectre
--   - Module pour le Todoroki Companion (dossier references, liste mise a jour en direct)
-- @provides
--   [nomain] .
--   [main] RefLab - *.lua
--   RefLab LISEZMOI.md
-- @about
--   # RefLab - actions et module Companion
--
--   A installer avec les paquets **RefLab** (JSFX) et **Todoroki Companion**.
--
--   - Actions "RefLab - ..." : a assigner a des touches ou a un controleur MIDI
--   - Module Companion : ouvre `<REAPER>/Data/references` et tient la liste des fichiers
--     a jour dans le plugin

-- Protocole gmem "RefLab" (partage avec RefLab.jsfx) :
--   [0] battement de coeur      [1] requete du plugin (1 = ouvrir dossier, 2 = actualiser)
--   [2] commande des actions    [3] version de la liste   [4] nombre de fichiers
--   [100 + i*256 ...] noms de fichiers (1 caractere par case, 0 final)

local M = { name = "RefLab", gmem = "RefLab", interval = 1.5 }
local MAXF, NAMEW, BASE = 250, 256, 100

local dir, last_sig, hb = nil, nil, 0

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

function M.init(C)
  dir = C.path(C.res, "Data", "references")
  reaper.RecursiveCreateDirectory(dir, 0)
  publish(C, true)
end

function M.tick(C)
  hb = (hb + 1) % 1000000
  reaper.gmem_write(0, hb)
  local req = reaper.gmem_read(1)
  if req ~= 0 then
    reaper.gmem_write(1, 0)
    if req == 1 then C.open_folder(dir) end
    publish(C, true)
  end
end

function M.slow(C) publish(C, false) end

M.commands = {
  refresh     = function(C) return tostring(publish(C, true)) end,
  open_folder = function(C) C.open_folder(dir); publish(C, true); return dir end,
  folder      = function() return dir end,
  send        = function(C, arg) reaper.gmem_write(2, tonumber(arg) or 0); return "ok" end,
}

return M
