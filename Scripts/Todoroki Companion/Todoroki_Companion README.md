# Todoroki Companion

A **single** background service for all the Todoroki tools. Only one script runs all the time;
each tool adds its own **module** to it instead of starting its own background script.

- **Todoroki_Companion** action: starts the service (run the action again = stop it; state shown on toolbars).
- **Todoroki_Companion autostart (on-off)**: start together with REAPER (a line in `Scripts/__startup.lua`,
  path relative to the REAPER folder → fine with portable REAPER, even if the drive letter changes).
- **Todoroki_Companion status and modules**: reloads the modules and prints the log in the console.

Debug: `reaper.SetExtState("Todoroki_Companion", "debug", "1", false)` prints the log live.

---

## Adding a module (for a future tool: drum triggers, sample finder…)

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

### Toolbox `C` passed to the modules

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

## Using the Companion from a Lua script

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

Module `"core"`: `ping`, `version`, `reload`, `modules`, `open_folder`, `log`.

## Using the Companion from a JSFX

A JSFX cannot see ExtState: it goes through **gmem** (`options:gmem=<Name>`), with a module of the same name.
Recommended convention (the one RefLab uses):

| Slot | Purpose |
|---|---|
| `gmem[0]` | heartbeat written by the module every cycle (lets the JSFX know the Companion is running) |
| `gmem[1]` | request from the JSFX to the module (reset to 0 by the module) |
| `gmem[2]` | command from the REAPER actions to the JSFX (reset to 0 by the JSFX) |
| `gmem[3…99]` | free (versions, counters…) |
| `gmem[100…]` | data (strings: 1 character per slot, 0 terminated) |

To keep something **per project** (like RefLab's references), store it from the module with
`reaper.SetProjExtState(0, "<Name>", key, value)`: it is saved in the .rpp file. Watch the
current project with `reaper.EnumProjects(-1)` to reload it when the user opens a project or changes tab.
