-- Mode normal / toggle / gate PAR CASE du Launchpad (27 nov.).
-- Usage : cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='virtuallaunchpad_main.lua'; l.execute(open('../../../tools/tcellmode.lua').read())"
VL_TEST = true
EXT = {}; GM = {}; CLOCK = 100
local TR = {}
for n = 1, 25 do TR[n] = { n = n, sends = {}, info = { B_MAINSEND = 1, B_MUTE = 0 }, str = {} } end
local SKEYS = { B_MUTE = 0, D_VOL = 1, D_PAN = 0, I_SENDMODE = 0, I_SRCCHAN = 0, I_DSTCHAN = 0, I_MIDIFLAGS = 0 }
reaper = setmetatable({
  time_precise = function() return CLOCK end,
  GetExtState = function(a, k) return EXT[a .. "/" .. k] or "" end, SetExtState = function(a, k, v) EXT[a .. "/" .. k] = v end,
  HasExtState = function(a, k) return EXT[a .. "/" .. k] ~= nil end, DeleteExtState = function(a, k) EXT[a .. "/" .. k] = nil end,
  gmem_read = function(a) return GM[a] or 0 end, gmem_write = function(a, v) GM[a] = v end, gmem_attach = function() end,
  GetResourcePath = function() return "/nonexistent" end, GetOS = function() return "Win64" end,
  get_action_context = function() return false, "/nonexistent/x.lua" end,
  CountTracks = function() return 25 end, GetTrack = function(_, i) return TR[i + 1] end,
  GetTrackName = function(tr) return true, "T" .. tr.n end,
  GetTrackNumSends = function(tr, cat) return #tr.sends end,
  GetTrackSendInfo_Value = function(tr, cat, i, k)
    local s = tr.sends[i + 1]; if not s then return 0 end
    if k == "P_DESTTRACK" then return s.dst end
    return s[k] or 0
  end,
  SetTrackSendInfo_Value = function(tr, cat, i, k, v) local s = tr.sends[i + 1]; if s then s[k] = v end return true end,
  CreateTrackSend = function(src, dst)
    local s = { dst = dst }; for k, v in pairs(SKEYS) do s[k] = v end
    src.sends[#src.sends + 1] = s; return #src.sends - 1
  end,
  GetMediaTrackInfo_Value = function(tr, k) return tr.info[k] or 0 end,
  SetMediaTrackInfo_Value = function(tr, k, v) tr.info[k] = v return true end,
  GetSetMediaTrackInfo_String = function(tr, k, v, set) if set then tr.str[k] = v return true, v end return true, tr.str[k] or "" end,
  defer = function() end, atexit = function() end, UpdateArrange = function() end,
  ShowConsoleMsg = function() end, file_exists = function() return false end, EnumerateFiles = function() return nil end,
}, { __index = function() return function() return 0 end end })
gfx = setmetatable({ w = 800, h = 600 }, { __index = function() return function() return 0 end end })
for i = 0, 7 do local b = 1000 + i * 600; GM[100 + i] = 1; GM[130 + i] = 99; GM[b + 42] = 1; GM[b + 2] = 0; GM[b + 46] = 0 end
local VL = dofile(arg_path)

local fails = 0
local function check(label, got, want)
  local ok = got == want
  if not ok then fails = fails + 1 end
  print(string.format("%-4s %-58s %s", ok and "OK" or "FAUX", label, ok and tostring(got) or (tostring(got) .. "  (attendu " .. tostring(want) .. ")")))
end
-- rush 5 = normal, rush 6 = toggle ; poses : 5 en c1 (mode du rush), 5 en c2 en gate, 5 en c3 en toggle, 6 en c4 en normal
EXT["NowUndo_Macros/set"] = table.concat({ "NOWUNDO_MACROS 1",
  "M\t5\t0\tAUX\tl1 aux1 0.5\t0\t0\t0\t", "M\t6\t0\tREV\trev\t1\t0\t0\t",
  "L\t1\t5", "L\t2\t5\tg", "L\t3\t5\tt", "L\t4\t6\tn", "P\t1\tRushes" }, "\n")
EXT["NowUndo_Macros/rev"] = "1"
CLOCK = CLOCK + 1; VL.macros_poll(CLOCK)
check("mode c1 (celui du rush 5 = normal)", VL.cell_mode(1), "n")
check("mode c2 (gate sur la case)", VL.cell_mode(2), "g")
check("mode c3 (toggle sur la case)", VL.cell_mode(3), "t")
check("mode c4 (rush toggle mis en normal)", VL.cell_mode(4), "n")
local function mcr() local q = EXT["NowUndo_Scn/mcr"] or ""; EXT["NowUndo_Scn/mcr"] = ""; return (q:gsub("\t%d+%.%d%d%d\t", "\tT\t"):gsub("\n", " | ")) end
VL.macro_press(1); check("appui c1", mcr(), "5\t1\tT\t\tn\t1 | ")
VL.macro_press(2); check("appui c2 (gate : on)", mcr(), "5\t1\tT\ton\tg\t2 | ")
VL.macro_release(2); check("relachement c2 (gate : off)", mcr(), "5\t1\tT\toff\tg\t2 | ")
VL.macro_release(1); check("relachement c1 (normal : rien)", mcr(), "")
VL.macro_press(3); check("appui c3 (toggle)", mcr(), "5\t1\tT\t\tt\t3 | ")
-- changer le mode d'une case : ecrit dans la ligne L, garde par un deplacement
VL.set_cell_mode(1, "g"); CLOCK = CLOCK + 1; VL.macros_poll(CLOCK)
check("c1 passee en gate", VL.cell_mode(1), "g")
check("ligne L enregistree", tostring((EXT["NowUndo_Macros/set"]):match("L\t1\t5\tg") ~= nil), "true")
VL.macro_move(1, 9)
check("deplacee en c9 : le mode suit", VL.cell_mode(9), "g")
check("c1 vide", tostring(VL.cell_mode(1)), "nil")
VL.set_cell_mode(9, nil)
check("mode du rush retabli en c9", VL.cell_mode(9), "n")
check("ligne L sans mode", tostring((EXT["NowUndo_Macros/set"]):match("L\t9\t5\n") ~= nil or (EXT["NowUndo_Macros/set"]):match("L\t9\t5$") ~= nil), "true")
-- barres (page 4, sous-page a)
VL.S.page = 4; VL.S.p4_layer = "rp1"
check("barre c2 (rangee 1, col 2)", tostring(VL.cell_band(4, 1, 2)), "g")
check("barre c3", tostring(VL.cell_band(4, 1, 3)), "t")
check("pas de barre c4 (normal)", tostring(VL.cell_band(4, 1, 4)), "nil")
check("pas de barre hors page 4", tostring(VL.cell_band(1, 1, 2)), "nil")
VL.web_publish(CLOCK + 10)
check("page web : band dans web_meta", tostring((EXT["nowundo_vl/web_meta"] or ""):match("band=([^;]*)")), "1,2g.1,3t")
print(fails == 0 and "TOUT OK" or (fails .. " ECHEC(S)"))
