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
VL.VERSION = "0.9.0"            -- NE PAS CHANGER : le miroir / la remote web refusent l'etat synchronise si la version differe
VL.BUILD = "0.9.15-status-tap" -- numero de build (affiche a la console)
VL.debug = false                  -- true : messages de diagnostic dans la console REAPER
local function dbg(fmt, ...)
  if VL.debug and reaper and reaper.ShowConsoleMsg then reaper.ShowConsoleMsg("[VL] " .. string.format(fmt, ...) .. "\n") end
end
if reaper and reaper.ShowConsoleMsg then
  reaper.ShowConsoleMsg("[VL] build " .. VL.BUILD .. " charge depuis : " .. tostring(debug.getinfo(1, "S").source) .. "\n")
end

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
                     link = false, rec = false, rec_led = false, overdub = false, wait_sync = false, state = 0,
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
      L.wait_sync = (st == 8)                 -- sorti du rec, attend le point de sync
      L.rec_led   = (st == 1)                 -- LED rouge : vrai REC
      -- cle toggle "rec" : true tant que on est dans le cycle rec/dub/wait-sync
      L.rec       = (st == 1 or st == 3 or st == 8)
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
local function track_by_index_1based(n)
  if not (reaper and reaper.GetTrack and n and n >= 1) then return nil end
  local tr = reaper.GetTrack(0, n - 1)
  return tr
end

local function track_name(tr)
  if not tr then return "" end
  local _, name = reaper.GetTrackName(tr)
  return name or ""
end

local function match_indexed_name(name, patterns)
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
    inputs[i] = track_by_index_1based((cfg.in_track_first or 2) + (i - 1))
  end
  for i = 1, NLOOP do
    loopers[i] = track_by_index_1based((cfg.looper_track_first or 11) + (i - 1))
  end
  -- 2) secours par nom si une piste manque
  local named_in, named_l = {}, {}
  for t = 0, n - 1 do
    local tr = reaper.GetTrack(0, t)
    local nm = track_name(tr)
    local ii = match_indexed_name(nm, VL.config.in_name_patterns)
    if ii and ii >= 1 and ii <= NIN then named_in[ii] = tr end
    local li = match_indexed_name(nm, VL.config.looper_name_patterns)
    if li and li >= 1 and li <= NLOOP then named_l[li] = tr end
  end
  for i = 1, NIN do if not inputs[i] then inputs[i] = named_in[i] end end
  for i = 1, NLOOP do if not loopers[i] then loopers[i] = named_l[i] end end
  _route_cache = { ntracks = n, inputs = inputs, loopers = loopers }
  return _route_cache
end

local function find_send(src, dst)
  if not (src and dst) then return nil end
  local ns = reaper.GetTrackNumSends(src, 0)
  for i = 0, ns - 1 do
    local dest = reaper.GetTrackSendInfo_Value(src, 0, i, "P_DESTTRACK")
    if dest == dst then return i end
  end
  return nil
end

local function ensure_send(src, dst)
  local idx = find_send(src, dst)
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

local function set_send_open(src, dst, open, gain_db)
  if not (src and dst) then return false end
  local idx = open and ensure_send(src, dst) or find_send(src, dst)
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
local function set_track_prop(tr, key, want)
  if reaper.GetMediaTrackInfo_Value(tr, key) ~= want then
    reaper.SetMediaTrackInfo_Value(tr, key, want)
    return true
  end
  return false
end

-- Rend une piste IN silencieuse (aucun send actif) ou audible (au moins un send actif).
-- NE TOUCHE JAMAIS au mute des sends. Deux modes (VL.config.unrouted_mode) :
--   "parent" : B_MAINSEND = 0/1 (sortie vers le dossier parent coupee), mute de piste laisse a 0
--   "mute"   : B_MUTE = 1/0 (mute de piste), envoi au parent laisse a 1
local function set_input_silent(tr, silent)
  if not tr then return false end
  local ch
  if VL.config.unrouted_mode == "mute" then
    ch = set_track_prop(tr, "B_MAINSEND", 1)
    ch = set_track_prop(tr, "B_MUTE", silent and 1 or 0) or ch
  else
    ch = set_track_prop(tr, "B_MUTE", 0)
    ch = set_track_prop(tr, "B_MAINSEND", silent and 0 or 1) or ch
  end
  return ch
end

-- Vrai s'il existe au moins un send NON mute de cette IN vers un looper (etat REEL REAPER)
local function input_has_active_send(tr, loopers)
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
local function reachable_loopers(k)
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
    local aux = track_by_index_1based(a)
    if aux then
      -- reglages de reference : un looper qui envoie (non mute) vers cette piste d'effets
      local ref = {}
      for i = 1, NLOOP do
        local ltr = tracks.loopers[i]
        local idx = ltr and find_send(ltr, aux)
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
          local reach = reachable_loopers(k)
          for i = 1, NLOOP do
            if reach[i] and ref[i] and (not best or ref[i].vol > best.vol) then best = ref[i] end
          end
          if best then
            local idx = ensure_send(src, aux)
            if idx then
              local ch = set_send_val(src, idx, "B_MUTE", 0)
              ch = set_send_val(src, idx, "D_VOL", best.vol) or ch
              ch = set_send_val(src, idx, "D_PAN", best.pan) or ch
              ch = set_send_val(src, idx, "I_SENDMODE", best.mode) or ch
              if ch then log("info", "IN%d -> piste %d : send effet suit le looper", k, a) end
            end
          else
            local idx = find_send(src, aux)
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
      local real = input_has_active_send(tr, tracks.loopers)
      if real ~= active and VL._mm[k] ~= (tostring(active) .. tostring(real)) then
        VL._mm[k] = tostring(active) .. tostring(real)
        log("warn", "IN%d : pad=%s mais sends REAPER=%s (ecart)", k, tostring(active), tostring(real))
      elseif real == active then
        VL._mm[k] = nil
      end
      local ch = set_input_silent(tr, not active)
      if ch then
        changed = true
        log("info", "IN%d : %s", k, active and "audible (send actif)" or "silencieuse (aucun send actif)")
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
    if src and dst then set_send_open(src, dst, e.open, e.gain_db or 0) end
  end
  VL.update_input_mutes()
end

function VL.set_auto_mute_unrouted(on)
  S.cfg.auto_mute_unrouted_inputs = not not on
  if not S.cfg.auto_mute_unrouted_inputs then
    local tracks = VL.resolve_tracks(true)
    for k = 1, NIN do set_track_prop(tracks.inputs[k], "B_MUTE", 0); set_track_prop(tracks.inputs[k], "B_MAINSEND", 1) end
  else
    VL.update_input_mutes()
  end
end

function VL.toggle_auto_mute_unrouted()
  VL.set_auto_mute_unrouted(S.cfg.auto_mute_unrouted_inputs == false)
end

--------------------------------------------------------------------------
-- FX inserts : 4 slots par IN (haut page FX) + 4 slots par looper (bas)
-- Slot N = N-ieme effet "utile" sur la piste (les JSFX nowundo sont ignores sur les L).
--------------------------------------------------------------------------
local function is_nowundo_fx(tr, fx)
  local _, nm = reaper.TrackFX_GetFXName(tr, fx, "")
  nm = (nm or ""):lower()
  for _, pat in ipairs(VL.config.fx_patterns or {}) do
    if nm:find(pat, 1, true) then return true end
  end
  return false
end

-- Retourne l'index TrackFX (0-based) du slot logique 1..NSLOT, ou nil si absent
local function fx_index_for_slot(tr, slot, skip_nowundo)
  if not tr or slot < 1 then return nil end
  local n = reaper.TrackFX_GetCount(tr)
  local seen = 0
  for fx = 0, n - 1 do
    if not (skip_nowundo and is_nowundo_fx(tr, fx)) then
      seen = seen + 1
      if seen == slot then return fx end
    end
  end
  return nil
end

function VL.scan_fx_present()
  if not (reaper and reaper.CountTracks) then return end
  local tracks = VL.resolve_tracks(true)
  for k = 1, NIN do
    local tr = tracks.inputs[k]
    for slot = 1, NSLOT do
      local fx = tr and fx_index_for_slot(tr, slot, false) or nil
      S.fx_present.input[k][slot] = fx ~= nil
      -- miroir = etat REAPER (enabled) ; pas de notify au scan
      S.fx.input[k][slot] = (fx ~= nil) and reaper.TrackFX_GetEnabled(tr, fx) or false
    end
  end
  for i = 1, NLOOP do
    local tr = tracks.loopers[i]
    for slot = 1, NSLOT do
      local fx = tr and fx_index_for_slot(tr, slot, true) or nil
      S.fx_present.looper[i][slot] = fx ~= nil
      S.fx.looper[i][slot] = (fx ~= nil) and reaper.TrackFX_GetEnabled(tr, fx) or false
    end
  end
end

function VL.apply_fx(slots)
  if not (reaper and reaper.CountTracks) then return end
  slots = slots or VL.fx_list()
  local tracks = VL.resolve_tracks(true)
  reaper.PreventUIRefresh(1)
  for _, s in ipairs(slots) do
    local tr = (s.kind == "input") and tracks.inputs[s.id] or tracks.loopers[s.id]
    if tr then
      local fx = fx_index_for_slot(tr, s.slot, s.kind == "looper")
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
  if VL.follow_looper_window then VL.follow_looper_window() end   -- une fenetre looper ouverte bascule sur le nouveau
end
function VL.step_looper(d)
  S.sel_looper = ((S.sel_looper - 1 + d) % NLOOP) + 1
  follow_group()
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
  log("info", "page %d", S.page)
  -- Publier immediatement pour le miroir (section fixe : SYNC est local plus bas dans le fichier)
  if not VL.mirror_mode and reaper and reaper.SetExtState then
    reaper.SetExtState("nowundo_vl", "active_page", tostring(S.page), false)
  end
end
function VL.set_fighter_page(n)
  S.fighter_page = clamp(n, 1, 5)
  VL.hooks.fighter_page(S.fighter_page)
  if reaper and reaper.SetExtState then
    reaper.SetExtState("nowundo_vl", "fighter_page", tostring(S.fighter_page), false)
  end
  log("info", "fighter page %d", S.fighter_page)
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
  -- CLEAR individuel :
  --   court (clear / clear_part) = part active seulement (Main|Chorus|Bridge)
  --   long  (clear_full)         = les 3 parts de CE looper
  -- CLEAR ALL (global, ignore la selection) :
  --   court (clear_all)      = part active de CHAQUE looper vivant
  --   long  (clear_all_full) = les 3 parts de CHAQUE looper vivant
  -- RESET : remet pitch / speed / volume / boucle (In-Out) a leur valeur d'origine sur les loopers cibles
  reset       = { kind = "trig" },
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
  for _, k in ipairs(RESET_FLAGS) do S.loopers[t][k] = false end
  if back_to_main then S.loopers[t].part = 1 end
end

local function send(looper, action, value)
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

local function sync_fx_matches(tr, fx)
  local ok, name = reaper.TrackFX_GetFXName(tr, fx, "")
  if not (ok and type(name) == "string") then return false end
  name = name:lower()
  for _, pat in ipairs(VL.config.sync_fx_patterns) do
    if name:find(pat, 1, true) then return true end
  end
  return false
end

local function sync_find_fx()
  if not (reaper and reaper.CountTracks and reaper.TrackFX_GetCount) then return nil end
  if SYNCMOD.tr and SYNCMOD.fx and reaper.ValidatePtr2 and reaper.ValidatePtr2(0, SYNCMOD.tr, "MediaTrack*")
     and SYNCMOD.fx < reaper.TrackFX_GetCount(SYNCMOD.tr) and sync_fx_matches(SYNCMOD.tr, SYNCMOD.fx) then
    return SYNCMOD.tr, SYNCMOD.fx
  end
  local list = {}
  if reaper.GetMasterTrack then list[#list + 1] = reaper.GetMasterTrack(0) end
  for i = 0, reaper.CountTracks(0) - 1 do list[#list + 1] = reaper.GetTrack(0, i) end
  for _, tr in ipairs(list) do
    for fx = 0, reaper.TrackFX_GetCount(tr) - 1 do
      if sync_fx_matches(tr, fx) then
        SYNCMOD.tr, SYNCMOD.fx, SYNCMOD.params = tr, fx, nil
        return tr, fx
      end
    end
  end
  return nil
end

-- index des parametres FX "Host Sync (Main/Chorus/Bridge)" (les sliders caches peuvent ne pas etre exposes)
local function sync_param_index(tr, fx, p)
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
  local tr, fx = sync_find_fx()
  if not tr then
    if not SYNCMOD.warned then
      SYNCMOD.warned = true
      log("warn", "module Master Sync introuvable (cherche : %s)", table.concat(VL.config.sync_fx_patterns, " / "))
    end
  else
    local pi = sync_param_index(tr, fx, p)
    if pi then reaper.TrackFX_SetParam(tr, fx, pi, on and 1 or 0) end
  end
  reaper.gmem_attach(GMEM_NAME)
  reaper.gmem_write(VL.config.sync_inbox + p - 1, on and 1 or 2)
end

local function sync_alias_exists(alias)
  if alias <= 0 then return false end
  for si = 0, 4 do
    if (reaper.gmem_read(1000 + si * 600 + 1) or 0) == alias then return true end
  end
  return false
end

-- libere la synchro engagee sur la part p (comme le bouton Unlock) ; se souvient de ce qui etait engage
local function sync_release(p)
  local locked, mid = sync_state(p)
  if locked == 0 then return false end
  SYNCMOD.mem[p] = { mode = locked, mid = mid }
  reaper.gmem_attach(GMEM_NAME)
  reaper.gmem_write(sync_off(p), 0)
  sync_set_host(p, false)
  return true
end

-- reengage la synchro precedente (looper maitre s'il existe encore, sinon Host Reaper)
local function sync_engage(p)
  local locked = sync_state(p)
  if locked ~= 0 then return false end
  local m = SYNCMOD.mem[p]
  reaper.gmem_attach(GMEM_NAME)
  if m and m.mode == 1 and sync_alias_exists(m.mid) then
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
    if any then if sync_release(p) then n = n + 1 end
    else if sync_engage(p) then n = n + 1 end end
  end
  log("info", "SYNC %s : %d part(s)%s", any and "OFF (libere)" or "ON", n, all and " (toutes)" or " (en cours)")
end

local function exec(action, args, targets)
  local def = ACTIONS[action]
  if not def then log("error", "action inconnue : %s", tostring(action)) return end
  -- RESET : une operation par parametre, cadencee (un seul slot gmem par type de commande et par looper)
  if action == "reset" then
    for _, t in ipairs(targets) do
      for _, sub in ipairs({ "reset_volume", "reset_pitch", "reset_speed", "reset_loop_in", "reset_loop_out" }) do
        VL.queue_op({ action = sub, targets = { t } })
      end
    end
    log("info", "reset -> %d looper(s)", #targets)
    return
  end
  -- CLEAR ALL / CLEAR ALL FULL : global — une seule diffusion + reset miroir de TOUS les loopers
  if action == "clear_all" or action == "clear_all_full" then
    VL.backend.send(1, action, nil)   -- broadcast (looper ignore)
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

local function fire_lanes(a)
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
    local lanes, free = fire_lanes(a), true
    for _, l in ipairs(lanes) do if used[l] then free = false end end
    for _, l in ipairs(lanes) do used[l] = true end     -- meme saute : les suivantes du meme looper ne passent pas devant
    if free then
      table.remove(fire_queue, i)
      exec(a.action, a.args, a.targets)
    else
      i = i + 1
    end
  end
  if #fire_queue == 0 then log("info", "fire : toutes les operations envoyees") end
end

function VL.fire()                       -- execute tout ce qui est arme (dans l'ordre), puis quitte le mode Launch
  local list = S.armed
  S.armed = {}
  S.launch = false
  for _, a in ipairs(list) do fire_queue[#fire_queue + 1] = a end
  log("info", "fire : %d operation(s), mode Launch OFF", #list)
  VL.fire_pump(now())
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
  dbg("set_route %s %s->%s = %s", tostring(kind), tostring(a), tostring(b), tostring(value))
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

for n = 1, 5 do bind(1, 2, n, fn(function() VL.set_fighter_page(n) end, function() return S.fighter_page == n and "on" or "idle" end)) end

-- Rangee statut (row 1) : appui intelligent play/stop / sortie de mode
for i = 1, NLOOP do
  bind(1, 1, i, fn(function() VL.status_pad_tap(i) end))
end


-- Twister pages (rangee 2 apres decalage statut)
PAD_LABEL[1]["2,1"] = "Twister 1 In/Out"
PAD_LABEL[1]["2,2"] = "Twister 2 Pitch/Speed"
PAD_LABEL[1]["2,3"] = "Twister 3 Vol/Feedback"
PAD_LABEL[1]["2,4"] = "Twister 4 Slicer"
PAD_LABEL[1]["2,5"] = "Twister 5 Cloud"

bind(1, 2, 7, fn(function() VL.step_looper(-1) end))
bind(1, 2, 8, fn(function() VL.step_looper(1) end))
for n = 1, NPRESET do
  for r, bank in ipairs({ "routing", "group" }) do
    bind(1, 2 + r, n,   -- routing=row3, group=row4
      fn(function() VL.preset_press(bank, n) end, function()
        local p = S.presets[bank]
        return p.active == n and "on" or (p.slots[n] and "idle" or "off")
      end),
      fn(function() VL.preset_revert(bank, n) end))
  end
end
-- LAUNCH / GO : un appui active la memorisation, l'appui suivant execute tout (Go) ; appui long = annuler sans executer
bind(1, 5, 1, fn(function() VL.launch_go() end,
                 function() return S.launch and (#S.armed > 0 and "armed" or "on") or "idle" end),
               fn(function() VL.launch_cancel() end))
PAD_LABEL[1]["5,1"] = "LAUNCH / GO (long = annuler)"
-- SYNC / UNSYNC du module Master Sync : court = part en cours (Main/Chorus/Bridge), long = les 3 parts. Allume = synchro engagee.
bind(1, 5, 2, fn(function() VL.sync_toggle(false) end, function() return VL.sync_is_on() and "on" or "idle" end),
               fn(function() VL.sync_toggle(true) end))
PAD_LABEL[1]["5,2"] = "SYNC on/off (court = part en cours, long = 3 parts)"; PAD_RGB[1]["5,2"] = 0x40C0FF
bind(1, 5, 7, act("quantise_inout"))
bind(1, 5, 8, act("full_loop"))
for n = 1, 3 do bind(1, 6, n, act("part", n)) end
bind(1, 6, 4, act("speed_step", -12)); bind(1, 6, 5, act("speed_step", 12))
bind(1, 6, 6, act("pitch_step", -12)); bind(1, 6, 7, act("pitch_step", 12))
bind(1, 6, 8, act("link"))
bind(1, 7, 1, act("auto"));    bind(1, 7, 3, act("restart"));  bind(1, 7, 4, act("one_shot"))
bind(1, 7, 5, act("cloud"));   bind(1, 7, 6, act("slicer"));   bind(1, 7, 7, act("redo")); bind(1, 7, 8, act("undo"))
-- CLEAR ALL : court = part active sur les 8 | long = 3 parts sur les 8
bind(1, 8, 1, act("clear_all"), act("clear_all_full"))
-- CLEAR individuel : court = part active | long = 3 parts de ce looper (ou groupe)
bind(1, 8, 2, act("clear"), act("clear_full"))
-- RESET (au-dessus de CLEAR) : pitch / speed / volume / boucle des loopers cibles remis a l'origine
bind(1, 7, 2, act("reset"))
PAD_LABEL[1]["7,2"] = "RESET (pitch/speed/vol/loop)"; PAD_RGB[1]["7,2"] = 0xFF8040
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
  elseif row == 5 then                                          -- rappel des presets de groupe (comme la ligne 4 de la page Main apres decalage)
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
  if p.dirty_routing then
    pcall(function() VL.hooks.routing_changed(VL.routing_edges()) end)
    if VL.update_input_mutes then pcall(VL.update_input_mutes) end
  end
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
  elseif d.b.release and not d.long_fired and not d.consumed then
    dispatch(d.b.release)
  end
  VL.sync_out()
end

function VL.tick(t)
  t = t or now()
  if VL.poll_looper_feedback then VL.poll_looper_feedback() end
  VL.fire_pump(t)
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

local function looper_window_close(tr, fx)
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
        looper_window_close(tr, fx)
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
local was_open = {}
function VL.looper_button_press(i)
  local tr, fx = nil, nil
  if reaper and reaper.CountTracks then tr, fx = looper_window_target(i) end
  was_open[i] = (tr and looper_window_is_open(tr, fx)) and true or false
  VL.select_looper(i)
end

-- Relachement apres un appui court : ferme la fenetre de ce looper si elle etait deja ouverte a l'appui
function VL.looper_button_release(i)
  if was_open[i] then VL.close_looper_windows() end
  was_open[i] = nil
end

-- Appui long (1 s) : selectionne le looper (en groupe, c'est le looper selectionne qui s'ouvre) et ouvre sa fenetre
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
  -- Toujours publier groupes/routing pour Twister & dashboard (meme en hardware_test)
  VL.dash_publish(false, t)
  if reaper and reaper.SetExtState then
    reaper.SetExtState("nowundo_vl", "fighter_page", tostring(S.fighter_page or 1), false)
    reaper.SetExtState("nowundo_vl", "sel_looper", tostring(S.sel_looper or 1), false)
    reaper.SetExtState("nowundo_vl", "sel_group", tostring(S.sel_group or 0), false)
  end
  -- Garder active_page a jour pour le miroir (chaque frame, cout negligeable)
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

local function midi_device_name(is_output, index)
  local fn = is_output and reaper.GetMIDIOutputName or reaper.GetMIDIInputName
  if not fn then return "" end
  local ok, name = fn(index, "")
  if ok and type(name) == "string" then return name end      -- retval false = peripherique absent / inactif
  return ""
end

-- Ports actifs uniquement : REAPER reserve des index vides (peripheriques absents) qu'on ne liste pas.
local function list_active_ports(is_output)
  local count_fn = is_output and reaper.GetNumMIDIOutputs or reaper.GetNumMIDIInputs
  local list = {}
  if not count_fn then return list end
  for i = 0, count_fn() - 1 do
    local name = midi_device_name(is_output, i)
    if name ~= "" then list[#list + 1] = { index = i, name = name } end
  end
  return list
end

local function find_launchpad_device(is_output)
  local count_fn = is_output and reaper.GetNumMIDIOutputs or reaper.GetNumMIDIInputs
  if not count_fn then return nil, "API MIDI indisponible" end
  local list = list_active_ports(is_output)
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

local LP_OUT, LP_OUT_NAME = find_launchpad_device(true)
local LP_IN, LP_IN_NAME = find_launchpad_device(false)
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

local function lp_refresh_devices()
  LP_INPUTS, LP_OUTPUTS = list_active_ports(false), list_active_ports(true)
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
local function hw_load()
  local a = tonumber(reaper.GetExtState(HW_EXT, "idle_pos"))
  local b = tonumber(reaper.GetExtState(HW_EXT, "sat"))
  if a then HW.idle_pos = math.max(0, math.min(1, a)) end
  if b then HW.sat = math.max(0, math.min(2, b)) end
end
local function hw_save()
  reaper.SetExtState(HW_EXT, "idle_pos", string.format("%.4f", HW.idle_pos), true)
  reaper.SetExtState(HW_EXT, "sat", string.format("%.4f", HW.sat), true)
end
-- luminosite materielle 0..1 d'un etat (la fenetre garde ses propres niveaux)
local function hw_bright(led, ctrl)
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
local function hw_saturate(r, g, b)
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
  for i = #pending, 1, -1 do lp_parse_event(pending[i].msg, t) end
  local seq0 = reaper.MIDI_GetRecentInputEvent(0)
  if seq0 and seq0 > LP_LAST_SEQ then LP_LAST_SEQ = seq0 end
end

local function lp_choose_device(is_output)
  lp_refresh_devices()
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
      LP_OUT_NAME = midi_device_name(true, idx)
      lp_set_mode(true)
      -- Renvoyer les couleurs actuelles vers le nouveau port.
      for key, c in pairs(VL._hw_colors or {}) do
        local row, col = key:match("^(%-?%d+),(%-?%d+)$")
        if row and col then lp_set_rgb(tonumber(row), tonumber(col), c[1], c[2], c[3]) end
      end
    else
      LP_IN = idx
      LP_IN_NAME = midi_device_name(false, idx)
      LP_LAST_SEQ = 0
      if reaper.MIDI_GetRecentInputEvent then LP_LAST_SEQ = reaper.MIDI_GetRecentInputEvent(0) or 0 end
      LP_HELD = {}
    end
  end
end

local function lp_status_text()
  local ins = LP_IN_NAME or ("introuvable (index a regler)")
  local outs = LP_OUT_NAME or ("introuvable (index a regler)")
  return "MIDI IN: " .. ins .. " | OUT: " .. outs
end

function VL.run_gfx_test()
  lp_refresh_devices()
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
  hw_load()
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
      local kh = hw_bright(led, ctrl)
      if ctrl and not CTRL_RGB then
        local v = 255 * kh
        hr, hg_, hb = v, v, v
      else
        local sr, sg, sb = hw_saturate(r, g, b)
        hr, hg_, hb = sr * kh, sg * kh, sb * kh
      end
      hr, hg_, hb = math.floor(hr + 0.5), math.floor(hg_ + 0.5), math.floor(hb + 0.5)
      hw[key] = { hr, hg_, hb }
      lp_set_rgb(row, col, hr, hg_, hb)
    end })
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

    local s, CELL, OX, OY, HOLD, LAYERBTN = layout()
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

    if edge_down then
      local mx, my = gfx.mouse_x, gfx.mouse_y
      if mx >= INBTN.x and mx <= INBTN.x + INBTN.w and my >= INBTN.y and my <= INBTN.y + INBTN.h then
        gfx.x, gfx.y = INBTN.x, INBTN.y
        lp_choose_device(false)
      elseif mx >= OUTBTN.x and mx <= OUTBTN.x + OUTBTN.w and my >= OUTBTN.y and my <= OUTBTN.y + OUTBTN.h then
        gfx.x, gfx.y = OUTBTN.x, OUTBTN.y
        lp_choose_device(true)
      elseif in_rect(SL_IDLE, mx, my) then drag_slider = "idle"
      elseif in_rect(SL_SAT, mx, my) then drag_slider = "sat"
      elseif S.page == 4 and mx >= LAYERBTN.x and mx <= LAYERBTN.x + LAYERBTN.w
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
        hw_save()
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
    gfx.x, gfx.y = OX, 8 * s
    gfx.drawstr(VL.status())

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
  init_presets()
  VL.last = {}
  for k in pairs(down) do down[k] = nil end
  log("info", "Virtual Launchpad %s initialise", VL.VERSION)
end
VL.reset()
-- Applique l'etat de routing initial (tout ferme) + mute auto des IN non routees
if VL.scan_fx_present then VL.scan_fx_present() end
if VL.apply_routing then VL.apply_routing() end
if VL.apply_fx then VL.apply_fx() end

if rawget(_G, "VL_TEST") then return VL end
VL.run_gfx_test()
