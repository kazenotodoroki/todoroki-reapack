# Todoroki Portable Backup

Save, restore and clean the configuration of a **portable REAPER on Windows**.
It replaces the old `backup_reaper.bat`, `save_reaper.bat` and `restore_reaper.bat`, and reads their backups.

## Actions

| Action | What it does |
|---|---|
| **Todoroki_Portable Backup** | Pick the items to save (**All** is selected by default) and the destination |
| **Todoroki_Portable Restore** | Pick a backup and the items to bring back. REAPER closes, files are copied back, REAPER relaunches |
| **Todoroki_Portable Clean backups** | Delete old backups (nothing selected by default, confirmation required) |

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

## Toolbar icons

On first run, the icons are copied into `Data/toolbar_icons` (with `150` and `200` versions for HiDPI):
`Todoroki_Portable Backup.png`, `Todoroki_Portable Restore.png`, `Todoroki_Portable Clean backups.png`.
Right-click a toolbar > Customize toolbar > Add the action > Icon.

Optional: with **js_ReaScriptAPI** installed, folders are picked with the Windows folder browser.
