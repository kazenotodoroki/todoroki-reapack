# RefLab

Comparaison de ton mix avec des morceaux de référence, directement dans REAPER (JSFX, compatible REAPER portable).

## Installation (ReaPack, dépôt Todoroki)

Installer les trois paquets :

1. **RefLab** (le plugin, catégorie FX)
2. **RefLab - actions et module Companion**
3. **Todoroki Companion**

Puis :

- Lancer une fois l'action **Todoroki Companion - Autostart (on-off)** : le Companion démarrera avec REAPER.
- **View > Monitoring FX > Add > JS: RefLab** (le Monitoring FX n'est jamais inclus dans un rendu).

## Fichiers de référence

- Dossier : `<REAPER>/Data/references` (bouton **DOSSIER REFS** du plugin).
- WAV, FLAC, MP3, OGG, AIFF… La liste se met à jour toute seule ; bouton **ACTUALISER** pour forcer.
- Sans le Companion, le menu montre les fichiers présents à l'ouverture du plugin.

## Utilisation

| Où | Quoi |
|---|---|
| Emplacements 1 à 4 | clic : choisir le fichier ; « … » ou clic droit : menu |
| MIX / REF, touche **A** | écouter le mix ou la référence (fondu 15 ms) |
| MATCH | OFF / INTÉGRÉ / SHORT-T : alignement automatique du niveau de la référence |
| Forme d'onde | glisser : boucle ; clic : position ; clic droit : boucle off ; touche **L** |
| VITESSE, touche **V** | RAPIDE (0,12 s) / MOYEN (0,4 s) / LENT (1,5 s) / TRÈS LENT (5 s) / MOY. INF |
| Clic droit sur VITESSE, touche **R** | remise à zéro de la moyenne du spectre |
| PENTE, OCT | pente d'affichage (dB/oct) et lissage en fréquence |
| Molette / Ctrl + molette | niveau / plage du spectre |
| LECTURE, touche **P** | lire les références sans lancer le transport |

En **MOY. INF**, le spectre est la moyenne de tout ce qui a été joué depuis la remise à zéro
(les silences sont ignorés) : idéal pour comparer l'équilibre tonal global d'un morceau entier.
La moyenne repart de zéro quand on change de vitesse ou de référence.

## Assignation MIDI / clavier

- **Paramètres du plugin** : bouton *Param* de la fenêtre FX > *Learn*. Tous les réglages, plus des
  boutons « [Bouton] » (bascule MIX/REF, référence suivante/précédente, boucle, reset intégré,
  mode match suivant, vitesse spectre suivante, reset moyenne spectre).
- **Actions « RefLab - … »** dans la liste d'actions : *Add shortcut*, puis appuyer sur la touche
  ou bouger le contrôle MIDI (*Préférences > MIDI devices* : activer *Enable input for control messages*).

## Mise à jour depuis la version 1.1 (installée à la main)

- Supprimer `<REAPER>/Effects/RefLab.jsfx` (sinon deux « JS: RefLab » dans la liste).
- Supprimer le dossier `<REAPER>/Scripts/RefLab` (anciennes actions et ancien companion).
- Lancer **Todoroki Companion - Autostart (on-off)** : il retire l'ancienne ligne RefLab de `__startup.lua`.
- Réinsérer RefLab dans le Monitoring FX et recharger les références.
