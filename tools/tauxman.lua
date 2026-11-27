-- Sends vers les pistes AUX (26 nov.) : faux REAPER avec 24 pistes et de vrais envois.
-- Usage : cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='virtuallaunchpad_main.lua'; l.execute(open('../../../tools/taux.lua').read())"
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
local S = VL.S
local function IN(k) return TR[1 + k] end          -- entrees = pistes 2..9
local function LP(i) return TR[10 + i] end         -- loopers = pistes 11..18
local function AUX(a) return TR[20 + a] end        -- aux = pistes 21..24
local function snd(src, dst)
  for _, s in ipairs(src.sends) do if s.dst == dst then return s end end
end
local function st(src, a)
  local s = snd(src, AUX(a)); if not s then return "-" end
  return (s.B_MUTE == 0 and "OUV" or "fer") .. string.format("%.2f", s.D_VOL)
end
local function run(sec)                             -- fait tourner le Launchpad (tick ~30 Hz)
  local n = math.floor(sec / 0.033 + 0.5)
  for _ = 1, n do CLOCK = CLOCK + 0.033; VL.poll_looper_feedback(); VL.aux_tick(CLOCK) end
end
local function cmd(s) EXT["NowUndo_VLcmd/q"] = (EXT["NowUndo_VLcmd/q"] or "") .. s .. "\t" .. string.format("%.3f", CLOCK) .. "\n"; VL.ext_cmd_poll() end
local function lstate(i, state, len) local b = 1000 + (i - 1) * 600; GM[b + 2] = state; GM[b + 46] = len end
local fails = 0
local function check(label, got, want)
  local ok = got == want
  if not ok then fails = fails + 1 end
  print(string.format("%-4s %-62s %s", ok and "OK" or "FAUX", label, ok and got or (got .. "  (attendu " .. want .. ")")))
end
for i = 1, 8 do GM[100 + i - 1] = i end
run(0.3)
S.routing.in_l[1][1] = true; S.routing.in_l[1][2] = true
lstate(1, 2, 96000); lstate(2, 0, 0); run(0.3)
cmd("aux_in_1_1_on"); run(0.4)
check("IN1 aux1 on : L1 et L2 ne suivent pas", st(IN(1), 1) .. st(LP(1), 1) .. st(LP(2), 1), "OUV1.00--")
cmd("aux_l_1_1_on"); run(0.4); VL.select_looper(1); run(0.3); cmd("aux_in_1_1_off"); run(0.4)
check("IN1 off : L1 garde, rien de donne / repris", st(IN(1), 1) .. st(LP(1), 1), "fer1.00OUV1.00")
VL.select_looper(2); run(0.2); VL.select_looper(1); run(0.3)
check("reselection de L1 : IN1 reste ferme", st(IN(1), 1), "fer1.00")
cmd("aux_in_1_1_on"); run(0.3); IN(1).info.B_MAINSEND = 0; run(0.4)
check("in mute : les sends de IN1 restent ouverts", st(IN(1), 1), "OUV1.00")
IN(1).info.B_MAINSEND = 1
-- effet d'insert active par une commande (rush page 4) -> Twister page 6 ; desactive : page inchangee
for k = 1, 4 do S.fx_present.looper[3][k] = true; S.fx_present.input[2][k] = true end
VL.set_fighter_page(1); cmd("fx_3_2_on")
check("rush l3 fx 2 on -> Twister page 6", tostring(S.fighter_page or EXT["nowundo_vl/fighter_page"]), "6")
VL.set_fighter_page(1); cmd("fx_3_2_off")
check("rush off -> page inchangee", tostring(S.fighter_page or EXT["nowundo_vl/fighter_page"]), "1")
cmd("fxin_2_3_on")
check("rush in2 fx 3 on -> page 6", tostring(S.fighter_page or EXT["nowundo_vl/fighter_page"]), "6")
VL.set_fighter_page(1); cmd("fxg_3_4_tog")
check("web fxg -> page 6", tostring(S.fighter_page or EXT["nowundo_vl/fighter_page"]), "6")
VL.set_fighter_page(1); EXT["nowundo_vl/tw_lock"] = "1"; cmd("fx_3_1_on")
check("pages verrouillees : pas de navigation", tostring(S.fighter_page or EXT["nowundo_vl/fighter_page"]), "1")
EXT["nowundo_vl/tw_lock"] = nil
print(fails == 0 and "TOUT OK" or (fails .. " ECHEC(S)"))
