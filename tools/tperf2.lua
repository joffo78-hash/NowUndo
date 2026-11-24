-- Test du saucissonnage de NowUndo_Performance.lua : phase de l'horloge retrouvee malgre la gigue, re-phase, coupes des items de loopers.
-- cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='NowUndo_Performance.lua'; l.execute(open('../../../tools/tperf2.lua').read())"
math.randomseed(7)
DRIPSODY_PERF_TEST = true
GM = {}; EXT = {}; CLOCK = 1000; POS = 0; STATE = 1; DEFER = nil; PROJ = {}; CMDS = {}
TR = {}; for n = 1, 30 do TR[n] = { n = n, v = { I_RECARM = 1, I_RECMODE = 2, B_MAINSEND = 1 }, items = {} } end
reaper = {
  gmem_attach = function() end, gmem_read = function(a) return GM[a] or 0 end, gmem_write = function(a, v) GM[a] = v end,
  time_precise = function() return CLOCK end, GetPlayPosition = function() return POS end, GetPlayState = function() return STATE end,
  GetExtState = function(s, k) return EXT[s .. "/" .. k] or "" end, SetExtState = function(s, k, v) EXT[s .. "/" .. k] = v end,
  CountTracks = function() return #TR end, GetTrack = function(_, i) return TR[i + 1] end,
  GetMediaTrackInfo_Value = function(t, k) return t.v[k] end, SetMediaTrackInfo_Value = function(t, k, v) t.v[k] = v end,
  GetSetRepeat = function() return 0 end, GetSetProjectInfo = function() return 48000 end,
  Main_OnCommand = function(id) if id == 1013 then STATE = 5 elseif id == 1016 then STATE = 0 end end,
  AddProjectMarker2 = function() return 1 end, SetProjectMarker3 = function() end,
  TimeMap_GetDividedBpmAtTime = function() return 120 end, CountTempoTimeSigMarkers = function() return 1 end,
  SetTempoTimeSigMarker = function() return true end, UpdateTimeline = function() end, UpdateArrange = function() end,
  SetProjExtState = function(_, s, k, v) PROJ[k] = v; return 0 end, GetProjExtState = function(_, s, k) local v = PROJ[k]; if v then return #v, v end return 0, "" end,
  CountTrackMediaItems = function(tr) return #tr.items end, GetTrackMediaItem = function(tr, i) return tr.items[i + 1] end,
  GetMediaItemInfo_Value = function(it, k) if k == "D_POSITION" then return it.pos elseif k == "D_LENGTH" then return it.len end return 0 end,
  SetMediaItemInfo_Value = function(it, k, v) if k == "D_LENGTH" then it.len = v end end,
  SplitMediaItem = function(it, t) local r = { pos = t, len = it.pos + it.len - t, tr = it.tr, src = it.src, off = it.off + (t - it.pos) }; it.len = t - it.pos; table.insert(it.tr.items, r); return r end,
  GetSetMediaItemInfo_String = function(it, k, v, set) it.ext = it.ext or {}; if set then it.ext[k] = v end return true, it.ext[k] or "" end,
  GetActiveTake = function(it) return { it = it } end, GetMediaItemTake_Source = function(tk) return { f = tk.it.src } end, GetMediaSourceFileName = function(src) return src.f end,
  GetMediaItemTakeInfo_Value = function(tk, k) if k == "D_STARTOFFS" then return tk.it.off elseif k == "D_PLAYRATE" then return 1 end return 0 end,
  DeleteTrackMediaItem = function(tr, it) for i, x in ipairs(tr.items) do if x == it then table.remove(tr.items, i) break end end end,
  Undo_BeginBlock = function() end, Undo_EndBlock = function() end, PreventUIRefresh = function() end,
  defer = function(f) DEFER = f end, atexit = function() end }
gfx = setmetatable({ w = 440, h = 250, mouse_x = 0, mouse_y = 0, mouse_cap = 0 }, { __index = function() return function() return 0 end end })
gfx.getchar = function() return 0 end; gfx.measurestr = function() return 50, 14 end
dofile(arg_path)
local SR, LEN = 48000, 96000                       -- cycle de 2 s
local L = LEN / SR
local T0 = 1.234                                    -- vrai depart de cycle (phase inconnue du script)
local function jit(ms) return (math.random() - 0.5) * 2 * ms / 1000 end
local function frame()
  CLOCK = CLOCK + 0.05; POS = POS + 0.05
  for i = 0, 7 do GM[100 + i] = 1; GM[130 + i] = CLOCK; GM[1000 + i * 600 + 42] = 1 end
  GM[1000 + 186] = SR
  -- l'horloge est lue a un instant qui differe de +-3 ms de la lecture de la position (gigue)
  local tt = POS + jit(3)
  GM[0] = 1; GM[1] = 1; GM[2] = LEN; GM[3] = ((tt - T0) % L) * SR; GM[4] = math.floor((tt - T0) / L)
  GM[1000 + 2] = 2; GM[1000 + 46] = LEN
  local f = DEFER; DEFER = nil; if f then f() end
end
for k = 1, 4 do frame() end
EXT["NowUndo_Perf/cmd"] = "toggle"; frame(); frame()
-- item de looper 1 (piste 11) du debut a la fin, item de looper 2 (piste 12) au milieu, item d'entree (piste 2)
TR[11].items = { { pos = 0.5, len = 29.5, tr = TR[11], src = "a.wav", off = 0 } }; TR[12].items = { { pos = 3.0, len = 7.0, tr = TR[12], src = "b.wav", off = 0 } }; TR[2].items = { { pos = 0.5, len = 29.5, tr = TR[2], src = "c.wav", off = 0 } }
for k = 1, 380 do                                  -- 19 s de plus : phase T0
  frame()
end
T0 = T0 + 0.3                                       -- re-phase de l'horloge de 300 ms
local T0b = T0
for k = 1, 220 do frame() end                       -- jusqu'a ~30 s
EXT["NowUndo_Perf/cmd"] = "toggle"; frame(); for k = 1, 40 do frame() end
-- resultats : apres l'arret, rien n'est coupe ; les boutons font le travail a posteriori
local P = DRIPSODY_PERF
local function items(n) local r = {}; for _, it in ipairs(TR[n].items) do r[#r + 1] = it end; table.sort(r, function(a, b) return a.pos < b.pos end); return r end
print("apres l'arret (rien coupe) : piste 11 =", #items(11), "item | piste 12 =", #items(12), "item")
P.load_log()
print("journal relu : segments", #P.saved.segs, "| morceaux", P.saved.songs, "| debut", P.saved.pos0 and string.format("%.2f", P.saved.pos0) or "?")
local sg = P.saved.segs
local truths = { 1.234, T0 }
for i, s in ipairs(sg) do
  local d = ((s.T0 - (truths[i] or 0) + L / 2) % L) - L / 2
  print(string.format("  segment %d : %.2f -> %.2f s, erreur de phase %.2f ms", i, s.t0, s.t1, d * 1000))
end
local ni, nc = P.split_items()
local it11, it12, it2 = items(11), items(12), items(2)
local maxerr = 0
for i = 2, #it11 do
  local t = it11[i].pos
  local truth = (t < 19.4) and ((t - 1.234 + L / 2) % L - L / 2) or ((t - T0 + L / 2) % L - L / 2)
  maxerr = math.max(maxerr, math.abs(truth))
end
print(string.format("DECOUPER : %d coupe(s) | piste 11 : %d items, piste 12 : %d items, entree (piste 2) : %d item (non coupee) | erreur max sur un vrai depart de cycle : %.2f ms", nc, #it11, #it12, #it2, maxerr * 1000))
-- le 2e appui ne coupe rien de plus
local ni2, nc2 = P.split_items()
print("DECOUPER une 2e fois : coupes supplementaires =", nc2, "(attendu 0)")
-- recoller : retour a l'etat d'origine
local nj, nk = P.join_items()
it11, it12 = items(11), items(12)
print(string.format("RECOLLER : %d recolle(s), %d non recollable(s) | piste 11 : %d item(s) [%.2f -> %.2f] | piste 12 : %d item(s) [%.2f -> %.2f]", nj, nk, #it11, it11[1].pos, it11[1].pos + it11[1].len, #it12, it12[1].pos, it12[1].pos + it12[1].len))
-- un morceau deplace a la main n'est PAS recolle
P.split_items()
local x = items(11)[3]; x.pos = x.pos + 0.5                    -- l'utilisateur deplace un morceau
local nj2, nk2 = P.join_items()
print(string.format("RECOLLER apres un deplacement manuel : %d recolle(s), %d non recollable(s) (attendu : le morceau deplace et son voisin restent)", nj2, nk2))
