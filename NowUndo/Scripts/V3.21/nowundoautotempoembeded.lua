-- NowUndo - Auto Tempo Sync (Background Script + UI)
-- v6 (21 nov. 2026) : AUTO-SYNC seul. Le MSV3 (Master Sync) est le SEUL a gerer la synchro : ce script n'ecrit plus la
--   longueur / position des parts Host (il les reecrivait ~30 fois/s avec la position ENTENDUE, en concurrence avec le MSV3
--   qui les ecrit a chaque bloc audio -> la position sautait entre deux valeurs) ; plus de colonne MAIN / CHORUS / BRIDGE
--   (doublon du MSV3) ni de recherche du JSFX par nom ; choix des temps par menu au lieu de - / +.
-- CORRIGÉ v3 : Host 100% gmem-driven (longueur + phase calculées côté Lua)
-- v5 : demarrage cale sur la phase du looper maitre ; get_beats_per_measure corrige
-- v4 : srate réel (looper/carte son), loop_beats lu au bon endroit (gmem[4] = cycles), estimation de beats revue
reaper.gmem_attach("nowundo_sync")

local was_locked = false
local last_id = -1
local tempo_applied = false
local last_applied_bpm = 0
local last_applied_len = 0
local last_applied_beats = 0
local last_len = 0
local last_msg = "En attente..."
local last_msg_t = 0
local ui_force_beats = 0
local BEAT_CANDIDATES = {1, 2, 3, 4, 5, 6, 7, 8, 12, 16, 24, 32, 48, 64}

-- v4 : fréquence réellement utilisée = celle du looper maître (JSFX), sinon carte son, sinon projet
local function get_srate()
  local idx = reaper.gmem_read(910)
  if idx and idx >= 0 then
    local base = 1000 + math.floor(idx + 0.5) * 600
    local part = math.max(1, math.floor(reaper.gmem_read(base + 42) + 0.5))
    local sr = reaper.gmem_read(base + (part - 1) * 200 + 186)
    if sr and sr > 8000 then return sr end
  end
  if reaper.GetAudioDeviceInfo then
    local ok, s = reaper.GetAudioDeviceInfo("SRATE", "")
    local n = ok and tonumber(s) or nil
    if n and n > 8000 then return n end
  end
  local sr = reaper.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
  if sr and sr > 8000 then return sr end
  return 48000
end

-- v4 : loop_beats réellement réglé sur le looper maître (0 = Auto). gmem[4] est le compteur de cycles, PAS loop_beats.
local function read_loop_beats()
  local idx = reaper.gmem_read(910)
  if idx and idx >= 0 then
    local base = 1000 + math.floor(idx + 0.5) * 600
    local part = math.max(1, math.floor(reaper.gmem_read(base + 42) + 0.5))
    return reaper.gmem_read(base + (part - 1) * 200 + 31) or 0
  end
  return 0
end

-- ===== NowUndo : persistance du dock / position (ajout) =====
NDDOCK = {}
function NDDOCK.init(title, ext, dw, dh)
  local function ld(k, d) return tonumber(reaper.GetExtState(ext, k)) or d end
  NDDOCK.ext, NDDOCK.last_t, NDDOCK.sig = ext, 0, ""
  local w, h = ld("w", dw), ld("h", dh)
  if w < 100 then w = dw end
  if h < 60 then h = dh end
  gfx.init(title, w, h, ld("dock", 0), ld("x", 100), ld("y", 100))
end
function NDDOCK.tick()
  local t = reaper.time_precise()
  if t - NDDOCK.last_t < 1 then return end
  NDDOCK.last_t = t
  local d, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
  d = math.floor(d or 0)
  local sig = d .. "," .. x .. "," .. y .. "," .. w .. "," .. h
  if sig == NDDOCK.sig then return end
  NDDOCK.sig = sig
  local e = NDDOCK.ext
  reaper.SetExtState(e, "dock", tostring(d), true)
  if d & 1 == 0 then   -- flottante : on retient position + taille
    reaper.SetExtState(e, "x", tostring(math.floor(x)), true)
    reaper.SetExtState(e, "y", tostring(math.floor(y)), true)
    reaper.SetExtState(e, "w", tostring(math.floor(w)), true)
    reaper.SetExtState(e, "h", tostring(math.floor(h)), true)
  end
end
-- ===== fin ajout =====

local WIN_W, WIN_H = 300, 300
NDDOCK.init("NowUndo Auto-Tempo Sync", "NowUndo_Sync", WIN_W, WIN_H)

local function set_msg(s)
  last_msg = s
  last_msg_t = reaper.time_precise()
end

local function play_state_str()
  local ps = reaper.GetPlayState()
  if ps & 4 == 4 then return "RECORD", 0.9, 0.2, 0.2 end
  if ps & 2 == 2 then return "PAUSE", 0.9, 0.7, 0.2 end
  if ps & 1 == 1 then return "PLAY", 0.2, 0.85, 0.3 end
  return "STOP", 0.6, 0.6, 0.65
end

local function get_beats_per_measure()
  -- TimeMap_GetTimeSigAtTime renvoie (numérateur, dénominateur, tempo) : le 1er retour est le nombre de temps
  local num = reaper.TimeMap_GetTimeSigAtTime(0, reaper.GetPlayPosition())
  if num and num >= 1 then return math.floor(num + 0.5) end
  return 4
end

local function score_candidate(beats, bpm, current_bpm, min_beats)
  if beats < min_beats then return 1e9 end
  -- v4 : distance (en octaves) à 112 BPM + pénalités de "non-musicalité" + léger rappel du tempo courant
  local s = 3 * math.abs(math.log(bpm / 112.0) / math.log(2))
  local k = beats / min_beats
  if k ~= math.floor(k) then
    s = s + 4                                        -- pas un nombre entier de mesures
  else
    local kk = math.floor(k)
    if (kk & (kk - 1)) ~= 0 then s = s + 1.5 end     -- 3, 5, 6, 7... mesures : possible mais moins probable
  end
  if current_bpm >= 50 and current_bpm <= 220 then
    s = s + 0.5 * math.abs(math.log(bpm / current_bpm) / math.log(2))
  end
  return s
end

local function choose_beats_and_bpm(dur_sec, loop_beats_hint, current_bpm, min_beats)
  if dur_sec <= 0.001 then return 0, 0 end
  if min_beats < 1 then min_beats = 4 end
  if ui_force_beats and ui_force_beats >= 1 then
    local beats = math.floor(ui_force_beats + 0.5)
    if beats < min_beats then beats = min_beats end
    return beats, beats / dur_sec * 60.0
  end
  if loop_beats_hint and loop_beats_hint >= 1 then
    local beats = math.floor(loop_beats_hint + 0.5)
    if beats < min_beats then beats = min_beats end
    return beats, beats / dur_sec * 60.0
  end
  local best_beats, best_bpm, best_score = 0, 0, 1e18
  for _, beats in ipairs(BEAT_CANDIDATES) do
    if beats >= min_beats then
      local bpm = beats / dur_sec * 60.0
      local sc = score_candidate(beats, bpm, current_bpm, min_beats)
      if sc < best_score then
        best_score = sc
        best_beats = beats
        best_bpm = bpm
      end
    end
  end
  if best_beats == 0 then
    best_beats = min_beats
    best_bpm = best_beats / dur_sec * 60.0
  end
  return best_beats, best_bpm
end

local function top_candidates(dur_sec, current_bpm, min_beats)
  local list = {}
  if dur_sec <= 0.001 then return list end
  for _, beats in ipairs(BEAT_CANDIDATES) do
    if beats >= min_beats then
      local bpm = beats / dur_sec * 60.0
      if bpm >= 30 and bpm <= 600 then
        list[#list + 1] = { beats = beats, bpm = bpm, score = score_candidate(beats, bpm, current_bpm, min_beats) }
      end
    end
  end
  table.sort(list, function(a, b) return a.score < b.score end)
  local top = {}
  for i = 1, math.min(3, #list) do top[i] = list[i] end
  return top
end

local function hit_test(mx, my, x, y, w, h)
  return mx >= x and mx < x + w and my >= y and my < y + h
end

local last_mouse_cap = 0

-- menu des temps : Auto + tous les candidats (>= 1 mesure) avec le tempo qu'ils donnent
local function beats_menu(x, y, dur_s, min_beats)
  local items, vals = { (ui_force_beats == 0 and "!" or "") .. "Auto (le plus probable)" }, { 0 }
  items[2] = ""
  for _, b in ipairs(BEAT_CANDIDATES) do
    if b >= min_beats then
      local bpm = dur_s > 0 and (b / dur_s * 60.0) or 0
      local lbl = string.format("%d temps (%s mes.)%s", b, (b % min_beats == 0) and tostring(b // min_beats) or string.format("%.1f", b / min_beats),
        bpm > 0 and string.format("  =  %.1f BPM", bpm) or "")
      items[#items + 1] = (ui_force_beats == b and "!" or "") .. lbl
      vals[#items - 1] = b
    end
  end
  gfx.x, gfx.y = x, y
  local k = gfx.showmenu(table.concat(items, "|"))
  if k > 0 and vals[k] then ui_force_beats = vals[k]; tempo_applied = false end
end

local function draw_ui()
  local char = gfx.getchar()
  if char == 27 or char < 0 then gfx.quit(); return false end
  NDDOCK.tick()

  local mouse_cap = gfx.mouse_cap
  local mouse_click = (mouse_cap & 1 == 1) and (last_mouse_cap & 1 == 0)
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local w, h = gfx.w, gfx.h
  local armed = reaper.gmem_read(95)
  local g2 = reaper.gmem_read(2)
  local g4 = read_loop_beats()
  local tempo = reaper.Master_GetTempo()
  local ps_lbl, pr, pg, pb = play_state_str()
  local srate = get_srate()
  local dur_s = (g2 > 0) and (g2 / srate) or 0
  local min_beats = get_beats_per_measure()
  local prev_beats, prev_bpm = 0, 0
  if dur_s > 0 then prev_beats, prev_bpm = choose_beats_and_bpm(dur_s, g4, tempo, min_beats) end
  local cands = top_candidates(dur_s, tempo, min_beats)

  gfx.set(0.12, 0.10, 0.12); gfx.rect(0, 0, w, h, 1)
  gfx.setfont(2, "Arial", 16, "b"); gfx.set(0.95, 0.85, 0.3)
  gfx.x, gfx.y = 12, 8; gfx.drawstr("NOWUNDO AUTO-TEMPO")

  local function draw_btn(x, y, bw, bh, label, active, r, g, b)
    local hov = hit_test(mx, my, x, y, bw, bh)
    if active then gfx.set(r or 0.25, g or 0.55, b or 0.35)
    elseif hov then gfx.set(0.35, 0.28, 0.32)
    else gfx.set(0.22, 0.18, 0.20) end
    gfx.rect(x, y, bw, bh, 1)
    gfx.set(0.4, 0.35, 0.38); gfx.rect(x, y, bw, bh, 0)
    gfx.setfont(1, "Arial", 12, "b"); gfx.set(0.95, 0.9, 0.85)
    local tw = gfx.measurestr(label)
    gfx.x = x + (bw - tw) * 0.5; gfx.y = y + (bh - 12) * 0.5
    gfx.drawstr(label)
    return hov and mouse_click
  end

  -- AUTO-SYNC (meme interrupteur que dans le MSV3, gmem 95) : action principale, en haut
  local bw = w - 24
  if draw_btn(12, 34, bw, 26, armed == 1 and "AUTO-SYNC : ON" or "AUTO-SYNC : OFF", armed == 1, 0.2, 0.6, 0.2) then
    reaper.gmem_write(95, 1 - armed)
  end
  gfx.setfont(1, "Arial", 11); gfx.set(0.55, 0.5, 0.55)
  gfx.x, gfx.y = 12, 64
  gfx.drawstr("1er looper maitre -> tempo de REAPER + PLAY ; Unlock -> STOP")

  -- boucle maitre
  gfx.setfont(1, "Arial", 12)
  gfx.x, gfx.y = 12, 88
  if g2 > 0 then gfx.set(0.85, 0.8, 0.75); gfx.drawstr(string.format("Boucle maitre : %.3f s", dur_s))
  else gfx.set(0.6, 0.45, 0.45); gfx.drawstr("Boucle maitre : aucune") end

  -- TEMPS DE LA BOUCLE : Auto | 1, 2, 4 mesures | autre (menu)
  gfx.setfont(1, "Arial", 10, "b"); gfx.set(1, 1, 1, 0.45)
  gfx.x, gfx.y = 12, 110; gfx.drawstr("TEMPS DE LA BOUCLE")
  local b1, b2, b4 = min_beats, min_beats * 2, min_beats * 4
  local cw = math.floor((bw - 4 * 4) / 5)
  local function cx(k) return 12 + (k - 1) * (cw + 4) end
  if draw_btn(cx(1), 124, cw, 22, "Auto", ui_force_beats == 0) then ui_force_beats = 0; tempo_applied = false end
  if draw_btn(cx(2), 124, cw, 22, tostring(b1), ui_force_beats == b1) then ui_force_beats = b1; tempo_applied = false end
  if draw_btn(cx(3), 124, cw, 22, tostring(b2), ui_force_beats == b2) then ui_force_beats = b2; tempo_applied = false end
  if b4 <= 64 and draw_btn(cx(4), 124, cw, 22, tostring(b4), ui_force_beats == b4) then ui_force_beats = b4; tempo_applied = false end
  local other = ui_force_beats >= 1 and ui_force_beats ~= b1 and ui_force_beats ~= b2 and ui_force_beats ~= b4
  if draw_btn(cx(5), 124, cw, 22, other and (ui_force_beats .. " v") or "... v", other) then beats_menu(cx(5), 146, dur_s, min_beats) end

  gfx.setfont(1, "Arial", 12); gfx.set(0.85, 0.8, 0.75)
  gfx.x, gfx.y = 12, 152
  local lb_looper = math.floor((g4 or 0) + 0.5)
  if ui_force_beats >= 1 then gfx.drawstr(string.format("Temps forces ici : %d", ui_force_beats))
  elseif lb_looper >= 1 then gfx.drawstr(string.format("Temps forces par le looper : %d", lb_looper))
  else gfx.drawstr("Temps : Auto (>= 1 mesure)") end

  gfx.setfont(1, "Arial", 13); gfx.x, gfx.y = 12, 174
  if prev_beats > 0 then
    gfx.set(0.7, 0.85, 0.95); gfx.drawstr(string.format("Choix : %d temps (%.1f mes.)", prev_beats, prev_beats / min_beats))
    gfx.x, gfx.y = 12, 192; gfx.set(0.95, 0.9, 0.4); gfx.drawstr(string.format("-> %.2f BPM", prev_bpm))
  else gfx.set(0.7, 0.85, 0.95); gfx.drawstr("Choix : --") end
  gfx.setfont(1, "Arial", 11); gfx.x, gfx.y = 12, 212; gfx.set(0.55, 0.5, 0.55)
  if #cands > 0 then
    local parts = {}
    for _, c in ipairs(cands) do parts[#parts + 1] = string.format("%d=%.0f", c.beats, c.bpm) end
    gfx.drawstr("Autres : " .. table.concat(parts, " | "))
  end

  gfx.setfont(1, "Arial", 13, "b"); gfx.x, gfx.y = 12, 236; gfx.set(0.95, 0.9, 0.4)
  gfx.drawstr(string.format("Tempo REAPER : %.2f", tempo))
  gfx.x = gfx.x + 12; gfx.set(pr, pg, pb); gfx.drawstr(ps_lbl)
  gfx.setfont(1, "Arial", 12); gfx.set(0.55, 0.5, 0.55); gfx.x, gfx.y = 12, 258
  gfx.drawstr(last_applied_bpm > 0 and string.format("Applique : %.2f BPM", last_applied_bpm) or "Applique : --")
  gfx.x, gfx.y = 12, 278
  local age = reaper.time_precise() - last_msg_t
  local a = (age < 2.0) and 1.0 or math.max(0.45, 1.0 - (age - 2.0) * 0.15)
  gfx.set(0.7 * a, 0.85 * a, 0.95 * a); gfx.drawstr(last_msg)

  last_mouse_cap = mouse_cap
  gfx.update()
  return true
end

-- v5 : compensation de latence au démarrage (ms). Positif = le début de boucle arrive en RETARD sur la mesure REAPER
-- (on avance alors le point de départ). À régler une fois à l'oreille / au clic si besoin ; 0 par défaut.
local START_COMP_MS = 0.0

-- Cale le curseur d'édition (point de départ de la lecture) pour que la position du looper maître dans sa boucle
-- corresponde à la grille REAPER : début de boucle <-> début de mesure. N'agit que si la lecture est arrêtée
-- (on ne touche JAMAIS à une lecture en cours) et si la boucle fait un nombre entier de mesures.
local function align_cursor_to_loop(bpm, beats, min_beats, srate)
  if min_beats < 1 or beats % min_beats ~= 0 then return false end
  local len  = reaper.gmem_read(2)           -- longueur de la boucle maître (échantillons)
  local mpos = reaper.gmem_read(3)           -- position courante de son horloge (échantillons)
  if not len or not mpos or len <= 0 or mpos < 0 or mpos >= len then return false end
  local off_qn = (mpos / srate + START_COMP_MS / 1000.0) * bpm / 60.0
  local _, meas = reaper.TimeMap2_timeToBeats(0, reaper.GetCursorPosition())
  local _, qn0 = reaper.TimeMap_GetMeasureInfo(0, meas)
  if not qn0 then return false end
  reaper.SetEditCurPos(reaper.TimeMap_QNToTime(qn0 + off_qn), true, false)
  return true
end

local function apply_tempo_and_play(g1, g2, g4)
  local srate = get_srate()
  local dur = g2 / srate
  if dur <= 0 then return false end

  local bpm = reaper.Master_GetTempo()
  local min_beats = get_beats_per_measure()
  local beats, new_bpm = choose_beats_and_bpm(dur, g4, bpm, min_beats)

  if math.abs(new_bpm - bpm) > 0.01 then
    reaper.SetCurrentBPM(0, new_bpm, true)
    set_msg(string.format("Tempo -> %.2f BPM (%d beats)", new_bpm, beats))
  else
    set_msg(string.format("Tempo deja OK (%.2f)", bpm))
  end

  if reaper.GetPlayState() == 0 then
    local aligned = align_cursor_to_loop(new_bpm, beats, min_beats, srate)
    reaper.CSurf_OnPlay()
    set_msg((last_msg or "") .. " + PLAY" .. (aligned and " (cale sur la boucle)" or ""))
  end

  last_applied_bpm = new_bpm
  last_applied_len = g2
  last_applied_beats = beats
  last_id = g1
  last_len = g2
  tempo_applied = true
  return true
end

function loop()
  if not draw_ui() then return end

  local armed = reaper.gmem_read(95)
  local g0 = reaper.gmem_read(0)
  local g1 = reaper.gmem_read(1)
  local g2 = reaper.gmem_read(2)
  local g4 = read_loop_beats()

  local is_locked = (g0 == 1 and g1 > 0)

  if armed == 1 and is_locked then
    local need_apply = (not was_locked) or (g1 ~= last_id) or (g2 ~= last_len) or (not tempo_applied)
    if need_apply and g2 > 0 then
      apply_tempo_and_play(g1, g2, g4)
    elseif need_apply and g2 <= 0 then
      set_msg("Lock OK mais longueur=0...")
    end
  end

  if armed == 1 and was_locked and not is_locked then
    if reaper.GetPlayState() ~= 0 then
      reaper.CSurf_OnStop()
      set_msg("Unlock -> STOP")
    else
      set_msg("Unlock (deja stop)")
    end
    tempo_applied = false
  end

  if not is_locked then
    last_id = -1
    tempo_applied = false
  end
  was_locked = is_locked

  reaper.defer(loop)
end

set_msg("Pret (la synchro est geree par le MSV3)")
loop()
