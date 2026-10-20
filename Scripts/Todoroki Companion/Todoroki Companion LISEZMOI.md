# Todoroki Companion

Service d'arrière-plan **unique** pour tous les outils Todoroki. Un seul script tourne en
permanence ; chaque outil y ajoute son **module** au lieu de lancer son propre script de fond.

- Action **Todoroki Companion** : démarre le service (relancer l'action = l'arrêter ; état visible en toolbar).
- **Todoroki Companion - Autostart (on-off)** : démarrage avec REAPER (ligne dans `Scripts/__startup.lua`,
  chemin relatif au dossier REAPER → OK en portable, même si la lettre de la clé change).
- **Todoroki Companion - Etat et modules** : recharge les modules et affiche le journal dans la console.

Debug : `reaper.SetExtState("Todoroki_Companion", "debug", "1", false)` affiche le journal en direct.

---

## Ajouter un module (pour un futur outil : trigs de batterie, recherche de samples…)

1. Créer un fichier nommé **`Todoroki_Companion_Module_<Nom>.lua`** n'importe où dans le dépôt
   (ex. `Scripts/DrumTrig/Todoroki_Companion_Module_DrumTrig.lua`). Le Companion cherche ces fichiers
   dans tout le dossier du dépôt installé (`Scripts/Todoroki/…`, 4 niveaux).
2. Le déclarer dans le `@provides` du paquet de l'outil (sans `[main]`).
3. Lancer **Etat et modules** (ou redémarrer REAPER) pour le charger.

```lua
-- Todoroki_Companion_Module_DrumTrig.lua
local M = {
  name     = "DrumTrig",   -- nom unique (utilise par l'API)
  gmem     = "DrumTrig",   -- optionnel : namespace gmem attache avant chaque appel
  interval = 1.0,          -- optionnel : periode de M.slow en secondes (1,5 par defaut)
}

function M.init(C) end     -- au chargement
function M.tick(C) end     -- a chaque cycle (~30/s) : rester tres court
function M.slow(C) end     -- toutes les `interval` secondes
function M.exit(C) end     -- a l'arret ou au rechargement

-- commandes appelables depuis un script Lua via l'API
M.commands = {
  find_samples = function(C, arg)
    -- arg et la valeur de retour sont des chaines
    return "ok"
  end,
}

return M
```

Une erreur dans un module est capturée et journalisée ; après 20 erreurs le module est désactivé,
les autres continuent de tourner.

### Boîte à outils `C` passée aux modules

| Fonction | Rôle |
|---|---|
| `C.res`, `C.sep`, `C.dir` | dossier REAPER, séparateur, dossier du Companion |
| `C.path(a, b, …)` | joindre des chemins |
| `C.now()` | `time_precise()` |
| `C.log(qui, msg)` | journal (console si debug) |
| `C.get(k, def)` / `C.set(k, v, persist)` | réglages (ExtState section `Todoroki_Companion`) |
| `C.open_folder(dir)` | ouvre un dossier (Explorateur / Finder) |
| `C.list_files(dir, exts)` / `C.list_dirs(dir)` | contenu d'un dossier, trié, cache REAPER vidé |
| `C.AUDIO_EXT` | `{ wav, flac, mp3, ogg, aif, aiff, wv, opus }` |
| `C.scan(root, opts)` | **scan récursif asynchrone** (4 ms max par cycle, ne bloque jamais REAPER) |
| `C.gmem_write_string(base, s, max)` / `C.gmem_read_string(base, max)` | chaînes en gmem pour les JSFX |
| `C.module(nom)`, `C.reload()` | accès à un autre module, rechargement |

```lua
-- exemple : indexer une librairie de samples sans figer REAPER
local job = C.scan("D:/Samples/Drums", {
  exts = C.AUDIO_EXT, max_depth = 12,
  on_file = function(path, name) end,            -- optionnel, appele pour chaque fichier
  on_done = function(files, job) C.log("DrumTrig", #files .. " samples") end,
})
-- job.done, job.files, job.dirs_done, job.cancel()
```

---

## Utiliser le Companion depuis un script Lua

```lua
local dir = reaper.GetExtState("Todoroki_Companion", "dir")
if dir == "" then dir = reaper.GetResourcePath() .. "/Scripts/Todoroki/Scripts/Todoroki Companion/" end
local TC = dofile(dir .. "Todoroki_Companion_API.lua")

if not TC.running() then TC.start() end

TC.request("DrumTrig", "find_samples", "kick", function(ok, result)
  reaper.ShowConsoleMsg(tostring(result) .. "\n")
end)
```

| Fonction | Rôle |
|---|---|
| `TC.running()` / `TC.start()` | état / démarrage du service |
| `TC.modules()` / `TC.has(nom)` | modules chargés |
| `TC.call(module, cmd, arg)` → id, puis `TC.result(id)` | appel asynchrone manuel |
| `TC.request(module, cmd, arg, cb, timeout)` | appel avec rappel `cb(ok, valeur)` |
| `TC.open_folder(path)` | ouvrir un dossier |

Module `"core"` : `ping`, `version`, `reload`, `modules`, `open_folder`, `log`.

## Utiliser le Companion depuis un JSFX

Un JSFX ne voit pas l'ExtState : il passe par la **gmem** (`options:gmem=<Nom>`), avec un module du même nom.
Convention recommandée (celle de RefLab) :

| Case | Rôle |
|---|---|
| `gmem[0]` | battement de cœur écrit par le module à chaque cycle (le JSFX sait si le Companion tourne) |
| `gmem[1]` | requête du JSFX vers le module (remise à 0 par le module) |
| `gmem[2]` | commande des actions REAPER vers le JSFX (remise à 0 par le JSFX) |
| `gmem[3…99]` | libres (versions, compteurs…) |
| `gmem[100…]` | données (chaînes : 1 caractère par case, 0 final) |
