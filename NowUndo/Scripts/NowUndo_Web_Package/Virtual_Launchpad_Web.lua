-- @description NowUndo Virtual Launchpad Web Backend
-- @version 1.0
-- @author joffo78-hash
-- @changelog
--   Initial ReaPack release.
-- @provides
--   [webinterface] NowUndo.html
--[[
  Virtual_Launchpad_Web.lua
  Backend web pour le Virtual Launchpad (nowundo).

  Usage :
  1. Place ce script + virtuallaunchpad_main.lua dans le même dossier Scripts/
  2. Place VirtualLaunchpad.html dans reaper_www_root/
  3. Active le Web Browser Interface (Preferences → Control/OSC/Web)
  4. Lance ce script (Actions → Run ReaScript)
  5. Ouvre http://localhost:8080/VirtualLaunchpad.html (ou l'IP LAN)
]]

local SCRIPT_PATH = ({reaper.get_action_context()})[2]
local SCRIPT_DIR  = SCRIPT_PATH:match("^(.*)[/\\]") or ""

-- Charge le coeur (mode bibliotheque)
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

--------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------
local WEB = {
  section     = "nowundo_vl",
  poll_hz     = 30,
  cmd_poll_hz = 60,
  open_gfx    = false,
  debug       = false,
}

local last_publish = 0
local last_cmd_check = 0
local last_frame_sig = ""
local last_status = ""
local last_meta = ""

--------------------------------------------------------------------------
-- Helpers serialisation compacte
--------------------------------------------------------------------------
local function hex6(h)
  return string.format("%06X", h & 0xFFFFFF)
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
  for _, l in ipairs(layers) do layer_names[#layer_names + 1] = l.id .. "=" .. l.name end
  return table.concat({
    "page=" .. S.page,
    "layer=" .. (S.p4_layer or "fx"),
    "looper=" .. S.sel_looper,
    "group=" .. S.sel_group,
    "launch=" .. (S.launch and "1" or "0"),
    "hold=" .. (function() local g = VL.held_group(); return g and tostring(g) or "0" end)(),
    "layers=" .. table.concat(layer_names, ","),
    "ver=" .. VL.VERSION,
  }, ";")
end

--------------------------------------------------------------------------
-- Publication d'etat vers le web
--------------------------------------------------------------------------
local function publish_state(force)
  local t = reaper.time_precise()
  if not force and (t - last_publish) < (1 / WEB.poll_hz) then return end
  last_publish = t

  local frame = VL.build_frame()
  local frame_str = encode_frame(frame)
  local status = VL.status()
  local meta = encode_meta()

  local changed = force or frame_str ~= last_frame_sig or status ~= last_status or meta ~= last_meta
  if not changed then return end

  last_frame_sig = frame_str
  last_status = status
  last_meta = meta

  reaper.SetExtState(WEB.section, "web_frame", frame_str, false)
  reaper.SetExtState(WEB.section, "web_status", status, false)
  reaper.SetExtState(WEB.section, "web_meta", meta, false)
  reaper.SetExtState(WEB.section, "web_labels", encode_labels(VL.S.page), false)
  reaper.SetExtState(WEB.section, "web_tick", string.format("%.3f", t), false)
end

--------------------------------------------------------------------------
-- Traitement des commandes venant du web
--------------------------------------------------------------------------
local function process_cmd(cmd)
  cmd = (cmd or ""):match("^%s*(.-)%s*$")
  if cmd == "" then return end

  local op, a, b = cmd:match("^(%a),?([^,]*),?(.*)$")
  if not op then return end
  op = op:upper()

  if op == "P" then
    local row, col = tonumber(a), tonumber(b)
    if row and col then VL.on_pad_pressed(row, col) end
  elseif op == "R" then
    local row, col = tonumber(a), tonumber(b)
    if row and col then VL.on_pad_released(row, col) end
  elseif op == "D" then
    local row, col = tonumber(a), tonumber(b)
    if row and col then VL.on_pad_dragged(row, col) end
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

  for cmd in raw:gmatch("[^;]+") do
    process_cmd(cmd)
  end
  publish_state(true)
end

--------------------------------------------------------------------------
-- Boucle principale
--------------------------------------------------------------------------
local function main_loop()
  local t = reaper.time_precise()
  VL.tick(t)
  VL.sync_poll()
  poll_commands()
  publish_state(false)
  VL.dash_publish(false, t)
  VL.render(t)
  reaper.defer(main_loop)
end

--------------------------------------------------------------------------
-- Demarrage
--------------------------------------------------------------------------
VL.sync_enable()
VL.reset()

reaper.SetExtState(WEB.section, "web_backend", "1", false)
reaper.SetExtState(WEB.section, "web_cmd", "", false)
publish_state(true)

reaper.ShowConsoleMsg(string.format(
  "[VL Web] Backend demarre (v%s)\n" ..
  "  -> Ouvrez http://localhost:8080/VirtualLaunchpad.html\n" ..
  "  -> (ou l'IP de cette machine sur le LAN)\n",
  VL.VERSION))

if WEB.open_gfx then
  reaper.defer(function()
    VL.run_gfx_test()
  end)
else
  main_loop()
end
