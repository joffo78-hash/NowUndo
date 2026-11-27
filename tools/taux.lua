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
-- 4) le looper avec boucle impose ses sends a IN1 : on change le send propre de IN1, L1 l'impose toujours
cmd("aux_in_1_2_200"); run(0.3)
check("27 nov. : boucle qui tourne : IN1 aux2 0.2 ne baisse pas L1 (0.5 impose)", st(IN(1), 2) .. st(LP(1), 2), "OUV0.50OUV0.50")
cmd("aux_l_1_2_800"); run(0.3)
check("l1 aux2 0.8 : L1 change -> IN1 suit (0.8)", st(IN(1), 2), "OUV0.80")
-- 5) reglage manuel de l'entree pendant qu'elle est imposee : remis en place
snd(IN(1), AUX(2)).D_VOL = 0.1; run(0.3)
check("reglage manuel de IN1 impose : remis a 0.8", st(IN(1), 2), "OUV0.80")
-- 6) in mute : sends de l'entree coupes, remis a la sortie du mute
IN(1).info.B_MAINSEND = 0; run(0.3)
check("in mute IN1 : aux2 ferme", st(IN(1), 2), "fer0.80")
IN(1).info.B_MAINSEND = 1; run(0.3)
check("fin du in mute : aux2 rouvert (impose 0.8)", st(IN(1), 2), "OUV0.80")
-- 7) looper vide : IN1 retrouve son send propre (0.2)
lstate(1, 0, 0); run(0.3)
check("L1 vide : IN1 retrouve son send propre (0.2)", st(IN(1), 2), "OUV0.20")
-- 8) reglage manuel de l'entree libre = devient son reglage propre
snd(IN(1), AUX(2)).D_VOL = 0.33; run(0.3)
local _, own = IN(1).str["P_EXT:nowundo_aux_own"] ~= nil, IN(1).str["P_EXT:nowundo_aux_own"] or ""
check("reglage manuel de IN1 libre : memorise (0.33)", tostring(own:match("^%d:[%d%.]+ 1:0%.33") ~= nil), "true")
-- 9) l'overdub ne change rien
lstate(2, 1, 0); run(0.2); lstate(2, 2, 96000); run(0.2)       -- L2 : REC (IN1 aux2 0.33 ; IN2 rien) -> L2 aux2 0.33
check("REC L2 : plus grand niveau des entrees (IN1 0.33)", st(LP(2), 2), "OUV0.33")
cmd("aux_in_2_2_900"); run(0.2)
lstate(2, 3, 96000); run(0.2); lstate(2, 2, 96000); run(0.2)    -- overdub
check("overdub L2 : sends gardes (27 nov. : IN2 0.9 recopie sur L2)", st(LP(2), 2), "OUV0.90")
-- 10) priorite : IN1 alimente L1 (boucle, aux2 0.5) et L2 (boucle, aux2 0.33) ; L2 selectionne -> 0.33 ; L1 en overdub -> 0.5
lstate(1, 2, 96000); cmd("aux_l_1_2_500"); S.sel_looper = 2; run(0.3)
check("IN1 -> 2 loopers (27 nov. : niveau recopie)", st(IN(1), 2), "OUV0.90")
lstate(1, 3, 96000); run(0.3)
check("... mais le looper en overdub (L1) passe devant", st(IN(1), 2), "OUV0.50")
lstate(1, 2, 96000); S.sel_looper = 5; run(0.3)
check("... aucun selectionne (27 nov. : niveau recopie)", st(IN(1), 2), "OUV0.90")
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
print(fails == 0 and "TOUT OK" or (fails .. " ECHEC(S)"))
