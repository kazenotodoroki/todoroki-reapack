-- @description Todoroki Param Sweep - automate FX parameter steps into regions to render and analyse
-- @author Todoroki
-- @version 1.0
-- @changelog
--   First version.
-- @about
--   # Param Sweep
--
--   Automates the variation of one or more FX parameters and creates one region per step,
--   ready to be rendered with the `$region` pattern.
--
--   1. Set a **time selection** (the passage replayed for each step: test signal, loop, MIDI item…).
--   2. Run the script, then **move the parameters** to analyse in the plugin windows
--      (or click *Scan* to detect every parameter changed since launch).
--   3. **Continue**: for each parameter enter `steps min% max%` (e.g. `10 0 100`),
--      whether the parameters **interact**, and the **tail** (silence after each step).
--
--   - No interaction: 10 + 10 steps = 20 regions (the other parameters stay at their initial value).
--   - Interaction: 10 × 10 = 100 regions (every combination).
--
--   The script inserts space after the time selection, duplicates its content for each step,
--   writes the automation (square points, slightly before each step), creates the regions,
--   writes a CSV (region → values) next to the project and can prepare the render (`$region`).
--   Everything is in a single undo.
--
--   Hardware: automate a ReaControlMIDI (CC) or ReaInsert parameter the same way.
--   Track FX and master FX only (not take FX, input FX or containers).

local r = reaper
local SCRIPT = "Todoroki Param Sweep"
local EXT = "todoroki_ParamSweep"
local MAX_PARAMS = 12

local function msg(s) r.ShowMessageBox(s, SCRIPT, 0) end

---------------------------------------------------------------- time selection
local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
if te - ts < 0.001 then
  msg("Définis d'abord une time selection : le passage rejoué à chaque pas.")
  return
end
local selLen = te - ts

---------------------------------------------------------------- helpers
local function key(tr, fx, p) return tostring(tr) .. ":" .. fx .. ":" .. p end

local function trackByNumber(n)
  if n == 0 then return r.GetMasterTrack(0) end
  return r.GetTrack(0, n - 1)
end

local function forEachTrack(f)
  f(r.GetMasterTrack(0))
  for i = 0, r.CountTracks(0) - 1 do f(r.GetTrack(0, i)) end
end

local function trackName(tr)
  if tr == r.GetMasterTrack(0) then return "Master" end
  local _, n = r.GetTrackName(tr)
  return n
end

local function cleanFxName(name)
  name = name:gsub("^%w+i?:%s*", ""):gsub("%s*%(.-%)%s*$", "")
  return name
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function sanitize(s)
  s = s:gsub('[\\/:%*%?"<>|]', "-"):gsub("%s+", " ")
  return trim(s)
end

---------------------------------------------------------------- snapshot
local snap = {}
forEachTrack(function(tr)
  for fx = 0, r.TrackFX_GetCount(tr) - 1 do
    for p = 0, r.TrackFX_GetNumParams(tr, fx) - 1 do
      snap[key(tr, fx, p)] = r.TrackFX_GetParamNormalized(tr, fx, p)
    end
  end
end)

---------------------------------------------------------------- capture
local params, byKey, blocked = {}, {}, {}
local status = ""
local done = false

do -- the parameter already "last touched" counts only if it moves again
  local ok, tn, fxn, pn = r.GetLastTouchedFX()
  if ok then
    local tr = trackByNumber(tn)
    if tr and fxn < 0x10000 and fxn < r.TrackFX_GetCount(tr) then
      blocked[key(tr, fxn, pn)] = r.TrackFX_GetParamNormalized(tr, fxn, pn)
    end
  end
end

local function register(tr, fx, p)
  local k = key(tr, fx, p)
  if byKey[k] then return end
  if #params >= MAX_PARAMS then status = "Maximum " .. MAX_PARAMS .. " paramètres." return end
  local _, fxName = r.TrackFX_GetFXName(tr, fx, "")
  local _, pName = r.TrackFX_GetParamName(tr, fx, p, "")
  local okS, _, _, _, isToggle = r.TrackFX_GetParameterStepSizes(tr, fx, p)
  local cur = r.TrackFX_GetParamNormalized(tr, fx, p)
  local e = {
    tr = tr, fx = fx, p = p, key = k, guid = r.TrackFX_GetFXGUID(tr, fx),
    orig = snap[k] or cur, trName = trackName(tr), fxName = cleanFxName(fxName),
    pName = pName, toggle = okS and isToggle,
  }
  params[#params + 1] = e
  byKey[k] = e
  status = ""
end

local function removeParam(i)
  local e = table.remove(params, i)
  byKey[e.key] = nil
  if r.ValidatePtr2(0, e.tr, "MediaTrack*") then
    r.TrackFX_SetParamNormalized(e.tr, e.fx, e.p, e.orig)
    blocked[e.key] = e.orig
  end
end

local function restoreAll()
  for _, e in ipairs(params) do
    if r.ValidatePtr2(0, e.tr, "MediaTrack*") then
      r.TrackFX_SetParamNormalized(e.tr, e.fx, e.p, e.orig)
    end
  end
end

local function poll()
  local ok, tn, fxn, pn = r.GetLastTouchedFX()
  if not ok then return end
  local tr = trackByNumber(tn)
  if not tr or fxn >= 0x10000 or fxn >= r.TrackFX_GetCount(tr) then return end
  local k = key(tr, fxn, pn)
  if byKey[k] then return end
  local b = blocked[k]
  if b == nil or math.abs(r.TrackFX_GetParamNormalized(tr, fxn, pn) - b) > 1e-7 then
    blocked[k] = nil
    register(tr, fxn, pn)
  end
end

local function scan()
  local n = 0
  forEachTrack(function(tr)
    for fx = 0, r.TrackFX_GetCount(tr) - 1 do
      for p = 0, r.TrackFX_GetNumParams(tr, fx) - 1 do
        local k = key(tr, fx, p)
        local v = snap[k]
        if v and not byKey[k] and math.abs(r.TrackFX_GetParamNormalized(tr, fx, p) - v) > 1e-6 then
          register(tr, fx, p)
          n = n + 1
        end
      end
    end
  end)
  status = n .. " paramètre(s) ajouté(s) par comparaison."
end

-- FX may have been moved during capture: find it again by GUID
local function resolve(e)
  if not r.ValidatePtr2(0, e.tr, "MediaTrack*") then return false end
  if r.TrackFX_GetFXGUID(e.tr, e.fx) == e.guid then return true end
  for fx = 0, r.TrackFX_GetCount(e.tr) - 1 do
    if r.TrackFX_GetFXGUID(e.tr, fx) == e.guid then e.fx = fx return true end
  end
  return false
end

---------------------------------------------------------------- generation
local function getExt(k, d)
  local v = r.GetExtState(EXT, k)
  return v ~= "" and v or d
end

local function projectDir()
  local _, fn = r.EnumProjects(-1, "")
  if fn and fn ~= "" then return fn:match("^(.*)[/\\]") end
  return r.GetProjectPath("")
end

local function newGuids(chunk)
  chunk = chunk:gsub("(%u*GUID) {[^}]*}", function(tag) return tag .. " " .. r.genGuid("") end)
  chunk = chunk:gsub("FXID {[^}]*}", function() return "FXID " .. r.genGuid("") end)
  chunk = chunk:gsub("POOLEDEVTS {[^}]*}", function() return "POOLEDEVTS " .. r.genGuid("") end)
  return chunk
end

local function copyItem(it, off)
  local tr = r.GetMediaItem_Track(it)
  local _, chunk = r.GetItemStateChunk(it, "", false)
  local new = r.AddMediaItemToTrack(tr)
  r.SetItemStateChunk(new, newGuids(chunk), false)
  local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
  r.SetMediaItemInfo_Value(new, "D_POSITION", pos + off)
  local a, b = ts + off, te + off
  if pos + off < a - 1e-9 then
    local right = r.SplitMediaItem(new, a)
    r.DeleteTrackMediaItem(tr, new)
    new = right
  end
  if new then
    local np = r.GetMediaItemInfo_Value(new, "D_POSITION")
    local nl = r.GetMediaItemInfo_Value(new, "D_LENGTH")
    if np + nl > b + 1e-9 then
      local right = r.SplitMediaItem(new, b)
      if right then r.DeleteTrackMediaItem(tr, right) end
    end
  end
end

local function proceed()
  restoreAll()
  for i = #params, 1, -1 do
    if not resolve(params[i]) then table.remove(params, i) end
  end
  if #params == 0 then msg("Aucun paramètre capturé.") return end

  -- dialog
  local lastSteps = getExt("steps", "10")
  local caps, defs = {}, {}
  for i, e in ipairs(params) do
    local name = e.pName:gsub("[,=]", " ")
    if #name > 24 then name = name:sub(1, 24) end
    caps[#caps + 1] = ("P%d %s (pas min%% max%%)"):format(i, name)
    defs[#defs + 1] = e.toggle and "2 0 100" or (lastSteps .. " 0 100")
  end
  caps[#caps + 1] = "Interaction entre params (o/n)"
  defs[#defs + 1] = getExt("interact", "n")
  caps[#caps + 1] = "Queue après chaque pas (s)"
  defs[#defs + 1] = getExt("tail", "1")
  caps[#caps + 1] = "Préparer le rendu $region (o/n)"
  defs[#defs + 1] = getExt("render", "o")

  local ok, ret = r.GetUserInputs(SCRIPT, #caps, table.concat(caps, ",") .. ",extrawidth=120", table.concat(defs, ","))
  if not ok then return end
  local vals = {}
  for s in (ret .. ","):gmatch("(.-),") do vals[#vals + 1] = trim(s) end

  local n = #params
  local values = {}
  for i = 1, n do
    local nums = {}
    for x in vals[i]:gmatch("%-?[%d%.]+") do nums[#nums + 1] = tonumber(x) end
    local steps = math.max(1, math.floor(nums[1] or 10))
    local lo = math.min(1, math.max(0, (nums[2] or 0) / 100))
    local hi = math.min(1, math.max(0, (nums[3] or 100) / 100))
    local list = {}
    for s = 1, steps do
      list[s] = steps == 1 and lo or lo + (hi - lo) * (s - 1) / (steps - 1)
    end
    values[i] = list
    if i == 1 then r.SetExtState(EXT, "steps", tostring(steps), true) end
  end
  local interact = vals[n + 1]:lower():match("^[oy]") ~= nil
  local tail = math.max(0, tonumber(vals[n + 2]) or 0)
  local render = vals[n + 3]:lower():match("^[oy]") ~= nil
  r.SetExtState(EXT, "interact", interact and "o" or "n", true)
  r.SetExtState(EXT, "tail", tostring(tail), true)
  r.SetExtState(EXT, "render", render and "o" or "n", true)

  -- combinations
  local combos = {}
  local base = {}
  for i, e in ipairs(params) do base[i] = e.orig end
  if interact then
    local cur = {}
    local function cart(i)
      if i > n then combos[#combos + 1] = { table.unpack(cur) } return end
      for _, v in ipairs(values[i]) do cur[i] = v cart(i + 1) end
    end
    cart(1)
  else
    for i = 1, n do
      for _, v in ipairs(values[i]) do
        local c = { table.unpack(base) }
        c[i] = v
        combos[#combos + 1] = c
      end
    end
  end
  local N = #combos
  if N > 300 and r.ShowMessageBox(N .. " régions vont être créées. Continuer ?", SCRIPT, 4) ~= 6 then return end

  -- names (displayed value read from the plugin itself)
  local singleFx = true
  for i = 2, n do
    if params[i].tr ~= params[1].tr or params[i].fx ~= params[1].fx then singleFx = false end
  end
  local prefix = singleFx and params[1].fxName or "Sweep"
  local fmtCache = {}
  local function fmt(i, v)
    local ck = i .. ":" .. string.format("%.6f", v)
    if fmtCache[ck] then return fmtCache[ck] end
    local e = params[i]
    r.TrackFX_SetParamNormalized(e.tr, e.fx, e.p, v)
    local _, s = r.TrackFX_GetFormattedParamValue(e.tr, e.fx, e.p, "")
    s = trim(s or "")
    if s == "" then s = string.format("%.1f%%", v * 100) end
    fmtCache[ck] = s
    return s
  end
  local names, shown = {}, {}
  for k, c in ipairs(combos) do
    local parts = {}
    shown[k] = {}
    for i, e in ipairs(params) do
      local label = singleFx and e.pName or (e.fxName .. "-" .. e.pName)
      shown[k][i] = fmt(i, c[i])
      parts[#parts + 1] = label .. "=" .. shown[k][i]
    end
    names[k] = sanitize(("%s %03d %s"):format(prefix, k, table.concat(parts, " ")))
  end
  restoreAll()

  local _, numMarkers, numRegions = r.CountProjectMarkers(0)

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local slot = selLen + tail
  local total = N * slot

  -- make room after the time selection
  local extra = total - selLen
  if extra > 1e-9 then
    r.GetSet_LoopTimeRange(true, false, te, te + extra, false)
    r.Main_OnCommand(40200, 0) -- Time selection: Insert empty space at time selection
    r.GetSet_LoopTimeRange(true, false, ts, te, false)
  end

  -- duplicate the content of the time selection for each step
  local src = {}
  for i = 0, r.CountMediaItems(0) - 1 do
    local it = r.GetMediaItem(0, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
    if pos < te - 1e-9 and pos + len > ts + 1e-9 then src[#src + 1] = it end
  end
  for k = 2, N do
    for _, it in ipairs(src) do copyItem(it, (k - 1) * slot) end
  end

  -- automation: square points, slightly ahead of each step
  local lead = math.min(0.05, tail * 0.5)
  for i, e in ipairs(params) do
    local env = r.GetFXEnvelope(e.tr, e.fx, e.p, true)
    if env then
      local _, mn, mx = r.TrackFX_GetParam(e.tr, e.fx, e.p)
      local mode = r.GetEnvelopeScalingMode(env)
      local function ev(norm) return r.ScaleToEnvelopeMode(mode, mn + norm * (mx - mn)) end
      local t0 = math.max(0, ts - lead)
      r.DeleteEnvelopePointRange(env, t0 - 0.02, ts + total + 0.001)
      if t0 > 0.02 then r.InsertEnvelopePoint(env, t0 - 0.01, ev(e.orig), 1, 0, false, true) end
      for k, c in ipairs(combos) do
        r.InsertEnvelopePoint(env, math.max(0, ts + (k - 1) * slot - lead), ev(c[i]), 1, 0, false, true)
      end
      r.InsertEnvelopePoint(env, ts + total, ev(e.orig), 1, 0, false, true)
      r.Envelope_SortPoints(env)
    end
  end

  -- regions
  local color = r.ColorToNative(80, 160, 220) | 0x1000000
  for k = 1, N do
    local s = ts + (k - 1) * slot
    r.AddProjectMarker2(0, true, s, s + slot, names[k], -1, color)
  end

  if render then
    r.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 3, true) -- all project regions
    r.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$region", true)
  end

  r.PreventUIRefresh(-1)
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
  r.Undo_EndBlock(SCRIPT .. " (" .. N .. " régions)", -1)

  -- CSV for the analysis
  local function q(s) return '"' .. (tostring(s):gsub('"', '""')) .. '"' end
  local path = projectDir() .. "/todoroki_ParamSweep_" .. os.date("%Y%m%d-%H%M%S") .. ".csv"
  local f = io.open(path, "w")
  if f then
    local head = { "index", "region", "start", "end" }
    for _, e in ipairs(params) do
      local label = e.trName .. " / " .. e.fxName .. " / " .. e.pName
      head[#head + 1] = q(label .. " (norm)")
      head[#head + 1] = q(label .. " (valeur)")
    end
    f:write(table.concat(head, ";"), "\n")
    for k, c in ipairs(combos) do
      local s = ts + (k - 1) * slot
      local row = { k, q(names[k]), string.format("%.6f", s), string.format("%.6f", s + slot) }
      for i = 1, n do
        row[#row + 1] = string.format("%.6f", c[i])
        row[#row + 1] = q(shown[k][i])
      end
      f:write(table.concat(row, ";"), "\n")
    end
    f:close()
  end

  local info = N .. " régions créées."
  if f then info = info .. "\n\nCSV : " .. path end
  if render and numRegions > 0 then
    info = info .. "\n\nAttention : le rendu est réglé sur « toutes les régions » et le projet en contenait déjà "
      .. numRegions .. " ; elles seront rendues aussi."
  end
  msg(info)
end

---------------------------------------------------------------- GUI
local clickEdge, prevCap = false, 0

local function fit(s, w)
  if gfx.measurestr(s) <= w then return s end
  while #s > 1 and gfx.measurestr(s .. "...") > w do
    s = s:gsub("[%z\1-\127\194-\244][\128-\191]*$", "")
  end
  return s .. "..."
end

local function btn(x, y, w, h, label)
  local hover = gfx.mouse_x >= x and gfx.mouse_x < x + w and gfx.mouse_y >= y and gfx.mouse_y < y + h
  local c = hover and 0.34 or 0.25
  gfx.set(c, c, c + 0.04)
  gfx.rect(x, y, w, h, 1)
  gfx.set(0.92, 0.92, 0.92)
  local tw, th = gfx.measurestr(label)
  gfx.x, gfx.y = x + (w - tw) / 2, y + (h - th) / 2
  gfx.drawstr(label)
  return hover and clickEdge
end

gfx.init(SCRIPT, 580, 380)
gfx.setfont(1, "Arial", 15)

r.atexit(function() if not done then restoreAll() end end)

local function loop()
  local ch = gfx.getchar()
  if ch < 0 or ch == 27 then
    restoreAll()
    done = true
    gfx.quit()
    return
  end
  local cap = gfx.mouse_cap
  clickEdge = (cap & 1) == 1 and (prevCap & 1) == 0
  prevCap = cap

  for i = #params, 1, -1 do
    if not r.ValidatePtr2(0, params[i].tr, "MediaTrack*") then removeParam(i) end
  end
  poll()

  local W, H = gfx.w, gfx.h
  gfx.set(0.15, 0.15, 0.17)
  gfx.rect(0, 0, W, H, 1)
  gfx.set(0.92, 0.92, 0.92)
  gfx.x, gfx.y = 12, 12
  gfx.drawstr(("Bouge les paramètres à analyser.  Time selection : %.2f s"):format(selLen))

  if #params == 0 then
    gfx.set(0.6, 0.6, 0.6)
    gfx.x, gfx.y = 12, 46
    gfx.drawstr("Aucun paramètre pour l'instant : touche un bouton dans un plugin.")
  end
  for i, e in ipairs(params) do
    local y = 42 + (i - 1) * 22
    if btn(12, y, 18, 18, "x") then removeParam(i) break end
    gfx.set(0.92, 0.92, 0.92)
    gfx.x, gfx.y = 38, y + 2
    gfx.drawstr(fit(("%d. %s · %s · %s"):format(i, e.trName, e.fxName, e.pName), W - 220))
    local _, cur = r.TrackFX_GetFormattedParamValue(e.tr, e.fx, e.p, "")
    gfx.set(0.55, 0.78, 1)
    gfx.x, gfx.y = W - 170, y + 2
    gfx.drawstr(fit(cur or "", 160))
  end

  gfx.set(0.95, 0.75, 0.4)
  gfx.x, gfx.y = 12, H - 64
  gfx.drawstr(fit(status, W - 24))

  local by = H - 40
  if btn(12, by, 150, 28, "Scanner les changements") then scan() end
  local cancel = btn(W - 262, by, 100, 28, "Annuler")
  local go = btn(W - 152, by, 140, 28, "Continuer (Entrée)")

  if cancel then
    restoreAll()
    done = true
    gfx.quit()
    return
  end
  if go or ch == 13 then
    done = true
    gfx.quit()
    proceed()
    return
  end
  gfx.update()
  r.defer(loop)
end

loop()
