-- Scenario = liste de rushes (V3.27) : conversion des pas texte, GO / BACK. Usage : python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path=\"NowUndo/Scripts/V3.21/NowUndo_Scenario.lua\"; l.execute(open(\"tools/tscn.lua\").read())"
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
local lines = { "NOWUNDO_MACROS 1", table.concat({ "M", 1, 0, "MON REV", "l2 rev", 0, 0, 0 }, "\t") }
EXT["NowUndo_Macros/set"] = table.concat(lines, "\n"); EXT["NowUndo_Macros/fx_page"] = "1"
EXT["nowundo_scn/steps"] = "@1¦l3 cloud, l4 stop¦l2 rev"      -- pas 2 et 3 : anciens pas texte (le 3e = meme texte que le rush 1)
EXT["nowundo_vl/sel_looper"] = "2"
local LOG = {}
for i = 0, 7 do
  GM[100 + i] = 1; local b = 1000 + i * 600; GM[b + 42] = 1; GM[b + 2] = 2; GM[b + 46] = 96000; GM[b + 45] = 96000
end
local function jsfx()
  for i = 0, 7 do
    local b = 1000 + i * 600
    local c = GM[b + 48] or 0
    if c > 0 then LOG[#LOG + 1] = "L" .. (i + 1) .. ":cmd" .. c; GM[b + 48] = 0 end
  end
end
dofile(arg_path)
local function run(n) for k = 1, n do CLOCK = CLOCK + 0.03; jsfx(); if LOOP then LOOP() end end end
run(3)
local function upv(f, name, seen)
  seen = seen or {}
  if seen[f] then return end; seen[f] = true
  local k = 1
  while true do
    local n, v = debug.getupvalue(f, k); if not n then return end
    if n == name then return v end
    if type(v) == "function" then local r = upv(v, name, seen); if r then return r end end
    k = k + 1
  end
end
print("pas enregistres : " .. EXT["nowundo_scn/steps"])
local go = upv(LOOP, "go")
for n = 1, 3 do LOG = {}; go(); run(12); print("GO " .. n .. " -> " .. table.concat(LOG, " ") .. "   | " .. tostring(upv(LOOP, "msg"))) end
