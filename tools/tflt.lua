-- Rushes d'usine en lecture seule (V3.27). Usage : python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path=\"NowUndo/Scripts/V3.21/NowUndo_Scenario.lua\"; l.execute(open(\"tools/trush_rom.lua\").read())"
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
M(5, "L1 CLOUD", "l1 cloud", true); M(6, "", "all stop", false)
L[#L + 1] = "L\t1\t1"; L[#L + 1] = "L\t65\t2"
local L = { "NOWUNDO_MACROS 1", "P\t1\tRC-505", "P\t2\tLive", "P\t3\tFin" }
local function M(id, name, text, all) L[#L + 1] = table.concat({ "M", id, 0, name, text, 0, all and 1 or 0, 0, "" }, "\t") end
M(1, "A", "l1 rec"); M(2, "B", "rec, a"); M(3, "C", "all stop"); M(4, "D", "l3 to g2"); M(5, "E", "g2 cloud")
M(6, "F", "go lp 2"); M(7, "G", "g(2)"); M(8, "H", "rec, l6 play"); M(9, "I", "in1 fx 2"); M(10, "J", "rev", true)
M(11, "K", "to g1"); M(12, "L", "l(1/3) rev *1/4"); M(13, "M", "stop *")
L[#L + 1] = "L\t1\t1"; L[#L + 1] = "L\t70\t2"; L[#L + 1] = "L\t72\t3"; L[#L + 1] = "L\t130\t8"
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
local H, macros = upv(LOOP, "H"), upv(LOOP, "macros")
local function show(t)
  local V, o = H._view(), {}
  for _, i in ipairs(V) do local m = macros[i]; if not m.rom then o[#o + 1] = m.name end end
  print(string.format("%-22s %s", t, table.concat(o, " ")))
end
local cls = {}
for _, m in ipairs(macros) do if not m.rom then cls[#cls + 1] = m.name .. "=" .. H._tclass(m) end end
print("classes : " .. table.concat(cls, " "))
show("aucun filtre")
H._flt = { pg = 2 }; show("page 4b")
H._flt = { pg = 0 }; show("pas poses")
H._flt = { tg = "tgt" }; show("cibles")
H._flt = { tg = "all" }; show("all")
H._flt = { tg = "none" }; show("non cibles")
H._flt = { pg = 2, tg = "tgt" }; show("4b + cibles")
print("texte du filtre : " .. H._flt_txt())
-- menu : 1 Tout | 2 toutes pages | 3 pas poses | 4.. pages | puis Toutes / Cibles / All / Non cibles
local np = #H._pages
for _, k in ipairs({ 3, 4 + 1, 3 + np + 3, 3 + np + 1, 1 }) do
  gfx.showmenu = function(s) LASTMENU = s; return k end
  H._flt_menu(0, 0); print("menu choix " .. k .. " -> filtre : '" .. H._flt_txt() .. "'")
end
print("menu : " .. LASTMENU:gsub("|", " | "))
-- une image complete avec filtre (pas d'erreur de dessin)
H._flt = { pg = 2 }; LOOP(); LOOP()
H._flt = { tg = "none" }; LOOP()
print("dessin OK, H._lp = " .. tostring(H._lp))
EXT["NowUndo_VLcmd/q"] = ""
H._show_pg(130); print("badge c? -> H._pg = " .. H._pg .. " | file LP : " .. EXT["NowUndo_VLcmd/q"]:gsub("\t.*", "") .. " | " .. tostring(upv(LOOP, "msg")))
