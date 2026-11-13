-- @description NowUndo MIDI Learn — Launchpad + Twister
-- @version 2.6
-- @about
--   v2.6 : pages Twister 7 (Custom) et 8 (Display). Groupe "Custom P7" : 16 knobs + 16 push dont la fonction se choisit
--          dans un MENU (colonne Learn -> Menu), parmi les reglages / actions du looper ; s'appliquent au looper selectionne.
--          Assignations : ExtState "custom" (sauvees avec le modele).
--   v2.5 : groupe "Looper" : Rec Density, Rec Density Length, Fade, Mix, Degradation, Stereo, Feedback, Output Volume,
--          Dry/Wet du Slicer, du Cloud et du Beat Repeat (v2.6)
--          (CC absolu ; note / push = valeur par defaut ; Pickup possible) + Full Loop.
--          Navigation auto du Twister : Slicer -> page Slicer, Cloud -> page Cloud, Pitch/Speed -> page Pitch/Speed,
--          Rec / Re-Rec / Clear All -> page Volume, Quantise In/Out -> page In/Out (comme le Launchpad).
--          Relache -> Volume : couper Slicer / Cloud, pitch revenu a 0, speed revenu a 100 %.
--          Pages Twister : bouton 1 = Vol/Fdbk, 3 = In/Out (Twister v3.3).
--   v2.2 : page Twister 6 "Effets" (FX Router) + parametre learn "Selection FX" (+ / - / encodeur / knob absolu).
--   Mapping MIDI pour actions NowUndo + navigation + 16 knobs / 16 boutons Twister.
--
--   Twister : 16 knobs + 16 push appris ici ; le script Twister lit les maps
--   et applique selon fighter_page (page active).
--
--   Actions -> gmem direct. Navigation -> ExtState (VL suit si lance).
--   Ports Launchpad ignores. Zoom UI : + / - ou Ctrl+molette.
--
--   v2 : LEARN AUX par page Twister (1..5) pour d'autres controleurs (2e Twister, BCR32...),
--        navigation +/- et encodeur (loopers, pages Twister, pages Launchpad),
--        moteur actif meme fenetre fermee (relancer le script = rouvrir la fenetre).
--
--   v2.3 : MODELE dans un fichier a cote du script (nowundo_midi_learn_model.txt), charge par defaut
--        au demarrage. Boutons : Sauver modele / Recharger / Exporter / Importer / Demarrer sur modele.
--
--   ExtState "NowUndo_MIDILearn".

local EXT = "NowUndo_MIDILearn"

-- Dossier du script : le modele y est sauve (pas de recherche de fichier)
local SCRIPT_DIR = (function()
  local src = debug.getinfo(1, "S").source or ""
  local d = src:match("^@(.*[/\\])")
  if d then return d end
  local _, p = reaper.get_action_context()
  return (p or ""):match("^(.*[/\\])") or ""
end)()
local MODEL_FILE = SCRIPT_DIR .. "nowundo_midi_learn_model.txt"
local VL_SEC = "nowundo_vl"
local GMEM = "nowundo_sync"
local DASH_BASE = 6000
local IGNORE_DEV_SUBSTR = { "lpminimk3", "launchpad", "lpmini" }

local W, H = 1200, 700
local ui_scale = tonumber(reaper.GetExtState(EXT, "ui_scale")) or 1.25
if ui_scale < 0.85 then ui_scale = 0.85 end
if ui_scale > 2.5 then ui_scale = 2.5 end

local function S(v) return math.floor(v * ui_scale + 0.5) end

local function layout_cols()
  return {
    { id = "name",  x = S(8),   w = S(240), title = "Fonction" },
    { id = "cat",   x = S(252), w = S(90),  title = "Groupe" },
    { id = "midi",  x = S(346), w = S(230), title = "MIDI  @ peripherique" },
    { id = "learn", x = S(584), w = S(80),  title = "Learn" },
    { id = "ret",   x = S(672), w = S(60),  title = "Return" },
    { id = "gate",  x = S(738), w = S(55),  title = "Gate" },
    { id = "pick",  x = S(800), w = S(55),  title = "Pickup" },
    { id = "clear", x = S(862), w = S(55),  title = "Clear" },
  }
end

--------------------------------------------------------------------------
-- Catalogue
--------------------------------------------------------------------------
local function A(id, name, cat, action, args, toggle)
  return { id = id, name = name, cat = cat, kind = "action", action = action, args = args, toggle = toggle and true or false }
end
local function U(id, name, cat, ui)
  return { id = id, name = name, cat = cat, kind = "ui", ui = ui }
end

local TARGETS = {}

for i = 1, 8 do
  TARGETS[#TARGETS + 1] = U("sel:L" .. i, "Select L" .. i, "Selection", { sel_looper = i })
end
for g = 1, 4 do
  TARGETS[#TARGETS + 1] = U("sel:G" .. g, "Select Group " .. g, "Selection", { sel_group = g })
end
-- Bouton a MAINTENIR : tant qu'il est enfonce, le principe de groupe est inhibe (actions sur le looper selectionne seul)
TARGETS[#TARGETS + 1] = U("hold:nogroup", "Inhibe groupe (maintenir)", "Selection", { inhibit = true })
for p = 1, 4 do
  TARGETS[#TARGETS + 1] = U("page:" .. p, "Launchpad Page " .. p, "Pages", { page = p })
end
-- Noms LOGIQUES des pages (contenu) : utilises par les learns aux "aux:P" (P = contenu, inchange)
local FIGHTER_NAMES = { "In/Out", "Pitch/Speed", "Vol/Fdbk", "Slicer", "Cloud", "Effets", "Custom", "Display" }
-- v2.5 : nom de la page appelee par chaque BOUTON (Twister v3.3 : pages 1 et 3 permutees)
local SLOT_NAMES = { "Vol/Fdbk", "Pitch/Speed", "In/Out", "Slicer", "Cloud", "Effets", "Custom", "Display" }
local NFIGHTER = #FIGHTER_NAMES
for n = 1, NFIGHTER do
  TARGETS[#TARGETS + 1] = U("fighter:" .. n, "Twister page " .. n .. " (" .. SLOT_NAMES[n] .. ")", "Pages", { fighter = n })
end
for i = 1, 8 do
  TARGETS[#TARGETS + 1] = U("status:" .. i, "Status L" .. i .. " (smart)", "Status", { status = i })
end

local acts = {
  A("act:rec", "Rec / Overdub", "Transport", "rec_overdub", nil, true),
  A("act:stop_play", "Stop / Play", "Transport", "stop_play", nil, true),
  A("act:replace", "Replace", "Transport", "replace", nil, true),
  A("act:multiply", "Multiply", "Transport", "multiply", nil, true),
  A("act:rerec", "Re-Rec", "Transport", "rerec"),
  A("act:restart", "Restart", "Transport", "restart"),
  A("act:clear", "Clear (part)", "Transport", "clear"),
  A("act:clear_full", "Clear Full (3 parts)", "Transport", "clear_full"),
  A("act:clear_all", "Clear All", "Transport", "clear_all"),
  A("act:clear_all_full", "Clear All Full", "Transport", "clear_all_full"),
  A("act:undo", "Undo", "Transport", "undo"),
  A("act:redo", "Redo", "Transport", "redo"),
  A("act:reverse", "Reverse", "Modes", "reverse", nil, true),
  A("act:auto_rev", "Auto Reverse", "Modes", "auto_rev", nil, true),
  A("act:slicer", "Slicer", "Modes", "slicer", nil, true),
  A("act:cloud", "Cloud", "Modes", "cloud", nil, true),
  A("act:one_shot", "One-Shot", "Modes", "one_shot", nil, true),
  A("act:link", "Link P/S", "Modes", "link", nil, true),
  A("act:auto", "Auto Rec", "Modes", "auto", nil, true),
  A("act:part1", "Part Main", "Parts", "part", 1),
  A("act:part2", "Part Chorus", "Parts", "part", 2),
  A("act:part3", "Part Bridge", "Parts", "part", 3),
  A("act:speed_m", "Speed -1 oct", "Tune", "speed_step", -12),
  A("act:speed_p", "Speed +1 oct", "Tune", "speed_step", 12),
  A("act:pitch_m", "Pitch -12 st", "Tune", "pitch_step", -12),
  A("act:pitch_p", "Pitch +12 st", "Tune", "pitch_step", 12),
  A("act:full_loop", "Full Loop", "Looper", "full_loop"),
  A("act:quant", "Quantise In/Out", "Tune", "quantise_inout"),
  A("act:reset", "Reset params", "Tune", "reset"),
  A("act:launch_go", "Launch GO", "Launch", "launch_go"),
  A("act:launch_cancel", "Launch Cancel", "Launch", "launch_cancel"),
  A("act:sync", "Sync Toggle", "Launch", "sync_toggle"),
  -- [SCN] commandes du script NowUndo_Scenario (ex pads Main / Chorus / Bridge du Launchpad)
  A("act:scn_validate", "Scenario : Valider le pas", "Scenario", "scn_validate"),
  A("act:scn_prev", "Scenario : Pas precedent", "Scenario", "scn_prev"),
  A("act:scn_next", "Scenario : Pas suivant", "Scenario", "scn_next"),
  A("act:scn_capture", "Scenario : Capture on/off", "Scenario", "scn_capture"),
  A("act:rec_dub", "Rec -> Overdub (mode, sortie du 1er rec)", "Transport", "rec_dub_toggle"),
}
for _, a in ipairs(acts) do TARGETS[#TARGETS + 1] = a end

-- v2.5 : reglages continus du looper. CC absolu 0..127 -> plage ; note / push = valeur par defaut.
-- wr = identifiant d'ecriture JSFX (+180/+181), off = offset de lecture (gmem part active), curve = exposant de la course
local function P(id, name, wr, off, lo, hi, def, curve, step)
  return { id = id, name = name, cat = "Looper", kind = "param", wr = wr, off = off,
           lo = lo, hi = hi, def = def, curve = curve or 1, step = step }
end
for _, p in ipairs({
  P("par:density",  "Rec Density (%)",                29, 29, 0, 100, 100),
  P("par:dens_len", "Rec Density Length (1/1..1/64)", 30, 30, 0, 6,   2, 1, 1),
  P("par:fade",     "Fade (ms)",                      7,  7,  0, 500, 10, 2),   -- course quadratique : finesse en bas
  P("par:mix",      "Mix (dry / wet)",                5,  5,  0, 1,   1),
  P("par:degrad",   "Degradation",                    20, 20, 0, 1,   1),
  P("par:stereo",   "Stereo (largeur)",               21, 21, 0, 1,   0),
  P("par:fdbk",     "Feedback",                       19, 19, 0, 2,   1),
  P("par:out_vol",  "Output Volume",                  22, 22, 0, 2,   1),
  P("par:sl_mix",   "Slicer Dry/Wet",                 61, 193, 0, 1,  1),
  P("par:cl_mix",   "Cloud Dry/Wet",                  36, 36, 0, 1,   1),
  P("par:br_mix",   "Beat Repeat Dry/Wet",            60, 194, 0, 1,  1),
}) do TARGETS[#TARGETS + 1] = p end

-- Restart INDIVIDUEL par looper : agit toujours sur le looper nomme, sans tenir compte de la selection / du groupe
for i = 1, 8 do
  local a = A("act:restart_L" .. i, "Restart L" .. i, "Transport", "restart")
  a.looper = i
  TARGETS[#TARGETS + 1] = a
end

-- Navigation +/- et encodeur relatif (loopers, pages Twister, pages Launchpad)
for _, d in ipairs({
  { "looper",  "Looper" },
  { "fighter", "Twister page" },
}) do
  local k, label = d[1], d[2]
  TARGETS[#TARGETS + 1] = { id = "nav:" .. k .. ":inc", name = label .. "  +  (suivant)", cat = "Navigation", kind = "nav", nav = { what = k, dir = 1 } }
  TARGETS[#TARGETS + 1] = { id = "nav:" .. k .. ":dec", name = label .. "  -  (precedent)", cat = "Navigation", kind = "nav", nav = { what = k, dir = -1 } }
  TARGETS[#TARGETS + 1] = { id = "nav:" .. k .. ":enc", name = label .. "  encodeur (relatif)", cat = "Navigation", kind = "nav", nav = { what = k, rel = true } }
end

-- Selection d'effet (FX Router) : fait defiler la bibliotheque pour le SLOT choisi sur le Launchpad.
-- Execute par le script Twister (ExtState "NowUndo_FX") : step = pas relatifs cumules, abs = valeur 0..1.
for _, d in ipairs({
  { "inc", "Selection FX  +  (suivant)",        { what = "fxsel", dir = 1 } },
  { "dec", "Selection FX  -  (precedent)",      { what = "fxsel", dir = -1 } },
  { "enc", "Selection FX  encodeur (relatif)",  { what = "fxsel", rel = true } },
  { "abs", "Selection FX  knob (absolu)",       { what = "fxsel", abs = true } },
}) do
  TARGETS[#TARGETS + 1] = { id = "nav:fxsel:" .. d[1], name = d[2], cat = "FX", kind = "nav", nav = d[3] }
end

-- Un seul jeu physique Twister : 16 knobs + 16 push (page = fighter active)
for idx = 0, 15 do
  local row, col = math.floor(idx / 4) + 1, (idx % 4) + 1
  TARGETS[#TARGETS + 1] = {
    id = string.format("tw:knob:%d", idx),
    name = string.format("Twister Knob %d (r%d c%d)", idx + 1, row, col),
    cat = "Twister",
    kind = "tw_knob",
    idx = idx,
  }
  TARGETS[#TARGETS + 1] = {
    id = string.format("tw:btn:%d", idx),
    name = string.format("Twister Push %d (r%d c%d)", idx + 1, row, col),
    cat = "Twister",
    kind = "tw_btn",
    idx = idx,
  }
end

-- LEARN AUX : 16 knobs + 16 push pour CHAQUE page Twister (1..7 ; la page 8 Display n'a rien a piloter)
-- Un controleur appris ici pilote la page en permanence (page active ou non).
for p = 1, NFIGHTER - 1 do
  for idx = 0, 15 do
    local row, col = math.floor(idx / 4) + 1, (idx % 4) + 1
    TARGETS[#TARGETS + 1] = {
      id = string.format("aux:%d:knob:%d", p, idx),
      name = string.format("P%d %s - Knob %d (r%d c%d)", p, FIGHTER_NAMES[p], idx + 1, row, col),
      cat = "Aux P" .. p, kind = "aux_knob", page = p, idx = idx,
    }
    TARGETS[#TARGETS + 1] = {
      id = string.format("aux:%d:btn:%d", p, idx),
      name = string.format("P%d %s - Push %d (r%d c%d)", p, FIGHTER_NAMES[p], idx + 1, row, col),
      cat = "Aux P" .. p, kind = "aux_btn", page = p, idx = idx,
    }
  end
end

-- ===== CATALOGUE page Twister 7 "Custom" (IDENTIQUE dans nowundo_midi_learn.lua et twisterinoutreset.lua) =====
-- Familles (couleur) : play = rouge (lecture / sortie / transport), pitch = rose, inout = vert (fenetre / rec),
--                      slicer = jaune, cloud = bleu.
-- Knobs : { id, libelle, famille, wr (id ecriture JSFX), off (offset lecture gmem), lo, hi, defaut, courbe ("log" | exposant), pas, io }
--   io = "in" | "out" | "width" : fenetre de boucle (edition +160..162), valeurs en fraction de la boucle.
-- Push : { id, libelle, famille, cmd (+48), arg (+49), wr, valeur ("tog" = bascule lue a l'offset tog_off), tog_off }
CU_KNOBS = {
  { "speed",     "Speed",              "pitch",  3,  3,   0.01,  100,  1,    "log" },
  { "pitch",     "Pitch",              "pitch",  4,  4,   -48,   48,   0 },
  { "grain",     "Grain (ms)",         "pitch",  6,  6,   20,    200,  80 },
  { "grain_fade","Grain Fade %",       "pitch",  13, 13,  5,     50,   25 },
  { "mix",       "Mix",                "play",   5,  5,   0,     1,    1 },
  { "out_vol",   "Output Volume",      "play",   22, 22,  0,     2,    1 },
  { "feedback",  "Feedback",           "play",   19, 19,  0,     2,    1 },
  { "degrad",    "Degradation",        "play",   20, 20,  0,     1,    1 },
  { "stereo",    "Stereo",             "play",   21, 21,  0,     1,    0 },
  { "pos",       "Position (%)",       "play",   10, 47,  0,     100,  0 },
  { "auto_thr",  "Auto Seuil",         "play",   11, 11,  0.01,  0.8,  0.15, "log" },
  { "in",        "In",                 "inout",  0,  0,   0,     1,    0,    nil, nil, "in" },
  { "out",       "Out",                "inout",  0,  0,   0,     1,    1,    nil, nil, "out" },
  { "width",     "Width",              "inout",  0,  0,   0,     1,    1,    nil, nil, "width" },
  { "fade",      "Fade (ms)",          "inout",  7,  7,   0,     500,  10,   2 },
  { "rec_dens",  "Rec Density %",      "inout",  29, 29,  0,     100,  100 },
  { "dens_len",  "Rec Density Length", "inout",  30, 30,  0,     6,    2,    nil, 1 },
  { "sl_decay",  "Slice Decay",        "slicer", 16, 16,  4,     2000, 150,  "log" },
  { "sl_attack", "Slice Attack",       "slicer", 55, 174, 0,     100,  0,    nil, 1 },
  { "sl_steps",  "Slicer Steps",       "slicer", 47, 167, 1,     32,   8,    nil, 1 },
  { "sl_rate",   "Slicer Rate",        "slicer", 15, 15,  0,     5,    3,    nil, 1 },
  { "sl_grid",   "Grid Sub",           "slicer", 33, 33,  0,     9,    3,    nil, 1 },
  { "sl_max",    "Max Slices",         "slicer", 48, 168, 0,     32,   16,   nil, 1 },
  { "sl_pitch",  "Slicer Pitch Spread","slicer", 34, 34,  0,     100,  0 },
  { "sl_detect", "Detect Thresh",      "slicer", 50, 165, 0.001, 0.8,  0.01, "log" },
  { "cl_dens",   "Cloud Density",      "cloud",  26, 26,  0,     1,    0.5 },
  { "cl_agit",   "Cloud Agitation",    "cloud",  27, 27,  0,     1,    0 },
  { "cl_spread", "Cloud Spread",       "cloud",  28, 28,  0,     1,    0.1 },
  { "cl_size",   "Cloud Size",         "cloud",  62, 190, 1,     1000, 80,   "log" },
  { "cl_pitch",  "Cloud Pitch Spread", "cloud",  35, 35,  0,     100,  0 },
  { "cl_mix",    "Cloud Dry/Wet",      "cloud",  36, 36,  0,     1,    1 },
  { "sl_mix",    "Slicer Dry/Wet",     "slicer", 61, 193, 0,     1,    1 },
  { "br_mix",    "Beat Repeat Dry/Wet","inout",  60, 194, 0,     1,    1 },
  { "cl_pos",    "Cloud Pos",          "cloud",  38, 38,  0,     100,  50 },
  { "cl_diff",   "Cloud Diffuse",      "cloud",  64, 192, 0,     1,    0 },
  { "cl_lfo_r",  "Cloud LFO Rate",     "cloud",  40, 40,  0.1,   4,    1 },
  { "cl_lfo_d",  "Cloud LFO Depth",    "cloud",  41, 41,  0,     100,  0 },
}
CU_BTNS = {
  { "rec",        "Rec / Overdub",      "play",   1 },
  { "stop_play",  "Stop / Play",        "play",   3 },
  { "replace",    "Replace",            "play",   9 },
  { "auto_rep",   "Auto-Replace",       "play",   10 },
  { "multiply",   "Multiply",           "play",   13 },
  { "rerec",      "Re-Rec",             "play",   17 },
  { "restart",    "Restart",            "play",   16 },
  { "clear",      "Clear (part)",       "play",   2 },
  { "clear_full", "Clear Full",         "play",   11 },
  { "undo",       "Undo",               "play",   14 },
  { "redo",       "Redo",               "play",   15 },
  { "auto",       "Auto Rec",           "play",   19 },
  { "reverse",    "Reverse",            "play",   4 },
  { "pingpong",   "Ping-Pong",          "play",   5 },
  { "one_shot",   "One-Shot",           "play",   18 },
  { "reset",      "Reset params",       "play",   24 },
  { "link",       "Link P/S",           "pitch",  8 },
  { "speed_m",    "Speed -1 oct",       "pitch",  20, -12 },
  { "speed_p",    "Speed +1 oct",       "pitch",  20, 12 },
  { "pitch_m12",  "Pitch -12",          "pitch",  21, -12 },
  { "pitch_p12",  "Pitch +12",          "pitch",  21, 12 },
  { "pitch_m1",   "Pitch -1",           "pitch",  21, -1 },
  { "pitch_p1",   "Pitch +1",           "pitch",  21, 1 },
  { "full_loop",  "Full Loop",          "inout",  22 },
  { "quant",      "Quantise In/Out",    "inout",  23 },
  { "beat_rep",   "Beat Repeat",        "inout",  33 },
  { "slicer",     "Slicer on/off",      "slicer", 6 },
  { "sl_regen",   "Slicer Regen",       "slicer", nil, nil, 56, 1 },
  { "sl_src",     "Slicer Trans/Grid",  "slicer", nil, nil, 32, "tog", 32 },
  { "sl_link",    "Slicer Link",        "slicer", nil, nil, 58, "tog", 177 },
  { "cloud",      "Cloud on/off",       "cloud",  7 },
  { "cl_freeze",  "Cloud Freeze",       "cloud",  nil, nil, 63, "tog", 191 },
  { "cl_posmode", "Cloud Pos Link/Free","cloud",  nil, nil, 37, "tog", 37 },
  { "knob_def",   "Defaut du knob",     "" },
}
CU_FAM_NAME = { { "play", "Lecture / Sortie / Transport" }, { "pitch", "Pitch / Speed / Grain" },
                { "inout", "In / Out / Rec" }, { "slicer", "Slicer" }, { "cloud", "Cloud" }, { "", "Autre" } }

-- v2.6 : page Twister 7 "Custom" : pas de learn, un MENU par knob / push (assignation lue par le script Twister)
for idx = 0, 15 do
  local row, col = math.floor(idx / 4) + 1, (idx % 4) + 1
  TARGETS[#TARGETS + 1] = { id = "cu:knob:" .. idx, name = string.format("P7 Custom - Knob %d (r%d c%d)", idx + 1, row, col),
                            cat = "Custom P7", kind = "cu_knob", idx = idx }
  TARGETS[#TARGETS + 1] = { id = "cu:btn:" .. idx, name = string.format("P7 Custom - Push %d (r%d c%d)", idx + 1, row, col),
                            cat = "Custom P7", kind = "cu_btn", idx = idx }
end
local CUL = { raw = nil, a = {},
  RGB = { play = {0.95, 0.40, 0.38}, pitch = {0.95, 0.55, 0.82}, inout = {0.32, 0.88, 0.52},
          slicer = {0.98, 0.83, 0.22}, cloud = {0.35, 0.70, 1.00} } }
function CUL.is(t) return t.kind == "cu_knob" or t.kind == "cu_btn" end
function CUL.parse()
  local raw = reaper.GetExtState(EXT, "custom") or ""
  if raw ~= CUL.raw then
    CUL.raw, CUL.a = raw, {}
    for key, id in raw:gmatch("([kb]%d+)=([%w_]+)") do CUL.a[key] = id end
  end
  return CUL.a
end
function CUL.key(t) return (t.kind == "cu_knob" and "k" or "b") .. t.idx end
function CUL.get(t) return CUL.parse()[CUL.key(t)] end
function CUL.list(t) return t.kind == "cu_knob" and CU_KNOBS or CU_BTNS end
function CUL.find(t, id) for _, e in ipairs(CUL.list(t)) do if e[1] == id then return e end end end
function CUL.set(t, id)
  local a = CUL.parse()
  a[CUL.key(t)] = id
  local parts = {}
  for i = 0, 15 do for _, pfx in ipairs({ "k", "b" }) do if a[pfx .. i] then parts[#parts + 1] = pfx .. i .. "=" .. a[pfx .. i] end end end
  local raw = table.concat(parts, ";")
  reaper.SetExtState(EXT, "custom", raw, true)
  CUL.raw = raw
end
function CUL.text(t)
  local e = CUL.find(t, CUL.get(t) or "")
  if not e then return "— (aucune)", { 0.45, 0.45, 0.5 } end
  return e[2], CUL.RGB[e[3]] or { 0.8, 0.8, 0.85 }
end
function CUL.menu(t)
  local cur = CUL.get(t)
  local items, ids = { (cur and "" or "!") .. "(aucune)" }, { "" }
  for _, f in ipairs(CU_FAM_NAME) do
    local sub = {}
    for _, e in ipairs(CUL.list(t)) do if e[3] == f[1] then sub[#sub + 1] = e end end
    for j, e in ipairs(sub) do
      local lab = ((j == #sub) and "<" or "") .. ((cur == e[1]) and "!" or "") .. e[2]
      if j == 1 then lab = ">" .. f[2] .. "|" .. lab end
      items[#items + 1] = lab; ids[#ids + 1] = e[1]
    end
  end
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local pick = gfx.showmenu(table.concat(items, "|"))
  if pick and pick >= 1 and ids[pick] then
    CUL.set(t, ids[pick] ~= "" and ids[pick] or nil)
    return true                                    -- (notify est definie plus bas : l'appelant affiche le message)
  end
  return false
end

local BY_ID = {}
for _, t in ipairs(TARGETS) do BY_ID[t.id] = t end

local CMD = {
  rec_overdub = 1, clear = 2, clear_part = 2, stop_play = 3,
  reverse = 4, auto_rev = 5, slicer = 6, cloud = 7, link = 8,
  replace = 9, auto_rep = 10, clear_full = 11, part = 12,
  multiply = 13, undo = 14, redo = 15, restart = 16, rerec = 17,
  one_shot = 18, auto = 19, speed_step = 20, pitch_step = 21,
  full_loop = 22, quantise_inout = 23, clear_all = 2, clear_all_full = 11,
}

--------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------
local maps = {}
local learn_id, learn_armed_t = nil, 0
local scroll, filter = 0, ""
local status_msg, status_t = "", 0
local midi_out_idx, last_seq = -1, 0
local last_cap = 0
local auto_next = true      -- apres un learn aux : passe au suivant (meme type)
local want_scroll_id = nil
local pickup = {}          -- id -> true : soft takeover (knobs sans retour)
local ui_open = true

local function notify(msg)
  status_msg = msg
  status_t = reaper.time_precise()
end

local function sanitize(str)
  return ((str or ""):gsub("[|\r\n]", "/"))
end

local function is_aux_id(id) return id:sub(1, 4) == "aux:" end

local function save_maps()
  local lines, aux = {}, {}
  for id, m in pairs(maps) do
    if is_aux_id(id) then
      aux[#aux + 1] = string.format("%s|%d|%d|%d|%d|%d|%s",
        id, m.status or 0, m.ch or 0, m.d1 or 0,
        m.ret and 1 or 0, m.gate and 1 or 0, sanitize(m.dev))
    else
      lines[#lines + 1] = string.format("%s|%d|%d|%d|%d|%d|%d",
        id, m.status or 0, m.ch or 0, m.d1 or 0, m.d2 or -1,
        m.ret and 1 or 0, m.gate and 1 or 0)
    end
  end
  table.sort(lines)
  table.sort(aux)
  reaper.SetExtState(EXT, "maps", table.concat(lines, "\n"), true)
  reaper.SetExtState(EXT, "maps_aux", table.concat(aux, "\n"), true)
  local pk = {}
  for id in pairs(pickup) do pk[#pk + 1] = id end
  table.sort(pk)
  reaper.SetExtState(EXT, "pickup", table.concat(pk, ","), true)
  -- peripherique de chaque map principale (aux l'a deja dans sa ligne)
  local devl = {}
  for id, m in pairs(maps) do
    if not is_aux_id(id) and m.dev and m.dev ~= "" then
      devl[#devl + 1] = id .. "|" .. sanitize(m.dev)
    end
  end
  table.sort(devl)
  reaper.SetExtState(EXT, "maps_dev", table.concat(devl, "\n"), true)
  -- NB : "midi_out" n'est PAS reecrit ici (sinon on ecrase le choix fait dans la fenetre Twister)
  reaper.SetExtState(EXT, "ui_scale", tostring(ui_scale), true)
end

local function load_maps()
  maps = {}
  local raw = reaper.GetExtState(EXT, "maps") or ""
  for line in raw:gmatch("[^\n]+") do
    local id, st, ch, d1, d2, ret, gate = line:match("^([^|]+)|(%d+)|(%d+)|(%d+)|(%-?%d+)|(%d+)|(%d+)$")
    if id and BY_ID[id] then
      maps[id] = {
        status = tonumber(st), ch = tonumber(ch), d1 = tonumber(d1),
        d2 = tonumber(d2), ret = ret == "1", gate = gate == "1",
      }
    end
  end
  local rawa = reaper.GetExtState(EXT, "maps_aux") or ""
  for line in rawa:gmatch("[^\n]+") do
    local id, st, ch, d1, ret, gate, dev = line:match("^([^|]+)|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)|(.*)$")
    if id and BY_ID[id] then
      maps[id] = {
        status = tonumber(st), ch = tonumber(ch), d1 = tonumber(d1), d2 = -1,
        ret = ret == "1", gate = gate == "1", dev = dev or "",
      }
    end
  end
  for line in (reaper.GetExtState(EXT, "maps_dev") or ""):gmatch("[^\n]+") do
    local id, dev = line:match("^([^|]+)|(.*)$")
    if id and maps[id] and not is_aux_id(id) then maps[id].dev = dev end
  end
  pickup = {}
  for id in (reaper.GetExtState(EXT, "pickup") or ""):gmatch("[^,]+") do
    if BY_ID[id] then pickup[id] = true end
  end
  midi_out_idx = tonumber(reaper.GetExtState(EXT, "midi_out")) or -1
end

local function fighter_page()
  local p = tonumber(reaper.GetExtState(VL_SEC, "fighter_page")) or 1
  return math.max(1, math.min(NFIGHTER, math.floor(p)))
end

--------------------------------------------------------------------------
-- MIDI helpers
--------------------------------------------------------------------------
local function fmt_midi(m)
  if not m or not m.status then return "—" end
  local st = m.status
  if st == 0x90 or st == 0x80 then
    return string.format("Note ch%d n%d", m.ch + 1, m.d1)
  elseif st == 0xB0 then
    return string.format("CC ch%d #%d", m.ch + 1, m.d1)
  end
  return string.format("%02X ch%d %d", st, m.ch + 1, m.d1)
end

-- CSV : id,name,cat,status,ch,d1,d2,return,gate,midi
local function browse_save_csv()
  -- 1) extension js_ReaScriptAPI (recommandee)
  if reaper.JS_Dialog_BrowseForSaveFile then
    local rv, file = reaper.JS_Dialog_BrowseForSaveFile(
      "Exporter MIDI Learn (CSV)", "", "nowundo_midi_learn.csv",
      "CSV files (.csv)\0*.csv\0All files\0*.*\0")
    if rv and file and file ~= "" then
      if not file:lower():match("%.csv$") then file = file .. ".csv" end
      return file
    end
    return nil
  end
  -- 2) SWS
  if reaper.BR_Win32_GetSaveFileName then
    local file = reaper.BR_Win32_GetSaveFileName("Exporter MIDI Learn (CSV)", "", "CSV files|*.csv||")
    if file and file ~= "" then
      if not file:lower():match("%.csv$") then file = file .. ".csv" end
      return file
    end
    return nil
  end
  -- 3) Fallback : chemin complet a taper
  local def = "nowundo_midi_learn.csv"
  local proj = reaper.GetProjectPath("") or ""
  if proj ~= "" then
    if not proj:match("[/\\]$") then proj = proj .. "/" end
    def = proj .. "nowundo_midi_learn.csv"
  end
  local ok, fname = reaper.GetUserInputs("Export CSV — indique le chemin complet", 1,
    "Chemin complet du fichier CSV:,extrawidth=420", def)
  if ok and fname and fname ~= "" then return fname end
  return nil
end

local function export_csv()
  local fname = browse_save_csv()
  if not fname then return end
  local lines = { "id,name,cat,status,ch,d1,d2,return,gate,midi,dev" }
  local ids = {}
  for id in pairs(maps) do ids[#ids + 1] = id end
  table.sort(ids)
  for _, id in ipairs(ids) do
    local m = maps[id]
    local t = BY_ID[id]
    local name = (t and t.name or id):gsub('"', "'")
    local cat = (t and t.cat or ""):gsub('"', "'")
    lines[#lines + 1] = string.format('%s,"%s","%s",%d,%d,%d,%d,%d,%d,"%s","%s"',
      id, name, cat,
      m.status or 0, m.ch or 0, m.d1 or 0, m.d2 or -1,
      m.ret and 1 or 0, m.gate and 1 or 0, fmt_midi(m), ((m.dev or ""):gsub('"', "'")))
  end
  local f = io.open(fname, "w")
  if not f then
    notify("Export impossible: " .. tostring(fname))
    return
  end
  f:write(table.concat(lines, "\n") .. "\n")
  f:close()
  local short = fname:match("([^/\\]+)$") or fname
  notify("Export: " .. short .. " (" .. (#lines - 1) .. " maps)")
end

local function import_csv()
  local rv, fname = reaper.GetUserFileNameForRead("", "Importer MIDI Learn (CSV)", "csv")
  if not rv or not fname or fname == "" then return end
  local f = io.open(fname, "r")
  if not f then
    notify("Import impossible: " .. tostring(fname))
    return
  end
  local content = f:read("*a") or ""
  f:close()
  local n, first = 0, true
  for line in content:gmatch("[^\r\n]+") do
    if first then
      first = false
      if line:lower():find("^id,") then goto cont end
    end
    local id, st, ch, d1, d2, ret, gate = line:match(
      '^([^,]+),"[^"]*","[^"]*",(%d+),(%d+),(%d+),(%-?%d+),(%d+),(%d+)'
    )
    if not id then
      id, st, ch, d1, d2, ret, gate = line:match(
        "^([^,]+),[^,]*,[^,]*,(%d+),(%d+),(%d+),(%-?%d+),(%d+),(%d+)"
      )
    end
    if id and BY_ID[id] then
      local q = {}
      for qs in line:gmatch('"([^"]*)"') do q[#q + 1] = qs end
      maps[id] = {
        status = tonumber(st), ch = tonumber(ch), d1 = tonumber(d1),
        d2 = tonumber(d2), ret = ret == "1", gate = gate == "1",
        dev = (id:sub(1, 4) == "aux:") and (q[4] or "") or ((q[4] and q[4] ~= "") and q[4] or nil),
      }
      n = n + 1
    end
    ::cont::
  end
  save_maps()
  notify(string.format("Import: %d mappings", n))
end


-- Sortie MIDI : on memorise le NOM du port (l'index change quand on branche/debranche un controleur).
-- Nom memorise mais port absent => on n'envoie rien (jamais de port choisi "a la place").
local function out_by_name(name, idx)
  if name and name ~= "" and reaper.GetNumMIDIOutputs then
    for i = 0, (reaper.GetNumMIDIOutputs() or 0) - 1 do
      local ok, nm = reaper.GetMIDIOutputName(i, "")
      if ok and nm == name then return i end
    end
    return -1
  end
  return idx or -1
end

local out_cache = { t = -10, idx = -1 }
local function cur_out()
  local t = reaper.time_precise()
  if t - out_cache.t > 1 then
    out_cache.t = t
    out_cache.idx = out_by_name(reaper.GetExtState(EXT, "midi_out_name"),
      tonumber(reaper.GetExtState(EXT, "midi_out")) or -1)
  end
  return out_cache.idx
end

local function send_return(m, vel_or_val)
  if not m or not m.ret then return end
  local out = cur_out()
  if out < 0 then return end
  if not reaper.SendMIDIMessageToHardware then return end
  local d2 = math.max(0, math.min(127, math.floor(vel_or_val or 0)))
  if m.status == 0x90 or m.status == 0x80 then
    pcall(reaper.SendMIDIMessageToHardware, out, string.char(0x90 + m.ch, m.d1, d2))
  elseif m.status == 0xB0 then
    pcall(reaper.SendMIDIMessageToHardware, out, string.char(0xB0 + m.ch, m.d1, d2))
  end
end

--------------------------------------------------------------------------
-- gmem engine
--------------------------------------------------------------------------
local function gbase(looper, part)
  return 1000 + (looper - 1) * 600 + ((part or 1) - 1) * 200
end

local function alive(i)
  reaper.gmem_attach(GMEM)
  if (reaper.gmem_read(1000 + (i - 1) * 600) or 0) <= 0 then return false end
  if (reaper.time_precise() - (reaper.gmem_read(130 + (i - 1)) or 0)) > 3.0 then return false end
  return true
end

local function sel_looper()
  return math.max(1, math.min(8, tonumber(reaper.GetExtState(VL_SEC, "sel_looper")) or 1))
end

local function sel_group()
  return math.max(0, math.min(4, tonumber(reaper.GetExtState(VL_SEC, "sel_group")) or 0))
end

local function group_of(i)
  reaper.gmem_attach(GMEM)
  local g = math.floor((reaper.gmem_read(DASH_BASE + i) or 0) + 0.5)
  return (g >= 1 and g <= 4) and g or 0
end

-- Inhibition de groupe : pad GROUPE maintenu sur le Launchpad ou bouton "Inhibe groupe" maintenu ici
local function group_inhibited()
  return reaper.GetExtState(VL_SEC, "group_inhibit") == "1"
      or reaper.GetExtState(VL_SEC, "group_inhibit_ml") == "1"
end

local function targets()
  if group_inhibited() then return { sel_looper() } end
  local g = sel_group()
  if g > 0 then
    local t = {}
    for i = 1, 8 do if group_of(i) == g then t[#t + 1] = i end end
    if #t > 0 then return t end
  end
  return { sel_looper() }
end

local function active_part(looper)
  local ap = reaper.gmem_read(gbase(looper, 1) + 42) or 1
  if ap < 1 or ap > 3 then ap = 1 end
  return ap
end

local function write_cmd(looper, cmd, arg)
  if not cmd then return end
  reaper.gmem_attach(GMEM)
  local b = gbase(looper, active_part(looper))
  if arg ~= nil then reaper.gmem_write(b + 49, arg) end
  reaper.gmem_write(b + 48, cmd)
end

local function write_param(looper, id, value)
  reaper.gmem_attach(GMEM)
  local b = gbase(looper, active_part(looper))
  reaper.gmem_write(b + 181, value)
  reaper.gmem_write(b + 180, id)
end

local SCN_CMD = { scn_validate = "validate", scn_prev = "prev", scn_next = "next", scn_capture = "toggle" }
local function fire_action(action, args, looper)
  if action == "rec_dub_toggle" then   -- [REC>DUB] file de commandes lue par le Launchpad
    local cur = reaper.GetExtState("NowUndo_VLcmd", "q")
    reaper.SetExtState("NowUndo_VLcmd", "q", cur .. string.format("rec_dub_toggle\t%.3f\n", reaper.time_precise()), false)
    return
  end
  if SCN_CMD[action] then          -- [SCN] file de commandes lue par NowUndo_Scenario.lua
    local cur = reaper.GetExtState("NowUndo_Scn", "cmd")
    reaper.SetExtState("NowUndo_Scn", "cmd", cur .. string.format("%s\t%.3f\n", SCN_CMD[action], reaper.time_precise()), false)
    return
  end
  if action == "launch_go" or action == "launch_cancel" or action == "sync_toggle" then
    reaper.SetExtState(VL_SEC, "midi_ui", action, false)
    return
  end
  local cmd = CMD[action]
  if looper then   -- action ciblee sur UN looper precis (ex : Restart L3)
    if alive(looper) then write_cmd(looper, cmd, args) end
    return
  end
  if action == "clear_all" or action == "clear_all_full" then
    for i = 1, 8 do if alive(i) then write_cmd(i, cmd) end end
    return
  end
  for _, i in ipairs(targets()) do
    if alive(i) then write_cmd(i, cmd, args) end
  end
end

-- Le Launchpad ne lit pas le GMEM pour la selection : on passe par le meme canal que le Display (miroir) :
-- ExtState nowundo_vl/state + rev, que le Launchpad relit a chaque cycle (VL.sync_poll).
local function vl_sorted_keys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return ta < tb end
    return a < b
  end)
  return keys
end
local function vl_ser(v)
  local tv = type(v)
  if tv == "number" then return math.type(v) == "integer" and tostring(v) or string.format("%.17g", v)
  elseif tv == "boolean" then return tostring(v)
  elseif tv == "string" then return string.format("%q", v)
  elseif tv == "table" then
    local parts = {}
    for _, k in ipairs(vl_sorted_keys(v)) do parts[#parts + 1] = "[" .. vl_ser(k) .. "]=" .. vl_ser(v[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "nil"
end
local vl_edit_n = 0
local function vl_state_edit(fn)
  local raw = reaper.GetExtState(VL_SEC, "state")
  if raw == "" then return false end          -- Launchpad (ou Display) pas lance
  local f = load("return " .. raw, "vl_state", "t", {})
  if not f then return false end
  local ok, t = pcall(f)
  if not ok or type(t) ~= "table" then return false end
  fn(t)
  vl_edit_n = vl_edit_n + 1
  reaper.SetExtState(VL_SEC, "state", vl_ser(t), false)
  reaper.SetExtState(VL_SEC, "rev", "learn:" .. vl_edit_n .. ":" .. string.format("%.3f", reaper.time_precise()), false)
  return true
end

local function fire_ui(ui)
  if ui.sel_looper then
    local i = ui.sel_looper
    vl_state_edit(function(t)
      t.sel_looper = i
      t.sel_group = (type(t.group_of) == "table" and t.group_of[i]) or 0   -- comme follow_group() du Launchpad
    end)
    reaper.SetExtState(VL_SEC, "sel_looper", tostring(i), false)   -- lecture immediate (Twister, pas suivants)
  end
  if ui.sel_group then
    local g = ui.sel_group
    vl_state_edit(function(t) t.sel_group = g end)   -- sinon VL.render (Launchpad) ecrase sel_group a la frame suivante
    reaper.SetExtState(VL_SEC, "sel_group", tostring(ui.sel_group), false)
    reaper.SetExtState(VL_SEC, "midi_ui", "sel_group:" .. ui.sel_group, false)
  end
  if ui.page then reaper.SetExtState(VL_SEC, "midi_ui", "page:" .. ui.page, false) end
  if ui.fighter then
    local n = math.max(1, math.min(NFIGHTER, math.floor(ui.fighter)))
    vl_state_edit(function(t) t.fighter_page = n end)
    reaper.SetExtState(VL_SEC, "fighter_page", tostring(n), false)
  end
  if ui.status then reaper.SetExtState(VL_SEC, "midi_ui", "status:" .. ui.status, false) end
end

local function wrap(v, lo, hi)
  if v > hi then return lo elseif v < lo then return hi end
  return v
end

-- Encodeur relatif : complement a 2 (1 / 127) ou offset binaire (65 / 63)
local function rel_dir(v)
  if v >= 1 and v <= 32 then return 1 end
  if v >= 96 then return -1 end
  if v >= 33 and v <= 63 then return -1 end
  if v >= 65 and v <= 95 then return 1 end
  return 0
end


local function fire_nav(nav, dir)
  if dir == 0 then return end
  if nav.what == "looper" then
    -- saute les loopers absents ; si aucun n'est vivant, ne fait rien
    local cur = sel_looper()
    local nxt = cur
    for _ = 1, 8 do
      nxt = wrap(nxt + dir, 1, 8)
      if alive(nxt) then break end
    end
    if nxt ~= cur and alive(nxt) then fire_ui({ sel_looper = nxt }) end
  elseif nav.what == "fighter" then
    fire_ui({ fighter = wrap(fighter_page() + dir, 1, NFIGHTER) })
  elseif nav.what == "fxsel" then
    -- pas cumules tant que le script Twister ne les a pas consommes (un tour d'encodeur = plusieurs evenements)
    local cur = tonumber(reaper.GetExtState("NowUndo_FX", "step")) or 0
    reaper.SetExtState("NowUndo_FX", "step", tostring(math.max(-200, math.min(200, cur + dir))), false)
  end
end

-- Page active → parametre pour knob idx 0..15
local function tw_apply_knob(idx, norm)
  local page = fighter_page()
  reaper.gmem_attach(GMEM)
  if page == 1 then
    local looper = math.floor(idx / 2) + 1
    local is_out = (idx % 2) == 1
    if not alive(looper) then return end
    local b = gbase(looper, active_part(looper))
    local len = reaper.gmem_read(b + 46) or 0
    if len <= 0 then return end
    local in_s = reaper.gmem_read(b + 44) or 0
    local w_s = reaper.gmem_read(b + 45) or 0
    if is_out then
      local out = math.max(in_s, math.min(len, norm * len))
      reaper.gmem_write(b + 162, out)
      reaper.gmem_write(b + 160, 2)
    else
      local out = in_s + w_s
      local new_in = math.max(0, math.min(out, norm * len))
      reaper.gmem_write(b + 161, new_in)
      reaper.gmem_write(b + 160, 1)
    end
  elseif page == 2 then
    local looper = (idx % 8) + 1
    if not alive(looper) then return end
    if idx < 8 then write_param(looper, 4, norm * 96 - 48)
    else write_param(looper, 3, 2 ^ (norm * 4 - 2)) end
  elseif page == 3 then
    local looper = (idx % 8) + 1
    if not alive(looper) then return end
    if idx < 8 then write_param(looper, 22, norm * 2)
    else write_param(looper, 19, norm * 2) end
  elseif page == 4 then
    local map = {
      [0] = {50, 0.01, 0.8}, [1] = {51, 30, 1000}, [2] = {16, 10, 2000}, [3] = {34, 0, 100},
      [4] = {47, 1, 32}, [5] = {48, 0, 64}, [6] = {49, 1, 4}, [7] = {14, 0, 5},
      [8] = {15, 0, 5}, [9] = {32, 0, 1},
      [12] = {42, 0, 127}, [13] = {44, 0, 3000}, [15] = {43, 0, 1},
    }
    local spec = map[idx]
    if not spec then return end
    local v = spec[2] + norm * (spec[3] - spec[2])
    for _, i in ipairs(targets()) do if alive(i) then write_param(i, spec[1], v) end end
  elseif page == 5 then
    local map = {
      [0] = {26, 0, 1}, [1] = {27, 0, 1}, [2] = {28, 0, 1}, [3] = {35, 0, 100},
      [4] = {38, 0, 100}, [5] = {40, 0.1, 4}, [6] = {41, 0, 100}, [7] = {39, 0, 2},
    }
    local spec = map[idx]
    if not spec then return end
    local v = spec[2] + norm * (spec[3] - spec[2])
    for _, i in ipairs(targets()) do if alive(i) then write_param(i, spec[1], v) end end
  end
end

local function tw_apply_btn(idx, down)
  if not down then return end
  local page = fighter_page()
  if page == 1 then
    local looper = math.floor(idx / 2) + 1
    local is_out = (idx % 2) == 1
    if not alive(looper) or is_out then return end
    local b = gbase(looper, active_part(looper))
    local len = reaper.gmem_read(b + 46) or 0
    if len > 0 then
      reaper.gmem_write(b + 161, 0); reaper.gmem_write(b + 160, 1)
      reaper.gmem_write(b + 162, len); reaper.gmem_write(b + 160, 2)
    end
  elseif page == 2 then
    local looper = (idx % 8) + 1
    if not alive(looper) then return end
    if idx < 8 then write_param(looper, 4, 0) else write_param(looper, 3, 1) end
  elseif page == 3 then
    local looper = (idx % 8) + 1
    if not alive(looper) then return end
    if idx < 8 then write_param(looper, 22, 1) else write_param(looper, 19, 1) end
  end
end

-- v2.5 : reglages continus "param"
local function param_value(t, n)
  n = math.max(0, math.min(1, n)) ^ (t.curve or 1)
  local v = t.lo + n * (t.hi - t.lo)
  if t.step then v = math.floor(v / t.step + 0.5) * t.step end
  return v
end
local function param_norm(t, v)
  local n = math.max(0, math.min(1, (v - t.lo) / (t.hi - t.lo)))
  return n ^ (1 / (t.curve or 1))
end
local function param_write(t, v)
  for _, i in ipairs(targets()) do if alive(i) then write_param(i, t.wr, v) end end
end
-- Soft takeover (Pickup coche) : la valeur entrante est ignoree tant qu'elle n'a pas rejoint / croise la valeur actuelle
local pk_par = {}
local function param_pickup_ok(t, n)
  local s = sel_looper()
  if not alive(s) then return true end
  reaper.gmem_attach(GMEM)
  local cur = param_norm(t, reaper.gmem_read(gbase(s, active_part(s)) + t.off) or t.def)
  local now = reaper.time_precise()
  local st = pk_par[t.id]
  if not st then st = { eng = false }; pk_par[t.id] = st end
  if st.eng and st.t_set and (now - st.t_set) > 0.3 and math.abs(cur - (st.last or cur)) > 0.03 then
    st.eng = false; st.prev = nil                    -- modifie ailleurs (UI, Twister...) : on re-attrape
  end
  if not st.eng then
    local d = n - cur
    if math.abs(d) <= 0.02 or (st.prev and st.prev * d < 0) then st.eng = true end
    st.prev = d
    if not st.eng then return false end
  end
  st.last, st.t_set = n, now
  return true
end

-- v2.5 : NAVIGATION AUTO du Twister (meme regle que le Launchpad). Valeur = BOUTON de page (1 Vol, 2 Pitch, 3 In/Out...)
local AUTO_TW = { slicer = 4, cloud = 5, speed_step = 2, pitch_step = 2,
                  rec_overdub = 1, rerec = 1, clear_all = 1, clear_all_full = 1, quantise_inout = 3 }
-- Relache -> Volume (page 1) : couper Slicer / Cloud, pitch revenu a 0, speed revenu a 100 %.
local function auto_twister(action, looper, args)
  local pg = AUTO_TW[action]
  if not pg then return end
  local s = looper or sel_looper()
  if alive(s) then
    reaper.gmem_attach(GMEM)
    local b = gbase(s, active_part(s))
    if action == "slicer" or action == "cloud" then
      local on = (action == "slicer") and ((reaper.gmem_read(b + 8) or 0) == 1) or ((reaper.gmem_read(b + 24) or 0) > 0.5)
      if on then pg = 1 end                                        -- on coupe le mode -> Volume
    elseif action == "pitch_step" then
      local np = math.max(-48, math.min(48, (reaper.gmem_read(b + 4) or 0) + (tonumber(args) or 12)))
      if math.abs(np) < 0.01 then pg = 1 end
    elseif action == "speed_step" then
      local ns = math.max(0.01, math.min(100, (reaper.gmem_read(b + 3) or 1) * (2 ^ ((tonumber(args) or 12) / 12))))
      if math.abs(ns - 1) < 0.001 then pg = 1 end
    end
  end
  fire_ui({ fighter = pg })
end

local function execute_target(tgt, m, velocity, is_on, is_off)
  if tgt.kind == "param" then
    if m.status == 0xB0 then
      local n = velocity / 127
      if pickup[tgt.id] and not param_pickup_ok(tgt, n) then return end
      param_write(tgt, param_value(tgt, n))
    elseif is_on then
      param_write(tgt, tgt.def)                      -- note / push : valeur par defaut
    end
    return
  end
  -- Twister : applique ET renvoye par le script Twister. Ici on ne fait rien
  -- (avant : "Return" renvoyait 127 a chaque tick de knob => l'anneau sautait a fond).
  if tgt.kind == "tw_knob" or tgt.kind == "tw_btn" then return end
  if tgt.kind == "action" then
    if is_on then auto_twister(tgt.action, tgt.looper, tgt.args) end   -- v2.5 : AVANT l'action (l'etat lu est celui d'avant)
    if m.gate then
      if is_on or is_off then fire_action(tgt.action, tgt.args, tgt.looper) end
    else
      if is_on then fire_action(tgt.action, tgt.args, tgt.looper) end
    end
  elseif tgt.kind == "ui" and tgt.ui.inhibit then
    if is_on then reaper.SetExtState(VL_SEC, "group_inhibit_ml", "1", false)
    elseif is_off then reaper.SetExtState(VL_SEC, "group_inhibit_ml", "0", false) end
    return
  elseif tgt.kind == "ui" then
    if is_on then fire_ui(tgt.ui) end
  elseif tgt.kind == "nav" then
    if tgt.nav.abs then
      if m.status == 0xB0 then
        reaper.SetExtState("NowUndo_FX", "abs", string.format("%.4f", math.max(0, math.min(1, velocity / 127))), false)
      end
      return
    end
    if tgt.nav.rel then
      if m.status == 0xB0 then fire_nav(tgt.nav, rel_dir(velocity)) end
      return
    elseif is_on then
      fire_nav(tgt.nav, tgt.nav.dir)
    end
  elseif tgt.kind == "tw_knob" or tgt.kind == "tw_btn" then
    -- Applique par le script Twister (lit les memes maps ExtState)
  end
  if is_on then send_return(m, 127) end
  if is_off then send_return(m, 0) end
end

--------------------------------------------------------------------------
-- MIDI poll
--------------------------------------------------------------------------
local function parse_midi_msg(msg)
  if not msg or #msg < 2 then return nil end
  local b1 = msg:byte(1)
  local st, ch = b1 & 0xF0, b1 & 0x0F
  local d1, d2 = msg:byte(2) or 0, msg:byte(3) or 0
  if st == 0x80 then return { status = 0x90, ch = ch, d1 = d1, d2 = 0, note_off = true } end
  if st == 0x90 or st == 0xB0 then return { status = st, ch = ch, d1 = d1, d2 = d2 } end
  return nil
end

local dev_cache = {}
local function dev_name(dev)
  if type(dev) ~= "number" then return "" end
  local n = dev_cache[dev]
  if n == nil then
    n = ""
    if reaper.GetMIDIInputName then
      local ok, nm = reaper.GetMIDIInputName(math.floor(dev) & 0xFFFF, "")
      if ok and nm then n = nm end
    end
    if n ~= "" then dev_cache[dev] = n end
  end
  return n
end

local function is_ignored_dev(dname)
  local low = dname:lower()
  for _, sub in ipairs(IGNORE_DEV_SUBSTR) do
    if low:find(sub, 1, true) then return true end
  end
  return false
end

-- Le message appartient-il a un learn aux ? (alors les maps principales l'ignorent)
local function matches_aux(ev, dn)
  for id, m in pairs(maps) do
    if is_aux_id(id) and m.status == ev.status and m.ch == ev.ch and m.d1 == ev.d1
       and (not m.dev or m.dev == "" or m.dev == dn) then
      return true
    end
  end
  return false
end

local function advance_learn(from_id)
  local t = BY_ID[from_id]
  if not (auto_next and t and (t.kind == "aux_knob" or t.kind == "aux_btn")) then return end
  local found = false
  for _, x in ipairs(TARGETS) do
    if found and x.cat == t.cat and x.kind == t.kind then
      learn_id = x.id
      learn_armed_t = reaper.time_precise()
      want_scroll_id = x.id
      return
    end
    if x.id == from_id then found = true end
  end
end

-- Flux du dernier message appris : un knob qui continue de tourner ne doit PAS etre appris
-- sur la ligne suivante (auto-suivant) => sinon un meme CC finit assigne a plusieurs fonctions.
local LEARN_QUIET = 0.6   -- le controleur appris doit etre immobile ce temps avant d'apprendre la ligne suivante
local learn_block = nil   -- { dn, st, ch, t } : controleur (peripherique + canal + type) du dernier learn

local function ev_key(ev, dn)
  return ev.status .. ":" .. ev.ch .. ":" .. ev.d1 .. "@" .. (dn or "")
end

-- 1 message (meme peripherique) = 1 seule fonction : on retire les AUTRES assignations identiques.
local function steal_assignment(new_id, ev, dn)
  local removed = {}
  local new_aux = is_aux_id(new_id)
  for id, m in pairs(maps) do
    if id ~= new_id and is_aux_id(id) == new_aux
       and m.status == ev.status and m.ch == ev.ch and m.d1 == ev.d1 then
      local a, b = m.dev or "", dn or ""
      if a == b or a == "" or b == "" then
        maps[id] = nil
        removed[#removed + 1] = BY_ID[id] and BY_ID[id].name or id
      end
    end
  end
  return removed
end

local function handle_event(msg, dev)
  local dn = dev_name(dev)
  if dn ~= "" and is_ignored_dev(dn) then return end
  local ev = parse_midi_msg(msg)
  if not ev then return end
  local now = reaper.time_precise()

  if learn_id then
    -- Pendant un learn : rien n'est execute, le message sert uniquement a apprendre.
    -- Tant que le controleur qu'on vient d'apprendre continue d'envoyer (meme peripherique, meme canal,
    -- meme type : couvre aussi les sliders 14 bits MSB/LSB ou a messages multiples), on ignore.
    if learn_block and learn_block.dn == dn and learn_block.st == ev.status and learn_block.ch == ev.ch
       and (now - learn_block.t) < LEARN_QUIET then
      learn_block.t = now
      notify("Learn: relache le controleur " .. (BY_ID[learn_id] and ("avant « " .. BY_ID[learn_id].name .. " »") or ""))
      return
    end
    learn_block = nil
    local is_off = ev.note_off or (ev.status == 0x90 and ev.d2 == 0)
    if (now - learn_armed_t) > 0.05 and not is_off then
      local done_id = learn_id
      local removed = steal_assignment(done_id, ev, dn)
      maps[done_id] = {
        status = ev.status, ch = ev.ch, d1 = ev.d1, d2 = -1,
        ret = maps[done_id] and maps[done_id].ret or false,
        gate = maps[done_id] and maps[done_id].gate or false,
        dev = dn,
      }
      local msgtxt = "Learned " .. (BY_ID[done_id] and BY_ID[done_id].name or done_id) .. " ← " .. fmt_midi(maps[done_id])
      if dn ~= "" then msgtxt = msgtxt .. " @" .. dn end
      if #removed > 0 then msgtxt = msgtxt .. "   (retire de: " .. table.concat(removed, ", ") .. ")" end
      notify(msgtxt)
      learn_id = nil
      learn_block = { dn = dn, st = ev.status, ch = ev.ch, t = now }
      save_maps()
      advance_learn(done_id)
    end
    return
  end

  -- Un message appris en aux (pour CE peripherique) n'est jamais traite par les maps principales.
  if matches_aux(ev, dn) then return end

  for id, m in pairs(maps) do
    if not is_aux_id(id) and m.status == ev.status and m.ch == ev.ch and m.d1 == ev.d1
       and (not m.dev or m.dev == "" or m.dev == dn) then
      local tgt = BY_ID[id]
      if tgt then
        local is_on, is_off = false, false
        if ev.status == 0x90 then
          if ev.note_off or ev.d2 == 0 then is_off = true else is_on = true end
        elseif ev.status == 0xB0 then
          if m.gate or (tgt.kind == "ui" and tgt.ui.inhibit) then
            if ev.d2 > 0 then is_on = true else is_off = true end
          else
            if ev.d2 > 0 then is_on = true end
          end
        end
        execute_target(tgt, m, ev.d2, is_on, is_off)
      end
    end
  end
end

local function process_midi()
  if not reaper.MIDI_GetRecentInputEvent then return end
  -- MIDI_GetRecentInputEvent(0) = le plus RECENT. On collecte puis on traite du plus ancien au plus recent
  -- (avant : plus recent d'abord => une valeur de knob ancienne ecrasait la derniere, et le feedback
  -- renvoyait cette vieille valeur au controleur = "le knob se bat contre moi").
  local evs, newest = {}, nil
  for i = 0, 255 do
    local seq, msg, ts, dev = reaper.MIDI_GetRecentInputEvent(i)
    if not seq or seq == 0 then break end
    if i == 0 then newest = seq end
    if last_seq ~= 0 and seq <= last_seq then break end
    evs[#evs + 1] = { msg = msg, dev = dev }
  end
  if newest then last_seq = newest end
  for k = #evs, 1, -1 do handle_event(evs[k].msg, evs[k].dev) end
end

--------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Modele : instantane de toutes les assignations (principales + aux), pickup, sorties, exclusifs.
-- Fichier : nowundo_midi_learn_model.txt, dans le dossier du script. Charge par defaut au demarrage.
-- Boutons / touches : T sauver | L recharger | E exporter | I importer | M demarrer sur modele on/off
--------------------------------------------------------------------------
local TPL_KEYS = { "maps", "maps_aux", "maps_dev", "pickup", "midi_out", "midi_out_name", "custom" }
local model_blob = nil          -- contenu du modele tel que sauve/charge (pour detecter les modifications)
local model_dirty_t, model_dirty = -10, false

local function model_all_keys()
  local keys = {}
  for _, k in ipairs(TPL_KEYS) do keys[#keys + 1] = k end
  for p = 1, NFIGHTER do
    for _, k in ipairs({ "aux_out_", "aux_out_name_", "aux_excl_" }) do keys[#keys + 1] = k .. p end
  end
  return keys
end

local function esc(v) return (v:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\r", "")) end
local function unesc(v)
  return (v:gsub("\\(.)", function(c) if c == "n" then return "\n" end return c end))
end

local function model_serialize()
  local out = { "NOWUNDO_MIDI_MODEL 1" }
  for _, k in ipairs(model_all_keys()) do
    out[#out + 1] = k .. "\t" .. esc(reaper.GetExtState(EXT, k) or "")
  end
  return table.concat(out, "\n") .. "\n"
end

local function read_text(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local t = f:read("*a"); f:close()
  return t
end

local function write_text(path, text)
  local f = io.open(path, "w")
  if not f then return false end
  f:write(text); f:close()
  return true
end

local function model_apply(text)
  if not text or not text:find("^NOWUNDO_MIDI_MODEL") then return false end
  local allowed = {}
  for _, k in ipairs(model_all_keys()) do allowed[k] = true end
  for line in text:gmatch("[^\r\n]+") do
    local k, v = line:match("^([^\t]+)\t(.*)$")
    if k and allowed[k] then reaper.SetExtState(EXT, k, unesc(v), true) end
  end
  load_maps()
  learn_id, learn_block = nil, nil
  out_cache.t = -10
  return true
end

local function count_maps()
  local n = 0
  for _ in pairs(maps) do n = n + 1 end
  return n
end

local function save_template()
  save_maps()
  local text = model_serialize()
  if write_text(MODEL_FILE, text) then
    model_blob = text
    model_dirty = false
    notify("Modele sauve (" .. count_maps() .. " maps) : nowundo_midi_learn_model.txt")
    return true
  end
  notify("Sauvegarde impossible : " .. MODEL_FILE)
  return false
end

-- Migration : ancien modele stocke dans les ExtState (versions <= 2.2) -> fichier
local function migrate_old_template()
  if reaper.GetExtState(EXT, "tpl_exists") ~= "1" then return nil end
  local out = { "NOWUNDO_MIDI_MODEL 1" }
  for _, k in ipairs(model_all_keys()) do
    out[#out + 1] = k .. "\t" .. esc(reaper.GetExtState(EXT, "tpl_" .. k) or "")
  end
  local text = table.concat(out, "\n") .. "\n"
  write_text(MODEL_FILE, text)
  return text
end

local function load_template(silent)
  local text = read_text(MODEL_FILE) or migrate_old_template()
  if not text then
    if not silent then notify("Aucun modele : clique 'Sauver modele'") end
    return false
  end
  if not model_apply(text) then
    if not silent then notify("Modele illisible : " .. MODEL_FILE) end
    return false
  end
  model_blob = model_serialize()
  model_dirty = false
  if not silent then notify("Modele charge (" .. count_maps() .. " maps)") end
  return true
end

local function export_model()
  save_maps()
  local text = model_serialize()
  local fname
  if reaper.JS_Dialog_BrowseForSaveFile then
    local rv, file = reaper.JS_Dialog_BrowseForSaveFile("Exporter le modele MIDI Learn", SCRIPT_DIR,
      "nowundo_midi_learn_export.txt", "Modele (.txt)\0*.txt\0All files\0*.*\0")
    if rv and file and file ~= "" then fname = file end
  else
    local ok, f = reaper.GetUserInputs("Exporter le modele — chemin complet", 1,
      "Chemin complet:,extrawidth=420", SCRIPT_DIR .. "nowundo_midi_learn_export.txt")
    if ok and f and f ~= "" then fname = f end
  end
  if not fname then return end
  if not fname:lower():match("%.txt$") then fname = fname .. ".txt" end
  if write_text(fname, text) then
    notify("Exporte : " .. (fname:match("([^/\\]+)$") or fname))
  else
    notify("Export impossible : " .. fname)
  end
end

local function import_model()
  local rv, fname = reaper.GetUserFileNameForRead(SCRIPT_DIR .. "nowundo_midi_learn_export.txt",
    "Importer un modele MIDI Learn", "txt")
  if not rv or not fname or fname == "" then return end
  local text = read_text(fname)
  if not model_apply(text) then
    notify("Fichier invalide : " .. (fname:match("([^/\\]+)$") or fname))
    return
  end
  notify("Importe (" .. count_maps() .. " maps) — 'Sauver modele' pour en faire le modele par defaut")
end

local function filtered_list()
  local out, f = {}, filter:lower()
  for _, t in ipairs(TARGETS) do
    if f == "" or t.name:lower():find(f, 1, true) or t.cat:lower():find(f, 1, true) then
      out[#out + 1] = t
    end
  end
  return out
end

local function hit_col(x, cols)
  for _, c in ipairs(cols) do
    if x >= c.x and x < c.x + c.w then return c.id end
  end
end

local function mouse_click()
  local cap = gfx.mouse_cap
  local c = (cap & 1) == 1 and (last_cap & 1) == 0
  last_cap = cap
  return c
end

local function set_zoom(delta)
  ui_scale = math.max(0.85, math.min(2.5, ui_scale + delta))
  reaper.SetExtState(EXT, "ui_scale", tostring(ui_scale), true)
  notify(string.format("Zoom %.0f%%", ui_scale * 100))
end

local function draw()
  local w, h = gfx.w, gfx.h
  local ROW_H = S(26)
  local HEADER_H = S(88)
  local COLS = layout_cols()
  local font_title = S(17)
  local font_body = S(13)
  local font_small = S(12)

  gfx.set(0.10, 0.10, 0.12)
  gfx.rect(0, 0, w, h, 1)

  gfx.set(0.14, 0.14, 0.16)
  gfx.rect(0, 0, w, HEADER_H, 1)
  gfx.setfont(1, "Arial", font_title, "b")
  gfx.set(0.95, 0.45, 0.40)
  gfx.x, gfx.y = S(10), S(6)
  gfx.drawstr("NowUndo MIDI Learn")

  local nmap = 0
  for _ in pairs(maps) do nmap = nmap + 1 end
  gfx.setfont(1, "Arial", font_small)
  gfx.set(0.7, 0.7, 0.7)
  gfx.x, gfx.y = S(220), S(8)
  gfx.drawstr(string.format("%d maps  |  Twister page %d (%s)  |  zoom %.0f%%",
    nmap, fighter_page(), FIGHTER_NAMES[fighter_page()] or "?", ui_scale * 100))

  do  -- resume des pages aux
    local cnt = {}
    for id in pairs(maps) do
      local p = id:match("^aux:(%d):")
      if p then cnt[tonumber(p)] = (cnt[tonumber(p)] or 0) + 1 end
    end
    local parts = {}
    for p = 1, NFIGHTER do
      if cnt[p] then
        local ex = reaper.GetExtState(EXT, "aux_excl_" .. p) == "1" and " excl" or ""
        parts[#parts + 1] = string.format("P%d:%d%s", p, cnt[p], ex)
      end
    end
    local txt = "Aux  " .. (#parts > 0 and table.concat(parts, "  ") or "aucune") .. (auto_next and "  |  auto-suivant" or "")
    gfx.set(0.55, 0.8, 0.95)
    gfx.x, gfx.y = w - gfx.measurestr(txt) - S(12), S(8)
    gfx.drawstr(txt)
  end

  if learn_id then
    gfx.set(1, 0.4, 0.2)
    gfx.x, gfx.y = S(10), S(32)
    gfx.drawstr("LEARNING: " .. (BY_ID[learn_id] and BY_ID[learn_id].name or learn_id) .. " — note ou CC…")
  elseif status_msg ~= "" and reaper.time_precise() - status_t < 3 then
    gfx.set(0.5, 0.9, 0.6)
    gfx.x, gfx.y = S(10), S(32)
    gfx.drawstr(status_msg)
  else
    gfx.set(0.55, 0.55, 0.6)
    gfx.x, gfx.y = S(10), S(32)
    gfx.drawstr("1-6 page aux  0 tout  |  K pickup en bloc  R return en bloc  N auto-suivant  A sortie aux  X exclusif  |  F filtre  S sauver  O OUT  |  Esc")
  end

  local y0 = HEADER_H
  gfx.set(0.18, 0.18, 0.20)
  gfx.rect(0, y0, w, ROW_H, 1)
  gfx.setfont(1, "Arial", font_body, "b")
  gfx.set(0.8, 0.8, 0.85)
  for _, c in ipairs(COLS) do
    gfx.x, gfx.y = c.x, y0 + S(5)
    gfx.drawstr(c.title)
  end

  local list = filtered_list()
  local visible = math.floor((h - y0 - ROW_H - S(8)) / ROW_H)
  if visible < 1 then visible = 1 end
  if want_scroll_id then
    for k, tt in ipairs(list) do
      if tt.id == want_scroll_id then
        if k <= scroll + 1 or k > scroll + visible - 1 then scroll = math.max(0, k - 3) end
        break
      end
    end
    want_scroll_id = nil
  end
  if scroll > math.max(0, #list - visible) then scroll = math.max(0, #list - visible) end
  if scroll < 0 then scroll = 0 end

  local mx, my = gfx.mouse_x, gfx.mouse_y
  local clicked = mouse_click()

  -- Barre MODELE : boutons cliquables + etat (modele a jour / modifie)
  do
    local by, bh = S(56), S(24)
    local bx = S(10)
    gfx.setfont(1, "Arial", font_small, "b")
    local startup_on = reaper.GetExtState(EXT, "tpl_open") ~= "0"
    local btns = {
      { "Sauver modele",   save_template, { 0.22, 0.45, 0.28 } },
      { "Recharger modele", function()
          if reaper.MB("Remplacer TOUTES les assignations actuelles par le modele ?", "NowUndo MIDI Learn", 4) == 6 then load_template() end
        end, { 0.25, 0.35, 0.55 } },
      { "Exporter...",     export_model, { 0.30, 0.30, 0.34 } },
      { "Importer...",     import_model, { 0.30, 0.30, 0.34 } },
      { "Demarrer sur modele : " .. (startup_on and "OUI" or "NON"), function()
          reaper.SetExtState(EXT, "tpl_open", startup_on and "0" or "1", true)
          notify(startup_on and "Demarrage : derniere session" or "Demarrage : charge le MODELE")
        end, startup_on and { 0.20, 0.40, 0.40 } or { 0.45, 0.28, 0.20 } },
    }
    for _, b in ipairs(btns) do
      local bw = math.floor(gfx.measurestr(b[1])) + S(20)
      local hov = mx >= bx and mx < bx + bw and my >= by and my < by + bh
      local c = b[3]
      gfx.set(c[1] + (hov and .12 or 0), c[2] + (hov and .12 or 0), c[3] + (hov and .12 or 0))
      gfx.rect(bx, by, bw, bh, 1)
      gfx.set(1, 1, 1)
      gfx.x, gfx.y = bx + S(10), by + math.floor((bh - gfx.texth) / 2)
      gfx.drawstr(b[1])
      if clicked and hov then b[2]() end
      bx = bx + bw + S(6)
    end
    -- etat du modele (recalcule 1 fois par seconde)
    local now = reaper.time_precise()
    if now - model_dirty_t > 1.0 then
      model_dirty_t = now
      model_dirty = (model_blob ~= nil) and (model_serialize() ~= model_blob)
    end
    local txt, col
    if not model_blob then txt, col = "Aucun modele sauve", { 0.9, 0.6, 0.3 }
    elseif model_dirty then txt, col = "Modifie depuis le modele (non sauve)", { 0.95, 0.75, 0.3 }
    else txt, col = "Modele a jour", { 0.45, 0.85, 0.55 } end
    local tw = gfx.measurestr(txt)
    if bx + tw + S(12) < w then
      gfx.set(col[1], col[2], col[3])
      gfx.x, gfx.y = w - tw - S(12), by + math.floor((bh - gfx.texth) / 2)
      gfx.drawstr(txt)
    end
    gfx.setfont(1, "Arial", font_body)
  end

  gfx.setfont(1, "Arial", font_body)
  for row = 0, visible - 1 do
    local idx = scroll + row + 1
    local t = list[idx]
    if not t then break end
    local y = y0 + ROW_H + row * ROW_H
    local hover = my >= y and my < y + ROW_H
    if learn_id == t.id then gfx.set(0.35, 0.18, 0.12)
    elseif hover then gfx.set(0.16, 0.16, 0.19)
    elseif row % 2 == 0 then gfx.set(0.12, 0.12, 0.14)
    else gfx.set(0.11, 0.11, 0.13) end
    gfx.rect(0, y, w, ROW_H, 1)

    local m = maps[t.id]
    gfx.set(0.92, 0.92, 0.92)
    gfx.x, gfx.y = COLS[1].x, y + S(5)
    gfx.drawstr(t.name)
    gfx.set(0.6, 0.65, 0.7)
    gfx.x = COLS[2].x
    gfx.drawstr(t.cat)
    gfx.set(m and 0.4 or 0.45, m and 0.85 or 0.45, m and 0.55 or 0.5)
    gfx.x = COLS[3].x
    local midi_txt = fmt_midi(m)
    if m and m.dev and m.dev ~= "" then midi_txt = midi_txt .. "  @" .. m.dev end
    if CUL.is(t) then                                 -- v2.6 : Custom P7 = fonction choisie (couleur de sa famille)
      local c
      midi_txt, c = CUL.text(t)
      gfx.set(c[1], c[2], c[3])
    end
    while #midi_txt > 12 and gfx.measurestr(midi_txt) > COLS[3].w - S(6) do
      midi_txt = midi_txt:sub(1, #midi_txt - 2)
    end
    gfx.drawstr(midi_txt)

    local lx, lw = COLS[4].x, COLS[4].w - S(6)
    local learning = learn_id == t.id
    gfx.set(learning and 0.9 or 0.25, learning and 0.35 or 0.25, learning and 0.2 or 0.28)
    gfx.rect(lx, y + S(4), lw, ROW_H - S(8), 1)
    gfx.set(1, 1, 1)
    gfx.x, gfx.y = lx + S(12), y + S(5)
    gfx.drawstr(learning and "..." or (CUL.is(t) and "Menu" or "Learn"))

    local rx = COLS[5].x + S(18)
    local ret_on = m and m.ret
    gfx.set(ret_on and 0.2 or 0.25, ret_on and 0.7 or 0.25, ret_on and 0.4 or 0.28)
    gfx.rect(rx, y + S(6), S(16), S(16), 1)
    if ret_on then gfx.set(1, 1, 1); gfx.x, gfx.y = rx + S(3), y + S(5); gfx.drawstr("✓") end

    local gx = COLS[6].x + S(16)
    local gate_on = m and m.gate
    gfx.set(gate_on and 0.7 or 0.25, gate_on and 0.5 or 0.25, gate_on and 0.2 or 0.28)
    gfx.rect(gx, y + S(6), S(16), S(16), 1)
    if gate_on then gfx.set(1, 1, 1); gfx.x, gfx.y = gx + S(3), y + S(5); gfx.drawstr("✓") end

    if t.kind == "tw_knob" or t.kind == "aux_knob" or t.kind == "param" then
      local px = COLS[7].x + S(18)
      local pk_on = pickup[t.id]
      gfx.set(pk_on and 0.25 or 0.25, pk_on and 0.6 or 0.25, pk_on and 0.9 or 0.28)
      gfx.rect(px, y + S(6), S(16), S(16), 1)
      if pk_on then gfx.set(1, 1, 1); gfx.x, gfx.y = px + S(3), y + S(5); gfx.drawstr("✓") end
    end

    if m or (CUL.is(t) and CUL.get(t)) then
      local cx = COLS[8].x + S(6)
      gfx.set(0.35, 0.2, 0.2)
      gfx.rect(cx, y + S(4), S(44), ROW_H - S(8), 1)
      gfx.set(1, 0.7, 0.7)
      gfx.x, gfx.y = cx + S(6), y + S(5)
      gfx.drawstr("clr")
    end

    if clicked and hover then
      local col = hit_col(mx, COLS)
      if CUL.is(t) then                               -- v2.6 : Custom P7 : menu / effacer, pas de learn
        if col == "learn" or col == "midi" then
          if CUL.menu(t) then notify(t.name .. "  ->  " .. (CUL.text(t))) end
        elseif col == "clear" and CUL.get(t) then CUL.set(t, nil); notify("Cleared " .. t.name) end
      elseif col == "learn" then
        if learn_id == t.id then learn_id = nil; notify("Learn cancelled")
        else learn_id = t.id; learn_armed_t = reaper.time_precise(); notify("Learning " .. t.name) end
      elseif col == "ret" then
        maps[t.id] = maps[t.id] or { status = 0, ch = 0, d1 = 0 }
        maps[t.id].ret = not maps[t.id].ret
        save_maps()
      elseif col == "gate" then
        maps[t.id] = maps[t.id] or { status = 0, ch = 0, d1 = 0 }
        maps[t.id].gate = not maps[t.id].gate
        save_maps()
      elseif col == "pick" and (t.kind == "tw_knob" or t.kind == "aux_knob" or t.kind == "param") then
        if pickup[t.id] then pickup[t.id] = nil else pickup[t.id] = true end
        save_maps()
        notify((pickup[t.id] and "Soft takeover ON : " or "Soft takeover OFF : ") .. t.name)
      elseif col == "clear" and m then
        maps[t.id] = nil
        save_maps()
        notify("Cleared " .. t.name)
      end
    end
  end

  if #list > visible then
    local sb_h = h - y0 - ROW_H
    local thumb = math.max(S(20), sb_h * visible / #list)
    local max_s = math.max(1, #list - visible)
    local ty = y0 + ROW_H + (sb_h - thumb) * (scroll / max_s)
    gfx.set(0.3, 0.3, 0.35)
    gfx.rect(w - S(10), y0 + ROW_H, S(7), sb_h, 1)
    gfx.set(0.6, 0.4, 0.35)
    gfx.rect(w - S(10), ty, S(7), thumb, 1)
  end
end

--------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------

local function pick_midi_out()
  if not reaper.GetNumMIDIOutputs then
    notify("API MIDI OUT indisponible")
    return
  end
  local n = reaper.GetNumMIDIOutputs() or 0
  local menu, idxs = {}, {}
  for i = 0, n - 1 do
    local ok, name = reaper.GetMIDIOutputName(i, "")
    if ok and name then
      local mark = (i == midi_out_idx) and "!" or ""
      menu[#menu + 1] = mark .. name
      idxs[#idxs + 1] = i
    end
  end
  if #menu == 0 then notify("Aucune sortie MIDI"); return end
  menu[#menu + 1] = ""
  menu[#menu + 1] = "Aucun (desactiver return)"
  local pick = gfx.showmenu(table.concat(menu, "|"))
  if pick and pick > 0 then
    if pick <= #idxs then
      midi_out_idx = idxs[pick]
      local ok, name = reaper.GetMIDIOutputName(midi_out_idx, "")
      reaper.SetExtState(EXT, "midi_out", tostring(midi_out_idx), true)
      reaper.SetExtState(EXT, "midi_out_name", (ok and name) or "", true)
      out_cache.t = -10
      notify("MIDI OUT: " .. (name or tostring(midi_out_idx)))
    else
      midi_out_idx = -1
      reaper.SetExtState(EXT, "midi_out", "-1", true)
      reaper.SetExtState(EXT, "midi_out_name", "", true)
      out_cache.t = -10
      notify("MIDI OUT desactive")
    end
  end
end

local function out_label(idx)
  if not idx or idx < 0 then return "aucune" end
  local ok, name = reaper.GetMIDIOutputName(idx, "")
  return (ok and name) and name or ("#" .. idx)
end

-- Sortie MIDI (renvoi de valeurs) propre a chaque page aux
local function pick_aux_out()
  local items = {}
  for p = 1, NFIGHTER do
    local cur = tonumber(reaper.GetExtState(EXT, "aux_out_" .. p)) or -1
    items[#items + 1] = string.format("P%d %s   sortie: %s", p, FIGHTER_NAMES[p], out_label(cur))
  end
  local pg = gfx.showmenu(table.concat(items, "|"))
  if not pg or pg < 1 then return end
  local n = reaper.GetNumMIDIOutputs and reaper.GetNumMIDIOutputs() or 0
  local menu, idxs = {}, {}
  local cur = tonumber(reaper.GetExtState(EXT, "aux_out_" .. pg)) or -1
  for i = 0, n - 1 do
    local ok, name = reaper.GetMIDIOutputName(i, "")
    if ok and name then
      menu[#menu + 1] = ((i == cur) and "!" or "") .. name
      idxs[#idxs + 1] = i
    end
  end
  menu[#menu + 1] = ""
  menu[#menu + 1] = "Aucune (pas de renvoi)"
  local pick = gfx.showmenu(table.concat(menu, "|"))
  if not pick or pick < 1 then return end
  if pick <= #idxs then
    local okn, nm = reaper.GetMIDIOutputName(idxs[pick], "")
    reaper.SetExtState(EXT, "aux_out_" .. pg, tostring(idxs[pick]), true)
    reaper.SetExtState(EXT, "aux_out_name_" .. pg, (okn and nm) or "", true)
    notify(string.format("P%d aux OUT: %s", pg, out_label(idxs[pick])))
  else
    reaper.SetExtState(EXT, "aux_out_" .. pg, "-1", true)
    reaper.SetExtState(EXT, "aux_out_name_" .. pg, "", true)
    notify(string.format("P%d aux OUT desactive", pg))
  end
end

-- Exclusif : le Twister principal n'agit plus sur cette page
local function pick_aux_excl()
  local items = {}
  for p = 1, NFIGHTER do
    local on = reaper.GetExtState(EXT, "aux_excl_" .. p) == "1"
    items[#items + 1] = (on and "!" or "") .. string.format("P%d %s : controleur aux seul", p, FIGHTER_NAMES[p])
  end
  local pg = gfx.showmenu(table.concat(items, "|"))
  if not pg or pg < 1 then return end
  local on = reaper.GetExtState(EXT, "aux_excl_" .. pg) == "1"
  reaper.SetExtState(EXT, "aux_excl_" .. pg, on and "0" or "1", true)
  notify(string.format("P%d : %s", pg, on and "Twister principal actif aussi" or "controleur aux exclusif"))
end

local function open_ui()
  gfx.init("NowUndo MIDI Learn", W, H, 0, 100, 100)
  gfx.clear = 0x1A1A1E
  ui_open = true
end

local function handle_ui()
  local char = gfx.getchar()
  if char < 0 then
    ui_open = false
    gfx.quit()
    return
  end

  if char == 27 then
    learn_id = nil
  elseif char == string.byte("+") or char == string.byte("=") then
    set_zoom(0.1)
  elseif char == string.byte("-") or char == string.byte("_") then
    set_zoom(-0.1)
  elseif char == string.byte("s") or char == string.byte("S") then
    save_maps(); notify("Saved")
  elseif char == string.byte("e") or char == string.byte("E") then
    export_model()
  elseif char == string.byte("i") or char == string.byte("I") then
    import_model()
  elseif char == string.byte("o") or char == string.byte("O") then
    pick_midi_out()
  elseif char == string.byte("a") or char == string.byte("A") then
    pick_aux_out()
  elseif char == string.byte("x") or char == string.byte("X") then
    pick_aux_excl()
  elseif char == string.byte("k") or char == string.byte("K") then
    -- soft takeover en bloc sur les knobs appris de la liste affichee
    local rows, any_off = {}, false
    for _, t in ipairs(filtered_list()) do
      if (t.kind == "tw_knob" or t.kind == "aux_knob") and maps[t.id] then
        rows[#rows + 1] = t.id
        if not pickup[t.id] then any_off = true end
      end
    end
    for _, id in ipairs(rows) do pickup[id] = any_off or nil end
    save_maps()
    notify(string.format("Soft takeover %s sur %d knobs", any_off and "ON" or "OFF", #rows))
  elseif char == string.byte("t") or char == string.byte("T") then
    save_template()
  elseif char == string.byte("l") or char == string.byte("L") then
    local ok = reaper.MB("Remplacer TOUTES les assignations actuelles par le modele sauve ?", "NowUndo MIDI Learn", 4)
    if ok == 6 then load_template() end
  elseif char == string.byte("m") or char == string.byte("M") then
    local on = reaper.GetExtState(EXT, "tpl_open") ~= "0"
    reaper.SetExtState(EXT, "tpl_open", on and "0" or "1", true)
    notify(on and "Demarrage : derniere session" or "Demarrage : charge le MODELE")
  elseif char == string.byte("r") or char == string.byte("R") then
    -- Return en bloc sur les knobs appris de la liste affichee (le retour d'anneau du Twister en depend)
    local rows, any_off = {}, false
    for _, t in ipairs(filtered_list()) do
      if (t.kind == "tw_knob" or t.kind == "aux_knob") and maps[t.id] then
        rows[#rows + 1] = t.id
        if not maps[t.id].ret then any_off = true end
      end
    end
    for _, id in ipairs(rows) do maps[id].ret = any_off end
    save_maps()
    notify(string.format("Return %s sur %d knobs", any_off and "ON" or "OFF", #rows))
  elseif char == string.byte("n") or char == string.byte("N") then
    auto_next = not auto_next
    notify(auto_next and "Auto-suivant ON (learn aux enchaine)" or "Auto-suivant OFF")
  elseif char >= string.byte("1") and char <= string.byte("0") + NFIGHTER then
    filter = "Aux P" .. string.char(char); scroll = 0
  elseif char == string.byte("0") then
    filter = ""; scroll = 0
  elseif char == string.byte("f") or char == string.byte("F") then
    local rv, txt = reaper.GetUserInputs("Filter", 1, "Texte:", filter)
    if rv then filter = txt or ""; scroll = 0 end
  elseif char == 30064 then scroll = math.max(0, scroll - 1)
  elseif char == 30065 then scroll = scroll + 1
  elseif char == 30066 then scroll = math.max(0, scroll - 10)
  elseif char == 30067 then scroll = scroll + 10
  end

  local wheel = gfx.mouse_wheel
  if wheel ~= 0 then
    if (gfx.mouse_cap & 4) ~= 0 then  -- Ctrl + molette = zoom
      set_zoom(wheel > 0 and 0.1 or -0.1)
    else
      scroll = scroll - math.floor(wheel / 20)
    end
    gfx.mouse_wheel = 0
  end

  draw()
  gfx.update()
end

-- Le moteur MIDI tourne en permanence ; la fenetre est facultative.
local function main()
  reaper.SetExtState(EXT, "hb", tostring(reaper.time_precise()), false)
  process_midi()

  if reaper.GetExtState(EXT, "ui_req") == "1" then
    reaper.SetExtState(EXT, "ui_req", "", false)
    if not ui_open then open_ui() end
  end
  if ui_open then handle_ui() end

  reaper.defer(main)
end

-- Instance unique : relancer le script ne fait que rouvrir la fenetre
do
  local hb0 = tonumber(reaper.GetExtState(EXT, "hb")) or 0
  if reaper.time_precise() - hb0 < 2 then
    reaper.SetExtState(EXT, "ui_req", "1", false)
    return
  end
end
reaper.atexit(function()
  reaper.SetExtState(EXT, "hb", "0", false)
  reaper.SetExtState(VL_SEC, "group_inhibit_ml", "0", false)   -- jamais d'inhibition bloquee
end)

reaper.gmem_attach(GMEM)
load_maps()
if reaper.GetExtState(EXT, "tpl_open") ~= "0" then load_template(true) end   -- demarre sur le modele (par defaut)
if not model_blob and read_text(MODEL_FILE) then model_blob = read_text(MODEL_FILE) end
if reaper.MIDI_GetRecentInputEvent then
  last_seq = reaper.MIDI_GetRecentInputEvent(0) or 0
end
open_ui()
notify(string.format("%d fonctions | learn aux : touches 1-6", #TARGETS))
reaper.defer(main)


