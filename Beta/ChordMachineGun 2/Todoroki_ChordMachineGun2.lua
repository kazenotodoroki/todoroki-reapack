-- @noindex
--[[
  ChordMachineGun 2 (beta) — main window.
  Test variant: installs next to ChordMachineGun 1.x, with its own settings and its own
  window. Not published through ReaPack yet (every file is @noindex).
  Needs Todoroki_ChordMachineGun2_core.lua in the same folder.

  New in 2 (see "Todoroki_ChordMachineGun2 README.md"):
    - Colors: 7 / 9 / 11 / 13 / sus2 / sus4 / no3 added to any chord (F1…F7, F8 clears)
    - Insert patterns: arpeggios, Alberti, bass/chord, pulse, with rate and chord length (F9 / F10)
    - Parallel-mode borrowing on the Ctrl row (modal interchange)
    - Film / game scales (Lydian Dominant, Mixolydian b6, Phrygian Dominant, Double Harmonic…)
    - Proper note spelling for every scale
  New in 2.1:
    - Live patterns: the preview plays the arpeggio / pattern in real time, in sync with the transport
    - Quantized chord change: a new chord can wait for the next beat, bar or 2-bar line
    - Reharmonize: selected notes keep their rhythm and move onto the new chord
    - Wiki (F11): most used and most beautiful progressions of every scale, playable and insertable

  Mouse
    click               : play the chord
    Shift + click       : insert the chord (or replace the selected notes)
    right-click (empty) : dock / undock the window
    wheel over panel    : scroll the right panel
  Keys
    1-7 play, Shift+1-7 insert, arrows select, Enter play, +/- octave, 0 stop,
    F1-F8 colors, F9/F10 pattern, F11 wiki, F12 chord change (now / beat / bar / 2 bars),
    Ctrl+1-7 degrees of the chord's scale, Alt+1-7 PLR transformations
]]

local scriptPath = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(scriptPath .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()

-- this window runs the live engine (patterns in real time, queued chord changes)
LiveArp.host = true

------------------------------------------------------------------------------
-- Theme
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
-- Ctrl (Windows/Linux); Ctrl or Cmd (macOS)
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
  -- a menu or dialog swallowed the mouse button release
  M.prev, M.rprev = true, true
end

------------------------------------------------------------------------------
-- Dessin
------------------------------------------------------------------------------

local function fillRect(x, y, w, h, hex, a) setColor(hex, a); gfx.rect(x, y, w, h, 1) end

-- square shapes (the r parameter is kept so calls stay readable)
local function fillRound(x, y, w, h, r, hex, a)
  setColor(hex, a)
  gfx.rect(math.floor(x), math.floor(y), math.floor(w), math.floor(h), 1)
end

local function strokeRound(x, y, w, h, r, hex, a)
  setColor(hex, a)
  gfx.rect(math.floor(x), math.floor(y), math.floor(w), math.floor(h), 0)
end

-- upper case with accents (string.upper does not handle UTF-8)
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
    -- removes a whole UTF-8 character (continuation bytes + lead byte)
    while #s > 0 and s:byte(-1) >= 0x80 and s:byte(-1) < 0xC0 do s = s:sub(1, -2) end
    s = s:sub(1, -2)
  end
  return s .. "…"
end

-- align: 0 left, 1 centre, 2 right; vertically centred in h
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

-- returns -1, +1 or 0
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
  { "Close",                 "1 3 5 7" },
  { "Open",                "1 5 3 7" },
  { "Drop 2",                 "5 1 3 7" },
  { "Drop 3",                 "3 1 5 7" },
  { "Shell",                  "1 3 7" },
  { "Shell inverted",         "1 7 3" },
  { "Rootless A",    "3 5 7 9" },
  { "Rootless B",    "7 9 3 5" },
  { "Ninth / thirteenth",   "1 5 3 13 9" },
  { "Open triad",         "1 5 3" },
}

local DOUBLING_MENU = {
  { label = "Octave above",          value = "s12" },
  { label = "Octave below",         value = "s-12" },
  { label = "Two octaves above",    value = "s24" },
  { header = "Chromatic interval" },
  { label = "Perfect fifth +",            value = "s7" },
  { label = "Perfect fourth +",            value = "s5" },
  { label = "Major third +",          value = "s4" },
  { label = "Minor third +",          value = "s3" },
  { label = "Major sixth +",           value = "s9" },
  { label = "Minor sixth +",           value = "s8" },
  { label = "Perfect fifth −",            value = "s-7" },
  { label = "Perfect fourth −",            value = "s-5", last = true },
  { header = "Scale interval" },
  { label = "Third +",                  value = "d2" },
  { label = "Fourth +",                  value = "d3" },
  { label = "Fifth +",                  value = "d4" },
  { label = "Sixth +",                   value = "d5" },
  { label = "Third −",                  value = "d-2" },
  { label = "Sixth −",                   value = "d-5", last = true },
  { label = "Custom…",             value = "custom" },
  { label = "Clear this voice's doublings", value = "clear" },
}

local function editCustomPosition()
  local ok, text = reaper.GetUserInputs("ChordMachineGun — position (low → high)", 1,
    "Functions (e.g. 1 5 3 13 9),extrawidth=180", getCustomPosition())
  afterModal()
  if not ok then return end
  local valid, err = validateCustomPosition(text)
  if not valid then
    reaper.MB("Invalid position: " .. tostring(err) ..
      "\n\nAccepted tokens: 1 (or R), 2, 3, 4, 5, 6, 7, 9, 11, 13" ..
      "\nAlterations: b9, #9, #11, b13, b5, #5, b7, 7M (or maj7)" ..
      "\nSuffix +: one octave higher (e.g. 5+)", "ChordMachineGun", 0)
    return
  end
  setCustomPosition(text)
  setCustomPositionEnabled(true)
end

local function askCustomDoubling()
  local ok, text = reaper.GetUserInputs("ChordMachineGun — doubling", 1,
    "Semitones (e.g. 7, -12) or d+scale steps (e.g. d2),extrawidth=80", "12")
  afterModal()
  if not ok then return nil end
  text = text:gsub("%s", "")
  local n = text:match("^([%+%-]?%d+)$")
  if n then return "s" .. tonumber(n) end
  n = text:match("^[gGdD]([%+%-]?%d+)$")
  if n then return "d" .. tonumber(n) end
  reaper.MB("Unrecognised format: " .. text, "ChordMachineGun", 0)
  return nil
end

------------------------------------------------------------------------------
-- UI state
------------------------------------------------------------------------------

local ui = {
  panelScroll = 0,
  panelContentH = 0,
  compactView = 1,  -- 1 = chords, 2 = voices (narrow window)
  frameNo = 0,
  refFrame = -100,
  refCache = nil,
  ccDrag = nil,        -- CC slider being dragged
  ccLearn = nil,       -- CC slider waiting for a controller (Learn)
  ccSeq = nil,         -- last processed MIDI input message
  mod = nil,           -- { kind = "ctrl"|"alt", ctx = ... } while Ctrl or Alt is held
  pinApplied = false,
  lastTonic = getScaleTonicNote(),
  lastType = getScaleType(),
  wiki = false,        -- wiki page shown instead of the chord grid
  wikiScroll = 0,
  wikiCache = nil,
  wikiLast = nil,      -- last chord clicked in the wiki
}

local PAD, GAP = 16, 3
local PANEL_W = 312
local HEADER_H = 52

------------------------------------------------------------------------------
-- Pin the window (always on top) — needs js_ReaScriptAPI
------------------------------------------------------------------------------

local function windowHandle()
  if not reaper.JS_Window_Find then return nil end
  return reaper.JS_Window_Find("ChordMachineGun 2", true)
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
    reaper.MB("To pin the window, install the js_ReaScriptAPI extension\n" ..
      "(Extensions → ReaPack → Browse packages → 'js_ReaScriptAPI'), then restart REAPER.", "ChordMachineGun", 0)
    afterModal()
    return
  end
  setWindowPinned(not getWindowPinned())
  applyPin()
end

local function drawPinIcon(x, y, size, hex)
  -- pin: head, collar, needle
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
      reaper.MB("The window is docked: undock it (right-click) to pin it.", "ChordMachineGun", 0)
      afterModal()
    else
      togglePin()
    end
  end
end

------------------------------------------------------------------------------
-- History window (separate script: REAPER allows one window per script)
------------------------------------------------------------------------------

local HISTORY_SCRIPT = scriptPath .. "Todoroki_ChordMachineGun2 history.lua"

local function historyWindowOpen()
  local t = tonumber(reaper.GetExtState("ChordMachineGun2", "historyAlive")) or 0
  return t > 0 and (reaper.time_precise() - t) < 1.0
end

local function toggleHistoryWindow()
  if historyWindowOpen() then
    reaper.SetExtState("ChordMachineGun2", "historyCloseRequest", "1", false)
    return
  end
  reaper.SetExtState("ChordMachineGun2", "historyCloseRequest", "0", false)
  local cmd = reaper.AddRemoveReaScript(true, 0, HISTORY_SCRIPT, true)
  if cmd and cmd ~= 0 then
    reaper.Main_OnCommand(cmd, 0)
  else
    reaper.MB("Could not launch 'Todoroki_ChordMachineGun2 history.lua'.\nMake sure it is in the same folder.", "ChordMachineGun", 0)
    afterModal()
  end
end

------------------------------------------------------------------------------
-- Header
------------------------------------------------------------------------------

local function drawHeader(W, compact)
  fillRect(0, 0, W, HEADER_H, THEME.bg)
  local y, h = 14, 28
  local x = PAD
  local titleW = compact and 62 or 172
  drawText(compact and "CMG 2" or "ChordMachineGun 2", x, y, titleW - 12, h, THEME.text, F_BOLD, 0)
  x = x + titleW

  -- tonique
  local tonic = getScaleTonicNote()
  if button(x, y, 56, h, notes[tonic], { font = F_BOLD, caret = true }) then
    local entries = {}
    for i, n in ipairs(notes) do entries[i] = { label = n, value = i, checked = (i == tonic) } end
    local v = showMenu(entries)
    if v then setScaleTonicAndType(v, nil) end
  end
  x = x + 62

  -- scale
  local st = getScaleType()
  local scaleW = 150
  if compact then scaleW = math.max(70, math.min(150, (W - PAD - 330 - 150) - x - 8 - 60)) end
  if button(x, y, scaleW, h, scales[st].name, { align = 0, caret = true }) then
    local entries = {}
    for i, s in ipairs(scales) do entries[i] = { label = s.name, value = i, checked = (i == st) } end
    local v = showMenu(entries)
    if v then setScaleTonicAndType(nil, v) end
  end
  x = x + scaleW + 6

  -- wiki: progressions of the current scale
  if button(x, y, 54, h, "Wiki", { font = F_SMALL, active = ui.wiki }) then
    ui.wiki = not ui.wiki
    ui.wikiScroll = 0
  end
  x = x + 66

  local rightW = 330
  if compact then rightW = rightW + 150 end
  drawText(getScaleNotesText(), x, y, math.max(0, W - x - rightW - PAD), h, THEME.muted, F_SMALL, 0)

  -- compact view: Chords / Voices switch
  if compact then
    ui.compactView = segmented(W - PAD - 330 - 150, y, 140, h, { "Chords", "Voices" }, ui.compactView)
  end

  -- pin
  pinButton(W - PAD - 30, y, 30, h)

  -- history
  if button(W - PAD - 30 - 178 - 118, y, 110, h, "History", { font = F_SMALL, active = historyWindowOpen() }) then
    toggleHistoryWindow()
  end

  -- octave
  local d = stepper(W - PAD - 30 - 178, y, 170, "Octave", tostring(getOctave()), 60)
  if d < 0 then decrementOctaveAction() elseif d > 0 then incrementOctaveAction() end

  fillRect(PAD, HEADER_H - 1, W - 2 * PAD, 1, THEME.line)
end

------------------------------------------------------------------------------
-- Current chord + inversion
------------------------------------------------------------------------------

local function drawChordDisplay(x, y, w)
  local h = 62
  local name = getChordText()
  if name == "" then name = "—" end
  drawText(name, x, y + 4, w - 230, 36, THEME.text, F_TITLE, 0)
  local notesLine = getChordNotesText()
  if getDroneEnabled() and #getDronePitches() > 0 then
    local d = {}
    for _, p in ipairs(getDronePitches()) do d[#d + 1] = getPitchName(p) end
    notesLine = notesLine .. "      drone  " .. table.concat(d, " ")
  end
  -- chord waiting for the next beat / bar: badge + countdown line
  local live = LiveArp.status()
  local nx = x
  if live and live.pending then
    local label = "QUEUED  ·  " .. (({ beat = "NEXT BEAT", bar = "NEXT BAR", ["2bars"] = "2-BAR LINE" })[live.mode] or "")
    local lw = measure(label, F_LABEL) + 14
    fillRect(x, y + 41, lw, 16, THEME.accent)
    drawText(label, x + 7, y + 41, lw - 14, 16, THEME.onAccent, F_LABEL, 0)
    nx = x + lw + 10
    fillRect(x, y + 60, w - 230, 2, THEME.line)
    fillRect(x, y + 60, math.floor((w - 230) * live.progress), 2, THEME.accent)
  end
  drawText(notesLine, nx, y + 40, w - 230 - (nx - x), 18, THEME.muted, F_SMALL, 0)

  if ui.mod and ui.mod.ctx then
    local isCtrl = ui.mod.kind == "ctrl"
    local key = isCtrl and (IS_MAC and "Ctrl/Cmd" or "Ctrl") or (IS_MAC and "Option" or "Alt")
    drawText(isCtrl and "DEGREES" or "NEO-RIEMANNIAN", x + w - 220, y + 8, 220, 16, THEME.accent, F_LABEL, 2)
    drawText(isCtrl and ("scale of " .. ui.mod.ctx.label) or ("transformations of " .. ui.mod.ctx.label),
      x + w - 300, y + 24, 300, 22, THEME.text, F_BOLD, 2)
    drawText(key .. "+1…7 play  ·  +Shift insert", x + w - 300, y + 44, 300, 16, THEME.muted, F_SMALL, 2)
    return y + h
  end

  local s = getSelectedScaleNote()
  local inv = getChordInversionState(s)
  local d = stepper(x + w - 220, y + 10, 220, "Inversion", (inv > 0 and "+" or "") .. inv, 110)
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
-- Chord grid
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
      -- borrowed mode: chords outside the main scale use the accent colour
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
-- Row above the grid: degrees (Ctrl) or PLR (Alt)
------------------------------------------------------------------------------

local MOD_ROW_H = 64

------------------------------------------------------------------------------
-- Color & pattern strip (v2), between the chord display and the Ctrl/Alt row
------------------------------------------------------------------------------

local function patternName()
  local id = getPattern()
  for _, pt in ipairs(PATTERNS) do if pt.id == id then return pt.name end end
  return "Block chord"
end

local function rateName()
  local id = getPatternRate()
  for _, r in ipairs(RATES) do if r.id == id then return r.name end end
  return "1/8"
end

local function drawPerformanceStrip(x, y, w)
  local h = 26
  local colors = getColors()

  -- colors
  drawText("COLOR", x, y, 50, h, THEME.muted, F_LABEL, 0)
  local cx = x + 52
  for _, name in ipairs(COLOR_NAMES) do
    local cw = (#name > 2) and 46 or 34
    local on = colors[name] == true
    local hov = hover(cx, y, cw, h)
    fillRect(cx, y, cw, h, on and THEME.accent or (hov and THEME.hover or THEME.surface2))
    drawText(name, cx, y, cw, h, on and THEME.onAccent or (hov and THEME.text or THEME.soft), on and F_BOLD or F_SMALL, 1)
    if clicked(cx, y, cw, h) then toggleColor(name) end
    cx = cx + cw + GAP
  end
  if next(colors) ~= nil then
    if button(cx + 2, y, 22, h, "×", { font = F_BOLD, ghost = true, fg = THEME.muted }) then clearColors() end
  end
  cx = cx + 30

  -- pattern controls: on the same row when there is room, otherwise on a second row
  local need = 50 + 118 + 64 + 96 + 86 + 4 * GAP
  local px, py = cx, y
  if cx + need > x + w then px, py = x, y + h + 6 end

  drawText("PATTERN", px, py, 50, h, THEME.muted, F_LABEL, 0)
  px = px + 52
  local block = (getPattern() == "block")
  if button(px, py, 118, h, patternName(), { font = F_SMALL, align = 0, caret = true, active = not block }) then
    local entries = {}
    for k, pt in ipairs(PATTERNS) do entries[k] = { label = pt.name, value = pt.id, checked = (pt.id == getPattern()) } end
    local v = showMenu(entries)
    if v then setPattern(v) end
  end
  px = px + 118 + GAP
  if button(px, py, 64, h, rateName(), { font = F_SMALL, align = 0, caret = true, fg = block and THEME.faint or nil }) then
    local entries = {}
    for k, r in ipairs(RATES) do entries[k] = { label = r.name, value = r.id, checked = (r.id == getPatternRate()) } end
    local v = showMenu(entries)
    if v then setPatternRate(v) end
  end
  px = px + 64 + GAP
  local mult = getLengthMultiplier()
  if button(px, py, 96, h, "Length ×" .. mult, { font = F_SMALL, align = 0, caret = true }) then
    local entries = {}
    for _, m in ipairs({ 1, 2, 3, 4, 6, 8, 12, 16 }) do
      entries[#entries + 1] = { label = "× " .. m .. " grid unit" .. (m > 1 and "s" or ""), value = m, checked = (m == mult) }
    end
    local v = showMenu(entries)
    if v then setLengthMultiplier(v) end
  end
  px = px + 96 + GAP
  local hold = getPatternHoldBass()
  if button(px, py, 86, h, "Hold bass", { font = F_SMALL, active = hold and not block, fg = block and THEME.faint or nil }) then
    setPatternHoldBass(not hold)
  end

  -- play row: live pattern, quantized chord change, what happens to selected notes
  local ry = py + h + 6
  drawText("PLAY", x, ry, 50, h, THEME.muted, F_LABEL, 0)
  local qx = x + 52
  local livePattern = getLivePattern()
  if button(qx, ry, 96, h, "Live pattern", { font = F_SMALL, active = livePattern and not block,
      fg = (block or not livePattern) and THEME.faint or nil }) then
    setLivePattern(not livePattern)
  end
  qx = qx + 96 + GAP
  local changeMode = getChangeMode()
  local changeName = "Now"
  for _, m in ipairs(CHANGE_MODES) do if m.id == changeMode then changeName = m.name end end
  if button(qx, ry, 124, h, "Change: " .. changeName, { font = F_SMALL, align = 0, caret = true, active = changeMode ~= "now" }) then
    local entries = {}
    for k, m in ipairs(CHANGE_MODES) do
      entries[k] = { label = m.name .. "   —   " .. m.hint, value = m.id, checked = (m.id == changeMode) }
    end
    local v = showMenu(entries)
    if v then setChangeMode(v) end
  end
  qx = qx + 124 + GAP
  local reharm = getSelectionMode() == "reharm"
  if button(qx, ry, 168, h, reharm and "Selection: Reharmonize" or "Selection: Replace",
      { font = F_SMALL, align = 0, caret = true, active = reharm }) then
    local v = showMenu({
      { label = "Replace   —   selected chords are replaced by the new chord", value = "replace", checked = not reharm },
      { label = "Reharmonize   —   selected notes keep their rhythm and move onto the new chord", value = "reharm", checked = reharm },
    })
    if v then setSelectionMode(v) end
  end
  qx = qx + 168 + GAP
  if button(qx, ry, 50, h, "Stop", { font = F_SMALL }) then stopAllNotesFromPlaying() end
  qx = qx + 50 + 10
  local status = LiveArp.status()
  if status and x + w - qx > 90 then
    drawText((status.live and "live" or "held") .. "  ·  " .. (status.clockMode == "transport" and "synced to transport" or "free clock"),
      qx, ry, x + w - qx, h, status.live and THEME.accent or THEME.faint, F_SMALL, 2)
  end

  return ry + h + 10
end


local function drawModifierRow(x, y, w)
  local n = 7
  local colW = math.floor((w - (n - 1) * GAP) / n)
  local cellH = 34
  local cy = y + 20

  if not ui.mod or not ui.mod.ctx then
    local ctrlKey = IS_MAC and "Ctrl" or "Ctrl"
    local altKey = IS_MAC and "Option" or "Alt"
    drawText(ctrlKey .. ": degrees    ·    " .. altKey .. ": PLR    ·    arrows: select    ·    Enter: play    ·    + / −: octave",
      x, y, w, 16, THEME.faint, F_SMALL, 0)
    for k = 1, n do
      local cx = x + (k - 1) * (colW + GAP)
      strokeRound(cx, cy, colW, cellH, 0, THEME.line)
    end
    return y + MOD_ROW_H
  end

  local ctx, isCtrl = ui.mod.ctx, ui.mod.kind == "ctrl"
  if isCtrl then
    drawText("SCALE OF " .. upperFR(ctx.label), x, y, w, 16, THEME.accent, F_LABEL, 0)
  else
    drawText("PLR", x, y, 30, 16, THEME.accent, F_LABEL, 0)
    -- breadcrumb: each step can be clicked to go back to it (without playing)
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
    drawText("← → choose  ·  Enter / digit play  ·  ↓ go down  ·  ↑ go up", x + w - helpW, y, helpW, 16, THEME.muted, F_SMALL, 2)
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
-- Wiki page (v2.1): the progressions of the current scale, in the current key
------------------------------------------------------------------------------

local function wrapText(s, maxW, font)
  gfx.setfont(font or F_SMALL)
  local lines, line = {}, ""
  for word in s:gmatch("%S+") do
    local try = (line == "") and word or (line .. " " .. word)
    if line ~= "" and gfx.measurestr(try) > maxW then
      lines[#lines + 1] = line
      line = word
    else
      line = try
    end
  end
  if line ~= "" then lines[#lines + 1] = line end
  return lines
end

local function drawPlayIcon(x, y, w, h, hex, stop)
  setColor(hex)
  local cx, cy = math.floor(x + w / 2), math.floor(y + h / 2)
  if stop then gfx.rect(cx - 4, cy - 4, 9, 9, 1)
  else gfx.triangle(cx - 4, cy - 6, cx - 4, cy + 6, cx + 6, cy) end
end

local function wikiSpecs(progression)
  local sig = getScaleTonicNote() .. "|" .. getScaleType()
  if not ui.wikiCache or ui.wikiCache.sig ~= sig then ui.wikiCache = { sig = sig, items = {} } end
  local specs = ui.wikiCache.items[progression]
  if not specs then
    specs = wikiChords(progression)
    ui.wikiCache.items[progression] = specs
  end
  return specs
end

local function drawWikiRow(x, y, w, h, pr, key)
  fillRect(x, y, w, h, THEME.surface)
  local nameW = math.max(120, math.min(210, math.floor(w * 0.27)))
  drawText(pr[1], x + 10, y + 4, nameW - 14, 20, THEME.text, F_BOLD, 0)
  drawText(pr[4] or pr[2], x + 10, y + 23, nameW - 14, 16, THEME.muted, F_SMALL, 0)

  local specs = wikiSpecs(pr[2])
  local n = math.max(1, #specs)
  local btnW = 30 + GAP + 58
  local ax = x + nameW
  local avail = w - nameW - btnW - 14
  local chipW = math.max(24, math.min(88, math.floor((avail - (n - 1) * GAP) / n)))
  local seq = LiveArp.sequence
  for k, spec in ipairs(specs) do
    local cx = ax + (k - 1) * (chipW + GAP)
    local playingNow = seq ~= nil and seq.key == key and seq.index == k
    local hov = hover(cx, y + 3, chipW, h - 6)
    fillRect(cx, y + 3, chipW, h - 6, playingNow and THEME.accent or (hov and THEME.hover or THEME.surface2))
    if ui.wikiLast == key .. ":" .. k and not playingNow then fillRect(cx, y + h - 5, chipW, 2, THEME.accent) end
    drawText(spec.roman, cx + 2, y + 5, chipW - 4, 14, playingNow and THEME.onAccent or THEME.muted, F_LABEL, 1)
    drawText(spec.name, cx + 2, y + 19, chipW - 4, 20,
      playingNow and THEME.onAccent or (spec.outside and THEME.accent or THEME.text), F_BOLD, 1)
    if clicked(cx, y + 3, chipW, h - 6) then
      wikiPlay(spec, M.shift, pr[1])
      ui.wikiLast = key .. ":" .. k
    end
  end

  -- listen (one chord per bar) / write the whole progression
  local bx = x + w - btnW - 6
  local active = seq ~= nil and seq.key == key
  local hov = hover(bx, y + 8, 30, h - 16)
  fillRect(bx, y + 8, 30, h - 16, active and THEME.accent or (hov and THEME.hover or THEME.surface2))
  drawPlayIcon(bx, y + 8, 30, h - 16, active and THEME.onAccent or (hov and THEME.text or THEME.soft), active)
  if clicked(bx, y + 8, 30, h - 16) then wikiAudition(specs, pr[1], key) end
  if button(bx + 30 + GAP, y + 8, 58, h - 16, "Insert", { font = F_SMALL }) then
    if not wikiInsertProgression(specs, pr[1]) then
      reaper.MB("Open a MIDI item in the MIDI editor first.", "ChordMachineGun 2", 0)
      afterModal()
    end
  end
end

local function drawWiki(x, y, w, h)
  local y0 = y
  local st = getScaleType()
  local page = getWiki(st)
  local tonicName = getScaleNoteName(1) or notes[getScaleTonicNote()]
  fillRect(x, y - 6, w, 2, THEME.accent)
  drawText("WIKI  ·  " .. upperFR(tonicName .. " " .. scales[st].name), x, y, w - 80, 18, THEME.accent, F_LABEL, 0)
  if button(x + w - 64, y - 2, 64, 22, "Close", { font = F_SMALL }) then ui.wiki = false end
  y = y + 24
  if not page then
    drawText("No page for this scale yet.", x, y, w, 20, THEME.muted, F_SMALL, 0)
    return
  end
  for _, line in ipairs(wrapText(page.about, w, F_SMALL)) do
    drawText(line, x, y, w, 17, THEME.soft, F_SMALL, 0)
    y = y + 17
  end
  y = y + 4
  drawText("click: play  ·  Shift + click: insert  ·  triangle: listen, one chord per bar  ·  Insert: write the whole progression  ·  blue: outside the scale",
    x, y, w, 16, THEME.faint, F_SMALL, 0)
  y = y + 24

  local top, bottom = y, y0 + h
  local rowH, headH = 42, 24
  local contentH = 2 * headH + #page.progressions * rowH
  if hover(x, top, w, bottom - top) and M.wheel ~= 0 then
    ui.wikiScroll = ui.wikiScroll + (M.wheel > 0 and rowH or -rowH)
    M.wheel = 0
  end
  ui.wikiScroll = math.max(math.min(0, (bottom - top) - contentH), math.min(0, ui.wikiScroll))

  clip.top, clip.bottom = top, bottom
  local cy = top + ui.wikiScroll
  local hidden = false
  for _, sec in ipairs({ { "c", "MOST USED" }, { "b", "MOST BEAUTIFUL" } }) do
    if cy >= top and cy + headH <= bottom then
      drawText(sec[2], x, cy + 6, w, 16, THEME.muted, F_LABEL, 0)
    end
    cy = cy + headH
    for index, pr in ipairs(page.progressions) do
      if pr[3] == sec[1] then
        if cy >= top and cy + rowH <= bottom then
          drawWikiRow(x, cy, w, rowH - 2 * GAP, pr, st .. "#" .. index)
        elseif cy + rowH > bottom then
          hidden = true
        end
        cy = cy + rowH
      end
    end
  end
  clip.top, clip.bottom = 0, 1e9
  if hidden then drawText("scroll for more  ↓", x, bottom - 16, w, 16, THEME.muted, F_SMALL, 2) end
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
  entries[#entries + 1] = { label = "Other…", value = "other" }
  local v = showMenu(entries)
  if v == "other" then
    local ok, txt = reaper.GetUserInputs("ChordMachineGun — CC", 1, "CC number (0-127)", tostring(current))
    afterModal()
    v = ok and tonumber(txt) or nil
    if v then v = math.max(0, math.min(127, math.floor(v))) end
  end
  return v
end

-- common slider access: 1 and 2 = CC, "vel" = note velocity
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

  -- label: CC choice (CC sliders) / input menu (velocity)
  if id == "vel" then
    if button(x, y, 118, h, "Velocity", { font = F_SMALL, align = 0, caret = sl.inp >= 0 }) and sl.inp >= 0 then
      local v = showMenu({ { label = "Forget learned controller (CC " .. sl.inp .. ")", value = "forget" } })
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

  -- Learn: the next controller moved drives this slider; click again to cancel
  local learning = (ui.ccLearn == id)
  if button(x + w - 28, y, 28, h, "L", { font = F_BOLD, active = learning }) then
    if learning then stopLearn() else startLearn(id) end
  end
end

-- MIDI controllers → sliders (called every frame)
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
-- Drone section
------------------------------------------------------------------------------

local function droneAddMenu()
  local octave = getOctave()
  local tonic = scaleNotes[1] and (scaleNotes[1] + octave * 12 - 1) or 48
  local i = getSelectedScaleNote()
  local root = scaleNotes[i] and (scaleNotes[i] + octave * 12 - 1) or tonic
  local entries = {
    { label = "Scale tonic  (" .. getPitchName(tonic) .. ")", value = "tonic" },
    { label = "Scale fifth  (" .. getPitchName(tonic + 7) .. ")", value = "fifth" },
    { label = "Tonic + fifth  (" .. getPitchName(tonic) .. " " .. getPitchName(tonic + 7) .. ")", value = "both" },
    { label = "Selected chord root  (" .. getPitchName(root) .. ")", value = "root" },
    { label = "Notes of the current chord", value = "chord" },
    { label = "Selected notes in the MIDI editor", value = "selection" },
    { label = "Type notes…  (e.g. C2 G2)", value = "type" },
  }
  local v = showMenu(entries)
  if v == "tonic" then addDronePitch(tonic)
  elseif v == "fifth" then addDronePitch(tonic + 7)
  elseif v == "both" then addDronePitch(tonic); addDronePitch(tonic + 7)
  elseif v == "root" then addDronePitch(root)
  elseif v == "chord" then
    local t = getDronePitches()
    for _, p in ipairs(getLastVoices()) do t[#t + 1] = p end
    setDronePitches(t)
  elseif v == "selection" then
    local take = activeTake()
    local t = getDronePitches()
    local found = false
    if take then
      for k = 0, getNumberOfNotes() - 1 do
        local _, sel, _, _, _, _, pitch = reaper.MIDI_GetNote(take, k)
        if sel then t[#t + 1] = pitch; found = true end
      end
    end
    if found then setDronePitches(t)
    else reaper.MB("Select notes in the MIDI editor first.", "ChordMachineGun", 0); afterModal() end
  elseif v == "type" then
    local current = {}
    for _, p in ipairs(getDronePitches()) do current[#current + 1] = getPitchName(p) end
    local ok, text = reaper.GetUserInputs("ChordMachineGun — drone notes", 1,
      "Notes (e.g. C2 G2, or MIDI numbers),extrawidth=160", table.concat(current, " "))
    afterModal()
    if ok then
      local list, bad = parsePitchList(text)
      if list then setDronePitches(list)
      else reaper.MB("Unknown note: " .. tostring(bad) .. "\n\nUse names like C2, F#1, Bb3 (C4 = middle C) or MIDI numbers.", "ChordMachineGun", 0); afterModal() end
    end
  end
end

local function drawDroneSection(x, y, w)
  y = sectionTitle(x, y, w, "Drone")
  local on = getDroneEnabled()
  local non = toggleRow(x, y, w, "Drone", on)
  if non ~= on then setDroneEnabled(non); on = non end
  y = y + 34

  -- notes: chips (click = remove) + add button
  local rowH = 28
  local cx = x
  local pitches = getDronePitches()
  if #pitches == 0 then
    drawText("no drone notes yet", x, y, w - 40, rowH, THEME.faint, F_SMALL, 0)
  end
  for _, p in ipairs(pitches) do
    local label = getPitchName(p)
    local cw = measure(label, F_BOLD) + 18
    if cx + cw > x + w - 36 then
      drawText("…", cx, y, 14, rowH, THEME.muted, F_SMALL, 0)
      break
    end
    local hov = hover(cx, y, cw, rowH)
    fillRect(cx, y, cw, rowH, hov and THEME.danger or (on and THEME.accent or THEME.hover))
    drawText(hov and "×" or label, cx, y, cw, rowH, (hov or on) and THEME.onAccent or THEME.soft, F_BOLD, 1)
    if clicked(cx, y, cw, rowH) then removeDronePitch(p) end
    cx = cx + cw + 4
  end
  if button(x + w - 30, y, 30, rowH, "+", { font = F_BOLD }) then droneAddMenu() end
  y = y + rowH + 8

  -- channel + clear
  local ch = getDroneChannel()
  drawText("Channel", x, y, 70, 26, THEME.soft, F_SMALL, 0)
  if button(x + 70, y, 120, 26, (ch >= 0) and ("Channel " .. (ch + 1)) or "Default", { font = F_SMALL, align = 0, caret = true }) then
    local entries = { { label = "Default channel (MIDI editor)", value = -1, checked = (ch < 0) } }
    for c = 0, 15 do entries[#entries + 1] = { label = "Channel " .. (c + 1), value = c, checked = (ch == c) } end
    local v = showMenu(entries)
    if v then setDroneChannel(v) end
  end
  if #pitches > 0 and button(x + w - 64, y, 64, 26, "clear", { font = F_SMALL, ghost = true, fg = THEME.muted }) then
    setDronePitches({})
  end
  y = y + 32

  local hold = getDroneHold()
  local nhold = toggleRow(x, y, w, "Hold between chords", hold)
  if nhold ~= hold then setDroneHold(nhold) end
  y = y + 30
  drawText(nhold and "held in preview · written under inserted chords"
    or "replayed with each chord · written under inserted chords", x, y, w, 16, THEME.faint, F_SMALL, 0)
  y = y + 18
  drawText("ignored by voice leading", x, y, w, 16, THEME.faint, F_SMALL, 0)
  y = y + 26
  fillRect(x, y, w, 1, THEME.line)
  return y + 12
end

------------------------------------------------------------------------------
-- Voices panel
------------------------------------------------------------------------------

local function voiceName(v, total)
  if v == 1 then return (getBassMode() == "root") and "Bass · root" or "Bass" end
  if v == total and total >= 3 then return "Soprano" end
  return "Voice " .. v
end

local function drawPanel(x, y0, w, h)
  local y = y0 + ui.panelScroll

  -- CC -------------------------------------------------------------------------
  y = sectionTitle(x, y, w, "Controllers")
  sliderRow(1, x, y, w); y = y + 34
  sliderRow(2, x, y, w); y = y + 34
  sliderRow("vel", x, y, w); y = y + 30
  local hint = "drag · wheel (Shift ×10) · L: learn"
  if ui.ccLearn then
    local left = math.max(0, math.ceil(LEARN_TIMEOUT - (reaper.time_precise() - (ui.ccLearnStart or 0))))
    hint = "move a MIDI controller…  (L or Esc to cancel · " .. left .. " s)"
  end
  drawText(hint, x, y, w, 16, ui.ccLearn and THEME.accent or THEME.faint, F_SMALL, 0)
  y = y + 26
  fillRect(x, y, w, 1, THEME.line); y = y + 12

  -- DRONE ----------------------------------------------------------------------
  y = drawDroneSection(x, y, w)

  -- VOICE LEADING ------------------------------------------------------------
  y = sectionTitle(x, y, w, "Voice leading")
  local vl = getVoiceLeadingEnabled()
  local nv = toggleRow(x, y, w, "Voice leading", vl)
  if nv ~= vl then setVoiceLeadingEnabled(nv); vl = nv end
  y = y + 32

  if vl then
    local src = getReferenceSource()
    local nsrc = segmented(x, y, w, 28, { "Live", "MIDI item" }, src == "item" and 2 or 1)
    if (nsrc == 2) ~= (src == "item") then
      src = (nsrc == 2) and "item" or "live"
      setReferenceSource(src)
      ui.refFrame = -100
    end
    y = y + 36

    -- current chord, analysed continuously
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
      drawText(src == "item" and "no chord before the cursor" or "play a chord…",
        x + 12, y, w - 120, ch, THEME.muted, F_SMALL, 0)
    end
    if button(x + w - 94, y + ch - 28, 52, 22, "Sel.", { font = F_SMALL }) then
      if not setReferenceFromSelectedNotes() then
        reaper.MB("Select notes in the MIDI editor first.", "ChordMachineGun", 0)
        afterModal()
      end
      ui.refFrame = -100
    end
    if button(x + w - 38, y + ch - 28, 30, 22, "↺", { font = F_BODY }) then
      resetVoiceLeadingReference()
      ui.refFrame = -100
    end
    y = y + ch + 4
    drawText(src == "item" and "chord before the cursor (or each selected chord)"
      or "MIDI keyboard  ·  playback  ·  last chord", x, y, w, 16, THEME.faint, F_SMALL, 0)
    y = y + 24
  end

  local vc = getVoiceCount()
  local d = stepper(x, y, w, "Voices", vc == 0 and "auto" or tostring(vc))
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
  y = sectionTitle(x, y, w, "Degrees  (Ctrl)")
  local bmode = ({ chord = 1, scale = 2, parallel = 3 })[getBorrowMode()] or 1
  local nb = segmented(x, y, w, 28, { "From chord", "Scale type", "Parallel" }, bmode)
  if nb ~= bmode then setBorrowMode(({ "chord", "scale", "parallel" })[nb]); bmode = nb end
  y = y + 32
  if bmode == 3 then
    -- modal interchange: another mode on the same tonic (bVI, bVII, iv… in one key press)
    local pst = getParallelScaleType()
    local tonicName = getScaleNoteName(1)
    if button(x, y, w, 26, tonicName .. " " .. scales[pst].name, { font = F_SMALL, align = 0, caret = true }) then
      local entries = {}
      for k, sc in ipairs(scales) do
        entries[k] = { label = tonicName .. " " .. sc.name, value = k, checked = (k == pst) }
      end
      local v = showMenu(entries)
      if v then setParallelScaleType(v) end
    end
    y = y + 30
    drawText("chords borrowed from a parallel mode (same tonic)", x, y, w, 16, THEME.faint, F_SMALL, 0)
  else
    drawText(bmode == 1 and "major chord → major scale, minor → minor" or "same type as the main scale",
      x, y, w, 16, THEME.faint, F_SMALL, 0)
  end
  y = y + 26

  -- POSITION -----------------------------------------------------------------
  fillRect(x, y, w, 1, THEME.line); y = y + 12
  y = sectionTitle(x, y, w, "Position")
  local cp = getCustomPositionEnabled()
  local ncp = toggleRow(x, y, w, "Custom position", cp)
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
  drawText("low → high", x + 12, y + fieldH, w, 16, THEME.faint, F_SMALL, 0)
  if clicked(x, y, w - 40, fieldH) then editCustomPosition() end
  if button(x + w - 36, y + 4, 32, fieldH - 8, "", { ghost = true, caret = true }) then
    local entries = {}
    for i, p in ipairs(POSITION_PRESETS) do
      entries[i] = { label = p[1] .. "    " .. p[2], value = p[2], checked = (p[2] == pos) }
    end
    entries[#entries + 1] = { label = "Custom…", value = "__custom" }
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
    local nai = toggleRow(x, y, w, "Auto inversion", ai)
    if nai ~= ai then setAutoInversion(nai) end
    drawText(vl and "picks the closest inversion" or "active with voice leading",
      x, y + 26, w, 16, THEME.faint, F_SMALL, 0)
    y = y + 50
  end

  -- VOICES, MIDI SPLIT & DOUBLINGS -------------------------------------------
  fillRect(x, y, w, 1, THEME.line); y = y + 12
  y = sectionTitle(x, y, w, "Voices & MIDI channels")

  drawText("Bass", x, y, 60, 28, THEME.soft, F_BODY, 0)
  local bm = (getBassMode() == "root") and 2 or 1
  local nbm = segmented(x + 64, y, w - 64, 28, { "Lowest note", "Root" }, bm)
  if nbm ~= bm then setBassMode(nbm == 2 and "root" or "lowest") end
  y = y + 36

  -- presets de split
  local mode = getChannelMode()
  drawText("Split", x, y, 60, 28, THEME.soft, F_BODY, 0)
  local presetIndex = ({ single = 1, all = 2, bass = 3 })[mode] or 0
  local np = segmented(x + 64, y, w - 64, 28, { "None", "All", "Bass only" }, presetIndex)
  if np ~= presetIndex and np >= 1 then setChannelMode(({ "single", "all", "bass" })[np]) end
  y = y + 30
  local modeHint = ({
    single = "all voices on the MIDI editor channel",
    all = "voice 1 → channel 1, voice 2 → channel 2…",
    bass = "bass → channel 1, upper voices → channel 2",
    custom = "custom: channel chosen per voice",
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
  if button(x, y, half, 28, "Create tracks", { font = F_SMALL }) then
    if getChannelMode() == "single" then setChannelMode("all") end
    createRoutedVoiceTracks(K)
  end
  if button(x + half + 8, y, half, 28, "Explode MIDI item", { font = F_SMALL }) then
    explodeTakeToVoiceTracks()
  end
  y = y + 40

  -- voice list: channel + doublings (doublings also work without split)
  drawText("Voices (low → high) · channel · doublings", x, y, w - 60, 18, THEME.muted, F_SMALL, 0)
  if button(x + w - 56, y - 2, 56, 20, "clear", { font = F_SMALL, ghost = true, fg = THEME.muted }) then
    clearDoublings()
  end
  y = y + 24

  local doublings = getDoublings()
  local rowH = 30
  for v = 1, K do
    local ry = y
    fillRect(x, ry, w, rowH - 4, THEME.surface)

    -- voice channel (click: choose)
    local ch = voiceChannel(v)
    local badge = ch and ("ch " .. (ch + 1)) or "def."
    local bhov = hover(x, ry, 40, rowH - 4)
    if bhov then fillRect(x, ry, 40, rowH - 4, THEME.hover) end
    drawText(badge, x + 6, ry, 34, rowH - 4, ch and THEME.accent or THEME.muted, F_LABEL, 0)
    if clicked(x, ry, 40, rowH - 4) then
      local entries = { { label = "Default channel (MIDI editor)", value = -1, checked = (ch == nil) } }
      for c = 0, 15 do entries[#entries + 1] = { label = "Channel " .. (c + 1), value = c, checked = (ch == c) } end
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
-- Keyboard (original shortcuts)
------------------------------------------------------------------------------

local function moveEditCursorByGrid(dir)
  local ed = activeMidiEditor()
  if ed then reaper.MIDIEditor_OnCommand(ed, dir < 0 and 40047 or 40048) end
end

-- With Ctrl/Alt held, REAPER does not always pass digits and arrows to gfx.getchar,
-- so the physical key state is read (js_ReaScriptAPI) while the window has focus.
local VK = { left = 0x25, up = 0x26, right = 0x27, down = 0x28, enter = 0x0D }
local vkPrev, vkPrimed = {}, false

local function windowHasFocus()
  local st = gfx.getchar(65536)
  if st and st > 0 then return st & 2 == 2 end
  if reaper.JS_Window_GetFocus and reaper.JS_Window_Find then
    local hwnd = reaper.JS_Window_Find("ChordMachineGun 2", true)
    local f = reaper.JS_Window_GetFocus()
    return hwnd ~= nil and f ~= nil and (f == hwnd or reaper.JS_Window_IsChild(hwnd, f))
  end
  return false
end

local function physicalKeysAvailable() return type(reaper.JS_VKeys_GetState) == "function" end

-- returns newly pressed keys: {digit=n} / {arrow="left"} / {enter=true}
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

-- Ctrl: degrees of the chord's scale; Alt: PLR transformations
local function dispatchModifierEvent(kind, ev, shift)
  if ev.digit then
    if kind == "ctrl" then borrowedChordAction(ev.digit, shift) else plrAction(ev.digit, shift, false) end
    return true
  end
  if kind == "alt" then
    if ev.arrow == "left" then plrMoveFocus(-1)
    elseif ev.arrow == "right" then plrMoveFocus(1)
    elseif ev.enter then plrPlayFocused(shift)          -- play (Shift: insert)
    elseif ev.arrow == "down" then plrDescendFocused()  -- go down, without playing
    elseif ev.arrow == "up" then plrBack(false) end     -- go up, without playing
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

  -- F1…F7: colors · F8: clear colors · F9 / F10: previous / next insert pattern
  if char >= 26161 and char <= 26167 then toggleColor(COLOR_NAMES[char - 26160]); return end
  if char == 26168 then clearColors(); return end
  if char == 26169 then cyclePattern(-1); return end
  if char == 6697264 then cyclePattern(1); return end
  if char == 6697265 then ui.wiki = not ui.wiki; ui.wikiScroll = 0; return end   -- F11
  if char == 6697266 then cycleChangeMode(1); return end                        -- F12

  -- with Ctrl/Alt and the js extension: digits, arrows and Enter are read physically (see frame)
  if modKind and physicalKeysAvailable() then
    local isDigitish = (char >= 49 and char <= 55) or (char >= 305 and char <= 311) or char == 13
      or char == 1818584692 or char == 1919379572 or char == 30064 or char == 1685026670
      or ("!@#$%^&"):find(string.char(char % 256), 1, true) ~= nil
    if isDigitish then return end
  end

  -- without the js extension: decode gfx.getchar
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

  -- arrows: select without playing (Shift + ←/→: move the edit cursor by one grid step)
  if char == 1818584692 then if shiftDown then moveEditCursorByGrid(-1) else moveSelection(-1, 0) end; return end
  if char == 1919379572 then if shiftDown then moveEditCursorByGrid(1) else moveSelection(1, 0) end; return end
  if char == 30064 then moveSelection(0, -1); return end
  if char == 1685026670 then moveSelection(0, 1); return end
  -- Enter: play the selected chord (Shift: insert)
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
-- Window
------------------------------------------------------------------------------

local function saveWindowState()
  local dock, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
  if dock > 0 then
    setDockState(dock)
  else
    setInterfaceXPosition(math.floor(wx))
    setInterfaceYPosition(math.floor(wy))
    if ww and ww > 200 then reaper.SetProjExtState(0, "com.ChordMachineGun2", "interfaceW", tostring(math.floor(ww))) end
    if wh and wh > 200 then reaper.SetProjExtState(0, "com.ChordMachineGun2", "interfaceH", tostring(math.floor(wh))) end
  end
end

local function dockMenu()
  local docked = gfx.dock(-1) > 0
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local i = gfx.showmenu(docked and "Undock window" or "Dock window")
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
  local _, ws = reaper.GetProjExtState(0, "com.ChordMachineGun2", "interfaceW")
  local _, hs = reaper.GetProjExtState(0, "com.ChordMachineGun2", "interfaceH")
  local w, h = tonumber(ws) or 1100, tonumber(hs) or 780
  local x, y = getInterfaceXPosition(), getInterfaceYPosition()
  if x < 0 or y < 0 then
    local _, _, sw, sh = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)
    x, y = math.floor((sw - w) / 2), math.floor((sh - h) / 2)
  end
  local dock = windowShouldBeDocked() and getDockState() or 0
  gfx.clear = 0 -- noir
  gfx.init("ChordMachineGun 2", w, h, dock, x, y)
  setupFonts()
end

------------------------------------------------------------------------------
-- Boucle
------------------------------------------------------------------------------

local function frame()
  local char = gfx.getchar()
  if char == 27 and ui.ccLearn then stopLearn(); char = 0 end
  if char == -1 or char == 27 then
    LiveArp.shutdown()
    saveWindowState()
    gfx.quit()
    return
  end

  -- scale changed from an action script
  if ui.lastTonic ~= getScaleTonicNote() or ui.lastType ~= getScaleType() then
    ui.lastTonic, ui.lastType = getScaleTonicNote(), getScaleType()
    updateScaleData()
  end

  ui.frameNo = ui.frameNo + 1
  updateMouse()
  processIncomingCC()
  LiveArp.tick()
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

  -- panel (drawn first: the header covers it when scrolling)
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
    y = drawPerformanceStrip(PAD, y + 4, gw)
    if ui.wiki then
      drawWiki(PAD, y + 8, gw, H - y - 8 - footerH)
    else
      y = drawModifierRow(PAD, y, gw)
      drawChordGrid(PAD, y, gw, H - y - footerH, nil)
    end
  end

  -- pied
  fillRect(0, H - footerH, W, footerH, THEME.bg)
  drawText("click: play   ·   Shift + click: insert   ·   0: stop   ·   F1–F7: colors   ·   F9 / F10: pattern   ·   F11: wiki   ·   F12: chord change   ·   right-click: dock", PAD, H - footerH, W - 2 * PAD, footerH - 4, THEME.faint, F_SMALL, 0)

  drawHeader(W, compact)

  if M.rclick and not M.rconsumed then dockMenu() end

  gfx.update()
  reaper.defer(frame)
end

initWindow()
reaper.atexit(function()
  LiveArp.shutdown()
  saveWindowState()
end)
frame()
