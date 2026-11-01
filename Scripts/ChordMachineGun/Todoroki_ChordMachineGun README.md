# ChordMachineGun

Chord generator for REAPER, based on **ChordGun** by pandabot (MIT licence). It installs next to ChordGun without changing it, and a ChordGun update through ReaPack never overwrites it.

## Installation
With ReaPack (recommended): add `https://github.com/kazenotodoroki/todoroki-reapack/raw/main/index.xml` in *Extensions → ReaPack → Import repositories*, then install **ChordMachineGun**. Every action shows up in the *Main* and *MIDI Editor* sections.

By hand: copy the `ChordMachineGun/` folder into `Scripts/`, then load `Todoroki_ChordMachineGun.lua`, `Todoroki_ChordMachineGun history.lua` and the actions you want with *Actions → New action → Load ReaScript*.

Recommended: the **js_ReaScriptAPI** extension (ReaPack), for Ctrl/Alt + digits and window pinning.

ChordMachineGun stores its settings in the project, separately from ChordGun: both can run at the same time.

## History
The **History** button at the top of the main window opens (or closes) a separate window.

- Every chord you play or insert becomes a button, with its actual voices (position, voice leading, channels, doublings, drone).
- An immediate repeat of the same chord is not duplicated.
- A blue bar on the left marks a chord that was inserted into an item.
- The blue label in the top right shows where the chord came from ("V of C major", "R of C"…).

Controls:
- **click** or **← →**: replay the chord exactly as it was played. **↑ ↓**: previous / next row.
- **Shift+click** or **Shift+Enter**: insert it into the MIDI editor (or replace the selected notes).
- **Del**: remove the chord. **Right-click**: menu (replay, insert, remove, clear all).
- The round button pins the window (js_ReaScriptAPI). Right-click an empty area to dock it.

Replaying from the history **does not add** to the history. The replayed chord does become the voice leading reference, so you can carry on naturally.

The history is saved in the project (last 300 chords).

## Controllers (CC and velocity)
Three sliders at the top of the right panel.

- **CC 1 and CC 2**
  - Click the label to change the CC: Modulation, Expression, Volume, Brightness…, or **Other…** for any number.
  - By default each slider follows the same CC number coming from your controller.
- **Velocity**: the velocity of the chords you play and insert (1 to 127). When notes are replaced, they keep their original velocity.

For every slider:
- **Mouse**: drag, or use the wheel (Shift = steps of 10).
- **L** (Learn): then move any knob or fader; it will drive the slider. The learned input is shown ("← CC 21").
- **Cancel a Learn**: click **L** again, press **Esc**, or wait 10 seconds.

CCs are sent like the chords, through the virtual keyboard, to the armed track receiving it. With a split, they go to every channel used by the voices.

Your controller must be enabled as a MIDI input in REAPER's preferences.

## Drone
One or more fixed notes played under every chord. They never move and **voice leading ignores them**: they are not part of the voicing and they are filtered out when the reference chord is analysed (keyboard, playback, item).

- **Drone** switch: turns the drone on or off.
- **Notes**: click **+** to add the scale tonic, the scale fifth, both, the root of the selected chord, the notes of the current chord, the notes selected in the MIDI editor, or type notes (`C2 G2`, `F#1`, `Bb3`, or MIDI numbers; C4 = middle C). Click a note to remove it.
- **Channel**: the drone can go to its own MIDI channel (for example another instrument), or to the default channel.
- **Hold between chords** (on by default): in preview the drone keeps sounding continuously and is never re-attacked. Off: it is played again with each chord.
- Inserted chords always get the drone notes written under them.
- When a chord voice falls on the same note and channel as the drone, the drone wins: the held note is never cut by the next chord.

Action: `toggle drone`.

## Voice leading
Turn on **Voice leading**, then choose where the reference chord comes from. The reference chord is analysed continuously and shown in the panel (recognised name, notes, source).

- **Live** (default). The reference is, in order of priority:
  1. the chord **held on the MIDI keyboard**;
  2. during **playback**, the chord sounding under the play cursor;
  3. otherwise the most recent of the last keyboard chord and the last ChordMachineGun chord.

  As soon as you trigger a new chord in ChordMachineGun, it is voiced from that chord.
- **MIDI item**. The reference is the chord before the edit cursor in the item. When several selected chords are replaced, each one is voice-led from the previous one.

Your keyboard must be enabled as a MIDI input in REAPER's preferences. It does not need to be armed. ChordMachineGun's own previews (virtual keyboard) are ignored.

**Sel.** sets the selected notes as the reference. **↺** clears it.

Rules applied:
- no parallel fifths or octaves, and no direct ones in the outer voices;
- no voice overlap;
- the 7th resolves down, the leading tone rises;
- the root is preferred for doubling;
- the register follows the analysed chord.

**Inversion** chooses the bass note. **Voices**: auto (= number of notes in the reference) or 2 to 8.

## Keys
- **← →**: change degree, **↑ ↓**: change chord type. This selects **without playing**: the chord and its voicing are displayed.
- **Enter**: play the selected chord. **Shift+Enter**: insert it.
- **+ / −**: octave.
- **Shift+← →**: move the edit cursor by one grid step.
- **1-7**: play the scale chords, **Shift+1-7**: insert them. **a-j / q-u / z-m**: single notes (as in ChordGun).
- **0** or middle click: stop all notes (including the drone).

## Ctrl and Alt: reliable keys
With Ctrl or Alt held, REAPER does not always pass digits and arrows to the script. ChordMachineGun therefore reads the physical key state through the **js_ReaScriptAPI** extension. The numeric keypad works too.

Without the extension, a fallback decoding is tried, but it is less reliable. Clicking in the row always works.

## Degrees of the chord's scale (Ctrl)
Hold **Ctrl** (Ctrl or Cmd on macOS). A row above the grid shows the 7 degrees of the scale whose tonic is the root of the selected chord.

Example in C major: with G selected, the row shows G Am Bm C D Em F#dim.
- **Ctrl+5** plays D.
- **Ctrl+4** plays C.
- **Ctrl+Shift+digit** (or Shift+click) inserts the chord.

The selection does not move. In blue: chords that are not in the main scale.

Scale choice, in the panel (**Degrees (Ctrl)**):
- **From chord**: major chord → major scale, minor chord → natural minor.
- **Scale type**: same type as the main scale.

Actions: `borrowed scale chord 1` … `7`.

## Neo-Riemannian transformations (Alt)
Hold **Alt** (Option on macOS). The row shows the transformations of the selected chord's triad (a 7th chord is reduced to its triad).

| Key | Transformation | From C |
|---|---|---|
| 1 | **P** parallel | Cm |
| 2 | **L** leading-tone exchange | Em |
| 3 | **R** relative | Am |
| 4 | **N** Nebenverwandt (RLP) | Fm |
| 5 | **S** slide (LPR) | C#m |
| 6 | **H** hexatonic pole (LPL) | Abm |
| 7 | **PR** chromatic mediant | Eb |

Navigation (with **Alt** held):
- **← →**: move the focus over the 7 cells, without playing.
- **Enter** or **digit 1…7**: play the transformation. You stay on the same level.
- **↓**: go down into the focused cell. It becomes the new starting point, without playing.
- **↑**: go up one level, without playing.
- Add **Shift** to insert instead of play.
- **Click** a cell to play it. **Click** a step of the path (e.g. `C → Am → F`) to jump back to it.

You can explore suggestions of suggestions silently and only listen to what you like. The path restarts when you pick another chord in the grid.

The global `PLR 1…7` actions (window closed) play the transformation **and** go down into it, so you can chain them without seeing the row. `PLR back` goes up and plays the chord.

## Pin the window
The pin button in the top right keeps the window on top.
- It needs the **js_ReaScriptAPI** extension (ReaPack).
- It is disabled while the window is docked.

## Custom position
From lowest to highest, e.g. `1 5 3 13 9`.
- Tokens: `1` (or R), `2 3 4 5 6 7 9 11 13`. Without an accidental, 3/5/7/6 come from the chosen chord and the extensions (9, 11, 13) come from the scale.
- Accidentals: `b9 #9 #11 b13 b5 #5 b7 7M` (or `maj7`, `m3`).
- `+` after a token = one octave higher (e.g. `1 5+ 3`).
- With voice leading: the position is kept and the closest register is chosen.
  **Auto inversion**: also picks the closest rotation (ideal for Drop 2 / Drop 3).

## Voices & MIDI channels
- **Bass**: *Lowest note* (voice 1 is the lowest note, whatever its function) or *Root* (separate bass voice, under the chord).
- **Split** (presets):
  - **None**: every voice on the MIDI editor channel.
  - **All**: voice 1 → channel 1, voice 2 → channel 2…
  - **Bass only**: bass → channel 1, all upper voices → channel 2.
- **Channel per voice**: click a voice's `ch …` badge to choose its channel (1 to 16, or the default channel). The split then switches to *custom*.
- **Doublings**: `+` on a voice adds an octave, a fifth, a third (chromatic or in the scale) or a free value (`7`, `-12`, `d2` = 2 scale steps). Click a chip to remove it. They work **with or without split** and go out on their voice's channel.
- **Create tracks**: one track per channel in use, fed by a MIDI send filtered on that channel (non-destructive). With *Bass only* you get 2 tracks: bass and chord.
- **Explode MIDI item**: copies each channel's notes into an item on a new track.

## Actions
Every action starts with `Todoroki_ChordMachineGun …` in the action list:
scale chords and notes (as in ChordGun), `toggle voice leading`, `toggle custom position`, `toggle MIDI channel per voice` (None ↔ All), `toggle drone`, `reset voice leading reference`, `toggle voice leading source (live - item)`, `set voice leading reference from selected notes`, `explode MIDI item to voice tracks`, `borrowed scale chord 1…7`, `PLR 1…7`, `PLR back`, and the `history` window script.
