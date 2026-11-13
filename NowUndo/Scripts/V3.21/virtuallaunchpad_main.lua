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
              rc505  : une colonne par looper, de BAS en HAUT : Rec, Clear, Replace, Restart (gate : appui + relachement), Rev, Ping-pong, Slicer, Cloud
              macros : 64 macros d'action creees dans NowUndo_Scenario (onglet MACROS), appliquees au looper / groupe selectionne
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
            Chord Yamaha (rangee du haut) : maintenir un looper (affectateur) puis appuyer sur d'autres —
              * affectateur deja groupe -> les cibles rejoignent ce groupe (re-appui = retrait)
              * affectateur libre -> premier groupe vide ; les deux y sont places (aucun groupe libre = no-op)

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
VL.VERSION = "0.9.0"            -- NE PAS CHANGER : le miroir / la remote web refusent l'etat synchronise si la version differe
VL.BUILD = "0.9.24-op-mute-parent+macros+RGES" -- operationnel + mute AUTOMUTE + parent bleu (depuis 0.9.20)
VL.debug = false                  -- true : messages de diagnostic dans la console REAPER
VL._held_loopers = {}             -- [looper]=t_appui ; chord Yamaha (rangee du haut)
local function dbg(fmt, ...)
  if VL.debug and reaper and reaper.ShowConsoleMsg then reaper.ShowConsoleMsg("[VL] " .. string.format(fmt, ...) .. "\n") end
end
-- (plus de message de demarrage dans la console : la console ne s'ouvre plus au lancement ; VL.debug = true pour la diagnostic)
VL.page_key = "active_page"
VL.heartbeat_key = "heartbeat"
VL.LOADED_FROM = tostring(debug.getinfo(1, "S").source)
dbg("build %s charge depuis : %s", VL.BUILD, VL.LOADED_FROM)

-- Fonctions internes rangees dans une table : le chunk principal etait a la limite Lua de 200 variables locales
-- (199). Meme comportement ; chaque fonction ici libere une place pour de futures evolutions.
local LPF = {}
local NLOOP, NGROUP, NPAGE, NIN, NSLOT, NPRESET = 8, 4, 4, 8, 4, 8   -- NIN : nombre d'inputs (8, ou 4 pour une grille reduite)
local DOUBLE_S = 0.40       -- double clic (CLEAR : double clic = tout effacer)
local LONG_PRESS_S = 1.0     -- appui long (REVERSE/AUTO REV, revert preset ; pas CLEAR/RESET)
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
-- Page 1 : inserer la ligne statut sous la selection (row 1) et decaler l'ancienne grille 1-4 -> 2-5
do
  local function shift_row_map(map)
    local moved = {}
    for key, val in pairs(map) do
      local r, c = key:match("^(%d+),(%d+)$")
      r, c = tonumber(r), tonumber(c)
      if r and r >= 1 and r <= 4 and c >= 1 and c <= 8 then
        moved[(r + 1) .. "," .. c] = val
        map[key] = nil
      end
    end
    for k, v in pairs(moved) do map[k] = v end
  end
  shift_row_map(PAD_LABEL[1])
  shift_row_map(PAD_RGB[1])
  -- Ordre : 2 = selection Twister | 3 = presets routing | 4 = presets groupe | 5 = Launch/Sync/Quantise/Full loop (+ slots FX)
  local function permute_rows(map)
    local to = {}                      -- identite : les presets sont remontes, le Launch descend en ligne 5
    local moved = {}
    for key, val in pairs(map) do
      local r, c = key:match("^(%d+),(%d+)$")
      r, c = tonumber(r), tonumber(c)
      if r and to[r] and c >= 1 and c <= 8 then
        moved[to[r] .. "," .. c] = val
        map[key] = nil
      end
    end
    for k, v in pairs(moved) do map[k] = v end
  end
  permute_rows(PAD_LABEL[1])
  permute_rows(PAD_RGB[1])
  for i = 1, 8 do
    PAD_LABEL[1]["1," .. i] = "L" .. i .. " STATUS"
    PAD_RGB[1]["1," .. i] = 0x444444
  end
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

local LOG = { level = 3, console = false, ring = {}, max = 300 }
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
    sel_input = 1,                  -- derniere entree touchee sur la matrice page 2
    fx_source = NIN + 1,            -- source FX active : 1..NIN = entree, NIN+1.. = looper
    sel_group = 0,                  -- 0..4, 0 = aucun groupe
    exclusive = false,              -- mode EXCLU : un seul groupe joue ; changement au synchro point commun
    super = false,                  -- SUPER EXCLU (appui long) : les loopers seuls se comportent comme des groupes
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
    cfg = {
      feedback_policy = "attenuate", feedback_gain_db = -6,   -- "allow" | "attenuate" | "block"
      auto_mute_unrouted_inputs = true,                       -- IN sans aucun send actif vers un looper => piste silencieuse
      -- Index 1-based REAPER (ta structure) : dossier IN=1, IN1..8=2..9, dossier L=10, L1..8=11..18
      in_track_first = 2,
      looper_track_first = 11,
    },
  }
  for i = 1, NLOOP do
    s.group_of[i] = 0
    s.loopers[i] = { playing = false, rev = false, oneshot = false, cloud = false, slicer = false,
                     link = false, rec = false, rec_led = false, overdub = false, wait_sync = false, wait_start = false, state = 0,
                     replace = false, multiply = false, auto = false, pingpong = false, part = 1, pending_part = false, target_part = 1 }
  end
  return s
end

--------------------------------------------------------------------------
-- Hooks / backend (phase 2 les remplacera)
--------------------------------------------------------------------------
-- Mapping actions -> commandes gmem NowUndo (options:gmem=nowundo_sync)
-- Layout par instance (looper 1..8) / part (0=Main,1=Chorus,2=Bridge) :
--   base = 1000 + (looper-1)*600 + part*200
--   base+48 = cmd (ecrit par le controleur, lu puis remis a 0 par le JSFX)
--   base+49 = arg numerique optionnel (speed/pitch step)
--   base+160/161/162 = edition In/Out/Width
--   base+180/181 = write param abs (id, value)
-- Feedback (JSFX -> miroir) : base+2=state, +3=speed, +4=pitch, +8=play_mode,
--   +9=link, +17=rev, +18=pingpong, +24=cloud, +43=auto_on, ...
local GMEM_NAME = "nowundo_sync"
-- NowUndo do_clear(0) = part active seulement | do_clear(1) = les 3 parts
-- cmd 2  = clear part active
-- cmd 11 = clear les 3 parts
local CMD = {
  rec_overdub = 1,   clear = 2,  clear_part = 2,   -- court : part active
  clear_full  = 11,                                -- long  : 3 parts (1 looper)
  stop_play = 3,
  reverse = 4,       auto_rev = 5,               slicer = 6,
  cloud = 7,         link = 8,                   replace = 9,
  auto_rep = 10,     part = 12,
  -- clear_all / clear_all_full : broadcast (pas un cmd unique) — voir backend.send
  clear_all = 2,     clear_all_full = 11,          -- court=part partout | long=3 parts partout
  multiply = 13,     undo = 14,                  redo = 15,
  restart = 16,      rerec = 17,                 one_shot = 18,
  auto = 19,         speed_step = 20,            pitch_step = 21,
  full_loop = 22,    quantise_inout = 23,
  reset_params = 24,                           -- RESET : tous les parametres a leur defaut sauf out_vol (JSFX cmd 24)
}

local function gmem_base(looper, part)
  part = part or 1
  return 1000 + (looper - 1) * 600 + (part - 1) * 200
end

local function gmem_write_cmd(looper, cmd, arg, part)
  if not (reaper and reaper.gmem_attach and reaper.gmem_write) then
    log("warn", "gmem indisponible : action %s ignoree", tostring(cmd))
    return false
  end
  local L = S.loopers[looper]
  part = part or (L and L.part) or 1
  local base = gmem_base(looper, part)
  reaper.gmem_attach(GMEM_NAME)
  if arg ~= nil then reaper.gmem_write(base + 49, arg) end
  -- NowUndo V3.22 : heure de l'appui (gmem 950) + cible (951) -> le JSFX cale le REC sur l'appui, pas sur l'arrivee
  reaper.gmem_write(950, VL.press_t or now()); reaper.gmem_write(951, base + 48)
  reaper.gmem_write(base + 48, cmd)   -- ecrit en dernier : le JSFX consomme des que cmd > 0
  return true
end

-- Commandes GLOBALES (comme le Dashboard) : toutes les instances NowUndo vivantes (heartbeat).
-- Utilise pour CLEAR ALL : pas de selection looper/groupe — diffusion a chaque slot actif.
local function gmem_broadcast_cmd(cmd, arg)
  if not (reaper and reaper.gmem_attach and reaper.gmem_write and reaper.gmem_read) then
    log("warn", "gmem indisponible : broadcast %s ignore", tostring(cmd))
    return 0
  end
  reaper.gmem_attach(GMEM_NAME)
  local t = now()
  local n = 0
  for i = 1, NLOOP do
    local alive = reaper.gmem_read(100 + (i - 1)) or 0
    local hb = reaper.gmem_read(130 + (i - 1)) or 0
    if alive > 0 and (t - hb) <= 3.0 then
      local ap = reaper.gmem_read(gmem_base(i, 1) + 42) or 1
      if ap < 1 or ap > 3 then ap = 1 end
      local base = gmem_base(i, math.floor(ap + 0.5))
      if arg ~= nil then reaper.gmem_write(base + 49, arg) end
      reaper.gmem_write(base + 48, cmd)
      n = n + 1
    end
  end
  log("info", "broadcast cmd %s -> %d instance(s)", tostring(cmd), n)
  return n
end

local function gmem_write_param(looper, param_id, value, part)
  if not (reaper and reaper.gmem_attach and reaper.gmem_write) then return false end
  local L = S.loopers[looper]
  part = part or (L and L.part) or 1
  local base = gmem_base(looper, part)
  reaper.gmem_attach(GMEM_NAME)
  reaper.gmem_write(base + 181, value)
  reaper.gmem_write(base + 180, param_id)
  return true
end

local function gmem_write_edit(looper, edit_cmd, v1, v2, part)
  if not (reaper and reaper.gmem_attach and reaper.gmem_write) then return false end
  local L = S.loopers[looper]
  part = part or (L and L.part) or 1
  local base = gmem_base(looper, part)
  reaper.gmem_attach(GMEM_NAME)
  if v1 ~= nil then reaper.gmem_write(base + 161, v1) end
  if v2 ~= nil then reaper.gmem_write(base + 162, v2) end
  reaper.gmem_write(base + 160, edit_cmd)
  return true
end

VL.backend = {
  -- API publique utilisee par exec()
  send = function(looper, action, value)
    log("debug", "send L%d  %s  %s", looper, action, tostring(value))
    -- CLEAR ALL (court) / CLEAR ALL FULL (long) : GLOBAL, ignore selection — comme le Dashboard
    if action == "clear_all" then
      gmem_broadcast_cmd(CMD.clear_all)        -- cmd 2 : part active partout
      return
    end
    if action == "clear_all_full" then
      gmem_broadcast_cmd(CMD.clear_all_full)   -- cmd 11 : 3 parts partout
      return
    end
    if action == "part" then
      -- bascule de part : cmd 12 sur la part cible (le JSFX switch_part avant d'agir)
      local part = tonumber(value) or 1
      gmem_write_cmd(looper, CMD.part, nil, part)
      return
    end
    if action == "speed_step" or action == "pitch_step" then
      gmem_write_cmd(looper, CMD[action], tonumber(value) or 12)
      return
    end
    if action == "loop_in_step" or action == "loop_out_step" then
      -- value = fraction de la boucle (signe = sens). Utilise length / loop_start / loop_width du feedback.
      local L = S.loopers[looper]
      local len = L.length or 0
      if len <= 0 then log("debug", "loop step ignore: length inconnue L%d", looper) return end
      local frac = tonumber(value) or 0.01
      local delta = frac * len
      local start = L.loop_start or 0
      local width = L.loop_width or len
      local min_w = math.max(1, len * 0.01)
      if action == "loop_in_step" then
        local new_in = math.max(0, math.min(start + delta, len - min_w))
        local endp = start + width
        start = new_in
        width = math.max(min_w, endp - start)
        width = math.min(width, len - start)
        L.loop_start, L.loop_width = start, width
        gmem_write_edit(looper, 1, start, nil)  -- edit_cmd 1 = set In, keep Out
      else
        local new_out = math.max(start + min_w, math.min(start + width + delta, len))
        width = new_out - start
        L.loop_width = width
        gmem_write_edit(looper, 2, nil, new_out)  -- edit_cmd 2 = set Out absolute
      end
      return
    end
    if action == "volume_step" then
      -- value = dB ; conversion approx vers facteur lineaire sur out_vol
      local L = S.loopers[looper]
      local cur = L.out_vol or 1.0
      local db = tonumber(value) or 0
      local nxt = math.max(0, math.min(2, cur * (10 ^ (db / 20))))
      L.out_vol = nxt
      gmem_write_param(looper, 22, nxt)
      return
    end
    if action == "reset_volume" then
      S.loopers[looper].out_vol = 1.0
      gmem_write_param(looper, 22, 1.0)
      return
    end
    if action == "reset_pitch" then
      S.loopers[looper].pitch = 0
      gmem_write_param(looper, 4, 0)
      return
    end
    if action == "reset_speed" then
      S.loopers[looper].speed = 1
      gmem_write_param(looper, 3, 1)
      return
    end
    if action == "reset_loop_in" then
      S.loopers[looper].loop_start = 0
      gmem_write_edit(looper, 1, 0, nil)             -- edit_cmd 1 = In a 0
      return
    end
    if action == "reset_loop_out" then
      local len = S.loopers[looper].length or 0
      if len > 0 then
        S.loopers[looper].loop_width = len
        gmem_write_edit(looper, 2, nil, len)         -- edit_cmd 2 = Out a la fin
      end
      return
    end
    if action == "volume_pct" then
      local L = S.loopers[looper]
      local cur = L.out_vol or 1.0
      local pct = tonumber(value) or 0
      local nxt = math.max(0, math.min(2, cur + pct * 0.01))
      L.out_vol = nxt
      gmem_write_param(looper, 22, nxt)
      return
    end
    local cmd = CMD[action]
    if not cmd then
      log("warn", "action gmem inconnue : %s", tostring(action))
      return
    end
    -- toggles : value est le nouvel etat desire (true/false). Le JSFX toggle localement ;
    -- on envoie la commande une seule fois (le miroir optimiste est deja a jour dans send()).
    gmem_write_cmd(looper, cmd, nil)
  end,
  -- helpers exposes pour les couches tune / loop
  write_param = gmem_write_param,
  write_edit  = gmem_write_edit,
  broadcast   = gmem_broadcast_cmd,
  gmem_base   = gmem_base,
  CMD         = CMD,
}

-- Feedback gmem NowUndo -> miroir d'etat (appele dans VL.tick / render)
function VL.poll_looper_feedback()
  if not (reaper and reaper.gmem_attach and reaper.gmem_read) then return end
  reaper.gmem_attach(GMEM_NAME)
  for i = 1, NLOOP do
    local L = S.loopers[i]
    -- presence : gmem[100 + i-1] == i (heartbeat instance)
    local alive = reaper.gmem_read(100 + (i - 1))
    if alive and alive > 0 then
      -- part active publiee sur chaque slot (+42) ; on lit depuis Main
      local base0 = gmem_base(i, 1)
      local ap = reaper.gmem_read(base0 + 42) or L.part or 1
      if ap < 1 or ap > 3 then ap = 1 end
      L.part = math.floor(ap + 0.5)
      local part = L.part
      local base = gmem_base(i, part)
      L.pending_part = (reaper.gmem_read(base + 163) or 0) > 0.5
      local tp = reaper.gmem_read(base + 164) or part
      L.target_part = math.max(1, math.min(3, math.floor((tp or part) + 0.5)))
      local st = math.floor((reaper.gmem_read(base + 2) or 0) + 0.5)
      L.state    = st
      -- Rec LED : rec=rouge, overdub=orange (warn), wait-sync=clignote (armed)
      L.overdub   = (st == 3)                 -- DUB
      L.wait_start = (st == 7)                -- bouton Rec enclenche, REC pas encore actif (attente point de sync ou signal)
      L.wait_sync = (st == 7 or st == 8)      -- clignote : attente avant REC (7) ou attente de sortie de rec (8)
      L.rec_led   = (st == 1)                 -- LED rouge : vrai REC
      -- cle toggle "rec" : true tant que on est dans le cycle rec/dub/wait-sync
      L.rec       = (st == 1 or st == 3 or st == 7 or st == 8)
      L.playing   = (st == 2 or st == 3 or st == 4 or st == 5 or st == 6)
      L.replace   = (st == 4)
      L.multiply  = (st == 6)
      L.rev      = (reaper.gmem_read(base + 17) or 0) > 0.5
      L.pingpong = (reaper.gmem_read(base + 18) or 0) > 0.5
      L.cloud    = (reaper.gmem_read(base + 24) or 0) > 0.5
      local pm   = reaper.gmem_read(base + 8) or 0
      L.slicer   = (pm > 0.5 and pm < 1.5)
      L.oneshot  = (pm > 1.5)
      L.link     = (reaper.gmem_read(base + 9) or 0) > 0.5
      L.auto     = (reaper.gmem_read(base + 43) or 0) > 0.5
      L.speed    = reaper.gmem_read(base + 3) or L.speed or 1
      L.pitch    = reaper.gmem_read(base + 4) or L.pitch or 0
      L.out_vol  = reaper.gmem_read(base + 22) or L.out_vol or 1
      L.loop_quant = reaper.gmem_read(base + 25) or L.loop_quant or 0
      L.loop_start = reaper.gmem_read(base + 44) or L.loop_start or 0
      L.loop_width = reaper.gmem_read(base + 45) or L.loop_width or 0
      L.length     = reaper.gmem_read(base + 46) or L.length or 0
    end
  end
end

VL.hooks = {
  routing_changed = function(edges) VL.apply_routing(edges) end,
  groups_changed  = function(group_of) end,
  fighter_page    = function(n) end,
  fx_changed      = function(slots) VL.apply_fx(slots) end,
  layer_changed   = function(id) end,
  find_looper_fx  = nil,                 -- (i) -> track, fxindex ; defaut : voir plus bas
}
VL.config = {
  -- Reglages propres a ce script (hors S.cfg : la synchro avec le miroir / la remote web ecrase S.cfg)
  unrouted_mode = "parent",        -- "parent" : coupe l'envoi au parent (B_MAINSEND) | "mute" : mute de piste (B_MUTE)
  follow_aux_sends = true,         -- les sources d'un looper suivent ses sends vers les pistes d'effets auxiliaires
  aux_track_first = 20, aux_track_count = 4,   -- pistes d'effets auxiliaires : numeros REAPER 20 a 23
  aux_follow_chain = true,         -- inclut les sources qui atteignent le looper via des routes looper -> looper
  sync_fx_patterns = { "master sync", "master_synchro", "central timebase" },   -- nom du JSFX Master Sync (minuscules)
  sync_inbox = 96,                 -- gmem[96..98] : boite de commandes du JSFX Master Sync (Main / Chorus / Bridge)
  looper_window_fx = 0,            -- index (0 = premier) de l'effet looper dont on ouvre la fenetre
  fx_patterns = { "nowundo", "noundo", "looper" },   -- nom du JSFX a reconnaitre sur les pistes
  -- Noms de secours si les index de piste ne collent pas
  in_name_patterns = { "^in%s*%d+", "^input%s*%d+", "^entree%s*%d+" },
  looper_name_patterns = { "^l%d+", "^looper%s*%d+" },
}

--------------------------------------------------------------------------
-- Routing REAPER : sends IN->L et L->L + mute auto des entrees non routees
-- Ne touche PAS aux parent sends (dossier Inputs / dossier Loopers).
--------------------------------------------------------------------------
function LPF.track_by_index_1based(n)
  if not (reaper and reaper.GetTrack and n and n >= 1) then return nil end
  local tr = reaper.GetTrack(0, n - 1)
  return tr
end

function LPF.track_name(tr)
  if not tr then return "" end
  local _, name = reaper.GetTrackName(tr)
  return name or ""
end

function LPF.match_indexed_name(name, patterns)
  local lower = (name or ""):lower()
  for _, pat in ipairs(patterns or {}) do
    local n = lower:match(pat)
    if n then
      local num = tonumber(lower:match("(%d+)"))
      if num then return num end
    end
  end
  return nil
end

-- Cache leger (invalide si le nombre de pistes change)
local _route_cache = { ntracks = -1, inputs = {}, loopers = {} }

function VL.resolve_tracks(force)
  if not (reaper and reaper.CountTracks) then return _route_cache end
  local n = reaper.CountTracks(0)
  if not force and n == _route_cache.ntracks and _route_cache.inputs[1] then
    return _route_cache
  end
  local inputs, loopers = {}, {}
  local cfg = S.cfg
  -- 1) index fixes (structure projet)
  for i = 1, NIN do
    inputs[i] = LPF.track_by_index_1based((cfg.in_track_first or 2) + (i - 1))
  end
  for i = 1, NLOOP do
    loopers[i] = LPF.track_by_index_1based((cfg.looper_track_first or 11) + (i - 1))
  end
  -- 2) secours par nom si une piste manque
  local named_in, named_l = {}, {}
  for t = 0, n - 1 do
    local tr = reaper.GetTrack(0, t)
    local nm = LPF.track_name(tr)
    local ii = LPF.match_indexed_name(nm, VL.config.in_name_patterns)
    if ii and ii >= 1 and ii <= NIN then named_in[ii] = tr end
    local li = LPF.match_indexed_name(nm, VL.config.looper_name_patterns)
    if li and li >= 1 and li <= NLOOP then named_l[li] = tr end
  end
  for i = 1, NIN do if not inputs[i] then inputs[i] = named_in[i] end end
  for i = 1, NLOOP do if not loopers[i] then loopers[i] = named_l[i] end end
  _route_cache = { ntracks = n, inputs = inputs, loopers = loopers }
  return _route_cache
end

function LPF.find_send(src, dst)
  if not (src and dst) then return nil end
  local ns = reaper.GetTrackNumSends(src, 0)
  for i = 0, ns - 1 do
    local dest = reaper.GetTrackSendInfo_Value(src, 0, i, "P_DESTTRACK")
    if dest == dst then return i end
  end
  return nil
end

function LPF.ensure_send(src, dst)
  local idx = LPF.find_send(src, dst)
  if idx then return idx end
  if not (src and dst) then return nil end
  idx = reaper.CreateTrackSend(src, dst)
  if idx and idx >= 0 then
    -- send audio, pas MIDI ; mode post-fader par defaut
    reaper.SetTrackSendInfo_Value(src, 0, idx, "I_SENDMODE", 0)  -- post-fader
    reaper.SetTrackSendInfo_Value(src, 0, idx, "I_SRCCHAN", 0)    -- stereo 1/2
    reaper.SetTrackSendInfo_Value(src, 0, idx, "I_DSTCHAN", 0)
    return idx
  end
  return nil
end

function LPF.set_send_open(src, dst, open, gain_db)
  if not (src and dst) then return false end
  local idx = open and LPF.ensure_send(src, dst) or LPF.find_send(src, dst)
  if not idx then return false end
  -- mute si ferme ; unmute + volume si ouvert
  reaper.SetTrackSendInfo_Value(src, 0, idx, "B_MUTE", open and 0 or 1)
  if open then
    local db = gain_db or 0
    local vol = (db <= -150) and 0 or (10 ^ (db / 20))
    reaper.SetTrackSendInfo_Value(src, 0, idx, "D_VOL", vol)
  end
  return true
end

-- Ecrit une propriete de piste seulement si elle change (retourne true si modifiee)
function LPF.set_track_prop(tr, key, want)
  if reaper.GetMediaTrackInfo_Value(tr, key) ~= want then
    reaper.SetMediaTrackInfo_Value(tr, key, want)
    return true
  end
  return false
end

-- Rend une piste IN silencieuse (aucun send actif) ou audible (au moins un send actif).
-- NE TOUCHE JAMAIS au mute des sends NI a l'envoi au parent (B_MAINSEND) : le parent reste au choix de l'utilisateur.
-- Seul le MUTE de la piste est utilise (visible dans REAPER). Le script ne demute que ce qu'il a lui-meme mute
-- (marqueur persistant dans le projet, P_EXT) : un mute manuel de l'utilisateur est respecte.
local AUTOMUTE_KEY = "P_EXT:nowundo_vl_automute"
function LPF.set_input_silent(tr, silent)
  if not tr then return false end
  local _, mark = reaper.GetSetMediaTrackInfo_String(tr, AUTOMUTE_KEY, "", false)
  local muted = reaper.GetMediaTrackInfo_Value(tr, "B_MUTE") == 1
  if silent then
    if not muted then
      reaper.SetMediaTrackInfo_Value(tr, "B_MUTE", 1)
      reaper.GetSetMediaTrackInfo_String(tr, AUTOMUTE_KEY, "1", true)
      return true
    end
  elseif mark == "1" then
    if muted then reaper.SetMediaTrackInfo_Value(tr, "B_MUTE", 0) end
    reaper.GetSetMediaTrackInfo_String(tr, AUTOMUTE_KEY, "", true)
    return muted
  end
  return false
end

-- Retire le mute automatique pose par le script (pas les mutes manuels)
function LPF.clear_input_automute(tr)
  if not tr then return end
  local _, mark = reaper.GetSetMediaTrackInfo_String(tr, AUTOMUTE_KEY, "", false)
  if mark == "1" then
    reaper.SetMediaTrackInfo_Value(tr, "B_MUTE", 0)
    reaper.GetSetMediaTrackInfo_String(tr, AUTOMUTE_KEY, "", true)
  end
end

-- Vrai s'il existe au moins un send NON mute de cette IN vers un looper (etat REEL REAPER)
function LPF.input_has_active_send(tr, loopers)
  local ns = reaper.GetTrackNumSends(tr, 0)
  for s = 0, ns - 1 do
    if reaper.GetTrackSendInfo_Value(tr, 0, s, "B_MUTE") == 0 then
      local dest = reaper.GetTrackSendInfo_Value(tr, 0, s, "P_DESTTRACK")
      for i = 1, NLOOP do
        if loopers[i] == dest then return true end
      end
    end
  end
  return false
end

-- Regle : aucun send actif sur la piste IN -> piste mutee ; au moins un send actif -> piste demutee
-- Source de verite = S.routing.in_l
-- Pistes d'effets auxiliaires (reverb, delay...) : numeros de piste REAPER aux_track_first .. +aux_track_count-1.
-- Quand un looper envoie vers une de ces pistes (send non mute), chaque entree dont le pad IN->looper est allume
-- envoie aussi vers cette piste, avec les memes reglages (volume, pan, mode pre/post).
-- Si plusieurs loopers alimentes par la meme entree envoient vers la meme piste : on prend le volume le plus fort.
-- Quand la condition disparait, le send IN->aux est MUTE (jamais supprime).
local function send_val(tr, idx, key) return reaper.GetTrackSendInfo_Value(tr, 0, idx, key) end
local function set_send_val(tr, idx, key, want)
  if math.abs(send_val(tr, idx, key) - want) > 1e-6 then
    reaper.SetTrackSendInfo_Value(tr, 0, idx, key, want)
    return true
  end
  return false
end

-- Loopers atteints par l'entree k : routes IN->looper allumees, puis (option) routes looper->looper en cascade
function LPF.reachable_loopers(k)
  local seen, queue = {}, {}
  for i = 1, NLOOP do
    if S.routing.in_l[k][i] then seen[i] = true; queue[#queue + 1] = i end
  end
  if VL.config.aux_follow_chain ~= false then
    local L = S.routing.l_l
    local qi = 1
    while qi <= #queue do
      local a = queue[qi]; qi = qi + 1
      for b = 1, NLOOP do
        if L[a][b] and not seen[b] then seen[b] = true; queue[#queue + 1] = b end
      end
    end
  end
  return seen
end

function VL.update_aux_follow()
  if VL.config.follow_aux_sends == false then return end
  if not (reaper and reaper.CountTracks) then return end
  local first = VL.config.aux_track_first or 20
  local count = VL.config.aux_track_count or 4
  local tracks = VL.resolve_tracks(false)
  local R = S.routing.in_l
  for a = first, first + count - 1 do
    local aux = LPF.track_by_index_1based(a)
    if aux then
      -- reglages de reference : un looper qui envoie (non mute) vers cette piste d'effets
      local ref = {}
      for i = 1, NLOOP do
        local ltr = tracks.loopers[i]
        local idx = ltr and LPF.find_send(ltr, aux)
        if idx and send_val(ltr, idx, "B_MUTE") == 0 then
          ref[i] = { vol = send_val(ltr, idx, "D_VOL"), pan = send_val(ltr, idx, "D_PAN"), mode = send_val(ltr, idx, "I_SENDMODE") }
        end
      end
      if VL.debug then
        local who = {}
        for i = 1, NLOOP do if ref[i] then who[#who + 1] = "L" .. i end end
        local sig = a .. ":" .. table.concat(who, ",")
        VL._auxdbg = VL._auxdbg or {}
        if VL._auxdbg[a] ~= sig then
          VL._auxdbg[a] = sig
          local _, nm = reaper.GetTrackName(aux)
          reaper.ShowConsoleMsg(string.format("[VL] piste %d '%s' : loopers qui envoient vers elle (send non mute) = {%s}\n", a, nm, table.concat(who, ",")))
        end
      end
      for k = 1, NIN do
        local src = tracks.inputs[k]
        if src then
          local best
          local reach = LPF.reachable_loopers(k)
          for i = 1, NLOOP do
            if reach[i] and ref[i] and (not best or ref[i].vol > best.vol) then best = ref[i] end
          end
          if best then
            local idx = LPF.ensure_send(src, aux)
            if idx then
              local ch = set_send_val(src, idx, "B_MUTE", 0)
              ch = set_send_val(src, idx, "D_VOL", best.vol) or ch
              ch = set_send_val(src, idx, "D_PAN", best.pan) or ch
              ch = set_send_val(src, idx, "I_SENDMODE", best.mode) or ch
              if ch then log("info", "IN%d -> piste %d : send effet suit le looper", k, a) end
            end
          else
            local idx = LPF.find_send(src, aux)
            if idx and send_val(src, idx, "B_MUTE") == 0 then
              reaper.SetTrackSendInfo_Value(src, 0, idx, "B_MUTE", 1)
              log("info", "IN%d -> piste %d : send effet coupe", k, a)
            end
          end
        end
      end
    end
  end
end

function VL.update_input_mutes()
  if not (reaper and reaper.CountTracks) then return end
  local ok_aux, err_aux = pcall(VL.update_aux_follow)
  if not ok_aux and VL._aux_err ~= err_aux then VL._aux_err = err_aux; log("error", "sends effets : %s", tostring(err_aux)) end
  if S.cfg.auto_mute_unrouted_inputs == false then return end   -- nil (config ecrasee par la synchro) = actif
  local tracks = VL.resolve_tracks(false)
  local R = S.routing.in_l
  VL._mm = VL._mm or {}
  local changed = false
  for k = 1, NIN do
    local tr = tracks.inputs[k]
    if tr then
      -- ACTIF = au moins un pad IN->looper allume (etat du script). Les sends REAPER ne sont que relus pour comparaison.
      local active = false
      for i = 1, NLOOP do
        if R[k][i] then active = true; break end
      end
      local real = LPF.input_has_active_send(tr, tracks.loopers)
      if real ~= active and VL._mm[k] ~= (tostring(active) .. tostring(real)) then
        VL._mm[k] = tostring(active) .. tostring(real)
        log("warn", "IN%d : pad=%s mais sends REAPER=%s (ecart)", k, tostring(active), tostring(real))
      elseif real == active then
        VL._mm[k] = nil
      end
      local ch = LPF.set_input_silent(tr, not active)
      if ch then
        changed = true
        log("info", "IN%d : %s", k, active and "demutee (send actif)" or "mutee (aucun send actif)")
      end
      VL._sig = VL._sig or {}
      local sig = tostring(active) .. tostring(real) .. reaper.GetMediaTrackInfo_Value(tr, "B_MAINSEND") .. reaper.GetMediaTrackInfo_Value(tr, "B_MUTE")
      if VL._sig[k] ~= sig then
        VL._sig[k] = sig
        local _, nm = reaper.GetTrackName(tr)
        dbg("IN%d '%s' : pad=%s sendsREAPER=%s -> ecrit=%s | lu : parent=%s mute=%s", k, nm, tostring(active), tostring(real),
            tostring(ch), tostring(reaper.GetMediaTrackInfo_Value(tr, "B_MAINSEND")), tostring(reaper.GetMediaTrackInfo_Value(tr, "B_MUTE")))
      end
    end
  end
  if changed and reaper.UpdateArrange then reaper.UpdateArrange() end
end

function VL.apply_routing(edges)
  if not (reaper and reaper.CountTracks) then return end
  edges = edges or VL.routing_edges()
  local tracks = VL.resolve_tracks(true)
  for _, e in ipairs(edges) do
    local src, dst
    if e.kind == "in_l" then
      src = tracks.inputs[e.a]; dst = tracks.loopers[e.b]
    elseif e.kind == "l_l" then
      src = tracks.loopers[e.a]; dst = tracks.loopers[e.b]
    end
    if src and dst then LPF.set_send_open(src, dst, e.open, e.gain_db or 0) end
  end
  VL.update_input_mutes()
end

function VL.set_auto_mute_unrouted(on)
  S.cfg.auto_mute_unrouted_inputs = not not on
  if not S.cfg.auto_mute_unrouted_inputs then
    local tracks = VL.resolve_tracks(true)
    for k = 1, NIN do LPF.clear_input_automute(tracks.inputs[k]) end
  else
    VL.update_input_mutes()
  end
end

function VL.toggle_auto_mute_unrouted()
  VL.set_auto_mute_unrouted(S.cfg.auto_mute_unrouted_inputs == false)
end

-- Sortie du PARENT d'une entree IN (page 2, appui long sur l'une de ses 8 cases).
-- L'etat est lu directement dans REAPER (B_MAINSEND) : il survit au redemarrage et suit tes changements manuels.
function VL.input_parent_cut(k)
  if not (reaper and reaper.GetMediaTrackInfo_Value) then return false end
  local tr = VL.resolve_tracks(false).inputs[k]
  return tr ~= nil and reaper.GetMediaTrackInfo_Value(tr, "B_MAINSEND") == 0
end
function VL.set_input_parent(k, on)            -- on = true : dans le parent | false : sortie du parent
  if not (reaper and reaper.SetMediaTrackInfo_Value) then return false end
  local tr = VL.resolve_tracks(false).inputs[k]
  if not tr then return false end
  local want = on and 1 or 0
  if reaper.GetMediaTrackInfo_Value(tr, "B_MAINSEND") == want then return false end
  reaper.SetMediaTrackInfo_Value(tr, "B_MAINSEND", want)
  if reaper.UpdateArrange then reaper.UpdateArrange() end
  log("info", "IN%d : parent %s", k, on and "reactive" or "coupe")
  return true
end

--------------------------------------------------------------------------
-- FX inserts : 4 slots par IN (haut page FX) + 4 slots par looper (bas)
-- Slot N = N-ieme effet "utile" sur la piste (les JSFX nowundo sont ignores sur les L).
--------------------------------------------------------------------------
function LPF.is_nowundo_fx(tr, fx)
  local _, nm = reaper.TrackFX_GetFXName(tr, fx, "")
  nm = (nm or ""):lower()
  for _, pat in ipairs(VL.config.fx_patterns or {}) do
    if nm:find(pat, 1, true) then return true end
  end
  return false
end

-- Retourne l'index TrackFX (0-based) du slot logique 1..NSLOT, ou nil si absent
function LPF.fx_index_for_slot(tr, slot, skip_nowundo)
  if not tr or slot < 1 then return nil end
  local n = reaper.TrackFX_GetCount(tr)
  local seen = 0
  for fx = 0, n - 1 do
    if not (skip_nowundo and LPF.is_nowundo_fx(tr, fx)) then
      seen = seen + 1
      if seen == slot then return fx end
    end
  end
  return nil
end

-- Identite stable d'un effet : detecte un remplacement sans reprendre son activation par defaut.
function LPF.fx_identity(tr, fx)
  if not tr or fx == nil then return nil end
  if reaper.TrackFX_GetFXGUID then
    local guid = reaper.TrackFX_GetFXGUID(tr, fx)
    if guid and guid ~= "" then return guid end
  end
  local _, name = reaper.TrackFX_GetFXName(tr, fx, "")
  return name or ("FX#" .. tostring(fx))
end

function VL.scan_fx_present()
  if not (reaper and reaper.CountTracks) then return false end
  local tracks = VL.resolve_tracks(false)
  local first_scan = VL._fx_identity == nil
  VL._fx_identity = VL._fx_identity or { input = {}, looper = {} }
  local changed = false
  local function scan_kind(kind, count, track_list, skip_nowundo)
    VL._fx_identity[kind] = VL._fx_identity[kind] or {}
    for id = 1, count do
      VL._fx_identity[kind][id] = VL._fx_identity[kind][id] or {}
      local tr = track_list[id]
      for slot = 1, NSLOT do
        local fx = tr and LPF.fx_index_for_slot(tr, slot, skip_nowundo) or nil
        local identity = fx and LPF.fx_identity(tr, fx) or nil
        local previous = VL._fx_identity[kind][id][slot]
        local present = fx ~= nil
        S.fx_present[kind][id][slot] = present
        if first_scan then
          -- Au demarrage, on reprend l'etat reel deja en place dans REAPER.
          S.fx[kind][id][slot] = present and reaper.TrackFX_GetEnabled(tr, fx) or false
        elseif identity ~= previous then
          changed = true
          if not present then S.fx[kind][id][slot] = false end
        end
        if present then
          -- La matrice page 4 commande aussi l'activation du container lui-meme.
          -- Cela couvre le cas ou le remplacement d'un FX interne reactive le container
          -- sans changer son identite TrackFX externe.
          local wanted = S.fx[kind][id][slot] and true or false
          if reaper.TrackFX_GetEnabled(tr, fx) ~= wanted then
            reaper.TrackFX_SetEnabled(tr, fx, wanted)
          end
        end
        VL._fx_identity[kind][id][slot] = identity
      end
    end
  end
  scan_kind("input", NIN, tracks.inputs, false)
  scan_kind("looper", NLOOP, tracks.loopers, true)
  return changed
end

function VL.apply_fx(slots)
  if not (reaper and reaper.CountTracks) then return end
  slots = slots or VL.fx_list()
  local tracks = VL.resolve_tracks(true)
  reaper.PreventUIRefresh(1)
  for _, s in ipairs(slots) do
    local tr = (s.kind == "input") and tracks.inputs[s.id] or tracks.loopers[s.id]
    if tr then
      local fx = LPF.fx_index_for_slot(tr, s.slot, s.kind == "looper")
      if not fx then
        if s.present then VL.set_fx_present(s.kind, s.id, s.slot, false) end
      else
        if not s.present then VL.set_fx_present(s.kind, s.id, s.slot, true) end
        -- enabled true = effet actif = bypass OFF
        local on = reaper.TrackFX_GetEnabled(tr, fx)
        if on ~= s.enabled then
          reaper.TrackFX_SetEnabled(tr, fx, s.enabled and true or false)
        end
      end
    end
  end
  reaper.PreventUIRefresh(-1)
end


-- Geste de "peinture" : on pose/retire une cellule, puis on glisse (souris) ou on appuie sur d'autres
-- pads sans lacher le premier (hardware) : toutes prennent la meme valeur. Les hooks (routing, groupes)
-- ne sont appeles qu'UNE fois, a la fin du geste.
local paint = nil
local function notify_routing()
  if paint then
    paint.dirty_routing = true
  else
    -- hooks d'abord (sends), puis mute IN toujours a jour
    local ok, err = pcall(function() VL.hooks.routing_changed(VL.routing_edges()) end)
    if not ok then log("warn", "routing_changed : %s", tostring(err)) end
    if VL.update_input_mutes then
      ok, err = pcall(VL.update_input_mutes)
      if not ok then log("warn", "update_input_mutes : %s", tostring(err)) end
    end
  end
end
local function notify_groups()
  if paint then paint.dirty_groups = true else VL.hooks.groups_changed(S.group_of) end
end
local function notify_fx()
  if paint then paint.dirty_fx = true else VL.hooks.fx_changed(VL.fx_list()) end
end

--------------------------------------------------------------------------
-- Source FX Router : independante de la page affichee.
-- Elle ne change QUE lors d'une selection explicite d'une entree ou d'un looper.
--------------------------------------------------------------------------
function VL.publish_fx_source()
  if not (reaper and reaper.SetExtState) then return end
  local source = clamp(S.fx_source or (NIN + clamp(S.sel_looper or 1, 1, NLOOP)), 1, NIN + NLOOP)
  reaper.SetExtState("nowundo_vl", "fx_source", tostring(source), false)
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
  S.fx_source = NIN + S.sel_looper
  VL.publish_fx_source()
  log("info", "looper %d selectionne", S.sel_looper)
  if VL.follow_looper_window then VL.follow_looper_window() end   -- une fenetre looper ouverte bascule sur le nouveau
end
function VL.step_looper(d)
  S.sel_looper = ((S.sel_looper - 1 + d) % NLOOP) + 1
  follow_group()
  S.fx_source = NIN + S.sel_looper
  VL.publish_fx_source()
  log("info", "looper %d selectionne", S.sel_looper)
  if VL.follow_looper_window then VL.follow_looper_window() end
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
  -- Le changement de page ne modifie jamais la source du FX Router.
  log("info", "page %d", S.page)
  -- Publier immediatement pour le miroir (section fixe : SYNC est local plus bas dans le fichier)
  if not VL.mirror_mode and reaper and reaper.SetExtState then
    reaper.SetExtState("nowundo_vl", "active_page", tostring(S.page), false)
  end
end
function VL.set_fighter_page(n)
  S.fighter_page = clamp(n, 1, 8)
  VL.hooks.fighter_page(S.fighter_page)
  if reaper and reaper.SetExtState then
    reaper.SetExtState("nowundo_vl", "fighter_page", tostring(S.fighter_page), false)
  end
  log("info", "fighter page %d", S.fighter_page)
end

-- Slot (1..4) du FX Router cible par la selection d'effet (page Twister 6) : exclusif, toujours un slot actif.
-- Stocke dans l'ExtState (lu par le Twister, le FX Router et le miroir) ; defaut = slot 1.
function VL.fx_slot()
  local n = (reaper and reaper.GetExtState) and tonumber(reaper.GetExtState("nowundo_vl", "fx_slot")) or 1
  return clamp(math.floor(n or 1), 1, NSLOT)
end
function VL.set_fx_slot(n)
  n = clamp(n, 1, NSLOT)
  if reaper and reaper.SetExtState then reaper.SetExtState("nowundo_vl", "fx_slot", tostring(n), false) end
  log("info", "slot FX %d", n)
end

function VL.group_members(g)
  local m = {}
  for i = 1, NLOOP do if S.group_of[i] == g then m[#m + 1] = i end end
  return m
end

-- cibles d'une action : groupe actif ET non vide -> uniquement les membres du groupe
-- (le looper selectionne n'est PAS inclus s'il n'en fait pas partie) ; sinon looper selectionne
function VL.targets()
  -- Un pad GROUPE maintenu inhibe le principe de groupe : seul le looper selectionne est concerne
  if VL.group_inhibit and VL.group_inhibit() then return { S.sel_looper } end
  if S.sel_group > 0 then
    local m = VL.group_members(S.sel_group)
    if #m > 0 then return m end
  end
  return { S.sel_looper }
end

-- ===================== MODE EXCLU =====================
-- Regles (changer de groupe ne declenche plus rien ; tout se joue a l'ENREGISTREMENT) :
--  * REC sur un groupe : il demarre a la fin du REC. Les AUTRES groupes qui jouent sont stoppes des le debut du REC.
--      - un looper SOLO tourne ET la synchro est verrouillee : la synchro reste, le groupe s'enregistre en SYNC sur le maitre actif
--      - sinon : la synchro est desactivee au debut du REC ; a la fin, elle se verrouille sur le PREMIER looper du groupe (le maitre),
--        les autres membres (meme longueur) adoptent sa reference (JSFX cmd 28)
--  * REC sur un looper SOLO : le groupe en cours continue ; le solo se synchronise sur le maitre actif (ou devient maitre s'il n'y en a pas)
--  * deux solos de synchros differentes : la synchro active s'applique ; pour changer, desactiver la synchro puis la reverrouiller
--    sur le looper voulu (pad SYNC : se verrouille sur le looper selectionne)
-- Regle d'appartenance : meme reference de synchro (uid exporte par le looper, gmem +183 ; survit a la suppression du maitre).
local EXCL = { job = nil }
-- messages EXCLU : journal du Launchpad uniquement (pas de console)
local function elog(level, fmt, ...) log(level, fmt, ...) end
function LPF.excl_alive(i)
  return (reaper.gmem_read(100 + (i - 1)) or 0) > 0 and (now() - (reaper.gmem_read(130 + (i - 1)) or 0)) <= 3.0
end
function LPF.looper_ref(i)       -- uid de la reference du looper (part active), 0 = aucune (pas de boucle)
  if not (reaper and reaper.gmem_attach and reaper.gmem_read) then return 0 end
  reaper.gmem_attach(GMEM_NAME)
  if (reaper.gmem_read(100 + (i - 1)) or 0) <= 0 then return 0 end
  local ap = math.floor((reaper.gmem_read(gmem_base(i, 1) + 42) or 1) + 0.5)
  if ap < 1 or ap > 3 then ap = 1 end
  return math.floor((reaper.gmem_read(gmem_base(i, ap) + 183) or 0) + 0.5)
end
function LPF.group_ref(g, except)
  for i = 1, NLOOP do
    if i ~= except and S.group_of[i] == g then
      local r = LPF.looper_ref(i); if r > 0 then return r end
    end
  end
  return 0
end
function VL.excl_can_join(looper, g)
  if not S.exclusive or g == 0 then return true end
  local r, gr = LPF.looper_ref(looper), LPF.group_ref(g, looper)
  return r == 0 or gr == 0 or r == gr           -- un looper sans boucle (reference inconnue) est accepte
end
-- etat / longueur du looper (part active) : state 0 = stoppe, 7 = attente de depart, 1 = REC
function LPF.looper_info(i)
  reaper.gmem_attach(GMEM_NAME)
  local ap = math.floor((reaper.gmem_read(gmem_base(i, 1) + 42) or 1) + 0.5)
  if ap < 1 or ap > 3 then ap = 1 end
  local b = gmem_base(i, ap)
  return math.floor((reaper.gmem_read(b + 2) or 0) + 0.5), (reaper.gmem_read(b + 46) or 0)
end
function LPF.group_all_empty(g)      -- vrai si le groupe a des loopers vivants et qu'ils sont TOUS vides
  local n = 0
  for i = 1, NLOOP do
    if S.group_of[i] == g and LPF.excl_alive(i) then
      n = n + 1
      local _, len = LPF.looper_info(i)
      if len > 0 then return false end
    end
  end
  return n > 0
end
function LPF.excl_cancel_all()
  EXCL.job = nil
  if reaper and reaper.gmem_attach then
    reaper.gmem_attach(GMEM_NAME)
    for i = 1, NLOOP do if LPF.excl_alive(i) then gmem_write_cmd(i, 27) end end   -- annule les armements en cours
  end
end
function VL.excl_super_toggle()               -- appui long : EXCLU <-> SUPER EXCLU (active le mode si besoin), meme en cours de jeu
  if not S.exclusive then
    VL.excl_toggle()
    S.super = true
  else
    S.super = not S.super
    LPF.excl_cancel_all()
  end
  elog("info", S.super and "SUPER EXCLU ON (loopers seuls = groupes)" or "EXCLU (loopers seuls non concernes)")
end
function VL.excl_toggle()
  S.exclusive = not S.exclusive
  S.super = false
  EXCL.job = nil
  if S.exclusive then
    local changed = false
    for g = 1, NGROUP do                          -- groupes deja constitues : on ejecte les references differentes
      local gr = 0
      for i = 1, NLOOP do
        if S.group_of[i] == g then
          local r = LPF.looper_ref(i)
          if r > 0 then
            if gr == 0 then gr = r elseif r ~= gr then
              S.group_of[i] = 0; changed = true
              elog("warn", "EXCLU : looper %d sorti du groupe %d (autre reference de synchro)", i, g)
            end
          end
        end
      end
    end
    if changed then S.sel_group = S.group_of[S.sel_looper] or 0; notify_groups() end
    elog("info", "EXCLU ON")
  else
    if reaper and reaper.gmem_attach then
      reaper.gmem_attach(GMEM_NAME)
      for i = 1, NLOOP do if LPF.excl_alive(i) then gmem_write_cmd(i, 27) end end   -- annule les armements en cours
    end
    elog("info", "EXCLU OFF")
  end
end
function VL.excl_poll(t)
  if VL.mirror_mode or not S.exclusive then return end
  if VL.excl_job_tick then VL.excl_job_tick(t) end
end
function VL.excl_led()
  -- libelle court + couleur selon le mode : EXCLU = jaune, SUPER EXCLU = violet
  PAD_LABEL[1]["6,2"] = S.super and "SUPER EXCLU" or "EXCLU"      -- EXCLU est en C2 (ligne 6, colonne 2)
  PAD_RGB[1]["6,2"] = S.super and 0xB040FF or 0xFFD000
  return S.exclusive and (EXCL.job and "armed" or "on") or "idle"
end

VL._chord_group = {}                        -- [g]=true : groupe cree par chord (se dissout quand il ne reste qu'un looper)
function VL.assign_group(looper, g, via_chord)   -- exclusif : un looper = au plus un groupe (g = 0 : aucun)
  if g > 0 and not via_chord then VL._chord_group[g] = nil end   -- ancienne methode (maintien GROUP) : groupe "manuel", jamais dissous
  if S.group_of[looper] == g then return false end
  if g > 0 and not VL.excl_can_join(looper, g) then
    elog("warn", "EXCLU : looper %d refuse dans le groupe %d (reference de synchro differente)", looper, g)
    return false
  end
  S.group_of[looper] = g
  if looper == S.sel_looper then S.sel_group = g end      -- le looper selectionne a change de groupe : le groupe actif suit
  notify_groups()
  log("info", "looper %d -> group %d", looper, g)
  return true
end
function VL.set_membership(looper, g)       -- bascule
  return VL.assign_group(looper, (S.group_of[looper] == g) and 0 or g)
end

-- Premier groupe sans aucun membre (1..NGROUP), ou nil si tous occupes
function VL.first_empty_group()
  for g = 1, NGROUP do
    if #VL.group_members(g) == 0 then VL._chord_group[g] = nil; return g end
  end
  return nil
end

-- Groupe cree par chord qui ne contient plus qu'un looper : le looper restant sort du groupe.
-- Les groupes faits a l'ancienne (maintien du pad GROUP) ne sont jamais dissous.
function VL.dissolve_if_lonely(g)
  if not g or g <= 0 or not VL._chord_group[g] then return false end
  local m = VL.group_members(g)
  if #m > 1 then return false end
  VL._chord_group[g] = nil
  if #m == 1 then
    VL.assign_group(m[1], 0, true)
    log("info", "chord : L%d seul -> sort du groupe %d (groupe libere)", m[1], g)
  end
  return true
end

-- Regroupement type console Yamaha : le premier looper maintenu est l'affectateur (anchor),
-- chaque looper presse ensuite (target) est ajoute / retire du meme groupe.
--   - anchor deja groupe  -> target rejoint ce groupe, ou en sort s'il y etait deja
--   - anchor libre        -> PREMIER GROUPE LIBRE (vide) ; les deux y sont places ; aucun groupe libre = no-op
--   - un groupe cree par chord qui n'a plus qu'un looper est dissous
function VL.looper_chord_group(anchor, target)
  anchor = clamp(anchor, 1, NLOOP)
  target = clamp(target, 1, NLOOP)
  if anchor == target then return false end
  local ga = S.group_of[anchor] or 0
  local gt = S.group_of[target] or 0
  if ga > 0 then
    if gt == ga then
      VL.assign_group(target, 0, true)
      log("info", "chord : L%d retire du groupe %d (affectateur L%d)", target, ga, anchor)
      VL.dissolve_if_lonely(ga)
    else
      if VL.assign_group(target, ga, true) then
        log("info", "chord : L%d ajoute au groupe %d (affectateur L%d)", target, ga, anchor)
        VL.dissolve_if_lonely(gt)          -- l'ancien groupe de target peut se retrouver avec un seul looper
      end
    end
    VL.select_looper(anchor)
    return true
  end
  -- anchor libre : les deux loopers sont regroupes dans un groupe LIBRE (jamais dans un groupe deja occupe)
  local g = VL.first_empty_group()
  if not g then
    log("info", "chord : aucun groupe libre — regroupement ignore (L%d + L%d)", anchor, target)
    return false
  end
  local old_gt = gt
  VL.assign_group(anchor, g, true)
  VL.assign_group(target, g, true)
  VL._chord_group[g] = true
  if old_gt > 0 then VL.dissolve_if_lonely(old_gt) end
  VL.select_looper(anchor)
  log("info", "chord : groupe %d cree avec L%d + L%d", g, anchor, target)
  return true
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
  -- CLEAR :
  --   court (clear / clear_part) = part active seulement (Main|Chorus|Bridge)
  --   double clic (clear_all_full) = les 3 parts de CHAQUE looper vivant
  -- RESET :
  --   court (reset) = remet a zero les loopers cibles
  --   double clic (reset_all) = remet a zero les 8 loopers
  -- RESET : remet tous les parametres (pitch, speed, grain, slicer, cloud, align...) et la boucle In/Out a leur defaut, SAUF le volume
  reset       = { kind = "trig" },
  reset_params = { kind = "trig" },
  reset_all   = { kind = "trig", global = true },   -- double clic sur RESET : les 8 loopers
  reset_volume = { kind = "trig" }, reset_pitch = { kind = "trig" }, reset_speed = { kind = "trig" },
  reset_loop_in = { kind = "trig" }, reset_loop_out = { kind = "trig" },
  clear       = { kind = "trig", reset = "part" },
  clear_part  = { kind = "trig", reset = "part" },
  clear_full  = { kind = "trig", reset = "all" },
  clear_all   = { kind = "trig", reset = "part", global = true },
  clear_all_full = { kind = "trig", reset = "all", global = true },
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

-- Affichage / reference : toujours le looper selectionne s'il est dans les cibles, sinon le 1er.
-- Les toggles de groupe NE resynchronisent plus les etats : chaque membre bascule individuellement
-- (ex. reverse inverse : A->B et B->A, l'inversion relative est conservee).
local function ref_looper(targets)
  for _, t in ipairs(targets) do if t == S.sel_looper then return t end end
  return targets[1]
end

-- etat LED d'un toggle : celui du looper selectionne (s'il est cible), sinon majorite (fallback)
local function toggle_on(key, targets)
  for _, t in ipairs(targets) do
    if t == S.sel_looper then return S.loopers[t][key] end
  end
  local on = 0
  for _, t in ipairs(targets) do if S.loopers[t][key] then on = on + 1 end end
  return on * 2 > #targets
end

local RESET_FLAGS = { "rec", "replace", "multiply", "auto", "rev", "pingpong", "playing", "oneshot", "cloud", "slicer", "link" }
local function reset_looper(t, back_to_main)
  local L = S.loopers[t]
  for _, k in ipairs(RESET_FLAGS) do L[k] = false end
  -- CLEAR remet aussi les parametres de lecture et le volume a leur valeur initiale.
  L.speed, L.pitch, L.out_vol = 1.0, 0.0, 1.0
  if back_to_main then L.part = 1 end
end

-- [SCN] Mode CAPTURE du script NowUndo_Scenario : tant que son heartbeat est vivant, le Launchpad lui signale ce
-- qu'il EXECUTE reellement (par looper, apres resolution des groupes / toggles) et le GO du mode Launch.
-- Rien n'est bloque : le Launchpad agit normalement.
function VL.scn_on()
  local hb = tonumber(reaper.GetExtState("NowUndo_Scn", "hb")) or 0
  return reaper.time_precise() - hb < 0.6
end
function VL.scn_emit_glob(word)             -- [SCN] capture : mot global (r(n), g(n), sync...)
  if VL.scn_on() then VL.scn_emit("glob\t" .. word) end
end
function VL.scn_emit(line)
  reaper.SetExtState("NowUndo_Scn", "q", reaper.GetExtState("NowUndo_Scn", "q") .. line .. "\n", false)
end
function VL.scn_op(action, looper, value)
  if not (reaper and reaper.GetExtState) or not VL.scn_on() then return end
  VL.scn_emit(string.format("op\t%s\t%d\t%s", tostring(action), looper, value ~= nil and tostring(value) or ""))
end
function VL.scn_cmd(name)                   -- commande vers le scenario (file d'attente ExtState NowUndo_Scn/cmd)
  local cur = reaper.GetExtState("NowUndo_Scn", "cmd")
  reaper.SetExtState("NowUndo_Scn", "cmd", cur .. string.format("%s\t%.3f\n", name, reaper.time_precise()), false)
end

local function send(looper, action, value)
  VL.scn_op(action, looper, value)   -- [SCN]
  VL.backend.send(looper, action, value)
  local def = ACTIONS[action]
  if def and def.key and value ~= nil then S.loopers[looper][def.key] = value end   -- miroir optimiste
end

-- loopers vivants (heartbeat gmem) ; sans feedback gmem : tous
function VL.alive_loopers()
  local list = {}
  if reaper and reaper.gmem_attach and reaper.gmem_read then
    reaper.gmem_attach(GMEM_NAME)
    for i = 1, NLOOP do
      if (reaper.gmem_read(100 + (i - 1)) or 0) > 0 then list[#list + 1] = i end
    end
  end
  if #list == 0 then for i = 1, NLOOP do list[i] = i end end
  return list
end

-- ======================================================================================
-- Module JSFX "Nowundo Master Sync" (gmem nowundo_sync) : un slot de synchro par part
--   gmem[0] Main | gmem[10] Chorus | gmem[20] Bridge  :  0 = LIBRE | 1 = MASTER (un looper) | 2 = HOST (Reaper)
--   gmem[slot+1] = alias du looper maitre (etat 1)
--   Host Sync = sliders 1..3 du JSFX (Main / Chorus / Bridge) : on les pilote par parametre FX, et par la
--   boite de commandes gmem[96..98] du JSFX corrige (1 = Host ON, 2 = OFF / unlock).
-- Les loopers qui ont deja une boucle gardent leur synchro : seuls les NOUVEAUX rec sont concernes (gere par le JSFX).
-- ======================================================================================
local SYNCMOD = { mem = {}, tr = nil, fx = nil, warned = false, params = nil }
local function sync_off(p) return (p - 1) * 10 end

function LPF.sync_fx_matches(tr, fx)
  local ok, name = reaper.TrackFX_GetFXName(tr, fx, "")
  if not (ok and type(name) == "string") then return false end
  name = name:lower()
  for _, pat in ipairs(VL.config.sync_fx_patterns) do
    if name:find(pat, 1, true) then return true end
  end
  return false
end

function LPF.sync_find_fx()
  if not (reaper and reaper.CountTracks and reaper.TrackFX_GetCount) then return nil end
  if SYNCMOD.tr and SYNCMOD.fx and reaper.ValidatePtr2 and reaper.ValidatePtr2(0, SYNCMOD.tr, "MediaTrack*")
     and SYNCMOD.fx < reaper.TrackFX_GetCount(SYNCMOD.tr) and LPF.sync_fx_matches(SYNCMOD.tr, SYNCMOD.fx) then
    return SYNCMOD.tr, SYNCMOD.fx
  end
  local list = {}
  if reaper.GetMasterTrack then list[#list + 1] = reaper.GetMasterTrack(0) end
  for i = 0, reaper.CountTracks(0) - 1 do list[#list + 1] = reaper.GetTrack(0, i) end
  for _, tr in ipairs(list) do
    for fx = 0, reaper.TrackFX_GetCount(tr) - 1 do
      if LPF.sync_fx_matches(tr, fx) then
        SYNCMOD.tr, SYNCMOD.fx, SYNCMOD.params = tr, fx, nil
        return tr, fx
      end
    end
  end
  return nil
end

-- index des parametres FX "Host Sync (Main/Chorus/Bridge)" (les sliders caches peuvent ne pas etre exposes)
function LPF.sync_param_index(tr, fx, p)
  if not SYNCMOD.params then
    SYNCMOD.params = {}
    local want = { "main", "chorus", "bridge" }
    for i = 0, reaper.TrackFX_GetNumParams(tr, fx) - 1 do
      local ok, nm = reaper.TrackFX_GetParamName(tr, fx, i, "")
      nm = ok and type(nm) == "string" and nm:lower() or ""
      if nm:find("host sync", 1, true) and not nm:find("meas", 1, true) then
        for k, w in ipairs(want) do if nm:find(w, 1, true) then SYNCMOD.params[k] = i end end
      end
    end
  end
  return SYNCMOD.params[p]
end

local function sync_state(p)
  if not (reaper and reaper.gmem_attach and reaper.gmem_read) then return 0, 0 end
  reaper.gmem_attach(GMEM_NAME)
  return math.floor((reaper.gmem_read(sync_off(p)) or 0) + 0.5), (reaper.gmem_read(sync_off(p) + 1) or 0)
end

-- Host sync ON/OFF d'une part : parametre FX si expose + boite de commandes gmem du JSFX corrige
local function sync_set_host(p, on)
  local tr, fx = LPF.sync_find_fx()
  if not tr then
    if not SYNCMOD.warned then
      SYNCMOD.warned = true
      log("warn", "module Master Sync introuvable (cherche : %s)", table.concat(VL.config.sync_fx_patterns, " / "))
    end
  else
    local pi = LPF.sync_param_index(tr, fx, p)
    if pi then reaper.TrackFX_SetParam(tr, fx, pi, on and 1 or 0) end
  end
  reaper.gmem_attach(GMEM_NAME)
  reaper.gmem_write(VL.config.sync_inbox + p - 1, on and 1 or 2)
end

function LPF.sync_alias_exists(alias)
  if alias <= 0 then return false end
  for si = 0, 4 do
    if (reaper.gmem_read(1000 + si * 600 + 1) or 0) == alias then return true end
  end
  return false
end

-- libere la synchro engagee sur la part p (comme le bouton Unlock) ; se souvient de ce qui etait engage
function LPF.sync_release(p)
  local locked, mid = sync_state(p)
  if locked == 0 then return false end
  SYNCMOD.mem[p] = { mode = locked, mid = mid }
  reaper.gmem_attach(GMEM_NAME)
  reaper.gmem_write(sync_off(p), 0)
  sync_set_host(p, false)
  return true
end

-- verrouille la synchro de la part p sur le looper SELECTIONNE (il doit etre vivant et avoir une boucle dans cette part)
function LPF.sync_lock_selected(p)
  local i = S.sel_looper
  if not i then return false end
  reaper.gmem_attach(GMEM_NAME)
  if (reaper.gmem_read(100 + (i - 1)) or 0) <= 0 then return false end
  local base = 1000 + (i - 1) * 600 + (p - 1) * 200
  local alias = reaper.gmem_read(base + 1) or 0
  if alias <= 0 or (reaper.gmem_read(base + 46) or 0) <= 0 then return false end
  reaper.gmem_write(sync_off(p), 1)
  reaper.gmem_write(sync_off(p) + 1, alias)
  sync_set_host(p, false)
  return true, i
end

-- reengage la synchro : par defaut verrouillage sur le looper selectionne ; a defaut le maitre precedent (s'il existe encore), sinon Host Reaper
function LPF.sync_engage(p)
  local locked = sync_state(p)
  if locked ~= 0 then return false end
  local ok, who = LPF.sync_lock_selected(p)
  if ok then log("info", "SYNC part %d : verrouille sur le looper %d (selectionne)", p, who); return true end
  local m = SYNCMOD.mem[p]
  reaper.gmem_attach(GMEM_NAME)
  if m and m.mode == 1 and LPF.sync_alias_exists(m.mid) then
    reaper.gmem_write(sync_off(p), 1)
    reaper.gmem_write(sync_off(p) + 1, m.mid)
    sync_set_host(p, false)
  else
    sync_set_host(p, true)
  end
  return true
end

-- part en cours = part la plus utilisee parmi les loopers vivants (1 Main, 2 Chorus, 3 Bridge)
function VL.current_part()
  local cnt = { 0, 0, 0 }
  for _, i in ipairs(VL.alive_loopers()) do
    local p = S.loopers[i].part or 1
    if p >= 1 and p <= 3 then cnt[p] = cnt[p] + 1 end
  end
  local best = 1
  for p = 2, 3 do if cnt[p] > cnt[best] then best = p end end
  return best
end

function VL.sync_is_on(p)
  return (sync_state(p or VL.current_part())) ~= 0
end

-- SYNC / UNSYNC : court = part en cours ; long = les 3 parts. Une part engagee -> on libere ; sinon -> on reengage.
function VL.sync_toggle(all)
  local parts = all and { 1, 2, 3 } or { VL.current_part() }
  local any = false
  for _, p in ipairs(parts) do if sync_state(p) ~= 0 then any = true end end
  local n = 0
  for _, p in ipairs(parts) do
    if any then if LPF.sync_release(p) then n = n + 1 end
    else if LPF.sync_engage(p) then n = n + 1 end end
  end
  log("info", "SYNC %s : %d part(s)%s", any and "OFF (libere)" or "ON", n, all and " (toutes)" or " (en cours)")
  if n > 0 and not VL._scn_quiet then VL.scn_emit_glob((any and "unsync" or "sync") .. (all and "all" or "")) end   -- [SCN] capture
end

-- commande SYNC (on) / UNSYNC (off) sans bascule : part en cours, ou les 3 parts (script Scenario : sync / unsync / syncall / unsyncall)
function VL.sync_set(on, all)
  local parts = all and { 1, 2, 3 } or { VL.current_part() }
  local n = 0
  for _, p in ipairs(parts) do
    if on then if LPF.sync_engage(p) then n = n + 1 end
    else if LPF.sync_release(p) then n = n + 1 end end
  end
  log("info", "SYNC %s : %d part(s)%s", on and "ON" or "OFF (libere)", n, all and " (toutes)" or " (en cours)")
end

-- ===== MODE EXCLU : logique d'enregistrement (apres les fonctions SYNC, avant exec) =====
function LPF.sync_lock_looper(i, p)               -- verrouille la synchro de la part p sur le looper i (vivant, avec boucle)
  reaper.gmem_attach(GMEM_NAME)
  if (reaper.gmem_read(100 + (i - 1)) or 0) <= 0 then return false end
  local base = 1000 + (i - 1) * 600 + (p - 1) * 200
  local alias = reaper.gmem_read(base + 1) or 0
  if alias <= 0 or (reaper.gmem_read(base + 46) or 0) <= 0 then return false end
  reaper.gmem_write(sync_off(p), 1)
  reaper.gmem_write(sync_off(p) + 1, alias)
  sync_set_host(p, false)
  return true
end
function LPF.excl_rec_state(st) return st == 1 or st == 7 or st == 8 end
function LPF.excl_solo_running()                   -- un looper hors groupe, avec boucle, qui joue
  for i = 1, NLOOP do
    local L = S.loopers[i]
    if (S.group_of[i] or 0) == 0 and (L.length or 0) > 0 and LPF.excl_alive(i) then
      local st = L.state or 0
      if st >= 2 and st <= 6 then return true end
    end
  end
  return false
end
-- appele par exec() AVANT l'envoi de REC. Retourne true si le REC est DIFFERE (le looper l'executera au synchro point).
function LPF.excl_cancel_armed()
  reaper.gmem_attach(GMEM_NAME)
  for i = 1, NLOOP do if LPF.excl_alive(i) then gmem_write_cmd(i, 27) end end
end
-- arme le basculement differe : le groupe actif s'arrete a son synchro point, le groupe selectionne passe en REC a cet instant
function LPF.excl_arm_switch(g, p, running, fresh, loops, solo_sync)
  reaper.gmem_attach(GMEM_NAME)
  for _, j in ipairs(running) do gmem_write_cmd(j, 25) end
  if #fresh > 0 then
    for _, t in ipairs(fresh) do gmem_write_cmd(t, 30, solo_sync and 0 or 1) end    -- REC arme sur looper vide
    for _, t in ipairs(loops) do gmem_write_cmd(t, 29) end
    if solo_sync then
      EXCL.job = nil
    else
      EXCL.job = { group = g, members = fresh, p = p, phase = "rec", t0 = now(), seen = false, deferred = true, release_on_start = true }
    end
    elog("info", "EXCLU : groupe %d (vide) en REC au prochain synchro point du groupe actif", g)
  else
    for _, t in ipairs(loops) do gmem_write_cmd(t, 29) end
    EXCL.job = { group = g, members = loops, p = p, phase = "switch", t0 = now(), keep = solo_sync }
    elog("info", "EXCLU : groupe %d en REC au prochain synchro point du groupe actif", g)
  end
end
function VL.excl_before_rec(targets)
  if not S.exclusive then return false end
  local job = EXCL.job
  if job and (job.phase == "switch" or (job.phase == "rec" and job.deferred and not job.seen)) then   -- 2e appui pendant l'attente : annule
    LPF.excl_cancel_armed(); EXCL.job = nil
    elog("info", "EXCLU : basculement annule")
    return true
  end
  local fresh, loops, recording = {}, {}, false
  for _, t in ipairs(targets or {}) do
    local L = S.loopers[t]; local st = L.state or 0
    if LPF.excl_rec_state(st) or st == 3 then recording = true end
    if (L.length or 0) <= 0 then fresh[#fresh + 1] = t else loops[#loops + 1] = t end
  end
  if recording or #targets == 0 then EXCL.note = "NORMAL (fin de REC / overdub)"; return false end          -- fin de REC / overdub en cours : comportement normal
  table.sort(fresh); table.sort(loops)
  local first = (#fresh > 0) and fresh[1] or loops[1]
  local g = S.group_of[first] or 0
  local super = S.super and true or false
  if g == 0 and not super then EXCL.note = "IMMEDIAT (looper solo)"; return false end                              -- looper SOLO : synchro active, le groupe en cours continue
  local p = S.loopers[first].part or VL.current_part()
  local running = {}                                           -- loopers des AUTRES unites (groupes ; en SUPER aussi les loopers seuls) qui jouent
  local tset = {}
  for _, t in ipairs(targets) do tset[t] = true end
  for j = 1, NLOOP do
    local gj = S.group_of[j] or 0
    if not tset[j] and not (g > 0 and gj == g) and (gj > 0 or super) and LPF.excl_alive(j) then
      local st = S.loopers[j].state or 0
      if st >= 2 and st <= 6 then running[#running + 1] = j end
    end
  end
  local function stop_now()
    for _, j in ipairs(running) do gmem_write_cmd(j, 3); S.loopers[j].playing = false end
  end
  local solo_sync = (not super) and LPF.excl_solo_running() and sync_state(p) ~= 0   -- en SUPER : pas de looper seul privilegie, synchro independante

  local function start_free_job(deferred)
    if solo_sync then
      elog("info", "EXCLU : REC groupe %d en SYNC sur le maitre actif (looper solo en lecture)", g)
      EXCL.job = nil
    else
      if not deferred then LPF.sync_release(p) end
      EXCL.job = { group = g, members = fresh, p = p, phase = "rec", t0 = now(), seen = false, deferred = deferred, release_on_start = deferred }
      elog("info", "EXCLU : REC groupe %d, synchro desactivee ; verrouillage sur le looper %d a la fin du REC", g, fresh[1])
    end
  end

  local ss = sync_state(p)
  elog("info", "EXCLU REC : groupe %d | vides=%d avec_boucle=%d | autres groupes en lecture=%d | synchro part %d = %s",
      g, #fresh, #loops, #running, p, ss == 1 and "looper maitre" or (ss == 2 and "Host" or "aucune"))
  if #running == 0 then                                        -- personne d'autre ne joue : rien a attendre
    EXCL.note = "IMMEDIAT (aucun autre groupe en lecture)"
    if #fresh > 0 then start_free_job(false) end
    return false
  end
  if ss == 0 then
    -- un groupe joue mais la synchro n'est plus verrouillee : on la remet sur son premier looper, puis on arme (au bloc suivant)
    if LPF.sync_lock_looper(running[1], p) then
      elog("warn", "EXCLU : synchro absente -> reverrouillee sur le looper %d, basculement dans un instant", running[1])
      EXCL.job = { phase = "arm_later", t0 = now(), g = g, p = p, running = running, fresh = fresh, loops = loops, solo_sync = false }
      EXCL.note = "ATTENTE (synchro reverrouillee)"
      return true
    end
    elog("warn", "EXCLU : pas de synchro active -> basculement IMMEDIAT (rien a attendre)")
    EXCL.note = "IMMEDIAT (aucune synchro)"
    stop_now()
    if #fresh > 0 then start_free_job(false) end
    return false
  end
  LPF.excl_arm_switch(g, p, running, fresh, loops, solo_sync)
  EXCL.note = "ATTENTE du synchro point"
  return true
end
function VL.excl_job_tick(t)
  local job = EXCL.job
  if not job then return end
  if job.phase == "rec" then
    local any_rec, all_done = false, true
    for _, i in ipairs(job.members) do
      local L = S.loopers[i]
      if LPF.excl_rec_state(L.state or 0) then any_rec = true; all_done = false
      elseif (L.length or 0) <= 0 then all_done = false end
    end
    if not job.seen then
      if any_rec then
        job.seen = true
        if job.release_on_start then LPF.sync_release(job.p) end      -- les loopers du groupe enregistrent librement
      elseif t - job.t0 > (job.deferred and 120 or 3.0) then
        if job.deferred then LPF.excl_cancel_armed() end
        EXCL.job = nil
      end
      return
    end
    if all_done then
      local f = job.members[1]
      local fp = S.loopers[f].part or job.p
      if LPF.sync_lock_looper(f, fp) then
        elog("info", "EXCLU : synchro verrouillee sur le looper %d (groupe %d)", f, job.group)
        job.phase, job.t1, job.f, job.p = "adopt", t, f, fp
      else
        EXCL.job = nil
      end
    elseif not any_rec then
      EXCL.job = nil                              -- REC annule (looper vide apres arret)
    end
  elseif job.phase == "arm_later" then
    if t - job.t0 >= 0.25 then
      EXCL.job = nil
      LPF.excl_arm_switch(job.g, job.p, job.running, job.fresh, job.loops, job.solo_sync)
    end
  elseif job.phase == "switch" then
    local all_dub = true
    for _, m in ipairs(job.members) do if (S.loopers[m].state or 0) ~= 3 then all_dub = false end end
    if all_dub then
      if not job.keep then                         -- plus de solo : la synchro suit le groupe qui joue (premier looper)
        if LPF.sync_lock_looper(job.members[1], job.p) then
          elog("info", "EXCLU : synchro verrouillee sur le looper %d (groupe %d)", job.members[1], job.group)
        end
      end
      EXCL.job = nil
    elseif t - job.t0 > 120 then
      LPF.excl_cancel_armed(); EXCL.job = nil
    end
  elseif job.phase == "adopt" then
    if t - job.t1 > 4.0 then EXCL.job = nil return end
    if t - job.t1 >= 0.08 and LPF.looper_ref(job.f) > 0 then      -- le maitre a cree sa reference : les autres l'adoptent
      for _, m in ipairs(job.members) do
        if m ~= job.f and LPF.excl_alive(m) then gmem_write_cmd(m, 28, job.f) end
      end
      EXCL.job = nil
    end
  end
end

local function exec(action, args, targets)
  if action == "rec_overdub" and S.exclusive and VL.excl_before_rec(targets) then return end   -- REC differe au synchro point
  local def = ACTIONS[action]
  if not def then log("error", "action inconnue : %s", tostring(action)) return end
  -- RESET : une operation par parametre, cadencee (un seul slot gmem par type de commande et par looper)
  -- RESET / RESET ALL : une seule commande JSFX (24) par looper. Looper VIDE : tout est remis a zero,
  -- volume compris ; looper contenant une boucle : tout sauf le volume (decide cote JSFX via length).
  if action == "reset" or action == "reset_all" then
    local list = targets
    if action == "reset_all" then list = {}; for i = 1, NLOOP do list[i] = i end end
    for _, t in ipairs(list) do
      VL.queue_op({ action = "reset_params", targets = { t } })
      local L = S.loopers[t]
      L.speed, L.pitch = 1, 0
      if (L.length or 0) <= 0 then L.out_vol = 1.0 end
      for _, k in ipairs({ "rev", "pingpong", "oneshot", "cloud", "slicer", "link" }) do L[k] = false end
    end
    log("info", "%s -> %d looper(s)", action, #list)
    return
  end
  -- CLEAR ALL / CLEAR ALL FULL : global — une seule diffusion + reset miroir de TOUS les loopers
  if action == "clear_all" or action == "clear_all_full" then
    VL.backend.send(1, action, nil)   -- broadcast (looper ignore)
    for i = 1, NLOOP do VL.scn_op(action, i, nil) end   -- [SCN]
    local all_parts = (action == "clear_all_full")
    for i = 1, NLOOP do reset_looper(i, all_parts) end
    log("info", "%s -> toutes les instances", action)
    return
  end
  if def.kind == "toggle" then
    -- Mode A (toggles) : chaque cible bascule depuis SON etat courant.
    -- Les inversions relatives dans un groupe sont conservees (reverse, slicer, cloud, rec...).
    -- Seules les actions ponctuelles (trig : clear, undo, steps...) restent communes absolues.
    for _, t in ipairs(targets) do
      local cur = S.loopers[t][def.key] and true or false
      local want = not cur
      if want and def.excl then                       -- ex. REC <-> REPLACE : l'un coupe l'autre
        for _, ex in ipairs(def.excl) do
          if S.loopers[t][ACTIONS[ex].key] then send(t, ex, false) end
        end
      end
      send(t, action, want)
    end
  else
    for _, t in ipairs(targets) do
      send(t, action, args)
      if def.reset then reset_looper(t, def.reset == "all") end
    end
  end
  log("info", "%s%s -> %s%s", action, args and (" " .. tostring(args)) or "", table.concat(targets, ","), (action == "rec_overdub" and EXCL.note) and ("  [EXCLU : " .. EXCL.note .. "]") or "")
  EXCL.note = nil
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
  local def = ACTIONS[action]
  -- Les actions "trig" (pas de pitch/speed/volume, undo, clear...) s'EMPILENT : chaque appui = une operation a rejouer au fire.
  -- Les toggles / selections se desarment en re-appuyant (sinon deux appuis s'annuleraient au fire).
  if not (def and def.kind == "trig") then
    for i, a in ipairs(S.armed) do
      if a.key == key then table.remove(S.armed, i) log("info", "desarme %s", key) return end
    end
  end
  S.armed[#S.armed + 1] = { action = action, args = args, targets = targets, key = key }
  log("info", "arme %s (%d en file)", key, #S.armed)
end

function VL.toggle_launch()
  S.launch = not S.launch
  if not S.launch then S.armed = {} end         -- quitter Launch annule les actions armees
  log("info", "mode Launch %s", S.launch and "ON" or "OFF")
end

-- LAUNCH / GO sur un seul pad : OFF -> active la memorisation ; ON -> execute tout ce qui est arme (Go) et quitte Launch
function VL.launch_go()
  if not S.launch then
    S.launch, S.armed = true, {}
    log("info", "mode Launch ON : les operations sont memorisees")
  else
    VL.fire()
  end
end

-- appui long : quitte Launch SANS rien executer
function VL.launch_cancel()
  if S.launch then
    S.launch, S.armed = false, {}
    log("info", "mode Launch OFF : operations annulees")
  end
end

-- Chaque looper n'a qu'UN slot de commande gmem : ecrire plusieurs commandes dans le meme cycle ne laisse que la derniere.
-- Le fire met donc les operations en file et les envoie dans l'ordre, au plus UNE par looper tous les FIRE_GAP_S
-- (des loopers differents partent en meme temps).
local FIRE_GAP_S = 0.08
local fire_queue, fire_last = {}, -1e9

function LPF.fire_lanes(a)
  local def = ACTIONS[a.action]
  if def and def.global then
    local all = {}
    for i = 1, NLOOP do all[i] = i end
    return all
  end
  return a.targets
end

function VL.queue_op(a) fire_queue[#fire_queue + 1] = a end

function VL.fire_pump(t)
  if #fire_queue == 0 then return end
  t = t or now()
  if t - fire_last < FIRE_GAP_S then return end
  fire_last = t
  local used = {}
  local i = 1
  while i <= #fire_queue do
    local a = fire_queue[i]
    local lanes, free = LPF.fire_lanes(a), true
    for _, l in ipairs(lanes) do if used[l] then free = false end end
    for _, l in ipairs(lanes) do used[l] = true end     -- meme saute : les suivantes du meme looper ne passent pas devant
    if free then
      table.remove(fire_queue, i)
      exec(a.action, a.args, a.targets)
    else
      i = i + 1
    end
  end
  if #fire_queue == 0 then
    log("info", "fire : toutes les operations envoyees")
    if VL.scn_on() then VL.scn_emit("done") end   -- [SCN]
  end
end

function VL.fire()                       -- execute tout ce qui est arme (dans l'ordre), puis quitte le mode Launch
  local list = S.armed
  S.armed = {}
  S.launch = false
  if VL.scn_on() then VL.scn_emit("go") end   -- [SCN] capture : le GO valide automatiquement le pas
  for _, a in ipairs(list) do fire_queue[#fire_queue + 1] = a end
  log("info", "fire : %d operation(s), mode Launch OFF", #list)
  VL.fire_pump(now())
end

-- Pedal Board : si un switch du pedalier virtuel est arme (mode PROG), le prochain pad n'execute rien :
-- il publie l'action visee dans ExtState "NowUndo_Pedal/capture".
local function pedal_capture_action(action, args)
  local hb = tonumber(reaper.GetExtState("NowUndo_Pedal", "armed_hb")) or 0
  if reaper.time_precise() - hb > 0.6 then return false end
  reaper.SetExtState("NowUndo_Pedal", "capture", string.format("%.6f\tcmd\t%s\t%s\t\t\t\t%s",
    reaper.time_precise(), tostring(action), args ~= nil and tostring(args) or "", tostring(action)), false)
  return true
end

-- NAVIGATION AUTO du Twister : une action du Launchpad amene le Twister sur la page utile.
-- Valeur = BOUTON de page Twister (v3.3 : 1 Vol/Feedback, 2 Pitch/Speed, 3 In/Out, 4 Slicer, 5 Cloud, 6 Effets).
-- RELACHE -> retour sur Volume (page 1) : couper Slicer / Cloud, pitch qui revient a 0, speed qui revient a 100 %,
-- Reset Pitch / Reset Speed (et desactiver un effet : voir la couche Effects).
-- (champs de VL et non locales : le chunk principal est a la limite Lua de 200 variables locales)
VL.AUTO_TW = { slicer = 4, cloud = 5, speed_step = 2, pitch_step = 2, reset_pitch = 1, reset_speed = 1,
               rec_overdub = 1, rerec = 1, clear_all = 1, clear_all_full = 1, quantise_inout = 3 }
function VL.auto_twister(action, targets, args)
  local pg = VL.AUTO_TW[action]
  if not pg then return end                      -- (le miroir interactif navigue aussi : son etat est synchronise)
  if action == "slicer" or action == "cloud" then
    local def = ACTIONS[action]
    if def and toggle_on(def.key, targets) then pg = 1 end            -- on coupe le mode -> Volume
  elseif action == "pitch_step" or action == "speed_step" then
    local L = S.loopers[ref_looper(targets)] or {}
    local st = tonumber(args) or 12
    if action == "pitch_step" then
      local np = math.max(-48, math.min(48, (L.pitch or 0) + st))
      if math.abs(np) < 0.01 then pg = 1 end                          -- pitch revenu a 0 -> Volume
    else
      local ns = math.max(0.01, math.min(100, (L.speed or 1) * (2 ^ (st / 12))))
      if math.abs(ns - 1) < 0.001 then pg = 1 end                     -- speed revenu a 100 % -> Volume
    end
  end
  VL.set_fighter_page(pg)
end

function VL.trigger(action, args, targets)    -- targets : cibles explicites (couches), sinon looper / groupe actif
  if pedal_capture_action(action, args) then return end
  targets = targets or VL.targets()
  VL.auto_twister(action, targets, args)
  if S.launch then arm(action, args, targets) else exec(action, args, targets) end
end

--------------------------------------------------------------------------
-- Routing (IN1-4 / FX1-4 / L1-8) + garde-fou feedback
--------------------------------------------------------------------------
-- Seuls les loopers peuvent former une boucle (L -> L) : les IN n'ont pas d'entree et les effets sont en insert.
function LPF.compute_feedback()
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
  local fb, out, R = LPF.compute_feedback(), {}, S.routing
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
  if kind == "looper" and not VL._scn_quiet then VL.scn_op("fx" .. slot, id, tostring(value)) end   -- [SCN] capture : e<slot> on/off
  return true
end
function VL.toggle_fx(kind, id, slot) return VL.set_fx(kind, id, slot, not S.fx[kind][id][slot]) end
-- NAVIGATION AUTO (geste utilisateur sur un pad d'effet) : effet active -> Twister page Effets sur CET effet
-- (source + slot du FX Router). Effet desactive : si un autre effet reste actif sur la MEME source (looper / entree),
-- on reste sur la page Effets, positionne sur un effet encore actif ; plus aucun effet actif -> page Volume.
-- Slot vide : rien.
function VL.fx_nav(kind, id, slot)
  if not S.fx_present[kind][id][slot] then return end
  local on_slot = S.fx[kind][id][slot] and slot or nil
  if not on_slot then
    for k = 1, NSLOT do if S.fx_present[kind][id][k] and S.fx[kind][id][k] then on_slot = k break end end
  end
  if on_slot then
    S.fx_source = (kind == "input") and id or (NIN + id)
    VL.publish_fx_source()
    VL.set_fx_slot(on_slot)
    VL.set_fighter_page(6)
  else
    VL.set_fighter_page(1)
  end
end

function VL.set_fx_present(kind, id, slot, present)     -- feedback backend : un slot vide ne peut pas etre actif
  S.fx_present[kind][id][slot] = present and true or false
  if not present then S.fx[kind][id][slot] = false end
end

function VL.set_route(kind, a, b, value)
  dbg("set_route %s %s->%s = %s", tostring(kind), tostring(a), tostring(b), tostring(value))
  local m = S.routing[kind]
  if kind == "l_l" and a == b then log("debug", "L%d -> L%d desactive", a, b) return false end
  if m[a][b] == value then return false end
  m[a][b] = value
  if value and S.cfg.feedback_policy == "block" and LPF.compute_feedback()[kind .. ":" .. a .. ":" .. b] then
    m[a][b] = false
    log("warn", "route %s %d->%d refusee : creerait une boucle de feedback", kind, a, b)
    return false
  end
  notify_routing()
  -- Mute auto : toujours recalculer apres un changement IN->L
  if kind == "in_l" then
    VL.update_input_mutes()
  end
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

function LPF.init_presets()
  for name, bank in pairs(BANKS) do
    S.presets[name].active = 1
    S.presets[name].slots = { [1] = bank.get() }
  end
end

function VL.preset_press(name, n)
  local p, bank = S.presets[name], BANKS[name]
  if p.active == n then return end
  local existed = p.slots[n] ~= nil
  p.slots[p.active] = bank.get()                       -- validation implicite de l'ancien
  if p.slots[n] then bank.set(p.slots[n]) else p.slots[n] = bank.get() end
  p.active = n
  log("info", "preset %s %d actif", name, n)
  if existed and not VL._scn_quiet and VL.scn_on and VL.scn_on() then   -- [SCN] capture : r(n) / g(n)
    VL.scn_emit("glob\t" .. (name == "routing" and "r" or "g") .. "(" .. n .. ")")
  end
end

function VL.preset_revert(name, n)
  local p, bank = S.presets[name], BANKS[name]
  if p.active == n and p.slots[n] then bank.set(p.slots[n]) log("info", "preset %s %d : revert", name, n) end
end

-- appui long sur le 1er preset : efface TOUS les presets de la banque (apres confirmation) ; le preset 1 garde l'etat actuel
function VL.preset_erase(name)
  local p, bank = S.presets[name], BANKS[name]
  p.slots = { [1] = bank.get() }; p.active = 1
  log("info", "presets %s : tous effaces", name)
end
function VL.preset_erase_confirm(name)
  if VL.mirror_mode then return end
  local what = (name == "routing") and "routing" or "groupe"
  local ok = true
  if reaper and reaper.MB then
    ok = reaper.MB("Effacer tous les presets de " .. what .. " ?\n(le preset 1 est conserve avec l'etat actuel)", "NowUndo - presets de " .. what, 4) == 6
  end
  if ok then VL.preset_erase(name) end
end

--------------------------------------------------------------------------
-- Bindings : (page,row,col) -> { short = ..., long = ... }
--------------------------------------------------------------------------
local function act(action, args) return { kind = "action", action = action, args = args } end
local function act_on(looper, action, args) return { kind = "action", action = action, args = args, targets = { looper } } end
local function fn(f, led)       return { kind = "fn", fn = f, led = led } end

local BIND = {}
for p = 1, NPAGE do BIND[p] = {} end
-- instant = true : l'action courte part a l'appui ; l'action longue s'ajoute au seuil (1 s).
-- Sans instant, un pad qui a une action longue differe son action courte jusqu'au relachement.
-- defer   : l'appui court n'agit qu'au relachement, et seulement si le pad n'a pas servi de "maintien".
-- Exception volontaire : LAUNCH/GO reste differe, car un maintien doit annuler sans executer GO.
-- release : action au RELACHEMENT, seulement si l'appui etait court (l'appui long n'a pas tire)
local function bind(page, row, col, short, long, instant, defer, release)
  BIND[page][row .. "," .. col] = { short = short, long = long, instant = instant, defer = defer, release = release }
end
local function bind_all(row, col, short, long, instant, defer, release)
  for p = 1, NPAGE do bind(p, row, col, short, long, instant, defer, release) end
end

-- global : top row, groupes, pages
-- appui = selection ; appui long (1 s) = ouvre / ferme la fenetre du looper
-- APPUI : selectionne tout de suite ce looper et ferme la fenetre d'un AUTRE looper
-- RELACHEMENT d'un appui court : ferme la fenetre de ce looper si elle est ouverte
-- APPUI LONG (1 s) : ouvre la fenetre du looper selectionne
for i = 1, NLOOP do
  bind_all(0, i, fn(function() VL.looper_button_press(i) end, function() return S.sel_looper == i and "on" or "idle" end),
                 fn(function() VL.looper_button_long(i) end), true, nil,
                 fn(function() VL.looper_button_release(i) end))
end
-- GROUP n : tap = selectionne / quitte le groupe (cf. VL.select_group). MAINTENU + tap sur un looper (rangee du haut)
-- = ajoute / retire ce looper du groupe. Avec Ctrl enfonce, le tap choisit le groupe edite (cf. VL.group_pad_tap).
for g = 1, NGROUP do
  bind_all(g, 9, fn(function() VL.group_pad_tap(g) end, function() return S.sel_group == g and "on" or "idle" end), nil, false, true)
end
for p = 1, NPAGE do bind_all(NGROUP + p, 9, fn(function() VL.set_page(p) end, function() return S.page == p and "on" or "idle" end)) end

-- Page 1 : Main
-- row 0 = selection loopers | row 1 = statut loopers | rows 2-5 = ancienne grille 1-4 decalee

-- Appui intelligent sur le pad statut (rangee 1) : sort du mode affiche, sinon play/stop
function VL.status_pad_tap(i)
  local L = S.loopers[i]
  if not L then return end
  VL.select_looper(i)
  local function do_send(action, want)
    local def = ACTIONS[action]
    local cur = def and def.key and (L[def.key] and true or false) or false
    if want ~= nil and cur == (want and true or false) then return end
    send(i, action, want ~= nil and want or (not cur))
  end
  if L.wait_sync or L.rec_led or L.overdub or L.rec then
    do_send("rec_overdub", false)
  elseif L.replace then
    do_send("replace", false)
  elseif L.multiply then
    do_send("multiply", false)
  elseif L.playing then
    if L.cloud then do_send("cloud", false)
    elseif L.slicer then do_send("slicer", false)
    elseif L.rev then do_send("reverse", false)
    else do_send("stop_play", false) end
  else
    if L.cloud then do_send("cloud", false)
    elseif L.slicer then do_send("slicer", false)
    elseif L.rev then do_send("reverse", false)
    elseif (L.length or 0) > 0 then do_send("stop_play", true)
    end
  end
  if VL.sync_out then VL.sync_out() end
end

for n = 1, 8 do bind(1, 2, n, fn(function() VL.set_fighter_page(n) end, function() return S.fighter_page == n and "on" or "idle" end)) end   -- 7 Custom, 8 Display (ex Prev / Next looper)

-- Rangee statut (row 1) : appui intelligent play/stop / sortie de mode
for i = 1, NLOOP do
  bind(1, 1, i, fn(function() VL.status_pad_tap(i) end))
end


-- Twister pages (rangee 2 apres decalage statut)
PAD_LABEL[1]["2,1"] = "Twister 1 Vol/Feedback"   -- pages 1 et 3 permutees (Twister v3.3)
PAD_LABEL[1]["2,2"] = "Twister 2 Pitch/Speed"
PAD_LABEL[1]["2,3"] = "Twister 3 In/Out"
PAD_LABEL[1]["2,4"] = "Twister 4 Slicer"
PAD_LABEL[1]["2,5"] = "Twister 5 Cloud"
PAD_LABEL[1]["2,6"] = "Twister 6 Effects"
PAD_LABEL[1]["2,7"] = "Twister 7 Custom"
PAD_LABEL[1]["2,8"] = "Twister 8 Display"
PAD_RGB[1]["2,6"] = PAD_RGB[1]["2,5"] or 0x666666

-- (pads 2,7 / 2,8 : ex Previous / Next looper -> pages Twister 7 et 8 ; Prev / Next restent dans le MIDI Learn et le pedalier)
for n = 1, NPRESET do
  for r, bank in ipairs({ "routing", "group" }) do
    bind(1, 2 + r, n,   -- routing=row3, group=row4
      fn(function() VL.preset_press(bank, n) end, function()
        local p = S.presets[bank]
        return p.active == n and "on" or (p.slots[n] and "idle" or "off")
      end),
      fn(function() if n == 1 then VL.preset_erase_confirm(bank) else VL.preset_revert(bank, n) end end))
  end
end
-- LAUNCH / GO : un appui active la memorisation, l'appui suivant execute tout (Go) ; appui long = annuler sans executer
VL._lp_rgb = PAD_RGB[1]["5,1"]
bind(1, 5, 1, fn(function() VL.launch_go() end,
                 function()   -- [SCN] pad rouge pendant la capture du scenario
                   if VL.scn_on() then PAD_RGB[1]["5,1"] = 0xFF2020; PAD_LABEL[1]["5,1"] = "LAUNCH / GO  [CAPTURE ACTIVE]"
                   else PAD_RGB[1]["5,1"] = VL._lp_rgb; PAD_LABEL[1]["5,1"] = "LAUNCH / GO (long = capture scenario)" end
                   return S.launch and (#S.armed > 0 and "armed" or "on") or "idle"
                 end),
               fn(function() VL.launch_cancel(); VL.scn_cmd("toggle") end))   -- [SCN] long : capture on/off ; court volontairement differe pour proteger GO
PAD_LABEL[1]["5,1"] = "LAUNCH / GO (long = capture scenario)"
-- SYNC / UNSYNC du module Master Sync : court = part en cours (Main/Chorus/Bridge), long = les 3 parts. Allume = synchro engagee.
bind(1, 5, 2, fn(function() if pedal_capture_action("sync_toggle") then return end VL.sync_toggle(false) end, function() return VL.sync_is_on() and "on" or "idle" end),
               fn(function() if pedal_capture_action("sync_toggle_all") then return end VL.sync_toggle(true) end), true)
PAD_LABEL[1]["5,2"] = "SYNC/UNSYNC"; PAD_RGB[1]["5,2"] = 0x40C0FF   -- court = part en cours, long = 3 parts
bind(1, 5, 7, act("quantise_inout"))
bind(1, 5, 8, act("full_loop"))
-- Miroirs FX : helpers (les binds sont UNIQUEMENT sur D5-D8 = 5,5..5,8 plus bas).
-- Maintenir PAGE 1 (5,9) puis appuyer sur D5-D8 pour changer le mode Toggle/Gate du slot.
local FX_MIRROR_EXT = "VirtualLaunchpad_FX_Mirror"
local function fx_mirror_mode(source, slot)
  local value = reaper.GetExtState(FX_MIRROR_EXT, "mode_" .. source .. "_" .. slot)
  return value == "gate" and "gate" or "toggle"
end
local function fx_mirror_set_mode(source, slot, mode)
  reaper.SetExtState(FX_MIRROR_EXT, "mode_" .. source .. "_" .. slot, mode, true)
  log("info", "FX miroir source %d slot %d : mode %s", source, slot, mode:upper())
end

-- [SCN] ex pads MAIN / CHORUS / BRIDGE (l'action "part" reste disponible, ex. par MIDI learn) -> commandes du scenario
bind(1, 6, 1, fn(function() VL.scn_cmd("validate") end, function() return VL.scn_on() and "on" or "idle" end))
bind(1, 6, 2, fn(function() VL.scn_cmd("prev") end, function() return "idle" end))
bind(1, 6, 3, fn(function() VL.scn_cmd("next") end, function() return "idle" end))
PAD_LABEL[1]["6,1"] = "VALIDER (scenario)"; PAD_LABEL[1]["6,2"] = "PAS PRECEDENT (scenario)"; PAD_LABEL[1]["6,3"] = "PAS SUIVANT (scenario)"
PAD_RGB[1]["6,1"] = 0x33DD66; PAD_RGB[1]["6,2"] = 0x66CCFF; PAD_RGB[1]["6,3"] = 0x66CCFF
bind(1, 6, 4, act("speed_step", -12)); bind(1, 6, 5, act("speed_step", 12))
bind(1, 6, 6, act("pitch_step", -12)); bind(1, 6, 7, act("pitch_step", 12))
bind(1, 6, 8, act("link"))
bind(1, 7, 1, act("auto"));    bind(1, 7, 3, act("restart"));  bind(1, 7, 4, act("reverse"), act("auto_rev"), true)
bind(1, 7, 5, act("cloud"));   bind(1, 7, 6, act("slicer"));   bind(1, 7, 7, act("redo")); bind(1, 7, 8, act("undo"))
-- EXCLU : un seul groupe joue ; changement de groupe au synchro point commun (ancien pad CLEAR ALL)
bind(1, 8, 1, fn(function() if pedal_capture_action("excl_toggle") then return end VL.excl_toggle() end,
                 function() return VL.excl_led() end),
               fn(function() if pedal_capture_action("excl_super_toggle") then return end VL.excl_super_toggle() end), true)
PAD_LABEL[1]["8,1"] = "EXCLU"; PAD_RGB[1]["8,1"] = 0xFFD000
-- CLEAR : appui simple = partie active des loopers cibles ;
-- appui long = les 3 parties de chacun des loopers cibles (jusqu'a 3 loopers) ;
-- double clic = efface les 3 parties des 8 loopers.
bind(1, 8, 2, act("clear"), act("clear_full"), true)
BIND[1]["8,2"].double = act("clear_all_full")
-- RESET : appui simple = reset des loopers cibles ; double clic = RESET ALL (8 loopers).
-- Pas d'action longue sur RESET.
bind(1, 7, 2, act("reset"), nil, true)
BIND[1]["7,2"].double = act("reset_all")
PAD_LABEL[1]["7,2"] = "RESET"; PAD_RGB[1]["7,2"] = 0xFF8040
bind(1, 8, 3, act("one_shot"))
-- one_shot et reverse ont echange leurs places : couleurs / libelles suivent
PAD_RGB[1]["7,4"], PAD_RGB[1]["8,3"] = PAD_RGB[1]["8,3"], PAD_RGB[1]["7,4"]
PAD_LABEL[1]["7,4"], PAD_LABEL[1]["8,3"] = PAD_LABEL[1]["8,3"], PAD_LABEL[1]["7,4"]
bind(1, 8, 4, act("stop_play")); bind(1, 8, 5, act("multiply")); bind(1, 8, 6, act("replace"))
-- [REC>DUB] Appui long sur REC.
-- REC est toujours declenche IMMEDIATEMENT a l'appui (jamais au relachement).
-- Si le looper etait vide au debut de cet enregistrement, un appui long annule
-- le REC en cours puis CLEAR la prise provisoire. Sur un looper deja enregistre,
-- l'appui long conserve le mode historique REC -> OVERDUB.
VL.rec_dub_rgb = PAD_RGB[1]["8,8"]
VL._rd = { prev = {}, first = {}, len = {} }
function VL.rec_dub_apply()
  PAD_RGB[1]["8,8"] = VL.rec_dub and 0xCC5500 or VL.rec_dub_rgb
end
function VL.rec_dub_toggle()
  VL.rec_dub = not VL.rec_dub
  if reaper and reaper.SetExtState then reaper.SetExtState("nowundo_vl", "rec_dub", VL.rec_dub and "1" or "0", true) end
  VL.rec_dub_apply()
  log("info", "REC -> OVERDUB a la sortie du 1er rec : %s", VL.rec_dub and "ON" or "OFF")
end

-- Geste long sur REC : les loopers vides ont deja commence a enregistrer a l'appui.
-- On arrete donc ce REC immediatement puis on efface la prise temporaire.
-- Les loopers qui contenaient deja une boucle gardent le comportement REC>DUB historique.
function VL.rec_pad_long()
  local targets = VL.targets()
  local handled_empty, handled_existing = false, false
  for _, i in ipairs(targets) do
    local L = S.loopers[i]
    local was_empty = VL._rd.first[i] == true
    if not was_empty then
      was_empty = ((VL._rd.len[i] or L.length or 0) <= 0)
    end
    if was_empty then
      handled_empty = true
      -- La commande REC est un toggle : le second envoi termine le REC demarre a l'appui.
      send(i, "rec_overdub", false)
      send(i, "clear", nil)
      reset_looper(i, false)
      VL._rd.first[i] = false
      log("info", "REC long L%d : prise vide annulee et clear", i)
    else
      handled_existing = true
    end
  end
  if handled_existing or not handled_empty then VL.rec_dub_toggle() end
end

VL.rec_dub = (reaper and reaper.GetExtState and reaper.GetExtState("nowundo_vl", "rec_dub") == "1") or false
VL.rec_dub_apply()
-- surveille chaque looper : fin du PREMIER rec (1 ou 8 -> 2 sur boucle vide au depart) => rec_overdub envoye une fois de plus.
-- Envoi direct au backend (pas d'evenement de capture scenario : la ligne enregistree reste "rec off").
function VL.rec_dub_tick()
  if VL.mirror_mode then return end
  local R = VL._rd
  for i = 1, NLOOP do
    local L = S.loopers[i]
    if L then
      local st = L.state or 0
      local prev = R.prev[i] or 0
      if st ~= 1 and st ~= 7 and st ~= 8 then R.len[i] = L.length or 0 end
      if (st == 1 or st == 7 or st == 8) and prev ~= 1 and prev ~= 7 and prev ~= 8 then
        R.first[i] = (R.len[i] or 0) <= 0
      end
      if (prev == 1 or prev == 8) and st == 2 then
        if VL.rec_dub and R.first[i] then VL.backend.send(i, "rec_overdub", true) end
        R.first[i] = false
      end
      R.prev[i] = st
    end
  end
end
-- commandes externes (script MIDI learn) : ExtState NowUndo_VLcmd/q = lignes "nom<TAB>temps"
function VL.ext_cmd_poll()
  if VL.mirror_mode or not (reaper and reaper.GetExtState) then return end
  local c = reaper.GetExtState("NowUndo_VLcmd", "q")
  if c == "" then return end
  reaper.SetExtState("NowUndo_VLcmd", "q", "", false)
  local t = reaper.time_precise()
  for line in c:gmatch("[^\n]+") do
    local name, ts = line:match("^(%a[%w_]*)\t([%d%.]+)")
    if name == "rec_dub_toggle" and ts and t - tonumber(ts) < 2 then VL.rec_dub_toggle() end
    -- R(n) / G(n) du script Scenario : meme geste qu'un appui sur le pad du slot n, mais RAPPEL seulement (slot vide : rien)
    local pbank, pn = (name or ""):match("^preset_(%a+)_(%d+)$")
    if pbank and ts and t - tonumber(ts) < 2 and (pbank == "routing" or pbank == "group") then
      pn = tonumber(pn)
      if pn >= 1 and pn <= NPRESET and S.presets[pbank].slots[pn] then
        VL._scn_quiet = true; VL.preset_press(pbank, pn); VL._scn_quiet = false
      end
    end
    -- sync / unsync / syncall / unsyncall du script Scenario (comme le pad SYNC/UNSYNC, sans bascule)
    if (name == "sync_on" or name == "sync_off" or name == "sync_all_on" or name == "sync_all_off") and ts and t - tonumber(ts) < 2 then
      VL._scn_quiet = true
      VL.sync_set(name:find("_on", 1, true) ~= nil, name:find("_all_", 1, true) ~= nil)
      VL._scn_quiet = false
    end
    -- e<n> du script Scenario : effet n du looper i (page Effects), comme un appui sur son pad : on / off / tog
    local fi, fs, fa = (name or ""):match("^fx_(%d+)_(%d+)_(%a+)$")
    if fi and ts and t - tonumber(ts) < 2 then
      fi, fs = tonumber(fi), tonumber(fs)
      if fi >= 1 and fi <= NLOOP and fs >= 1 and fs <= NSLOT then
        VL._scn_quiet = true
        if fa == "on" then VL.set_fx("looper", fi, fs, true)
        elseif fa == "off" then VL.set_fx("looper", fi, fs, false)
        elseif fa == "tog" then VL.toggle_fx("looper", fi, fs) end
        VL._scn_quiet = false
      end
    end
    -- fxin_<n>_<slot>_<on|off|tog> : effet d'une ENTREE (page web Twister / Effets)
    local ii, is_, ia = (name or ""):match("^fxin_(%d+)_(%d+)_(%a+)$")
    if ii and ts and t - tonumber(ts) < 2 then
      ii, is_ = tonumber(ii), tonumber(is_)
      if ii >= 1 and ii <= NIN and is_ >= 1 and is_ <= NSLOT then
        if ia == "on" then VL.set_fx("input", ii, is_, true)
        elseif ia == "off" then VL.set_fx("input", ii, is_, false)
        elseif ia == "tog" then VL.toggle_fx("input", ii, is_) end
      end
    end
  end
end
bind(1, 8, 7, act("rerec"));     bind(1, 8, 8, act("rec_overdub"), fn(function() VL.rec_pad_long() end), true) -- REC + sortie REC immediats a l'appui ; long = annule/clear si vide

-- [LAYOUT] page 1 final (notation échiquier, A = bas) — permutation SANS toucher D3-D8 :
--   A1 CLEAR | A2 RESET | B1 FULL LOOP | B2 QUANTISE | C2 EXCLU | C3 SYNC
--   D2 PAS PRECEDENT | D3 PAS SUIVANT | D4 AUTO | D5-D8 FX (poses explicitement apres)
do
  local MOVE = {
    ["8,1"] = "6,2",  -- EXCLU -> C2
    ["8,2"] = "8,1",  -- CLEAR -> A1
    ["7,2"] = "8,2",  -- RESET -> A2
    ["5,2"] = "6,3",  -- SYNC -> C3
    ["5,7"] = "7,2",  -- QUANTISE -> B2
    ["5,8"] = "7,1",  -- FULL LOOP -> B1
    ["6,2"] = "5,2",  -- PAS PRECEDENT -> D2
  }
  for _, map in ipairs({ BIND[1], PAD_LABEL[1], PAD_RGB[1] }) do
    local old = {}
    for from in pairs(MOVE) do old[from] = map[from] end
    for from, to in pairs(MOVE) do map[to] = old[from] end
  end
end

-- === RANGEE D (row 5) : positions FINALES, jamais d'FX sur D3/D4 ===
-- D3 = pas suivant scenario
bind(1, 5, 3, fn(function() VL.scn_cmd("next") end, function() return "idle" end))
PAD_LABEL[1]["5,3"] = "PAS SUIVANT (scenario)"
PAD_RGB[1]["5,3"] = 0x66CCFF
-- D4 = AUTO
bind(1, 5, 4, act("auto"))
PAD_LABEL[1]["5,4"] = "AUTO"
PAD_RGB[1]["5,4"] = 0x9999FF
-- D5-D8 = miroirs FX 1..4 uniquement
do
  for n = 1, NSLOT do
    local slot = n
    local function fx_target()
      local source = clamp(S.fx_source or (NIN + clamp(S.sel_looper or 1, 1, NLOOP)), 1, NIN + NLOOP)
      if source <= NIN then return "input", source end
      return "looper", source - NIN
    end
    local function fx_targets()
      local kind, id = fx_target()
      if kind == "looper" then
        local g = S.group_of[id] or 0
        if g ~= 0 then
          local list = {}
          for _, m in ipairs(VL.group_members(g)) do list[#list + 1] = { "looper", m } end
          if #list > 0 then return list end
        end
      end
      return { { kind, id } }
    end
    local function fx_pad_action()
      local kind, id = fx_target()
      local value = not S.fx[kind][id][slot]
      for _, tg in ipairs(fx_targets()) do VL.set_fx(tg[1], tg[2], slot, value) end
      VL.fx_nav(kind, id, slot)
    end
    local function fx_pad_state()
      local kind, id = fx_target()
      if not S.fx_present[kind][id][slot] then return "off" end
      return S.fx[kind][id][slot] and "on" or "idle"
    end
    local mirror_binding = fn(fx_pad_action, fx_pad_state)
    mirror_binding.fx_mirror_slot = slot
    bind(1, 5, 4 + n, mirror_binding)  -- cols 5..8 seulement
    PAD_LABEL[1]["5," .. (4 + n)] = "FX SLOT " .. n .. " (PAGE 1 + pad = mode)"
    PAD_RGB[1]["5," .. (4 + n)] = 0xFF2DA0
  end
end
-- D2 label (action deja deplacee par MOVE depuis 6,2)
PAD_LABEL[1]["5,2"] = "PAS PRECEDENT (scenario)"
PAD_RGB[1]["5,2"] = 0x66CCFF

-- Pages 2 / 3 / 4 : matrices
local function route_pad(page, row, col, kind, a, b)
  local sh = fn(function() VL.toggle_route(kind, a, b) end)
  sh.paint = { get = function() return S.routing[kind][a][b] end,
               set = function(v) VL.set_route(kind, a, b, v) end }
  if kind == "in_l" then
    -- page 2 : gestes lies au PARENT de l'entree (etat lu dans REAPER)
    --   appui court, case affectee ET entree sortie du parent : desaffecte + remet dans le parent (au relachement)
    --   appui court sinon : bascule seulement l'affectation
    --   appui long, case NON affectee : affecte + sort l'entree du parent
    --   appui long, case affectee : bascule le parent SANS desaffecter du looper
    sh.paint.snap = function() return VL.input_parent_cut(a) end
    sh.paint.after_short = function(prev, was_cut)
      if prev and was_cut then VL.set_input_parent(a, true) end
    end
    sh.paint.on_long = function(prev, was_cut)
      if prev then
        VL.set_route("in_l", a, b, true);  VL.set_input_parent(a, was_cut and true or false)
      else
        VL.set_route("in_l", a, b, true);  VL.set_input_parent(a, false)
      end
    end
  end
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
      spec.bind = { short = spec.short, long = spec.long, instant = spec.instant, defer = spec.defer, release = spec.release }
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

-- Rangee 1 page Main : statut des 8 loopers (affichage + appui intelligent)
local STATUS_HEX = {
  empty     = 0x202020,
  rec       = 0xFF0000,   -- premier rec
  wait_sync = 0xFF0000,   -- attente sortie de rec (clignote)
  play      = 0x00CC44,   -- play
  overdub   = 0xFF8800,   -- overdub
  multiply  = 0x9933FF,   -- multiply (violet, comme le bouton)
  stop      = 0x00CC44,   -- stop avec contenu (vert clignotant)
  cloud     = 0x3399FF,   -- cloud
  slicer    = 0xFFD320,   -- slicer
  reverse   = 0xFF66AA,   -- reverse
  replace   = 0xFF5500,   -- replace (autre orange)
}

local function looper_status(i)
  local L = S.loopers[i]
  local has = (L.length or 0) > 0
  -- Priorite transport / modes
  if L.wait_start then return "WAIT", STATUS_HEX.wait_sync, "armed" end
  if L.wait_sync then return "WAIT SYNC", STATUS_HEX.wait_sync, "armed" end
  if L.rec_led then return "REC", STATUS_HEX.rec, "on" end
  if L.replace then return "REPLACE", STATUS_HEX.replace, "on" end
  if L.multiply then return "MULT", STATUS_HEX.multiply, "on" end
  if L.overdub then return "DUB", STATUS_HEX.overdub, "on" end
  if L.playing then
    if L.cloud then return "CLOUD", STATUS_HEX.cloud, "on" end
    if L.slicer then return "SLICER", STATUS_HEX.slicer, "on" end
    if L.rev then return "REVERSE", STATUS_HEX.reverse, "on" end
    return "PLAY", STATUS_HEX.play, "on"
  end
  if has then
    -- stop avec boucle : vert clignotant ; reverse/cloud/slicer en stop restent visibles
    if L.cloud then return "CLOUD", STATUS_HEX.cloud, "member_cursor" end
    if L.slicer then return "SLICER", STATUS_HEX.slicer, "member_cursor" end
    if L.rev then return "REVERSE", STATUS_HEX.reverse, "member_cursor" end
    return "STOP", STATUS_HEX.stop, "member_cursor"
  end
  return "EMPTY", STATUS_HEX.empty, "off"
end

function VL.pad_label(page, row, col)
  -- Rangée D (row 5) : labels HARDCODÉS — indépendants de PAD_LABEL / MOVE (évite les bugs remote)
  if page == 1 and row == 5 then
    if col == 1 then
      if VL.scn_on and VL.scn_on() then return "LAUNCH / GO  [CAPTURE ACTIVE]" end
      return "LAUNCH / GO (long = capture scenario)"
    elseif col == 2 then
      return "PAS PRECEDENT (scenario)"
    elseif col == 3 then
      return "PAS SUIVANT (scenario)"
    elseif col == 4 then
      return "AUTO"
    elseif col >= 5 and col <= 8 then
      local slot = col - 4
      local mode = "TOGGLE"
      local source = clamp(S.fx_source or (NIN + clamp(S.sel_looper or 1, 1, NLOOP)), 1, NIN + NLOOP)
      if fx_mirror_mode then
        local ok, m = pcall(fx_mirror_mode, source, slot)
        if ok and m then mode = tostring(m):upper() end
      end
      return "FX SLOT " .. slot .. " " .. mode
    end
  end
  if row == 8 and col == 9 then return "Launchpad PAGE 4 " .. cur_layer().name end
  if page == 1 and row == 1 and col >= 1 and col <= 8 then
    local label = looper_status(col)
    return "L" .. col .. " " .. label
  end
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
  local sh = fn(function() VL.toggle_fx(kind, id, slot); VL.fx_nav(kind, id, slot) end)
  -- l'appui sur un pad de matrice passe par ce "geste de peinture" (pas par fn) : la navigation y est aussi
  sh.paint = { get = function() return S.fx[kind][id][slot] end, set = function(v) VL.set_fx(kind, id, slot, v); VL.fx_nav(kind, id, slot) end }
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
  elseif row == 5 then                                          -- rappel des presets de groupe (ligne 4 de la page Main)
    local b = BIND[1]["4," .. col]
    return { short = b.short, long = b.long, hex = PAD_RGB[1]["4," .. col] or COL.default,
             label = PAD_LABEL[1]["4," .. col], state = function() return main_state(b) end }
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
  { "rec_overdub", "REC",       p1col("8,8") },  { "clear",  "CLEAR",     p1col("8,1") },
  { "replace",     "REPLACE",   p1col("8,6") },  { "restart",  "RESTART",   p1col("7,3") },
  { "reverse",     "REVERSE",   p1col("7,4") },  { "auto_rev", "PING PONG", p1col("7,4") },
  { "slicer",      "SLICER",    p1col("7,6") },  { "cloud",  "CLOUD",     p1col("7,5") },
}
VL.register_layer({ id = "rc505", name = "RC-505", cell = function(row, col)
  local fnrow = RC_ROWS[9 - row]                                -- ligne 8 = Rec (bas), ligne 1 = Cloud (haut)
  local action, name, hex = fnrow[1], fnrow[2], fnrow[3]
  local def = ACTIONS[action]
  -- RESTART en GATE : relance le looper a l'appui ET au relachement
  local gate_release = (action == "restart") and act_on(col, action) or nil
  return { short = act_on(col, action), release = gate_release, hex = hex, label = "L" .. col .. " " .. name,
           state = function()
             local L = S.loopers[col]
             if action == "rec_overdub" then
               if L.wait_sync then return "armed" end  -- clignote
               if L.overdub then return "warn" end     -- orange
               if L.rec_led then return "on" end       -- rouge
               return "idle"
             end
             return (def.key and L[def.key]) and "on" or "idle"
           end }
end })

-- Pads "-/+" : 2 pads par looper et par parametre ; rangee impaire = loopers 1-4, rangee paire = loopers 5-8
local function pair_cell(row, col)
  return ((row - 1) % 2) * 4 + math.ceil(col / 2), (col % 2 == 1) and -1 or 1
end
local function sign_str(sg) return sg < 0 and "-" or "+" end

local NUDGES = { 0.1, 0.5, 1, 2, 5, 10, 25, 50 }                    -- % de la longueur de la boucle (mode libre)
local function fmtn(v) return (v == math.floor(v)) and tostring(math.floor(v)) or tostring(v) end

-- Couche ACTION MACROS (remplace l'ancienne couche Tune) : 64 pads (8 x 8), un par emplacement du chutier.
-- Les macros se creent / se nomment / se colorent dans NowUndo_Scenario.lua (onglet MACROS) et se glissent ici.
-- Donnees partagees par ExtState "NowUndo_Macros" (set = macros + disposition, rev = numero de version).
-- Un appui envoie la macro au script Scenario (ExtState NowUndo_Scn/mcr) avec les cibles actuelles
-- (looper selectionne ou groupe actif, cf. VL.targets) : le script Scenario doit donc tourner.
local MACRO_EXT = "NowUndo_Macros"
VL.macros = { by_id = {}, layout = {}, rev = nil, last_poll = -1e9, last_rev = -1e9, flash = {}, on = {}, on_s = nil }

function LPF.macros_parse(txt)
  local by_id, layout = {}, {}
  for line in (txt or ""):gmatch("[^\r\n]+") do
    local f = {}
    for w in (line .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = w end
    if f[1] == "M" and tonumber(f[2]) then
      by_id[math.floor(tonumber(f[2]))] = { id = math.floor(tonumber(f[2])), color = math.floor(tonumber(f[3]) or 0xAAAAAA), name = f[4] or "", text = f[5] or "", toggle = (f[6] == "1"), all = (f[7] == "1"), gate = (f[8] == "1") }
    elseif f[1] == "L" and tonumber(f[2]) and tonumber(f[3]) then
      layout[math.floor(tonumber(f[2]))] = math.floor(tonumber(f[3]))
    end
  end
  return by_id, layout
end

function VL.macros_poll(t)
  if not (reaper and reaper.GetExtState) then return end
  t = t or now()
  local M = VL.macros
  if t - M.last_poll < 0.1 then return end
  M.last_poll = t
  local on_s = reaper.GetExtState(MACRO_EXT, "on")             -- macros TOGGLE actuellement actives (publie par NowUndo_Scenario)
  if on_s ~= M.on_s then
    M.on_s, M.on = on_s, {}
    for n in on_s:gmatch("%d+") do M.on[tonumber(n)] = true end
  end
  if t - M.last_rev < 0.4 then return end
  M.last_rev = t
  local rev = reaper.GetExtState(MACRO_EXT, "rev")
  if rev == M.rev then return end
  M.rev = rev
  M.by_id, M.layout = LPF.macros_parse(reaper.GetExtState(MACRO_EXT, "set"))
end

-- libelle d'un pad : le nom, sinon l'action elle-meme (jamais "Macro 3")
function LPF.macro_label(m)
  local n = m.name or ""
  if n == "" or n:match("^Macro %d+$") then return m.text or "" end
  return n
end

-- Ctrl + clic sur un pad : retire la macro de ce pad (elle reste dans le chutier du script Scenario, qui recharge la disposition)
function VL.macro_unplace(cell)
  local lines = {}
  for line in (reaper.GetExtState(MACRO_EXT, "set") or ""):gmatch("[^\r\n]+") do
    local kind, c = line:match("^(%a)\t(%d+)")
    if not (kind == "L" and tonumber(c) == cell) then lines[#lines + 1] = line end
  end
  local rev = string.format("%.4f", reaper.time_precise())
  reaper.SetExtState(MACRO_EXT, "set", table.concat(lines, "\n"), true)
  reaper.SetExtState(MACRO_EXT, "rev", rev, false)
  VL.macros.layout[cell] = nil
  VL.macros.rev = rev
  log("info", "macro retiree du pad %d", cell)
end

-- Reecrit la disposition (lignes L) dans l'ExtState partage ; fn(lay) modifie lay : case -> id de macro
function VL.macros_layout_edit(fn)
  local lines, lay = {}, {}
  for line in (reaper.GetExtState(MACRO_EXT, "set") or ""):gmatch("[^\r\n]+") do
    local kind, c, id = line:match("^(%a)\t(%d+)\t(%d+)")
    if kind == "L" then lay[tonumber(c)] = tonumber(id) else lines[#lines + 1] = line end
  end
  fn(lay)
  local cells = {}
  for c in pairs(lay) do cells[#cells + 1] = c end
  table.sort(cells)
  for _, c in ipairs(cells) do lines[#lines + 1] = "L\t" .. c .. "\t" .. lay[c] end
  local rev = string.format("%.4f", reaper.time_precise())
  reaper.SetExtState(MACRO_EXT, "set", table.concat(lines, "\n"), true)
  reaper.SetExtState(MACRO_EXT, "rev", rev, false)
  VL.macros.layout = lay
  VL.macros.rev = rev
end

-- Depose des macros (ids) sur une case : la 1re sur la case visee, les suivantes dans les cases libres qui suivent.
-- Case occupee : echange si la macro deposee etait deja sur le Launchpad, sinon l'occupant va dans la 1re case libre.
function VL.macro_drop(ids, cell)
  VL.macros_layout_edit(function(lay)
    local function cell_of(id) for c, i in pairs(lay) do if i == id then return c end end end
    local function free_from(c) while c <= 64 and lay[c] do c = c + 1 end; return c end
    local nextc = cell
    for n, id in ipairs(ids) do
      local old = cell_of(id)
      if n == 1 then
        local occ = lay[cell]
        if old then lay[old] = nil end
        if occ and occ ~= id then
          if old then lay[old] = occ
          else local c = free_from(1); if c <= 64 then lay[c] = occ end end
        end
        lay[cell] = id
      else
        if old then lay[old] = nil end
        local c = free_from(nextc + 1)
        if c > 64 then c = free_from(1) end
        if c <= 64 then lay[c] = id; nextc = c end
      end
    end
  end)
  log("info", "macro(s) deposee(s) en case %d", cell)
end

-- Deplace une macro d'une case a une autre (echange si la case visee est occupee)
function VL.macro_move(from, to)
  if from == to then return end
  VL.macros_layout_edit(function(lay)
    local a, b = lay[from], lay[to]
    if not a then return end
    lay[to] = a; lay[from] = b
  end)
  log("info", "macro deplacee : case %d -> %d", from, to)
end

function VL.macro_at(cell)
  local id = VL.macros.layout[cell]
  return id and VL.macros.by_id[id] or nil
end

function VL.macro_fire(cell)
  local m = VL.macro_at(cell)
  if not m then return end
  VL.macros.flash[cell] = now() + 0.25
  local hb = tonumber(reaper.GetExtState("NowUndo_Scn", "alive")) or 0
  if reaper.time_precise() - hb > 2 then log("warn", "macro '%s' : le script NowUndo_Scenario ne tourne pas", LPF.macro_label(m)) end
  local cur = reaper.GetExtState("NowUndo_Scn", "mcr")
  reaper.SetExtState("NowUndo_Scn", "mcr", cur .. string.format("%d\t%s\t%.3f\n", m.id, table.concat(VL.targets(), ","), reaper.time_precise()), false)
  log("info", "macro '%s' -> %s", LPF.macro_label(m), table.concat(VL.targets(), ","))
end

function VL.macro_press(cell)
  local m = VL.macro_at(cell)
  if not m then return end
  if VL.ctrl_held and VL.ctrl_held() then VL.macro_unplace(cell); return end   -- Ctrl + clic : retire du Launchpad
  VL.macro_fire(cell)
end

function VL.macro_release(cell)
  local m = VL.macro_at(cell)
  if not m or not m.gate then return end
  VL.macro_fire(cell)   -- gate : second fire = desactivation (avec toggle)
end
VL.register_layer({ id = "macros", name = "Action macros", cell = function(row, col)
  local cell = (row - 1) * 8 + col
  return {
    short = fn(function() VL.macro_press(cell) end),
    release = fn(function() VL.macro_release(cell) end),  -- no-op si la macro n'est pas en mode GATE
    instant = true,   -- fire a l'appui (gate = on ; non-gate = declenchement)
    hex = function() local mm = VL.macro_at(cell); return mm and mm.color or 0x222222 end,
    label = function() local mm = VL.macro_at(cell); return mm and LPF.macro_label(mm) or "" end,
    state = function()
      if not VL.macro_at(cell) then return "off" end
      if (VL.macros.flash[cell] or 0) > now() then return "armed" end
      local mm = VL.macro_at(cell)
      if mm.toggle or mm.gate then return VL.macros.on[mm.id] and "on" or "idle" end
      return "on"
    end }
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
local last_rel = {}      -- dernier relachement court par pad (detection du double clic)

-- Maintien virtuel (bouton HOLD de la fenetre) ou clavier (Ctrl) : meme effet tant qu'ils sont actifs.
-- Par defaut ils editent le groupe ACTIF ; un tap sur un pad GROUP n (meme vide) choisit le groupe edite (edit_group).
local vhold, ctrl_hold, edit_group = false, false, nil
function LPF.check_edit_end() if not (vhold or ctrl_hold) then edit_group = nil end end   -- fin du maintien = fin de l'edition
function VL.set_virtual_hold(on) vhold = on and true or false; LPF.check_edit_end() end
function VL.set_ctrl_hold(on) ctrl_hold = on and true or false; LPF.check_edit_end() end
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

-- Affectateur du chord = looper maintenu le plus ancien, hors `exclude`.
-- Verite = table down[] (pad reellement enfonce) : un _held_loopers peri me (relachement manque) est ignore et purge.
function VL.chord_anchor(exclude)
  local anchor, anchor_t
  for j = 1, NLOOP do
    if j ~= exclude and VL._held_loopers[j] then
      if down["0," .. j] then
        if not anchor or VL._held_loopers[j] < anchor_t then anchor, anchor_t = j, VL._held_loopers[j] end
      else
        VL._held_loopers[j] = nil
      end
    end
  end
  return anchor
end

-- vrai tant qu'un pad GROUPE est maintenu (physiquement, ou via HOLD + groupe choisi a la souris)
local function group_inhibit()
  for g = 1, NGROUP do
    if down[g .. ",9"] then return true end
  end
  return (vhold or ctrl_hold) and edit_group ~= nil
end
function VL.group_inhibit() return group_inhibit() end

local function membership_pnt(looper, g)
  return { get = function() return S.group_of[looper] == g end,
           set = function(v)
             if v then VL.assign_group(looper, g) elseif S.group_of[looper] == g then VL.assign_group(looper, 0) end
           end }
end

-- pads qu'on peut "maintenir" (utile pour la souris : bouton HOLD) : GROUP 1-4 et cellules de matrice
function VL.is_holdable(row, col)
  local b = BIND[S.page][row .. "," .. col]
  return b ~= nil and (b.short.paint ~= nil or (col == 9 and row >= 1 and row <= NGROUP) or (col == 9 and row == 5))
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
  if p.dirty_routing then
    pcall(function() VL.hooks.routing_changed(VL.routing_edges()) end)
    if VL.update_input_mutes then pcall(VL.update_input_mutes) end
  end
  if p.dirty_groups then VL.hooks.groups_changed(S.group_of) end
  if p.dirty_fx then VL.hooks.fx_changed(VL.fx_list()) end
end

function VL.on_pad_pressed(row, col, t)
  t = t or now()
  -- Seuls les pads 1..8 x 1..8 de la matrice d'entrees peuvent changer la source FX.
  -- Les boutons lateraux (colonne 9 : pages/groupes) ne doivent jamais etre lus comme une entree.
  if S.page == 2 and row >= 1 and row <= NIN and col >= 1 and col <= 8 then
    S.sel_input = row
    S.fx_source = row
    VL.publish_fx_source()
  end
  local key = row .. "," .. col
  local b = BIND[S.page][key]
  if not b then return end

  -- === Chord Yamaha (rangee du haut) : AVANT tout autre traitement ===
  -- Maintenir un looper puis en enfoncer un autre = grouper / degrouper.
  -- Ignore si un pad GROUP physique est deja maintenu (edition classique prioritaire).
  if row == 0 and col >= 1 and col <= NLOOP then
    local group_pad_held = false
    for g = 1, NGROUP do
      if down[g .. ",9"] then group_pad_held = true; break end
    end
    if not group_pad_held then
      local anchor = VL.chord_anchor(col)
      VL._held_loopers[col] = t
      if anchor then
        local da = down["0," .. anchor]
        if da then da.long_fired = true; da.consumed = true end   -- l'affectateur maintenu n'ouvre pas sa fenetre (appui long)
        VL.looper_chord_group(anchor, col)
        down[key] = { t = t, b = b, short_done = true, long_fired = true, consumed = true, chord_group = true }
        VL.sync_out()
        return
      end
    else
      VL._held_loopers[col] = t
    end
  end

  local pnt = b.short and b.short.paint
  if row ~= 0 and not (col == 9 and row >= 1 and row <= NGROUP) then
    for g = 1, NGROUP do                              -- action pendant le maintien d'un GROUP : pas de selection de groupe au relachement
      local d = down[g .. ",9"]
      if d then d.consumed = true end
    end
  end
  if row == 0 then                                    -- un GROUP n est maintenu : la rangee du haut edite ses membres
    local g, gkey = held_group()
    if g then pnt = membership_pnt(col, g); if gkey then down[gkey].consumed = true end end
  end
  if pnt then                                         -- cellule de matrice / looper-membre : geste de peinture
    local prev, is_first = nil, false
    if paint and paint.page == S.page then
      paint_apply(key, pnt)
      paint.n = (paint.n or 1) + 1
    elseif not paint then
      prev = pnt.get()
      is_first = true
      paint = { page = S.page, value = not prev, visited = { [key] = true }, first = key, n = 1 }
      pnt.set(paint.value)
      -- dirty flags for end_paint (routing / groups / fx)
      if S.page == 2 or S.page == 3 then paint.dirty_routing = true end
    end
    down[key] = { b = b, paint = true, short_done = true, key = key, t = t or now(), prev = prev, pnt = pnt, first = is_first,
                  snap = pnt.snap and pnt.snap() or nil }
  else
    local tt = t or now()
    if b.short and b.short.fx_mirror_slot then
      local slot = b.short.fx_mirror_slot
      local source = clamp(S.fx_source or (NIN + clamp(S.sel_looper or 1, 1, NLOOP)), 1, NIN + NLOOP)
      -- PAGE 1 maintenue = commande de configuration : aucun changement d'etat FX.
      if down["5,9"] then
        local old_mode = fx_mirror_mode(source, slot)
        local new_mode = old_mode == "toggle" and "gate" or "toggle"
        fx_mirror_set_mode(source, slot, new_mode)
        down[key] = { t = tt, b = b, short_done = true, fx_mode_switch = true,
                      fx_slot = slot, fx_source = source }
        VL.sync_out()
        return
      end
      local kind, id = (source <= NIN) and "input" or "looper", (source <= NIN) and source or (source - NIN)
      local mode = fx_mirror_mode(source, slot)
      -- cibles : le looper selectionne, ou tous les loopers de son groupe (capturees a l'appui)
      local targets = { { kind, id } }
      if kind == "looper" and (S.group_of[id] or 0) ~= 0 then
        targets = {}
        for _, m in ipairs(VL.group_members(S.group_of[id])) do targets[#targets + 1] = { "looper", m } end
        if #targets == 0 then targets = { { kind, id } } end
      end
      down[key] = { t = tt, b = b, short_done = true, fx_mirror = true, fx_slot = slot,
                    fx_source = source, fx_kind = kind, fx_id = id, fx_mode = mode, fx_targets = targets }
      local newval = (mode == "gate") and true or (not S.fx[kind][id][slot])
      for _, tg in ipairs(targets) do
        if S.fx_present[tg[1]][tg[2]][slot] then VL.set_fx(tg[1], tg[2], slot, newval) end
      end
      VL.fx_nav(kind, id, slot)
      VL.sync_out()
      return
    end
    if b.double and last_rel[key] and (tt - last_rel[key]) <= DOUBLE_S then      -- double clic
      last_rel[key] = nil
      down[key] = { t = tt, b = b, short_done = true, long_fired = true, consumed = true }
      dispatch(b.double)
      VL.sync_out()
      return
    end
    down[key] = { t = tt, b = b, short_done = false, long_fired = false }
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
  -- Toujours liberer le tracker chord, meme si release/long a court-circuite le handler
  if row == 0 and col >= 1 and col <= NLOOP then VL._held_loopers[col] = nil end
  if not d then return end
  if d.fx_mirror then
    -- En Gate, le relachement coupe exactement la source capturee a l'appui,
    -- meme si la selection FX a change entre-temps.
    if d.fx_mode == "gate" then
      for _, tg in ipairs(d.fx_targets or { { d.fx_kind, d.fx_id } }) do
        if S.fx_present[tg[1]][tg[2]][d.fx_slot] then VL.set_fx(tg[1], tg[2], d.fx_slot, false) end
      end
      VL.fx_nav(d.fx_kind, d.fx_id, d.fx_slot)
    end
  elseif d.fx_mode_switch then
    -- Le changement de mode a deja ete effectue a l'appui ; rien au relachement.
  elseif d.paint then
    if d.first and not d.long_fired and d.pnt and d.pnt.after_short and paint and paint.first == key and (paint.n or 1) == 1 then
      d.pnt.after_short(d.prev, d.snap)          -- appui court sur une cellule seule
    end
    if paint and paint.first == key then end_paint() end
  elseif not d.short_done and not d.long_fired and not d.consumed then
    dispatch(d.b.short)
  elseif d.b.release and not d.long_fired and not d.consumed then
    dispatch(d.b.release)
  end
  if d.b.double and not d.long_fired and not d.consumed then last_rel[key] = t or now() end
  VL.sync_out()
end

function VL.tick(t)
  t = t or now()
  if VL.poll_looper_feedback then VL.poll_looper_feedback() end
  VL.rec_dub_tick(); VL.ext_cmd_poll()   -- [REC>DUB]
  VL.excl_poll(t)
  if VL.macros_poll then VL.macros_poll(t) end
  VL.fire_pump(t)
  local fired = false
  for _, d in pairs(down) do
    -- appui long sur une cellule de matrice SEULE : annule la bascule, execute l'action longue (parent, etc.)
    if d.paint and d.first and (d.b.long or (d.pnt and d.pnt.on_long)) and not d.long_fired and paint and paint.first == d.key
       and (paint.n or 1) == 1 and d.t and (t - d.t) >= LONG_PRESS_S then
      d.long_fired = true
      if d.pnt and d.pnt.on_long then
        d.pnt.on_long(d.prev, d.snap)
      else
        if d.pnt then d.pnt.set(d.prev) end
        if d.b.long then dispatch(d.b.long) end
      end
      fired = true
    end
    if d.b.long and not d.paint and not d.long_fired and d.t and (t - d.t) >= LONG_PRESS_S then
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
function LPF.track_looper_index(name)
  local n = (name or ""):lower()
  return tonumber(n:match("^l(%d+)$") or n:match("^l(%d+)[^%d]") or n:match("^looper%s*(%d+)"))
end

function LPF.find_nowundo_fx(tr)
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
    local fx = LPF.find_nowundo_fx(tr)
    if fx then
      local _, name = reaper.GetTrackName(tr)
      local idx = LPF.track_looper_index(name)
      if idx then named_any = true end
      if idx == i then return tr, fx end
      all[#all + 1] = { tr, fx }
    end
  end
  if not named_any and all[i] then return all[i][1], all[i][2] end   -- aucune piste nommee L<n> : ordre des pistes
end

-- Piste + index d'effet de la fenetre looper i : piste du looper (index fixe, comme le script openlooper), effet looper_window_fx
local function looper_window_target(i)
  local tr = VL.resolve_tracks(false).loopers[i]
  local fx = VL.config.looper_window_fx or 0
  if tr and fx < reaper.TrackFX_GetCount(tr) then return tr, fx end
  return nil
end

local function looper_window_is_open(tr, fx)
  return reaper.TrackFX_GetFloatingWindow(tr, fx) ~= nil or reaper.TrackFX_GetOpen(tr, fx)
end

function LPF.looper_window_close(tr, fx)
  reaper.TrackFX_SetOpen(tr, fx, false)
  if reaper.TrackFX_GetFloatingWindow(tr, fx) then reaper.TrackFX_Show(tr, fx, 2) end
  if reaper.TrackFX_GetFloatingWindow(tr, fx) then            -- plugins qui resistent : astuce ouvrir + refermer
    reaper.TrackFX_Show(tr, fx, 3)
    reaper.TrackFX_Show(tr, fx, 2)
  end
end

-- Ferme toutes les fenetres looper ouvertes (sauf `except`). Retourne true si une fenetre a ete fermee.
function VL.close_looper_windows(except)
  if not (reaper and reaper.CountTracks) then return false end
  local closed = false
  for i = 1, NLOOP do
    if i ~= except then
      local tr, fx = looper_window_target(i)
      if tr and looper_window_is_open(tr, fx) then
        LPF.looper_window_close(tr, fx)
        closed = true
        log("info", "looper %d : fenetre fermee", i)
      end
    end
  end
  if closed and reaper.TrackList_AdjustWindows then reaper.TrackList_AdjustWindows(false) end
  return closed
end

function VL.open_looper_window(i)
  if not (reaper and reaper.CountTracks) then log("warn", "looper %d : pas de REAPER", i) return false end
  VL.close_looper_windows(i)                                   -- un seul looper ouvert a la fois
  local tr, fx = looper_window_target(i)
  if not tr then log("warn", "looper %d : piste ou effet %d introuvable", i, VL.config.looper_window_fx or 0) return false end
  if not looper_window_is_open(tr, fx) then
    reaper.TrackFX_Show(tr, fx, 3)                             -- 3 = fenetre flottante
    log("info", "looper %d : fenetre ouverte", i)
  end
  return true
end

-- Si une fenetre looper est ouverte sur un AUTRE looper que celui selectionne, elle bascule sur le selectionne
function VL.follow_looper_window()
  if not (reaper and reaper.CountTracks) then return end
  local sel = S.sel_looper
  for i = 1, NLOOP do
    if i ~= sel then
      local tr, fx = looper_window_target(i)
      if tr and looper_window_is_open(tr, fx) then VL.open_looper_window(sel) return end
    end
  end
end

-- Appui sur un bouton de selection : selection immediate (la fenetre ouverte suit la selection).
-- On memorise si la fenetre de CE looper etait deja ouverte : un appui court la refermera au relachement.
-- Chord Yamaha : si un autre looper est deja maintenu, le plus ancien sert d'affectateur (voir VL.looper_chord_group).
local was_open = {}
function VL.looper_button_press(i)
  if pedal_capture_action("select_looper", i) then return end
  local tpress = now()
  -- Affectateur = looper maintenu le plus ancien (hors celui qu'on vient d'enfoncer)
  local anchor = VL.chord_anchor(i)
  VL._held_loopers[i] = tpress
  -- Priorite au mode edition GROUP (pad GROUP / HOLD / Ctrl) : pas de chord dans ce cas
  if anchor and not (VL.held_group and VL.held_group()) then
    VL.looper_chord_group(anchor, i)
    was_open[i] = false
    return
  end
  local tr, fx = nil, nil
  if reaper and reaper.CountTracks then tr, fx = looper_window_target(i) end
  was_open[i] = (tr and looper_window_is_open(tr, fx)) and true or false
  VL.select_looper(i)
end

-- Relachement apres un appui court : ferme la fenetre de ce looper si elle etait deja ouverte a l'appui
function VL.looper_button_release(i)
  VL._held_loopers[i] = nil
  if was_open[i] then VL.close_looper_windows() end
  was_open[i] = nil
end

-- Appui long (1 s) : selectionne le looper (en groupe, c'est le looper selectionne qui s'ouvre) et ouvre sa fenetre
-- Pas de chord ici : un appui long reste "ouvrir la fenetre".
function VL.looper_button_long(i)
  VL.select_looper(i)
  VL.open_looper_window(S.sel_looper)
end

-- compatibilite : bascule ouvre/ferme
function VL.toggle_looper_window(i)
  local tr, fx = looper_window_target(i)
  if tr and looper_window_is_open(tr, fx) then VL.close_looper_windows() else VL.open_looper_window(i) end
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

--------------------------------------------------------------------------
-- MODELE PERSISTANT : routing, effets actifs, groupes et presets sont sauves dans un fichier
-- a cote du script (nowundo_vl_model.txt) et recharges automatiquement au demarrage.
-- Sauvegarde automatique ~1 s apres le dernier changement. Reinitialiser : supprimer le fichier.
--------------------------------------------------------------------------
local MODEL = { file = "nowundo_vl_model.txt", last = nil, pending = nil, pending_t = 0, t = 0 }
do
  local info = debug.getinfo(1, "S")
  local dir = info and info.source and info.source:match("^@(.*[/\\])")
  if dir then MODEL.file = dir .. "nowundo_vl_model.txt" end
end

function LPF.model_matrix_ok(m, n, c)
  if type(m) ~= "table" then return false end
  for i = 1, n do
    local r = m[i]
    if type(r) ~= "table" then return false end
    for j = 1, c do if type(r[j]) ~= "boolean" then return false end end
  end
  return true
end
function LPF.model_routing_ok(r)
  return type(r) == "table" and LPF.model_matrix_ok(r.in_l, NIN, NLOOP) and LPF.model_matrix_ok(r.l_l, NLOOP, NLOOP)
end
function LPF.model_fx_ok(f)
  return type(f) == "table" and LPF.model_matrix_ok(f.input, NIN, NSLOT) and LPF.model_matrix_ok(f.looper, NLOOP, NSLOT)
end
function LPF.model_groups_ok(g)
  if type(g) ~= "table" then return false end
  for i = 1, NLOOP do
    if type(g[i]) ~= "number" or g[i] < 0 or g[i] > NGROUP then return false end
  end
  return true
end

function LPF.model_table()
  return { _m = 1, routing = S.routing, fx = S.fx, group_of = S.group_of, presets = S.presets }
end

function VL.model_load()
  local f = io.open(MODEL.file, "r")
  if not f then return false end
  local txt = f:read("*a"); f:close()
  local chunk = load("return " .. txt, "vl_model", "t", {})
  if not chunk then return false end
  local ok, t = pcall(chunk)
  if not ok or type(t) ~= "table" or t._m ~= 1 then return false end
  if LPF.model_routing_ok(t.routing) then S.routing = { in_l = t.routing.in_l, l_l = t.routing.l_l } end
  if LPF.model_fx_ok(t.fx) then S.fx = { input = t.fx.input, looper = t.fx.looper } end
  if LPF.model_groups_ok(t.group_of) then
    for i = 1, NLOOP do S.group_of[i] = math.floor(t.group_of[i]) end
    S.sel_group = S.group_of[S.sel_looper] or 0
  end
  if type(t.presets) == "table" then
    local pr, pg = t.presets.routing, t.presets.group
    local function slots_ok(p, check)
      if type(p) ~= "table" or type(p.slots) ~= "table" or type(p.active) ~= "number" then return false end
      if p.active < 1 or p.active > NPRESET then return false end
      for n, d in pairs(p.slots) do
        if type(n) ~= "number" or n < 1 or n > NPRESET or not check(d) then return false end
      end
      return true
    end
    if slots_ok(pr, function(d) return type(d) == "table" and LPF.model_routing_ok(d.routing) and LPF.model_fx_ok(d.fx) end) then
      S.presets.routing = { active = math.floor(pr.active), slots = pr.slots }
    end
    if slots_ok(pg, LPF.model_groups_ok) then
      S.presets.group = { active = math.floor(pg.active), slots = pg.slots }
    end
  end
  MODEL.last = ser(LPF.model_table())
  log("info", "modele charge : %s", MODEL.file)
  return true
end

-- Appelee a chaque frame par le CONTROLEUR (jamais par le miroir) : ecrit quand l'etat est stable depuis 1 s.
function VL.model_autosave(t)
  if VL.mirror_mode then return end
  t = t or now()
  if t - MODEL.t < 0.5 then return end
  MODEL.t = t
  local txt = ser(LPF.model_table())
  if txt == MODEL.last then MODEL.pending = nil; return end
  if txt ~= MODEL.pending then MODEL.pending = txt; MODEL.pending_t = t; return end
  if t - MODEL.pending_t < 1.0 then return end
  local f = io.open(MODEL.file, "w")
  if f then
    f:write(txt); f:close()
    MODEL.last = txt; MODEL.pending = nil
    log("info", "modele sauve : %s", MODEL.file)
  end
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
    pcall(VL.apply_routing)
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
    -- REC : rouge en enregistrement, orange en overdub, clignote en Wait Sync
    if sh.action == "rec_overdub" then
      local function rec_mode_for(L)
        if L.wait_sync then return "armed" end   -- clignote : sorti du rec, sync pas encore atteinte
        if L.overdub then return "warn" end      -- orange : overdub
        if L.rec_led then return "on" end        -- rouge (couleur famille du pad) : rec
        return "idle"
      end
      -- Affiche UNIQUEMENT le looper de reference (selectionne), pas un agregat du groupe
      mode = rec_mode_for(ref)
      mode = armed_mode(sh.action, sh.args) or mode
      return mode
    end
    if sh.action == "part" then
      -- Main/Chorus/Bridge : allume si active, clignote si pending (attente fin de cycle)
      local want = sh.args
      if ref.pending_part and ref.target_part == want then mode = "armed"
      elseif ref.part == want and not ref.pending_part then mode = "on"
      else mode = "idle" end
      mode = armed_mode(sh.action, sh.args) or mode
      return mode
    end
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
      if row >= 1 and col <= 8 and row ~= 1 then put(row, col, rgb[key] or COL.default, main_state(b)) end
    end
    -- Ligne 1 (sous selection) : statut live des 8 loopers
    for i = 1, NLOOP do
      local label, hex, mode = looper_status(i)
      put(1, i, hex, mode)
    end
  else
    local fb = LPF.compute_feedback()
    for row = 1, 8 do for col = 1, 8 do
      local base = rgb[row .. "," .. col] or COL.default
      if page == 2 then
        if row <= NIN then
          if VL.input_parent_cut(row) then
            -- entree sortie du parent : toute la rangee en bleu ; routes ouvertes = clignotent, fermees = bleu attenue
            put(row, col, 0x2D5BFF, S.routing.in_l[row][col] and "armed" or "idle")
          else
            put(row, col, cell_led(S.routing.in_l[row][col], fb["in_l:" .. row .. ":" .. col], base))
          end
        else put(row, col, base, "off") end
      elseif page == 3 then
        if row == col then put(row, col, base, "off")
        else put(row, col, cell_led(S.routing.l_l[col][row], fb["l_l:" .. col .. ":" .. row], base)) end
      else                                                         -- page 4 : couche courante
        local spec = cur_layer().cells[row .. "," .. col]
        if spec then put(row, col, type(spec.hex) == "function" and spec.hex() or spec.hex, spec.state()) else put(row, col, base, "off") end
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

-- Pedal Board : commandes de selection de looper (ExtState "NowUndo_Pedal/lp_cmd" = ts \t nom \t arg)
local pedal_cmd_ts = nil
function LPF.pedal_poll_cmd()
  if not (reaper and reaper.GetExtState) then return end
  local raw = reaper.GetExtState("NowUndo_Pedal", "lp_cmd")
  local ts, name, arg = raw:match("^([^\t]*)\t([^\t]*)\t?([^\t]*)")
  ts = tonumber(ts)
  if not ts then pedal_cmd_ts = pedal_cmd_ts or 0 return end
  if pedal_cmd_ts == nil then pedal_cmd_ts = ts return end     -- 1er passage : ignore une commande deja ancienne
  if ts <= pedal_cmd_ts then return end
  pedal_cmd_ts = ts
  if name == "next_looper" then VL.step_looper(1)
  elseif name == "prev_looper" then VL.step_looper(-1)
  elseif name == "select_looper" and tonumber(arg) then VL.select_looper(math.floor(tonumber(arg)))
  elseif name == "trigger" and arg ~= "" then VL.trigger(arg)
  elseif name == "excl_toggle" then VL.excl_toggle()
  elseif name == "excl_super_toggle" then VL.excl_super_toggle()
  elseif name == "sync_toggle" then VL.sync_toggle(false)
  elseif name == "sync_toggle_all" then VL.sync_toggle(true) end
end


--------------------------------------------------------------------------
-- Remote web (NowUndo.html) + QR code d'accès
-- ExtState section "nowundo_vl" :
--   web_frame / web_labels / web_meta / web_status / web_tick / web_cmd
--------------------------------------------------------------------------
local WEB = {
  section = "nowundo_vl",
  last_frame = "",
  last_labels = "",
  last_meta = "",
  last_status = "",
  last_pub = 0,
  last_lbl = 0,
  last_cmd = "",
  acks = {},      -- web v3.9 : dernier numero traite par page web (sid)
  page = nil,     -- web v4.1 : page affichee sur la page web, independante de la fenetre / du Launchpad physique
}
-- Execute f avec la page WEB comme page courante, puis rend sa page au Launchpad. Un changement de page fait
-- pendant f (bouton PAGE du web) ne change que la page web.
function VL.web_with_page(f)
  local real = S.page
  S.page = WEB.page or real
  local ok, err = pcall(f)
  WEB.page = S.page
  S.page = real
  if not VL.mirror_mode and reaper and reaper.SetExtState then
    reaper.SetExtState("nowundo_vl", "active_page", tostring(real), false)
  end
  if not ok then error(err, 0) end
end
local WEB_STATE_CODE = {
  off = "o", idle = "i", on = "n", warn = "w",
  armed = "a", armed_other = "x", cursor = "c", member_cursor = "m",
}

function VL.remote_guess_lan_ip()
  -- 1) Surcharge manuelle (optionnelle)
  local manual = reaper.GetExtState("nowundo_vl", "lan_ip")
  if manual and manual ~= "" and manual ~= "127.0.0.1" then return manual end

  -- 2) Cache court (évite de relancer un shell à chaque clic QR)
  local cached = reaper.GetExtState("nowundo_vl", "lan_ip_auto")
  local cached_t = tonumber(reaper.GetExtState("nowundo_vl", "lan_ip_auto_t")) or 0
  local nowt = reaper.time_precise and reaper.time_precise() or os.clock()
  if cached and cached ~= "" and cached ~= "127.0.0.1" and (nowt - cached_t) < 300 then
    return cached
  end

  local function is_private(ip)
    if not ip or ip == "" or ip == "127.0.0.1" or ip == "0.0.0.0" then return false end
    if ip:match("^192%.168%.") then return true end
    if ip:match("^10%.") then return true end
    local a, b = ip:match("^172%.(%d+)%.")
    if a then a = tonumber(a); if a and a >= 16 and a <= 31 then return true end end
    return false
  end

  local function pick_best(text)
    if not text then return nil end
    local best
    for ip in text:gmatch("(%d+%.%d+%.%d+%.%d+)") do
      if is_private(ip) then
        if ip:match("^192%.168%.") then return ip end -- priorité Wi‑Fi/LAN classique
        best = best or ip
      end
    end
    return best
  end

  -- 3) LuaSocket (si chargé)
  if socket and socket.udp then
    local ok, ip = pcall(function()
      local u = socket.udp()
      u:setpeername("1.1.1.1", 80)
      local ip = u:getsockname()
      u:close()
      return ip
    end)
    if ok and is_private(ip) then
      reaper.SetExtState("nowundo_vl", "lan_ip_auto", ip, false)
      reaper.SetExtState("nowundo_vl", "lan_ip_auto_t", string.format("%.0f", nowt), false)
      return ip
    end
  end

  -- 4) Détection OS via shell → fichier temporaire
  local tmp = (reaper.GetResourcePath() or ".") .. "/nowundo_lan_ip.txt"
  local osname = reaper.GetOS() or ""
  local cmd
  if osname:match("Win") then
    -- ipconfig : simple et toujours dispo ; on parse les IPv4 privées
    cmd = 'cmd.exe /C ipconfig > "' .. tmp:gsub("/", "\\") .. '" 2>nul'
  elseif osname:match("OSX") or osname:match("mac") then
    cmd = '(ipconfig getifaddr en0 || ipconfig getifaddr en1 || route -n get default 2>/dev/null | awk \'/interface:/{print $2}\' | head -1 | xargs -I{} ipconfig getifaddr {}) > "' .. tmp .. '" 2>/dev/null'
  else
    cmd = '(hostname -I 2>/dev/null || ip -4 route get 1.1.1.1 2>/dev/null | awk \'{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}\') > "' .. tmp .. '" 2>/dev/null'
  end

  pcall(function()
    if reaper.ExecProcess then
      reaper.ExecProcess(cmd, 3000)
    else
      os.execute(cmd)
    end
  end)

  local ip
  local f = io.open(tmp, "r")
  if f then
    local body = f:read("*a") or ""
    f:close()
    pcall(os.remove, tmp)
    ip = pick_best(body)
  end

  if ip then
    reaper.SetExtState("nowundo_vl", "lan_ip_auto", ip, false)
    reaper.SetExtState("nowundo_vl", "lan_ip_auto_t", string.format("%.0f", nowt), false)
    return ip
  end

  return "127.0.0.1"
end

function VL.remote_web_port()
  local p = tonumber(reaper.GetExtState("nowundo_vl", "web_port"))
  if p and p > 0 and p < 65536 then return math.floor(p) end
  return 8080
end

function VL.remote_open_url(url)
  if not url or url == "" then return end
  if reaper.CF_ShellExecute then
    reaper.CF_ShellExecute(url)
    return
  end
  local osname = reaper.GetOS() or ""
  if osname:match("Win") then
    reaper.ExecProcess('cmd.exe /C start "" "' .. url:gsub('"', "") .. '"', -1)
  elseif osname:match("OSX") or osname:match("mac") then
    os.execute('open "' .. url:gsub('"', '\\"') .. '"')
  else
    os.execute('xdg-open "' .. url:gsub('"', '\\"') .. '" &')
  end
end

function VL.remote_show_qr()
  local ip = VL.remote_guess_lan_ip()
  local port = VL.remote_web_port()
  -- ?v=<horodatage> : adresse unique a chaque QR -> le telephone recharge la page au lieu de garder une ancienne copie en cache
  local remote_url = string.format("http://%s:%d/NowUndo.html?v=%d", ip, port, math.floor(os.time()))
  local enc = remote_url:gsub("([^%w%-_.~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
  local qr_url = string.format("http://127.0.0.1:%d/NowUndo_QR.html?u=%s", port, enc)
  VL.remote_open_url(qr_url)
  log("info", "QR Remote : %s", remote_url)
end

function VL.web_publish(t)
  if not (reaper and reaper.SetExtState) then return end
  t = t or now()
  if t - WEB.last_pub < 0.05 then return end   -- ~20 Hz max
  WEB.last_pub = t

  local frame
  VL.web_with_page(function() frame = VL.build_frame() end)
  local parts = {}
  for key, v in pairs(frame) do
    local hex, state = v[1] or 0, v[2] or "off"
    local code = WEB_STATE_CODE[state] or "o"
    parts[#parts + 1] = string.format("%s:%06X:%s", key, hex & 0xFFFFFF, code)
  end
  table.sort(parts)
  local frame_s = table.concat(parts, "|")
  if frame_s ~= WEB.last_frame or reaper.GetExtState(WEB.section, "web_frame") ~= frame_s then
    WEB.last_frame = frame_s
    reaper.SetExtState(WEB.section, "web_frame", frame_s, false)
  end

  -- labels ~3 Hz
  if t - WEB.last_lbl > 0.35 then
    WEB.last_lbl = t
    local labs = {}
    for row = 0, 8 do
      for col = 1, 9 do
        if not (row == 0 and col == 9) then
          local lab = VL.pad_label(WEB.page or S.page, row, col)
          if lab and lab ~= "" then
            lab = tostring(lab):gsub("|", "¦"):gsub(":", "⁚")
            labs[#labs + 1] = row .. "," .. col .. ":" .. lab
          end
        end
      end
    end
    table.sort(labs)
    local lab_s = table.concat(labs, "|")
    if lab_s ~= WEB.last_labels or reaper.GetExtState(WEB.section, "web_labels") ~= lab_s then
      WEB.last_labels = lab_s
      reaper.SetExtState(WEB.section, "web_labels", lab_s, false)
    end
  end

  -- meta
  local layers = {}
  if VL.layers then
    for _, l in ipairs(VL.layers()) do
      layers[#layers + 1] = l.id .. "=" .. (l.name or l.id)
    end
  end
  local hg = held_group and held_group() or 0
  local meta = string.format("page=%d;layer=%s;hold=%d;layers=%s",
    WEB.page or S.page or 1,
    tostring(S.p4_layer or "fx"),
    tonumber(hg) or 0,
    table.concat(layers, ","))
  if meta ~= WEB.last_meta or reaper.GetExtState(WEB.section, "web_meta") ~= meta then
    WEB.last_meta = meta
    reaper.SetExtState(WEB.section, "web_meta", meta, false)
  end

  local st = VL.status and VL.status() or ""
  if st ~= WEB.last_status then
    WEB.last_status = st
    reaper.SetExtState(WEB.section, "web_status", st, false)
  end

  reaper.SetExtState(WEB.section, "web_tick", string.format("%.3f", t), false)
end

function VL.web_poll_cmd()
  if not (reaper and reaper.GetExtState) then return end
  local raw = reaper.GetExtState(WEB.section, "web_cmd")
  if not raw or raw == "" then return end
  -- web v3.9 : "@sid;#n:cmd;#n:cmd..." = commandes numerotees, renvoyees par la page tant qu'elles ne sont
  -- pas acquittees (web_ack) -> plus de commande perdue quand la page ecrit plus vite qu'on ne lit.
  local sid = raw:match("^@([%w]+);")
  if not sid then
    if raw == WEB.last_cmd then return end   -- ancien format
    WEB.last_cmd = raw
  end
  reaper.SetExtState(WEB.section, "web_cmd", "", false)

  local t = now()
  local acked = sid and (WEB.acks[sid] or 0) or 0
  VL.web_with_page(function()
  for item in raw:gmatch("[^;]+") do
    local cmd = item
    if sid then
      local n, c = item:match("^#(%d+):(.*)$")
      n = tonumber(n)
      if n and n > acked then acked = n; cmd = c else cmd = nil end
    end
    local op, a, b
    if cmd then op, a, b = cmd:match("^(%w+),?([^,]*),?(.*)$") end
    if not op then
      -- ignore
    elseif op == "P" then
      local row, col = tonumber(a), tonumber(b)
      if row and col then VL.on_pad_pressed(row, col, t) end
    elseif op == "R" then
      local row, col = tonumber(a), tonumber(b)
      if row and col then VL.on_pad_released(row, col, t) end
    elseif op == "D" then
      local row, col = tonumber(a), tonumber(b)
      if row and col and VL.on_pad_dragged then VL.on_pad_dragged(row, col) end
    elseif op == "H" then
      local on = (a == "1")
      if VL.set_virtual_hold then VL.set_virtual_hold(on) end
    elseif op == "L" and a and a ~= "" then
      if VL.set_layer then VL.set_layer(a) end
    elseif op == "PAGE" and tonumber(a) then
      if VL.set_page then VL.set_page(tonumber(a)) end
    elseif op == "SEL" and tonumber(a) then         -- web v4.0 : appeler un looper (onglet Loopers) le selectionne ici
      local i = math.floor(tonumber(a))
      if i >= 1 and i <= NLOOP and S.sel_looper ~= i then VL.select_looper(i) end
    elseif op == "ACT" and tonumber(a) and ACTIONS[b] then   -- ACT,looper,action : bouton de l'onglet Loopers
      local i = math.floor(tonumber(a))                      -- = meme chemin qu'un pad (groupe, etats, page Twister)
      if i >= 1 and i <= NLOOP then
        if S.sel_looper ~= i then VL.select_looper(i) end
        VL.trigger(b)
      end
    end
  end
  end)
  if sid then
    WEB.acks[sid] = acked
    local parts = {}
    for k, v in pairs(WEB.acks) do parts[#parts + 1] = k .. ":" .. v end
    if #parts > 8 then WEB.acks = { [sid] = acked }; parts = { sid .. ":" .. acked } end
    reaper.SetExtState(WEB.section, "web_ack", table.concat(parts, ","), false)
  end
  if VL.sync_out then VL.sync_out() end
end

function VL.render(t)
  t = t or now()
  LPF.pedal_poll_cmd()
  VL.web_poll_cmd()
  VL.web_publish(t)
  -- Toujours publier groupes/routing pour Twister & dashboard (meme en hardware_test)
  VL.dash_publish(false, t)
  if reaper and reaper.SetExtState then
    reaper.SetExtState("nowundo_vl", "fighter_page", tostring(S.fighter_page or 1), false)
    reaper.SetExtState("nowundo_vl", "sel_looper", tostring(S.sel_looper or 1), false)
    reaper.SetExtState("nowundo_vl", "sel_group", tostring(S.sel_group or 0), false)
    reaper.SetExtState("nowundo_vl", "exclusive", S.exclusive and "1" or "0", false)
  end
  -- Garder active_page a jour pour le miroir (chaque frame, cout negligeable)
  if not VL.mirror_mode then VL.model_autosave(t) end
  if SYNC.enabled and not VL.mirror_mode and reaper and reaper.SetExtState then
    reaper.SetExtState(SYNC.section, "active_page", tostring(S.page), false)
    reaper.SetExtState(SYNC.section, "heartbeat", string.format("%.3f", reaper.time_precise and reaper.time_precise() or os.clock()), false)
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

-- ===== Launchpad Mini MK3 : pont MIDI direct pour test autonome =====
-- Le script reste independant de NowUndo : aucun hook metier n'est branche.
VL.hardware_test = true

function LPF.midi_device_name(is_output, index)
  local fn = is_output and reaper.GetMIDIOutputName or reaper.GetMIDIInputName
  if not fn then return "" end
  local ok, name = fn(index, "")
  if ok and type(name) == "string" then return name end      -- retval false = peripherique absent / inactif
  return ""
end

-- Ports actifs uniquement : REAPER reserve des index vides (peripheriques absents) qu'on ne liste pas.
function LPF.list_active_ports(is_output)
  local count_fn = is_output and reaper.GetNumMIDIOutputs or reaper.GetNumMIDIInputs
  local list = {}
  if not count_fn then return list end
  for i = 0, count_fn() - 1 do
    local name = LPF.midi_device_name(is_output, i)
    if name ~= "" then list[#list + 1] = { index = i, name = name } end
  end
  return list
end

function LPF.find_launchpad_device(is_output)
  local count_fn = is_output and reaper.GetNumMIDIOutputs or reaper.GetNumMIDIInputs
  if not count_fn then return nil, "API MIDI indisponible" end
  local list = LPF.list_active_ports(is_output)
  local best, first, fallback, names = nil, nil, nil, {}
  for _, d in ipairs(list) do
    names[#names + 1] = string.format("%d: %s", d.index, d.name)
    local lower = d.name:lower()
    if lower:find("launchpad mini", 1, true) or lower:find("lpminimk3", 1, true) then
      first = first or d
      -- sortie par defaut : le port "MIDIOUT2 (LPMiniMK3 MIDI)"
      if is_output and not best and lower:find("midiout2", 1, true) then best = d end
    elseif lower:find("launchpad", 1, true) or lower:find("lpmini", 1, true) then
      fallback = fallback or d
    end
  end
  local pick = best or first or fallback
  if pick then return pick.index, pick.name end
  return nil, table.concat(names, "\n")
end

local LP_OUT, LP_OUT_NAME = LPF.find_launchpad_device(true)
local LP_IN, LP_IN_NAME = LPF.find_launchpad_device(false)
local LP_LAST_SEQ = 0
local LP_HELD = {}
local LP_IN_ACTIVITY = 0
local LP_OUT_ACTIVITY = 0
local LP_IN_EVENTS = 0
local LP_OUT_EVENTS = 0
local LP_LAST_IN_TEXT = "aucun evenement"
local LP_LAST_OUT_TEXT = "aucun envoi"
local LP_DEVICES_REFRESH = 0
local LP_INPUTS, LP_OUTPUTS = {}, {}

function LPF.lp_refresh_devices()
  LP_INPUTS, LP_OUTPUTS = LPF.list_active_ports(false), LPF.list_active_ports(true)
  LP_DEVICES_REFRESH = now and now() or os.clock()
end
if reaper.MIDI_GetRecentInputEvent then
  local seq = reaper.MIDI_GetRecentInputEvent(0)
  LP_LAST_SEQ = seq or 0 -- ignorer l'historique precedent au lancement
end

local function lp_send(bytes)
  if LP_OUT == nil or not reaper.SendMIDIMessageToHardware then return false end
  local ok, err = pcall(reaper.SendMIDIMessageToHardware, LP_OUT, bytes)
  if not ok then
    if not VL._midi_send_error then
      VL._midi_send_error = true
      -- MIDI send error silenced
    end
    return false
  end
  LP_OUT_ACTIVITY = now()
  LP_OUT_EVENTS = LP_OUT_EVENTS + 1
  LP_LAST_OUT_TEXT = string.format("%d octets", #bytes)
  return true
end

local function lp_sysex(values)
  local bytes = {}
  for _, v in ipairs(values) do bytes[#bytes + 1] = string.char(v & 0xFF) end
  return lp_send(table.concat(bytes))
end

local function lp_led_index(row, col)
  -- Programmer Mode (Mini MK3) : rangee du haut = CC 91..98 ; matrice = notes 11..88 ;
  -- colonne droite = CC 89, 79, ... 19 (meme formule que la matrice avec col = 9).
  if row == 0 then return 90 + col end
  return (9 - row) * 10 + col
end

-- ===== Reglages d'affichage materiel (n'affectent QUE le Launchpad, jamais la fenetre) =====
-- Actif = 100 % (luminosite max de la LED). Deux curseurs en bas de la fenetre, memorises entre les sessions :
--   IDLE       : luminosite reelle des pads inactifs, 0 % (eteint) .. 50 %. Reponse quadratique : precision
--                maximale dans les bas niveaux (les LED paraissent bien plus claires que leur valeur).
--   SATURATION : 0 % = gris, 100 % = couleurs d'origine, 200 % = couleurs poussees (utile : les teintes
--                pastel comme 0xFFFF99 virent au blanc sur les LED).
-- CTRL_RGB : false = rangee du haut + colonne droite en BLANC a intensite variable (non colorables),
--            true  = on y envoie quand meme la couleur RVB (si votre materiel l'accepte).
-- CTRL_CURSOR : intensite de ces 17 touches pour l'etat "curseur" (entre idle et actif).
local HW_EXT      = "VirtualLaunchpad_MK3_TEST"
local HW          = { idle_pos = 0.40, sat = 1.0 }      -- idle_pos 0..1 (0.40 -> 8 %) ; sat 0..2
local CTRL_RGB    = false
local CTRL_CURSOR = 0.35
local HW_BLINK = { armed = { 1.0, 0.0 }, armed_other = { 0.8, 0.30 }, member_cursor = { 1.0, 0.30 } }   -- { phase haute, phase basse }

local function hw_idle() return 0.5 * HW.idle_pos ^ 2 end
function LPF.hw_load()
  local a = tonumber(reaper.GetExtState(HW_EXT, "idle_pos"))
  local b = tonumber(reaper.GetExtState(HW_EXT, "sat"))
  if a then HW.idle_pos = math.max(0, math.min(1, a)) end
  if b then HW.sat = math.max(0, math.min(2, b)) end
end
function LPF.hw_save()
  reaper.SetExtState(HW_EXT, "idle_pos", string.format("%.4f", HW.idle_pos), true)
  reaper.SetExtState(HW_EXT, "sat", string.format("%.4f", HW.sat), true)
end
-- luminosite materielle 0..1 d'un etat (la fenetre garde ses propres niveaux)
function LPF.hw_bright(led, ctrl)
  local st = led.state
  if st == "off" then return 0 end
  if st == "idle" then return hw_idle() end
  local bl = HW_BLINK[st]
  if bl then                                              -- phase deduite du niveau envoye par le coeur
    if led.level > 0.6 then return bl[1] end
    return (bl[2] > 0) and math.max(bl[2], hw_idle()) or 0
  end
  if st == "cursor" and ctrl then return math.max(CTRL_CURSOR, hw_idle()) end
  return 1.0
end
function LPF.hw_saturate(r, g, b)
  if HW.sat == 1 then return r, g, b end
  local y = 0.299 * r + 0.587 * g + 0.114 * b
  local function f(c) return math.max(0, math.min(255, y + (c - y) * HW.sat)) end
  return f(r), f(g), f(b)
end
local function is_ctrl_pad(row, col) return row == 0 or col == 9 end

local function lp_set_rgb(row, col, r, g, b)
  if not LP_OUT then return end
  local idx = lp_led_index(row, col)
  local function scale(v) return math.max(0, math.min(127, math.floor((v or 0) * 127 / 255 + 0.5))) end
  -- Novation Launchpad Mini MK3 RGB lighting SysEx: F0 00 20 29 02 0D 03 03 <LED> R G B F7
  lp_sysex({ 0xF0, 0x00, 0x20, 0x29, 0x02, 0x0D, 0x03, 0x03, idx, scale(r), scale(g), scale(b), 0xF7 })
end

local function lp_set_mode(programmer)
  if LP_OUT then lp_sysex({ 0xF0, 0x00, 0x20, 0x29, 0x02, 0x0D, 0x0E, programmer and 1 or 0, 0xF7 }) end
end

local function lp_dispatch(row, col, is_down, t)
  if row < 0 or row > 8 or col < 1 or col > 9 or (row == 0 and col == 9) then return end
  local key = row .. "," .. col
  if is_down then
    if not LP_HELD[key] then
      LP_HELD[key] = true
      VL.on_pad_pressed(row, col, t)
    end
  elseif LP_HELD[key] then
    LP_HELD[key] = nil
    VL.on_pad_released(row, col, t)
  end
end

local function lp_parse_event(msg, t)
  if type(msg) ~= "string" or #msg < 2 then return end
  LP_IN_ACTIVITY = t
  LP_IN_EVENTS = LP_IN_EVENTS + 1
  local b1, b2, b3 = msg:byte(1) or 0, msg:byte(2) or 0, msg:byte(3) or 0
  LP_LAST_IN_TEXT = string.format("%02X %02X %02X", b1, b2, b3)
  local status = msg:byte(1)
  local d1, d2 = msg:byte(2) or 0, msg:byte(3) or 0
  local kind = status & 0xF0
  if kind == 0x90 or kind == 0x80 then
    local tens, units = math.floor(d1 / 10), d1 % 10
    if tens >= 1 and tens <= 8 and units >= 1 and units <= 9 then
      local row, col = 9 - tens, units
      lp_dispatch(row, col, kind == 0x90 and d2 > 0, t)
    end
  elseif kind == 0xB0 then
    if d1 >= 91 and d1 <= 98 then
      lp_dispatch(0, d1 - 90, d2 > 0, t)
    elseif d1 >= 19 and d1 <= 89 and d1 % 10 == 9 then      -- colonne droite : CC 89 (haut) .. 19 (bas)
      lp_dispatch(9 - math.floor(d1 / 10), 9, d2 > 0, t)
    end
  end
end

local function lp_poll_input(t)
  if LP_IN == nil or not reaper.MIDI_GetRecentInputEvent then return end
  local pending = {}
  -- L'index 0 accroche l'etat recent ; les indices suivants remontent dans l'historique.
  for i = 0, 127 do
    local seq, msg, ts, dev = reaper.MIDI_GetRecentInputEvent(i)
    if not seq or seq == 0 then break end
    if seq <= LP_LAST_SEQ then break end
    if ((dev or 0) & 0xFFFF) == LP_IN then pending[#pending + 1] = { seq = seq, msg = msg } end
  end
  -- L'historique est du plus recent au plus ancien : traiter les nouveaux evenements dans l'ordre.
  -- Heure estimee de l'appui : milieu de l'intervalle depuis la lecture precedente (le script tourne ~30 fois/s)
  local prev = VL._lp_prev_poll or t
  VL._lp_prev_poll = t
  if #pending > 0 then VL.press_t = t - math.min(t - prev, 0.1) * 0.5 end
  for i = #pending, 1, -1 do lp_parse_event(pending[i].msg, t) end
  VL.press_t = nil
  local seq0 = reaper.MIDI_GetRecentInputEvent(0)
  if seq0 and seq0 > LP_LAST_SEQ then LP_LAST_SEQ = seq0 end
end

function LPF.lp_choose_device(is_output)
  LPF.lp_refresh_devices()
  local list = is_output and LP_OUTPUTS or LP_INPUTS
  local current = is_output and LP_OUT or LP_IN
  local menu = { is_output and "#SORTIE MIDI  (vers le Launchpad)" or "#ENTRÉE MIDI  (depuis le Launchpad)",
                 ((current == nil) and "!" or "") .. "Aucun" }
  local indexes = { false, false }
  if #list == 0 then menu[#menu + 1] = "#(aucun port actif dans REAPER)"; indexes[#indexes + 1] = false end
  for _, d in ipairs(list) do
    menu[#menu + 1] = ((d.index == current) and "!" or "") .. d.name
    indexes[#indexes + 1] = d.index
  end
  local pick = gfx.showmenu(table.concat(menu, "|"))
  if pick == 2 then
    if is_output then LP_OUT, LP_OUT_NAME = nil, nil else LP_IN, LP_IN_NAME, LP_LAST_SEQ = nil, nil, 0 end
  elseif pick and pick > 2 and indexes[pick] ~= nil then
    local idx = indexes[pick]
    if is_output then
      LP_OUT = idx
      LP_OUT_NAME = LPF.midi_device_name(true, idx)
      lp_set_mode(true)
      -- Renvoyer les couleurs actuelles vers le nouveau port.
      for key, c in pairs(VL._hw_colors or {}) do
        local row, col = key:match("^(%-?%d+),(%-?%d+)$")
        if row and col then lp_set_rgb(tonumber(row), tonumber(col), c[1], c[2], c[3]) end
      end
    else
      LP_IN = idx
      LP_IN_NAME = LPF.midi_device_name(false, idx)
      LP_LAST_SEQ = 0
      if reaper.MIDI_GetRecentInputEvent then LP_LAST_SEQ = reaper.MIDI_GetRecentInputEvent(0) or 0 end
      LP_HELD = {}
    end
  end
end

function LPF.lp_status_text()
  local ins = LP_IN_NAME or ("introuvable (index a regler)")
  local outs = LP_OUT_NAME or ("introuvable (index a regler)")
  return "MIDI IN: " .. ins .. " | OUT: " .. outs
end

function VL.run_gfx_test()
  LPF.lp_refresh_devices()
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

  VL._test_pad_colors = pads
  LPF.hw_load()
  local hw = {}
  VL._hw_colors = hw
  VL.attach_profile({ caps = { native_blink = false },
    set_led = function(row, col, led)
      local r, g, b = hex_to_rgb(led.hex)
      local k = led.level
      local key = row .. "," .. col
      -- fenetre : couleur de famille x niveau
      pads[key] = { math.floor(r * k + 0.5), math.floor(g * k + 0.5), math.floor(b * k + 0.5) }
      -- materiel : luminosite par etat (curseur IDLE) + saturation ; rangee du haut / colonne droite = blanc, l'etat se lit a l'intensite
      local hr, hg_, hb
      local ctrl = is_ctrl_pad(row, col)
      local kh = LPF.hw_bright(led, ctrl)
      if ctrl and not CTRL_RGB then
        local v = 255 * kh
        hr, hg_, hb = v, v, v
      else
        local sr, sg, sb = LPF.hw_saturate(r, g, b)
        hr, hg_, hb = sr * kh, sg * kh, sb * kh
      end
      hr, hg_, hb = math.floor(hr + 0.5), math.floor(hg_ + 0.5), math.floor(hb + 0.5)
      hw[key] = { hr, hg_, hb }
      lp_set_rgb(row, col, hr, hg_, hb)
    end })
  -- Purge des donnees web perimees (residu d'anciennes versions : D3/D4 pointant sur FX slot 1/2)
  if reaper and reaper.DeleteExtState then
    for _, k in ipairs({ "web_frame", "web_labels", "web_meta", "web_status", "web_cmd" }) do
      reaper.DeleteExtState("nowundo_vl", k, true)
    end
    WEB.last_frame, WEB.last_labels, WEB.last_meta, WEB.last_status, WEB.last_cmd = "", "", "", "", ""
  end
  VL.mirror_mode = false          -- ce script est le CONTROLEUR : il publie la page active et l'etat pour VirtualLaunchpadDisplay
  VL.sync_enable()
  -- Le Display charge EXACTEMENT ce fichier (meme version du coeur), ou qu'il soit range
  local info = debug.getinfo(1, "S")
  if info and info.source and info.source:sub(1, 1) == "@" then
    reaper.SetExtState("nowundo_vl", "core_path", info.source:sub(2), false)
  end
  NDDOCK.init("Virtual Launchpad - Launchpad Mini MK3 TEST", "VirtualLaunchpad_MK3_TEST", REF_W, REF_H)
  if LP_OUT then
    lp_set_mode(true)
    -- MIDI OUT ok
  else
    -- MIDI OUT missing
  end
  if LP_IN then
    -- MIDI IN ok
  else
    -- MIDI IN missing
  end

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
    local QRBTN = {
      x = HOLD.x - 50 * s,
      y = 6 * s,
      w = 46 * s,
      h = 22 * s
    }
    local LAYERBTN = {                     -- a gauche de la barre du haut : ne depend plus du QR ni de HOLD
      x = OX,
      y = 6 * s,
      w = 180 * s,
      h = 22 * s
    }

    return s, CELL, OX, OY, HOLD, LAYERBTN, QRBTN
  end

  local function pad_at(mx, my, CELL, OX, OY)
    local col = math.floor((mx - OX) / CELL) + 1
    local row = math.floor((my - OY) / CELL)
    if col < 1 or col > 9 or row < 0 or row > 8 or (row == 0 and col == 9) then
      return nil
    end
    return row, col
  end

  local drag_slider, hw_dirty, hw_last_push = nil, false, 0
  local function in_rect(r, mx, my) return mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h end

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
    if ch == -1 or ch == 27 then lp_set_mode(false); gfx.quit(); return end
    NDDOCK.tick()
    if VL.sync_poll() then pcall(VL.apply_routing) end   -- etat recu du miroir (Display) : appliquer sends + mutes
    -- Mute auto des IN : verification reguliere de l'etat reel des sends (4 fois par seconde)
    if not VL._last_mute_check or t - VL._last_mute_check > 0.25 then
      VL._last_mute_check = t
      pcall(VL.update_input_mutes)
    end
    -- Surveille les insertions/remplacements d'effets faits depuis le FX Router.
    -- Un nouvel effet reprend l'etat ON/OFF deja defini par la matrice page 4.
    if not VL._last_fx_scan or t - VL._last_fx_scan > 0.10 then
      VL._last_fx_scan = t
      local ok, err = pcall(VL.scan_fx_present)
      if not ok then log("warn", "scan FX : %s", tostring(err)) end
    end

    local s, CELL, OX, OY, HOLD, LAYERBTN, QRBTN = layout()
    local CTRL_Y = OY + CELL * 9 + 5 * s
    local CTRL_H = 20 * s
    local CTRL_W = 54 * s
    local OUTBTN = { x=OX + CELL * 9 - CTRL_W, y=CTRL_Y, w=CTRL_W, h=CTRL_H }     -- en bas a droite, discrets
    local INBTN  = { x=OUTBTN.x - CTRL_W - 6 * s, y=CTRL_Y, w=CTRL_W, h=CTRL_H }
    -- Curseurs de reglage du Launchpad (ligne sous l'aide, dans la marge basse existante)
    local SL_Y, SL_H = OY + CELL * 9 + 33 * s, 13 * s
    local SL_W = (CELL * 9 - 10 * s) / 2
    local SL_IDLE = { x = OX,                 y = SL_Y, w = SL_W, h = SL_H }
    local SL_SAT  = { x = OX + SL_W + 10 * s, y = SL_Y, w = SL_W, h = SL_H }

    VL.tick(t)
    local cap = math.floor(gfx.mouse_cap)
    VL.set_ctrl_hold((cap & CTRL_MASK) ~= 0)          -- Ctrl (Cmd sur Mac) maintenu = HOLD du groupe actif
    local pressed = (cap & 1) == 1
    local edge_down = pressed and not was_pressed
    local edge_up   = (not pressed) and was_pressed
    was_pressed = pressed
    lp_poll_input(t)

    -- Macros deposees depuis NowUndo_Scenario (glisser-deposer) : ExtState NowUndo_Macros/drop = ids <TAB> x ecran <TAB> y ecran <TAB> temps
    local dq = reaper.GetExtState("NowUndo_Macros", "drop")
    if dq ~= "" then
      reaper.SetExtState("NowUndo_Macros", "drop", "", false)
      local ids_s, X, Y, ts = dq:match("^([%d,]+)\t(-?%d+)\t(-?%d+)\t([%d%.]+)")
      if ids_s and reaper.time_precise() - tonumber(ts) < 3 then
        local ox, oy = gfx.clienttoscreen(0, 0)
        local _, oy2 = gfx.clienttoscreen(0, gfx.h)
        local cx = tonumber(X) - ox
        local cy = (oy2 < oy) and (oy - tonumber(Y)) or (tonumber(Y) - oy)       -- Mac : axe Y des coordonnees ecran inverse
        if cx >= 0 and cy >= 0 and cx <= gfx.w and cy <= gfx.h then              -- le curseur est bien sur cette fenetre
          local ids = {}
          for n in ids_s:gmatch("%d+") do ids[#ids + 1] = tonumber(n) end
          local r, c = pad_at(cx, cy, CELL, OX, OY)
          local cell
          if S.page == 4 and S.p4_layer == "macros" and r and r >= 1 and c <= 8 then cell = (r - 1) * 8 + c
          else
            cell = 1
            while cell <= 64 and VL.macros.layout[cell] do cell = cell + 1 end       -- pas sur une case : a la suite
          end
          if cell <= 64 and #ids > 0 then VL.macro_drop(ids, cell) end
        end
      end
    end

    if edge_down then
      local mx, my = gfx.mouse_x, gfx.mouse_y
      if mx >= INBTN.x and mx <= INBTN.x + INBTN.w and my >= INBTN.y and my <= INBTN.y + INBTN.h then
        gfx.x, gfx.y = INBTN.x, INBTN.y
        LPF.lp_choose_device(false)
      elseif mx >= OUTBTN.x and mx <= OUTBTN.x + OUTBTN.w and my >= OUTBTN.y and my <= OUTBTN.y + OUTBTN.h then
        gfx.x, gfx.y = OUTBTN.x, OUTBTN.y
        LPF.lp_choose_device(true)
      elseif in_rect(SL_IDLE, mx, my) then drag_slider = "idle"
      elseif in_rect(SL_SAT, mx, my) then drag_slider = "sat"
      elseif mx >= LAYERBTN.x and mx <= LAYERBTN.x + LAYERBTN.w
                    and my >= LAYERBTN.y and my <= LAYERBTN.y + LAYERBTN.h then
        local menu, ids = {}, {}
        for i, l in ipairs(VL.layers()) do
          ids[i] = l.id
          menu[i] = (l.id == S.p4_layer and "!" or "") .. l.name
        end
        gfx.x, gfx.y = LAYERBTN.x, LAYERBTN.y + LAYERBTN.h
        local pick = gfx.showmenu(table.concat(menu, "|"))
        if pick and pick > 0 then VL.set_layer(ids[pick]); if S.page ~= 4 then VL.set_page(4) end end

      elseif mx >= QRBTN.x and mx <= QRBTN.x + QRBTN.w
         and my >= QRBTN.y and my <= QRBTN.y + QRBTN.h then
        VL.remote_show_qr()
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
      if S.page == 4 and S.p4_layer == "macros" and r >= 1 and c <= 8 and VL.macro_at((r - 1) * 8 + c) then
        local r2, c2 = pad_at(gfx.mouse_x, gfx.mouse_y, CELL, OX, OY)             -- relache sur un autre pad : on DEPLACE la macro
        if r2 and r2 >= 1 and c2 <= 8 and (r2 ~= r or c2 ~= c) then
          local dd = down[r .. "," .. c]
          if dd then dd.consumed = true end                                       -- ne declenche pas la macro
          VL.macro_move((r - 1) * 8 + c, (r2 - 1) * 8 + c2)
        end
      end
      if sticky_on and not sticky_pad and VL.is_holdable(r, c)
         and (c == 9 and r == 5 or (S.sel_group == 0 and not (c == 9 and r >= 1 and r <= 4))) then
        sticky_pad = { r, c }
      else
        VL.on_pad_released(r, c, t)
      end
      down_pad = nil
      last_pad = nil
    end

    -- Curseurs : glisser pour regler ; le Launchpad est rafraichi (au plus ~12 fois/s) puis memorise au relachement
    if drag_slider then
      if pressed then
        local sl = (drag_slider == "idle") and SL_IDLE or SL_SAT
        local pos = math.max(0, math.min(1, (gfx.mouse_x - sl.x) / sl.w))
        if drag_slider == "idle" then HW.idle_pos = pos
        else HW.sat = (math.abs(pos - 0.5) < 0.02) and 1.0 or pos * 2 end
        hw_dirty = true
      else
        drag_slider = nil
        LPF.hw_save()
      end
    end
    if hw_dirty and (t - hw_last_push) > 0.08 then
      VL.last = {}                                  -- force le renvoi de tous les pads avec les nouveaux reglages
      hw_dirty, hw_last_push = false, t
    end

    VL.render(t)

    -- Etat de la liaison MIDI (outil de test independant)
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

    -- Statut + selection des ports MIDI
    local port_tip = nil
    gfx.setfont(1, "Arial", math.max(9, math.floor(11 * s)))
    gfx.set(0.9, 0.9, 0.9, 1)
    do
      local x0 = OX + LAYERBTN.w + 8 * s
      local maxw = QRBTN.x - 6 * s - x0
      local st = VL.status()
      while #st > 4 and maxw > 0 and gfx.measurestr(st) > maxw do st = st:sub(1, -3) end
      gfx.x, gfx.y = x0, 8 * s
      if maxw > 0 then gfx.drawstr(st) end
    end

    -- Ports MIDI : deux petits boutons "IN" / "OUT" (clic = choisir le port).
    -- Pastille : bleu vif = activite, bleu sombre = port OK, rouge sombre = aucun port. Le survol affiche le nom complet.
    local function draw_port_button(rect, label, long_label, name, activity, count)
      local mx, my = gfx.mouse_x, gfx.mouse_y
      local hover = mx >= rect.x and mx <= rect.x + rect.w and my >= rect.y and my <= rect.y + rect.h
      if hover then gfx.set(0.24, 0.26, 0.30, 1) else gfx.set(0.16, 0.17, 0.19, 1) end
      gfx.rect(rect.x, rect.y, rect.w, rect.h, 1)
      gfx.set(0.32, 0.34, 0.37, 1)
      gfx.rect(rect.x, rect.y, rect.w, rect.h, 0)
      if (t - activity) < 0.22 then gfx.set(0.12, 0.55, 1.0, 1)
      elseif name then gfx.set(0.08, 0.22, 0.42, 1)
      else gfx.set(0.45, 0.12, 0.12, 1) end
      gfx.circle(rect.x + 10 * s, rect.y + rect.h / 2, 4 * s, 1, 1)
      gfx.set(0.93, 0.94, 0.96, 1)
      gfx.setfont(1, "Arial", math.max(9, math.floor(11 * s)))
      gfx.x, gfx.y = rect.x + 20 * s, rect.y + (rect.h - gfx.texth) / 2
      gfx.drawstr(label)
      if hover then
        port_tip = long_label .. " : " .. (name or "aucun port") .. "  (" .. tostring(count) .. " evt)  - clic pour changer"
      end
    end
    draw_port_button(INBTN, "IN", "ENTRÉE", LP_IN_NAME, LP_IN_ACTIVITY, LP_IN_EVENTS)
    draw_port_button(OUTBTN, "OUT", "SORTIE", LP_OUT_NAME, LP_OUT_ACTIVITY, LP_OUT_EVENTS)

    -- Curseurs IDLE / SATURATION (n'agissent que sur le Launchpad)
    local function draw_slider(r, frac, text)
      gfx.set(0.16, 0.17, 0.19, 1)
      gfx.rect(r.x, r.y, r.w, r.h, 1)
      gfx.set(0.22, 0.42, 0.78, 1)
      gfx.rect(r.x, r.y, r.w * frac, r.h, 1)
      gfx.set(0.32, 0.34, 0.37, 1)
      gfx.rect(r.x, r.y, r.w, r.h, 0)
      gfx.set(0.95, 0.95, 0.97, 1)
      gfx.setfont(1, "Arial", math.max(8, math.floor(9 * s)))
      gfx.x, gfx.y = r.x + 6 * s, r.y + (r.h - gfx.texth) / 2
      gfx.drawstr(text)
    end
    draw_slider(SL_IDLE, HW.idle_pos, string.format("Launchpad - Idle : %.1f %%  (actif 100 %%)", hw_idle() * 100))
    draw_slider(SL_SAT, HW.sat / 2, string.format("Launchpad - Saturation : %d %%", math.floor(HW.sat * 100 + 0.5)))

    -- Bouton QR Remote
    do
      local mx, my = gfx.mouse_x, gfx.mouse_y
      local hover = mx >= QRBTN.x and mx <= QRBTN.x + QRBTN.w and my >= QRBTN.y and my <= QRBTN.y + QRBTN.h
      if hover then gfx.set(0.20, 0.40, 0.75, 1) else gfx.set(0.18, 0.32, 0.58, 1) end
      gfx.rect(QRBTN.x, QRBTN.y, QRBTN.w, QRBTN.h, 1)
      gfx.set(0.95, 0.95, 0.97, 1)
      gfx.setfont(1, "Arial", math.floor(11 * s))
      local qtxt = "QR"
      local qw = gfx.measurestr(qtxt)
      gfx.x = QRBTN.x + (QRBTN.w - qw) / 2
      gfx.y = QRBTN.y + 4 * s
      gfx.drawstr(qtxt)
    end

    -- Bouton Layer (toutes pages)
    do
      gfx.set(0.28, 0.28, 0.28, 1)
      gfx.rect(LAYERBTN.x, LAYERBTN.y, LAYERBTN.w, LAYERBTN.h, 1)
      gfx.set(0.55, 0.55, 0.60, 1)
      gfx.rect(LAYERBTN.x, LAYERBTN.y, LAYERBTN.w, LAYERBTN.h, 0)
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
      elseif sticky_pad and sticky_pad[1] == 5 and sticky_pad[2] == 9 then label = "HOLD PAGE 1 : clic FX"
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
    gfx.drawstr(port_tip or LOG.ring[#LOG.ring] or "")

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
  LPF.init_presets()
  VL.last = {}
  for k in pairs(down) do down[k] = nil end
  log("info", "Virtual Launchpad %s initialise", VL.VERSION)
end
VL.reset()
VL.model_load()      -- routing / effets / groupes / presets du dernier modele sauve (fichier a cote du script)
-- Au demarrage, la source initiale suit le looper restaure, sans dependre de la page affichee.
S.fx_source = NIN + clamp(S.sel_looper or 1, 1, NLOOP)
VL.publish_fx_source()
-- Applique l'etat de routing initial (tout ferme) + mute auto des IN non routees
if VL.scan_fx_present then VL.scan_fx_present() end
if VL.apply_routing then VL.apply_routing() end
if VL.apply_fx then VL.apply_fx() end

if rawget(_G, "VL_TEST") then return VL end
VL.run_gfx_test()










