-- Quantisation * des rushes (V3.27) : *, *1/4, *2, reverse, 1er REC. Usage : python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path=\"NowUndo/Scripts/V3.21/NowUndo_Scenario.lua\"; l.execute(open(\"tools/tstar.lua\").read())"
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
local R = { "l1 rev*", "l1 rev*1/4", "l1 rev*2", "l1 pp*1/8", "l2 rec off*" }
local lines = { "NOWUNDO_MACROS 1" }
for n, t in ipairs(R) do lines[#lines + 1] = table.concat({ "M", n, 0, "R" .. n, t, 0, 0, 0 }, "\t") end
EXT["NowUndo_Macros/set"] = table.concat(lines, "\n")
EXT["nowundo_vl/sel_looper"] = "2"
local LOG = {}
for i = 0, 7 do
  GM[100 + i] = 1; local b = 1000 + i * 600; GM[b + 42] = 1; GM[b + 2] = 2; GM[b + 46] = 96000; GM[b + 45] = 96000
end
GM[6003] = 1; GM[6005] = 1; GM[6004] = 2; GM[6008] = 2     -- groupe 1 = L3, L5 ; groupe 2 = L4, L8
function jsfx()
  for i = 0, 7 do
    local b = 1000 + i * 600
    local c = gr(b + 48)
    if c > 0 then LOG[#LOG + 1] = "L" .. (i + 1) .. ":cmd" .. c; GM[b + 48] = 0 end
    local p = gr(b + 180)
    if p > 0 then LOG[#LOG + 1] = "L" .. (i + 1) .. ":par" .. p .. "=" .. gr(b + 181); if p == 67 then GM[b + 159] = gr(b + 181) end; GM[b + 180] = 0 end
    local e = gr(b + 160)
    if e > 0 then LOG[#LOG + 1] = "L" .. (i + 1) .. ":edit" .. e; GM[b + 160] = 0 end
  end
end
-- L1 joue une boucle de 2 s (96000 a 48 kHz) : position publiee en % (+47) ; L2 = 1er REC (longueur 0, etat 1)
local T0 = CLOCK
local function phase() return ((CLOCK - T0) / 2.0) % 1 end
GM[1000 + 600 + 2] = 1; GM[1000 + 600 + 46] = 0; GM[1000 + 600 + 45] = 0
local oldjsfx = jsfx
jsfx = function()
  GM[1000 + 47] = ((GM[1000 + 17] or 0) > 0.5 and (1 - phase()) or phase()) * 100   -- reverse : la tete recule
  oldjsfx()
end
dofile(arg_path)
local function run(n) for k = 1, n do CLOCK = CLOCK + 0.03; jsfx(); if LOOP then LOOP() end end end
run(5)
run(5)
local function at_phase(p) while math.abs(phase() - p) > 0.016 do run(1) end end
for n, t in ipairs(R) do
  if n == 5 then GM[1000 + 17] = 0 end
  at_phase(0.30)
  if n == 4 then GM[1000 + 17] = 1 end                       -- rush 4 : L1 en reverse
  LOG = {}
  local t0, p0 = CLOCK, phase()
  EXT["NowUndo_Scn/mcr"] = (EXT["NowUndo_Scn/mcr"] or "") .. string.format("%d\t1\t%.3f\t\n", n, CLOCK)
  local fired
  for k = 1, 200 do run(1); if #LOG > 0 then fired = CLOCK; break end end
  local cyc = fired and ((fired - t0) / 2.0) or -1
  print(string.format("%-12s arme a %.2f du cycle -> part %.3f cycle(s) plus tard (point vise : %s)  %s", t, p0, cyc,
    ({ "1.0 - 0.30 = 0.70", "0.50 - 0.30 = 0.20", "2.0 - 0.30 = 1.70", "reverse : cycle entendu 0.30 -> 0.375 : 0.075", "sortie du 1er REC : immediat" })[n], table.concat(LOG, " ")))
end
