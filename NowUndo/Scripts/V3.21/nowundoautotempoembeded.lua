-- NowUndo - Auto Tempo Sync : OBSOLETE (21 nov. 2026)
-- AUTO-TEMPO est maintenant dans le MSV3 (Master Sync : AUTO-SYNC + temps de la boucle) et c'est le script Launchpad
-- qui applique le tempo a REAPER (VL.autotempo_tick). Ce script ne fait plus rien : retire-le de __startup.lua.
-- (Il s'arrete tout seul pour ne pas appliquer le tempo une 2e fois.)
if reaper.GetExtState("NowUndo_Sync", "obsolete_msg") ~= "1" then
  reaper.SetExtState("NowUndo_Sync", "obsolete_msg", "1", true)
  reaper.MB("Auto-Tempo est maintenant dans le Master Sync (MSV3) + le Launchpad.\n\n"
    .. "Ce script ne sert plus : retire-le du demarrage (__startup.lua).", "NowUndo Auto-Tempo", 0)
end
