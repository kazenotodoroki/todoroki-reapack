-- @description Todoroki ZLEQ2 Curve Import - AutoEQ / Open Sound Meter curves to ZL Equalizer 2
-- @author Todoroki
-- @version 1.0
-- @changelog
--   Premiere version
-- @about
--   # Todoroki ZLEQ2 Curve Import
--
--   Lit une courbe et la transforme en bandes pour **ZL Equalizer 2** (ZL Audio).
--
--   Fichiers acceptes :
--   - **AutoEQ** : ParametricEQ.txt (filtres repris tels quels), GraphicEQ.txt, CSV AutoEQ
--     (colonnes equalization / error_smoothed / raw + target)
--   - **Open Sound Meter** : export CSV, TXT ou FRD d'une mesure (frequence, magnitude, phase, coherence)
--   - Tout CSV / TXT simple "frequence, dB" (REW, etc.)
--
--   Pour une courbe (CSV, mesure), le script calcule les bandes (Peak + shelves) qui reproduisent
--   la correction : nombre de bandes, plage de frequences, boost / cut / Q max, lissage, pente cible.
--   Une mesure est inversee (correction = niveau moyen - mesure), ponderee par la coherence OSM.
--
--   Sorties (au choix, combinables) :
--   - **A** : applique les bandes au ZL Equalizer 2 de la piste selectionnee (ou de la fenetre FX
--     ZL au premier plan ; propose de l'ajouter s'il manque). Preamp -> Output Gain.
--   - **C** : copie les bandes dans le presse-papiers au format ZL : clic droit dans ZL > Paste.
--     Un fichier _ZLEQ2_bands.xml est aussi ecrit a cote du fichier source.
--   - **M** : ecrit la courbe (mesure ou cible) comme cible EQ Match dans
--     ZL Audio/ZL Equalizer 2/Match Presets (EQ Match > Target : Preset).

local r = reaper
local TITLE = "Todoroki ZLEQ2 Curve Import"
local EXT = "Todoroki_ZLEQ2_CurveImport"
local ZL_MAX_BANDS = 24

local M = {}

----------------------------------------------------------------------------------------------------
-- Utils
----------------------------------------------------------------------------------------------------
local function trim(s) return (s:match("^%s*(.-)%s*$")) end
local function log10(x) return math.log(x, 10) end
local function log2(x) return math.log(x, 2) end
local function clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end

local function num(s)
  if not s then return nil end
  s = trim(s):gsub('^"(.*)"$', "%1"):gsub(",", ".")
  return tonumber(s)
end

local function split(line, sep)
  local t = {}
  if not sep then
    for w in line:gmatch("%S+") do t[#t + 1] = w end
    return t
  end
  local i = 1
  while true do
    local a, b = line:find(sep, i, true)
    if not a then t[#t + 1] = trim(line:sub(i)); break end
    t[#t + 1] = trim(line:sub(i, a - 1))
    i = b + 1
  end
  return t
end

local function read_lines(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local data = f:read("*a")
  f:close()
  data = data:gsub("^\239\187\191", "")
  local lines = {}
  for l in data:gmatch("[^\r\n]+") do lines[#lines + 1] = l end
  return lines
end

local function file_parts(path)
  local dir, name = path:match("^(.*)[/\\]([^/\\]+)$")
  if not dir then dir, name = ".", path end
  local base = name:gsub("%.[^%.]+$", "")
  return dir, base
end

----------------------------------------------------------------------------------------------------
-- Parsing
----------------------------------------------------------------------------------------------------
local TYPE_MAP = {
  PK = "PK", PEQ = "PK", MODAL = "PK",
  LSC = "LS", LS = "LS", LSQ = "LS",
  HSC = "HS", HS = "HS", HSQ = "HS",
  LP = "LP", LPQ = "LP", HP = "HP", HPQ = "HP",
  NO = "NO", BP = "BP", AP = "AP",
}

local function parse_parametric(lines)
  local res = { kind = "param", filters = {}, preamp = 0, source = "Parametric EQ (AutoEQ / EqualizerAPO)" }
  for _, l in ipairs(lines) do
    local pre = l:match("^%s*[Pp]reamp%s*:%s*([-+]?[%d%.]+)")
    if pre then res.preamp = tonumber(pre) or 0 end
    local body = l:match("^%s*[Ff]ilter%s*%d*%s*:%s*(.*)$")
    if body then
      local state, typ = body:match("^(%a+)%s+(%a+)")
      typ = typ and typ:upper()
      if state and state:upper() == "ON" and TYPE_MAP[typ] then
        local fc, unit = body:match("Fc%s+([%d%.]+)%s*([kK]?)[Hh]z")
        fc = tonumber(fc or body:match("Fc%s+([%d%.]+)"))
        if fc and unit and unit ~= "" then fc = fc * 1000 end
        local g = tonumber(body:match("Gain%s+([-+]?[%d%.]+)")) or 0
        local q = tonumber(body:match("Q%s+([%d%.]+)"))
        local bw = tonumber(body:match("BW%s+[Oo]ct%s+([%d%.]+)"))
        if not q and bw and bw > 0 then local n = 2 ^ bw; q = math.sqrt(n) / (n - 1) end
        if fc then
          res.filters[#res.filters + 1] = { type = TYPE_MAP[typ], fc = fc, g = g, q = q or 0.707 }
        end
      end
    end
  end
  return res
end

local function parse_graphic(lines)
  local f, v = {}, {}
  for _, l in ipairs(lines) do
    local body = l:match("^%s*GraphicEQ%s*:%s*(.*)$")
    if body then
      for pair in body:gmatch("[^;]+") do
        local a, b = pair:match("([%d%.]+)%s+([-+]?[%d%.]+)")
        if a and b then f[#f + 1] = tonumber(a); v[#v + 1] = tonumber(b) end
      end
    end
  end
  local w = {}
  for i = 1, #f do w[i] = 1 end
  return { kind = "curve", f = f, v = v, w = w, measurement = false, source = "AutoEQ GraphicEQ" }
end

local function detect_sep(lines)
  local counts = { [";"] = 0, ["\t"] = 0, [","] = 0 }
  local n = 0
  for _, l in ipairs(lines) do
    if not l:match("^%s*[%*#]") and l:match("%d") then
      for s in pairs(counts) do if l:find(s, 1, true) then counts[s] = counts[s] + 1 end end
      n = n + 1
      if n >= 30 then break end
    end
  end
  local best, bc = nil, 0
  for _, s in ipairs({ ";", "\t", "," }) do
    if counts[s] > bc then best, bc = s, counts[s] end
  end
  return best
end

local function parse_table(lines, path)
  local sep = detect_sep(lines)
  local header, rows = nil, {}
  local osm_text = false
  for _, l in ipairs(lines) do
    if l:find("Open Sound Meter", 1, true) then osm_text = true end
    if not l:match("^%s*[%*#]") then
      local cells = split(l, sep)
      local first = num(cells[1])
      if first and first > 0 and #cells >= 2 then
        local row = {}
        for i, c in ipairs(cells) do row[i] = num(c) end
        rows[#rows + 1] = row
      elseif not header and #rows == 0 and #cells >= 2 and l:match("%a") then
        header = {}
        for i, c in ipairs(cells) do header[i] = c:lower():gsub('"', ""):gsub("%s+", "_") end
      end
    end
  end
  if #rows < 3 then return nil, "Pas assez de lignes numeriques dans le fichier." end

  local col = {}
  if header then for i, h in ipairs(header) do col[h] = col[h] or i end end
  local fcol = col.frequency or col.freq or col.hz or col.frequency_hz or col["freq(hz)"] or 1

  local res = { kind = "curve", f = {}, v = {}, w = {}, measurement = true }
  local function pick(getter, src, is_meas)
    res.source, res.measurement = src, is_meas
    for _, row in ipairs(rows) do
      local fr, val = row[fcol], getter(row)
      if fr and val then
        res.f[#res.f + 1] = fr; res.v[#res.v + 1] = val; res.w[#res.w + 1] = 1
      end
    end
  end

  if header and col.equalization then
    pick(function(rw) return rw[col.equalization] end, "AutoEQ CSV (equalization)", false)
  elseif header and (col.error_smoothed or col.error) then
    local c = col.error_smoothed or col.error
    pick(function(rw) return rw[c] and -rw[c] end, "AutoEQ CSV (-error)", false)
  elseif header and col.raw and col.target then
    pick(function(rw) return rw[col.raw] and rw[col.target] and rw[col.target] - rw[col.raw] end,
      "AutoEQ CSV (target - raw)", false)
  else
    local vcol = (header and (col.raw or col.magnitude or col.spl or col.db or col.mag)) or 2
    local ncol = #rows[1]
    local cohcol = header and (col.coherence or col.coh) or nil
    if not cohcol and not header and ncol >= 4 then
      local ok = true
      for i = 1, math.min(#rows, 50) do
        local c = rows[i][4]
        if c and (c < 0 or c > 1.0001) then ok = false break end
      end
      if ok then cohcol = 4 end
    end
    local ext = (path or ""):match("%.(%w+)$")
    local src
    if cohcol or osm_text then src = "Open Sound Meter (mesure)"
    elseif ext and ext:lower() == "frd" then src = "FRD (mesure)"
    else src = "Courbe frequence / dB" end
    res.source, res.measurement = src, true
    for _, row in ipairs(rows) do
      local fr, val = row[fcol], row[vcol]
      if fr and val then
        local w = 1
        if cohcol then w = row[cohcol] or 0 end
        res.f[#res.f + 1] = fr; res.v[#res.v + 1] = val; res.w[#res.w + 1] = w
      end
    end
  end
  if header and col.target then
    res.match_f, res.match_v = {}, {}
    for _, row in ipairs(rows) do
      if row[fcol] and row[col.target] then
        res.match_f[#res.match_f + 1] = row[fcol]; res.match_v[#res.match_v + 1] = row[col.target]
      end
    end
  end
  if #res.f < 3 then return nil, "Colonne de valeurs introuvable." end
  return res
end

function M.parse(path)
  local lines = read_lines(path)
  if not lines then return nil, "Impossible de lire le fichier." end
  for _, l in ipairs(lines) do
    if l:match("^%s*[Ff]ilter%s*%d*%s*:") then return parse_parametric(lines) end
  end
  for _, l in ipairs(lines) do
    if l:match("^%s*GraphicEQ%s*:") then return parse_graphic(lines) end
  end
  return parse_table(lines, path)
end

----------------------------------------------------------------------------------------------------
-- Curve processing
----------------------------------------------------------------------------------------------------
function M.log_grid(f1, f2, ppo)
  local t = {}
  local n = math.floor(log2(f2 / f1) * ppo + 0.5)
  for i = 0, n do t[#t + 1] = f1 * 2 ^ (i / ppo) end
  return t
end

-- Average the source points falling in each log bin (weighted), fill holes by interpolation.
function M.resample(f, v, w, grid, ppo)
  local idx = {}
  for i = 1, #f do idx[i] = i end
  table.sort(idx, function(a, b) return f[a] < f[b] end)
  local h = 2 ^ (1 / (2 * ppo))
  local gv, gw, has = {}, {}, {}
  local j = 1
  for gi, g in ipairs(grid) do
    local lo, hi = g / h, g * h
    while j <= #idx and f[idx[j]] < lo do j = j + 1 end
    local k, sv, sw, cnt = j, 0, 0, 0
    while k <= #idx and f[idx[k]] < hi do
      local wi = w[idx[k]] or 1
      sv = sv + v[idx[k]] * wi; sw = sw + wi; cnt = cnt + 1
      k = k + 1
    end
    if sw > 0 then
      gv[gi], gw[gi], has[gi] = sv / sw, sw / cnt, true
    end
  end
  -- fill gaps
  local fmin, fmax = f[idx[1]], f[idx[#idx]]
  local last = nil
  for gi = 1, #grid do
    if has[gi] then
      if last and gi - last > 1 then
        for m = last + 1, gi - 1 do
          local t = (m - last) / (gi - last)
          gv[m] = gv[last] + (gv[gi] - gv[last]) * t
          gw[m] = 0.25 * math.min(gw[last], gw[gi])
        end
      end
      last = gi
    end
  end
  if not last then return nil end
  local firsti
  for gi = 1, #grid do if gv[gi] then firsti = gi break end end
  for gi = 1, #grid do
    if not gv[gi] then
      local src = gi < firsti and firsti or last
      gv[gi] = gv[src]
      gw[gi] = 0
    end
    if grid[gi] < fmin / h or grid[gi] > fmax * h then gw[gi] = 0 end
  end
  return gv, gw
end

-- Box smoothing of 1/frac octave on a log grid with ppo points per octave.
function M.smooth(v, w, ppo, frac)
  if not frac or frac <= 0 then return v end
  local half = math.max(1, math.floor(ppo / (2 * frac) + 0.5))
  local out = {}
  for i = 1, #v do
    local sv, sw = 0, 0
    for k = math.max(1, i - half), math.min(#v, i + half) do
      local wk = math.max(w[k], 1e-3)
      sv = sv + v[k] * wk; sw = sw + wk
    end
    out[i] = sv / sw
  end
  return out
end

----------------------------------------------------------------------------------------------------
-- Filter responses (analog prototypes, same formulas as ZL Equalizer 2 / RBJ)
----------------------------------------------------------------------------------------------------
function M.filt_db(t, fc, g, q, f)
  local w = f / fc
  local w2 = w * w
  if t == "PK" then
    local A = 10 ^ (g / 40)
    local re = 1 - w2
    local n = re * re + (A * w / q) ^ 2
    local d = re * re + (w / (A * q)) ^ 2
    return 10 * log10(n / d)
  elseif t == "LS" then
    local A = 10 ^ (g / 40); local sA = math.sqrt(A)
    local nr, ni = A - w2, sA * w / q
    local dr, di = 1 / A - w2, sA * w / (A * q)
    return 10 * log10((nr * nr + ni * ni) / (dr * dr + di * di))
  elseif t == "HS" then
    local A = 10 ^ (g / 40); local sA = math.sqrt(A)
    local nr, ni = A - A * A * w2, A * sA * w / q
    local dr, di = A - w2, sA * w / q
    return 10 * log10((nr * nr + ni * ni) / (dr * dr + di * di))
  else
    local re = 1 - w2
    local d = re * re + (w / q) ^ 2
    local n
    if t == "LP" then n = 1
    elseif t == "HP" then n = w2 * w2
    elseif t == "NO" then n = re * re
    elseif t == "BP" then n = (w / q) ^ 2
    else return 0 end
    return 10 * log10(math.max(n, 1e-30) / d)
  end
end

function M.response(filters, F)
  local H = {}
  for i = 1, #F do H[i] = 0 end
  for _, fl in ipairs(filters) do
    for i = 1, #F do H[i] = H[i] + M.filt_db(fl.type, fl.fc, fl.g, fl.q, F[i]) end
  end
  return H
end

----------------------------------------------------------------------------------------------------
-- Fitting (greedy init + Levenberg-Marquardt)
----------------------------------------------------------------------------------------------------
local function solve(A, b, n)
  for c = 1, n do
    local p, pv = c, math.abs(A[c][c])
    for rr = c + 1, n do if math.abs(A[rr][c]) > pv then p, pv = rr, math.abs(A[rr][c]) end end
    if pv < 1e-15 then return nil end
    A[c], A[p] = A[p], A[c]; b[c], b[p] = b[p], b[c]
    for rr = c + 1, n do
      local fct = A[rr][c] / A[c][c]
      if fct ~= 0 then
        for k = c, n do A[rr][k] = A[rr][k] - fct * A[c][k] end
        b[rr] = b[rr] - fct * b[c]
      end
    end
  end
  local x = {}
  for c = n, 1, -1 do
    local s = b[c]
    for k = c + 1, n do s = s - A[c][k] * x[k] end
    x[c] = s / A[c][c]
  end
  return x
end

local function limits(fl, o)
  if fl.type == "PK" then
    return o.fmin, o.fmax, 0.2, o.qmax
  else
    return 15, 22000, 0.4, 1.5
  end
end

local function clamp_filter(fl, o)
  local f1, f2, q1, q2 = limits(fl, o)
  fl.fc = clamp(fl.fc, f1, f2)
  fl.q = clamp(fl.q, q1, q2)
  fl.g = clamp(fl.g, -o.cut, o.boost)
end

-- active: list of filter indices to optimize (others are fixed)
local function optimize(filters, active, F, T, W, o, iters)
  local N = #F
  local R = {}
  for k, fl in ipairs(filters) do
    R[k] = {}
    for i = 1, N do R[k][i] = M.filt_db(fl.type, fl.fc, fl.g, fl.q, F[i]) end
  end
  local function total_cost(Rr)
    local c = 0
    for i = 1, N do
      if W[i] > 0 then
        local h = 0
        for k = 1, #filters do h = h + Rr[k][i] end
        c = c + W[i] * (h - T[i]) ^ 2
      end
    end
    return c
  end
  local pts = {}
  for i = 1, N do if W[i] > 0 then pts[#pts + 1] = i end end
  local cost = total_cost(R)
  local lambda = 1e-2
  local P = 3 * #active
  for _ = 1, iters do
    -- residual
    local res = {}
    for _, i in ipairs(pts) do
      local h = 0
      for k = 1, #filters do h = h + R[k][i] end
      res[i] = h - T[i]
    end
    -- jacobian columns
    local cols = {}
    for a, k in ipairs(active) do
      local fl = filters[k]
      local base = { math.log(fl.fc), fl.g, math.log(fl.q) }
      for j = 1, 3 do
        local step = (j == 2) and 1e-3 or 1e-4
        local p = { base[1], base[2], base[3] }
        p[j] = p[j] + step
        local fc, g, q = math.exp(p[1]), p[2], math.exp(p[3])
        local colv = {}
        for _, i in ipairs(pts) do
          colv[i] = (M.filt_db(fl.type, fc, g, q, F[i]) - R[k][i]) / step
        end
        cols[(a - 1) * 3 + j] = colv
      end
    end
    local JtJ, Jtr = {}, {}
    for p1 = 1, P do
      JtJ[p1] = {}
      local c1 = cols[p1]
      local s = 0
      for _, i in ipairs(pts) do s = s + W[i] * c1[i] * res[i] end
      Jtr[p1] = -s
      for p2 = 1, p1 do
        local c2 = cols[p2]
        local s2 = 0
        for _, i in ipairs(pts) do s2 = s2 + W[i] * c1[i] * c2[i] end
        JtJ[p1][p2] = s2
        JtJ[p2] = JtJ[p2] or {}
        JtJ[p2][p1] = s2
      end
    end
    local improved = false
    while lambda < 1e8 do
      local A, b = {}, {}
      for p1 = 1, P do
        A[p1] = {}
        for p2 = 1, P do A[p1][p2] = JtJ[p1][p2] end
        A[p1][p1] = A[p1][p1] * (1 + lambda) + 1e-9
        b[p1] = Jtr[p1]
      end
      local d = solve(A, b, P)
      if not d then lambda = lambda * 10 else
        local saved, newR = {}, {}
        for k = 1, #filters do newR[k] = R[k] end
        for a, k in ipairs(active) do
          local fl = filters[k]
          saved[a] = { fl.fc, fl.g, fl.q }
          fl.fc = math.exp(math.log(fl.fc) + clamp(d[(a - 1) * 3 + 1], -1, 1))
          fl.g = fl.g + clamp(d[(a - 1) * 3 + 2], -12, 12)
          fl.q = math.exp(math.log(fl.q) + clamp(d[(a - 1) * 3 + 3], -1, 1))
          clamp_filter(fl, o)
          local rk = {}
          for i = 1, N do rk[i] = M.filt_db(fl.type, fl.fc, fl.g, fl.q, F[i]) end
          newR[k] = rk
        end
        local nc = total_cost(newR)
        if nc < cost then
          local rel = (cost - nc) / math.max(cost, 1e-12)
          R, cost = newR, nc
          lambda = math.max(lambda * 0.3, 1e-7)
          improved = rel > 1e-7
          break
        else
          for a, k in ipairs(active) do
            local fl = filters[k]
            fl.fc, fl.g, fl.q = saved[a][1], saved[a][2], saved[a][3]
          end
          lambda = lambda * 5
        end
      end
    end
    if not improved then break end
  end
  return cost
end

local function wrms(filters, F, T, W)
  local H = M.response(filters, F)
  local s, sw = 0, 0
  for i = 1, #F do
    if W[i] > 0 then s = s + W[i] * (H[i] - T[i]) ^ 2; sw = sw + W[i] end
  end
  return sw > 0 and math.sqrt(s / sw) or 0
end

local function bw_to_q(bw)
  local n = 2 ^ bw
  return math.sqrt(n) / (n - 1)
end

-- Best new peak on the residual: largest |error| x bandwidth area
local function best_peak(filters, F, T, W, o)
  local H = M.response(filters, F)
  local e = {}
  for i = 1, #F do e[i] = T[i] - H[i] end
  local best, bscore
  for i = 1, #F do
    if W[i] > 0 and F[i] >= o.fmin and F[i] <= o.fmax and math.abs(e[i]) > 0.1 then
      local isext = (i == 1 or math.abs(e[i]) >= math.abs(e[i - 1])) and (i == #F or math.abs(e[i]) >= math.abs(e[i + 1]))
      if isext then
        local half = math.abs(e[i]) / 2
        local sg = e[i] > 0
        local lo, hi = i, i
        while lo > 1 and (e[lo - 1] > 0) == sg and math.abs(e[lo - 1]) > half do lo = lo - 1 end
        while hi < #F and (e[hi + 1] > 0) == sg and math.abs(e[hi + 1]) > half do hi = hi + 1 end
        local bw = math.max(log2(F[hi] / F[lo]), 0.05)
        local score = math.abs(e[i]) * bw * W[i]
        if not bscore or score > bscore then
          bscore = score
          best = { type = "PK", fc = F[i], g = e[i], q = bw_to_q(bw) }
        end
      end
    end
  end
  if best then clamp_filter(best, o) end
  return best
end

local function weighted_mean(F, V, W, f1, f2)
  local s, sw = 0, 0
  for i = 1, #F do
    if F[i] >= f1 and F[i] <= f2 and W[i] > 0 then s = s + V[i] * W[i]; sw = sw + W[i] end
  end
  return sw > 0 and s / sw or nil
end

-- o: bands, fmin, fmax, boost, cut, qmax, shelves(bool), tol
function M.fit(F, T, W, o)
  local filters = {}
  local function all() local t = {} for k = 1, #filters do t[k] = k end return t end
  if o.shelves and o.bands >= 3 then
    if o.fmin <= 105 then
      local g = weighted_mean(F, T, W, o.fmin, 105)
      if g and math.abs(g) > 1 then filters[#filters + 1] = { type = "LS", fc = 105, g = g, q = 0.7 } end
    end
    if o.fmax >= 10000 then
      local g = weighted_mean(F, T, W, 10000, o.fmax)
      if g and math.abs(g) > 1 then filters[#filters + 1] = { type = "HS", fc = 10000, g = g, q = 0.7 } end
    end
    for _, fl in ipairs(filters) do clamp_filter(fl, o) end
    if #filters > 0 then optimize(filters, all(), F, T, W, o, 20) end
  end
  while #filters < o.bands do
    if wrms(filters, F, T, W) < o.tol then break end
    local p = best_peak(filters, F, T, W, o)
    if not p then break end
    filters[#filters + 1] = p
    optimize(filters, { #filters }, F, T, W, o, 25)
    optimize(filters, all(), F, T, W, o, 8)
  end
  if #filters > 0 then optimize(filters, all(), F, T, W, o, 60) end
  local kept = {}
  for _, fl in ipairs(filters) do if math.abs(fl.g) >= 0.05 then kept[#kept + 1] = fl end end
  table.sort(kept, function(a, b) return a.fc < b.fc end)
  for _, fl in ipairs(kept) do
    fl.fc = math.floor(fl.fc * 10 + 0.5) / 10
    fl.g = math.floor(fl.g * 100 + 0.5) / 100
    fl.q = math.floor(fl.q * 1000 + 0.5) / 1000
  end
  return kept, wrms(kept, F, T, W)
end

function M.preamp_for(filters)
  local G = M.log_grid(10, 22000, 48)
  local H = M.response(filters, G)
  local mx = 0
  for i = 1, #H do if H[i] > mx then mx = H[i] end end
  return -math.ceil(mx * 10 - 1e-9) / 10
end

-- Builds fit target from a parsed curve. Returns F, T, W (fit grid) and curve for EQ Match.
function M.prepare(data, o)
  local PPO = 24
  local F = M.log_grid(20, 20000, PPO)
  local v, w = M.resample(data.f, data.v, data.w, F, PPO)
  if not v then return nil end
  v = M.smooth(v, w, PPO, o.smooth)
  local ref = 0
  if o.invert then
    ref = weighted_mean(F, v, w, o.fmin, o.fmax) or 0
  end
  local T, W = {}, {}
  for i = 1, #F do
    local base = o.invert and -(v[i] - ref) or v[i]
    base = base + (o.slope or 0) * log2(F[i] / 1000)
    T[i] = clamp(base, -o.cut, o.boost)
    if F[i] >= o.fmin and F[i] <= o.fmax then
      W[i] = w[i]
      if o.coh_min and W[i] < o.coh_min then W[i] = 0 end
    else
      T[i], W[i] = 0, 0.1
    end
  end
  return F, T, W
end

function M.match_curve(data, o)
  local PPO = 48
  local F = M.log_grid(20, 20000, PPO)
  local mf, mv = data.match_f, data.match_v
  local mw
  if mf then
    mw = {}
    for i = 1, #mf do mw[i] = 1 end
  else
    mf, mv, mw = data.f, data.v, data.w
  end
  local v, w = M.resample(mf, mv, mw, F, PPO)
  if not v then return nil end
  v = M.smooth(v, w, PPO, o.smooth)
  local mean = 0
  for i = 1, #v do mean = mean + v[i] end
  mean = mean / #v
  for i = 1, #v do v[i] = v[i] - mean - 30 end
  return F, v
end

----------------------------------------------------------------------------------------------------
-- ZL Equalizer 2 output
----------------------------------------------------------------------------------------------------
local ZL_TYPE = {
  PK = "Peak", LS = "Low Shelf", HS = "High Shelf", LP = "Low Pass",
  HP = "High Pass", NO = "Notch", BP = "Band Pass", AP = "All Pass",
}

function M.clipboard_xml(filters)
  local t = { '<?xml version="1.0" encoding="UTF-8"?>', "", "<filter_info>" }
  for i, fl in ipairs(filters) do
    t[#t + 1] = string.format(
      '  <filter%d filter_status="On" filter_type="%s" order="12 dB/oct" lr_mode="Stereo" '
        .. 'freq="%.1f" gain="%.2f" target_gain="%.2f" q="%.3f" dynamic_on="Off"/>',
      i - 1, ZL_TYPE[fl.type] or "Peak", fl.fc, fl.g, fl.g, fl.q)
  end
  t[#t + 1] = "</filter_info>"
  return table.concat(t, "\n") .. "\n"
end

local function set_clipboard(text)
  if r.CF_SetClipboard then r.CF_SetClipboard(text) return true end
  local tmp = (os.getenv("TEMP") or os.getenv("TMPDIR") or "/tmp") .. "/todoroki_zleq2_clip.txt"
  local f = io.open(tmp, "wb")
  if not f then return false end
  f:write(text); f:close()
  local osn = r.GetOS()
  if osn:match("Win") then
    r.ExecProcess('cmd.exe /C clip < "' .. tmp .. '"', 5000)
  elseif osn:match("OSX") or osn:match("mac") then
    r.ExecProcess('/bin/sh -c "pbcopy < \'' .. tmp .. '\'"', 5000)
  else
    r.ExecProcess('/bin/sh -c "xclip -selection clipboard < \'' .. tmp .. '\'"', 5000)
  end
  return true
end

local function appdata_dir()
  local osn = r.GetOS()
  local home = os.getenv("HOME") or ""
  if osn:match("Win") then return os.getenv("APPDATA") end
  if osn:match("OSX") or osn:match("mac") then return home .. "/Library" end
  return os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
end

function M.write_match(F, V, name)
  local root = appdata_dir()
  if not root then return nil end
  local sep = package.config:sub(1, 1)
  local dirs = {
    root .. sep .. "ZL Audio" .. sep .. "ZL Equalizer 2" .. sep .. "Match Presets",
    root .. sep .. "Audio" .. sep .. "Presets" .. sep .. "ZL" .. sep .. "ZL Equalizer 2" .. sep .. "Match Presets",
  }
  local lines = {}
  for i = 1, #F do lines[i] = string.format("%.2f,%.3f", F[i], V[i]) end
  local content = table.concat(lines, "\n") .. "\n"
  local written
  for di, d in ipairs(dirs) do
    if di == 1 then r.RecursiveCreateDirectory(d, 0) end
    local f = io.open(d .. sep .. name .. ".csv", "wb")
    if f then
      f:write(content); f:close()
      written = written or (d .. sep .. name .. ".csv")
    end
  end
  return written
end

-- FX helpers ------------------------------------------------------------------------------------
local function is_zl(name) local n = name:lower() return n:find("zl equalizer 2", 1, true) or n:find("zlequalizer2", 1, true) end

local function fmt_norm(tr, fx, p, v)
  local ok, s = r.TrackFX_FormatParamValueNormalized(tr, fx, p, v, "")
  if ok and s and s ~= "" then return s end
  r.TrackFX_SetParamNormalized(tr, fx, p, v)
  local _, s2 = r.TrackFX_GetFormattedParamValue(tr, fx, p, "")
  return s2 or ""
end

local function text_num(s)
  local x = tonumber((s or ""):match("[-+]?%d+%.?%d*"))
  if x and s:match("%d%s*[kK]") then x = x * 1000 end
  return x
end

local choice_cache = {}
local function choice_value(tr, fx, p, key, label)
  local c = choice_cache[key]
  if not c then
    c = {}
    local STEPS = 240
    for i = 0, STEPS do
      local v = i / STEPS
      local s = trim(fmt_norm(tr, fx, p, v)):lower()
      c[s] = c[s] or {}
      table.insert(c[s], v)
    end
    choice_cache[key] = c
  end
  local list = c[label:lower()]
  if not list then return nil end
  return list[math.floor((#list + 1) / 2)]
end

local function set_choice(tr, fx, p, key, label)
  local v = choice_value(tr, fx, p, key, label)
  if not v then return false end
  r.TrackFX_SetParamNormalized(tr, fx, p, v)
  return true
end

local function set_float(tr, fx, p, target)
  local vlo, vhi = text_num(fmt_norm(tr, fx, p, 0)), text_num(fmt_norm(tr, fx, p, 1))
  if not vlo or not vhi or vlo == vhi then return false end
  local inc = vhi > vlo
  local lo, hi = 0, 1
  for _ = 1, 32 do
    local m = (lo + hi) / 2
    local vm = text_num(fmt_norm(tr, fx, p, m))
    if not vm then break end
    if (vm < target) == inc then lo = m else hi = m end
  end
  local tl, th = text_num(fmt_norm(tr, fx, p, lo)), text_num(fmt_norm(tr, fx, p, hi))
  local best = hi
  if tl and th and math.abs(tl - target) < math.abs(th - target) then best = lo end
  r.TrackFX_SetParamNormalized(tr, fx, p, best)
  return true
end

local function find_target_fx()
  local ret, tnum, inum, fxn = r.GetFocusedFX2()
  ret = math.tointeger(ret) or 0
  if (ret & 1) == 1 and (inum or -1) < 0 then
    local tr = tnum == 0 and r.GetMasterTrack(0) or r.GetTrack(0, tnum - 1)
    if tr then
      local _, nm = r.TrackFX_GetFXName(tr, fxn, "")
      if is_zl(nm) then return tr, fxn end
    end
  end
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then return nil, nil, "Selectionne une piste (ou ouvre la fenetre de ZL Equalizer 2)." end
  for i = 0, r.TrackFX_GetCount(tr) - 1 do
    local _, nm = r.TrackFX_GetFXName(tr, i, "")
    if is_zl(nm) then return tr, i end
  end
  if r.ShowMessageBox("Pas de ZL Equalizer 2 sur la piste selectionnee.\nL'ajouter ?", TITLE, 4) ~= 6 then
    return nil, nil, nil
  end
  local fx = r.TrackFX_AddByName(tr, "ZL Equalizer 2", false, -1)
  if fx < 0 then return nil, nil, "ZL Equalizer 2 introuvable : verifie qu'il est installe et scanne dans REAPER." end
  return tr, fx
end

function M.apply_to_fx(filters, preamp, use_preamp)
  local tr, fx, err = find_target_fx()
  if not tr then return false, err end
  choice_cache = {}
  local map = {}
  for p = 0, r.TrackFX_GetNumParams(tr, fx) - 1 do
    local _, n = r.TrackFX_GetParamName(tr, fx, p, "")
    map[n] = p
  end
  local nb = 0
  while map["Freq" .. nb] do nb = nb + 1 end
  if nb == 0 then return false, "Parametres de ZL Equalizer 2 introuvables (Freq0...)." end
  if #filters > nb then return false, "Trop de bandes (" .. #filters .. ") : ZL n'en a que " .. nb .. "." end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  for b = 0, nb - 1 do
    local p = map["Filter Status" .. b]
    if p then set_choice(tr, fx, p, "status", "Off") end
  end
  local missing = {}
  for i, fl in ipairs(filters) do
    local b = i - 1
    local function P(name) local p = map[name .. b] if not p then missing[name] = true end return p end
    local p
    p = P("Dynamic ON"); if p then r.TrackFX_SetParamNormalized(tr, fx, p, 0) end
    p = P("Filter Type")
    if p and not set_choice(tr, fx, p, "type", ZL_TYPE[fl.type] or "Peak") then missing["type " .. fl.type] = true end
    p = P("Order"); if p then set_choice(tr, fx, p, "order", "12 dB/oct") end
    p = P("LRMode"); if p then set_choice(tr, fx, p, "lr", "Stereo") end
    p = P("Freq"); if p then set_float(tr, fx, p, fl.fc) end
    p = P("Gain"); if p then set_float(tr, fx, p, fl.g) end
    p = P("Target Gain"); if p then set_float(tr, fx, p, fl.g) end
    p = P("Q"); if p then set_float(tr, fx, p, fl.q) end
    p = P("Filter Status"); if p then set_choice(tr, fx, p, "status", "On") end
  end
  if use_preamp and map["Output Gain"] then set_float(tr, fx, map["Output Gain"], preamp) end
  r.PreventUIRefresh(-1)
  r.Undo_EndBlock(TITLE, -1)
  r.TrackFX_Show(tr, fx, 3)
  local miss = {}
  for k in pairs(missing) do miss[#miss + 1] = k end
  if #miss > 0 then return true, "Attention, parametres non trouves : " .. table.concat(miss, ", ") end
  return true
end

----------------------------------------------------------------------------------------------------
-- UI
----------------------------------------------------------------------------------------------------
local function get_ext(k, d)
  local v = r.GetExtState(EXT, k)
  if v == "" then return d end
  return v
end

local function yes(s) s = (s or ""):lower() return s:sub(1, 1) == "o" or s:sub(1, 1) == "y" or s == "1" end

local function pick_file()
  local last = get_ext("dir", "")
  if r.JS_Dialog_BrowseForOpenFiles then
    local rv, p = r.JS_Dialog_BrowseForOpenFiles(TITLE .. " - courbe AutoEQ / Open Sound Meter", last, "",
      "Courbes (*.csv;*.txt;*.frd)\0*.csv;*.txt;*.frd\0Tous les fichiers (*.*)\0*.*\0\0", false)
    if (rv == 1 or rv == true) and p and p ~= "" then return p end
    return nil
  end
  local ok, p = r.GetUserFileNameForRead(last, TITLE .. " - courbe AutoEQ / Open Sound Meter", "*.csv;*.txt;*.frd")
  if ok then return p end
end

local function describe(filters)
  local t = {}
  for i, fl in ipairs(filters) do
    t[#t + 1] = string.format("%2d  %-10s %8.1f Hz  %+6.2f dB  Q %.3f", i, ZL_TYPE[fl.type] or fl.type, fl.fc, fl.g, fl.q)
  end
  return table.concat(t, "\n")
end

local function main()
  local path = pick_file()
  if not path then return end
  local dir, base = file_parts(path)
  r.SetExtState(EXT, "dir", dir, true)

  local data, err = M.parse(path)
  if not data then r.ShowMessageBox(err or "Format non reconnu.", TITLE, 0) return end

  local filters, preamp, rms
  local o = {}
  local outputs, use_preamp

  if data.kind == "param" then
    if #data.filters == 0 then r.ShowMessageBox("Aucun filtre actif dans le fichier.", TITLE, 0) return end
    local ok, csv = r.GetUserInputs(TITLE .. " - " .. #data.filters .. " filtres", 2,
      "Sortie (A=appliquer C=presse-papiers),Preamp -> Output Gain (o/n),extrawidth=120,separator=|",
      get_ext("out_p", "AC") .. "|o")
    if not ok then return end
    local v = split(csv, "|")
    outputs = (v[1] or "A"):upper()
    use_preamp = yes(v[2])
    r.SetExtState(EXT, "out_p", outputs, true)
    filters = data.filters
    preamp = data.preamp ~= 0 and data.preamp or M.preamp_for(filters)
    if #filters > ZL_MAX_BANDS then
      while #filters > ZL_MAX_BANDS do table.remove(filters) end
    end
  else
    local fmin_def = data.measurement and get_ext("fmin_m", "30") or get_ext("fmin", "20")
    local fmax_def = data.measurement and get_ext("fmax_m", "16000") or get_ext("fmax", "20000")
    local defaults = {
      get_ext("bands", "10"),
      data.measurement and "o" or "n",
      fmin_def, fmax_def,
      get_ext("boost", "6"), get_ext("cut", "12"), get_ext("qmax", "6"),
      get_ext("smooth", data.measurement and "6" or "0"),
      get_ext("slope", "0"),
      get_ext("shelves", "o"),
      get_ext("out", "AC"),
      get_ext("pre", "o"),
    }
    local caps = "Bandes max (1-24),Inverser (mesure -> correction) o/n,Freq min (Hz),Freq max (Hz),"
      .. "Boost max (dB),Cut max (dB),Q max,Lissage 1/N oct (0=aucun),Pente cible (dB/oct),"
      .. "Shelves aux extremites o/n,Sortie A=appliquer C=presse-pap. M=Match,Preamp -> Output Gain o/n,"
      .. "extrawidth=120,separator=|"
    local ok, csv = r.GetUserInputs(TITLE .. " - " .. data.source, 12, caps, table.concat(defaults, "|"))
    if not ok then return end
    local v = split(csv, "|")
    o.bands = clamp(math.floor(num(v[1]) or 10), 1, ZL_MAX_BANDS)
    o.invert = yes(v[2])
    o.fmin = clamp(num(v[3]) or 20, 10, 20000)
    o.fmax = clamp(num(v[4]) or 20000, o.fmin * 1.5, 22000)
    o.boost = math.abs(num(v[5]) or 6)
    o.cut = math.abs(num(v[6]) or 12)
    o.qmax = clamp(num(v[7]) or 6, 0.5, 25)
    o.smooth = math.max(0, num(v[8]) or 0)
    o.slope = num(v[9]) or 0
    o.shelves = yes(v[10])
    outputs = (v[11] or "A"):upper()
    use_preamp = yes(v[12])
    o.tol = 0.2
    o.coh_min = data.source:find("Open Sound Meter") and 0.5 or nil
    r.SetExtState(EXT, "bands", tostring(o.bands), true)
    r.SetExtState(EXT, data.measurement and "fmin_m" or "fmin", tostring(o.fmin), true)
    r.SetExtState(EXT, data.measurement and "fmax_m" or "fmax", tostring(o.fmax), true)
    r.SetExtState(EXT, "boost", tostring(o.boost), true)
    r.SetExtState(EXT, "cut", tostring(o.cut), true)
    r.SetExtState(EXT, "qmax", tostring(o.qmax), true)
    r.SetExtState(EXT, "smooth", tostring(o.smooth), true)
    r.SetExtState(EXT, "slope", tostring(o.slope), true)
    r.SetExtState(EXT, "shelves", o.shelves and "o" or "n", true)
    r.SetExtState(EXT, "out", outputs, true)
    r.SetExtState(EXT, "pre", use_preamp and "o" or "n", true)

    if outputs:find("[AC]") then
      local F, T, W = M.prepare(data, o)
      if not F then r.ShowMessageBox("Courbe vide apres traitement.", TITLE, 0) return end
      filters, rms = M.fit(F, T, W, o)
      preamp = M.preamp_for(filters)
    end
  end

  local report = { "Source : " .. data.source, "" }
  if filters then
    report[#report + 1] = describe(filters)
    report[#report + 1] = ""
    if rms then report[#report + 1] = string.format("Erreur residuelle : %.2f dB RMS", rms) end
    report[#report + 1] = string.format("Preamp conseille : %.1f dB", preamp)
    report[#report + 1] = ""
  end

  if filters and outputs:find("A") then
    local ok, e = M.apply_to_fx(filters, preamp, use_preamp)
    if ok then
      report[#report + 1] = "A : bandes appliquees a ZL Equalizer 2" .. (use_preamp and " (Output Gain = preamp)." or ".")
      if e then report[#report + 1] = e end
    elseif e then
      report[#report + 1] = "A : " .. e
    else
      report[#report + 1] = "A : annule."
    end
  end
  if filters and outputs:find("C") then
    local xml = M.clipboard_xml(filters)
    local xp = dir .. "/" .. base .. "_ZLEQ2_bands.xml"
    local f = io.open(xp, "wb")
    if f then f:write(xml); f:close() end
    set_clipboard(xml)
    report[#report + 1] = "C : copie dans le presse-papiers -> dans ZL : clic droit > Paste."
    report[#report + 1] = "     (aussi enregistre : " .. xp .. ")"
    if use_preamp and preamp ~= 0 then
      report[#report + 1] = string.format("     Regle Output Gain a %.1f dB a la main.", preamp)
    end
  end
  if data.kind == "curve" and outputs:find("M") then
    local F, V = M.match_curve(data, o)
    local p = F and M.write_match(F, V, base)
    if p then
      report[#report + 1] = "M : cible EQ Match ecrite -> ZL : EQ Match > Target : Preset"
      report[#report + 1] = "     " .. p
    else
      report[#report + 1] = "M : impossible d'ecrire la cible EQ Match."
    end
  end
  r.ShowMessageBox(table.concat(report, "\n"), TITLE, 0)
end

if TODOROKI_TEST then return M end
main()
