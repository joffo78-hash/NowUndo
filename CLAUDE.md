# Dripsody (ex-NowUndo) — mémoire de projet pour Claude

**Renommage du 24 nov. 2026 : le logiciel s'appelle maintenant « Dripsody ».** Seuls les textes **affichés** changent (titres de fenêtres, boîtes
de message, en-tête du looper, `desc:` des JSFX, titre de la page web, @description / @about ReaPack, nom du dépôt ReaPack). Les identifiants
internes gardent « NowUndo » / « nowundo » (ExtState, gmem `nowundo_sync`, dossiers `Data/NowUndo_*`, **noms de fichiers**, préfixe `NU_`) : ne
les renommer que sur demande (les noms de fichiers apparaissent dans la liste des actions de REAPER). Détection du looper par nom d'effet :
`fx_patterns` contient maintenant `dripsody` en plus de `nowundo`.

Looper 8 instances synchronisées pour **REAPER** : un JSFX (le moteur audio) + des scripts Lua (Launchpad,
Twister, MIDI Learn, 8 Looper Panel, Scenario, ponts web) + une télécommande web (`NowUndo.html`).
L'utilisateur est francophone (tutoiement), musicien, teste tout lui-même dans REAPER (Windows, buffer 128).

## Où est quoi

- Dépôt : `joffo78-hash/NowUndo`, branche de travail **`nowundo-v3.27`** (créée le 21 nov. 2026 depuis `nowundo-v3.26`, qui contient
  tout le travail jusqu'au 21 nov. ; `nowundo-v3.26` venait de `ccr-12a0f3a9-86p9ey`, travail jusqu'au 16 nov.).
- `NowUndo/NowUndo_V3.27.jsfx` : **version courante du JSFX** = V3.26 + dub brut A / D (fait par l'utilisateur) + bouton Mute
  (3.19 → 3.26 gardées pour l'historique). `NowUndo/NowUndo_V3.26.jsfx` : Faite à partir du
  fichier que l'utilisateur avait chargé dans REAPER (une V3.25 sans `slc_move`, remis ensuite : V3.26 = V3.25 + détection).
- `NowUndo/NU_DropCapture.jsfx` : capture du drop (posée temporairement par le Launchpad en bout de chaîne de la piste du looper cible).
- `NowUndo/Scripts/V3.21/` : tous les scripts courants (le nom du dossier est historique) :
  | Fichier | Rôle |
  |---|---|
  | `virtuallaunchpad_main.lua` | Launchpad (Mini MK3 + fenêtre virtuelle + serveur de la page web). Cœur de la logique : pages, groupes, routing, FX, macros/rushes, Ctrl/HOLD. **Page 4 = sous-pages de rushes a..z seulement** (V3.27, couches `rp1`..`rp26`). |
  | `Virtual_Launchpad_secondary.lua` | Miroir (3 pages non affichées), charge `virtuallaunchpad_main.lua` en `mirror_mode`. |
  | `twisterinoutreset.lua` | Midi Fighter Twister v3.5 (8 pages, page 7 Custom, page 8 Display, sélection d'effet FX Router). |
  | `nowundo_midi_learn.lua` | MIDI Learn v2.8 + raccourcis clavier (js_ReaScriptAPI), cumul clavier/MIDI, double appui. Écoute aussi le **MIDI des rushes** (table `RL`, V3.27). |
  | `NowUndo_8Looper_Panel.lua` | **OBSOLÈTE (24 nov.)** : ancien panneau 8 loopers. L'import de fichiers audio a été porté dans **8Waves** (voir `IMP` dans `NowUndo_8Waves.lua`). Gardé dans le dépôt, ne plus le modifier. |
  | `NowUndo_8Waves.lua` | Variante du 8 Panel : les 8 formes d'onde empilées, pleine largeur, affichage seul (couleurs d'état, Cloud + zone des grains, Slicer + slices, sync point, In/Out, tête, fond de la forme d'onde teinté de la couleur du looper (arrêt, et un peu plus sombre en lecture : plus de noir), cadre + fond teinté de la sélection / du groupe autour de la zone In/Out seulement, parties hors In/Out grisées ; étiquette : L n (partie seulement si ≠ MAIN) + sources entre parenthèses + état + REVERSE / SLICE / CLOUD + SP (speed ≠ 1) / PS (pitch ≠ 0) (« FX n » retiré le 27 nov. : colonne FX d'insert) ; M / S / F tout à droite ; VU vertical d'entrée à gauche (`+172`) et de sortie à droite (`+173`) ; état MUTE (`+199`) ; saturation de **tout le cadre** = Out Vol (`+22`) : 0 dB couleur pleine → -40 dB noir et blanc, courbe ^1.5, gris un peu assombri, textes / tête gardent une luminosité ≥ 0,8 ; Mute = noir et blanc ; VU d'entrée et cadre de groupe restent en couleur). Pas de paramètres, sources ni boutons ; **interactif depuis le 21 nov.** (voir « 8Waves interactif ») ; **import de fichiers audio depuis le 24 nov.** (voir ci-dessous). Fenêtre `NowUndo_8Waves`. |
  | `NowUndo_Scenario.lua` | Séquenceur de scénarios + **Rushes** (ex « macros ») : éditeur, assistant, palette ; V3.27 : cibles dans les rushes, sous-pages de la page 4 (+ PAGE / NOM / SUPPR), MIDI par rush, modèle de démarrage. |
  | `NowUndo_Twister_Web.lua` | Pont gmem ↔ ExtState pour l'onglet Twister In/Out et l'onglet **Loopers** du web. |
  | `NowUndo_Latency.lua` | Réglage global de la compensation de latence (V3.23). |
  | `NowUndo_VirtualPedalBoard.lua` | Pédalier virtuel (G-Board / FCB1010 / M-Vave). Deux réglages **séparés** : **LEARN PÉDALE** (clic sur un switch → appui sur la vraie pédale = son MIDI) et **ACTION** (clic sur un switch ou appui sur sa pédale → clic sur un pad du Launchpad / knob du Twister via `NowUndo_Pedal/capture`, ou clic droit > liste) ; Échap = annuler. Témoin MIDI en bas (dernier message reçu + ce qu'il déclenche), le switch s'allume à chaque appui. Modes Gate / Toggle / Absolu, cible = sélection ou looper n. Actions Launchpad (Exclu, Sync, Drop, sélection) via `NowUndo_Pedal/lp_cmd`. V3.25 : + Mute, + Drop. |
  | (Auto-Tempo) | Script `nowundoautotempoembeded.lua` **supprimé** (retiré de `__startup.lua`) : AUTO-TEMPO fusionné dans le **MSV3** (`NowUndo/master_synchro` : AUTO-SYNC gmem 95, réglage des temps Auto / 1-2-4 mesures / menu, slider10 `at_force`, publie **917** tempo voulu, **918** temps, **919** compteur des temps forcés) + le **Launchpad** (`VL.autotempo_tick` dans `VL.render` : maître MAIN → `SetCurrentBPM`, `VL.align_reaper`, PLAY si arrêté ; Unlock → STOP). L'ancien script réécrivait aussi la synchro Host (en concurrence avec le MSV3, piste possible du « saut à chaque mesure » du 20 nov.). Le MSV3 est le **seul maître de la synchro** (Host, grille de sortie 99, Start Sync 94, Re-phase 93/92). Tests `tools/tmsv3.py`, `tools/tlp_autotempo.lua`. |
  | `NowUndo.html` | Télécommande web v4.0 (onglets Launchpad / Twister / Loopers), à copier dans `reaper_www_root`. |
  | `virtual_launchpad_web.lua` | **Obsolète, ne pas lancer** (doublon qui volait les commandes web). |
- `NowUndo/Scripts/V3.21/FX_Router_v2.lua` (ReaImGui, v2.11 : `ImGui_End` seulement si `Begin` renvoie visible ; clic droit = Docker / Détacher, docker mémorisé `FXRouter/dock`) : choix de l'effet de chaque container (lib JSFX `Effects/MonRig`, 4 containers par piste, source suivie depuis `nowundo_vl/fx_source`). **Il ne bypasse jamais les containers** : l'activation des slots est faite par le Launchpad (`VL.apply_fx`).
- `tools/` : outils de test (voir plus bas).

## Protocoles (à respecter)

**gmem `nowundo_sync`** : bloc par looper/part = `1000 + i*600 + part*200` (i = 0..7, part = 0..2).
`+2` état (0 stop, 1 rec, 2 play, 3 dub, 4 replace, 5 auto-rep, 6 multiply, 7 attente, 8 sync) · `+42` part active ·
`+44/+45/+46` loop start / width / length · `+47` pos % · `+48` **commande** · `+49` argument ·
`+50..149` forme d'onde · `+155` BPM estimé · `+160..162` édition In/Out/Width · `+172/+173` VU in/out ·
`+156/+157/+158` warp (état / grille / force) · `+159` mode d'overdub (V3.27 : 0 = A compensé, 1 = D brut, lecture seule) · `+178/+179` zone des grains du Cloud en % (V3.26) · `+180` id de paramètre à écrire, `+181` valeur (V3.25 : 2 boîtes de plus `+195/+196` et `+197/+198`) · `+19` feedback · `+20` dégradation · `+21` stéréo · `+22` out vol ·
`+182..184` sync point / ref / len du maître. **Le bloc de 200 et les 60 paramètres (`110000 + (i*3+part)*60`) sont pleins** : publication supplémentaire V3.27 en `112000 + (i*3+part)*20` (+0 = lissage du LFO Random du Cloud). Global : `0..24` Master Sync par part (`[o]==1` maître looper, `==2` Host,
`[o+2]` longueur, `[o+3]` position), `100+i` vivant, `130+i` heartbeat, `950/951` heure de l'appui + adresse cible (V3.22), `95` AUTO-SYNC, `917/918/919` Auto-Tempo, `921` battement du MSV3 (tempo voulu / temps / compteur, publiés par le MSV3),
`955/956/957` latence auto (samples) / décalage ms / 2 = coupée (V3.23), `LD_BASE=1000000` import de fichiers
(sert aussi d'enregistrement au drop), **drop de groupe (V3.25)** : `300 + k*10` accusé du looper k (+0 jeton, +1 horloge
du passage, +5 durée entendue), `380` signal final (jeton+0.5 bascule / +0.75 abandon), `381` cible, `393` départ capture,
`394` fin capture, `395` gain (1/volume piste cible), `396` latence PDC. **Tableau de bord (Launchpad)** : `6000+i` groupe, `6010+i` / `6020+i` masques des sources, `6030+i` masque des slots FX actifs du looper i (V3.26), `6040+n` masque des slots FX actifs de l'entrée n (V3.27). `6050+n` = 1 si l'entrée n est sortie du parent (« in mute », V3.27). `6060` masque de la sélection, `6061` heure (clavier MIDI, V3.27). **Nouveau REC (V3.25)** : `398` heure, `399` id.

**Commandes JSFX (+48)** : 1 rec/dub, 2 clear, 3 stop/play, 4 reverse, 5 ping-pong, 6 slicer, 7 cloud, 8 link,
9 replace, 10 auto-replace, 11 clear full, 12 part, 13 multiply, 14 undo, 15 redo, 16 restart, 17 re-rec, 18 one-shot,
19 auto, 20 speed step, 21 pitch step, 22 full loop, 23 quantise, 24 reset, 30 exclu, 31/32 import (copie / requête longueur), 33 beat repeat,
34/35/36 drop (horloge du passage sur la cible / source en attente d'effacement / copie de l'enregistrement ; arg = jeton),
37 mute (arg 0 bascule / 1 on / 2 off ; état publié en `+199`), 38 warp, **39 dub A / D** (V3.27 : arg 0 bascule / 1 = D / 2 = A).
**Paramètres (+180)** : 3 speed, 4 pitch, 5 mix, 7 fade, 19 fdbk, 20 dégradation, 21 stéréo, 22 out vol, 26-28/35/36/38-41 cloud,
29/30 rec density, 59 loop quant, 60 BR mix, 61 slicer mix, 62-64 cloud v2, 65/66 warp grille / force, **67 dub A (0) / D (1)** (V3.27), **68 lissage du LFO Random** (V3.27, slider69 ; **69 pitch absolu**, **70 gamme du Scaler** ; 39 forme du LFO = 0..3, 3 = Random).

**ExtState** : `nowundo_vl` (état partagé du Launchpad : `state` + `rev`, `web_cmd`/`web_ack`, `web_frame/labels/meta`,
`fx_source`, `fx_slot`, `sel_looper`, `fighter_page`, `active_page`) · `NowUndo_VLcmd/q` (file de commandes externes vers le
Launchpad : lignes `nom\ttemps`, ex. `fxg_<looper>_<slot>_tog`, `fx_…`, `fxin_…`, `preset_…`, `sync_on`, `rec_dub_toggle`, `drop_group`, V3.27 : `grp_<l>_<g>`, `grpoff_<l>_<g>`, `lppage_<n>`, `p4page_<k>`, `twpage_<n>`) ·
`nowundo_tw` (Twister + web : `tw_*`, `lv_fast`, `lv_wave`, `web_cmd`) · `NowUndo_MIDILearn` (maps, `custom`, `maps_kbd`,
`kbd_intercept`) · `NowUndo_Scn` (`mcr` déclenchements de rushes `id\tcibles\ttemps\ton|off`, `alive`, `typing`) ·
`NowUndo_Macros` (rushes partagés : `set` = lignes `M` rushes, `L case id` (case = (page-1)*64 + 1..64), `P n nom` sous-pages (V3.27) ; `rev`, `on`, `pend`) · `NowUndo_Latency` (`on`, `offset_ms`) · `NowUndo_Clock/align`.

**Web Launchpad** : commandes numérotées `@sid;#n:cmd;…` + accusé `web_ack` (repli automatique sur l'ancien format si
pas d'accusé). Commandes : `P/R/D,row,col`, `H,0|1`, `L,layer`, `PAGE,n`, `SEL,i`, `ACT,i,action`. La page web a **sa
propre page Launchpad** (`VL.web_with_page`).

## Règles de code (pièges déjà rencontrés)

- **RÈGLE ABSOLUE In / Out / Width (l'utilisateur l'a répétée ~20 fois, ne JAMAIS la changer)** :
  **mode Width actif = In et Out AIMANTÉS** : Width règle l'écart, In DÉCALE la fenêtre et l'écart ne bouge pas
  (commande d'édition **5**, In borné à longueur − width). **Mode Out (Width pas actif) = In et Out COMPLÈTEMENT
  AUTONOMES** : In bouge seul, Out reste (commande **1**) ; Out bouge seul (commande **2**). Le mode : JSFX `loop_edit_mode`
  (+ Beat Repeat = aimanté) ; Twister `tw_mode_io[looper]` (page 1, et **pages 7 / 9 suivent le même mode** : le push Out
  de la page 9 bascule `tw_mode_io` du looper sélectionné). Sans notion de mode (MIDI Learn, Launchpad `loop_in_step`,
  8Waves poignée In, web, rushes `in`) = autonomes (commande 1) ; glisser le milieu de la fenêtre (8Waves) = commande 5.
  **Erreur du 24 nov. à ne pas refaire** : tout passer en commande 5 « partout » (même en mode Out) → annulé le jour même.

- **Lua : 200 variables locales max au niveau principal.** `virtuallaunchpad_main.lua` ≈ 143 (fonctions rangées dans
  `VL.*`, `LPF.*`), `NowUndo_Scenario.lua` ≈ 193 (**presque plein** : ranger le neuf dans la table `ED` ou `H._xxx`),
  `twisterinoutreset.lua` ≈ 172. Vérifier avec `python3 tools/lualoc.py <fichier>` après chaque modif.
- Lua : une `local function` n'est visible qu'après sa déclaration ; pour un appel « en avant », passer par un champ de table.
- **EEL2 (JSFX) : `min()` / `max()` prennent exactement 2 arguments** (erreur de compilation sinon ; le traducteur Python
  ne le détecte pas). Mettre des parenthèses autour des branches d'un `? :` qui contiennent des affectations.
- `CU_KNOBS` / `CU_BTNS` / `CU_FAM_NAME` doivent rester **identiques** dans `nowundo_midi_learn.lua` et `twisterinoutreset.lua`.
- Dans le Scenario, la table `H` contient les mots de la syntaxe : `split_key` n'accepte que les entrées de type fonction.
- Ne jamais renommer les identifiants internes (ExtState, dossiers, formats) : seulement les textes affichés.
- Un seul script Launchpad doit tourner (deux = page web qui « vacille », effets qui se battent) : **verrou d'instance** (`nowundo_vl/lp_hb`) ; le FX Router aussi (`FXRouter/hb`). Le miroir (`Virtual_Launchpad_secondary`) n'écrit jamais sur les pistes (`apply_fx` / `apply_routing` sortent en `mirror_mode` ou `VL_TEST`). `virtual_launchpad_web.lua` s'arrête tout seul (obsolète).
- Livraison : commit + push sur la branche, puis envoyer les fichiers modifiés à l'utilisateur (il les copie à la main
  dans REAPER ; `NowUndo.html` va dans `reaper_www_root`). Dire clairement ce qui n'a pas pu être testé dans REAPER.

## Préférences de l'utilisateur

- **Jamais de réglage « +1 par clic »** quand il y a beaucoup de valeurs (ex. piste 1 → 30) : un **menu** (gfx.showmenu)
  ou un champ. Pas de boutons géants : hiérarchie claire (actions principales près de ce qu'elles touchent, le reste en
  groupes titrés, tous les boutons de taille normale).

- Répondre en français, simplement, sans jargon inutile ; il teste et revient avec des captures.
- Machines de test : PC fixe (Antelope Discrete 4, buffer 128) **et** portable avec la carte **Realtek + ASIO4ALL** (exprès,
  « pires conditions ») : latence annoncée par ASIO4ALL peu fiable → régler LAT / `NowUndo_Latency` à la main.
- **Proposer des alternatives quand son idée n'est pas optimale** (demandé explicitement), avec une recommandation.
- Il veut garder la cohérence entre Launchpad, web, MIDI Learn, Twister (même logique partout : groupes, double appui…).
- Il n'aime pas les ergonomies « à l'envers » (ex. choisir OFF avant l'action) ni l'absence de Retour arrière.

## RÉSUMÉ DE LA SESSION DU 21 NOV. (point de départ de la prochaine discussion)

Tout est poussé sur `nowundo-v3.27`, **rien n'a été testé dans REAPER** (bancs Python / mocks Lua seulement) : demander
d'abord ses retours à l'utilisateur. Détails dans les sections datées du 21 nov. plus bas.
1. **Synchro / tempo** : le **MSV3** (`NowUndo/master_synchro`) est le **seul** maître de la synchro (Host, grille de
   sortie, Start Sync, Re-phase). **Auto-Tempo fusionné** : le MSV3 choisit les temps (AUTO / 4 / 8 / 16 / menu) et publie
   le tempo (gmem 917-919), le **Launchpad** l'applique (`VL.autotempo_tick` : tempo, curseur calé, PLAY ; Unlock → STOP).
   Script `nowundoautotempoembeded.lua` **supprimé** et retiré de `__startup.lua` (il réécrivait aussi la synchro Host en
   concurrence avec le MSV3 : piste possible du « saut à chaque mesure » du 20 nov., à confirmer). Sliders natifs du MSV3
   **cachés** ; mesures Host et tolérance Re-phase en **menus** dans son interface (fenêtre 330 × 390). `opensync.lua` =
   simple raccourci qui ouvre la fenêtre du MSV3 (1er effet piste 10), facultatif.
   **En attente de réponse** : MSV3 dockable → (1) docker la chaîne d'effets de la piste 10 (natif, recommandé d'abord) ou
   (2) script « NowUndo Sync » dockable qui reprend son interface (remplacerait `opensync.lua`).
2. **FX Router v2.11** : clic droit = Docker / Détacher, docker retenu ; `ImGui_End` seulement si visible (corrige
   « End() too many times »).
3. **Rushes** : liste en pages, rushes d'usine en ROM et ordonnés, **FILTRE** par page du Launchpad / par cible (ciblés,
   all, non ciblés), clic sur « LP c1.3 » = affiche la sous-page sur le Launchpad, `*` / `*1/4` / `*2` quantisés sur le
   cycle du looper, palette « Cible », toggle `a` = interrupteur A / D, clic droit sur un pad vide de la page 4 = nouveau
   rush. **Scenario + Rushes fusionnés** (scénario à gauche = liste de rushes avec GO / BACK, rushes à droite).
4. **Drop** : DROP ON / OFF qui garde **tout** depuis ON, drop **solo**, drop fidèle en Slicer.
5. **8Waves** : gris sur tout le cadre selon Out Vol, fond teinté, **interactif** (sélection, tap de statut, Ctrl + clic
   groupe, flèches, In / Out et grains à la souris).
6. **JSFX V3.27** : ping-pong qui restait en reverse corrigé ; LFO **Random** + **Smooth** du Cloud ; page Cloud du Twister
   refaite (disposition de l'utilisateur).
7. Encore à vérifier depuis avant : migration de la page 4 (a RC-505, b, c, d Effets), `l3 to g2`, `in1 mute`, learn MIDI
   d'un rush, modèle de démarrage des rushes, carré A / D.
Idées proposées pas faites : recherche texte + tags perso dans les rushes ; retirer aussi `virtual_launchpad_web.lua` de
`__startup.lua` (obsolète) ; chantiers « tout est rush » et « Quantize global » (plus bas).

## 24 nov. : partage du projet (ReaPack) — inventaire des effets MonRig

- But de l'utilisateur : rendre NowUndo **facile à partager** → rester dans REAPER, paquet ReaPack à jour (l'`index.xml`
  actuel pointe encore sur les fichiers du 1er nov.), installateur / modèle de projet, `__startup.lua` par nom de fichier
  (les ids `_RS…` changent d'une installation à l'autre), notice. Projet de l'utilisateur reçu : pistes 1 « inputs »,
  2-9 entrées (4 containers), 10 « loopers » (MSV3, chargé depuis `js fx addons/mises à jour du 19 octobre/`), 11-18
  loopers (fichier `aNowUndo_V3.6` du même dossier), 19 `NowundoMidi.jsfx` **en bypass** (looper MIDI étape 1, ID Auto
  → prendrait l'ID 1 avec 8 loopers : à ne pas activer tel quel, pas dans le paquet), 20-24 « effets », 25-30 instruments perso.
- `tools/NowUndo_FX_Inventaire.lua` : inventaire de `Effects/MonRig` (72 effets ; poids = 307 PNG, 76 Mo, interfaces Tukan).
  Utilisés : joffo_stutter, Filters_LPHP, --bbddelay.jsfx, Lexikan (Tukan), 16rec.jsfx, Bricastic.jsfx (chmaha, GPLv3).
  Licences : Cockos (LGPL, déjà livrés avec REAPER), Stillwell (BSD), Liteon Tape (GPL), chmaha (GPLv3), chokehold (MIT),
  Justin Johnson / Theo Niessink (libs LGPL / GPL) = partageables avec leur en-tête ; Tukan = à installer par leur propre
  dépôt ReaPack (pas redistribués) ; Neurotype = pas de licence écrite → pas dans le paquet. Doublons à la racine et dans `Tukan/`.
  **À l'utilisateur** (confirmé 24 nov.) : `Manipulator_Formant`, `grm_sweep_comb` (+ `joffo_stutter`, `16rec` d'après leur
  en-tête). **Pas à lui / origine inconnue** : `--bbddelay.jsfx` (utilisé partout), `freezer`, « GRM comb v2 »
  (`Lexikan2gui/SC Filter (Tukan)`). `Filters_LPHP` = à lui aussi, mais « simplifié du SC Filter de Tukan » (**recopie du code de Tukan** → à réécrire par nous).
  **Convention des effets du pack (demandée)** : le Twister (page FX) et le FX Router montrent les **4 premiers paramètres**
  de chaque effet → slider1 = **Dry/Wet** quand il a un sens, puis les paramètres principaux (4 au total en tête).
  Effets réordonnés = **nouveaux fichiers** (« NU … ») pour ne pas casser les projets / réglages mémorisés par index.
  **Faits le 24 nov.** (`NowUndo/Effects/`, non testés dans REAPER, bancs Python) : `NU_GRM_Comb.jsfx` (= grm_sweep_comb de
  l'utilisateur, sliders renumérotés : Mix, Sweep, Freq A, Résonance en tête ; sortie identique à l'ancien, écart 0) et
  `NU_Filter.jsfx` (remplace Filters_LPHP, code original RBJ : HP, LP, Résonance, Drive, pente 12/24 dB ; ouvert = son inchangé).
  Vérifiés OK pour les autres : bbddelay, joffo_stutter, Manipulator_Formant. **L'utilisateur accepte de partager BBD delay** (à lui,
  confirmé 24 nov.) : `NU_BBD_Delay`, `NU_Stutter`, `NU_Manipulator_Formant` ajoutés dans `NowUndo/Effects/` (copies du fichier de
  l'utilisateur + en-tête `author/version/changelog` pour ReaPack, DSP inchangé, même ordre de réglages). **Licence : MIT** (choisie par l'utilisateur le 24 nov., fichier `LICENSE` à la racine, copyright « 2026 joffo78 » ; vaut pour tout le dépôt, les effets de tiers ne sont pas inclus et gardent leur licence). Restent : `16rec` (pas reçu), delay NU éventuel
  (origine de bbddelay inconnue → l'utilisateur dit qu'il est à lui, à confirmer).

## 24 nov. : import de fichiers audio dans 8Waves (le 8 Looper Panel est abandonné)

- Demande : « adapter toutes les fonctions d'import de fichier audio du 8 Panel au 8 Waveform, le premier étant obsolète ».
- `NowUndo_8Waves.lua` : table `IMP` (moteur repris à l'identique du 8 Panel : protocole gmem `LD_BASE = 1000000`, commandes
  `+48` = 32 requête de longueur puis 31 copie, lecture par petits blocs, modes 1 Adapter / 2 Indépendant / 3 Étirer en
  Hermite, tronqué à la capacité, 1er fichier sans maître = tempo du projet via `SetCurrentBPM`). **Glisser-déposer** sur la
  ligne d'un looper actif (une ligne = un looper ; un seul fichier à la fois, les autres sont ignorés avec un message) ; **clic droit sur une
  ligne** = menu : « Charger un fichier audio dans le looper N… » (sélecteur REAPER `GetUserFileNameForRead`) + les 3 modes
  (coché = actif, mémorisé dans `NowUndo_8Waves/load_mode`, repris de `NowUndo_8Looper_Panel/load_mode` au 1er lancement).
  Bandeau d'état en haut au centre (progression, résultat). Menu sans séparateur ni ligne grisée (la numérotation de
  `gfx.showmenu` reste 1..4). Test `tools/t8waves_import.lua` (faux reaper + faux JSFX) ; `tools/t8waves_ui.lua` inchangé OK.
  **Non testé dans REAPER** (décodage réel d'un fichier, glisser-déposer de l'explorateur).

## 24 nov. : paquet ReaPack « NowUndo » (préparé sur la branche, pas encore publié)

- **Un seul paquet** : `NowUndo/Scripts/V3.21/NowUndo_Setup.lua` (en-tête `@provides`) fournit tous les scripts (`[main]`), la page web
  (`[webinterface] NowUndo.html`) et les effets (`[effect] ../../NowUndo_V3.27.jsfx`, `NU_DropCapture.jsfx`, `master_synchro`,
  `Effects/NU_*.jsfx`). Les autres fichiers sont **ignorés** par `.reapack-index.conf` (pas de commentaires ni d'apostrophes dans ce fichier : le
  format est celui d'une ligne de commande ; chemins avec espaces entre guillemets) : anciens scripts / versions JSFX, `tools/`, 8 Looper Panel (obsolète), `nowundo_vl_model.txt`
  (écrit par l'utilisateur, un paquet l'écraserait à chaque mise à jour).
- **Setup** (action « NowUndo : installation et démarrage automatique ») : vérifie SWS (`BR_`), js_ReaScriptAPI (`JS_`), ReaImGui ; menu à cocher
  des scripts à lancer au démarrage (ExtState `NowUndo_Setup/auto_<fichier>`) ; écrit **un bloc balisé** dans `Scripts/__startup.lua`
  (`-- >>> NOWUNDO … <<<`, le reste du fichier est conservé) qui lance les scripts par **chemin** (`AddRemoveReaScript`), plus d'ids `_RS…`.
- Chemins après installation par ReaPack (nom du dépôt ReaPack = **Dripsody**, workflow `--name "Dripsody"`) : scripts
  `Scripts/Dripsody/NowUndo/Scripts/V3.21/`, effets `Effects/Dripsody/NowUndo/` (looper, MSV3, DropCapture) et `Effects/Dripsody/NowUndo/Effects/NU_*.jsfx`.
  FX Router et Twister scannent **aussi** `Dripsody/NowUndo/Effects` (en plus de `MonRig`) ; le Launchpad cherche `NU_DropCapture` aussi sous
  `Dripsody/NowUndo/`.
- Vérifié : `reapack-index --check` = 1 paquet, 0 erreur ; `--rebuild --no-commit` produit bien tous les `@provides`. **À confirmer à la 1re vraie
  installation** : ReaPack accepte les chemins `../../` des effets (l'index les contient, pas vérifié côté REAPER) ; le menu du Setup ; le bloc
  `__startup.lua`. Publication = fusion sur `main` (l'action GitHub régénère `index.xml`) : **ne pas fusionner sans l'accord de l'utilisateur**.
- Reste à faire : modèle de projet (pistes 1-24, containers) à partir du .RPP de l'utilisateur ; notice d'installation ; bouton visible du mode
  d'import dans 8Waves (demandé implicitement le 24 nov. : l'utilisateur ne retrouvait pas les options dans le clic droit).

## 24 nov. : enregistrement de performance (spécification validée, rien d'écrit dans le MSV3 / le Launchpad encore)

- But : enregistrer **un concert entier** dans REAPER (un seul enregistrement continu). Un JSFX ne peut ni armer une piste, ni toucher au transport,
  ni créer de marqueur : le **MSV3 publie les évènements** (bouton « REC PERFORMANCE » dans son interface + action Launchpad / MIDI Learn) et un
  **script** agit. Décisions de l'utilisateur : pistes 2-9 (entrées) et 11-18 (loopers) en monitoring + record disable par défaut ; **entrée** armée
  en « Record : output » (`I_RECMODE` 3 = stéréo avec compensation de latence) dès qu'elle est affectée à au moins un looper (même évènement que le
  « mute » de l'entrée, `VL.set_input_parent`) ; **looper** armé dès qu'un enregistrement est abouti, désarmé au Clear (un item par période armée) ;
  timeline qui tourne en continu, **marqueur de tempo à chaque synchro** (avec signature = nombre de temps de la boucle pour que le 1er temps tombe sur
  le départ de la boucle : à confirmer) ; option : **découper les items à chaque cycle** de l'horloge interne (après l'arrêt, avec les heures exactes
  publiées par le JSFX, pas en direct) ; **régions de morceaux** : un morceau commence au **1er REC alors que tous les loopers sont vides** (3 parts
  comprises, quel que soit le geste de total clear), la région va jusqu'au 1er REC du morceau suivant (la dernière jusqu'à l'arrêt), créée au début et
  agrandie en continu ; pas de durée minimale (une région de trop est acceptée) ; tempo de départ = celui du projet, pas de marge avant le 1er REC.
- Pièges notés : Auto-Tempo (`VL.autotempo_tick`) fait `SetCurrentBPM` et **STOP au Unlock** → incompatible avec un enregistrement continu (mode performance :
  marqueurs à la place, pas de STOP) ; base de temps des items = **temps** (sinon les marqueurs étirent l'audio) ; disque ≈ 16 Go / h (16 pistes stéréo 24 bits).
- **Résultats de l'essai (24 nov., projet de l'utilisateur)** : armer / désarmer / réarmer EN COURS d'enregistrement marche (item = +4-5 ms après l'ordre, un item
  par période armée) ; `I_RECMODE` 3 accepté ; région agrandie en direct OK ; marqueur de tempo ajouté à la position de lecture = pas de saut. **MAIS** :
  (1) un marqueur avec signature posé en milieu de mesure est coupé en 2 : tempo à l'instant demandé + signature repoussée à la **barre de mesure suivante**
  → on ne peut pas aligner le 1er temps sur le départ d'une boucle en direct ; (2) **`SetCurrentBPM` (ou tout changement d'un tempo déjà posé) pendant la lecture
  déplace la tête de lecture** (REAPER garde la position musicale : saut de +1,65 s observé) → INTERDIT en mode performance. L'alignement des mesures
  sur les boucles se fera APRÈS l'arrêt (reconstruction de la carte de tempo, items en base de temps : pas de déplacement d'audio) = étape 2.
- **Étape 1 livrée : `NowUndo_Performance.lua`** (fenêtre « Dripsody Performance », bouton REC PERFORMANCE ; relancer le script pendant un concert = bascule ;
  test `tools/tperf.lua`, faux REAPER). Gère seulement les entrées 2-9 et les loopers 11-18 (constantes `IN_FIRST`, `LP_FIRST`) ; les instruments / aux sont routés
  vers les entrées (confirmé par l'utilisateur) donc enregistrés par elles, les autres pistes restent à sa charge. Entrée **enregistrée** (mode output) si affectée à un looper
  (gmem `6010+i`) **et** sortie vers la piste parent active (`B_MAINSEND` = 1, demandé le 24 nov. ; coupée = « in mute »), looper armé si boucle > 0 et plus en REC / attente (états 1, 7, 8), régions « Morceau n » (1er REC alors que tous les loopers sont vides ; fin =
  début du suivant), marqueur de tempo à chaque nouveau maître looper (tempo estimé `+155`), journal dans l'ExtState du projet `Dripsody_Perf/log` (lignes `S` morceaux,
  `E` évènements) pour l'étape 2. Non testé dans REAPER. Question ouverte : armer aussi les entrées non affectées pendant le concert ?
  Reste : étape 2 (grille alignée après l'arrêt, découpe optionnelle des items par cycle avec les heures exactes du JSFX) ; boutons Launchpad / MIDI Learn pour
  la bascule (ExtState `NowUndo_Perf/cmd` = `toggle`).
- **CORRECTION du 24 nov. (retour de l'utilisateur : « dès que je déclenche le script l'entrée n'entre plus dans le looper »)** : dans son modèle, les pistes
  2-9 / 11-18 sont **ARMÉES avec le mode « Record : disable (input monitoring only) »** (`I_RECARM` 1, `I_RECMODE` 2) : c'est l'**armement** qui fait entrer le signal
  (monitoring). La 1re version désarmait ces pistes au démarrage → plus de signal vers les loopers. **Règle : ne JAMAIS désarmer une piste qui était armée.**
  Le script bascule seulement le **mode** : 2 (monitoring seul) ↔ 3 (output) ; une piste non armée à l'origine est armée pour enregistrer puis désarmée. L'envoi
  vers les loopers n'est jamais touché. **Hypothèse NON vérifiée** : changer `I_RECMODE` d'une piste déjà armée EN COURS d'enregistrement démarre / arrête bien un item
  (l'essai du 24 nov. n'a testé que l'armement). Garde-fou : à l'arrêt, le script vérifie qu'un item existe pour chaque période demandée > 1 s et affiche
  « ATTENTION : rien d'enregistré pour : piste N (…) » (aussi `MANQUANT` dans le journal). Si ça échoue : essai n°2 (`I_RECMODE` en cours d'enregistrement), plan B =
  enregistrer en continu puis couper les items après coup.
- **Saucissonnage = À POSTERIORI et RÉVERSIBLE (24 nov., demandé : « je suis obligé de choisir avant ? »)** : plus de case à cocher avant le concert. Après l'arrêt
  (et même en rouvrant le projet plus tard, le journal est dans le projet), la fenêtre « Dripsody Performance » a deux boutons : **DÉCOUPER PAR CYCLE** (items des **loopers**
  seulement, pas les entrées) et **RECOLLER**. Recollage sûr : les morceaux créés sont marqués `P_EXT:dripsody_cut` ; un morceau n'est recollé au précédent que s'il est
  contigu (< 2 ms), de la même source, même vitesse et même décalage dans le fichier (un morceau déplacé / modifié à la main n'est pas touché, compté « non recollable »).
  Découper deux fois ne coupe rien de plus. Ctrl+Z annule aussi (blocs d'annulation). **Pas de modification du JSFX** : le looper maître publie `gmem[o+3]` = position de
  l'horloge en échantillons **à chaque échantillon** et `[o+2]` = longueur ; à chaque image le script apparie cette position avec `GetPlayPosition` → début de cycle
  `r = (pos − mpos/sr) mod L` ; **médiane circulaire** des 400 dernières mesures = phase T0 (erreur < 0,3 ms avec ±3 ms de gigue au banc) ; coupes = `T0 + k·L`. Écart durable
  (> 15 ms, 10 mesures) = re-phase → nouveau segment (qui démarre à la 1re mesure écartée). Pas de coupe à moins de 30 ms du bord d'un item. Journal `Dripsody_Perf/log`
  (`P.load_log()` : lignes `C` segments, `E start`, `S` morceaux). Réglage fin : ExtState `NowUndo_Perf/cut_ms` (ms, négatif = plus tôt ; la latence « output » peut décaler
  de quelques ms : à régler à l'oreille). Tests `tools/tperf2.lua` (hook `DRIPSODY_PERF_TEST` → `DRIPSODY_PERF`). Non testé dans REAPER. **Reste** : grille de tempo alignée sur
  ces segments (barres de mesure = cycles, mesures de raccord entre segments) ; boutons Launchpad / MIDI Learn pour démarrer / arrêter.
- **GRILLE ALIGNÉE (24 nov., à posteriori et réversible, demandé : « dommage que les boucles ne soient pas calées sur un premier temps »)** : boutons **ALIGNER LA GRILLE** /
  **ANCIENNE GRILLE** de la fenêtre « Dripsody Performance » (hors enregistrement). Pas possible en direct (essai du 24 nov. : une signature posée en milieu de mesure est
  repoussée à la barre suivante ; changer un tempo posé fait sauter la tête de lecture), donc après coup à partir des segments d'horloge du journal (`P.grid_plan` / `grid_build`) :
  par segment tempo exact `60·N/L` (N = temps par cycle = round(bpm estimé × L / 60), le bpm estimé vient des lignes `E sync` du journal), mesure de q temps (q = 1er diviseur de N dans
  4, 3, 6, 8, 2, 5, 7, sinon N) → **chaque départ de cycle tombe sur un 1er temps** ; **mesures de raccord** (`plan_fill` : nombre entier de temps, tempo ajusté entre ½× et 2× la
  référence, dernière mesure raccourcie par une signature) avant le 1er segment (depuis une barre de l'ancienne grille ≥ 2 mesures avant) et entre deux segments (re-phase comprise).
  Marqueurs posés **par numéro de mesure** (`timepos = -1`, `measurepos`, `beatpos = 0` : pas d'arrondi) ; repli automatique **par instant, 1 µs avant la barre** si la vérification
  (départs de cycle sur un 1er temps, tolérance 2 ms) échoue. Sécurité : ancienne carte de tempo sauvée dans l'ExtState du projet `Dripsody_Perf/grid_backup`
  (réaligner repart toujours de l'ancienne), items / régions / marqueurs remis en place s'ils ont bougé (`put_back`), blocs d'annulation. **À confirmer dans REAPER** :
  pose par mesure acceptée, indices de mesure 0-based (`TimeMap2_timeToBeats` / `TimeMap_GetMeasureInfo`), tolérance de 1 µs, aspect du tempo de raccord. Test `tools/tperf3.lua`
  (simulateur de carte de tempo : barres, signature repoussée à la barre suivante) : 15 départs de cycle examinés, tous sur un 1er temps ; restauration exacte ; mode repli.
  **Retour de l'utilisateur (24 nov., captures)** : « c'est les LOOPERS qui doivent être calés, pas les inputs » / « t'appelle ça aligné ? » (début d'un item de looper pas sur la barre).
  Corrections : `P.item_phase` = écart médian du **début des items de loopers** par rapport à la phase de l'horloge ; s'il dépasse 40 ms la grille est **recalée sur les items**
  (message « Grille recalée sur le début des items… ») ; sinon l'horloge (plus précise) est gardée ; le message affiche toujours « ITEMS DE LOOPERS : n, écart médian X ms, max Y ms »
  et le fichier `Dripsody_Perf_grid.txt` (diagnostic, dossier de REAPER) liste chaque item ; `Dripsody_Perf_log.txt` = journal du concert. Les entrées ne sont jamais prises en compte.
  Si ça ne colle toujours pas : demander `Dripsody_Perf_grid.txt` + capture avec règle et grille visibles.
  **Reste** : boutons Launchpad / MIDI Learn pour démarrer / arrêter le concert.
- **QUEUES D'EFFETS (24 nov., demandé : « si je clear un looper et que j'ai un feedback de delay sur la piste, il ne sera pas enregistré ? »)** : à la fin d'une période
  d'enregistrement (Clear d'un looper, entrée désaffectée), la piste **continue d'enregistrer** tant qu'elle sonne (`P.level_db` = pic de `Track_GetPeakInfo`) :
  au moins 0,5 s (`TAIL_MIN`), **sans durée maximale** (demandé le 24 nov.), jusqu'à passer sous -60 dB. Réglages : ExtState `NowUndo_Perf/tail_s` (durée max facultative, s) et `NowUndo_Perf/tail_db` (seuil, dB).
  Redemande pendant la queue = même item. Test `tools/tperf.lua` (6a/6b/6c, niveau simulé `PEAK`). **Non testé dans REAPER.**
- **Essai jetable** `tools/Dripsody_PerfSpike.lua` (à lancer dans un projet vide, ~12 s) : arme / désarme / réarme des pistes en cours d'enregistrement, pose un
  marqueur 5/4, teste `SetCurrentBPM` avec un marqueur, crée et agrandit une région ; rapport `Dripsody_Spike_Report.txt`. Attendre ses résultats avant de coder.

## 25 nov. : page MIDI Learn rationalisée = onglets par catégorie + une cible par looper (non testé dans REAPER)

- Demande de l'utilisateur : « page indigeste » ; **Aux supprimé** (il n'y en avait aucune d'affectée) ; onglets **Transport / Playback / Loop / Slicer / Cloud / Output**
  (+ **Pages**, **Twister**, **Autres**) ; dans chaque onglet, chaque fonction a un learn **Sélection** puis **L1..L8** ; **règle : un looper qui appartient à un
  groupe fait suivre tout le groupe** quand on change sa valeur (sauf « inhibe groupe » maintenu et sauf `Restart Ln`, volontairement individuel).
- `nowundo_midi_learn.lua` : `TABS`, `TAB_SLOTS`, `ACT_TAB` / `PAR_TAB` (onglet de chaque cible), `UIS` (onglet + looper affiché, ExtState `NowUndo_MIDILearn/ui_tab`
  / `ui_slot`). Chaque cible a `tab`, `fn` (fonction commune), `slot` (0 = sélection, 1..8 = looper). Variantes par looper : id `<id>_L<n>` (ex. `par:fdbk_L3`,
  `act:reverse_L2`), champs `looper = n`, `grp = true` ; `group_members(i)` (membres du groupe de i). **Les ids d'avant ne changent pas** (les learns existants restent).
- Nouvelles cibles : **Speed** (1/4 x .. 4 x, comme la page 2 du Twister), **Pitch**, Scaler, Grain, tous les réglages Slicer / Cloud du catalogue Custom (générés depuis
  `CU_KNOBS`), et **In / Out / Width** (`io:in` / `io:out` / `io:width`, fraction de la boucle ; `io_write` : **autonomes** = commandes 1 / 2 / 3, règle absolue). Courbe
  `"log"` gérée dans `param_value` / `param_norm`.
- Interface : barre d'onglets, puces « Afficher : Tous / Sélection / L1..L8 », titres de fonction (lignes `hdr`), touches 1-9 = onglet, 0 = tout, F = recherche
  (cherche dans tout le catalogue). Retiré : lignes Aux, touches A / X / N, résumé « Aux ». Test `tools/tlearn_tabs.lua` (faux REAPER : groupe, In / Out, Restart, Reverse).
  Locales : 141.

## 25 nov. : DASHBOARD (spécification validée, à coder sur la branche `nowundo-dashboard`) — EN SUSPENS, revue le 26 nov.

- **DÉCISION DU 26 NOV. (remplace la fenêtre ReaImGui)** : le dashboard devient un **onglet « Dashboard » de la page web `NowUndo.html`**,
  pensé pour le **tactile**. L'utilisateur a **une tablette et un écran tactile** sur le PC : la même page sert aux deux (tablette par le Wi-Fi,
  écran tactile du PC dans un navigateur à côté de REAPER). Raison : le navigateur gère le **multi-touch** (plusieurs knobs à la fois), une fenêtre
  REAPER / ReaImGui n'a qu'un seul pointeur. Le nom `DashBoard.lua` est déjà pris par un **ancien** panneau gfx des 8 instances (sans rapport) :
  ne pas le réutiliser pour le pont.
- Ce que le dashboard apporte par rapport aux learns seuls (discuté le 26 nov.) : voir valeurs et états au même endroit, **disposition par projet**
  (les learns sont globaux), jouer sans contrôleur, pads de rushes à l'écran. Recoupe la page 7 Custom du Twister et le MIDI Learn par looper.
- Demande : une page blanche pour composer sa propre surface de contrôle, à l'image des pages Custom du Twister et du Launchpad.
- **Grille 8 × 8**. Chaque case = **knob** ou **pad** (vide au départ). Retour visuel en direct (valeurs, états, couleur de famille comme le Twister).
  Interaction directe au doigt (glisser sur un knob, appui ou gate sur un pad ; plusieurs doigts en même temps).
- **Configuration d'une case** : **appui long** sur une case (menu tactile, à la place du clic droit) → knob ou pad → fonction du catalogue
  (paramètres de looper, actions) ou **rush** ; **portée par case** (sélection, L1..L8, groupe, tous). **Cible individuelle par case** (comme les rushes),
  pas de cible globale imposée.
- **Learn par case** : déclenché depuis la page, fait par le MIDI Learn existant (cumul possible, appareil strict).
- **Par projet** : la grille est stockée dans le projet REAPER (ExtState projet, comme `Dripsody_Perf`) par un **petit pont côté REAPER** (comme
  `NowUndo_Twister_Web.lua`). **Modèle par défaut** (fichier) pour les projets neufs.
- **Fermer la page ne coupe rien** : le pont continue de tourner dans REAPER.
- **Découpage** : v1 = onglet + grille 8 × 8 + knobs (Pitch, Speed, Feedback, Out vol, In, Out) avec portée par case + sauvegarde projet + modèle.
  v2 = pads et import de rushes. Test d'abord avec faux REAPER + Playwright (`tools/*.js`, `reaper_main.js`), puis essai dans REAPER.

## 26 nov. : idée « Dripsody Net Session » (jouer à plusieurs sur un LAN) — discutée, rien de codé, EN SUSPENS

- Demande : plusieurs utilisateurs de Dripsody se voient sur un LAN et jouent ensemble en partageant la synchro. Mêmes règles qu'en local, mais
  **le premier qui verrouille la synchro la verrouille pour tout le monde** (« super maître »), les autres se calent dessus.
- **Pas d'audio par le réseau** (décidé) : chacun sort sur la table de mixage / son ampli. Le réseau ne transporte que la synchro et un peu d'état.
- **Ableton Link** : protocole LAN de tempo + phase sans serveur (Live, Push, Move, Note, MPC Live / X / Force, Reason, Traktor, Maschine, Max,
  Serato, beaucoup d'apps iOS / Android, Eurorack). REAPER ne l'a pas en natif, mais l'extension **reablink** (ak5k, ReaPack, dernière mise à jour
  juillet 2025) donne l'horloge Link aux ReaScripts (`Blink_GetBeatAtTime`, `Blink_GetPhaseAtTime`, quantum…) et a deux modes : **Puppet** (REAPER suit
  Link : transport, tempo écrit en marqueurs, phase tenue par de petits changements de playrate, actions 40524 / 40525 / 40521) et **Master**.
- **Montage recommandé (B)** : Link → script → **MSV3** (nouveau mode « esclave réseau », proche du mode Host) → loopers ; **REAPER reste libre**
  (pas de Puppet : un changement de tempo en lecture fait sauter la tête, voir 24 nov. ; conflit avec l'Auto-Tempo et l'enregistrement de performance) ;
  grille alignée après coup comme « Aligner la grille ». Montage A (REAPER en Puppet + MSV3 en Host) = option si on joue avec du contenu du projet.
- Boucle du super maître = tempo `60·N/L` + quantum N (temps). **Le déphasage est conservé** : les loopers gardent leur sync point par rapport au
  MSV3 local (précision réseau ~1 ms en câble, plus en Wi-Fi ; au sample près sur une même machine).
- **Un joueur Live dans la session** : Dripsody prend son tempo et sa phase ; 1er REC arrondi à un nombre entier de temps / mesures. Recommandé :
  si Live est là avant, son tempo fait référence (super maître) ; la règle du premier qui verrouille vaut entre joueurs Dripsody. Changement de
  tempo par Live en cours de jeu : recommandé = les boucles suivent (Speed / stretch), avec une option pour refuser les changements pendant qu'on joue.
- Difficultés : dérive des cartes son (corriger en douceur), gigue Wi-Fi (câble + switch recommandé), latence de sortie de chaque machine (CAL / LAT),
  relève du super maître (garder l'horloge tant qu'un joueur a une boucle, comme le Clear du maître du 23 nov.).
- « Se voir » : commencer par liste des joueurs + super maître + longueur de boucle + repère du début de cycle ; état des loopers des autres plus tard.
- L'utilisateur est **sur PC (Windows)** : Mac sans importance. **À faire d'abord** : installer reablink par ReaPack, essai avec Live et le script
  « ReaBlink Monitor » (pairs, tempo, phase).
- **26 nov. après-midi : reablink INSTALLÉ et fonctionne** chez l'utilisateur. Il est dans le dépôt **ReaTeam Extensions** (Browse packages > « ReaBlink »),
  pas besoin d'importer de dépôt (importer `https://github.com/ak5k/reablink` = erreur XML : page GitHub, pas un index). **Essai réussi le 26 nov. : deux REAPER
  (PC fixe + portable) se voient en Link** (ReaBlink_Monitor). Pas d'app Android gratuite fiable trouvée (Soundbrenner payante) ; test Live = version d'essai.
  **Essai Wi-Fi (26 nov., 2 REAPER)** : se cale et suit le tempo, mais **changer le tempo en cours de lecture ne passe pas** (champ tempo de REAPER).
  Lu dans le code de reablink : en Puppet, l'extension réécrit elle-même les marqueurs de tempo ; le changement prévu passe par `Blink_SetTempo`
  (actions fournies `ReaBlink_IncreaseTempoByOneBpm` / `DecreaseTempoByOneBpm`). Pour Dripsody (montage B) : le MSV3 / le script enverra le tempo par
  `Blink_SetTempo`, jamais par le champ tempo de REAPER. À confirmer : essai des actions ReaBlink en cours de lecture.

## 26 nov. : SENDS VERS LES PISTES AUX (spécification validée, rien de codé)

- Demande : doser le signal envoyé dans un effet en le gardant actif (comme un send vers une aux), sans toucher à l'architecture des 4 containers.
  Proposition écartée : mode « Send » par container (container en parallèle REAPER 7 + JSFX de gain en tête). **Choix de l'utilisateur : pistes aux
  partagées** (« moins de plomberie, plus clair, cohérent que les loopers partagent les mêmes reverb / delay »).
- **Pistes aux = 20 à 24** (5 aux, déjà dans son projet). Les containers d'effets restent en **insert** (inchangés). Les **reverbs des entrées restent
  en insert** quand elles doivent être enregistrées dans le looper (un send vers une aux sort de la piste : le looper ne l'entend jamais).
- **Dripsody crée les envois** (comme `LPF.send_nomidi` : MIDI coupé, `I_MIDIFLAGS` = 31) **post-fader** (Out Vol / volume de piste baissent aussi la
  reverb ; mode REAPER post-fader = **après les effets d'insert** de la piste, looper + 4 containers : demandé le 26 nov., ne jamais utiliser le mode pré-FX), des loopers 11-18 et des entrées 2-9 vers les aux 20-24. Si les pistes aux manquent (projet neuf / autre utilisateur) : à créer (à confirmer).
- **Réglage** : niveau de send par looper × aux, au Twister / MIDI Learn / rush (`l1 aux2 0.5`), **règle de groupe** habituelle (un looper groupé fait
  suivre son groupe). Pad = ouvrir / fermer le send avec un court fondu, réouverture au **dernier niveau réglé** ; les queues continuent sur l'aux.
- **Entrées** : sends vers les aux possibles (reverb entendue en direct, non enregistrée). **Quand la sortie vers le parent est coupée (« in mute »,
  `VL.set_input_parent`, gmem `6050+n`), ses sends vers les aux sont coupés aussi**, puis remis à l'identique : enregistrer en silence dans un looper.
- **Les loopers héritent des sends de leurs entrées, COPIE AU REC (choix B de l'utilisateur, 26 nov.)** : quand un looper commence à enregistrer
  (REC, Re-Rec ; **un overdub ne change rien** : les sends du 1er REC sont gardés, c'est au musicien de garder une même famille de sons dans un looper) une entrée qui lui est affectée (masques `6010+i` / `6020+i`), il copie les niveaux de send de cette entrée
  vers les aux 20-24 et les **garde** (la boucle sonne comme jouée ; changer ensuite les sends de l'entrée ne touche pas les boucles déjà posées).
  Réglage à la main du send du looper possible ensuite. **Le « in mute » de l'entrée ne compte pas** : on copie le réglage des sends, pas leur
  coupure (une boucle enregistrée en silence garde sa reverb). Plusieurs entrées → pour chaque aux, le **plus grand** niveau. Suivi en direct
  (choix A) écarté : fermer la reverb de l'entrée changerait les boucles déjà jouées.
- **Le looper impose ses sends à ses entrées tant qu'il a une boucle (demandé le 26 nov., « jamais de différence »)** : looper **vide** = l'entrée
  décide (copie au REC ci-dessus) ; looper **avec une boucle** = les entrées routées vers lui prennent **exactement** ses sends vers les aux (à la place
  de leurs propres réglages, pas un « au moins ») : l'overdub s'entend avec la même reverb que la boucle. Entrée désaffectée ou looper vidé = l'entrée
  retrouve ses propres sends (mémorisés). « In mute » coupe toujours tout. **Entrée routée vers plusieurs loopers aux sends différents** : priorité au
  looper qui **enregistre / overdub** en ce moment, sinon au **looper sélectionné** (Launchpad / 8Waves / web / MIDI Learn, celui de la page 9 du Twister),
  sinon le **plus grand** niveau par aux.
- Conséquences : **Performance** (`NowUndo_Performance.lua`) doit aussi enregistrer les pistes aux 20-24 (sinon la reverb partagée manque dans
  l'enregistrement du concert) ; le **Drop** n'inclut toujours pas les aux (la reverb partagée continue par le send après la bascule).

## 26 nov. : SENDS AUX = FAIT (branche `nowundo-sends`, non testé dans REAPER)

- **Launchpad** (`virtuallaunchpad_main.lua`) : config `aux_track_first = 20`, `aux_track_count = 5`. Moteur `VL.AUX` (remplace l'ancien
  `update_aux_follow`) : `LPF.aux_apply` (fondu 60 ms, fermer = rampe vers 0 puis `B_MUTE` et niveau remis), envois créés post-fader
  (`I_SENDMODE` 0) MIDI coupé ; sends **propres** de chaque entrée mémorisés dans la piste (`P_EXT:nowundo_aux_own`, `on:vol` × 5) ;
  `VL.update_aux_follow` toutes les 0,1 s (`VL.aux_tick` dans `VL.tick`) : (1) copie au REC (passage en état 1, plus grand niveau des
  entrées routées `S.routing.in_l`), (2) entrées : in mute (`B_MAINSEND` 0) > imposé par un looper avec boucle (`LPF.aux_imposed` :
  looper en REC / overdub, sinon sélectionné, sinon max) > propre ; réglage manuel dans REAPER d'une entrée libre = devient le sien,
  d'une entrée imposée / coupée = remis en place ; (3) garde-fou feedback (aux → looper fermé si le looper envoie vers cette aux).
  Les pistes aux manquantes ne sont **pas** créées automatiquement (à faire si besoin).
- **Commandes** `NowUndo_VLcmd/q` : `aux_l_<i>_<a>_<v>`, `aux_in_<k>_<a>_<v>` (v = niveau en millièmes, `on` = dernier niveau, `off`,
  `tog` ; 0 = fermer), `auxrx_<i>_<a>_<on|off|tog>` (aux → looper, refusé si feedback). `VL.aux_cmd`.
- **Rushes** (`NowUndo_Scenario.lua`) : `aux1`..`aux5` [niveau | -6db | 50% | on | off] sur loopers / groupes / `all` / entrées
  (`in1 aux2 -6db`) ; `l3 from aux2 [off]` = envoi aux → looper (loopers seulement). Toggle sans valeur = bascule ; gate / toggle relâché =
  fermé. Palette « Sends aux ». Tests : `tools/taux.lua` (moteur, 24 contrôles) et `tools/taux_rush.lua` (mots → commandes).
- **Reste** : réglage des sends au Twister / MIDI Learn / web ; `NowUndo_Performance.lua` doit enregistrer les pistes 21-24.
- **27 nov. (retours de l'utilisateur)** : aux = **pistes 21 à 24** (4 aux, `aux_track_first = 21`, `aux_track_count = 4`) ; mots `aux1`..`aux4`.
  **Entrée sélectionnée** = dernière entrée choisie comme source FX (page 2 du Launchpad / FX Router, `S.sel_input`, `VL.sel_in()`, publiée en
  gmem **6062**) ; elle reste quand on sélectionne un looper. Rushes `in aux2 0.5`, `in fx 2`, `in mute` (le mot `in` seul suivi de aux / fx / mute ;
  `in 0.25` reste le point In) → cible 100 → commandes `aux_in_0_…`, `fxin_0_…`, `inmute_0_…` (0 = entrée sélectionnée).
  **Tableau de bord des sends** (`VL.aux_publish`) : gmem `6098` = 1re piste aux, `6099` = nombre, `6100 + (L-1)*8 + (a-1)` send du looper
  (> 0 ouvert, < 0 fermé avec son niveau, 0 = pas d'envoi), `6164 + (k-1)*8 + (a-1)` send réel de l'entrée k, `6228 + (L-1)*8 + (a-1)` = 1 si aux → looper.
  **8Waves** : une pastille par aux dans une **colonne à droite de chaque ligne, après le VU de sortie, les unes au-dessus des autres** (27 nov., demandé ; nom de la piste aux + niveau ; turquoise = ouvert, gris = fermé,
  cadre orange + `<` = l'aux revient dans ce looper) ; **clic = ouvrir / fermer, glisser gauche / droite = niveau (200 px = 100 %), clic droit = aux → looper**.
  Tests `tools/taux.lua`, `tools/taux_rush.lua`, `tools/t8waves_aux.lua` (hook `W8_TEST`). **Règle** : pas de message qui interrompt le jeu (live).
  **27 nov. (suite, demandé : « effets prête à confusion »)** : les pastilles s'appellent **« Send n »** (plus le nom de la piste aux) ; **juste avant**,
  une colonne de **petits carrés « FX1..FX4 » = FX d'insert** du looper (masque gmem `6030+L`, rose = actif ; clic = `fxg_<L>_<slot>_tog`, le groupe suit
  comme le pad d'effet ; `VIS.ins_badges`, `UI.fxbadge`, kind `fxi`).
- **27 nov. : bug Ctrl+D (dupliquer un rush) corrigé** : `ED.mpaste` retirait les DERNIERS rushes de la liste pour replacer les copies, mais `mac_add`
  → `mac_save` → `H._msort` avait déjà retrié la liste (perso avant usine) : la copie restait deux fois (même objet, même id → impossible de la
  sélectionner seule) et un rush d'usine disparaissait. Maintenant les copies sont retirées par identité ; au chargement, un id en double reçoit un id
  neuf (`mac_apply`). Test `tools/tdup.lua` (ancienne version : 6 échecs, nouvelle : OK).
  **Séquelle (signalée le 27 nov. : pads L7 FX4 / L8 FX4 de la page Effets toujours vides)** : les rushes d'usine perdus par ce bug étaient recréés par
  `H._rom_fix` mais **hors du Launchpad**. Maintenant un rush d'usine recréé est reposé sur sa case de la page « RC-505 » / « Effets » si elle est vide
  (mode toggle si l'usine est toggle) ; réparation **une fois** (ExtState persistant `NowUndo_Macros/rom_repair1`) des rushes d'usine restés hors du
  Launchpad. Test `tools/tromrepair.lua`.

## 27 nov. : MODE PAR CASE du Launchpad (normal / toggle / gate) + toggles des sends = miroir de l'état réel

- **Mode par case** (demandé : « utiliser plusieurs fois le même rush avec des comportements différents ») : 4e champ de la ligne `L case id [n|t|g]`
  (`n` normal, `t` toggle, `g` gate ; absent = mode du rush). Launchpad : `LPF.macros_parse` → `VL.macros.lmode`, `VL.cell_mode(cell)`,
  `VL.set_cell_mode(cell, md)` ; `VL.macros_layout_edit(fn(lay, lm))` garde les modes (le mode suit le rush déplacé / glissé) ; appui / relâchement /
  état du pad selon le mode de la case (gate = allumé tant qu'on tient). **Clic droit sur un pad occupé de la page 4** = menu « Editer le rush | Mode du
  rush (x) | Normal / Toggle / Gate sur ce pad » (case vide = nouveau rush, inchangé). **Triangles** dans l'angle haut (27 nov., demandé) : bleu à gauche = toggle, violet à droite = gate (fenêtre :
  `VL.cell_band` ; web : `band=1,2g.1,3t` dans `web_meta`, classes CSS `band-t` / `band-g`) ; le vrai Launchpad n'affiche qu'une couleur.
  `mcr` (Launchpad → Scenario) = `id\tcibles\ttemps\tgst\tmode\tcase` ; Scenario : `H._as(m, mode)` (le rush vu avec le mode de la case, proxy),
  `H._cmode`, `H._lmode` (lu / écrit avec la disposition, suit la suppression d'une page) ; liste `on` = rushes toggle OU posés en toggle sur une case.
  **Un même rush sur plusieurs pads (27 nov., demandé)** : déposer un rush depuis le Scenario = **un pad de plus** (`VL.macro_drop` ne le retire plus de
  ses autres pads ; occupant d'une case visée → 1re case libre de la sous-page). **Un état par pad** : le proxy `H._as(m, mode, case)` porte `lid = id@case`,
  la pile `H._live` est indexée par `lid` (sinon id = déclenchement MIDI / scénario) ; liste `on` = jetons `id@case` (pads) et `id` (rush) ; le Launchpad
  allume un pad toggle si `on[id@case]` ou `on[id]`. Scenario : « LP c1.3+2 » (1re case + nombre d'autres pads), vérification du dépôt = un pad de plus.
  **Plus de mode global du rush (27 nov., demandé)** : les cases **T / G** de la liste du Scenario sont **retirées** (reste A ; ▶ en x0+66, nom en x0+92) ;
  le mode se règle **seulement par pad** (clic droit : Éditer le rush | Normal | Toggle | Gate) ; **pad sans mode = normal** (`VL.cell_mode`, `H._cmode`).
  Migration une fois au démarrage du Scenario (`H._lmode_mig`) : le mode des rushes déjà posés est recopié sur leurs pads. Le drapeau toggle / gate du rush
  ne sert plus qu'au **MIDI du rush** (pas de case). Test `tools/ttogpad.lua`.
- **Toggles des sends = miroir** (demandé : « si j'active l'aux 1 dans L1 par un rush et que je vais sur L2 le rush est toujours actif ») : `H._mirror`
  inclut `aux1..aux4`, `from auxN`, `in auxN` ; `mac_active` lit l'état réel publié par le Launchpad (6100.. loopers, 6164.. entrées, 6228.. aux → looper)
  sur la cible du moment (sélection) : pad allumé seulement si le send du looper sélectionné est ouvert ; un appui inverse l'état réel.
  Tests `tools/tcellmode.lua` (Launchpad), `tools/taux_mirror.lua` (Scenario), `tools/tbands.js` (web, Playwright). Non testé dans REAPER.

## 27 nov. : page 1 du Launchpad = IN / LOOPER + sends C5-C8 (non testé dans REAPER)

- **B1 (ex FULL LOOP, qui reste au MIDI Learn / Twister) = IN / LOOPER** : la rangée du haut passe en **sélection des entrées** (IN1..IN8,
  vert ; groupe = couleur du groupe ; **in mute = bleu** comme la page 2). `S.top_in`, `VL.set_top_in`, publié en gmem **6063** (1 = entrées).
  Gestes comme les loopers : tap = sélection (`VL.select_input`), **appui long = in mute** (`VL.set_input_mute(k, "tog")` via `d.in_long` dans
  `VL.tick`), chord (entrée tenue + autre), Ctrl / HOLD (1re entrée libre = nouveau groupe), pad GROUP maintenu + entrée = entre / sort.
  **Groupes d'entrées** séparés (`S.in_group_of`, `VL.in_members`, `VL.in_assign`, `VL.in_chord`, mémorisés `nowundo_vl/in_groups`) ;
  pads GROUP en mode entrées = groupes d'entrées (`VL.in_select_group`). Sélectionner un looper en mode entrées ne change pas la source FX.
- **Cible des pads FX D5-D8 et sends C5-C8** = `VL.src_targets()` (source `S.fx_source` + son groupe, looper OU entrée ; pad GROUP tenu = sans groupe).
- **Rangée C** : speed / pitch ±12 retirés (MIDI Learn / Twister) ; **C4 = LINK** ; **C5-C8 = sends vers aux 1-4** (`aux_slot`, toggle ou gate,
  **PAGE 1 maintenue + pad = bascule du mode**, ExtState `VirtualLaunchpad_FX_Mirror/auxmode_<a>`) ; LED = état du send de la source
  (entrée : son réglage propre ; looper : gmem 6100..). `VL.aux_pad_apply`, `VL.aux_sel_cmd`.
- Commandes `NowUndo_VLcmd/q` : `topin_<on|off|tog>`, `auxsel_<a>_<on|off|tog>`. MIDI Learn : `act:top_in` (onglet Pages), `act:auxsel_1..4`
  (Output). Rush : **`inputs`** / `inputs on` / `inputs off` (toggle = miroir de gmem 6063), palette « Groupes / pages ».
- **RÈGLE DES SENDS (27 nov., FINALE, dite par l'utilisateur : « rien dans le looper : looper suit l'état des sends de ses inputs À LA LETTRE.
  Une fois que le premier rec est lancé tu touches plus à rien jusqu'au clear où tu enlèves tout. Et tu me laisses désactiver les sends »)** :
  looper **vide** (pas de boucle et pas en 7 / 1 / 8) = ses sends = ceux de ses sources (`VL.aux_follow_src` : entrées routées = réglage propre,
  loopers routés vers lui = leur send ; plus grand niveau ouvert par aux ; aucune ouverte = fermé). Sans aucune source routée : rien touché.
  **Dès le 1er REC lancé (état 7, 1 ou 8) et jusqu'au Clear : on ne touche plus à rien** (réglage à la main libre, fermer compris).
  **Clear** (passage boucle → vide, `VL.AUX.empty`) : tout est enlevé puis le looper suit de nouveau ses sources. Plus d'imposition looper → entrée,
  plus de copie au REC (`VL.aux_copy_on_rec` / `LPF.aux_imposed` inutilisés). Les essais intermédiaires du 27 nov. ont été retirés.
- **Correction du 27 nov. 18h (retour de l'utilisateur : « interdit de m'empêcher de faire quoi que ce soit, l'utilisateur est toujours prioritaire »)** :
  `VL.aux_follow_src` (sources = entrées ET loopers routés vers lui, confirmé 18h05 : « le looper doit transmettre les sends ») n'agit **que quand
  l'état d'une de ses sources change** (signature par source `VL.AUX.fsig`) ou au Clear : un réglage fait à la main sur un looper vide n'est plus jamais écrasé.
- **Le looper SÉLECTIONNÉ donne ses sends à ses entrées (27 nov., corrigé par l'utilisateur : « c'est pas à l'affectation, c'est le looper
  sélectionné qui donne son niveau d'aux »)** : `VL.aux_sel_give` : si le looper sélectionné a une boucle (ou un REC lancé), les entrées routées
  vers lui prennent EXACTEMENT ses sends (ouvert / fermé + niveau ; les aux que le looper n’a pas sont enlevées, réouvrables à la main) **au moment de la sélection et chaque fois que ses sends changent**
  (signature `VL.AUX.give`) ; entre deux, les entrées restent réglables librement. (L'essai « à l'affectation » `aux_route_pickup` est retiré.)
- **Correction du 27 nov. 18h30** (signalé : couper l'aux de IN1 le coupait aussi dans L1 qui tournait) : « vide » = drapeau collant `VL.AUX.busy[i]`,
  mis dès que l'état est 1..8 ou qu'une des 3 parts a une longueur (`LPF.aux_any_len`), retiré seulement au vrai Clear (état 0, plus aucune longueur,
  looper vivant). Avant : le test exigeait le battement `100+i` → un looper qui joue pouvait être vu vide et suivre ses entrées.
  18h40 : « vide » = ni REC lancé (1, 7, 8) ni longueur sur une part (un état 2..6 à vide reste vide), retour à vide sans exiger le battement.
- **27nov-diag1** (l'utilisateur : « dans REAPER le looper 2 a bien l'aux actif », banc OK) : source routée = routing du Launchpad **ou** envoi REAPER ouvert
  (`LPF.aux_routed`, routing fait à la main) ; doublons d'envois vers une même aux : `LPF.aux_get` = ouvert si l'un l'est, fermer les ferme tous
  (`LPF.aux_mute_dups`) ; diagnostic sans message `Dripsody_aux_diag.txt` (dossier de REAPER, écrit à chaque commande de send d'une entrée : état, longueur,
  busy, sources, sends de chaque looper, sends propres des entrées). Si le bug reste : demander ce fichier.
- **27 nov. 18h15 : SENDS AUX 100 % MANUELS (décision finale de l'utilisateur** : « une entrée qui va aussi dans L1 se retrouve avec l'effet de L1 et contamine L2,
  ça ne pourra jamais marcher ; on laisse l'utilisateur gérer ses affectations, sans rien automatiser »). Config `VL.config.aux_auto = false` (défaut) :
  plus de suivi des sources par un looper vide, plus de don du looper sélectionné aux entrées, plus de coupure des sends au in mute, plus de fermeture auto
  aux → looper (le refus d'ouvrir un envoi qui ferait une boucle de feedback reste dans `VL.aux_cmd`). Restent : pads C5-C8, rushes, MIDI Learn, 8Waves,
  fondus, publication 6100.., réglage fait dans REAPER adopté. `aux_auto = true` = ancien comportement (bancs `taux.lua`, `tinmode.lua`) ; banc du mode manuel
  `tools/tauxman.lua`. **Ne plus rien automatiser sur les sends sans demande explicite.**
- **Effet d'insert activé par une commande** (rush de la page 4 / scénario `fx_` / `fxin_`, web et 8Waves `fxg_`) : Twister → page Effets sur cet effet comme le pad
  (`VL.fx_nav_on`, sauf pages verrouillées `tw_lock`) ; désactiver par une commande ne change pas de page.
- `VL.BUILD = "27nov-manuel"` (une 2e ligne `VL.BUILD = "0.9.24…"` écrasait le marqueur depuis le début : retirée).
- Tests : `tools/tinmode.lua` (Launchpad), `tools/tinputs_rush.lua` (rush) ; taux / tcellmode inchangés OK.

## 27 nov. : 1er REC avec Pitch ≠ 0 = boucle ralentie (JSFX V3.27, corrigé)

- Signalé : 1er enregistrement avec Pitch +X → restitué ralenti, pas pitché, même en D. Cause : le 1er REC s'écrivait toujours à `rec_speed = varispeed`
  (pitch compris) ; en granulaire (Link off) la lecture n'avance qu'à Speed → boucle étirée (×2 pour +12) et pitch annulé. Maintenant :
  **A** = vitesse d'écriture = vitesse de lecture (varispeed en Link / Slicer / Cloud = son tel que joué ; Speed seul en granulaire = son pitché, tempo juste) ;
  **D** = écriture 1:1 (hors Slicer), la boucle est relue transformée (en Link : plus aiguë ET plus rapide). Banc `tools/trecpitch.py . v327.jsfx <0|1 = A|D> <link>` :
  avant 1,99 s / 217 Hz, après 1,00 s / 442 Hz (A et D, Link off) ; A Link on inchangé (220 Hz, 1 s) ; D Link on = 0,5 s / 442 Hz. Non testé dans REAPER.

## 27 nov. : In / Out pré-réglables sur un looper VIDE (JSFX V3.27 + scripts, non testé dans REAPER)

- Demande : « une longueur fictive quand les loopers sont vides pour pré-caler des valeurs de In / Out ». Choix validé : **fractions** appliquées à la fin du 1er REC.
- JSFX : `pre_s` / `pre_e` (fractions), longueur fictive `pre_L` = 1 000 000 ; looper vide (`length` 0, 1er REC compris) = les commandes d'édition +160
  (1 In seul, 5 fenêtre décalée, 2 Out seul, 3 Width, 4 pleine) agissent sur la fenêtre fictive (**même règle In / Out / Width**) ; publiée en
  `112000 + (looper*3 + part)*20` **+4** longueur fictive (0 dès qu'il y a une boucle), **+5** In, **+6** Width (unités fictives). **`+44/+45/+46` restent à 0**
  (rien d'autre ne croit qu'il y a une boucle). Fin du 1er REC (`finish_rec`) : fenêtre appliquée à la boucle puis oubliée ; Full Loop (cmd 22 / edit 4) et
  Clear d'un looper vide = remise à pleine boucle.
- Scripts : fonction **globale `NU_IO(b, 44|45|46)`** (copiée dans Launchpad, Twister, MIDI Learn, Scenario, Twister_Web) = vraie boucle, sinon valeurs fictives.
  Utilisée aux endroits qui écrivent / affichent In / Out : Twister (`read_fb` 44/45/46 ; l'anneau « Clear = boucle / vide » de la page 9 lit la vraie longueur),
  MIDI Learn (`io_write`, page 1, reset), rushes `in` / `out` (`F.iolen/iost/iow`), Launchpad `loop_in_step`, pont web (`read_state`, `set_io`, reset).
  8Waves : pas de forme d'onde à vide, rien changé. Test `tools/tpreio.py` (JSFX). `VL.BUILD = "27nov-preio"`.

## Ce qui a été fait (session de nov. 2026, résumé)

- **JSFX** : V3.19 anti-clics ; V3.20 slicer précis, largeur Cloud = Stereo, Rec Density aléatoire, Auto-Replace par
  niveau ; V3.21 Cloud v2 (Size/Density/Agitation/Freeze/Diffuse) ; **V3.22** REC calé sur l'appui (pré-enregistrement
  depuis l'historique d'entrée + fin compensée, heure d'appui via gmem 950/951) ; **V3.23** compensation de latence
  aller-retour (overdubs écrits en arrière de la latence, 1er REC esclave tourné), longueur d'un fichier importé = valeur
  musicale **la plus proche** (1/8, 1/4, 1/2, n boucles).
- **Launchpad** : page web indépendante ; PAGE 2 / PAGE 3 = tap (aller) ou **maintien = page temporaire** (retour au
  relâchement, HOLD à la souris pareil) ; Ctrl/HOLD + clic = geste de groupe (1er looper libre → nouveau groupe, groupé →
  édite son groupe) ; ligne de statut sensible aux groupes ; doubles appuis Stop/Play (tout arrêter) et Restart (tout) ;
  pad D5–D8 sur slot vide = le sélectionne ; au Play de REAPER le curseur se cale sur l'horloge du maître (B2) ; rushes
  gate ON/OFF ; pads de rush qui clignotent en attente de synchro. Ports MIDI du Launchpad mémorisés par **nom** (`nowundo_vl/lp_in_name`,
  `lp_out_name`, choix du menu ; « Aucun » = détection auto ; port absent au démarrage = détection auto).
- **Web v4.0** : onglet Loopers (forme d'onde, In/Out au doigt, rangées B/A du Launchpad, modes, sliders Feedback /
  Dégradation / Output / Stereo, VU), navigation commune 8 pages Twister + 8 loopers sur tous les onglets, appeler un
  looper le sélectionne sur le Launchpad, envoi fiable numéroté, HOLD pour PAGE 1/2/3.
- **MIDI Learn** : Beat Repeat, Auto-Replace, Reset corrigé, double appui = action sur les 8 loopers (Clear → Clear All
  Full, Reset, Stop, Restart), modificateurs lus en état réel (plus de faux Alt), raccourcis **en pause pendant toute
  saisie de texte**, cumul clavier + MIDI. V3.25 : saisie détectée aussi dans l'éditeur de code JSFX / ReaScript
  (`KB.text_focus` : classe contenant « edit », ou fenêtre « Development Environment » / titre .jsfx .lua .eel).
- **Twister** : boutons d'effets du web = looper sélectionné + son groupe ; page 7 Custom : « Effet du slot (type) ».
  Page 4 Slicer réorganisée : C = Detect | Detect Hold | Pitch | Link ; D = Root | Release | **Scaler** (24 nov., rose, param 70,
  lu en `112000+…+3`) | **Dry/Wet**. Une case peut avoir sa couleur sur toute page (`spec.col` fenêtre / web, `spec.twc` Twister).
- **8 Panel** : import Adapter/Étirer dès qu'une référence existe ; étirement fait dans le script (Hermite) ; le 1er
  fichier fixe le tempo du projet (A2).
- **Scenario / Rushes** : rushes gate (appui = tel qu'écrit, relâchement = tout défait) ; éditeur avec champ texte,
  curseur, **assistant** (propositions en tapant, Tab/Entrée), palette par catégorie, `off` / `*` sur la dernière action,
  clic droit = action en off, Maj+E = boîte REAPER ; liste : Ctrl+C/X/V/D + clic droit ; titre par défaut = contenu ;
  « macros » renommées **Rushes** à l'écran.

- **Drop de groupe (V3.25, refait)** : `VL.drop_group()` / `VL.drop_tick()` dans le Launchpad, **pad B2 de la page 1** (à la
  place de QUANTISE IN/OUT, qui reste dispo par MIDI Learn / Twister), bouton DROP de l'onglet Loopers du web
  (`ACT,i,drop_group`), pédalier (`drop_group`), action MIDI Learn « Drop de groupe », `drop_group` dans `NowUndo_VLcmd/q`.
  Principe (corrigé : avant, piste « NU Drop » séparée = horloge décalée → saut + boucle bancale) : `NU_DropCapture` est
  posé **en bout de chaîne de la piste du looper cible** (même bloc audio = calage exact), la piste reçoit 2 canaux de
  plus où arrivent les sends post-fader des autres loopers (broches 3/4, gain 1/volume cible) ; tout est retiré à la fin.
  Il enregistre **un passage** de la boucle la plus longue (durée entendue =
  fenêtre / vitesse), effets des pistes et tous les modes compris, raccord fondu sur 10 ms. Puis la cible joue le mixdown
  à plat (vitesse 1, pitch 0, pas de reverse / slicer / cloud / BR / stereo, mix et out vol 100 %, fade 0), ses slots FX
  sont coupés, les autres loopers qui jouaient sont **effacés** dans le même bloc et le **groupe est supprimé**. Undo sur
  la cible = sa boucle d'avant. Les pistes d'effets aux (20-23) ne sont pas incluses (elles mélangent d'autres sources).
  Vérifié par `tools/tdrop.py` (effet sur la piste source, A en reverse, B granulaire, A vitesse ×2 : recalage de 16
  samples sur l'horloge, normal).
- **Rushes gate / toggle (V3.25)** : le **dernier rush actif gagne** (pile `H._live` dans le Scenario, clé = looper + mot).
  Activer = tel qu'écrit (plus d'inversion en toggle : un 2e BR ne coupe pas le 1er, la fraction devient la sienne) ;
  désactiver = chaque action reprend la valeur du rush actif le plus récent qui la porte, sinon défaut. Pad toggle allumé
  = rush dans la pile (et 1er mot vérifié sur le looper). Corrigé : `brf` au relâchement d'un gate revient bien à Free.
- **MIDI Learn (V3.25)** : **Ctrl + clic sur Learn = cumul** (le contrôleur garde ses autres fonctions) ; cible
  « Dry/Wet des effets (Slicer + Cloud + BR) » (`par:fx_mix`, champ `also`) ; écritures de paramètres sur 3 boîtes
  + file d'attente (`PQ`).
- **Mute de looper (V3.25)** : dans le JSFX (fondu ~5 ms, la boucle tourne, l'entrée n'est pas coupée, la piste non
  plus) ; action Launchpad `mute` (bascule, groupe), MIDI Learn « Mute », mot de rush `mute` / `mute off`, bouton MUTE
  (modes) de l'onglet Loopers du web. Pas de pad sur la page 1 (pleine).
- **Page 4 : couche Loop remplacée par « Rushes 2 »** (cases 65-128) ; 128 rushes max dans le Scenario. (Remplacé en V3.27 : sous-pages a..z.)
- **Co-enregistrement (V3.25)** : plusieurs loopers en REC sans synchro, sortie ensemble : le 1er qui sort devient maître ;
  un autre qui voit ce maître apparaître avec la même durée (±0,3 s) sort **avec lui** (même longueur, sync point 0,
  repart avancé du temps écoulé) au lieu d'attendre le tour suivant (`try_finish_rec`, `co_rec`, `tools/tcorec.py`).
- **Enregistrement en Slicer (V3.25)** : **Replace / Auto-Replace remplacent la tranche entendue, comme un Echoplex** :
  au début du remplacement l'écriture part de la tête du slicer, puis avance d'un bloc (vitesse de lecture) sans suivre les
  sauts du slicer (`slc_move`, `sw_on` / `sw_pos`) — avant, chaque répétition de la tranche réécrivait son début et il ne
  restait que la queue de la note. **Overdub** en slicer : écrit à la tête de fond (`slx_pos`, `slw_move`). La porte du
  slicer ne coupe plus l'écriture.
- **Appareils MIDI stricts (V3.25)** : une affectation ne répond **qu'à l'appareil sur lequel elle a été apprise**
  (MIDI Learn `dev_ok`, Twister, pédalier `matches(..., dev)`). Ancienne affectation sans appareil : lignes Twister (`tw:`)
  = Twister seulement ; autres = seulement les appareils déjà utilisés par au moins une affectation. Un appareil sans
  learn (ex. QuNeo) ne déclenche plus rien (il envoyait des Clear via des CC communs).
- **Nouveau REC (V3.25)** : un looper qui lance un nouvel enregistrement (REC sur vide, Re-Rec) termine le REC en cours
  d'un autre looper (> 0,3 s), qui attend son point de synchro puis joue (`tools/trec.py`). Un overdub ne le fait pas.

## Anciens problèmes (RÉSOLUS, confirmé par l'utilisateur le 21 nov.)

Launchpad muet à l'ouverture du MIDI Learn, Clear envoyés par le QuNeo, saut / boucle bancale du Drop, fractions du
Beat Repeat (1/16 vs 1/32) : **tous résolus**. Ne pas les rouvrir sauf nouveau signalement.

## V3.26 (18 nov.) : détection des slices « à l'oreille »

- Avant : les N slices = les N attaques au **volume brut** le plus fort (sans écart) → tout se regroupait dans la partie
  forte de la boucle ; une attaque noyée dans un fond (charley sur basse) n'était pas vue ; l'amorce de l'analyse lisait
  le début de la boucle à l'envers (`%` d'EEL2 sur un négatif) et pouvait retarder la 1re slice.
- Maintenant (`dt_*` dans le JSFX) : 3 bandes (< 150 Hz, médiums, > 2,5 kHz), suiveurs de crête, contraste en dB avec le
  fond (monte en 250 ms, redescend en 60 ms) **et** avec le niveau d'il y a ~25 ms (écarte trémolo / nappe qui enfle),
  seuil 6 dB, masquage 60 ms (la plus forte des deux reste). Choix des N : score = contraste (plafonné 30 dB) + un peu de
  volume, écart mini = moitié de l'écart moyen, bonus d'éloignement (à score égal la zone la moins couverte gagne).
  Coupe recalée sur la montée au-dessus du niveau qui précède (`odf_refine`).
- Test : `cd tools && python3 tdetect.py . <fichier.jsfx> tag [-v]` (scénarios : fort puis doux, basse + charley,
  crescendo, nappe avec trémolo).

## V3.26 : WARP (18 nov., étape 1 livrée, non testée dans REAPER)

- Comme le warp d'Ableton : les attaques (détection V3.26, **toutes**, pas la limite Slices) sont calées sur une grille
  (`warp_grid` 0..5 = 1/4 1/8 1/12 1/16 1/24 1/32, sur la boucle de chaque looper via `loop_beat_len`) avec une force
  (`warp_force` %). Entre deux attaques : étirement sans changer la hauteur (fenêtres de Hann 50 %, WSOLA ±5 ms, jamais de
  lecture au-delà de l'attaque suivante), 10 ms d'attaque jamais étirés, fondus de 3 ms aux raccords. Circulaire (raccord
  de boucle compris), longueur inchangée.
- **Non destructif précalculé** (choix de l'utilisateur) : original = couche d'historique `wp_orig`, version calée =
  couche suivante `wp_wsl`. ON/OFF = undo/redo internes en fondu (sans `sync_hard_resync`). Grille / force / In-Out
  changés (attente 250 ms) → recalcul depuis l'original dans la couche d'après, bascule, recopie dans `wp_wsl`.
  Toute nouvelle couche (overdub…) **fige** le warp (`warp_on` = 0). Undo / redo de l'utilisateur pilotent ON/OFF.
  Clear / changement de part = plus de warp. Calcul étalé sur les blocs (~0,5 s pour 4 s de boucle à 48 kHz).
- Protocole : commande `+48` = **38** (arg 0 bascule / 1 on / 2 off) ; paramètres `+180` **65** grille, **66** force ;
  état publié `+156` (0 off, 1 on, 2 calcul), `+157` grille, `+158` force. Sliders 65-67.
- MIDI Learn : action « Warp ON/OFF », paramètres « Warp : grille », « Warp : force ». Affichage « WARP 1/16 100% »
  en haut à droite de la forme d'onde du JSFX. **Dans la fenêtre du JSFX** (looper utilisé seul) : bas du panneau
  PLAYBACK = bouton Warp, bouton grille (clic = suivante), barre Force.
- Grille = **tempo de la boucle** (`loop_beat_len` : longueur / nombre de temps). Nombre de temps : bouton « Loop Beats »
  (Auto / 2..32), sinon Auto (libre ou maître : puissance de 2 × chiffre de mesure, tempo le plus proche de 112 ;
  esclave Host / d'un maître : déduit du tempo de référence). Le tempo de REAPER ne sert qu'à ce comptage.
- **EEL2 : les noms de variables ne distinguent pas majuscules / minuscules** (`wp_A` = `wp_a`). Le traducteur Python
  le fait maintenant aussi (tout en minuscules).
- Test : `cd tools && python3 twarp.py . <fichier.jsfx> tag [--play [-v]]`.
- (Corrigé plus tard, voir Beat Repeat) un Undo utilisateur à longueur égale faisait un petit clic au tour suivant.

## V3.26 : Cloud qui craque (18 nov.)

- Reproduit (`tools/tvoice.py`) : voix tenue forte + densité 95 % → les grains s'additionnent parfois en phase, crêtes
  au-dessus de 0,95 → écrêtage doux de sortie = craquements. Corrigé : **limiteur à anticipation 2 ms** sur la sortie du
  Cloud (seuil 0,8, `cl_lk` / `cl_lg`), le gain est atteint avant que le pic sorte de la ligne à retard. Le Cloud a donc
  2 ms de retard. Le banc simule maintenant le Cloud (adresses fixes 120 M ramenées dans `bench.py`), `tools/tcloud.py`.
- **Vraie cause des craquements (trouvée sur l'enregistrement de l'utilisateur)** : EEL2 ne distingue pas majuscules /
  minuscules → `cl_W` (somme des fenêtres) = `cl_w` (fenêtre du grain) et `cl_A` (attaque) = `cl_a` (agitation) depuis
  la V3.21 : le gain du nuage sautait à chaque grain. Renommés `cl_wsum` / `cl_atk`. **`tools/eel2py.py` met maintenant
  tous les noms en minuscules** (comme EEL2) : le banc reproduit le bug sur V3.25 (27 sauts / 4 s) et 0 sur V3.26.
  Aucune autre collision réelle dans le JSFX (les autres paires sont des locales de fonctions différentes).
- **Clics inscrits dans la boucle** (enregistrement utilisateur : 2 clics à 17 ms d'écart, au même endroit à chaque tour ;
  le Cloud les fait réentendre partout) : l'overdub démarrait / s'arrêtait d'un coup. Corrigé : **fondu de 5 ms à
  l'entrée et à la sortie de l'overdub** (`dub_pf` / `dub_g`, la sortie continue d'écrire 5 ms en baissant). Les boucles
  déjà enregistrées gardent leurs clics (à refaire). Constaté : Launchpad fermé = plus de clics en lecture normale
  (micro-overdubs involontaires depuis le Launchpad ? non confirmé).
- **Beat Repeat qui clique (18 nov.)** : reproduit sur une voix (`tools/tbr.py`). Causes : (1) au changement de fenêtre,
  la fenêtre « glissait » (`smooth_start/width`) et la tête rebondissait d'un bord à l'autre ; (2) le saut de la tête
  (recalage `sync_hard_resync` / repli dans la fenêtre) était sec. Corrigé : fenêtre posée d'un coup + **fondu 6 ms**
  (`xf_begin(xf_len_rs)`, voix fantôme) à chaque BR on / off / refresh, et tout recalage > 64 échantillons en lecture
  normale passe aussi par ce fondu (petit recalage = anti-clic `pd_arm`). En BR, chaque répétition a au moins 3 ms de
  fondu même si Fade = 0. Effet de bord voulu : l'ancien petit clic après un Undo (recalage au tour suivant) a disparu.
- **Warp + Beat Repeat (18 nov.)** : le BR change In/Out, qui entraient dans la signature du warp → recalcul sur la
  fenêtre du BR (« le warp se réinitialise »). Le warp utilise maintenant la fenêtre de la boucle (`wp_win_s/w` =
  `br_saved_start/width` pendant un BR). Vérifié dans `tools/twarp.py` (cas BR on/off : pas de recalcul, warp gardé).
- Signalé aussi : « en Link il ne suit plus la tête de lecture, le LFO doit avoir Pos comme centre » : pas reproduit
  (en Link le centre suit `pos`, le LFO oscille autour du centre) ; questions posées (Freeze ? curseur violet ? Twister ?).

## 19 nov. : clics = PC + raccord de boucle

- **PC de l'utilisateur** (MSI PRO B840, Ryzen 5 8400F, RTX 5060 Ti, Antelope Discrete 4 en USB, buffer 128) : LatencyMon
  montrait des DPC `Wdf01000.sys` de 2,7 à 4,2 ms (plus long qu'un bloc de 128) quand REAPER tournait. Réglé côté PC :
  Global C-state Control = Désactivé dans le BIOS (Overclocking > Advanced CPU Configuration > AMD CBS) ; après 20 min,
  pire DPC 0,85 ms (NVIDIA). Le trafic MIDI des scripts est faible (Launchpad ~27 msg/s, Twister diff ≤ 33 Hz).
- **Clic au raccord de la boucle** (enregistrement `clic.wav`, Fade = 0) : marche à chaque tour au même endroit. Corrigé :
  au départ du REC on garde les 5 ms d'entrée qui précèdent la boucle (`seam_capture`, historique `ih_*`), à la fin les
  5 dernières ms fondent vers elles (`seam_apply` au début de `finish_rec`, avant la rotation de latence). Pas en reverse /
  ping-pong / vitesse ≠ 1. Test `tools/tseam.py . fichier.jsfx <fade_ms>` ; tlat / tcorec / trec / tdrop / twarp inchangés.

## 19 nov. : bosses énormes avec Slicer + Beat Repeat (bug ancien, présent en V3.25)

- Enregistrement `clic2.wav` : bosse arrondie de 3 ms, 10× le signal, qui s'arrête net. Reproduit (`tools/tslc.py`,
  `tools/tslc2_combo.py`) : Slicer + BR ensemble → 45 sauts / 3 s, sortie collée à ±1. Cause : le Slicer envoie la tête
  hors de la fenêtre du BR (plusieurs fenêtres plus loin) ; le repli de `safe_pos` ne retirait qu'**une** fenêtre, `p1`
  était bloqué au bord et `frac = safe_pos - p1` valait des milliers → `hermite` extrapolait une cubique (jusqu'à 1e11).
  Corrigé : `hermite` borne `frac` à [0,1] (protège les 11 lectures) + vrai modulo pour `safe_pos` / `old_safe_pos`.
  0 saut dans toutes les combinaisons ; tbr / twarp / tseam / tcorec / trec / tdrop inchangés.

## 20 nov. : boucle en retard de la latence + saut à chaque mesure

- `clcic_decall_.wav` (clic à droite, boucle à gauche) : boucle **en retard de ~16 ms** (latence aller-retour non
  compensée). Cause : la rotation de latence V3.23 ne se faisait que si le 1er REC suivait une référence
  (`rec_ref_kind > 0`) ; un 1er REC **libre** (REAPER qui joue le clic) restait en retard. Corrigé : rotation de
  `lat_samps` pour tout 1er REC (`finish_rec`). Test `tools/thost.py . f.jsfx <lat> [host|libre]` → 0,0 ms dans les deux cas.
  `tools/tlat2.py` corrigé : le musicien de l'overdub joue sur les coups **réels** de la boucle (avant : positions codées
  en dur = non rotées) ; ancienne et nouvelle version donnent le même écart.
- `clcic_decall__gauche_ref_droite_looper.wav` : clic 117,4 BPM ; le looper joue des coups espacés de 499,3 ms (120 BPM)
  et saute de ~35 ms à chaque mesure de REAPER (2,044 s) = la boucle dure ~2,0 s au lieu de 2,044 → recalage Host à chaque
  mesure (le « saut sur la 1re attaque »). Cause non trouvée : questions posées (tempo REAPER, Master Sync, Speed, Loop Beats).

## V3.27 (21 nov.) : dub brut A / D (écrit par l'utilisateur) + bouton Mute

- Slider 68 `dub_raw` : **A** (0, « bande ») = overdub compensé d'origine (la couche ressort telle que jouée, sans le
  pitch / speed / reverse en cours) ; **D** (1, « brut ») = l'entrée est écrite à 1 sample par sample vers l'avant
  (`dub_raw_tick`, `raw_splat`) dans les zones d'accumulation du dub compensé, collée au bouclage de la tête
  (`dub_commit_begin`, ou à la sortie de l'overdub), puis relue transformée comme le reste. Seulement hors Slicer et
  seulement quand quelque chose est transformé (pitch / speed, varispeed, reverse) ; sinon chemin normal. Empilement =
  somme (poids plafonné à 1). Compensation de latence au départ de l'écriture (`wr_off`). Changement de mode = `dub_flush`.
- Carré **A / D** en bas à droite du panneau OUTPUT (394, 598). État publié en `+159`. Pilotage : commande **39**
  (0 bascule / 1 D / 2 A) et paramètre **67** ; MIDI Learn « Dub A / D (bascule) » + paramètre « Dub A / D » ; mots de rush `a` / `d`.
- Ajouté par Claude : bouton **Mute** du Transport (venu de la V3.26) ; parenthèses autour d'un `? :` à affectations
  (`rw_pos`, sens inchangé). Test `tools/traw.py . [0|1] [rev|speed]` : A = impulsion revient à sa place, D = relue en
  reverse / à la vitesse ; pas de NaN. Non testé dans REAPER.

## 21 nov. : MIDI des rushes + modèle de démarrage des rushes

- **MIDI d'un rush** : appris dans la fenêtre Rushes (bouton **MIDI** de la rangée ADD…▼, ou clic droit > « MIDI Learn de
  ce rush » ; Ctrl + MIDI = cumul ; Échap / re-clic = annuler ; clic droit > « Oublier le MIDI »). Rangé **dans le rush** :
  9e champ de la ligne `M` = `status:ch:d1@appareil` (`m.midi`, suit export / import / pages). Badge « MIDI » sur la ligne.
  Un contrôle = un seul rush (sauf cumul). **Écoute et déclenchement = script MIDI Learn** (`RL` : `RL.poll`,
  `RL.try_learn`, `RL.fire`) : demande `NowUndo_MIDILearn/rush_learn` = `id\ttemps`, réponse `rush_learned` =
  `id\tclé\ttexte\ttemps` (+ « pilote aussi : … » si une map du MIDI Learn a le même message). Appareil **strict**.
  Gate : appui = on / relâchement = off ; sinon 1 appui = 1 déclenchement (CC : passage au-dessus de 63). Envoi dans
  `NowUndo_Scn/mcr` avec **cible vide = sélection** du Launchpad et l'heure de l'appui (REC calé). Page du MIDI Learn :
  seulement « Rushes appris : N » dans la ligne d'aide. Test `tools/trush_midi.lua`.
- **Modèle de démarrage des rushes** (bouton **MODELE**, 5e de la rangée du bas) : ExtState persistant
  `NowUndo_Macros/model` = fichier de `Data/NowUndo_Macros/`. Démarrage : modèle s'il y en a un, sinon `_autosave.txt`,
  sinon la mémoire de REAPER (le fichier d'abord : un ExtState long peut être relu en partie). **Le modèle n'est jamais
  réécrit automatiquement** (choix de l'utilisateur) : menu « Enregistrer l'état actuel dans le modèle », « Recharger »,
  « Aucun modèle ».

## 21 nov. : SCENARIO + RUSHES fusionnés (une seule fenêtre)

- Plus d'onglets : **scénario à gauche** (`H._scn_draw`, largeur 38 %, 250..440 px), **rushes à droite** (`mac_draw`
  dessiné hors écran image 7 puis `gfx.blit`, souris décalée de `H._ox`) ; un clic dans un panneau lui donne le clavier
  (variable `tab` = panneau actif, liseré jaune). Fenêtre ≥ 1000 px à l'ouverture. Liste des rushes : 1 colonne si < 760 px.
- **Un pas = un rush** (`steps[i] = "@id"`) : GO / BACK lancent le rush (`H._run_step` → `run_macro`, cible vide =
  sélection du LP). Pas texte (anciens, fichiers importés) convertis en rushes perso « S<n> … » par `H._scn_conv`
  (réutilise un rush perso de même texte). Ajout : glisser un rush de droite sur la liste du scénario (`H._to_scn`) ou
  `+ SELECTION`. EDIT d'un pas = éditeur du rush. RETIRER / ▲▼ / → ITEM / VIDER. Capture du scénario (incrémentale) :
  chaque VALIDER crée un rush (`H._mk`) et l'ajoute comme pas. Timeline ON/OFF ; **piste = menu des pistes** (nom).
  Export : le fichier garde le texte des rushes (`# nom` au-dessus) ; Import : reconvertit. Exemple de scénario supprimé
  (l'ancien exemple enregistré est vidé). Test `tools/tscn.lua`.

## 22 nov. : looper seul = esclave d'un maître fantôme + Slicer bloqué sur 2 pas (JSFX V3.27 + MSV3)

- Signalé : looper ouvert **seul** (sans MSV3 ni Launchpad) → « MS: SLAVE » et Slicer qui ne joue que 2 pas. Cause unique :
  gmem garde l'état de la synchro tant que REAPER tourne → maître (`gmem[o]` = 1, id d'un looper disparu) dont l'horloge
  `[o+3]` est figée ; le Slicer (Slicer Clock = Master) suivait cette horloge (`mclk_trk`). Reproduit : `tools/tghost.py`
  (avant : pas -1 / 0 seulement ; après : le Slicer avance).
- Corrigé (@block, après le battement `130+i`, variables `gh_*`) : maître looper sans battement depuis 1,5 s → libéré ;
  Host libéré si le MSV3 a battu un jour (**`gmem[921]`** = battement du MSV3, ajouté au MSV3) puis s'est arrêté. Un looper
  **seul depuis 2 s** avec une boucle devient maître (`gh_want` : seulement au chargement ou après un fantôme ; un Unlock
  fait à la main n'est pas repris). Drop en autonome : pas possible (orchestré par le Launchpad), proposé : bouton
  « Resample » dans le JSFX.

## 24 nov. : page 9 « LOOPER » du Twister (réglages principaux du looper sélectionné)

- `CU.P9` (`CU.p9_build`, `CU.p9_cell` : cellules faites avec `CU_KNOBS` / `CU_BTNS`, règle de groupe `CU.set_group`, push
  `CU.fire`) ; `CU.page_cells(9)`. Disposition (rangées haut → bas, colonnes A..D) : **1** Volume | Feedback | Stereo (rouge) |
  Grain (rose) ; **2** Speed (push = Speed 1 + Pitch 0, boîtes +180 et +195) | Pitch (push = Link P/S) | Scaler | Grn Fade (rose) ; **3** In (push = Full Loop = reset In/Out) | Out (push =
  Out ↔ Width, `CU.p9w`) | BR Mix (push = Beat Repeat) | Quantize `io_frac` (push = Full Loop) (vert) ; **4** Rec Dens (push =
  REC) | Play (knob inactif, anneau = joue, push = Stop/Play) | Clear (knob inactif, anneau = boucle, push = Clear) | Auto
  Seuil (push = Auto) (rouge). Push non précisé = défaut du knob.
- Pages 1..9 partout : `fighter_page()` du Twister, `VL.set_fighter_page` (clamp 9), `twpage_9`, MIDI Learn (`FIGHTER_NAMES`
  + « Looper » → action « Twister page 9 (Looper) » ; pas d'aux pour la page 9), rush `go t9`.
- **Sélection d'un looper → page 9** si les pages ne sont pas verrouillées (`tw_lock`) : `VL.tw_follow_sel()` dans
  `VL.select_looper` / `VL.step_looper` (pas en miroir) ; MIDI Learn `fire_ui` sel_looper (sauf si l'action demande une page).
  Une action qui suit la sélection (REC, Slicer…) garde sa navigation auto (`VL.auto_twister` passe après).
- **Navigation auto vers la page 9 au lieu de la page 1 (Volume)** : REC / Re-Rec / Clear All (Full) / Reset Pitch / Speed,
  Slicer ou Cloud coupés, pitch revenu à 0, speed revenu à 1, plus aucun effet actif (`VL.fx_nav`) ; `VL.AUTO_TW` du
  Launchpad et `AUTO_TW` du MIDI Learn.
- Test : mock lupa (lectures, knob Volume, pushes REC 1 / Stop-Play 3 / Full Loop 22 / BR 33 / Auto 19, Out ↔ Width).
  Non testé dans REAPER ; la page web n'a pas de bouton 9 (elle affiche la page quand elle est active).

## 24 nov. : stretch = alignement des grains réparé + Grn Fade sur la lecture

- **Bug introduit le 23 nov.** (limite « pas de recherche au-delà de ×2,5 ») : un commentaire `//` posé au milieu de la ligne
  de naissance des grains cachait `rd_Wn = min(512, ...)` → `rd_Wn` jamais calculé → **alignement WSOLA de la lecture coupé**
  (bourdon à la fréquence des grains sur les notes graves, répétitions audibles). Réparé. Nouvel outil
  **`python3 tools/eelcomment.py f.jsfx`** (code caché derrière un `//` sur la même ligne) : à lancer avec `eelorder.py`.
- **Grn Fade** (`grain_fade`, 5..50 %) règle maintenant aussi le fondu des grains de **lecture** (avant : 2 % fixes, il ne
  servait qu'aux grains de l'overdub).
- Test `tools/tgrain.py . f.jsfx <pitch> <speed>` (note de 65 Hz, modulation d'enveloppe) : avant 6-16 %, après 0,1 % à
  40 ms, ~5 % à 80/150 ms dont 2-4 % viennent du raccord de boucle dans la mesure (même valeur sans transposition).
- Drop solo : le banc montre que la bascule remet déjà le pitch à 0 (`dr_install`) ; question posée à l'utilisateur.
- **Transposition par un autre contrôleur** (signalé : entrée MIDI de la piste du looper = piano canal 9, mais le QuNeo canal 1
  transposait) : les **envois** créés par le Launchpad (entrées → loopers, looper → looper, drop) transportaient le MIDI
  (défaut REAPER) et contournaient l'entrée MIDI de la piste. Maintenant `LPF.send_nomidi` met `I_MIDIFLAGS` = 31 (MIDI
  coupé) à la création **et** sur les envois existants (`ensure_send` / `set_send_open`, repassé au démarrage par
  `VL.apply_routing()`). Envois faits à la main dans REAPER : non touchés.

## 23 nov. : clavier MIDI = sélection + transposition en lecture + SCALER (JSFX V3.27, Launchpad, Scenario)

- **Sélection** : le Launchpad publie `gmem 6060` = masque des loopers visés (bit i-1 = looper i sélectionné ou dans le
  groupe du sélectionné) et `6061` = heure (`VL.sel_publish`, pas en miroir). Le JSFX n'accepte les notes (sampler à
  l'arrêt **et** transposition en lecture) que si son bit est là ; rien publié depuis 3 s (pas de Launchpad) = tout accepté.
  Les note-off passent toujours.
- **Transposition en lecture** (états 2..6) : notes tenues dans `kb_held[128]` ; la plus grave règle **directement le
  bouton Pitch** (`pitch = sc_snap(note - sampler_root)`, C3 = root 48 = 0) ; au relâchement la hauteur **reste**
  (choix de l'utilisateur). Mono pour l'instant (voix d'harmonie : étape 2, gratuites tant qu'une seule note).
- **SCALER** (slider73 `pitch_scale`, bouton-menu sous Speed dans PLAYBACK, 16,328) : 0 Free, 1 demi-ton, 2 par ton,
  3 penta, 4 majeure, 5 min harm, 6 min mel, 7 diminuée, 8 augmentée (0 3 4 7 8 11), 9 octave. Masques 12 bits
  (`sc_mask`), tonique = hauteur d'origine de la boucle (Pitch 0). `sc_snap` (degré le plus proche), `sc_step` (cmd 21 :
  cible calée, sinon degré suivant). Bouton Pitch du JSFX : tourne librement (`pitch_ui_raw`), affiche la valeur calée.
  Param **4** (Twister, MIDI Learn, web) = calé ; param **69** = pitch **absolu** (rushes) ; param **70** = gamme.
  Changer de gamme par param 70 ne recale pas le Pitch (un rush garde sa valeur) ; le menu du JSFX, si.
  **Pitch Spread** Slicer / Cloud en gamme (`sc_spread`, sauf Free / Octave = sauts d'octave d'origine) : proportion
  min(1, 2×%) des slices / grains, hauteur au hasard dans ±24×% demi-tons calée sur la gamme ; regénéré au changement.
  Publié en `112000 + (i*3+part)*20 + 3`. Knob **« Scaler (gamme) »** dans `CU_KNOBS` (param 70, offset de lecture `"x3"` =
  zone supplémentaire, lu par `CU.rd` dans le Twister, affiché par nom) : posable sur la page 7 Custom.
- Rushes : `pitch` → param 69 (absolu, `pitch 3.5` = 3,5) ; mot **`scale`** 0..9 ou `free demi ton penta maj mharm mmel
  dim aug oct` (`H._scnames`, palette « Niveaux »). Test `tools/tscale.py . v327.jsfx` (midirecv simulé par une file).

## 23 nov. : page 7 Custom du Twister = 4 sous-pages 7a..7d

- Sous-page courante : ExtState persistant `nowundo_vl/tw_cu_sub` (1..4). Assignations : `NowUndo_MIDILearn/custom` (7a,
  inchangé) et `custom2` / `custom3` / `custom4` (7b..7d), toutes dans le modèle du MIDI Learn (`TPL_KEYS`) et rechargées par
  le Twister (`CU.model_boot`). Twister : `CU.sub()`, `CU.ext(sub)`, `CU.cells()` (cache par sous-page) ; fenêtre : boutons
  a b c d en haut à gauche + « Custom 7b ». MIDI Learn : groupes « Custom P7a..P7d » (ids `cu:` = 7a, `cu2:`..`cu4:`),
  `CUL.parse(sub)` ; actions « Twister page 7a..7d » (`fighter:7a`..) ; « Twister page 7 » déjà en page 7 = sous-page
  suivante. Launchpad : re-appui sur le pad Twister 7 = suivante (`VL.tw_cu_sub`), commande `twpage_7_<k>`. Rush :
  `go t7b` (`H._go`, palette). Non testé dans REAPER (syntaxe + locales vérifiées seulement).

## 23 nov. : craquements en STRETCH (vitesse / pitch granulaire sans Link), temps réel seulement

- Signalé : stretch actif = craquements en direct, CPU moyen bas (LatencyMon OK), l'enregistrement de la sortie dans REAPER
  est propre → décrochages temps réel (blocs de 128 en retard), pas un défaut du son. Cause probable : recherche WSOLA
  faite **d'un coup à la naissance de chaque grain** (`rd_pick` lecture ~19 500 lectures, `wg_pick` overdub ~74 000
  produits) ; plusieurs loopers dans le même bloc = bloc trop long.
- Allégé : `rd_pick` 1 point / 8, pas de 8 + affinage ±7 (~5 600) ; `wg_pick` → `wg_sc` + pas grossier pour ~12 000
  produits + affinage (~19 000). Banc : même sortie (`tools/tstretch_q.py`), blocs > 4× la médiane 15 → 0
  (`tools/tcpu.py . v327.jsfx gran`). **Non confirmé dans REAPER** : si ça craque encore, regarder le « RT CPU / longest
  block » du Performance Meter et essayer un buffer de 256.
- Suite (vidéo de l'utilisateur : L1-L4 à ×10, pitch +0,5, 128 samples → trous de bloc + craquements) : **pas de recherche
  WSOLA au-delà de ×2,5** (`abs(pos_step) < 2.5`, ~83 recherches/s/looper à ×10 pour un gain nul) ; **clic au passage
  ×1 → ×10** (3 sauts dans le signal, `tools/tstretch2.py`) : moteur au repos = aucun grain, ~12 ms de trou pendant le fondu
  puis 1er grain normalisé par `total_w` ≈ 0 = plein volume d'un coup → `spawn_timer` forcé quand `grain_mix` = 0 (1er grain
  dès le démarrage) + `total_w = max(total_w, 0.35)`. Banc : 0 clic sur 1→10, 10→1, 1→0,25.
- **Cloud, 4 loopers** : RT longest-block **5,04 ms** pour 2,90 ms (128 samples à 44,1 kHz) = décrochages. Fenêtre des grains
  lue dans `lut_cos` interpolée au lieu d’un `cos()` par grain et par sample (même son à −108 dB, `tools/tcloudcpu.py`) ;
  gain réel dans REAPER inconnu (le banc Python ne mesure pas le coût EEL2). Un « hold » de 248 ms = rechargement du JSFX,
  pas le calcul : remettre le hold à zéro avant de mesurer.
- **Conclusion (mesures de l'utilisateur)** : 4 loopers en lecture simple = 4,34 ms, 1 looper ≈ 3,5 ms, et **2,68 ms sans
  ses plugins Roland Cloud** (piste « rodhes ») → le dépassement venait surtout des plugins Roland, pas de NowUndo.
- Ajouté : **mesure intégrée** du temps de calcul par bloc dans le JSFX (`pf_*` : `@block` → dernier sample du bloc),
  bandeau du haut « CPU bloc max x / y ms (analyse | freeze | warp | drop | import | cloud | stretch | overdub | rec) »,
  vert < 50 %, orange < 100 %, rouge ≥ durée du bloc ; clic = remise à zéro ; publié en `112000 + i*60 + 1` (ms) / `+ 2`
  (tag). Libellé du bandeau passé de « V3.26 » à « V3.27 ».

## 23 nov. : Clear du maître = la synchro reste verrouillée (JSFX V3.27)

- Demande : Clear du looper qui a verrouillé la synchro ne doit **pas** la libérer ; elle ne s'arrête que par unsync /
  Unlock manuel ou quand **plus aucun looper** n'a de boucle. Avant : `do_clear` remettait `gmem[o]` à 0.
- Maintenant (`ck_keep(p)`, `ck_others()`, `ck_active(p)`, variables `ck_on/len/pos/cyc1..3`) : au Clear, si un autre looper
  vivant a une boucle, le looper effacé **garde l'horloge** de la part (même longueur, même phase, publiée en
  `gmem[o+2..4]` à chaque sample, dans `@sample` après les horloges des parts) ; sinon libère. Fin : `gmem[o]` changé par
  quelqu'un (Unlock, unsync) ou plus aucune boucle (`@block`). S'il réenregistre sur cette part, il se cale sur l'horloge
  gardée comme un esclave (`is_self` annulé dans `rec_ref_capture` / `try_finish_rec`). Test `tools/tclearsync.py` (Clear
  de L1 maître : verrouillé, horloge qui tourne ; L1 réenregistre 1,3 s → 2 s calé ; tout effacé → libre ; Unlock → libre).

## 22 nov. : looper seul à la souris (Mac) : boucle décalée vers la droite

- Signalé : en autonome (sans Launchpad), à la souris sur Mac, la boucle a la bonne longueur mais son contenu est en
  retard (silence au début), relecture « pas instantanée ». Causes : (1) le clic sur REC n'a pas d'heure d'appui (le
  Launchpad l'envoie en gmem 950/951) → pas de pré-enregistrement ni de fin ramenée au clic ; (2) la latence aller-retour
  n'est fournie que par le Launchpad (gmem 955/956) → pas de rotation de latence.
- Corrigé : `ui_rec_t` = heure du clic sur REC (entrée et sortie) → `rec_lag_pend` (≤ 0,1 s) dans `rec_cmd` ;
  **slider70 `lat_own`** (-1 = Auto = Launchpad, sinon ms) = bouton **« LAT auto / LAT n ms »** (menu) dans le panneau
  OUTPUT (VU raccourcis à 300 px). Test `tools/tstart2.py . v327.jsfx <retard_clic_ms> <latence_ms> <LAT>` (latence 30 ms,
  LAT 30 → 1er son à 0 ms ; LAT auto sans Launchpad → 30 ms). `tools/tstart.py` : REC + son simultanés → 0 ms.
- **Bouton CAL (23 nov.)** sous LAT (panneau OUTPUT, 330, 592) : 8 clics (2 kHz, 1,5 ms, 0,6) joués **à la place de la
  sortie** du looper toutes les ~0,47 s, retour écouté à l'entrée (bruit de fond 120 ms avant, pic dans les 300 ms
  après) ; délai = pic − milieu du clic ; tri, médiane, ≥ 3 retours à ±1 ms → `lat_own` (LAT) ; sinon message (retours
  incohérents / non entendus) et LAT inchangé ; re-clic = annuler ; message 8 s sur la ligne d'aide du bas. Mémoire
  `cal_d = sm_r + 528` (16 cases). Mesure l'aller-retour réel (pilote + effets après le looper + air). Test `tools/tcal.py`
  (23 ms → 22,9 ; 47,3 ms faible → 47,4 ; trop faible → « non entendus »).
- **Calibration partagée** : `gmem[958]` = ms mesurés, `gmem[959]` = date (`time()`) ; sliders 71/72 `cal_sv_ms` /
  `cal_sv_d` (sauvés avec le projet, la plus récente gagne, republiée au chargement) ; LAT « auto » = calibration si
  présente, sinon Launchpad (955 + 956) ; après CAL le looper repasse en Auto ; menu LAT : « Oublier la calibration ».
  Test `tools/tcal2.py`.
- Si le décalage reste grand : piste du looper armée avec monitoring (sinon REAPER calcule les effets en avance,
  « anticipative FX », et le retard dépasse la latence de la carte).

## 21 nov. : FILTRE de la liste des rushes + clic sur « LP c1.3 »

- Bouton **FILTRE ▾** en haut de la liste (à côté de `< RUSHES … >`), menu `gfx.showmenu` : **Page du Launchpad** (toutes /
  pas posés / 4a..4z avec le nombre de rushes) et **Cible** (toutes / **ciblés** = cible écrite `l1`, `l2/l3`, `g2`, `in1`,
  `l3 to g2` / **all** = `all` écrit ou case A / **non ciblés** = sélection du LP ; `go`, `g(2)`, `sync` = non ciblés).
  Les deux se combinent ; bouton bleu avec le résumé + `×` pour tout afficher. `H._flt`, `H._tclass` (cache par texte),
  `H._view()` (indices affichés), `H._vpos` ; flèches, Maj+clic, Ctrl+A, glisser suivent la liste filtrée ; le numéro de
  ligne reste celui du rush.
- **Clic sur « LP c1.3 »** d'un rush : la page 4 du Launchpad passe sur cette sous-page (`p4page_k` dans `NowUndo_VLcmd/q`,
  va aussi en page 4) et les boutons LAUNCHPAD PAGE 4 du bas la gèrent (`H._show_pg`). Test `tools/tflt.lua`.

## 21 nov. : `*` quantise sur le cycle du looper (demande de l'utilisateur)

- `*` = prochain début de cycle **du looper visé** (sa position +47 dans In/Out, sens de lecture compris : en reverse le
  cycle entendu repart de Out) ; `*1/4`, `*1/8` = prochain 1/4, 1/8 de cycle ; `*2` = 2e début de cycle (`*0.5` permis,
  `H._qparse`) ; boucle en cours de création (longueur 0 ou état 1 = 1er REC) : **immédiat** (sortie de REC comprise).
  Avant : point de synchro de l'horloge maître + grille globale gmem 99. `sync_ready` mesure l'avance (cycles/s) et part
  un peu avant le point (latence script) ; looper arrêté (position figée 0,6 s) = part quand même. Éditeur : OFF / `*`
  gardent le suffixe. Test `tools/tstar.lua`.

## 21 nov. : rushes d'usine = ROM + ordre de la liste

- Usine (64 RC-505 + 64 Effets, `H._fdefs`) : **lecture seule** (`m.rom`, 10e champ `R` de la ligne `M`, le Launchpad
  l'ignore) : pas d'effacement / édition / nom / couleur / T-G-A / déplacement (`H._ro`) ; MIDI Learn, pose sur le LP et
  Ctrl+D (copie perso) permis. Au chargement (`H._rom_fix`) : anciens rushes d'usine reconnus à nom + texte d'origine,
  manquants recréés (non posés) si la migration est faite (`fx_page` = 1). Ordre (`H._msort`, appelé par `mac_save`) :
  perso d'abord (ordre choisi), puis usine dans l'ordre fixe. Lignes d'usine : fond gris-bleu, « ROM » à la place de ×.
  Test `tools/trush_rom.lua`.

## 21 nov. : onglet Rushes réorganisé (l'utilisateur : « aucune hiérarchie »)

- Haut, au-dessus de la liste (`LY = LIST_Y + 30`) : `< RUSHES 1-64 sur 134 >` à gauche, `● CAPTURE` (`■ VALIDER` en
  capture), `+ NOUVEAU`, `EDIT` à droite. Bas, sous petits titres : **RUSH SELECTIONNE** (NOM, COULEUR, MIDI, ▲, ▼) |
  **FICHIER** (EXPORT, IMPORT, MODELE) ; **LAUNCHPAD PAGE 4** (`<` sous-page `>`, + PAGE, RENOMMER, SUPPRIMER, VIDER,
  RETIRER SEL.). Plus de gros boutons. Tient en 620 px. Reverse du Drop : `dr_tau` −1 en reverse (calé sur `sync_expected`).

## 21 nov. (corrigé) : DROP garde TOUT depuis DROP ON

- Première version ON / OFF = seulement le dernier cycle : **faux** (l'utilisateur veut tout ce qui a été joué). Maintenant :
  `NU_DropCapture` écrit tout linéairement (échantillon n en `LD_BASE+16 + n mod LD_MAXN`, publie `392` = instant du cycle
  au départ, `397` = n) ; la cible recopie au fil de l'eau à l'index `début + n` de la couche suivante ; DROP OFF fixe
  K = tours entiers jusqu'à la fin du tour en cours ; bascule quand n ≥ K + X ; repliage (index ≥ K → début) et raccord
  fondu de la fin (n = K..K+X-1) vers l'amorce (n = 0..X-1). Nouvelle longueur = K (multiple du cycle → synchro gardée).
  Place max = couche d'historique (~83 s à 48 kHz) : presque pleine sans DROP OFF → bascule sur les tours complets.
  L'ancien raccord par gmem 390/391/113000 n'existe plus.

## 21 nov. : DROP ON / OFF + drop fidèle en Slicer (JSFX V3.27 + NU_DropCapture refait)

- **Demande de l'utilisateur** : 1er appui DROP = la capture démarre ; 2e appui = bascule au **prochain début de cycle**
  (choix du moment laissé au musicien) ; appui long sur B2 = annuler (`VL.drop_cancel`). Pad : clignote (`armed`) pendant la
  capture, fixe après DROP OFF. MIDI Learn / web / pédalier appellent `VL.drop_group` = même bascule ON / OFF.
- `NU_DropCapture` tourne **en continu** sur un cycle (index = instant du cycle donné par la cible) et publie `392` (prochain
  index), `397` (nb écrit), `391` (X = 10 ms), `390` = jeton quand les X valeurs écrasées avant le début du cycle sont gardées
  (gmem `113000+k` / `114000+k`). La cible **recopie au fil de l'eau** dans la couche d'historique suivante (choisie à
  l'armement ; un nouvel état d'historique = annulation) ; DROP OFF = `380 = jeton + 0.25` → la cible bascule seule au début
  de bloc où son horloge repasse par 0 (dès qu'un cycle complet est recopié), fond la fin du cycle vers ce qui précédait son
  début, publie `jeton + 0.5` ; les sources s'effacent en voyant cet accusé ; le script coupe ensuite les effets de la piste
  cible (~1 tick de script de double effet), retire sends / capture, supprime le groupe. Commande 36 = sans effet.
- **Slicer** : durée = un cycle de l'horloge du looper (`length`, ou `mclk_len` si le slicer suit le maître), phase =
  `master_pos` (ou `mclk_pos`) + 2 (mesuré). Avant : largeur / vitesse « pitchée » (128 145 au lieu de 96 000 en pitch −5) et
  phase prise sur la tête du slicer (boucle décalée). `VL.drop_period` : slicer = longueur.
- Test : `tools/tdrop.py . [base|arev|speed|gran|solo|slc|slcp]` (protocole ON / OFF ; slc/slcp : après la bascule, A rejoue
  exactement le dernier cycle capturé au même instant).

## 21 nov. : DROP SOLO

- `VL.drop_group()` : **sans groupe sélectionné** (ou groupe où un seul looper joue) = drop du looper seul : il enregistre
  un passage de ce qu'il fait entendre (vitesse, reverse, slicer, cloud, effets de sa piste) puis le rejoue à plat ; aucun
  send, rien d'effacé, le groupe éventuel est **gardé** (`R.g = 0`). Même pad B2 / bouton web / MIDI Learn / pédalier.
  Test `tools/tdrop.py . solo` (A seul en reverse : écart 0 après la bascule, B intact, Undo OK).

## 21 nov. : page Cloud du Twister refaite + LFO Random / Smooth (JSFX V3.27 en place)

- Page 5 (disposition de l'utilisateur), A en haut : **A** Pos (push = Link/Free) | Density | Size | Agitation ;
  **B** Spread | LFO forme (Sine / Saw / InvSaw / **Random**) | Rate | Depth ; **C** Width | Diffuse (push = **Freeze**) | **PSpread** (23 nov., param 35, 0-100 %) |
  **Smooth** ; **D** - | - | **Scaler** (24 nov., rose, même case que la page Slicer, `scaler_cell()` partagée) | Dry/Wet. Push = valeur par défaut ailleurs. PSpread (pitch) retiré de la page (reste en page 7
  Custom / MIDI Learn). `SCN.P5` (capture du Scenario) suit la nouvelle disposition.
- JSFX : forme 3 = Random sample & hold (`cl_lfo_rnd` tiré à chaque période) ; Smooth (`cloud_lfo_smooth`, param 68) =
  glissement à un pôle, constante = Smooth × demi-période (`cl_lfo_sm`). Mot de scénario `clfoshape` 0..3. Test `tools/tlfo.py`.

## 21 nov. : 8Waves interactif

- `NowUndo_8Waves.lua` (table `UI`, géométrie des lignes dans `VIS.R[i]`) : **clic rapide** (< 0,4 s, sans glisser) sur la
  forme d'onde = sélection + **tap du pad de statut** (2e rangée du LP : `VL.status_pad_tap`, groupe compris) ; clic sur
  l'étiquette ou les VU = sélection seule ; **Ctrl + clic** = geste de groupe (1er clic : looper libre → nouveau groupe,
  groupé → son groupe ; clics suivants Ctrl tenu : entre / sort) ; **flèches haut / bas** = looper actif précédent / suivant ;
  **glisser** : poignées In (commande d'édition 1) / Out (2), milieu de la fenêtre = déplacer In/Out (5) ; Cloud : milieu de la
  zone des grains = position (param 38, passe en Free param 37 par la boîte +195), bords = Spread (param 28 = demi-largeur /
  demi-fenêtre). Curseur souris selon la cible. Écran tactile : REAPER ne donne qu'un seul pointeur (pas de multi-doigts).
- Launchpad, file `NowUndo_VLcmd/q` : `sel_<i>`, `stap_<i>`, `ctrlgrp_<i>_<1|0>` (`VL._w8g` = groupe du geste en cours).
- Tests : `tools/t8waves_ui.lua` (gestes → commandes / écritures gmem), `tools/tlp_8waves.lua` (Launchpad en `VL_TEST`).

## 21 nov. : ping-pong qui restait en reverse (JSFX V3.27, corrigé en place)

- Symptôme : PP activé (rush ou Launchpad) = parfois juste du reverse, un coup sur deux selon le moment de l'appui.
  Cause : au rebond du début, le recalage sur l'horloge (`is_normal_playback && wrapped`, écart ~1 sample avant que le
  maître boucle) sautait à l'équivalent « modulo » = l'autre bout de la fenêtre → nouveau rebond → reverse pour toujours.
  Corrigé : en ping-pong le recalage reste du côté de la tête (`pos - sync_dev` borné) ; PP on/off remet `ping_pong_dir = 1`.
  Test `tools/tpp.py` (4 activations : toutes rebondissent) ; thost / tseam inchangés.

## 21 nov. (suite) : liste des rushes en pages, bouton POSER, palette après une cible

- Liste de l'onglet Rushes = **pages de 64** (2 colonnes × 32, `H._lp`, boutons `< LISTE n/N >` en haut à droite) ; un rush
  sélectionné / créé ouvre sa page (`mwant`). Avant : seuls les 64 premiers étaient visibles.
- Bouton « → LAUNCHPAD » **supprimé** (jugé superflu ; CAPTURE pleine largeur) ; rangée des pages = « LAUNCHPAD PAGE 4x ».
- **Clic droit sur un pad de la page 4 du Launchpad virtuel** : case vide = le Scenario (rouvert s'il était fermé) ouvre
  l'éditeur de nouveau rush, le rush validé est posé sur cette case (`ED.cell`) ; case occupée = édition du rush.
  Protocole : `NowUndo_Scn/lp_new` = `case\tid (0 = vide)\ttemps` → `H._lpreq` traité dans `main`.
- **Glisser un rush vers le Launchpad** : le Launchpad refusait toute case > 64 (reste d'avant les sous-pages) → impossible de
  déposer ailleurs qu'en 4a. Corrigé (limite 26 × 64 ; hors d'un pad = 1re case libre de la sous-page affichée). Le Scenario
  vérifie 1,5 s après (`H._dropchk`) et dit « posé en c1.3 » ou « le Launchpad n'a pas pris le rush ».
- **Rush toggle `a` / `d` = interrupteur A / D** : `mac_check` réécrit un toggle `a` (ou `l1 a`, `all a`, 1re action) en `d` ;
  pad allumé = **D**, miroir de l'état réel (`H._mirror`). Test `tools/trush_ad.lua`.
- Palette de l'éditeur : rangée **« Cible »** (l1..l8, g1..g4, all). Cible cliquée après une cible seule = combinée
  (`l1` + `l3` → `l1/l3`, `all` remplace) ; puis le mot d'action est collé par une espace (`l1/l3 rec`).
- `ED.add` : après une cible seule (`all`, `l3`, `g2`, `in1`) ou `… to`, le mot de la palette est collé par une espace (`all a`), plus par une virgule.

## 21 nov. : page 4 = pages de rushes, `to g`, `go`

- **Page 4 du Launchpad = sous-pages de rushes a..z** (couches `rp1`..`rp26`, `VL.p4_moff()`, menu = pages existantes
  avec leur nom, PAGE 4 = page suivante). **Couches Effects / Groups / RC-505 / Rushes / Rushes 2 retirées.**
  Pages créées / nommées / supprimées / choisies dans le Scenario (onglet Rushes : `<` `PAGE 4x (n/64) v` `>` `+ PAGE`
  `NOM PAGE` `SUPPR PAGE` ; « → LAUNCHPAD » pose dans la page affichée ; « VIDER LA PAGE »). `H._pages`, `H._pg`,
  `H._pg_*`, lignes `P` ; 26 × 64 rushes max. Supprimer une page : ses pads sont retirés, les suivantes remontent.
- **Migration (une fois, set sans ligne `P`)** : page a = **RC-505** en 64 rushes (`H._rc505` : `l<n> rec` / replace / rev /
  pp / slicer / cloud en toggle, `l<n> clear` / `restart` simples ; bas → haut comme avant), anciens Rushes → b,
  Rushes 2 → c (cases +64). Import d'un ancien fichier : pages déduites des cases, sans RC-505.
- Mots : **`l3 to g2`** (groupe, exclusif ; `to g0` = sans groupe ; sans cible = sélection ; toggle / gate OFF = sort
  du groupe ; pad toggle allumé = membre) → `grp_` / `grpoff_` ; **`go lp 2`**, **`go 4c`** / `go lp 4c` (sous-page),
  **`go t3`** (Twister) → `lppage_` / `p4page_` / `twpage_` (`H._go`). Palette « Groupes / pages ».
- REC / Re-Rec d'un rush : heure de l'appui du pad écrite en gmem 950/951 (comme le Launchpad) → REC calé sur l'appui
  aussi via les rushes (`run_macro(..., press_t)`, pas pour `*`).
- **Effets en rushes** : `l1 fx 2` = `l1 e2` (`fx(2)` aussi, `H._norm`) ; **entrées** `in1` / `i1` / `in2-4` / `in(1/3)`
  (codées 100 + n dans les cibles, seulement `fx` / `e` dessus) → `fxin_<n>_<slot>_<on|off>`. Page **« Effets »** créée
  une fois en dernière page (`H._fxpage`, ExtState persistant `NowUndo_Macros/fx_page` = 1) : rangées 1-4 = FX 1-4 de
  IN1-8, rangées 5-8 = FX 1-4 de L1-8, en toggle. Rushes toggle **miroir** (`H._mirror` : 1re action = effet ou `to g`) :
  pad allumé = état réel (masques 6030 / 6040, groupe 6000), un appui inverse l'état réel (pas la pile).
- **`in1 mute` / `in1 mute off`** = **sortie du parent** de l'entrée (`B_MAINSEND`, comme l'appui long de la page 2 ;
  demandé par l'utilisateur : PAS un mute de piste) → `VL.set_input_mute` → `VL.set_input_parent`, commande
  `inmute_<n>_<on|off|tog>`, état publié en `6050+n` (= `VL.input_parent_cut`). Les loopers reçoivent toujours l'entrée.
  Rush toggle = miroir.
- Limites connues : LED des pads RC-505 = allumé / éteint (plus de rouge / orange / clignotant du REC) ; Restart n'est plus
  en gate ; effets des entrées : revenus en rushes (`in1 fx 2`, page Effets).
- Tests : mocks lupa (`tools/trush_tgt.lua` + scénario pages / commandes) ; non testé dans REAPER.

## 21 nov. : cibles dans les rushes (préparation du chantier « tout est rush »)

- Rush = même syntaxe qu'un pas de scénario, **cible facultative** : rien = looper / groupe sélectionné (`rec`) ; `l1`,
  `l1/3`, `l2-4`, `l(1/3)`, **`g2`, `g1/3`, `g(2)`** (groupe du Launchpad, gmem `6000+i`, lu à l'exécution), mélange
  `l2/g1`, `all`. Après une virgule sans cible = cible précédente (`rec, l6 play, stop` : stop sur L6). `g(2)` **seul**
  dans une action reste le rappel du preset de groupe. Scénarios : mêmes cibles, pas recompilé au GO (groupes à jour).
- Mots `a` / `d` (dub A / D, param 67) ; `a` reste un mot de liaison ailleurs qu'en position de mot (`l1 in 0.25 out a 0.5`).
- Pile « dernier actif gagne » : comparaison par items (looper + mot), plus par la sélection. Pad toggle allumé : vérifie le
  1er mot sur la cible écrite. Message = loopers réellement visés. `parse_target` / `is_tgt` dans le Scenario (193 locales).
- Test : `tools/trush_tgt.lua` (lupa, faux REAPER, 8 loopers, groupes). Non testé dans REAPER.

## 21 nov. : 8Waves VU / Mute / saturation + bouton Mute du JSFX

- `NowUndo_8Waves.lua` : VU d'entrée / sortie verticaux, état MUTE, saturation selon Out Vol (voir tableau). `NowUndo_V3.26.jsfx` :
  bouton **Mute** dans le panneau Transport (6 boutons, `lp_mute`). Non testé dans REAPER.

## 20 nov. : 8 Panel — Cloud en bleu + zone des grains

- JSFX publie la zone jouée par les grains en % de la longueur : `+178` début, `+179` fin (-1 si Cloud off) =
  `cloud_center_draw` ± dispersion (`cl_zspray`, dernière valeur de `spray`) + longueur d'un grain (`cl_zspan`, du côté
  de la lecture). Le 8 Panel : forme d'onde **bleue** en lecture Cloud, bande bleue translucide + bords sur la zone,
  repliée dans la fenêtre In/Out. Non testé dans REAPER.

## 19 nov. : démarrage du Twister, Scenario fermé, verrou des pages, source du FX Router

- **Twister inactif au démarrage tant qu'on n'avait pas ouvert le MIDI Learn** : cause probable = les affectations
  (`maps`, `maps_dev`, `custom`…) tiennent sur plusieurs lignes et l'ExtState persistant de REAPER ne les relit pas en
  entier ; le MIDI Learn recharge `nowundo_midi_learn_model.txt` à son lancement. Maintenant le Twister recharge
  lui-même ce modèle au démarrage si le MIDI Learn ne tourne pas (`CU.model_boot`, sauf `tpl_open` = 0 ; le port de
  sortie déjà choisi n'est pas écrasé). **Hypothèse non confirmée dans REAPER.**
- **Scenario** : fermer la fenêtre (croix / Échap) ne coupe plus le script : rushes, scénarios, file d'actions et
  capture continuent (`H._bg`) ; relancer le script rouvre la fenêtre (instance unique via `NowUndo_Scn/alive`,
  `NowUndo_Scn/ui_req`). Fermer la fenêtre arrête une capture en cours.
- **Verrou des pages du Twister** : ExtState `nowundo_vl/tw_lock` = "1" (persistant). Coupe la navigation auto
  (`VL.auto_twister`, `VL.fx_nav` → pages 6/1, `auto_twister` du MIDI Learn) ; les rappels manuels marchent toujours.
  Bascule : action MIDI Learn « Twister : verrou des pages » (`fighter:lock`), bouton en haut à droite de la fenêtre
  du Twister. Source / slot FX continuent de suivre les pads d'effets.
- **FX Router → Launchpad** : choisir une source à la main dans le FX Router envoie `fxsrc_<n>` dans
  `NowUndo_VLcmd/q` ; le Launchpad règle `S.fx_source` → les pads D5-D8 affichent et pilotent les slots de cette
  source, **entrées comprises** (plus besoin de la page 2).

## Idées en suspens (proposées, pas faites)

- **ROADMAP (ajouté le 26 nov., demandé par l'utilisateur)** :
  - **Supprimer l'ancien `NowUndo/Scripts/DashBoard.lua`** (panneau gfx des 8 instances, v1.3) : « n'a plus aucune raison d'être ».
    Il est encore cité dans l'ancien `index.xml` (paquet ReaPack du 1er nov., régénéré à la publication) et ignoré par
    `.reapack-index.conf` (ligne `--ignore` à retirer avec le fichier). Vérifier qu'aucun `__startup.lua` ne le lance.
  - **Miroir de 8Waves en page web** : onglet de `NowUndo.html` qui reprend l'affichage de `NowUndo_8Waves.lua` (8 formes d'onde
    empilées, couleurs d'état, In / Out, tête, Cloud / Slicer, VU, Mute, saturation selon Out Vol) et, si possible, ses gestes au doigt
    (sélection, tap de statut, In / Out). Base existante : l'onglet Loopers du web (forme d'onde d'un looper, In / Out au doigt) et le
    pont `NowUndo_Twister_Web.lua` (`lv_wave`). À penser avec l'onglet Dashboard (même page, tablette + écran tactile).

- **GRAND CHANTIER « tout est rush » (validé sur le principe, à faire plus tard, par étapes)** :
  1. Moteur commun `NowUndo_Rush.lua` (langage des rushes sorti du Scenario), exécuté **directement par le Launchpad**
     (pas de détour par le Scenario : garder l'heure d'appui du REC calé) ; les mots qui ont une action Launchpad passent
     par elle (règles de groupe, Launch/GO, Exclu) ; cibles : rien = sélection (looper ou groupe), `l1`, `l1/l3`, **`g2`,
     `g1/g3` (sans parenthèses : `G(n)` reste le rappel de preset)** ; dans un scénario, pas sans cible = cible
     précédente du pas, sinon sélection.
  2. Rushes **d'usine** (lecture seule, illimités, ~40 fonctions : page 1 + Launch/GO, Exclu, Sync, Drop, pas du
     scénario, FX 1-4, pages Twister, presets) qui n'occupent pas les 64 rushes perso ; un pad = rush + cible
     (« REC du looper 3 » = `rec` + `l3`, pas d'entrée en plus).
  3. Page 1 et RC-505 = **dispositions de rushes** (défaut = disposition actuelle) ; pad = court / long / double
     (+ relâchement gate), les comportements suivent la fonction ; Ctrl+clic sur un pad = réaffecter ; bouton
     « Disposition d'usine » ; LED = état du 1er mot sur la cible du pad (REC : rouge / orange / clignote).
     Zones fixes : rangée du haut (loopers) et colonne de droite (groupes / pages / HOLD) ; couches Effects / Groups
     de la page 4 inchangées.
  4. Le web reprend les dispositions.

- **CHANTIER « Quantize global » (demandé, à faire plus tard)** : une action (rush + MIDI Learn) qui, activée,
  **quantise toutes les actions du looper** et pas seulement In/Out : REC (début / fin), Restart, activation /
  désactivation du Slicer, Cloud, Beat Repeat, Reverse, effets (slots FX), Stop/Play, etc., ainsi que les unités de
  **Rec Density**. Grille au choix : **cycle, temps, croche, double croche**. La grille est calculée sur **la durée
  de la boucle de chaque looper** (pas sur l'horloge globale). Comme les autres rushes, elle s'active pour **tous**,
  un **looper ciblé** ou **la sélection** (looper / groupe). Pistes : un état `qz` par looper dans le JSFX + une file
  d'actions en attente déclenchées au prochain point de grille (comme `*` / exclu), effets FX déclenchés par le
  Launchpad au même moment ; LED qui clignote en attente.
  **Contrainte (demandée)** : activer le quantize global ne doit **jamais modifier une boucle déjà calée** : In / Out
  existants et l'écart (largeur) restent tels quels (contrairement au bouton Quant actuel qui recale In / Out au
  changement) ; seules les actions **à venir** sont quantisées.
- **WARP étape 2 (à faire si le son plaît)** : mot de rush `snap 1/16 80%` (cible sélection / `l3` / `all`), grille par
  looper partagée avec le futur « Quantize global » ; bouton web / Launchpad ; swing éventuel.
- MIDI direct au JSFX via un JSFX « Clock » sur une piste Contrôle (horodatage à l'échantillon des appuis).
- Conflit possible entre les touches à une lettre du Scenario et les raccourcis du MIDI Learn quand sa fenêtre a le focus
  (options proposées : laisser, pause quand focus, pause seulement pour les touches du Scenario).
- Titre par pas de scénario ; poser un même rush sur plusieurs pads ; bouton pour désactiver le calage du Play (B2).
- Page Display / VU du Twister : coût MIDI déjà discuté, rien à faire.

## Outils de test (`tools/`)

- **`python3 tools/eelcomment.py f.jsfx`** (un `//` au milieu d'une ligne de code cache la suite : déjà arrivé) · **`python3 tools/eelorder.py f.jsfx`** (EEL2 : fonction appelée avant sa définition = « undefined » dans REAPER, invisible au banc Python ; à lancer après chaque modif du JSFX) · `python3 tools/lualoc.py f.lua` (locales au niveau principal) · `python3 tools/luabal.py f.lua` (équilibre des blocs ;
  l'écart de parenthèses peut être un faux positif dû à `"%("` dans un motif).
- `eel2py.py` + `bench.py` : traduisent le JSFX en Python pour mesurer clics / calage. Copier le JSFX en `v322.jsfx` /
  `v323.jsfx` / `v325.jsfx` (+ `cap.jsfx` pour `tdrop.py`) dans `tools/`, puis `cd tools && python3 tlat.py .` (REC calé), `tlat2.py .` (latence overdub),
  `tld.py .` (longueur d'import). Lent (plusieurs minutes).
- Tests de la page web (Playwright, Chromium préinstallé dans le cloud) : `node tools/holdtest.js`, `navtest.js`,
  `lvshot.js`, `lptest.js`, `acktest.js`, `legacy.js`, `realtest.js` (simule le `main.js` de REAPER avec `reaper_main.js`).
- Lua : `pip install lupa` donne un vrai Lua 5.4 (`import lupa.lua54`) : vérifier la syntaxe avec `load()`, et le Launchpad se
  charge sans GUI avec `VL_TEST = true` + un faux `reaper` (le script renvoie `VL`).
