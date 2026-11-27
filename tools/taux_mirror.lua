-- Toggles des sends aux = miroir de l etat reel + mode par case du Launchpad (27 nov.). Usage : python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path=\"NowUndo/Scripts/V3.21/NowUndo_Scenario.lua\"; l.execute(open(\"tools/taux_mirror.lua\").read())"
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
  "M\t1\t0\tA1\taux1 0.5\t1\t0\t0\t",          -- rush toggle sur la selection
  "M\t2\t0\tA2\tl2 aux2\t0\t0\t0\t",           -- rush normal, pose en TOGGLE sur la case 5
  "M\t3\t0\tRX\tl3 from aux4\t1\t0\t0\t", "M\t4\t0\tMSG\tl4 slicer\t0\t0\t0\t",
  "L\t1\t1", "L\t5\t2\tt", "L\t6\t3", "L\t7\t4\tt", "L\t8\t4\tt" }
EXT["NowUndo_Macros/set"] = table.concat(lines, "\n")
EXT["NowUndo_Macros/fx_page"] = "1"
EXT["nowundo_vl/sel_looper"] = "1"
for i = 0, 7 do GM[100 + i] = 1; local b = 1000 + i * 600; GM[b + 42] = 1; GM[b + 2] = 2; GM[b + 46] = 96000; GM[b + 45] = 96000 end
dofile(arg_path)
local function run(n) for k = 1, n do CLOCK = CLOCK + 0.03; if LOOP then LOOP() end end end
run(5)
local fails = 0
local function check(label, got, want)
  local ok = got == want; if not ok then fails = fails + 1 end
  print(string.format("%-4s %-60s %s", ok and "OK" or "FAUX", label, ok and got or (got .. "  (attendu " .. want .. ")")))
end
local function fire(id, cmode, cell)
  EXT["NowUndo_VLcmd/q"] = ""
  EXT["NowUndo_Scn/mcr"] = string.format("%d\t\t%.3f\t\t%s\t%d\n", id, CLOCK, cmode or "", cell or 0)
  run(8)
  return ((EXT["NowUndo_VLcmd/q"] or ""):gsub("\t[%d%.]+\n", " "))
end
local function on() run(6); return EXT["NowUndo_Macros/on"] or "" end
local function S(L, a) return 6100 + (L - 1) * 8 + (a - 1) end
check("L1 aux1 ferme : pad A1 eteint", on():match("%f[%d]1%f[%D]") and "allume" or "eteint", "eteint")
check("appui A1 (L1 selectionne) : ouvre L1 -> aux1", fire(1), "aux_l_1_1_500 ")
GM[S(1, 1)] = 0.5                                  -- le Launchpad a ouvert le send
check("pad A1 allume (send reel ouvert)", on():match("%f[%d]1%f[%D]") and "allume" or "eteint", "allume")
EXT["nowundo_vl/sel_looper"] = "2"                 -- on passe sur L2 (qui ne va pas dans aux1)
check("selection L2 : pad A1 eteint", on():match("%f[%d]1%f[%D]") and "allume" or "eteint", "eteint")
check("appui A1 sur L2 : ouvre L2 -> aux1 (ne ferme pas L1)", fire(1), "aux_l_2_1_500 ")
GM[S(2, 1)] = 0.5
check("re-appui A1 sur L2 : ferme L2 -> aux1", fire(1), "aux_l_2_1_off ")
GM[S(2, 1)] = -0.5
EXT["nowundo_vl/sel_looper"] = "1"
check("retour sur L1 : pad A1 allume (L1 toujours ouvert)", on():match("%f[%d]1%f[%D]") and "allume" or "eteint", "allume")
GM[S(1, 1)] = -0.5                                 -- ferme a la main ailleurs (8Waves)
check("ferme dans 8Waves : pad A1 eteint", on():match("%f[%d]1%f[%D]") and "allume" or "eteint", "eteint")
check("rush A2 (normal) pose en toggle : dans la liste des toggles", on():match("%f[%d]2%f[%D]") and "oui" or "non", "non")
check("appui case 5 (toggle) : ouvre L2 -> aux2", fire(2, "t", 5), "aux_l_2_2_on ")
GM[S(2, 2)] = 1
check("pad de la case 5 allume", on():match("%f[%d]2%f[%D]") and "oui" or "non", "oui")
check("re-appui case 5 : ferme", fire(2, "t", 5), "aux_l_2_2_off ")
check("meme rush depuis une case normale : tel qu'ecrit", fire(2, "n", 9), "aux_l_2_2_on ")
check("meme rush depuis une case gate, appui", (function() EXT["NowUndo_VLcmd/q"] = ""; EXT["NowUndo_Scn/mcr"] = string.format("2\t1\t%.3f\ton\tg\t10\n", CLOCK); run(8); return ((EXT["NowUndo_VLcmd/q"] or ""):gsub("\t[%d%.]+\n", " ")) end)(), "aux_l_2_2_on ")
check("... relachement", (function() EXT["NowUndo_VLcmd/q"] = ""; EXT["NowUndo_Scn/mcr"] = string.format("2\t1\t%.3f\toff\tg\t10\n", CLOCK); run(8); return ((EXT["NowUndo_VLcmd/q"] or ""):gsub("\t[%d%.]+\n", " ")) end)(), "aux_l_2_2_off ")
check("from aux4 : pad eteint", on():match("%f[%d]3%f[%D]") and "allume" or "eteint", "eteint")
check("appui RX : ouvre aux4 -> L3", fire(3), "auxrx_3_4_on ")
GM[6228 + 2 * 8 + 3] = 1
check("pad RX allume", on():match("%f[%d]3%f[%D]") and "allume" or "eteint", "allume")
check("re-appui RX : ferme", fire(3), "auxrx_3_4_off ")
check("ancien format du Launchpad (sans mode) : toggle du rush", fire(1), "aux_l_1_1_500 ")
-- meme rush (non miroir) sur deux pads toggle : chacun son etat
fire(4, "t", 7); GM[1000 + 3 * 600 + 8] = 1
local o = on()
check("pad 7 allume, pad 8 eteint (meme rush)", (o:find("4@7", 1, true) and "7on" or "7off") .. "/" .. (o:find("4@8", 1, true) and "8on" or "8off"), "7on/8off")
print(fails == 0 and "TOUT OK" or (fails .. " ECHEC(S)"))
