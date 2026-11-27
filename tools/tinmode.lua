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
local function press(r, c) VL.on_pad_pressed(r, c, CLOCK) end
local function rel(r, c) VL.on_pad_released(r, c, CLOCK) end
local function tap(r, c) press(r, c); CLOCK = CLOCK + 0.05; rel(r, c) end
local function lbl(r, c) return tostring(VL.pad_label(1, r, c)) end
local function fr(r, c) local f = VL.build_frame()[r .. "," .. c]; return string.format("%06X/%s", f[1], f[2]) end
run(0.3)
check("B1 = IN / LOOPER", lbl(7, 1), "IN / LOOPER : LOOPERS")
check("C4 = LINK", lbl(6, 4), "LINK PITCH / SPEED")
check("C5 = send 1 de L1", lbl(6, 5), "SEND 1 L1 TOGGLE")
tap(7, 1)
check("B1 : mode ENTREES", tostring(S.top_in) .. " " .. tostring(GM[6063]), "true 1")
check("rangee du haut = IN 1", lbl(0, 1), "IN 1")
check("IN1 selectionnee en vert", fr(0, 1), "99FF66/on")
tap(0, 3)
check("tap IN3 = entree 3, source FX 3", S.sel_input .. " " .. S.fx_source .. " " .. GM[6062], "3 3 3")
check("C6 suit l'entree", lbl(6, 6), "SEND 2 IN3 TOGGLE")
-- chord IN3 + IN5 = groupe d'entrees
press(0, 3); CLOCK = CLOCK + 0.05; press(0, 5); CLOCK = CLOCK + 0.05; rel(0, 5); rel(0, 3)
check("chord IN3+IN5 : groupe 1", S.in_group_of[3] .. S.in_group_of[5], "11")
check("groupe memorise", EXT["nowundo_vl/in_groups"], "0,0,1,0,1,0,0,0")
check("pad GROUP 1 allume", fr(1, 9):match("/(%a+)$"), "on")
-- send aux 2 en toggle : IN3 + IN5
tap(6, 6); run(0.3)
check("C6 : IN3 -> aux2 ouvert", st(IN(3), 2), "OUV1.00")
check("C6 : IN5 -> aux2 ouvert (groupe)", st(IN(5), 2), "OUV1.00")
check("C6 allume", fr(6, 6):match("/(%a+)$"), "on")
tap(6, 6); run(0.3)
check("C6 re-appui : IN3 ferme", st(IN(3), 2), "fer1.00")
-- PAGE 1 maintenue + C7 = gate
press(5, 9); tap(6, 7); rel(5, 9)
check("PAGE 1 + C7 : mode gate", lbl(6, 7), "SEND 3 IN3 GATE")
press(6, 7); run(0.3)
check("gate tenu : IN5 -> aux3 ouvert", st(IN(5), 3), "OUV1.00")
rel(6, 7); run(0.3)
check("gate relache : ferme", st(IN(5), 3), "fer1.00")
-- FX D5 sur le groupe d'entrees
for k = 1, 8 do for sl = 1, 4 do S.fx_present.input[k][sl] = true end end
tap(5, 5)
check("D5 : FX1 de IN3 et IN5", tostring(S.fx.input[3][1]) .. tostring(S.fx.input[5][1]) .. tostring(S.fx.input[1][1]), "truetruefalse")
-- appui long = in mute (bleu)
press(0, 1); for _ = 1, 40 do CLOCK = CLOCK + 0.033; VL.tick(CLOCK) end; rel(0, 1)
check("appui long IN1 : sortie du parent coupee", tostring(IN(1).info.B_MAINSEND), "0")
check("IN1 en bleu", fr(0, 1):sub(1, 6), "2D5BFF")
-- retour loopers
tap(7, 1)
check("B1 : retour LOOPERS, source = L1", tostring(S.top_in) .. " " .. S.fx_source, "false 9")
tap(6, 5); run(0.3)
check("C5 : L1 -> aux1 ouvert", st(LP(1), 1), "OUV1.00")
cmd("topin_on")
check("commande topin_on", tostring(S.top_in), "true")
check("IN1 in mute : aux ferme (in mute coupe tout)", st(IN(1), 4), "-")
tap(0, 3); cmd("auxsel_4_on"); run(0.3)
check("auxsel_4_on : IN3 + IN5 (groupe) -> aux4", st(IN(3), 4) .. st(IN(5), 4), "OUV1.00OUV1.00")
print(fails == 0 and "TOUT OK" or (fails .. " ECHEC(S)"))
-- 27 nov. : looper vide alimente par IN3 : il suit le send de IN3 ; apres la sortie du 1er REC il ne bouge plus
S.routing.in_l[3][2] = true
local b2 = 1000 + 1 * 600; GM[b2 + 2] = 0; GM[b2 + 46] = 0
cmd("topin_on"); tap(0, 3); cmd("auxsel_1_on"); run(0.3)
check("L2 vide : suit IN3 -> aux1", st(IN(3), 1) .. st(LP(2), 1), "OUV1.00OUV1.00")
GM[b2 + 2] = 1; run(0.3); GM[b2 + 2] = 2; GM[b2 + 46] = 96000; run(0.3); cmd("auxsel_1_off"); run(0.3)
check("boucle posee : IN3 ferme, L2 garde", st(IN(3), 1) .. st(LP(2), 1), "fer1.00OUV1.00")
cmd("auxsel_3_on"); run(0.3)
check("boucle posee : IN3 ouvre aux3 -> L2 reste sans send", st(IN(3), 3) .. st(LP(2), 3), "OUV1.00-")
print(fails == 0 and "TOUT OK (2)" or (fails .. " ECHEC(S)"))
