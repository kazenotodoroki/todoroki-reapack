# ChordMachineGun 2 (beta)

Test variant of ChordMachineGun, aimed at modern, film and game writing. It lives next to ChordMachineGun 1.x: its own files, its own window, its own settings. Nothing from 1.x is overwritten, and it is **not published through ReaPack** yet (every file is `@noindex`).

## How to test it in REAPER
1. *Actions → Show action list → New action → Load ReaScript…*
2. Go to `todoroki-reapack\Beta\ChordMachineGun 2\` and select `Todoroki_ChordMachineGun2.lua` (select every `.lua` of the folder if you also want the actions).
3. Run **Script: Todoroki_ChordMachineGun2.lua**. The window is called "ChordMachineGun 2".

REAPER runs the files straight from the repo folder, so any later change is live at the next launch. To remove the beta, delete the actions from the action list.

Recommended: the **js_ReaScriptAPI** extension (ReaPack), for Ctrl/Alt + digits and window pinning.

## What is new in 2.2

### Shortcuts at a glance
| Keys | What it does |
|---|---|
| **Space** held + **1…7** | toggle the colors 7 · 9 · 11 · 13 · sus2 · sus4 · no3 (the row above the grid shows them) |
| **Space** + **0** | clear the colors |
| **Ctrl** held (Cmd on macOS) | degrees of the selected chord's scale (as before) |
| **Alt** held (Option) | neo-Riemannian PLR row (as before) |
| **Ctrl+Alt** held (**AltGr** on Swiss / French / German keyboards, Cmd+Option on macOS) | substitutions of the selected chord |
| **Tab** / **Shift+Tab** | next / previous tools page: Progressions → Detect → Modulation → Sketch → back to the grid |
| **Esc** | back to the grid when a page is open (otherwise closes the window, as before) |

On keyboards that have them, **F1…F7** (colors), **F8** (clear), **F9** (Detect), **F10** (Modulation), **F11** (Progressions) and **F12** (Sketch) still work.

### Tools page
The **Tools** button in the header (or **Tab**) replaces the grid with four tabs.

#### Progressions
The former Wiki: for the current scale, what it sounds like, then the **Most used** and **Most beautiful** progressions in the current key.
- Each chord shows its roman numeral. Blue = outside the scale (borrowed).
- **Click** a chord to play it, **Shift+click** to insert it (colors, voice leading and channels apply as for any chord).
- **Insert** writes the whole progression at the edit cursor. **+ Sketch** copies it into the selected sketch slot.
- Roman numerals are measured from the major scale of the tonic: `bVI` is the major chord a minor sixth above the tonic, lower case is minor, `o` diminished, `+` augmented. All 21 scales have a page; the lists are an editorial selection.

#### Detect
Finds the scale of what you wrote.
- It analyses the **selected notes** in the MIDI editor, otherwise the **whole item**, otherwise the **last chords played**. Drone notes are ignored. Long notes weigh more; the lowest note, the first and the last note help to find the tonic.
- The list shows the 10 best matches with the share of notes that fit and the notes that fall outside. **Click** a result to make it the current scale.
- Several scales can fit 100% when some notes are missing (a tune without F or F# fits both A minor and A Dorian): the order then follows the tonic clues and how common the scale is.
- Action: `detect scale (apply best match)`.

#### Modulation
Ways to move from the current key to another one.
- Choose the target with the two menus, or with the quick buttons: **Dominant**, **Subdominant**, **Relative**, **Parallel**, **Up a step**, **Up ½ step**, **Mediant ↑**, **Mediant ↓**.
- Each path starts on your tonic chord and lands on the new tonic:
  - **Pivot chord**: a chord that belongs to both keys (preferably ii, IV or vi of the new key), then V7 → I.
  - **ii – V – I**: the new key's own cadence.
  - **Dominant**: straight to V7 of the new key.
  - **Backdoor** (major targets): minor iv then bVII7, a soft, cinematic arrival.
  - **Neo-Riemannian**: the shortest chain of P / L / R moves between the two tonic chords.
  - **Chromatic mediant** (targets a third away, outside the scale): direct move, the film-score shift.
- **Click** a chord to play it, **Shift+click** to insert it, **Insert** writes the whole path, **+ Sketch** keeps it.
- **Switch to that key** makes the target the current scale, so you can carry on there.

#### Sketch
Seven slots (**A…G**) to keep progressions side by side, saved in the project.
- **Click a letter** to select the slot; **+ Sketch** buttons on the other tabs add to the selected slot.
- **+ Last** adds the chord you just played (from the grid, Ctrl, Alt, substitutions, history…).
- **History** replaces the slot with the last 4 or 8 chords played.
- **Click** a chord to play it, **Shift+click** to insert it, **right-click** to move it left / right or remove it.
- **Insert** writes the slot at the edit cursor, **×** clears it.
- Chords are stored as real chords (Am, Bb7…), so they stay the same when you change the scale.

### Next-chord hints
After every chord you play, small marks appear in the top-right corner of the grid cells that usually come next: **3 marks** = the most likely, then 2, then 1.
- The hints are learned from the progressions of the Progressions tab for the current scale (plus the general major or minor ones), so they follow the style of the scale.
- They can point to a chord outside the scale when the progressions use it (Fm after F in C major: the minor plagal).
- Turn them on / off with **next-chord hints**, to the right of the line above the grid, or with the action `toggle next-chord hints`.

### Substitutions (Ctrl+Alt)
Hold **Ctrl+Alt** (or **AltGr**): the row above the grid shows seven chords built around the selected chord. In C major with Am selected:

| Key | Substitution | Am → | |
|---|---|---|---|
| 1 | **R** relative | C | same notes, other colour |
| 2 | **P** parallel | A | major ↔ minor |
| 3 | **V7/** secondary dominant | E7 | leads into Am |
| 4 | **subV7/** tritone substitute | Bb7 | leads into Am by a half step |
| 5 | **viio/** leading-tone diminished | G#dim | leads into Am |
| 6 | **M3** chromatic mediant | C#m | a third up, same quality: the film shift |
| 7 | **bVII7/** backdoor dominant | G7 | soft approach to Am |

- **Ctrl+Alt+1…7** plays, add **Shift** to insert. Click a cell works too.
- The grid selection does not move, so you can try all seven around the same chord.
- Actions: `substitution 1 - R - relative` … `substitution 7 - bVII7 - backdoor dominant`.

### New actions
`substitution 1…7`, `detect scale (apply best match)`, `toggle next-chord hints`.

## What is new in 2.1

### Reharmonize selected notes
**Selection** menu (INSERT row): what Shift+click / Shift+digit does when notes are selected in the MIDI editor.

- **Replace** (default): each selected chord is replaced by the new chord, as before.
- **Reharmonize**: the selected notes keep their position, length, velocity and channel, and each pitch moves to the closest note of the new chord. A riff, a figure or a pad written on C becomes the same figure on F, Am, Ab…
  - Notes that were different stay different and in the same order whenever the chord allows it.
  - A bass note (below C3) follows the bass of the new chord.
  - Colors apply (with **7** on, the 7th becomes available). Drone notes do not move. Unselected notes are untouched.
  - Every selected note lands on a chord tone, so passing notes of a melody are pulled onto the chord: select the accompaniment, not the tune.

The **Wiki** became the **Progressions** tab of the Tools page (see 2.2).

## What is new in 2

### Colors
A row of chips under the chord name: **7 · 9 · 11 · 13 · sus2 · sus4 · no3**. They apply to *every* chord you play (grid, Ctrl row, Alt row), using the notes of the current scale. One key gives you Cmaj9, Dm9, G9… without choosing chord types.

- **7, 9, 11, 13** stack scale thirds on top of the chord.
- **sus2, sus4, no3** replace or remove the third (only one at a time). `no3` gives open fifths.
- Harsh clashes are softened for you: a b9 becomes a 9, and an 11 over a major third becomes a #11 (the Lydian sound).
- Keys: hold **Space** and press **1…7** to toggle the seven colors, **Space+0** clears them (F1…F8 also work).
- With voice leading on **auto** voices, the chord gets one voice per chord tone, so added colors are always heard. With a fixed voice count, the fifth and the root are dropped first.
- In a custom position, `9`, `11` and `13` use the active colors.

### Chord length
**Length ×N** (INSERT row): an inserted chord lasts N grid units. Example: grid 1/4, Length ×4 = one bar. Inserting again at the same place replaces what was there.

### Parallel-mode borrowing (modal interchange)
In the panel, **Degrees (Ctrl)** has a third option, **Parallel**: the Ctrl row then shows the chords of another mode on the *same tonic*. In C major with "C Natural Minor": Ctrl+6 = Ab, Ctrl+7 = Bb, Ctrl+4 = Fm. Choose the mode in the dropdown under the switch (any scale of the list).

### More scales
Lydian Dominant, Mixolydian b6, Phrygian Dominant, Harmonic Major, Double Harmonic, Hungarian Minor, Dorian #4, Lydian Augmented, Whole Tone.

### Note spelling
Seven-note scales are spelled with one letter per degree (F# next to G, never Gb next to G), in the grid, the chord names and the voices.

### New actions
`toggle color 7th / 9th / 11th / 13th / sus2 / sus4 / no 3rd`, `clear colors`, `toggle reharmonize selected notes`.

---

Everything below works as in ChordMachineGun 1.1.

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

Your keyboard must be enabled as a MIDI input in REAPER's preferences. It does not need to be armed. ChordMachineGun 2's own previews (virtual keyboard) are ignored.

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
- **Space+1…7** colors, **Space+0** clear colors, **Tab** tools pages, **Esc** back to the grid.
- **Ctrl+Alt** (AltGr) **+1…7**: substitutions.

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
Every action starts with `Todoroki_ChordMachineGun2 …` in the action list:
scale chords and notes (as in ChordGun), `toggle voice leading`, `toggle custom position`, `toggle MIDI channel per voice` (None ↔ All), `toggle drone`, `reset voice leading reference`, `toggle voice leading source (live - item)`, `set voice leading reference from selected notes`, `explode MIDI item to voice tracks`, `borrowed scale chord 1…7`, `PLR 1…7`, `PLR back`, and the `history` window script.
