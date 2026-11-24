-- Test de la GRILLE DE TEMPO alignee (simulateur de carte de tempo REAPER : barres de mesure, signature repoussee a la barre suivante).
-- cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='NowUndo_Performance.lua'; l.execute(open('../../../tools/tperf3.lua').read())"
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

reaper.EnumProjectMarkers3 = function() return 0 end
-- ====== simulateur de carte de tempo ======
MK = { { t = 0, bpm = 122.983, num = 4, den = 4 } }
local function sorted() table.sort(MK, function(a, b) return a.t < b.t end) end
local function qn_at(t)
  sorted(); local q = 0
  for i, m in ipairs(MK) do
    local nxt = MK[i + 1]; local tend = nxt and math.min(t, nxt.t) or t
    if tend > m.t then q = q + m.bpm / 60 * (tend - m.t) end
    if nxt and t <= nxt.t then break end
  end
  return q
end
local function time_at_qn(q)
  sorted(); local acc = 0
  for i, m in ipairs(MK) do
    local nxt = MK[i + 1]
    if nxt then local dq = m.bpm / 60 * (nxt.t - m.t); if acc + dq >= q then return m.t + (q - acc) * 60 / m.bpm end; acc = acc + dq
    else return m.t + (q - acc) * 60 / m.bpm end
  end
end
local function bars()                                   -- changements de signature : { qn0, num, m0 }
  sorted(); local out = { { qn0 = 0, num = 4, m0 = 0 } }
  for _, m in ipairs(MK) do
    if m.num and m.t > 0 then
      local q = qn_at(m.t); local last = out[#out]
      local nm = last.m0 + (q - last.qn0) / last.num
      out[#out + 1] = { qn0 = q, num = m.num, m0 = nm }
    elseif m.num and m.t == 0 then out[1].num = m.num end
  end
  return out
end
local function t2b(t)
  local q = qn_at(t); local B = bars(); local c = B[1]
  for _, x in ipairs(B) do if x.qn0 <= q + 1e-9 then c = x end end
  local k = math.floor((q - c.qn0) / c.num + 1e-9)
  local beat = (q - c.qn0) - k * c.num; if beat < 0 then beat = 0 end
  return beat, math.floor(c.m0 + k + 0.5), c.num, q
end
reaper.TimeMap2_timeToBeats = function(_, t) return t2b(t) end
reaper.TimeMap_GetMeasureInfo = function(_, m)
  local B = bars(); local c = B[1]
  for _, x in ipairs(B) do if x.m0 <= m + 1e-9 then c = x end end
  local qs = c.qn0 + (m - c.m0) * c.num
  local mk = MK[1]; for _, x in ipairs(MK) do if x.t <= time_at_qn(qs) + 1e-9 then mk = x end end
  return true, qs, qs + c.num, c.num, 4, mk.bpm
end
reaper.TimeMap2_QNToTime = function(_, q) return time_at_qn(q) end
reaper.TimeMap_GetDividedBpmAtTime = function(t) sorted(); local b = MK[1].bpm; for _, m in ipairs(MK) do if m.t <= t + 1e-12 then b = m.bpm end end; return b end
reaper.CountTempoTimeSigMarkers = function() return #MK end
reaper.GetTempoTimeSigMarker = function(_, i) sorted(); local m = MK[i + 1]; return true, m.t, 0, 0, m.bpm, m.num or -1, m.den or -1, false end
reaper.DeleteTempoTimeSigMarker = function(_, i) sorted(); table.remove(MK, i + 1); return true end
reaper.SetTempoTimeSigMarker = function(_, idx, t, mp, bp, bpm, num, den, lin)
  sorted()
  if t == -1 then                                                      -- pose par mesure / temps (la barre est designee par son numero)
    if SIM_MEASURE_BROKEN then return false end
    local B = bars(); local c = B[1]
    for _, x in ipairs(B) do if x.m0 <= mp + 1e-9 then c = x end end
    t = time_at_qn(c.qn0 + (mp - c.m0) * c.num)
    table.insert(MK, { t = t, bpm = bpm, num = num, den = den }); sorted(); return true
  end
  if idx == 0 then MK[1].bpm = bpm; if num and num > 0 then MK[1].num = num; MK[1].den = den end; return true end
  if num and num > 0 then
    local beat, meas, bnum, q = t2b(t)
    if beat < 1e-9 or (bnum - beat) < 1e-9 then                     -- deja sur une barre
    else
      local tb = nil
      local dq = bnum - beat                                         -- barre suivante
      local qn_next = q + dq
      local t_next = time_at_qn(qn_next)
      -- 1 microseconde avant une barre : REAPER la ramene sur la barre (modele : tolerance 5 microsecondes)
      if (t_next - t) <= 5e-6 then t = t_next
      else table.insert(MK, { t = t, bpm = bpm }); t = t_next end   -- tempo a l'instant demande, signature repoussee a la barre suivante
    end
    if (bnum - beat) < 1e-9 and (bnum - beat) > -1e-9 and t2b(t) then end
    table.insert(MK, { t = t, bpm = bpm, num = num, den = den })
  else
    table.insert(MK, { t = t, bpm = bpm })
  end
  sorted(); return true
end

GM[1000 + 155] = 118.5
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
MK0 = {}
TR[11].items = { { pos = 0.5, len = 29.5, tr = TR[11], src = "a.wav", off = 0 } }; TR[12].items = { { pos = 3.0, len = 7.0, tr = TR[12], src = "b.wav", off = 0 } }; TR[2].items = { { pos = 0.5, len = 29.5, tr = TR[2], src = "c.wav", off = 0 } }
for k = 1, 380 do                                  -- 19 s de plus : phase T0
  frame()
end
T0 = T0 + 0.3                                       -- re-phase de l'horloge de 300 ms
local T0b = T0
for k = 1, 220 do frame() end                       -- jusqu'a ~30 s
EXT["NowUndo_Perf/cmd"] = "toggle"; frame(); for k = 1, 40 do frame() end

-- ===== apres l'arret : grille =====
local P = DRIPSODY_PERF
P.load_log()
local function dump(title) print(title) for i, m in ipairs(MK) do print(string.format("   %2d  t=%9.4f  %8.3f BPM  sig %s", i, m.t, m.bpm, m.num and (m.num .. "/" .. (m.den or 4)) or "-")) end end
dump("carte de tempo apres le concert (marqueurs poses en direct) :")
local before = #MK
local np, worst, moved, nsg, gmode, ist = P.grid_apply()
print(string.format('items de loopers : %d, ecart median %.1f ms, max %.1f ms', ist.n, ist.med, ist.max))
dump("apres ALIGNER LA GRILLE :")
print(string.format("script : %d marqueur(s), %d segment(s), ecart max annonce %.4f ms, elements remis en place %d, pose par %s", np, nsg, worst, moved, gmode))
-- verification independante : chaque depart de cycle vrai est-il sur un 1er temps ?
local L = 2.0
local function check(T0, a, b)
  local w, n = 0, 0
  local k0 = math.ceil((a - T0) / L)
  for k = k0, math.floor((b - T0) / L) do
    local c = T0 + k * L; local beat, meas, bnum = t2b(c); local e = math.min(beat, bnum - beat) * 60 / MK[1].bpm
    w = math.max(w, math.abs(beat) < 1e-3 and 0 or e); n = n + 1
    if math.min(beat, bnum - beat) > 1e-3 then print(string.format("   PAS SUR UN PREMIER TEMPS : cycle a %.4f s, temps %.5f de la mesure de %d", c, beat, bnum)) end
  end
  return n
end
local n1 = check(1.234, 1.0, 19.2); local n2 = check(1.534, 19.5, 30.0)
print(string.format("verification : %d + %d departs de cycle examines (segment 1 : phase 1.234, segment 2 : phase 1.534)", n1, n2))
-- les items n'ont pas bouge
local it11 = TR[11].items[1]
print(string.format("item piste 11 : %.3f -> %.3f (inchange : 0.500 -> 30.000)", it11.pos, it11.pos + it11.len))
-- ANCIENNE GRILLE : retour exact
local cnt_after = #MK
print("restauration :", P.grid_restore(), "| marqueurs :", #MK, "(avant :", before .. ")")
dump("apres ANCIENNE GRILLE :")
-- 2e alignement depuis la grille d'origine : meme resultat
local np2 = P.grid_apply()
print("realigner : marqueurs", np2, "(1er alignement :", np .. ")  | taille de la carte", #MK, "(1er alignement :", cnt_after .. ")")

-- ===== repli : la pose par mesure ne marche pas dans cette version de REAPER (simule) =====
P.grid_restore()
SIM_MEASURE_BROKEN = true
local np3, worst3, moved3, nsg3, mode3 = P.grid_apply()
print(string.format("REPLI (pose par mesure impossible) : %d marqueur(s), ecart max %.4f ms, pose par %s", np3, worst3, mode3))
local n3 = check(1.234, 1.0, 19.2) + check(1.534, 19.5, 30.0)
print("verification independante du repli :", n3, "departs de cycle examines")
