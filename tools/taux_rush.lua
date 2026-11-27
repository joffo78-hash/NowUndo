-- Test des mots de rush aux1..aux5 / from aux (26 nov.). Usage : python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path=\"NowUndo/Scripts/V3.21/NowUndo_Scenario.lua\"; l.execute(open(\"tools/taux_rush.lua\").read())"
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
local R = { "l1 aux2 0.5", "in1 aux2 -6db", "aux2 off", "g1 aux3 50%", "all aux1 on", "in1-2 aux5 1", "l3 from aux2", "l3 from aux2 off", "g2 from aux4", "aux2", "aux2 0.8", "l3 from aux2", "in1 fx 2, aux1 0.3", "l1 aux9 1", "in aux2 0.5", "in fx 2", "in mute", "in 0.25", "l1 in 0.25 out 0.5" }
local TG = { [10] = "t", [11] = "g", [12] = "t" }
local lines = { "NOWUNDO_MACROS 1" }
for n, t in ipairs(R) do lines[#lines + 1] = table.concat({ "M", n, 0, "R" .. n, t, TG[n] == "t" and 1 or 0, 0, TG[n] == "g" and 1 or 0 }, "\t") end
EXT["NowUndo_Macros/set"] = table.concat(lines, "\n")
EXT["nowundo_vl/sel_looper"] = "2"
local LOG = {}
for i = 0, 7 do
  GM[100 + i] = 1; local b = 1000 + i * 600; GM[b + 42] = 1; GM[b + 2] = 2; GM[b + 46] = 96000; GM[b + 45] = 96000
end
GM[6003] = 1; GM[6005] = 1; GM[6004] = 2; GM[6008] = 2     -- groupe 1 = L3, L5 ; groupe 2 = L4, L8
local function jsfx()
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
dofile(arg_path)
local function run(n) for k = 1, n do CLOCK = CLOCK + 0.03; jsfx(); if LOOP then LOOP() end end end
run(5)
local function fire(n, t, onoff)
  LOG = {}
  EXT["NowUndo_VLcmd/q"] = ""
  EXT["NowUndo_Scn/mcr"] = (EXT["NowUndo_Scn/mcr"] or "") .. string.format("%d\t\t%.3f\t%s\n", n, CLOCK, onoff)
  run(25)
  local q = (EXT["NowUndo_VLcmd/q"] or ""):gsub("\t[%d%.]+\n", " ")
  local msg = EXT["NowUndo_Scn/last_err"] or ""
  print(string.format("%-28s %-4s -> %s %s", t, onoff, table.concat(LOG, " "), q ~= "" and ("[Launchpad: " .. q .. "]") or ""))
end
for n, t in ipairs(R) do
  if TG[n] then fire(n, t .. " (" .. TG[n] .. ")", "on"); fire(n, t .. " (" .. TG[n] .. ")", "off") else fire(n, t, "") end
end
