-- @description Todoroki Param Sweep - automate FX parameter steps into regions to render and analyse
-- @author Todoroki
-- @version 1.1
-- @changelog
--   New "→ Parametric NAM" mode: plans the captures for a parametric Neural Amp Modeler
--   (optimized Latin hypercube + corners + held-out validation) instead of a grid,
--   names the regions with a parsable scheme and writes a manifest for `namp import-reaper`.
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
--   ## → Parametric NAM
--
--   Instead of a grid (which grows exponentially with the number of knobs), this mode picks a
--   small set of settings with optimal experimental design: an optimized Latin hypercube over the
--   continuous knobs, balanced switch positions, the corners of the knob space, a center point and
--   held-out validation settings. Use the short reamp signal of `namp input` as the time selection.
--
--   For each parameter enter `min% max%` (knob) or `pos N` (switch / selector with N positions).
--   Regions are named `<Model> T007 Drive=6.5 Tone=3 Boost=on` (T = training, V = validation;
--   knob values on a 0–10 scale = normalized parameter × 10). A `<Model>_namp.json` manifest is
--   written next to the project. Render, then run `namp import-reaper <manifest> --project <dir>`.
--
--   Hardware: automate a ReaControlMIDI (CC) or ReaInsert parameter the same way.
--   Track FX and master FX only (not take FX, input FX or containers).

local r = reaper
local SCRIPT = "Todoroki Param Sweep"
local EXT = "todoroki_ParamSweep"
local MAX_PARAMS = 12
local MAX_NAMP_PARAMS = 10

local function msg(s) r.ShowMessageBox(s, SCRIPT, 0) end

---------------------------------------------------------------- pure helpers (no REAPER API)
-- BEGIN PURE
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function sanitize(s)
  s = s:gsub('[\\/:%*%?"<>|]', "-"):gsub("%s+", " ")
  return trim(s)
end

-- token used in "Key=value": no spaces, no "=" (the file name must stay parsable)
local function token(s)
  s = sanitize(s):gsub("[%s=]+", "_"):gsub("[^%w%._%+%-]", "")
  return s ~= "" and s or "x"
end

local function round(x, d)
  local m = 10 ^ (d or 2)
  return math.floor(x * m + 0.5) / m
end

local function fmtNum(x)
  local s = string.format("%.2f", round(x, 2)):gsub("0+$", ""):gsub("%.$", "")
  return s == "-0" and "0" or s
end

local function jsonEncode(v, ind)
  ind = ind or ""
  local t = type(v)
  if t == "nil" then return "null" end
  if t == "boolean" then return v and "true" or "false" end
  if t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return "null" end
    if math.type and math.type(v) == "integer" then return tostring(v) end
    return string.format("%.10g", v)
  end
  if t == "string" then
    local esc = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
    return '"' .. (v:gsub('[%c"\\]', function(c) return esc[c] or string.format("\\u%04x", c:byte()) end)) .. '"'
  end
  local nxt = ind .. "  "
  if v.__array or #v > 0 then
    if #v == 0 then return "[]" end
    local parts = {}
    for i = 1, #v do parts[i] = nxt .. jsonEncode(v[i], nxt) end
    return "[\n" .. table.concat(parts, ",\n") .. "\n" .. ind .. "]"
  end
  local keys = {}
  for k in pairs(v) do if k ~= "__array" then keys[#keys + 1] = k end end
  table.sort(keys)
  if #keys == 0 then return "{}" end
  local parts = {}
  for i, k in ipairs(keys) do parts[i] = nxt .. jsonEncode(tostring(k)) .. ": " .. jsonEncode(v[k], nxt) end
  return "{\n" .. table.concat(parts, ",\n") .. "\n" .. ind .. "}"
end

-- Capture planning for a parametric model (same method as `namp plan`).
-- knob = { kind = "continuous", lo, hi } (0–10 scale)  |  { kind = "boolean"/"choice", levels = {...}, default = idx }
-- A setting is a list: continuous -> knob value, switch -> level index (1-based).
local Design = {}

local function shuffle(t)
  for i = #t, 2, -1 do
    local k = math.random(i)
    t[i], t[k] = t[k], t[i]
  end
end

function Design.lhs(n, d, tries)
  local best, bestScore = {}, -1
  if n <= 0 then return best end
  for i = 1, n do best[i] = {} end
  if d == 0 then return best end
  for _ = 1, tries or 100 do
    local cols = {}
    for j = 1, d do
      local perm = {}
      for i = 1, n do perm[i] = i end
      shuffle(perm)
      cols[j] = perm
    end
    local pts = {}
    for i = 1, n do
      local p = {}
      for j = 1, d do p[j] = (cols[j][i] - 1 + math.random()) / n end
      pts[i] = p
    end
    local score = n == 1 and 0 or math.huge
    for a = 1, n - 1 do
      for b = a + 1, n do
        local s = 0
        for j = 1, d do
          local t = pts[a][j] - pts[b][j]
          s = s + t * t
        end
        if s < score then score = s end
      end
      if score <= bestScore then break end
    end
    if score > bestScore then best, bestScore = pts, score end
  end
  return best
end

local function popcount(x)
  local c = 0
  while x > 0 do c = c + (x & 1); x = x >> 1 end
  return c
end

-- two-level design on the extremes: full factorial (<= 3 knobs), half fraction (4),
-- Hadamard + fold-over (>= 5): main effects and pairwise interactions stay estimable
function Design.corners(c)
  local out = {}
  if c == 0 then return out end
  if c <= 4 then
    local m = c <= 3 and c or 3
    for i = 0, (1 << m) - 1 do
      local p, par = {}, 0
      for j = 1, m do
        p[j] = (i >> (j - 1)) & 1
        par = par + p[j]
      end
      if c == 4 then p[4] = par % 2 end
      out[#out + 1] = p
    end
    return out
  end
  local n = 1
  while n < c + 1 do n = n * 2 end
  for i = 0, n - 1 do
    local p, q = {}, {}
    for j = 1, c do
      p[j] = popcount(i & j) % 2 == 0 and 1 or 0
      q[j] = 1 - p[j]
    end
    out[#out + 1] = p
    out[#out + 1] = q
  end
  return out
end

function Design.plan(knobs, nTrain, nVal)
  local cont, disc = {}, {}
  for i, k in ipairs(knobs) do
    if k.kind == "continuous" then cont[#cont + 1] = i else disc[#disc + 1] = i end
  end
  local combos = { {} }
  for _, i in ipairs(disc) do
    local new = {}
    for _, cmb in ipairs(combos) do
      for l = 1, #knobs[i].levels do
        local x = { table.unpack(cmb) }
        x[#x + 1] = l
        new[#new + 1] = x
      end
    end
    combos = new
  end
  local c = #cont
  if not nTrain or nTrain <= 0 then nTrain = math.max(12, 12 * c + 6 * (#combos - 1)) end
  if not nVal or nVal <= 0 then nVal = math.max(3, math.ceil(0.12 * nTrain)) end

  local caps, seen = {}, {}
  local function make(u, cmb)
    local s = {}
    for j, i in ipairs(cont) do
      local k = knobs[i]
      s[i] = round(k.lo + u[j] * (k.hi - k.lo), 2)
    end
    for j, i in ipairs(disc) do s[i] = cmb[j] end
    return s
  end
  local function add(s, split, kind)
    local keyParts = {}
    for i = 1, #knobs do keyParts[i] = tostring(s[i]) end
    local key = table.concat(keyParts, "|")
    if seen[key] then return false end
    seen[key] = true
    caps[#caps + 1] = { setting = s, split = split, kind = kind }
    return true
  end

  -- 1) space-filling training points, stratified by switch combination when possible
  if #combos <= math.max(1, nTrain // 6) then
    local per = nTrain // #combos
    local extra = nTrain - per * #combos
    for ci, cmb in ipairs(combos) do
      for _, u in ipairs(Design.lhs(per + (ci <= extra and 1 or 0), c)) do add(make(u, cmb), "train", "lhs") end
    end
  else
    local U = Design.lhs(nTrain, c)
    local cols = {}
    for j, i in ipairs(disc) do
      local L, col = #knobs[i].levels, {}
      for row = 1, nTrain do col[row] = (row - 1) % L + 1 end
      shuffle(col)
      cols[j] = col
    end
    for row = 1, nTrain do
      local cmb = {}
      for j = 1, #disc do cmb[j] = cols[j][row] end
      add(make(U[row], cmb), "train", "lhs")
    end
  end

  -- 2) corners of the knob space + center (the model must not extrapolate there)
  local cornerCombos = combos
  if #combos > 4 then
    local d = {}
    for j, i in ipairs(disc) do d[j] = knobs[i].default or 1 end
    cornerCombos = { d }
  end
  for _, cmb in ipairs(cornerCombos) do
    for _, u in ipairs(Design.corners(c)) do add(make(u, cmb), "train", "corner") end
    local mid = {}
    for j = 1, c do mid[j] = 0.5 end
    add(make(mid, cmb), "train", "center")
  end

  -- 3) held-out validation: interior points, far from every training point
  local function pos(s)
    local v = {}
    for i, k in ipairs(knobs) do
      if k.kind == "continuous" then
        v[i] = k.hi > k.lo and (s[i] - k.lo) / (k.hi - k.lo) or 0
      else
        v[i] = #k.levels > 1 and (s[i] - 1) / (#k.levels - 1) or 0
      end
    end
    return v
  end
  local function dist(a, b)
    local t = 0
    for j = 1, #a do t = t + (a[j] - b[j]) ^ 2 end
    return math.sqrt(t)
  end
  local trainPos = {}
  for _, cp in ipairs(caps) do trainPos[#trainPos + 1] = pos(cp.setting) end
  local cand = {}
  for _ = 1, 40 * nVal do
    local u = {}
    for j = 1, c do u[j] = 0.1 + 0.8 * math.random() end
    local s = make(u, combos[math.random(#combos)])
    local p, m = pos(s), math.huge
    for _, q in ipairs(trainPos) do m = math.min(m, dist(p, q)) end
    cand[#cand + 1] = { d = m, s = s, p = p }
  end
  table.sort(cand, function(a, b) return a.d > b.d end)
  local picked = {}
  for _, cd in ipairs(cand) do
    local ok = true
    for _, q in ipairs(picked) do
      if dist(cd.p, q) < 0.15 then ok = false break end
    end
    if ok and add(cd.s, "validation", "lhs") then picked[#picked + 1] = cd.p end
    if #picked >= nVal then break end
  end
  return caps
end

-- "<Model> T007 Drive=6.5 Tone=3 Boost=on"
local function nampRegionName(model, split, k, knobs, s)
  local parts = {}
  for i, kn in ipairs(knobs) do
    local v
    if kn.kind == "continuous" then v = fmtNum(s[i])
    elseif kn.kind == "boolean" then v = s[i] == 2 and "on" or "off"
    else v = kn.labels[s[i]] end
    parts[i] = kn.key .. "=" .. v
  end
  return sanitize(("%s %s%03d %s"):format(model, split == "validation" and "V" or "T", k, table.concat(parts, " ")))
end
-- END PURE

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

-- displayed value of a parameter, read from the plugin itself
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

local function singleFx()
  for i = 2, #params do
    if params[i].tr ~= params[1].tr or params[i].fx ~= params[1].fx then return false end
  end
  return true
end

-- Everything that touches the project: space, copies, automation, regions, render setup.
-- combos[k][i] = normalized value of parameter i at step k.
local function generate(combos, names, tail, render, renderDir, color)
  local N = #combos
  local slot = selLen + tail
  local total = N * slot

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

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
  for k = 1, N do
    local s = ts + (k - 1) * slot
    r.AddProjectMarker2(0, true, s, s + slot, names[k], -1, color(k))
  end

  if render then
    r.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 3, true) -- all project regions
    r.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$region", true)
    if renderDir then r.GetSetProjectInfo_String(0, "RENDER_FILE", renderDir, true) end
  end

  r.PreventUIRefresh(-1)
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
  r.Undo_EndBlock(SCRIPT .. " (" .. N .. " régions)", -1)
  return slot
end

local function writeCsv(path, combos, names, shown, slot)
  local function q(s) return '"' .. (tostring(s):gsub('"', '""')) .. '"' end
  local f = io.open(path, "w")
  if not f then return nil end
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
    for i = 1, #params do
      row[#row + 1] = string.format("%.6f", c[i])
      row[#row + 1] = q(shown[k][i])
    end
    f:write(table.concat(row, ";"), "\n")
  end
  f:close()
  return path
end

local function prepare()
  restoreAll()
  for i = #params, 1, -1 do
    if not resolve(params[i]) then table.remove(params, i) end
  end
  if #params == 0 then msg("Aucun paramètre capturé.") return false end
  fmtCache = {}
  return true
end

local function splitFields(ret)
  local vals = {}
  for s in (ret .. ","):gmatch("(.-),") do vals[#vals + 1] = trim(s) end
  return vals
end

---------------------------------------------------------------- classic sweep
local function proceed()
  if not prepare() then return end

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
  local vals = splitFields(ret)

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

  -- names
  local one = singleFx()
  local prefix = one and params[1].fxName or "Sweep"
  local names, shown = {}, {}
  for k, c in ipairs(combos) do
    local parts = {}
    shown[k] = {}
    for i, e in ipairs(params) do
      local label = one and e.pName or (e.fxName .. "-" .. e.pName)
      shown[k][i] = fmt(i, c[i])
      parts[#parts + 1] = label .. "=" .. shown[k][i]
    end
    names[k] = sanitize(("%s %03d %s"):format(prefix, k, table.concat(parts, " ")))
  end
  restoreAll()

  local _, _, numRegions = r.CountProjectMarkers(0)
  local color = r.ColorToNative(80, 160, 220) | 0x1000000
  local slot = generate(combos, names, tail, render, nil, function() return color end)

  local path = writeCsv(projectDir() .. "/todoroki_ParamSweep_" .. os.date("%Y%m%d-%H%M%S") .. ".csv",
    combos, names, shown, slot)

  local info = N .. " régions créées."
  if path then info = info .. "\n\nCSV : " .. path end
  if render and numRegions > 0 then
    info = info .. "\n\nAttention : le rendu est réglé sur « toutes les régions » et le projet en contenait déjà "
      .. numRegions .. " ; elles seront rendues aussi."
  end
  msg(info)
end

---------------------------------------------------------------- → Parametric NAM
-- audio item that covers the whole time selection: the reamp signal used as model input
local function findInput()
  local best
  for i = 0, r.CountMediaItems(0) - 1 do
    local it = r.GetMediaItem(0, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
    local tk = r.GetActiveTake(it)
    if tk and not r.TakeIsMIDI(tk) and pos <= ts + 1e-6 and pos + len >= te - 1e-6 then
      local src = r.GetMediaItemTake_Source(tk)
      local fn = r.GetMediaSourceFileName(src, "")
      if fn and fn ~= "" then
        local rate = r.GetMediaItemTakeInfo_Value(tk, "D_PLAYRATE")
        best = {
          file = fn,
          offset = r.GetMediaItemTakeInfo_Value(tk, "D_STARTOFFS") + (ts - pos) * rate,
          playrate = rate,
          sample_rate = r.GetMediaSourceSampleRate(src),
          track = trackName(r.GetMediaItem_Track(it)),
          length = selLen,
        }
        break
      end
    end
  end
  return best
end

local function proceedNamp()
  if not prepare() then return end
  if #params > MAX_NAMP_PARAMS then
    msg("Le mode Parametric NAM accepte " .. MAX_NAMP_PARAMS .. " paramètres au plus (" .. #params .. " capturés).")
    return
  end

  local proj = r.GetProjectName(0, ""):gsub("%.[Rr][Pp][Pp]$", "")
  local caps, defs = {}, {}
  for i, e in ipairs(params) do
    local name = e.pName:gsub("[,=]", " ")
    if #name > 24 then name = name:sub(1, 24) end
    caps[#caps + 1] = ("P%d %s (min%% max%% | pos N)"):format(i, name)
    defs[#defs + 1] = e.toggle and "pos 2" or "0 100"
  end
  caps[#caps + 1] = "Nom du modèle"
  defs[#defs + 1] = getExt("namp_model", (singleFx() and token(params[1].fxName)) or (proj ~= "" and token(proj)) or "Model")
  caps[#caps + 1] = "Captures d'entraînement (0 = auto)"
  defs[#defs + 1] = "0"
  caps[#caps + 1] = "Captures de validation (0 = auto)"
  defs[#defs + 1] = "0"
  caps[#caps + 1] = "Queue après chaque capture (s)"
  defs[#defs + 1] = getExt("namp_tail", "0.5")
  caps[#caps + 1] = "Préparer le rendu $region (o/n)"
  defs[#defs + 1] = getExt("render", "o")

  local ok, ret = r.GetUserInputs(SCRIPT .. " → Parametric NAM", #caps,
    table.concat(caps, ",") .. ",extrawidth=140", table.concat(defs, ","))
  if not ok then return end
  local vals = splitFields(ret)
  local n = #params

  -- knobs: continuous (0–10 scale = normalized × 10) or N-position switches
  local knobs, usedKeys = {}, {}
  for i, e in ipairs(params) do
    local field = vals[i]:lower()
    local nums = {}
    for x in field:gmatch("%-?[%d%.]+") do nums[#nums + 1] = tonumber(x) end
    local base = token(e.pName)
    local kkey, dup = base, 2
    while usedKeys[kkey:lower()] do kkey = base .. dup; dup = dup + 1 end
    usedKeys[kkey:lower()] = true
    local kn = { key = kkey, param = i }
    if field:match("pos") then
      local N = math.max(2, math.floor(nums[1] or 2))
      kn.kind = N == 2 and "boolean" or "choice"
      kn.levels, kn.labels = {}, {}
      local seenLabel, bestD = {}, math.huge
      for l = 1, N do
        local v = (l - 1) / (N - 1)
        kn.levels[l] = v
        local lab = token(fmt(i, v))
        if seenLabel[lab] then lab = lab .. "_" .. l end
        seenLabel[lab] = true
        kn.labels[l] = lab
        if math.abs(v - e.orig) < bestD then bestD, kn.default = math.abs(v - e.orig), l end
      end
    else
      local lo = math.min(100, math.max(0, nums[1] or 0)) / 10
      local hi = math.min(100, math.max(0, nums[2] or 100)) / 10
      if hi < lo then lo, hi = hi, lo end
      kn.kind, kn.lo, kn.hi = "continuous", lo, hi
      kn.default = math.min(hi, math.max(lo, round(e.orig * 10, 2)))
    end
    knobs[i] = kn
  end
  restoreAll()

  local model = token(vals[n + 1] ~= "" and vals[n + 1] or "Model")
  local nTrain = math.floor(tonumber(vals[n + 2]) or 0)
  local nVal = math.floor(tonumber(vals[n + 3]) or 0)
  local tail = math.max(0, tonumber(vals[n + 4]) or 0.5)
  local render = vals[n + 5]:lower():match("^[oy]") ~= nil
  r.SetExtState(EXT, "namp_model", model, true)
  r.SetExtState(EXT, "namp_tail", tostring(tail), true)
  r.SetExtState(EXT, "render", render and "o" or "n", true)

  local input = findInput()
  if not input and r.ShowMessageBox(
      "Aucun item audio ne couvre toute la time selection.\n\n"
        .. "Le modèle a besoin du fichier d'entrée (le signal de reamp, idéalement celui de `namp input`). "
        .. "Continuer quand même ? Il faudra alors passer --input à namp import-reaper.", SCRIPT, 4) ~= 6 then
    return
  end

  math.randomseed(os.time())
  local plan = Design.plan(knobs, nTrain, nVal)
  local N = #plan
  if N > 400 and r.ShowMessageBox(N .. " captures vont être créées. Continuer ?", SCRIPT, 4) ~= 6 then return end

  -- regions, normalized automation values, displayed values
  local combos, names, shown, settings = {}, {}, {}, {}
  local nTr, nVa = 0, 0
  for k, cp in ipairs(plan) do
    local c, sh, st = {}, {}, {}
    for i, kn in ipairs(knobs) do
      local v = cp.setting[i]
      if kn.kind == "continuous" then
        c[i] = v / 10
        st[kn.key] = v
      elseif kn.kind == "boolean" then
        c[i] = kn.levels[v]
        st[kn.key] = v == 2
      else
        c[i] = kn.levels[v]
        st[kn.key] = kn.labels[v]
      end
      sh[i] = fmt(i, c[i])
    end
    combos[k], shown[k], settings[k] = c, sh, st
    names[k] = nampRegionName(model, cp.split, k, knobs, cp.setting)
    if cp.split == "train" then nTr = nTr + 1 else nVa = nVa + 1 end
  end
  restoreAll()

  local dir = projectDir()
  local renderDir = dir .. "/NAMP_" .. model
  local _, _, numRegions = r.CountProjectMarkers(0)
  local cTrain = r.ColorToNative(90, 190, 120) | 0x1000000
  local cVal = r.ColorToNative(230, 160, 60) | 0x1000000
  local slot = generate(combos, names, tail, render, render and renderDir or nil,
    function(k) return plan[k].split == "validation" and cVal or cTrain end)

  local stamp = os.date("%Y%m%d-%H%M%S")
  local csv = writeCsv(dir .. "/todoroki_ParamSweep_" .. model .. "_" .. stamp .. ".csv", combos, names, shown, slot)

  -- manifest for `namp import-reaper`
  local nampKnobs, reaperParams = { __array = true }, { __array = true }
  for i, kn in ipairs(knobs) do
    local e = params[i]
    if kn.kind == "continuous" then
      nampKnobs[i] = { type = "continuous", name = kn.key, minval = kn.lo, maxval = kn.hi,
        default = kn.default, step = 0.01 }
    elseif kn.kind == "boolean" then
      nampKnobs[i] = { type = "boolean", name = kn.key, default = kn.default == 2 }
    else
      local opts = { __array = true }
      for l, lab in ipairs(kn.labels) do opts[l] = lab end
      nampKnobs[i] = { type = "choice", name = kn.key, options = opts, default = kn.default - 1 }
    end
    local lv = { __array = true }
    for l, v in ipairs(kn.levels or {}) do lv[l] = v end
    reaperParams[i] = { knob = kn.key, track = e.trName, fx = e.fxName, param = e.pName,
      scale = kn.kind == "continuous" and "knob = normalized x 10" or "levels", levels = lv }
  end
  local capsJson = { __array = true }
  for k, cp in ipairs(plan) do
    local s = ts + (k - 1) * slot
    capsJson[k] = { id = k, region = names[k], split = cp.split, kind = cp.kind, setting = settings[k],
      start = s - ts, ["end"] = s - ts + slot }
  end
  local srate = r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
  local manifest = {
    format = "todoroki-paramsweep-namp-1",
    model = model,
    created = stamp,
    knobs = nampKnobs,
    captures = capsJson,
    input = input,
    selection_length = selLen,
    tail = tail,
    slot = slot,
    project_sample_rate = srate,
    render_dir = renderDir,
    render_pattern = "$region",
    reaper_params = reaperParams,
  }
  local mpath = dir .. "/" .. model .. "_namp.json"
  local f = io.open(mpath, "w")
  if f then f:write(jsonEncode(manifest), "\n") f:close() else mpath = nil end

  local gridSize = 1
  for _, kn in ipairs(knobs) do
    gridSize = gridSize * (kn.kind == "continuous" and (math.floor((kn.hi - kn.lo) * 2 + 0.5) + 1) or #kn.levels)
  end
  local info = ("%d captures : %d d'entraînement, %d de validation (tenues à l'écart).\n"
    .. "Une grille au demi-cran aurait demandé %d captures.\n"
    .. "Durée à rendre : %.1f min."):format(N, nTr, nVa, gridSize, N * slot / 60)
  if mpath then info = info .. "\n\nManifeste : " .. mpath end
  if csv then info = info .. "\nCSV : " .. csv end
  if not input then
    info = info .. "\n\nPas d'item audio d'entrée détecté : passe --input à namp."
  elseif math.abs(input.playrate - 1) > 1e-9 then
    info = info .. "\n\nAttention : l'item d'entrée a un playrate de " .. input.playrate .. " ; remets-le à 1."
  end
  if srate > 0 and math.abs(srate - 48000) > 0.5 then
    info = info .. "\n\nAttention : le projet est à " .. math.floor(srate) .. " Hz ; NAM travaille à 48 kHz."
  end
  if render then
    info = info .. "\n\nRendu prêt ($region → " .. renderDir .. ").\n"
      .. "Rendre en WAV 24 bits ou 32 bits float, sans normalisation ni dither."
    if numRegions > 0 then
      info = info .. "\nLe projet contenait déjà " .. numRegions .. " région(s) : elles seront rendues aussi (namp les ignorera)."
    end
  end
  info = info .. "\n\nEnsuite : namp import-reaper \"" .. (mpath or "<manifeste>") .. "\" --project <dossier>"
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

gfx.init(SCRIPT, 680, 380)
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
  local namp = btn(170, by, 150, 28, "→ Parametric NAM")
  local cancel = btn(W - 262, by, 100, 28, "Annuler")
  local go = btn(W - 152, by, 140, 28, "Continuer (Entrée)")

  if cancel then
    restoreAll()
    done = true
    gfx.quit()
    return
  end
  if namp then
    done = true
    gfx.quit()
    proceedNamp()
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
