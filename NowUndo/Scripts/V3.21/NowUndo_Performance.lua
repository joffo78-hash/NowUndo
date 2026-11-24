-- @noindex
--[[
  NowUndo_Performance.lua  -  « Dripsody Performance » : enregistrement d'un CONCERT entier dans REAPER (etape 1).

  Un seul enregistrement continu. Le script ne gere QUE les entrees (pistes 2 a 9) et les loopers (pistes 11 a 18) ;
  les autres pistes (instruments, effets...) restent a ta charge : si tu les armes, elles sont enregistrees avec le reste.

  ATTENTION (24 nov., constate par l'utilisateur) : dans son modele, les pistes sont ARMEES avec le mode « Record :
  disable (input monitoring only) » : c'est l'armement qui fait entrer le signal (monitoring). Le script ne DESARME donc
  JAMAIS une piste qui etait armee : il bascule seulement son MODE d'enregistrement (2 = monitoring seul, 3 = output).
  Une piste qui n'etait pas armee est armee quand elle doit enregistrer, puis desarmee.
  - ENTREE k : enregistre (mode output) des qu'elle est affectee a au moins un looper (masques publies par le
    Launchpad, gmem 6010 + i) ET que sa sortie vers la piste parent est active ; monitoring seul sinon.
  - LOOPER i : enregistre des que son enregistrement est abouti (boucle > 0, plus en REC / attente), jusqu'au Clear.
    Une periode d'enregistrement = un item (a confirmer : changement de mode en cours d'enregistrement).
  - MORCEAUX : un morceau commence au 1er REC alors que TOUS les loopers sont vides (3 parts comprises) ; sa region
    va jusqu'au 1er REC du morceau suivant (la derniere jusqu'a l'arret). Region creee au debut puis agrandie en direct.
  - TEMPO : a chaque nouvelle synchro (nouveau maitre looper) un marqueur de tempo est AJOUTE a la position de lecture.
    Jamais de SetCurrentBPM ni de modification d'un tempo deja pose pendant la lecture (la tete de lecture sauterait,
    essai du 24 nov.). L'alignement des mesures sur les boucles se fera apres l'arret (etape 2).
  - SAUCISSONNAGE (a posteriori, reversible) : APRES le concert, meme apres avoir rouvert le projet, deux boutons de la fenetre :
    « DECOUPER PAR CYCLE » coupe les items des LOOPERS a chaque depart de cycle de l'horloge interne (le maitre de la synchro) ;
    « RECOLLER » remet les items comme avant (les morceaux coupes sont marques « dripsody_cut » et recolles seulement s'ils sont
    toujours contigus, de la meme source, a la meme place dans le fichier). Ctrl+Z annule aussi. Les departs de cycle sont retrouves
    EN DIRECT pendant le concert : a chaque image on lit la position de l'horloge (gmem [o+3], publiee a chaque echantillon) et la
    position de lecture du projet ; la phase (mediane de centaines de mesures) + la longueur exacte du cycle donnent T0 + k * L.
    Un decalage de phase (re-phase) ouvre un nouveau segment. Les segments sont gardes dans le projet (ExtState « Dripsody_Perf/log »).
    Reglage fin : ExtState « NowUndo_Perf/cut_ms » (ms, negatif = coupe plus tot ; 0 par defaut).
  - GRILLE ALIGNEE (a posteriori, reversible) : bouton « ALIGNER LA GRILLE » = tempo exact par synchro (60 * N / L), mesure d'un nombre
    entier de temps, mesures de raccord entre les synchros : CHAQUE DEPART DE CYCLE TOMBE SUR UN PREMIER TEMPS. « ANCIENNE GRILLE » revient
    a la carte de tempo d'avant. Items, regions et marqueurs ne bougent pas. Ctrl+Z annule aussi.
  - QUEUES D'EFFETS : quand un looper est efface (ou une entree desaffectee), la piste continue d'enregistrer tant qu'elle sonne encore
    (delay, reverb...) : au moins 0,5 s, au plus 10 s, jusqu'a passer sous -60 dB. Reglages : ExtState « NowUndo_Perf/tail_s » (duree max, s)
    et « NowUndo_Perf/tail_db » (seuil, dB). Redemande pendant la queue = meme item.
  - Au demarrage : repetition coupee. A l'arret : etats d'armement / modes d'enregistrement des pistes geree restaures,
    items regles en base de temps « temps ». Les evenements sont gardes dans l'ExtState du projet (« Dripsody_Perf »).

  Lancer le script = ouvre la fenetre ; relancer pendant un concert = bascule (demarrer / arreter) sans ouvrir de 2e fenetre.
]]
local R = reaper
local EXT = "NowUndo_Perf"
local GMEM = "nowundo_sync"
local IN_FIRST, NB_IN, LP_FIRST, NB_LP = 2, 8, 11, 8     -- numeros de pistes (1 = premiere), comme le Launchpad / le Twister
local REC_MODE = 3                                        -- 3 = sortie stereo avec compensation de latence
local MON_MODE = 2                                        -- 2 = « disable (input monitoring only) » : la piste armee ecoute sans enregistrer
local TAIL_MIN = 0.5                                      -- la queue d'une piste est toujours enregistree au moins 0,5 s apres l'arret demande
local TOL = 0.03                                          -- pas de coupe a moins de 30 ms du bord d'un item (pas de miettes)
local DASH = 6000                                          -- tableau de bord du Launchpad : [DASH+10+i] = entrees qui alimentent le looper i

local P = { active = false, starting = false, tr = {}, songs = {}, events = {}, song = nil, in_song = false, had_loop = false, segs = {}, clk = nil,
            key = "none", t_rule = 0, t_region = 0, post_t = nil, msg = "", info = {} }
R.gmem_attach(GMEM)
local function g(a) return R.gmem_read(a) or 0 end
local function fmt_t(s) s = math.max(0, math.floor(s)); return string.format("%d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60) end

for k = 1, NB_IN do P.tr[#P.tr + 1] = { n = IN_FIRST + k - 1, kind = "in", idx = k } end
for i = 1, NB_LP do P.tr[#P.tr + 1] = { n = LP_FIRST + i - 1, kind = "lp", idx = i } end

-- ============================ lecture de l'etat des loopers (gmem) ============================
function P.looper(i)                                       -- i = 0..7
  local b0 = 1000 + i * 600
  local alive = g(100 + i) > 0 and (R.time_precise() - g(130 + i)) <= 3.0
  local ap = math.floor(g(b0 + 42) + .5); if ap < 1 or ap > 3 then ap = 1 end
  local b = b0 + (ap - 1) * 200
  local any = false
  for p = 0, 2 do if g(b0 + p * 200 + 46) > 0 then any = true end end
  return { alive = alive, state = math.floor(g(b + 2) + .5), len = g(b + 46), any = any, b = b }
end
function P.input_used(k)                                   -- l'entree k alimente-t-elle au moins un looper ?
  for i = 1, NB_LP do
    local m = math.floor(g(DASH + 10 + i) + .5)
    if (m >> (k - 1)) & 1 == 1 then return true end
  end
  return false
end
function P.master()                                         -- cle de la synchro en cours + tempo estime du maitre looper
  for p = 0, 2 do
    local o = p * 10
    local lock = math.floor(g(o) + .5)
    if lock == 1 then
      local id = math.floor(g(o + 1) + .5); local len = g(o + 2)
      if len > 0 and id >= 1 and id <= 8 then
        local bpm = g(1000 + (id - 1) * 600 + p * 200 + 155)
        return string.format("L%d:%d:%d", p, id, math.floor(len + .5)), bpm, len, id, p
      end
    elseif lock == 2 then return "HOST" end
  end
  return "none"
end

-- ============================ regions, marqueurs ============================
function P.press_pos()                                      -- position de lecture de l'appui du REC (heure d'appui du Launchpad : gmem 950)
  local pos = R.GetPlayPosition()
  local t = g(950)
  if t > 0 then
    local dt = R.time_precise() - t
    if dt >= 0 and dt < 1.0 then pos = pos - dt end
  end
  return math.max(0, pos)
end
function P.open_song(pos)
  if P.song and P.song.idx then R.SetProjectMarker3(0, P.song.idx, true, P.song.start, pos, P.song.name, 0); P.song.stop = pos end
  local n = #P.songs + 1
  local name = "Morceau " .. n
  local idx = R.AddProjectMarker2(0, true, pos, pos + 0.5, name, -1, 0)
  P.song = { n = n, start = pos, idx = idx, name = name }
  P.songs[n] = P.song
  P.in_song, P.had_loop = true, false
  P.info.song = name
end
function P.grow_region(pos)
  local s = P.song
  if s and s.idx then R.SetProjectMarker3(0, s.idx, true, s.start, math.max(pos, s.start + 0.1), s.name, 0) end
end
function P.tempo_marker(pos, bpm)
  if not (bpm and bpm >= 30 and bpm <= 400) then return false end
  local cur = R.TimeMap_GetDividedBpmAtTime(pos)
  if cur and math.abs(cur - bpm) < 0.02 then return false end
  local n0 = R.CountTempoTimeSigMarkers(0)
  R.SetTempoTimeSigMarker(0, -1, pos, -1, -1, bpm, 0, 0, false)       -- 0 / 0 : pas de changement de signature
  R.UpdateTimeline()
  return R.CountTempoTimeSigMarkers(0) > n0
end

-- ============================ horloge interne : phase des cycles ============================
local function median(t)
  local a = {}; for i = 1, #t do a[i] = t[i] end
  table.sort(a); local n = #a
  if n == 0 then return 0 end
  return n % 2 == 1 and a[(n + 1) // 2] or (a[n // 2] + a[n // 2 + 1]) / 2
end
function P.clock_close(pos)
  local c = P.clk; P.clk = nil
  if not c or c.n < 8 then return end
  local L = c.L
  local T0 = (c.r0 + c.med) % L
  P.segs[#P.segs + 1] = { key = c.key, L = L, T0 = T0, t0 = c.t0, t1 = c.t1 or pos, n = c.n }
  P.ev(c.t1 or pos, "clock", string.format("%s L=%.6f T0=%.6f n=%d", c.key, L, T0, c.n))
end
function P.clock_sample(pos, key, len, id, part)
  if not (key and key:sub(1, 1) == "L" and len and len > 0) then P.clock_close(pos); return end
  local c = P.clk
  if c and c.key ~= key then P.clock_close(pos); c = nil end
  local sr = g(1000 + (id - 1) * 600 + part * 200 + 186)
  if sr <= 0 then sr = R.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false); if sr <= 0 then sr = 48000 end end
  local L = len / sr
  local mpos = g(part * 10 + 3)
  if not c then c = { key = key, L = L, t0 = P.next_t0 or pos, ds = {}, nds = 0, n = 0, bad = 0 }; P.clk = c; P.next_t0 = nil end
  local r = (pos - mpos / sr) % L                              -- debut (modulo L) du cycle en cours, d'apres cette mesure
  if not c.r0 then c.r0 = r end
  local d = ((r - c.r0 + L / 2) % L) - L / 2                   -- ecart a la 1re mesure, ramene dans [-L/2, L/2[
  if c.med and math.abs(d - c.med) > 0.015 then                -- ecart durable : re-phase de l'horloge -> nouveau segment
    c.bad = c.bad + 1
    if c.bad == 1 then c.bad_t0 = pos end
    if c.bad >= 10 then P.clock_close(c.bad_t0 or pos); P.next_t0 = c.bad_t0; return end   -- le nouveau segment commence a la 1re mesure ecartee
    return
  end
  c.bad = 0
  c.nds = c.nds % 400 + 1; c.ds[c.nds] = d; c.n = c.n + 1       -- 400 dernieres mesures (anneau)
  if c.n < 8 then c.med = median(c.ds) elseif c.n % 10 == 0 then c.med = median(c.ds) end
  c.t1 = pos
end
function P.cut_times(segs)
  local cuts = {}
  local off = (tonumber(R.GetExtState(EXT, "cut_ms")) or 0) / 1000
  for _, sg in ipairs(segs) do
    local m0 = math.ceil((sg.t0 - 0.05 - sg.T0) / sg.L)
    local m1 = math.floor((sg.t1 + 0.05 - sg.T0) / sg.L)
    for m = m0, m1 do cuts[#cuts + 1] = sg.T0 + m * sg.L + off end
  end
  table.sort(cuts)
  local out = {}
  for _, t in ipairs(cuts) do if #out == 0 or t - out[#out] > TOL then out[#out + 1] = t end end
  return out
end
-- journal du projet (ecrit a l'arret) : segments d'horloge « C » et debut « E start »
function P.load_log()
  P.saved = { segs = {}, pos0 = nil, songs = 0 }
  local rv, str = R.GetProjExtState(0, "Dripsody_Perf", "log")
  if not rv or rv == 0 or not str or str == "" then return end
  for line in str:gmatch("[^\n]+") do
    local f = {}
    for x in (line .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = x end
    if f[1] == "C" and #f >= 6 then P.saved.segs[#P.saved.segs + 1] = { key = f[2], T0 = tonumber(f[3]), L = tonumber(f[4]), t0 = tonumber(f[5]), t1 = tonumber(f[6]) }
    elseif f[1] == "E" and f[3] == "start" then P.saved.pos0 = tonumber(f[2])
    elseif f[1] == "E" and f[3] == "sync" and f[4] then
      local key, bpm = f[4]:match("^(%S+)"), tonumber(f[4]:match("bpm=([%d%.]+)"))
      if key and bpm then P.saved.bpm = P.saved.bpm or {}; P.saved.bpm[key] = bpm end
    elseif f[1] == "S" then P.saved.songs = P.saved.songs + 1 end
  end
end
local function lp_items(m, pos0)
  local list = {}
  for i = 0, R.CountTrackMediaItems(m.tr) - 1 do
    local it = R.GetTrackMediaItem(m.tr, i)
    if R.GetMediaItemInfo_Value(it, "D_POSITION") >= (pos0 or 0) - 0.5 then list[#list + 1] = it end
  end
  return list
end
function P.split_items()
  P.load_log()
  local sv = P.saved
  local cuts = P.cut_times(sv.segs)
  local n_items, n_cuts = 0, 0
  if #cuts == 0 then return 0, 0 end
  R.Undo_BeginBlock(); R.PreventUIRefresh(1)
  for _, m in ipairs(P.tr) do
    if m.kind == "lp" then
      m.tr = m.tr or R.GetTrack(0, m.n - 1)
      for _, it in ipairs(m.tr and lp_items(m, sv.pos0) or {}) do
        local cur = it
        local lo, hi = 1, #cuts + 1                                  -- 1re coupe apres le debut de l'item (recherche dichotomique)
        local ip = R.GetMediaItemInfo_Value(cur, "D_POSITION")
        while lo < hi do local mid = (lo + hi) // 2; if cuts[mid] <= ip + TOL then lo = mid + 1 else hi = mid end end
        local k = lo
        while k <= #cuts do
          local cp = R.GetMediaItemInfo_Value(cur, "D_POSITION"); local ce = cp + R.GetMediaItemInfo_Value(cur, "D_LENGTH")
          local t = cuts[k]
          if t >= ce - TOL then break end
          if t > cp + TOL then
            local right = R.SplitMediaItem(cur, t)
            if right then
              R.GetSetMediaItemInfo_String(right, "P_EXT:dripsody_cut", "1", true)   -- marque : morceau cree par la decoupe
              cur = right; n_cuts = n_cuts + 1
            end
          end
          k = k + 1
        end
        n_items = n_items + 1
      end
    end
  end
  R.PreventUIRefresh(-1); R.Undo_EndBlock("Dripsody : decoupe des items par cycle", -1)
  return n_items, n_cuts
end
-- remet les items comme avant : un morceau marque est recolle au precedent s'il est contigu, de la meme source et a la meme place du fichier
function P.join_items()
  P.load_log()
  local n_join, n_skip = 0, 0
  R.Undo_BeginBlock(); R.PreventUIRefresh(1)
  for _, m in ipairs(P.tr) do
    if m.kind == "lp" then
      m.tr = m.tr or R.GetTrack(0, m.n - 1)
      local list = m.tr and lp_items(m, P.saved.pos0) or {}
      table.sort(list, function(a, b) return R.GetMediaItemInfo_Value(a, "D_POSITION") < R.GetMediaItemInfo_Value(b, "D_POSITION") end)
      local prev
      for _, it in ipairs(list) do
        local _, mark = R.GetSetMediaItemInfo_String(it, "P_EXT:dripsody_cut", "", false)
        local merged = false
        if mark == "1" and prev then
          local pp, pl = R.GetMediaItemInfo_Value(prev, "D_POSITION"), R.GetMediaItemInfo_Value(prev, "D_LENGTH")
          local ip, il = R.GetMediaItemInfo_Value(it, "D_POSITION"), R.GetMediaItemInfo_Value(it, "D_LENGTH")
          local ta, tb = R.GetActiveTake(prev), R.GetActiveTake(it)
          if ta and tb and math.abs(ip - (pp + pl)) < 0.002 then
            local fa = R.GetMediaSourceFileName(R.GetMediaItemTake_Source(ta), "")
            local fb = R.GetMediaSourceFileName(R.GetMediaItemTake_Source(tb), "")
            local ra, rb = R.GetMediaItemTakeInfo_Value(ta, "D_PLAYRATE"), R.GetMediaItemTakeInfo_Value(tb, "D_PLAYRATE")
            local oa, ob = R.GetMediaItemTakeInfo_Value(ta, "D_STARTOFFS"), R.GetMediaItemTakeInfo_Value(tb, "D_STARTOFFS")
            if fa == fb and math.abs(ra - rb) < 1e-6 and math.abs(ob - (oa + pl * ra)) < 0.002 then
              R.SetMediaItemInfo_Value(prev, "D_LENGTH", ip + il - pp)
              R.DeleteTrackMediaItem(m.tr, it)
              n_join = n_join + 1; merged = true
            end
          end
          if not merged then n_skip = n_skip + 1 end
        end
        if not merged then prev = it end
      end
    end
  end
  R.PreventUIRefresh(-1); R.Undo_EndBlock("Dripsody : recollage des items", -1)
  R.UpdateArrange()
  return n_join, n_skip
end

-- ============================ grille de tempo alignee sur les cycles (a posteriori, reversible) ============================
-- Chaque segment d'horloge = un maitre de synchro : tempo exact 60 * N / L (N temps par cycle, estime par le looper), mesure de q temps
-- (q divise N : 4, 3, 6, 8, 2, 5, 7 sinon N) -> un cycle = un nombre entier de mesures, et CHAQUE DEPART DE CYCLE TOMBE SUR UN PREMIER TEMPS.
-- Entre deux segments (et avant le 1er) : « mesures de raccord » (tempo legerement ajuste, derniere mesure raccourcie) pour que la mesure suivante
-- commence exactement au depart du cycle. REAPER repousse une signature posee en milieu de mesure jusqu'a la barre suivante : tous les marqueurs sont
-- donc poses sur une barre, 1 microseconde avant, pour que l'arrondi ne les envoie jamais a la barre d'apres.
-- Securite : l'ancienne carte de tempo est sauvee dans le projet (« grid_backup ») ; position des items, regions et marqueurs remise telle quelle apres coup.
local function bar_num(N)
  for _, q in ipairs({ 4, 3, 6, 8, 2, 5, 7 }) do if N % q == 0 then return q end end
  return N
end
function P.grid_dump()
  local lines = {}
  for i = 0, R.CountTempoTimeSigMarkers(0) - 1 do
    local _, tp, _, _, bpm, num, den, lin = R.GetTempoTimeSigMarker(0, i)
    lines[#lines + 1] = string.format("%.9f\t%.9f\t%d\t%d", tp, bpm, num or 0, den or 0)
  end
  return table.concat(lines, "\n")
end
local function snap_project()                                   -- positions des items, regions et marqueurs
  local S = { items = {}, marks = {} }
  for t = 0, R.CountTracks(0) - 1 do
    local tr = R.GetTrack(0, t)
    for i = 0, R.CountTrackMediaItems(tr) - 1 do
      local it = R.GetTrackMediaItem(tr, i)
      S.items[#S.items + 1] = { it = it, pos = R.GetMediaItemInfo_Value(it, "D_POSITION"), len = R.GetMediaItemInfo_Value(it, "D_LENGTH") }
    end
  end
  local i = 0
  while true do
    local rv, isrgn, pos, rgnend, name, idx, col = R.EnumProjectMarkers3(0, i)
    if not rv or rv == 0 then break end
    S.marks[#S.marks + 1] = { isrgn = isrgn, pos = pos, rgnend = rgnend, name = name, idx = idx, col = col }
    i = i + 1
  end
  return S
end
local function put_back(S)                                      -- ce qui a bouge pendant la reconstruction de la grille est remis en place
  local moved = 0
  for _, x in ipairs(S.items) do
    if math.abs(R.GetMediaItemInfo_Value(x.it, "D_POSITION") - x.pos) > 1e-7 then R.SetMediaItemInfo_Value(x.it, "D_POSITION", x.pos); moved = moved + 1 end
    if math.abs(R.GetMediaItemInfo_Value(x.it, "D_LENGTH") - x.len) > 1e-7 then R.SetMediaItemInfo_Value(x.it, "D_LENGTH", x.len) end
  end
  local i = 0
  for _, mk in ipairs(S.marks) do
    local rv, isrgn, pos, rgnend = R.EnumProjectMarkers3(0, i)
    if rv and rv ~= 0 and (math.abs(pos - mk.pos) > 1e-7 or math.abs((rgnend or 0) - (mk.rgnend or 0)) > 1e-7) then
      R.SetProjectMarker3(0, mk.idx, mk.isrgn, mk.pos, mk.rgnend, mk.name, mk.col); moved = moved + 1
    end
    i = i + 1
  end
  return moved
end
local function plan_fill(plan, a, b, bpm_ref, num)            -- [a, b) : bar line -> bar line, un nombre entier de temps, derniere mesure raccourcie
  local D = b - a
  if D < 0.02 then return end
  local K = math.floor(D * bpm_ref / 60 + 0.5)
  local kmin = math.max(1, math.ceil(D * bpm_ref * 0.5 / 60)); local kmax = math.max(kmin, math.floor(D * bpm_ref * 2 / 60))
  K = math.max(1, math.max(kmin, math.min(kmax, K)))
  local bpm = 60 * K / D
  local nb, r = K // num, K % num
  if nb > 0 then plan[#plan + 1] = { t = a, bpm = bpm, num = num } end
  if r > 0 then plan[#plan + 1] = { t = (nb > 0) and (a + nb * num * 60 / bpm) or a, bpm = bpm, num = r } end
end
-- ce que voit l'utilisateur : le DEBUT DES ITEMS DES LOOPERS. Si la phase de l'horloge s'en ecarte de plus de 40 ms (mediane), la grille se cale sur les
-- items (la phase de l'horloge n'est plus fiable sur ce projet) ; en dessous, on garde l'horloge, plus precise.
function P.item_phase(sg, pos0)
  local offs = {}
  for _, m in ipairs(P.tr) do
    if m.kind == "lp" then
      m.tr = m.tr or R.GetTrack(0, m.n - 1)
      for _, it in ipairs(m.tr and lp_items(m, pos0) or {}) do
        local ip = R.GetMediaItemInfo_Value(it, "D_POSITION")
        if ip >= sg.t0 - 1.0 and ip <= sg.t1 + 1.0 then
          offs[#offs + 1] = ((ip - sg.T0 + sg.L / 2) % sg.L) - sg.L / 2        -- ecart du debut de l'item a la barre de cycle la plus proche
        end
      end
    end
  end
  if #offs == 0 then return nil, 0 end
  table.sort(offs)
  return offs[(#offs + 1) // 2], #offs
end
function P.grid_plan(sv)
  local segs = {}
  for _, s in ipairs(sv.segs) do segs[#segs + 1] = s end
  table.sort(segs, function(a, b) return a.t0 < b.t0 end)
  for _, s in ipairs(segs) do
    s.N = math.max(1, math.floor(s.L * ((sv.bpm and sv.bpm[s.key]) or 120) / 60 + 0.5))
    s.q = bar_num(s.N); s.bpm = 60 * s.N / s.L
    s.c0 = s.T0 + math.ceil((s.t0 - 0.05 - s.T0) / s.L) * s.L           -- 1er depart de cycle du segment
  end
  return segs
end
function P.grid_restore()
  local rv, str = R.GetProjExtState(0, "Dripsody_Perf", "grid_backup")
  if not rv or rv == 0 or not str or str == "" then return false end
  local T = {}
  for line in str:gmatch("[^\n]+") do
    local a, b, c, d = line:match("^(%S+)\t(%S+)\t(%S+)\t(%S+)")
    if a then T[#T + 1] = { t = tonumber(a), bpm = tonumber(b), num = tonumber(c), den = tonumber(d) } end
  end
  if #T == 0 then return false end
  R.Undo_BeginBlock(); R.PreventUIRefresh(1)
  for i = R.CountTempoTimeSigMarkers(0) - 1, 1, -1 do R.DeleteTempoTimeSigMarker(0, i) end
  R.SetTempoTimeSigMarker(0, 0, T[1].t, -1, -1, T[1].bpm, T[1].num > 0 and T[1].num or 4, T[1].den > 0 and T[1].den or 4, false)
  for i = 2, #T do
    local x = T[i]
    if x.num > 0 then R.SetTempoTimeSigMarker(0, -1, x.t - 1e-6, -1, -1, x.bpm, x.num, x.den > 0 and x.den or 4, false)
    else R.SetTempoTimeSigMarker(0, -1, x.t, -1, -1, x.bpm, 0, 0, false) end
  end
  R.SetProjExtState(0, "Dripsody_Perf", "grid_backup", "")
  R.UpdateTimeline(); R.PreventUIRefresh(-1); R.Undo_EndBlock("Dripsody : retour a l'ancienne grille de tempo", -1)
  return true
end
function P.grid_build(mode)                                     -- mode : "measure" (marqueurs poses par mesure / temps) ou "time" (par instant, 1 microseconde avant la barre)
  P.load_log()
  local sv = P.saved
  if #sv.segs == 0 then return nil, "Pas de segment d'horloge dans ce projet." end
  local rv0, bk = R.GetProjExtState(0, "Dripsody_Perf", "grid_backup")
  if rv0 and rv0 ~= 0 and bk ~= "" then P.grid_restore() end              -- on repart toujours de la grille d'origine
  local segs = P.grid_plan(sv)
  local pos0 = sv.pos0 or segs[1].t0
  local corrs = {}
  for i, sg in ipairs(segs) do
    local d, n = P.item_phase(sg, pos0)
    if d and math.abs(d) > 0.040 then
      sg.T0 = sg.T0 + d                                                    -- grille recalee sur le debut des items
      sg.c0 = sg.T0 + math.ceil((sg.t0 - 0.05 - sg.T0) / sg.L) * sg.L
      corrs[#corrs + 1] = string.format("segment %d : %+.0f ms (%d item(s))", i, d * 1000, n)
    end
  end
  P.last_corr = corrs
  local bpm0 = R.TimeMap_GetDividedBpmAtTime(pos0) or 120
  local bar0 = 4 * 60 / bpm0
  -- depart de la zone reconstruite : une barre de l'ancienne grille, au moins 2 mesures avant le 1er cycle
  local target = math.max(0, math.min(pos0, segs[1].c0 - 2 * bar0))
  local _, meas = R.TimeMap2_timeToBeats(0, target)
  local _, qn_start, _, num0, den0 = R.TimeMap_GetMeasureInfo(0, meas)
  local b_a = R.TimeMap2_QNToTime(0, qn_start)
  num0 = (den0 == 4 and num0 and num0 > 0) and num0 or 4
  local plan = {}
  plan_fill(plan, b_a, segs[1].c0, bpm0, num0)
  for i, sg in ipairs(segs) do
    local nxt = segs[i + 1]
    local n_full = nxt and math.floor((nxt.c0 - sg.c0) / sg.L + 1e-6) or 1
    if n_full >= 1 then plan[#plan + 1] = { t = sg.c0, bpm = sg.bpm, num = sg.q } end
    if nxt then plan_fill(plan, sg.c0 + math.max(0, n_full) * sg.L, nxt.c0, sg.bpm, 4) end
  end
  table.sort(plan, function(a, b) return a.t < b.t end)
  local clean = {}
  for _, x in ipairs(plan) do if #clean == 0 or x.t - clean[#clean].t > 1e-6 then clean[#clean + 1] = x end end
  plan = clean
  -- sauvegarde de l'ancienne carte, puis remplacement de tout ce qui est a partir de b_a
  R.Undo_BeginBlock(); R.PreventUIRefresh(1)
  local snap = snap_project()
  R.SetProjExtState(0, "Dripsody_Perf", "grid_backup", P.grid_dump())
  local first_is_0 = false
  for i = R.CountTempoTimeSigMarkers(0) - 1, 0, -1 do
    local _, tp = R.GetTempoTimeSigMarker(0, i)
    if tp >= b_a - 1e-6 then
      if i == 0 then first_is_0 = true else R.DeleteTempoTimeSigMarker(0, i) end
    end
  end
  for j, x in ipairs(plan) do
    if j == 1 and first_is_0 then R.SetTempoTimeSigMarker(0, 0, 0, -1, -1, x.bpm, x.num, 4, false)
    elseif mode == "measure" then
      -- la barre cible est a x.t (fin de la region precedente) : on la designe par son numero de mesure, sans passer par un instant arrondi
      local _, meas = R.TimeMap2_timeToBeats(0, x.t + 1e-4)
      R.SetTempoTimeSigMarker(0, -1, -1, meas, 0, x.bpm, x.num, 4, false)
    else R.SetTempoTimeSigMarker(0, -1, x.t - 1e-6, -1, -1, x.bpm, x.num, 4, false) end
  end
  R.UpdateTimeline()
  local moved = put_back(snap)
  R.PreventUIRefresh(-1); R.Undo_EndBlock("Dripsody : grille de tempo alignee sur les cycles", -1)
  -- verification : le depart de plusieurs cycles de chaque segment tombe-t-il sur un premier temps ?
  local worst, nchk = 0, 0
  for i, sg in ipairs(segs) do
    local nxt = segs[i + 1]
    local last = nxt and (nxt.c0 - 1e-3) or sg.t1
    local K = math.max(1, math.floor((last - sg.c0) / sg.L))
    for _, k in ipairs({ 0, 1, K // 2, K - 1, K }) do
      if k >= 0 and sg.c0 + k * sg.L <= last + 1e-3 then
        local c = sg.c0 + k * sg.L
        local b, _, cml = R.TimeMap2_timeToBeats(0, c)
        local e = math.min(b, (cml or sg.q) - b) * 60 / sg.bpm
        worst = math.max(worst, e); nchk = nchk + 1
      end
    end
  end
  -- ce qui compte pour l'utilisateur : le DEBUT DES ITEMS DES LOOPERS (pas des entrees) tombe-t-il sur un premier temps ?
  local istat = { n = 0, med = 0, max = 0, ok = 0, list = {} }
  do
    local devs = {}
    for _, m in ipairs(P.tr) do
      if m.kind == "lp" then
        m.tr = m.tr or R.GetTrack(0, m.n - 1)
        for _, it in ipairs(m.tr and lp_items(m, pos0) or {}) do
          local ip = R.GetMediaItemInfo_Value(it, "D_POSITION")
          local b, meas, cml = R.TimeMap2_timeToBeats(0, ip)
          local bpm_here = R.TimeMap_GetDividedBpmAtTime(ip) or 120
          local signed = (b <= (cml or 4) / 2) and b or (b - (cml or 4))          -- temps avant (-) / apres (+) la barre la plus proche
          local ms = signed * 60 / bpm_here * 1000
          devs[#devs + 1] = math.abs(ms)
          istat.list[#istat.list + 1] = string.format("  piste %d  item a %.4f s  mesure %s  ecart a la barre la plus proche : %+.1f ms", m.n, ip, tostring(meas), ms)
        end
      end
    end
    table.sort(devs)
    istat.n = #devs
    if #devs > 0 then
      istat.med = devs[(#devs + 1) // 2]; istat.max = devs[#devs]
      for _, d in ipairs(devs) do if d <= 30 then istat.ok = istat.ok + 1 end end
    end
  end
  pcall(function()                                                  -- rapport de la grille (pour diagnostic)
    local out = { "Dripsody grille (" .. mode .. ")", string.format("pos0 = %.4f ; zone reconstruite depuis b_a = %.4f s", pos0, b_a), "", "SEGMENTS" }
    for i, sg in ipairs(segs) do
      out[#out + 1] = string.format("  %d  cle=%s  L=%.6f s  N=%d temps  q=%d/4  bpm=%.4f  t0=%.4f  t1=%.4f  T0=%.6f  1er cycle c0=%.6f", i, sg.key, sg.L, sg.N, sg.q, sg.bpm, sg.t0, sg.t1, sg.T0, sg.c0)
    end
    for _, c in ipairs(P.last_corr or {}) do out[#out + 1] = "RECALAGE SUR LES ITEMS : " .. c end
    out[#out + 1] = ""; out[#out + 1] = "MARQUEURS POSES (instant, bpm, signature)"
    for _, x in ipairs(plan) do out[#out + 1] = string.format("  %.6f  %.4f BPM  %d/4", x.t, x.bpm, x.num) end
    out[#out + 1] = ""; out[#out + 1] = "CARTE DE TEMPO RELUE"
    for i = 0, R.CountTempoTimeSigMarkers(0) - 1 do
      local _, tp, mp, bp, bpm, num, den = R.GetTempoTimeSigMarker(0, i)
      out[#out + 1] = string.format("  %d  t=%.6f  mesure=%s temps=%s  %.4f BPM  sig %s/%s", i, tp, tostring(mp), tostring(bp), bpm, tostring(num), tostring(den))
    end
    out[#out + 1] = ""; out[#out + 1] = "DEPARTS DE CYCLE (temps dans la mesure ; 0 = premier temps)"
    for i, sg in ipairs(segs) do
      for k = 0, 4 do
        local c = sg.c0 + k * sg.L
        local b, m, cml = R.TimeMap2_timeToBeats(0, c)
        out[#out + 1] = string.format("  seg %d cycle %d  t=%.6f  mesure=%s  temps=%.5f  (mesure de %s temps)", i, k, c, tostring(m), b, tostring(cml))
      end
    end
    out[#out + 1] = ""; out[#out + 1] = string.format("DEBUT DES ITEMS DE LOOPERS (%d) : ecart median %.1f ms, max %.1f ms, %d a moins de 30 ms d'une barre", istat.n, istat.med, istat.max, istat.ok)
    for i = 1, math.min(60, #istat.list) do out[#out + 1] = istat.list[i] end
    local f = io.open(R.GetResourcePath() .. "/Dripsody_Perf_grid.txt", "w")
    if f then f:write(table.concat(out, "\n")); f:close() end
  end)
  return #plan, worst * 1000, moved, #segs, istat
end
-- bouton : essaie la pose par mesure ; si les departs de cycle ne tombent pas sur un 1er temps (> 2 ms), refait avec la pose par instant
function P.grid_apply()
  local np, worst, moved, nsg, istat = P.grid_build("measure")
  local mode = "mesure"
  if np and worst > 2 then
    np, worst, moved, nsg, istat = P.grid_build("time"); mode = "instant"
  end
  if np then return np, worst, moved, nsg, mode, istat end
  return np, worst
end

-- ============================ regles (appelees ~20 fois par seconde) ============================
-- niveau de sortie de la piste en dB (pic des deux canaux) : sert a laisser finir les queues d'effets (delay, reverb)
function P.level_db(tr)
  local a = math.max(R.Track_GetPeakInfo(tr, 0) or 0, R.Track_GetPeakInfo(tr, 1) or 0)
  return a > 1e-9 and 20 * math.log(a, 10) or -200
end
function P.set_rec(m, want)                                 -- want = cette piste doit ENREGISTRER (sortie) maintenant
  if not m.tr then return end
  local now = R.time_precise()
  local pos = R.GetPlayPosition()
  if want then
    m.tail_t = nil                                          -- redemande pendant la queue : on continue le meme item
    if m.rec then return end
    m.rec = true
    R.SetMediaTrackInfo_Value(m.tr, "I_RECMODE", REC_MODE)
    if m.save.arm < 0.5 then R.SetMediaTrackInfo_Value(m.tr, "I_RECARM", 1) end
    m.iv = { pos }                                          -- debut d'une periode demandee (verifie a l'arret)
  else
    if not m.rec then return end
    -- QUEUE : apres le Clear / la desaffectation, on continue d'enregistrer tant que la piste sonne encore (delay, reverb...) :
    -- au moins TAIL_MIN, au plus tail_s (10 s par defaut), et on s'arrete des que le niveau passe sous tail_db (-60 dB par defaut)
    m.tail_t = m.tail_t or now
    local el = now - m.tail_t
    if el < TAIL_MIN or (el < P.tail_max and P.level_db(m.tr) > P.tail_db) then return end
    m.tail_t, m.rec = nil, false
    if m.save.arm >= 0.5 then R.SetMediaTrackInfo_Value(m.tr, "I_RECMODE", MON_MODE)   -- reste armee : le monitoring continue
    else R.SetMediaTrackInfo_Value(m.tr, "I_RECARM", 0) end
    if m.iv then m.iv[2] = pos; m.ivs[#m.ivs + 1] = m.iv; m.iv = nil end
  end
end
function P.rules()
  local pos = R.GetPlayPosition()
  local nb_arm_in, nb_arm_lp = 0, 0
  local L = {}
  local any_loop, rec_engaged = false, false
  for i = 0, NB_LP - 1 do
    L[i] = P.looper(i)
    if L[i].alive then
      if L[i].any then any_loop = true end
      if L[i].state == 1 or L[i].state == 7 or L[i].state == 8 then rec_engaged = true end
    end
  end
  for _, m in ipairs(P.tr) do
    if m.kind == "in" then
      -- entree armee = affectee a un looper ET sortie vers la piste parent active (B_MAINSEND ; coupee = « in mute » du Launchpad)
      local want = P.input_used(m.idx) and R.GetMediaTrackInfo_Value(m.tr, "B_MAINSEND") >= 0.5
      P.set_rec(m, want); if m.rec then nb_arm_in = nb_arm_in + 1 end
    else
      local l = L[m.idx - 1]
      local want = l.alive and l.len > 0 and l.state ~= 1 and l.state ~= 7 and l.state ~= 8
      P.set_rec(m, want and true or false); if m.rec then nb_arm_lp = nb_arm_lp + 1 end
    end
  end
  P.info.arm_in, P.info.arm_lp = nb_arm_in, nb_arm_lp
  -- morceaux : total clear = plus aucune boucle ; le morceau suivant commence au 1er REC
  if any_loop then P.had_loop = true end
  if P.in_song and P.had_loop and not any_loop then P.in_song = false; P.ev(pos, "total_clear") end
  if not P.in_song and rec_engaged then
    local pp = P.press_pos(); P.open_song(pp); P.ev(pp, "song_start", P.song.name)
  end
  -- synchro : nouveau maitre looper = marqueur de tempo (ajoute seulement)
  local key, bpm, len, mid, mpart = P.master()
  P.clock_sample(pos, key, len, mid, mpart)
  if key ~= P.key then
    local old = P.key; P.key = key
    if key:sub(1, 1) == "L" then
      local ok = P.tempo_marker(pos, bpm)
      P.ev(pos, "sync", string.format("%s bpm=%.3f len=%d marqueur=%s", key, bpm or 0, len or 0, tostring(ok)))
      P.info.tempo = bpm
    elseif key == "none" and old:sub(1, 1) == "L" then P.ev(pos, "sync_off", old) end
  end
end
function P.ev(pos, what, extra) P.events[#P.events + 1] = string.format("%.4f\t%s\t%s", pos, what, extra or "") end

-- ============================ demarrer / arreter ============================
function P.start()
  if P.active or P.starting then return end
  if R.CountTracks(0) < LP_FIRST + NB_LP - 1 then P.msg = "Le projet n'a pas assez de pistes (loopers 11 a 18)."; return end
  for _, m in ipairs(P.tr) do
    m.tr = R.GetTrack(0, m.n - 1)
    if m.tr then
      m.save = { arm = R.GetMediaTrackInfo_Value(m.tr, "I_RECARM"), mode = R.GetMediaTrackInfo_Value(m.tr, "I_RECMODE") }
      m.rec, m.iv, m.ivs = false, nil, {}
      -- piste armee : on la laisse armee (monitoring) et on s'assure qu'elle n'enregistre pas encore (mode 2) ; piste non armee : rien
      if m.save.arm >= 0.5 and m.save.mode ~= MON_MODE then R.SetMediaTrackInfo_Value(m.tr, "I_RECMODE", MON_MODE) end
    end
  end
  P.tail_max = tonumber(R.GetExtState(EXT, "tail_s")) or 10            -- duree maximale de la queue (s)
  P.tail_db = tonumber(R.GetExtState(EXT, "tail_db")) or -60           -- on s'arrete quand la piste passe sous ce niveau (dB)
  P.rep = R.GetSetRepeat(-1); R.GetSetRepeat(0)
  P.songs, P.events, P.song, P.in_song, P.had_loop, P.key, P.segs, P.clk = {}, {}, nil, false, false, "none", {}, nil
  P.t_start = R.time_precise(); P.starting = true; P.msg = ""
  if (R.GetPlayState() & 4) == 0 then R.Main_OnCommand(1013, 0) end     -- Transport : enregistrer
end
function P.begin_active()
  P.active, P.starting = true, false
  P.pos0 = R.GetPlayPosition()
  P.ev(P.pos0, "start")
  R.SetExtState(EXT, "running", "1", false)
  local any = false
  for i = 0, NB_LP - 1 do local l = P.looper(i); if l.alive and l.any then any = true end end
  if any then P.open_song(P.pos0); P.had_loop = true; P.ev(P.pos0, "song_start", "deja des boucles au demarrage") end
end
function P.restore()
  for _, m in ipairs(P.tr) do
    if m.tr and m.save then
      R.SetMediaTrackInfo_Value(m.tr, "I_RECMODE", m.save.mode)
      R.SetMediaTrackInfo_Value(m.tr, "I_RECARM", m.save.arm)       -- etat d'origine : une piste armee reste armee (monitoring)
      if m.iv then m.iv[2] = R.GetPlayPosition(); m.ivs[#m.ivs + 1] = m.iv; m.iv = nil end
      m.rec = nil
    end
  end
  if P.rep then R.GetSetRepeat(P.rep) end
end
function P.stop(external)
  if not (P.active or P.starting) then return end
  local pos = R.GetPlayPosition()
  if P.active then
    P.clock_close(pos)
    P.ev(pos, "stop")
    if P.song and P.song.idx then R.SetProjectMarker3(0, P.song.idx, true, P.song.start, pos, P.song.name, 0); P.song.stop = pos end
    if not external then R.Main_OnCommand(1016, 0) end                  -- Transport : arret
  end
  P.restore()
  P.active, P.starting = false, false
  R.SetExtState(EXT, "running", "0", false)
  P.post_t = R.time_precise() + 1.0                                      -- items finalises par REAPER : reglage de la base de temps apres 1 s
  P.msg = string.format("Enregistrement termine : %d morceau(x).", #P.songs)
end
function P.post()
  local n = 0
  for _, m in ipairs(P.tr) do
    if m.tr then
      for i = 0, R.CountTrackMediaItems(m.tr) - 1 do
        local it = R.GetTrackMediaItem(m.tr, i)
        if R.GetMediaItemInfo_Value(it, "D_POSITION") >= (P.pos0 or 0) - 0.5 then
          R.SetMediaItemInfo_Value(it, "C_BEATATTACHMODE", 0); n = n + 1       -- base de temps : temps (les marqueurs ne deplacent pas l'audio)
        end
      end
    end
  end
  local manquants = {}
  for _, m in ipairs(P.tr) do
    if m.tr then
      for _, iv in ipairs(m.ivs or {}) do
        if (iv[2] or 0) - iv[1] > 1.0 then
          local found = false
          for i = 0, R.CountTrackMediaItems(m.tr) - 1 do
            local it = R.GetTrackMediaItem(m.tr, i)
            local ip = R.GetMediaItemInfo_Value(it, "D_POSITION"); local il = R.GetMediaItemInfo_Value(it, "D_LENGTH")
            if ip < iv[2] and ip + il > iv[1] then found = true break end
          end
          if not found then manquants[#manquants + 1] = string.format("piste %d (%.1f-%.1f s)", m.n, iv[1], iv[2]) end
        end
      end
    end
  end
  local lines = { "Dripsody_Perf v1" }
  for _, t in ipairs(manquants) do lines[#lines + 1] = "MANQUANT\t" .. t end
  for _, s in ipairs(P.songs) do lines[#lines + 1] = string.format("S\t%d\t%.4f\t%.4f", s.n, s.start, s.stop or s.start) end
  for _, sg in ipairs(P.segs) do lines[#lines + 1] = string.format("C\t%s\t%.6f\t%.6f\t%.4f\t%.4f", sg.key, sg.T0, sg.L, sg.t0, sg.t1) end
  for _, e in ipairs(P.events) do lines[#lines + 1] = "E\t" .. e end
  R.SetProjExtState(0, "Dripsody_Perf", "log", table.concat(lines, "\n"))
  pcall(function()                                                  -- copie lisible dans le dossier de REAPER (pour diagnostic)
    local f = io.open(R.GetResourcePath() .. "/Dripsody_Perf_log.txt", "w")
    if f then f:write(table.concat(lines, "\n")); f:close() end
  end)
  R.UpdateArrange()
  P.msg = string.format("Termine : %d morceau(x), %d item(s) regle(s) en base de temps.", #P.songs, n)
  if #manquants > 0 then P.msg = "ATTENTION : rien d'enregistre pour : " .. table.concat(manquants, ", ") end
  P.load_log()
end

-- ============================ fenetre ============================
local function button(x, y, w, h, label, on)
  local hv = gfx.mouse_x >= x and gfx.mouse_x <= x + w and gfx.mouse_y >= y and gfx.mouse_y <= y + h
  if on then gfx.set(.80, .18, .20, 1) else gfx.set(hv and .30 or .22, hv and .32 or .24, hv and .38 or .30, 1) end
  gfx.rect(x, y, w, h, 1)
  gfx.set(1, 1, 1, 1); gfx.setfont(1, "Arial", 17, 'b')
  local tw, th = gfx.measurestr(label); gfx.x, gfx.y = x + (w - tw) / 2, y + (h - th) / 2; gfx.drawstr(label)
  return hv
end
local mdown = false
local function draw()
  gfx.set(.07, .07, .09, 1); gfx.rect(0, 0, gfx.w, gfx.h, 1)
  local running = P.active or P.starting
  local click = (gfx.mouse_cap & 1) == 1 and not mdown
  mdown = (gfx.mouse_cap & 1) == 1
  local hv = button(12, 12, gfx.w - 24, 46, running and (P.starting and "DEMARRAGE..." or "STOP  -  enregistrement en cours") or "REC PERFORMANCE", running)
  if hv and click then if running then P.stop(false) else P.start() end end
  gfx.setfont(2, "Arial", 14)
  local y = 72
  local function line(t, r, gg, b) gfx.set(r or .85, gg or .86, b or .9, 1); gfx.x, gfx.y = 14, y; gfx.drawstr(t); y = y + 20 end
  if P.active then
    local el = R.GetPlayPosition() - (P.pos0 or 0)
    line("Duree : " .. fmt_t(el))
    line("Morceau : " .. (P.info.song or "(en attente du 1er REC)"), .95, .85, .35)
    line(string.format("Entrees enregistrees : %d / %d     Loopers enregistres : %d / %d", P.info.arm_in or 0, NB_IN, P.info.arm_lp or 0, NB_LP))
    if P.info.tempo then line(string.format("Tempo de la synchro : %.2f BPM", P.info.tempo)) end
    local hb = tonumber(R.GetExtState("nowundo_vl", "lp_hb")) or 0
    if R.time_precise() - hb > 3 then line("Launchpad absent : les affectations d'entrees ne sont pas a jour.", 1, .5, .3) end
  else
    line("Pistes gerees : entrees " .. IN_FIRST .. "-" .. (IN_FIRST + NB_IN - 1) .. ", loopers " .. LP_FIRST .. "-" .. (LP_FIRST + NB_LP - 1) .. ".", .6, .62, .7)
    line("Les autres pistes restent a ta charge.", .6, .62, .7)
  end
  if P.msg ~= "" then line(P.msg, 1, .8, .4) end
  -- apres le concert : grille de tempo alignee et saucissonnage (a posteriori, reversibles), hors enregistrement
  if not running then
    if not P.saved then P.load_log() end
    local ns = #P.saved.segs
    gfx.set(.6, .62, .7, 1); gfx.setfont(2, "Arial", 13); gfx.x, gfx.y = 14, gfx.h - 132
    gfx.drawstr(ns > 0 and string.format("Dernier concert : %d morceau(x), %d segment(s) d'horloge.", P.saved.songs, ns) or "Pas de concert enregistre dans ce projet.")
    local bw = (gfx.w - 38) / 2
    local g1 = button(12, gfx.h - 108, bw, 38, "ALIGNER LA GRILLE", false)
    local g2 = button(26 + bw, gfx.h - 108, bw, 38, "ANCIENNE GRILLE", false)
    local h1 = button(12, gfx.h - 58, bw, 38, "DECOUPER PAR CYCLE", false)
    local h2 = button(26 + bw, gfx.h - 58, bw, 38, "RECOLLER", false)
    if click and g1 and ns > 0 then
      local ok, np, worst, moved, nsg, gmode, ist = pcall(P.grid_apply)
      if not ok then P.msg = "Erreur de grille : " .. tostring(np)
      elseif not np then P.msg = tostring(worst)
      else P.msg = string.format("Grille : %d marqueur(s), %d segment(s) ; depart des cycles sur un 1er temps a %.2f ms pres%s.%s Ctrl+Z annule.", np, nsg, worst, worst > 2 and " (ATTENTION : mal aligne, essaie ANCIENNE GRILLE)" or "", moved > 0 and (" " .. moved .. " element(s) remis en place.") or "")
        if P.last_corr and #P.last_corr > 0 then P.msg = P.msg .. "  Grille recalee sur le debut des items (" .. table.concat(P.last_corr, ", ") .. ")." end
        if ist and ist.n > 0 then P.msg = P.msg .. string.format("  ITEMS DE LOOPERS : %d, ecart median %.0f ms, max %.0f ms au 1er temps le plus proche.", ist.n, ist.med, ist.max) end
      end
    elseif click and g2 then
      local ok, done = pcall(P.grid_restore)
      P.msg = ok and (done and "Ancienne grille de tempo restauree." or "Pas de grille sauvegardee a restaurer.") or ("Erreur : " .. tostring(done))
    elseif click and h1 and ns > 0 then
      local ok, ni, nc = pcall(P.split_items)
      P.msg = ok and string.format("Decoupe : %d item(s) parcourus, %d coupe(s). Ctrl+Z annule.", ni, nc) or ("Erreur de decoupe : " .. tostring(ni))
    elseif click and h2 then
      local ok, nj, nk = pcall(P.join_items)
      P.msg = ok and string.format("Recolle : %d morceau(x)%s.", nj, nk > 0 and (", " .. nk .. " non recollable(s) (deplaces ou modifies)") or "") or ("Erreur de recollage : " .. tostring(nj))
    end
  end
end

-- ============================ boucle principale ============================
local function main()
  local ch = gfx.getchar()
  local now = R.time_precise()
  R.SetExtState(EXT, "hb", string.format("%.3f", now), false)
  -- commande externe (relance du script = bascule)
  if R.GetExtState(EXT, "cmd") == "toggle" then
    R.SetExtState(EXT, "cmd", "", false)
    if P.active or P.starting then P.stop(false) else P.start() end
  end
  local ps = R.GetPlayState()
  if P.starting then
    if (ps & 4) == 4 then P.begin_active()
    elseif now - P.t_start > 2.0 then P.starting = false; P.restore(); P.msg = "L'enregistrement n'a pas demarre."; end
  elseif P.active then
    if (ps & 4) == 0 then P.stop(true)                                  -- arret par REAPER (barre espace...) : on termine proprement
    else
      -- pcall : une erreur ne doit jamais couper la logique en plein concert (elle est affichee dans la fenetre)
      if now - P.t_rule >= 0.05 then P.t_rule = now; local ok, e = pcall(P.rules); if not ok then P.msg = "Erreur : " .. tostring(e) end end
      if now - P.t_region >= 0.25 then P.t_region = now; local ok, e = pcall(P.grow_region, R.GetPlayPosition()); if not ok then P.msg = "Erreur : " .. tostring(e) end end
    end
  end
  if P.post_t and now >= P.post_t then P.post_t = nil; local ok, e = pcall(P.post); if not ok then P.msg = "Erreur a l'ecriture du journal : " .. tostring(e) end end
  if ch >= 0 then draw() end
  gfx.update()
  if ch < 0 and not (P.active or P.starting or P.post_t) then return end   -- fenetre fermee hors enregistrement : fin du script
  R.defer(main)
end

-- instance unique : une 2e instance bascule la 1re et se termine
do
  local hb = tonumber(R.GetExtState(EXT, "hb")) or 0
  if R.time_precise() - hb < 1.0 then R.SetExtState(EXT, "cmd", "toggle", false); return end
end
R.atexit(function() if P.active or P.starting then P.restore(); R.SetExtState(EXT, "running", "0", false) end end)
gfx.init("Dripsody Performance", 440, 350, 0, 140, 140)
R.defer(main)
if rawget(_G, "DRIPSODY_PERF_TEST") then DRIPSODY_PERF = P end
