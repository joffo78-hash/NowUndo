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
local function dump(t)
  local ms, out, nrom = macros(), {}, 0
  for i, m in ipairs(ms) do if m.rom then nrom = nrom + 1 end; if i <= 6 or i == #ms then out[#out + 1] = i .. ":" .. (m.name ~= "" and m.name or m.text) .. (m.rom and "[ROM]" or "") end end
  print(t, #ms .. " rushes, " .. nrom .. " ROM | " .. table.concat(out, "  "))
end
dump("apres chargement :")
local H = upv(LOOP, "H")
local msel_set = function(id) local ms = macros(); for _, m in ipairs(ms) do if m.id == id then return m end end end
-- tentative d'effacer un rush d'usine (L1 REC, id 1) puis un perso (id 2)
local mac_delete = upv(LOOP, "mac_delete")
for _, id in ipairs({ 1, 2 }) do
  local k = 1
  while true do local n = debug.getupvalue(mac_delete, k); if not n then break end; if n == "msel" then debug.setupvalue(mac_delete, k, { [id] = true }) end; k = k + 1 end
  mac_delete()
  print("effacer id " .. id .. " -> " .. (msel_set(id) and "toujours la" or "efface") .. " | message : " .. tostring(upv(LOOP, "msg")))
end
dump("apres effacements :")
local set = EXT["NowUndo_Macros/set"]
print("ligne enregistree du rush d'usine 1 : " .. (set:match("M\t1\t[^\n]*") or "?"):gsub("\t", " | "))
