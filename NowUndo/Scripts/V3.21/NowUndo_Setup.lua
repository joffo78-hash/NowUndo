-- @description Dripsody : installation et demarrage automatique (a lancer une fois, puis quand tu veux changer)
-- @version 3.27
-- @author joffo78
-- @about
--   # Dripsody
--   Looper a 8 instances synchronisees pour REAPER : le looper (JSFX), le Launchpad, le Twister, le MIDI Learn, les
--   Rushes / Scenario, les 8 Waves (avec import de fichiers audio), le FX Router, le pedalier virtuel et la page web.
--
--   Apres l'installation par ReaPack, lance l'action **Dripsody : installation et demarrage automatique** :
--   elle verifie les extensions necessaires (SWS, js_ReaScriptAPI, ReaImGui), te laisse choisir les scripts a lancer
--   automatiquement a l'ouverture de REAPER et ecrit le demarrage pour toi.
--
--   La page web (NowUndo.html) demande d'activer l'interface web de REAPER (Preferences > Control/OSC/web).
-- @changelog
--   3.27 : premiere version du paquet ReaPack.
-- @provides
--   [main] virtuallaunchpad_main.lua
--   [main] Virtual_Launchpad_secondary.lua
--   [main] twisterinoutreset.lua
--   [main] nowundo_midi_learn.lua
--   [main] NowUndo_Scenario.lua
--   [main] NowUndo_8Waves.lua
--   [main] NowUndo_Twister_Web.lua
--   [main] NowUndo_Latency.lua
--   [main] NowUndo_VirtualPedalBoard.lua
--   [main] FX_Router_v2.lua
--   [main] NowUndo_Performance.lua
--   [webinterface] NowUndo.html
--   [effect] ../../NowUndo_V3.27.jsfx
--   [effect] ../../NU_DropCapture.jsfx
--   [effect] ../../master_synchro
--   [effect] ../../Effects/NU_BBD_Delay.jsfx
--   [effect] ../../Effects/NU_Filter.jsfx
--   [effect] ../../Effects/NU_GRM_Comb.jsfx
--   [effect] ../../Effects/NU_Manipulator_Formant.jsfx
--   [effect] ../../Effects/NU_Stutter.jsfx

local EXT = "NowUndo_Setup"
local MARK_A = "-- >>> NOWUNDO (genere par NowUndo_Setup, ne pas modifier a la main) >>>"
local MARK_B = "-- <<< NOWUNDO <<<"

-- Scripts proposes au demarrage automatique : fichier, nom affiche, coche par defaut
local SCRIPTS = {
  { "virtuallaunchpad_main.lua",  "Launchpad (virtuel + vrai Mini MK3)",    true  },
  { "twisterinoutreset.lua",      "Twister (Midi Fighter Twister)",          true  },
  { "NowUndo_Twister_Web.lua",    "Pont de la page web (Twister / Loopers)", true  },
  { "nowundo_midi_learn.lua",     "MIDI Learn + raccourcis clavier",         false },
  { "NowUndo_8Waves.lua",         "8 Waves (formes d'onde + import audio)",  false },
  { "NowUndo_Scenario.lua",       "Rushes / Scenario",                       false },
  { "FX_Router_v2.lua",           "FX Router",                               false },
  { "NowUndo_VirtualPedalBoard.lua", "Pedalier virtuel",                     false },
  { "NowUndo_Performance.lua",    "Performance (enregistrement du concert)", false },
}

local function sdir()
  local src = debug.getinfo(1, "S").source or ""
  local d = src:match("^@(.*[/\\])")
  if d then return d end
  local _, p = reaper.get_action_context()
  return (p or ""):match("^(.*[/\\])") or ""
end
local DIR = sdir()

-- choix memorises (ExtState persistant) : "1" / "0" par fichier
local function get_on(i)
  local v = reaper.GetExtState(EXT, "auto_" .. SCRIPTS[i][1])
  if v == "" then return SCRIPTS[i][3] end
  return v == "1"
end
local function set_on(i, on) reaper.SetExtState(EXT, "auto_" .. SCRIPTS[i][1], on and "1" or "0", true) end

local function file_exists(p) local f = io.open(p, "rb"); if f then f:close(); return true end return false end

-- extensions necessaires
local function check_deps()
  local res = reaper.GetResourcePath()
  local miss = {}
  if not reaper.BR_GetMouseCursorContext then miss[#miss + 1] = "SWS / S&M Extension  (https://www.sws-extension.org)" end
  if not reaper.JS_VKeys_GetState then miss[#miss + 1] = "js_ReaScriptAPI  (ReaPack : repository ReaTeam Extensions)" end
  if not (reaper.ImGui_CreateContext or file_exists(res .. "/Scripts/ReaTeam Extensions/API/imgui.lua")) then
    miss[#miss + 1] = "ReaImGui  (ReaPack : repository ReaTeam Extensions)"
  end
  return miss
end

-- ecrit (ou remplace) le bloc NowUndo de Scripts/__startup.lua, sans toucher au reste du fichier
local function write_startup(list)
  local path = reaper.GetResourcePath() .. "/Scripts/__startup.lua"
  local old = ""
  local f = io.open(path, "rb"); if f then old = f:read("*a") or ""; f:close() end
  local a = old:find(MARK_A, 1, true)
  if a then
    local _, b = old:find(MARK_B, a, true)
    old = old:sub(1, a - 1) .. old:sub((b or #old) + 1)
  end
  old = old:gsub("%s+$", "")
  local block = ""
  if #list > 0 then
    local q = {}
    for _, fn in ipairs(list) do q[#q + 1] = string.format("%q", fn) end
    block = table.concat({
      MARK_A,
      "do",
      "  local dir = " .. string.format("%q", DIR),
      "  local files = { " .. table.concat(q, ", ") .. " }",
      "  local t0, done = reaper.time_precise(), false",
      "  local function boot()",
      "    if done then return end",
      "    if reaper.time_precise() - t0 < 1.5 then reaper.defer(boot); return end   -- laisse REAPER finir de demarrer",
      "    done = true",
      "    for _, fn in ipairs(files) do",
      "      local id = reaper.AddRemoveReaScript(true, 0, dir .. fn, true)",
      "      if id and id ~= 0 then reaper.Main_OnCommand(id, 0) end",
      "    end",
      "  end",
      "  boot()",
      "end",
      MARK_B,
    }, "\n")
  end
  local out = old
  if block ~= "" then out = (out ~= "" and (out .. "\n\n") or "") .. block .. "\n" elseif out ~= "" then out = out .. "\n" end
  local w = io.open(path, "wb")
  if not w then return false, path end
  w:write(out); w:close()
  return true, path
end

local function main()
  -- 1) extensions
  local miss = check_deps()
  local msg = {}
  if #miss > 0 then
    msg[#msg + 1] = "Il manque des extensions (a installer puis relancer REAPER) :\n  - " .. table.concat(miss, "\n  - ") .. "\n"
  else
    msg[#msg + 1] = "Extensions : SWS, js_ReaScriptAPI, ReaImGui OK.\n"
  end
  -- 2) fichiers presents
  local absent = {}
  for _, s in ipairs(SCRIPTS) do if not file_exists(DIR .. s[1]) then absent[#absent + 1] = s[1] end end
  if #absent > 0 then msg[#msg + 1] = "Fichiers absents : " .. table.concat(absent, ", ") .. " (reinstalle Dripsody par ReaPack).\n" end

  -- 3) menu des scripts a lancer au demarrage (cocher / decocher, puis Appliquer)
  gfx.init("Dripsody", 1, 1, 0, 0, 0)
  while true do
    local items = {}
    for i, s in ipairs(SCRIPTS) do items[#items + 1] = (get_on(i) and "!" or "") .. s[2] end
    items[#items + 1] = "APPLIQUER (ecrire le demarrage automatique)"
    items[#items + 1] = "Quitter sans rien changer"
    gfx.x, gfx.y = 0, 0
    local c = gfx.showmenu(table.concat(items, "|"))
    -- pas de separateur dans le menu : la numerotation de gfx.showmenu reste 1, 2, 3...
    local n = #SCRIPTS
    if c >= 1 and c <= n then
      set_on(c, not get_on(c))
    elseif c == n + 1 then
      local list = {}
      for i, s in ipairs(SCRIPTS) do if get_on(i) then list[#list + 1] = s[1] end end
      local ok, p = write_startup(list)
      gfx.quit()
      if ok then
        msg[#msg + 1] = (#list > 0 and (#list .. " script(s) se lanceront au demarrage de REAPER.") or "Plus aucun script Dripsody au demarrage.") .. "\nFichier : " .. p
      else
        msg[#msg + 1] = "Impossible d'ecrire " .. tostring(p)
      end
      break
    else
      gfx.quit(); break
    end
  end
  msg[#msg + 1] = "\nPour lancer un script maintenant : liste des actions > chercher \"NowUndo_\" (les noms de fichiers gardent cet ancien nom).\nPage web : active l'interface web de REAPER (Preferences > Control/OSC/web) puis ouvre http://localhost:<port>/NowUndo.html"
  reaper.ShowMessageBox(table.concat(msg, "\n"), "Dripsody : installation", 0)
end

main()
