-- @description ChordMachineGun
-- @author Todoroki
-- @version 1.0
-- @changelog
--   Première version publique.
--   - Conduite de voix live (clavier MIDI, lecture, item) et positions personnalisées
--   - Degrés de la gamme de l'accord (Ctrl) et transformations néo-riemanniennes explorables (Alt)
--   - Split MIDI par voix (aucun / toutes les voix / basse seule / par voix) et doublures
--   - Fenêtre Historique, curseurs CC et vélocité, épinglage des fenêtres
-- @provides
--   [main=main,midi_editor] .
--   [main=main,midi_editor] Todoroki_ChordMachineGun *.lua
--   Todoroki_ChordMachineGun_core.lua
--   Todoroki_ChordMachineGun LISEZMOI.md
--   LICENSE.md
-- @about
--   # ChordMachineGun
--
--   Générateur d'accords pour REAPER, dérivé de **ChordGun** de pandabot (licence MIT).
--   Il s'installe à côté de ChordGun sans le modifier.
--
--   - Grille d'accords de la gamme, insertion dans l'éditeur MIDI ou jeu en direct
--   - Conduite de voix (règles classiques), analysée en continu depuis le clavier MIDI, la lecture ou l'item
--   - Positions personnalisées (ex. `1 5 3 13 9`), renversement automatique
--   - **Ctrl** : degrés de la gamme de l'accord sélectionné (accords d'emprunt)
--   - **Alt** : transformations néo-riemanniennes P, L, R, N, S, H, PR, explorables sans fin
--   - Split MIDI par voix, choix du canal de chaque voix, doublures (octave, quinte, tierce…)
--   - Fenêtre Historique, deux curseurs CC et un curseur de vélocité (souris ou contrôleur MIDI)
--
--   Recommandé : l'extension **js_ReaScriptAPI** (ReaPack), pour Ctrl/Alt + chiffres et l'épinglage des fenêtres.
--
--   Mode d'emploi complet : `Todoroki_ChordMachineGun LISEZMOI.md`, installé avec le script.
--
--   Licence MIT. ChordGun © 2018 pandabot (Ben Johnson), ChordMachineGun © 2026 Todoroki.

--[[
  ChordMachineGun — fenêtre principale. Nécessite Todoroki_ChordMachineGun_core.lua dans le même dossier.

  Souris
    clic                : écouter l'accord
    Maj + clic          : insérer l'accord (ou remplacer les notes sélectionnées)
    clic droit (vide)   : ancrer / détacher la fenêtre
    molette sur panneau : faire défiler le panneau de droite
  Clavier : 1-7 écouter, Maj+1-7 insérer, flèches sélectionner, Entrée jouer, +/- octave,
            Ctrl+1-7 degrés de la gamme de l'accord, Alt+1-7 transformations PLR
]]

local scriptPath = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(scriptPath .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()

------------------------------------------------------------------------------
-- Thème
------------------------------------------------------------------------------

local THEME = {
  bg       = "000000",
  surface  = "0E0E0E",
  surface2 = "161616",
  hover    = "202020",
  line     = "1E1E1E",
  text     = "EDEDED",
  soft     = "B5B5B5",
  muted    = "7C7C7C",
  faint    = "3E3E3E",
  accent   = "8AB4FF",
  onAccent = "05070A",
  danger   = "FF7A7A",
}

local function setColor(hex, a)
  gfx.set(tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, a or 1)
end

local osName = reaper.GetOS()
local FACE = "Arial"
if osName:match("Win") then FACE = "Segoe UI"
elseif osName:match("OSX") or osName:match("mac") then FACE = "Helvetica Neue" end

local F_BODY, F_SMALL, F_TITLE, F_LABEL, F_BOLD = 1, 2, 3, 4, 5
local function setupFonts()
  gfx.setfont(F_BODY, FACE, 15)
  gfx.setfont(F_SMALL, FACE, 13)
  gfx.setfont(F_TITLE, FACE, 30, string.byte('b'))
  gfx.setfont(F_LABEL, FACE, 11, string.byte('b'))
  gfx.setfont(F_BOLD, FACE, 15, string.byte('b'))
end

------------------------------------------------------------------------------
-- Souris
------------------------------------------------------------------------------

local M = { x = 0, y = 0, prev = false, rprev = false, click = false, rclick = false, shift = false, consumed = false, rconsumed = false, wheel = 0 }

local IS_MAC = reaper.GetOS():match("OSX") ~= nil or reaper.GetOS():match("mac") ~= nil
-- Ctrl (Windows/Linux) ; Ctrl ou Cmd (macOS)
local function borrowModifierDown(cap)
  cap = cap or gfx.mouse_cap
  if IS_MAC then return cap & 32 == 32 or cap & 4 == 4 end
  return cap & 4 == 4
end

local function altModifierDown(cap)
  cap = cap or gfx.mouse_cap
  return cap & 16 == 16
end

local function updateMouse()
  local cap = gfx.mouse_cap
  M.x, M.y = gfx.mouse_x, gfx.mouse_y
  local down, rdown = cap & 1 == 1, cap & 2 == 2
  M.click = down and not M.prev
  M.rclick = rdown and not M.rprev
  M.prev, M.rprev = down, rdown
  M.shift = cap & 8 == 8
  M.consumed, M.rconsumed = false, false
  M.wheel = gfx.mouse_wheel
  gfx.mouse_wheel = 0
end

local clip = { top = 0, bottom = 1e9 }
local function hover(x, y, w, h)
  if M.y < clip.top or M.y >= clip.bottom then return false end
  return M.x >= x and M.x < x + w and M.y >= y and M.y < y + h
end

local function clicked(x, y, w, h)
  if M.click and not M.consumed and hover(x, y, w, h) then M.consumed = true; return true end
  return false
end

local function afterModal()
  -- un menu ou une boîte de dialogue a volé le relâchement du bouton
  M.prev, M.rprev = true, true
end

------------------------------------------------------------------------------
-- Dessin
------------------------------------------------------------------------------

local function fillRect(x, y, w, h, hex, a) setColor(hex, a); gfx.rect(x, y, w, h, 1) end

-- formes carrées (le paramètre r est conservé pour garder les appels lisibles)
local function fillRound(x, y, w, h, r, hex, a)
  setColor(hex, a)
  gfx.rect(math.floor(x), math.floor(y), math.floor(w), math.floor(h), 1)
end

local function strokeRound(x, y, w, h, r, hex, a)
  setColor(hex, a)
  gfx.rect(math.floor(x), math.floor(y), math.floor(w), math.floor(h), 0)
end

-- majuscules avec accents (string.upper ne gère pas l'UTF-8)
local ACCENT_UPPER = { ["é"] = "É", ["è"] = "È", ["ê"] = "Ê", ["ë"] = "Ë", ["à"] = "À", ["â"] = "Â",
  ["ô"] = "Ô", ["î"] = "Î", ["ï"] = "Ï", ["û"] = "Û", ["ù"] = "Ù", ["ç"] = "Ç" }
local function upperFR(str)
  str = str:upper()
  for lower, up in pairs(ACCENT_UPPER) do str = str:gsub(lower, up) end
  return str
end

local function measure(s, font)
  gfx.setfont(font or F_BODY)
  return gfx.measurestr(s)
end

local function ellipsize(s, maxW, font)
  gfx.setfont(font or F_BODY)
  if gfx.measurestr(s) <= maxW then return s end
  while #s > 0 and gfx.measurestr(s .. "…") > maxW do
    -- retire un caractère UTF-8 complet (octets de continuation + octet de tête)
    while #s > 0 and s:byte(-1) >= 0x80 and s:byte(-1) < 0xC0 do s = s:sub(1, -2) end
    s = s:sub(1, -2)
  end
  return s .. "…"
end

-- align : 0 gauche, 1 centre, 2 droite ; centré verticalement dans h
local function drawText(s, x, y, w, h, hex, font, align)
  gfx.setfont(font or F_BODY)
  s = ellipsize(s, w, font)
  local tw, th = gfx.measurestr(s)
  local tx = x
  if align == 1 then tx = x + (w - tw) / 2 elseif align == 2 then tx = x + w - tw end
  setColor(hex)
  gfx.x, gfx.y = math.floor(tx), math.floor(y + (h - th) / 2)
  gfx.drawstr(s)
end

------------------------------------------------------------------------------
-- Widgets
------------------------------------------------------------------------------

local function button(x, y, w, h, label, opts)
  opts = opts or {}
  local hov = hover(x, y, w, h)
  local fill, fg = opts.fill or THEME.surface2, opts.fg or THEME.soft
  if opts.active then fill, fg = THEME.accent, THEME.onAccent
  elseif hov then fill, fg = THEME.hover, THEME.text end
  if opts.ghost and not hov and not opts.active then fill = nil end
  if fill then fillRound(x, y, w, h, opts.radius or 6, fill) end
  local padX = (w < 44) and 1 or 6
  local caretW = opts.caret and 14 or 0
  if label ~= "" then
    drawText(label, x + padX, y, w - 2 * padX - caretW, h, fg, opts.font or F_BODY, opts.align or 1)
  end
  if opts.caret then
    local cx = (label == "") and (x + w / 2) or (x + w - padX - 6)
    local cy = y + h / 2
    setColor(fg)
    gfx.triangle(cx - 4, cy - 2, cx + 4, cy - 2, cx, cy + 3)
  end
  return clicked(x, y, w, h)
end

local function switch(x, y, on)
  local w, h = 32, 18
  fillRound(x, y, w, h, 9, on and THEME.accent or THEME.faint)
  local kx = on and (x + w - h + 2) or (x + 2)
  fillRound(kx, y + 2, h - 4, h - 4, 7, on and THEME.onAccent or THEME.soft)
end

local function toggleRow(x, y, w, label, value, hint)
  local h = 30
  local hov = hover(x, y, w, h)
  if hov then fillRound(x - 6, y, w + 12, h, 6, THEME.surface2) end
  drawText(label, x, y, w - 44, h, value and THEME.text or THEME.soft, F_BODY, 0)
  switch(x + w - 32, y + 6, value)
  if hint then drawText(hint, x, y + h - 2, w, 14, THEME.muted, F_SMALL, 0) end
  if clicked(x - 6, y, w + 12, h) then return not value end
  return value
end

-- renvoie -1, +1 ou 0
local function stepper(x, y, w, label, valueText, labelW)
  local h = 28
  if label then drawText(label, x, y, labelW or (w - 100), h, THEME.soft, F_BODY, 0) end
  local bw = 26
  local vx = x + w - (bw * 2 + 44)
  local r = 0
  if button(vx, y + 2, bw, h - 4, "−", { ghost = false }) then r = -1 end
  drawText(valueText, vx + bw, y, 44, h, THEME.text, F_BOLD, 1)
  if button(vx + bw + 44, y + 2, bw, h - 4, "+") then r = 1 end
  return r
end

local function segmented(x, y, w, h, options, index)
  fillRound(x, y, w, h, 7, THEME.surface2)
  local sw = (w - 4) / #options
  local new = index
  for i, opt in ipairs(options) do
    local sx = x + 2 + (i - 1) * sw
    local active = (i == index)
    if active then fillRound(sx, y + 2, sw, h - 4, 5, THEME.hover) end
    drawText(opt, sx, y, sw, h, active and THEME.text or THEME.muted, F_SMALL, 1)
    if clicked(sx, y, sw, h) then new = i end
  end
  return new
end

local function sectionTitle(x, y, w, label)
  drawText(upperFR(label), x, y, w, 16, THEME.muted, F_LABEL, 0)
  return y + 22
end

------------------------------------------------------------------------------
-- Menus
------------------------------------------------------------------------------

-- entries : { {label=, value=} | {header=label} | {label=, value=, last=true} }
local function showMenu(entries)
  local parts, leaves = {}, {}
  for _, e in ipairs(entries) do
    if e.header then
      parts[#parts + 1] = ">" .. e.header
    else
      local l = e.label
      if e.checked then l = "!" .. l end
      if e.last then l = "<" .. l end
      parts[#parts + 1] = l
      leaves[#leaves + 1] = e.value
    end
  end
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local i = gfx.showmenu(table.concat(parts, "|"))
  afterModal()
  if i and i > 0 then return leaves[i] end
  return nil
end

local POSITION_PRESETS = {
  { "Serrée",                 "1 3 5 7" },
  { "Ouverte",                "1 5 3 7" },
  { "Drop 2",                 "5 1 3 7" },
  { "Drop 3",                 "3 1 5 7" },
  { "Shell",                  "1 3 7" },
  { "Shell inversée",         "1 7 3" },
  { "Sans fondamentale A",    "3 5 7 9" },
  { "Sans fondamentale B",    "7 9 3 5" },
  { "Neuvième / treizième",   "1 5 3 13 9" },
  { "Triade ouverte",         "1 5 3" },
}

local DOUBLING_MENU = {
  { label = "Octave au-dessus",          value = "s12" },
  { label = "Octave en dessous",         value = "s-12" },
  { label = "Deux octaves au-dessus",    value = "s24" },
  { header = "Intervalle chromatique" },
  { label = "Quinte juste +",            value = "s7" },
  { label = "Quarte juste +",            value = "s5" },
  { label = "Tierce majeure +",          value = "s4" },
  { label = "Tierce mineure +",          value = "s3" },
  { label = "Sixte majeure +",           value = "s9" },
  { label = "Sixte mineure +",           value = "s8" },
  { label = "Quinte juste −",            value = "s-7" },
  { label = "Quarte juste −",            value = "s-5", last = true },
  { header = "Intervalle dans la gamme" },
  { label = "Tierce +",                  value = "d2" },
  { label = "Quarte +",                  value = "d3" },
  { label = "Quinte +",                  value = "d4" },
  { label = "Sixte +",                   value = "d5" },
  { label = "Tierce −",                  value = "d-2" },
  { label = "Sixte −",                   value = "d-5", last = true },
  { label = "Personnalisé…",             value = "custom" },
  { label = "Effacer les doublures de cette voix", value = "clear" },
}

local function editCustomPosition()
  local ok, text = reaper.GetUserInputs("ChordMachineGun — position (grave → aigu)", 1,
    "Fonctions (ex. 1 5 3 13 9),extrawidth=180", getCustomPosition())
  afterModal()
  if not ok then return end
  local valid, err = validateCustomPosition(text)
  if not valid then
    reaper.MB("Position invalide : " .. tostring(err) ..
      "\n\nJetons acceptés : 1 (ou R/T/F), 2, 3, 4, 5, 6, 7, 9, 11, 13" ..
      "\nAltérations : b9, #9, #11, b13, b5, #5, b7, 7M (ou maj7)" ..
      "\nSuffixe + : une octave de plus (ex. 5+)", "ChordMachineGun", 0)
    return
  end
  setCustomPosition(text)
  setCustomPositionEnabled(true)
end

local function askCustomDoubling()
  local ok, text = reaper.GetUserInputs("ChordMachineGun — doublure", 1,
    "Demi-tons (ex. 7, -12) ou g+degrés (ex. g2),extrawidth=80", "12")
  afterModal()
  if not ok then return nil end
  text = text:gsub("%s", "")
  local n = text:match("^([%+%-]?%d+)$")
  if n then return "s" .. tonumber(n) end
  n = text:match("^[gGdD]([%+%-]?%d+)$")
  if n then return "d" .. tonumber(n) end
  reaper.MB("Format non reconnu : " .. text, "ChordMachineGun", 0)
  return nil
end

------------------------------------------------------------------------------
-- État de l'interface
------------------------------------------------------------------------------

local ui = {
  panelScroll = 0,
  panelContentH = 0,
  compactView = 1,  -- 1 = accords, 2 = voix (fenêtre étroite)
  frameNo = 0,
  refFrame = -100,
  refCache = nil,
  ccDrag = nil,        -- curseur CC en cours de glissement
  ccLearn = nil,       -- curseur CC en attente d'un contrôleur (Learn)
  ccSeq = nil,         -- dernier message MIDI d'entrée traité
  mod = nil,           -- { kind = "ctrl"|"alt", ctx = ... } quand Ctrl ou Alt est maintenu
  pinApplied = false,
  lastTonic = getScaleTonicNote(),
  lastType = getScaleType(),
}

local PAD, GAP = 16, 3
local PANEL_W = 312
local HEADER_H = 52

------------------------------------------------------------------------------
-- Épingler la fenêtre (toujours au premier plan) — nécessite js_ReaScriptAPI
------------------------------------------------------------------------------

local function windowHandle()
  if not reaper.JS_Window_Find then return nil end
  return reaper.JS_Window_Find("ChordMachineGun", true)
end

local function applyPin()
  local hwnd = windowHandle()
  if not hwnd then return false end
  local docked = gfx.dock(-1) > 0
  reaper.JS_Window_SetZOrder(hwnd, (getWindowPinned() and not docked) and "TOPMOST" or "NOTOPMOST")
  return true
end

local function togglePin()
  if not reaper.JS_Window_SetZOrder then
    reaper.MB("Pour épingler la fenêtre, installe l'extension js_ReaScriptAPI\n" ..
      "(Extensions → ReaPack → Browse packages → « js_ReaScriptAPI »), puis redémarre REAPER.", "ChordMachineGun", 0)
    afterModal()
    return
  end
  setWindowPinned(not getWindowPinned())
  applyPin()
end

local function drawPinIcon(x, y, size, hex)
  -- punaise : tête, collerette, aiguille
  local cx = math.floor(x + size / 2)
  setColor(hex)
  gfx.rect(cx - 4, y + 2, 8, 6, 1)
  gfx.rect(cx - 6, y + 8, 12, 2, 1)
  gfx.rect(cx, y + 10, 1, size - 12, 1)
end

local function pinButton(x, y, w, h)
  local pinned = getWindowPinned()
  local docked = gfx.dock(-1) > 0
  local hov = hover(x, y, w, h)
  if pinned and not docked then fillRect(x, y, w, h, THEME.accent)
  elseif hov then fillRect(x, y, w, h, THEME.hover)
  else fillRect(x, y, w, h, THEME.surface2) end
  local fg = (pinned and not docked) and THEME.onAccent or (docked and THEME.faint or THEME.soft)
  drawPinIcon(x + (w - 20) / 2, y + (h - 20) / 2 + 1, 20, fg)
  if clicked(x, y, w, h) then
    if docked then
      reaper.MB("La fenêtre est ancrée : détache-la (clic droit) pour l'épingler.", "ChordMachineGun", 0)
      afterModal()
    else
      togglePin()
    end
  end
end

------------------------------------------------------------------------------
-- Fenêtre Historique (script séparé : une fenêtre par script dans REAPER)
------------------------------------------------------------------------------

local HISTORY_SCRIPT = scriptPath .. "Todoroki_ChordMachineGun history.lua"

local function historyWindowOpen()
  local t = tonumber(reaper.GetExtState("ChordMachineGun", "historyAlive")) or 0
  return t > 0 and (reaper.time_precise() - t) < 1.0
end

local function toggleHistoryWindow()
  if historyWindowOpen() then
    reaper.SetExtState("ChordMachineGun", "historyCloseRequest", "1", false)
    return
  end
  reaper.SetExtState("ChordMachineGun", "historyCloseRequest", "0", false)
  local cmd = reaper.AddRemoveReaScript(true, 0, HISTORY_SCRIPT, true)
  if cmd and cmd ~= 0 then
    reaper.Main_OnCommand(cmd, 0)
  else
    reaper.MB("Impossible de lancer « ChordMachineGun history.lua ».\nVérifie qu'il est dans le même dossier.", "ChordMachineGun", 0)
    afterModal()
  end
end

------------------------------------------------------------------------------
-- En-tête
------------------------------------------------------------------------------

local function drawHeader(W, compact)
  fillRect(0, 0, W, HEADER_H, THEME.bg)
  local y, h = 14, 28
  local x = PAD
  drawText("ChordMachineGun", x, y, 150, h, THEME.text, F_BOLD, 0)
  x = x + 156

  -- tonique
  local tonic = getScaleTonicNote()
  if button(x, y, 56, h, notes[tonic], { font = F_BOLD, caret = true }) then
    local entries = {}
    for i, n in ipairs(notes) do entries[i] = { label = n, value = i, checked = (i == tonic) } end
    local v = showMenu(entries)
    if v then setScaleTonicAndType(v, nil) end
  end
  x = x + 62

  -- gamme
  local st = getScaleType()
  if button(x, y, 150, h, scales[st].name, { align = 0, caret = true }) then
    local entries = {}
    for i, s in ipairs(scales) do entries[i] = { label = s.name, value = i, checked = (i == st) } end
    local v = showMenu(entries)
    if v then setScaleTonicAndType(nil, v) end
  end
  x = x + 162

  local rightW = 330
  if compact then rightW = rightW + 150 end
  drawText(getScaleNotesText(), x, y, math.max(0, W - x - rightW - PAD), h, THEME.muted, F_SMALL, 0)

  -- vue compacte : bascule Accords / Voix
  if compact then
    ui.compactView = segmented(W - PAD - 330 - 150, y, 140, h, { "Accords", "Voix" }, ui.compactView)
  end

  -- épingle
  pinButton(W - PAD - 30, y, 30, h)

  -- historique
  if button(W - PAD - 30 - 178 - 118, y, 110, h, "Historique", { font = F_SMALL, active = historyWindowOpen() }) then
    toggleHistoryWindow()
  end

  -- octave
  local d = stepper(W - PAD - 30 - 178, y, 170, "Octave", tostring(getOctave()), 60)
  if d < 0 then decrementOctaveAction() elseif d > 0 then incrementOctaveAction() end

  fillRect(PAD, HEADER_H - 1, W - 2 * PAD, 1, THEME.line)
end

------------------------------------------------------------------------------
-- Accord courant + renversement
------------------------------------------------------------------------------

local function drawChordDisplay(x, y, w)
  local h = 62
  local name = getChordText()
  if name == "" then name = "—" end
  drawText(name, x, y + 4, w - 230, 36, THEME.text, F_TITLE, 0)
  drawText(getChordNotesText(), x, y + 40, w - 230, 18, THEME.muted, F_SMALL, 0)

  if ui.mod and ui.mod.ctx then
    local isCtrl = ui.mod.kind == "ctrl"
    local key = isCtrl and (IS_MAC and "Ctrl/Cmd" or "Ctrl") or (IS_MAC and "Option" or "Alt")
    drawText(isCtrl and "DEGRÉS" or "NÉO-RIEMANNIEN", x + w - 220, y + 8, 220, 16, THEME.accent, F_LABEL, 2)
    drawText(isCtrl and ("gamme de " .. ui.mod.ctx.label) or ("transformations de " .. ui.mod.ctx.label),
      x + w - 300, y + 24, 300, 22, THEME.text, F_BOLD, 2)
    drawText(key .. "+1…7 écouter  ·  +Maj insérer", x + w - 300, y + 44, 300, 16, THEME.muted, F_SMALL, 2)
    return y + h
  end

  local s = getSelectedScaleNote()
  local inv = getChordInversionState(s)
  local d = stepper(x + w - 220, y + 10, 220, "Renversement", (inv > 0 and "+" or "") .. inv, 110)
  if d ~= 0 then
    local shift = M.shift
    if d < 0 then
      if shift then decrementChordInversionAction() else decrementChordInversion(); previewScaleChord() end
    else
      if shift then incrementChordInversionAction() else incrementChordInversion(); previewScaleChord() end
    end
  end
  return y + h
end

------------------------------------------------------------------------------
-- Grille d'accords
------------------------------------------------------------------------------

local function drawChordGrid(x, y, w, h, ctx)
  local notesList = ctx and ctx.notes or scaleNotes
  local chordLists = ctx and ctx.chords or scaleChords
  local n = #notesList
  if n == 0 then return end
  local colW = math.floor((w - (n - 1) * GAP) / n)
  local headerH = 24
  local rows = #chords
  local rowH = math.floor((h - headerH - (rows - 1) * GAP) / rows)
  rowH = math.max(18, math.min(36, rowH))

  local selectedScaleNote = ctx and -1 or getSelectedScaleNote()
  local selectedTypes = ctx and getBorrowedChordTypes() or getSelectedChordTypes()

  if ctx then fillRect(x, y - 6, w, 2, THEME.accent) end

  for i = 1, n do
    local cx = x + (i - 1) * (colW + GAP)
    local isSelCol = (i == selectedScaleNote)
    local header = ctx and ctx.headers[i] or getScaleDegreeHeader(i)
    local headerColor = (isSelCol or (ctx and i == 1)) and THEME.accent or THEME.muted
    drawText(ctx and (i .. "  " .. header) or header, cx, y, colW, headerH - 4, headerColor, F_LABEL, 1)

    local inScaleCount = ctx and ctx.inScaleCounts[i] or getNumberOfScaleChordsForScaleNoteIndex(i)
    local selType = tonumber(selectedTypes[i]) or 1
    local noteName = ctx and ctx.names[i] or getScaleNoteName(i)

    for t, chord in ipairs(chordLists[i]) do
      local by = y + headerH + (t - 1) * (rowH + GAP)
      local inScale = t <= inScaleCount
      local isSel = (t == selType)
      local hov = hover(cx, by, colW, rowH)
      local fill, fg

      if isSel and isSelCol then
        fill, fg = THEME.accent, THEME.onAccent
      elseif isSel then
        fill, fg = hov and THEME.hover or THEME.surface2, THEME.text
      elseif inScale then
        fill, fg = hov and THEME.hover or THEME.surface, hov and THEME.text or THEME.soft
      else
        fill, fg = hov and THEME.surface2 or nil, hov and THEME.soft or THEME.faint
      end
      -- en mode emprunt : les accords absents de la gamme principale sont en couleur d'accent
      if ctx and inScale and chordIsOutsideMainScale(notesList[i], chord) and not (isSel and isSelCol) then
        fg = THEME.accent
      end

      if fill then fillRect(cx, by, colW, rowH, fill) end
      if isSel and not isSelCol then fillRect(cx, by, 2, rowH, THEME.accent) end
      drawText(noteName .. chord.display, cx + 4, by, colW - 8, rowH, fg, (isSel and F_BOLD) or F_BODY, 1)

      if clicked(cx, by, colW, rowH) then
        if ctx then
          borrowedChordAction(i, M.shift, t)
        else
          setSelectedScaleNote(i)
          setSelectedChordType(i, t)
          if M.shift then
            playOrInsertScaleChord("scale chord " .. i .. "  (" .. chord.code .. ")")
          else
            previewScaleChord()
          end
        end
      end
    end
  end
end

------------------------------------------------------------------------------
-- Ligne au-dessus de la grille : degrés (Ctrl) ou voisins (Alt)
------------------------------------------------------------------------------

local MOD_ROW_H = 64

local function drawModifierRow(x, y, w)
  local n = 7
  local colW = math.floor((w - (n - 1) * GAP) / n)
  local cellH = 34
  local cy = y + 20

  if not ui.mod or not ui.mod.ctx then
    local ctrlKey = IS_MAC and "Ctrl" or "Ctrl"
    local altKey = IS_MAC and "Option" or "Alt"
    drawText(ctrlKey .. " : degrés    ·    " .. altKey .. " : PLR    ·    flèches : sélectionner    ·    Entrée : jouer    ·    + / − : octave",
      x, y, w, 16, THEME.faint, F_SMALL, 0)
    for k = 1, n do
      local cx = x + (k - 1) * (colW + GAP)
      strokeRound(cx, cy, colW, cellH, 0, THEME.line)
    end
    return y + MOD_ROW_H
  end

  local ctx, isCtrl = ui.mod.ctx, ui.mod.kind == "ctrl"
  if isCtrl then
    drawText("GAMME DE " .. upperFR(ctx.label), x, y, w, 16, THEME.accent, F_LABEL, 0)
  else
    drawText("PLR", x, y, 30, 16, THEME.accent, F_LABEL, 0)
    -- fil d'Ariane : chaque étape est cliquable pour y remonter (sans jouer)
    local steps = {}
    for name in (ctx.trail .. " → "):gmatch("(.-) → ") do steps[#steps + 1] = name end
    local helpW = 380
    local maxX = x + w - helpW - 8
    local first = 1
    gfx.setfont(F_SMALL)
    local function widthFrom(k)
      local tw = 0
      for j = k, #steps do tw = tw + gfx.measurestr(steps[j]) + 22 end
      return tw
    end
    while first < #steps and x + 34 + widthFrom(first) + 18 > maxX do first = first + 1 end
    local tx = x + 34
    if first > 1 then drawText("…", tx, y, 14, 16, THEME.muted, F_SMALL, 0); tx = tx + 16 end
    for j = first, #steps do
      local current = (j == #steps)
      gfx.setfont(current and F_BOLD or F_SMALL)
      local tw = gfx.measurestr(steps[j]) + (current and 4 or 0)
      local hov = (not current) and hover(tx - 2, y - 2, tw + 4, 20)
      drawText(steps[j], tx, y, tw + 2, 16, current and THEME.accent or (hov and THEME.text or THEME.soft), current and F_BOLD or F_SMALL, 0)
      if not current and clicked(tx - 2, y - 2, tw + 4, 20) then plrJumpTo(j) end
      tx = tx + tw
      if not current then drawText("→", tx + 4, y, 14, 16, THEME.faint, F_SMALL, 0); tx = tx + 22 end
    end
    drawText("← → choisir  ·  Entrée / chiffre jouer  ·  ↓ descendre  ·  ↑ remonter", x + w - helpW, y, helpW, 16, THEME.muted, F_SMALL, 2)
  end

  for k = 1, n do
    local cx = x + (k - 1) * (colW + GAP)
    local root = ctx.notes[k]
    if root then
      local chord, label, outside, sub
      if isCtrl then
        local t = getBorrowedChordType(k)
        chord = ctx.chords[k][t] or ctx.chords[k][1]
        label = ctx.names[k] .. chord.display
        outside = chordIsOutsideMainScale(root, chord)
        sub = ctx.headers[k]
      else
        chord = ctx.chords[k][1]
        label = ctx.info[k].op .. "   " .. ctx.headers[k]
        outside = not ctx.info[k].inScale
        sub = ctx.info[k].opName
      end
      local hov = hover(cx, cy, colW, cellH)
      local focused = (not isCtrl) and (k == ctx.focus)
      fillRect(cx, cy, colW, cellH, (hov or focused) and THEME.hover or THEME.surface2)
      fillRect(cx, cy, colW, 2, THEME.accent)
      if focused then
        strokeRound(cx, cy, colW, cellH, 0, THEME.accent)
        strokeRound(cx + 1, cy + 1, colW - 2, cellH - 2, 0, THEME.accent)
      end
      drawText(tostring(k), cx + 6, cy, 14, cellH, THEME.muted, F_LABEL, 0)
      drawText(label, cx + 18, cy + 2, colW - 24, 20, outside and THEME.accent or THEME.text, F_BOLD, 1)
      drawText(sub, cx + 18, cy + 18, colW - 24, 14, THEME.muted, F_SMALL, 1)
      if clicked(cx, cy, colW, cellH) then
        if isCtrl then borrowedChordAction(k, M.shift) else plrAction(k, M.shift, false) end
      end
    end
  end
  return y + MOD_ROW_H
end


------------------------------------------------------------------------------
-- Curseurs CC
------------------------------------------------------------------------------

local CC_MENU = { 1, 2, 4, 5, 7, 10, 11, 64, 71, 72, 73, 74, 91, 93 }

local function ccLabel(cc)
  local n = CC_NAMES[cc]
  return "CC " .. cc .. (n and ("  " .. n) or "")
end

local function chooseCC(current)
  local entries = {}
  for _, cc in ipairs(CC_MENU) do entries[#entries + 1] = { label = ccLabel(cc), value = cc, checked = (cc == current) } end
  entries[#entries + 1] = { label = "Autre…", value = "other" }
  local v = showMenu(entries)
  if v == "other" then
    local ok, txt = reaper.GetUserInputs("ChordMachineGun — CC", 1, "Numéro de CC (0-127)", tostring(current))
    afterModal()
    v = ok and tonumber(txt) or nil
    if v then v = math.max(0, math.min(127, math.floor(v))) end
  end
  return v
end

-- accès communs aux curseurs : 1 et 2 = CC, "vel" = vélocité des notes
local function sliderGet(id)
  if id == "vel" then
    local v = getVelocitySlider()
    return { inp = v.inp, value = v.value, min = 1 }
  end
  local sl = getCCSlider(id)
  sl.min = 0
  return sl
end

local function sliderSet(id, sl)
  if id == "vel" then setVelocitySlider({ inp = sl.inp, value = sl.value }) else setCCSlider(id, sl) end
end

local LEARN_TIMEOUT = 10

local function startLearn(id) ui.ccLearn, ui.ccLearnStart = id, reaper.time_precise() end
local function stopLearn() ui.ccLearn, ui.ccLearnStart = nil, nil end

local function sliderRow(id, x, y, w)
  local sl = sliderGet(id)
  local h = 28

  -- étiquette : choix du CC (curseurs CC) / menu d'entrée (vélocité)
  if id == "vel" then
    if button(x, y, 118, h, "Vélocité", { font = F_SMALL, align = 0, caret = sl.inp >= 0 }) and sl.inp >= 0 then
      local v = showMenu({ { label = "Oublier le contrôleur appris (CC " .. sl.inp .. ")", value = "forget" } })
      if v == "forget" then sl.inp = -1; sliderSet(id, sl) end
    end
  else
    if button(x, y, 118, h, ccLabel(sl.out), { font = F_SMALL, align = 0, caret = true }) then
      local v = chooseCC(sl.out)
      if v then
        local followed = (sl.inp == sl.out)
        sl.out = v
        if followed then sl.inp = v end
        sliderSet(id, sl)
      end
    end
  end

  -- barre
  local bx, bw = x + 124, w - 124 - 34
  local hov = hover(bx, y, bw, h)
  fillRect(bx, y, bw, h, THEME.surface)
  local fw = math.floor(bw * sl.value / 127)
  fillRect(bx, y, fw, h, hov and THEME.accent or THEME.soft, hov and 1 or 0.85)
  drawText(tostring(sl.value), bx + 6, y, bw - 12, h, (fw > 30) and THEME.onAccent or THEME.text, F_BOLD, 0)
  local srcColor = (fw > bw - 70) and THEME.onAccent or THEME.muted
  if id == "vel" then
    if sl.inp >= 0 then drawText("← CC " .. sl.inp, bx, y, bw - 6, h, srcColor, F_SMALL, 2) end
  elseif sl.inp ~= sl.out then
    drawText("← CC " .. sl.inp, bx, y, bw - 6, h, srcColor, F_SMALL, 2)
  end

  local newValue = nil
  if clicked(bx, y, bw, h) then ui.ccDrag = id end
  if ui.ccDrag == id then
    if gfx.mouse_cap & 1 == 1 then
      newValue = math.floor((M.x - bx) / bw * 127 + 0.5)
    else
      ui.ccDrag = nil
    end
  end
  if hov and M.wheel ~= 0 then
    newValue = sl.value + (M.wheel > 0 and 1 or -1) * (M.shift and 10 or 1)
    M.wheel = 0
  end
  if newValue then
    newValue = math.max(sl.min, math.min(127, newValue))
    if newValue ~= sl.value then
      sl.value = newValue
      sliderSet(id, sl)
      if id ~= "vel" then sendCC(sl.out, newValue) end
    end
  end

  -- Learn : le prochain contrôleur touché pilotera ce curseur ; recliquer annule
  local learning = (ui.ccLearn == id)
  if button(x + w - 28, y, 28, h, "L", { font = F_BOLD, active = learning }) then
    if learning then stopLearn() else startLearn(id) end
  end
end

-- contrôleurs MIDI → curseurs (appelé à chaque image)
local function processIncomingCC()
  if ui.ccLearn and reaper.time_precise() - (ui.ccLearnStart or 0) > LEARN_TIMEOUT then stopLearn() end
  if ui.ccSeq == nil then ui.ccSeq = currentInputSeq(); return end
  local events, newest = pollIncomingCC(ui.ccSeq)
  ui.ccSeq = newest
  for _, ev in ipairs(events) do
    if ui.ccLearn then
      local sl = sliderGet(ui.ccLearn)
      sl.inp = ev.cc
      sliderSet(ui.ccLearn, sl)
      stopLearn()
    end
    for _, id in ipairs({ 1, 2, "vel" }) do
      local sl = sliderGet(id)
      if sl.inp == ev.cc then
        local v = math.max(sl.min, ev.value)
        if sl.value ~= v then
          sl.value = v
          sliderSet(id, sl)
          if id ~= "vel" and sl.out ~= sl.inp then sendCC(sl.out, v) end
        end
      end
    end
  end
end

------------------------------------------------------------------------------
-- Panneau Voix
------------------------------------------------------------------------------

local function voiceName(v, total)
  if v == 1 then return (getBassMode() == "root") and "Basse · fond." or "Basse" end
  if v == total and total >= 3 then return "Soprano" end
  return "Voix " .. v
end

local function drawPanel(x, y0, w, h)
  local y = y0 + ui.panelScroll

  -- CC -------------------------------------------------------------------------
  y = sectionTitle(x, y, w, "Contrôleurs")
  sliderRow(1, x, y, w); y = y + 34
  sliderRow(2, x, y, w); y = y + 34
  sliderRow("vel", x, y, w); y = y + 30
  local hint = "glisser · molette (Maj ×10) · L : apprendre"
  if ui.ccLearn then
    local left = math.max(0, math.ceil(LEARN_TIMEOUT - (reaper.time_precise() - (ui.ccLearnStart or 0))))
    hint = "touche un contrôleur MIDI…  (L ou Échap pour annuler · " .. left .. " s)"
  end
  drawText(hint, x, y, w, 16, ui.ccLearn and THEME.accent or THEME.faint, F_SMALL, 0)
  y = y + 26
  fillRect(x, y, w, 1, THEME.line); y = y + 12

  -- CONDUITE DE VOIX ---------------------------------------------------------
  y = sectionTitle(x, y, w, "Conduite de voix")
  local vl = getVoiceLeadingEnabled()
  local nv = toggleRow(x, y, w, "Conduite de voix", vl)
  if nv ~= vl then setVoiceLeadingEnabled(nv); vl = nv end
  y = y + 32

  if vl then
    local src = getReferenceSource()
    local nsrc = segmented(x, y, w, 28, { "Live", "Item MIDI" }, src == "item" and 2 or 1)
    if (nsrc == 2) ~= (src == "item") then
      src = (nsrc == 2) and "item" or "live"
      setReferenceSource(src)
      ui.refFrame = -100
    end
    y = y + 36

    -- accord actuel, analysé en continu
    if ui.frameNo - ui.refFrame >= 4 then
      ui.refCache = describeCurrentReference()
      ui.refFrame = ui.frameNo
    end
    local r = ui.refCache
    local ch = 60
    fillRound(x, y, w, ch, 8, THEME.surface)
    if r then
      local tx = x + 12
      if r.live then
        local pulse = 0.55 + 0.45 * math.abs(math.sin(reaper.time_precise() * 4))
        fillRound(x + 12, y + 13, 8, 8, 4, THEME.accent, pulse)
        tx = x + 28
      end
      drawText(r.name ~= "" and r.name or "?", tx, y + 5, w - 150, 24, THEME.text, F_BOLD, 0)
      drawText(r.source, x + w - 150, y + 5, 138, 24, r.live and THEME.accent or THEME.muted, F_SMALL, 2)
      drawText(r.notes, x + 12, y + 31, w - 120, 22, THEME.muted, F_SMALL, 0)
    else
      drawText(src == "item" and "aucun accord avant le curseur" or "joue un accord…",
        x + 12, y, w - 120, ch, THEME.muted, F_SMALL, 0)
    end
    if button(x + w - 94, y + ch - 28, 52, 22, "Sél.", { font = F_SMALL }) then
      if not setReferenceFromSelectedNotes() then
        reaper.MB("Sélectionne d'abord des notes dans l'éditeur MIDI.", "ChordMachineGun", 0)
        afterModal()
      end
      ui.refFrame = -100
    end
    if button(x + w - 38, y + ch - 28, 30, 22, "↺", { font = F_BODY }) then
      resetVoiceLeadingReference()
      ui.refFrame = -100
    end
    y = y + ch + 4
    drawText(src == "item" and "accord qui précède le curseur (ou chaque accord sélectionné)"
      or "clavier MIDI  ·  lecture  ·  dernier accord ChordMachineGun", x, y, w, 16, THEME.faint, F_SMALL, 0)
    y = y + 24
  end

  local vc = getVoiceCount()
  local d = stepper(x, y, w, "Nombre de voix", vc == 0 and "auto" or tostring(vc))
  if d ~= 0 then
    local order = { 0, 2, 3, 4, 5, 6, 7, 8 }
    local idx = 1
    for k, v in ipairs(order) do if v == vc then idx = k end end
    idx = math.max(1, math.min(#order, idx + d))
    setVoiceCount(order[idx])
  end
  y = y + 36

  -- EMPRUNT ------------------------------------------------------------------
  fillRect(x, y, w, 1, THEME.line); y = y + 12
  y = sectionTitle(x, y, w, "Degrés  (Ctrl)")
  local bmode = (getBorrowMode() == "scale") and 2 or 1
  local nb = segmented(x, y, w, 28, { "Selon l'accord", "Type de la gamme" }, bmode)
  if nb ~= bmode then setBorrowMode(nb == 2 and "scale" or "chord") end
  y = y + 32
  drawText(bmode == 1 and "accord majeur → gamme majeure, mineur → mineure" or "même type que la gamme principale",
    x, y, w, 16, THEME.faint, F_SMALL, 0)
  y = y + 26

  -- POSITION -----------------------------------------------------------------
  fillRect(x, y, w, 1, THEME.line); y = y + 12
  y = sectionTitle(x, y, w, "Position")
  local cp = getCustomPositionEnabled()
  local ncp = toggleRow(x, y, w, "Position personnalisée", cp)
  if ncp ~= cp then setCustomPositionEnabled(ncp); cp = ncp end
  y = y + 34

  -- champ position
  local fieldH = 32
  local pos = getCustomPosition()
  local pretty = pos:gsub("[%s,;]+", "  ·  ")
  local fhov = hover(x, y, w - 40, fieldH)
  fillRound(x, y, w, fieldH, 7, THEME.surface)
  strokeRound(x, y, w, fieldH, 7, fhov and THEME.muted or THEME.line)
  drawText(pretty, x + 12, y, w - 60, fieldH, cp and THEME.text or THEME.muted, F_BOLD, 0)
  drawText("grave → aigu", x + 12, y + fieldH, w, 16, THEME.faint, F_SMALL, 0)
  if clicked(x, y, w - 40, fieldH) then editCustomPosition() end
  if button(x + w - 36, y + 4, 32, fieldH - 8, "", { ghost = true, caret = true }) then
    local entries = {}
    for i, p in ipairs(POSITION_PRESETS) do
      entries[i] = { label = p[1] .. "    " .. p[2], value = p[2], checked = (p[2] == pos) }
    end
    entries[#entries + 1] = { label = "Personnalisée…", value = "__custom" }
    local v = showMenu(entries)
    if v == "__custom" then editCustomPosition()
    elseif v then setCustomPosition(v); setCustomPositionEnabled(true) end
  end
  y = y + fieldH + 20

  local valid, err = validateCustomPosition(pos)
  if cp and not valid then
    drawText("⚠ " .. tostring(err), x, y - 4, w, 16, THEME.danger, F_SMALL, 0)
    y = y + 16
  end

  if cp then
    local ai = getAutoInversion()
    local nai = toggleRow(x, y, w, "Renversement auto", ai)
    if nai ~= ai then setAutoInversion(nai) end
    drawText(vl and "choisit le renversement le plus proche" or "actif avec la conduite de voix",
      x, y + 26, w, 16, THEME.faint, F_SMALL, 0)
    y = y + 50
  end

  -- VOIX, SPLIT MIDI & DOUBLURES ---------------------------------------------
  fillRect(x, y, w, 1, THEME.line); y = y + 12
  y = sectionTitle(x, y, w, "Voix & canaux MIDI")

  drawText("Basse", x, y, 60, 28, THEME.soft, F_BODY, 0)
  local bm = (getBassMode() == "root") and 2 or 1
  local nbm = segmented(x + 64, y, w - 64, 28, { "Note la plus grave", "Fondamentale" }, bm)
  if nbm ~= bm then setBassMode(nbm == 2 and "root" or "lowest") end
  y = y + 36

  -- presets de split
  local mode = getChannelMode()
  drawText("Split", x, y, 60, 28, THEME.soft, F_BODY, 0)
  local presetIndex = ({ single = 1, all = 2, bass = 3 })[mode] or 0
  local np = segmented(x + 64, y, w - 64, 28, { "Aucun", "Toutes", "Basse seule" }, presetIndex)
  if np ~= presetIndex and np >= 1 then setChannelMode(({ "single", "all", "bass" })[np]) end
  y = y + 30
  local modeHint = ({
    single = "toutes les voix sur le canal de l'éditeur MIDI",
    all = "voix 1 → canal 1, voix 2 → canal 2…",
    bass = "basse → canal 1, voix supérieures → canal 2",
    custom = "personnalisé : canal choisi voix par voix",
  })[mode] or ""
  drawText(modeHint, x, y, w, 16, mode == "custom" and THEME.accent or THEME.faint, F_SMALL, 0)
  y = y + 24

  local half = (w - 8) / 2
  local lastVoices = getLastVoices()
  local lastNames = getLastVoiceNames()
  if #lastNames ~= #lastVoices then lastNames = {} end
  local K = #lastVoices
  if K == 0 then
    K = (getVoiceCount() > 0 and getVoiceCount() or 4) + ((getBassMode() == "root") and 1 or 0)
  end
  if button(x, y, half, 28, "Créer les pistes", { font = F_SMALL }) then
    if getChannelMode() == "single" then setChannelMode("all") end
    createRoutedVoiceTracks(K)
  end
  if button(x + half + 8, y, half, 28, "Éclater l'item MIDI", { font = F_SMALL }) then
    explodeTakeToVoiceTracks()
  end
  y = y + 40

  -- liste des voix : canal + doublures (les doublures marchent aussi sans split)
  drawText("Voix (grave → aigu) · canal · doublures", x, y, w - 60, 18, THEME.muted, F_SMALL, 0)
  if button(x + w - 56, y - 2, 56, 20, "effacer", { font = F_SMALL, ghost = true, fg = THEME.muted }) then
    clearDoublings()
  end
  y = y + 24

  local doublings = getDoublings()
  local rowH = 30
  for v = 1, K do
    local ry = y
    fillRect(x, ry, w, rowH - 4, THEME.surface)

    -- canal de la voix (clic : choisir)
    local ch = voiceChannel(v)
    local badge = ch and ("ch " .. (ch + 1)) or "déf."
    local bhov = hover(x, ry, 40, rowH - 4)
    if bhov then fillRect(x, ry, 40, rowH - 4, THEME.hover) end
    drawText(badge, x + 6, ry, 34, rowH - 4, ch and THEME.accent or THEME.muted, F_LABEL, 0)
    if clicked(x, ry, 40, rowH - 4) then
      local entries = { { label = "Canal par défaut (éditeur MIDI)", value = -1, checked = (ch == nil) } }
      for c = 0, 15 do entries[#entries + 1] = { label = "Canal " .. (c + 1), value = c, checked = (ch == c) } end
      local val = showMenu(entries)
      if val then setVoiceChannel(v, (val >= 0) and val or nil, K) end
    end

    drawText(voiceName(v, K), x + 44, ry, 78, rowH - 4, THEME.soft, F_SMALL, 0)
    local pitch = lastVoices[v]
    drawText(lastNames[v] or (pitch and getPitchName(pitch)) or "", x + 122, ry, 36, rowH - 4, THEME.muted, F_SMALL, 0)

    -- puces de doublure
    local cx = x + 160
    local list = doublings[v] or {}
    for k, tok in ipairs(list) do
      local label = doublingLabel(tok)
      local cw = measure(label, F_SMALL) + 14
      if cx + cw > x + w - 30 then
        drawText("…", cx, ry, 12, rowH - 4, THEME.muted, F_SMALL, 0)
        break
      end
      local chov = hover(cx, ry + 4, cw, rowH - 12)
      fillRect(cx, ry + 4, cw, rowH - 12, chov and THEME.danger or THEME.hover)
      drawText(chov and "×" or label, cx, ry + 4, cw, rowH - 12, chov and THEME.onAccent or THEME.text, F_SMALL, 1)
      if clicked(cx, ry + 4, cw, rowH - 12) then removeDoubling(v, k) end
      cx = cx + cw + 4
    end
    if button(x + w - 28, ry + 4, 24, rowH - 12, "+", { font = F_BOLD }) then
      local val = showMenu(DOUBLING_MENU)
      if val == "custom" then val = askCustomDoubling() end
      if val == "clear" then clearDoublings(v)
      elseif val then addDoubling(v, val) end
    end
    y = y + rowH
  end

  ui.panelContentH = (y - ui.panelScroll) - y0 + 8
end

------------------------------------------------------------------------------
-- Clavier (raccourcis d'origine)
------------------------------------------------------------------------------

local function moveEditCursorByGrid(dir)
  local ed = activeMidiEditor()
  if ed then reaper.MIDIEditor_OnCommand(ed, dir < 0 and 40047 or 40048) end
end

-- Avec Ctrl/Alt, REAPER ne transmet pas toujours les chiffres et les flèches à gfx.getchar :
-- on lit donc l'état physique des touches (js_ReaScriptAPI) quand la fenêtre a le focus.
local VK = { left = 0x25, up = 0x26, right = 0x27, down = 0x28, enter = 0x0D }
local vkPrev, vkPrimed = {}, false

local function windowHasFocus()
  local st = gfx.getchar(65536)
  if st and st > 0 then return st & 2 == 2 end
  if reaper.JS_Window_GetFocus and reaper.JS_Window_Find then
    local hwnd = reaper.JS_Window_Find("ChordMachineGun", true)
    local f = reaper.JS_Window_GetFocus()
    return hwnd ~= nil and f ~= nil and (f == hwnd or reaper.JS_Window_IsChild(hwnd, f))
  end
  return false
end

local function physicalKeysAvailable() return type(reaper.JS_VKeys_GetState) == "function" end

-- renvoie la liste des touches nouvellement enfoncées : {digit=n} / {arrow="left"} / {enter=true}
local function pollPhysicalKeys()
  if not physicalKeysAvailable() then return nil end
  local state = reaper.JS_VKeys_GetState(0)
  if type(state) ~= "string" or #state < 0x70 then return nil end
  local events = {}
  local function edge(vk)
    local down = state:byte(vk) ~= 0
    local fired = down and not vkPrev[vk] and vkPrimed
    vkPrev[vk] = down
    return fired
  end
  for d = 1, 7 do
    local top = edge(0x30 + d)
    local pad = edge(0x60 + d)
    if top or pad then events[#events + 1] = { digit = d } end
  end
  for name, vk in pairs(VK) do
    if edge(vk) then
      if name == "enter" then events[#events + 1] = { enter = true } else events[#events + 1] = { arrow = name } end
    end
  end
  vkPrimed = true
  if not windowHasFocus() then return {} end
  return events
end

-- Ctrl : degrés de la gamme de l'accord ; Alt : transformations PLR
local function dispatchModifierEvent(kind, ev, shift)
  if ev.digit then
    if kind == "ctrl" then borrowedChordAction(ev.digit, shift) else plrAction(ev.digit, shift, false) end
    return true
  end
  if kind == "alt" then
    if ev.arrow == "left" then plrMoveFocus(-1)
    elseif ev.arrow == "right" then plrMoveFocus(1)
    elseif ev.enter then plrPlayFocused(shift)          -- jouer (Maj : insérer)
    elseif ev.arrow == "down" then plrDescendFocused()  -- descendre, sans jouer
    elseif ev.arrow == "up" then plrBack(false) end     -- remonter, sans jouer
    return true
  end
  return false
end

local rowKeys = {
  { keys = "1234567", fn = function(i) previewScaleChordAction(i) end },
  { keys = "!@#$%^&", fn = function(i) scaleChordAction(i) end },
  { keys = "qwertyu", fn = function(i) previewHigherScaleNoteAction(i) end },
  { keys = "asdfghj", fn = function(i) previewScaleNoteAction(i) end },
  { keys = "zxcvbnm", fn = function(i) previewLowerScaleNoteAction(i) end },
  { keys = "QWERTYU", fn = function(i) higherScaleNoteAction(i) end },
  { keys = "ASDFGHJ", fn = function(i) scaleNoteAction(i) end },
  { keys = "ZXCVBNM", fn = function(i) lowerScaleNoteAction(i) end },
}

local function handleInput(char)
  if char <= 0 then
    if gfx.mouse_cap & 64 == 64 then stopAllNotesFromPlaying() end
    return
  end
  local cap = gfx.mouse_cap
  local shiftDown = cap & 8 == 8
  local modKind = borrowModifierDown(cap) and "ctrl" or (altModifierDown(cap) and "alt" or nil)

  -- avec Ctrl/Alt et l'extension js : chiffres, flèches et Entrée sont lus physiquement (voir frame)
  if modKind and physicalKeysAvailable() then
    local isDigitish = (char >= 49 and char <= 55) or (char >= 305 and char <= 311) or char == 13
      or char == 1818584692 or char == 1919379572 or char == 30064 or char == 1685026670
      or ("!@#$%^&"):find(string.char(char % 256), 1, true) ~= nil
    if isDigitish then return end
  end

  -- sans l'extension js : décodage de gfx.getchar
  if modKind then
    local d = nil
    local c = char
    if c >= 256 and c < 1024 then c = c % 256 end            -- Alt+touche = code + 256
    if c >= 49 and c <= 55 then d = c - 48 end
    if not d and c < 256 then
      local k = ("!@#$%^&"):find(string.char(c), 1, true)
      if k then d = k; shiftDown = true end
    end
    if not d then
      local macOption = { [161] = 1, [8482] = 2, [163] = 3, [162] = 4, [8734] = 5, [167] = 6, [182] = 7 }
      d = macOption[char]
    end
    local ev = nil
    if d then ev = { digit = d }
    elseif char == 1818584692 then ev = { arrow = "left" }
    elseif char == 1919379572 then ev = { arrow = "right" }
    elseif char == 30064 then ev = { arrow = "up" }
    elseif char == 1685026670 then ev = { arrow = "down" }
    elseif char == 13 then ev = { enter = true } end
    if ev and dispatchModifierEvent(modKind, ev, shiftDown) then return end
  end

  -- flèches : sélectionner sans jouer (Maj + ←/→ : déplacer le curseur d'une grille)
  if char == 1818584692 then if shiftDown then moveEditCursorByGrid(-1) else moveSelection(-1, 0) end; return end
  if char == 1919379572 then if shiftDown then moveEditCursorByGrid(1) else moveSelection(1, 0) end; return end
  if char == 30064 then moveSelection(0, -1); return end
  if char == 1685026670 then moveSelection(0, 1); return end
  -- Entrée : jouer l'accord sélectionné (Maj : insérer)
  if char == 13 then
    if shiftDown then playOrInsertScaleChord("scale chord " .. getSelectedScaleNote()) else previewScaleChord() end
    return
  end
  -- + / − : octave
  if char == 43 or char == 61 then incrementOctaveAction(); return end
  if char == 45 or char == 95 then decrementOctaveAction(); return end
  if char == string.byte("0") then stopAllNotesFromPlaying(); return end

  local shift, cmd, alt, ctrl = cap & 8 == 8, cap & 4 == 4, cap & 16 == 16, cap & 32 == 32
  local ctrlOnly = ctrl and not alt and not cmd
  local altOnly = alt and not ctrl and not cmd
  local cmdOnly = cmd and not alt and not ctrl

  if not (cmd or alt or ctrl) and char < 256 then
    local c = string.char(char)
    for _, row in ipairs(rowKeys) do
      local i = row.keys:find(c, 1, true)
      if i then row.fn(i); return end
    end
  end

  local comma, dot, lt, gt = 44, 46, 60, 62
  if ctrlOnly then
    if char == comma then decrementScaleTonicNoteAction()
    elseif char == dot then incrementScaleTonicNoteAction()
    elseif char == lt then decrementScaleTypeAction()
    elseif char == gt then incrementScaleTypeAction() end
    return
  end

  local windows = osName:match("Win") ~= nil
  if altOnly then
    if windows then
      if char == comma and not shift then halveGridSize()
      elseif char == dot and not shift then doubleGridSize()
      elseif char == comma and shift then decrementOctaveAction()
      elseif char == dot and shift then incrementOctaveAction() end
    else
      if char == comma then halveGridSize()
      elseif char == dot then doubleGridSize()
      elseif char == lt then decrementOctaveAction()
      elseif char == gt then incrementOctaveAction() end
    end
  elseif cmdOnly then
    if windows then
      if char == comma and not shift then decrementChordTypeAction()
      elseif char == dot and not shift then incrementChordTypeAction()
      elseif char == comma and shift then decrementChordInversionAction()
      elseif char == dot and shift then incrementChordInversionAction() end
    else
      if char == comma then decrementChordTypeAction()
      elseif char == dot then incrementChordTypeAction()
      elseif char == lt then decrementChordInversionAction()
      elseif char == gt then incrementChordInversionAction() end
    end
  end
end

------------------------------------------------------------------------------
-- Fenêtre
------------------------------------------------------------------------------

local function saveWindowState()
  local dock, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
  if dock > 0 then
    setDockState(dock)
  else
    setInterfaceXPosition(math.floor(wx))
    setInterfaceYPosition(math.floor(wy))
    if ww and ww > 200 then reaper.SetProjExtState(0, "com.ChordMachineGun", "interfaceW", tostring(math.floor(ww))) end
    if wh and wh > 200 then reaper.SetProjExtState(0, "com.ChordMachineGun", "interfaceH", tostring(math.floor(wh))) end
  end
end

local function dockMenu()
  local docked = gfx.dock(-1) > 0
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local i = gfx.showmenu(docked and "Détacher la fenêtre" or "Ancrer la fenêtre")
  afterModal()
  if i ~= 1 then return end
  if docked then
    saveWindowState()
    setWindowShouldBeDocked(false)
    gfx.dock(0)
    ui.pinApplied = false
  else
    saveWindowState()
    setWindowShouldBeDocked(true)
    gfx.dock(getDockState())
  end
end

local function initWindow()
  local _, ws = reaper.GetProjExtState(0, "com.ChordMachineGun", "interfaceW")
  local _, hs = reaper.GetProjExtState(0, "com.ChordMachineGun", "interfaceH")
  local w, h = tonumber(ws) or 1100, tonumber(hs) or 720
  local x, y = getInterfaceXPosition(), getInterfaceYPosition()
  if x < 0 or y < 0 then
    local _, _, sw, sh = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)
    x, y = math.floor((sw - w) / 2), math.floor((sh - h) / 2)
  end
  local dock = windowShouldBeDocked() and getDockState() or 0
  gfx.clear = 0 -- noir
  gfx.init("ChordMachineGun", w, h, dock, x, y)
  setupFonts()
end

------------------------------------------------------------------------------
-- Boucle
------------------------------------------------------------------------------

local function frame()
  local char = gfx.getchar()
  if char == 27 and ui.ccLearn then stopLearn(); char = 0 end
  if char == -1 or char == 27 then
    saveWindowState()
    gfx.quit()
    return
  end

  -- changement de gamme depuis un script d'action
  if ui.lastTonic ~= getScaleTonicNote() or ui.lastType ~= getScaleType() then
    ui.lastTonic, ui.lastType = getScaleTonicNote(), getScaleType()
    updateScaleData()
  end

  ui.frameNo = ui.frameNo + 1
  updateMouse()
  processIncomingCC()
  local physical = pollPhysicalKeys()
  handleInput(char)
  if physical and #physical > 0 then
    local cap = gfx.mouse_cap
    local kind = borrowModifierDown(cap) and "ctrl" or (altModifierDown(cap) and "alt" or nil)
    if kind then
      for _, ev in ipairs(physical) do dispatchModifierEvent(kind, ev, cap & 8 == 8) end
    end
  end
  if char > 0 or M.click then ui.refFrame = -100 end

  if not ui.pinApplied then ui.pinApplied = true; applyPin() end

  if borrowModifierDown() then
    ui.mod = { kind = "ctrl", ctx = getBorrowedContext() }
  elseif altModifierDown() then
    ui.mod = { kind = "alt", ctx = getPLRContext() }
  else
    ui.mod = nil
  end

  local W, H = gfx.w, gfx.h
  fillRect(0, 0, W, H, THEME.bg)

  local compact = W < 960
  local contentY = HEADER_H + 12
  local footerH = 22

  local showGrid = (not compact) or ui.compactView == 1
  local showPanel = (not compact) or ui.compactView == 2

  -- panneau (dessiné d'abord : l'en-tête le recouvre en défilant)
  if showPanel then
    local pw = compact and math.min(W - 2 * PAD, 520) or PANEL_W
    local px = compact and PAD or (W - PAD - pw)
    local ph = H - contentY - footerH
    if not compact then fillRect(px - PAD / 2 - 1, contentY, 1, ph, THEME.line) end
    clip.top, clip.bottom = contentY, H - footerH
    drawPanel(px + (compact and 0 or 8), contentY, pw - (compact and 0 or 8), ph)
    clip.top, clip.bottom = 0, 1e9

    if hover(px, contentY, pw, ph) and M.wheel ~= 0 then
      ui.panelScroll = ui.panelScroll + (M.wheel > 0 and 40 or -40)
    end
    local minScroll = math.min(0, ph - ui.panelContentH)
    ui.panelScroll = math.max(minScroll, math.min(0, ui.panelScroll))
  end

  if showGrid then
    local gw = compact and (W - 2 * PAD) or (W - 3 * PAD - PANEL_W)
    local y = drawChordDisplay(PAD, contentY, gw)
    y = drawModifierRow(PAD, y + 4, gw)
    drawChordGrid(PAD, y, gw, H - y - footerH, nil)
  end

  -- pied
  fillRect(0, H - footerH, W, footerH, THEME.bg)
  drawText("clic : écouter   ·   Maj + clic : insérer   ·   clic droit : ancrer", PAD, H - footerH, W - 2 * PAD, footerH - 4, THEME.faint, F_SMALL, 0)

  drawHeader(W, compact)

  if M.rclick and not M.rconsumed then dockMenu() end

  gfx.update()
  reaper.defer(frame)
end

initWindow()
reaper.atexit(saveWindowState)
frame()
