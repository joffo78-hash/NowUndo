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

run(0.3)
-- routing : IN1 -> L1, IN1 -> L2, IN2 -> L2
S.routing.in_l[1][1] = true; S.routing.in_l[1][2] = true; S.routing.in_l[2][2] = true
-- 1) send propre d'une entree
cmd("aux_in_1_2_500"); run(0.3)
check("in1 aux2 0.5 : IN1 -> aux2 ouvert a 0.5", st(IN(1), 2), "OUV0.50")
check("fondu : post-fader, MIDI coupe", tostring(snd(IN(1), AUX(2)).I_SENDMODE) .. "/" .. tostring(snd(IN(1), AUX(2)).I_MIDIFLAGS), "0/31")
-- 2) fondu a l'ouverture : niveau intermediaire juste apres l'ordre
cmd("aux_in_1_3_1000"); CLOCK = CLOCK + 0.03; VL.aux_tick(CLOCK)
local mid = snd(IN(1), AUX(3)).D_VOL
check("fondu a l'ouverture (niveau entre 0 et 1 apres 30 ms)", tostring(mid > 0.05 and mid < 0.95), "true")
run(0.3)
check("... puis 1.00", st(IN(1), 3), "OUV1.00")
cmd("aux_in_1_3_off"); run(0.3)
check("in1 aux3 off : ferme, niveau garde", st(IN(1), 3), "fer1.00")
-- 3) copie au REC : L1 enregistre (IN1 alimente L1)
lstate(1, 7, 0); run(0.2); lstate(1, 1, 0); run(0.2)
check("REC L1 : L1 -> aux2 copie de IN1 (0.5)", st(LP(1), 2), "OUV0.50")
check("REC L1 : L1 -> aux3 ferme (IN1 aux3 ferme)", st(LP(1), 3), "fer1.00")
lstate(1, 2, 96000); run(0.2)
-- 4) 27 nov. : la boucle est posee -> les sends de L1 ne bougent plus ; l'entree garde les siens (plus d'imposition)
cmd("aux_in_1_2_200"); run(0.3)
check("boucle posee : IN1 aux2 0.2 -> IN1 0.2, L1 reste 0.5", st(IN(1), 2) .. st(LP(1), 2), "OUV0.20OUV0.50")
cmd("aux_in_1_2_off"); run(0.3)
check("boucle posee : IN1 ferme -> L1 garde son send", st(IN(1), 2) .. st(LP(1), 2), "fer0.20OUV0.50")
cmd("aux_l_1_2_800"); run(0.3)
check("l1 aux2 0.8 (L1 selectionne) : IN1 suit", st(IN(1), 2) .. st(LP(1), 2), "OUV0.80OUV0.80")
-- 5) in mute : coupe les sends de l'entree, remis ensuite
cmd("aux_in_1_2_200"); run(0.3)
IN(1).info.B_MAINSEND = 0; run(0.3)
check("in mute IN1 : aux2 ferme", st(IN(1), 2), "fer0.20")
IN(1).info.B_MAINSEND = 1; run(0.3)
check("fin du in mute : aux2 rouvert", st(IN(1), 2), "OUV0.20")
-- 6) looper vide : suit ses sources a la lettre ; des le 1er REC lance : plus rien ; Clear : suit de nouveau
lstate(2, 0, 0); run(0.3)                                        -- L2 vide, alimente par IN1 (0.2) et IN2 (rien)
check("L2 vide : suit IN1 (0.2)", st(LP(2), 2), "OUV0.20")
cmd("aux_in_2_2_900"); run(0.3)
check("L2 vide : IN2 0.9 -> plus grand niveau (0.9)", st(LP(2), 2), "OUV0.90")
cmd("aux_in_2_2_off"); cmd("aux_in_1_2_off"); run(0.3)
check("L2 vide : toutes les sources fermees -> ferme", st(LP(2), 2):sub(1,3), "fer")
lstate(2, 1, 0); run(0.2); cmd("aux_in_1_2_700"); run(0.3)
check("1er REC lance : IN1 ouvre -> L2 ne bouge pas", st(LP(2), 2):sub(1,3), "fer")
lstate(2, 2, 96000); run(0.2); cmd("aux_l_2_2_500"); run(0.2); cmd("aux_in_1_2_off"); run(0.3)
check("boucle : reglage a la main garde (0.5), IN1 ferme -> rien", st(LP(2), 2), "OUV0.50")
cmd("aux_l_2_2_off"); run(0.3)
check("boucle : on peut fermer a la main", st(LP(2), 2), "fer0.50")
cmd("aux_in_1_2_700"); lstate(2, 0, 0); run(0.3)
check("Clear : L2 suit de nouveau IN1 (0.7)", st(LP(2), 2), "OUV0.70")
-- 7) un looper route vers un looper vide compte comme source
lstate(4, 0, 0); S.routing.l_l[1][4] = true; run(0.3)
check("L1 -> L4 (vide) : L4 prend le send de L1 (0.8)", st(LP(4), 2), "OUV0.80")
-- 11) aux -> looper, et garde-fou du feedback
cmd("auxrx_3_4_on"); run(0.3)
check("l3 from aux4 : aux4 -> L3 ouvert", (function() local s = snd(AUX(4), LP(3)) return s and (s.B_MUTE == 0 and "OUV" or "fer") or "-" end)(), "OUV")
cmd("aux_l_3_4_on"); run(0.3)
check("l3 aux4 refuse (aux4 envoie deja vers L3)", st(LP(3), 4), "-")
cmd("auxrx_1_2_on"); run(0.3)
check("l1 from aux2 refuse (L1 envoie vers aux2)", (function() local s = snd(AUX(2), LP(1)) return s and (s.B_MUTE == 0 and "OUV" or "fer") or "-" end)(), "-")
-- 12) send d'un looper : tog / off / on garde le niveau
cmd("aux_l_5_1_tog"); run(0.3)
check("l5 aux1 (tog, pas de send) : ouvert a 1", st(LP(5), 1), "OUV1.00")
cmd("aux_l_5_1_250"); run(0.2); cmd("aux_l_5_1_off"); run(0.3); cmd("aux_l_5_1_on"); run(0.3)
check("l5 aux1 0.25 puis off puis on : rouvert a 0.25", st(LP(5), 1), "OUV0.25")
-- 13) entree selectionnee (in0) : derniere entree choisie comme source FX
VL.S.fx_source = 3; VL.publish_fx_source(); cmd("aux_in_0_4_700"); run(0.3)
check("in aux4 0.7 (entree selectionnee = IN3)", st(IN(3), 4), "OUV0.70")
VL.S.fx_source = 8 + 2; VL.publish_fx_source()                 -- on selectionne un looper : l'entree selectionnee reste IN3
check("selection d'un looper : entree selectionnee gardee (gmem 6062)", tostring(GM[6062]), "3")
-- 14) publication pour 8Waves
check("gmem 6098/6099 = 1re piste aux / nombre", GM[6098] .. "/" .. GM[6099], "21/4")
check("gmem : L5 -> aux1 ouvert 0.25", string.format("%.2f", GM[6100 + 4 * 8 + 0]), "0.25")
cmd("aux_l_5_1_off"); run(0.3)
check("gmem : L5 -> aux1 ferme (niveau garde, negatif)", string.format("%.2f", GM[6100 + 4 * 8 + 0]), "-0.25")
check("gmem : aux4 -> L3 ouvert", tostring(GM[6228 + 2 * 8 + 3]), "1")
check("gmem : IN3 -> aux4 reel 0.7", string.format("%.2f", GM[6164 + 2 * 8 + 3]), "0.70")
check("aux5 n'existe plus (piste 25 non touchee)", tostring(#TR[25].sends), "0")
cmd("aux_l_1_5_1000"); run(0.2)
check("... meme par un rush aux5", tostring(snd(LP(1), TR[25]) == nil), "true")
lstate(5, 2, 96000); run(0.2); cmd("aux_l_5_1_on"); run(0.3); lstate(5, 0, 0); run(0.3)
check("Clear de L5 (aucune source) : sends enleves", st(LP(5), 1):sub(1,3), "fer")
-- 27 nov. : le looper selectionne (avec boucle) donne ses sends a ses entrees
lstate(6, 2, 96000); run(0.2); cmd("aux_l_6_3_600"); run(0.2)
S.routing.in_l[4][6] = true; run(0.3)
check("IN4 -> L6 non selectionne : IN4 inchange", st(IN(4), 3), "-")
VL.select_looper(6); run(0.3)
check("L6 selectionne : IN4 prend aux3 0.6", st(IN(4), 3), "OUV0.60")
cmd("aux_in_4_3_off"); run(0.3)
check("IN4 reglable ensuite (ferme), L6 garde", st(IN(4), 3) .. st(LP(6), 3), "fer0.60OUV0.60")
cmd("aux_l_6_3_300"); run(0.3)
check("L6 change son send (0.3) : IN4 suit", st(IN(4), 3), "OUV0.30")
cmd("aux_l_6_3_off"); run(0.3)
check("L6 ferme son send : IN4 ferme aussi", st(IN(4), 3):sub(1,3), "fer")
cmd("aux_in_4_1_700"); run(0.3); VL.select_looper(2); run(0.2); VL.select_looper(6); run(0.3)
check("reselection de L6 (pas d'aux1) : aux1 de IN4 enleve", st(IN(4), 1):sub(1,3), "fer")
cmd("aux_in_4_1_on"); run(0.3)
check("... et remettable a la main", st(IN(4), 1), "OUV0.70")
-- 27 nov. 18h : cas de l'utilisateur. L8 vide alimente par IN1 et par L1 (boucle, aux1 ouvert) ; IN1 ferme son aux1
cmd("aux_l_1_1_on"); run(0.2); S.routing.in_l[1][8] = true; S.routing.l_l[1][8] = true; cmd("aux_in_1_1_off"); run(0.3)
check("L8 vide (IN1 ferme, L1 aux1 ouvert) : suit L1", st(LP(8), 1):sub(1,3), "OUV")
cmd("aux_l_8_1_on"); run(0.5)
check("l'utilisateur ouvre L8 aux1 a la main : garde", st(LP(8), 1):sub(1,3), "OUV")
cmd("aux_l_8_1_off"); run(0.5)
check("... et le referme : garde", st(LP(8), 1):sub(1,3), "fer")
cmd("aux_in_1_1_on"); run(0.3)
check("IN1 rouvre son aux1 : L8 (vide) suit", st(LP(8), 1):sub(1,3), "OUV")
-- 27 nov. 18h30 : cas de l'utilisateur. IN1 -> L1 (joue) et L2 (vide) ; IN1 coupe son aux2 : L1 GARDE, L2 suit
for i = 1, 8 do S.routing.in_l[1][i] = nil end; S.routing.in_l[1][1] = true; S.routing.in_l[1][2] = true
lstate(2, 0, 0); run(0.3); cmd("aux_in_1_2_on"); run(0.3)
lstate(1, 2, 96000); GM[100] = 0; cmd("aux_l_1_2_on"); run(0.3)   -- L1 joue, battement absent (cas reel suppose)
check("L2 vide suit IN1 (aux2 ouvert)", st(LP(2), 2):sub(1,3), "OUV")
cmd("aux_in_1_2_off"); run(0.5)
check("IN1 coupe aux2 : L1 qui joue garde", st(LP(1), 2):sub(1,3), "OUV")
check("... L2 vide suit (ferme)", st(LP(2), 2):sub(1,3), "fer")
lstate(1, 0, 96000); cmd("aux_in_1_2_on"); run(0.3); cmd("aux_in_1_2_off"); run(0.5)
check("L1 arrete avec boucle en memoire : garde", st(LP(1), 2):sub(1,3), "OUV")
print(fails == 0 and "TOUT OK" or (fails .. " ECHEC(S)"))
