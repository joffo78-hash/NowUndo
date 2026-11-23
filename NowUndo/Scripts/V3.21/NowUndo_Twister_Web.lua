--[[
  NowUndo_Twister_Web.lua
  Bridge gmem nowundo_sync ↔ ExtState pour la page web (NowUndo.html) : onglet Twister (In/Out)
  et onglet Loopers (forme d'onde, In/Out, transport, modes, degradation / output / stereo, VU).

  À lancer en parallèle de Virtual_Launchpad_Web.lua
  (ou après, les deux cohabitent).
]]

local SECTION = "nowundo_tw"
local POLL_HZ = 30
local CMD_HZ = 60

local last_pub = 0
local last_cmd = 0
local last_sig = ""
local pending_reset = {}
local pending_width = {}

reaper.gmem_attach("nowundo_sync")

local function clamp(v, a, b)
  if v < a then return a elseif v > b then return b end
  return v
end

-- Lit l'état In/Out des 8 loopers
local function read_state()
  local parts = {}
  local now_t = reaper.time_precise()
  for i = 0, 7 do
    local base0 = 1000 + i * 600
    local alive = (reaper.gmem_read(base0) or 0) > 0
      and (now_t - (reaper.gmem_read(130 + i) or 0)) <= 3.0
    local active_p = reaper.gmem_read(base0 + 42) or 1
    if active_p < 1 or active_p > 3 then active_p = 1 end
    local gbase = base0 + (active_p - 1) * 200
    local len = reaper.gmem_read(gbase + 46) or 0
    local in_s = reaper.gmem_read(gbase + 44) or 0
    local w_s = reaper.gmem_read(gbase + 45) or 0
    local in_n, out_n = 0, 1
    if len > 0 then
      in_n = clamp(in_s / len, 0, 1)
      out_n = clamp((in_s + w_s) / len, 0, 1)
    end
    parts[#parts + 1] = string.format("%d:%d:%.4f:%.4f:%.0f",
      i, alive and 1 or 0, in_n, out_n, len)
  end
  return table.concat(parts, "|")
end

local function publish(force)
  local t = reaper.time_precise()
  if not force and (t - last_pub) < (1 / POLL_HZ) then return end
  last_pub = t
  -- page Twister active (choisie au Launchpad, au MIDI Learn ou au web) : le web la suit
  reaper.SetExtState(SECTION, "tw_page", reaper.GetExtState("nowundo_vl", "fighter_page"), false)
  local sig = read_state()
  if sig == last_sig and not force then
    reaper.SetExtState(SECTION, "tw_tick", string.format("%.3f", t), false)
    return
  end
  last_sig = sig
  reaper.SetExtState(SECTION, "tw_state", sig, false)
  reaper.SetExtState(SECTION, "tw_tick", string.format("%.3f", t), false)
end

-- Applique In/Out normalisés [0..1] pour looper i (0..7)
local function set_io(i, in_n, out_n)
  local base0 = 1000 + i * 600
  local active_p = reaper.gmem_read(base0 + 42) or 1
  if active_p < 1 or active_p > 3 then active_p = 1 end
  local gbase = base0 + (active_p - 1) * 200
  local len = reaper.gmem_read(gbase + 46) or 0
  if len <= 0 then return end
  in_n = clamp(in_n, 0, 1)
  out_n = clamp(out_n, in_n, 1)
  local new_in = in_n * len
  local new_out = out_n * len
  local new_w = math.max(0, new_out - new_in)
  -- Frame 1 : set In
  reaper.gmem_write(gbase + 161, new_in)
  reaper.gmem_write(gbase + 160, 1)
  -- Width au cycle suivant (comme le script gfx)
  pending_width[i] = { gbase = gbase, w = new_w }
end

local function reset_all()
  for i = 0, 7 do
    local base0 = 1000 + i * 600
    local active_p = reaper.gmem_read(base0 + 42) or 1
    if active_p < 1 or active_p > 3 then active_p = 1 end
    local gbase = base0 + (active_p - 1) * 200
    local len = reaper.gmem_read(gbase + 46) or 0
    if len > 0 then
      pending_reset[i] = { gbase = gbase, len = len, step = 1 }
    end
  end
end

-- Le controleur Launchpad republie "fighter_page" depuis SON etat a chaque image : une simple ecriture d'ExtState
-- etait aussitot ecrasee. On modifie donc l'etat partage du Launchpad (meme methode que le MIDI Learn), qu'il recharge.
local function vl_sorted_keys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, function(x, y)
    local tx, ty = type(x), type(y)
    if tx ~= ty then return tx < ty end
    return x < y
  end)
  return keys
end
local function vl_ser(v)
  local tv = type(v)
  if tv == "number" then return math.type(v) == "integer" and tostring(v) or string.format("%.17g", v)
  elseif tv == "boolean" then return tostring(v)
  elseif tv == "string" then return string.format("%q", v)
  elseif tv == "table" then
    local parts = {}
    for _, k in ipairs(vl_sorted_keys(v)) do parts[#parts + 1] = "[" .. vl_ser(k) .. "]=" .. vl_ser(v[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "nil"
end
local vl_edit_n = 0
local function set_fighter_page(p)
  reaper.SetExtState("nowundo_vl", "fighter_page", tostring(p), false)   -- suffit si le Launchpad n'est pas lance
  local raw = reaper.GetExtState("nowundo_vl", "state")
  if raw == "" then return end
  local f = load("return " .. raw, "vl_state", "t", {})
  if not f then return end
  local ok, t = pcall(f)
  if not ok or type(t) ~= "table" then return end
  t.fighter_page = p
  vl_edit_n = vl_edit_n + 1
  reaper.SetExtState("nowundo_vl", "state", vl_ser(t), false)
  reaper.SetExtState("nowundo_vl", "rev", "twweb:" .. vl_edit_n .. ":" .. string.format("%.3f", reaper.time_precise()), false)
end

-- ===== VUES LOOPER (onglet Loopers de NowUndo.html) =====
-- lv_fast (~15 Hz) : par looper "i,vivant,etat,pos%,in,out,vuIn,vuOut,flags,degradation,output,stereo,longueur,part,feedback"
--   flags : 1 reverse | 2 ping-pong | 4 slicer | 8 cloud | 16 beat repeat | 32 one-shot | 64 auto rec
-- lv_wave (~2 Hz, si change) : 8 formes d'onde de 100 points, 1 caractere par point (0..61), separees par "|"
local LV = { t = 0, wt = 0, wsig = "", ALPHA = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" }
local function lv_base(i)
  local base0 = 1000 + i * 600
  local ap = reaper.gmem_read(base0 + 42) or 1
  if ap < 1 or ap > 3 then ap = 1 end
  return base0 + (math.floor(ap + 0.5) - 1) * 200, math.floor(ap + 0.5)
end
local function lv_publish(t)
  if t - LV.t < 0.066 then return end
  LV.t = t
  local parts = {}
  for i = 0, 7 do
    local base0 = 1000 + i * 600
    local alive = (reaper.gmem_read(base0) or 0) > 0 and (t - (reaper.gmem_read(130 + i) or 0)) <= 3.0
    local b, ap = lv_base(i)
    local function g(o) return reaper.gmem_read(b + o) or 0 end
    local len = g(46)
    local in_n, out_n = 0, 1
    if len > 0 then in_n = clamp(g(44) / len, 0, 1); out_n = clamp((g(44) + g(45)) / len, 0, 1) end
    local pm = math.floor(g(8) + 0.5)
    local fl = (g(17) > 0.5 and 1 or 0) + (g(18) > 0.5 and 2 or 0) + (pm == 1 and 4 or 0) + (g(24) > 0.5 and 8 or 0)
             + (g(189) > 0.5 and 16 or 0) + (pm == 2 and 32 or 0) + (g(43) > 0.5 and 64 or 0)
    parts[#parts + 1] = string.format("%d,%d,%d,%.2f,%.4f,%.4f,%.3f,%.3f,%d,%.3f,%.3f,%.3f,%.0f,%d,%.3f",
      i, alive and 1 or 0, math.floor(g(2) + 0.5), g(47), in_n, out_n, g(172), g(173), fl, g(20), g(22), g(21), len, ap, g(19))
  end
  reaper.SetExtState(SECTION, "lv_fast", table.concat(parts, ";"), false)
  if t - LV.wt >= 0.5 then
    LV.wt = t
    local w = {}
    for i = 0, 7 do
      local b = lv_base(i)
      local c = {}
      for k = 0, 99 do
        local v = math.floor(clamp(reaper.gmem_read(b + 50 + k) or 0, 0, 1) * 61 + 0.5)
        c[#c + 1] = LV.ALPHA:sub(v + 1, v + 1)
      end
      w[#w + 1] = table.concat(c)
    end
    local sig = table.concat(w, "|")
    if sig ~= LV.wsig then LV.wsig = sig; reaper.SetExtState(SECTION, "lv_wave", sig, false) end
  end
end

local function process_cmd(cmd)
  cmd = (cmd or ""):match("^%s*(.-)%s*$")
  if cmd == "" then return end
  local op, a, b, c = cmd:match("^([^,]+),?([^,]*),?([^,]*),?(.*)$")
  if not op then return end
  op = op:upper()
  if op == "IO" then
    local i = tonumber(a)
    local in_n = tonumber(b)
    local out_n = tonumber(c)
    if i and in_n and out_n then set_io(i, in_n, out_n) end
  elseif op == "RESET" then
    reset_all()
  elseif op == "CMD" then                       -- CMD,i,commande[,argument] : commande looper (vue Loopers)
    local i, c, arg = tonumber(a), tonumber(b), tonumber(c)
    if i and c and i >= 0 and i <= 7 then
      local gb = lv_base(i)
      if arg then reaper.gmem_write(gb + 49, arg) end
      reaper.gmem_write(gb + 48, c)
    end
  elseif op == "PAR" then                       -- PAR,i,id,valeur : reglage (degradation 20, stereo 21, output 22)
    local i, id, v = tonumber(a), tonumber(b), tonumber(c)
    if i and id and v and i >= 0 and i <= 7 then
      local gb = lv_base(i)
      reaper.gmem_write(gb + 181, v)
      reaper.gmem_write(gb + 180, id)
    end
  elseif op == "PAGE" then
    local p = tonumber(a)
    if p then
      -- La page web (NowUndo.html a jour) numerote les pages comme les BOUTONS du Launchpad / Twister v3.3+
      -- (1 Volume, 2 Pitch, 3 In/Out, 4 Slicer, 5 Cloud, 6 Effets, 7 Custom, 8 Display).
      p = math.max(1, math.min(8, math.floor(p)))
      set_fighter_page(p)
      -- si le Launchpad tourne, on peut aussi pousser via une cmd dédiée plus tard
    end
  end
end

local function poll_commands()
  local t = reaper.time_precise()
  if (t - last_cmd) < (1 / CMD_HZ) then return end
  last_cmd = t
  local raw = reaper.GetExtState(SECTION, "web_cmd")
  if not raw or raw == "" then return end
  reaper.SetExtState(SECTION, "web_cmd", "", false)
  for cmd in raw:gmatch("[^;]+") do process_cmd(cmd) end
  publish(true)
end

local function tick_pending()
  for i, pr in pairs(pending_reset) do
    if pr.step == 1 then
      reaper.gmem_write(pr.gbase + 161, 0)
      reaper.gmem_write(pr.gbase + 160, 1)
      pr.step = 2
    elseif pr.step == 2 then
      reaper.gmem_write(pr.gbase + 162, pr.len)
      reaper.gmem_write(pr.gbase + 160, 2)
      pending_reset[i] = nil
    end
  end
  for i, pw in pairs(pending_width) do
    reaper.gmem_write(pw.gbase + 162, pw.w)
    reaper.gmem_write(pw.gbase + 160, 3)
    pending_width[i] = nil
  end
end

local function loop()
  tick_pending()
  poll_commands()
  publish(false)
  lv_publish(reaper.time_precise())
  reaper.defer(loop)
end

reaper.SetExtState(SECTION, "web_cmd", "", false)
publish(true)
reaper.ShowConsoleMsg("[NowUndo Twister Web] bridge gmem demarre\n")
reaper.defer(loop)
