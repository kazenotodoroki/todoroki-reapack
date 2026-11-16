# Todoroki ReaPack catalogue

Every package of the **todoroki-reapack** repository, with its documentation compiled in one place (the package README, or the `@about` text of its ReaPack header when it has no README).

ReaPack repository: `https://github.com/kazenotodoroki/todoroki-reapack/raw/main/index.xml` (*Extensions → ReaPack → Import repositories*).

_This file is generated automatically by `.github/scripts/build_catalogue.py` on every push: do not edit it by hand, edit the READMEs and script headers instead._ Latest package update: 2026-11-05.

## Contents

| Family | Package | Type | Version | Files | Docs |
|---|---|---|---|---|---|
| Mixing & referencing | [RefLab (JSFX)](#pkg-reflab-jsfx) | JSFX | 1.6 | 1 | README |
| Mixing & referencing | [RefLab actions and Companion module](#pkg-todoroki-companion-module-reflab-lua) | Lua script | 1.6 | 206 | README |
| Mixing & referencing | [Todoroki Companion](#pkg-todoroki-companion-lua) | Lua script | 1.3 | 18 | README |
| Composition | [ChordMachineGun](#pkg-todoroki-chordmachinegun-lua) | Lua script | 1.1 | 69 | README |
| Composition | [ChordMachineGun 2 (beta)](#pkg-beta-chordmachinegun-2) | Lua script | beta (unpublished) | – | README |
| Drums | [RS Trig Sampler (JSFX)](#pkg-rs-trig-sampler-jsfx) | JSFX | 1.4 | 1 | README |
| Drums | [RS Trig Kit Builder](#pkg-todoroki-rs-trig-kit-builder-lua) | Lua script | 1.5 | 5 | README |
| Sampling (building instruments) | [Sampling 01: Regions Creator](#pkg-todoroki-sampling-01-regions-creator-lua) | Lua script | 1.0 | 1 | @about |
| Sampling (building instruments) | [Sampling 02: Session Cleaner](#pkg-todoroki-sampling-02-session-cleaner-lua) | Lua script | 1.0 | 1 | @about |
| Sampling (building instruments) | [Sampling 03: Loops Creator](#pkg-todoroki-sampling-03-loops-creator-lua) | Lua script | 1.0 | 1 | @about |
| Sampling (building instruments) | [Sampling 04: Select Regions to export](#pkg-todoroki-sampling-04-select-regions-to-export-lua) | Lua script | 1.0 | 1 | @about |
| Sampling (building instruments) | [Sampling 05: Reaper To DecentSampler (Python)](#pkg-todoroki-sampling-05-reaper-to-ds-py) | Python (external) | 1.0 | 1 | @about |
| Sampling (building instruments) | [Sampling 05: Reaper To Kontakt (Python)](#pkg-todoroki-sampling-05-reaper-to-kontakt-py) | Python (external) | 1.0 | 1 | @about |
| Effects | [DS-8 Distortion Compressor (JSFX)](#pkg-todoroki-ds-8-distortion-compressor-jsfx) | JSFX | 1.3 | 1 | @about |
| Tools | [Param Sweep](#pkg-todoroki-param-sweep-lua) | Lua script | 1.1 | 1 | @about |
| Tools | [ZLEQ2 Curve Import](#pkg-todoroki-zleq2-curve-import-lua) | Lua script | 1.0 | 1 | @about |
| Tools | [Portable Backup](#pkg-todoroki-portable-backup-lua) | Lua script | 1.1 | 18 | README |
| Tools | [FX Param_idx Lister](#pkg-todoroki-fxlister-fx-param-idx-lister-lua) | Lua script | 1.0 | 1 | @about |
| Tools | [FX Lua Creator (Python)](#pkg-todoroki-fxlist-fx-lua-creator-py) | Python (external) | 1.2 | 1 | @about |

*Files*: number of files installed by the ReaPack package (actions, icons, modules…).

---

## Mixing & referencing

<a id="pkg-reflab-jsfx"></a>

### RefLab (JSFX)

**Main file**: `FX/RefLab.jsfx`  
**Version**: 1.6 (2026-10-29)  
**README**: `Scripts/RefLab/Todoroki_RefLab README.md`

Compare your mix with reference tracks, right inside REAPER (JSFX, works with portable REAPER).

#### Installation (ReaPack, Todoroki repository)

Install the three packages:

1. **RefLab** (the plugin, FX category)
2. **RefLab - actions and Companion module**
3. **Todoroki Companion** (`Todoroki_Companion.lua`)

Then:

- Run the **Todoroki_Companion autostart (on-off)** action once: the Companion will start together with REAPER.
- **View > Monitoring FX > Add > JS: RefLab** (the Monitoring FX are never included in a render).

#### Reference files

- Folder: `<REAPER>/Data/references` (**REFS FOLDER** button in the plugin).
- WAV, FLAC, MP3, OGG, AIFF… The list updates by itself; **REFRESH** button to force it.
- Without the Companion, the menu shows the files that were there when the plugin opened.

#### Per-project memory

The loaded references, their loops and the selected reference are **saved in the project**
(.rpp file) by the Todoroki Companion, even when RefLab sits in the Monitoring FX.
When you open a project or switch project tabs, RefLab reloads the references of that project.
A project that has nothing saved yet keeps the current references.

- Remember to **save the project** (Ctrl+S): the project is marked as modified when you change a reference.
- One RefLab instance at a time (preferably in the Monitoring FX).

#### Usage

| Where | What |
|---|---|
| Slots 1 to 4 | click: choose the file; "…" or right click: menu |
| MIX / REF, **A** key | listen to the mix or the reference (15 ms crossfade) |
| MATCH | OFF / INTEGRATED / SHORT-T: automatic level alignment of the reference |
| Waveform | drag: loop; click: position; right click: loop off; **L** key |
| Speed button, **V** key | FAST 0.12 s · MEDIUM 0.4 s · SLOW 1.5 s · INF. AVG |
| Right click on the speed button, **R** key | reset the spectrum (average / smoothing) |
| SLOPE, OCT | display slope (dB/oct) and frequency smoothing |
| Wheel / Ctrl + wheel | spectrum level / range |
| PLAY, **P** key | play the references without starting the transport |

##### SLOW speed (tweaking an EQ while watching the spectrum)

In SLOW, the curves **glide smoothly in dB** towards their new value: an EQ change shows up
progressively, without jumps. When playback starts, the curve settles quickly (1.5 s), then switches
to the slow glide. When playback stops, the curve **stays frozen** ("frozen" is shown).

In **INF. AVG**, the spectrum is the average of everything played since the last reset
(silences are ignored): ideal for the overall tonal balance of a whole song.

##### Difference curve (REF − MIX)

- **CENTERED** (default): the average difference between the reference and the mix is removed, the curve
  shows the **tonal balance difference** (independent of the volume). The average offset is shown in the title.
  **ABSOLUTE**: raw difference.
- **AUTO**: the scale adapts (±3, 6, 12 or 24 dB); or a fixed scale. **E** key.
- **SMOOTH**: smoothing of the difference curve only: 1/48, 1/24, 1/12, 1/6, 1/3 (default) or 1 octave.
- Orange = the reference has more energy, blue = the mix has more.

##### Band solo and output (ISOL8 style)

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

#### MIDI / keyboard mapping

Every setting can be mapped in two ways:

- **Plugin parameters**: *Param* button of the FX window > *Learn*. All settings (listen, reference, match,
  trim, slope, smoothing, speed, band solo and each band, crossover frequencies, output mode,
  difference curve…), plus "[Button]" parameters for pads (toggle MIX/REF, next reference, loop,
  exclusive solo of each band, next output mode…).
  For a pad on an on/off parameter, choose *Toggle* in the Learn window.
- **"Todoroki_RefLab …" actions** (51 actions) in the action list: *Add shortcut*, then press the key or move
  the MIDI control (*Preferences > MIDI devices*: enable *Enable input for control messages*).

#### Opening a project

RefLab always starts by listening to the **MIX** when a project is opened, when REAPER starts or when you
switch project tabs, even if the project was saved while listening to a reference.

#### Toolbar icons (dark)

Every "Todoroki_RefLab …" action has a dark toolbar icon (normal / mouse over / active, 100 %, 150 % and
200 %). The Todoroki Companion copies them into `<REAPER>/Data/toolbar_icons` when it starts
(or run **Todoroki_Companion install toolbar icons**).

To use one: right click on a toolbar > *Customize toolbar…* > add the action > *Icon…* > pick the icon
with the same name as the action. On/off actions (loop, band solo, MIX/REF…) light up in orange when active.

#### Stream Deck

The repository folder `Stream Deck` contains a dark key pack (144 px) for all the actions, with an
"(on)" version for the on/off ones:

- double-click `Todoroki RefLab.streamDeckIconPack` to install it, or copy the
  `com.todoroki.reflab.sdIconPack` folder into `%appdata%\Elgato\StreamDeck\IconPacks` and restart Stream Deck;
- then pick the icons in the key's icon menu (*Icon library* > Todoroki RefLab).

To trigger the actions from the Stream Deck, give each REAPER action a keyboard shortcut and use a
*Hotkey* key, or use a Stream Deck plugin that runs REAPER actions by command ID.

#### Upgrading

- **From 1.3 / 1.4**: the actions are now named "Todoroki_RefLab …". ReaPack removes the old ones;
  re-assign the shortcuts you had made. The Companion package is now `Todoroki_Companion.lua`:
  uninstall the old "Todoroki Companion" package in ReaPack (shown as obsolete), install the new one,
  then run **Todoroki_Companion autostart (on-off)** once (it updates the startup line and stays ON).
- **From 1.1 (manual install)**: delete `<REAPER>/Effects/RefLab.jsfx` and the `<REAPER>/Scripts/RefLab`
  folder, then run **Todoroki_Companion autostart (on-off)** (it removes the old RefLab line from
  `__startup.lua`).

<a id="pkg-todoroki-companion-module-reflab-lua"></a>

### RefLab actions and Companion module

**Main file**: `Scripts/RefLab/Todoroki_Companion_Module_RefLab.lua`  
**Version**: 1.6 (2026-10-29)

Full documentation: see [RefLab (JSFX)](#pkg-reflab-jsfx).

Install together with the **RefLab** (JSFX) and **Todoroki Companion** packages.

- "Todoroki_RefLab ..." actions: map them to keys or to a MIDI controller
- Companion module: opens `<REAPER>/Data/references`, keeps the file list up to date
  and remembers the references of each project

<a id="pkg-todoroki-companion-lua"></a>

### Todoroki Companion

**Main file**: `Scripts/Todoroki Companion/Todoroki_Companion.lua`  
**Version**: 1.3 (2026-10-29)  
**README**: `Scripts/Todoroki Companion/Todoroki_Companion README.md`

A **single** background service for all the Todoroki tools. Only one script runs all the time;
each tool adds its own **module** to it instead of starting its own background script.

- **Todoroki_Companion** action: starts the service (run the action again = stop it; state shown on toolbars).
- **Todoroki_Companion autostart (on-off)**: start together with REAPER (a line in `Scripts/__startup.lua`,
  path relative to the REAPER folder → fine with portable REAPER, even if the drive letter changes).
- **Todoroki_Companion status and modules**: reloads the modules and prints the log in the console.
- **Todoroki_Companion install toolbar icons**: copies the dark toolbar icons of every Todoroki package into
  `<REAPER>/Data/toolbar_icons` (done automatically when the Companion starts, for missing or changed files).

Debug: `reaper.SetExtState("Todoroki_Companion", "debug", "1", false)` prints the log live.

---

#### Adding a module (for a future tool: drum triggers, sample finder…)

1. Create a file named **`Todoroki_Companion_Module_<Name>.lua`** anywhere in the repository
   (e.g. `Scripts/DrumTrig/Todoroki_Companion_Module_DrumTrig.lua`). The Companion looks for these files
   in the whole installed repository folder (`Scripts/Todoroki/…`, 4 levels deep).
2. Declare it in the `@provides` of the tool's package (without `[main]`).
3. Run **Todoroki_Companion status and modules** (or restart REAPER) to load it.

```lua
-- Todoroki_Companion_Module_DrumTrig.lua
local M = {
  name     = "DrumTrig",   -- unique name (used by the API)
  gmem     = "DrumTrig",   -- optional: gmem namespace attached before each call
  interval = 1.0,          -- optional: period of M.slow in seconds (1.5 by default)
}

function M.init(C) end     -- when loaded
function M.tick(C) end     -- every cycle (~30/s): keep it very short
function M.slow(C) end     -- every `interval` seconds
function M.exit(C) end     -- when stopping or reloading

-- commands callable from a Lua script through the API
M.commands = {
  find_samples = function(C, arg)
    -- arg and the return value are strings
    return "ok"
  end,
}

return M
```

An error inside a module is caught and logged; after 20 errors the module is disabled,
the other modules keep running.

##### Toolbox `C` passed to the modules

| Function | Purpose |
|---|---|
| `C.res`, `C.sep`, `C.dir` | REAPER folder, path separator, Companion folder |
| `C.path(a, b, …)` | join paths |
| `C.now()` | `time_precise()` |
| `C.log(who, msg)` | log (console when debug is on) |
| `C.get(k, def)` / `C.set(k, v, persist)` | settings (ExtState section `Todoroki_Companion`) |
| `C.open_folder(dir)` | opens a folder (Explorer / Finder) |
| `C.list_files(dir, exts)` / `C.list_dirs(dir)` | folder content, sorted, REAPER cache cleared |
| `C.AUDIO_EXT` | `{ wav, flac, mp3, ogg, aif, aiff, wv, opus }` |
| `C.scan(root, opts)` | **asynchronous recursive scan** (4 ms max per cycle, never freezes REAPER) |
| `C.gmem_write_string(base, s, max)` / `C.gmem_read_string(base, max)` | strings in gmem for JSFX |
| `C.module(name)`, `C.reload()` | access another module, reload |

```lua
-- example: index a sample library without freezing REAPER
local job = C.scan("D:/Samples/Drums", {
  exts = C.AUDIO_EXT, max_depth = 12,
  on_file = function(path, name) end,            -- optional, called for each file
  on_done = function(files, job) C.log("DrumTrig", #files .. " samples") end,
})
-- job.done, job.files, job.dirs_done, job.cancel()
```

---

#### Using the Companion from a Lua script

```lua
local dir = reaper.GetExtState("Todoroki_Companion", "dir")
if dir == "" then dir = reaper.GetResourcePath() .. "/Scripts/Todoroki/Scripts/Todoroki Companion/" end
local TC = dofile(dir .. "Todoroki_Companion_API.lua")

if not TC.running() then TC.start() end

TC.request("DrumTrig", "find_samples", "kick", function(ok, result)
  reaper.ShowConsoleMsg(tostring(result) .. "\n")
end)
```

| Function | Purpose |
|---|---|
| `TC.running()` / `TC.start()` | service state / start |
| `TC.modules()` / `TC.has(name)` | loaded modules |
| `TC.call(module, cmd, arg)` → id, then `TC.result(id)` | manual asynchronous call |
| `TC.request(module, cmd, arg, cb, timeout)` | call with a `cb(ok, value)` callback |
| `TC.open_folder(path)` | open a folder |
| `TC.install_toolbar_icons(only_new)` | copy the `toolbar_icons` folders of the packages into `Data/toolbar_icons` |

Module `"core"`: `ping`, `version`, `reload`, `modules`, `open_folder`, `log`.

#### Using the Companion from a JSFX

A JSFX cannot see ExtState: it goes through **gmem** (`options:gmem=<Name>`), with a module of the same name.
Recommended convention (the one RefLab uses):

| Slot | Purpose |
|---|---|
| `gmem[0]` | heartbeat written by the module every cycle (lets the JSFX know the Companion is running) |
| `gmem[1]` | request from the JSFX to the module (reset to 0 by the module) |
| `gmem[2]` | command from the REAPER actions to the JSFX (reset to 0 by the JSFX) |
| `gmem[3…99]` | free (versions, counters…) |
| `gmem[100…]` | data (strings: 1 character per slot, 0 terminated) |

#### Toolbar icons for a new tool

Put the icons in a `toolbar_icons` folder next to the tool's scripts (`toolbar_icons/*.png` at 100 %,
`toolbar_icons/150/` and `toolbar_icons/200/` for HiDPI; each file = 3 states side by side: normal,
mouse over, active), and declare the three folders in the package's `@provides`. The Companion installs
them by itself.

To keep something **per project** (like RefLab's references), store it from the module with
`reaper.SetProjExtState(0, "<Name>", key, value)`: it is saved in the .rpp file. Watch the
current project with `reaper.EnumProjects(-1)` to reload it when the user opens a project or changes tab.

---

## Composition

<a id="pkg-todoroki-chordmachinegun-lua"></a>

### ChordMachineGun

**Main file**: `Scripts/ChordMachineGun/Todoroki_ChordMachineGun.lua`  
**Version**: 1.1 (2026-11-01)  
**README**: `Scripts/ChordMachineGun/Todoroki_ChordMachineGun README.md`

Chord generator for REAPER, based on **ChordGun** by pandabot (MIT licence). It installs next to ChordGun without changing it, and a ChordGun update through ReaPack never overwrites it.

#### Installation
With ReaPack (recommended): add `https://github.com/kazenotodoroki/todoroki-reapack/raw/main/index.xml` in *Extensions → ReaPack → Import repositories*, then install **ChordMachineGun**. Every action shows up in the *Main* and *MIDI Editor* sections.

By hand: copy the `ChordMachineGun/` folder into `Scripts/`, then load `Todoroki_ChordMachineGun.lua`, `Todoroki_ChordMachineGun history.lua` and the actions you want with *Actions → New action → Load ReaScript*.

Recommended: the **js_ReaScriptAPI** extension (ReaPack), for Ctrl/Alt + digits and window pinning.

ChordMachineGun stores its settings in the project, separately from ChordGun: both can run at the same time.

#### History
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

#### Controllers (CC and velocity)
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

#### Drone
One or more fixed notes played under every chord. They never move and **voice leading ignores them**: they are not part of the voicing and they are filtered out when the reference chord is analysed (keyboard, playback, item).

- **Drone** switch: turns the drone on or off.
- **Notes**: click **+** to add the scale tonic, the scale fifth, both, the root of the selected chord, the notes of the current chord, the notes selected in the MIDI editor, or type notes (`C2 G2`, `F#1`, `Bb3`, or MIDI numbers; C4 = middle C). Click a note to remove it.
- **Channel**: the drone can go to its own MIDI channel (for example another instrument), or to the default channel.
- **Hold between chords** (on by default): in preview the drone keeps sounding continuously and is never re-attacked. Off: it is played again with each chord.
- Inserted chords always get the drone notes written under them.
- When a chord voice falls on the same note and channel as the drone, the drone wins: the held note is never cut by the next chord.

Action: `toggle drone`.

#### Voice leading
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

#### Keys
- **← →**: change degree, **↑ ↓**: change chord type. This selects **without playing**: the chord and its voicing are displayed.
- **Enter**: play the selected chord. **Shift+Enter**: insert it.
- **+ / −**: octave.
- **Shift+← →**: move the edit cursor by one grid step.
- **1-7**: play the scale chords, **Shift+1-7**: insert them. **a-j / q-u / z-m**: single notes (as in ChordGun).
- **0** or middle click: stop all notes (including the drone).

#### Ctrl and Alt: reliable keys
With Ctrl or Alt held, REAPER does not always pass digits and arrows to the script. ChordMachineGun therefore reads the physical key state through the **js_ReaScriptAPI** extension. The numeric keypad works too.

Without the extension, a fallback decoding is tried, but it is less reliable. Clicking in the row always works.

#### Degrees of the chord's scale (Ctrl)
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

#### Neo-Riemannian transformations (Alt)
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

#### Pin the window
The pin button in the top right keeps the window on top.
- It needs the **js_ReaScriptAPI** extension (ReaPack).
- It is disabled while the window is docked.

#### Custom position
From lowest to highest, e.g. `1 5 3 13 9`.
- Tokens: `1` (or R), `2 3 4 5 6 7 9 11 13`. Without an accidental, 3/5/7/6 come from the chosen chord and the extensions (9, 11, 13) come from the scale.
- Accidentals: `b9 #9 #11 b13 b5 #5 b7 7M` (or `maj7`, `m3`).
- `+` after a token = one octave higher (e.g. `1 5+ 3`).
- With voice leading: the position is kept and the closest register is chosen.
  **Auto inversion**: also picks the closest rotation (ideal for Drop 2 / Drop 3).

#### Voices & MIDI channels
- **Bass**: *Lowest note* (voice 1 is the lowest note, whatever its function) or *Root* (separate bass voice, under the chord).
- **Split** (presets):
  - **None**: every voice on the MIDI editor channel.
  - **All**: voice 1 → channel 1, voice 2 → channel 2…
  - **Bass only**: bass → channel 1, all upper voices → channel 2.
- **Channel per voice**: click a voice's `ch …` badge to choose its channel (1 to 16, or the default channel). The split then switches to *custom*.
- **Doublings**: `+` on a voice adds an octave, a fifth, a third (chromatic or in the scale) or a free value (`7`, `-12`, `d2` = 2 scale steps). Click a chip to remove it. They work **with or without split** and go out on their voice's channel.
- **Create tracks**: one track per channel in use, fed by a MIDI send filtered on that channel (non-destructive). With *Bass only* you get 2 tracks: bass and chord.
- **Explode MIDI item**: copies each channel's notes into an item on a new track.

#### Actions
Every action starts with `Todoroki_ChordMachineGun …` in the action list:
scale chords and notes (as in ChordGun), `toggle voice leading`, `toggle custom position`, `toggle MIDI channel per voice` (None ↔ All), `toggle drone`, `reset voice leading reference`, `toggle voice leading source (live - item)`, `set voice leading reference from selected notes`, `explode MIDI item to voice tracks`, `borrowed scale chord 1…7`, `PLR 1…7`, `PLR back`, and the `history` window script.

<a id="pkg-beta-chordmachinegun-2"></a>

### ChordMachineGun 2 (beta)

**Main file**: `Beta/ChordMachineGun 2/`  
**README**: `Beta/ChordMachineGun 2/Todoroki_ChordMachineGun2 README.md`

> Not published through ReaPack yet (every file is `@noindex`): install it by hand from `Beta/ChordMachineGun 2/`.

Test variant of ChordMachineGun, aimed at modern, film and game writing. It lives next to ChordMachineGun 1.x: its own files, its own window, its own settings. Nothing from 1.x is overwritten, and it is **not published through ReaPack** yet (every file is `@noindex`).

#### How to test it in REAPER
1. *Actions → Show action list → New action → Load ReaScript…*
2. Go to `todoroki-reapack\Beta\ChordMachineGun 2\` and select `Todoroki_ChordMachineGun2.lua` (select every `.lua` of the folder if you also want the actions).
3. Run **Script: Todoroki_ChordMachineGun2.lua**. The window is called "ChordMachineGun 2".

REAPER runs the files straight from the repo folder, so any later change is live at the next launch. To remove the beta, delete the actions from the action list.

Recommended: the **js_ReaScriptAPI** extension (ReaPack), for Ctrl/Alt + digits and window pinning.

#### What is new in 2.2

##### Shortcuts at a glance
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

##### Tools page
The **Tools** button in the header (or **Tab**) replaces the grid with four tabs.

###### Progressions
The former Wiki: for the current scale, what it sounds like, then the **Most used** and **Most beautiful** progressions in the current key.
- Each chord shows its roman numeral. Blue = outside the scale (borrowed).
- **Click** a chord to play it, **Shift+click** to insert it (colors, voice leading and channels apply as for any chord).
- **Insert** writes the whole progression at the edit cursor. **+ Sketch** copies it into the selected sketch slot.
- Roman numerals are measured from the major scale of the tonic: `bVI` is the major chord a minor sixth above the tonic, lower case is minor, `o` diminished, `+` augmented. All 21 scales have a page; the lists are an editorial selection.

###### Detect
Finds the scale of what you wrote.
- It analyses the **selected notes** in the MIDI editor, otherwise the **whole item**, otherwise the **last chords played**. Drone notes are ignored. Long notes weigh more; the lowest note, the first and the last note help to find the tonic.
- The list shows the 10 best matches with the share of notes that fit and the notes that fall outside. **Click** a result to make it the current scale.
- Several scales can fit 100% when some notes are missing (a tune without F or F# fits both A minor and A Dorian): the order then follows the tonic clues and how common the scale is.
- Action: `detect scale (apply best match)`.

###### Modulation
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

###### Sketch
Seven slots (**A…G**) to keep progressions side by side, saved in the project.
- **Click a letter** to select the slot; **+ Sketch** buttons on the other tabs add to the selected slot.
- **+ Last** adds the chord you just played (from the grid, Ctrl, Alt, substitutions, history…).
- **History** replaces the slot with the last 4 or 8 chords played.
- **Click** a chord to play it, **Shift+click** to insert it, **right-click** to move it left / right or remove it.
- **Insert** writes the slot at the edit cursor, **×** clears it.
- Chords are stored as real chords (Am, Bb7…), so they stay the same when you change the scale.

##### Next-chord hints
After every chord you play, small marks appear in the top-right corner of the grid cells that usually come next: **3 marks** = the most likely, then 2, then 1.
- The hints are learned from the progressions of the Progressions tab for the current scale (plus the general major or minor ones), so they follow the style of the scale.
- They can point to a chord outside the scale when the progressions use it (Fm after F in C major: the minor plagal).
- Turn them on / off with **next-chord hints**, to the right of the line above the grid, or with the action `toggle next-chord hints`.

##### Substitutions (Ctrl+Alt)
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

##### New actions
`substitution 1…7`, `detect scale (apply best match)`, `toggle next-chord hints`.

#### What is new in 2.1

##### Reharmonize selected notes
**Selection** menu (INSERT row): what Shift+click / Shift+digit does when notes are selected in the MIDI editor.

- **Replace** (default): each selected chord is replaced by the new chord, as before.
- **Reharmonize**: the selected notes keep their position, length, velocity and channel, and each pitch moves to the closest note of the new chord. A riff, a figure or a pad written on C becomes the same figure on F, Am, Ab…
  - Notes that were different stay different and in the same order whenever the chord allows it.
  - A bass note (below C3) follows the bass of the new chord.
  - Colors apply (with **7** on, the 7th becomes available). Drone notes do not move. Unselected notes are untouched.
  - Every selected note lands on a chord tone, so passing notes of a melody are pulled onto the chord: select the accompaniment, not the tune.

The **Wiki** became the **Progressions** tab of the Tools page (see 2.2).

#### What is new in 2

##### Colors
A row of chips under the chord name: **7 · 9 · 11 · 13 · sus2 · sus4 · no3**. They apply to *every* chord you play (grid, Ctrl row, Alt row), using the notes of the current scale. One key gives you Cmaj9, Dm9, G9… without choosing chord types.

- **7, 9, 11, 13** stack scale thirds on top of the chord.
- **sus2, sus4, no3** replace or remove the third (only one at a time). `no3` gives open fifths.
- Harsh clashes are softened for you: a b9 becomes a 9, and an 11 over a major third becomes a #11 (the Lydian sound).
- Keys: hold **Space** and press **1…7** to toggle the seven colors, **Space+0** clears them (F1…F8 also work).
- With voice leading on **auto** voices, the chord gets one voice per chord tone, so added colors are always heard. With a fixed voice count, the fifth and the root are dropped first.
- In a custom position, `9`, `11` and `13` use the active colors.

##### Chord length
**Length ×N** (INSERT row): an inserted chord lasts N grid units. Example: grid 1/4, Length ×4 = one bar. Inserting again at the same place replaces what was there.

##### Parallel-mode borrowing (modal interchange)
In the panel, **Degrees (Ctrl)** has a third option, **Parallel**: the Ctrl row then shows the chords of another mode on the *same tonic*. In C major with "C Natural Minor": Ctrl+6 = Ab, Ctrl+7 = Bb, Ctrl+4 = Fm. Choose the mode in the dropdown under the switch (any scale of the list).

##### More scales
Lydian Dominant, Mixolydian b6, Phrygian Dominant, Harmonic Major, Double Harmonic, Hungarian Minor, Dorian #4, Lydian Augmented, Whole Tone.

##### Note spelling
Seven-note scales are spelled with one letter per degree (F# next to G, never Gb next to G), in the grid, the chord names and the voices.

##### New actions
`toggle color 7th / 9th / 11th / 13th / sus2 / sus4 / no 3rd`, `clear colors`, `toggle reharmonize selected notes`.

---

Everything below works as in ChordMachineGun 1.1.

#### History
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

#### Controllers (CC and velocity)
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

#### Drone
One or more fixed notes played under every chord. They never move and **voice leading ignores them**: they are not part of the voicing and they are filtered out when the reference chord is analysed (keyboard, playback, item).

- **Drone** switch: turns the drone on or off.
- **Notes**: click **+** to add the scale tonic, the scale fifth, both, the root of the selected chord, the notes of the current chord, the notes selected in the MIDI editor, or type notes (`C2 G2`, `F#1`, `Bb3`, or MIDI numbers; C4 = middle C). Click a note to remove it.
- **Channel**: the drone can go to its own MIDI channel (for example another instrument), or to the default channel.
- **Hold between chords** (on by default): in preview the drone keeps sounding continuously and is never re-attacked. Off: it is played again with each chord.
- Inserted chords always get the drone notes written under them.
- When a chord voice falls on the same note and channel as the drone, the drone wins: the held note is never cut by the next chord.

Action: `toggle drone`.

#### Voice leading
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

#### Keys
- **← →**: change degree, **↑ ↓**: change chord type. This selects **without playing**: the chord and its voicing are displayed.
- **Enter**: play the selected chord. **Shift+Enter**: insert it.
- **+ / −**: octave.
- **Shift+← →**: move the edit cursor by one grid step.
- **1-7**: play the scale chords, **Shift+1-7**: insert them. **a-j / q-u / z-m**: single notes (as in ChordGun).
- **0** or middle click: stop all notes (including the drone).
- **Space+1…7** colors, **Space+0** clear colors, **Tab** tools pages, **Esc** back to the grid.
- **Ctrl+Alt** (AltGr) **+1…7**: substitutions.

#### Ctrl and Alt: reliable keys
With Ctrl or Alt held, REAPER does not always pass digits and arrows to the script. ChordMachineGun therefore reads the physical key state through the **js_ReaScriptAPI** extension. The numeric keypad works too.

Without the extension, a fallback decoding is tried, but it is less reliable. Clicking in the row always works.

#### Degrees of the chord's scale (Ctrl)
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

#### Neo-Riemannian transformations (Alt)
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

#### Pin the window
The pin button in the top right keeps the window on top.
- It needs the **js_ReaScriptAPI** extension (ReaPack).
- It is disabled while the window is docked.

#### Custom position
From lowest to highest, e.g. `1 5 3 13 9`.
- Tokens: `1` (or R), `2 3 4 5 6 7 9 11 13`. Without an accidental, 3/5/7/6 come from the chosen chord and the extensions (9, 11, 13) come from the scale.
- Accidentals: `b9 #9 #11 b13 b5 #5 b7 7M` (or `maj7`, `m3`).
- `+` after a token = one octave higher (e.g. `1 5+ 3`).
- With voice leading: the position is kept and the closest register is chosen.
  **Auto inversion**: also picks the closest rotation (ideal for Drop 2 / Drop 3).

#### Voices & MIDI channels
- **Bass**: *Lowest note* (voice 1 is the lowest note, whatever its function) or *Root* (separate bass voice, under the chord).
- **Split** (presets):
  - **None**: every voice on the MIDI editor channel.
  - **All**: voice 1 → channel 1, voice 2 → channel 2…
  - **Bass only**: bass → channel 1, all upper voices → channel 2.
- **Channel per voice**: click a voice's `ch …` badge to choose its channel (1 to 16, or the default channel). The split then switches to *custom*.
- **Doublings**: `+` on a voice adds an octave, a fifth, a third (chromatic or in the scale) or a free value (`7`, `-12`, `d2` = 2 scale steps). Click a chip to remove it. They work **with or without split** and go out on their voice's channel.
- **Create tracks**: one track per channel in use, fed by a MIDI send filtered on that channel (non-destructive). With *Bass only* you get 2 tracks: bass and chord.
- **Explode MIDI item**: copies each channel's notes into an item on a new track.

#### Actions
Every action starts with `Todoroki_ChordMachineGun2 …` in the action list:
scale chords and notes (as in ChordGun), `toggle voice leading`, `toggle custom position`, `toggle MIDI channel per voice` (None ↔ All), `toggle drone`, `reset voice leading reference`, `toggle voice leading source (live - item)`, `set voice leading reference from selected notes`, `explode MIDI item to voice tracks`, `borrowed scale chord 1…7`, `PLR 1…7`, `PLR back`, and the `history` window script.

---

## Drums

<a id="pkg-rs-trig-sampler-jsfx"></a>

### RS Trig Sampler (JSFX)

**Main file**: `FX/RS Trig Sampler.jsfx`  
**Version**: 1.4 (2026-10-22)  
**README**: `Scripts/RS Trig Sampler/Todoroki_RS Trig Sampler README.md`

A drum replacement sampler for REAPER, in the spirit of the sample-playback side of Slate Trigger 2.
It is written in JSFX and Lua, so there is no VST and nothing to install outside REAPER. It works in a portable REAPER on a USB stick.

Put it after your trigger tool (MIDI) on the track. One instance plays one drum element, with up to 8 samples layered in parallel (close mic + sub + room...).

#### Packages (ReaPack, repository "Todoroki")

| Package | Installs |
|---|---|
| **RS Trig Sampler** (FX) | the JSFX `RS Trig Sampler` |
| **RS Trig Kit Builder** (Scripts) | actions `Todoroki_RS Trig Kit Builder` and `Todoroki_RS Trig Rescan Library`, the page `Todoroki_RS Trig TCI Converter.html`, a demo kit, this README |

After installing, run **Todoroki_RS Trig Rescan Library** once (Actions list: search "RS Trig"). It creates the library (`<REAPER>/Data/RSampler`) and installs the demo kit.

#### The sampler

- **Load**: click an empty slot, or use LOAD / right-click. The browser opens in the folder of the slot's current sample.
  - Click folders to go down. Backspace or `..` goes up.
  - Type to search the whole library. Esc closes.
- **Drag & drop** audio files onto a slot. Several files fill the following slots.
  - Files outside `Data` work, but their path turns yellow: they will not follow the USB stick.
- **All 8 slots default to note 36 (C2)**: they play together. Change NOTE (or LEARN) per slot if needed.
- The **velocity x round robin grid** shows the last hit. Click a cell to audition that exact sample and lock the waveform view.

##### Per-slot controls

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

##### Projects and presets

- **Projects**: the sample paths of the 8 slots are saved with the plugin state in the project and reloaded when it opens.
- **Presets**: REAPER presets store the same state.
  - To save a layered kit (e.g. "Snare - Top + Bottom + Room"), use the plugin's **+ > Save preset**. Recalling it loads all its samples at once.
- **Paths**: they are relative to `<REAPER>/Data`, so projects and presets survive a change of drive letter.

#### RS Trig Kit Builder

##### Import .tci (Slate Trigger 2)

Pick a `.tci`, then import that file only, or its whole folder tree. Pick a file at the top of your Trigger library to import everything.

- Decoding is bit-exact: it is the same audio Trigger plays, with the same velocity layers and round robins (e.g. 4 layers x 12 RR, ranges 1-30 / 31-61 / 62-92 / 93-127).
- Optional: also export every sound as a WAV (`Data/RSampler_TCI_WAV/`).
- Speed: about 2 s per stereo kit of 48 sounds.

##### TCI Converter (web page, whole library)

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

##### Library organisation

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

##### Build kits from WAV folders

Recognised names:

- `Snare_V01_RR1.wav`, `Snare v3 rr2.wav`, `Kick_Vel10.wav`.
- `metal_snare_025_01.wav`: two trailing numbers are read as velocity then round robin.
- When velocity numbers are real MIDI values (025, 050, ... 127), they become the layer ranges. Plain indexes spread the layers over 1-127.
- Files without tags: you choose layers sorted by attack level, layers by name, round robins, or one kit per file.

##### Other actions

- **Unpack a kit**: writes one WAV per layer / round robin to `Data/RSampler_Unpacked/<kit>/`.
- **Rescan library**: run it after adding or removing files by hand, then click RESCAN in the sampler.
  - A JSFX cannot list folders by itself, so the sampler reads `Data/RSampler/_library.txt`.

#### Notes

- **Memory**: a stereo kit of 4 x 12 sounds is about 2 min 30 of audio, i.e. ~110 MB of RAM per loaded slot.
  - A recent REAPER (7.x) lets a slot hold about 3 min of stereo. Older versions show "File truncated".
- **Loading during playback**: loading a big kit while playing can cause a short dropout. Load kits while stopped.
- **Trigger Instrument Editor gain**: the editor applies a gain to every sound of a multi-sound .tci (normalisation). Imported kits keep that level, like Trigger.
- **Clicks**: avoided by a 4 ms fade at the end of every sample, and by fades when a voice is stolen, choked or limited by VOICES.

#### .rsk.wav format

A standard 32-bit float WAV. Its first values are a header:

```
-7337.25, 1, channels, layers, header length,
  per layer: vel lo, vel hi, RR count,
    per RR: offset (frames), length (frames)
```

All samples follow, concatenated.

<a id="pkg-todoroki-rs-trig-kit-builder-lua"></a>

### RS Trig Kit Builder

**Main file**: `Scripts/RS Trig Sampler/Todoroki_RS Trig Kit Builder.lua`  
**Version**: 1.5 (2026-10-22)

Full documentation: see [RS Trig Sampler (JSFX)](#pkg-rs-trig-sampler-jsfx).

Companion script of the **RS Trig Sampler** JSFX (install both packages).

- Import .tci files from a Slate Trigger 2 library (one file or a whole folder tree)
- Build multi-velocity / round-robin kits from WAV folders
- Everything lands in `<REAPER>/Data/RSampler`, sorted as Element / Instrument
- "RS Trig Rescan Library" refreshes the list shown in the sampler's browser
- "Todoroki_RS Trig TCI Converter.html" (menu: Open TCI converter) does the same TCI import from a web
  browser, handy for a whole library folder

Pure Lua, no extension required (portable REAPER friendly).

---

## Sampling (building instruments)

<a id="pkg-todoroki-sampling-01-regions-creator-lua"></a>

### Sampling 01: Regions Creator

**Main file**: `Scripts/Todoroki_Sampling_01_Regions_Creator.lua`  
**Version**: 1.0 (2026-10-20)

Creates the regions and a MIDI track to record samples.

<a id="pkg-todoroki-sampling-02-session-cleaner-lua"></a>

### Sampling 02: Session Cleaner

**Main file**: `Scripts/Todoroki_Sampling_02_Session_Cleaner.lua`  
**Version**: 1.0 (2026-10-20)

Deletes the regions and markers whose name starts with "/".

<a id="pkg-todoroki-sampling-03-loops-creator-lua"></a>

### Sampling 03: Loops Creator

**Main file**: `Scripts/Todoroki_Sampling_03_Loops_Creator.lua`  
**Version**: 1.0 (2026-10-20)

Creates a seamless loop on each sample.

<a id="pkg-todoroki-sampling-04-select-regions-to-export-lua"></a>

### Sampling 04: Select Regions to export

**Main file**: `Scripts/Todoroki_Sampling_04_Select_Regions_to_export.lua`  
**Version**: 1.0 (2026-10-20)

Exports every region except those whose name starts with "#".

<a id="pkg-todoroki-sampling-05-reaper-to-ds-py"></a>

### Sampling 05: Reaper To DecentSampler (Python)

**Main file**: `Python Utilities/Todoroki_Sampling_05_Reaper_To_DS.py`  
**Version**: 1.0 (2026-10-20)

Creates a DecentSampler library from the samples exported from REAPER.
External tool: run it with Python, outside REAPER.

<a id="pkg-todoroki-sampling-05-reaper-to-kontakt-py"></a>

### Sampling 05: Reaper To Kontakt (Python)

**Main file**: `Python Utilities/Todoroki_Sampling_05_Reaper_To_Kontakt.py`  
**Version**: 1.0 (2026-10-20)

Renames and sorts the samples exported from REAPER for Kontakt.
External tool: run it with Python, outside REAPER.

---

## Effects

<a id="pkg-todoroki-ds-8-distortion-compressor-jsfx"></a>

### DS-8 Distortion Compressor (JSFX)

**Main file**: `FX/Todoroki_DS-8 Distortion Compressor.jsfx`  
**Version**: 1.3 (2026-11-05)

Character compressor modelled on the behaviour of the Empirical Labs Distressor (EL8 / EL8-X),
built as an ear-training tool to learn to hear compression.

- Attack 50 us .. 30 ms, Release 50 ms .. 3.5 s (up to ~20 s, program dependent, in 10:1 Opto)
- Ratios 1:1, 2:1 (+15 dB soft knee), 3:1, 4:1, 6:1, 10:1 Opto, 20:1, Nuke
- Detector: HP (100 Hz, 6 dB/oct), Band emphasis (+12 dB @ 6 kHz), Stereo link, external sidechain (3/4)
- Audio: Dist 2 (tube, 2nd harm.), Dist 3 (tape, 3rd harm.), HP (80 Hz, 18 dB/oct), British mode
- Fixed internal threshold: drive with INPUT, compensate with OUTPUT (like the hardware)
- LED gain-reduction meter and exact value readouts under every knob
- MATCH: automatic loudness compensation for level-matched bypass comparison

Mouse: drag knobs (Shift = fine), wheel, double-click = reset. Click ratio / mode buttons.

---

## Tools

<a id="pkg-todoroki-param-sweep-lua"></a>

### Param Sweep

**Main file**: `Scripts/Param Sweep/Todoroki_Param Sweep.lua`  
**Version**: 1.1 (2026-11-04)

Automates the variation of one or more FX parameters and creates one region per step,
ready to be rendered with the `$region` pattern.

1. Set a **time selection** (the passage replayed for each step: test signal, loop, MIDI item…).
2. Run the script, then **move the parameters** to analyse in the plugin windows
   (or click *Scan* to detect every parameter changed since launch).
3. **Continue**: for each parameter enter `steps min% max%` (e.g. `10 0 100`),
   whether the parameters **interact**, and the **tail** (silence after each step).

- No interaction: 10 + 10 steps = 20 regions (the other parameters stay at their initial value).
- Interaction: 10 × 10 = 100 regions (every combination).

The script inserts space after the time selection, duplicates its content for each step,
writes the automation (square points, slightly before each step), creates the regions,
writes a CSV (region → values) next to the project and can prepare the render (`$region`).
Everything is in a single undo.

#### → Parametric NAM

Instead of a grid (which grows exponentially with the number of knobs), this mode picks a
small set of settings with optimal experimental design: an optimized Latin hypercube over the
continuous knobs, balanced switch positions, the corners of the knob space, a center point and
held-out validation settings. Use the short reamp signal of `namp input` as the time selection.

For each parameter enter `min% max%` (knob) or `pos N` (switch / selector with N positions).
Regions are named `<Model> T007 Drive=6.5 Tone=3 Boost=on` (T = training, V = validation;
knob values on a 0–10 scale = normalized parameter × 10). A `<Model>_namp.json` manifest is
written next to the project. Render, then run `namp import-reaper <manifest> --project <dir>`.

Hardware: automate a ReaControlMIDI (CC) or ReaInsert parameter the same way.
Track FX and master FX only (not take FX, input FX or containers).

<a id="pkg-todoroki-zleq2-curve-import-lua"></a>

### ZLEQ2 Curve Import

**Main file**: `Scripts/Todoroki_ZLEQ2 Curve Import.lua`  
**Version**: 1.0 (2026-10-29)

Reads a curve and turns it into bands for **ZL Equalizer 2** (ZL Audio).

Accepted files:
- **AutoEQ**: ParametricEQ.txt (filters taken as they are), GraphicEQ.txt, AutoEQ CSV
  (equalization / error_smoothed / raw + target columns)
- **Open Sound Meter**: CSV, TXT or FRD export of a measurement (frequency, magnitude, phase, coherence)
- Any simple "frequency, dB" CSV / TXT (REW, etc.)

For a curve (CSV, measurement), the script computes the bands (Peak + shelves) that reproduce
the correction: number of bands, frequency range, max boost / cut / Q, smoothing, target slope.
A measurement is inverted (correction = average level - measurement), weighted by the OSM coherence.

Outputs (pick any, can be combined):
- **A**: applies the bands to the ZL Equalizer 2 of the selected track (or of the ZL FX window
  in front; offers to add it if missing). Preamp -> Output Gain.
- **C**: copies the bands to the clipboard in ZL format: right-click in ZL > Paste.
  A _ZLEQ2_bands.xml file is also written next to the source file.
- **M**: writes the curve (measurement or target) as an EQ Match target in
  ZL Audio/ZL Equalizer 2/Match Presets (EQ Match > Target: Preset).

<a id="pkg-todoroki-portable-backup-lua"></a>

### Portable Backup

**Main file**: `Scripts/Portable Backup/Todoroki_Portable Backup.lua`  
**Version**: 1.1 (2026-10-28)  
**README**: `Scripts/Portable Backup/Todoroki_Portable README.md`

Save, restore, clean and clear the configuration of a **portable REAPER on Windows**.
It replaces the old `backup_reaper.bat`, `save_reaper.bat` and `restore_reaper.bat`, and reads their backups.

#### Actions

| Action | What it does |
|---|---|
| **Todoroki_Portable Backup** | Pick the items to save (**All** is selected by default) and the destination |
| **Todoroki_Portable Restore** | Pick a backup and the items to bring back. REAPER closes, files are copied back, REAPER relaunches |
| **Todoroki_Portable Clean backups** | Delete old backups (nothing selected by default, confirmation required) |
| **Todoroki_Portable Clear user data** | Empty your personal data so the next person gets a clean REAPER |

Copies run in a PowerShell window with robocopy, so REAPER never freezes. `Enter` runs, `Esc` closes.

#### Items

- **REAPER**: every `*.ini` at the root, then ColorThemes, Data, Effects, FXChains, KeyMaps, LangPack, MenuSets,
  presets, ProjectTemplates, ReaPack, Scripts, TrackTemplates, User, UserPlugins
- **Todoroki data**: RefLab references (`Data/references`) and the RS Trig library
  (`Data/RSampler`, `Data/RSampler_TCI_WAV`, `Data/RSampler_Unpacked`).
  These stay separate from the "Data" item, so a big sample library can be left out
- **Plugin User folders**: Neural Amp Modeler, Vital, Decent Sampler.
  Default locations are `<drive>\NAM`, `<drive>\Vital`, `<drive>\DS` (drive of the REAPER folder).
  Change them with **Folders...** (each folder must contain `User`)

Items missing from the install (or from the backup) are greyed out.

#### Destinations

| Choice | Folder |
|---|---|
| Temporary | `%TEMP%\REAPER_Backup_<date>`: quick round trip around an update |
| Archive | `<drive>\REAPER_Saves\REAPER_Save_<date>` (changeable with **Folders...**) |
| Custom folder | `<your folder>\REAPER_Save_<date>` |

Each backup gets a `Todoroki_Portable.manifest` file (date, REAPER version, items).

#### Updating REAPER

1. **Todoroki_Portable Backup**, Temporary, tick **Close REAPER before copying** (catches unsaved preferences)
2. Install the new REAPER over the portable folder
3. Start REAPER, run **Todoroki_Portable Restore** (the last backup is preselected), restore

#### Sharing the portable REAPER (Clear user data)

1. Arriving: **Todoroki_Portable Restore** with your own backup (shortcuts, samples, presets...)
2. Leaving: **Todoroki_Portable Clear user data**. A copy is saved to the archive first (on by default),
   REAPER closes, your data is emptied, REAPER relaunches clean
3. The next person does the same with their own backup

What is cleared (all ticked by default): settings and shortcuts (`*.ini`), ColorThemes, Data, FXChains, KeyMaps,
MenuSets, presets, templates, User, RefLab references, RS Trig library, plugin User folders.

Installed tools (Effects, LangPack, ReaPack, Scripts, UserPlugins) are **not** ticked by default, so ReaPack packages
and extensions stay installed. Tick them for a fully empty REAPER.

Always kept, whatever is ticked:
- `reaper.ini` is reset to an empty file instead of deleted (REAPER stays in portable mode)
- the ReaPack extension (`UserPlugins/reaper_reapack*`) and these Todoroki_Portable scripts
- script registrations in `reaper-kb.ini` (shortcuts and custom actions are removed), so the actions stay in the Actions list
- if the copy fails, nothing is deleted

After a clear, Restore no longer preselects your backup.

#### Toolbar icons

On first run, the icons are copied into `Data/toolbar_icons` (with `150` and `200` versions for HiDPI):
`Todoroki_Portable Backup.png`, `Todoroki_Portable Restore.png`, `Todoroki_Portable Clean backups.png`,
`Todoroki_Portable Clear user data.png`.
Right-click a toolbar > Customize toolbar > Add the action > Icon.

Optional: with **js_ReaScriptAPI** installed, folders are picked with the Windows folder browser.

<a id="pkg-todoroki-fxlister-fx-param-idx-lister-lua"></a>

### FX Param_idx Lister

**Main file**: `Scripts/Todoroki_FXLISTER_FX Param_idx_Lister.lua`  
**Version**: 1.0 (2026-10-20)

> Use it with **FX Lua Creator**: the list printed in the console is pasted into the Python tool.

Lists the parameters of a plugin and their indexes.

<a id="pkg-todoroki-fxlist-fx-lua-creator-py"></a>

### FX Lua Creator (Python)

**Main file**: `Python Utilities/Todoroki_FXLIST_FX_lua_Creator.py`  
**Version**: 1.2 (2026-10-20)

Creates toggle actions (for the toolbar) from the parameters of a plugin.
External tool: run it with Python, outside REAPER.

---

## Extras (not installed by ReaPack)

- `Stream Deck/Todoroki RefLab.streamDeckIconPack`: Stream Deck icon pack for the RefLab actions (sources in `Stream Deck/com.todoroki.reflab.sdIconPack/`).
- `Scripts/RS Trig Sampler/Todoroki_RS Trig TCI Converter.html`: Web page (Chrome / Edge) that converts a whole Slate Trigger 2 library; installed with RS Trig Kit Builder.
- `AIDE-MEMOIRE.txt`: Repository rules: where to put files, header template, how to publish an update.

