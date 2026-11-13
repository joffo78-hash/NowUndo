--[[
  NowUndo_Latency.lua  -  reglage de la compensation de latence (NowUndo V3.23+)

  Ce qu'on joue en ecoutant les boucles arrive au looper en retard de la latence aller-retour de la carte son
  (sortie + entree). NowUndo V3.23 ecrit donc les overdubs (et le 1er REC d'un looper synchronise) d'autant
  plus tot dans la boucle.

  Valeur utilisee = latence annoncee par REAPER (automatique) + decalage manuel (ms, peut etre negatif).
  Le script Launchpad (virtuallaunchpad_main.lua) transmet ces valeurs aux 8 loopers chaque seconde.

  Lancer ce script : une fenetre affiche la latence annoncee et permet de regler :
    - Compensation : 1 = active, 0 = coupee
    - Decalage manuel en ms (ajustement a l'oreille, ex. 2 ou -1.5)
]]

local SEC = "NowUndo_Latency"

local li, lo = 0, 0
if reaper.GetInputOutputLatency then li, lo = reaper.GetInputOutputLatency() end
local sr = 48000
if reaper.GetAudioDeviceInfo then
  local _, v = reaper.GetAudioDeviceInfo("SRATE", "")
  sr = tonumber(v) or sr
end
local auto_ms = ((tonumber(li) or 0) + (tonumber(lo) or 0)) / sr * 1000

local on = reaper.GetExtState(SEC, "on")
if on == "" then on = "1" end
local off = reaper.GetExtState(SEC, "offset_ms")
if off == "" then off = "0" end

local title = string.format("NowUndo latence (auto REAPER : %.1f ms = %d + %d samples)", auto_ms, li or 0, lo or 0)
local ok, csv = reaper.GetUserInputs(title, 2, "Compensation (1 = on / 0 = off),Decalage manuel (ms),extrawidth=80", on .. "," .. off)
if not ok then return end

local a, b = csv:match("^%s*([^,]*)%s*,%s*([^,]*)%s*$")
local new_on = (tonumber(a) or 1) ~= 0 and "1" or "0"
local new_off = tonumber(b) or 0
new_off = math.max(-20, math.min(40, new_off))
reaper.SetExtState(SEC, "on", new_on, true)
reaper.SetExtState(SEC, "offset_ms", tostring(new_off), true)

reaper.MB(string.format("Compensation : %s\nLatence auto : %.1f ms\nDecalage manuel : %+.1f ms\nTotal applique : %.1f ms\n\n(Pris en compte en 1 s par le script Launchpad, qui doit tourner.)",
  new_on == "1" and "ACTIVE" or "COUPEE", auto_ms, new_off, new_on == "1" and math.max(0, auto_ms + new_off) or 0), "NowUndo latence", 0)
