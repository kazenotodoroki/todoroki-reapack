# RS Trig Sampler

A drum replacement sampler for REAPER, in the spirit of the sample-playback side of Slate Trigger 2.
It is written in JSFX and Lua, so there is no VST and nothing to install outside REAPER. It works in a portable REAPER on a USB stick.

Put it after your trigger tool (MIDI) on the track. One instance plays one drum element, with up to 8 samples layered in parallel (close mic + sub + room...).

## Packages (ReaPack, repository "Todoroki")

| Package | Installs |
|---|---|
| **RS Trig Sampler** (FX) | the JSFX `RS Trig Sampler` |
| **RS Trig Kit Builder** (Scripts) | actions `Todoroki_RS Trig Kit Builder` and `Todoroki_RS Trig Rescan Library`, the page `Todoroki_RS Trig TCI Converter.html`, a demo kit, this README |

After installing, run **Todoroki_RS Trig Rescan Library** once (Actions list: search "RS Trig"). It creates the library (`<REAPER>/Data/RSampler`) and installs the demo kit.

## The sampler

- **Load**: click an empty slot, or use LOAD / right-click. The browser opens in the folder of the slot's current sample.
  - Click folders to go down. Backspace or `..` goes up.
  - Type to search the whole library. Esc closes.
- **Drag & drop** audio files onto a slot. Several files fill the following slots.
  - Files outside `Data` work, but their path turns yellow: they will not follow the USB stick.
- **All 8 slots default to note 36 (C2)**: they play together. Change NOTE (or LEARN) per slot if needed.
- The **velocity x round robin grid** shows the last hit. Click a cell to audition that exact sample and lock the waveform view.

### Per-slot controls

| Control | What it does |
|---|---|
| VOLUME / PAN / PITCH | Pitch ±24 semitones, Hermite interpolation |
| VOICES | Hits that may overlap on this slot (1 = mono). Older hits fade out in 6 ms |
| ATTACK / HOLD / DECAY / CURVE | Envelope applied **to the sample audio**, counted from the hit. Note length and note-off are ignored. HOLD = INF plays the whole sample. The graph shows the part of the sample that is heard |
| VELOCITY | **THRU** = incoming velocity. Any other value = target velocity: the sample is played as if hit at this velocity |
| VEL SENS | With a target: 0 % always plays the target, 100 % follows the drummer's dynamics around it (incoming minus average incoming, clipped at 127). Also scales the volume response to velocity |
| IN > PLAYED | Last incoming velocity and the velocity actually played |
| ROUND ROBIN | CYCLE (1-2-3-1...) or RANDOM (never the same twice in a row) |
| CHOKE | Group 1–8: a hit in the group fades the others (open / closed hi-hat) |
| OUTPUT | Stereo pair 1/2 ... 15/16 (set the track channel count accordingly) |
| M / S | Mute / Solo |

Example: the trigger sends 96 and you want the sample hit at 120. Set VELOCITY to 120.
- VEL SENS 0 %: every hit plays 120.
- VEL SENS 100 %: a hit at 90 plays 114, and a hit at 110 plays 127 (clipped).

All controls are automatable and MIDI-learnable (they appear in the plugin's parameter list).

### Projects and presets

- **Projects**: the sample paths of the 8 slots are saved with the plugin state in the project and reloaded when it opens.
- **Presets**: REAPER presets store the same state.
  - To save a layered kit (e.g. "Snare - Top + Bottom + Room"), use the plugin's **+ > Save preset**. Recalling it loads all its samples at once.
- **Paths**: they are relative to `<REAPER>/Data`, so projects and presets survive a change of drive letter.

## RS Trig Kit Builder

### Import .tci (Slate Trigger 2)

Pick a `.tci`, then import that file only, or its whole folder tree. Pick a file at the top of your Trigger library to import everything.

- Decoding is bit-exact: it is the same audio Trigger plays, with the same velocity layers and round robins (e.g. 4 layers x 12 RR, ranges 1-30 / 31-61 / 62-92 / 93-127).
- Optional: also export every sound as a WAV (`Data/RSampler_TCI_WAV/`).
- Speed: about 2 s per stereo kit of 48 sounds.

### TCI Converter (web page, whole library)

Open it from **RS Trig Kit Builder > Open TCI converter**. The file is `Todoroki_RS Trig TCI Converter.html`, next to the script.

1. **Source**: pick the top folder of your Trigger library, or drop it onto the page.
   - The preview shows where every kit will go (element counts, instrument folders).
2. **Output**: choose one of two modes.
   - **Write into my library folder** (Chrome / Edge): pick `<REAPER>/Data/RSampler`.
     - Kits are written in place and `_library.txt` is updated, so you only have to click RESCAN in the sampler.
     - "Skip kits that already exist" lets you resume an interrupted import.
   - **Download a ZIP** (any browser, up to ~3.9 GB per ZIP): extract it into `<REAPER>/Data`, then run **RS Trig Rescan Library**.
3. **Optional WAV export**: every sound is written as a WAV into a separate folder you pick, so the WAVs do not show up in the sampler's browser.

The page works offline from disk and nothing is uploaded. It uses the same decoder and the same organisation as the script, and produces byte-identical kits.

### Library organisation

Every kit is written to `Data/RSampler/<Element>/<Instrument>/<name>.rsk.wav`. Library names are ignored.

- **Element**: Kick, Snare, Tom, HiHat, Cymbal, Percussion or Other. It is detected from the deepest folder or file name that names a drum: `Close Room - Guru 22x16 Kick`, `SD_...`, `T1_...`, `Toms`, `BB Snare`...
- **Instrument**: the nearest folder that is not a generic one (`Individuals`, `LO / MID / HI`, `RAW`...) and not just a drum word (`Kicks`, `02 SNARE`). Leading numbers (`01 `) are removed.
- **Name collisions** are resolved automatically:
  - First, sub-folder names are added to the file name (`LO BOTTOM`, `MID BOTTOM`).
  - If that is not enough, the instrument is tagged with its parent folder (`SNARE 1 (RAW)` / `SNARE 1 (PROCESSED)`).

Examples:

```
Trigger2 Kicks/ACKick/ACKick NRG.tci                 -> Kick/ACKick/ACKick NRG
BD Jens Bogren Signature/Kicks/1 SumoSub/Individuals/SumoSub 52.tci
                                                      -> Kick/SumoSub/SumoSub 52
Perfect Drums/03 RACK TOM 1/02 TAMA STARCLASSIC 10/T1_TAMA STARCLASSIC 10_DIR.tci
                                                      -> Tom/TAMA STARCLASSIC 10/T1_TAMA STARCLASSIC 10_DIR
Fatal Snares/01 RAW/01 SNARE 1/01 LO/BOTTOM.tci       -> Snare/SNARE 1 (RAW)/LO BOTTOM
```

### Build kits from WAV folders

Recognised names:

- `Snare_V01_RR1.wav`, `Snare v3 rr2.wav`, `Kick_Vel10.wav`.
- `metal_snare_025_01.wav`: two trailing numbers are read as velocity then round robin.
- When velocity numbers are real MIDI values (025, 050, ... 127), they become the layer ranges. Plain indexes spread the layers over 1-127.
- Files without tags: you choose layers sorted by attack level, layers by name, round robins, or one kit per file.

### Other actions

- **Unpack a kit**: writes one WAV per layer / round robin to `Data/RSampler_Unpacked/<kit>/`.
- **Rescan library**: run it after adding or removing files by hand, then click RESCAN in the sampler.
  - A JSFX cannot list folders by itself, so the sampler reads `Data/RSampler/_library.txt`.

## Notes

- **Memory**: a stereo kit of 4 x 12 sounds is about 2 min 30 of audio, i.e. ~110 MB of RAM per loaded slot.
  - A recent REAPER (7.x) lets a slot hold about 3 min of stereo. Older versions show "File truncated".
- **Loading during playback**: loading a big kit while playing can cause a short dropout. Load kits while stopped.
- **Trigger Instrument Editor gain**: the editor applies a gain to every sound of a multi-sound .tci (normalisation). Imported kits keep that level, like Trigger.
- **Clicks**: avoided by a 4 ms fade at the end of every sample, and by fades when a voice is stolen, choked or limited by VOICES.

## .rsk.wav format

A standard 32-bit float WAV. Its first values are a header:

```
-7337.25, 1, channels, layers, header length,
  per layer: vel lo, vel hi, RR count,
    per RR: offset (frames), length (frames)
```

All samples follow, concatenated.
