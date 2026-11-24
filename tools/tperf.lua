-- Test de NowUndo_Performance.lua avec un faux REAPER (gmem, pistes, marqueurs, regions).
-- cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='NowUndo_Performance.lua'; l.execute(open('../../../tools/tperf.lua').read())"
GM = {}; EXT = {}; CLOCK = 1000; POS = 0; STATE = 1; DEFER = nil; PROJ = {}
TR = {}; for n = 1, 30 do TR[n] = { n = n, v = { I_RECARM = 0, I_RECMODE = 2 }, items = {} } end
REGS = {}; MK = { { t = 0, bpm = 120 } }; LOGARM = {}; REP = 1; CMDS = {}
reaper = {
  gmem_attach = function() end, gmem_read = function(a) return GM[a] or 0 end, gmem_write = function(a, v) GM[a] = v end,
  time_precise = function() return CLOCK end, GetPlayPosition = function() return POS end, GetPlayState = function() return STATE end,
  GetExtState = function(s, k) return EXT[s .. "/" .. k] or "" end, SetExtState = function(s, k, v) EXT[s .. "/" .. k] = v end,
  CountTracks = function() return #TR end, GetTrack = function(_, i) return TR[i + 1] end,
  GetMediaTrackInfo_Value = function(t, k) return t.v[k] end,
  SetMediaTrackInfo_Value = function(t, k, v) if k == "I_RECARM" and t.v[k] ~= v then LOGARM[#LOGARM + 1] = string.format("t=%.1f piste %d arm=%d", POS, t.n, v) end t.v[k] = v end,
  GetSetRepeat = function(v) local o = REP; if v >= 0 then REP = v end; return o end,
  Main_OnCommand = function(id) CMDS[#CMDS + 1] = id; if id == 1013 then STATE = 5 elseif id == 1016 then STATE = 0 end end,
  AddProjectMarker2 = function(_, rg, s, e, name) REGS[#REGS + 1] = { s = s, e = e, name = name }; return #REGS end,
  SetProjectMarker3 = function(_, idx, _, s, e, name) REGS[idx].s, REGS[idx].e = s, e end,
  TimeMap_GetDividedBpmAtTime = function() return MK[#MK].bpm end,
  CountTempoTimeSigMarkers = function() return #MK end,
  SetTempoTimeSigMarker = function(_, _, t, _, _, b) MK[#MK + 1] = { t = t, bpm = b }; return true end,
  UpdateTimeline = function() end, UpdateArrange = function() end, SetProjExtState = function(_, s, k, v) PROJ[k] = v; return 0 end,
  CountTrackMediaItems = function() return 0 end, GetTrackMediaItem = function() return nil end,
  defer = function(f) DEFER = f end, atexit = function() end }
gfx = setmetatable({ w = 420, h = 200, mouse_x = 0, mouse_y = 0, mouse_cap = 0 }, { __index = function() return function() return 0 end end })
gfx.getchar = function() return 0 end; gfx.measurestr = function() return 50, 14 end
dofile(arg_path)
local function setl(i, alive, state, len, mask)               -- looper i (0..7)
  local b = 1000 + i * 600; GM[100 + i] = alive and 1 or 0; GM[130 + i] = CLOCK; GM[b + 42] = 1; GM[b + 2] = state; GM[b + 46] = len; GM[b + 155] = 120
  GM[6000 + 10 + i + 1] = mask or 0
end
local function run(sec) for k = 1, math.floor(sec / 0.05) do CLOCK = CLOCK + 0.05; POS = POS + 0.05; local f = DEFER; DEFER = nil; if f then f() end end end
for i = 0, 7 do setl(i, true, 0, 0, 0) end
EXT["NowUndo_Perf/cmd"] = ""
run(0.2)
-- 1) demarrage par bascule externe
EXT["NowUndo_Perf/cmd"] = "toggle"; run(0.2); run(0.5)
print("1 demarrage : commandes", table.concat(CMDS, ","), "| repetition", REP, "| mode piste 2 =", TR[2].v.I_RECMODE, "| armee ?", TR[2].v.I_RECARM)
-- 2) entree 1 affectee au looper 1 (masque bit0) : piste 2 armee
GM[6000 + 10 + 1] = 1; run(0.2)
print("2 entree 1 affectee : piste 2 armee =", TR[2].v.I_RECARM, "| piste 3 =", TR[3].v.I_RECARM)
-- 3) 1er REC du looper 1 (tous vides) : morceau 1
GM[950] = CLOCK; setl(0, true, 1, 0, 1); run(0.3)
print("3 REC : regions", #REGS, REGS[1] and REGS[1].name, string.format("debut %.2f", REGS[1] and REGS[1].s or -1), "| piste 11 armee =", TR[11].v.I_RECARM, "(attendu 0 : en REC)")
-- 4) REC abouti : looper joue, master synchro verrouille -> marqueur de tempo, piste 11 armee
GM[0] = 1; GM[1] = 1; GM[2] = 96000; setl(0, true, 2, 96000, 1); GM[1000 + 155] = 118.5; run(0.3)
print("4 REC abouti : piste 11 armee =", TR[11].v.I_RECARM, "| marqueurs de tempo", #MK, string.format("(dernier %.1f BPM)", MK[#MK].bpm))
-- 5) 2e looper enregistre pendant le morceau : pas de nouveau morceau
GM[950] = CLOCK; setl(1, true, 1, 0, 0); run(0.3); setl(1, true, 2, 96000, 0); run(0.3)
print("5 2e looper : regions", #REGS, "| piste 12 armee =", TR[12].v.I_RECARM)
-- 6) Clear du looper 1 : desarme ; looper 2 reste
setl(0, true, 0, 0, 1); run(0.3)
print("6 clear L1 : piste 11 =", TR[11].v.I_RECARM, "| piste 12 =", TR[12].v.I_RECARM, "| regions", #REGS)
-- 7) total clear puis 1er REC : morceau 2, la region 1 s'arrete au debut de la 2
setl(1, true, 0, 0, 0); run(1.0)
local pos_before = POS
GM[950] = CLOCK; setl(2, true, 1, 0, 0); run(0.3)
print("7 total clear + REC : regions", #REGS, string.format("| region 1 : %.2f -> %.2f | region 2 : debut %.2f", REGS[1].s, REGS[1].e, REGS[2] and REGS[2].s or -1))
-- 8) arret par bascule externe : regions fermees, pistes restaurees
setl(2, true, 2, 50000, 0); run(0.5); local pstop = POS
EXT["NowUndo_Perf/cmd"] = "toggle"; run(0.1); run(1.5)
print("8 arret : commandes", table.concat(CMDS, ","), string.format("| region 2 : %.2f -> %.2f (arret a %.2f)", REGS[2].s, REGS[2].e, pstop), "| mode piste 2 =", TR[2].v.I_RECMODE, "(attendu 2) | arm =", TR[2].v.I_RECARM, "| repetition", REP)
print(PROJ.log)
print(#LOGARM .. " changements d'armement")
