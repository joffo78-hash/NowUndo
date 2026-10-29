-- @description NowUndo Twister Control - Compact
-- @version 1.2
-- @author Assistant

local SCALE = 1.0
local COLS = 4
local ROWS = 4
local KNOB_R = 17

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
  if d & 1 == 0 then
    reaper.SetExtState(e, "x", tostring(math.floor(x)), true)
    reaper.SetExtState(e, "y", tostring(math.floor(y)), true)
    reaper.SetExtState(e, "w", tostring(math.floor(w)), true)
    reaper.SetExtState(e, "h", tostring(math.floor(h)), true)
  end
end
-- ===== fin ajout =====

function init()
  reaper.gmem_attach("nowundo_sync")
  local w = math.floor((COLS * 58 + 16) * SCALE)
  local h = math.floor((ROWS * 72 + 28) * SCALE)
  NDDOCK.init("NowUndo Twister", "NowUndo_Twister", w, h)
  gfx.clear = 0x0C0C0F
end

local tw_mode = {0,0,0,0,0,0,0,0}
local tw_active_id = -1
local tw_drag_start_y = 0
local tw_drag_start_val = 0
local tw_has_moved = 0
local last_mouse_down = false
-- Reset In+Out en 2 frames (1 commande gmem / cycle JSFX)
local pending_reset = {}
-- Pendant un drag In (mode In/Out) : figer Out, ajuster Width au frame suivant
local pending_width = {}
local tw_lock_out = {}   -- [tw_id] = position Out figee au debut du drag In

local function draw_arc(cx, cy, r, a0, a1)
  local n = math.max(1, math.ceil(math.abs(a1 - a0) / 0.12))
  local step = (a1 - a0) / n
  local aa = a0
  for i = 1, n do
    local bb = aa + step
    gfx.line(cx + math.cos(aa)*r, cy + math.sin(aa)*r, cx + math.cos(bb)*r, cy + math.sin(bb)*r)
    gfx.line(cx + math.cos(aa)*(r-1), cy + math.sin(aa)*(r-1), cx + math.cos(bb)*(r-1), cy + math.sin(bb)*(r-1))
    aa = bb
  end
end

local function draw_knob(cx, cy, r, val, label, is_width, is_out, has_looper, s)
  local ua = has_looper and 1 or 0.35
  local led_r = r + 3

  gfx.set(0.15, 0.15, 0.18, ua)
  gfx.circle(cx, cy, led_r, 1)
  gfx.set(0.3, 0.3, 0.35, ua)
  gfx.circle(cx, cy, led_r, 0)

  for i = 0, 15 do
    local t = (i + 0.5) / 16
    local ang = 0.75 * math.pi + t * 1.5 * math.pi
    if t <= val then gfx.set(0.2, 0.7, 0.9, ua) else gfx.set(0.35, 0.35, 0.4, ua) end
    gfx.circle(cx + math.cos(ang)*led_r, cy + math.sin(ang)*led_r, math.max(1, r*0.07), 1)
  end

  gfx.set(0.2, 0.7, 0.9, 0.3 * ua)
  draw_arc(cx, cy, led_r + 2, 0.75*math.pi, 0.75*math.pi + 1.5*math.pi)

  gfx.set(0.08, 0.08, 0.1, ua)
  gfx.circle(cx, cy, math.max(3, r-2), 1)

  local ang = 0.75 * math.pi + val * 1.5 * math.pi
  if is_out then
    if is_width then gfx.set(1.0, 0.5, 0.2, ua) else gfx.set(0.9, 0.2, 0.2, ua) end
  else gfx.set(0.2, 0.8, 0.4, ua) end
  gfx.line(cx + math.cos(ang)*(r*0.2), cy + math.sin(ang)*(r*0.2),
           cx + math.cos(ang)*(r-2), cy + math.sin(ang)*(r-2))

  gfx.setfont(1, "Arial", math.floor(10 * s))
  gfx.set(0.8, 0.8, 0.8, 0.9 * ua)
  local tw = gfx.measurestr(label)
  gfx.x = cx - tw * 0.5
  gfx.y = cy + r + 7 * s
  gfx.drawstr(label)

  local val_str = string.format("%.0f%%", val * 100)
  gfx.set(1, 1, 1, 0.85 * ua)
  tw = gfx.measurestr(val_str)
  gfx.x = cx - tw * 0.5
  gfx.y = cy + r + 17 * s
  gfx.drawstr(val_str)
end

function main()
  local char = gfx.getchar()
  if char < 0 then return end
  NDDOCK.tick()

  -- 1 commande / frame : resets In→Out
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

  -- Width en attente (garde Out fixe apres un drag In)
  for i, pw in pairs(pending_width) do
    reaper.gmem_write(pw.gbase + 162, pw.w)
    reaper.gmem_write(pw.gbase + 160, 3)
    pending_width[i] = nil
  end

  local w, h = gfx.w, gfx.h
  local s = SCALE * math.min(w / 250, h / 310)

  local mouse_down = (gfx.mouse_cap & 1) == 1
  local mouse_click = mouse_down and not last_mouse_down
  last_mouse_down = mouse_down
  local now_t = reaper.time_precise()
  local hb_timeout = 3.0

  gfx.set(0.08, 0.08, 0.10)
  gfx.rect(0, 0, w, h, 1)

  gfx.setfont(1, "Arial", math.floor(12 * s), "b")
  gfx.set(0.85, 0.35, 0.40)
  gfx.x = 6 * s
  gfx.y = 4 * s
  gfx.drawstr("TWISTER")

  local cell_w = 58 * s
  local cell_h = 72 * s
  local start_x = (w - COLS * cell_w) * 0.5
  local start_y = 22 * s
  local kr = KNOB_R * s
  local tw_id = 0

  for row = 0, ROWS-1 do
    for col = 0, COLS-1 do
      local looper_idx = row * 2 + math.floor(col / 2)
      local is_out = (col % 2) == 1

      local cx = start_x + col * cell_w + cell_w * 0.5
      local cy = start_y + row * cell_h + 22 * s

      local base0 = 1000 + looper_idx * 600
      local has_looper = (reaper.gmem_read(base0) or 0) > 0
                      and (now_t - (reaper.gmem_read(130 + looper_idx) or 0)) <= hb_timeout

      local active_p = reaper.gmem_read(base0 + 42) or 1
      if active_p < 1 or active_p > 3 then active_p = 1 end
      local gbase = base0 + (active_p - 1) * 200

      local len   = reaper.gmem_read(gbase + 46) or 0
      local in_s  = reaper.gmem_read(gbase + 44) or 0
      local w_s   = reaper.gmem_read(gbase + 45) or 0

      local in_norm    = (len > 0) and (in_s / len) or 0
      local out_norm   = (len > 0) and ((in_s + w_s) / len) or 0
      local width_norm = (len > 0) and (w_s / len) or 0

      local is_width = tw_mode[looper_idx + 1] == 1
      local val_norm = is_out and (is_width and width_norm or out_norm) or in_norm
      val_norm = math.max(0, math.min(1, val_norm))
      local label = is_out and (is_width and "Width" or "Out") or "In"

      local hov = has_looper
                and gfx.mouse_x >= cx - 20*s and gfx.mouse_x <= cx + 20*s
                and gfx.mouse_y >= cy - 20*s and gfx.mouse_y <= cy + 20*s

      if mouse_down then
        if mouse_click and hov and tw_active_id < 0 then
          tw_active_id = tw_id
          tw_drag_start_y = gfx.mouse_y
          tw_drag_start_val = val_norm
          tw_has_moved = 0
          -- Mode In/Out : figer Out au debut du drag In (In ne doit pas le repousser)
          if not is_out and not is_width and len > 0 then
            tw_lock_out[tw_id] = math.min(len, in_s + w_s)
          else
            tw_lock_out[tw_id] = nil
          end
        end
        if tw_active_id == tw_id and has_looper and len > 0 then
          local dy = tw_drag_start_y - gfx.mouse_y
          if math.abs(dy) > 2 then
            tw_has_moved = 1
            val_norm = math.max(0, math.min(1, tw_drag_start_val + dy * 0.005))
            if is_out then
              if is_width then
                -- Width libre
                reaper.gmem_write(gbase + 162, val_norm * len)
                reaper.gmem_write(gbase + 160, 3)
              else
                -- Out : ne peut pas passer avant In
                local new_out = math.max(in_s, math.min(len, val_norm * len))
                val_norm = new_out / len
                reaper.gmem_write(gbase + 162, new_out)
                reaper.gmem_write(gbase + 160, 2)
              end
            else
              if is_width then
                reaper.gmem_write(gbase + 161, val_norm * len)
                reaper.gmem_write(gbase + 160, 5)
              else
                -- In (mode In/Out) : borne par Out fige, Width suit pour ne pas pousser Out
                local out_pos = tw_lock_out[tw_id] or math.min(len, in_s + w_s)
                local new_in = math.max(0, math.min(out_pos, val_norm * len))
                local new_w  = math.max(0, out_pos - new_in)
                val_norm = (len > 0) and (new_in / len) or 0
                reaper.gmem_write(gbase + 161, new_in)
                reaper.gmem_write(gbase + 160, 1)
                pending_width[looper_idx + 1] = { gbase = gbase, w = new_w }
              end
            end
          end
        end
      else
        if tw_active_id == tw_id then
          if tw_has_moved == 0 and has_looper then
            if is_out then
              tw_mode[looper_idx + 1] = 1 - tw_mode[looper_idx + 1]
            else
              if len > 0 then
                pending_reset[looper_idx + 1] = { gbase = gbase, len = len, step = 1 }
              end
            end
          end
          tw_lock_out[tw_id] = nil
          tw_active_id = -1
        end
      end

      if has_looper then
        draw_knob(cx, cy, kr, val_norm, label, is_width, is_out, true, s)
      else
        gfx.set(0.15, 0.15, 0.18)
        gfx.circle(cx, cy, 16 * s, 1)
        gfx.set(0.25, 0.25, 0.3)
        gfx.circle(cx, cy, 16 * s, 0)
        gfx.set(0.35, 0.35, 0.4)
        gfx.setfont(1, "Arial", math.floor(11 * s))
        local tw = gfx.measurestr("-")
        gfx.x = cx - tw * 0.5
        gfx.y = cy - 5 * s
        gfx.drawstr("-")
      end

      tw_id = tw_id + 1
    end
  end

  gfx.update()
  reaper.defer(main)
end

init()
reaper.defer(main)