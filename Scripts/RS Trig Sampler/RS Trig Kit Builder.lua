-- @description RS Trig Kit Builder - TCI import, kit builder and library for RS Trig Sampler
-- @author Todoroki
-- @version 1.4
-- @changelog
--   - Import Slate Trigger 2 .tci files (bit-exact decoding, velocity layers and round robins kept)
--   - Automatic library organisation: <Element>/<Instrument>/<name>.rsk.wav
--   - Build kits from WAV folders (V01_RR1, Vel3, name_025_01 and untagged conventions)
--   - Unpack kits to WAV, rescan the library, demo kit installed on first run
--   - English UI
-- @provides
--   [main] .
--   [main] RS Trig Rescan Library.lua
--   [nomain] RS Trig Demo Kick.rsk.wav
--   RS Trig Sampler README.md
-- @about
--   # RS Trig Kit Builder
--
--   Companion script of the **RS Trig Sampler** JSFX (install both packages).
--
--   - Import .tci files from a Slate Trigger 2 library (one file or a whole folder tree)
--   - Build multi-velocity / round-robin kits from WAV folders
--   - Everything lands in `<REAPER>/Data/RSampler`, sorted as Element / Instrument
--   - "RS Trig Rescan Library" refreshes the list shown in the sampler's browser
--
--   Pure Lua, no extension required (portable REAPER friendly).

-- RS Trig Kit Builder - companion script for the "RS Trig Sampler" JSFX.
-- Pure Lua, no extension required: works in a portable REAPER.
--
--   Import .tci (Slate Trigger 2)  ->  <REAPER>/Data/RSampler/<Element>/<Instrument>/<name>.rsk.wav
--   Build kits from WAV folders    ->  same organisation (Kick / Snare / Tom / HiHat / Cymbal ...)
--   Unpack a kit back to WAV files, rescan the library index
--
-- .rsk.wav format: a 32-bit float WAV. Its first values (read as samples) are a header:
--   MAGIC(-7337.25), version(1), channels, layers, header length,
--   then per layer: vel lo, vel hi, RR count, then RR count x (offset frames, length frames).
-- All samples follow, concatenated. One file per instrument/mic = easy to move around.

local MAGIC      = -7337.25
local SLOT_VALUES = 15900000     -- sampler slot capacity (values, recent REAPER)
local MAX_LAYERS, MAX_RR = 32, 16

local SEP = package.config:sub(1,1)

---------------------------------------------------------------- utilities
local function join(a, b)
  if a:sub(-1) == "/" or a:sub(-1) == "\\" then return a .. b end
  return a .. SEP .. b
end

local function dirname(p)  return p:match("^(.*)[/\\][^/\\]*$") or "." end
local function basename(p) return p:match("([^/\\]+)$") or p end

local function natural_lt(a, b)
  local function pad(s) return (s:lower():gsub("%d+", function(d) return ("%012d"):format(tonumber(d)) end)) end
  return pad(a) < pad(b)
end

---------------------------------------------------------------- WAV reading
-- returns { sr=, nch=, frames=, ch = { {..L..}, {..R..} } }  (2 channels max)
local function read_wav(path)
  local f = io.open(path, "rb")
  if not f then return nil, "cannot open file" end
  local d = f:read("a"); f:close()
  if #d < 12 or d:sub(1,4) ~= "RIFF" or d:sub(9,12) ~= "WAVE" then return nil, "not a RIFF WAV" end
  local pos, fmt, data_off, data_len = 13, nil, nil, nil
  while pos + 8 <= #d do
    local id = d:sub(pos, pos+3)
    local sz = string.unpack("<I4", d, pos+4)
    if id == "fmt " then
      local tag, nch, sr, _, _, bits = string.unpack("<I2I2I4I4I2I2", d, pos+8)
      if tag == 0xFFFE and sz >= 40 then tag = string.unpack("<I2", d, pos+8+24) end
      fmt = { tag = tag, nch = nch, sr = sr, bits = bits }
    elseif id == "data" then
      data_off = pos + 8
      data_len = math.min(sz, #d - data_off + 1)
      if sz == 0xFFFFFFFF or sz == 0 then data_len = #d - data_off + 1 end
    end
    pos = pos + 8 + sz + (sz % 2)
    if data_off and fmt then break end
  end
  if not fmt or not data_off then return nil, "missing fmt/data chunk" end
  local code, bps
  if fmt.tag == 1 then
    if fmt.bits == 16 then code, bps = "i2", 2
    elseif fmt.bits == 24 then code, bps = "i3", 3
    elseif fmt.bits == 32 then code, bps = "i4", 4
    elseif fmt.bits == 8 then code, bps = "B", 1
    else return nil, "PCM " .. fmt.bits .. " bits not supported" end
  elseif fmt.tag == 3 then
    if fmt.bits == 32 then code, bps = "f", 4
    elseif fmt.bits == 64 then code, bps = "d", 8
    else return nil, "float " .. fmt.bits .. " bits not supported" end
  else
    return nil, "WAV format " .. fmt.tag .. " not supported (compressed?)"
  end
  local scale = 1
  if fmt.tag == 1 then scale = (fmt.bits == 8) and 1/128 or 1 / (2^(fmt.bits-1)) end
  local nch = fmt.nch
  local frames = data_len // (bps * nch)
  local keep = math.min(nch, 2)
  local ch = {}
  for c = 1, keep do ch[c] = {} end
  local CH = 1024
  local p = data_off
  local fi = 0
  while fi < frames do
    local n = math.min(CH, frames - fi)
    local vals = table.pack(string.unpack("<" .. string.rep(code, n*nch), d, p))
    p = vals[vals.n]
    local k = 1
    for i = 1, n do
      for c = 1, nch do
        local v = vals[k]; k = k + 1
        if c <= keep then
          if fmt.bits == 8 and fmt.tag == 1 then v = v - 128 end
          ch[c][fi+i] = v * scale
        end
      end
    end
    fi = fi + n
  end
  return { sr = fmt.sr, nch = keep, frames = frames, ch = ch }
end

---------------------------------------------------------------- float WAV writing
local function write_wav_float(path, sr, nch, values)   -- values: interleaved table
  local f = io.open(path, "wb")
  if not f then return false end
  local n = #values
  local datalen = n * 4
  f:write("RIFF", string.pack("<I4", 36 + datalen), "WAVE")
  f:write("fmt ", string.pack("<I4I2I2I4I4I2I2", 16, 3, nch, sr, sr*nch*4, nch*4, 32))
  f:write("data", string.pack("<I4", datalen))
  local CH = 2048
  local i = 1
  while i <= n do
    local m = math.min(CH, n - i + 1)
    f:write(string.pack("<" .. string.rep("f", m), table.unpack(values, i, i + m - 1)))
    i = i + m
  end
  f:close()
  return true
end

---------------------------------------------------------------- audio processing
local function resample(chan, from, to)
  if from == to then return chan end
  local ratio = from / to
  local n = #chan
  local outn = math.floor((n - 1) / ratio) + 1
  local out = {}
  for i = 0, outn - 1 do
    local pos = i * ratio
    local ip = math.floor(pos)
    local t = pos - ip
    local y0 = chan[ip] or chan[ip+1] or 0
    local y1 = chan[ip+1] or 0
    local y2 = chan[ip+2] or y1
    local y3 = chan[ip+3] or y2
    local c1 = 0.5*(y2 - y0)
    local c2 = y0 - 2.5*y1 + 2*y2 - 0.5*y3
    local c3 = 0.5*(y3 - y0) + 1.5*(y1 - y2)
    out[i+1] = ((c3*t + c2)*t + c1)*t + y1
  end
  return out
end

local function attack_peak(w)  -- peak over the first 50 ms
  local n = math.min(w.frames, math.floor(w.sr * 0.05))
  local pk = 0
  for c = 1, w.nch do
    local ch = w.ch[c]
    for i = 1, n do local v = math.abs(ch[i]); if v > pk then pk = v end end
  end
  return pk
end

---------------------------------------------------------------- file name parsing
-- returns prefix, vel (or nil), rr (or nil)
local function parse_name(file)
  local base = file:gsub("%.[Ww][Aa][Vv]$", "")
  local work = "_" .. base .. "_"
  local rr, vel
  -- round robin: RR1, rr02, "RR 3"
  work = work:gsub("([%s_%-%.%(%[])[Rr][Rr][%s_]?(%d+)([%s_%-%.%)%]])", function(a, d, b) rr = tonumber(d); return a .. b end, 1)
  -- velocity: V01, Vel3, VEL_3, velocity 3
  work = work:gsub("([%s_%-%.%(%[])[Vv][Ee]?[Ll]?[Oo]?[Cc]?[Ii]?[Tt]?[Yy]?[%s_]?(%d+)([%s_%-%.%)%]])", function(a, d, b) vel = tonumber(d); return a .. b end, 1)
  work = work:gsub("%(%s*%)", ""):gsub("%[%s*%]", "")
  local prefix = work:gsub("^[%s_%-%.]+", ""):gsub("[%s_%-%.]+$", ""):gsub("[%s_%-%.][%s_%-%.]+", "_")
  if prefix == "" then prefix = base end
  -- letter-free convention: name_VEL_RR  (e.g. metal_snare_025_01)
  if not vel and not rr then
    local p, v, r = base:match("^(.-)[%s_%-%.]+(%d+)[%s_%-%.]+(%d+)$")
    if p and p ~= "" then prefix, vel, rr = p, tonumber(v), tonumber(r) end
  end
  return prefix, vel, rr
end

local function clean_name(s)
  s = s:gsub('[<>:"/\\|%?%*]', "_")
  return s
end

---------------------------------------------------------------- kit building
-- layers = { { files = { path, path, ... } }, ... } in ascending velocity order
-- an item of L.files is either a .wav path or an already decoded sound:
--   { sr=, nch=, frames=, pcm = interleaved float32 LE string }   (TCI import)
local FMT = setmetatable({}, { __index = function(t, n) local v = "<" .. string.rep("f", n); t[n] = v; return v end })

local function pcm_to_channels(w)
  local L, R = {}, (w.nch == 2) and {} or nil
  local i, CH, frame = 1, 4096, 0
  local total = w.frames * w.nch
  while i <= total do
    local m = math.min(CH, total - i + 1)
    local vals = table.pack(string.unpack(FMT[m], w.pcm, (i - 1) * 4 + 1))
    for j = 1, m do
      local idx = i + j - 2
      if w.nch == 2 then
        if idx % 2 == 0 then L[idx // 2 + 1] = vals[j] else R[idx // 2 + 1] = vals[j] end
      else L[idx + 1] = vals[j] end
    end
    i = i + m
  end
  return { L, R }
end

local function resampled_len(n, from, to)
  if from == to then return n end
  return math.floor((n - 1) / (from / to)) + 1
end

local function write_faded_pcm(fh, pcm, frames, nch, sr)
  local nf = math.min(frames, math.floor(sr * 0.003))
  local cut = (frames - nf) * nch * 4
  fh:write(pcm:sub(1, cut))
  if nf > 0 then
    local vals = table.pack(string.unpack(FMT[nf * nch], pcm, cut + 1))
    for fi = 0, nf - 1 do
      local g = (nf - 1 - fi) / nf
      for c = 1, nch do local k = fi * nch + c; vals[k] = vals[k] * g end
    end
    fh:write(string.pack(FMT[nf * nch], table.unpack(vals, 1, nf * nch)))
  end
end

local function build_kit(out_path, layers, log)
  local waves, sr_count = {}, {}
  local nch = 1
  for li, L in ipairs(layers) do
    for ri, p in ipairs(L.files) do
      local w, err
      if type(p) == "table" then w = p else w, err = read_wav(p) end
      if not w then
        log[#log+1] = "  ! " .. basename(tostring(p)) .. " : " .. tostring(err)
      else
        waves[p] = w
        sr_count[w.sr] = (sr_count[w.sr] or 0) + 1
        if w.nch == 2 then nch = 2 end
      end
    end
  end
  local sr, best = 44100, -1
  for k, v in pairs(sr_count) do if v > best then sr, best = k, v end end

  -- valid layers, limits
  local good, good_hi = {}, nil
  for _, L in ipairs(layers) do
    local f = {}
    for _, p in ipairs(L.files) do if waves[p] and waves[p].frames > 1 then f[#f+1] = p end end
    if #f > 0 then
      if #f > MAX_RR then log[#log+1] = ("  ! %d RR > %d, extra ones ignored"):format(#f, MAX_RR) end
      while #f > MAX_RR do table.remove(f) end
      good[#good+1] = f
      good_hi = good_hi or {}
      good_hi[#good] = L.vhi
    end
  end
  if #good == 0 then return false, "no readable file" end
  if #good > MAX_LAYERS then
    log[#log+1] = ("  ! %d velocity layers > %d, reduced"):format(#good, MAX_LAYERS)
    while #good > MAX_LAYERS do table.remove(good, 1); if good_hi then table.remove(good_hi, 1) end end
  end
  -- velocity ranges: MIDI values from the names / the TCI when available, otherwise spread over 1-127
  local NL = #good
  local los, his = {}, {}
  local use_hi = good_hi ~= nil
  if use_hi then for i = 1, NL do if not good_hi[i] then use_hi = false end end end
  for i = 1, NL do
    if use_hi then
      his[i] = (i == NL) and 127 or math.max(1, math.min(127, math.floor(good_hi[i])))
      los[i] = (i == 1) and 1 or math.min(his[i-1] + 1, 127)
      if his[i] < los[i] then his[i] = los[i] end
    else
      los[i] = math.floor((i-1) * 127 / NL) + 1
      his[i] = math.floor(i * 127 / NL)
    end
  end

  -- header (lengths are known without converting the audio)
  local hdr_len = 5
  for _, f in ipairs(good) do hdr_len = hdr_len + 3 + 2*#f end
  if hdr_len % nch ~= 0 then hdr_len = hdr_len + (nch - hdr_len % nch) end
  local frame = hdr_len // nch
  local hdr = { MAGIC, 1, nch, NL, hdr_len }
  local order = {}
  for li, f in ipairs(good) do
    hdr[#hdr+1] = los[li]; hdr[#hdr+1] = his[li]; hdr[#hdr+1] = #f
    for _, p in ipairs(f) do
      local w = waves[p]
      local n = resampled_len(w.frames, w.sr, sr)
      hdr[#hdr+1] = frame; hdr[#hdr+1] = n
      order[#order+1] = p
      frame = frame + n
    end
  end
  while #hdr < hdr_len do hdr[#hdr+1] = 0 end
  if frame >= 16777216 then return false, "kit too long (offsets > 16.7M frames)" end
  local total = frame * nch

  -- streamed writing: the whole kit is never held in memory
  local fh = io.open(out_path, "wb")
  if not fh then return false, "cannot write: " .. out_path end
  local datalen = total * 4
  fh:write("RIFF", string.pack("<I4", 36 + datalen), "WAVE")
  fh:write("fmt ", string.pack("<I4I2I2I4I4I2I2", 16, 3, nch, sr, sr*nch*4, nch*4, 32))
  fh:write("data", string.pack("<I4", datalen))
  fh:write(string.pack(FMT[#hdr], table.unpack(hdr)))
  for _, p in ipairs(order) do
    local w = waves[p]
    if w.pcm and w.sr == sr and w.nch == nch then
      write_faded_pcm(fh, w.pcm, w.frames, nch, sr)
    else
      local ch = w.ch or pcm_to_channels(w)
      local L = resample(ch[1], w.sr, sr)
      local R = (w.nch == 2) and resample(ch[2], w.sr, sr) or L
      local n = #L
      local nf = math.min(n, math.floor(sr * 0.003))
      local buf, k = {}, 0
      for i = 1, n do
        local g = (i > n - nf) and (n - i) / nf or 1
        if nch == 2 then buf[k+1] = L[i] * g; buf[k+2] = R[i] * g; k = k + 2
        else k = k + 1; buf[k] = L[i] * g end
        if k >= 4096 or i == n then fh:write(string.pack(FMT[k], table.unpack(buf, 1, k))); k = 0 end
      end
    end
  end
  fh:close()
  if total > SLOT_VALUES then
    log[#log+1] = ("  ! %.0f s of audio: needs a recent REAPER (128M JSFX memory) to load entirely"):format(frame/sr)
  end
  local nrr = 0
  for _, f in ipairs(good) do if #f > nrr then nrr = #f end end
  local rng = {}
  for i = 1, NL do rng[#rng+1] = los[i] .. "-" .. his[i] end
  return true, ("%d velocity layer(s) x %d RR, %s, %d Hz, %.2f s  [vel %s]"):format(NL, nrr, nch == 2 and "stereo" or "mono", sr, frame/sr, table.concat(rng, " "))
end

---------------------------------------------------------------- TCI import (Slate Trigger 2)
-- Format (verified bit-exact on test files and a Trigger 2 library):
--   64 bytes "TRIGGER COMPRESSED INSTRUMENT", then records [id u32][size u32][data]
--   0x14 = sample rate, 0x05 = one sound:
--       [channels u8][bit count u32][value count u32] then blocks [k u8][201 x k bits]
--       each value = sign + magnitude on a 24-bit scale (MSB first), interleaved channels
--   0x0b ... 0x12 = one velocity layer: 0x0c lowest velocity, 0x0f sound index (round robins)
local function tci_read(path)
  local f = io.open(path, "rb")
  if not f then return nil, "cannot open file" end
  local d = f:read("a"); f:close()
  if #d < 72 or d:sub(1, 8) ~= "TRIGGER " then return nil, "not a TCI file" end
  local t = { sr = 44100, waves = {}, layers = {}, data = d }
  local pos, cur = 65, nil
  while pos + 7 <= #d do
    local id, len = string.unpack("<I4I4", d, pos)
    pos = pos + 8
    if len > #d - pos + 1 then return nil, "unexpected TCI structure (truncated record)" end
    if id == 0x14 and len == 4 then t.sr = string.unpack("<I4", d, pos)
    elseif id == 0x05 then t.waves[#t.waves+1] = { start = pos, len = len }
    elseif id == 0x0b then cur = { lo = 0, idx = {} }; t.layers[#t.layers+1] = cur
    elseif id == 0x0c and cur and len == 4 then cur.lo = string.unpack("<I4", d, pos)
    elseif id == 0x0f and cur and len == 4 then cur.idx[#cur.idx+1] = string.unpack("<I4", d, pos)
    elseif id == 0x12 then cur = nil end
    pos = pos + len
  end
  if #t.waves == 0 then return nil, "no sound found (different TCI format?)" end
  return t
end

local function tci_decode_wave(t, wi)
  local d, rec = t.data, t.waves[wi]
  local byte = string.byte
  local start = rec.start
  local nch = byte(d, start)
  local comp, count = string.unpack("<I4I4", d, start + 1)
  if nch < 1 or nch > 2 or count < 2 then return nil, "invalid sound header" end
  local bp, acc, nb, used = start + 9, 0, 0, 0
  local need, n, ok = count - 1, 0, true
  local parts, buf = {}, {}
  local scale = 1 / 8388608
  while n < need do
    -- block width
    while nb < 8 do acc = (acc << 8) | (byte(d, bp) or 0); bp = bp + 1; nb = nb + 8 end
    nb = nb - 8
    local k = (acc >> nb) & 0xFF
    acc = acc & ((1 << nb) - 1)
    used = used + 8
    local take = math.min(201, need - n)
    if k < 1 or k > 32 or used + take * k > comp then ok = false; break end
    local half = 1 << (k - 1)
    local mmask = half - 1
    for i = 1, take do
      while nb < k do acc = (acc << 8) | (byte(d, bp) or 0); bp = bp + 1; nb = nb + 8 end
      nb = nb - k
      local v = acc >> nb
      acc = acc & ((1 << nb) - 1)
      local m = v & mmask
      buf[i] = ((v & half) ~= 0 and -m or m) * scale
    end
    used = used + take * k
    parts[#parts+1] = string.pack(FMT[take], table.unpack(buf, 1, take))
    n = n + take
  end
  -- the last value is not stored; on error the rest is zero-filled
  local missing = count - n
  while missing > 0 do
    local m = math.min(missing, 4096)
    parts[#parts+1] = string.rep("\0\0\0\0", m)
    missing = missing - m
  end
  return { sr = t.sr, nch = nch, frames = count // nch, pcm = table.concat(parts) }, ok and n == need
end

local function write_wav_pcm(path, sr, nch, pcm)
  local fh = io.open(path, "wb")
  if not fh then return false end
  fh:write("RIFF", string.pack("<I4", 36 + #pcm), "WAVE")
  fh:write("fmt ", string.pack("<I4I2I2I4I4I2I2", 16, 3, nch, sr, sr*nch*4, nch*4, 32))
  fh:write("data", string.pack("<I4", #pcm), pcm)
  fh:close()
  return true
end

-- one .tci -> one .rsk.wav kit (and optionally the WAV files)
local function import_tci(path, out_kit, wav_dir, log)
  local t, err = tci_read(path)
  if not t then return false, err end
  local layers_sorted = {}
  for _, L in ipairs(t.layers) do if #L.idx > 0 then layers_sorted[#layers_sorted+1] = L end end
  if #layers_sorted == 0 then   -- no layer table: one sound = one velocity
    for i = 1, #t.waves do layers_sorted[#layers_sorted+1] = { lo = math.floor((i-1) * 128 / #t.waves), idx = { i - 1 } } end
  end
  table.sort(layers_sorted, function(a, b) return a.lo < b.lo end)
  local decoded, bad = {}, 0
  local kl = {}
  for li, L in ipairs(layers_sorted) do
    local files = {}
    for ri, wi in ipairs(L.idx) do
      if not decoded[wi] and t.waves[wi + 1] then
        local w, complete = tci_decode_wave(t, wi + 1)
        if w then
          decoded[wi] = w
          if not complete then bad = bad + 1 end
        end
      end
      if decoded[wi] then files[#files+1] = decoded[wi] end
      if wav_dir and decoded[wi] then
        local w = decoded[wi]
        write_wav_pcm(join(wav_dir, ("%s_V%02d_RR%02d.wav"):format((basename(out_kit):gsub("%.rsk%.wav$", "")), li, ri)), w.sr, w.nch, w.pcm)
      end
    end
    local nxt = layers_sorted[li + 1]
    kl[#kl+1] = { files = files, vhi = nxt and (nxt.lo - 1) or 127 }
  end
  t.data = nil
  if bad > 0 then log[#log+1] = ("  ! %d sound(s) partially unreadable, completed with silence"):format(bad) end
  return build_kit(out_kit, kl, log)
end

---------------------------------------------------------------- kit unpacking
local function unpack_kit(path, outdir, log)
  local w, err = read_wav(path)
  if not w then return false, err end
  local L, R = w.ch[1], w.ch[2]
  -- rebuild the interleaved value stream of the first frames
  local function val(i)  -- i = value index (0-based)
    local fr = i // w.nch
    local c = i % w.nch
    return (c == 0 and L or R)[fr + 1]
  end
  if not (math.abs(val(0) - MAGIC) < 1e-3 and val(1) == 1) then return false, "not a .rsk.wav kit" end
  local NL = math.floor(val(3) + 0.5)
  local idx = 5
  local base = basename(path):gsub("%.rsk%.wav$", ""):gsub("%.wav$", "")
  local count = 0
  for li = 1, NL do
    local nrr = math.floor(val(idx+2) + 0.5)
    idx = idx + 3
    for ri = 1, nrr do
      local off, len = math.floor(val(idx) + 0.5), math.floor(val(idx+1) + 0.5)
      idx = idx + 2
      local v = {}
      for i = 1, len do
        if w.nch == 2 then v[#v+1] = L[off+i]; v[#v+1] = R[off+i] else v[#v+1] = L[off+i] end
      end
      local name = ("%s_V%02d_RR%d.wav"):format(base, li, ri)
      write_wav_float(join(outdir, name), w.sr, w.nch, v)
      count = count + 1
    end
  end
  return true, ("%d file(s) in %s"):format(count, outdir)
end

---------------------------------------------------------------- folder scanning
local function list_wavs(dir)
  local t, i = {}, 0
  while true do
    local f = reaper.EnumerateFiles(dir, i)
    if not f then break end
    if f:lower():match("%.wav$") and not f:lower():match("%.rsk%.wav$") then t[#t+1] = f end
    i = i + 1
  end
  table.sort(t, natural_lt)
  return t
end

local function list_dirs_recursive(dir, acc)
  acc = acc or { dir }
  local i = 0
  while true do
    local s = reaper.EnumerateSubdirectories(dir, i)
    if not s then break end
    local p = join(dir, s)
    acc[#acc+1] = p
    list_dirs_recursive(p, acc)
    i = i + 1
  end
  return acc
end

-- groups the files of one folder into kits
-- untagged_mode: 1 velocities by level, 2 velocities by name, 3 round robins, 4 one kit per file
local function plan_folder(dir, untagged_mode, folder_as_name)
  local files = list_wavs(dir)
  local groups, order = {}, {}
  for _, f in ipairs(files) do
    local prefix, vel, rr = parse_name(f)
    local key = (vel or rr) and prefix or "\0untagged"
    if not groups[key] then groups[key] = { prefix = prefix, items = {} }; order[#order+1] = key end
    local g = groups[key]
    g.items[#g.items+1] = { file = f, path = join(dir, f), vel = vel, rr = rr }
  end
  local kits = {}
  for _, key in ipairs(order) do
    local g = groups[key]
    if key == "\0untagged" then
      if untagged_mode == 4 then
        for _, it in ipairs(g.items) do
          kits[#kits+1] = { name = it.file:gsub("%.[Ww][Aa][Vv]$", ""), layers = { { files = { it.path } } } }
        end
      else
        local name = basename(dir)
        if untagged_mode == 3 then
          local f = {}
          for _, it in ipairs(g.items) do f[#f+1] = it.path end
          kits[#kits+1] = { name = name, layers = { { files = f } } }
        else
          local items = g.items
          if untagged_mode == 1 then
            for _, it in ipairs(items) do
              local w = read_wav(it.path)
              it.peak = w and attack_peak(w) or 0
            end
            table.sort(items, function(a, b) return a.peak < b.peak end)
          end
          local layers = {}
          for _, it in ipairs(items) do layers[#layers+1] = { files = { it.path } } end
          kits[#kits+1] = { name = name, layers = layers }
        end
      end
    else
      -- tags: velocities sorted by number, RR by number
      local byvel, vkeys = {}, {}
      for _, it in ipairs(g.items) do
        local v = it.vel or 1
        if not byvel[v] then byvel[v] = {}; vkeys[#vkeys+1] = v end
        byvel[v][#byvel[v]+1] = it
      end
      table.sort(vkeys)
      local layers = {}
      for _, v in ipairs(vkeys) do
        local list = byvel[v]
        table.sort(list, function(a, b)
          if (a.rr or 0) ~= (b.rr or 0) then return (a.rr or 0) < (b.rr or 0) end
          return natural_lt(a.file, b.file)
        end)
        local f = {}
        for _, it in ipairs(list) do f[#f+1] = it.path end
        layers[#layers+1] = { files = f, v = v }
      end
      -- velocity numbers = real MIDI velocities (025, 050, 127...) or plain indexes (1, 2, 3 / 0, 1, 2)?
      local consecutive = true
      for i, v in ipairs(vkeys) do if v ~= vkeys[1] + i - 1 then consecutive = false end end
      local midi = vkeys[#vkeys] <= 127 and not (consecutive and vkeys[1] <= 1)
      if midi then for _, L in ipairs(layers) do L.vhi = L.v end end
      local name = g.prefix
      if folder_as_name and #order == 1 then name = basename(dir) end
      kits[#kits+1] = { name = name, layers = layers }
    end
  end
  return kits, #files
end

---------------------------------------------------------------- library organisation
-- Every kit goes to  <Element>/<Instrument>/<name>.rsk.wav  (library names are ignored).
-- The element comes from the deepest folder or file name that names a drum
-- ("Close Room - Guru 22x16 Kick", "SD_SONOR...", "T1_TAMA...", "Toms", "BB Snare"...).

local function tokens(s)
  local t = {}
  for w in s:lower():gmatch("[%a%d]+") do t[#t+1] = w end
  return t
end

local function element_of(name)
  local l = name:lower()
  local tk = tokens(name)
  local has = {}
  for _, w in ipairs(tk) do has[w] = true end
  if l:find("kick") or has.bd or has.bassdrum or l:find("bass drum") then return "Kick" end
  if l:find("snare") or has.sd or has.snr or has.sn then return "Snare" end
  if l:find("hihat") or l:find("hi%-hat") or l:find("hi hat") or has.hh or has.hat or has.hats then return "HiHat" end
  if l:find("cymbal") or l:find("crash") or l:find("ride") or l:find("china") or l:find("splash") or has.cym then return "Cymbal" end
  for _, w in ipairs(tk) do
    if w:match("^toms?%d*$") or w:match("^t%d$") or w:find("^floortom") or w:find("^racktom") then return "Tom" end
  end
  if l:find("perc") or l:find("clap") or l:find("shaker") or l:find("tamb") or l:find("cowbell") or l:find("snap") then return "Percussion" end
  return nil
end

local GENERIC = {
  individuals = true, individual = true, mics = true, mic = true, raw = true, processed = true,
  lo = true, low = true, mid = true, middle = true, hi = true, high = true,
  soft = true, medium = true, hard = true, samples = true, multis = true, wav = true, tci = true,
}

local function strip_number(name)  -- "01 LO" -> "LO", "1 SumoSub" -> "SumoSub"
  local r = name:gsub("^%d+[%s%._%-]+", "")
  if r == "" then return name end
  return r
end

local function is_generic(name)
  return GENERIC[strip_number(name):lower():gsub("[%s_%-]+", "")] == true
end

local function is_element_only(name)  -- "Kicks", "02 SNARE", "Toms", "05 FLOOR TOM" (but not "Snare18")
  local n = strip_number(name):lower()
  if n:find("%d") then return false end
  n = n:gsub("[%s_%-]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  local words = { kick = 1, kicks = 1, snare = 1, snares = 1, tom = 1, toms = 1, floor = 1, rack = 1,
                  hihat = 1, hihats = 1, hat = 1, hats = 1, cymbal = 1, cymbals = 1, perc = 1, percussion = 1,
                  bd = 1, sd = 1, drum = 1, drums = 1 }
  if n == "" then return false end
  for w in n:gmatch("%S+") do if not words[w] then return false end end
  return true
end

-- items: { { dirs = {"Trigger2 Kicks","ACKick"}, base = "ACKick NRG", root = "<picked folder name>" }, ... }
-- adds it.element, it.inst, it.name (unique per element/instrument)
local function organise(items)
  for _, it in ipairs(items) do
    local parts = {}
    for _, d in ipairs(it.dirs) do parts[#parts+1] = d end
    parts[#parts+1] = it.base
    local el
    for i = #parts, 1, -1 do el = element_of(parts[i]); if el then break end end
    if not el and it.root then el = element_of(it.root) end
    it.element = el or "Other"
    -- instrument: nearest folder that is neither generic nor just a drum word
    it.below, it.above = {}, {}
    local inst_i
    for i = #it.dirs, 1, -1 do
      local d = it.dirs[i]
      if not is_generic(d) and not is_element_only(d) then inst_i = i; break end
    end
    it.src = table.concat(it.dirs, "/", 1, inst_i or 0)
    if inst_i then
      it.inst = strip_number(it.dirs[inst_i])
      for i = inst_i + 1, #it.dirs do it.below[#it.below+1] = strip_number(it.dirs[i]) end
      for i = inst_i - 1, 1, -1 do it.above[#it.above+1] = strip_number(it.dirs[i]) end
    else
      local r = it.root and strip_number(it.root) or ""
      it.inst = (r ~= "" and not is_generic(r) and not is_element_only(r)) and r or it.base
      for i = 1, #it.dirs do it.below[#it.below+1] = strip_number(it.dirs[i]) end
    end
    it.name = it.base
  end
  local function key(it) return (it.element .. "/" .. it.inst .. "/" .. it.name):lower() end
  local function collisions()
    local g, bad = {}, {}
    for _, it in ipairs(items) do local k = key(it); g[k] = g[k] or {}; table.insert(g[k], it) end
    for _, list in pairs(g) do if #list > 1 then for _, it in ipairs(list) do bad[#bad+1] = it end end end
    return bad
  end
  -- 1) same file name inside one instrument (e.g. LO / MID / HI sub-folders):
  --    every sound of that instrument gets its sub-folders in its name
  local fix = {}
  for _, it in ipairs(collisions()) do if #it.below > 0 then fix[it.src] = true end end
  for _, it in ipairs(items) do
    if fix[it.src] and #it.below > 0 then it.name = table.concat(it.below, " ") .. " " .. it.base end
  end
  -- 2) still colliding (RAW vs PROCESSED, two libraries using the same instrument name):
  --    the whole instrument is tagged with its parent folder(s)
  for level = 1, 3 do
    local tag = {}
    for _, it in ipairs(collisions()) do if it.above[level] then tag[it.src] = true end end
    if not next(tag) then break end
    for _, it in ipairs(items) do
      if tag[it.src] and it.above[level] then it.inst = it.inst .. " (" .. it.above[level] .. ")" end
    end
  end
  -- 3) last resort: numbering
  local seen = {}
  for _, it in ipairs(items) do
    local k = key(it)
    if seen[k] then seen[k] = seen[k] + 1; it.name = it.name .. " " .. seen[k] else seen[k] = 1 end
  end
  return items
end

local function split_rel(rel)
  local t = {}
  for p in rel:gmatch("[^/\\]+") do t[#t+1] = p end
  return t
end

---------------------------------------------------------------- REAPER user interface
local TITLE = "RS Trig Kit Builder"
local function msg(t) reaper.ShowMessageBox(t, TITLE, 0) end

local function data_dir() return join(reaper.GetResourcePath(), "Data") end
local function lib_dir()
  local d = join(data_dir(), "RSampler")
  reaper.RecursiveCreateDirectory(d, 0)
  return d
end

-- Library index: a JSFX cannot list a folder, so the sampler reads this file.
local AUDIO_EXT = { wav = true, flac = true, ogg = true, aif = true, aiff = true, mp3 = true }

local function write_index(lib)
  local list = {}
  local function scan(dir, rel)
    reaper.EnumerateFiles(dir, -1)            -- flush REAPER's directory cache: we want the real disk state
    local i = 0
    while true do
      local f = reaper.EnumerateFiles(dir, i)
      if not f then break end
      local ext = (f:match("%.([^.]+)$") or ""):lower()
      if AUDIO_EXT[ext] then list[#list+1] = rel .. f end
      i = i + 1
    end
    reaper.EnumerateSubdirectories(dir, -1)
    i = 0
    while true do
      local sd = reaper.EnumerateSubdirectories(dir, i)
      if not sd then break end
      scan(join(dir, sd), rel .. sd .. "/")
      i = i + 1
    end
  end
  scan(lib, "")
  table.sort(list, natural_lt)
  local fh = io.open(join(lib, "_library.txt"), "wb")
  if not fh then return nil end
  fh:write("; RS Trig Sampler - generated automatically, do not edit\n")
  for _, p in ipairs(list) do fh:write(p, "\n") end
  fh:close()
  return #list
end

local function file_exists(p) local f = io.open(p, "rb"); if f then f:close(); return true end return false end

-- first run: copy the demo kit shipped with the script into the library
local function install_demo()
  local here = (debug.getinfo(1, "S").source:match("^@?(.*[/\\])") or "")
  local src = here .. "RS Trig Demo Kick.rsk.wav"
  local dst_dir = join(lib_dir(), "Kick")
  local dst = join(dst_dir, "Demo Kick.rsk.wav")
  if file_exists(dst) or not file_exists(src) then return false end
  reaper.RecursiveCreateDirectory(dst_dir, 0)
  local i = io.open(src, "rb"); local d = i:read("a"); i:close()
  local o = io.open(dst, "wb"); if not o then return false end
  o:write(d); o:close()
  return true
end

local function ensure_library()
  local lib = lib_dir()
  local fresh = not file_exists(join(lib, "_library.txt"))
  if fresh then install_demo(); write_index(lib) end
  return lib
end

local function open_folder(d)
  if reaper.CF_ShellExecute then reaper.CF_ShellExecute(d)
  elseif SEP == "\\" then os.execute('explorer "' .. d .. '"')
  else os.execute('open "' .. d .. '" 2>/dev/null || xdg-open "' .. d .. '"') end
end

local function out_path(it)
  local dir = join(join(lib_dir(), clean_name(it.element)), clean_name(it.inst))
  reaper.RecursiveCreateDirectory(dir, 0)
  return join(dir, clean_name(it.name) .. ".rsk.wav"), dir
end

local function action_build()
  local ok, pick = reaper.GetUserFileNameForRead("", "Pick ONE .wav in the source folder (the whole folder is processed)", "*.wav")
  if not ok then return end
  local root = dirname(pick)
  local rec = reaper.ShowMessageBox("Folder: " .. root .. "\n\nAlso process all sub-folders?", TITLE, 3)
  if rec == 2 then return end
  local dirs = (rec == 6) and list_dirs_recursive(root) or { root }

  local okI, ans = reaper.GetUserInputs(TITLE .. " - files WITHOUT V/RR tags", 1,
    "1=layers by level 2=by name 3=RR 4=1 kit/file,extrawidth=120", "1")
  if not okI then return end
  local mode = math.tointeger(tonumber(ans)) or 1
  if mode < 1 or mode > 4 then mode = 1 end

  local items, scanned = {}, 0
  for _, d in ipairs(dirs) do
    local kits, n = plan_folder(d, mode, false)
    scanned = scanned + n
    local rel = d:sub(#root + 2)
    for _, k in ipairs(kits) do
      items[#items+1] = { dirs = split_rel(rel), base = k.name, root = basename(root), layers = k.layers }
    end
  end
  organise(items)
  local log, made = {}, 0
  for _, it in ipairs(items) do
    local out = out_path(it)
    local ok2, info = build_kit(out, it.layers, log)
    log[#log+1] = (ok2 and "OK   " or "ERR  ") .. it.element .. "/" .. it.inst .. "/" .. it.name .. "  -  " .. info
    if ok2 then made = made + 1 end
  end
  write_index(lib_dir())
  reaper.ShowConsoleMsg(("\n=== %s ===\n%d wav scanned, %d kit(s) built in\n%s\n\n%s\n")
    :format(TITLE, scanned, made, lib_dir(), table.concat(log, "\n")))
  msg(("%d kit(s) built in\n%s\n\nLibrary updated: click RESCAN (or LOAD) in the sampler."):format(made, lib_dir()))
end

local function action_unpack()
  local ok, pick = reaper.GetUserFileNameForRead(lib_dir(), "Pick a .rsk.wav kit", "*.wav")
  if not ok then return end
  local base = basename(pick):gsub("%.rsk%.wav$", ""):gsub("%.wav$", "")
  local out = join(join(data_dir(), "RSampler_Unpacked"), base)
  reaper.RecursiveCreateDirectory(out, 0)
  local ok2, info = unpack_kit(pick, out, {})
  msg((ok2 and "Unpacked: " or "Error: ") .. info)
end

local function list_tci(root, recursive)
  local out = {}
  local function scan(dir, rel)
    reaper.EnumerateFiles(dir, -1)
    local i = 0
    while true do
      local f = reaper.EnumerateFiles(dir, i)
      if not f then break end
      if f:lower():match("%.tci$") then out[#out+1] = { path = join(dir, f), rel = rel, base = (f:gsub("%.[Tt][Cc][Ii]$", "")) } end
      i = i + 1
    end
    if recursive then
      reaper.EnumerateSubdirectories(dir, -1)
      i = 0
      while true do
        local sd = reaper.EnumerateSubdirectories(dir, i)
        if not sd then break end
        scan(join(dir, sd), rel == "" and sd or (rel .. "/" .. sd))
        i = i + 1
      end
    end
  end
  scan(root, "")
  table.sort(out, function(a, b) return natural_lt(a.rel .. "/" .. a.base, b.rel .. "/" .. b.base) end)
  return out
end

local function action_import_tci()
  local ok, pick = reaper.GetUserFileNameForRead("", "Pick a .tci file (Slate Trigger 2)", "*.tci")
  if not ok then return end
  local root = dirname(pick)
  local scope = reaper.ShowMessageBox(
    "Import ALL .tci files of this folder and its sub-folders?\n\n" .. root ..
    "\n\nYes = whole folder   /   No = only " .. basename(pick) ..
    "\n\nTip: pick a file at the top of your Trigger library to import everything.", TITLE .. " - TCI import", 3)
  if scope == 2 then return end
  local wavs = reaper.ShowMessageBox("Also export every sound as a WAV file?\n(into Data/RSampler_TCI_WAV, handy to edit them)",
    TITLE .. " - TCI import", 4) == 6
  local items
  if scope == 6 then items = list_tci(root, true)
  else items = { { path = pick, rel = "", base = (basename(pick):gsub("%.[Tt][Cc][Ii]$", "")) } } end
  for _, it in ipairs(items) do it.dirs = split_rel(it.rel); it.root = basename(root) end
  organise(items)
  local log, made = {}, 0
  local t0 = reaper.time_precise()
  reaper.ShowConsoleMsg(("\n=== TCI import: %d file(s) ===\n"):format(#items))
  for _, it in ipairs(items) do
    local out = out_path(it)
    local wdir = nil
    if wavs then
      wdir = join(join(join(join(data_dir(), "RSampler_TCI_WAV"), clean_name(it.element)), clean_name(it.inst)), clean_name(it.name))
      reaper.RecursiveCreateDirectory(wdir, 0)
    end
    local sub = {}
    local ok2, info = import_tci(it.path, out, wdir, sub)
    local line = (ok2 and "OK   " or "ERR  ") .. it.element .. "/" .. it.inst .. "/" .. it.name .. "  -  " .. tostring(info)
    reaper.ShowConsoleMsg(line .. "\n")
    for _, l in ipairs(sub) do reaper.ShowConsoleMsg(l .. "\n") end
    if ok2 then made = made + 1 end
  end
  write_index(lib_dir())
  reaper.ShowConsoleMsg(("%d kit(s) in %.1f s\n"):format(made, reaper.time_precise() - t0))
  msg(("%d / %d TCI file(s) imported into\n%s\n(organised as Element / Instrument)\n\nDetails in the console. Library updated: click RESCAN (or LOAD) in the sampler.")
    :format(made, #items, lib_dir()))
end

local function action_rescan(silent)
  local lib = ensure_library()
  local n = write_index(lib)
  if not n then msg("Cannot write the index in\n" .. lib); return end
  if not silent then msg(("%d file(s) indexed in Data/RSampler.\nClick RESCAN (or LOAD) in the sampler."):format(n)) end
end

local function main()
  ensure_library()
  gfx.init(TITLE, 220, 40)
  gfx.x, gfx.y = 10, 10
  local m = gfx.showmenu("Import .tci files (Slate Trigger 2)...|Build kits from a WAV folder...|Unpack a .rsk.wav kit to WAV files...||Rescan library|Open library folder (Data/RSampler)")
  gfx.quit()
  if m == 1 then action_import_tci()
  elseif m == 2 then action_build()
  elseif m == 3 then action_unpack()
  elseif m == 4 then action_rescan(false)
  elseif m == 5 then open_folder(lib_dir()) end
end

if reaper and RS_KB_MODE == "rescan" then
  RS_KB_MODE = nil
  action_rescan(false)
elseif reaper then
  main()
else
  -- test mode outside REAPER
  return { read_wav = read_wav, write_wav_float = write_wav_float, build_kit = build_kit,
           unpack_kit = unpack_kit, parse_name = parse_name, plan_folder = plan_folder,
           resample = resample, write_index = write_index, organise = organise, element_of = element_of,
           tci_read = tci_read, tci_decode_wave = tci_decode_wave, import_tci = import_tci }
end
