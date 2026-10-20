# ChordMachineGun

Script dérivé de ChordGun (pandabot), installé à part : **ChordGun reste intact**, et une mise à jour ReaPack de ChordGun n'écrase rien ici.

## Installation
Par ReaPack (recommandé) : ajoute le dépôt `https://github.com/kazenotodoroki/todoroki-reapack/raw/main/index.xml` dans *Extensions → ReaPack → Import repositories*, puis installe **ChordMachineGun**. Toutes les actions apparaissent dans les sections *Main* et *MIDI Editor*. ChordGun peut rester installé à côté.

À la main : copie le dossier `ChordMachineGun/` dans `Scripts/`, puis charge `Todoroki_ChordMachineGun.lua`, `Todoroki_ChordMachineGun history.lua` et les actions voulues via *Actions → New action → Load ReaScript*.

Recommandé : l'extension **js_ReaScriptAPI** (ReaPack), pour Ctrl/Alt + chiffres et l'épinglage des fenêtres.

Les réglages de ChordMachineGun sont enregistrés séparément de ceux de ChordGun : les deux peuvent tourner en même temps.

## Historique
Bouton **Historique** en haut de la fenêtre principale. Il ouvre (ou ferme) une fenêtre à part.

- Chaque accord joué ou inséré devient un bouton, avec ses voix réelles (position, conduite de voix, canaux, doublures).
- Les répétitions immédiates du même accord ne sont pas dupliquées.
- Un trait bleu à gauche indique un accord qui a été inséré dans un item.
- Le libellé bleu en haut à droite donne l'origine de l'accord (« V de C majeur », « R de C »…).

Commandes :
- **clic** ou **← →** : rejouer l'accord exactement comme il a été joué. **↑ ↓** : rangée précédente ou suivante.
- **Maj+clic** ou **Maj+Entrée** : l'insérer dans l'éditeur MIDI (ou remplacer les notes sélectionnées).
- **Suppr** : retirer l'accord. **Clic droit** : menu (rejouer, insérer, retirer, tout effacer).
- Le bouton rond épingle la fenêtre (js_ReaScriptAPI). Clic droit dans une zone vide pour l'ancrer.

Rejouer depuis l'historique **n'ajoute rien** à l'historique. L'accord rejoué devient en revanche la référence de la conduite de voix, pour enchaîner naturellement.

L'historique est enregistré dans le projet (300 derniers accords).

## Contrôleurs (CC et vélocité)
Trois curseurs en haut du panneau de droite.

- **CC 1 et CC 2**
  - Clique sur l'étiquette pour changer de CC : Modulation, Expression, Volume, Brillance…, ou **Autre…** pour n'importe quel numéro.
  - Par défaut, chaque curseur suit le même numéro de CC venant de ton contrôleur.
- **Vélocité** : la vélocité des accords joués et insérés (1 à 127). Sans contrôleur appris, seule la souris la pilote. Clic sur l'étiquette pour oublier le contrôleur appris.

Pour tous les curseurs :
- **Souris** : glisser, ou molette (Maj = pas de 10).
- **L** (Learn) : touche ensuite n'importe quel bouton ou fader, il pilotera le curseur. L'entrée apprise s'affiche (« ← CC 21 »).
- **Annuler un Learn** : reclique sur **L**, appuie sur **Échap**, ou attends 10 secondes.

Les CC sont envoyés comme les accords, par le clavier virtuel, vers la piste armée qui le reçoit. Avec un split, ils partent sur chaque canal utilisé par les voix.

Ton contrôleur doit être activé comme entrée MIDI dans les préférences de REAPER.

## Conduite de voix
Active **Conduite de voix**, puis choisis la source de l'accord de référence. L'accord de référence est analysé en continu et affiché dans le panneau (nom reconnu, notes, source).

- **Live** (par défaut). La référence est, dans cet ordre de priorité :
  1. l'accord **tenu au clavier MIDI** ;
  2. pendant la **lecture**, l'accord qui sonne sous la tête de lecture ;
  3. sinon le plus récent entre le dernier accord joué au clavier et le dernier accord ChordMachineGun.

  Dès que tu déclenches un nouvel accord dans ChordMachineGun, il est placé dans le bon ordre depuis cet accord.
- **Item MIDI**. La référence est l'accord qui précède le curseur d'édition dans l'item. Quand on remplace plusieurs accords sélectionnés, chacun est conduit depuis celui qui le précède.

Le clavier doit être activé comme entrée MIDI dans les préférences de REAPER. Il n'a pas besoin d'être armé. Les prévisualisations ChordMachineGun (clavier virtuel) sont ignorées.

**Sél.** fixe les notes sélectionnées comme référence. **↺** l'efface.

Règles appliquées :
- pas de quintes ni d'octaves parallèles, ni directes aux voix extrêmes ;
- pas de chevauchement ;
- la 7e descend et la sensible monte ;
- on double de préférence la fondamentale ;
- le registre suit l'accord analysé.

**Renversement** choisit la note de basse. **Nombre de voix** : auto (= nombre de notes de la référence) ou 2 à 8.

## Clavier
- **← →** : changer de degré, **↑ ↓** : changer de type d'accord. Ça sélectionne **sans jouer** : l'accord et son voicing s'affichent.
- **Entrée** : jouer l'accord sélectionné. **Maj+Entrée** : l'insérer.
- **+ / −** : octave.
- **Maj+← →** : déplacer le curseur d'édition d'un pas de grille (ancien comportement des flèches).

## Ctrl et Alt : touches fiables
Avec Ctrl ou Alt maintenu, REAPER ne transmet pas toujours les chiffres et les flèches au script. ChordMachineGun lit donc l'état physique des touches grâce à l'extension **js_ReaScriptAPI** (ReaPack), la même que pour la punaise. Le pavé numérique fonctionne aussi.

Sans l'extension, un décodage de secours est tenté, mais il est moins fiable. Le clic dans la ligne fonctionne toujours.

## Degrés de la gamme de l'accord (Ctrl)
Maintiens **Ctrl** (Ctrl ou Cmd sur macOS). Une ligne au-dessus de la grille affiche les 7 degrés de la gamme dont la tonique est la fondamentale de l'accord sélectionné.

Exemple en Do majeur : G est sélectionné, la ligne affiche G Am Bm C D Em F#dim.
- **Ctrl+5** joue D.
- **Ctrl+4** joue C.
- **Ctrl+Maj+chiffre** (ou Maj+clic) insère l'accord.

La sélection ne bouge pas. En bleu : les accords absents de la gamme principale.

Choix de la gamme, dans le panneau (**Degrés (Ctrl)**) :
- **Selon l'accord** : accord majeur → gamme majeure, mineur → mineure naturelle.
- **Type de la gamme** : même type que la gamme principale.

Actions : `borrowed scale chord 1` … `7`.

## Transformations néo-riemanniennes (Alt)
Maintiens **Alt** (Option sur macOS). La ligne affiche les transformations de la triade de l'accord sélectionné (une 7e est ramenée à sa triade).

| Touche | Transformation | Exemple depuis C |
|---|---|---|
| 1 | **P** parallèle | Cm |
| 2 | **L** échange de sensible | Em |
| 3 | **R** relatif | Am |
| 4 | **N** Nebenverwandt (RLP) | Fm |
| 5 | **S** glissement (LPR) | C#m |
| 6 | **H** pôle hexatonique (LPL) | Abm |
| 7 | **PR** médiante chromatique | Eb |

Navigation (avec **Alt** maintenu) :
- **← →** : déplacer le focus sur les 7 cases, sans jouer.
- **Entrée** ou **chiffre 1…7** : jouer la transformation. On reste sur la même strate.
- **↓** : descendre dans la case focalisée. Elle devient le nouveau point de départ, sans jouer.
- **↑** : remonter d'une strate, sans jouer.
- **Maj** en plus : insérer au lieu de jouer.
- **Clic** sur une case : la jouer. **Clic** sur une étape du chemin (ex. `C → Am → F`) : y remonter directement.

Tu peux donc explorer les suggestions de suggestions en silence et n'écouter que ce qui t'intéresse. Le chemin repart de zéro quand tu changes d'accord dans la grille.

Les actions globales `PLR 1…7` (fenêtre fermée) jouent la transformation **et** descendent dedans, pour pouvoir enchaîner sans voir la ligne. `PLR back` remonte et joue l'accord.

Actions : `PLR 1 - P` … `PLR 7 - PR`, `PLR back`.

## Épingler la fenêtre
Le bouton punaise, en haut à droite, garde la fenêtre au premier plan.
- Il nécessite l'extension **js_ReaScriptAPI** (ReaPack).
- Il est inactif quand la fenêtre est ancrée.

## Position personnalisée
De la plus grave à la plus aiguë, ex. `1 5 3 13 9`.
- Jetons : `1` (ou R/T/F), `2 3 4 5 6 7 9 11 13`. Sans altération, 3/5/7/6 viennent de l'accord choisi,
  les extensions (9, 11, 13) viennent de la gamme.
- Altérations : `b9 #9 #11 b13 b5 #5 b7 7M` (ou `maj7`, `m3`).
- `+` après un jeton = une octave de plus (ex. `1 5+ 3`).
- Avec la conduite de voix : la position est conservée, le registre le plus proche est choisi.
  **Renversement auto** : choisit aussi la rotation la plus proche (idéal pour Drop 2 / Drop 3).

## Voix & canaux MIDI
- **Basse** : *Note la plus grave* (la voix 1 est la note la plus basse, quelle que soit sa fonction) ou *Fondamentale* (voix de basse séparée, sous l'accord).
- **Split** (presets) :
  - **Aucun** : toutes les voix sur le canal de l'éditeur MIDI.
  - **Toutes** : voix 1 → canal 1, voix 2 → canal 2…
  - **Basse seule** : basse → canal 1, toutes les voix supérieures → canal 2.
- **Canal par voix** : clique sur le badge `ch …` d'une voix pour lui choisir un canal (1 à 16, ou le canal par défaut). Le split passe alors en *personnalisé*.
- **Doublures** : `+` sur une voix ajoute une octave, une quinte, une tierce (chromatique ou dans la gamme) ou une valeur libre (`7`, `-12`, `g2` = 2 degrés de la gamme). Clic sur une pastille = suppression. Elles fonctionnent **avec ou sans split** et sortent sur le canal de leur voix.
- **Créer les pistes** : une piste par canal utilisé, alimentée par un envoi MIDI filtré sur ce canal (non destructif). Avec *Basse seule*, ça fait 2 pistes : basse et accord.
- **Éclater l'item MIDI** : copie les notes de chaque canal dans un item sur une nouvelle piste.

## Nouvelles actions
`toggle voice leading`, `toggle custom position`, `toggle MIDI channel per voice` (bascule Aucun ↔ Toutes),
`reset voice leading reference`, `toggle voice leading source (live / item)`, `set voice leading reference from selected notes`,
`explode MIDI item to voice tracks`, `borrowed scale chord 1…7`, `PLR 1…7`, `PLR back`, et le script de fenêtre `ChordMachineGun history`.
Toutes les actions commencent par `ChordMachineGun …` dans la liste d'actions.
