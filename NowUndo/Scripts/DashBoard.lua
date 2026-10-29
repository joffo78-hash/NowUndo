-- @description NowUndo Dashboard (Light) - Compact
-- @version 1.3
-- @author Assistant

local SCALE = 1.0
local MAX_INST = 8
local COLS = 4
local PANEL_W = 185
local PANEL_H = 290   -- 240 avant : place pour 4 lignes de sources en gros texte
local MARGIN = 10

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

function init()
  reaper.gmem_attach("nowundo_sync")
  local w = math.floor((COLS * (PANEL_W + MARGIN) + MARGIN + 8) * SCALE)
  local h = math.floor((2 * (PANEL_H + MARGIN) + 42) * SCALE)
  NDDOCK.init("NowUndo Dashboard", "NowUndo_Dashboard", w, h)
  gfx.clear = 0x0C0C0F
end

local last_mouse_down = false
local clr_all_press_time = 0
local clr_all_long_pressed = 0

-- Donnees publiees par le script Virtual Launchpad dans le gmem "nowundo_sync" (cf. dash_publish du Lua) :
--   [DASH_BASE + n] groupe du looper n | [+10 + n] masque des INPUTS entrants | [+20 + n] masque des LOOPERS entrants
local DASH_BASE = 6000
local GROUP_RGB = { {1.00, 0.25, 0.25}, {0.23, 0.48, 1.00}, {0.19, 0.88, 0.38}, {0.88, 0.25, 1.00} }   -- = GROUP_COL du Launchpad

local function get_looper_color(hue)
  if hue == 1 then return 0.36, 0.08, 0.08
  elseif hue == 2 then return 0.40, 0.20, 0.04
  elseif hue == 3 then return 0.34, 0.31, 0.04
  elseif hue == 4 then return 0.08, 0.30, 0.10
  elseif hue == 5 then return 0.04, 0.29, 0.33
  elseif hue == 6 then return 0.08, 0.14, 0.40
  elseif hue == 7 then return 0.26, 0.09, 0.36
  elseif hue == 8 then return 0.40, 0.09, 0.26
  else return 0.25, 0.25, 0.28 end
end

function main()
  local char = gfx.getchar()
  if char < 0 then return end
  NDDOCK.tick()

  local w, h = gfx.w, gfx.h
  local s = SCALE * math.min(w / 780, h / 540)

  local mouse_down = (gfx.mouse_cap & 1) == 1
  local mouse_click = mouse_down and not last_mouse_down
  last_mouse_down = mouse_down
  local now_t = reaper.time_precise()
  local hb_timeout = 3.0

  gfx.set(0.08, 0.08, 0.10)
  gfx.rect(0, 0, w, h, 1)

  -- Titre
  gfx.setfont(1, "Arial", math.floor(14 * s), "b")
  gfx.set(0.85, 0.35, 0.40)
  gfx.x = 10 * s
  gfx.y = 8 * s
  gfx.drawstr("NOWUNDO DASHBOARD")

  -- CLEAR ALL (collé à droite du titre)
  local clear_all_w = 110 * s
  local clear_all_h = 22 * s
  local clear_all_x = w - clear_all_w - 10 * s
  local clear_all_y = 6 * s
  local clr_all_hov = gfx.mouse_x >= clear_all_x and gfx.mouse_x < clear_all_x + clear_all_w
                   and gfx.mouse_y >= clear_all_y and gfx.mouse_y < clear_all_y + clear_all_h

  local clr_all_progress = 0
  if clr_all_press_time > 0 and mouse_down and clr_all_hov and clr_all_long_pressed == 0 then
    clr_all_progress = math.min(1.0, (now_t - clr_all_press_time) / 1.0)
  end

  if clr_all_hov then gfx.set(0.6, 0.15, 0.18, 1)
  else gfx.set(0.35, 0.1, 0.12, 1) end
  gfx.rect(clear_all_x, clear_all_y, clear_all_w, clear_all_h, 1)

  if clr_all_progress > 0 then
    gfx.set(0.9, 0.2, 0.2, 0.5)
    gfx.rect(clear_all_x, clear_all_y, clear_all_w * clr_all_progress, clear_all_h, 1)
  end

  gfx.set(0.85, 0.35, 0.40, 1)
  gfx.rect(clear_all_x, clear_all_y, clear_all_w, clear_all_h, 0)

  gfx.setfont(1, "Arial", math.floor(11 * s), "b")
  gfx.set(1, 0.9, 0.9, 1)
  local tw = gfx.measurestr(clr_all_progress > 0 and "CLEAR ALL..." or "CLEAR ALL")
  gfx.x = clear_all_x + (clear_all_w - tw) * 0.5
  gfx.y = clear_all_y + 4 * s
  gfx.drawstr(clr_all_progress > 0 and "CLEAR ALL..." or "CLEAR ALL")

  if mouse_click and clr_all_hov then
    clr_all_press_time = now_t
    clr_all_long_pressed = 0
  end

  if mouse_down and clr_all_hov and clr_all_long_pressed == 0 and clr_all_press_time > 0 then
    if (now_t - clr_all_press_time) >= 1.0 then
      clr_all_long_pressed = 1
      for ca_i = 0, MAX_INST-1 do
        local ca_base_0 = 1000 + ca_i * 600
        local ca_id = reaper.gmem_read(ca_base_0 + 0) or 0
        local ca_hb_ok = (now_t - (reaper.gmem_read(130 + ca_i) or 0)) <= 3.0
        if ca_id > 0 and ca_hb_ok then
          local ca_active_p = reaper.gmem_read(ca_base_0 + 42) or 1
          local ca_p = (ca_active_p >= 1 and ca_active_p <= 3) and (ca_active_p - 1) or 0
          reaper.gmem_write(1000 + ca_i * 600 + ca_p * 200 + 48, 11)
        end
      end
    end
  end

  if not mouse_down and clr_all_hov and clr_all_long_pressed == 0
     and clr_all_press_time > 0 and (now_t - clr_all_press_time) < 1.0 then
    for ca_i = 0, MAX_INST-1 do
      local ca_base_0 = 1000 + ca_i * 600
      local ca_id = reaper.gmem_read(ca_base_0 + 0) or 0
      local ca_hb_ok = (now_t - (reaper.gmem_read(130 + ca_i) or 0)) <= 3.0
      if ca_id > 0 and ca_hb_ok then
        local ca_active_p = reaper.gmem_read(ca_base_0 + 42) or 1
        local ca_p = (ca_active_p >= 1 and ca_active_p <= 3) and (ca_active_p - 1) or 0
        reaper.gmem_write(1000 + ca_i * 600 + ca_p * 200 + 48, 2)
      end
    end
    clr_all_press_time = 0
  end
  if not mouse_down then clr_all_press_time = 0 end

  -- Heartbeat cleanup
  for si = 0, MAX_INST-1 do
    local hb = reaper.gmem_read(130 + si) or 0
    if (reaper.gmem_read(100 + si) or 0) > 0 and (now_t - hb) > hb_timeout then
      reaper.gmem_write(100 + si, 0)
      reaper.gmem_write(130 + si, 0)
      reaper.gmem_write(160 + si, 0)
      for pi = 0, 2 do reaper.gmem_write(1000 + si * 600 + pi * 200, 0) end
    end
  end

  local master_instance_idx = reaper.gmem_read(910) or -1
  local sync_master_len = 0
  if master_instance_idx >= 0 and master_instance_idx < MAX_INST then
    sync_master_len = reaper.gmem_read(1000 + master_instance_idx * 600 + 46) or 0
  end
  if sync_master_len <= 0 then sync_master_len = reaper.gmem_read(1000 + 46) or 0 end

  -- Slots
  local start_x = 8 * s
  local start_y = 34 * s
  local panel_w = PANEL_W * s
  local panel_h = PANEL_H * s
  local margin_x = MARGIN * s
  local margin_y = MARGIN * s
  local num_active = 0

  for slot_i = 0, MAX_INST-1 do
    local inst_idx = slot_i
    local gmem_base_0 = 1000 + inst_idx * 600
    local active_p = reaper.gmem_read(gmem_base_0 + 42) or 0
    local hb_ok = (now_t - (reaper.gmem_read(130 + inst_idx) or 0)) <= hb_timeout
    local is_active = (reaper.gmem_read(gmem_base_0) or 0) > 0 and hb_ok and active_p >= 1 and active_p <= 3

    local row = math.floor(inst_idx / COLS)
    local col = inst_idx % COLS
    local x = start_x + col * (panel_w + margin_x)
    local y = start_y + row * (panel_h + margin_y)

    if is_active then
      num_active = num_active + 1
      local p = active_p - 1
      local gmem_base = 1000 + inst_idx * 600 + p * 200

      local pc_n = math.floor((reaper.gmem_read(160 + inst_idx) or 0) + 0.5)
      if pc_n < 1 then pc_n = (inst_idx % 8) + 1 end
      local r_col, g_col, b_col = get_looper_color(pc_n)

      gfx.set(r_col, g_col, b_col)
      gfx.rect(x, y, panel_w, panel_h, 1)
      gfx.set(r_col + 0.1, g_col + 0.05, b_col + 0.05)
      gfx.rect(x, y, panel_w, panel_h, 0)
      gfx.set(0.85, 0.35, 0.40)
      gfx.rect(x, y, panel_w, 2 * s, 1)

      local inst_alias = reaper.gmem_read(gmem_base + 1) or (inst_idx + 1)
      local state = reaper.gmem_read(gmem_base + 2) or 0
      local length = reaper.gmem_read(gmem_base + 46) or 0
      local loop_start = reaper.gmem_read(gmem_base + 44) or 0
      local loop_width = reaper.gmem_read(gmem_base + 45) or 0
      local clock_pct = reaper.gmem_read(gmem_base + 23) or 0
      local real_pos_pct = reaper.gmem_read(gmem_base + 47) or 0

      local dur_str = "-"
      if inst_idx == master_instance_idx then dur_str = "1/1"
      elseif sync_master_len > 0 and length > 0 then
        local ratio = length / sync_master_len
        if math.abs(ratio - 1.0) < 0.05 then dur_str = "1/1"
        elseif math.abs(ratio - 2.0) < 0.05 then dur_str = "x2"
        elseif math.abs(ratio - 0.5) < 0.05 then dur_str = "1/2"
        elseif math.abs(ratio - 4.0) < 0.05 then dur_str = "x4"
        elseif math.abs(ratio - 0.25) < 0.05 then dur_str = "1/4"
        else dur_str = string.format("%.2f", ratio) end
      end

      local part_name = (p == 0) and "Main" or ((p == 1) and "Chorus" or "Bridge")
      local title_str = string.format("L%d - %s [%s]", inst_alias, part_name, dur_str)

      gfx.setfont(1, "Arial", math.floor(11 * s), "b")
      gfx.set(1, 1, 1, 0.9)
      gfx.x = x + 6 * s
      gfx.y = y + 5 * s
      gfx.drawstr(title_str)

      local sname = ({[1]="REC",[2]="PLAY",[3]="DUB",[4]="REPL",[5]="A-REP",[6]="MULT",[7]="WAIT",[8]="SYNC"})[state] or "STOP"
      if state == 1 then gfx.set(0.9, 0.2, 0.2)
      elseif state == 2 then gfx.set(0.2, 0.8, 0.35)
      elseif state == 3 then gfx.set(0.95, 0.7, 0.2)
      elseif state == 4 then gfx.set(0.25, 0.55, 0.95)
      elseif state == 5 then gfx.set(0.95, 0.5, 0.25)
      elseif state == 6 then gfx.set(0.7, 0.3, 0.85)
      elseif state == 7 or state == 8 then gfx.set(0.9, 0.5, 0.1)
      else gfx.set(0.5, 0.5, 0.55) end
      gfx.circle(x + panel_w - 12 * s, y + 11 * s, 4.5 * s, 1)

      gfx.set(0.7, 0.7, 0.7)
      gfx.setfont(1, "Arial", math.floor(10 * s))
      gfx.x = x + panel_w - 48 * s
      gfx.y = y + 5 * s
      gfx.drawstr(sname)

      -- Clock bar
      local bar_x, bar_y, bar_w, bar_h = x + 78 * s, y + 9 * s, 38 * s, 5 * s
      gfx.set(0.12, 0.04, 0.05)
      gfx.rect(bar_x, bar_y, bar_w, bar_h, 1)
      local fill_w = math.floor((clock_pct / 100.0) * bar_w)
      if fill_w > 0 then
        gfx.set(0.85, 0.35, 0.40, 0.85)
        gfx.rect(bar_x + 1, bar_y + 1, math.max(0, fill_w - 2), bar_h - 2, 1)
      end

      -- Waveform
      local wav_x, wav_y, wav_w, wav_h = x + 6 * s, y + 26 * s, panel_w - 12 * s, 72 * s
      gfx.set(0.10, 0.03, 0.04)
      gfx.rect(wav_x, wav_y, wav_w, wav_h, 1)
      local mid_y = wav_y + wav_h * 0.5
      local w_step = wav_w / 100
      gfx.set(0.2, 0.85, 0.3, 0.85)
      for wi = 0, 99 do
        local w_val = reaper.gmem_read(gmem_base + 50 + wi) or 0
        local w_h = math.min(w_val, 1) * (wav_h * 0.45)
        gfx.line(wav_x + wi * w_step, mid_y - w_h, wav_x + wi * w_step, mid_y + w_h)
      end

      -- IN/OUT Markers & Out-of-bounds overlay
      if length > 0 then
        local cur_end = math.min(loop_start + loop_width, length)
        local start_x_px = wav_x + (loop_start / length) * wav_w
        local end_x_px = wav_x + (cur_end / length) * wav_w

        -- Overlay sombre hors sélection
        gfx.set(0, 0, 0, 0.55)
        if start_x_px > wav_x then
          gfx.rect(wav_x, wav_y, start_x_px - wav_x, wav_h)
        end
        if end_x_px < wav_x + wav_w then
          gfx.rect(end_x_px, wav_y, wav_x + wav_w - end_x_px, wav_h)
        end

        -- Marqueur IN (Vert)
        gfx.set(0.2, 0.9, 0.3, 0.95)
        gfx.rect(start_x_px, wav_y, math.max(1, 1 * s), wav_h)
        gfx.triangle(start_x_px, wav_y, start_x_px + 6 * s, wav_y, start_x_px, wav_y + 6 * s)

        -- Marqueur OUT (Orange)
        gfx.set(0.9, 0.4, 0.2, 0.95)
        gfx.rect(end_x_px, wav_y, math.max(1, 1 * s), wav_h)
        gfx.triangle(end_x_px, wav_y, end_x_px - 6 * s, wav_y, end_x_px, wav_y + 6 * s)
      end

      -- Curseur de lecture
      if length > 0 or state == 1 or state == 8 then
        local cursor_x = math.max(wav_x, math.min(wav_x + wav_w, wav_x + (real_pos_pct / 100.0) * wav_w))
        gfx.set(1, 0.3, 0.3, 0.95)
        gfx.line(cursor_x, wav_y, cursor_x, wav_y + wav_h)
        gfx.rect(cursor_x - 2 * s, wav_y, 4 * s, 5 * s, 1)
      end

      -- Boutons
      local btn_y1 = y + 103 * s
      local btn_w1, btn_h1, spacing1 = 30 * s, 19 * s, 2 * s
      local cur_bx1 = x + 8 * s

      local function btn(hov_check, cmd, active, r, g, b, draw_func)
        local hov = hov_check
        if hov and mouse_click then reaper.gmem_write(gmem_base + 48, cmd) end
        gfx.set(active and r or 0.22, active and g or 0.07, active and b or 0.09, 1)
        if hov then gfx.set(math.min(1, gfx.r+0.15), math.min(1, gfx.g+0.1), math.min(1, gfx.b+0.1), 1) end
        gfx.rect(cur_bx1, btn_y1, btn_w1, btn_h1, 1)
        draw_func(cur_bx1, btn_y1, btn_w1, btn_h1)
        cur_bx1 = cur_bx1 + btn_w1 + spacing1
      end

      -- REC
      btn(gfx.mouse_x >= cur_bx1 and gfx.mouse_x < cur_bx1+btn_w1 and gfx.mouse_y >= btn_y1 and gfx.mouse_y < btn_y1+btn_h1,
          1, (state==1 or state==3 or state==8), 0.9, 0.2, 0.09,
          function(bx,by,bw,bh) gfx.set(0.95,0.25,0.25,1) gfx.circle(bx+bw*0.5, by+bh*0.5, 3.5*s, 1) end)

      -- PLAY
      btn(gfx.mouse_x >= cur_bx1 and gfx.mouse_x < cur_bx1+btn_w1 and gfx.mouse_y >= btn_y1 and gfx.mouse_y < btn_y1+btn_h1,
          3, state==2, 0.15, 0.55, 0.3,
          function(bx,by,bw,bh)
            gfx.set(0.25,0.85,0.4,1)
            local mx,my = bx+bw*0.5, by+bh*0.5
            if state==2 then gfx.rect(mx-2.5*s, my-2.5*s, 5*s, 5*s, 1)
            else gfx.triangle(mx-2.5*s, my-3.5*s, mx-2.5*s, my+3.5*s, mx+3.5*s, my) end
          end)

      -- CLEAR
      btn(gfx.mouse_x >= cur_bx1 and gfx.mouse_x < cur_bx1+btn_w1 and gfx.mouse_y >= btn_y1 and gfx.mouse_y < btn_y1+btn_h1,
          2, false, 0.22, 0.07, 0.09,
          function(bx,by,bw,bh)
            gfx.set(0.85,0.35,0.4,1)
            local cx,cy = bx+bw*0.5, by+bh*0.5
            gfx.line(cx-2.5*s, cy-2.5*s, cx+2.5*s, cy+2.5*s)
            gfx.line(cx-2.5*s, cy+2.5*s, cx+2.5*s, cy-2.5*s)
          end)

      -- REV
      local rev_on = (reaper.gmem_read(gmem_base + 17) or 0) > 0
      btn(gfx.mouse_x >= cur_bx1 and gfx.mouse_x < cur_bx1+btn_w1 and gfx.mouse_y >= btn_y1 and gfx.mouse_y < btn_y1+btn_h1,
          4, rev_on, 0.35, 0.15, 0.15,
          function(bx,by,bw,bh)
            gfx.set(0.85,0.4,0.3,1)
            local mx,my = bx+bw*0.5, by+bh*0.5
            gfx.triangle(mx-3.5*s, my-2.5*s, mx+3.5*s, my-2.5*s, mx, my+2.5*s)
          end)

      -- PP
      local pp_on = (reaper.gmem_read(gmem_base + 18) or 0) > 0
      btn(gfx.mouse_x >= cur_bx1 and gfx.mouse_x < cur_bx1+btn_w1 and gfx.mouse_y >= btn_y1 and gfx.mouse_y < btn_y1+btn_h1,
          5, pp_on, 0.35, 0.15, 0.15,
          function(bx,by,bw,bh)
            gfx.set(0.85,0.4,0.3,1)
            local cx,cy = bx+bw*0.5, by+bh*0.5
            gfx.line(cx-3.5*s, cy, cx, cy-1.8*s)
            gfx.line(cx, cy-1.8*s, cx+3.5*s, cy)
            gfx.line(cx+3.5*s, cy, cx, cy+1.8*s)
            gfx.line(cx, cy+1.8*s, cx-3.5*s, cy)
          end)

      -- Ligne 2
      local btn_y2 = y + 126 * s
      local btn_w2, btn_h2, spacing2 = 29 * s, 18 * s, 2 * s
      local cur_bx2 = x + 8 * s

      local function text_btn(label, cmd, active, r, g, b)
        local hov = gfx.mouse_x >= cur_bx2 and gfx.mouse_x < cur_bx2+btn_w2 and gfx.mouse_y >= btn_y2 and gfx.mouse_y < btn_y2+btn_h2
        if hov and mouse_click then reaper.gmem_write(gmem_base + 48, cmd) end
        gfx.set(active and r or 0.22, active and g or 0.07, active and b or 0.09, 1)
        if hov then gfx.set(math.min(1,gfx.r+0.15), math.min(1,gfx.g+0.1), math.min(1,gfx.b+0.1), 1) end
        gfx.rect(cur_bx2, btn_y2, btn_w2, btn_h2, 1)
        gfx.setfont(1, "Arial", math.floor(10 * s), "b")
        gfx.set(0.95, 0.75, 0.2, 1)
        local tw = gfx.measurestr(label)
        gfx.x = cur_bx2 + (btn_w2 - tw) * 0.5
        gfx.y = btn_y2 + 3 * s
        gfx.drawstr(label)
        cur_bx2 = cur_bx2 + btn_w2 + spacing2
      end

      text_btn("Sli", 6, (reaper.gmem_read(gmem_base + 8) or 0) == 1, 0.35, 0.3, 0.08)
      text_btn("Cld", 7, (reaper.gmem_read(gmem_base + 24) or 0) > 0, 0.15, 0.35, 0.4)
      text_btn("Rep", 9, state == 4, 0.25, 0.55, 0.95)
      text_btn("Aut", 10, state == 5, 0.95, 0.5, 0.25)
      text_btn("Lnk", 8, (reaper.gmem_read(gmem_base + 9) or 0) > 0, 0.35, 0.15, 0.15)

      -- ===== Bloc statut (sous la ligne 2) : synchro Maitre/Esclave | groupe | sources entrantes =====
      local ds_i = math.floor((inst_alias or 0) + 0.5)                -- numero de looper affiche dans le titre
      if ds_i < 1 or ds_i > 8 then ds_i = inst_idx + 1 end
      local ds_grp = math.floor((reaper.gmem_read(DASH_BASE + ds_i) or 0) + 0.5)
      local ds_inm = math.floor((reaper.gmem_read(DASH_BASE + 10 + ds_i) or 0) + 0.5)
      local ds_lm  = math.floor((reaper.gmem_read(DASH_BASE + 20 + ds_i) or 0) + 0.5)

      local ds_x, ds_w = x + 11 * s, panel_w - 22 * s
      local ds_y1, ds_h = y + 152 * s, 20 * s
      gfx.set(0, 0, 0, 0.25)
      gfx.line(x + 8 * s, y + 148 * s, x + panel_w - 8 * s, y + 148 * s)

      -- Synchro : MASTER / SLAVE (+ rapport de duree)
      local ds_mw = 82 * s
      local is_master = (inst_idx == master_instance_idx)
      local sync_txt = is_master and "MASTER" or ((dur_str ~= "-") and ("SLAVE " .. dur_str) or "SLAVE")
      if is_master then gfx.set(0.35, 0.30, 0.08, 1) else gfx.set(0.10, 0.18, 0.30, 1) end
      gfx.rect(ds_x, ds_y1, ds_mw, ds_h, 1)
      if is_master then gfx.set(0.95, 0.75, 0.2, 1) else gfx.set(0.45, 0.65, 0.95, 1) end
      gfx.rect(ds_x, ds_y1, ds_mw, ds_h, 0)
      gfx.setfont(1, "Arial", math.floor(11 * s), "b")
      local tw, th = gfx.measurestr(sync_txt)
      if is_master then gfx.set(1, 0.85, 0.3, 1) else gfx.set(0.7, 0.85, 1, 1) end
      gfx.x, gfx.y = ds_x + (ds_mw - tw) * 0.5, ds_y1 + (ds_h - th) * 0.5
      gfx.drawstr(sync_txt)

      -- Groupe : encart a la couleur du groupe
      local ds_gx = ds_x + ds_mw + 4 * s
      local ds_gw = ds_w - ds_mw - 4 * s
      local gc = GROUP_RGB[ds_grp]
      local g_txt
      if gc then
        gfx.set(gc[1] * 0.45, gc[2] * 0.45, gc[3] * 0.45, 1)
        gfx.rect(ds_gx, ds_y1, ds_gw, ds_h, 1)
        gfx.set(gc[1], gc[2], gc[3], 1)
        gfx.rect(ds_gx, ds_y1, ds_gw, ds_h, 0)
        gfx.rect(ds_gx, ds_y1, 4 * s, ds_h, 1)
        g_txt = "GROUP " .. ds_grp
        gfx.set(1, 1, 1, 1)
      else
        gfx.set(0.10, 0.10, 0.13, 1)
        gfx.rect(ds_gx, ds_y1, ds_gw, ds_h, 1)
        gfx.set(0.25, 0.25, 0.30, 1)
        gfx.rect(ds_gx, ds_y1, ds_gw, ds_h, 0)
        g_txt = "NO GROUP"
        gfx.set(0.5, 0.5, 0.55, 1)
      end
      tw, th = gfx.measurestr(g_txt)
      gfx.x, gfx.y = ds_gx + 4 * s + (ds_gw - 4 * s - tw) * 0.5, ds_y1 + (ds_h - th) * 0.5
      gfx.drawstr(g_txt)

      -- Sources : inputs empiles dans la 1re colonne, loopers dans la 2e (texte 2x plus gros ; reduit seulement si trop de lignes)
      local src_in, src_lp = {}, {}
      for k = 0, 7 do
        if ((ds_inm >> k) & 1) == 1 then src_in[#src_in + 1] = "in " .. (k + 1) end
        if ((ds_lm  >> k) & 1) == 1 then src_lp[#src_lp + 1] = "L" .. (k + 1) end
      end
      local ds_y2 = ds_y1 + ds_h + 6 * s
      local rows = math.max(#src_in, #src_lp)
      if rows == 0 then
        gfx.setfont(1, "Arial", math.floor(22 * s))
        gfx.set(0.5, 0.5, 0.55, 1)
        gfx.x, gfx.y = ds_x, ds_y2
        gfx.drawstr("-")
      else
        local fs = 22 * s                                    -- 2x l'ancienne taille (11)
        local step = fs * 1.2
        local avail = (y + panel_h) - ds_y2 - 6 * s
        if rows * step > avail then step = avail / rows; fs = step / 1.2 end   -- garde-fou : tout doit tenir dans le panneau
        gfx.setfont(1, "Arial", math.max(8, math.floor(fs)))
        local col2_x = ds_x + ds_w * 0.5
        gfx.set(0.9, 0.9, 0.9, 1)
        for n, txt in ipairs(src_in) do
          gfx.x, gfx.y = ds_x, ds_y2 + (n - 1) * step
          gfx.drawstr(txt)
        end
        gfx.set(0.95, 0.8, 0.45, 1)
        for n, txt in ipairs(src_lp) do
          gfx.x, gfx.y = col2_x, ds_y2 + (n - 1) * step
          gfx.drawstr(txt)
        end
      end
    else
      gfx.set(0.12, 0.12, 0.15)
      gfx.rect(x, y, panel_w, panel_h, 1)
      gfx.set(0.2, 0.2, 0.25)
      gfx.rect(x, y, panel_w, panel_h, 0)
      gfx.setfont(1, "Arial", math.floor(11 * s), "b")
      gfx.set(0.4, 0.4, 0.45, 0.8)
      gfx.x = x + 6 * s
      gfx.y = y + 5 * s
      gfx.drawstr(string.format("Slot %d - Vide", inst_idx + 1))
    end
  end

  if num_active == 0 then
    gfx.set(0.65, 0.55, 0.58)
    gfx.setfont(1, "Arial", math.floor(12 * s))
    gfx.x = 12 * s
    gfx.y = 50 * s
    gfx.drawstr("Aucune instance active detectee.")
  end

  gfx.update()
  reaper.defer(main)
end

init()
reaper.defer(main)