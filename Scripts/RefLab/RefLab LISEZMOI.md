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

## Mémoire par projet

Les références chargées, leurs boucles et la référence sélectionnée sont **enregistrées dans le projet**
(fichier .rpp) par le Todoroki Companion, même quand RefLab est dans le Monitoring FX.
À l'ouverture d'un projet ou au changement d'onglet, RefLab recharge les références de ce projet.
Un projet qui n'a encore rien d'enregistré garde les références en cours.

- Penser à **enregistrer le projet** (Ctrl+S) : le projet est marqué « modifié » quand tu changes de référence.
- Une seule instance de RefLab à la fois (dans le Monitoring FX de préférence).

## Utilisation

| Où | Quoi |
|---|---|
| Emplacements 1 à 4 | clic : choisir le fichier ; « … » ou clic droit : menu |
| MIX / REF, touche **A** | écouter le mix ou la référence (fondu 15 ms) |
| MATCH | OFF / INTÉGRÉ / SHORT-T : alignement automatique du niveau de la référence |
| Forme d'onde | glisser : boucle ; clic : position ; clic droit : boucle off ; touche **L** |
| VITESSE, touche **V** | RAPIDE 0,12 s · MOYEN 0,4 s · LENT 1,5 s · TRÈS LENT 5 s · ULTRA LENT 15 s · GLACIAL 45 s · MOY. INF |
| Clic droit sur VITESSE, touche **R** | remise à zéro du spectre (moyenne / lissage) |
| PENTE, OCT | pente d'affichage (dB/oct) et lissage en fréquence |
| Molette / Ctrl + molette | niveau / plage du spectre |
| LECTURE, touche **P** | lire les références sans lancer le transport |

### Vitesses lentes (régler une EQ en regardant le spectre)

De LENT à GLACIAL, les courbes **glissent doucement en dB** vers leur nouvelle valeur : une correction d'EQ
apparaît progressivement, sans à-coups. Au démarrage de la lecture, la courbe se cale rapidement (1,5 s),
puis passe en glissement lent. Quand la lecture s'arrête, la courbe **reste figée** (indiqué « figé »).

En **MOY. INF**, le spectre est la moyenne de tout ce qui a été joué depuis la remise à zéro
(les silences sont ignorés) : idéal pour l'équilibre tonal global d'un morceau entier.

### Courbe d'écart (REF − MIX)

- **CENTRE** (par défaut) : l'écart moyen entre la référence et le mix est retiré, la courbe montre la
  **différence d'équilibre tonal** (indépendante du volume). Le décalage moyen est affiché dans le titre.
  **ABSOLU** : écart brut.
- **AUTO** : l'échelle s'adapte (±3, 6, 12 ou 24 dB) ; ou échelle fixe. Touche **E**.
- **LISS.** : lissage propre à la courbe d'écart (1/3 d'octave par défaut, ou 1/6, 1 octave, comme le spectre).
- Orange = la référence a plus d'énergie, bleu = le mix en a plus.

### Isolation de bandes et sortie (façon ISOL8)

Le bandeau **BANDES** agit sur ce que tu écoutes, **mix et références** (les mesures LUFS et le spectre
restent pleine bande).

| Où | Quoi |
|---|---|
| Clic sur une bande, **F1 à F5** | écouter cette bande seule (re-clic : retour pleine bande) |
| Ctrl/Maj + clic, clic droit, Maj + F1-F5 | ajouter / retirer une bande (écouter plusieurs bandes) |
| **FULL**, touche **I** | mettre l'isolation en pause / la reprendre (les bandes choisies sont gardées) |
| Lignes orange sur le spectre | glisser pour déplacer les fréquences de coupure (120, 500, 2k, 6k par défaut) |
| **SORTIE** : STEREO / MONO / SIDE / G / D, touche **M** | mode d'écoute |

Filtres Linkwitz-Riley 24 dB/oct : la somme de toutes les bandes est parfaitement plate. Quand aucune
bande n'est isolée, le signal n'est pas traité du tout.

## Assignation MIDI / clavier

Chaque réglage est assignable de deux façons :

- **Paramètres du plugin** : bouton *Param* de la fenêtre FX > *Learn*. Tous les réglages (écoute, référence,
  match, trim, pente, lissage, vitesse, isolation et chaque bande, fréquences de coupure, mode de sortie,
  courbe d'écart…), plus des boutons « [Bouton] » pour les pads (bascule MIX/REF, référence suivante,
  boucle, solo exclusif de chaque bande, mode de sortie suivant…).
  Pour un pad sur un paramètre on/off, choisir *Toggle* dans la fenêtre Learn.
- **Actions « RefLab - … »** (54 actions) dans la liste d'actions : *Add shortcut*, puis appuyer sur la
  touche ou bouger le contrôle MIDI (*Préférences > MIDI devices* : activer *Enable input for control messages*).

## Mise à jour depuis la version 1.1 (installée à la main)

- Supprimer `<REAPER>/Effects/RefLab.jsfx` (sinon deux « JS: RefLab » dans la liste).
- Supprimer le dossier `<REAPER>/Scripts/RefLab` (anciennes actions et ancien companion).
- Lancer **Todoroki Companion - Autostart (on-off)** : il retire l'ancienne ligne RefLab de `__startup.lua`.
- Réinsérer RefLab dans le Monitoring FX et recharger les références.
