--[[
  Virtual_Launchpad_Web.lua
  Backend web pour le Virtual Launchpad (nowundo).

  Usage :
  1. Place ce script + virtuallaunchpad_main.lua dans le même dossier Scripts/
  2. Place VirtualLaunchpad.html dans reaper_www_root/
  3. Active le Web Browser Interface (Preferences → Control/OSC/Web)
  4. Lance ce script (Actions → Run ReaScript)
  5. Ouvre http://localhost:8080/VirtualLaunchpad.html (ou l'IP LAN)

  PAGES : chaque navigateur a SA page (gardee cote navigateur). Le backend publie les 4 grilles
  (web_frame_1..4 / web_labels_1..4) et les appuis arrivent avec leur page ("P,row,col,page").
  Les boutons de page (colonne droite, lignes 5-8) sont traites dans le navigateur.
  (la couche de la page 4 et le HOLD restent partages entre les navigateurs)

  Compatible coeur VL 0.9.x (build mastersync+) :
  - selection looper / groupes synchronisee via ExtState (sync_out / sync_poll)
  - rangee du haut : appui = select, long = fenetre looper, relache = fermeture si deja ouverte
  - HOLD virtuel, couches page 4, labels dynamiques (statut loopers)
]]

local SCRIPT_PATH = ({reaper.get_action_context()})[2]
local SCRIPT_DIR  = SCRIPT_PATH:match("^(.*)[/\\]") or ""

-- Charge le coeur (mode bibliotheque : pas de fenetre gfx)
_G.VL_TEST = true
local candidates = {
  SCRIPT_DIR .. "/virtuallaunchpad_main.lua",
  SCRIPT_DIR .. "/../virtuallaunchpad_main.lua",
  SCRIPT_DIR .. "/Virtual_Launchpad.lua",
}
local VL, last_err
for _, path in ipairs(candidates) do
  local ok, res = pcall(dofile, path)
  if ok and type(res) == "table" and res.VERSION then
    VL = res
    break
  end
  last_err = res
end
if not VL then
  reaper.ShowMessageBox(
    "Impossible de charger virtuallaunchpad_main.lua\n" ..
    "Placez-le dans le meme dossier que ce script.\n\n" ..
    "Derniere erreur : " .. tostring(last_err),
    "Virtual Launchpad Web", 0)
  return
end
_G.VL_TEST = nil

-- La page du web reste PROPRE au web : elle est publiee sous des cles a part (lues uniquement par le miroir),
-- et non sous "active_page" / "heartbeat" que le controleur Launchpad et les autres peripheriques utilisent.
VL.page_key = "web_active_page"
VL.heartbeat_key = "web_heartbeat"

--------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------
local WEB = {
  section     = "nowundo_vl",
  poll_hz     = 30,     -- publication frame / status / meta
  cmd_poll_hz = 80,     -- lecture commandes web (reactif)
  labels_hz   = 4,      -- labels (plus legers, statut loopers inclus)
  open_gfx    = false,
  debug       = false,
}

local last_publish = 0
local last_cmd_check = 0
local last_labels = 0
local last_frame_sigs = { "", "", "", "" }     -- une grille / un jeu de libelles par page : chaque navigateur choisit la sienne
local last_status = ""
local last_meta = ""
local last_labels_sigs = { "", "", "", "" }

--------------------------------------------------------------------------
-- Helpers serialisation compacte
--------------------------------------------------------------------------
local function hex6(h)
  return string.format("%06X", (h or 0) & 0xFFFFFF)
end

local STATE_CODE = {
  off = "o", idle = "i", on = "n", warn = "w",
  armed = "a", armed_other = "x", cursor = "c", member_cursor = "m"
}

local function encode_frame(frame)
  local parts = {}
  for key, v in pairs(frame) do
    local hex, state = v[1], v[2]
    local code = STATE_CODE[state] or "o"
    parts[#parts + 1] = key .. ":" .. hex6(hex) .. ":" .. code
  end
  table.sort(parts)
  return table.concat(parts, "|")
end

local function encode_labels(page)
  local parts = {}
  for row = 0, 8 do
    for col = 1, 9 do
      local lab = VL.pad_label(page, row, col)
      if lab and lab ~= "" then
        -- escapers alignees avec le parseur HTML (¦ et ⁚)
        lab = lab:gsub("[|:]", function(c) return c == "|" and "¦" or "⁚" end)
        parts[#parts + 1] = row .. "," .. col .. ":" .. lab
      end
    end
  end
  return table.concat(parts, "|")
end

local function encode_meta()
  local S = VL.S
  local layers = VL.layers()
  local layer_names = {}
  for _, l in ipairs(layers) do
    layer_names[#layer_names + 1] = tostring(l.id) .. "=" .. tostring(l.name)
  end
  local hg = VL.held_group and VL.held_group() or nil
  return table.concat({
    "page=" .. tostring(S.page),
    "layer=" .. tostring(S.p4_layer or "fx"),
    "looper=" .. tostring(S.sel_looper or 1),
    "group=" .. tostring(S.sel_group or 0),
    "launch=" .. (S.launch and "1" or "0"),
    "hold=" .. (hg and tostring(hg) or "0"),
    "layers=" .. table.concat(layer_names, ","),
    "ver=" .. tostring(VL.VERSION),
    "build=" .. tostring(VL.BUILD or ""),
  }, ";")
end

--------------------------------------------------------------------------
-- Publication d'etat vers le web
--------------------------------------------------------------------------
-- Grille d'une page donnee, sans changer durablement la page du backend
local function frame_for_page(p)
  local S = VL.S
  local saved = S.page
  S.page = p
  local ok, f = pcall(VL.build_frame)
  S.page = saved
  return ok and f or {}
end

local function publish_state(force)
  local t = reaper.time_precise()
  if not force and (t - last_publish) < (1 / WEB.poll_hz) then return end
  last_publish = t

  -- Les 4 pages sont publiees en permanence (web_frame_1..4) : le navigateur n'affiche que la sienne
  for p = 1, 4 do
    local frame_str = encode_frame(frame_for_page(p))
    if force or frame_str ~= last_frame_sigs[p] then
      last_frame_sigs[p] = frame_str
      reaper.SetExtState(WEB.section, "web_frame_" .. p, frame_str, false)
    end
  end

  local status = VL.status()
  local meta = encode_meta()
  if force or status ~= last_status or meta ~= last_meta then
    last_status = status
    last_meta = meta
    reaper.SetExtState(WEB.section, "web_status", status, false)
    reaper.SetExtState(WEB.section, "web_meta", meta, false)
  end

  -- Labels (statut loopers dynamiques) a rythme plus lent, sauf force
  if force or (t - last_labels) >= (1 / WEB.labels_hz) then
    last_labels = t
    for p = 1, 4 do
      local labels = encode_labels(p)
      if force or labels ~= last_labels_sigs[p] then
        last_labels_sigs[p] = labels
        reaper.SetExtState(WEB.section, "web_labels_" .. p, labels, false)
      end
    end
  end

  -- Heartbeat pour le front (detection offline)
  reaper.SetExtState(WEB.section, "web_tick", string.format("%.3f", t), false)
end

--------------------------------------------------------------------------
-- Traitement des commandes venant du web
--------------------------------------------------------------------------
local function process_cmd(cmd)
  cmd = (cmd or ""):match("^%s*(.-)%s*$")
  if cmd == "" then return end

  -- Op multi-lettres (PAGE, …) ou mono-lettre (P,R,D,H,L,…)
  local op, rest = cmd:match("^([%a_]+),?(.*)$")
  if not op then return end
  op = op:upper()

  local a, b = "", ""
  if rest and rest ~= "" then
    a, b = rest:match("^([^,]*),?(.*)$")
    a, b = a or "", b or ""
  end

  if op == "P" or op == "R" or op == "D" then
    -- "P,row,col,page" : la page vient du NAVIGATEUR qui a appuye (chaque navigateur a la sienne) ;
    -- le coeur la lit dans VL.S.page, on la positionne le temps de l'appel puis on la restaure
    local row, col, page = rest:match("^(%d+),(%d+),?(%d*)$")
    row, col, page = tonumber(row), tonumber(col), tonumber(page)
    if row and col then
      local S = VL.S
      local saved = S.page
      if page and page >= 1 and page <= 4 then S.page = page end
      local ok, err = pcall(function()
        if op == "P" then VL.on_pad_pressed(row, col)
        elseif op == "R" then VL.on_pad_released(row, col)
        else VL.on_pad_dragged(row, col) end
      end)
      S.page = saved
      if not ok then reaper.ShowConsoleMsg("[VL Web] erreur pad " .. cmd .. " : " .. tostring(err) .. "\n") end
    end
  elseif op == "H" then
    VL.set_virtual_hold(a == "1")
  elseif op == "C" then
    VL.set_ctrl_hold(a == "1")
  elseif op == "L" then
    if a and a ~= "" then VL.set_layer(a) end
  elseif op == "N" then
    VL.cycle_layer()
  elseif op == "G" then
    local g = tonumber(a)
    if g then VL.group_pad_tap(g) end
  elseif op == "S" then
    local i = tonumber(a)
    if i then VL.select_looper(i) end
  elseif op == "PAGE" then
    local p = tonumber(a)
    if p then VL.set_page(p) end
  end
end

local function poll_commands()
  local t = reaper.time_precise()
  if (t - last_cmd_check) < (1 / WEB.cmd_poll_hz) then return end
  last_cmd_check = t

  local raw = reaper.GetExtState(WEB.section, "web_cmd")
  if not raw or raw == "" then return end

  reaper.SetExtState(WEB.section, "web_cmd", "", false)

  local n = 0
  for c in raw:gmatch("[^;]+") do
    process_cmd(c)
    n = n + 1
  end
  if n > 0 then
    -- Publier l'etat partage (autres fenetres / Launchpad gfx) + frame web
    if VL.sync_out then VL.sync_out(true) end
    publish_state(true)
  end
end

--------------------------------------------------------------------------
-- Boucle principale
--------------------------------------------------------------------------
local function main_loop()
  local t = reaper.time_precise()
  -- 1) horloge interne (long-press, feedback gmem, fire queue)
  VL.tick(t)
  -- 2) etat venant d'une autre instance (selection, groupes, routing…)
  local remote = VL.sync_poll and VL.sync_poll()
  -- 3) commandes utilisateur web (prioritaires sur le miroir distant)
  poll_commands()
  -- 4) si le miroir a change l'etat sans commande locale, republier la frame
  if remote then publish_state(true) end
  publish_state(false)
  if VL.dash_publish then VL.dash_publish(false, t) end
  -- render sans profil hardware : met a jour active_page / heartbeat seulement
  VL.render(t)
  reaper.defer(main_loop)
end

--------------------------------------------------------------------------
-- Demarrage
-- IMPORTANT : reset AVANT sync_enable, sinon on ecrase l'etat charge
-- depuis une autre fenetre (selection looper, groupes, etc.).
--------------------------------------------------------------------------
VL.reset()
-- reset vide l'etat (donc aussi ce que le coeur avait charge depuis nowundo_vl_model.txt) : on recharge le modele
-- avant sync_enable, sinon la sauvegarde automatique pourrait ecraser le fichier avec un etat vide si aucun
-- controleur n'est lance. Si un controleur est actif, sync_enable remplace ensuite l'etat par le sien.
if VL.model_load then VL.model_load() end
if VL.sync_enable then VL.sync_enable() end

reaper.SetExtState(WEB.section, "web_backend", "1", false)
reaper.SetExtState(WEB.section, "web_cmd", "", false)
if VL.sync_out then VL.sync_out(true) end
publish_state(true)

reaper.ShowConsoleMsg(string.format(
  "[VL Web] Backend demarre (v%s%s)\n" ..
  "  -> Ouvrez http://localhost:8080/VirtualLaunchpad.html\n" ..
  "  -> (ou l'IP de cette machine sur le LAN)\n",
  VL.VERSION,
  VL.BUILD and (" / " .. VL.BUILD) or ""))

if WEB.open_gfx then
  reaper.defer(function()
    VL.run_gfx_test()
  end)
else
  main_loop()
end

