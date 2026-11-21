# NowUndo — mémoire de projet pour Claude

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
  | `NowUndo_8Looper_Panel.lua` | Panneau 8 loopers + import de fichiers audio (glisser-déposer, modes Adapter / Indépendant / Étirer). |
  | `NowUndo_8Waves.lua` | Variante du 8 Panel : les 8 formes d'onde empilées, pleine largeur, affichage seul (couleurs d'état, Cloud + zone des grains, Slicer + slices, sync point, In/Out, tête, cadre + fond teinté de la sélection / du groupe autour de la zone In/Out seulement, parties hors In/Out grisées ; étiquette : L n (partie seulement si ≠ MAIN) + sources entre parenthèses + état + REVERSE / SLICE / CLOUD + SP (speed ≠ 1) / PS (pitch ≠ 0) + « FX n » en rose ; M / S / F tout à droite ; VU vertical d'entrée à gauche (`+172`) et de sortie à droite (`+173`) ; état MUTE (`+199`) ; saturation de **tout le cadre** = Out Vol (`+22`) : 0 dB couleur pleine → -40 dB noir et blanc, courbe ^1.5, gris un peu assombri, textes / tête gardent une luminosité ≥ 0,8 ; Mute = noir et blanc ; VU d'entrée et cadre de groupe restent en couleur). Pas de paramètres, sources, boutons ni glisser-déposer. Fenêtre `NowUndo_8Waves`. |
  | `NowUndo_Scenario.lua` | Séquenceur de scénarios + **Rushes** (ex « macros ») : éditeur, assistant, palette ; V3.27 : cibles dans les rushes, sous-pages de la page 4 (+ PAGE / NOM / SUPPR), MIDI par rush, modèle de démarrage. |
  | `NowUndo_Twister_Web.lua` | Pont gmem ↔ ExtState pour l'onglet Twister In/Out et l'onglet **Loopers** du web. |
  | `NowUndo_Latency.lua` | Réglage global de la compensation de latence (V3.23). |
  | `NowUndo_VirtualPedalBoard.lua` | Pédalier virtuel (G-Board / FCB1010 / M-Vave). Deux réglages **séparés** : **LEARN PÉDALE** (clic sur un switch → appui sur la vraie pédale = son MIDI) et **ACTION** (clic sur un switch ou appui sur sa pédale → clic sur un pad du Launchpad / knob du Twister via `NowUndo_Pedal/capture`, ou clic droit > liste) ; Échap = annuler. Témoin MIDI en bas (dernier message reçu + ce qu'il déclenche), le switch s'allume à chaque appui. Modes Gate / Toggle / Absolu, cible = sélection ou looper n. Actions Launchpad (Exclu, Sync, Drop, sélection) via `NowUndo_Pedal/lp_cmd`. V3.25 : + Mute, + Drop. |
  | `NowUndo.html` | Télécommande web v4.0 (onglets Launchpad / Twister / Loopers), à copier dans `reaper_www_root`. |
  | `virtual_launchpad_web.lua` | **Obsolète, ne pas lancer** (doublon qui volait les commandes web). |
- `NowUndo/Scripts/V3.21/FX_Router_v2.lua` (ReaImGui, v2.9) : choix de l'effet de chaque container (lib JSFX `Effects/MonRig`, 4 containers par piste, source suivie depuis `nowundo_vl/fx_source`). **Il ne bypasse jamais les containers** : l'activation des slots est faite par le Launchpad (`VL.apply_fx`).
- `tools/` : outils de test (voir plus bas).

## Protocoles (à respecter)

**gmem `nowundo_sync`** : bloc par looper/part = `1000 + i*600 + part*200` (i = 0..7, part = 0..2).
`+2` état (0 stop, 1 rec, 2 play, 3 dub, 4 replace, 5 auto-rep, 6 multiply, 7 attente, 8 sync) · `+42` part active ·
`+44/+45/+46` loop start / width / length · `+47` pos % · `+48` **commande** · `+49` argument ·
`+50..149` forme d'onde · `+155` BPM estimé · `+160..162` édition In/Out/Width · `+172/+173` VU in/out ·
`+156/+157/+158` warp (état / grille / force) · `+159` mode d'overdub (V3.27 : 0 = A compensé, 1 = D brut, lecture seule) · `+178/+179` zone des grains du Cloud en % (V3.26) · `+180` id de paramètre à écrire, `+181` valeur (V3.25 : 2 boîtes de plus `+195/+196` et `+197/+198`) · `+19` feedback · `+20` dégradation · `+21` stéréo · `+22` out vol ·
`+182..184` sync point / ref / len du maître. Global : `0..24` Master Sync par part (`[o]==1` maître looper, `==2` Host,
`[o+2]` longueur, `[o+3]` position), `100+i` vivant, `130+i` heartbeat, `950/951` heure de l'appui + adresse cible (V3.22),
`955/956/957` latence auto (samples) / décalage ms / 2 = coupée (V3.23), `LD_BASE=1000000` import de fichiers
(sert aussi d'enregistrement au drop), **drop de groupe (V3.25)** : `300 + k*10` accusé du looper k (+0 jeton, +1 horloge
du passage, +5 durée entendue), `380` signal final (jeton+0.5 bascule / +0.75 abandon), `381` cible, `393` départ capture,
`394` fin capture, `395` gain (1/volume piste cible), `396` latence PDC. **Tableau de bord (Launchpad)** : `6000+i` groupe, `6010+i` / `6020+i` masques des sources, `6030+i` masque des slots FX actifs du looper i (V3.26), `6040+n` masque des slots FX actifs de l'entrée n (V3.27). `6050+n` = 1 si l'entrée n est sortie du parent (« in mute », V3.27). **Nouveau REC (V3.25)** : `398` heure, `399` id.

**Commandes JSFX (+48)** : 1 rec/dub, 2 clear, 3 stop/play, 4 reverse, 5 ping-pong, 6 slicer, 7 cloud, 8 link,
9 replace, 10 auto-replace, 11 clear full, 12 part, 13 multiply, 14 undo, 15 redo, 16 restart, 17 re-rec, 18 one-shot,
19 auto, 20 speed step, 21 pitch step, 22 full loop, 23 quantise, 24 reset, 30 exclu, 31/32 import (copie / requête longueur), 33 beat repeat,
34/35/36 drop (horloge du passage sur la cible / source en attente d'effacement / copie de l'enregistrement ; arg = jeton),
37 mute (arg 0 bascule / 1 on / 2 off ; état publié en `+199`), 38 warp, **39 dub A / D** (V3.27 : arg 0 bascule / 1 = D / 2 = A).
**Paramètres (+180)** : 3 speed, 4 pitch, 5 mix, 7 fade, 19 fdbk, 20 dégradation, 21 stéréo, 22 out vol, 26-28/35/36/38-41 cloud,
29/30 rec density, 59 loop quant, 60 BR mix, 61 slicer mix, 62-64 cloud v2, 65/66 warp grille / force, **67 dub A (0) / D (1)** (V3.27).

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

- Répondre en français, simplement, sans jargon inutile ; il teste et revient avec des captures.
- **Proposer des alternatives quand son idée n'est pas optimale** (demandé explicitement), avec une recommandation.
- Il veut garder la cohérence entre Launchpad, web, MIDI Learn, Twister (même logique partout : groupes, double appui…).
- Il n'aime pas les ergonomies « à l'envers » (ex. choisir OFF avant l'action) ni l'absence de Retour arrière.

## RÉSUMÉ DE LA SESSION DU 21 NOV. (point de départ de la prochaine discussion)

Tout est poussé, **rien n'a été testé dans REAPER** (seulement bancs Python / mocks Lua) : demander à l'utilisateur ses retours.
1. **8Waves** : VU d'entrée / sortie verticaux, état MUTE, saturation des couleurs selon Out Vol (Mute = noir et blanc).
2. **JSFX V3.27** = version de référence : dub brut **A / D** écrit par l'utilisateur (relu, test `tools/traw.py`) + bouton
   **Mute** (Transport) + pilotage A / D (commande 39, paramètre 67, MIDI Learn, mots `a` / `d`).
3. **Rushes = langage des scénarios** : cible facultative (`rec` = sélection ; `l1`, `l(1/3)`, `g2`, `g(1/3)`, `all`,
   entrées `in1`…), `l3 to g2` (groupes), `go lp 2` / `go 4c` / `go t3` (pages), `l1 fx 2` / `in1 fx 2` (effets),
   `in1 mute` (= **sortie du parent**, comme la page 2 — PAS un mute de piste), REC des rushes calé sur l'appui.
4. **Page 4 du Launchpad = uniquement des pages de rushes a..z** (les couches Effects / Groups / RC-505 / Rushes 2 sont
   retirées). Migration au 1er lancement : a = RC-505 en rushes, b / c = anciens Rushes / Rushes 2, puis une page
   « Effets » ajoutée une fois (rangées 1-4 entrées, 5-8 loopers). Pads d'effets / de groupe / de mute d'entrée = miroir
   de l'état réel.
5. **MIDI Learn par rush** (appris dans la fenêtre Rushes, exécuté par le script MIDI Learn) + **modèle de démarrage** des
   rushes (bouton MODELE, jamais réécrit automatiquement).
À vérifier en priorité avec l'utilisateur : la migration de la page 4 (a RC-505, b, c, d Effets), le menu des pages,
`l3 to g2`, `in1 mute`, le learn MIDI d'un rush (QuNeo / pédale, gate), le modèle au redémarrage, le carré A / D.
Aucun problème ouvert connu : les anciens (Launchpad / MIDI Learn, QuNeo, Drop, BR) sont résolus.
Suite logique proposée : le grand chantier « tout est rush » (étapes 1-4 plus bas : moteur commun exécuté par le
Launchpad, rushes d'usine, page 1 en disposition de rushes, LED riches comme l'ancien REC rouge / orange / clignotant).

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
  Page 4 Slicer réorganisée : C = Detect | Detect Hold | Pitch | Link ; D = Root | Release | - | **Dry/Wet**.
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

## 21 nov. (suite) : liste des rushes en pages, bouton POSER, palette après une cible

- Liste de l'onglet Rushes = **pages de 64** (2 colonnes × 32, `H._lp`, boutons `< LISTE n/N >` en haut à droite) ; un rush
  sélectionné / créé ouvre sa page (`mwant`). Avant : seuls les 64 premiers étaient visibles.
- « → LAUNCHPAD » renommé **« POSER LA SELECTION SUR 4x »** (1/3 de largeur, couleur neutre) ; rangée des pages = « LAUNCHPAD PAGE 4x ».
- **Glisser un rush vers le Launchpad** : le Launchpad refusait toute case > 64 (reste d'avant les sous-pages) → impossible de
  déposer ailleurs qu'en 4a. Corrigé (limite 26 × 64 ; hors d'un pad = 1re case libre de la sous-page affichée). Le Scenario
  vérifie 1,5 s après (`H._dropchk`) et dit « posé en c1.3 » ou « le Launchpad n'a pas pris le rush ».
- **Rush toggle `a` / `d` = interrupteur A / D** : `mac_check` réécrit un toggle `a` (ou `l1 a`, `all a`, 1re action) en `d` ;
  pad allumé = **D**, miroir de l'état réel (`H._mirror`). Test `tools/trush_ad.lua`.
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

- `python3 tools/lualoc.py f.lua` (locales au niveau principal) · `python3 tools/luabal.py f.lua` (équilibre des blocs ;
  l'écart de parenthèses peut être un faux positif dû à `"%("` dans un motif).
- `eel2py.py` + `bench.py` : traduisent le JSFX en Python pour mesurer clics / calage. Copier le JSFX en `v322.jsfx` /
  `v323.jsfx` / `v325.jsfx` (+ `cap.jsfx` pour `tdrop.py`) dans `tools/`, puis `cd tools && python3 tlat.py .` (REC calé), `tlat2.py .` (latence overdub),
  `tld.py .` (longueur d'import). Lent (plusieurs minutes).
- Tests de la page web (Playwright, Chromium préinstallé dans le cloud) : `node tools/holdtest.js`, `navtest.js`,
  `lvshot.js`, `lptest.js`, `acktest.js`, `legacy.js`, `realtest.js` (simule le `main.js` de REAPER avec `reaper_main.js`).
- Lua : `pip install lupa` donne un vrai Lua 5.4 (`import lupa.lua54`) : vérifier la syntaxe avec `load()`, et le Launchpad se
  charge sans GUI avec `VL_TEST = true` + un faux `reaper` (le script renvoie `VL`).
