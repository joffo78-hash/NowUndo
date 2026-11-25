-- Test du MIDI des rushes dans le MIDI Learn (lupa, faux REAPER) : arg_path = NowUndo/Scripts/V3.21/nowundo_midi_learn.lua
GM = {}; local EXT = {}; CLOCK = 100; local LOOP; local Q = {}; local SEQ = 0
local function push(b1, d1, d2, dev) SEQ = SEQ + 1; table.insert(Q, 1, { SEQ, string.char(b1, d1, d2), dev }) end
reaper = setmetatable({
  GetExtState = function(s, k) return EXT[s .. "/" .. k] or "" end, SetExtState = function(s, k, v) EXT[s .. "/" .. k] = v end,
  HasExtState = function() return false end, DeleteExtState = function() end,
  time_precise = function() return CLOCK end, GetResourcePath = function() return "/nonexistent" end,
  get_action_context = function() return false, "/nonexistent/x.lua" end,
  gmem_attach = function() end, gmem_read = function(i) return GM[i] or 0 end, gmem_write = function(i, v) GM[i] = v end,
  defer = function(f) LOOP = f end, atexit = function() end,
  MIDI_GetRecentInputEvent = function(i) local e = Q[i + 1]; if not e then return 0 end; return e[1], e[2], 0, e[3] end,
  GetMIDIInputName = function(d) return true, d == 3 and "QuNeo" or "Twister" end,
  GetNumMIDIInputs = function() return 4 end, JS_VKeys_GetState = function() return nil end, JS_VKeys_Intercept = function() return 0 end, GetNumMIDIOutputs = function() return 0 end,
}, { __index = function() return function() return 0 end end })
gfx = setmetatable({ w = 900, h = 700, mouse_x = 0, mouse_y = 0, mouse_cap = 0, texth = 12, mouse_wheel = 0, mouse_hwheel = 0, x = 0, y = 0, r = 0, g = 0, b = 0, a = 1, ext_retina = 1 }, { __index = function() return function() return 0 end end })
gfx.getchar = function() return 0 end
gfx.measurestr = function(t) return 7 * #tostring(t), 12 end
-- maps apprises AVANT le chargement : id|status|ch|d1|d2|ret|gate  (appareil du faux MIDI 3 = "QuNeo")
EXT["NowUndo_MIDILearn/maps"] = table.concat({
  "par:fdbk_L2|176|1|20|-1|0|0", "par:speed_L1|176|1|21|-1|0|0", "io:in_L3|176|1|22|-1|0|0", "io:out_L3|176|1|23|-1|0|0",
  "act:restart_L1|176|1|24|-1|0|0", "act:reverse_L2|176|1|25|-1|0|0", "par:out_vol|176|1|26|-1|0|0" }, "\n")
EXT["NowUndo_MIDILearn/maps_dev"] = "par:fdbk_L2|QuNeo\npar:speed_L1|QuNeo\nio:in_L3|QuNeo\nio:out_L3|QuNeo\nact:restart_L1|QuNeo\nact:reverse_L2|QuNeo\npar:out_vol|QuNeo"
for i = 1, 4 do GM[1000 + (i - 1) * 600] = 1; GM[130 + i - 1] = 100 end   -- loopers 1..4 vivants
for i = 1, 4 do GM[6000 + i] = 0 end
GM[6001] = 1; GM[6002] = 1                                                    -- L1 et L2 dans le groupe 1
for i = 1, 4 do local b = 1000 + (i - 1) * 600; GM[b + 42] = 1; GM[b + 46] = 96000; GM[b + 44] = 12000; GM[b + 45] = 48000 end
dofile(arg_path)
local function run(n) for k = 1, n do CLOCK = CLOCK + 0.03; if LOOP then LOOP() end end end
local function box(i, o) local b = 1000 + (i - 1) * 600; return GM[b + o] or 0, GM[b + o + 1] or 0 end
local function clr() for k in pairs(GM) do if k >= 1000 and k < 1000 + 8 * 600 then local o = (k - 1000) % 600; if o == 180 or o == 195 or o == 197 or o == 160 or o == 48 then GM[k] = 0 end end end end
run(3)
-- 1) Feedback de L2 (groupe 1 avec L1) : les DEUX loopers recoivent la valeur ; L3 (hors groupe) rien
push(0xB1, 20, 127, 3); run(3)
print("1 fdbk L2 -> id L1 / L2 / L3 :", (box(1, 180)), (box(2, 180)), (box(3, 180)), "| valeur L1 / L2 :", select(2, box(1, 180)), select(2, box(2, 180)), "(attendu : 19 19 0 et 2 2)")
clr()
-- 2) Speed de L1 : meme groupe, 127 -> 4 ; 0 -> 0,25
push(0xB1, 21, 127, 3); run(3); local _, v1 = box(2, 180); local id2 = box(2, 180)
print("2 speed L1 127 -> id/valeur L2 :", id2, v1, "(attendu : 3 4)")
clr(); push(0xB1, 21, 0, 3); run(3); print("  speed L1 0 -> valeur L2 :", select(2, box(2, 180)), "(attendu : 0.25)")
clr()
-- 3) In / Out de L3 (pas de groupe, autonomes : cmd 1 et cmd 2)
push(0xB1, 22, 64, 3); run(3)
print("3 In L3 64 -> cmd", GM[1000 + 2 * 600 + 160], "valeur", GM[1000 + 2 * 600 + 161], "(attendu : cmd 1, 48000 borne a In+Width = 60000 -> 48000)")
clr(); push(0xB1, 23, 127, 3); run(3)
print("  Out L3 127 -> cmd", GM[1000 + 2 * 600 + 160], "valeur", GM[1000 + 2 * 600 + 162], "(attendu : cmd 2, 96000)")
clr()
-- 4) Restart L1 : individuel (L2 du meme groupe ne bouge pas) ; Reverse L2 : suit le groupe
push(0xB1, 24, 127, 3); run(3)
print("4 restart L1 -> cmd L1 / L2 :", GM[1000 + 48], GM[1600 + 48], "(attendu : 16 0)")
GM[1000 + 48], GM[1600 + 48] = 0, 0
push(0xB1, 25, 127, 3); run(3)
print("  reverse L2 -> cmd L1 / L2 / L3 :", GM[1000 + 48], GM[1600 + 48], GM[2200 + 48], "(attendu : 4 4 0)")
GM[1000 + 48], GM[1600 + 48] = 0, 0
-- 5) la selection (L1 selectionne, groupe 0) : volume de sortie sur le seul looper selectionne
EXT["nowundo_vl/sel_looper"] = "4"; clr()
push(0xB1, 26, 127, 3); run(3)
print("5 out vol (selection = L4) -> id L4 / L1 :", (box(4, 180)), (box(1, 180)), "(attendu : 22 0)")
-- 6) onglets : nombre de cibles
print("6 fichier charge sans erreur ; verifie dans Lua :")
