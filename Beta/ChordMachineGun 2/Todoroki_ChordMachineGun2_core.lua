-- @noindex
--[[
  ChordMachineGun — shared engine
  Loaded by the main window and by every action script.

  Features:
    • Voice leading (on/off): the first chord is the reference, the next ones
      are placed as close as possible, without parallel fifths/octaves or crossing,
      with sensible doubling.
    • Custom position: order of functions from lowest to highest,
      e.g. "1 5 3 13 9" (root, fifth, third, 13th, 9th). Works with voice leading.
    • Voices → MIDI channels: voice n (low to high) goes to channel n.
      Bass = lowest note, or root (separate bass voice).
    • Doublings per voice: octave, fifth, third… (chromatic or diatonic).
    • Voice tracks (MIDI routing per channel) or item explode.
]]

------------------------------------------------------------------------------
-- Chords (same order as the original, so saved indexes stay valid)
------------------------------------------------------------------------------

chords = {
  { name = 'major',             code = 'major', display = '',     pattern = '10001001' },
  { name = 'minor',             code = 'minor', display = 'm',    pattern = '10010001' },
  { name = 'power chord',       code = 'power', display = '5',    pattern = '10000001' },
  { name = 'suspended second',  code = 'sus2',  display = 'sus2', pattern = '10100001' },
  { name = 'suspended fourth',  code = 'sus4',  display = 'sus4', pattern = '10000101' },
  { name = 'diminished',        code = 'dim',   display = 'dim',  pattern = '1001001' },
  { name = 'augmented',         code = 'aug',   display = 'aug',  pattern = '100010001' },
  { name = 'major sixth',       code = 'maj6',  display = '6',    pattern = '1000100101' },
  { name = 'minor sixth',       code = 'min6',  display = 'm6',   pattern = '1001000101' },
  { name = 'dominant seventh',  code = '7',     display = '7',    pattern = '10001001001' },
  { name = 'major seventh',     code = 'maj7',  display = 'maj7', pattern = '100010010001' },
  { name = 'minor seventh',     code = 'min7',  display = 'm7',   pattern = '10010001001' },
  { name = 'flat fifth',        code = 'flat5', display = '5-',   pattern = '10000010' },
}

scales = {
  { name = "Major",          pattern = "101011010101" },
  { name = "Natural Minor",  pattern = "101101011010" },
  { name = "Harmonic Minor", pattern = "101101011001" },
  { name = "Melodic Minor",  pattern = "101101010101" },
  { name = "Pentatonic",     pattern = "101010010100" },
  { name = "Ionian",         pattern = "101011010101" },
  { name = "Aeolian",        pattern = "101101011010" },
  { name = "Dorian",         pattern = "101101010110" },
  { name = "Mixolydian",     pattern = "101011010110" },
  { name = "Phrygian",       pattern = "110101011010" },
  { name = "Lydian",         pattern = "101010110101" },
  { name = "Locrian",        pattern = "110101101010" },
  -- v2: modes used a lot in film / game scoring
  { name = "Lydian Dominant",   pattern = "101010110110" },
  { name = "Mixolydian b6",     pattern = "101011011010" },
  { name = "Phrygian Dominant", pattern = "110011011010" },
  { name = "Harmonic Major",    pattern = "101011011001" },
  { name = "Double Harmonic",   pattern = "110011011001" },
  { name = "Hungarian Minor",   pattern = "101100111001" },
  { name = "Dorian #4",         pattern = "101100110110" },
  { name = "Lydian Augmented",  pattern = "101010101101" },
  { name = "Whole Tone",        pattern = "101010101010" },
}

notes     = { 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B' }
flatNotes = { 'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B' }

------------------------------------------------------------------------------
-- Utilitaires
------------------------------------------------------------------------------

function print(arg) reaper.ShowConsoleMsg(tostring(arg) .. "\n") end

function startUndoBlock() reaper.Undo_BeginBlock() end

function endUndoBlock(actionDescription)
  reaper.Undo_OnStateChange(actionDescription)
  reaper.Undo_EndBlock(actionDescription, -1)
end

function emptyFunctionToPreventAutomaticCreationOfUndoPoint() end

local function copyTable(t)
  local o = {}
  for i, v in ipairs(t) do o[i] = v end
  return o
end

------------------------------------------------------------------------------
-- Settings (ProjExtState)
------------------------------------------------------------------------------

local activeProjectIndex = 0
local sectionName = "com.ChordMachineGun2"

defaultScaleTonicNoteValue = 1
defaultScaleTypeValue = 1
defaultOctave = 3

local function setValue(key, value)
  reaper.SetProjExtState(activeProjectIndex, sectionName, key, tostring(value))
end

local function getValue(key, defaultValue)
  local valueExists, value = reaper.GetProjExtState(activeProjectIndex, sectionName, key)
  if valueExists == 0 then
    setValue(key, defaultValue)
    return tostring(defaultValue)
  end
  return value
end

local function getTableValue(key, defaultValue)
  local valueExists, value = reaper.GetProjExtState(activeProjectIndex, sectionName, key)
  if valueExists == 0 then
    reaper.SetProjExtState(activeProjectIndex, sectionName, key, table.concat(defaultValue, ","))
    return copyTable(defaultValue)
  end
  local output = {}
  for match in value:gmatch("([^,%s]+)") do output[#output + 1] = match end
  return output
end

local function setTableValue(key, value)
  reaper.SetProjExtState(activeProjectIndex, sectionName, key, table.concat(value, ","))
end

local function getBool(key, default) return getValue(key, tostring(default)) == "true" end
local function setBool(key, v) setValue(key, tostring(v and true or false)) end

local defaultSevenOnes, defaultSevenZeros = {}, {}
for i = 1, 7 do defaultSevenOnes[i] = 1; defaultSevenZeros[i] = 0 end

function getScaleTonicNote() return tonumber(getValue("scaleTonicNote", defaultScaleTonicNoteValue)) or 1 end
function setScaleTonicNote(a) setValue("scaleTonicNote", a) end
function getScaleType() return tonumber(getValue("scaleType", defaultScaleTypeValue)) or 1 end
function setScaleType(a) setValue("scaleType", a) end
function getScaleNotesText() return getValue("scaleNotesText", "") end
function setScaleNotesText(a) setValue("scaleNotesText", a) end
function getChordText() return getValue("chordText", "") end
function setChordText(a) setValue("chordText", a) end
function getChordNotesText() return getValue("chordNotesText", "") end
function setChordNotesText(a) setValue("chordNotesText", a) end
function getSelectedScaleNote() return tonumber(getValue("selectedScaleNote", 1)) or 1 end
function setSelectedScaleNote(a) setValue("selectedScaleNote", a) end
function getOctave() return tonumber(getValue("octave", defaultOctave)) or 3 end
function setOctave(a) setValue("octave", a) end
function getOctaveMin() return -1 end
function getOctaveMax() return 8 end
function getChordInversionMin() return -8 end
function getChordInversionMax() return 8 end

function getSelectedChordTypes() return getTableValue("selectedChordTypes", defaultSevenOnes) end
function getSelectedChordType(i) return tonumber(getSelectedChordTypes()[i]) or 1 end
function setSelectedChordType(i, a)
  local t = getSelectedChordTypes(); t[i] = a; setTableValue("selectedChordTypes", t)
end

function getChordInversionStates() return getTableValue("chordInversionStates", defaultSevenZeros) end
function getChordInversionState(i) return tonumber(getChordInversionStates()[i]) or 0 end
function setChordInversionState(i, a)
  local t = getChordInversionStates(); t[i] = a; setTableValue("chordInversionStates", t)
end

function getScaleNoteNames() return getTableValue("scaleNoteNames", {'C','D','E','F','G','A','B'}) end
function getScaleNoteName(i) return getScaleNoteNames()[i] or "" end
function setScaleNoteName(i, a)
  local t = getScaleNoteNames(); t[i] = a; setTableValue("scaleNoteNames", t)
end

function getScaleDegreeHeaders() return getTableValue("scaleDegreeHeaders", {'I','ii','iii','IV','V','vi','viio'}) end
function getScaleDegreeHeader(i) return getScaleDegreeHeaders()[i] or "" end
function setScaleDegreeHeader(i, a)
  local t = getScaleDegreeHeaders(); t[i] = a; setTableValue("scaleDegreeHeaders", t)
end

function resetSelectedChordTypes() setTableValue("selectedChordTypes", defaultSevenOnes) end
function resetChordInversionStates() setTableValue("chordInversionStates", defaultSevenZeros) end

-- window
function getDockState() return tonumber(getValue("dockState", 0x0201)) or 0x0201 end
function setDockState(a) setValue("dockState", a) end
function windowShouldBeDocked() return getBool("shouldBeDocked", false) end
function setWindowShouldBeDocked(a) setBool("shouldBeDocked", a) end
function getWindowPinned() return getBool("windowPinned", false) end
function setWindowPinned(a) setBool("windowPinned", a) end

function getInterfaceXPosition() return tonumber(getValue("interfaceXPosition", -1)) or -1 end
function setInterfaceXPosition(a) setValue("interfaceXPosition", a) end
function getInterfaceYPosition() return tonumber(getValue("interfaceYPosition", -1)) or -1 end
function setInterfaceYPosition(a) setValue("interfaceYPosition", a) end

-- voices
function getVoiceLeadingEnabled() return getBool("vlEnabled", false) end
function setVoiceLeadingEnabled(a) setBool("vlEnabled", a); if not a then clearVoiceLeadingReference() end end

function getCustomPositionEnabled() return getBool("customPositionEnabled", false) end
function setCustomPositionEnabled(a) setBool("customPositionEnabled", a) end
function getCustomPosition() return getValue("customPosition", "1 5 3 7") end
function setCustomPosition(a) setValue("customPosition", a) end

-- 0 = auto, otherwise 2..8
function getVoiceCount() return tonumber(getValue("voiceCount", 0)) or 0 end
function setVoiceCount(a) setValue("voiceCount", a) end

--[[ Voice routing to MIDI channels
  mode "single" : all voices on the default channel (no split)
       "all"    : voice n → channel (first channel + n - 1)
       "bass"   : voice 1 → first channel, all others → next channel
       "custom" : channel chosen per voice (-1 = default channel)
]]
function getChannelMode()
  local m = getValue("channelMode", "")
  if m == "" then
    m = getBool("splitChannels", false) and "all" or "single"   -- ancienne option
    setValue("channelMode", m)
  end
  return m
end
function setChannelMode(m) setValue("channelMode", m) end

function getCustomVoiceChannels()
  local t = {}
  for m in getValue("voiceChannels", ""):gmatch("(%-?%d+)") do t[#t + 1] = tonumber(m) end
  return t
end
function setCustomVoiceChannels(t) setValue("voiceChannels", table.concat(t, ",")) end

-- channel (0-15) of voice v, or nil = editor default channel
function voiceChannel(v)
  local mode = getChannelMode()
  local first = getFirstChannel()
  if mode == "all" then return math.min(15, first + v - 1) end
  if mode == "bass" then return (v == 1) and first or math.min(15, first + 1) end
  if mode == "custom" then
    local c = getCustomVoiceChannels()[v]
    if c and c >= 0 then return math.min(15, c) end
  end
  return nil
end

-- set one voice's channel: switches to custom mode, starting from the current routing
function setVoiceChannel(v, chan, totalVoices)
  local t = {}
  local n = math.max(totalVoices or 0, v, #getCustomVoiceChannels())
  for i = 1, n do t[i] = voiceChannel(i) or -1 end
  t[v] = chan or -1
  setCustomVoiceChannels(t)
  setChannelMode("custom")
end

-- compatibility: "one channel per voice" = any routing other than single channel
function getSplitChannels() return getChannelMode() ~= "single" end
function setSplitChannels(a) setChannelMode(a and "all" or "single") end

-- true if each of the n voices has its own channel (voices can be identified by channel)
function voicesHaveDistinctChannels(n)
  local seen = {}
  for v = 1, n do
    local c = voiceChannel(v)
    if c == nil or seen[c] then return false end
    seen[c] = true
  end
  return true
end

-- "lowest" (lowest note) or "root" (root, separate bass voice)
function getBassMode() return getValue("bassMode", "lowest") end
function setBassMode(a) setValue("bassMode", a) end

-- MIDI channel of voice 1 (0-based)
function getFirstChannel() return tonumber(getValue("firstChannel", 0)) or 0 end
function setFirstChannel(a) setValue("firstChannel", a) end

function getVoiceLeadingReference()
  local raw = getValue("vlReference", "")
  local t = {}
  for m in raw:gmatch("(%-?%d+)") do t[#t + 1] = tonumber(m) end
  return t
end
-- tags: function of each voice in the reference chord ("7" = seventh, "L" = leading tone, "" otherwise)
function setVoiceLeadingReference(t, tags)
  setValue("vlReference", table.concat(t, ","))
  local tg = {}
  for i = 1, #t do tg[i] = (tags and tags[i] and tags[i] ~= "") and tags[i] or "_" end
  setValue("vlRefTags", table.concat(tg, ","))
end
function getVoiceLeadingReferenceTags()
  local t = {}
  for m in getValue("vlRefTags", ""):gmatch("([^,]+)") do t[#t + 1] = (m == "_") and "" or m end
  return t
end
function clearVoiceLeadingReference() setValue("vlReference", ""); setValue("vlRefTags", "") end

-- automatic inversion of custom positions with voice leading
function getAutoInversion() return getBool("autoInversion", false) end
function setAutoInversion(a) setBool("autoInversion", a) end

-- last output (voices shown in the UI): "pitch,pitch,..."
function getLastVoices()
  local raw = getValue("lastVoices", "")
  local t = {}
  for m in raw:gmatch("(%-?%d+)") do t[#t + 1] = tonumber(m) end
  return t
end
function setLastVoices(t) setValue("lastVoices", table.concat(t, ",")) end
function getLastVoiceNames()
  local t = {}
  for m in getValue("lastVoiceNames", ""):gmatch("([^,]+)") do t[#t + 1] = m end
  return t
end

--[[ Doublings: "voice1|voice2|..."; each voice = comma-separated tokens
     sN = N demi-tons (signé), dN = N degrés de la gamme (signé) ]]
function getDoublings()
  local raw = getValue("doublings", "")
  local out = {}
  local v = 1
  for chunk in (raw .. "|"):gmatch("([^|]*)|") do
    out[v] = {}
    for tok in chunk:gmatch("([sd]%-?%d+)") do table.insert(out[v], tok) end
    v = v + 1
  end
  return out
end

function setDoublings(d)
  local parts = {}
  local maxV = 0
  for k in pairs(d) do if k > maxV then maxV = k end end
  for v = 1, maxV do parts[v] = table.concat(d[v] or {}, ",") end
  setValue("doublings", table.concat(parts, "|"))
end

function addDoubling(voice, token)
  local d = getDoublings()
  d[voice] = d[voice] or {}
  for _, t in ipairs(d[voice]) do if t == token then return end end
  table.insert(d[voice], token)
  setDoublings(d)
end

function removeDoubling(voice, index)
  local d = getDoublings()
  if d[voice] then table.remove(d[voice], index) end
  setDoublings(d)
end

function clearDoublings(voice)
  local d = getDoublings()
  if voice then d[voice] = {} else d = {} end
  setDoublings(d)
end

local intervalNames = {
  [0] = "8ve", [1] = "m2", [2] = "M2", [3] = "m3", [4] = "M3", [5] = "P4",
  [6] = "TT", [7] = "P5", [8] = "m6", [9] = "M6", [10] = "m7", [11] = "M7",
}

function doublingLabel(token)
  local kind, n = token:sub(1, 1), tonumber(token:sub(2))
  if not n then return token end
  local sign = n < 0 and "-" or "+"
  local a = math.abs(n)
  if kind == "d" then return sign .. (a + 1) .. " steps" end
  if a == 12 then return sign .. "8ve" end
  if a == 24 then return sign .. "15ma" end
  if a == 0 then return "=" end
  local base = intervalNames[a % 12] or tostring(a)
  if a > 12 then base = base .. "+8" end
  return sign .. base
end

------------------------------------------------------------------------------
-- Scale
------------------------------------------------------------------------------

scaleNotes = {}
scaleChords = {}
scalePattern = nil

function getNotesIndex(note) return ((note - 1) % 12) + 1 end
function getSharpNoteName(note) return notes[getNotesIndex(note)] end
function getFlatNoteName(note) return flatNotes[getNotesIndex(note)] end

-- names of the main scale's notes by pitch class (rebuilt by updateScaleData)
mainNameByPC = {}
local mainScaleUsesFlats = false

function getNoteName(note)
  local pc = (note - 1) % 12
  if mainNameByPC[pc] then return mainNameByPC[pc] end
  if mainScaleUsesFlats then return getFlatNoteName(note) end
  return getSharpNoteName(note)
end

-- Spells a scale (list of notes, tonic first). Seven-note scales get one letter per
-- degree (C D E F# G A Bb, never Gb next to G); others use sharps, or flats on a clash.
function spellNotes(noteList)
  local n = #noteList
  local function simple(nameFn)
    local names, letters, ok = {}, {}, true
    for k, note in ipairs(noteList) do
      names[k] = nameFn(note)
      local letter = names[k]:sub(1, 1)
      if letters[letter] then ok = false end
      letters[letter] = true
    end
    return names, ok
  end
  if n == 7 then
    local LETTERS = { "C", "D", "E", "F", "G", "A", "B" }
    local NATURAL = { C = 0, D = 2, E = 4, F = 5, G = 7, A = 9, B = 11 }
    local tonicPC = (noteList[1] - 1) % 12
    local best, bestCost = nil, math.huge
    for li, letter in ipairs(LETTERS) do
      local d0 = ((tonicPC - NATURAL[letter] + 6) % 12) - 6
      if math.abs(d0) <= 1 then
        local names, cost, ok = {}, 0, true
        for k = 1, 7 do
          local L = LETTERS[((li - 1 + k - 1) % 7) + 1]
          local acc = (((noteList[k] - 1) % 12 - NATURAL[L] + 6) % 12) - 6
          if math.abs(acc) > 1 then ok = false; break end
          names[k] = L .. ((acc == 1) and "#" or (acc == -1) and "b" or "")
          cost = cost + math.abs(acc)
          -- on a tie, stay consistent with the main scale's spelling
          local known = mainNameByPC[(noteList[k] - 1) % 12]
          if known and known ~= names[k] then cost = cost + 0.01 end
        end
        if ok and cost < bestCost then best, bestCost = names, cost end
      end
    end
    if best then return best end
  end
  local names, ok = simple(getSharpNoteName)
  if not ok then names = simple(getFlatNoteName) end
  return names
end

-- name with octave for a MIDI pitch (C4 = 60)
function getPitchName(pitch)
  if noteNameInContext then return noteNameInContext(pitch + 1) .. tostring(math.floor(pitch / 12) - 1) end
  return getNoteName(pitch + 1) .. tostring(math.floor(pitch / 12) - 1)
end

function getScalePattern(tonic, scale)
  local s = scale.pattern
  local p = {false,false,false,false,false,false,false,false,false,false,false,false}
  for i = 0, #s - 1 do
    if s:sub(i + 1, i + 1) == '1' then p[getNotesIndex(tonic + i)] = true end
  end
  return p
end

function noteIsInScale(note) return scalePattern[getNotesIndex(note)] end
function noteIsNotInScale(note) return not noteIsInScale(note) end

function chordIsInScale(rootNote, chordIndex)
  local pattern = chords[chordIndex].pattern
  for i = 0, #pattern - 1 do
    if pattern:sub(i + 1, i + 1) == '1' and noteIsNotInScale(rootNote + i) then return false end
  end
  return true
end

local function chordIsNotAlreadyIncluded(list, code)
  for _, c in ipairs(list) do if c.code == code then return false end end
  return true
end

function getScaleChordsForRootNote(rootNote)
  local list = {}
  for idx, chord in ipairs(chords) do
    if chordIsInScale(rootNote, idx) then list[#list + 1] = chord end
  end
  for _, chord in ipairs(chords) do
    if chordIsNotAlreadyIncluded(list, chord.code) then list[#list + 1] = chord end
  end
  return list
end

function getNumberOfScaleChordsForScaleNoteIndex(i)
  local n = 0
  for idx in ipairs(chords) do
    if chordIsInScale(scaleNotes[i], idx) then n = n + 1 end
  end
  return n
end

function updateScaleNotes()
  scaleNotes = {}
  for note = getScaleTonicNote(), getScaleTonicNote() + 11 do
    if noteIsInScale(note) then scaleNotes[#scaleNotes + 1] = note end
  end
end

function updateScaleChords()
  scaleChords = {}
  for i, note in ipairs(scaleNotes) do scaleChords[i] = getScaleChordsForRootNote(note) end
end

function updateScaleNoteNames()
  mainNameByPC = {}
  local names = spellNotes(scaleNotes)
  setTableValue("scaleNoteNames", names)
  mainScaleUsesFlats = false
  for d, note in ipairs(scaleNotes) do
    mainNameByPC[(note - 1) % 12] = names[d]
    if names[d]:find("b", 1, true) then mainScaleUsesFlats = true end
  end
end

function updateScaleNotesText()
  local t = {}
  for i = 1, #scaleNotes do t[i] = getScaleNoteName(i) end
  setScaleNotesText(table.concat(t, ", "))
end

function updateScaleDegreeHeaders()
  local minorSymbols = {'i','ii','iii','iv','v','vi','vii'}
  local majorSymbols = {'I','II','III','IV','V','VI','VII'}
  local headers = {}
  for i = 1, #scaleNotes do
    local chord = scaleChords[i][1]
    local symbol
    if string.match(chord.code, "major") or chord.code == '7' then symbol = majorSymbols[i] else symbol = minorSymbols[i] end
    if chord.code == 'aug' then symbol = symbol .. '+' end
    if chord.code == 'dim' then symbol = symbol .. 'o' end
    if string.match(chord.code, "6") then symbol = symbol .. '6' end
    if string.match(chord.code, "7") then symbol = symbol .. '7' end
    headers[i] = symbol
  end
  setTableValue("scaleDegreeHeaders", headers)
end

function updateScaleData()
  scalePattern = getScalePattern(getScaleTonicNote(), scales[getScaleType()] or scales[1])
  updateScaleNotes()
  updateScaleNoteNames()
  updateScaleNotesText()
  updateScaleChords()
  updateScaleDegreeHeaders()
end

function showScaleStatus()
  reaper.Help_Set(("%s %s: %s"):format(notes[getScaleTonicNote()], scales[getScaleType()].name, getScaleNotesText()), false)
end

-- active borrowed context (nil = main scale)
borrowContext = nil
function currentTonicNote() return borrowContext and borrowContext.tonic or getScaleTonicNote() end
function noteNameInContext(note)
  if borrowContext then
    local n = borrowContext.nameByPC[(note - 1) % 12]
    if n then return n end
  end
  return getNoteName(note)
end

function scaleIsPentatonic()
  return string.match(string.lower(scales[getScaleType()].name), "pentatonic") ~= nil
end

------------------------------------------------------------------------------
-- MIDI editor (from the original)
------------------------------------------------------------------------------

local tolerance = 0.000001

function activeMidiEditor() return reaper.MIDIEditor_GetActive() end
function activeTake()
  local ed = activeMidiEditor()
  if ed == nil then return nil end
  return reaper.MIDIEditor_GetTake(ed)
end
function activeMediaItem() return reaper.GetMediaItemTake_Item(activeTake()) end
function activeTrack() return reaper.GetMediaItemTake_Track(activeTake()) end
function mediaItemStartPosition() return reaper.GetMediaItemInfo_Value(activeMediaItem(), "D_POSITION") end
function mediaItemStartPositionPPQ() return reaper.MIDI_GetPPQPosFromProjTime(activeTake(), mediaItemStartPosition()) end
function mediaItemStartPositionQN() return reaper.MIDI_GetProjQNFromPPQPos(activeTake(), mediaItemStartPositionPPQ()) end
local function mediaItemLength() return reaper.GetMediaItemInfo_Value(activeMediaItem(), "D_LENGTH") end
local function mediaItemEndPosition() return mediaItemStartPosition() + mediaItemLength() end
local function cursorPosition() return reaper.GetCursorPosition() end

local function loopStartPosition()
  local s = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  return s
end
local function loopEndPosition()
  local _, e = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  return e
end

function gridUnitLength()
  local gridLengthQN = reaper.MIDI_GetGrid(activeTake())
  local ppq = reaper.MIDI_GetPPQPosFromProjQN(activeTake(), mediaItemStartPositionQN() + gridLengthQN)
  return reaper.MIDI_GetProjTimeFromPPQPos(activeTake(), ppq) - mediaItemStartPosition()
end
-- chord length = grid unit × multiplier
function getLengthMultiplier()
  local v = tonumber(getValue("lengthMultiplier", 1)) or 1
  return math.max(1, math.min(64, math.floor(v)))
end
function setLengthMultiplier(a) setValue("lengthMultiplier", a) end
local function noteLength() return gridUnitLength() * getLengthMultiplier() end

function notCurrentlyRecording() return reaper.GetPlayStateEx(0) & 4 ~= 4 end

function setEditCursorPosition(arg) reaper.SetEditCurPos2(0, arg, false, false) end
local function moveEditCursorPosition(arg) reaper.MoveEditCursor(arg, false) end
local function repeatIsNotOn() return reaper.GetSetRepeat(-1) == 0 end

local function loopIsActive()
  if repeatIsNotOn() then return false end
  if loopStartPosition() < mediaItemStartPosition() and loopEndPosition() < mediaItemStartPosition() then return false end
  if loopStartPosition() > mediaItemEndPosition() and loopEndPosition() > mediaItemEndPosition() then return false end
  return loopStartPosition() ~= loopEndPosition()
end

function moveCursor(keepNotesSelected, selectedChord)
  local len
  if keepNotesSelected then
    len = reaper.MIDI_GetProjTimeFromPPQPos(activeTake(), selectedChord.longestEndPosition) - cursorPosition()
  else
    len = noteLength()
  end
  local function wrap()
    if loopIsActive() and loopStartPosition() > mediaItemStartPosition() then
      setEditCursorPosition(loopStartPosition())
    else
      setEditCursorPosition(mediaItemStartPosition())
    end
  end
  if loopIsActive() and loopEndPosition() < mediaItemEndPosition() then
    if cursorPosition() + len >= loopEndPosition() - tolerance then wrap() else moveEditCursorPosition(len) end
  elseif loopIsActive() and mediaItemEndPosition() <= loopEndPosition() then
    if cursorPosition() + len >= mediaItemEndPosition() - tolerance then wrap() else moveEditCursorPosition(len) end
  elseif cursorPosition() + len >= mediaItemEndPosition() - tolerance then
    setEditCursorPosition(mediaItemStartPosition())
  else
    moveEditCursorPosition(len)
  end
end

function getCursorPositionPPQ() return reaper.MIDI_GetPPQPosFromProjTime(activeTake(), cursorPosition()) end

function getMidiEndPositionPPQ()
  local s = reaper.GetCursorPosition()
  return reaper.MIDI_GetPPQPosFromProjTime(activeTake(), s + noteLength())
end

function getCurrentNoteChannel(channelArg)
  if channelArg ~= nil then return channelArg end
  if activeMidiEditor() == nil then return 0 end
  return reaper.MIDIEditor_GetSetting_int(activeMidiEditor(), "default_note_chan")
end

-- note velocity: "Velocity" slider of the main window
function getVelocitySlider()
  local raw = getValue("velocitySlider", "-1,96")
  local inp, val = raw:match("(%-?%d+),(%d+)")
  return { inp = tonumber(inp) or -1, value = math.max(1, math.min(127, tonumber(val) or 96)) }
end

function setVelocitySlider(v)
  setValue("velocitySlider", (v.inp or -1) .. "," .. math.max(1, math.min(127, v.value or 96)))
end

function getCurrentVelocity()
  return getVelocitySlider().value
end

function getNumberOfNotes()
  local _, n = reaper.MIDI_CountEvts(activeTake())
  return n
end

function deleteNote(i) reaper.MIDI_DeleteNote(activeTake(), i) end

function thereAreNotesSelected()
  if activeTake() == nil then return false end
  for i = 0, getNumberOfNotes() - 1 do
    local _, sel = reaper.MIDI_GetNote(activeTake(), i)
    if sel then return true end
  end
  return false
end

function halveGridSize()
  if activeTake() == nil then return end
  local g = reaper.MIDI_GetGrid(activeTake()) / 4
  if g <= 1/1024 then return end
  reaper.SetMIDIEditorGrid(0, g / 2)
end

function doubleGridSize()
  if activeTake() == nil then return end
  local g = reaper.MIDI_GetGrid(activeTake()) / 4
  if g >= 1024 then return end
  reaper.SetMIDIEditorGrid(0, g * 2)
end

function deleteExistingNotesInNextInsertionTimePeriod(keepNotesSelected, selectedChord)
  local startT = cursorPosition()
  local endT
  if keepNotesSelected then
    endT = reaper.MIDI_GetProjTimeFromPPQPos(activeTake(), selectedChord.longestEndPosition)
  else
    endT = startT + noteLength()
  end
  for i = getNumberOfNotes() - 1, 0, -1 do
    local _, _, _, sppq = reaper.MIDI_GetNote(activeTake(), i)
    local t = reaper.MIDI_GetProjTimeFromPPQPos(activeTake(), sppq)
    if t + tolerance >= startT and t + tolerance <= endT then deleteNote(i) end
  end
end

------------------------------------------------------------------------------
-- MIDI playback (preview)
------------------------------------------------------------------------------

function playMidiNote(midiNote, channel)
  channel = getCurrentNoteChannel(channel)
  reaper.StuffMIDIMessage(0, 0x90 + channel, midiNote, getCurrentVelocity())
end

function stopNoteFromPlaying(midiNote, channel)
  channel = getCurrentNoteChannel(channel)
  reaper.StuffMIDIMessage(0, 0x80 + channel, midiNote, 0)
end

-- "pitch:chan,pitch:chan"
function getNotesThatArePlaying()
  local raw = getValue("notesThatArePlaying", "")
  local t = {}
  for p, c in raw:gmatch("(%d+):?(%d*)") do
    t[#t + 1] = { pitch = tonumber(p), chan = tonumber(c) }
  end
  return t
end

function setNotesThatArePlaying(list)
  local parts = {}
  for _, n in ipairs(list) do
    parts[#parts + 1] = tostring(n.pitch) .. ":" .. tostring(n.chan or getCurrentNoteChannel())
  end
  setValue("notesThatArePlaying", table.concat(parts, ","))
end

function stopNotesFromPlaying()
  for _, n in ipairs(getNotesThatArePlaying()) do stopNoteFromPlaying(n.pitch, n.chan) end
  setNotesThatArePlaying({})
end

function stopAllNotesFromPlaying()
  for ch = 0, 15 do
    reaper.StuffMIDIMessage(0, 0xB0 + ch, 123, 0) -- All Notes Off
  end
  for midiNote = 0, 127 do
    reaper.StuffMIDIMessage(0, 0x80 + getCurrentNoteChannel(), midiNote, 0)
  end
  setNotesThatArePlaying({})
  setValue("droneSounding", "")
end


------------------------------------------------------------------------------
-- Drone: one or more fixed notes added under every chord.
--   They never move, and voice leading ignores them (they are filtered out of the
--   analysed reference and are not part of the voicing).
--   hold = true: in live preview the drone keeps sounding between chords
--   (it is started once and only stopped when the drone is turned off).
------------------------------------------------------------------------------

function getDroneEnabled() return getBool("droneEnabled", false) end

function getDronePitches()
  local t = {}
  for m in getValue("dronePitches", ""):gmatch("(%d+)") do
    local p = tonumber(m)
    if p and p >= 0 and p <= 127 then t[#t + 1] = p end
  end
  table.sort(t)
  return t
end

-- -1 = default (MIDI editor) channel
function getDroneChannel() return tonumber(getValue("droneChannel", -1)) or -1 end
function getDroneHold() return getBool("droneHold", true) end

local function droneChan()
  local c = getDroneChannel()
  if c >= 0 then return math.min(15, c) end
  return nil
end

local function droneSet()
  local set = {}
  if getDroneEnabled() then
    for _, p in ipairs(getDronePitches()) do set[p] = true end
  end
  return set
end

function isDronePitch(p) return droneSet()[p] == true end

-- notes to add under a chord: { {pitch=, chan=, voice=0, drone=true}, ... }
function getDroneNotes()
  if not getDroneEnabled() then return {} end
  local out = {}
  local chan = droneChan()
  for _, p in ipairs(getDronePitches()) do
    out[#out + 1] = { pitch = p, chan = chan, voice = 0, drone = true }
  end
  return out
end

-- remove drone pitches from a list of pitches (numbers) or notes ({pitch=})
function stripDrones(list)
  local set = droneSet()
  if next(set) == nil then return list end
  local out = {}
  for _, x in ipairs(list) do
    local p = (type(x) == "table") and x.pitch or x
    if not set[p] then out[#out + 1] = x end
  end
  return out
end

-- currently held drone ("pitch:chan,...")
local function getDroneSounding()
  local t = {}
  for p, c in getValue("droneSounding", ""):gmatch("(%d+):(%d+)") do
    t[#t + 1] = { pitch = tonumber(p), chan = tonumber(c) }
  end
  return t
end

local function setDroneSounding(list)
  local parts = {}
  for _, n in ipairs(list) do parts[#parts + 1] = n.pitch .. ":" .. n.chan end
  setValue("droneSounding", table.concat(parts, ","))
end

function stopDrone()
  for _, n in ipairs(getDroneSounding()) do
    reaper.StuffMIDIMessage(0, 0x80 + n.chan, n.pitch, 0)
  end
  setDroneSounding({})
end

-- start the held drone if it is not already sounding with the same notes
function startDrone()
  local wanted = {}
  for _, n in ipairs(getDroneNotes()) do
    wanted[#wanted + 1] = { pitch = n.pitch, chan = n.chan or getCurrentNoteChannel() }
  end
  local key = function(list)
    local t = {}
    for _, n in ipairs(list) do t[#t + 1] = n.pitch .. ":" .. n.chan end
    table.sort(t)
    return table.concat(t, ",")
  end
  local current = getDroneSounding()
  if key(current) == key(wanted) then return end
  stopDrone()
  for _, n in ipairs(wanted) do
    reaper.StuffMIDIMessage(0, 0x90 + n.chan, n.pitch, getCurrentVelocity())
  end
  setDroneSounding(wanted)
end

-- call after any drone setting change: restart, stop or leave it as it is
function refreshDrone()
  if getDroneEnabled() and getDroneHold() and #getDronePitches() > 0 then
    if #getDroneSounding() > 0 then startDrone() end
  else
    stopDrone()
  end
end

function setDroneEnabled(a) setBool("droneEnabled", a); refreshDrone() end
function setDronePitches(t)
  local seen, out = {}, {}
  for _, p in ipairs(t) do
    p = math.floor(p)
    if p >= 0 and p <= 127 and not seen[p] then seen[p] = true; out[#out + 1] = p end
  end
  table.sort(out)
  setValue("dronePitches", table.concat(out, ","))
  refreshDrone()
end
function setDroneChannel(c) setValue("droneChannel", c or -1); refreshDrone() end
function setDroneHold(a) setBool("droneHold", a); refreshDrone() end

function addDronePitch(p)
  local t = getDronePitches()
  t[#t + 1] = p
  setDronePitches(t)
end

function removeDronePitch(p)
  local t = {}
  for _, q in ipairs(getDronePitches()) do if q ~= p then t[#t + 1] = q end end
  setDronePitches(t)
end

-- "C2", "F#1", "Bb3", "eb2" or a MIDI number (C4 = 60); returns nil if invalid
function parsePitchName(token)
  token = token:gsub("%s", "")
  local n = tonumber(token)
  if n then
    if n >= 0 and n <= 127 then return math.floor(n) end
    return nil
  end
  local letter, acc, oct = token:match("^([A-Ga-g])([#b♯♭]*)(%-?%d+)$")
  if not letter then return nil end
  local base = ({ C = 0, D = 2, E = 4, F = 5, G = 7, A = 9, B = 11 })[letter:upper()]
  for ch in acc:gmatch(".") do
    if ch == "#" then base = base + 1 elseif ch == "b" then base = base - 1 end
  end
  if acc:find("♯", 1, true) then base = base + 1 end
  if acc:find("♭", 1, true) then base = base - 1 end
  local p = (tonumber(oct) + 1) * 12 + base
  if p < 0 or p > 127 then return nil end
  return p
end

-- parse "C2 G2, D3" into a list of pitches; returns list, first invalid token
function parsePitchList(text)
  local out = {}
  for tok in text:gmatch("[^%s,;]+") do
    local p = parsePitchName(tok)
    if not p then return nil, tok end
    out[#out + 1] = p
  end
  return out
end

------------------------------------------------------------------------------
-- Moteur de voicing
------------------------------------------------------------------------------

-- chord intervals (semitones from the root)
local function chordIntervals(chord)
  local t = {}
  local p = chord.pattern
  for n = 0, #p - 1 do
    if p:sub(n + 1, n + 1) == '1' then t[#t + 1] = n end
  end
  return t
end

local function intervalFunction(iv)
  if iv >= 12 then
    -- upper structure (colors): 9th, 11th, 13th
    local m = iv % 12
    if m >= 1 and m <= 3 then return "9" end
    if m == 5 or m == 6 then return "11" end
    if m == 8 or m == 9 then return "13" end
  end
  iv = iv % 12
  if iv == 0 then return "1" end
  if iv == 2 or iv == 3 or iv == 4 or iv == 5 then return "3" end -- sus2/sus4 replace the third
  if iv >= 6 and iv <= 8 then return "5" end
  if iv == 9 then return "6" end
  return "7"
end

-- diatonic interval (in the scale) from degree scaleNoteIndex, in steps
local majorRef = { 0, 2, 4, 5, 7, 9, 11 }

local function diatonicInterval(scaleNoteIndex, steps)
  local n = #scaleNotes
  if n ~= 7 or not scaleNoteIndex then return majorRef[(steps % 7) + 1] end
  local target = scaleNotes[((scaleNoteIndex - 1 + steps) % n) + 1]
  return (target - scaleNotes[scaleNoteIndex]) % 12
end

-- Parses a position token: "1", "R", "b9", "#11", "13", "7M", "5+" (+ = one more octave)
local function resolvePositionToken(token, ctx)
  local t = token:gsub("♭", "b"):gsub("♯", "#")
  local jumps = 0
  t = t:gsub("[%+']", function() jumps = jumps + 1; return "" end)

  local upper = t:upper()
  if upper == "R" or upper == "T" or upper == "F" then return 0, jumps end

  local acc = 0
  local natural = false
  local prefix, num, suffix = t:match("^([b#Mm]*)(%d+)([Mm]?a?j?)$")
  if not num then
    prefix, num = t:match("^(maj)(%d+)$")
    if not num then return nil end
  end
  for c in (prefix or ""):gmatch(".") do
    if c == "b" or c == "m" then acc = acc - 1 elseif c == "#" then acc = acc + 1 elseif c == "M" then natural = true end
  end
  if prefix == "maj" or (suffix and suffix:upper():sub(1, 1) == "M") then natural = true end

  num = tonumber(num)
  if num < 1 or num > 15 then return nil end
  local deg = ((num - 1) % 7) + 1

  if acc ~= 0 or natural then
    return (majorRef[deg] + acc) % 12, jumps
  end

  local f = ctx.funcs
  if deg == 1 then return 0, jumps end
  if deg == 3 then return f["3"] or diatonicInterval(ctx.scaleNoteIndex, 2), jumps end
  if deg == 5 then return f["5"] or diatonicInterval(ctx.scaleNoteIndex, 4), jumps end
  if deg == 7 then return f["7"] or diatonicInterval(ctx.scaleNoteIndex, 6), jumps end
  if deg == 6 then return f["6"] or f["13"] or diatonicInterval(ctx.scaleNoteIndex, 5), jumps end
  if deg == 2 then return f["9"] or diatonicInterval(ctx.scaleNoteIndex, 1), jumps end
  if deg == 4 then return f["11"] or diatonicInterval(ctx.scaleNoteIndex, 3), jumps end
  return nil
end

-- Returns { {pc=, jumps=}, ... } or nil, error message
function parseCustomPosition(text, rootPC, chord, scaleNoteIndex)
  local funcs = {}
  for _, iv in ipairs(chordIntervals(chord)) do
    local f = intervalFunction(iv)
    if funcs[f] == nil then funcs[f] = iv end
  end
  local ctx = { funcs = funcs, scaleNoteIndex = scaleNoteIndex }
  local shape = {}
  for token in text:gmatch("[^%s,;%-/·]+") do
    local iv, jumps = resolvePositionToken(token, ctx)
    if iv == nil then return nil, "unknown token: " .. token end
    shape[#shape + 1] = { pc = (rootPC + iv) % 12, jumps = jumps, token = token }
  end
  if #shape == 0 then return nil, "empty position" end
  return shape
end

-- validates a position without a chord (for the UI)
function validateCustomPosition(text)
  local _, err = parseCustomPosition(text, 0, chords[10], nil)
  return err == nil, err
end

local function lowestAtOrAbove(pc, floor) return floor + ((pc - floor) % 12) end

-- ChordGun-style inversion: rotation + octave shift
local function rotateForInversion(list, inversion)
  local n = #list
  if n == 0 or inversion == 0 then return list, 0 end
  local oct = math.floor(inversion / n)
  local r = inversion - oct * n
  local out = {}
  for i = 1, n do out[i] = list[((i - 1 + r) % n) + 1] end
  return out, oct
end

-- stacking of a custom position without voice leading
local function stackShape(rootPitch, shape, inversion)
  local rotated, oct = rotateForInversion(shape, inversion)
  local out = {}
  for i, s in ipairs(rotated) do
    local p
    if i == 1 then
      p = lowestAtOrAbove(s.pc, rootPitch)
    else
      p = lowestAtOrAbove(s.pc, out[i - 1] + 1)
    end
    out[i] = p + 12 * s.jumps
  end
  for i = 1, #out do out[i] = out[i] + oct * 12 end
  table.sort(out)
  return out
end

-- standard ChordGun voicing (close chord + inversion)
function getChordNotesArray(root, chord, octave, inversion)
  local arr = {}
  local p = chord.pattern
  for n = 0, #p - 1 do
    if p:sub(n + 1, n + 1) == '1' then arr[#arr + 1] = root + n + ((octave + 1) * 12) - 1 end
  end
  inversion = inversion or getChordInversionState(getSelectedScaleNote())
  local len = #arr
  local oct = 0
  if inversion < 0 then
    oct = math.floor(inversion / len)
    inversion = inversion + (math.abs(oct) * len)
  end
  for _ = 1, inversion do
    local r = table.remove(arr, 1)
    arr[#arr + 1] = r + 12
  end
  for i = 1, #arr do arr[i] = arr[i] + oct * 12 end
  return arr
end

-- fits a voicing to N voices (drops the fifth first, doubles root/fifth/third)
local function fitVoiceCount(V, N, info)
  table.sort(V)
  local removeOrder = { "5", "11", "9", "13", "6", "7" }
  while #V > N do
    local removed = false
    for _, f in ipairs(removeOrder) do
      for k = #V, 2, -1 do
        if info.funcOf[V[k] % 12] == f then table.remove(V, k); removed = true; break end
      end
      if removed then break end
    end
    if not removed then table.remove(V) end
  end
  local prefs = { info.rootPC, info.fifthPC or info.rootPC, info.thirdPC or info.rootPC, info.rootPC }
  local k = 1
  while #V < N do
    local pc = prefs[((k - 1) % #prefs) + 1]
    V[#V + 1] = lowestAtOrAbove(pc, V[#V] + 1)
    k = k + 1
  end
  return V
end

-- aligns an M-voice reference to N voices (interpolation); aligned=true if M==N
local function alignReference(ref, N)
  local M = #ref
  if M == N then return copyTable(ref), true end
  local out = {}
  for i = 1, N do
    local pos = (N == 1) and 1 or (1 + (i - 1) * (M - 1) / (N - 1))
    local lo = math.floor(pos)
    local hi = math.min(lo + 1, M)
    local f = pos - lo
    out[i] = math.floor(ref[lo] * (1 - f) + ref[hi] * f + 0.5)
  end
  return out, false
end

-- Penalties (tweakable)
VL = {
  parallel = 1000,     -- parallel fifths / octaves
  hidden = 6,          -- direct fifths/octaves in outer voices (leap in the soprano)
  crossing = 4,        -- overlap with the previous position
  spacing = 6,         -- more than an octave between adjacent upper voices
  bassGap = 3,         -- more than 2 octaves between bass and tenor
  doubledThird = 5,
  doubledSeventh = 10,
  doubledLeading = 10,
  doubledSixth = 3,
  doubledFifth = 1,
  seventhResolution = 6,
  leadingSoprano = 5,
  leadingInner = 1,
  minPitch = 24, maxPitch = 100,
}

--[[ Search for the best voicing.
  prev     : aligned reference (N pitches)
  aligned  : the reference has exactly N voices (enables parallel detection)
  allowed  : allowed[i] = table { [pc]=true } of pitch classes allowed for voice i
  opts     : { required = {pc,...}, funcOf = {[pc]=func}, leadingPC = pc|nil, coverage = bool }
]]
local function searchVoicing(prev, aligned, allowed, opts, window)
  local N = #prev
  local cands = {}
  for i = 1, N do
    cands[i] = {}
    for p = prev[i] - window, prev[i] + window do
      if p >= VL.minPitch and p <= VL.maxPitch and allowed[i][p % 12] then
        cands[i][#cands[i] + 1] = p
      end
    end
    -- try the closest notes first (better pruning)
    table.sort(cands[i], function(a, b) return math.abs(a - prev[i]) < math.abs(b - prev[i]) end)
    if #cands[i] == 0 then return nil end
  end

  local best, bestCost = nil, math.huge
  local cur = {}
  local counts = {}

  local function missingRequired()
    if not opts.coverage then return 0 end
    local m = 0
    for _, pc in ipairs(opts.required) do
      if (counts[pc] or 0) == 0 then m = m + 1 end
    end
    return m
  end

  local function stepPenalty(i)
    local c = math.abs(cur[i] - prev[i])
    -- register anchoring: the bass stays near the chosen octave (avoids drifting)
    if i == 1 and opts.anchor then
      local d = math.abs(cur[1] - opts.anchor)
      if d > 7 then c = c + (d - 7) * 2 end
    end
    if aligned then
      for j = 1, i - 1 do
        if cur[i] ~= prev[i] and cur[j] ~= prev[j] then
          local a = (prev[i] - prev[j]) % 12
          local b = (cur[i] - cur[j]) % 12
          if a == b and (a == 0 or a == 7) then c = c + VL.parallel end
        end
      end
      local tag = opts.tags and opts.tags[i]
      local move = cur[i] - prev[i]
      if tag == "7" and move ~= 0 and (move > 0 or move < -2) then
        c = c + VL.seventhResolution                       -- the 7th resolves down by step
      elseif tag == "L" and opts.tonicPC and opts.hasTonic and move ~= 1 then
        c = c + ((i == N) and VL.leadingSoprano or VL.leadingInner) -- the leading tone rises to the tonic
      end
      if i < N and cur[i] > prev[i + 1] then c = c + VL.crossing end
      if i > 1 and cur[i] < prev[i - 1] then c = c + VL.crossing end
    end
    if i >= 3 and cur[i] - cur[i - 1] > 12 then c = c + VL.spacing end
    if i == 2 and cur[2] - cur[1] > 24 then c = c + VL.bassGap end
    return c
  end

  local function finalPenalty()
    local c = 0
    if opts.coverage then
      if missingRequired() > 0 then return math.huge end
      for pc, n in pairs(counts) do
        if n > 1 then
          local f = opts.funcOf[pc]
          local extra = n - 1
          if opts.leadingPC and pc == opts.leadingPC and f ~= "1" then c = c + VL.doubledLeading * extra
          elseif f == "3" then c = c + VL.doubledThird * extra
          elseif f == "7" then c = c + VL.doubledSeventh * extra
          elseif f == "6" then c = c + VL.doubledSixth * extra
          elseif f == "9" or f == "11" or f == "13" then c = c + VL.doubledSeventh * extra
          elseif f == "5" then c = c + VL.doubledFifth * extra end
        end
      end
    end
    if aligned and N >= 2 then
      local db = cur[1] - prev[1]
      local ds = cur[N] - prev[N]
      if db ~= 0 and ds ~= 0 and (db > 0) == (ds > 0) and math.abs(ds) > 2 then
        local iv = (cur[N] - cur[1]) % 12
        if iv == 0 or iv == 7 then c = c + VL.hidden end
      end
    end
    return c
  end

  local function rec(i, cost)
    if cost >= bestCost then return end
    if i > N then
      local total = cost + finalPenalty()
      if total < bestCost then bestCost = total; best = copyTable(cur) end
      return
    end
    for _, p in ipairs(cands[i]) do
      if i == 1 or p > cur[i - 1] then
        cur[i] = p
        local pc = p % 12
        counts[pc] = (counts[pc] or 0) + 1
        if missingRequired() <= N - i then
          rec(i + 1, cost + stepPenalty(i))
        end
        counts[pc] = counts[pc] - 1
      end
    end
    cur[i] = nil
  end

  rec(1, 0)
  return best, bestCost
end

local function searchWithFallback(prev, aligned, allowed, opts)
  for _, w in ipairs({ 7, 12, 19, 26 }) do
    local best = searchVoicing(prev, aligned, allowed, opts, w)
    if best then return best end
  end
  return nil
end

-- chord info: pitch classes and functions
local function chordInfo(root, chord)
  local rootPC = (root - 1) % 12
  local info = { rootPC = rootPC, pcs = {}, funcOf = {}, funcs = {} }
  for _, iv in ipairs(chordIntervals(chord)) do
    local pc = (rootPC + iv) % 12
    local f = intervalFunction(iv)
    if info.funcOf[pc] == nil then
      info.pcs[#info.pcs + 1] = pc
      info.funcOf[pc] = f
      info.funcs[f] = pc
    end
  end
  info.thirdPC = info.funcs["3"]
  info.fifthPC = info.funcs["5"]
  return info
end

local function leadingTonePC()
  local tonicPC = (currentTonicNote() - 1) % 12
  local lt = (tonicPC + 11) % 12
  if scalePattern and scalePattern[lt + 1] then return lt end
  return nil
end

-- automatic voice leading (free functions, bass set by the inversion)
local function voiceLeadAuto(ref, info, N, inversion, anchor, tags)
  local M = #info.pcs
  local idx = inversion % M
  local bassPC = info.pcs[idx + 1]

  local required = {}
  local dropOrder = { "5", "1", "11", "9", "13", "6", "7" }
  local keep = {}
  for _, pc in ipairs(info.pcs) do keep[pc] = true end
  local count = M
  for _, f in ipairs(dropOrder) do
    if count <= N then break end
    local pc = info.funcs[f]
    if pc and keep[pc] and pc ~= bassPC then keep[pc] = false; count = count - 1 end
  end
  for pc, k in pairs(keep) do if k then required[#required + 1] = pc end end

  local all = {}
  for _, pc in ipairs(info.pcs) do all[pc] = true end
  local allowed = {}
  for i = 1, N do allowed[i] = (i == 1) and { [bassPC] = true } or all end

  local prev, aligned = alignReference(ref, N)
  local tonicPC = (currentTonicNote() - 1) % 12
  return searchWithFallback(prev, aligned, allowed, {
    required = required, funcOf = info.funcOf, leadingPC = leadingTonePC(), coverage = true, anchor = anchor,
    tags = aligned and tags or nil, tonicPC = tonicPC, hasTonic = info.funcOf[tonicPC] ~= nil,
  })
end

-- voice leading of a custom position: the position (order + spacing) is kept,
-- the closest register is chosen (and, optionally, the closest inversion)
local function voiceLeadShape(ref, shape, inversion, anchor, autoInversion)
  local rotations = {}
  if autoInversion then
    for r = 0, #shape - 1 do rotations[#rotations + 1] = r end
  else
    rotations[1] = inversion
  end
  local best, bestCost = nil, math.huge
  for _, r in ipairs(rotations) do
    local rotated = rotateForInversion(shape, r)
    local N = #rotated
    local prev, aligned = alignReference(ref, N)
    for bass = prev[1] - 12, prev[1] + 12 do
      if bass % 12 == rotated[1].pc then
        local cur = { bass }
        for i = 2, N do cur[i] = lowestAtOrAbove(rotated[i].pc, cur[i - 1] + 1) + 12 * rotated[i].jumps end
        if cur[1] >= VL.minPitch and cur[N] <= 115 then
          local c = 0
          for i = 1, N do c = c + math.abs(cur[i] - prev[i]) end
          local d = math.abs(cur[1] - anchor)
          if d > 7 then c = c + (d - 7) * 2 end
          if aligned then
            for i = 2, N do
              for j = 1, i - 1 do
                if cur[i] ~= prev[i] and cur[j] ~= prev[j] then
                  local a = (prev[i] - prev[j]) % 12
                  local b = (cur[i] - cur[j]) % 12
                  if a == b and (a == 0 or a == 7) then c = c + VL.parallel end
                end
              end
            end
          end
          if c < bestCost then bestCost = c; best = cur end
        end
      end
    end
  end
  return best
end

-- pitch shifted by n scale steps
local function diatonicShift(p, n)
  if n == 0 then return p end
  local dir = n > 0 and 1 or -1
  local count, q, guard = 0, p, 0
  while count < math.abs(n) and guard < 48 do
    q = q + dir
    guard = guard + 1
    if noteIsInScale(q + 1) then count = count + 1 end
  end
  return q
end

function applyDoublingToken(pitch, token)
  local kind, n = token:sub(1, 1), tonumber(token:sub(2))
  if not n then return nil end
  if kind == "s" then return pitch + n end
  if kind == "d" then return diatonicShift(pitch, n) end
  return nil
end

------------------------------------------------------------------------------
-- Current chord analysis (voice leading reference)
--   "live" : chord held on the MIDI keyboard > chord sounding under the play cursor
--            > the most recent of last keyboard chord and last ChordMachineGun chord
--   "item" : chord preceding the insertion position in the MIDI item
------------------------------------------------------------------------------

function getReferenceSource() return getValue("vlSource", "live") end
function setReferenceSource(a) setValue("vlSource", a) end
local function getRefSeq() return tonumber(getValue("vlRefSeq", 0)) or 0 end
local function setRefSeq(a) setValue("vlRefSeq", a) end

-- chord recognition (order = priority)
local CHORD_TEMPLATES = {
  { "",        { 0, 4, 7 } },        { "m",       { 0, 3, 7 } },
  { "7",       { 0, 4, 7, 10 } },    { "maj7",    { 0, 4, 7, 11 } },
  { "m7",      { 0, 3, 7, 10 } },    { "m7b5",    { 0, 3, 6, 10 } },
  { "dim7",    { 0, 3, 6, 9 } },     { "dim",     { 0, 3, 6 } },
  { "aug",     { 0, 4, 8 } },        { "sus4",    { 0, 5, 7 } },
  { "sus2",    { 0, 2, 7 } },        { "7sus4",   { 0, 5, 7, 10 } },
  { "6",       { 0, 4, 7, 9 } },     { "m6",      { 0, 3, 7, 9 } },
  { "add9",    { 0, 2, 4, 7 } },     { "m(add9)", { 0, 2, 3, 7 } },
  { "9",       { 0, 2, 4, 7, 10 } }, { "maj9",    { 0, 2, 4, 7, 11 } },
  { "m9",      { 0, 2, 3, 7, 10 } }, { "m(maj7)", { 0, 3, 7, 11 } },
  { "7#5",     { 0, 4, 8, 10 } },    { "7b9",     { 0, 1, 4, 7, 10 } },
  { "6/9",     { 0, 2, 4, 7, 9 } },  { "13",      { 0, 2, 4, 7, 9, 10 } },
  { "maj7#11", { 0, 4, 6, 7, 11 } }, { "m11",     { 0, 2, 3, 5, 7, 10 } },
  { "7",       { 0, 4, 10 } },       { "maj7",    { 0, 4, 11 } },
  { "m7",      { 0, 3, 10 } },       { "9",       { 0, 2, 4, 10 } },
  { "maj9",    { 0, 2, 4, 11 } },    { "m9",      { 0, 2, 3, 10 } },
  { "13",      { 0, 4, 9, 10 } },    { "7b9",     { 0, 1, 4, 10 } },
  { "5",       { 0, 7 } },
  -- v2: colored chords
  { "m(add11)", { 0, 3, 5, 7 } },     { "add11",    { 0, 4, 5, 7 } },
  { "add#11",   { 0, 4, 6, 7 } },     { "m(b6)",    { 0, 3, 7, 8 } },
  { "(b6)",     { 0, 4, 7, 8 } },     { "7sus2",    { 0, 2, 7, 10 } },
  { "maj7sus2", { 0, 2, 7, 11 } },    { "maj7sus4", { 0, 5, 7, 11 } },
  { "9sus4",    { 0, 2, 5, 7, 10 } }, { "m7(11)",   { 0, 3, 5, 7, 10 } },
  { "7(13)",    { 0, 4, 7, 9, 10 } }, { "maj7(13)", { 0, 4, 7, 9, 11 } },
  { "maj9#11",  { 0, 2, 4, 6, 7, 11 } }, { "m6/9",  { 0, 2, 3, 7, 9 } },
  { "9#11",     { 0, 2, 4, 6, 7, 10 } }, { "m7(b6)", { 0, 3, 7, 8, 10 } },
  { "susb2",    { 0, 1, 7 } },        { "5-",       { 0, 6 } },
  { "sus2sus4", { 0, 2, 5, 7 } },     { "m7b5(9)",  { 0, 2, 3, 6, 10 } },
  { "maj7#5",   { 0, 4, 8, 11 } },    { "m13",      { 0, 2, 3, 7, 9, 10 } },
  { "maj13",    { 0, 2, 4, 7, 9, 11 } },
}

-- quality name for an exact pitch-class set with a known root, or nil
function qualityForRoot(rootPC, pcs)
  local set, count = {}, 0
  for _, pc in ipairs(pcs) do
    local r = (pc - rootPC) % 12
    if not set[r] then set[r] = true; count = count + 1 end
  end
  for _, tpl in ipairs(CHORD_TEMPLATES) do
    if #tpl[2] == count then
      local ok = true
      for _, iv in ipairs(tpl[2]) do if not set[iv] then ok = false; break end end
      if ok then return tpl[1] end
    end
  end
  return nil
end

function identifyChord(pitches)
  if not pitches or #pitches == 0 then return nil end
  local sorted = copyTable(pitches)
  table.sort(sorted)
  local set, pcs = {}, {}
  for _, p in ipairs(sorted) do
    local pc = p % 12
    if not set[pc] then set[pc] = true; pcs[#pcs + 1] = pc end
  end
  local bassPC = sorted[1] % 12
  local best, bestScore = nil, -math.huge
  for ti, tpl in ipairs(CHORD_TEMPLATES) do
    if #tpl[2] == #pcs then
      for _, r in ipairs(pcs) do
        local ok = true
        for _, iv in ipairs(tpl[2]) do
          if not set[(r + iv) % 12] then ok = false; break end
        end
        if ok then
          local score = -ti + ((r == bassPC) and 100 or 0)
          if score > bestScore then bestScore = score; best = { rootPC = r, quality = tpl[1] } end
        end
      end
    end
  end
  local result = { bassPC = bassPC, pitches = sorted }
  if best then
    result.rootPC, result.quality = best.rootPC, best.quality
    result.name = getNoteName(best.rootPC + 1) .. best.quality
    if bassPC ~= best.rootPC then result.name = result.name .. "/" .. getNoteName(bassPC + 1) end
  else
    local t = {}
    for _, pc in ipairs(pcs) do t[#t + 1] = getNoteName(pc + 1) end
    result.name = table.concat(t, "-")
  end
  return result
end

-- functions used for resolution: "7" (seventh), "L" (leading tone as chord third)
function tagsFromPitches(pitches)
  local id = identifyChord(pitches)
  local tags = {}
  local lt = (function()
    local tonicPC = (currentTonicNote() - 1) % 12
    local l = (tonicPC + 11) % 12
    if scalePattern and scalePattern[l + 1] then return l end
  end)()
  for i, p in ipairs(pitches) do
    tags[i] = ""
    if id and id.rootPC then
      local iv = (p % 12 - id.rootPC) % 12
      if iv == 10 or iv == 11 or (id.quality == "dim7" and iv == 9) then tags[i] = "7"
      elseif lt and p % 12 == lt and iv == 4 then tags[i] = "L" end
    end
  end
  return tags
end

-- REAPER MIDI input history: last chord played / held on the keyboard
local function isIgnoredDevice(dev)
  if not dev then return false end
  dev = math.floor(dev)
  if dev & 0x10000 ~= 0 then return true end       -- device in control-only mode
  return (dev & 0xFFFF) == 62                       -- virtual keyboard (ChordMachineGun previews)
end

function scanKeyboardChord()
  if not reaper.MIDI_GetRecentInputEvent then return nil end
  local events = {}
  for idx = 0, 511 do
    local seq, buf, _, dev = reaper.MIDI_GetRecentInputEvent(idx)
    if not seq or seq == 0 or type(buf) ~= "string" then break end
    events[#events + 1] = { seq = seq, buf = buf, dev = dev }
  end
  local info = { latestSeq = events[1] and events[1].seq or 0, seq = 0, heldNow = false }
  local held, heldCount = {}, 0
  local bestCount = 0
  for i = #events, 1, -1 do
    local e = events[i]
    if #e.buf >= 3 and not isIgnoredDevice(e.dev) then
      local status, note, vel = e.buf:byte(1) & 0xF0, e.buf:byte(2), e.buf:byte(3)
      if status == 0x90 and vel > 0 then
        if heldCount == 0 then bestCount = 0 end     -- new episode
        if not held[note] then held[note] = true; heldCount = heldCount + 1 end
        if heldCount >= 2 and heldCount >= bestCount then
          local t = {}
          for n in pairs(held) do t[#t + 1] = n end
          table.sort(t)
          info.pitches, info.seq, bestCount = t, e.seq, heldCount
        end
      elseif status == 0x80 or (status == 0x90 and vel == 0) then
        if held[note] then held[note] = nil; heldCount = heldCount - 1 end
      end
    end
  end
  if heldCount >= 2 then
    local t = {}
    for n in pairs(held) do t[#t + 1] = n end
    table.sort(t)
    info.held, info.heldNow = t, true
  end
  return info
end

local function latestInputSeq()
  if not reaper.MIDI_GetRecentInputEvent then return 0 end
  local seq = reaper.MIDI_GetRecentInputEvent(0)
  return tonumber(seq) or 0
end

-- notes of a chord in a take: "sounding" = sounding at ppq; "before" = chord before ppq
local CHORD_WINDOW_PPQ = 40
function chordNotesInTake(take, ppq, mode)
  local _, n = reaper.MIDI_CountEvts(take)
  n = n or 0
  local all = {}
  local latest = nil
  for i = 0, n - 1 do
    local _, _, mute, s, e, chan, pitch = reaper.MIDI_GetNote(take, i)
    if not mute then
      if mode == "sounding" then
        if s <= ppq + 1 and e > ppq + 1 then all[#all + 1] = { pitch = pitch, chan = chan } end
      elseif s < ppq - 1 then
        all[#all + 1] = { pitch = pitch, chan = chan, s = s }
        if latest == nil or s > latest then latest = s end
      end
    end
  end
  if mode == "sounding" then return all end
  if latest == nil then return {} end
  local out = {}
  for _, x in ipairs(all) do
    if x.s >= latest - CHORD_WINDOW_PPQ then out[#out + 1] = x end
  end
  return out
end

-- removes the separate bass and ChordMachineGun doublings to recover the chord voices
function voicesFromNotes(list)
  list = stripDrones(list)
  local pitches = {}
  local nv = math.max(#getLastVoices(), 2)
  if voicesHaveDistinctChannels(nv) then
    local doublings = getDoublings()
    local voiceOfChan = {}
    for v = 1, 16 do local c = voiceChannel(v); if c and not voiceOfChan[c] then voiceOfChan[c] = v end end
    local byChan = {}
    for _, x in ipairs(list) do
      byChan[x.chan] = byChan[x.chan] or {}
      table.insert(byChan[x.chan], x.pitch)
    end
    local skip = (getBassMode() == "root") and voiceChannel(1) or -1
    for ch, ps in pairs(byChan) do
      if ch ~= skip then
        table.sort(ps)
        local voice = voiceOfChan[ch] or 0
        local base = ps[1]
        for _, cand in ipairs(ps) do
          local ok = true
          for _, q in ipairs(ps) do
            if q ~= cand then
              local found = false
              for _, tok in ipairs(doublings[voice] or {}) do
                if applyDoublingToken(cand, tok) == q then found = true; break end
              end
              if not found then ok = false; break end
            end
          end
          if ok then base = cand; break end
        end
        pitches[#pitches + 1] = base
      end
    end
  else
    -- shared channels: drop the separate bass (if on its own channel) and doubled octaves
    local bassChan = (getBassMode() == "root") and voiceChannel(1) or nil
    local shared = false
    for v = 2, nv do if voiceChannel(v) == bassChan then shared = true end end
    local seen, pcSeen = {}, {}
    table.sort(list, function(a, b) return a.pitch < b.pitch end)
    for _, x in ipairs(list) do
      if not (bassChan and not shared and x.chan == bassChan) and not seen[x.pitch] then
        seen[x.pitch] = true
        pitches[#pitches + 1] = x.pitch
      end
    end
    -- too many notes for the voice count: drop known doublings (highest first)
    local expected = #getLastVoices()
    if bassChan and not shared then expected = expected - 1 end
    if expected >= 2 and #pitches > expected then
      local tokens = {}
      for _, l in pairs(getDoublings()) do for _, tok in ipairs(l) do tokens[#tokens + 1] = tok end end
      table.sort(pitches)
      for k = #pitches, 2, -1 do
        if #pitches <= expected then break end
        local q = pitches[k]
        for j = 1, k - 1 do
          local derived = false
          for _, tok in ipairs(tokens) do
            if applyDoublingToken(pitches[j], tok) == q then derived = true; break end
          end
          if derived then table.remove(pitches, k); break end
        end
      end
    end
  end
  table.sort(pitches)
  return pitches
end

local function makeExternalRef(pitches, source)
  local p = stripDrones(copyTable(pitches))
  if #p == 0 then return nil end
  table.sort(p)
  while #p > 8 do table.remove(p, 1) end
  return { pitches = p, tags = tagsFromPitches(p), source = source, external = true }
end

-- positionPPQ: insertion position (item mode); nil = edit cursor
function resolveReference(positionPPQ)
  if not getVoiceLeadingEnabled() then return nil end
  local source = getReferenceSource()
  local take = activeTake()

  if source == "item" and take then
    local list = chordNotesInTake(take, positionPPQ or getCursorPositionPPQ(), "before")
    if #list >= 1 then
      local p = voicesFromNotes(list)
      if #p >= 2 then local r = makeExternalRef(p, "item"); if r then return r end end
    end
  end

  if source == "live" then
    local kb = scanKeyboardChord()
    if kb and kb.heldNow then local r = makeExternalRef(kb.held, "keyboard"); if r then return r end end
    if take and reaper.GetPlayState() & 1 == 1 then
      local ppq = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.GetPlayPosition())
      local list = chordNotesInTake(take, ppq, "sounding")
      if #list >= 2 then
        local p = voicesFromNotes(list)
        if #p >= 2 then local r = makeExternalRef(p, "playback"); if r then return r end end
      end
    end
    if kb and kb.pitches and kb.seq > getRefSeq() then local r = makeExternalRef(kb.pitches, "keyboard"); if r then return r end end
  end

  local mem = getVoiceLeadingReference()
  if #mem > 0 then return { pitches = mem, tags = getVoiceLeadingReferenceTags(), source = "chordgun" } end
  return nil
end

local SOURCE_LABELS = { keyboard = "MIDI keyboard", playback = "playback", chordgun = "last chord", item = "MIDI item" }

-- for display: { name, notes, source, live }
function describeCurrentReference()
  local ref = resolveReference(nil)
  if not ref then return nil end
  local id = identifyChord(ref.pitches)
  local t = {}
  for _, p in ipairs(ref.pitches) do t[#t + 1] = getPitchName(p) end
  return {
    name = id and id.name or "",
    notes = table.concat(t, " "),
    source = SOURCE_LABELS[ref.source] or ref.source,
    live = (ref.source == "keyboard" or ref.source == "playback"),
  }
end


------------------------------------------------------------------------------
-- Colors (v2): tones added to whatever chord is played, taken from the current scale
--   "7" "9" "11" "13"  stack scale thirds on top of the chord
--   "sus2" "sus4" "no3" replace or remove the third (mutually exclusive)
-- Harsh clashes are softened automatically: b9 becomes 9, and an 11 over a major
-- third becomes #11.
------------------------------------------------------------------------------

COLOR_NAMES = { "7", "9", "11", "13", "sus2", "sus4", "no3" }

function getColors()
  local set = {}
  for m in getValue("colors", ""):gmatch("([^,]+)") do set[m] = true end
  return set
end

local function saveColors(set)
  local t = {}
  for _, n in ipairs(COLOR_NAMES) do if set[n] then t[#t + 1] = n end end
  setValue("colors", table.concat(t, ","))
end

function toggleColor(name)
  local set = getColors()
  local on = not set[name]
  if on and (name == "sus2" or name == "sus4" or name == "no3") then
    set["sus2"], set["sus4"], set["no3"] = nil, nil, nil
  end
  set[name] = on or nil
  saveColors(set)
  return on
end

function clearColors() setValue("colors", "") end

function colorsActive() return getValue("colors", "") ~= "" end

-- interval (semitones) of the nth scale step above rootPC in the current scale, or nil
local function scaleStepAbove(rootPC, steps)
  if not scalePattern or not scalePattern[rootPC + 1] then return nil end
  local rel = {}
  for pc = 0, 11 do
    if scalePattern[((rootPC + pc) % 12) + 1] then rel[#rel + 1] = pc end
  end
  if #rel ~= 7 then return nil end
  return rel[steps + 1]
end

-- returns the chord with colors applied (a new table) and the list of color labels
function applyColors(root, chord)
  local colors = getColors()
  if next(colors) == nil then return chord, {} end
  local rootPC = (root - 1) % 12
  local has = {}
  local p = chord.pattern
  for n = 0, #p - 1 do if p:sub(n + 1, n + 1) == '1' then has[n] = true end end

  local labels = {}
  local third = (has[4] and 4) or (has[3] and 3) or nil

  if colors["no3"] and third then
    has[third] = nil; third = nil
    labels[#labels + 1] = "no3"
  elseif colors["sus2"] and third then
    has[third] = nil; third = nil
    local iv = scaleStepAbove(rootPC, 1) or 2
    if iv ~= 1 and iv ~= 2 then iv = 2 end
    has[iv] = true
    labels[#labels + 1] = (iv == 1) and "susb2" or "sus2"
  elseif colors["sus4"] and third then
    has[third] = nil; third = nil
    has[5] = true
    labels[#labels + 1] = "sus4"
  end

  local majorThird = (third == 4)
  local minorish = (third == 3)

  if colors["7"] and not (has[10] or has[11]) then
    local iv = scaleStepAbove(rootPC, 6)
    if iv ~= 9 and iv ~= 10 and iv ~= 11 then iv = majorThird and 11 or 10 end
    if not has[iv] then
      has[iv] = true
      labels[#labels + 1] = (iv == 11) and "maj7" or (iv == 9 and "dim7" or "7")
    end
  end
  if colors["9"] then
    local iv = scaleStepAbove(rootPC, 1) or 2
    if iv ~= 2 then iv = 2 end                       -- b9 → 9
    if not has[iv] then has[12 + iv] = true; labels[#labels + 1] = "9" end
  end
  if colors["11"] then
    local iv = scaleStepAbove(rootPC, 3) or 5
    if iv ~= 5 and iv ~= 6 then iv = 5 end
    if iv == 5 and majorThird then iv = 6 end        -- 11 over a major third → #11
    if not has[iv] then has[12 + iv] = true; labels[#labels + 1] = (iv == 6) and "#11" or "11" end
  end
  if colors["13"] and not has[9] then
    local iv = scaleStepAbove(rootPC, 5) or (minorish and 8 or 9)
    if iv ~= 8 and iv ~= 9 then iv = 9 end
    if not has[iv] then has[12 + iv] = true; labels[#labels + 1] = (iv == 8) and "b13" or "13" end
  end

  if #labels == 0 then return chord, {} end

  local bits, pcs = {}, {}
  for n = 0, 23 do
    bits[n + 1] = has[n] and '1' or '0'
    if has[n] then pcs[#pcs + 1] = (rootPC + n) % 12 end
  end
  local quality = qualityForRoot(rootPC, pcs)
  local display = quality
  if not display then
    local base, rest = chord.display, labels
    if not third and labels[1] and (labels[1]:find("^sus") or labels[1] == "no3") then
      -- the third is gone: "m" no longer applies
      base = (chord.display == "m" or chord.display == "") and "" or chord.display
      if labels[1] ~= "no3" and base == "" then
        base = labels[1]
        rest = {}
        for k = 2, #labels do rest[#rest + 1] = labels[k] end
      end
    end
    display = base .. ((#rest > 0) and ("(" .. table.concat(rest, ",") .. ")") or "")
  end
  return { name = chord.name, code = chord.code, display = display,
           pattern = table.concat(bits):gsub("0+$", ""), base = chord }, labels
end

--[[ Builds the full voicing of the selected chord.
  Retour :
    {
      upper  = {pitches}       chord structure (voice leading reference)
      voices = {pitches}       base voices (separate bass included in root mode)
      notes  = { {pitch=, chan=, voice=}, ... }   notes actually played/inserted
      name, error
    }
]]
-- refInfo: explicit reference, false = none, nil = resolved automatically
function buildChordVoicing(scaleNoteIndex, chordTypeIndex, refInfo)
  local root = scaleNotes[scaleNoteIndex]
  local chord = applyColors(root, scaleChords[scaleNoteIndex][chordTypeIndex])
  local octave = getOctave()
  local inversion = borrowContext and 0 or getChordInversionState(scaleNoteIndex)
  local info = chordInfo(root, chord)
  local rootPitch = root + ((octave + 1) * 12) - 1

  if refInfo == nil then refInfo = resolveReference(nil) end
  local ref = (refInfo and refInfo.pitches) or {}
  local refTags = (refInfo and refInfo.tags) or {}
  local useRef = getVoiceLeadingEnabled() and #ref >= 1
  -- register: the analysed chord's if external, otherwise the chosen octave
  local anchor = (refInfo and refInfo.external) and ref[1] or rootPitch
  local N = getVoiceCount()
  local result = { root = root, chord = chord }

  local V
  if getCustomPositionEnabled() then
    local shape, err = parseCustomPosition(getCustomPosition(), info.rootPC, chord, scaleNoteIndex)
    if shape then
      if useRef then V = voiceLeadShape(ref, shape, inversion, anchor, getAutoInversion()) end
      if not V then V = stackShape(rootPitch, shape, inversion) end
    else
      result.error = err
    end
  end

  if not V then
    if useRef then
      -- auto: at least one voice per chord tone (so colors are heard), at most 4 inherited
      local n = (N > 0) and N or math.max(#info.pcs, math.min(#ref, 4))
      if n < 2 then n = #info.pcs end
      V = voiceLeadAuto(ref, info, n, inversion, anchor, refTags)
    end
    if not V then
      V = getChordNotesArray(root, chord, octave, inversion)
      if N > 0 then V = fitVoiceCount(V, N, info) end
    end
  end

  table.sort(V)
  result.upper = V
  local lt = leadingTonePC()
  result.tags = {}
  for i, p in ipairs(V) do
    local f = info.funcOf[p % 12]
    if f == "7" then result.tags[i] = "7"
    elseif lt and p % 12 == lt and f == "3" then result.tags[i] = "L"
    else result.tags[i] = "" end
  end

  -- bass voice
  local voices = {}
  if getBassMode() == "root" then
    local bass = V[1] - ((V[1] - info.rootPC) % 12)   -- highest root <= lowest voice
    if bass >= V[1] then bass = bass - 12 end
    voices[1] = bass
    for i, p in ipairs(V) do voices[i + 1] = p end
  else
    voices = copyTable(V)
  end
  result.voices = voices

  -- final notes: voices + doublings, channels
  local doublings = getDoublings()
  local seen = {}
  local out = {}
  local function add(p, v)
    if p < 0 or p > 127 then return end
    local chan = voiceChannel(v)
    local key = p .. ":" .. tostring(chan)
    if seen[key] then return end
    seen[key] = true
    out[#out + 1] = { pitch = p, chan = chan, voice = v }
  end
  -- drone first: a chord note on the same pitch and channel merges into the drone
  -- (so a held drone is never cut by the next chord's note-off)
  for _, n in ipairs(getDroneNotes()) do
    local key = n.pitch .. ":" .. tostring(n.chan)
    if not seen[key] then seen[key] = true; out[#out + 1] = n end
  end
  for v, p in ipairs(voices) do
    add(p, v)
    for _, tok in ipairs(doublings[v] or {}) do
      local q = applyDoublingToken(p, tok)
      if q then add(q, v) end
    end
  end
  table.sort(out, function(a, b) return a.pitch < b.pitch end)
  result.notes = out

  -- chord name
  result.refSource = refInfo and refInfo.source or nil
  local rootName = (borrowContext and borrowContext.names and borrowContext.names[scaleNoteIndex]) or noteNameInContext(root)
  local name = rootName .. chord.display
  local lowestPC = voices[1] % 12
  if lowestPC ~= info.rootPC then name = name .. "/" .. noteNameInContext(voices[1] + 1) end
  if borrowContext then
    if borrowContext.isNeighbors then
      result.borrowLabel = borrowContext.describe or ("from " .. borrowContext.label)
    else
      result.borrowLabel = (borrowContext.headers[scaleNoteIndex] or "?") .. " of " .. borrowContext.label
    end
  end
  result.name = name
  return result
end

local function voicingNotesText(result)
  local t = {}
  for _, p in ipairs(result.voices) do t[#t + 1] = getPitchName(p) end
  return table.concat(t, "  ")
end

function updateChordDisplay(result)
  setChordText(result.borrowLabel and (result.name .. "   ·  " .. result.borrowLabel) or result.name)
  setChordNotesText(voicingNotesText(result))
  setLastVoices(result.voices)
  local vn = {}
  for i, p in ipairs(result.voices) do vn[i] = getPitchName(p) end
  setValue("lastVoiceNames", table.concat(vn, ","))
  local status = result.name .. "    " .. voicingNotesText(result)
  if result.error then status = status .. "    (position: " .. result.error .. ")" end
  reaper.Help_Set(status, false)
end

function showChordText() reaper.Help_Set(getChordText() .. "    " .. getChordNotesText(), false) end

-- every chord played by ChordMachineGun becomes the "memory" reference; chords
-- played on the keyboard before that moment are then considered older
local function commitReference(result)
  if not getVoiceLeadingEnabled() then return end
  setVoiceLeadingReference(result.upper, result.tags)
  setRefSeq(latestInputSeq())
end

function resetVoiceLeadingReference()
  clearVoiceLeadingReference()
  setRefSeq(latestInputSeq())
end

function setReferenceFromSelectedNotes()
  if activeTake() == nil then return false end
  local earliest = nil
  local list = {}
  for i = 0, getNumberOfNotes() - 1 do
    local _, sel, _, sppq, _, chan, pitch = reaper.MIDI_GetNote(activeTake(), i)
    if sel then
      if earliest == nil or sppq < earliest - 0.5 then earliest = sppq; list = {} end
      if math.abs(sppq - earliest) < 0.5 then list[#list + 1] = { pitch = pitch, chan = chan } end
    end
  end
  if #list == 0 then return false end
  local pitches = {}
  pitches = voicesFromNotes(list)
  setVoiceLeadingReference(pitches, tagsFromPitches(pitches))
  setRefSeq(latestInputSeq())
  return true
end

------------------------------------------------------------------------------
-- Insertion
------------------------------------------------------------------------------

SelectedNote = {}
SelectedNote.__index = SelectedNote
function SelectedNote:new(endPosition, velocity, channel, muteState, pitch)
  return setmetatable({ endPosition = endPosition, velocity = velocity, channel = channel, muteState = muteState, pitch = pitch }, SelectedNote)
end

SelectedChord = {}
SelectedChord.__index = SelectedChord
function SelectedChord:new(startPosition, endPosition, velocity, channel, muteState, pitch)
  local self = setmetatable({ startPosition = startPosition, longestEndPosition = endPosition, selectedNotes = {} }, SelectedChord)
  table.insert(self.selectedNotes, SelectedNote:new(endPosition, velocity, channel, muteState, pitch))
  return self
end

local function getSelectedChords()
  local chordsAt = {}
  local list = {}
  for i = 0, getNumberOfNotes() - 1 do
    local _, sel, mute, sppq, eppq, chan, pitch, vel = reaper.MIDI_GetNote(activeTake(), i)
    if sel then
      local c = chordsAt[sppq]
      if not c then
        c = SelectedChord:new(sppq, eppq, vel, chan, mute, pitch)
        chordsAt[sppq] = c
        list[#list + 1] = c
      else
        table.insert(c.selectedNotes, SelectedNote:new(eppq, vel, chan, mute, pitch))
        if eppq > c.longestEndPosition then c.longestEndPosition = eppq end
      end
    end
  end
  table.sort(list, function(a, b) return a.startPosition < b.startPosition end)
  for _, c in ipairs(list) do
    table.sort(c.selectedNotes, function(a, b) return a.pitch < b.pitch end)
  end
  return list
end

local function deleteSelectedNotes()
  for i = getNumberOfNotes() - 1, 0, -1 do
    local _, sel = reaper.MIDI_GetNote(activeTake(), i)
    if sel then deleteNote(i) end
  end
end

local function setEditCursorTo(ppq)
  setEditCursorPosition(reaper.MIDI_GetProjTimeFromPPQPos(activeTake(), ppq))
end

-- note = { pitch=, chan= }; chan nil => default channel / channel of the replaced note
function insertMidiNote(note, keepNotesSelected, selectedChord, noteIndex)
  local startPosition = getCursorPositionPPQ()
  local endPosition, velocity, channel, muteState
  if keepNotesSelected then
    local n = #selectedChord.selectedNotes
    local src = selectedChord.selectedNotes[math.min(noteIndex, n)]
    endPosition, velocity, channel, muteState = src.endPosition, src.velocity, src.channel, src.muteState
  else
    endPosition = getMidiEndPositionPPQ()
    velocity = getCurrentVelocity()
    channel = getCurrentNoteChannel()
    muteState = false
  end
  if type(note) == "table" then
    if note.chan ~= nil then channel = note.chan end
    note = note.pitch
  end
  reaper.MIDI_InsertNote(activeTake(), keepNotesSelected, muteState, startPosition, endPosition, channel, note, velocity, false)
end


------------------------------------------------------------------------------
-- Insert patterns (v2): how a chord is written into the item
--   block: plain chord · up / down / updown: arpeggios · alberti: low-high-mid-high
--   basschord: bass then chord · pulse: repeated chord
-- The drone (and the bass, with "hold bass") is written as one long note.
-- Preview always plays the plain chord.
------------------------------------------------------------------------------

PATTERNS = {
  { id = "block",     name = "Block chord" },
  { id = "up",        name = "Arp up" },
  { id = "down",      name = "Arp down" },
  { id = "updown",    name = "Arp up-down" },
  { id = "alberti",   name = "Alberti" },
  { id = "basschord", name = "Bass / chord" },
  { id = "pulse",     name = "Pulse" },
}

RATES = {
  { id = "4",   name = "1/4",   qn = 1 },
  { id = "8",   name = "1/8",   qn = 1 / 2 },
  { id = "8T",  name = "1/8T",  qn = 1 / 3 },
  { id = "16",  name = "1/16",  qn = 1 / 4 },
  { id = "16T", name = "1/16T", qn = 1 / 6 },
}

function getPattern() return getValue("pattern", "block") end
function setPattern(a) setValue("pattern", a) end
function getPatternRate() return getValue("patternRate", "8") end
function setPatternRate(a) setValue("patternRate", a) end
function getPatternHoldBass() return getBool("patternHoldBass", false) end
function setPatternHoldBass(a) setBool("patternHoldBass", a) end

function cyclePattern(d)
  local cur = getPattern()
  local idx = 1
  for k, pt in ipairs(PATTERNS) do if pt.id == cur then idx = k end end
  idx = ((idx - 1 + d) % #PATTERNS) + 1
  setPattern(PATTERNS[idx].id)
  return PATTERNS[idx]
end

local function rateQN()
  local id = getPatternRate()
  for _, r in ipairs(RATES) do if r.id == id then return r.qn end end
  return 0.5
end

-- order of note indexes (1 = lowest) for one cycle of an arpeggio over n notes
local function patternCycle(pattern, n)
  local seq = {}
  if pattern == "down" then
    for k = n, 1, -1 do seq[#seq + 1] = { k } end
  elseif pattern == "updown" then
    for k = 1, n do seq[#seq + 1] = { k } end
    for k = n - 1, 2, -1 do seq[#seq + 1] = { k } end
  elseif pattern == "alberti" then
    if n <= 2 then
      for k = 1, n do seq[#seq + 1] = { k } end
    else
      seq[#seq + 1] = { 1 }; seq[#seq + 1] = { n }
      for k = 2, n - 1 do seq[#seq + 1] = { k }; seq[#seq + 1] = { n } end
    end
  elseif pattern == "basschord" then
    local upper = {}
    for k = 2, n do upper[#upper + 1] = k end
    seq[#seq + 1] = { 1 }
    seq[#seq + 1] = (#upper > 0) and upper or { 1 }
  elseif pattern == "pulse" then
    local all = {}
    for k = 1, n do all[k] = k end
    seq[#seq + 1] = all
  else -- up
    for k = 1, n do seq[#seq + 1] = { k } end
  end
  return seq
end

-- writes noteList as a pattern between the edit cursor and cursor + chord length
function insertPatternNotes(noteList)
  local take = activeTake()
  local startPPQ = getCursorPositionPPQ()
  local endPPQ = getMidiEndPositionPPQ()
  local velocity = getCurrentVelocity()
  local defaultChan = getCurrentNoteChannel()
  local pattern = getPattern()

  local long, moving = {}, {}
  for _, n in ipairs(noteList) do
    if n.drone or n.voice == 0 then long[#long + 1] = n else moving[#moving + 1] = n end
  end
  table.sort(moving, function(a, b) return a.pitch < b.pitch end)
  if getPatternHoldBass() and #moving > 1 then
    -- the bass voice (and its doublings) is held; the rest moves
    local bassVoice = moving[1].voice
    local rest = {}
    for _, n in ipairs(moving) do
      if n.voice == bassVoice then long[#long + 1] = n else rest[#rest + 1] = n end
    end
    if #rest > 0 then moving = rest end
  end

  for _, n in ipairs(long) do
    reaper.MIDI_InsertNote(take, false, false, startPPQ, endPPQ, n.chan or defaultChan, n.pitch, velocity, true)
  end

  local startQN = reaper.MIDI_GetProjQNFromPPQPos(take, startPPQ)
  local step = rateQN()
  local cycle = patternCycle(pattern, #moving)
  local k = 0
  while #moving > 0 do
    local a = reaper.MIDI_GetPPQPosFromProjQN(take, startQN + k * step)
    if a >= endPPQ - 1 then break end
    local b = math.min(endPPQ, reaper.MIDI_GetPPQPosFromProjQN(take, startQN + (k + 1) * step))
    local onBeat = math.abs((k * step) - math.floor(k * step + 0.5)) < 0.001
    local vel = onBeat and velocity or math.max(1, math.floor(velocity * 0.8 + 0.5))
    for _, idx in ipairs(cycle[(k % #cycle) + 1]) do
      local n = moving[idx]
      if n then reaper.MIDI_InsertNote(take, false, false, a, b, n.chan or defaultChan, n.pitch, vel, true) end
    end
    k = k + 1
    if k > 4096 then break end
  end
  reaper.MIDI_Sort(take)
end

function insertScaleChord(noteList, keepNotesSelected, selectedChord)
  deleteExistingNotesInNextInsertionTimePeriod(keepNotesSelected, selectedChord)
  if not keepNotesSelected and getPattern() ~= "block" then
    insertPatternNotes(noteList)
  else
    for i, n in ipairs(noteList) do insertMidiNote(n, keepNotesSelected, selectedChord, i) end
  end
  moveCursor(keepNotesSelected, selectedChord)
end

-- replaces each selected chord; each one is voice-led from the previous one
function changeSelectedNotesToScaleChords(scaleNoteIndex, chordTypeIndex)
  local selectedChords = getSelectedChords()
  deleteSelectedNotes()
  local prev = nil
  for _, c in ipairs(selectedChords) do
    local ref = nil
    if getVoiceLeadingEnabled() then
      if getReferenceSource() == "item" then
        ref = resolveReference(c.startPosition)
      elseif prev then
        ref = { pitches = prev.upper, tags = prev.tags, source = "chordgun" }
      end
    end
    local result = buildChordVoicing(scaleNoteIndex, chordTypeIndex, ref)
    setEditCursorTo(c.startPosition)
    insertScaleChord(result.notes, true, c)
    prev = result
  end
  return prev
end

local function playScaleChord(noteList)
  stopNotesFromPlaying()
  local hold = getDroneEnabled() and getDroneHold()
  local held = {}
  if hold then
    for _, d in ipairs(getDroneNotes()) do held[d.pitch .. ":" .. (d.chan or getCurrentNoteChannel())] = true end
  end
  local played = {}
  for _, n in ipairs(noteList) do
    local isDrone = n.drone or n.voice == 0
    local onHeld = held[n.pitch .. ":" .. (n.chan or getCurrentNoteChannel())]
    if not (hold and (isDrone or onHeld)) then
      playMidiNote(n.pitch, n.chan)
      played[#played + 1] = n
    end
  end
  if hold and #getDroneNotes() > 0 then startDrone() end
  setNotesThatArePlaying(played)
end

function previewScaleChord()
  local i = getSelectedScaleNote()
  return previewChord(i, getSelectedChordType(i))
end

function previewChord(i, t)
  local result = buildChordVoicing(i, t)
  playScaleChord(result.notes)
  updateChordDisplay(result)
  commitReference(result)
  addToHistory(result, false)
  return result
end

function playOrInsertScaleChord(actionDescription)
  local i = getSelectedScaleNote()
  return playOrInsertChord(i, getSelectedChordType(i), actionDescription)
end

function playOrInsertChord(i, t, actionDescription)
  local result
  if activeTake() ~= nil and notCurrentlyRecording() then
    startUndoBlock()
    if thereAreNotesSelected() then
      result = changeSelectedNotesToScaleChords(i, t)
    else
      result = buildChordVoicing(i, t)
      insertScaleChord(result.notes, false)
    end
    endUndoBlock(actionDescription)
  end
  local inserted = result ~= nil
  result = result or buildChordVoicing(i, t)
  playScaleChord(result.notes)
  updateChordDisplay(result)
  commitReference(result)
  addToHistory(result, inserted)
  return result
end

-- single notes (unchanged)
local function playScaleNote(noteValue)
  stopNotesFromPlaying()
  playMidiNote(noteValue)
  setNotesThatArePlaying({ { pitch = noteValue } })
  setChordText("")
  setChordNotesText(getPitchName(noteValue))
end

function insertScaleNote(noteValue, keepNotesSelected, selectedChord)
  deleteExistingNotesInNextInsertionTimePeriod(keepNotesSelected, selectedChord)
  insertMidiNote(noteValue, keepNotesSelected, selectedChord, 1)
  moveCursor(keepNotesSelected, selectedChord)
end

function changeSelectedNotesToScaleNotes(noteValue)
  local selectedChords = getSelectedChords()
  deleteSelectedNotes()
  for _, c in ipairs(selectedChords) do
    setEditCursorTo(c.startPosition)
    insertScaleNote(noteValue, true, c)
  end
end

function previewScaleNote(octaveAdjustment)
  local root = scaleNotes[getSelectedScaleNote()]
  playScaleNote(root + ((getOctave() + 1 + octaveAdjustment) * 12) - 1)
end

function playOrInsertScaleNote(octaveAdjustment, actionDescription)
  local root = scaleNotes[getSelectedScaleNote()]
  local noteValue = root + ((getOctave() + 1 + octaveAdjustment) * 12) - 1
  if activeTake() ~= nil and notCurrentlyRecording() then
    startUndoBlock()
    if thereAreNotesSelected() then changeSelectedNotesToScaleNotes(noteValue) else insertScaleNote(noteValue, false) end
    endUndoBlock(actionDescription)
  end
  playScaleNote(noteValue)
end

local function transposeSelectedNotes(semitones)
  for i = getNumberOfNotes() - 1, 0, -1 do
    local _, sel, mute, sppq, eppq, chan, pitch, vel = reaper.MIDI_GetNote(activeTake(), i)
    if sel then
      deleteNote(i)
      reaper.MIDI_InsertNote(activeTake(), sel, mute, sppq, eppq, chan, pitch + semitones, vel, false)
    end
  end
end

function transposeSelectedNotesUpOneOctave() transposeSelectedNotes(12) end
function transposeSelectedNotesDownOneOctave() transposeSelectedNotes(-12) end

local function shiftReference(semitones)
  local ref = getVoiceLeadingReference()
  if #ref == 0 then return end
  for i = 1, #ref do ref[i] = ref[i] + semitones end
  setVoiceLeadingReference(ref)
end

------------------------------------------------------------------------------
-- Actions (same names as the original)
------------------------------------------------------------------------------

local function previewOrApply(actionDescription)
  if thereAreNotesSelected() then playOrInsertScaleChord(actionDescription) else previewScaleChord() end
end

function decrementChordInversion()
  local s = getSelectedScaleNote()
  local v = getChordInversionState(s)
  if v > getChordInversionMin() then setChordInversionState(s, v - 1) end
end

function incrementChordInversion()
  local s = getSelectedScaleNote()
  local v = getChordInversionState(s)
  if v < getChordInversionMax() then setChordInversionState(s, v + 1) end
end

function decrementChordInversionAction() decrementChordInversion(); previewOrApply("decrement chord inversion") end
function incrementChordInversionAction() incrementChordInversion(); previewOrApply("increment chord inversion") end

function decrementChordTypeAction()
  local s = getSelectedScaleNote()
  local t = getSelectedChordType(s)
  if t > 1 then setSelectedChordType(s, t - 1) end
  previewOrApply("decrement chord type")
end

function incrementChordTypeAction()
  local s = getSelectedScaleNote()
  local t = getSelectedChordType(s)
  if t < #chords then setSelectedChordType(s, t + 1) end
  previewOrApply("increment chord type")
end

function playTonicNote()
  local noteValue = scaleNotes[1] + ((getOctave() + 1) * 12) - 1
  stopNotesFromPlaying()
  playMidiNote(noteValue)
  setNotesThatArePlaying({ { pitch = noteValue } })
end

function decrementOctaveAction()
  if getOctave() <= getOctaveMin() then return end
  setOctave(getOctave() - 1)
  shiftReference(-12)
  if thereAreNotesSelected() then
    startUndoBlock(); transposeSelectedNotesDownOneOctave(); endUndoBlock("decrement octave")
  else
    playTonicNote()
  end
end

function incrementOctaveAction()
  if getOctave() >= getOctaveMax() then return end
  setOctave(getOctave() + 1)
  shiftReference(12)
  if thereAreNotesSelected() then
    startUndoBlock(); transposeSelectedNotesUpOneOctave(); endUndoBlock("increment octave")
  else
    playTonicNote()
  end
end

local function afterScaleChange()
  setSelectedScaleNote(1)
  setChordText("")
  setChordNotesText("")
  resetSelectedChordTypes()
  resetChordInversionStates()
  updateScaleData()
  showScaleStatus()
end

function decrementScaleTonicNoteAction()
  if getScaleTonicNote() > 1 then setScaleTonicNote(getScaleTonicNote() - 1) end
  afterScaleChange()
end

function incrementScaleTonicNoteAction()
  if getScaleTonicNote() < #notes then setScaleTonicNote(getScaleTonicNote() + 1) end
  afterScaleChange()
end

function decrementScaleTypeAction()
  if getScaleType() > 1 then setScaleType(getScaleType() - 1) end
  afterScaleChange()
end

function incrementScaleTypeAction()
  if getScaleType() < #scales then setScaleType(getScaleType() + 1) end
  afterScaleChange()
end

function setScaleTonicAndType(tonic, scaleType)
  if tonic then setScaleTonicNote(tonic) end
  if scaleType then setScaleType(scaleType) end
  afterScaleChange()
end

local function outOfRange(i) return scaleNotes[i] == nil or (scaleIsPentatonic() and i > 5) end

function scaleChordAction(i)
  if outOfRange(i) then return end
  setSelectedScaleNote(i)
  local chord = scaleChords[i][getSelectedChordType(i)]
  playOrInsertScaleChord("scale chord " .. i .. "  (" .. chord.code .. ")")
end

function previewScaleChordAction(i)
  if outOfRange(i) then return end
  setSelectedScaleNote(i)
  previewScaleChord()
end

function scaleNoteAction(i)
  if outOfRange(i) then return end
  setSelectedScaleNote(i)
  playOrInsertScaleNote(0, "scale note " .. i)
end

function lowerScaleNoteAction(i)
  if outOfRange(i) or getOctave() <= getOctaveMin() then return end
  setSelectedScaleNote(i)
  playOrInsertScaleNote(-1, "lower scale note " .. i)
end

function higherScaleNoteAction(i)
  if outOfRange(i) or getOctave() >= getOctaveMax() then return end
  setSelectedScaleNote(i)
  playOrInsertScaleNote(1, "higher scale note " .. i)
end

function previewScaleNoteAction(i)
  if outOfRange(i) then return end
  setSelectedScaleNote(i)
  previewScaleNote(0)
end

function previewLowerScaleNoteAction(i)
  if outOfRange(i) or getOctave() <= getOctaveMin() then return end
  setSelectedScaleNote(i)
  previewScaleNote(-1)
end

function previewHigherScaleNoteAction(i)
  if outOfRange(i) or getOctave() >= getOctaveMax() then return end
  setSelectedScaleNote(i)
  previewScaleNote(1)
end


------------------------------------------------------------------------------
-- Borrowed chords: the scale whose tonic is the root of the selected chord
--   Ctrl + 1..7 (or "borrowed scale chord N" actions): degree N of that scale
------------------------------------------------------------------------------

-- "chord" : major if the chord is major/dominant, natural minor if minor/diminished
-- "scale" : same scale type as the main scale
-- "parallel" : another mode on the same tonic as the main scale (modal interchange)
function getBorrowMode() return getValue("borrowMode", "chord") end
function getParallelScaleType()
  local v = tonumber(getValue("parallelScaleType", 0)) or 0
  if v < 1 or v > #scales then
    -- default: natural minor under a major-type scale, major otherwise
    local st = getScaleType()
    local majorish = scales[st].pattern:sub(5, 5) == '1'
    v = majorish and 2 or 1
  end
  return v
end
function setParallelScaleType(a) setValue("parallelScaleType", a) end
function setBorrowMode(a) setValue("borrowMode", a) end

function getBorrowedChordTypes() return getTableValue("borrowedChordTypes", defaultSevenOnes) end
function getBorrowedChordType(i) return tonumber(getBorrowedChordTypes()[i]) or 1 end
function setBorrowedChordType(i, a)
  local t = getBorrowedChordTypes(); t[i] = a; setTableValue("borrowedChordTypes", t)
end

local MINOR_CODES = { minor = true, min7 = true, min6 = true, dim = true, flat5 = true }

local function spellScale(scaleNotesList) return spellNotes(scaleNotesList) end

local function headersFor(chordLists)
  local minorSymbols = { 'i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii' }
  local majorSymbols = { 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII' }
  local headers = {}
  for i, list in ipairs(chordLists) do
    local chord = list[1]
    local symbol = (string.match(chord.code, "major") or chord.code == '7') and majorSymbols[i] or minorSymbols[i]
    if chord.code == 'aug' then symbol = symbol .. '+' end
    if chord.code == 'dim' then symbol = symbol .. 'o' end
    headers[i] = symbol
  end
  return headers
end

-- runs fn inside the borrowed scale context
function withBorrowContext(ctx, fn)
  local savedPattern, savedNotes, savedChords, savedCtx = scalePattern, scaleNotes, scaleChords, borrowContext
  scalePattern, scaleNotes, scaleChords, borrowContext = ctx.pattern, ctx.notes, ctx.chords, ctx
  local ok, r = pcall(fn)
  scalePattern, scaleNotes, scaleChords, borrowContext = savedPattern, savedNotes, savedChords, savedCtx
  if not ok then error(r, 0) end
  return r
end

function getBorrowedContext()
  local i = getSelectedScaleNote()
  local root = scaleNotes[i]
  if not root or not scaleChords[i] then return nil end
  local chord = scaleChords[i][getSelectedChordType(i)] or scaleChords[i][1]
  local st
  local mode = getBorrowMode()
  local tonic = getNotesIndex(root)
  if mode == "scale" then st = getScaleType()
  elseif mode == "parallel" then
    st = getParallelScaleType()
    tonic = getNotesIndex(getScaleTonicNote())
  else st = MINOR_CODES[chord.code] and 2 or 1 end

  local ctx = { tonic = tonic, scaleType = st }
  ctx.pattern = getScalePattern(tonic, scales[st])
  -- same register as the main scale: each note within [main tonic, +11]
  local mainTonic = getScaleTonicNote()
  ctx.notes = {}
  for note = tonic, tonic + 11 do
    if ctx.pattern[getNotesIndex(note)] then
      ctx.notes[#ctx.notes + 1] = mainTonic + ((note - mainTonic) % 12)
    end
  end
  ctx.names = spellScale(ctx.notes)
  ctx.nameByPC = {}
  for k, note in ipairs(ctx.notes) do ctx.nameByPC[(note - 1) % 12] = ctx.names[k] end

  local savedPattern = scalePattern
  scalePattern = ctx.pattern
  ctx.chords, ctx.inScaleCounts = {}, {}
  for k, note in ipairs(ctx.notes) do
    ctx.chords[k] = getScaleChordsForRootNote(note)
    local c = 0
    for idx in ipairs(chords) do if chordIsInScale(note, idx) then c = c + 1 end end
    ctx.inScaleCounts[k] = c
  end
  scalePattern = savedPattern

  ctx.headers = headersFor(ctx.chords)
  local isMinor = (st == 2)
  ctx.label = ctx.names[1] .. ((st == 1 or st == 6) and " major" or (isMinor or st == 7) and " minor" or (" " .. scales[st].name))
  return ctx
end

-- is the borrowed chord outside the main scale? (true borrowing)
function chordIsOutsideMainScale(rootNote, chord)
  local pattern = chord.pattern
  for n = 0, #pattern - 1 do
    if pattern:sub(n + 1, n + 1) == '1' and not scalePattern[getNotesIndex(rootNote + n)] then return true end
  end
  return false
end

function borrowedChordAction(degree, insert, chordTypeIndex)
  local ctx = getBorrowedContext()
  if not ctx or not ctx.notes[degree] then return nil end
  local t = chordTypeIndex or getBorrowedChordType(degree)
  if chordTypeIndex then setBorrowedChordType(degree, chordTypeIndex) end
  return withBorrowContext(ctx, function()
    if insert then
      local chord = ctx.chords[degree][t]
      return playOrInsertChord(degree, t, "borrowed chord " .. degree .. " of " .. ctx.label .. " (" .. chord.code .. ")")
    end
    return previewChord(degree, t)
  end)
end


------------------------------------------------------------------------------
-- Neo-Riemannian transformations (Alt)
--   P  parallel            C ↔ Cm
--   L  leading-tone exchange C ↔ Em
--   R  relatif             C ↔ Am
--   N  Nebenverwandt (RLP) C → Fm
--   S  glissement   (LPR)  C → C#m
--   H  hexatonic pole (LPL)  C → Abm
--   PR chromatic mediant    C → Eb
-- We start from an "anchor" (the selected chord); choosing a
-- transformation makes it the new anchor → suggestions of suggestions, endlessly.
------------------------------------------------------------------------------

PLR_OPS = {
  { op = "P",  name = "parallel" },
  { op = "L",  name = "leading tone" },
  { op = "R",  name = "relative" },
  { op = "N",  seq = "RLP", name = "nebenverw." },
  { op = "S",  seq = "LPR", name = "slide" },
  { op = "H",  seq = "LPL", name = "hex. pole" },
  { op = "PR", seq = "PR",  name = "mediant" },
}

-- quality of the underlying triad
local TRIAD_OF = { major = "M", ['7'] = "M", maj7 = "M", maj6 = "M", aug = "M", sus2 = "M", sus4 = "M",
                   power = "M", minor = "m", min7 = "m", min6 = "m", dim = "m", flat5 = "m" }

local function plrStep(pc, q, letter)
  if letter == "P" then return pc, (q == "M") and "m" or "M" end
  if letter == "R" then
    if q == "M" then return (pc + 9) % 12, "m" else return (pc + 3) % 12, "M" end
  end
  if letter == "L" then
    if q == "M" then return (pc + 4) % 12, "m" else return (pc + 8) % 12, "M" end
  end
  return pc, q
end

function plrApply(pc, q, seq)
  for letter in seq:gmatch(".") do pc, q = plrStep(pc, q, letter) end
  return pc, q
end

local function chordByCode(code)
  for _, c in ipairs(chords) do if c.code == code then return c end end
end

local function triadName(pc, q)
  local name
  for d, note in ipairs(scaleNotes) do
    if (note - 1) % 12 == pc then name = getScaleNoteName(d) end
  end
  if not name then
    -- black keys outside the scale: usual spelling (C#m, F#m, G#m / Db, Eb, Ab, Bb)
    local minorNames = { [1] = "C#", [3] = "Eb", [6] = "F#", [8] = "G#", [10] = "Bb" }
    local majorNames = { [1] = "Db", [3] = "Eb", [6] = "F#", [8] = "Ab", [10] = "Bb" }
    name = ((q == "m") and minorNames[pc] or majorNames[pc]) or getNoteName(pc + 1)
  end
  return name .. ((q == "m") and "m" or "")
end

local function encodeTriad(t) return t.pc .. q2s(t.q) end
function q2s(q) return (q == "m") and "m" or "M" end

local function decodeTriads(raw)
  local list = {}
  for pc, q in raw:gmatch("(%d+)([Mm])") do list[#list + 1] = { pc = tonumber(pc), q = q } end
  return list
end

local function gridSelectionKey()
  local i = getSelectedScaleNote()
  return i .. ":" .. getSelectedChordType(i) .. ":" .. getScaleTonicNote() .. ":" .. getScaleType()
end

-- state: anchor + history; reset when the selected grid chord changes
function getPLRState()
  local origin = getValue("plrOrigin", "")
  local key = gridSelectionKey()
  local path = decodeTriads(getValue("plrPath", ""))
  if origin ~= key or #path == 0 then
    local i = getSelectedScaleNote()
    if not scaleNotes[i] then return nil end
    local chord = scaleChords[i][getSelectedChordType(i)] or scaleChords[i][1]
    path = { { pc = (scaleNotes[i] - 1) % 12, q = TRIAD_OF[chord.code] or "M" } }
    setValue("plrPath", encodeTriad(path[1]))
    setValue("plrOrigin", key)
    setValue("plrFocus", 1)
  end
  local focus = tonumber(getValue("plrFocus", 1)) or 1
  return { path = path, anchor = path[#path], focus = math.max(1, math.min(#PLR_OPS, focus)) }
end

local function savePath(path)
  local parts = {}
  local start = math.max(1, #path - 31)  -- history limited to 32 steps
  for k = start, #path do parts[#parts + 1] = encodeTriad(path[k]) end
  setValue("plrPath", table.concat(parts, " "))
end

function getPLRContext()
  local st = getPLRState()
  if not st then return nil end
  local a = st.anchor
  local mainTonic = getScaleTonicNote()
  local ctx = {
    isNeighbors = true, tonic = mainTonic, pattern = scalePattern,
    notes = {}, chords = {}, inScaleCounts = {}, headers = {}, names = {}, nameByPC = {},
    info = {}, focus = st.focus, path = st.path,
  }
  for d, note in ipairs(scaleNotes) do ctx.nameByPC[(note - 1) % 12] = getScaleNoteName(d) end
  ctx.label = triadName(a.pc, a.q)
  local trail = {}
  for _, t in ipairs(st.path) do trail[#trail + 1] = triadName(t.pc, t.q) end
  ctx.trail = table.concat(trail, " → ")
  for k, def in ipairs(PLR_OPS) do
    local pc, q = plrApply(a.pc, a.q, def.seq or def.op)
    local chord = chordByCode((q == "m") and "minor" or "major")
    local rootNote = mainTonic + ((pc + 1 - mainTonic) % 12)
    ctx.notes[k] = rootNote
    ctx.chords[k] = { chord }
    ctx.inScaleCounts[k] = 1
    ctx.headers[k] = triadName(pc, q)
    ctx.names[k] = ctx.headers[k]:gsub("m$", "")
    local inScale = true
    local p = chord.pattern
    for n = 0, #p - 1 do
      if p:sub(n + 1, n + 1) == '1' and not scalePattern[getNotesIndex(rootNote + n)] then inScale = false end
    end
    ctx.info[k] = { op = def.op, opName = def.name, pc = pc, q = q, inScale = inScale }
  end
  return ctx
end

-- plays (or inserts) transformation k from the current anchor.
-- descend = true: it also becomes the new anchor (global actions);
-- otherwise we stay on the same level and the focus moves to k (window).
function plrAction(k, insert, descend)
  local ctx = getPLRContext()
  if not ctx or not ctx.notes[k] then return nil end
  local info = ctx.info[k]
  ctx.describe = info.op .. " of " .. ctx.label
  local r = withBorrowContext(ctx, function()
    if insert then
      return playOrInsertChord(k, 1, "PLR " .. info.op .. " (" .. ctx.headers[k] .. ")")
    end
    return previewChord(k, 1)
  end)
  if descend then
    local path = ctx.path
    path[#path + 1] = { pc = info.pc, q = info.q }
    savePath(path)
  end
  setValue("plrFocus", k)
  return r
end

function plrMoveFocus(d)
  local st = getPLRState()
  if not st then return end
  local f = ((st.focus - 1 + d) % #PLR_OPS) + 1
  setValue("plrFocus", f)
end

-- plays the focused cell without changing level
function plrPlayFocused(insert)
  local st = getPLRState()
  if not st then return end
  return plrAction(st.focus, insert, false)
end

-- go down into the focused cell, without playing
function plrDescendFocused()
  local ctx = getPLRContext()
  if not ctx then return end
  local info = ctx.info[ctx.focus]
  local path = ctx.path
  path[#path + 1] = { pc = info.pc, q = info.q }
  savePath(path)
end

-- go up one level; play = true to hear it (global action)
function plrBack(play)
  local st = getPLRState()
  if not st or #st.path <= 1 then return end
  table.remove(st.path)
  savePath(st.path)
  if not play then return end
  local a = st.path[#st.path]
  local mainTonic = getScaleTonicNote()
  local ctx = getPLRContext()
  ctx.notes = { mainTonic + ((a.pc + 1 - mainTonic) % 12) }
  ctx.chords = { { chordByCode((a.q == "m") and "minor" or "major") } }
  ctx.names = { triadName(a.pc, a.q):gsub("m$", "") }
  ctx.describe = "back to " .. triadName(a.pc, a.q)
  return withBorrowContext(ctx, function() return previewChord(1, 1) end)
end

-- jumps straight back to level n of the path (breadcrumb click), without playing
function plrJumpTo(n)
  local st = getPLRState()
  if not st or n < 1 or n >= #st.path then return end
  while #st.path > n do table.remove(st.path) end
  savePath(st.path)
end

-- keyboard selection without playing: shows the chord and its voicing
function showSelectedChordWithoutPlaying()
  local i = getSelectedScaleNote()
  if not scaleNotes[i] then return end
  local result = buildChordVoicing(i, getSelectedChordType(i))
  updateChordDisplay(result)
end

function moveSelection(dCol, dRow)
  local i = getSelectedScaleNote()
  local n = #scaleNotes
  if scaleIsPentatonic() then n = math.min(n, 5) end
  if dCol ~= 0 then
    i = math.max(1, math.min(n, i + dCol))
    setSelectedScaleNote(i)
  end
  if dRow ~= 0 then
    local t = math.max(1, math.min(#scaleChords[i], getSelectedChordType(i) + dRow))
    setSelectedChordType(i, t)
  end
  showSelectedChordWithoutPlaying()
end


------------------------------------------------------------------------------
-- History of played chords ("ChordMachineGun history" window)
--   each entry keeps the exact notes (voices, channels, doublings) to replay them
--   replaying from the history adds nothing to the history
------------------------------------------------------------------------------

HISTORY_MAX = 300
local historySuspended = false

local function encodeNotes(list)
  local t = {}
  for _, n in ipairs(list) do
    t[#t + 1] = n.pitch .. ":" .. (n.chan or -1) .. ":" .. (n.voice or 0)
  end
  return table.concat(t, ",")
end

local function decodeNotes(raw)
  local t = {}
  for p, c, v in (raw or ""):gmatch("(%-?%d+):(%-?%d+):(%-?%d+)") do
    local chan = tonumber(c)
    t[#t + 1] = { pitch = tonumber(p), chan = (chan >= 0) and chan or nil, voice = tonumber(v) }
  end
  return t
end

local function decodeInts(raw)
  local t = {}
  for m in (raw or ""):gmatch("(%-?%d+)") do t[#t + 1] = tonumber(m) end
  return t
end

-- entry: name \t label \t notes \t structure \t voices \t inserted(0/1)
function getHistory()
  local raw = getValue("history", "")
  local list = {}
  for line in raw:gmatch("[^\n]+") do
    local f = {}
    for field in (line .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = field end
    list[#list + 1] = {
      name = f[1] or "?", label = f[2] or "",
      notes = decodeNotes(f[3]), upper = decodeInts(f[4]), voices = decodeInts(f[5]),
      inserted = (f[6] == "1"), raw = line,
    }
  end
  return list
end

function getHistoryRevision() return tonumber(getValue("historyRev", 0)) or 0 end

local function saveHistory(list)
  local lines = {}
  local start = math.max(1, #list - HISTORY_MAX + 1)
  for k = start, #list do
    local e = list[k]
    lines[#lines + 1] = table.concat({
      (e.name or ""):gsub("[\t\n]", " "), (e.label or ""):gsub("[\t\n]", " "),
      encodeNotes(e.notes), table.concat(e.upper or {}, " "), table.concat(e.voices or {}, " "),
      e.inserted and "1" or "0" }, "\t")
  end
  setValue("history", table.concat(lines, "\n"))
  setValue("historyRev", getHistoryRevision() + 1)
end

function addToHistory(result, inserted)
  if historySuspended or not result or not result.notes then return end
  local list = getHistory()
  local entry = {
    name = result.name, label = result.borrowLabel or "",
    notes = result.notes, upper = result.upper, voices = result.voices, inserted = inserted,
  }
  local last = list[#list]
  if last and last.name == entry.name and encodeNotes(last.notes) == encodeNotes(entry.notes) then
    if inserted and not last.inserted then last.inserted = true; saveHistory(list) end
    return
  end
  list[#list + 1] = entry
  saveHistory(list)
end

function clearHistory() setValue("history", ""); setValue("historyRev", getHistoryRevision() + 1) end

function removeHistoryEntry(index)
  local list = getHistory()
  table.remove(list, index)
  saveHistory(list)
end

local function pitchesText(list)
  local t = {}
  for _, p in ipairs(list) do t[#t + 1] = getPitchName(p) end
  return table.concat(t, "  ")
end
function historyVoicesText(entry) return pitchesText(entry.voices) end

-- replays (or inserts) an entry exactly as it was played
function playHistoryEntry(index, insert)
  local list = getHistory()
  local e = list[index]
  if not e or #e.notes == 0 then return nil end
  historySuspended = true
  local ok, err = pcall(function()
    if insert and activeTake() ~= nil and notCurrentlyRecording() then
      startUndoBlock()
      if thereAreNotesSelected() then
        local selected = getSelectedChords()
        deleteSelectedNotes()
        for _, c in ipairs(selected) do
          setEditCursorTo(c.startPosition)
          insertScaleChord(e.notes, true, c)
        end
      else
        insertScaleChord(e.notes, false)
      end
      endUndoBlock("ChordMachineGun 2: history (" .. e.name .. ")")
    end
    playScaleChord(e.notes)
    setChordText(e.label ~= "" and (e.name .. "   ·  " .. e.label) or e.name)
    setChordNotesText(pitchesText(e.voices))
    setLastVoices(e.voices)
    local vn = {}
    for i, p in ipairs(e.voices) do vn[i] = getPitchName(p) end
    setValue("lastVoiceNames", table.concat(vn, ","))
    if getVoiceLeadingEnabled() and #e.upper > 0 then
      setVoiceLeadingReference(e.upper, tagsFromPitches(e.upper))
      setValue("vlRefSeq", latestInputSeq())
    end
    reaper.Help_Set("History: " .. e.name .. "    " .. pitchesText(e.voices), false)
  end)
  historySuspended = false
  if not ok then error(err, 0) end
  return e
end

------------------------------------------------------------------------------
-- CC sliders (2): mouse or MIDI controller
--   out   = CC sent; in = controller CC driving the slider (Learn)
------------------------------------------------------------------------------

CC_NAMES = { [1] = "Modulation", [2] = "Breath", [4] = "Foot", [5] = "Portamento", [7] = "Volume",
  [10] = "Pan", [11] = "Expression", [64] = "Sustain", [71] = "Resonance", [72] = "Release",
  [73] = "Attack", [74] = "Brightness", [91] = "Reverb", [93] = "Chorus" }

function getCCSlider(i)
  local defaults = { "1,1,0", "11,11,127" }
  local raw = getValue("ccSlider" .. i, defaults[i] or "1,1,0")
  local out, inp, val = raw:match("(%d+),(%d+),(%d+)")
  return { out = tonumber(out) or 1, inp = tonumber(inp) or 1, value = tonumber(val) or 0 }
end

function setCCSlider(i, sl)
  setValue("ccSlider" .. i, sl.out .. "," .. sl.inp .. "," .. sl.value)
end

-- sends the CC on the default channel, or on every voice channel when split
function sendCC(cc, value)
  value = math.max(0, math.min(127, math.floor(value + 0.5)))
  local chans, seen = {}, {}
  local n = #getLastVoices()
  if n == 0 then n = 4 end
  for v = 1, n do
    local c = voiceChannel(v) or getCurrentNoteChannel()
    if not seen[c] then seen[c] = true; chans[#chans + 1] = c end
  end
  for _, ch in ipairs(chans) do reaper.StuffMIDIMessage(0, 0xB0 + ch, cc, value) end
end

-- new CC messages from controllers since seq; returns events, last seq
function pollIncomingCC(sinceSeq)
  if not reaper.MIDI_GetRecentInputEvent then return {}, sinceSeq end
  local events = {}
  local newest = sinceSeq
  for idx = 0, 255 do
    local seq, buf, _, dev = reaper.MIDI_GetRecentInputEvent(idx)
    if not seq or seq == 0 or seq <= sinceSeq then break end
    if idx == 0 then newest = seq end
    if type(buf) == "string" and #buf >= 3 and (buf:byte(1) & 0xF0) == 0xB0 then
      local d = math.floor(dev or 0)
      if (d & 0xFFFF) ~= 62 then
        table.insert(events, 1, { cc = buf:byte(2), value = buf:byte(3) })
      end
    end
  end
  return events, newest
end

function currentInputSeq() return latestInputSeq() end

------------------------------------------------------------------------------
-- Voice tracks
------------------------------------------------------------------------------

local function voiceTrackName(v)
  if v == 1 then return getBassMode() == "root" and "Bass (root)" or "Bass" end
  return "Voice " .. v
end

-- track name for a channel: the voices routed to it
local function channelTrackName(ch, totalVoices)
  local names = {}
  for v = 1, totalVoices do
    if voiceChannel(v) == ch then names[#names + 1] = (v == 1) and voiceTrackName(1) or tostring(v) end
  end
  if #names == 0 then return "Channel " .. (ch + 1) end
  if #names == 1 then
    local v = tonumber(names[1])
    return v and voiceTrackName(v) or names[1]
  end
  if names[1]:match("^Bass") then
    return names[1] .. " + voices " .. table.concat(names, ", ", 2)
  end
  return "Voice " .. table.concat(names, ", ")
end

local function sourceTrack()
  if activeTake() ~= nil then return activeTrack() end
  return reaper.GetSelectedTrack(0, 0)
end

-- Creates one track per voice, fed by a MIDI send filtered on the voice channel
function createRoutedVoiceTracks(count)
  local src = sourceTrack()
  if not src then
    reaper.MB("Select a track (or open a MIDI item) first.", "ChordMachineGun", 0)
    return false
  end
  count = math.max(1, math.min(16, count))
  local srcIdx = math.floor(reaper.GetMediaTrackInfo_Value(src, "IP_TRACKNUMBER")) -- 1-based
  -- one track per channel used by the voices ("bass only" mode: 2 tracks)
  local chans, seen = {}, {}
  for v = 1, count do
    local c = voiceChannel(v)
    if c and not seen[c] then seen[c] = true; chans[#chans + 1] = c end
  end
  if #chans == 0 then
    reaper.MB("All voices are on the default channel: choose a split first.", "ChordMachineGun", 0)
    return false
  end
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  for k, ch in ipairs(chans) do
    reaper.InsertTrackAtIndex(srcIdx + k - 1, true)
    local tr = reaper.GetTrack(0, srcIdx + k - 1)
    reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", channelTrackName(ch, count) .. "  ·  channel " .. (ch + 1), true)
    local send = reaper.CreateTrackSend(src, tr)
    reaper.SetTrackSendInfo_Value(src, 0, send, "I_SRCCHAN", -1)            -- no audio
    reaper.SetTrackSendInfo_Value(src, 0, send, "I_MIDIFLAGS", (ch + 1))     -- source channel n, destination = original
  end
  reaper.PreventUIRefresh(-1)
  reaper.TrackList_AdjustWindows(false)
  reaper.Undo_EndBlock("ChordMachineGun 2: create voice tracks", -1)
  return true
end

-- Explodes the active (or selected) MIDI item: one track and one item per channel used
function explodeTakeToVoiceTracks()
  local take = activeTake()
  if take == nil then
    local item = reaper.GetSelectedMediaItem(0, 0)
    if item then take = reaper.GetActiveTake(item) end
  end
  if take == nil or not reaper.TakeIsMIDI(take) then
    reaper.MB("Open or select a MIDI item first.", "ChordMachineGun", 0)
    return false
  end
  local item = reaper.GetMediaItemTake_Item(take)
  local src = reaper.GetMediaItemTake_Track(take)
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

  local byChan, chans = {}, {}
  local _, n = reaper.MIDI_CountEvts(take)
  n = n or 0
  for i = 0, n - 1 do
    local _, _, mute, sppq, eppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if not byChan[chan] then byChan[chan] = {}; chans[#chans + 1] = chan end
    table.insert(byChan[chan], {
      s = reaper.MIDI_GetProjTimeFromPPQPos(take, sppq),
      e = reaper.MIDI_GetProjTimeFromPPQPos(take, eppq),
      chan = chan, pitch = pitch, vel = vel, mute = mute,
    })
  end
  if #chans == 0 then return false end
  table.sort(chans)

  local srcIdx = math.floor(reaper.GetMediaTrackInfo_Value(src, "IP_TRACKNUMBER"))
  local totalVoices = math.max(#getLastVoices(), 8)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  for k, ch in ipairs(chans) do
    reaper.InsertTrackAtIndex(srcIdx + k - 1, true)
    local tr = reaper.GetTrack(0, srcIdx + k - 1)
    local name = channelTrackName(ch, totalVoices)
    reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", name .. "  ·  channel " .. (ch + 1), true)
    local newItem = reaper.CreateNewMIDIItemInProj(tr, pos, pos + len, false)
    local newTake = reaper.GetActiveTake(newItem)
    for _, e in ipairs(byChan[ch]) do
      reaper.MIDI_InsertNote(newTake, false, e.mute,
        reaper.MIDI_GetPPQPosFromProjTime(newTake, e.s),
        reaper.MIDI_GetPPQPosFromProjTime(newTake, e.e),
        e.chan, e.pitch, e.vel, true)
    end
    reaper.MIDI_Sort(newTake)
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("ChordMachineGun 2: explode item to voice tracks", -1)
  return true
end
