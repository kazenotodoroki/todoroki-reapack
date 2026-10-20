-- @noindex
--[[
  ChordMachineGun — fenêtre Historique
  Chaque accord joué par ChordMachineGun apparaît ici sous forme de bouton, avec ses voix.
  Rejouer depuis l'historique n'ajoute rien à l'historique.

    clic / ← →          rejouer l'accord (↑ ↓ : rangée précédente / suivante)
    Maj + clic / Entrée insérer (Maj+Entrée) — Entrée seule rejoue
    Suppr / Retour arr. retirer l'accord focalisé
    clic droit          menu (sur un accord) ou ancrer / détacher (zone vide)
]]

local scriptPath = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(scriptPath .. "Todoroki_ChordMachineGun_core.lua")

local TITLE = "ChordMachineGun — Historique"
local EXT = "ChordMachineGun"

------------------------------------------------------------------------------
-- Thème et dessin (mêmes couleurs que la fenêtre principale, formes carrées)
------------------------------------------------------------------------------

local THEME = {
  bg = "000000", surface = "0E0E0E", surface2 = "161616", hover = "202020", line = "1E1E1E",
  text = "EDEDED", soft = "B5B5B5", muted = "7C7C7C", faint = "3E3E3E", accent = "8AB4FF", onAccent = "05070A",
}

local function setColor(hex, a)
  gfx.set(tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, a or 1)
end
local function fillRect(x, y, w, h, hex) setColor(hex); gfx.rect(math.floor(x), math.floor(y), math.floor(w), math.floor(h), 1) end
local function strokeRect(x, y, w, h, hex) setColor(hex); gfx.rect(math.floor(x), math.floor(y), math.floor(w), math.floor(h), 0) end

local osName = reaper.GetOS()
local FACE = "Arial"
if osName:match("Win") then FACE = "Segoe UI" elseif osName:match("OSX") or osName:match("mac") then FACE = "Helvetica Neue" end
local F_BODY, F_SMALL, F_BOLD, F_LABEL = 1, 2, 3, 4
local function setupFonts()
  gfx.setfont(F_BODY, FACE, 15)
  gfx.setfont(F_SMALL, FACE, 12)
  gfx.setfont(F_BOLD, FACE, 16, string.byte('b'))
  gfx.setfont(F_LABEL, FACE, 11, string.byte('b'))
end

local function ellipsize(s, maxW, font)
  gfx.setfont(font)
  if gfx.measurestr(s) <= maxW then return s end
  while #s > 0 and gfx.measurestr(s .. "…") > maxW do
    while #s > 0 and s:byte(-1) >= 0x80 and s:byte(-1) < 0xC0 do s = s:sub(1, -2) end
    s = s:sub(1, -2)
  end
  return s .. "…"
end

local function drawText(s, x, y, w, h, hex, font, align)
  s = ellipsize(s, w, font)
  local tw, th = gfx.measurestr(s)
  local tx = x
  if align == 1 then tx = x + (w - tw) / 2 elseif align == 2 then tx = x + w - tw end
  setColor(hex)
  gfx.x, gfx.y = math.floor(tx), math.floor(y + (h - th) / 2)
  gfx.drawstr(s)
end

------------------------------------------------------------------------------
-- Souris
------------------------------------------------------------------------------

local M = { prev = false, rprev = false }
local function updateMouse()
  local cap = gfx.mouse_cap
  M.x, M.y = gfx.mouse_x, gfx.mouse_y
  local down, rdown = cap & 1 == 1, cap & 2 == 2
  M.click, M.rclick = down and not M.prev, rdown and not M.rprev
  M.prev, M.rprev = down, rdown
  M.shift = cap & 8 == 8
  M.consumed, M.rconsumed = false, false
  M.wheel = gfx.mouse_wheel
  gfx.mouse_wheel = 0
end
local function hover(x, y, w, h) return M.x >= x and M.x < x + w and M.y >= y and M.y < y + h end
local function clicked(x, y, w, h)
  if M.click and not M.consumed and hover(x, y, w, h) then M.consumed = true; return true end
  return false
end
local function rclicked(x, y, w, h)
  if M.rclick and not M.rconsumed and hover(x, y, w, h) then M.rconsumed = true; return true end
  return false
end
local function afterModal() M.prev, M.rprev = true, true end

local function button(x, y, w, h, label, active)
  local hov = hover(x, y, w, h)
  fillRect(x, y, w, h, active and THEME.accent or (hov and THEME.hover or THEME.surface2))
  drawText(label, x + 4, y, w - 8, h, active and THEME.onAccent or (hov and THEME.text or THEME.soft), F_SMALL, 1)
  return clicked(x, y, w, h)
end

------------------------------------------------------------------------------
-- État
------------------------------------------------------------------------------

local ui = {
  list = {}, rev = -1, focus = 0, scroll = 0, contentH = 0,
  cells = {},          -- positions calculées à chaque image (pour ↑ ↓)
  ensureVisible = false,
}

local function reload()
  local rev = getHistoryRevision()
  if rev == ui.rev then return end
  local oldCount = #ui.list
  local followNewest = (ui.focus == 0 or ui.focus >= oldCount)
  ui.list = getHistory()
  ui.rev = rev
  if #ui.list > oldCount and followNewest then
    ui.focus = #ui.list
    ui.ensureVisible = true
  end
  if ui.focus > #ui.list then ui.focus = #ui.list end
end

local function play(index, insert)
  if not ui.list[index] then return end
  ui.focus = index
  ui.ensureVisible = true
  playHistoryEntry(index, insert)
end

local function removeEntry(index)
  if not ui.list[index] then return end
  removeHistoryEntry(index)
  reload()
  ui.focus = math.min(index, #ui.list)
end

------------------------------------------------------------------------------
-- Épingle (js_ReaScriptAPI)
------------------------------------------------------------------------------

local function getPinned() return reaper.GetExtState(EXT, "historyPinned") == "1" end
local function applyPin()
  if not reaper.JS_Window_Find then return end
  local hwnd = reaper.JS_Window_Find(TITLE, true)
  if hwnd then reaper.JS_Window_SetZOrder(hwnd, (getPinned() and gfx.dock(-1) == 0) and "TOPMOST" or "NOTOPMOST") end
end
local function togglePin()
  if not reaper.JS_Window_SetZOrder then
    reaper.MB("Pour épingler la fenêtre, installe l'extension js_ReaScriptAPI (ReaPack).", "ChordMachineGun", 0)
    afterModal()
    return
  end
  reaper.SetExtState(EXT, "historyPinned", getPinned() and "0" or "1", true)
  applyPin()
end

------------------------------------------------------------------------------
-- Dessin
------------------------------------------------------------------------------

local PAD, GAP = 14, 6
local HEADER_H, FOOTER_H = 50, 22
local CELL_H = 52

local function cellWidth(e)
  gfx.setfont(F_BOLD)
  local w1 = gfx.measurestr(e.name)
  gfx.setfont(F_SMALL)
  local w2 = gfx.measurestr(historyVoicesText(e))
  return math.max(96, math.min(260, math.max(w1, w2) + 26))
end

local function drawEntries(W, H)
  local top = HEADER_H
  local bottom = H - FOOTER_H
  local x, y = PAD, top + 8 + ui.scroll
  ui.cells = {}

  if #ui.list == 0 then
    drawText("Aucun accord pour l'instant : joue des accords dans ChordMachineGun.", PAD, top, W - 2 * PAD, bottom - top, THEME.muted, F_BODY, 1)
    ui.contentH = 0
    return
  end

  local rowIndex = 1
  for k, e in ipairs(ui.list) do
    local w = cellWidth(e)
    if x + w > W - PAD and x > PAD then
      x = PAD
      y = y + CELL_H + GAP
      rowIndex = rowIndex + 1
    end
    ui.cells[k] = { x = x, y = y, w = w, h = CELL_H, row = rowIndex }

    if y + CELL_H >= top and y <= bottom then
      local hov = hover(x, y, w, CELL_H) and M.y >= top and M.y < bottom
      local focused = (k == ui.focus)
      fillRect(x, y, w, CELL_H, focused and THEME.hover or (hov and THEME.surface2 or THEME.surface))
      if focused then
        strokeRect(x, y, w, CELL_H, THEME.accent)
        strokeRect(x + 1, y + 1, w - 2, CELL_H - 2, THEME.accent)
      end
      if e.inserted then fillRect(x, y, 3, CELL_H, THEME.accent) end
      drawText(tostring(k), x + 8, y + 4, w - 16, 12, THEME.faint, F_LABEL, 0)
      drawText(e.name, x + 8, y + 14, w - 16, 20, focused and THEME.text or THEME.soft, F_BOLD, 1)
      drawText(historyVoicesText(e), x + 8, y + 33, w - 16, 14, THEME.muted, F_SMALL, 1)
      if e.label ~= "" then drawText(e.label, x + 8, y + 4, w - 16, 12, THEME.accent, F_SMALL, 2) end

      if M.y >= top and M.y < bottom then
        if clicked(x, y, w, CELL_H) then play(k, M.shift) end
        if rclicked(x, y, w, CELL_H) then
          gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
          local choice = gfx.showmenu("Rejouer|Insérer dans l'éditeur MIDI||Retirer de l'historique|Effacer tout l'historique")
          afterModal()
          if choice == 1 then play(k, false)
          elseif choice == 2 then play(k, true)
          elseif choice == 3 then removeEntry(k)
          elseif choice == 4 then clearHistory(); reload(); ui.focus = 0 end
        end
      end
    end
    x = x + w + GAP
  end
  ui.contentH = (y - ui.scroll) + CELL_H + 16 - top

  -- garder l'accord focalisé visible
  if ui.ensureVisible and ui.cells[ui.focus] then
    local c = ui.cells[ui.focus]
    if c.y < top + 8 then ui.scroll = ui.scroll + (top + 8 - c.y)
    elseif c.y + c.h > bottom - 8 then ui.scroll = ui.scroll - (c.y + c.h - (bottom - 8)) end
    ui.ensureVisible = false
  end
end

local function drawHeader(W)
  fillRect(0, 0, W, HEADER_H, THEME.bg)
  drawText("Historique", PAD, 12, 120, 26, THEME.text, F_BOLD, 0)
  drawText(#ui.list .. " accord" .. (#ui.list > 1 and "s" or ""), PAD + 110, 12, 120, 26, THEME.muted, F_SMALL, 0)
  if button(W - PAD - 30 - 8 - 80, 12, 80, 26, "Effacer") then
    if #ui.list > 0 and reaper.MB("Effacer tout l'historique ?", "ChordMachineGun", 4) == 6 then
      clearHistory(); reload(); ui.focus = 0
    end
    afterModal()
  end
  if button(W - PAD - 30, 12, 30, 26, getPinned() and "●" or "○", getPinned()) then togglePin() end
  fillRect(PAD, HEADER_H - 1, W - 2 * PAD, 1, THEME.line)
end

local function drawFooter(W, H)
  fillRect(0, H - FOOTER_H, W, FOOTER_H, THEME.bg)
  drawText("clic / ← → ↑ ↓ : rejouer   ·   Maj : insérer   ·   Suppr : retirer   ·   clic droit : menu",
    PAD, H - FOOTER_H, W - 2 * PAD, FOOTER_H - 4, THEME.faint, F_SMALL, 0)
end

------------------------------------------------------------------------------
-- Clavier
------------------------------------------------------------------------------

local function moveVertical(dir)
  local cur = ui.cells[ui.focus]
  if not cur then return end
  local targetRow = cur.row + dir
  local best, bestD = nil, math.huge
  for k, c in pairs(ui.cells) do
    if c.row == targetRow then
      local d = math.abs((c.x + c.w / 2) - (cur.x + cur.w / 2))
      if d < bestD then best, bestD = k, d end
    end
  end
  if best then play(best, false) end
end

local function handleKey(char)
  if char <= 0 then return end
  local shift = gfx.mouse_cap & 8 == 8
  local n = #ui.list
  if n == 0 then return end
  if ui.focus == 0 then ui.focus = n end
  if char == 1818584692 then play(math.max(1, ui.focus - 1), false)          -- ←
  elseif char == 1919379572 then play(math.min(n, ui.focus + 1), false)      -- →
  elseif char == 30064 then moveVertical(-1)                                 -- ↑
  elseif char == 1685026670 then moveVertical(1)                             -- ↓
  elseif char == 1752132965 then play(1, false)                              -- Début
  elseif char == 6647396 then play(n, false)                                 -- Fin
  elseif char == 13 then play(ui.focus, shift)                               -- Entrée
  elseif char == 6579564 or char == 8 then removeEntry(ui.focus)             -- Suppr / Retour
  elseif char == string.byte("0") then stopAllNotesFromPlaying() end
end

------------------------------------------------------------------------------
-- Fenêtre
------------------------------------------------------------------------------

local function saveWindow()
  local dock, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
  reaper.SetExtState(EXT, "historyWindow", table.concat({ dock, math.floor(x), math.floor(y), math.floor(w), math.floor(h) }, ","), true)
end

local function initWindow()
  local raw = reaper.GetExtState(EXT, "historyWindow")
  local dock, x, y, w, h = raw:match("(%-?%d+),(%-?%d+),(%-?%d+),(%d+),(%d+)")
  dock, x, y, w, h = tonumber(dock) or 0, tonumber(x), tonumber(y), tonumber(w) or 720, tonumber(h) or 300
  if not x then
    local _, _, sw, sh = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)
    x, y = math.floor((sw - w) / 2), math.floor(sh - h - 120)
  end
  gfx.clear = 0
  gfx.init(TITLE, w, h, dock, x, y)
  setupFonts()
end

local function onExit()
  saveWindow()
  reaper.SetExtState(EXT, "historyAlive", "0", false)
end

local pinApplied = false

local function frame()
  local char = gfx.getchar()
  if char == -1 or char == 27 or reaper.GetExtState(EXT, "historyCloseRequest") == "1" then
    reaper.SetExtState(EXT, "historyCloseRequest", "0", false)
    gfx.quit()
    return
  end
  reaper.SetExtState(EXT, "historyAlive", tostring(reaper.time_precise()), false)
  if not pinApplied then pinApplied = true; applyPin() end

  -- la gamme a pu changer dans la fenêtre principale (noms de notes)
  local scaleKey = getScaleTonicNote() .. ":" .. getScaleType()
  if scaleKey ~= ui.scaleKey then ui.scaleKey = scaleKey; updateScaleData() end
  reload()
  updateMouse()
  handleKey(char)

  local W, H = gfx.w, gfx.h
  fillRect(0, 0, W, H, THEME.bg)

  if M.wheel ~= 0 then ui.scroll = ui.scroll + (M.wheel > 0 and 40 or -40) end
  local viewH = H - HEADER_H - FOOTER_H
  ui.scroll = math.max(math.min(0, viewH - ui.contentH), math.min(0, ui.scroll))

  drawEntries(W, H)
  drawHeader(W)
  drawFooter(W, H)

  if M.rclick and not M.rconsumed then
    local docked = gfx.dock(-1) > 0
    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
    local i = gfx.showmenu(docked and "Détacher la fenêtre" or "Ancrer la fenêtre")
    afterModal()
    if i == 1 then
      saveWindow()
      gfx.dock(docked and 0 or 1)
      pinApplied = false
    end
  end

  gfx.update()
  reaper.defer(frame)
end

initWindow()
reaper.atexit(onExit)
frame()
