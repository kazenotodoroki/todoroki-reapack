-- @description RefLab - actions et module Companion
-- @author Todoroki
-- @version 1.3
-- @changelog
--   - Memoire par projet : references, boucles et reference selectionnee enregistrees dans le
--     projet (.rpp) et rechargees a l'ouverture ou au changement d'onglet, meme quand RefLab
--     est dans le Monitoring FX
--   - Nouvelles actions : isolation de bandes (solo exclusif / cumulable par bande, full,
--     on/off), modes d'ecoute (stereo, mono, side, gauche, droite), vitesses du spectre,
--     courbe d'ecart (centrage, echelle, lissage), match, pente, lissage, trim
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
--   - Module Companion : ouvre `<REAPER>/Data/references`, tient la liste des fichiers a jour
--     et memorise les references de chaque projet

-- Protocole gmem "RefLab" (partage avec RefLab.jsfx) :
--   [0] battement de coeur      [1] requete du plugin (1 ouvrir dossier, 2 actualiser, 3 etat projet)
--   [2] commande des actions    [3] version de la liste   [4] nombre de fichiers
--   [10] compteur de publication (plugin)   [11] ref selectionnee (0-3)
--   [12] compteur de restauration (module)  [13] ref a selectionner  [15] accuse du plugin
--   [16] 1 = donnees a restaurer presentes
--   [20 + 4k ..] etat publie : actif, boucle on, debut, fin     [70000 + k*256] nom publie
--   [40 + 4k ..] etat a restaurer                                [71024 + k*256] nom a restaurer
--   [100 + i*256 ...] liste des fichiers (1 caractere par case, 0 final)

local M = { name = "RefLab", gmem = "RefLab", interval = 1.5 }
local MAXF, NAMEW, BASE = 250, 256, 100
local EXT_SEC, EXT_KEY = "RefLab", "state"

local dir, last_sig, hb = nil, nil, 0
local last_proj, last_pub, stored_body, last_push = nil, nil, nil, 0

----------------------------------------------------------------------------------------------
-- liste des fichiers de reference
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
-- memoire par projet
--   format : "v1|<ref>|<actif>,<boucle>,<debut>,<fin>,<nom>;... (4 emplacements)"
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

-- pousse l'etat du projet courant vers le plugin
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

-- enregistre dans le projet ce que le plugin publie
local function poll_published(C)
  local pub = reaper.gmem_read(10)
  if pub == last_pub then return end
  last_pub = pub
  -- n'accepter que ce qui suit la derniere restauration (evite d'ecrire l'etat d'un ancien projet)
  if reaper.gmem_read(15) ~= reaper.gmem_read(12) then return end
  local body, sel = read_published(C)
  local s = "v1|" .. sel .. "|" .. body
  if s ~= get_stored() then
    reaper.SetProjExtState(0, EXT_SEC, EXT_KEY, s)
    -- projet "modifie" seulement pour un vrai changement de l'utilisateur (pas l'echo d'une restauration)
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
