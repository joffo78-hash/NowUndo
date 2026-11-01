-- @description NowUndo Twister Web Backend
-- @version 1.0
-- @author joffo78-hash
-- @changelog
--   Initial ReaPack release.
--[[
  NowUndo_Twister_Web.lua
  Bridge gmem nowundo_sync ↔ ExtState pour la page web Twister (In/Out).

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
  elseif op == "PAGE" then
    local p = tonumber(a)
    if p then
      reaper.SetExtState("nowundo_vl", "fighter_page", tostring(p), false)
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
  reaper.defer(loop)
end

reaper.SetExtState(SECTION, "web_cmd", "", false)
publish(true)
reaper.ShowConsoleMsg("[NowUndo Twister Web] bridge gmem demarre\n")
reaper.defer(loop)
