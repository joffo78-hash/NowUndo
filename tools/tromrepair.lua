-- Pads L7 / L8 FX4 de la page Effets reposes (27 nov.). Usage : python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path=\"NowUndo/Scripts/V3.21/NowUndo_Scenario.lua\"; l.execute(open(\"tools/tromrepair.lua\").read())"
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
local L = { "NOWUNDO_MACROS 1", "P\t1\tRC-505", "P\t2\tPerso", "P\t3\tEffets" }
local id = 0
-- page Effets : 64 rushes d'usine, poses sauf L7 FX4 / L8 FX4 (recrees par l'ancien bug, hors Launchpad)
for r = 1, 8 do for col = 1, 8 do
  id = id + 1
  local inp, sl = r <= 4, (r - 1) % 4 + 1
  local name, text = (inp and "IN" or "L") .. col .. " FX" .. sl, (inp and "in" or "l") .. col .. " fx " .. sl
  L[#L + 1] = table.concat({ "M", id, 0, name, text, 1, 0, 0, "", "R" }, "\t")
  if not (r == 8 and col >= 7) then L[#L + 1] = "L\t" .. (128 + (r - 1) * 8 + col) .. "\t" .. id .. "\tt" end
end end
EXT["NowUndo_Macros/set"] = table.concat(L, "\n"); EXT["NowUndo_Macros/fx_page"] = "1"
dofile(arg_path)
LOOP()
local set = EXT["NowUndo_Macros/set"]
print("c191 (L7 FX4) :", (set:match("L\t191\t[^\n]*") or "VIDE"):gsub("\t", " "))
print("c192 (L8 FX4) :", (set:match("L\t192\t[^\n]*") or "VIDE"):gsub("\t", " "))
print("rom_repair1 =", EXT["NowUndo_Macros/rom_repair1"])
