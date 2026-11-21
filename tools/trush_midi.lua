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
dofile(arg_path)
local function run(n) for k = 1, n do CLOCK = CLOCK + 0.03; if LOOP then LOOP() end end end
run(3)
EXT["NowUndo_Macros/set"] = "NOWUNDO_MACROS 1\nM\t5\t0\tR\tl1 rec\t0\t0\t0\t144:0:36@QuNeo\nM\t6\t0\tG\tbr\t0\t0\t1\t176:1:20@QuNeo"
EXT["NowUndo_Macros/rev"] = "1"; run(15)
push(0x90, 36, 100, 3); run(2); print("QuNeo note 36 on  -> mcr :", (EXT["NowUndo_Scn/mcr"] or ""):gsub("\n", " | "))
EXT["NowUndo_Scn/mcr"] = ""
push(0x90, 36, 100, 1); run(2); print("meme note sur le Twister -> mcr :", EXT["NowUndo_Scn/mcr"] or "")
push(0xB1, 20, 127, 3); run(2); push(0xB1, 20, 0, 3); run(2); print("CC gate 127 puis 0 -> mcr :", (EXT["NowUndo_Scn/mcr"] or ""):gsub("\n", " | "))
EXT["NowUndo_MIDILearn/rush_learn"] = "7\t" .. CLOCK; run(15)
push(0x90, 40, 90, 3); run(2); print("learn -> reponse :", (EXT["NowUndo_MIDILearn/rush_learned"] or ""):gsub("\t", " | "), "| demande effacee :", EXT["NowUndo_MIDILearn/rush_learn"] == "")
