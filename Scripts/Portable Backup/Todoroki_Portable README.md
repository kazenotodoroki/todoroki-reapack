# Todoroki Portable Backup

Save, restore, clean and clear the configuration of a **portable REAPER on Windows**.
It replaces the old `backup_reaper.bat`, `save_reaper.bat` and `restore_reaper.bat`, and reads their backups.

## Actions

| Action | What it does |
|---|---|
| **Todoroki_Portable Backup** | Pick the items to save (**All** is selected by default) and the destination |
| **Todoroki_Portable Restore** | Pick a backup and the items to bring back. REAPER closes, files are copied back, REAPER relaunches |
| **Todoroki_Portable Clean backups** | Delete old backups (nothing selected by default, confirmation required) |
| **Todoroki_Portable Clear user data** | Empty your personal data so the next person gets a clean REAPER |

Copies run in a PowerShell window with robocopy, so REAPER never freezes. `Enter` runs, `Esc` closes.

## Items

- **REAPER**: every `*.ini` at the root, then ColorThemes, Data, Effects, FXChains, KeyMaps, LangPack, MenuSets,
  presets, ProjectTemplates, ReaPack, Scripts, TrackTemplates, User, UserPlugins
- **Todoroki data**: RefLab references (`Data/references`) and the RS Trig library
  (`Data/RSampler`, `Data/RSampler_TCI_WAV`, `Data/RSampler_Unpacked`).
  These stay separate from the "Data" item, so a big sample library can be left out
- **Plugin User folders**: Neural Amp Modeler, Vital, Decent Sampler.
  Default locations are `<drive>\NAM`, `<drive>\Vital`, `<drive>\DS` (drive of the REAPER folder).
  Change them with **Folders...** (each folder must contain `User`)

Items missing from the install (or from the backup) are greyed out.

## Destinations

| Choice | Folder |
|---|---|
| Temporary | `%TEMP%\REAPER_Backup_<date>`: quick round trip around an update |
| Archive | `<drive>\REAPER_Saves\REAPER_Save_<date>` (changeable with **Folders...**) |
| Custom folder | `<your folder>\REAPER_Save_<date>` |

Each backup gets a `Todoroki_Portable.manifest` file (date, REAPER version, items).

## Updating REAPER

1. **Todoroki_Portable Backup**, Temporary, tick **Close REAPER before copying** (catches unsaved preferences)
2. Install the new REAPER over the portable folder
3. Start REAPER, run **Todoroki_Portable Restore** (the last backup is preselected), restore

## Sharing the portable REAPER (Clear user data)

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

## Toolbar icons

On first run, the icons are copied into `Data/toolbar_icons` (with `150` and `200` versions for HiDPI):
`Todoroki_Portable Backup.png`, `Todoroki_Portable Restore.png`, `Todoroki_Portable Clean backups.png`,
`Todoroki_Portable Clear user data.png`.
Right-click a toolbar > Customize toolbar > Add the action > Icon.

Optional: with **js_ReaScriptAPI** installed, folders are picked with the Windows folder browser.
