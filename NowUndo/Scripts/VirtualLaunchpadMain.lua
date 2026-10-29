--[[
  Virtual_Launchpad.lua  -  nowundo
  Phase 0 + 1 : coeur logiciel du Virtual Launchpad.
  Aucune logique metier dans les profils hardware : ils ne font que
     - appeler  VL.on_pad_pressed(row, col) / VL.on_pad_released(row, col)
     - recevoir des ETATS SEMANTIQUES : profile.set_led(row, col, led)
         led.state    : "off" | "idle" | "on" | "warn" | "armed" | "armed_other" | "cursor" | "member_cursor"
         led.hex      : couleur "de famille" (indication, que le materiel limite peut ignorer)
         led.level    : luminosite 0..1 deja resolue (pour le materiel RGB)
         led.blinking : true pour armed / armed_other / member_cursor
     Le coeur ne s'appuie JAMAIS sur la seule luminosite : chaque etat se traduit par une couleur et/ou un
     clignotement distincts selon le profil (VL.profiles.rgb / palette / tricolor), cf. plus bas.

  ADRESSAGE DES PADS (identique sur toutes les pages)
     row 0        : rangee du haut  -> selection looper 1..8          (col 1..8)
     row 1..8     : grille 8x8      -> depend de la page              (col 1..8)
     col 9        : colonne droite  -> row 1..4 groupes, row 5..8 pages
  PAGES : 1 Main | 2 Routing in (IN1-8 -> loopers) | 3 Routing loopers (L -> L)
          4 Page d'EXTENSION a COUCHES (menu deroulant de la fenetre, ou rappuyer sur PAGE 4) :
              fx     : effets en insert, bypass par slot (4 par input colonnes 1-8 haut, 4 par looper bas)
              groups : grille d'affectation looper -> groupe (rows 1-4), rappel des presets de groupe (row 5),
                       puis les 3 dernieres lignes de la page Main (rows 6-8, memes pads, memes cibles)
              rc505  : une colonne par looper, de BAS en HAUT : Rec, Clear, Replace, Multiply, Rev, Ping-pong, Slicer, Cloud
              tune   : pitch / speed / volume (-/+ par looper) + selecteurs d'intervalle et de pas de volume
              loop   : vrais In / Out (-/+), quantise in/out, full loop + selecteur de pas
            Nouvelle couche = VL.register_layer({ id, name, cell(row, col) -> spec }) sans toucher au coeur.
            (les sequenceurs sont des JSFX MIDI a part, hors de ce script)
  GROUPES : plus de grille d'appartenance : on maintient GROUP n (ou HOLD, ou la touche CTRL du clavier avec
            un groupe selectionne) et on tape les loopers. Chaque groupe a sa couleur (GROUP_COL) : le bouton
            GROUP n et les loopers membres la portent (attenuee au repos, vive quand le groupe est selectionne).
            Selectionner un looper (pad du haut, PREVIOUS / NEXT) active son groupe ; sans groupe : plus de groupe actif.
            Pad GROUP n : tap = selectionne le groupe (re-tap = on en sort, la selection passe au prochain looper sans
            groupe : un membre n'est jamais selectionne seul). Affecter / desaffecter : pad GROUP maintenu, ou Ctrl +
            tap sur GROUP n puis taps sur les loopers, ou Ctrl seul = groupe actif.

  HOOKS a brancher (phase 2) :
     VL.backend.send(looper, action, value)   -> envoi des actions vers nowundo (gmem / TrackFX_SetParam)
     VL.hooks.routing_changed(edges)          -> applique le routing sur les sends REAPER (mute/vol)
     VL.hooks.fx_changed(slots)               -> bypass des effets (slots = VL.fx_list())
     VL.set_fx_present(kind, id, slot, bool)  -> feedback : le slot contient-il un effet ? (kind "input"|"looper")
     VL.hooks.groups_changed(group_of)
     VL.hooks.fighter_page(n)                 -> page logique du Twister
     VL.update_looper_state(i, patch)         -> feedback nowundo -> etat miroir
]]

local VL = {}
VL.VERSION = "0.9.0"

local NLOOP, NGROUP, NPAGE, NIN, NSLOT, NPRESET = 8, 4, 4, 8, 4, 8   -- NIN : nombre d'inputs (8, ou 4 pour une grille reduite)
local LONG_PRESS_S = 1.0     -- appui long (CLEAR/PART CLEAR, REVERSE/AUTO REV, revert preset)
local BLINK_HZ     = 2

--------------------------------------------------------------------------
-- DATA : couleurs et libelles, generes depuis NOMENCLATURE_LAUNCHPAD_1.xls
--------------------------------------------------------------------------
local PAD_RGB = {
  [1] = { ["0,1"]=0xFFFF66, ["0,2"]=0xFFFF66, ["0,3"]=0xFFFF66, ["0,4"]=0xFFFF66, ["0,5"]=0xFFFF66, ["0,6"]=0xFFFF66, ["0,7"]=0xFFFF66, ["0,8"]=0xFFFF66, ["1,1"]=0x666666, ["1,2"]=0x666666, ["1,3"]=0x666666, ["1,4"]=0x666666, ["1,5"]=0x666666, ["1,7"]=0xDDDDDD, ["1,8"]=0xDDDDDD, ["1,9"]=0x336600, ["2,1"]=0xDDDDDD, ["2,2"]=0xDDDDDD, ["2,3"]=0xDDDDDD, ["2,4"]=0xDDDDDD, ["2,5"]=0xDDDDDD, ["2,6"]=0xDDDDDD, ["2,7"]=0xDDDDDD, ["2,8"]=0xDDDDDD, ["2,9"]=0x336600, ["3,1"]=0xDDDDDD, ["3,2"]=0xDDDDDD, ["3,3"]=0xDDDDDD, ["3,4"]=0xDDDDDD, ["3,5"]=0xDDDDDD, ["3,6"]=0xDDDDDD, ["3,7"]=0xDDDDDD, ["3,8"]=0xDDDDDD, ["3,9"]=0x336600, ["4,1"]=0x663300, ["4,2"]=0xCC0000, ["4,7"]=0x99FF66, ["4,8"]=0xDDDDDD, ["4,9"]=0x336600, ["5,9"]=0xCC9999, ["6,1"]=0xFF99FF, ["6,2"]=0xFF99FF, ["6,3"]=0xFF99FF, ["6,4"]=0xFF9999, ["6,5"]=0xFF9999, ["6,6"]=0xFF9999, ["6,7"]=0xFF9999, ["6,8"]=0xFF9999, ["6,9"]=0xCC9999, ["7,1"]=0x9999FF, ["7,3"]=0xCCCCCC, ["7,4"]=0xCCCCCC, ["7,5"]=0x66CCFF, ["7,6"]=0xFFD320, ["7,7"]=0xCCCCCC, ["7,8"]=0xCCCCCC, ["7,9"]=0xCC9999, ["8,1"]=0x808080, ["8,2"]=0xCCCCCC, ["8,3"]=0xFFD320, ["8,4"]=0x009933, ["8,5"]=0x9933FF, ["8,6"]=0xFF3300, ["8,7"]=0xFF3333, ["8,8"]=0xFF0000, ["8,9"]=0xCC9999 },
  [2] = { ["0,1"]=0xFFFF66, ["0,2"]=0xFFFF66, ["0,3"]=0xFFFF66, ["0,4"]=0xFFFF66, ["0,5"]=0xFFFF66, ["0,6"]=0xFFFF66, ["0,7"]=0xFFFF66, ["0,8"]=0xFFFF66, ["1,1"]=0x99FF66, ["1,2"]=0x99FF66, ["1,3"]=0x99FF66, ["1,4"]=0x99FF66, ["1,5"]=0x99FF66, ["1,6"]=0x99FF66, ["1,7"]=0x99FF66, ["1,8"]=0x99FF66, ["1,9"]=0x336600, ["2,1"]=0x99FF66, ["2,2"]=0x99FF66, ["2,3"]=0x99FF66, ["2,4"]=0x99FF66, ["2,5"]=0x99FF66, ["2,6"]=0x99FF66, ["2,7"]=0x99FF66, ["2,8"]=0x99FF66, ["2,9"]=0x336600, ["3,1"]=0x99FF66, ["3,2"]=0x99FF66, ["3,3"]=0x99FF66, ["3,4"]=0x99FF66, ["3,5"]=0x99FF66, ["3,6"]=0x99FF66, ["3,7"]=0x99FF66, ["3,8"]=0x99FF66, ["3,9"]=0x336600, ["4,1"]=0x99FF66, ["4,2"]=0x99FF66, ["4,3"]=0x99FF66, ["4,4"]=0x99FF66, ["4,5"]=0x99FF66, ["4,6"]=0x99FF66, ["4,7"]=0x99FF66, ["4,8"]=0x99FF66, ["4,9"]=0x336600, ["5,1"]=0x99FF66, ["5,2"]=0x99FF66, ["5,3"]=0x99FF66, ["5,4"]=0x99FF66, ["5,5"]=0x99FF66, ["5,6"]=0x99FF66, ["5,7"]=0x99FF66, ["5,8"]=0x99FF66, ["5,9"]=0xCC9999, ["6,1"]=0x99FF66, ["6,2"]=0x99FF66, ["6,3"]=0x99FF66, ["6,4"]=0x99FF66, ["6,5"]=0x99FF66, ["6,6"]=0x99FF66, ["6,7"]=0x99FF66, ["6,8"]=0x99FF66, ["6,9"]=0xCC9999, ["7,1"]=0x99FF66, ["7,2"]=0x99FF66, ["7,3"]=0x99FF66, ["7,4"]=0x99FF66, ["7,5"]=0x99FF66, ["7,6"]=0x99FF66, ["7,7"]=0x99FF66, ["7,8"]=0x99FF66, ["7,9"]=0xCC9999, ["8,1"]=0x99FF66, ["8,2"]=0x99FF66, ["8,3"]=0x99FF66, ["8,4"]=0x99FF66, ["8,5"]=0x99FF66, ["8,6"]=0x99FF66, ["8,7"]=0x99FF66, ["8,8"]=0x99FF66, ["8,9"]=0xCC9999 },
  [3] = { ["0,1"]=0xFFFF66, ["0,2"]=0xFFFF66, ["0,3"]=0xFFFF66, ["0,4"]=0xFFFF66, ["0,5"]=0xFFFF66, ["0,6"]=0xFFFF66, ["0,7"]=0xFFFF66, ["0,8"]=0xFFFF66, ["1,1"]=0x333333, ["1,2"]=0xFFFF99, ["1,3"]=0xFFFF99, ["1,4"]=0xFFFF99, ["1,5"]=0xFFFF99, ["1,6"]=0xFFFF99, ["1,7"]=0xFFFF99, ["1,8"]=0xFFFF99, ["1,9"]=0x336600, ["2,1"]=0xFFFF99, ["2,2"]=0x333333, ["2,3"]=0xFFFF99, ["2,4"]=0xFFFF99, ["2,5"]=0xFFFF99, ["2,6"]=0xFFFF99, ["2,7"]=0xFFFF99, ["2,8"]=0xFFFF99, ["2,9"]=0x336600, ["3,1"]=0xFFFF99, ["3,2"]=0xFFFF99, ["3,3"]=0x333333, ["3,4"]=0xFFFF99, ["3,5"]=0xFFFF99, ["3,6"]=0xFFFF99, ["3,7"]=0xFFFF99, ["3,8"]=0xFFFF99, ["3,9"]=0x336600, ["4,1"]=0xFFFF99, ["4,2"]=0xFFFF99, ["4,3"]=0xFFFF99, ["4,4"]=0x333333, ["4,5"]=0xFFFF99, ["4,6"]=0xFFFF99, ["4,7"]=0xFFFF99, ["4,8"]=0xFFFF99, ["4,9"]=0x336600, ["5,1"]=0xFFFF99, ["5,2"]=0xFFFF99, ["5,3"]=0xFFFF99, ["5,4"]=0xFFFF99, ["5,5"]=0x333333, ["5,6"]=0xFFFF99, ["5,7"]=0xFFFF99, ["5,8"]=0xFFFF99, ["5,9"]=0xCC9999, ["6,1"]=0xFFFF99, ["6,2"]=0xFFFF99, ["6,3"]=0xFFFF99, ["6,4"]=0xFFFF99, ["6,5"]=0xFFFF99, ["6,6"]=0x333333, ["6,7"]=0xFFFF99, ["6,8"]=0xFFFF99, ["6,9"]=0xCC9999, ["7,1"]=0xFFFF99, ["7,2"]=0xFFFF99, ["7,3"]=0xFFFF99, ["7,4"]=0xFFFF99, ["7,5"]=0xFFFF99, ["7,6"]=0xFFFF99, ["7,7"]=0x333333, ["7,8"]=0xFFFF99, ["7,9"]=0xCC9999, ["8,1"]=0xFFFF99, ["8,2"]=0xFFFF99, ["8,3"]=0xFFFF99, ["8,4"]=0xFFFF99, ["8,5"]=0xFFFF99, ["8,6"]=0xFFFF99, ["8,7"]=0xFFFF99, ["8,8"]=0x333333, ["8,9"]=0xCC9999 },
  [4] = { ["0,1"]=0xFFFF66, ["0,2"]=0xFFFF66, ["0,3"]=0xFFFF66, ["0,4"]=0xFFFF66, ["0,5"]=0xFFFF66, ["0,6"]=0xFFFF66, ["0,7"]=0xFFFF66, ["0,8"]=0xFFFF66, ["1,1"]=0x99FF66, ["1,2"]=0x99FF66, ["1,3"]=0x99FF66, ["1,4"]=0x99FF66, ["1,5"]=0x99FF66, ["1,6"]=0x99FF66, ["1,7"]=0x99FF66, ["1,8"]=0x99FF66, ["1,9"]=0x336600, ["2,1"]=0x99FF99, ["2,2"]=0x99FF99, ["2,3"]=0x99FF99, ["2,4"]=0x99FF99, ["2,5"]=0x99FF99, ["2,6"]=0x99FF99, ["2,7"]=0x99FF99, ["2,8"]=0x99FF99, ["2,9"]=0x336600, ["3,1"]=0x99FF33, ["3,2"]=0x99FF33, ["3,3"]=0x99FF33, ["3,4"]=0x99FF33, ["3,5"]=0x99FF33, ["3,6"]=0x99FF33, ["3,7"]=0x99FF33, ["3,8"]=0x99FF33, ["3,9"]=0x336600, ["4,1"]=0x66FF00, ["4,2"]=0x66FF00, ["4,3"]=0x66FF00, ["4,4"]=0x66FF00, ["4,5"]=0x66FF00, ["4,6"]=0x66FF00, ["4,7"]=0x66FF00, ["4,8"]=0x66FF00, ["4,9"]=0x336600, ["5,1"]=0xFFFF99, ["5,2"]=0xFFFF99, ["5,3"]=0xFFFF99, ["5,4"]=0xFFFF99, ["5,5"]=0xFFFF99, ["5,6"]=0xFFFF99, ["5,7"]=0xFFFF99, ["5,8"]=0xFFFF99, ["5,9"]=0xCC9999, ["6,1"]=0xFFFF99, ["6,2"]=0xFFFF99, ["6,3"]=0xFFFF99, ["6,4"]=0xFFFF99, ["6,5"]=0xFFFF99, ["6,6"]=0xFFFF99, ["6,7"]=0xFFFF99, ["6,8"]=0xFFFF99, ["6,9"]=0xCC9999, ["7,1"]=0xFFFF99, ["7,2"]=0xFFFF99, ["7,3"]=0xFFFF99, ["7,4"]=0xFFFF99, ["7,5"]=0xFFFF99, ["7,6"]=0xFFFF99, ["7,7"]=0xFFFF99, ["7,8"]=0xFFFF99, ["7,9"]=0xCC9999, ["8,1"]=0xFFFF99, ["8,2"]=0xFFFF99, ["8,3"]=0xFFFF99, ["8,4"]=0xFFFF99, ["8,5"]=0xFFFF99, ["8,6"]=0xFFFF99, ["8,7"]=0xFFFF99, ["8,8"]=0xFFFF99, ["8,9"]=0xCC9999 },
}
local PAD_LABEL = {
  [1] = { ["0,1"]="LOOPER 1", ["0,2"]="LOOPER 2", ["0,3"]="LOOPER 3", ["0,4"]="LOOPER 4", ["0,5"]="LOOPER 5", ["0,6"]="LOOPER 6", ["0,7"]="LOOPER 7", ["0,8"]="LOOPER 8", ["1,1"]="fighter page1 In/out", ["1,2"]="fighter page2 Pitch/shift", ["1,3"]="fighter page3 Groupes", ["1,4"]="fighter page 4 Slicer", ["1,5"]="fighter page 5 Cloud", ["1,7"]="PREVIOUS LOOPER", ["1,8"]="NEXT LOOPER", ["1,9"]="GROUPE 1", ["2,1"]="ROUTING PRESET 1", ["2,2"]="ROUTING PRESET 2", ["2,3"]="ROUTING PRESET 3", ["2,4"]="ROUTING PRESET 4", ["2,5"]="ROUTING PRESET 5", ["2,6"]="ROUTING PRESET 6", ["2,7"]="ROUTING PRESET 7", ["2,8"]="ROUTING PRESET 8", ["2,9"]="GROUPE 2", ["3,1"]="GROUP PRESET 1", ["3,2"]="GROUP PRESET 2", ["3,3"]="GROUP PRESET 3", ["3,4"]="GROUP PRESET 4", ["3,5"]="GROUP PRESET 5", ["3,6"]="GROUP PRESET 6", ["3,7"]="GROUP PRESET 7", ["3,8"]="GROUP PRESET 8", ["3,9"]="GROUPE 3", ["4,1"]="MODE LAUNCH", ["4,2"]="FIRE", ["4,7"]="QUANTISE IN/OUT", ["4,8"]="FULL LOOP", ["4,9"]="GROUPE 4", ["5,9"]="Launchpad PAGE 1 Main", ["6,1"]="MAIN", ["6,2"]="CHORUS", ["6,3"]="BRIDGE", ["6,4"]="SPEED -12", ["6,5"]="SPEED +12", ["6,6"]="PITCH -12", ["6,7"]="PITCH +12", ["6,8"]="LINK PITCH/ SHIFT", ["6,9"]="Launchpad PAGE 2 Routing in", ["7,1"]="AUTO", ["7,3"]="RESTART", ["7,4"]="ONE SHOT", ["7,5"]="CLOUD", ["7,6"]="SLICER", ["7,7"]="REDO", ["7,8"]="UNDO", ["7,9"]="Launchpad PAGE 3 Routing lp", ["8,1"]="CLEAR ALL", ["8,2"]="CLEAR OU PART CLEAR", ["8,3"]="NORMAL/ REVERSE OU AUTO REV", ["8,4"]="STOP / PLAY", ["8,5"]="MULTIPLY", ["8,6"]="REPLACE", ["8,7"]="REREC", ["8,8"]="REC/ OVERDUB", ["8,9"]="PAGE 4" },
  [2] = { ["0,1"]="LOOPER 1", ["0,2"]="LOOPER 2", ["0,3"]="LOOPER 3", ["0,4"]="LOOPER 4", ["0,5"]="LOOPER 5", ["0,6"]="LOOPER 6", ["0,7"]="LOOPER 7", ["0,8"]="LOOPER 8", ["1,1"]="IN 1/ L1", ["1,2"]="IN 1/ L2", ["1,3"]="IN 1/ L3", ["1,4"]="IN 1/ L4", ["1,5"]="IN 1/ L5", ["1,6"]="IN 1/ L6", ["1,7"]="IN 1/ L7", ["1,8"]="IN 1/ L8", ["1,9"]="GROUPE 1", ["2,1"]="IN 2 / L1", ["2,2"]="IN 2 / L2", ["2,3"]="IN 2 / L3", ["2,4"]="IN 2 / L4", ["2,5"]="IN 2 / L5", ["2,6"]="IN 2 / L6", ["2,7"]="IN 2 / L7", ["2,8"]="IN 2 / L8", ["2,9"]="GROUPE 2", ["3,1"]="IN 3 / L1", ["3,2"]="IN 3 / L2", ["3,3"]="IN 3 / L3", ["3,4"]="IN 3 / L4", ["3,5"]="IN 3 / L5", ["3,6"]="IN 3 / L6", ["3,7"]="IN 3 / L7", ["3,8"]="IN 3 / L8", ["3,9"]="GROUPE 3", ["4,1"]="IN 4/ L1", ["4,2"]="IN 4/ L2", ["4,3"]="IN 4/ L3", ["4,4"]="IN 4/ L4", ["4,5"]="IN 4/ L5", ["4,6"]="IN 4/ L6", ["4,7"]="IN 4/ L7", ["4,8"]="IN 4/ L8", ["4,9"]="GROUPE 4", ["5,1"]="FX1/ L1", ["5,2"]="FX1/ L2", ["5,3"]="FX1/ L3", ["5,4"]="FX1/ L4", ["5,5"]="FX1/ L5", ["5,6"]="FX1/ L6", ["5,7"]="FX1/ L7", ["5,8"]="FX1/ L8", ["5,9"]="Launchpad PAGE 1 Main", ["6,1"]="FX2/ L1", ["6,2"]="FX2/ L2", ["6,3"]="FX2/ L3", ["6,4"]="FX2/ L4", ["6,5"]="FX2/ L5", ["6,6"]="FX2/ L6", ["6,7"]="FX2/ L7", ["6,8"]="FX2/ L8", ["6,9"]="Launchpad PAGE 2 Routing in", ["7,1"]="FX3/ L1", ["7,2"]="FX3/ L2", ["7,3"]="FX3/ L3", ["7,4"]="FX3/ L4", ["7,5"]="FX3/ L5", ["7,6"]="FX3/ L6", ["7,7"]="FX3/ L7", ["7,8"]="FX3/ L8", ["7,9"]="Launchpad PAGE 3 Routing lp", ["8,1"]="FX4/ L1", ["8,2"]="FX4/ L2", ["8,3"]="FX4/ L3", ["8,4"]="FX4/ L4", ["8,5"]="FX4/ L5", ["8,6"]="FX4/ L6", ["8,7"]="FX4/ L7", ["8,8"]="FX4/ L8", ["8,9"]="PAGE 4" },
  [3] = { ["0,1"]="LOOPER 1", ["0,2"]="LOOPER 2", ["0,3"]="LOOPER 3", ["0,4"]="LOOPER 4", ["0,5"]="LOOPER 5", ["0,6"]="LOOPER 6", ["0,7"]="LOOPER 7", ["0,8"]="LOOPER 8", ["1,1"]="L1/L1", ["1,2"]="L2/L1", ["1,3"]="L3/ L1", ["1,4"]="L4/ L1", ["1,5"]="L5/ L1", ["1,6"]="L6/ L1", ["1,7"]="L7/ L1", ["1,8"]="L8/ L1", ["1,9"]="GROUPE 1", ["2,1"]="L1/L2", ["2,2"]="L2/L2", ["2,3"]="L3/ L2", ["2,4"]="L4/ L2", ["2,5"]="L5/ L2", ["2,6"]="L6/ L2", ["2,7"]="L7/ L2", ["2,8"]="L8/ L2", ["2,9"]="GROUPE 2", ["3,1"]="L1/L3", ["3,2"]="L2/L3", ["3,3"]="L3/ L3", ["3,4"]="L4/ L3", ["3,5"]="L5/ L3", ["3,6"]="L6/ L3", ["3,7"]="L7/ L3", ["3,8"]="L8/ L3", ["3,9"]="GROUPE 3", ["4,1"]="L1/L4", ["4,2"]="L2/L4", ["4,3"]="L3/ L4", ["4,4"]="L4/ L4", ["4,5"]="L5/ L4", ["4,6"]="L6/ L4", ["4,7"]="L7/ L4", ["4,8"]="L8/ L4", ["4,9"]="GROUPE 4", ["5,1"]="L1/L5", ["5,2"]="L2/L5", ["5,3"]="L3/ L5", ["5,4"]="L4/ L5", ["5,5"]="L5/ L5", ["5,6"]="L6/ L5", ["5,7"]="L7/ L5", ["5,8"]="L8/ L5", ["5,9"]="Launchpad PAGE 1 Main", ["6,1"]="L1/L6", ["6,2"]="L2/L6", ["6,3"]="L3/ L6", ["6,4"]="L4/ L6", ["6,5"]="L5/ L6", ["6,6"]="L6/ L6", ["6,7"]="L7/ L6", ["6,8"]="L8/ L6", ["6,9"]="Launchpad PAGE 2 Routing in", ["7,1"]="L1/L7", ["7,2"]="L2/L7", ["7,3"]="L3/ L7", ["7,4"]="L4/ L7", ["7,5"]="L5/ L7", ["7,6"]="L6/ L7", ["7,7"]="L7/ L7", ["7,8"]="L8/ L7", ["7,9"]="Launchpad PAGE 3 Routing lp", ["8,1"]="L1/L8", ["8,2"]="L2/L8", ["8,3"]="L3/ L8", ["8,4"]="L4/ L8", ["8,5"]="L5/ L8", ["8,6"]="L6/ L8", ["8,7"]="L7/ L8", ["8,8"]="L8/ L8", ["8,9"]="PAGE 4" },
  [4] = { ["0,1"]="LOOPER 1", ["0,2"]="LOOPER 2", ["0,3"]="LOOPER 3", ["0,4"]="LOOPER 4", ["0,5"]="LOOPER 5", ["0,6"]="LOOPER 6", ["0,7"]="LOOPER 7", ["0,8"]="LOOPER 8", ["1,1"]="L1/ GRP1", ["1,2"]="L2/ GRP1", ["1,3"]="L3/ GRP1", ["1,4"]="L4/ GRP1", ["1,5"]="L5/ GRP1", ["1,6"]="L6/ GRP1", ["1,7"]="L7/ GRP1", ["1,8"]="L8/ GRP1", ["1,9"]="GROUPE 1", ["2,1"]="L1/ GRP2", ["2,2"]="L2/ GRP2", ["2,3"]="L3/ GRP2", ["2,4"]="L4/ GRP2", ["2,5"]="L5/ GRP2", ["2,6"]="L6/ GRP2", ["2,7"]="L7/ GRP2", ["2,8"]="L8/ GRP2", ["2,9"]="GROUPE 2", ["3,1"]="L1/ GRP3", ["3,2"]="L2/ GRP3", ["3,3"]="L3/ GRP3", ["3,4"]="L4/ GRP3", ["3,5"]="L5/ GRP3", ["3,6"]="L6/ GRP3", ["3,7"]="L7/ GRP3", ["3,8"]="L8/ GRP3", ["3,9"]="GROUPE 3", ["4,1"]="L1/ GRP4", ["4,2"]="L2/ GRP4", ["4,3"]="L3/ GRP4", ["4,4"]="L4/ GRP4", ["4,5"]="L5/ GRP4", ["4,6"]="L6/ GRP4", ["4,7"]="L7/ GRP4", ["4,8"]="L8/ GRP4", ["4,9"]="GROUPE 4", ["5,1"]="L1/FX1", ["5,2"]="L2/FX1", ["5,3"]="L3/FX1", ["5,4"]="L4/FX1", ["5,5"]="L5/FX1", ["5,6"]="L6/FX1", ["5,7"]="L7/FX1", ["5,8"]="L8/FX1", ["5,9"]="Launchpad PAGE 1 Main", ["6,1"]="L1/FX2", ["6,2"]="L2/FX2", ["6,3"]="L3/FX2", ["6,4"]="L4/FX2", ["6,5"]="L5/FX2", ["6,6"]="L6/FX2", ["6,7"]="L7/FX2", ["6,8"]="L8/FX2", ["6,9"]="Launchpad PAGE 2 Routing in", ["7,1"]="L1/FX3", ["7,2"]="L2/FX3", ["7,3"]="L3/FX3", ["7,4"]="L4/FX3", ["7,5"]="L5/FX3", ["7,6"]="L6/FX3", ["7,7"]="L7/FX3", ["7,8"]="L8/FX3", ["7,9"]="Launchpad PAGE 3 Routing lp", ["8,1"]="L1/FX4", ["8,2"]="L2/FX4", ["8,3"]="L3/FX4", ["8,4"]="L4/FX4", ["8,5"]="L5/FX4", ["8,6"]="L6/FX4", ["8,7"]="L7/FX4", ["8,8"]="L8/FX4", ["8,9"]="PAGE 4" },
}

PAD_LABEL[1]["4,1"] = "LAUNCH"      -- le libelle d'origine (MODE LAUNCH) debordait du pad
for p = 1, NPAGE do                  -- libelles en anglais + nom complet du bouton page 4
  for key, label in pairs(PAD_LABEL[p]) do PAD_LABEL[p][key] = (label:gsub("GROUPE", "GROUP")) end
end
for row = 1, 8 do for col = 1, 8 do                  -- pages 2 et 4 redefinies (inputs 1-8, effets en insert)
  PAD_LABEL[2][row .. "," .. col] = "IN" .. row .. "/ L" .. col
  PAD_RGB[2][row .. "," .. col] = 0x99FF66
end end
local COL = { looper = 0xFFFF66, group = 0x336600, page = 0xCC9999, feedback = 0xFF8C00, default = 0x808080, member = 0x66FF33 }
-- Une couleur par groupe : utilisee par le bouton GROUP n ET par les loopers qui lui appartiennent
-- (l'orange est reserve au feedback, le jaune aux loopers non groupes)
local GROUP_COL = { 0xFF4040, 0x3A7BFF, 0x30E060, 0xE040FF }   -- GROUP 1 rouge | 2 bleu | 3 vert | 4 magenta

--------------------------------------------------------------------------
-- Utils + debug
--------------------------------------------------------------------------
local function clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end
local function deepcopy(o)
  if type(o) ~= "table" then return o end
  local r = {}
  for k, v in pairs(o) do r[k] = deepcopy(v) end
  return r
end
local function now()
  if reaper and reaper.time_precise then return reaper.time_precise() end
  return os.clock()
end
local function hex_to_rgb(h) return (h >> 16) & 255, (h >> 8) & 255, h & 255 end

local LOG = { level = 3, console = true, ring = {}, max = 300 }
local LEVELS = { error = 1, warn = 2, info = 3, debug = 4 }
local function log(level, fmt, ...)
  if LEVELS[level] > LOG.level then return end
  local ok, msg = pcall(string.format, fmt, ...)
  if not ok then msg = tostring(fmt) end
  local line = string.format("[VL %s] %s", level, msg)
  LOG.ring[#LOG.ring + 1] = line
  if #LOG.ring > LOG.max then table.remove(LOG.ring, 1) end
  if LOG.console and reaper and reaper.ShowConsoleMsg then reaper.ShowConsoleMsg(line .. "\n") end
end
VL.LOG = LOG

--------------------------------------------------------------------------
-- Etat global (UNIQUE endroit ou vit l'etat)
--------------------------------------------------------------------------
local S

local function new_matrix(n, m, v)
  local t = {}
  for i = 1, n do t[i] = {} for j = 1, m do t[i][j] = v end end
  return t
end

local function new_state()
  local s = {
    page = 1,
    sel_looper = 1,                 -- 1..8, toujours un looper selectionne
    sel_group = 0,                  -- 0..4, 0 = aucun groupe
    group_of = {},                  -- group_of[looper] = 0..4 (un looper ne peut etre que dans UN groupe)
    launch = false,                 -- mode Launch
    armed = {},                     -- actions armees {action, args, targets, key}
    fighter_page = 1,               -- page logique du Twister
    loopers = {},                   -- miroir de l'etat des loopers (feedback nowundo)
    routing = {                     -- tout ferme par defaut ("on ouvre les vannes")
      in_l = new_matrix(NIN, NLOOP, false),     -- in_l[IN][looper]
      l_l  = new_matrix(NLOOP, NLOOP, false),   -- l_l[src][dst]
    },
    fx = {                          -- effets en insert : true = actif (bypass off)
      input  = new_matrix(NIN, NSLOT, false),   -- input[IN][slot]
      looper = new_matrix(NLOOP, NSLOT, false), -- looper[looper][slot]
    },
    p4_layer = "fx",                -- couche courante de la page 4 (partagee : survit au changement de page)
    layer_cfg = { interval = 12, vol_sel = 2, nudge = 3 },   -- indices : octave / 1 dB / 1 %   -- selecteurs globaux des couches tune / loop
    fx_present = {                  -- le slot contient-il un effet ? (feedback du backend ; vrai par defaut)
      input  = new_matrix(NIN, NSLOT, true),
      looper = new_matrix(NLOOP, NSLOT, true),
    },
    presets = {
      routing = { active = 1, slots = {} },
      group   = { active = 1, slots = {} },
    },
    cfg = { feedback_policy = "attenuate", feedback_gain_db = -6 },   -- "allow" | "attenuate" | "block"
  }
  for i = 1, NLOOP do
    s.group_of[i] = 0
    s.loopers[i] = { playing = false, rev = false, oneshot = false, cloud = false, slicer = false,
                     link = false, rec = false, replace = false, multiply = false, auto = false, pingpong = false, part = 1 }
  end
  return s
end

--------------------------------------------------------------------------
-- Hooks / backend (phase 2 les remplacera)
--------------------------------------------------------------------------
VL.backend = { send = function(looper, action, value)
  log("debug", "send L%d  %s  %s", looper, action, tostring(value))
end }
VL.hooks = {
  routing_changed = function(edges) end,
  groups_changed  = function(group_of) end,
  fighter_page    = function(n) end,
  fx_changed      = function(slots) end,
  layer_changed   = function(id) end,
  find_looper_fx  = nil,                 -- (i) -> track, fxindex ; defaut : voir plus bas
}
VL.config = { fx_patterns = { "nowundo", "noundo", "looper" } }   -- nom du JSFX a reconnaitre sur les pistes

-- Geste de "peinture" : on pose/retire une cellule, puis on glisse (souris) ou on appuie sur d'autres
-- pads sans lacher le premier (hardware) : toutes prennent la meme valeur. Les hooks (routing, groupes)
-- ne sont appeles qu'UNE fois, a la fin du geste.
local paint = nil
local function notify_routing()
  if paint then paint.dirty_routing = true else VL.hooks.routing_changed(VL.routing_edges()) end
end
local function notify_groups()
  if paint then paint.dirty_groups = true else VL.hooks.groups_changed(S.group_of) end
end
local function notify_fx()
  if paint then paint.dirty_fx = true else VL.hooks.fx_changed(VL.fx_list()) end
end

--------------------------------------------------------------------------
-- Selection looper / groupe / page
--------------------------------------------------------------------------
-- INVARIANT : le groupe actif est TOUJOURS le groupe du looper selectionne (0 = aucun) : un looper qui appartient
-- a un groupe n'est jamais selectionne seul, il agit toujours avec son groupe. Sortir d'un groupe ne defait aucune
-- appartenance : la selection passe alors sur un looper sans groupe.
local function follow_group()
  local g = S.group_of[S.sel_looper] or 0
  if g ~= S.sel_group then log("info", "group %d active", g) end
  S.sel_group = g
end
function VL.select_looper(i)
  S.sel_looper = clamp(i, 1, NLOOP)
  follow_group()
  log("info", "looper %d selectionne", S.sel_looper)
end
function VL.step_looper(d)
  S.sel_looper = ((S.sel_looper - 1 + d) % NLOOP) + 1
  follow_group()
  log("info", "looper %d selectionne", S.sel_looper)
end
-- Pad GROUP n (sans Ctrl) : selectionne le groupe (= son premier looper) ; re-appui sur le groupe actif = on en sort,
-- la selection passe au looper SANS groupe suivant (jamais un membre isole). Groupe vide : rien a selectionner.
function VL.select_group(g)
  if S.sel_group == g then
    for d = 1, NLOOP do
      local i = ((S.sel_looper - 1 + d) % NLOOP) + 1
      if (S.group_of[i] or 0) == 0 then VL.select_looper(i) return end
    end
    log("info", "tous les loopers sont groupes : groupe %d reste actif", g)
    return
  end
  local m = VL.group_members(g)
  if #m == 0 then log("info", "groupe %d vide : rien a selectionner", g) return end
  VL.select_looper(m[1])
end
function VL.set_page(p)
  if p == 4 and S.page == 4 then          -- sur page 4 : appui sur PAGE 4 = extension suivante (boucle)
    VL.cycle_layer()
    return
  end
  S.page = clamp(p, 1, NPAGE)
  log("info", "page %d", S.page)
  -- Publier immediatement pour le miroir (section fixe : SYNC est local plus bas dans le fichier)
  if not VL.mirror_mode and reaper and reaper.SetExtState then
    reaper.SetExtState("nowundo_vl", "active_page", tostring(S.page), false)
  end
end
function VL.set_fighter_page(n)
  S.fighter_page = n
  VL.hooks.fighter_page(n)
  log("info", "fighter page %d", n)
end

function VL.group_members(g)
  local m = {}
  for i = 1, NLOOP do if S.group_of[i] == g then m[#m + 1] = i end end
  return m
end

-- cibles d'une action : groupe actif ET non vide -> uniquement les membres du groupe
-- (le looper selectionne n'est PAS inclus s'il n'en fait pas partie) ; sinon looper selectionne
function VL.targets()
  if S.sel_group > 0 then
    local m = VL.group_members(S.sel_group)
    if #m > 0 then return m end
  end
  return { S.sel_looper }
end

function VL.assign_group(looper, g)         -- exclusif : un looper = au plus un groupe (g = 0 : aucun)
  if S.group_of[looper] == g then return false end
  S.group_of[looper] = g
  if looper == S.sel_looper then S.sel_group = g end      -- le looper selectionne a change de groupe : le groupe actif suit
  notify_groups()
  log("info", "looper %d -> group %d", looper, g)
  return true
end
function VL.set_membership(looper, g)       -- bascule
  return VL.assign_group(looper, (S.group_of[looper] == g) and 0 or g)
end

--------------------------------------------------------------------------
-- Actions looper (group-aware)
--------------------------------------------------------------------------
-- kind : trig (declenchement) | toggle (etat booleen, key = champ du miroir) | select (valeur, key)
local ACTIONS = {
  rerec       = { kind = "trig" },  undo      = { kind = "trig" },  redo      = { kind = "trig" },
  restart     = { kind = "trig" },
  quantise_inout = { kind = "trig" }, full_loop = { kind = "trig" },
  speed_step  = { kind = "trig" },  pitch_step = { kind = "trig" },     -- args = demi-tons (+/-12 = octave)
  volume_step = { kind = "trig" },                                      -- args = dB (signe = sens)
  volume_pct  = { kind = "trig" },                                      -- args = % (signe = sens)
  loop_in_step  = { kind = "trig" },                                    -- args = % de la boucle (signe = sens)
  loop_out_step = { kind = "trig" },                                    -- vrais In / Out : l'autre borne ne bouge pas
                                                                        -- (si la boucle est quantisee : une division par appui)
  -- CLEAR : reinitialise tout (rec, replace, multiply, auto, reverse, play, one shot, cloud, slicer, link)
  -- et remet PART sur MAIN. Epargne : presets, selecteurs looper/groupe/page, appartenance aux groupes.
  clear_all   = { kind = "trig", reset = "all" },
  clear       = { kind = "trig", reset = "all" },
  clear_part  = { kind = "trig", reset = "part" },                       -- idem mais garde la part courante
  -- toggles (allume / eteint) ; excl = actions mutuellement exclusives
  rec_overdub = { kind = "toggle", key = "rec",      excl = { "replace" } },
  replace     = { kind = "toggle", key = "replace",  excl = { "rec_overdub" } },
  multiply    = { kind = "toggle", key = "multiply" },
  auto        = { kind = "toggle", key = "auto" },
  stop_play   = { kind = "toggle", key = "playing" },
  reverse     = { kind = "toggle", key = "rev" },
  auto_rev    = { kind = "toggle", key = "pingpong" },                  -- AUTO REV = ping-pong
  one_shot    = { kind = "toggle", key = "oneshot" },
  cloud       = { kind = "toggle", key = "cloud" },
  slicer      = { kind = "toggle", key = "slicer" },
  link        = { kind = "toggle", key = "link" },
  part        = { kind = "select", key = "part" },                       -- args = 1 MAIN, 2 CHORUS, 3 BRIDGE
}

-- Etat cible d'un toggle applique a plusieurs loopers : on part du looper selectionne s'il fait
-- partie des cibles, sinon de la majorite. Le groupe se resynchronise ainsi des le 1er appui.
local function ref_looper(targets)
  for _, t in ipairs(targets) do if t == S.sel_looper then return t end end
  return targets[1]
end

-- etat "affiche" d'un toggle pour un ensemble de cibles (ce que l'appui va eteindre)
local function toggle_on(key, targets)
  for _, t in ipairs(targets) do
    if t == S.sel_looper then return S.loopers[t][key] end
  end
  local on = 0
  for _, t in ipairs(targets) do if S.loopers[t][key] then on = on + 1 end end
  return on * 2 > #targets
end

local function desired_toggle(key, targets) return not toggle_on(key, targets) end

local RESET_FLAGS = { "rec", "replace", "multiply", "auto", "rev", "pingpong", "playing", "oneshot", "cloud", "slicer", "link" }
local function reset_looper(t, back_to_main)
  for _, k in ipairs(RESET_FLAGS) do S.loopers[t][k] = false end
  if back_to_main then S.loopers[t].part = 1 end
end

local function send(looper, action, value)
  VL.backend.send(looper, action, value)
  local def = ACTIONS[action]
  if def and def.key and value ~= nil then S.loopers[looper][def.key] = value end   -- miroir optimiste
end

local function exec(action, args, targets)
  local def = ACTIONS[action]
  if not def then log("error", "action inconnue : %s", tostring(action)) return end
  if def.kind == "toggle" then
    local want = desired_toggle(def.key, targets)
    for _, t in ipairs(targets) do
      if S.loopers[t][def.key] ~= want then
        if want and def.excl then                     -- ex. REC <-> REPLACE : l'un coupe l'autre
          for _, ex in ipairs(def.excl) do
            if S.loopers[t][ACTIONS[ex].key] then send(t, ex, false) end
          end
        end
        send(t, action, want)
      end
    end
  else
    for _, t in ipairs(targets) do
      send(t, action, args)
      if def.reset then reset_looper(t, def.reset == "all") end
    end
  end
  log("info", "%s%s -> %s", action, args and (" " .. tostring(args)) or "", table.concat(targets, ","))
end

--------------------------------------------------------------------------
-- Mode Launch / Fire
--------------------------------------------------------------------------
local function armed_key(action, args, targets)
  return action .. ":" .. tostring(args) .. ":" .. table.concat(targets, ",")
end

local function arm(action, args, targets)
  targets = targets or VL.targets()             -- cibles figees a l'armement
  local key = armed_key(action, args, targets)
  for i, a in ipairs(S.armed) do
    if a.key == key then table.remove(S.armed, i) log("info", "desarme %s", key) return end
  end
  S.armed[#S.armed + 1] = { action = action, args = args, targets = targets, key = key }
  log("info", "arme %s", key)
end

function VL.toggle_launch()
  S.launch = not S.launch
  if not S.launch then S.armed = {} end         -- quitter Launch annule les actions armees
  log("info", "mode Launch %s", S.launch and "ON" or "OFF")
end

function VL.fire()                       -- execute tout ce qui est arme, puis quitte le mode Launch
  local list = S.armed
  S.armed = {}
  for _, a in ipairs(list) do exec(a.action, a.args, a.targets) end
  S.launch = false
  log("info", "fire : %d action(s), mode Launch OFF", #list)
end

function VL.trigger(action, args, targets)    -- targets : cibles explicites (couches), sinon looper / groupe actif
  targets = targets or VL.targets()
  if S.launch then arm(action, args, targets) else exec(action, args, targets) end
end

--------------------------------------------------------------------------
-- Routing (IN1-4 / FX1-4 / L1-8) + garde-fou feedback
--------------------------------------------------------------------------
-- Seuls les loopers peuvent former une boucle (L -> L) : les IN n'ont pas d'entree et les effets sont en insert.
local function compute_feedback()
  local reach = new_matrix(NLOOP, NLOOP, false)
  local R = S.routing
  for a = 1, NLOOP do for b = 1, NLOOP do if R.l_l[a][b] then reach[a][b] = true end end end
  for m = 1, NLOOP do for u = 1, NLOOP do if reach[u][m] then
    for v = 1, NLOOP do if reach[m][v] then reach[u][v] = true end end
  end end end
  local fb = {}
  for a = 1, NLOOP do for b = 1, NLOOP do
    if R.l_l[a][b] and reach[b][a] then fb["l_l:" .. a .. ":" .. b] = true end
  end end
  return fb
end

function VL.routing_edges()
  local fb, out, R = compute_feedback(), {}, S.routing
  local function add(kind, a, b, src, dst, open)
    local isfb = open and fb[kind .. ":" .. a .. ":" .. b] or false
    out[#out + 1] = { kind = kind, a = a, b = b, src = src, dst = dst, open = open, feedback = isfb,
                      gain_db = (isfb and S.cfg.feedback_policy == "attenuate") and S.cfg.feedback_gain_db or 0 }
  end
  for k = 1, NIN  do for i = 1, NLOOP do add("in_l", k, i, "IN" .. k, "L" .. i, R.in_l[k][i]) end end
  for a = 1, NLOOP do for b = 1, NLOOP do
    if a ~= b then add("l_l", a, b, "L" .. a, "L" .. b, R.l_l[a][b]) end
  end end
  return out
end

-- Effets en insert : activer un effet = retirer son bypass (instantane, sans toucher au routing)
function VL.fx_list()
  local out = {}
  for _, kind in ipairs({ "input", "looper" }) do
    for id = 1, (kind == "input") and NIN or NLOOP do
      for slot = 1, NSLOT do
        out[#out + 1] = { kind = kind, id = id, slot = slot,
                          present = S.fx_present[kind][id][slot], enabled = S.fx[kind][id][slot] }
      end
    end
  end
  return out
end

function VL.set_fx(kind, id, slot, value)
  if not S.fx_present[kind][id][slot] then log("debug", "fx %s %d slot %d : vide", kind, id, slot) return false end
  if S.fx[kind][id][slot] == value then return false end
  S.fx[kind][id][slot] = value
  notify_fx()
  log("info", "fx %s %d slot %d : %s", kind, id, slot, value and "actif" or "bypass")
  return true
end
function VL.toggle_fx(kind, id, slot) return VL.set_fx(kind, id, slot, not S.fx[kind][id][slot]) end

function VL.set_fx_present(kind, id, slot, present)     -- feedback backend : un slot vide ne peut pas etre actif
  S.fx_present[kind][id][slot] = present and true or false
  if not present then S.fx[kind][id][slot] = false end
end

function VL.set_route(kind, a, b, value)
  local m = S.routing[kind]
  if kind == "l_l" and a == b then log("debug", "L%d -> L%d desactive", a, b) return false end
  if m[a][b] == value then return false end
  m[a][b] = value
  if value and S.cfg.feedback_policy == "block" and compute_feedback()[kind .. ":" .. a .. ":" .. b] then
    m[a][b] = false
    log("warn", "route %s %d->%d refusee : creerait une boucle de feedback", kind, a, b)
    return false
  end
  notify_routing()
  log("info", "route %s %d->%d : %s", kind, a, b, value and "ouverte" or "fermee")
  return true
end
function VL.toggle_route(kind, a, b) return VL.set_route(kind, a, b, not S.routing[kind][a][b]) end

--------------------------------------------------------------------------
-- Presets : changer de preset valide de facto les modifications du precedent.
--   - le preset actif est toujours "en edition" (S.routing / S.group_of)
--   - appui sur un autre slot : le precedent est sauvegarde, puis le nouveau est charge
--     (slot vide = fork de l'etat courant)
--   - appui long : revert du slot actif a sa derniere version validee
--------------------------------------------------------------------------
local BANKS = {
  routing = { get = function() return deepcopy({ routing = S.routing, fx = S.fx }) end,       -- routing + effets actifs
              set = function(d)
                S.routing = deepcopy(d.routing); S.fx = deepcopy(d.fx)
                VL.hooks.routing_changed(VL.routing_edges()); VL.hooks.fx_changed(VL.fx_list())
              end },
  group   = { get = function() return deepcopy(S.group_of) end,
              set = function(d)
                S.group_of = deepcopy(d)
                S.sel_group = S.group_of[S.sel_looper] or 0
                VL.hooks.groups_changed(S.group_of)
              end },
}

local function init_presets()
  for name, bank in pairs(BANKS) do
    S.presets[name].active = 1
    S.presets[name].slots = { [1] = bank.get() }
  end
end

function VL.preset_press(name, n)
  local p, bank = S.presets[name], BANKS[name]
  if p.active == n then return end
  p.slots[p.active] = bank.get()                       -- validation implicite de l'ancien
  if p.slots[n] then bank.set(p.slots[n]) else p.slots[n] = bank.get() end
  p.active = n
  log("info", "preset %s %d actif", name, n)
end

function VL.preset_revert(name, n)
  local p, bank = S.presets[name], BANKS[name]
  if p.active == n and p.slots[n] then bank.set(p.slots[n]) log("info", "preset %s %d : revert", name, n) end
end

--------------------------------------------------------------------------
-- Bindings : (page,row,col) -> { short = ..., long = ... }
--------------------------------------------------------------------------
local function act(action, args) return { kind = "action", action = action, args = args } end
local function act_on(looper, action, args) return { kind = "action", action = action, args = args, targets = { looper } } end
local function fn(f, led)       return { kind = "fn", fn = f, led = led } end

local BIND = {}
for p = 1, NPAGE do BIND[p] = {} end
-- instant = true : l'appui court agit des l'appui (et l'appui long s'ajoute ensuite)
-- instant : l'appui court agit des l'appui (l'appui long s'ajoute ensuite)
-- defer   : l'appui court n'agit qu'au relachement, et seulement si le pad n'a pas servi de "maintien"
local function bind(page, row, col, short, long, instant, defer)
  BIND[page][row .. "," .. col] = { short = short, long = long, instant = instant, defer = defer }
end
local function bind_all(row, col, short, long, instant, defer)
  for p = 1, NPAGE do bind(p, row, col, short, long, instant, defer) end
end

-- global : top row, groupes, pages
-- appui = selection ; appui long (1 s) = ouvre / ferme la fenetre du looper
for i = 1, NLOOP do
  bind_all(0, i, fn(function() VL.select_looper(i) end, function() return S.sel_looper == i and "on" or "idle" end),
                 fn(function() VL.toggle_looper_window(i) end), true)
end
-- GROUP n : tap = selectionne / quitte le groupe (cf. VL.select_group). MAINTENU + tap sur un looper (rangee du haut)
-- = ajoute / retire ce looper du groupe. Avec Ctrl enfonce, le tap choisit le groupe edite (cf. VL.group_pad_tap).
for g = 1, NGROUP do
  bind_all(g, 9, fn(function() VL.group_pad_tap(g) end, function() return S.sel_group == g and "on" or "idle" end), nil, false, true)
end
for p = 1, NPAGE do bind_all(NGROUP + p, 9, fn(function() VL.set_page(p) end, function() return S.page == p and "on" or "idle" end)) end

-- Page 1 : Main
for n = 1, 5 do bind(1, 1, n, fn(function() VL.set_fighter_page(n) end, function() return S.fighter_page == n and "on" or "idle" end)) end
bind(1, 1, 7, fn(function() VL.step_looper(-1) end))
bind(1, 1, 8, fn(function() VL.step_looper(1) end))
for n = 1, NPRESET do
  for r, bank in ipairs({ "routing", "group" }) do
    bind(1, 1 + r, n,
      fn(function() VL.preset_press(bank, n) end, function()
        local p = S.presets[bank]
        return p.active == n and "on" or (p.slots[n] and "idle" or "off")
      end),
      fn(function() VL.preset_revert(bank, n) end))
  end
end
bind(1, 4, 1, fn(function() VL.toggle_launch() end, function() return S.launch and "on" or "idle" end))
bind(1, 4, 2, fn(function() VL.fire() end, function() return #S.armed > 0 and "armed" or "idle" end))
bind(1, 4, 7, act("quantise_inout"))
bind(1, 4, 8, act("full_loop"))
for n = 1, 3 do bind(1, 6, n, act("part", n)) end
bind(1, 6, 4, act("speed_step", -12)); bind(1, 6, 5, act("speed_step", 12))
bind(1, 6, 6, act("pitch_step", -12)); bind(1, 6, 7, act("pitch_step", 12))
bind(1, 6, 8, act("link"))
bind(1, 7, 1, act("auto"));    bind(1, 7, 3, act("restart"));  bind(1, 7, 4, act("one_shot"))
bind(1, 7, 5, act("cloud"));   bind(1, 7, 6, act("slicer"));   bind(1, 7, 7, act("redo")); bind(1, 7, 8, act("undo"))
bind(1, 8, 1, act("clear_all"))
bind(1, 8, 2, act("clear"), act("clear_part"))
bind(1, 8, 3, act("reverse"), act("auto_rev"))
bind(1, 8, 4, act("stop_play")); bind(1, 8, 5, act("multiply")); bind(1, 8, 6, act("replace"))
bind(1, 8, 7, act("rerec"));     bind(1, 8, 8, act("rec_overdub"))

-- Pages 2 / 3 / 4 : matrices
local function route_pad(page, row, col, kind, a, b)
  local sh = fn(function() VL.toggle_route(kind, a, b) end)
  sh.paint = { get = function() return S.routing[kind][a][b] end,
               set = function(v) VL.set_route(kind, a, b, v) end }
  bind(page, row, col, sh)
end
for row = 1, 8 do for col = 1, 8 do
  -- P2 : ligne = INPUT (1..NIN), colonne = looper destination
  if row <= NIN then route_pad(2, row, col, "in_l", row, col) end
  -- P3 : colonne = looper source, ligne = looper destination ; diagonale desactivee
  if row ~= col then route_pad(3, row, col, "l_l", col, row) end
end end

--------------------------------------------------------------------------
-- Page 4 : page d'EXTENSION de controle a couches
-- Une couche = { id, name, cell(row, col) -> spec ou nil }
-- spec = { short = binding, long = binding?, hex = couleur de famille, state = function() -> etat LED, label = texte|fonction }
-- Les couches pilotent des loopers PRECIS (colonnes) : pas d'adressage par groupe.
--------------------------------------------------------------------------
local LAYERS, LAYER_BY_ID = {}, {}
local main_state                      -- etat LED d'un pad de la page Main (defini avec le rendu) ; reutilise par la couche Groups

function VL.register_layer(def)
  def.cells = {}
  for row = 1, 8 do for col = 1, 8 do
    local spec = def.cell(row, col)
    if spec then
      spec.bind = { short = spec.short, long = spec.long }
      def.cells[row .. "," .. col] = spec
    end
  end end
  LAYERS[#LAYERS + 1] = def
  LAYER_BY_ID[def.id] = def
end

local function cur_layer() return LAYER_BY_ID[S.p4_layer] or LAYERS[1] end
setmetatable(BIND[4], { __index = function(_, key)               -- la grille de la page 4 vient de la couche courante
  local spec = cur_layer().cells[key]
  return spec and spec.bind
end })

function VL.layers()
  local out = {}
  for _, l in ipairs(LAYERS) do out[#out + 1] = { id = l.id, name = l.name } end
  return out
end
function VL.set_layer(id)
  if not LAYER_BY_ID[id] then return false end
  S.p4_layer = id
  VL.hooks.layer_changed(id)
  log("info", "page 4 : couche %s", id)
  return true
end
function VL.cycle_layer()
  local n = #LAYERS
  if n == 0 then return end
  local idx = 0
  for i, l in ipairs(LAYERS) do if l.id == S.p4_layer then idx = i; break end end
  if idx == 0 then idx = 1 end            -- couche inconnue : on repart de la premiere
  VL.set_layer(LAYERS[idx % n + 1].id)    -- derniere -> premiere (circulaire)
end

-- libelle d'un pad (fenetre de test) : dynamique pour la page 4 et le bouton PAGE 4
function VL.pad_label(page, row, col)
  if row == 8 and col == 9 then return "Launchpad PAGE 4 " .. cur_layer().name end
  if page == 4 and row >= 1 and col <= 8 then
    local spec = cur_layer().cells[row .. "," .. col]
    if not spec then return nil end
    return type(spec.label) == "function" and spec.label() or spec.label
  end
  return PAD_LABEL[page] and PAD_LABEL[page][row .. "," .. col]
end

local function p1col(key, fallback) return PAD_RGB[1][key] or fallback or COL.default end
local function ui_sel(fnc) return fn(fnc) end

-- Couche EFFETS : insert, bypass par slot
VL.register_layer({ id = "fx", name = "Effects", cell = function(row, col)
  local kind, id, slot = "looper", col, row - 4
  if row <= 4 then
    if col > NIN then return nil end
    kind, id, slot = "input", col, row
  end
  local sh = fn(function() VL.toggle_fx(kind, id, slot) end)
  sh.paint = { get = function() return S.fx[kind][id][slot] end, set = function(v) VL.set_fx(kind, id, slot, v) end }
  return { short = sh, hex = (row <= 4) and 0x99FF66 or 0xFFFF99,
           state = function()
             if not S.fx_present[kind][id][slot] then return "off" end        -- slot vide : eteint
             return S.fx[kind][id][slot] and "on" or "idle"                   -- dispo : attenue / actif : allume
           end,
           label = (row <= 4) and ("IN" .. col .. " FX" .. row) or ("L" .. col .. " FX" .. (row - 4)) }
end })

-- Couche GROUPS : affectation des loopers aux groupes (comme la page d'origine), presets de groupe,
-- et rappel des 3 dernieres lignes de la page Main (memes pads : memes cibles looper / groupe actif)
VL.register_layer({ id = "groups", name = "Groups", cell = function(row, col)
  if row <= 4 then                                              -- ligne = groupe, colonne = looper (exclusif par colonne)
    local sh = fn(function() VL.set_membership(col, row) end)
    sh.paint = { get = function() return S.group_of[col] == row end,
                 set = function(v)
                   if v then VL.assign_group(col, row) elseif S.group_of[col] == row then VL.assign_group(col, 0) end
                 end }
    return { short = sh, hex = GROUP_COL[row], label = "L" .. col .. " GRP" .. row,
             state = function() return S.group_of[col] == row and "on" or "idle" end }
  elseif row == 5 then                                          -- rappel des presets de groupe (comme la ligne 3 de la page Main)
    local b = BIND[1]["3," .. col]
    return { short = b.short, long = b.long, hex = PAD_RGB[1]["3," .. col] or COL.default,
             label = PAD_LABEL[1]["3," .. col], state = function() return main_state(b) end }
  else                                                          -- lignes 6-8 : repliquees de la page Main
    local key = row .. "," .. col
    local b = BIND[1][key]
    if not b then return nil end
    return { short = b.short, long = b.long, hex = PAD_RGB[1][key] or COL.default,
             label = PAD_LABEL[1][key], state = function() return main_state(b) end }
  end
end })

-- Couche RC-505 : une colonne par looper, les fonctions majeures de BAS en HAUT (Rec en bas)
local RC_ROWS = {
  { "rec_overdub", "REC",       p1col("8,8") },  { "clear",  "CLEAR",     p1col("8,2") },
  { "replace",     "REPLACE",   p1col("8,6") },  { "multiply", "MULTIPLY", p1col("8,5") },
  { "reverse",     "REVERSE",   p1col("8,3") },  { "auto_rev", "PING PONG", p1col("8,3") },
  { "slicer",      "SLICER",    p1col("7,6") },  { "cloud",  "CLOUD",     p1col("7,5") },
}
VL.register_layer({ id = "rc505", name = "RC-505", cell = function(row, col)
  local fnrow = RC_ROWS[9 - row]                                -- ligne 8 = Rec (bas), ligne 1 = Cloud (haut)
  local action, name, hex = fnrow[1], fnrow[2], fnrow[3]
  local def = ACTIONS[action]
  return { short = act_on(col, action), hex = hex, label = "L" .. col .. " " .. name,
           state = function() return (def.key and S.loopers[col][def.key]) and "on" or "idle" end }
end })

-- Pads "-/+" : 2 pads par looper et par parametre ; rangee impaire = loopers 1-4, rangee paire = loopers 5-8
local function pair_cell(row, col)
  return ((row - 1) % 2) * 4 + math.ceil(col / 2), (col % 2 == 1) and -1 or 1
end
local function sign_str(sg) return sg < 0 and "-" or "+" end

local INTERVALS = { 24, 12, 7, 5, 4, 3, 2, 1 }                      -- demi-tons : 2 octaves, octave, quinte, quarte, tierces, ton, demi-ton
local INTERVAL_NAME = { [24] = "2 OCT", [12] = "OCT", [7] = "5TH", [5] = "4TH", [4] = "M3", [3] = "m3", [2] = "TONE", [1] = "SEMI" }
local VOL_STEPS = { { "db", 0.5 }, { "db", 1 }, { "db", 2 }, { "db", 3 }, { "db", 6 }, { "pct", 1 }, { "pct", 5 }, { "pct", 10 } }
local NUDGES = { 0.1, 0.5, 1, 2, 5, 10, 25, 50 }                    -- % de la longueur de la boucle (mode libre)
local function fmtn(v) return (v == math.floor(v)) and tostring(math.floor(v)) or tostring(v) end

-- Couche TUNE : pitch / speed / volume + selecteurs globaux (rangee 7 : intervalle, rangee 8 : pas de volume)
VL.register_layer({ id = "tune", name = "Tune", cell = function(row, col)
  if row <= 6 then
    local looper, sg = pair_cell(row, col)
    local group = math.ceil(row / 2)                                 -- 1 pitch, 2 speed, 3 volume
    local sh, hex, label
    if group == 1 then
      hex = 0xFF9966
      sh = fn(function() VL.trigger("pitch_step", sg * S.layer_cfg.interval, { looper }) end)
      label = function() return "L" .. looper .. " PITCH " .. sign_str(sg) .. S.layer_cfg.interval end
    elseif group == 2 then
      hex = 0x66CCFF
      sh = fn(function() VL.trigger("speed_step", sg * S.layer_cfg.interval, { looper }) end)
      label = function() return "L" .. looper .. " SPEED " .. sign_str(sg) .. S.layer_cfg.interval end
    else
      hex = 0xCC99FF
      sh = fn(function()
        local v = VOL_STEPS[S.layer_cfg.vol_sel]
        VL.trigger(v[1] == "db" and "volume_step" or "volume_pct", sg * v[2], { looper })
      end)
      label = function()
        local v = VOL_STEPS[S.layer_cfg.vol_sel]
        return "L" .. looper .. " VOL " .. sign_str(sg) .. fmtn(v[2]) .. (v[1] == "db" and "dB" or "%")
      end
    end
    return { short = sh, hex = hex, label = label, state = function() return "idle" end }
  elseif row == 7 then
    local v = INTERVALS[col]
    return { short = fn(function() S.layer_cfg.interval = v end), hex = 0xCCCCCC,
             label = "INT " .. v .. " " .. INTERVAL_NAME[v],
             state = function() return S.layer_cfg.interval == v and "on" or "idle" end }
  else
    local v = VOL_STEPS[col]
    return { short = fn(function() S.layer_cfg.vol_sel = col end), hex = 0xCCCCCC,
             label = "VOL " .. fmtn(v[2]) .. (v[1] == "db" and "dB" or "%"),
             state = function() return S.layer_cfg.vol_sel == col and "on" or "idle" end }
  end
end })

-- Couche LOOP : vrais In / Out (le lien In/Width de l'interface du looper n'est pas utilise),
-- quantise in/out, full loop, et selecteur de pas (% de la boucle ; si quantisee : une division par appui)
VL.register_layer({ id = "loop", name = "Loop", cell = function(row, col)
  if row <= 4 then
    local looper, sg = pair_cell(row, col)
    local is_in = row <= 2
    local action = is_in and "loop_in_step" or "loop_out_step"
    return { short = fn(function() VL.trigger(action, sg * NUDGES[S.layer_cfg.nudge], { looper }) end),
             hex = is_in and 0x66FFCC or 0xFF6699,
             label = function() return "L" .. looper .. (is_in and " IN " or " OUT ") .. sign_str(sg) .. fmtn(NUDGES[S.layer_cfg.nudge]) .. "%" end,
             state = function() return "idle" end }
  elseif row == 5 then
    return { short = act_on(col, "quantise_inout"), hex = 0xFFCC66, label = "L" .. col .. " QUANT IN/OUT", state = function() return "idle" end }
  elseif row == 6 then
    return { short = act_on(col, "full_loop"), hex = 0xFFCC66, label = "L" .. col .. " FULL LOOP", state = function() return "idle" end }
  elseif row == 7 then
    return { short = fn(function() S.layer_cfg.nudge = col end), hex = 0xCCCCCC,
             label = "STEP " .. fmtn(NUDGES[col]) .. "%",
             state = function() return S.layer_cfg.nudge == col and "on" or "idle" end }
  end
  return nil
end })

-- Dispatch (appui court / long)
local function dispatch(b)
  if not b then return end
  if b.kind == "action" then VL.trigger(b.action, b.args, b.targets) else b.fn() end
end

local down = {}

-- Maintien virtuel (bouton HOLD de la fenetre) ou clavier (Ctrl) : meme effet tant qu'ils sont actifs.
-- Par defaut ils editent le groupe ACTIF ; un tap sur un pad GROUP n (meme vide) choisit le groupe edite (edit_group).
local vhold, ctrl_hold, edit_group = false, false, nil
local function check_edit_end() if not (vhold or ctrl_hold) then edit_group = nil end end   -- fin du maintien = fin de l'edition
function VL.set_virtual_hold(on) vhold = on and true or false; check_edit_end() end
function VL.set_ctrl_hold(on) ctrl_hold = on and true or false; check_edit_end() end
function VL.ctrl_held() return ctrl_hold end
-- Tap sur GROUP n : avec HOLD / Ctrl = choisit le groupe a editer (re-tap = retour au groupe actif) ; sinon = selection
function VL.group_pad_tap(g)
  if vhold or ctrl_hold then
    if edit_group == g then edit_group = nil else edit_group = g end   -- (pas de "and nil or" : nil est faux en Lua)
  else
    VL.select_group(g)
  end
end

-- groupe dont le pad est maintenu (mode edition d'appartenance), ou nil
-- renvoie (g, cle du pad maintenu) ; la cle est nil pour un maintien virtuel
local function held_group()
  for g = 1, NGROUP do
    local d = down[g .. ",9"]
    if d then return g, g .. ",9" end
  end
  if (vhold or ctrl_hold) and edit_group then return edit_group, nil end
  if (vhold or ctrl_hold) and S.sel_group > 0 then return S.sel_group, nil end
end
function VL.held_group() return (held_group()) end

local function membership_pnt(looper, g)
  return { get = function() return S.group_of[looper] == g end,
           set = function(v)
             if v then VL.assign_group(looper, g) elseif S.group_of[looper] == g then VL.assign_group(looper, 0) end
           end }
end

-- pads qu'on peut "maintenir" (utile pour la souris : bouton HOLD) : GROUP 1-4 et cellules de matrice
function VL.is_holdable(row, col)
  local b = BIND[S.page][row .. "," .. col]
  return b ~= nil and (b.short.paint ~= nil or (col == 9 and row >= 1 and row <= NGROUP))
end

local function paint_apply(key, pnt)
  if paint and pnt and not paint.visited[key] then
    paint.visited[key] = true
    pnt.set(paint.value)
  end
end

local function end_paint()
  local p = paint
  paint = nil
  if p.dirty_routing then VL.hooks.routing_changed(VL.routing_edges()) end
  if p.dirty_groups then VL.hooks.groups_changed(S.group_of) end
  if p.dirty_fx then VL.hooks.fx_changed(VL.fx_list()) end
end

function VL.on_pad_pressed(row, col, t)
  local key = row .. "," .. col
  local b = BIND[S.page][key]
  if not b then return end
  local pnt = b.short.paint
  if row == 0 then                                    -- un GROUP n est maintenu : la rangee du haut edite ses membres
    local g, gkey = held_group()
    if g then pnt = membership_pnt(col, g); if gkey then down[gkey].consumed = true end end
  end
  if pnt then                                         -- cellule de matrice / looper-membre : geste de peinture
    if paint and paint.page == S.page then
      paint_apply(key, pnt)                           -- pad presse pendant qu'un autre est maintenu
    elseif not paint then
      paint = { page = S.page, value = not pnt.get(), visited = { [key] = true }, first = key }
      pnt.set(paint.value)
    end
    down[key] = { b = b, paint = true, short_done = true }
  else
    down[key] = { t = t or now(), b = b, short_done = false, long_fired = false }
    if (not b.long and not b.defer) or b.instant then dispatch(b.short); down[key].short_done = true end
  end
  VL.sync_out()
end

-- le pointeur (bouton enfonce) entre sur un autre pad pendant un geste de peinture
function VL.on_pad_dragged(row, col)
  if not paint or paint.page ~= S.page then return end
  local key = row .. "," .. col
  local b = BIND[S.page][key]
  local pnt = b and b.short.paint
  if row == 0 then
    local g = held_group()
    if g then pnt = membership_pnt(col, g) end
  end
  paint_apply(key, pnt)
  VL.sync_out()
end

function VL.on_pad_released(row, col, t)
  local key = row .. "," .. col
  local d = down[key]
  down[key] = nil
  if not d then return end
  if d.paint then
    if paint and paint.first == key then end_paint() end
  elseif not d.short_done and not d.long_fired and not d.consumed then
    dispatch(d.b.short)
  end
  VL.sync_out()
end

function VL.tick(t)
  t = t or now()
  local fired = false
  for _, d in pairs(down) do
    if d.b.long and not d.paint and not d.long_fired and (t - d.t) >= LONG_PRESS_S then
      d.long_fired = true
      dispatch(d.b.long)
      fired = true
    end
  end
  if fired then VL.sync_out() end
end

--------------------------------------------------------------------------
-- Fenetre d'un looper (appui long sur la rangee du haut)
-- Une piste porte le looper i si elle s'appelle "L<i>" (L1, L1 drums, Looper 1...) et contient un JSFX nowundo ;
-- a defaut, on prend la i-eme piste (dans l'ordre du projet) qui porte un JSFX nowundo.
--------------------------------------------------------------------------
local function track_looper_index(name)
  local n = (name or ""):lower()
  return tonumber(n:match("^l(%d+)$") or n:match("^l(%d+)[^%d]") or n:match("^looper%s*(%d+)"))
end

local function find_nowundo_fx(tr)
  for fx = 0, reaper.TrackFX_GetFXCount(tr) - 1 do
    local _, nm = reaper.TrackFX_GetFXName(tr, fx, "")
    nm = (nm or ""):lower()
    for _, pat in ipairs(VL.config.fx_patterns) do
      if nm:find(pat, 1, true) then return fx end
    end
  end
end

VL.hooks.find_looper_fx = function(i)
  local all, named_any = {}, false
  for t = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, t)
    local fx = find_nowundo_fx(tr)
    if fx then
      local _, name = reaper.GetTrackName(tr)
      local idx = track_looper_index(name)
      if idx then named_any = true end
      if idx == i then return tr, fx end
      all[#all + 1] = { tr, fx }
    end
  end
  if not named_any and all[i] then return all[i][1], all[i][2] end   -- aucune piste nommee L<n> : ordre des pistes
end

function VL.toggle_looper_window(i)
  if not (reaper and reaper.CountTracks) then log("warn", "looper %d : pas de REAPER", i) return false end
  local tr, fx = VL.hooks.find_looper_fx(i)
  if not tr then log("warn", "looper %d : piste/JSFX nowundo introuvable (nommer la piste L%d)", i, i) return false end
  local is_open = reaper.TrackFX_GetFloatingWindow(tr, fx) ~= nil
  reaper.TrackFX_Show(tr, fx, is_open and 2 or 3)        -- 3 = fenetre flottante, 2 = la fermer
  log("info", "looper %d : fenetre %s", i, is_open and "fermee" or "ouverte")
  return true
end

--------------------------------------------------------------------------
-- Synchronisation entre plusieurs fenetres (plusieurs instances du script)
-- Tout l'etat est partage (selection, groupes, routing, presets, launch...) SAUF la page affichee,
-- propre a chaque fenetre. Les actions envoyees aux loopers ne partent que de la fenetre ou l'on appuie.
--------------------------------------------------------------------------
local SYNC = { enabled = false, section = "nowundo_vl", rev = nil, last = "", id = "", n = 0 }

local function sorted_keys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return ta < tb end
    return a < b
  end)
  return keys
end

local function ser(v)
  local tv = type(v)
  if tv == "number" then return math.type(v) == "integer" and tostring(v) or string.format("%.17g", v)
  elseif tv == "boolean" then return tostring(v)
  elseif tv == "string" then return string.format("%q", v)
  elseif tv == "table" then
    local parts = {}
    for _, k in ipairs(sorted_keys(v)) do parts[#parts + 1] = "[" .. ser(k) .. "]=" .. ser(v[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "nil"
end

local function snapshot()
  local snap = { _v = VL.VERSION }
  for k, v in pairs(S) do if k ~= "page" then snap[k] = v end end
  return ser(snap)
end

function VL.sync_out(force)
  if not SYNC.enabled then return end
  -- Publier la page active uniquement depuis le controleur (pas depuis le miroir)
  if not VL.mirror_mode then
    reaper.SetExtState(SYNC.section, "active_page", tostring(S.page), false)
  end
  local snap = snapshot()
  if snap == SYNC.last and not force then return end
  SYNC.last = snap
  SYNC.n = SYNC.n + 1
  SYNC.rev = SYNC.id .. ":" .. SYNC.n
  reaper.SetExtState(SYNC.section, "state", snap, false)
  reaper.SetExtState(SYNC.section, "rev", SYNC.rev, false)
end

-- a appeler a chaque cycle : applique l'etat ecrit par une autre fenetre (renvoie true si charge)
function VL.sync_poll(force)
  if not SYNC.enabled then return false end
  local rev = reaper.GetExtState(SYNC.section, "rev")
  if rev == "" or (rev == SYNC.rev and not force) then return false end
  local f = load("return " .. reaper.GetExtState(SYNC.section, "state"), "vl_state", "t", {})
  if not f then return false end
  local ok, t = pcall(f)
  if not ok or type(t) ~= "table" or t._v ~= VL.VERSION then return false end
  t._v = nil
  for k, v in pairs(t) do S[k] = v end
  SYNC.rev = rev
  SYNC.last = snapshot()
  return true
end

function VL.sync_disable() SYNC.enabled = false end

function VL.sync_enable()
  math.randomseed(math.floor(now() * 1000000) % 2147483647)
  SYNC.id = string.format("%06x", math.random(0, 0xFFFFFF))
  SYNC.enabled = true
  if reaper.GetExtState(SYNC.section, "rev") ~= "" and VL.sync_poll(true) then
    log("info", "etat charge depuis une autre fenetre")
  else
    VL.sync_out(true)
  end
end

--------------------------------------------------------------------------
-- Feedback nowundo -> etat miroir (phase 2)
--------------------------------------------------------------------------
function VL.update_looper_state(i, patch)
  for k, v in pairs(patch) do S.loopers[i][k] = v end
end

--------------------------------------------------------------------------
-- Rendu LED : l'etat decide, le profil hardware n'a qu'a afficher
--------------------------------------------------------------------------
local function armed_mode(action, args)
  local cur = armed_key(action, args, VL.targets())
  local other = false
  for _, a in ipairs(S.armed) do
    if a.action == action and a.args == args then
      if a.key == cur then return "armed" end
      other = true
    end
  end
  return other and "armed_other" or nil
end

-- cellule de matrice : fermee = idle, ouverte = on, ouverte dans une boucle de feedback = warn
local function cell_led(open, isfb, base)
  if not open then return base, "idle" end
  if isfb then return COL.feedback, "warn" end
  return base, "on"
end

-- etat LED d'un pad de la page Main (toggle allume, action armee, selecteur...) : aussi utilise par la couche Groups
main_state = function(b)
  local targets = VL.targets()
  local ref = S.loopers[ref_looper(targets)]
  local sh, mode = b.short, "idle"
  if sh.kind == "action" then
    local def = ACTIONS[sh.action]
    if def.kind == "toggle" and toggle_on(def.key, targets) then mode = "on"
    elseif def.kind == "select" and ref[def.key] == sh.args then mode = "on" end
    mode = armed_mode(sh.action, sh.args) or mode
  elseif sh.led then mode = sh.led() end
  return mode
end

function VL.build_frame()
  local f, page = {}, S.page
  for row = 0, 8 do for col = 1, 9 do
    if not (row == 0 and col == 9) then f[row .. "," .. col] = { 0, "off" } end
  end end
  local function put(row, col, hex, mode) f[row .. "," .. col] = { hex or COL.default, mode } end
  local rgb = PAD_RGB[page]

  -- global : top row / groupes / pages
  -- Rangee du haut :
  --   edition des membres (maintien)  : membres verts, les autres attenues
  --   groupe actif et non vide        : membres verts ; looper selectionne = "cursor" (non membre) ou
  --                                     "member_cursor" (membre, clignote) ; les autres attenues
  --   sinon                           : looper selectionne allume
  local hg = held_group()
  local ag = (S.sel_group > 0 and #VL.group_members(S.sel_group) > 0) and S.sel_group or nil
  for i = 1, NLOOP do
    local g = S.group_of[i]
    local base = (g > 0) and GROUP_COL[g] or rgb["0," .. i] or COL.looper   -- looper groupe : couleur de son groupe
    local sel = S.sel_looper == i
    if hg then
      put(0, i, base, (g == hg) and "on" or "idle")                     -- edition : membres du groupe edite en vif
    elseif ag then
      if g == ag then put(0, i, base, sel and "member_cursor" or "on")  -- groupe actif : membres en surbrillance
      else put(0, i, base, sel and "cursor" or "idle") end
    else
      put(0, i, base, sel and "on" or "idle")                           -- aucun groupe actif : membres attenues
    end
  end
  for g = 1, NGROUP do put(g, 9, GROUP_COL[g], ((hg or S.sel_group) == g) and "on" or "idle") end
  for p = 1, NPAGE do put(NGROUP + p, 9, rgb[(NGROUP + p) .. ",9"] or COL.page, S.page == p and "on" or "idle") end

  if page == 1 then
    for key, b in pairs(BIND[1]) do
      local row, col = key:match("^(%d+),(%d+)$"); row, col = tonumber(row), tonumber(col)
      if row >= 1 and col <= 8 then put(row, col, rgb[key] or COL.default, main_state(b)) end
    end
  else
    local fb = compute_feedback()
    for row = 1, 8 do for col = 1, 8 do
      local base = rgb[row .. "," .. col] or COL.default
      if page == 2 then
        if row <= NIN then
          put(row, col, cell_led(S.routing.in_l[row][col], fb["in_l:" .. row .. ":" .. col], base))
        else put(row, col, base, "off") end
      elseif page == 3 then
        if row == col then put(row, col, base, "off")
        else put(row, col, cell_led(S.routing.l_l[col][row], fb["l_l:" .. col .. ":" .. row], base)) end
      else                                                         -- page 4 : couche courante
        local spec = cur_layer().cells[row .. "," .. col]
        if spec then put(row, col, spec.hex, spec.state()) else put(row, col, base, "off") end
      end
    end end
  end
  return f
end

--------------------------------------------------------------------------
-- Profils hardware : traduisent un etat semantique en ce que l'appareil sait afficher
--
--   etat          sens                                      RGB            3 couleurs (defaut)
--   off           pad inutilise / desactive                 noir           eteint
--   idle          disponible, inactif                       famille x 45%  rouge fixe  (ou eteint : idle = "off")
--   on            actif / selectionne / ouvert              famille x 100% vert fixe
--   warn          cellule ouverte dans une boucle feedback  orange         orange fixe
--   armed         action armee (Launch)                     clignote       orange clignotant
--   armed_other   armee pour d'autres cibles                clignote doux  orange fixe
--   cursor        looper selectionne, hors du groupe actif  famille 100%   orange fixe
--   member_cursor looper selectionne ET membre du groupe    vert clignote  vert clignotant
--   (un looper membre du groupe actif, non selectionne, est simplement "on" en vert)
--
-- Sur du materiel a 3 couleurs la luminosite n'existe pas : "idle" devient une couleur (ou rien),
-- et la teinte de famille (looper jaune, groupe vert...) est perdue : seul l'etat est conserve.
--------------------------------------------------------------------------
VL.profiles = {}

-- RGB complet (fenetre de test, Launchpad RGB...) : set_rgb(row, col, r, g, b)
function VL.profiles.rgb(set_rgb)
  return { caps = { native_blink = false },
    set_led = function(row, col, led)
      local r, g, b = hex_to_rgb(led.hex)
      local k = led.level
      set_rgb(row, col, math.floor(r * k + 0.5), math.floor(g * k + 0.5), math.floor(b * k + 0.5))
    end }
end

-- Palette fixe indexee (ex. Launchpad MK2) : palette = { {r, g, b, index}, ... } ; set_index(row, col, index)
-- opts.off_index (defaut 0). Un etat allume ne tombe jamais sur le noir : on prend la couleur allumee la plus proche.
function VL.profiles.palette(palette, set_index, opts)
  opts = opts or {}
  local off = opts.off_index or 0
  return { caps = { native_blink = opts.native_blink or false },
    set_led = function(row, col, led)
      if led.state == "off" or led.level <= 0 then set_index(row, col, off) return end
      local r, g, b = hex_to_rgb(led.hex)
      local lr, lg, lb = r * led.level, g * led.level, b * led.level
      local best, bd
      for _, e in ipairs(palette) do
        if e[1] + e[2] + e[3] > 0 then
          local d = (e[1] - lr) ^ 2 + (e[2] - lg) ^ 2 + (e[3] - lb) ^ 2
          if not bd or d < bd then best, bd = e[4], d end
        end
      end
      set_index(row, col, best)
    end }
end

-- 3 couleurs + clignotement (ex. QuNeo) : set(row, col, color, blink) avec color = "off"|"green"|"red"|"orange"
-- opts.idle = "off" : les pads inactifs restent eteints (sinon rouge fixe)
-- opts.map = { etat = { couleur, clignote } } : surcharge de la table ci-dessus
-- opts.native_blink = false : le materiel ne sait pas clignoter, le coeur envoie alors les phases
function VL.profiles.tricolor(set, opts)
  opts = opts or {}
  local map = {
    off         = { "off", false },
    idle        = { opts.idle == "off" and "off" or "red", false },
    on          = { "green", false },
    warn        = { "orange", false },
    armed       = { "orange", true },
    armed_other = { "orange", false },
    cursor      = { "orange", false },
    member_cursor = { "green", true },
  }
  if opts.map then for k, v in pairs(opts.map) do map[k] = v end end
  local native = opts.native_blink ~= false
  return { caps = { native_blink = native },
    set_led = function(row, col, led)
      local m = map[led.state] or map.off
      if not native and led.blinking and led.level <= 0.5 then set(row, col, "off", false) return end   -- phase eteinte
      set(row, col, m[1], native and m[2] or false)
    end }
end

local LEVEL = { off = 0.0, idle = 0.45, on = 1.0, warn = 1.0, cursor = 1.0 }   -- idle releve : etats inactifs lisibles (RGB)
-- etats clignotants : { niveau phase allumee, niveau phase eteinte }
local BLINK = { armed = { 1.0, 0.0 }, armed_other = { 0.8, 0.45 }, member_cursor = { 1.0, 0.45 } }

-- accepte un profil semantique (set_led) ou un profil RGB "historique" (set_pad(row, col, r, g, b))
function VL.attach_profile(profile)
  if not profile.set_led and profile.set_pad then profile = VL.profiles.rgb(profile.set_pad) end
  VL.profile = profile
  VL.last = {}
end

-- a appeler a chaque cycle (defer) ; n'envoie au profil que les pads dont l'affichage change
--------------------------------------------------------------------------
-- Publication vers le dashboard NowUndo (gmem "nowundo_sync")
-- Plage 6000+ (au-dela des blocs instances 1000..5800). Index = numero de looper 1..8 :
--   [BASE + i]      groupe du looper i (0 = aucun, 1..4)
--   [BASE + 10 + i] masque binaire des INPUTS qui entrent dans i  (bit k-1 = IN k)
--   [BASE + 20 + i] masque binaire des LOOPERS qui entrent dans i (bit a-1 = L a)
-- Meme constante (dash_base) a reporter dans le JSFX dashboard.
--------------------------------------------------------------------------
local DASH = { base = 6000, last_sig = "", last_t = -1e9 }
function VL.dash_publish(force, t)
  if not (reaper and reaper.gmem_attach and reaper.gmem_write) then return end
  t = t or now()
  local gm, im, lm = {}, {}, {}
  for i = 1, NLOOP do
    gm[i] = S.group_of[i] or 0
    local m = 0
    for k = 1, NIN do if S.routing.in_l[k][i] then m = m | (1 << (k - 1)) end end
    im[i] = m
    local l = 0
    for a = 1, NLOOP do if a ~= i and S.routing.l_l[a][i] then l = l | (1 << (a - 1)) end end
    lm[i] = l
  end
  local sig = table.concat(gm, ",") .. "|" .. table.concat(im, ",") .. "|" .. table.concat(lm, ",")
  if not force and sig == DASH.last_sig and (t - DASH.last_t) < 1.0 then return end   -- changement, ou rafraichissement 1 Hz
  DASH.last_sig, DASH.last_t = sig, t
  reaper.gmem_attach("nowundo_sync")
  for i = 1, NLOOP do
    reaper.gmem_write(DASH.base + i, gm[i])
    reaper.gmem_write(DASH.base + 10 + i, im[i])
    reaper.gmem_write(DASH.base + 20 + i, lm[i])
  end
end

function VL.render(t)
  t = t or now()
  VL.dash_publish(false, t)
  -- Garder active_page a jour pour le miroir (chaque frame, cout negligeable)
  if SYNC.enabled and not VL.mirror_mode and reaper and reaper.SetExtState then
    reaper.SetExtState(SYNC.section, "active_page", tostring(S.page), false)
  end
  local P = VL.profile
  if not P then return end
  local phase = (math.floor(t * BLINK_HZ * 2) % 2 == 0)
  local native = P.caps and P.caps.native_blink
  for key, v in pairs(VL.build_frame()) do
    local hex, state = v[1], v[2]
    local level, blinking = LEVEL[state], false
    local bl = BLINK[state]
    if bl then blinking = true; level = (native or phase) and bl[1] or bl[2] end
    local sig = state .. ":" .. hex .. ":" .. string.format("%.2f", level)
    if VL.last[key] ~= sig then
      VL.last[key] = sig
      local row, col = key:match("^(%d+),(%d+)$")
      P.set_led(tonumber(row), tonumber(col), { state = state, hex = hex, level = level, blinking = blinking })
    end
  end
end

--------------------------------------------------------------------------
-- Debug : une ligne d'etat + fenetre de test (pads cliquables, sans hardware)
--------------------------------------------------------------------------
function VL.status()
  local arm = {}
  for _, a in ipairs(S.armed) do arm[#arm + 1] = a.key end
  local hg = held_group()
  return string.format("page %d | looper %d | group %d | launch %s | armed [%s] | fighter p%d%s",
    S.page, S.sel_looper, S.sel_group, S.launch and "ON" or "off", table.concat(arm, " ; "), S.fighter_page,
    hg and (" | EDIT GROUP " .. hg) or "") .. (S.page == 4 and (" | layer " .. cur_layer().name) or "")
end

-- ===== NowUndo : persistance du dock / position (ajout) =====
NDDOCK = {}
function NDDOCK.init(title, ext, dw, dh)
  local function ld(k, d) return tonumber(reaper.GetExtState(ext, k)) or d end
  NDDOCK.ext, NDDOCK.last_t, NDDOCK.sig = ext, 0, ""
  local w, h = ld("w", dw), ld("h", dh)
  if w < 100 then w = dw end
  if h < 60 then h = dh end
  gfx.init(title, w, h, ld("dock", 0), ld("x", 100), ld("y", 100))
end
function NDDOCK.tick()
  local t = reaper.time_precise()
  if t - NDDOCK.last_t < 1 then return end
  NDDOCK.last_t = t
  local d, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
  d = math.floor(d or 0)
  local sig = d .. "," .. x .. "," .. y .. "," .. w .. "," .. h
  if sig == NDDOCK.sig then return end
  NDDOCK.sig = sig
  local e = NDDOCK.ext
  reaper.SetExtState(e, "dock", tostring(d), true)
  if d & 1 == 0 then   -- flottante : on retient position + taille
    reaper.SetExtState(e, "x", tostring(math.floor(x)), true)
    reaper.SetExtState(e, "y", tostring(math.floor(y)), true)
    reaper.SetExtState(e, "w", tostring(math.floor(w)), true)
    reaper.SetExtState(e, "h", tostring(math.floor(h)), true)
  end
end
-- ===== fin ajout =====

function VL.run_gfx_test()
  -- Taille de référence (design)
  local REF_CELL = 56
  local REF_OX   = 12
  local REF_OY   = 36
  local REF_W    = REF_OX * 2 + REF_CELL * 9
  local REF_H    = REF_OY + REF_CELL * 9 + 48

  local pads, down_pad, last_pad = {}, nil, nil
  local OS = (reaper.GetOS and reaper.GetOS()) or ""
  local CTRL_MASK = 4 | (OS:find("OSX") and 32 or 0)   -- 4 = Ctrl (Win) / Cmd (Mac) ; 32 = Ctrl (Mac)
  local sticky_on, sticky_pad, was_pressed = false, nil, false

  VL.attach_profile({ set_pad = function(row, col, r, g, b) pads[row .. "," .. col] = { r, g, b } end })
  VL.sync_enable()
  NDDOCK.init("nowundo - Virtual Launchpad", "NowUndo_VL", REF_W, REF_H)

  -- Calcule le scale + positions à chaque frame
  local function layout()
    local w, h = gfx.w, gfx.h
    local sx = w / REF_W
    local sy = h / REF_H
    local s  = math.min(sx, sy)          -- garde les proportions
    s = math.max(0.55, math.min(s, 2.2)) -- limites raisonnables

    local CELL = REF_CELL * s
    local OX   = (w - CELL * 9) * 0.5    -- centré horizontalement
    local OY   = 32 * s

    local HOLD = {
      x = OX + CELL * 9 - 110 * s,
      y = 6 * s,
      w = 104 * s,
      h = 22 * s
    }
    local LAYERBTN = {
      x = HOLD.x - 190 * s,
      y = 6 * s,
      w = 180 * s,
      h = 22 * s
    }

    return s, CELL, OX, OY, HOLD, LAYERBTN
  end

  local function pad_at(mx, my, CELL, OX, OY)
    local col = math.floor((mx - OX) / CELL) + 1
    local row = math.floor((my - OY) / CELL)
    if col < 1 or col > 9 or row < 0 or row > 8 or (row == 0 and col == 9) then
      return nil
    end
    return row, col
  end

  -- Découpe le libellé pour qu'il tienne dans le pad
  local function layout_label(label, maxw, base_size)
    for _, size in ipairs({ base_size, base_size - 2, base_size - 3, 8 }) do
      if size < 8 then size = 8 end
      gfx.setfont(1, "Arial", size)
      local lines, cur, fits = {}, "", true
      for word in label:gmatch("%S+") do
        local first = true
        for part in word:gmatch("[^/]+/?") do
          local sep = first and " " or ""
          local try = (cur == "") and part or (cur .. sep .. part)
          if cur == "" or gfx.measurestr(try) <= maxw then
            cur = try
          else
            lines[#lines + 1] = cur
            cur = part
          end
          first = false
        end
      end
      if cur ~= "" then lines[#lines + 1] = cur end
      for _, l in ipairs(lines) do
        if gfx.measurestr(l) > maxw then fits = false end
      end
      if fits or size <= 9 then return lines, size end
    end
    return { label }, 8
  end

  local function loop()
    local t = now()
    local ch = gfx.getchar()
    if ch == -1 or ch == 27 then gfx.quit() return end
    NDDOCK.tick()

    local s, CELL, OX, OY, HOLD, LAYERBTN = layout()

    VL.tick(t)
    local cap = math.floor(gfx.mouse_cap)
    VL.set_ctrl_hold((cap & CTRL_MASK) ~= 0)          -- Ctrl (Cmd sur Mac) maintenu = HOLD du groupe actif
    local pressed = (cap & 1) == 1
    local edge_down = pressed and not was_pressed
    local edge_up   = (not pressed) and was_pressed
    was_pressed = pressed
    VL.sync_poll()

    if edge_down then
      local mx, my = gfx.mouse_x, gfx.mouse_y
      if S.page == 4 and mx >= LAYERBTN.x and mx <= LAYERBTN.x + LAYERBTN.w
                    and my >= LAYERBTN.y and my <= LAYERBTN.y + LAYERBTN.h then
        local menu, ids = {}, {}
        for i, l in ipairs(VL.layers()) do
          ids[i] = l.id
          menu[i] = (l.id == S.p4_layer and "!" or "") .. l.name
        end
        gfx.x, gfx.y = LAYERBTN.x, LAYERBTN.y + LAYERBTN.h
        local pick = gfx.showmenu(table.concat(menu, "|"))
        if pick and pick > 0 then VL.set_layer(ids[pick]) end

      elseif mx >= HOLD.x and mx <= HOLD.x + HOLD.w
         and my >= HOLD.y and my <= HOLD.y + HOLD.h then
        sticky_on = not sticky_on
        VL.set_virtual_hold(sticky_on)
        if not sticky_on and sticky_pad then
          VL.on_pad_released(sticky_pad[1], sticky_pad[2], t)
          sticky_pad = nil
        end
      else
        local r, c = pad_at(mx, my, CELL, OX, OY)
        if r and sticky_pad and sticky_pad[1] == r and sticky_pad[2] == c then
          VL.on_pad_released(r, c, t)
          sticky_pad = nil
        elseif r then
          down_pad = { r, c }
          last_pad = { r, c }
          VL.on_pad_pressed(r, c, t)
        end
      end

    elseif pressed and down_pad then
      local r, c = pad_at(gfx.mouse_x, gfx.mouse_y, CELL, OX, OY)
      if r and (r ~= last_pad[1] or c ~= last_pad[2]) then
        last_pad = { r, c }
        VL.on_pad_dragged(r, c)
      end

    elseif edge_up and down_pad then
      local r, c = down_pad[1], down_pad[2]
      if sticky_on and not sticky_pad and S.sel_group == 0 and VL.is_holdable(r, c)
         and not (c == 9 and r >= 1 and r <= 4) then
        sticky_pad = { r, c }
      else
        VL.on_pad_released(r, c, t)
      end
      down_pad = nil
      last_pad = nil
    end

    VL.render(t)

    -- Fond
    gfx.set(0.07, 0.07, 0.07, 1)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)

    -- Pads
    for row = 0, 8 do
      for col = 1, 9 do
        local c = pads[row .. "," .. col]
        if c then
          local x = OX + (col - 1) * CELL
          local y = OY + row * CELL
          local pad_s = 3 * s          -- marge intérieure
          gfx.set(c[1] / 255, c[2] / 255, c[3] / 255, 1)
          gfx.rect(x + pad_s, y + pad_s, CELL - pad_s * 2, CELL - pad_s * 2, 1)

          local label = VL.pad_label(S.page, row, col)
          if label then
            local lum = (0.299 * c[1] + 0.587 * c[2] + 0.114 * c[3]) / 255
            if lum > 0.5 then gfx.set(0.05, 0.05, 0.05, 1)
            else gfx.set(0.97, 0.97, 0.97, 1) end

            local maxw = CELL - 8 * s
            local base_size = math.floor(11 * s + 0.5)
            local lines, size = layout_label(label, maxw, base_size)
            local lh = size + 2 * s
            local y0 = y + (CELL - #lines * lh) / 2
            for i, l in ipairs(lines) do
              gfx.x = x + (CELL - gfx.measurestr(l)) / 2
              gfx.y = y0 + (i - 1) * lh
              gfx.drawstr(l)
            end
          end
        end
      end
    end

    -- Barre de statut
    gfx.setfont(1, "Arial", math.floor(11 * s))
    gfx.set(0.9, 0.9, 0.9, 1)
    gfx.x, gfx.y = OX, 8 * s
    gfx.drawstr(VL.status())

    -- Bouton Layer (page 4)
    if S.page == 4 then
      gfx.set(0.28, 0.28, 0.28, 1)
      gfx.rect(LAYERBTN.x, LAYERBTN.y, LAYERBTN.w, LAYERBTN.h, 1)
      gfx.set(0.9, 0.9, 0.9, 1)
      gfx.setfont(1, "Arial", math.floor(11 * s))
      local ltxt = "Layer: " .. cur_layer().name .. "  v"
      gfx.x = LAYERBTN.x + 8 * s
      gfx.y = LAYERBTN.y + 4 * s
      gfx.drawstr(ltxt)
    end

    -- Bouton HOLD
    if sticky_on then gfx.set(0.25, 0.85, 0.35, 1)
    else gfx.set(0.28, 0.28, 0.28, 1) end
    gfx.rect(HOLD.x, HOLD.y, HOLD.w, HOLD.h, 1)

    if sticky_on then gfx.set(0.05, 0.05, 0.05, 1)
    else gfx.set(0.9, 0.9, 0.9, 1) end
    gfx.setfont(1, "Arial", math.floor(11 * s))
    local label = "HOLD"
    if sticky_on then
      local eg = VL.held_group()
      if eg then label = "HOLD  GROUP " .. eg
      elseif sticky_pad then label = "HOLD  (held)"
      else label = "HOLD  pick GROUP" end
    end
    local lw = gfx.measurestr(label)
    gfx.x = HOLD.x + (HOLD.w - lw) / 2
    gfx.y = HOLD.y + 4 * s
    gfx.drawstr(label)

    -- Log + aide
    gfx.set(0.85, 0.85, 0.85, 1)
    gfx.setfont(1, "Arial", math.floor(10 * s))
    gfx.x = OX
    gfx.y = OY + CELL * 9 + 6 * s
    gfx.drawstr(LOG.ring[#LOG.ring] or "")

    if VL.ctrl_held() and not sticky_on then
      gfx.x = OX
      gfx.y = OY + CELL * 9 + 20 * s
      local eg = VL.held_group()
      if eg then
        gfx.drawstr("CTRL - EDIT GROUP " .. eg .. " : click loopers (top) to add/remove - click a GROUP pad to switch")
      else
        gfx.drawstr("CTRL : click a GROUP pad, then click loopers (top) to add/remove")
      end
    elseif sticky_on then
      gfx.x = OX
      gfx.y = OY + CELL * 9 + 20 * s
      local eg = VL.held_group()
      if eg then
        gfx.drawstr("EDIT GROUP " .. eg .. " : click loopers (top) to add/remove - click a GROUP pad to switch - HOLD again to exit")
      else
        gfx.drawstr("HOLD : click a GROUP pad (even empty), then click loopers (top) to add/remove")
      end
    end

    gfx.update()
    reaper.defer(loop)
  end

  loop()
end

--------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------
function VL.reset()
  S = new_state()
  VL.S = S
  init_presets()
  VL.last = {}
  for k in pairs(down) do down[k] = nil end
  log("info", "Virtual Launchpad %s initialise", VL.VERSION)
end
VL.reset()

if rawget(_G, "VL_TEST") then return VL end
VL.run_gfx_test()