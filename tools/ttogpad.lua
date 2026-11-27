-- Toggles des sends aux = miroir de l etat reel + mode par case du Launchpad (27 nov.). Usage : python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path=\"NowUndo/Scripts/V3.21/NowUndo_Scenario.lua\"; l.execute(open(\"tools/ttogpad.lua\").read())"
GM = {}; CLOCK = 100.0
local EXT = {}
local function gr(i) return GM[i] or 0 end
local LOOP
reaper = setmetatable({
  gmem_attach = function() end, gmem_read = function(i) return gr(i) end, gmem_write = function(i, v) GM[i] = v end,
  time_precise = function() return CLOCK end,
  GetExtState = function(s, k) return EXT[s .. "/" .. k] or "" end, SetExtState = function(s, k, v) EXT[s .. "/" .. k] = v end,
  HasExtState = function(s, k) return EXT[s .. "/" .. k] ~= nil end,
  GetResourcePath = function() return "/nonexistent" end, get_action_context = function() return false, "/nonexistent/x.lua" end,
  defer = function(f) LOOP = f end, atexit = function() end,
  JS_Window_Find = function() return nil end, GetOS = function() return "Win64" end, EnumerateFiles = function() return nil end, file_exists = function() return false end,
}, { __index = function() return function() return 0 end end })
gfx = setmetatable({ w = 800, h = 600, mouse_x = 0, mouse_y = 0, mouse_cap = 0 }, { __index = function() return function() return 0 end end })
gfx.getchar = function() return 0 end
gfx.measurestr = function(t) return 8 * #tostring(t), 12 end
gfx.texth = 12
for _, k in ipairs({ 'mouse_wheel', 'mouse_hwheel', 'x', 'y', 'r', 'g', 'b', 'a', 'a2', 'mode', 'clear', 'dest', 'ext_retina' }) do gfx[k] = 0 end
local lines = { "NOWUNDO_MACROS 1", "P\t1\tRushes",
  "M\t1\t0\tREV\tl1 rev\t1\t0\t0\t",            -- rush toggle (reglage du Scenario), pose en c3 sans mode de case
  "M\t2\t0\tSLC\tslicer\t0\t0\t0\t",            -- rush normal pose en toggle (case) c4
  "L\t3\t1", "L\t4\t2\tt" }
EXT["NowUndo_Macros/set"] = table.concat(lines, "\n")
EXT["NowUndo_Macros/fx_page"] = "1"
EXT["nowundo_vl/sel_looper"] = "1"
for i = 0, 7 do GM[100 + i] = 1; local b = 1000 + i * 600; GM[b + 42] = 1; GM[b + 2] = 2; GM[b + 46] = 96000; GM[b + 45] = 96000 end
dofile(arg_path)
local function run(n) for k = 1, n do CLOCK = CLOCK + 0.03; if LOOP then LOOP() end end end
-- faux JSFX : applique rev (cmd 4) et slicer (cmd 6)
local function jsfx() for i = 0, 7 do local b = 1000 + i * 600; local c = GM[b + 48] or 0
  if c == 4 then GM[b + 17] = (GM[b + 17] or 0) > .5 and 0 or 1 end
  if c == 6 then GM[b + 8] = (GM[b + 8] or 0) > .5 and 0 or 1 end
  GM[b + 48] = 0 end end
local function step(n) for k = 1, n do CLOCK = CLOCK + 0.03; jsfx(); if LOOP then LOOP() end end end
step(5)
local function press(id, md, cell) EXT["NowUndo_Scn/mcr"] = string.format("%d\t1\t%.3f\t\t%s\t%d\n", id, CLOCK, md, cell); step(10); return EXT["NowUndo_Macros/on"] or "" end
print("depart              on =", EXT["NowUndo_Macros/on"], "rev L1 =", GM[1017])
print("appui c3 (t)        on =", press(1, "t", 3), "rev L1 =", GM[1017])
print("re-appui c3         on =", press(1, "t", 3), "rev L1 =", GM[1017])
print("appui c4 (t)        on =", press(2, "t", 4), "slicer =", GM[1008])
print("re-appui c4         on =", press(2, "t", 4), "slicer =", GM[1008])
print("migration : ligne L de c3 =", (EXT["NowUndo_Macros/set"]:match("L\t3\t1[^\n]*") or "?"):gsub("\t", " "))
