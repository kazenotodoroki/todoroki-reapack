-- @description Regions Creator
-- @author Todoroki
-- @version 1.0
-- @changelog
--   Première version
-- @about
--   Crée les régions et une piste MIDI pour enregistrer des samples.

-- Initialize local variables with default values
local roundRobinsNumber = 1
local velocityLayersNumber = 1
local firstNote = "C4"
local lastNote = "C5"
local noteLength = 1.0  -- in seconds
local reverbLength = 1.5  -- in seconds
local silenceLength = 0.5  -- in seconds

-- Function to convert note number to note name
function noteNumberToName(noteNumber)
  local noteNames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
  local octave = math.floor(noteNumber / 12)
  local note = noteNumber % 12 + 1
  return noteNames[note] .. octave
end

-- Get user inputs
local retval, userInputs = reaper.GetUserInputs(
  "Enter values", 
  7, 
  "Round Robins Number,Velocity Layers Number,First Note,Last Note,Note Length (s),Reverb Length (s),Silence Length (s)", 
  tostring(roundRobinsNumber) .. ',' .. tostring(velocityLayersNumber) .. ',' .. firstNote .. ',' .. lastNote .. ',' .. tostring(noteLength) .. ',' .. tostring(reverbLength) .. ',' .. tostring(silenceLength)
)

if retval then
  -- If user clicked OK, parse the user inputs
  local inputs = {}
  for input in string.gmatch(userInputs, '([^,]+)') do
    table.insert(inputs, input)
  end

  -- Update variables with user inputs
  roundRobinsNumber = tonumber(inputs[1])
  velocityLayersNumber = tonumber(inputs[2])
  firstNote = inputs[3]
  lastNote = inputs[4]
  noteLength = tonumber(inputs[5])
  reverbLength = tonumber(inputs[6])
  silenceLength = tonumber(inputs[7])

  -- Check if inputs are numbers
  if roundRobinsNumber == nil or velocityLayersNumber == nil or noteLength == nil or reverbLength == nil or silenceLength == nil then
    reaper.ShowConsoleMsg("Error: One of the inputs is not a number.\n")
    return
  end

  -- If more than one velocity layer, ask for MIDI velocities
  local velocities = {}
  if velocityLayersNumber > 1 then
    local retval, userInputs = reaper.GetUserInputs(
      "Enter MIDI velocities for each layer", 
      velocityLayersNumber, 
      string.rep("Velocity Layer ", velocityLayersNumber), 
      string.rep("64,", velocityLayersNumber-1) .. "64"
    )
    
    if retval then
      for input in string.gmatch(userInputs, '([^,]+)') do
        local velocity = tonumber(input)
        if velocity == nil or velocity < 0 or velocity > 127 then
          reaper.ShowConsoleMsg("Error: Invalid MIDI velocity.\n")
          return
        end
        table.insert(velocities, velocity)
      end
    end
  end

  -- Convert note names to numeric values
  local noteValues = {
    C = 0, ["C#"] = 1, D = 2, ["D#"] = 3, E = 4, F = 5,
    ["F#"] = 6, G = 7, ["G#"] = 8, A = 9, ["A#"] = 10, B = 11
  }
  local firstNoteNumber = noteValues[string.sub(firstNote, 1, 1)] + 12 * tonumber(string.sub(firstNote, 2))
  local lastNoteNumber = noteValues[string.sub(lastNote, 1, 1)] + 12 * tonumber(string.sub(lastNote, 2))
  local notesNumber = lastNoteNumber - firstNoteNumber + 1

  -- Display variable values in the console
  reaper.ShowConsoleMsg("Notes Number: " .. notesNumber .. "\n")
  reaper.ShowConsoleMsg("Round Robins Number: " .. roundRobinsNumber .. "\n")
  reaper.ShowConsoleMsg("Velocity Layers Number: " .. velocityLayersNumber .. "\n")
  reaper.ShowConsoleMsg("First Note: " .. firstNote .. "\n")
  reaper.ShowConsoleMsg("Last Note: " .. lastNote .. "\n")
  reaper.ShowConsoleMsg("Note Length: " .. noteLength .. " (s)\n")
  reaper.ShowConsoleMsg("Reverb Length: " .. reverbLength .. " (s)\n")
  reaper.ShowConsoleMsg("Silence Length: " .. silenceLength .. " (s)\n")

  -- Set project BPM
  reaper.SetCurrentBPM(0, 120, false)

  -- Variables for region start and end times
  local regionStart = 2 * 4  -- Start at 5th measure (4 measures of 2 seconds each at 120 BPM)

  for i=1, notesNumber do
    local noteName = noteNumberToName(firstNoteNumber + i - 1)
    for k=1, velocityLayersNumber do
      for j=1, roundRobinsNumber do
        -- Calculate region end time for note
        local noteEnd = regionStart + noteLength
        local regionEnd = noteEnd + reverbLength

        -- Prepare region name
        local regionName = "_" .. noteName
        if velocityLayersNumber > 1 then
          regionName = regionName .. string.format("_%03d", velocities[k] or 0)
        end
        if roundRobinsNumber > 1 then
          regionName = regionName .. string.format("_RR%d", j)
        end


        -- Add region for note
        reaper.AddProjectMarker2(0, true, regionStart, regionEnd, regionName, -1, 0)

        -- Add /STOP marker at the end of the note
        reaper.AddProjectMarker2(0, false, noteEnd, 0, "/STOP", -1, 0)

        -- Update region start time for silence
        regionStart = regionEnd

        -- Calculate region end time for silence
        regionEnd = regionStart + silenceLength

        -- Add region for silence
        reaper.AddProjectMarker2(0, true, regionStart, regionEnd, "/SILENCE", -1, 0)

        -- Update region start time for next note
        regionStart = regionEnd
      end
    end
  end

-- Create a new MIDI track
reaper.InsertTrackAtIndex(0, false)
local track = reaper.GetTrack(0, 0)

-- Create an empty MIDI item that spans from measure 5 to the end of the last region
local item = reaper.CreateNewMIDIItemInProj(track, 2 * 4, regionStart)
local take = reaper.GetTake(item, 0)

-- Variables for MIDI event start and end times (PPQ)
-- Start at measure 5 (4 measures of 2 seconds each at 120 BPM)
local ppqStart = 0
local ppqEnd

for i=1, notesNumber do
  local noteNumber = firstNoteNumber + i - 1
  for k=1, velocityLayersNumber do
    -- Get velocity for this layer
    local velocity = velocities[k] or 64

    for j=1, roundRobinsNumber do
      -- Calculate end of the note (not including reverb)
      ppqEnd = ppqStart + (noteLength * 960 / 0.5)

      -- Insert a note-on event
      reaper.MIDI_InsertNote(take, false, false, ppqStart, ppqEnd, 0, noteNumber, velocity, false)

      -- Insert a note-off event
      reaper.MIDI_InsertNote(take, false, false, ppqEnd, ppqEnd, 0, noteNumber, 0, false)

      -- Update PPQ start and end times for next note
      ppqStart = ppqEnd + ((reverbLength + silenceLength) * 960 / 0.5)
    end
  end
end
end 
