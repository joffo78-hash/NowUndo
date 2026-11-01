-- @description NowUndo Twister Control - Multi pages virtuelles
-- @version 2.8
-- @about
--   Page 1 In/Out | 2 Pitch/Speed | 3 Vol/Feedback | 4 Slicer | 5 Cloud
--   Selection via Launchpad fighter page (ExtState nowundo_vl/fighter_page)
--   Mode A groupes : deltas relatifs pour pages 1-3
--   Pages 4-5 : looper (ou membres du groupe) selectionne
--   MIDI Learn : lit les maps "tw:knob:N" / "tw:btn:N" (ExtState NowUndo_MIDILearn)
--     et applique selon la page active — le hardware suit le soft.
--
-- Couleurs virtuelles : 1 vert, 2 rose, 3 rouge, 4 jaune, 5 bleu

local SCALE = 1.0
local COLS, ROWS, KNOB_R = 4, 4, 17
local DASH_BASE = 6000
local GMEM = "nowundo_sync"
local VL_SEC = "nowundo_vl"

local PAGE_COL = {
  [1] = {0.20, 0.75, 0.40},  -- vert
  [2] = {0.95, 0.40, 0.70},  -- rose
  [3] = {0.90, 0.25, 0.25},  -- rouge
  [4] = {0.95, 0.85, 0.20},  -- jaune
  [5] = {0.25, 0.55, 0.95},  -- bleu
}
local PAGE_NAME = {
  [1] = "In/Out", [2] = "Pitch/Speed", [3] = "Vol/Feedback",
  [4] = "Slicer", [5] = "Cloud",
}

--------------------------------------------------------------------------
-- Dock
--------------------------------------------------------------------------
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

--------------------------------------------------------------------------
-- Gmem helpers
--------------------------------------------------------------------------
local function gbase(looper_1, part)
  part = part or 1
  return 1000 + (looper_1 - 1) * 600 + (part - 1) * 200
end

local function looper_alive(i, now_t)
  local base0 = 1000 + (i - 1) * 600
  if (reaper.gmem_read(base0) or 0) <= 0 then return false end
  if (now_t - (reaper.gmem_read(130 + (i - 1)) or 0)) > 3.0 then return false end
  return true
end

local function active_part(i)
  local p = reaper.gmem_read(gbase(i, 1) + 42) or 1
  if p < 1 or p > 3 then p = 1 end
  return math.floor(p + 0.5)
end

local function read_fb(i, off)
  local b = gbase(i, active_part(i))
  return reaper.gmem_read(b + off) or 0
end

local function write_param(i, id, value)
  local b = gbase(i, active_part(i))
  reaper.gmem_write(b + 181, value)
  reaper.gmem_write(b + 180, id)
end

local function write_edit(i, cmd, v1, v2)
  local b = gbase(i, active_part(i))
  if v1 ~= nil then reaper.gmem_write(b + 161, v1) end
  if v2 ~= nil then reaper.gmem_write(b + 162, v2) end
  reaper.gmem_write(b + 160, cmd)
end

local function group_of(i)
  local g = math.floor((reaper.gmem_read(DASH_BASE + i) or 0) + 0.5)
  if g < 1 or g > 4 then return 0 end
  return g
end

local function group_peers(i)
  local g = group_of(i)
  if g == 0 then return {} end
  local t = {}
  for j = 1, 8 do if j ~= i and group_of(j) == g then t[#t + 1] = j end end
  return t
end

local function fighter_page()
  local p = tonumber(reaper.GetExtState(VL_SEC, "fighter_page")) or 1
  return math.max(1, math.min(5, math.floor(p)))
end

local function sel_looper()
  local s = tonumber(reaper.GetExtState(VL_SEC, "sel_looper")) or 1
  return math.max(1, math.min(8, math.floor(s)))
end

-- Cibles page 4/5 : membres du groupe du looper selectionne, sinon lui seul
local function page_targets()
  local s = sel_looper()
  local g = group_of(s)
  if g > 0 then
    local t = { s }
    for _, j in ipairs(group_peers(s)) do t[#t + 1] = j end
    return t
  end
  return { s }
end

--------------------------------------------------------------------------
-- Mapping valeurs <-> knob 0..1
--------------------------------------------------------------------------
local function clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end

-- Pitch -48..48, centre 0
local function pitch_to_n(p) return clamp((p + 48) / 96, 0, 1) end
local function n_to_pitch(n) return n * 96 - 48 end

-- Speed log 0.25..4 centre 1
local function speed_to_n(s)
  s = math.max(0.01, s)
  local logv = math.log(s) / math.log(2)  -- -2..2 for 0.25..4
  return clamp((logv + 2) / 4, 0, 1)
end
local function n_to_speed(n)
  local logv = n * 4 - 2
  return 2 ^ logv
end

-- Vol / feedback 0..2, centre 1
local function vol_to_n(v) return clamp(v / 2, 0, 1) end
local function n_to_vol(n) return n * 2 end

-- Generiques 0..1 et plages
local function lin_to_n(v, lo, hi) return clamp((v - lo) / (hi - lo), 0, 1) end
local function n_to_lin(n, lo, hi) return lo + n * (hi - lo) end

--------------------------------------------------------------------------
-- Etat interaction
--------------------------------------------------------------------------
local tw_mode_io = {0,0,0,0,0,0,0,0}  -- width mode page 1
local active_id = -1
local drag_start_y, drag_start_n, has_moved = 0, 0, 0
local last_mouse_down = false
local pending_reset, pending_width = {}, {}
local lock_out = {}
local drag = nil  -- snapshot drag

local function snapshot_peers_io(src)
  local snaps = {}
  for _, peer in ipairs(group_peers(src)) do
    if looper_alive(peer, reaper.time_precise()) then
      local len = read_fb(peer, 46)
      local ins = read_fb(peer, 44)
      local ws = read_fb(peer, 45)
      if len > 0 then
        snaps[peer] = { len = len, in0 = ins, out0 = ins + ws, w0 = ws, part = active_part(peer) }
      end
    end
  end
  return snaps
end

local function apply_peers_io(peers, kind, d_norm)
  if not peers then return end
  for peer, snap in pairs(peers) do
    local len, d = snap.len, d_norm * snap.len
    if len > 0 then
      local b = gbase(peer, snap.part or active_part(peer))
      if kind == "in" then
        local out_pos = math.min(len, snap.out0)
        local new_in = math.max(0, math.min(out_pos, snap.in0 + d))
        reaper.gmem_write(b + 161, new_in)
        reaper.gmem_write(b + 160, 1)
        -- JSFX cmd1 garde Out ; pas de cmd3 qui ecraserait
      elseif kind == "out" then
        local new_out = math.max(snap.in0, math.min(len, snap.out0 + d))
        reaper.gmem_write(b + 162, new_out)
        reaper.gmem_write(b + 160, 2)
      elseif kind == "width" then
        local new_w = math.max(0, math.min(len - snap.in0, snap.w0 + d))
        reaper.gmem_write(b + 162, new_w)
        reaper.gmem_write(b + 160, 3)
      end
    end
  end
end

-- Snapshot valeurs scalaires pour pages 2-3
local function snapshot_peers_scalar(src, read_fn)
  local snaps = {}
  for _, peer in ipairs(group_peers(src)) do
    if looper_alive(peer, reaper.time_precise()) then
      snaps[peer] = read_fn(peer)
    end
  end
  return snaps
end

--------------------------------------------------------------------------
-- Descripteurs de knobs par page
-- cell(row,col) -> { label, get(i), set(i,v), norm_get, norm_set, def, kind, push? }
--------------------------------------------------------------------------
local function io_cells()
  -- 8 loopers x (In, Out) : row = looper/2, col = (looper%2)*2 + is_out
  -- same layout as before
end

-- Param write IDs (JSFX)
local PID = {
  speed = 3, pitch = 4, feedback = 19, out_vol = 22,
  cloud_density = 26, cloud_chaos = 27, cloud_spread = 28,
  slicer_pitch = 34, cloud_pitch = 35, cloud_mix = 36,
  cloud_pos = 38, cloud_lfo_rate = 40, cloud_lfo_depth = 41,
  -- lecture seule / futurs (offsets feedback)
  trans_sens = 11, trans_hold = 12, grain_fade = 13,
  slicer_mode = 14, slicer_sub = 15, slice_decay = 16,
  slicer_src = 32, grid_sub = 33, cloud_pos_mode = 37, cloud_lfo_shape = 39,
  sampler_root = 150,
}

local function make_scalar_page_pitch_speed()
  -- row 0-1 : pitch L1-8 ; row 2-3 : speed L1-8
  local cells = {}
  for i = 1, 8 do
    local r = math.floor((i - 1) / 4)
    local c = (i - 1) % 4
    cells[r .. "," .. c] = {
      looper = i, label = "L" .. i .. " Pitch",
      get = function(li) return read_fb(li, 4) end,
      set = function(li, v) write_param(li, PID.pitch, clamp(v, -48, 48)) end,
      to_n = pitch_to_n, from_n = n_to_pitch, def = 0,
      group_delta = function(a, b) return b - a end, -- semitones
      apply_delta = function(li, base, d) write_param(li, PID.pitch, clamp(base + d, -48, 48)) end,
    }
  end
  for i = 1, 8 do
    local r = 2 + math.floor((i - 1) / 4)
    local c = (i - 1) % 4
    cells[r .. "," .. c] = {
      looper = i, label = "L" .. i .. " Speed",
      get = function(li) return read_fb(li, 3) end,
      set = function(li, v) write_param(li, PID.speed, clamp(v, 0.01, 100)) end,
      to_n = speed_to_n, from_n = n_to_speed, def = 1,
      group_delta = function(a, b)
        -- ratio multiplicatif en log2
        if a <= 0 then return 0 end
        return math.log(b / a) / math.log(2)
      end,
      apply_delta = function(li, base, d)
        write_param(li, PID.speed, clamp(base * (2 ^ d), 0.01, 100))
      end,
    }
  end
  return cells
end

local function make_scalar_page_vol_fb()
  local cells = {}
  for i = 1, 8 do
    local r = math.floor((i - 1) / 4)
    local c = (i - 1) % 4
    cells[r .. "," .. c] = {
      looper = i, label = "L" .. i .. " Vol",
      get = function(li) return read_fb(li, 22) end,
      set = function(li, v) write_param(li, PID.out_vol, clamp(v, 0, 2)) end,
      to_n = vol_to_n, from_n = n_to_vol, def = 1,
      group_delta = function(a, b) return b - a end,
      apply_delta = function(li, base, d) write_param(li, PID.out_vol, clamp(base + d, 0, 2)) end,
    }
  end
  for i = 1, 8 do
    local r = 2 + math.floor((i - 1) / 4)
    local c = (i - 1) % 4
    cells[r .. "," .. c] = {
      looper = i, label = "L" .. i .. " Fdbk",
      get = function(li) return read_fb(li, 19) end,
      set = function(li, v) write_param(li, PID.feedback, clamp(v, 0, 2)) end,
      to_n = vol_to_n, from_n = n_to_vol, def = 1,
      group_delta = function(a, b) return b - a end,
      apply_delta = function(li, base, d) write_param(li, PID.feedback, clamp(base + d, 0, 2)) end,
    }
  end
  return cells
end

-- Pages 4/5 : cible = premier target (sel), set applique a tous les targets
local function tgt_set_param(id, value)
  for _, li in ipairs(page_targets()) do
    write_param(li, id, value)
  end
end
local function tgt_get(off)
  local t = page_targets()
  return read_fb(t[1], off)
end

local function make_slicer_page()
  local cells = {}
  local function cell(r, c, label, off, id, lo, hi, def)
    cells[r .. "," .. c] = {
      label = label, looper = nil,
      get = function() return tgt_get(off) end,
      set = function(_, v)
        if id then tgt_set_param(id, clamp(v, lo, hi)) end
      end,
      to_n = function(v) return lin_to_n(v, lo, hi) end,
      from_n = function(n) return n_to_lin(n, lo, hi) end,
      def = def,
      push = function() if id then tgt_set_param(id, def) end end,
    }
  end
  -- row0 : detect, hold, decay, pitch spread
  cell(0, 0, "Detect", 165, 50, 0.01, 0.8, 0.15)
  cell(0, 1, "Hold", 166, 51, 30, 1000, 120)
  cell(0, 2, "Decay", 16, 16, 10, 2000, 150)
  cell(0, 3, "Pitch", 34, 34, 0, 100, 0)
  -- row1 : steps, max, preset, mode
  cell(1, 0, "Steps", 167, 47, 1, 32, 16)
  cell(1, 1, "Max", 168, 48, 0, 64, 0)
  cell(1, 2, "Preset", 169, 49, 1, 4, 1)
  cell(1, 3, "Mode", 14, 14, 0, 5, 0)
  -- row2 : rate, src (push toggle)
  cell(2, 0, "Rate", 15, 15, 0, 5, 0)
  cells["2,1"] = {
    label = "Src",
    get = function() return tgt_get(32) end,
    set = function(_, v) tgt_set_param(32, v >= 0.5 and 1 or 0) end,
    to_n = function(v) return v > 0.5 and 1 or 0 end,
    from_n = function(n) return n >= 0.5 and 1 or 0 end,
    def = 0,
    push = function()
      local cur = tgt_get(32)
      tgt_set_param(32, cur > 0.5 and 0 or 1)
    end,
  }
  -- row3 : root, release, empty, pitch mode (push toggle)
  cell(3, 0, "Root", 150, 42, 0, 127, 48)
  cell(3, 1, "Release", 170, 44, 0, 3000, 0)
  cells["3,3"] = {
    label = "PitchMd",
    get = function() return tgt_get(171) end,
    set = function(_, v) tgt_set_param(43, v >= 0.5 and 1 or 0) end,
    to_n = function(v) return v > 0.5 and 1 or 0 end,
    from_n = function(n) return n >= 0.5 and 1 or 0 end,
    def = 0,
    push = function()
      local cur = tgt_get(171)
      tgt_set_param(43, cur > 0.5 and 0 or 1)
    end,
  }
  return cells
end

local function make_cloud_page()
  local cells = {}
  local function cell(r, c, label, off, id, lo, hi, def)
    cells[r .. "," .. c] = {
      label = label,
      get = function() return tgt_get(off) end,
      set = function(_, v) if id then tgt_set_param(id, clamp(v, lo, hi)) end end,
      to_n = function(v) return lin_to_n(v, lo, hi) end,
      from_n = function(n) return n_to_lin(n, lo, hi) end,
      def = def, write_id = id,
      push = function() if id then tgt_set_param(id, def) end end,
    }
  end
  cell(0, 0, "Density", 26, PID.cloud_density, 0, 1, 0.5)
  cell(0, 1, "Chaos", 27, PID.cloud_chaos, 0, 1, 0)
  cell(0, 2, "Spread", 28, PID.cloud_spread, 0, 1, 0.1)
  cell(0, 3, "PSpread", 35, PID.cloud_pitch, 0, 100, 0)
  cell(1, 0, "Pos", 38, PID.cloud_pos, 0, 100, 50)
  cells["1,0"].push = function()
    local cur = tgt_get(37)
    tgt_set_param(37, cur > 0.5 and 0 or 1)
  end
  cell(1, 1, "Rate", 40, PID.cloud_lfo_rate, 0.1, 4, 1)
  cell(1, 2, "Depth", 41, PID.cloud_lfo_depth, 0, 100, 0)
  cells["1,3"] = {
    label = "LFO",
    get = function() return tgt_get(39) end,
    set = function(_, v) tgt_set_param(39, clamp(v, 0, 2)) end,
    to_n = function(v) return clamp(v / 2, 0, 1) end,
    from_n = function(n) return n * 2 end,
    def = 0,
    push = function() tgt_set_param(39, 0) end,
  }
  return cells
end

local PAGES = {
  [2] = make_scalar_page_pitch_speed(),
  [3] = make_scalar_page_vol_fb(),
  [4] = make_slicer_page(),
  [5] = make_cloud_page(),
}

--------------------------------------------------------------------------
-- Dessin
--------------------------------------------------------------------------
local function draw_arc(cx, cy, r, a0, a1)
  local n = math.max(1, math.ceil(math.abs(a1 - a0) / 0.12))
  local step = (a1 - a0) / n
  local aa = a0
  for _ = 1, n do
    local bb = aa + step
    gfx.line(cx + math.cos(aa)*r, cy + math.sin(aa)*r, cx + math.cos(bb)*r, cy + math.sin(bb)*r)
    gfx.line(cx + math.cos(aa)*(r-1), cy + math.sin(aa)*(r-1), cx + math.cos(bb)*(r-1), cy + math.sin(bb)*(r-1))
    aa = bb
  end
end

local function draw_knob(cx, cy, r, val, label, col, s, grouped, dim)
  local ua = dim and 0.35 or 1
  local led_r = r + 3
  local cr, cg, cb = col[1], col[2], col[3]
  gfx.set(0.15, 0.15, 0.18, ua)
  gfx.circle(cx, cy, led_r, 1)
  gfx.set(0.3, 0.3, 0.35, ua)
  gfx.circle(cx, cy, led_r, 0)
  for i = 0, 15 do
    local t = (i + 0.5) / 16
    local ang = 0.75 * math.pi + t * 1.5 * math.pi
    if t <= val then gfx.set(cr, cg, cb, ua) else gfx.set(0.35, 0.35, 0.4, ua) end
    gfx.circle(cx + math.cos(ang)*led_r, cy + math.sin(ang)*led_r, math.max(1, r*0.07), 1)
  end
  gfx.set(cr, cg, cb, 0.3 * ua)
  draw_arc(cx, cy, led_r + 2, 0.75*math.pi, 0.75*math.pi + 1.5*math.pi)
  gfx.set(0.08, 0.08, 0.1, ua)
  gfx.circle(cx, cy, math.max(3, r-2), 1)
  local ang = 0.75 * math.pi + val * 1.5 * math.pi
  gfx.set(cr, cg, cb, ua)
  gfx.line(cx + math.cos(ang)*(r*0.2), cy + math.sin(ang)*(r*0.2),
           cx + math.cos(ang)*(r-2), cy + math.sin(ang)*(r-2))
  if grouped then
    gfx.set(1, 1, 1, 0.9)
    gfx.circle(cx + r * 0.7, cy - r * 0.7, math.max(2, r * 0.16), 1)
  end
  gfx.setfont(1, "Arial", math.floor(9 * s))
  gfx.set(0.85, 0.85, 0.85, 0.9 * ua)
  local tw = gfx.measurestr(label or "")
  gfx.x = cx - tw * 0.5
  gfx.y = cy + r + 6 * s
  gfx.drawstr(label or "")
  local vs = string.format("%.0f%%", val * 100)
  gfx.set(1, 1, 1, 0.85 * ua)
  tw = gfx.measurestr(vs)
  gfx.x = cx - tw * 0.5
  gfx.y = cy + r + 16 * s
  gfx.drawstr(vs)
end

--------------------------------------------------------------------------
-- Init / loop
--------------------------------------------------------------------------
function init()
  reaper.gmem_attach(GMEM)
  local w = math.floor((COLS * 58 + 16) * SCALE)
  local h = math.floor((ROWS * 72 + 40) * SCALE)
  NDDOCK.init("NowUndo Twister", "NowUndo_Twister", w, h)
  gfx.clear = 0x0C0C0F
end


--------------------------------------------------------------------------
-- MIDI Learn (maps produites par nowundo_midi_learn.lua)
-- Uniquement tw:knob:0..15 et tw:btn:0..15 — page = fighter_page()
--------------------------------------------------------------------------
local LEARN_EXT = "NowUndo_MIDILearn"
local IGNORE_DEV_SUBSTR = { "lpminimk3", "launchpad", "lpmini" }
local midi_maps = {}       -- id -> { status, ch, d1, gate, ret }
local midi_last_seq = 0
local midi_maps_sig = ""
local midi_maps_t = 0
local midi_out_idx = tonumber(reaper.GetExtState(LEARN_EXT, "midi_out")) or -1
local last_fighter_page = -1

local function midi_reload_maps(force)
  local t = reaper.time_precise()
  if not force and (t - midi_maps_t) < 0.5 then return end
  midi_maps_t = t
  local raw = reaper.GetExtState(LEARN_EXT, "maps") or ""
  if raw == midi_maps_sig and not force then return end
  midi_maps_sig = raw
  midi_maps = {}
  for line in raw:gmatch("[^\n]+") do
    local id, st, ch, d1, d2, ret, gate = line:match("^([^|]+)|(%d+)|(%d+)|(%d+)|(%-?%d+)|(%d+)|(%d+)$")
    if id and (id:match("^tw:knob:%d+$") or id:match("^tw:btn:%d+$")) then
      midi_maps[id] = {
        status = tonumber(st), ch = tonumber(ch), d1 = tonumber(d1),
        gate = gate == "1", ret = ret == "1",
      }
    end
  end
  midi_out_idx = tonumber(reaper.GetExtState(LEARN_EXT, "midi_out")) or -1
end

-- Applique un slot physique 0..15 selon la page Twister courante

local function midi_send(m, val)
  if not m or midi_out_idx < 0 then return end
  if not reaper.SendMIDIMessageToHardware then return end
  local v = math.max(0, math.min(127, math.floor(val + 0.5)))
  if m.status == 0xB0 then
    pcall(reaper.SendMIDIMessageToHardware, midi_out_idx, string.char(0xB0 + (m.ch or 0), m.d1 or 0, v))
  elseif m.status == 0x90 or m.status == 0x80 then
    pcall(reaper.SendMIDIMessageToHardware, midi_out_idx, string.char(0x90 + (m.ch or 0), m.d1 or 0, v))
  end
end

-- Valeur normalisee 0..1 du knob physique idx pour la page donnee
local function read_knob_norm(page, idx, now_t)
  now_t = now_t or reaper.time_precise()
  if page == 1 then
    local looper = math.floor(idx / 2) + 1
    local is_out = (idx % 2) == 1
    if not looper_alive(looper, now_t) then return 0 end
    local len = read_fb(looper, 46)
    if len <= 0 then return 0 end
    local in_s = read_fb(looper, 44)
    local w_s = read_fb(looper, 45)
    if is_out then
      if tw_mode_io[looper] == 1 then return clamp(w_s / len, 0, 1) end
      return clamp((in_s + w_s) / len, 0, 1)
    end
    return clamp(in_s / len, 0, 1)
  elseif page == 2 then
    local looper = (idx % 8) + 1
    if not looper_alive(looper, now_t) then return 0 end
    if idx < 8 then
      local p = read_fb(looper, 4) -- check offset - pitch might be different
      -- gmem feedback: pitch at base+? use same as write_param id 4 path
      -- published at gmem_base offsets - pitch typically slider
      local b = gbase(looper, active_part(looper))
      local pitch = reaper.gmem_read(b + 4) or 0 -- may need correct offset
      return clamp((pitch + 48) / 96, 0, 1)
    else
      local b = gbase(looper, active_part(looper))
      local speed = reaper.gmem_read(b + 3) or 1
      speed = math.max(0.01, speed)
      local logv = math.log(speed) / math.log(2)
      return clamp((logv + 2) / 4, 0, 1)
    end
  elseif page == 3 then
    local looper = (idx % 8) + 1
    if not looper_alive(looper, now_t) then return 0 end
    local b = gbase(looper, active_part(looper))
    if idx < 8 then
      return clamp((reaper.gmem_read(b + 22) or 1) / 2, 0, 1)
    else
      return clamp((reaper.gmem_read(b + 19) or 1) / 2, 0, 1)
    end
  elseif page == 4 then
    -- offsets de LECTURE gmem publies par le JSFX
    local map = {
      [0]={165,0.01,0.8},[1]={166,30,1000},[2]={16,10,2000},[3]={34,0,100},
      [4]={167,1,32},[5]={168,0,64},[6]={169,1,4},[7]={14,0,5},
      [8]={15,0,5},[9]={32,0,1},[12]={42,0,127},[13]={170,0,3000},[15]={171,0,1},
    }
    local sp = map[idx]
    if not sp then return 0 end
    local tg = page_targets()
    local i = tg[1]
    if not i or not looper_alive(i, now_t) then return 0 end
    local b = gbase(i, active_part(i))
    local v = reaper.gmem_read(b + sp[1]) or sp[2]
    return clamp((v - sp[2]) / math.max(1e-9, sp[3] - sp[2]), 0, 1)
  elseif page == 5 then
    local map = {
      [0]={26,0,1},[1]={27,0,1},[2]={28,0,1},[3]={35,0,100},
      [4]={38,0,100},[5]={40,0.1,4},[6]={41,0,100},[7]={39,0,2},
    }
    local sp = map[idx]
    if not sp then return 0 end
    local tg = page_targets()
    local i = tg[1]
    if not i or not looper_alive(i, now_t) then return 0 end
    local b = gbase(i, active_part(i))
    local v = reaper.gmem_read(b + sp[1]) or sp[2]
    return clamp((v - sp[2]) / math.max(1e-9, sp[3] - sp[2]), 0, 1)
  end
  return 0
end


local midi_fb_status = ""
local midi_fb_count = 0
local midi_fb_last_t = 0
local midi_fb_last = {}
for i = 0, 15 do midi_fb_last[i] = -1 end
local midi_fb_sync_t = 0

local function midi_out_name()
  if midi_out_idx < 0 or not reaper.GetMIDIOutputName then return "(aucun)" end
  local ok, name = reaper.GetMIDIOutputName(midi_out_idx, "")
  return (ok and name) and name or ("out#" .. tostring(midi_out_idx))
end

local function resolve_midi_out()
  local stored = tonumber(reaper.GetExtState(LEARN_EXT, "midi_out"))
  if stored and stored >= 0 then
    midi_out_idx = stored
    return midi_out_idx
  end
  if midi_out_idx >= 0 then return midi_out_idx end
  if not reaper.GetNumMIDIOutputs then return -1 end
  local n = reaper.GetNumMIDIOutputs() or 0
  local prefer = nil
  for i = 0, n - 1 do
    local ok, name = reaper.GetMIDIOutputName(i, "")
    if ok and name then
      local low = name:lower()
      local skip = false
      for _, sub in ipairs(IGNORE_DEV_SUBSTR) do
        if low:find(sub, 1, true) then skip = true; break end
      end
      if not skip then
        -- prefer "twister" / "fighter" in the name
        if low:find("twister", 1, true) or low:find("fighter", 1, true) or low:find("djtechtools", 1, true) then
          midi_out_idx = i
          reaper.SetExtState(LEARN_EXT, "midi_out", tostring(i), true)
          return i
        end
        if not prefer then prefer = i end
      end
    end
  end
  if prefer then
    midi_out_idx = prefer
    reaper.SetExtState(LEARN_EXT, "midi_out", tostring(prefer), true)
    return prefer
  end
  return -1
end

local function pick_midi_out()
  if not reaper.GetNumMIDIOutputs then return end
  local n = reaper.GetNumMIDIOutputs() or 0
  local menu, idxs = {}, {}
  for i = 0, n - 1 do
    local ok, name = reaper.GetMIDIOutputName(i, "")
    if ok and name then
      menu[#menu + 1] = ((i == midi_out_idx) and "!" or "") .. name
      idxs[#idxs + 1] = i
    end
  end
  menu[#menu + 1] = ""
  menu[#menu + 1] = "Aucun"
  local pick = gfx.showmenu(table.concat(menu, "|"))
  if not pick or pick < 1 then return end
  if pick <= #idxs then
    midi_out_idx = idxs[pick]
    reaper.SetExtState(LEARN_EXT, "midi_out", tostring(midi_out_idx), true)
  else
    midi_out_idx = -1
    reaper.SetExtState(LEARN_EXT, "midi_out", "-1", true)
  end
  midi_fb_status = "OUT: " .. midi_out_name()
  last_fighter_page = -1  -- force renvoi au prochain cycle
end

local function midi_feedback_page(page)
  midi_reload_maps(true)
  local nmaps = 0
  for id, m in pairs(midi_maps) do
    if id:find("tw:knob:", 1, true) and m.status and m.status > 0 then nmaps = nmaps + 1 end
  end
  if resolve_midi_out() < 0 then
    midi_fb_status = "FB: pas de MIDI OUT (clic header)"
    return
  end
  if nmaps == 0 then
    midi_fb_status = "FB: aucun knob learn (tw:knob)"
    return
  end
  local now_t = reaper.time_precise()
  local sent = 0
  for idx = 0, 15 do
    local id = string.format("tw:knob:%d", idx)
    local m = midi_maps[id]
    if m and m.status and m.status > 0 then
      local n = read_knob_norm(page, idx, now_t)
      -- Toujours envoyer (meme si ret non coche) au changement de page
      midi_send(m, n * 127)
      sent = sent + 1
    end
  end
  midi_fb_count = sent
  midi_fb_last_t = now_t
  midi_fb_status = string.format("FB P%d: %d CC -> %s", page, sent, midi_out_name())
  for idx = 0, 15 do
    local id = string.format("tw:knob:%d", idx)
    if midi_maps[id] then
      midi_fb_last[idx] = math.floor(read_knob_norm(page, idx, now_t) * 127 + 0.5)
    end
  end
end

-- Feedback continu quand gmem / UI virtuelle change
local function midi_feedback_sync(page, force)
  local t = reaper.time_precise()
  if not force and (t - midi_fb_sync_t) < 0.03 then return end
  midi_fb_sync_t = t
  if resolve_midi_out() < 0 then return end
  midi_reload_maps(false)
  local changed = 0
  for idx = 0, 15 do
    local id = string.format("tw:knob:%d", idx)
    local m = midi_maps[id]
    if m and m.status and m.status > 0 then
      local n = read_knob_norm(page, idx, t)
      local v = math.max(0, math.min(127, math.floor(n * 127 + 0.5)))
      if force or midi_fb_last[idx] ~= v then
        midi_send(m, v)
        midi_fb_last[idx] = v
        changed = changed + 1
      end
    end
  end
  if changed > 0 then
    midi_fb_last_t = t
    midi_fb_status = string.format("FB live x%d | %s", changed, midi_out_name())
  end
end

local function midi_apply_knob(idx, norm)
  local page = fighter_page()
  norm = math.max(0, math.min(1, norm))
  local now_t = reaper.time_precise()
  if page == 1 then
    -- Mode Out (tw_mode_io==0) : In = cmd1 (Out fixe), Out = cmd2
    -- Mode Width (tw_mode_io==1) : In = cmd5 (Width fixe), Width = cmd3
    local looper = math.floor(idx / 2) + 1
    local is_out = (idx % 2) == 1
    if not looper_alive(looper, now_t) then return end
    local b = gbase(looper, active_part(looper))
    local len = reaper.gmem_read(b + 46) or 0
    if len <= 0 then return end
    local in_s = reaper.gmem_read(b + 44) or 0
    local w_s = reaper.gmem_read(b + 45) or 0
    local is_width = (tw_mode_io[looper] == 1)
    if is_out then
      if is_width then
        local new_w = math.max(0, math.min(len - in_s, norm * len))
        reaper.gmem_write(b + 162, new_w)
        reaper.gmem_write(b + 160, 3)
      else
        local out = math.max(in_s, math.min(len, norm * len))
        reaper.gmem_write(b + 162, out)
        reaper.gmem_write(b + 160, 2)
      end
    else
      local new_in = math.max(0, math.min(len, norm * len))
      if is_width then
        -- garder width : cmd 5
        reaper.gmem_write(b + 161, new_in)
        reaper.gmem_write(b + 160, 5)
      else
        -- garder Out : cmd 1 (JSFX recalcule width)
        local out_pos = math.min(len, in_s + w_s)
        new_in = math.max(0, math.min(out_pos, new_in))
        reaper.gmem_write(b + 161, new_in)
        reaper.gmem_write(b + 160, 1)
      end
    end
  elseif page == 2 then
    local looper = (idx % 8) + 1
    if not looper_alive(looper, now_t) then return end
    if idx < 8 then write_param(looper, 4, norm * 96 - 48)
    else write_param(looper, 3, 2 ^ (norm * 4 - 2)) end
  elseif page == 3 then
    local looper = (idx % 8) + 1
    if not looper_alive(looper, now_t) then return end
    if idx < 8 then write_param(looper, 22, norm * 2)
    else write_param(looper, 19, norm * 2) end
  elseif page == 4 then
    local map = {
      [0]={50,0.01,0.8},[1]={51,30,1000},[2]={16,10,2000},[3]={34,0,100},
      [4]={47,1,32},[5]={48,0,64},[6]={49,1,4},[7]={14,0,5},
      [8]={15,0,5},[9]={32,0,1},[12]={42,0,127},[13]={44,0,3000},[15]={43,0,1},
    }
    local sp = map[idx]
    if not sp then return end
    local v = sp[2] + norm * (sp[3] - sp[2])
    for _, i in ipairs(page_targets()) do
      if looper_alive(i, now_t) then write_param(i, sp[1], v) end
    end
  elseif page == 5 then
    local map = {
      [0]={26,0,1},[1]={27,0,1},[2]={28,0,1},[3]={35,0,100},
      [4]={38,0,100},[5]={40,0.1,4},[6]={41,0,100},[7]={39,0,2},
    }
    local sp = map[idx]
    if not sp then return end
    local v = sp[2] + norm * (sp[3] - sp[2])
    for _, i in ipairs(page_targets()) do
      if looper_alive(i, now_t) then write_param(i, sp[1], v) end
    end
  end
end

local function midi_apply_btn(idx)
  local page = fighter_page()
  local now_t = reaper.time_precise()
  if page == 1 then
    local looper = math.floor(idx / 2) + 1
    local is_out = (idx % 2) == 1
    if not looper_alive(looper, now_t) then return end
    if is_out then
      -- Push Out : bascule mode In/Out <-> In/Width
      tw_mode_io[looper] = 1 - (tw_mode_io[looper] or 0)
    else
      -- Push In : reset In/Out (boucle pleine)
      local b = gbase(looper, active_part(looper))
      local len = reaper.gmem_read(b + 46) or 0
      if len > 0 then
        pending_reset[looper] = { gbase = b, len = len, step = 1 }
      end
    end
  elseif page == 2 then
    local looper = (idx % 8) + 1
    if not looper_alive(looper, now_t) then return end
    if idx < 8 then write_param(looper, 4, 0) else write_param(looper, 3, 1) end
  elseif page == 3 then
    local looper = (idx % 8) + 1
    if not looper_alive(looper, now_t) then return end
    if idx < 8 then write_param(looper, 22, 1) else write_param(looper, 19, 1) end
  end
end

local function midi_process()
  if not reaper.MIDI_GetRecentInputEvent then return end
  midi_reload_maps(false)
  local i = 0
  while i < 64 do
    local seq, msg, ts, dev = reaper.MIDI_GetRecentInputEvent(i)
    if not seq or seq == 0 then break end
    if seq == midi_last_seq and i == 0 then break end
    if midi_last_seq ~= 0 and seq <= midi_last_seq then break end

    local skip = false
    if dev and type(dev) == "number" and reaper.GetMIDIInputName then
      local ok, dname = reaper.GetMIDIInputName(dev, "")
      if ok and dname then
        local low = dname:lower()
        for _, sub in ipairs(IGNORE_DEV_SUBSTR) do
          if low:find(sub, 1, true) then skip = true; break end
        end
      end
    end

    if not skip and msg and #msg >= 2 then
      local b1 = msg:byte(1)
      local st, ch = b1 & 0xF0, b1 & 0x0F
      local d1, d2 = msg:byte(2) or 0, msg:byte(3) or 0
      if st == 0x80 then st, d2 = 0x90, 0 end
      if st == 0x90 or st == 0xB0 then
        for id, m in pairs(midi_maps) do
          if m.status == st and m.ch == ch and m.d1 == d1 then
            local idx = tonumber(id:match(":(%d+)$"))
            -- idx 0 est valide (Knob 1) : ne pas utiliser "if idx then" (0 est falsy en Lua)
            if idx ~= nil then
              if id:find("knob", 1, true) then
                if st == 0xB0 then
                  midi_apply_knob(idx, d2 / 127)
                elseif st == 0x90 and d2 > 0 then
                  midi_apply_knob(idx, d2 / 127)
                end
              elseif id:find("btn", 1, true) then
                local on = (st == 0x90 and d2 > 0) or (st == 0xB0 and d2 > 0)
                if on then midi_apply_btn(idx) end
              end
            end
          end
        end
      end
    end
    if i == 0 then midi_last_seq = seq end
    i = i + 1
  end
  local seq0 = reaper.MIDI_GetRecentInputEvent(0)
  if seq0 and seq0 > 0 then midi_last_seq = seq0 end
end

function main()
  local char = gfx.getchar()
  if char < 0 then return end
  NDDOCK.tick()
  reaper.gmem_attach(GMEM)
  midi_process()

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

  local page = fighter_page()
  if page ~= last_fighter_page then
    last_fighter_page = page
    for i = 0, 15 do midi_fb_last[i] = -1 end  -- forcer renvoi complet
    midi_feedback_page(page)
  else
    midi_feedback_sync(page, false)
  end
  local col = PAGE_COL[page] or PAGE_COL[1]
  local w, h = gfx.w, gfx.h
  local s = SCALE * math.min(w / 250, h / 320)
  local mouse_down = (gfx.mouse_cap & 1) == 1
  local mouse_click = mouse_down and not last_mouse_down
  last_mouse_down = mouse_down
  local now_t = reaper.time_precise()

  gfx.set(0.08, 0.08, 0.10)
  gfx.rect(0, 0, w, h, 1)

  -- Header (clic = choix MIDI OUT + renvoi valeurs)
  gfx.setfont(1, "Arial", math.floor(11 * s), "b")
  gfx.set(col[1], col[2], col[3], 1)
  gfx.x, gfx.y = 6 * s, 4 * s
  gfx.drawstr(string.format("TWISTER  P%d %s", page, PAGE_NAME[page] or ""))
  gfx.setfont(1, "Arial", math.floor(8 * s))
  gfx.set(0.65, 0.65, 0.7, 1)
  gfx.x, gfx.y = 6 * s, 16 * s
  local fb = midi_fb_status
  if fb == "" then fb = "OUT: " .. midi_out_name() .. " | clic ici = port MIDI" end
  gfx.drawstr(fb)
  if mouse_click and gfx.mouse_y < 26 * s then
    pick_midi_out()
  end
  if page >= 4 then
    gfx.setfont(1, "Arial", math.floor(9 * s))
    gfx.set(0.7, 0.7, 0.7, 1)
    gfx.x = 6 * s
    gfx.y = 16 * s
    local tg = page_targets()
    gfx.drawstr("→ L" .. table.concat(tg, ",L"))
  end

  local cell_w, cell_h = 58 * s, 72 * s
  local start_x = (w - COLS * cell_w) * 0.5
  local start_y = 28 * s
  local kr = KNOB_R * s
  local tw_id = 0

  ------------------------------------------------------------------
  -- PAGE 1 : In/Out (logique historique)
  ------------------------------------------------------------------
  if page == 1 then
    for row = 0, ROWS - 1 do
      for coln = 0, COLS - 1 do
        local looper_idx = row * 2 + math.floor(coln / 2)
        local looper_1 = looper_idx + 1
        local is_out = (coln % 2) == 1
        local cx = start_x + coln * cell_w + cell_w * 0.5
        local cy = start_y + row * cell_h + 22 * s
        local alive = looper_alive(looper_1, now_t)
        local len = alive and read_fb(looper_1, 46) or 0
        local in_s = alive and read_fb(looper_1, 44) or 0
        local w_s = alive and read_fb(looper_1, 45) or 0
        local out_s = in_s + w_s
        local is_width = tw_mode_io[looper_1] == 1
        local val = 0
        if len > 0 then
          if is_out then val = is_width and (w_s / len) or (out_s / len)
          else val = in_s / len end
        end
        val = clamp(val, 0, 1)
        local label = is_out and (is_width and "Width" or "Out") or "In"
        local hov = alive and gfx.mouse_x >= cx - 20*s and gfx.mouse_x <= cx + 20*s
                         and gfx.mouse_y >= cy - 20*s and gfx.mouse_y <= cy + 20*s

        if mouse_down then
          if mouse_click and hov and active_id < 0 then
            active_id = tw_id
            drag_start_y = gfx.mouse_y
            drag_start_n = val
            has_moved = 0
            drag = {
              kind = "io", looper = looper_1, is_out = is_out, is_width = is_width,
              in0 = in_s, out0 = out_s, w0 = w_s, len0 = len,
              peers = snapshot_peers_io(looper_1),
            }
            if not is_out and not is_width and len > 0 then
              lock_out[tw_id] = math.min(len, out_s)
            else lock_out[tw_id] = nil end
          end
          if active_id == tw_id and alive and len > 0 and drag then
            local dy = drag_start_y - gfx.mouse_y
            if math.abs(dy) > 2 then
              has_moved = 1
              val = clamp(drag_start_n + dy * 0.005, 0, 1)
              local b = gbase(looper_1, active_part(looper_1))
              local kind, d_norm
              if is_out then
                if is_width then
                  local new_w = val * len
                  reaper.gmem_write(b + 162, new_w)
                  reaper.gmem_write(b + 160, 3)
                  kind, d_norm = "width", (drag.len0 > 0) and ((new_w - drag.w0) / drag.len0) or 0
                else
                  local new_out = math.max(in_s, math.min(len, val * len))
                  val = new_out / len
                  reaper.gmem_write(b + 162, new_out)
                  reaper.gmem_write(b + 160, 2)
                  kind, d_norm = "out", (drag.len0 > 0) and ((new_out - drag.out0) / drag.len0) or 0
                end
              else
                -- Mode Out : cmd1 (Out fixe). Mode Width : cmd5 (Width fixe).
                local new_in
                if is_width then
                  new_in = math.max(0, math.min(len, val * len))
                  val = new_in / len
                  reaper.gmem_write(b + 161, new_in)
                  reaper.gmem_write(b + 160, 5)
                  kind, d_norm = "in", (drag.len0 > 0) and ((new_in - drag.in0) / drag.len0) or 0
                else
                  local out_pos = lock_out[tw_id] or math.min(len, out_s)
                  new_in = math.max(0, math.min(out_pos, val * len))
                  val = new_in / len
                  reaper.gmem_write(b + 161, new_in)
                  reaper.gmem_write(b + 160, 1)
                  -- pas de pending_width : JSFX garde Out
                  kind, d_norm = "in", (drag.len0 > 0) and ((new_in - drag.in0) / drag.len0) or 0
                end
              end
              if kind then apply_peers_io(drag.peers, kind, d_norm) end
            end
          end
        else
          if active_id == tw_id then
            if has_moved == 0 and alive then
              if is_out then
                tw_mode_io[looper_1] = 1 - tw_mode_io[looper_1]
              elseif len > 0 then
                local b = gbase(looper_1, active_part(looper_1))
                pending_reset[looper_1] = { gbase = b, len = len, step = 1 }
                for _, peer in ipairs(group_peers(looper_1)) do
                  if looper_alive(peer, now_t) then
                    local plen = read_fb(peer, 46)
                    if plen > 0 then
                      pending_reset[peer] = { gbase = gbase(peer, active_part(peer)), len = plen, step = 1 }
                    end
                  end
                end
              end
            end
            active_id = -1
            drag = nil
            lock_out[tw_id] = nil
          end
        end

        if alive then
          draw_knob(cx, cy, kr, val, label, col, s, group_of(looper_1) > 0, false)
        else
          gfx.set(0.15, 0.15, 0.18)
          gfx.circle(cx, cy, 16 * s, 1)
        end
        tw_id = tw_id + 1
      end
    end
  else
    ------------------------------------------------------------------
    -- PAGES 2-5 : grille declarative
    ------------------------------------------------------------------
    local cells = PAGES[page] or {}
    for row = 0, ROWS - 1 do
      for coln = 0, COLS - 1 do
        local key = row .. "," .. coln
        local spec = cells[key]
        local cx = start_x + coln * cell_w + cell_w * 0.5
        local cy = start_y + row * cell_h + 22 * s
        if not spec then
          -- empty cell
          gfx.set(0.12, 0.12, 0.14, 0.5)
          gfx.circle(cx, cy, 14 * s, 1)
        else
          local li = spec.looper
          local alive = (not li) or looper_alive(li, now_t)
          local raw = 0
          if alive then
            if li then raw = spec.get(li) else raw = spec.get() end
          end
          local val = clamp(spec.to_n(raw), 0, 1)
          local hov = alive and gfx.mouse_x >= cx - 20*s and gfx.mouse_x <= cx + 20*s
                           and gfx.mouse_y >= cy - 20*s and gfx.mouse_y <= cy + 20*s

          if mouse_down then
            if mouse_click and hov and active_id < 0 then
              active_id = tw_id
              drag_start_y = gfx.mouse_y
              drag_start_n = val
              has_moved = 0
              local peers_snap = {}
              if li and spec.group_delta then
                for _, peer in ipairs(group_peers(li)) do
                  if looper_alive(peer, now_t) then
                    peers_snap[peer] = spec.get(peer)
                  end
                end
              end
              drag = {
                kind = "scalar", spec = spec, looper = li,
                base = raw, peers = peers_snap,
              }
            end
            if active_id == tw_id and alive and drag and drag.spec == spec then
              local dy = drag_start_y - gfx.mouse_y
              if math.abs(dy) > 2 then
                has_moved = 1
                val = clamp(drag_start_n + dy * 0.005, 0, 1)
                local newv = spec.from_n(val)
                if li then
                  spec.set(li, newv)
                  if spec.group_delta and drag.peers then
                    local d = spec.group_delta(drag.base, newv)
                    for peer, pbase in pairs(drag.peers) do
                      spec.apply_delta(peer, pbase, d)
                    end
                  end
                else
                  spec.set(nil, newv)
                end
              end
            end
          else
            if active_id == tw_id then
              if has_moved == 0 and alive and spec.push then
                spec.push()
              elseif has_moved == 0 and alive and li and spec.def ~= nil then
                -- reset default + peers
                spec.set(li, spec.def)
                if spec.group_delta then
                  for _, peer in ipairs(group_peers(li)) do
                    if looper_alive(peer, now_t) then spec.set(peer, spec.def) end
                  end
                end
              end
              active_id = -1
              drag = nil
            end
          end

          local grouped = li and group_of(li) > 0
          if page >= 4 then grouped = #page_targets() > 1 end
          if alive then
            draw_knob(cx, cy, kr, val, spec.label, col, s, grouped, false)
          else
            gfx.set(0.15, 0.15, 0.18)
            gfx.circle(cx, cy, 16 * s, 1)
          end
        end
        tw_id = tw_id + 1
      end
    end
  end

  gfx.update()
  reaper.defer(main)
end

init()
if reaper.MIDI_GetRecentInputEvent then midi_last_seq = reaper.MIDI_GetRecentInputEvent(0) or 0 end
midi_reload_maps(true)
resolve_midi_out()
last_fighter_page = -1  -- force FB au 1er cycle
reaper.defer(main)
