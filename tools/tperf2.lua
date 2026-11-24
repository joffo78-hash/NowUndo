-- Test du saucissonnage de NowUndo_Performance.lua : phase de l'horloge retrouvee malgre la gigue, re-phase, coupes des items de loopers.
-- cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='NowUndo_Performance.lua'; l.execute(open('../../../tools/tperf2.lua').read())"
math.randomseed(7)
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
  SetProjExtState = function(_, s, k, v) PROJ[k] = v; return 0 end,
  CountTrackMediaItems = function(tr) return #tr.items end, GetTrackMediaItem = function(tr, i) return tr.items[i + 1] end,
  GetMediaItemInfo_Value = function(it, k) if k == "D_POSITION" then return it.pos elseif k == "D_LENGTH" then return it.len end return 0 end,
  SetMediaItemInfo_Value = function() end,
  SplitMediaItem = function(it, t) local r = { pos = t, len = it.pos + it.len - t, tr = it.tr }; it.len = t - it.pos; table.insert(it.tr.items, r); return r end,
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
EXT["NowUndo_Perf/split"] = "1"
for k = 1, 4 do frame() end
EXT["NowUndo_Perf/cmd"] = "toggle"; frame(); frame()
-- item de looper 1 (piste 11) du debut a la fin, item de looper 2 (piste 12) au milieu, item d'entree (piste 2)
TR[11].items = { { pos = 0.5, len = 29.5, tr = TR[11] } }; TR[12].items = { { pos = 3.0, len = 7.0, tr = TR[12] } }; TR[2].items = { { pos = 0.5, len = 29.5, tr = TR[2] } }
for k = 1, 380 do                                  -- 19 s de plus : phase T0
  frame()
end
T0 = T0 + 0.3                                       -- re-phase de l'horloge de 300 ms
local T0b = T0
for k = 1, 220 do frame() end                       -- jusqu'a ~30 s
EXT["NowUndo_Perf/cmd"] = "toggle"; frame(); for k = 1, 40 do frame() end
-- resultats
local log = PROJ.log or ""
local segs = {}
for line in log:gmatch("[^\n]+") do local k, T, Lk, a, b = line:match("^C\t(%S+)\t([%d%.]+)\t([%d%.]+)\t([%d%.]+)\t([%d%.]+)"); if k then segs[#segs + 1] = { T = tonumber(T), L = tonumber(Lk), a = tonumber(a), b = tonumber(b) } end end
print("segments d'horloge :", #segs)
local truths = { 1.234, T0b }
for i, sg in ipairs(segs) do
  local tr = truths[i] or 0
  local d = ((sg.T - tr + L / 2) % L) - L / 2
  print(string.format("  segment %d : %.2f -> %.2f s, phase estimee %.4f (vraie %.4f), erreur %.2f ms, L = %.6f", i, sg.a, sg.b, sg.T % L, tr % L, d * 1000, sg.L))
end
local function items(n) local t = {}; for _, it in ipairs(TR[n].items) do t[#t + 1] = it end; table.sort(t, function(a, b) return a.pos < b.pos end); return t end
local it11 = items(11); local it12 = items(12); local it2 = items(2)
print("piste 11 :", #it11, "items | piste 12 :", #it12, "items | piste 2 (entree, pas coupee) :", #it2, "item(s)")
-- erreur des coupes de la piste 11 par rapport au vrai depart de cycle le plus proche
local maxerr, n = 0, 0
for i = 2, #it11 do
  local t = it11[i].pos
  local truth = (t < 19.4) and ((t - 1.234 + L / 2) % L - L / 2) or ((t - T0b + L / 2) % L - L / 2)
  maxerr = math.max(maxerr, math.abs(truth)); n = n + 1
end
print(string.format("coupes piste 11 : %d, erreur max sur un vrai depart de cycle : %.2f ms", n, maxerr * 1000))
print(select(2, PROJ.log:gsub("\nC\t", "")), "segments dans le journal")
