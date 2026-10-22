# RefLab

Compare your mix with reference tracks, right inside REAPER (JSFX, works with portable REAPER).

## Installation (ReaPack, Todoroki repository)

Install the three packages:

1. **RefLab** (the plugin, FX category)
2. **RefLab - actions and Companion module**
3. **Todoroki Companion**

Then:

- Run the **Todoroki Companion - Autostart (on-off)** action once: the Companion will start together with REAPER.
- **View > Monitoring FX > Add > JS: RefLab** (the Monitoring FX are never included in a render).

## Reference files

- Folder: `<REAPER>/Data/references` (**REFS FOLDER** button in the plugin).
- WAV, FLAC, MP3, OGG, AIFF… The list updates by itself; **REFRESH** button to force it.
- Without the Companion, the menu shows the files that were there when the plugin opened.

## Per-project memory

The loaded references, their loops and the selected reference are **saved in the project**
(.rpp file) by the Todoroki Companion, even when RefLab sits in the Monitoring FX.
When you open a project or switch project tabs, RefLab reloads the references of that project.
A project that has nothing saved yet keeps the current references.

- Remember to **save the project** (Ctrl+S): the project is marked as modified when you change a reference.
- One RefLab instance at a time (preferably in the Monitoring FX).

## Usage

| Where | What |
|---|---|
| Slots 1 to 4 | click: choose the file; "…" or right click: menu |
| MIX / REF, **A** key | listen to the mix or the reference (15 ms crossfade) |
| MATCH | OFF / INTEGRATED / SHORT-T: automatic level alignment of the reference |
| Waveform | drag: loop; click: position; right click: loop off; **L** key |
| Speed button, **V** key | FAST 0.12 s · MEDIUM 0.4 s · SLOW 1.5 s · VERY SLOW 5 s · INF. AVG |
| Right click on the speed button, **R** key | reset the spectrum (average / smoothing) |
| SLOPE, OCT | display slope (dB/oct) and frequency smoothing |
| Wheel / Ctrl + wheel | spectrum level / range |
| PLAY, **P** key | play the references without starting the transport |

### Slow speeds (tweaking an EQ while watching the spectrum)

In SLOW and VERY SLOW, the curves **glide smoothly in dB** towards their new value: an EQ change
shows up progressively, without jumps. When playback starts, the curve settles quickly (1.5 s),
then switches to the slow glide. When playback stops, the curve **stays frozen** ("frozen" is shown).

In **INF. AVG**, the spectrum is the average of everything played since the last reset
(silences are ignored): ideal for the overall tonal balance of a whole song.

### Difference curve (REF − MIX)

- **CENTERED** (default): the average difference between the reference and the mix is removed, the curve
  shows the **tonal balance difference** (independent of the volume). The average offset is shown in the title.
  **ABSOLUTE**: raw difference.
- **AUTO**: the scale adapts (±3, 6, 12 or 24 dB); or a fixed scale. **E** key.
- **SMOOTH**: smoothing of the difference curve only (1/3 octave by default, or 1/6, 1 octave, same as spectrum).
- Orange = the reference has more energy, blue = the mix has more.

### Band solo and output (ISOL8 style)

The **BANDS** strip acts on what you hear, **mix and references** (LUFS meters and spectrum stay full band).

| Where | What |
|---|---|
| Click on a band, **F1 to F5** | listen to that band only (click again: back to full band) |
| Ctrl/Shift + click, right click, Shift + F1-F5 | add / remove a band (listen to several bands) |
| **FULL**, **I** key | pause / resume the band solo (the selected bands are kept) |
| Orange lines on the spectrum | drag them to move the crossover frequencies (120, 500, 2k, 6k by default) |
| **OUTPUT**: STEREO / MONO / SIDE / L / R, **M** key | monitoring mode |

Linkwitz-Riley 24 dB/oct filters: the sum of all bands is perfectly flat. When no band is soloed,
the signal is not processed at all.

## MIDI / keyboard mapping

Every setting can be mapped in two ways:

- **Plugin parameters**: *Param* button of the FX window > *Learn*. All settings (listen, reference, match,
  trim, slope, smoothing, speed, band solo and each band, crossover frequencies, output mode,
  difference curve…), plus "[Button]" parameters for pads (toggle MIX/REF, next reference, loop,
  exclusive solo of each band, next output mode…).
  For a pad on an on/off parameter, choose *Toggle* in the Learn window.
- **"RefLab - …" actions** (52 actions) in the action list: *Add shortcut*, then press the key or move
  the MIDI control (*Preferences > MIDI devices*: enable *Enable input for control messages*).

## Upgrading

- **From 1.3**: the actions now have English names. ReaPack removes the old ones; re-assign the
  shortcuts you had made.
- **From 1.1 (manual install)**: delete `<REAPER>/Effects/RefLab.jsfx` and the `<REAPER>/Scripts/RefLab`
  folder, then run **Todoroki Companion - Autostart (on-off)** (it removes the old RefLab line from
  `__startup.lua`).
