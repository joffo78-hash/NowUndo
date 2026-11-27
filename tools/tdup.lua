-- Ctrl+D (dupliquer un rush), bug du 27 nov. Usage : python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path=\"NowUndo/Scripts/V3.21/NowUndo_Scenario.lua\"; l.execute(open(\"tools/tdup.lua\").read())"
GM = {}; CLOCK = 100.0
local EXT = {}
local LOOP
reaper = setmetatable({
  gmem_attach = function() end, gmem_read = function(i) return GM[i] or 0 end, gmem_write = function(i, v) GM[i] = v end,
  time_precise = function() return CLOCK end,
  GetExtState = function(s, k) return EXT[s .. "/" .. k] or "" end, SetExtState = function(s, k, v) EXT[s .. "/" .. k] = v end,
  HasExtState = function(s, k) return EXT[s .. "/" .. k] ~= nil end, MB = function() return 6 end,
  GetResourcePath = function() return "/nonexistent" end, get_action_context = function() return false, "/nonexistent/x.lua" end,
  defer = function(f) LOOP = f end, atexit = function() end, JS_Window_Find = function() return nil end,
  JS_VKeys_GetState = function() return string.rep("\0", 255) end, GetOS = function() return "Win64" end,
  GetUserInputs = function() return true, "nouveau nom" end,
}, { __index = function() return function() return 0 end end })
gfx = setmetatable({ w = 800, h = 600, mouse_x = 0, mouse_y = 0, mouse_cap = 0 }, { __index = function() return function() return 0 end end })
gfx.getchar = function() return 0 end
gfx.measurestr = function(t) return 8 * #tostring(t), 12 end
for _, k in ipairs({ 'mouse_wheel', 'mouse_hwheel', 'x', 'y', 'texth' }) do gfx[k] = 0 end
-- ancien set (avant la ROM) : pages RC-505 + Rushes, rushes d'usine ordinaires melanges a des perso
local L = { "NOWUNDO_MACROS 1", "P\t1\tRC-505", "P\t2\tRushes" }
local function M(id, name, text, tog) L[#L + 1] = table.concat({ "M", id, 0, name, text, tog and 1 or 0, 0, 0, "" }, "\t") end
M(1, "L1 REC", "l1 rec", true); M(2, "", "rec, a", false); M(3, "L2 CLEAR", "l2 clear", false); M(4, "MON RUSH", "l3 rev", true)
M(5, "L1 CLOUD", "l1 cloud", true); M(6, "", "all stop", false); M(6, "DOUBLE", "l2 rev", false)   -- id 6 en double (ancien bug)
L[#L + 1] = "L\t1\t1"; L[#L + 1] = "L\t65\t2"
EXT["NowUndo_Macros/set"] = table.concat(L, "\n"); EXT["NowUndo_Macros/fx_page"] = "1"
dofile(arg_path)
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
LOOP()
local macros = function() return upv(LOOP, "macros") end
local ED = upv(LOOP, "ED")
local fails = 0
local function check(label, ok) if not ok then fails = fails + 1 end print((ok and "OK   " or "FAUX ") .. label) end
local function stats()
  local ids, dup, objs, sameobj = {}, false, {}, false
  for _, m in ipairs(macros()) do
    if ids[m.id] then dup = true end; ids[m.id] = true
    if objs[m] then sameobj = true end; objs[m] = true
  end
  return #macros(), dup, sameobj
end
local function select(id) local t = upv(LOOP, "msel"); for k in pairs(t) do t[k] = nil end; t[id] = true end
local n0, d0 = stats()
check("au chargement : ids tous differents (l'ancien double est repare)", not d0)
local function find(name) local r = {}; for _, m in ipairs(macros()) do if m.name == name then r[#r + 1] = m end end return r end
select(find("MON RUSH")[1].id); ED.mdup()
local n1, d1, o1 = stats()
check("Ctrl+D sur un rush perso : +1 rush (" .. n0 .. " -> " .. n1 .. ")", n1 == n0 + 1)
check("... ids tous differents", not d1); check("... pas deux fois la meme ligne", not o1)
check("... deux MON RUSH distincts", #find("MON RUSH") == 2 and find("MON RUSH")[1].id ~= find("MON RUSH")[2].id)
local romname; for _, m in ipairs(macros()) do if m.rom then romname = m.name; select(m.id); break end end
ED.mdup()
local n2, d2, o2 = stats()
check("Ctrl+D sur un rush d'usine (" .. tostring(romname) .. ") : +1 rush", n2 == n1 + 1)
check("... ids tous differents, pas de ligne en double", not d2 and not o2)
local f = find(romname); local nr = 0; for _, m in ipairs(f) do if m.rom then nr = nr + 1 end end
check("... l'original reste en ROM, la copie est perso", #f == 2 and nr == 1)
for k = 1, 3 do select(find("MON RUSH")[1].id); ED.mdup() end
local n3, d3, o3 = stats()
check("3 Ctrl+D de plus : +3, ids differents", n3 == n2 + 3 and not d3 and not o3)
print(fails == 0 and "TOUT OK" or (fails .. " ECHEC(S)"))
