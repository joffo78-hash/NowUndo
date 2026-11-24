-- @noindex
-- Dripsody_PerfSpike.lua : ESSAI (jetable) pour l'enregistrement de performance.
-- A lancer dans un PROJET VIDE (Ctrl+N), sans rien d'autre. Dure environ 12 secondes, joue un petit son (440 Hz, faible).
-- Il verifie ce qu'on suppose pour la future fonction « REC PERFORMANCE » :
--   1) armer une piste PENDANT l'enregistrement : un item commence-t-il bien a cet instant ?
--   2) desarmer puis rearmer : un item par periode armee ?
--   3) mode « Record : output » (I_RECMODE) accepte, items places a quelle precision ?
--   4) marqueur de tempo + signature pose en plein enregistrement : tombe-t-il sur un 1er temps ? les items bougent-ils ?
--   5) SetCurrentBPM avec un marqueur existant : que devient la carte de tempo ?
--   6) region creee pendant l'enregistrement et agrandie en continu.
-- Resultat : fenetre + fichier Dripsody_Spike_Report.txt (dossier de REAPER). Les pistes temporaires restent dans le projet vide.

local R = reaper
local LOG = {}
local function log(fmt, ...) LOG[#LOG + 1] = string.format(fmt, ...) end

if R.CountTracks(0) > 0 then
  R.ShowMessageBox("Lance cet essai dans un PROJET VIDE (Ctrl+N) : ce projet contient deja des pistes.", "Dripsody essai", 0)
  return
end

-- petit generateur de son (fichier JSFX ecrit a la volee)
local res = R.GetResourcePath()
local tone = res .. "/Effects/Dripsody_Spike_Tone.jsfx"
do
  local f = io.open(tone, "w")
  if not f then R.ShowMessageBox("Impossible d'ecrire " .. tone, "Dripsody essai", 0); return end
  f:write("desc:Dripsody spike tone\n@init\nph = 0;\n@sample\nspl0 = spl1 = 0.5 * sin(ph); ph += 2 * $pi * 440 / srate;\n")
  f:close()
end

local function new_track(name)
  local n = R.CountTracks(0)
  R.InsertTrackAtIndex(n, true)
  local tr = R.GetTrack(0, n)
  R.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  R.SetMediaTrackInfo_Value(tr, "D_VOL", 0.1)
  local fx = R.TrackFX_AddByName(tr, "JS:Dripsody_Spike_Tone", false, -1)
  if fx < 0 then fx = R.TrackFX_AddByName(tr, "Dripsody spike tone", false, -1) end
  R.SetMediaTrackInfo_Value(tr, "I_RECMODE", 3)            -- 3 = sortie stereo avec compensation de latence
  log("piste %s : effet ajoute = %s ; I_RECMODE relu = %s", name, tostring(fx >= 0), tostring(R.GetMediaTrackInfo_Value(tr, "I_RECMODE")))
  return tr
end
local A, B = new_track("SPIKE A"), new_track("SPIKE B")

local bpm0 = R.Master_GetTempo()
log("tempo de depart : %.3f BPM ; items : base de temps par defaut non lisible ici (voir C_BEATATTACHMODE plus bas)", bpm0)

local EV = {}                                    -- instants reels (position de lecture du projet) de chaque action
local function now_pos() return R.GetPlayPosition() end
local rgn_idx
local STEP = 0
local t0
local STEPS = {
  { 1.0,  function() rgn_idx = R.AddProjectMarker2(0, true, now_pos(), now_pos() + 1, "Spike morceau 1", -1, 0); EV.rgn = now_pos() end, "region creee" },
  { 3.0,  function() R.SetMediaTrackInfo_Value(B, "I_RECARM", 1); EV.armB = now_pos() end, "B armee EN COURS d'enregistrement" },
  { 5.0,  function()
      local p = now_pos(); EV.mk = p
      local ok = R.SetTempoTimeSigMarker(0, -1, p, -1, -1, 100, 5, 4, false)    -- 100 BPM, 5/4, a la position courante
      log("marqueur de tempo pose a %.3f s (ok=%s)", p, tostring(ok))
      EV.mk_ok = ok
    end, "marqueur de tempo + signature 5/4" },
  { 6.5,  function()
      local n = R.CountTempoTimeSigMarkers(0)
      for i = 0, n - 1 do
        local _, tp, mp, bp, bpm, ns, nd, lin = R.GetTempoTimeSigMarker(0, i)
        log("  avant SetCurrentBPM : marqueur %d : t=%.3f mesure=%s temps=%.3f bpm=%.3f sig=%s/%s", i, tp, tostring(mp), bp, bpm, tostring(ns), tostring(nd))
      end
      R.SetCurrentBPM(0, 90, false)
      for i = 0, R.CountTempoTimeSigMarkers(0) - 1 do
        local _, tp, mp, bp, bpm, ns, nd = R.GetTempoTimeSigMarker(0, i)
        log("  apres SetCurrentBPM(90) : marqueur %d : t=%.3f bpm=%.3f sig=%s/%s", i, tp, bpm, tostring(ns), tostring(nd))
      end
      log("  Master_GetTempo apres = %.3f", R.Master_GetTempo())
    end, "SetCurrentBPM(90) avec un marqueur existant" },
  { 7.0,  function() R.SetMediaTrackInfo_Value(A, "I_RECARM", 0); EV.disA = now_pos() end, "A desarmee" },
  { 8.5,  function() R.SetMediaTrackInfo_Value(A, "I_RECARM", 1); EV.armA2 = now_pos() end, "A rearmee" },
  { 11.0, function() EV.stop = now_pos(); R.Main_OnCommand(1016, 0) end, "arret" },
}

local function report()
  local function items_of(tr, name)
    log("-- %s : %d item(s)", name, R.CountTrackMediaItems(tr))
    for i = 0, R.CountTrackMediaItems(tr) - 1 do
      local it = R.GetTrackMediaItem(tr, i)
      local take = R.GetActiveTake(it)
      local src = take and R.GetMediaItemTake_Source(take)
      local fn = src and R.GetMediaSourceFileName(src, "") or "?"
      log("   item %d : debut %.4f s, longueur %.4f s, C_BEATATTACHMODE=%s, fichier=%s", i + 1,
        R.GetMediaItemInfo_Value(it, "D_POSITION"), R.GetMediaItemInfo_Value(it, "D_LENGTH"),
        tostring(R.GetMediaItemInfo_Value(it, "C_BEATATTACHMODE")), (fn:match("[^/\\]+$") or fn))
    end
  end
  log("")
  log("instants reels des actions (position du projet) : A armee %.3f | region %.3f | B armee %.3f | marqueur %.3f | A desarmee %.3f | A rearmee %.3f | arret %.3f",
    EV.armA1 or -1, EV.rgn or -1, EV.armB or -1, EV.mk or -1, EV.disA or -1, EV.armA2 or -1, EV.stop or -1)
  items_of(A, "SPIKE A (attendu : 2 items, ~0 -> ~7 et ~8.5 -> arret)")
  items_of(B, "SPIKE B (attendu : 1 item, ~3 -> arret)")
  -- le marqueur est-il sur un 1er temps ?
  if EV.mk then
    local beats_in_measure, measure, cml = R.TimeMap2_timeToBeats(0, EV.mk)
    log("")
    log("au marqueur : temps dans la mesure = %.4f (0 = 1er temps) ; mesure n %s ; longueur de mesure %s temps", beats_in_measure, tostring(measure), tostring(cml))
    local b2, m2, c2 = R.TimeMap2_timeToBeats(0, EV.mk - 0.25)
    log("0.25 s avant le marqueur : temps dans la mesure = %.4f ; mesure n %s ; longueur %s temps", b2, tostring(m2), tostring(c2))
  end
  -- region
  local retval, isrgn, pos, rgnend, name = R.EnumProjectMarkers3(0, 0)
  log("region : %s (debut %.3f, fin %.3f)", tostring(name), pos or -1, rgnend or -1)
  log("")
  log("Lis : (1) les debuts d'items B et A2 collent-ils aux instants reels d'armement ? (ecart en ms)")
  log("     (2) le marqueur est-il a 0.0000 temps de la mesure ? (3) SetCurrentBPM a-t-il change le marqueur ou seulement le debut ?")
  local text = table.concat(LOG, "\n")
  local f = io.open(res .. "/Dripsody_Spike_Report.txt", "w"); if f then f:write(text); f:close() end
  R.ClearConsole(); R.ShowConsoleMsg(text .. "\n")
  R.ShowMessageBox("Essai termine.\nRapport : " .. res .. "/Dripsody_Spike_Report.txt\n(aussi dans la console de REAPER)\nEnvoie-moi ce fichier.", "Dripsody essai", 0)
end

local function tick()
  local t = R.time_precise() - t0
  -- la region s'agrandit en continu, comme ce que fera la vraie fonction
  if rgn_idx and (R.GetPlayState() & 4) == 4 then
    R.SetProjectMarker3(0, rgn_idx, true, EV.rgn, now_pos(), "Spike morceau 1", 0)
  end
  while STEPS[STEP + 1] and t >= STEPS[STEP + 1][1] do
    STEP = STEP + 1
    local ok, err = pcall(STEPS[STEP][2])
    log("t=%.2f : %s%s", t, STEPS[STEP][3], ok and "" or ("  ERREUR : " .. tostring(err)))
  end
  if STEP >= #STEPS then
    if t > STEPS[#STEPS][1] + 1.0 and (R.GetPlayState() & 4) == 0 then report(); return end
  end
  R.defer(tick)
end

R.SetEditCurPos(0, false, false)
R.SetMediaTrackInfo_Value(A, "I_RECARM", 1); EV.armA1 = 0      -- A armee AVANT de lancer l'enregistrement
R.Main_OnCommand(1013, 0)                          -- Transport : enregistrer
t0 = R.time_precise()
R.defer(tick)
