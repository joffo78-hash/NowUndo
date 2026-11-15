# NowUndo — mémoire de projet pour Claude

Looper 8 instances synchronisées pour **REAPER** : un JSFX (le moteur audio) + des scripts Lua (Launchpad,
Twister, MIDI Learn, 8 Looper Panel, Scenario, ponts web) + une télécommande web (`NowUndo.html`).
L'utilisateur est francophone (tutoiement), musicien, teste tout lui-même dans REAPER (Windows, buffer 128).

## Où est quoi

- Dépôt : `joffo78-hash/NowUndo`, branche de travail `ccr-12a0f3a9-86p9ey` (tout le travail récent y est).
- `NowUndo/NowUndo_V3.25.jsfx` : **version courante du JSFX** (3.19 → 3.24 gardées pour l'historique).
- `NowUndo/NU_DropCapture.jsfx` : capture du drop (posé automatiquement par le Launchpad sur la piste cachée « NU Drop »).
- `NowUndo/Scripts/V3.21/` : tous les scripts courants (le nom du dossier est historique) :
  | Fichier | Rôle |
  |---|---|
  | `virtuallaunchpad_main.lua` | Launchpad (Mini MK3 + fenêtre virtuelle + serveur de la page web). Cœur de la logique : pages, groupes, routing, FX, macros/rushes, Ctrl/HOLD. |
  | `Virtual_Launchpad_secondary.lua` | Miroir (3 pages non affichées), charge `virtuallaunchpad_main.lua` en `mirror_mode`. |
  | `twisterinoutreset.lua` | Midi Fighter Twister v3.5 (8 pages, page 7 Custom, page 8 Display, sélection d'effet FX Router). |
  | `nowundo_midi_learn.lua` | MIDI Learn v2.8 + raccourcis clavier (js_ReaScriptAPI), cumul clavier/MIDI, double appui. |
  | `NowUndo_8Looper_Panel.lua` | Panneau 8 loopers + import de fichiers audio (glisser-déposer, modes Adapter / Indépendant / Étirer). |
  | `NowUndo_Scenario.lua` | Séquenceur de scénarios + **Rushes** (ex « macros ») : éditeur, assistant, palette. |
  | `NowUndo_Twister_Web.lua` | Pont gmem ↔ ExtState pour l'onglet Twister In/Out et l'onglet **Loopers** du web. |
  | `NowUndo_Latency.lua` | Réglage global de la compensation de latence (V3.23). |
  | `NowUndo.html` | Télécommande web v4.0 (onglets Launchpad / Twister / Loopers), à copier dans `reaper_www_root`. |
  | `virtual_launchpad_web.lua` | **Obsolète, ne pas lancer** (doublon qui volait les commandes web). |
- `FX_Router_v2.lua` (ReaImGui) n'est pas dans le dépôt : l'utilisateur l'a fourni en pièce jointe (lib JSFX `Effects/MonRig`, 4 containers par piste, source suivie depuis `nowundo_vl/fx_source`).
- `tools/` : outils de test (voir plus bas).

## Protocoles (à respecter)

**gmem `nowundo_sync`** : bloc par looper/part = `1000 + i*600 + part*200` (i = 0..7, part = 0..2).
`+2` état (0 stop, 1 rec, 2 play, 3 dub, 4 replace, 5 auto-rep, 6 multiply, 7 attente, 8 sync) · `+42` part active ·
`+44/+45/+46` loop start / width / length · `+47` pos % · `+48` **commande** · `+49` argument ·
`+50..149` forme d'onde · `+155` BPM estimé · `+160..162` édition In/Out/Width · `+172/+173` VU in/out ·
`+180` id de paramètre à écrire, `+181` valeur · `+19` feedback · `+20` dégradation · `+21` stéréo · `+22` out vol ·
`+182..184` sync point / ref / len du maître. Global : `0..24` Master Sync par part (`[o]==1` maître looper, `==2` Host,
`[o+2]` longueur, `[o+3]` position), `100+i` vivant, `130+i` heartbeat, `950/951` heure de l'appui + adresse cible (V3.22),
`955/956/957` latence auto (samples) / décalage ms / 2 = coupée (V3.23), `LD_BASE=1000000` import de fichiers
(sert aussi d'enregistrement au drop), **drop de groupe (V3.25)** : `300 + k*10` accusé du looper k (+0 jeton, +1 horloge
du passage, +5 durée entendue), `380` signal final (jeton+0.5 bascule / +0.75 abandon), `381` cible, `393` départ capture,
`394` fin capture, `395` gain (1/volume piste cible), `396` latence PDC. **Nouveau REC (V3.25)** : `398` heure, `399` id.

**Commandes JSFX (+48)** : 1 rec/dub, 2 clear, 3 stop/play, 4 reverse, 5 ping-pong, 6 slicer, 7 cloud, 8 link,
9 replace, 10 auto-replace, 11 clear full, 12 part, 13 multiply, 14 undo, 15 redo, 16 restart, 17 re-rec, 18 one-shot,
19 auto, 20 speed step, 21 pitch step, 22 full loop, 23 quantise, 24 reset, 30 exclu, 31/32 import (copie / requête longueur), 33 beat repeat,
34/35/36 drop (horloge du passage sur la cible / source en attente d'effacement / copie de l'enregistrement ; arg = jeton).
**Paramètres (+180)** : 3 speed, 4 pitch, 5 mix, 7 fade, 19 fdbk, 20 dégradation, 21 stéréo, 22 out vol, 26-28/35/36/38-41 cloud,
29/30 rec density, 59 loop quant, 60 BR mix, 61 slicer mix, 62-64 cloud v2.

**ExtState** : `nowundo_vl` (état partagé du Launchpad : `state` + `rev`, `web_cmd`/`web_ack`, `web_frame/labels/meta`,
`fx_source`, `fx_slot`, `sel_looper`, `fighter_page`, `active_page`) · `NowUndo_VLcmd/q` (file de commandes externes vers le
Launchpad : lignes `nom\ttemps`, ex. `fxg_<looper>_<slot>_tog`, `fx_…`, `fxin_…`, `preset_…`, `sync_on`, `rec_dub_toggle`, `drop_group`) ·
`nowundo_tw` (Twister + web : `tw_*`, `lv_fast`, `lv_wave`, `web_cmd`) · `NowUndo_MIDILearn` (maps, `custom`, `maps_kbd`,
`kbd_intercept`) · `NowUndo_Scn` (`mcr` déclenchements de rushes `id\tcibles\ttemps\ton|off`, `alive`, `typing`) ·
`NowUndo_Macros` (rushes partagés : `set`, `rev`, `on`, `pend`) · `NowUndo_Latency` (`on`, `offset_ms`) · `NowUndo_Clock/align`.

**Web Launchpad** : commandes numérotées `@sid;#n:cmd;…` + accusé `web_ack` (repli automatique sur l'ancien format si
pas d'accusé). Commandes : `P/R/D,row,col`, `H,0|1`, `L,layer`, `PAGE,n`, `SEL,i`, `ACT,i,action`. La page web a **sa
propre page Launchpad** (`VL.web_with_page`).

## Règles de code (pièges déjà rencontrés)

- **Lua : 200 variables locales max au niveau principal.** `virtuallaunchpad_main.lua` ≈ 143 (fonctions rangées dans
  `VL.*`, `LPF.*`), `NowUndo_Scenario.lua` ≈ 192 (**presque plein** : ranger le neuf dans la table `ED` ou `H._xxx`),
  `twisterinoutreset.lua` ≈ 172. Vérifier avec `python3 tools/lualoc.py <fichier>` après chaque modif.
- Lua : une `local function` n'est visible qu'après sa déclaration ; pour un appel « en avant », passer par un champ de table.
- **EEL2 (JSFX) : `min()` / `max()` prennent exactement 2 arguments** (erreur de compilation sinon ; le traducteur Python
  ne le détecte pas). Mettre des parenthèses autour des branches d'un `? :` qui contiennent des affectations.
- `CU_KNOBS` / `CU_BTNS` / `CU_FAM_NAME` doivent rester **identiques** dans `nowundo_midi_learn.lua` et `twisterinoutreset.lua`.
- Dans le Scenario, la table `H` contient les mots de la syntaxe : `split_key` n'accepte que les entrées de type fonction.
- Ne jamais renommer les identifiants internes (ExtState, dossiers, formats) : seulement les textes affichés.
- Un seul script Launchpad doit tourner (deux = page web qui « vacille »).
- Livraison : commit + push sur la branche, puis envoyer les fichiers modifiés à l'utilisateur (il les copie à la main
  dans REAPER ; `NowUndo.html` va dans `reaper_www_root`). Dire clairement ce qui n'a pas pu être testé dans REAPER.

## Préférences de l'utilisateur

- Répondre en français, simplement, sans jargon inutile ; il teste et revient avec des captures.
- **Proposer des alternatives quand son idée n'est pas optimale** (demandé explicitement), avec une recommandation.
- Il veut garder la cohérence entre Launchpad, web, MIDI Learn, Twister (même logique partout : groupes, double appui…).
- Il n'aime pas les ergonomies « à l'envers » (ex. choisir OFF avant l'action) ni l'absence de Retour arrière.

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
  gate ON/OFF ; pads de rush qui clignotent en attente de synchro.
- **Web v4.0** : onglet Loopers (forme d'onde, In/Out au doigt, rangées B/A du Launchpad, modes, sliders Feedback /
  Dégradation / Output / Stereo, VU), navigation commune 8 pages Twister + 8 loopers sur tous les onglets, appeler un
  looper le sélectionne sur le Launchpad, envoi fiable numéroté, HOLD pour PAGE 1/2/3.
- **MIDI Learn** : Beat Repeat, Auto-Replace, Reset corrigé, double appui = action sur les 8 loopers (Clear → Clear All
  Full, Reset, Stop, Restart), modificateurs lus en état réel (plus de faux Alt), raccourcis **en pause pendant toute
  saisie de texte**, cumul clavier + MIDI.
- **Twister** : boutons d'effets du web = looper sélectionné + son groupe ; page 7 Custom : « Effet du slot (type) ».
- **8 Panel** : import Adapter/Étirer dès qu'une référence existe ; étirement fait dans le script (Hermite) ; le 1er
  fichier fixe le tempo du projet (A2).
- **Scenario / Rushes** : rushes gate (appui = tel qu'écrit, relâchement = tout défait) ; éditeur avec champ texte,
  curseur, **assistant** (propositions en tapant, Tab/Entrée), palette par catégorie, `off` / `*` sur la dernière action,
  clic droit = action en off, Maj+E = boîte REAPER ; liste : Ctrl+C/X/V/D + clic droit ; titre par défaut = contenu ;
  « macros » renommées **Rushes** à l'écran.

- **Drop de groupe (V3.25, refait)** : `VL.drop_group()` / `VL.drop_tick()` dans le Launchpad, **pad B2 de la page 1** (à la
  place de QUANTISE IN/OUT, qui reste dispo par MIDI Learn / Twister), bouton DROP de l'onglet Loopers du web
  (`ACT,i,drop_group`), pédalier (`drop_group`), action MIDI Learn « Drop de groupe », `drop_group` dans `NowUndo_VLcmd/q`.
  Principe : sends post-fader temporaires des loopers du groupe qui jouent vers la piste cachée « NU Drop » (créée au 1er
  drop, sans envoi au master) où `NU_DropCapture` enregistre **un passage** de la boucle la plus longue (durée entendue =
  fenêtre / vitesse), effets des pistes et tous les modes compris, raccord fondu sur 10 ms. Puis la cible joue le mixdown
  à plat (vitesse 1, pitch 0, pas de reverse / slicer / cloud / BR / stereo, mix et out vol 100 %, fade 0), ses slots FX
  sont coupés, les autres loopers qui jouaient sont **effacés** dans le même bloc et le **groupe est supprimé**. Undo sur
  la cible = sa boucle d'avant. Les pistes d'effets aux (20-23) ne sont pas incluses (elles mélangent d'autres sources).
  Vérifié par `tools/tdrop.py` (effet sur la piste source, A en reverse, B granulaire, A vitesse ×2 : recalage de 16
  samples sur l'horloge, normal).
- **Nouveau REC (V3.25)** : un looper qui lance un nouvel enregistrement (REC sur vide, Re-Rec) termine le REC en cours
  d'un autre looper (> 0,3 s), qui attend son point de synchro puis joue (`tools/trec.py`). Un overdub ne le fait pas.

## Idées en suspens (proposées, pas faites)

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
