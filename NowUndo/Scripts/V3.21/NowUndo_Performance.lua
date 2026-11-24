-- @noindex
--[[
  NowUndo_Performance.lua  -  « Dripsody Performance » : enregistrement d'un CONCERT entier dans REAPER (etape 1).

  Un seul enregistrement continu. Le script ne gere QUE les entrees (pistes 2 a 9) et les loopers (pistes 11 a 18) ;
  les autres pistes (instruments, effets...) restent a ta charge : si tu les armes, elles sont enregistrees avec le reste.

  - ENTREE k : armee en « Record : output » des qu'elle est affectee a au moins un looper (masques publies par le
    Launchpad, gmem 6010 + i), desarmee quand elle ne l'est plus.
  - LOOPER i : arme des que son enregistrement est abouti (boucle > 0, plus en REC / attente), desarme au Clear.
    Une periode armee = un item.
  - MORCEAUX : un morceau commence au 1er REC alors que TOUS les loopers sont vides (3 parts comprises) ; sa region
    va jusqu'au 1er REC du morceau suivant (la derniere jusqu'a l'arret). Region creee au debut puis agrandie en direct.
  - TEMPO : a chaque nouvelle synchro (nouveau maitre looper) un marqueur de tempo est AJOUTE a la position de lecture.
    Jamais de SetCurrentBPM ni de modification d'un tempo deja pose pendant la lecture (la tete de lecture sauterait,
    essai du 24 nov.). L'alignement des mesures sur les boucles se fera apres l'arret (etape 2).
  - Au demarrage : repetition coupee. A l'arret : etats d'armement / modes d'enregistrement des pistes geree restaures,
    items regles en base de temps « temps ». Les evenements sont gardes dans l'ExtState du projet (« Dripsody_Perf »).

  Lancer le script = ouvre la fenetre ; relancer pendant un concert = bascule (demarrer / arreter) sans ouvrir de 2e fenetre.
]]
local R = reaper
local EXT = "NowUndo_Perf"
local GMEM = "nowundo_sync"
local IN_FIRST, NB_IN, LP_FIRST, NB_LP = 2, 8, 11, 8     -- numeros de pistes (1 = premiere), comme le Launchpad / le Twister
local REC_MODE = 3                                        -- 3 = sortie stereo avec compensation de latence
local DASH = 6000                                          -- tableau de bord du Launchpad : [DASH+10+i] = entrees qui alimentent le looper i

local P = { active = false, starting = false, tr = {}, songs = {}, events = {}, song = nil, in_song = false, had_loop = false,
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
        return string.format("L%d:%d:%d", p, id, math.floor(len + .5)), bpm, len, id
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

-- ============================ regles (appelees ~20 fois par seconde) ============================
function P.arm(m, want)
  if not m.tr or m.armed == want then return end
  R.SetMediaTrackInfo_Value(m.tr, "I_RECARM", want and 1 or 0)
  m.armed = want
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
      local want = P.input_used(m.idx)
      P.arm(m, want); if m.armed then nb_arm_in = nb_arm_in + 1 end
    else
      local l = L[m.idx - 1]
      local want = l.alive and l.len > 0 and l.state ~= 1 and l.state ~= 7 and l.state ~= 8
      P.arm(m, want and true or false); if m.armed then nb_arm_lp = nb_arm_lp + 1 end
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
  local key, bpm, len = P.master()
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
      R.SetMediaTrackInfo_Value(m.tr, "I_RECMODE", REC_MODE)
      R.SetMediaTrackInfo_Value(m.tr, "I_RECARM", 0)
      m.armed = false
    end
  end
  P.rep = R.GetSetRepeat(-1); R.GetSetRepeat(0)
  P.songs, P.events, P.song, P.in_song, P.had_loop, P.key = {}, {}, nil, false, false, "none"
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
      R.SetMediaTrackInfo_Value(m.tr, "I_RECARM", 0)
      R.SetMediaTrackInfo_Value(m.tr, "I_RECMODE", m.save.mode)
      R.SetMediaTrackInfo_Value(m.tr, "I_RECARM", m.save.arm)
      m.armed = nil
    end
  end
  if P.rep then R.GetSetRepeat(P.rep) end
end
function P.stop(external)
  if not (P.active or P.starting) then return end
  local pos = R.GetPlayPosition()
  if P.active then
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
  local lines = { "Dripsody_Perf v1" }
  for _, s in ipairs(P.songs) do lines[#lines + 1] = string.format("S\t%d\t%.4f\t%.4f", s.n, s.start, s.stop or s.start) end
  for _, e in ipairs(P.events) do lines[#lines + 1] = "E\t" .. e end
  R.SetProjExtState(0, "Dripsody_Perf", "log", table.concat(lines, "\n"))
  R.UpdateArrange()
  P.msg = string.format("Termine : %d morceau(x), %d item(s) regle(s) en base de temps.", #P.songs, n)
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
    line(string.format("Entrees armees : %d / %d     Loopers armes : %d / %d", P.info.arm_in or 0, NB_IN, P.info.arm_lp or 0, NB_LP))
    if P.info.tempo then line(string.format("Tempo de la synchro : %.2f BPM", P.info.tempo)) end
    local hb = tonumber(R.GetExtState("nowundo_vl", "lp_hb")) or 0
    if R.time_precise() - hb > 3 then line("Launchpad absent : les affectations d'entrees ne sont pas a jour.", 1, .5, .3) end
  else
    line("Pistes gerees : entrees " .. IN_FIRST .. "-" .. (IN_FIRST + NB_IN - 1) .. ", loopers " .. LP_FIRST .. "-" .. (LP_FIRST + NB_LP - 1) .. ".", .6, .62, .7)
    line("Les autres pistes restent a ta charge.", .6, .62, .7)
  end
  if P.msg ~= "" then line(P.msg, 1, .8, .4) end
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
gfx.init("Dripsody Performance", 420, 200, 0, 140, 140)
R.defer(main)
