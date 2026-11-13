-- @description NowUndo Twister Control - Multi pages virtuelles
-- @version 3.4
-- @about
--   Page 1 Vol/Feedback | 2 Pitch/Speed | 3 In/Out | 4 Slicer | 5 Cloud | 6 Effets (FX Router)
--   (v3.3 : pages 1 et 3 permutees ; chaque page garde sa couleur : Vol/Feedback rouge, In/Out vert.
--    En interne les numeros logiques restent 1 = In/Out, 3 = Vol/Feedback : seul le bouton qui les appelle change.)
--   Page 5 Cloud v2 (NowUndo V3.21) : Density | Agitation | Spread | PSpread / Pos | Rate | Depth | LFO /
--     Size | Diffuse | Mix | Freeze (push) / Width (= Stereo de la section Output)
--   Page 6 : colonne = slot 1..4 de la source courante du FX Router, ligne = parametre 1..4 ; push = valeur par defaut.
--   Page 7 Custom (v3.4) : 16 knobs + 16 push assignes dans le MIDI Learn (menus) ; agissent sur le looper selectionne
--     et les membres de son groupe (knobs : meme delta, chacun garde son ecart ; push : chacun selon son etat) ;
--     couleur de chaque encodeur = famille de sa fonction (jaune slicer, rose pitch, vert in/out, bleu cloud, rouge lecture).
--   Page 8 Display (v3.4) : rangees 1-2 = position de lecture des loopers 1..8 (anneau), rangees 3-4 = VU de sortie ;
--     couleurs RGB eteintes sur le vrai Twister.
--   Selection via Launchpad fighter page (ExtState nowundo_vl/fighter_page)
--   Mode A groupes : deltas relatifs pour pages 1-3
--   Pages 4-5 : looper (ou membres du groupe) selectionne
--   MIDI Learn : lit les maps "tw:knob:N" / "tw:btn:N" (ExtState NowUndo_MIDILearn)
--     et applique selon la page active — le hardware suit le soft.
--   LEARN AUX (v3) : maps "aux:P:knob:i" / "aux:P:btn:i" = controleur dedie a la page P,
--     actif en permanence (meme page non active), avec renvoi de valeurs vers sa propre sortie.
--   Le moteur tourne meme fenetre fermee ; relancer le script rouvre la fenetre.
--
-- Couleurs virtuelles : 1 vert, 2 rose, 3 rouge, 4 jaune, 5 bleu
-- Page 6 (Effets) : une teinte douce par colonne (slot)

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
  [6] = {0.20, 0.85, 0.90},  -- cyan (header page 6)
  [7] = {0.85, 0.85, 0.88},  -- Custom (chaque knob a la couleur de sa fonction)
  [8] = {0.55, 0.57, 0.62},  -- Display
}
-- Page 6 : couleur par colonne (slot 1..4) — teintes adoucies
local PAGE6_COL = {
  [0] = {0.92, 0.58, 0.28},  -- orange doux
  [1] = {0.72, 0.42, 0.88},  -- violet
  [2] = {0.32, 0.78, 0.55},  -- vert menthe
  [3] = {0.88, 0.38, 0.42},  -- corail / rouge doux
}
local PAGE_NAME = {
  [1] = "In/Out", [2] = "Pitch/Speed", [3] = "Vol/Feedback",
  [4] = "Slicer", [5] = "Cloud", [6] = "Effets", [7] = "Custom", [8] = "Display",
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

-- v3.3 : bouton/page Launchpad 1 = Vol/Feedback, 3 = In/Out (permutation symetrique). Les numeros LOGIQUES utilises dans
-- tout le script (couleurs, contenus, maps aux) restent 1 = In/Out, 3 = Vol/Feedback.
local PAGE_SLOT_SWAP = { [1] = 3, [3] = 1 }
local function fighter_page()
  local p = tonumber(reaper.GetExtState(VL_SEC, "fighter_page")) or 1
  p = math.max(1, math.min(8, math.floor(p)))
  return PAGE_SLOT_SWAP[p] or p
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

-- Speed log 0.01..100 (vraies bornes du JSFX), centre 1 a n = 0.5 (plage symetrique en log)
local SPEED_MIN, SPEED_MAX = 0.01, 100
local SPEED_LOG = math.log(SPEED_MAX) / math.log(10)   -- = 2 decades de chaque cote de 1
local function speed_to_n(s)
  s = clamp(s, SPEED_MIN, SPEED_MAX)
  return clamp((math.log(s) / math.log(10) / SPEED_LOG + 1) / 2, 0, 1)
end
local function n_to_speed(n)
  return clamp(10 ^ ((clamp(n, 0, 1) * 2 - 1) * SPEED_LOG), SPEED_MIN, SPEED_MAX)
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
      elseif kind == "shift" then
        -- Mode In/Width : la reference du groupe est la position du OUT du looper source (= In + Width constant).
        -- Les pairs decalent donc In ET Out du meme delta, en gardant leur propre largeur (cmd 5 : Width fixe).
        local new_in = math.max(0, math.min(math.max(0, len - snap.w0), snap.in0 + d))
        reaper.gmem_write(b + 161, new_in)
        reaper.gmem_write(b + 160, 5)
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
-- Pedal Board : si un switch du pedalier virtuel est arme (mode PROG), le prochain clic sur un knob
-- n'agit pas : il publie le parametre vise dans ExtState "NowUndo_Pedal/capture".
local function pedal_capture(spec)
  if not spec or not spec.pid then return false end
  local hb = tonumber(reaper.GetExtState("NowUndo_Pedal", "armed_hb")) or 0
  if reaper.time_precise() - hb > 0.6 then return false end
  reaper.SetExtState("NowUndo_Pedal", "capture", string.format("%.6f\tpar\t%s\t\t%d\t\t\t%s\t%s",
    reaper.time_precise(), tostring(spec.label or ""), spec.pid, tostring(spec.label or ""), spec.looper and tostring(spec.looper) or ""), false)
  return true
end

local PID = {
  speed = 3, pitch = 4, feedback = 19, out_vol = 22,
  cloud_density = 26, cloud_chaos = 27, cloud_spread = 28,
  slicer_pitch = 34, cloud_pitch = 35, cloud_mix = 36,
  cloud_pos = 38, cloud_lfo_rate = 40, cloud_lfo_depth = 41,
  cloud_size = 62, cloud_freeze = 63, cloud_diffuse = 64, stereo_width = 21,   -- NowUndo V3.21 (Cloud v2)
  -- lecture seule / futurs (offsets feedback)
  trans_sens = 11, trans_hold = 12, grain_fade = 13,
  slicer_mode = 14, slicer_sub = 15, slice_decay = 16,
  slicer_src = 32, grid_sub = 33, cloud_pos_mode = 37, cloud_lfo_shape = 39,
  sampler_root = 150,
  slice_attack = 55, slicer_regen = 56, slicer_link = 58,
}

local function make_scalar_page_pitch_speed()
  -- row 0-1 : pitch L1-8 ; row 2-3 : speed L1-8
  local cells = {}
  for i = 1, 8 do
    local r = math.floor((i - 1) / 4)
    local c = (i - 1) % 4
    cells[r .. "," .. c] = {
      looper = i, pid = PID.pitch, label = "L" .. i .. " Pitch",
      get = function(li) return read_fb(li, 4) end,
      set = function(li, v) write_param(li, PID.pitch, clamp(v, -48, 48)) end,
      to_n = pitch_to_n, from_n = n_to_pitch, def = 0,
      group_delta = function(a, b) return b - a end, -- semitones
      apply_delta = function(li, base, d) write_param(li, PID.pitch, clamp(base + d, -48, 48)) end,
      disp = function(v)
        -- progressif (pas d'arrondi au demi-ton) : resolution ~0.01 st cote JSFX
        if v > 0.005 then return string.format("%+.1fst", v) end
        if v < -0.005 then return string.format("%.1fst", v) end
        return "0.0st"
      end,
    }
  end
  for i = 1, 8 do
    local r = 2 + math.floor((i - 1) / 4)
    local c = (i - 1) % 4
    cells[r .. "," .. c] = {
      looper = i, pid = PID.speed, label = "L" .. i .. " Speed",
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
      disp = function(v)
        if v >= 10 then return string.format("%.0fx", v) end
        return string.format("%.2fx", v)
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
      looper = i, pid = PID.out_vol, label = "L" .. i .. " Vol",
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
      looper = i, pid = PID.feedback, label = "L" .. i .. " Fdbk",
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
  local now_t = reaper.time_precise()
  for _, li in ipairs(page_targets()) do
    if looper_alive(li, now_t) then write_param(li, id, value) end
  end
end
local function tgt_get(off)
  local t = page_targets()
  return read_fb(t[1], off)
end

-- Decay : position knob 0..100 <-> ms (meme courbe que le JSFX, interpolation exponentielle entre points)
local DECAY_K = { {0,4}, {25,20}, {50,45}, {75,150}, {90,300}, {99,500}, {100,2000} }
local function decay_pos_to_ms(pos)
  if pos <= 0 then return 4 end
  for i = 1, #DECAY_K - 1 do
    local x0, m0, x1, m1 = DECAY_K[i][1], DECAY_K[i][2], DECAY_K[i + 1][1], DECAY_K[i + 1][2]
    if pos < x1 then return m0 * (m1 / m0) ^ ((pos - x0) / (x1 - x0)) end
  end
  return 2000
end
local function decay_ms_to_pos(ms)
  if ms > 1950 then return 100 end
  if ms <= 4 then return 0 end
  for i = 1, #DECAY_K - 1 do
    local x0, m0, x1, m1 = DECAY_K[i][1], DECAY_K[i][2], DECAY_K[i + 1][1], DECAY_K[i + 1][2]
    if ms < m1 then return x0 + (x1 - x0) * math.log(ms / m0) / math.log(m1 / m0) end
  end
  return 100
end

-- PAGE 4 SLICER (Twister) : lignes A(haut) B C D(bas), colonnes 1..4 de gauche a droite
--   A : Attack | Decay | Steps | Rate
--   B : Mode | Grid (fractions) | Preset | Max slices
--   C : Detect | Detect Hold | Root note | Release
--   D : - | - | Link Rate (push seulement) | Pitch
-- Push : remet la valeur d'init, sauf B2 (bascule Trans/Grid), B3 (Regen), C3 (Tape/Pitch si moteur arrete).
local function make_slicer_page()
  local cells = {}
  local function put(r, c, spec) cells[r .. "," .. c] = spec end

  local RATE_LBL = { [0]="1/4", [1]="1/8", [2]="1/12", [3]="1/16", [4]="1/24", [5]="1/32" }
  local GRID_LBL = { [0]="1/4", [1]="1/8", [2]="1/12", [3]="1/16", [4]="1/24",
                     [5]="1/32", [6]="1/48", [7]="1/64", [8]="1/96", [9]="1/128" }
  local MODE_LBL = { [0]="Rnd", [1]="Steps", [5]="All" }
  local NOTE_N = { "C","C#","D","D#","E","F","F#","G","G#","A","A#","B" }
  local function note_name(n)
    n = math.floor(n + 0.5)
    return NOTE_N[(n % 12) + 1] .. tostring(math.floor(n / 12) - 1)
  end
  -- Source slices : 0 = Transitoires, 1 = Grid (param 32)
  local function is_grid_src() return (tgt_get(32) or 0) > 0.5 end
  -- Mode : 0 Random, 1 Steps, 5 All
  local function mode_val() return math.floor((tgt_get(14) or 5) + 0.5) end
  local function is_link() return (tgt_get(177) or 0) > 0.5 end

  -- plage lineaire arrondie a un pas
  local function cell_lin(r, c, label, off, id, lo, hi, def, step, disp, inactive)
    step = step or 1
    put(r, c, {
      label = label, pid = id,
      get = function() return tgt_get(off) end,
      set = function(_, v) tgt_set_param(id, clamp(v, lo, hi)) end,
      to_n = function(v) return lin_to_n(v, lo, hi) end,
      from_n = function(n) return clamp(math.floor((lo + n * (hi - lo)) / step + 0.5) * step, lo, hi) end,
      def = def,
      push = function() tgt_set_param(id, def) end,
      disp = disp or function(v) return string.format("%.0f", v) end,
      inactive = inactive,
    })
  end
  -- liste de valeurs discretes (zones egales sur la course du knob)
  local function cell_list(r, c, label, off, id, vals, def, push, labels, inactive)
    local N = #vals
    put(r, c, {
      label = label, pid = id,
      get = function() return tgt_get(off) end,
      set = function(_, v) tgt_set_param(id, v) end,
      to_n = function(v)
        local best, bi = math.huge, 1
        for i, x in ipairs(vals) do
          local d = math.abs(x - v)
          if d < best then best, bi = d, i end
        end
        return (bi - 0.5) / N
      end,
      from_n = function(n) return vals[math.min(N, math.floor(n * N) + 1)] end,
      def = def,
      push = push or function() tgt_set_param(id, def) end,
      disp = function(v)
        local iv = math.floor(v + 0.5)
        if labels and labels[iv] then return labels[iv] end
        return tostring(iv)
      end,
      inactive = inactive,
    })
  end

  -- ===== Ligne A =====
  cell_lin(0, 0, "Attack", 174, PID.slice_attack, 0, 100, 0, 1,
    function(v) return string.format("%.0f", v) end)
  put(0, 1, {                                             -- Decay : 4 ms .. Infini (courbe expo)
    label = "Decay", pid = 16,
    get = function() return tgt_get(16) end,
    set = function(_, v) tgt_set_param(16, clamp(v, 4, 2000)) end,
    to_n = function(v) return decay_ms_to_pos(v) / 100 end,
    from_n = function(n)
      if n >= 0.999 then return 2000 end
      return math.floor(decay_pos_to_ms(n * 100) + 0.5)
    end,
    def = 150,
    push = function() tgt_set_param(16, 150) end,
    disp = function(v)
      if v >= 1950 then return "∞" end
      if v >= 1000 then return string.format("%.1fs", v / 1000) end
      return string.format("%.0fms", v)
    end,
  })
  -- Steps : utile seulement en mode Steps, et pas en source Grid
  cell_lin(0, 2, "Steps", 167, 47, 1, 32, 8, 1,
    function(v) return string.format("%.0f", v) end,
    function() return mode_val() ~= 1 or is_grid_src() end)
  -- Rate : inactif si Link est ON (la subdiv suit la Grid)
  cell_list(0, 3, "Rate", 15, 15, {0, 1, 2, 3, 4, 5}, 3, nil, RATE_LBL, is_link)

  -- ===== Ligne B =====
  cell_list(1, 0, "Mode", 14, 14, {0, 1, 5}, 5, nil, MODE_LBL)
  cell_list(1, 1, "Grid", 33, 33, {0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, 3,  -- 1/4 .. 1/128
    function()                                              -- push : bascule Transitoires <-> Grid
      tgt_set_param(32, tgt_get(32) > 0.5 and 0 or 1)
    end, GRID_LBL)
  cell_list(1, 2, "Preset", 169, 49, {1, 2, 3, 4}, 1,        -- push : Regen
    function() tgt_set_param(PID.slicer_regen, 1) end)
  -- Max slices detectes : 0..32 (plafond du looper). Courbe : 1ere moitie de la course = 0..4, 2e moitie = 4..32.
  -- Max : utile en detection transitoires seulement (pas en Grid)
  put(1, 3, {
    label = "Max", pid = 48,
    get = function() return tgt_get(168) end,
    set = function(_, v) tgt_set_param(48, clamp(v, 0, 32)) end,
    to_n = function(v)
      v = clamp(v, 0, 32)
      if v <= 4 then return v / 8 end
      return 0.5 + (v - 4) / 56
    end,
    from_n = function(n)
      n = clamp(n, 0, 1)
      if n <= 0.5 then return math.floor(n * 8 + 0.5) end
      return clamp(math.floor(4 + (n - 0.5) * 56 + 0.5), 4, 32)
    end,
    def = 16,
    push = function() tgt_set_param(48, 16) end,
    disp = function(v) return string.format("%.0f", v) end,
    inactive = is_grid_src,
  })

  -- ===== Ligne C =====
  -- Detect / DHold : detection transitoires uniquement
  put(2, 0, {                                              -- Detect (log 0.001..0.8), init 0.002
    label = "Detect", pid = 50,
    get = function() return tgt_get(165) end,
    set = function(_, v) tgt_set_param(50, clamp(v, 0.001, 0.8)) end,
    to_n = function(v) return clamp(math.log(math.max(v, 0.001) / 0.001) / math.log(800), 0, 1) end,
    from_n = function(n) return 0.001 * (800 ^ n) end,
    def = 0.002,
    push = function() tgt_set_param(50, 0.002) end,
    disp = function(v)
      if v < 0.01 then return string.format("%.3f", v) end
      if v < 0.1 then return string.format("%.2f", v) end
      return string.format("%.2f", v)
    end,
    inactive = is_grid_src,
  })
  cell_lin(2, 1, "DHold", 166, 51, 30, 1000, 120, 10,
    function(v)
      if v >= 1000 then return string.format("%.1fs", v / 1000) end
      return string.format("%.0fms", v)
    end,
    is_grid_src)
  put(2, 2, {                                              -- Root (init C3 = 48) ; push = Tape/Pitch si moteur arrete
    label = "Root", pid = 42,
    get = function() return tgt_get(150) end,
    set = function(_, v) tgt_set_param(42, clamp(v, 0, 127)) end,
    to_n = function(v) return lin_to_n(v, 0, 127) end,
    from_n = function(n) return math.floor(n * 127 + 0.5) end,
    def = 48,
    push = function()
      if tgt_get(2) == 0 then                              -- state 0 = looper stoppe -> moteur sampler
        tgt_set_param(43, tgt_get(171) > 0.5 and 0 or 1)
      else
        tgt_set_param(42, 48)
      end
    end,
    disp = function(v) return note_name(v) end,
  })
  put(2, 3, {                                              -- Release 0..3000 ms (courbe quadratique)
    label = "Release", pid = 44,
    get = function() return tgt_get(170) end,
    set = function(_, v) tgt_set_param(44, clamp(v, 0, 3000)) end,
    to_n = function(v) return clamp(math.sqrt(math.max(v, 0) / 3000), 0, 1) end,
    from_n = function(n)
      local r = math.floor(n * n * 3000 + 0.5)
      if r < 5 then r = 0 end
      return r
    end,
    def = 0,
    push = function() tgt_set_param(44, 0) end,
    disp = function(v)
      if v <= 0 then return "0"
      elseif v >= 1000 then return string.format("%.1fs", v / 1000)
      else return string.format("%.0fms", v) end
    end,
  })

  -- ===== Ligne D : D1-D2 libres, D3 = Link Rate (push), D4 = Pitch spread =====
  put(3, 2, {                                              -- Link Rate : slice = duree boucle / subdivision Grid
    label = "Link", pid = 58,
    get = function() return tgt_get(177) end,
    set = function() end,                                  -- le knob ne fait rien : seul le push bascule
    to_n = function(v) return v > 0.5 and 1 or 0 end,      -- anneau plein = ON, vide = OFF
    from_n = function(n) return n end,
    def = 0,
    push = function() tgt_set_param(PID.slicer_link, tgt_get(177) > 0.5 and 0 or 1) end,
    disp = function(v) return v > 0.5 and "ON" or "OFF" end,
  })
  cell_lin(3, 3, "Pitch", 34, 34, 0, 100, 0, 1,
    function(v) return string.format("%.0fst", v) end)
  return cells
end

local function make_cloud_page()
  -- NowUndo V3.21 (Cloud v2). Lignes A(haut) .. D(bas), colonnes 1..4 :
  --   A : Density | Agitation | Spread | PSpread
  --   B : Pos (push = Link/Free) | Rate | Depth | LFO
  --   C : Size (log) | Diffuse | Mix | Freeze (push = On/Off)
  --   D : Width (= Stereo de la section Output) | - | - | -
  -- Push : valeur par defaut, sauf Pos et Freeze (bascules).
  local cells = {}
  local function cell(r, c, label, off, id, lo, hi, def, disp)
    cells[r .. "," .. c] = {
      label = label, pid = id,
      get = function() return tgt_get(off) end,
      set = function(_, v) if id then tgt_set_param(id, clamp(v, lo, hi)) end end,
      to_n = function(v) return lin_to_n(v, lo, hi) end,
      from_n = function(n) return n_to_lin(n, lo, hi) end,
      def = def, write_id = id,
      push = function() if id then tgt_set_param(id, def) end end,
      disp = disp,
    }
  end
  local function pct(v) return string.format("%.0f%%", v * 100) end
  cell(0, 0, "Density", 26, PID.cloud_density, 0, 1, 0.5, pct)
  cell(0, 1, "Agitation", 27, PID.cloud_chaos, 0, 1, 0, pct)
  cell(0, 2, "Spread", 28, PID.cloud_spread, 0, 1, 0.1, pct)
  cell(0, 3, "PSpread", 35, PID.cloud_pitch, 0, 100, 0, function(v) return string.format("%.0f%%", v) end)
  cell(1, 0, "Pos", 38, PID.cloud_pos, 0, 100, 50, function(v) return string.format("%.0f%%", v) end)
  cells["1,0"].push = function()
    local cur = tgt_get(37)
    tgt_set_param(37, cur > 0.5 and 0 or 1)
  end
  cell(1, 1, "Rate", 40, PID.cloud_lfo_rate, 0.1, 4, 1, function(v) return string.format("%.1fHz", v) end)
  cell(1, 2, "Depth", 41, PID.cloud_lfo_depth, 0, 100, 0, function(v) return string.format("%.0f%%", v) end)
  cells["1,3"] = {
    label = "LFO", pid = 39,
    get = function() return tgt_get(39) end,
    set = function(_, v) tgt_set_param(39, clamp(math.floor(v + 0.5), 0, 2)) end,
    to_n = function(v) return clamp(v / 2, 0, 1) end,
    from_n = function(n) return n * 2 end,
    def = 0,
    push = function() tgt_set_param(39, 0) end,
    disp = function(v) local k = math.floor(v + 0.5); return k == 0 and "Sine" or (k == 1 and "Saw" or "InvSaw") end,
  }
  -- Size : 1 .. 1000 ms en echelle log (meme course que le bouton du looper)
  cells["2,0"] = {
    label = "Size", pid = PID.cloud_size,
    get = function() return tgt_get(190) end,
    set = function(_, v) tgt_set_param(PID.cloud_size, clamp(v, 1, 1000)) end,
    to_n = function(v) return clamp(math.log(math.max(v, 1)) / math.log(1000), 0, 1) end,
    from_n = function(n) return clamp(1000 ^ clamp(n, 0, 1), 1, 1000) end,
    def = 80,
    push = function() tgt_set_param(PID.cloud_size, 80) end,
    disp = function(v) if v >= 100 then return string.format("%.0fms", v) end return string.format("%.1fms", v) end,
  }
  cell(2, 1, "Diffuse", 192, PID.cloud_diffuse, 0, 1, 0, pct)
  cell(2, 2, "Mix", 36, PID.cloud_mix, 0, 1, 1, pct)
  cells["2,3"] = {
    label = "Freeze", pid = PID.cloud_freeze,
    get = function() return tgt_get(191) end,
    set = function() end,                                   -- le knob ne fait rien : seul le push bascule
    to_n = function(v) return v > 0.5 and 1 or 0 end,       -- anneau plein = ON
    from_n = function(n) return n end,
    def = 0,
    push = function() tgt_set_param(PID.cloud_freeze, tgt_get(191) > 0.5 and 0 or 1) end,
    disp = function(v) return v > 0.5 and "ON" or "OFF" end,
  }
  cell(3, 0, "Width", 21, PID.stereo_width, 0, 1, 0, pct)
  return cells
end

-- ===== CATALOGUE page Twister 7 "Custom" (IDENTIQUE dans nowundo_midi_learn.lua et twisterinoutreset.lua) =====
-- Familles (couleur) : play = rouge (lecture / sortie / transport), pitch = rose, inout = vert (fenetre / rec),
--                      slicer = jaune, cloud = bleu.
-- Knobs : { id, libelle, famille, wr (id ecriture JSFX), off (offset lecture gmem), lo, hi, defaut, courbe ("log" | exposant), pas, io }
--   io = "in" | "out" | "width" : fenetre de boucle (edition +160..162), valeurs en fraction de la boucle.
-- Push : { id, libelle, famille, cmd (+48), arg (+49), wr, valeur ("tog" = bascule lue a l'offset tog_off), tog_off }
CU_KNOBS = {
  { "speed",     "Speed",              "pitch",  3,  3,   0.01,  100,  1,    "log" },
  { "pitch",     "Pitch",              "pitch",  4,  4,   -48,   48,   0 },
  { "grain",     "Grain (ms)",         "pitch",  6,  6,   20,    200,  80 },
  { "grain_fade","Grain Fade %",       "pitch",  13, 13,  5,     50,   25 },
  { "mix",       "Mix",                "play",   5,  5,   0,     1,    1 },
  { "out_vol",   "Output Volume",      "play",   22, 22,  0,     2,    1 },
  { "feedback",  "Feedback",           "play",   19, 19,  0,     2,    1 },
  { "degrad",    "Degradation",        "play",   20, 20,  0,     1,    1 },
  { "stereo",    "Stereo",             "play",   21, 21,  0,     1,    0 },
  { "pos",       "Position (%)",       "play",   10, 47,  0,     100,  0 },
  { "auto_thr",  "Auto Seuil",         "play",   11, 11,  0.01,  0.8,  0.15, "log" },
  { "in",        "In",                 "inout",  0,  0,   0,     1,    0,    nil, nil, "in" },
  { "out",       "Out",                "inout",  0,  0,   0,     1,    1,    nil, nil, "out" },
  { "width",     "Width",              "inout",  0,  0,   0,     1,    1,    nil, nil, "width" },
  { "fade",      "Fade (ms)",          "inout",  7,  7,   0,     500,  10,   2 },
  { "rec_dens",  "Rec Density %",      "pitch",  29, 29,  0,     100,  100 },
  { "dens_len",  "Rec Density Length", "pitch",  30, 30,  0,     6,    2,    nil, 1 },
  { "io_frac",   "In/Out Fraction",    "inout",  59, 25,  0,     9,    0,    nil, 1 },
  { "sl_decay",  "Slice Decay",        "slicer", 16, 16,  4,     2000, 150,  "log" },
  { "sl_attack", "Slice Attack",       "slicer", 55, 174, 0,     100,  0,    nil, 1 },
  { "sl_steps",  "Slicer Steps",       "slicer", 47, 167, 1,     32,   8,    nil, 1 },
  { "sl_rate",   "Slicer Rate",        "slicer", 15, 15,  0,     5,    3,    nil, 1 },
  { "sl_grid",   "Grid Sub",           "slicer", 33, 33,  0,     9,    3,    nil, 1 },
  { "sl_max",    "Max Slices",         "slicer", 48, 168, 0,     32,   16,   nil, 1 },
  { "sl_pitch",  "Slicer Pitch Spread","slicer", 34, 34,  0,     100,  0 },
  { "sl_detect", "Detect Thresh",      "slicer", 50, 165, 0.001, 0.8,  0.01, "log" },
  { "cl_dens",   "Cloud Density",      "cloud",  26, 26,  0,     1,    0.5 },
  { "cl_agit",   "Cloud Agitation",    "cloud",  27, 27,  0,     1,    0 },
  { "cl_spread", "Cloud Spread",       "cloud",  28, 28,  0,     1,    0.1 },
  { "cl_size",   "Cloud Size",         "cloud",  62, 190, 1,     1000, 80,   "log" },
  { "cl_pitch",  "Cloud Pitch Spread", "cloud",  35, 35,  0,     100,  0 },
  { "cl_mix",    "Cloud Dry/Wet",      "cloud",  36, 36,  0,     1,    1 },
  { "sl_mix",    "Slicer Dry/Wet",     "slicer", 61, 193, 0,     1,    1 },
  { "br_mix",    "Beat Repeat Dry/Wet","inout",  60, 194, 0,     1,    1 },
  { "cl_pos",    "Cloud Pos",          "cloud",  38, 38,  0,     100,  50 },
  { "cl_diff",   "Cloud Diffuse",      "cloud",  64, 192, 0,     1,    0 },
  { "cl_lfo_r",  "Cloud LFO Rate",     "cloud",  40, 40,  0.1,   4,    1 },
  { "cl_lfo_d",  "Cloud LFO Depth",    "cloud",  41, 41,  0,     100,  0 },
}
CU_BTNS = {
  { "rec",        "Rec / Overdub",      "play",   1 },
  { "stop_play",  "Stop / Play",        "play",   3 },
  { "replace",    "Replace",            "play",   9 },
  { "auto_rep",   "Auto-Replace",       "play",   10 },
  { "multiply",   "Multiply",           "play",   13 },
  { "rerec",      "Re-Rec",             "play",   17 },
  { "restart",    "Restart",            "play",   16 },
  { "clear",      "Clear (part)",       "play",   2 },
  { "clear_full", "Clear Full",         "play",   11 },
  { "undo",       "Undo",               "play",   14 },
  { "redo",       "Redo",               "play",   15 },
  { "auto",       "Auto Rec",           "play",   19 },
  { "reverse",    "Reverse",            "play",   4 },
  { "pingpong",   "Ping-Pong",          "play",   5 },
  { "one_shot",   "One-Shot",           "play",   18 },
  { "reset",      "Reset params",       "play",   24 },
  { "link",       "Link P/S",           "pitch",  8 },
  { "speed_m",    "Speed -1 oct",       "pitch",  20, -12 },
  { "speed_p",    "Speed +1 oct",       "pitch",  20, 12 },
  { "pitch_m12",  "Pitch -12",          "pitch",  21, -12 },
  { "pitch_p12",  "Pitch +12",          "pitch",  21, 12 },
  { "pitch_m1",   "Pitch -1",           "pitch",  21, -1 },
  { "pitch_p1",   "Pitch +1",           "pitch",  21, 1 },
  { "full_loop",  "Full Loop",          "inout",  22 },
  { "quant",      "Quantise In/Out",    "inout",  23 },
  { "beat_rep",   "Beat Repeat",        "inout",  33 },
  { "slicer",     "Slicer on/off",      "slicer", 6 },
  { "sl_regen",   "Slicer Regen",       "slicer", nil, nil, 56, 1 },
  { "sl_src",     "Slicer Trans/Grid",  "slicer", nil, nil, 32, "tog", 32 },
  { "sl_link",    "Slicer Link",        "slicer", nil, nil, 58, "tog", 177 },
  { "cloud",      "Cloud on/off",       "cloud",  7 },
  { "cl_freeze",  "Cloud Freeze",       "cloud",  nil, nil, 63, "tog", 191 },
  { "cl_posmode", "Cloud Pos Link/Free","cloud",  nil, nil, 37, "tog", 37 },
  { "knob_def",   "Defaut du knob",     "" },
}
CU_FAM_NAME = { { "play", "Lecture / Sortie / Transport" }, { "pitch", "Pitch / Speed / Grain" },
                { "inout", "In / Out / Rec" }, { "slicer", "Slicer" }, { "cloud", "Cloud" }, { "", "Autre" } }

-- ===== v3.4 : moteur des pages 7 (Custom) et 8 (Display) — tout dans la table CU (pas de nouvelles locales) =====
local CU = { K = {}, B = {}, raw = nil, cache = {}, t = -10, recolor = false }
for _, k in ipairs(CU_KNOBS) do CU.K[k[1]] = k end
for _, b in ipairs(CU_BTNS) do CU.B[b[1]] = b end
-- famille -> { r, g, b (fenetre), valeur couleur du vrai Twister (meme echelle que TW_PAGE_COLOR) }
CU.FAM = { play = {0.90, 0.25, 0.25, 84}, pitch = {0.95, 0.40, 0.70, 108}, inout = {0.20, 0.75, 0.40, 50},
           slicer = {0.95, 0.85, 0.20, 63}, cloud = {0.25, 0.55, 0.95, 126} }
CU.FRAC = { [0] = "Free", "1/2", "1/3", "1/4", "1/6", "1/8", "1/12", "1/16", "1/32", "1/64" }
function CU.n_of(k, v)
  local lo, hi, c = k[6], k[7], k[9]
  if c == "log" then return clamp(math.log(math.max(v, lo) / lo) / math.log(hi / lo), 0, 1) end
  local n = clamp((v - lo) / (hi - lo), 0, 1)
  if type(c) == "number" then n = n ^ (1 / c) end
  return n
end
function CU.v_of(k, n)
  n = clamp(n, 0, 1)
  local lo, hi, c, st = k[6], k[7], k[9], k[10]
  local v
  if c == "log" then v = lo * (hi / lo) ^ n
  elseif type(c) == "number" then v = lo + (n ^ c) * (hi - lo)
  else v = lo + n * (hi - lo) end
  if st then v = math.floor(v / st + 0.5) * st end
  return clamp(v, lo, hi)
end
-- valeur normalisee 0..1 du knob k sur le looper s
function CU.get_n(k, s)
  if k[11] then
    local len = read_fb(s, 46)
    if len <= 0 then return 0 end
    local i0, w0 = read_fb(s, 44), read_fb(s, 45)
    if k[11] == "in" then return clamp(i0 / len, 0, 1) end
    if k[11] == "out" then return clamp((i0 + w0) / len, 0, 1) end
    return clamp(w0 / len, 0, 1)
  end
  return CU.n_of(k, read_fb(s, k[5]))
end
function CU.set_n(k, s, n)
  if not looper_alive(s, reaper.time_precise()) then return end
  if k[11] then
    local len = read_fb(s, 46)
    if len <= 0 then return end
    local i0, w0 = read_fb(s, 44), read_fb(s, 45)
    if k[11] == "in" then write_edit(s, 1, math.max(0, math.min(i0 + w0, n * len)), nil)      -- In (Out fixe)
    elseif k[11] == "out" then write_edit(s, 2, nil, math.max(i0, math.min(len, n * len)))   -- Out
    else write_edit(s, 3, nil, math.max(0, math.min(len - i0, n * len))) end                  -- Width
    return
  end
  write_param(s, k[4], CU.v_of(k, n))
end
-- Regle de groupe (knobs) : le looper selectionne prend la valeur, les membres de son groupe suivent du MEME DELTA
-- (course normalisee du knob) en gardant leur ecart, comme les pages Pitch / Vol. Instantane pris au debut du geste.
function CU.set_group(k, idx, n)
  local now, s = reaper.time_precise(), sel_looper()
  local g = CU.gs
  if not g or g.idx ~= idx or g.s ~= s or (now - g.t) > 0.6 then
    g = { idx = idx, s = s, n0 = CU.get_n(k, s), peers = {} }
    for _, li in ipairs(page_targets()) do
      if li ~= s and looper_alive(li, now) then g.peers[li] = CU.get_n(k, li) end
    end
    CU.gs = g
  end
  g.t = now
  CU.set_n(k, s, n)
  for li, b0 in pairs(g.peers) do CU.set_n(k, li, clamp(b0 + (n - g.n0), 0, 1)) end
end
function CU.disp(k, s)
  if k[11] then return string.format("%.0f%%", CU.get_n(k, s) * 100) end
  local v = read_fb(s, k[5])
  if k[1] == "speed" then return string.format("%.2fx", v) end
  if k[1] == "pitch" then return string.format("%+.1fst", v) end
  if k[1] == "io_frac" then return CU.FRAC[math.floor(v + 0.5)] or "?" end
  if k[1] == "dens_len" then return "1/" .. math.floor(2 ^ math.floor(v + 0.5) + 0.5) end
  if k[10] then return string.format("%.0f", v) end
  if k[7] - k[6] >= 10 then return string.format("%.0f", v) end
  return string.format("%.2f", v)
end
-- Regle de groupe : les push agissent sur le looper selectionne ET les membres de son groupe (chacun selon son etat)
function CU.fire(bid, kid)
  local now = reaper.time_precise()
  for _, s in ipairs(page_targets()) do
    if looper_alive(s, now) then CU.fire1(bid, kid, s) end
  end
end
function CU.fire1(bid, kid, s)
  local b = CU.B[bid]
  if not b then return end
  if bid == "knob_def" then
    local k = kid and CU.K[kid]
    if k then
      if k[11] then CU.set_n(k, s, (k[11] == "in") and 0 or 1) else write_param(s, k[4], k[8]) end
    end
    return
  end
  if b[4] then
    local base = gbase(s, active_part(s))
    if b[5] ~= nil then reaper.gmem_write(base + 49, b[5]) end
    reaper.gmem_write(base + 48, b[4])
  elseif b[6] then
    if b[7] == "tog" then write_param(s, b[6], read_fb(s, b[8]) > 0.5 and 0 or 1)
    else write_param(s, b[6], b[7]) end
  end
end
-- Page 7 : cellules construites a partir des assignations du MIDI Learn (ExtState NowUndo_MIDILearn / custom)
function CU.cells()
  local now = reaper.time_precise()
  if now - CU.t < 0.25 then return CU.cache end
  CU.t = now
  local raw = reaper.GetExtState("NowUndo_MIDILearn", "custom") or ""
  if raw == CU.raw then return CU.cache end
  CU.raw, CU.recolor = raw, true
  local asg = {}
  for key, id in raw:gmatch("([kb]%d+)=([%w_]+)") do asg[key] = id end
  local cells = {}
  for idx = 0, 15 do
    local kid, bid = asg["k" .. idx], asg["b" .. idx]
    local k, b = kid and CU.K[kid], bid and CU.B[bid]
    if k or b then
      local fam = CU.FAM[(k and k[3]) or (b and b[3]) or ""]
      cells[math.floor(idx / 4) .. "," .. (idx % 4)] = {
        label = k and k[2] or b[2], col = fam and { fam[1], fam[2], fam[3] } or nil, twc = fam and fam[4] or nil,
        get = function() return k and CU.get_n(k, sel_looper()) or 0 end,
        set = function(_, n) if k then CU.set_group(k, idx, n) end end,
        to_n = function(n) return n end, from_n = function(n) return n end,
        push = function() CU.fire(bid or "knob_def", kid) end,   -- push non assigne = valeur par defaut du knob
        disp = function() if k then return CU.disp(k, sel_looper()) end return b and "push" or "" end,
      }
    end
  end
  CU.cache = cells
  return cells
end
-- Page 8 : affichage (lecture seule). Rangees 1-2 : position de lecture L1..L8 ; rangees 3-4 : VU de sortie L1..L8.
CU.P8 = {}
for i = 1, 8 do
  local r, c = math.floor((i - 1) / 4), (i - 1) % 4
  CU.P8[r .. "," .. c] = {
    label = "L" .. i .. " Pos", looper = i,
    get = function(li) return read_fb(li, 47) end, set = function() end,
    to_n = function(v) return clamp(v / 100, 0, 1) end, from_n = function(n) return n end,
    disp = function(v) return string.format("%.0f%%", v) end,
  }
  CU.P8[(r + 2) .. "," .. c] = {
    label = "L" .. i .. " Out", looper = i,
    get = function(li) return read_fb(li, 173) end, set = function() end,
    to_n = function(v) return clamp((20 * math.log(math.max(v, 0.00001), 10) + 48) / 48, 0, 1) end,
    from_n = function(n) return n end,
    disp = function(v) if v < 0.0001 then return "-inf" end return string.format("%.0fdB", 20 * math.log(v, 10)) end,
  }
end
function CU.page_cells(page) if page == 7 then return CU.cells() end return CU.P8 end

local PAGES = {
  [2] = make_scalar_page_pitch_speed(),
  [3] = make_scalar_page_vol_fb(),
  [4] = make_slicer_page(),
  [5] = make_cloud_page(),
}


--------------------------------------------------------------------------
-- PAGE 6 : EFFETS (FX Router)
-- La source affichee est celle du FX Router (ExtState FXRouter/src).
-- Colonne = slot 1..4, ligne = parametre 1..4. Constantes identiques a celles de FX_Router.
--------------------------------------------------------------------------
local FX_LIB_FOLDER, FX_INPUT_FIRST_TRACK, FX_LOOPER_FIRST_TRACK = "MonRig", 2, 11
local FX_NB_SOURCES, FX_NB_SLOTS, FX_NB_PARAMS = 8, 4, 4
local FX_EXT, FXR_EXT = "NowUndo_FX", "FXRouter"

local function fx_norm(str)
  str = (str or ""):lower():gsub("\\", "/")
  str = str:gsub("^js:%s*", ""):gsub("%.jsfx$", "")
  return str
end

-- Bibliotheque (meme scan / meme tri que le FX Router => memes index)
local fx_lib, fx_lib_t = {}, -100
local function fx_scan(rel)
  local base = reaper.GetResourcePath() .. "/Effects/"
  reaper.EnumerateFiles(base .. rel, -1)
  reaper.EnumerateSubdirectories(base .. rel, -1)
  local i = 0
  while true do
    local f = reaper.EnumerateFiles(base .. rel, i)
    if not f then break end
    local ext = f:match("%.([^%.]+)$")
    if not ext or ext:lower() == "jsfx" then
      local desc
      local fh = io.open(base .. rel .. "/" .. f, "r")
      if fh then
        local n = 0
        for line in fh:lines() do
          n = n + 1
          local d = line:match("^desc:%s*(.-)%s*$")
          if d then desc = d break end
          if n > 40 then break end
        end
        fh:close()
      end
      local ident = (rel .. "/" .. f):gsub("%.jsfx$", "")
      fx_lib[#fx_lib + 1] = { ident = ident, name = desc or f }
    end
    i = i + 1
  end
  local j = 0
  while true do
    local d = reaper.EnumerateSubdirectories(base .. rel, j)
    if not d then break end
    fx_scan(rel .. "/" .. d)
    j = j + 1
  end
end
local function fx_rescan()
  fx_lib = {}
  fx_scan(FX_LIB_FOLDER)
  table.sort(fx_lib, function(a, b) return a.name:lower() < b.name:lower() end)
  fx_lib_t = reaper.time_precise()
end

local function fx_clean_name(n)
  n = n:gsub("^[%w]+i?: ", "")
  n = n:gsub("%s*%b()%s*$", "")
  n = n:gsub("%s*%b[]%s*$", "")
  return n
end

local function fx_get_containers(tr, is_looper)
  local list = {}
  local fx_count = reaper.TrackFX_GetCount(tr)
  for i = (is_looper and 1 or 0), fx_count - 1 do
    local rv, cnt = reaper.TrackFX_GetNamedConfigParm(tr, i, "container_count")
    if rv and cnt ~= nil then
      list[#list + 1] = i
      if #list >= FX_NB_SLOTS then break end
    end
  end
  return list
end

local function fx_get_children(tr, cidx)
  local children = {}
  local _, cnt = reaper.TrackFX_GetNamedConfigParm(tr, cidx, "container_count")
  cnt = tonumber(cnt) or 0
  for n = 0, cnt - 1 do
    local _, str = reaper.TrackFX_GetNamedConfigParm(tr, cidx, "container_item." .. n)
    local fx = tonumber(str)
    if fx then
      local _, name = reaper.TrackFX_GetFXName(tr, fx, "")
      local _, ident = reaper.TrackFX_GetNamedConfigParm(tr, fx, "fx_ident")
      children[#children + 1] = { fx = fx, name = fx_clean_name(name), ident = ident }
    end
  end
  return children
end

local function fx_child_addr(tr, cidx, n)
  return 0x2000000 + (n + 1) * (reaper.TrackFX_GetCount(tr) + 1) + (cidx + 1)
end

-- Source courante du FX Router
local function fx_source()
  local cur = math.floor(tonumber(reaper.GetExtState(FXR_EXT, "src")) or 1)
  if cur < 1 or cur > 2 * FX_NB_SOURCES then cur = 1 end
  if cur > FX_NB_SOURCES then
    return cur, FX_LOOPER_FIRST_TRACK - 1 + (cur - FX_NB_SOURCES - 1), true, "Looper " .. (cur - FX_NB_SOURCES)
  end
  return cur, FX_INPUT_FIRST_TRACK - 1 + (cur - 1), false, "Entree " .. cur
end

local function fx_slot_sel()
  local n = math.floor(tonumber(reaper.GetExtState(VL_SEC, "fx_slot")) or 1)
  return math.max(1, math.min(FX_NB_SLOTS, n))
end

-- Structure (containers / effets) en cache 150 ms : le feedback lit 16 knobs toutes les 30 ms
local fx_cache, fx_cache_t = nil, -1
local function fx_struct()
  local t = reaper.time_precise()
  local cur, track0, is_looper, label = fx_source()
  if fx_cache and fx_cache.src == cur and (t - fx_cache_t) < 0.15 then return fx_cache end
  local st = { src = cur, label = label, is_looper = is_looper, slots = {} }
  local tr = reaper.GetTrack(0, track0)
  st.tr = tr
  if tr then
    local containers = fx_get_containers(tr, is_looper)
    for s = 1, FX_NB_SLOTS do
      local cidx = containers[s]
      local slot = { cidx = cidx }
      if cidx then
        slot.child = fx_get_children(tr, cidx)[1]
        slot.inactive = not reaper.TrackFX_GetEnabled(tr, cidx)
          or (slot.child ~= nil and not reaper.TrackFX_GetEnabled(tr, slot.child.fx))
      end
      st.slots[s] = slot
    end
  end
  fx_cache, fx_cache_t = st, t
  return st
end

local function fx_child_of(s)
  local st = fx_struct()
  local slot = st.slots[s]
  if st.tr and slot and slot.child then return st.tr, slot.child end
end

local function fx_set_param(s, p, v)
  local tr, ch = fx_child_of(s)
  if not tr then return end
  if p >= reaper.TrackFX_GetNumParams(tr, ch.fx) then return end
  reaper.TrackFX_SetParamNormalized(tr, ch.fx, p, clamp(v, 0, 1))
end

local function fx_get_param_norm(s, p)
  local tr, ch = fx_child_of(s)
  if not tr or p >= reaper.TrackFX_GetNumParams(tr, ch.fx) then return nil end
  return reaper.TrackFX_GetParamNormalized(tr, ch.fx, p)
end

-- Valeurs par defaut : lues dans le source du JSFX (sliderN:defaut<min,max,pas>Nom).
-- Les sliders caches (nom precede de "-") ne sont pas des parametres. Pas de defaut trouve => rien ne bouge.
local fx_defaults = {}
local function fx_parse_defaults(ident)
  local key = fx_norm(ident)
  if fx_defaults[key] then return fx_defaults[key] end
  local d = { by_index = {}, by_name = {} }
  fx_defaults[key] = d
  local rel = (ident or ""):gsub("\\", "/"):gsub("^[Jj][Ss]:%s*", ""):gsub("%.jsfx$", "")   -- casse conservee (fichiers sensibles a la casse)
  for _, e in ipairs(fx_lib) do
    if fx_norm(e.ident) == key then rel = e.ident break end
  end
  local base = reaper.GetResourcePath() .. "/Effects/" .. rel
  local fh = io.open(base .. ".jsfx", "r") or io.open(base, "r")
  if not fh then return d end
  local n = 0
  for line in fh:lines() do
    if line:match("^@") then break end                      -- fin de l'en-tete : plus de sliders apres
    local num, body = line:match("^slider(%d+):(.*)$")
    if num then
      if line:find("^slider%d+:%s*/") then goto continue end    -- selecteur de fichier
      body = body:gsub("^[%w_%.]+=", "")
      local def, rng, name = body:match("^%s*([%-%+]?[%d%.]+[eE]?[%-%+]?%d*)%s*<([^>]*)>%s*(.-)%s*$")
      if def and name and name:sub(1, 1) ~= "-" then
        n = n + 1
        local v = tonumber(def)
        if v then
          d.by_index[n] = v
          d.by_name[name:lower()] = v
        end
      elseif def == nil and body:find("<") and not body:match(">%s*%-") then
        n = n + 1       -- slider non decodable mais visible : garde l'index aligne
      end
    end
    ::continue::
  end
  fh:close()
  return d
end

local function fx_reset_param(s, p)
  local tr, ch = fx_child_of(s)
  if not tr or p >= reaper.TrackFX_GetNumParams(tr, ch.fx) then return end
  local d = fx_parse_defaults(ch.ident)
  local _, pname = reaper.TrackFX_GetParamName(tr, ch.fx, p)
  local v = d.by_name[(pname or ""):lower()] or d.by_index[p + 1]
  if v ~= nil then reaper.TrackFX_SetParam(tr, ch.fx, p, v) end
end

-- Cellules de la page (specs STABLES : le drag compare drag.spec == spec)
local fx_specs = {}
local function fx_cells()
  local st = fx_struct()
  local cells = {}
  if not st.tr then return cells end
  for s = 1, FX_NB_SLOTS do
    local ch = st.slots[s] and st.slots[s].child
    if ch then
      local np = math.min(FX_NB_PARAMS, reaper.TrackFX_GetNumParams(st.tr, ch.fx))
      for p = 0, np - 1 do
        local key = p .. "," .. (s - 1)
        local spec = fx_specs[key]
        if not spec then
          local sl, pa = s, p
          spec = {
            get = function() return fx_get_param_norm(sl, pa) or 0 end,
            set = function(_, v) fx_set_param(sl, pa, v) end,
            to_n = function(v) return v end,
            from_n = function(n) return n end,
            push = function() fx_reset_param(sl, pa) end,
          }
          fx_specs[key] = spec
        end
        local _, pname = reaper.TrackFX_GetParamName(st.tr, ch.fx, p)
        spec.label = (pname or ""):sub(1, 9)
        cells[key] = spec
      end
    end
  end
  return cells
end

-- Chargement d'un effet dans un slot (meme logique que le FX Router ; memes memoires de reglages)
local function fx_pkey(s, ident)
  return "P_EXT:FXR_" .. s .. "_" .. (fx_norm(ident):gsub("[^%w]", "_"))
end
local function fx_save_params(tr, fx, s, ident)
  if not ident or ident == "" then return end
  local t = {}
  for p = 0, reaper.TrackFX_GetNumParams(tr, fx) - 1 do
    t[#t + 1] = string.format("%.6f", reaper.TrackFX_GetParamNormalized(tr, fx, p))
  end
  reaper.GetSetMediaTrackInfo_String(tr, fx_pkey(s, ident), table.concat(t, ","), true)
end
local function fx_load_params(tr, fx, s, ident)
  local ok, str = reaper.GetSetMediaTrackInfo_String(tr, fx_pkey(s, ident), "", false)
  if not ok or str == "" then return end
  local p = 0
  for v in str:gmatch("[^,]+") do
    local n = tonumber(v)
    if n then reaper.TrackFX_SetParamNormalized(tr, fx, p, n) end
    p = p + 1
  end
end

local function fx_load(s, entry)      -- entry == nil : slot vide
  local st = fx_struct()
  local tr, slot = st.tr, st.slots[s]
  if not tr or not slot or not slot.cidx then return end
  local cidx = slot.cidx
  local children = fx_get_children(tr, cidx)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  for j = #children, 1, -1 do
    fx_save_params(tr, children[j].fx, s, children[j].ident)
    reaper.TrackFX_Delete(tr, children[j].fx)
  end
  if entry then
    local name = "JS:" .. entry.ident
    local addr = fx_child_addr(tr, cidx, 0)
    local idx = reaper.TrackFX_AddByName(tr, name, false, -1000 - addr)
    if idx < 0 then
      local top = reaper.TrackFX_AddByName(tr, name, false, -1)
      if top >= 0 then
        local dest = 0x2000000 + 1 * (reaper.TrackFX_GetCount(tr) + 1) + (cidx + 1)
        reaper.TrackFX_CopyToTrack(tr, top, tr, dest, true)
      else
        reaper.ShowConsoleMsg("Twister FX : impossible de charger " .. name .. "\n")
      end
    end
    local new = fx_get_children(tr, cidx)
    if new[1] then
      fx_load_params(tr, new[1].fx, s, entry.ident)
      reaper.TrackFX_SetEnabled(tr, new[1].fx, true)
    end
    reaper.TrackFX_SetEnabled(tr, cidx, true)
  end
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("Twister : changement d'effet (slot " .. s .. ")", -1)
  fx_cache = nil
end

-- Selection d'effet : defilement dans la liste (0 = Aucun, 1..N = bibliotheque).
-- Le chargement n'a lieu qu'apres une courte pause : on peut faire defiler vite sans charger chaque effet.
local FX_APPLY_DELAY = 0.30
local fx_sel = { pending = nil, slot = 1, t = 0 }

local function fx_current_index(s)
  local _, ch = fx_child_of(s)
  if not ch then return 0 end
  local n = fx_norm(ch.ident)
  for i, e in ipairs(fx_lib) do
    if fx_norm(e.ident) == n then return i end
  end
  return 0
end

local function fx_ensure_lib()
  if #fx_lib == 0 or (reaper.time_precise() - fx_lib_t) > 10 then fx_rescan() end
end

local function fx_select_move(delta, absolute)
  fx_ensure_lib()
  local s = fx_slot_sel()
  local base
  if fx_sel.pending and fx_sel.slot == s then base = fx_sel.pending else base = fx_current_index(s) end
  local target
  if absolute then target = math.floor(delta * #fx_lib + 0.5) else target = base + delta end
  fx_sel.slot, fx_sel.pending, fx_sel.t = s, clamp(target, 0, #fx_lib), reaper.time_precise()
end

local function fx_poll()
  -- commandes envoyees par le script Learn
  local st = reaper.GetExtState(FX_EXT, "step")
  if st ~= "" then
    reaper.SetExtState(FX_EXT, "step", "", false)
    local d = tonumber(st)
    if d and d ~= 0 then fx_select_move(math.floor(d), false) end
  end
  local ab = reaper.GetExtState(FX_EXT, "abs")
  if ab ~= "" then
    reaper.SetExtState(FX_EXT, "abs", "", false)
    local v = tonumber(ab)
    if v then fx_select_move(clamp(v, 0, 1), true) end
  end
  -- application differee
  if fx_sel.pending and (reaper.time_precise() - fx_sel.t) > FX_APPLY_DELAY then
    local idx, s = fx_sel.pending, fx_sel.slot
    fx_sel.pending = nil
    if idx ~= fx_current_index(s) then fx_load(s, idx > 0 and fx_lib[idx] or nil) end
  end
end

-- Lecture / ecriture d'un knob physique (idx 0..15) sur la page 6
local function fx_idx_to_slot_param(idx) return (idx % 4) + 1, math.floor(idx / 4) end

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

local function draw_knob(cx, cy, r, val, label, col, s, grouped, dim, disp)
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
  local vs = disp or string.format("%.0f%%", val * 100)
  gfx.set(1, 1, 1, 0.85 * ua)
  tw = gfx.measurestr(vs)
  gfx.x = cx - tw * 0.5
  gfx.y = cy + r + 16 * s
  gfx.drawstr(vs)
end

--------------------------------------------------------------------------
-- Init / loop
--------------------------------------------------------------------------
local HB_EXT = "NowUndo_Twister"
local SCRIPT_VERSION = "3.4-custom-display"   -- change a chaque version : la nouvelle instance remplace l'ancienne
local ui_open = true

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
-- true : le retour de valeurs vers un controleur n'est envoye QUE si "Return" est coche sur sa ligne
-- (false = ancien comportement : toujours renvoyer aux knobs principaux)
local FB_REQUIRE_RET = true

-- Couleur des encodeurs du VRAI Twister = couleur de la page virtuelle active (sans changer de banque materielle).
-- Le Twister colore le segment RGB d'un encodeur quand il recoit un CC de meme numero sur le canal 2
-- (octet de statut 0xB1 => TW_COLOR_CH = 1). Valeurs 1..126 = echelle de teinte du Twister
-- (1 = bleu ... 126 = rose/rouge). 0 = rend la main a la couleur reglee dans Midi Fighter Utility.
-- Valeurs ESTIMEES : ajuste-les ici si une page ne tombe pas sur la bonne couleur.
local TW_COLORS = true
local TW_COLOR_CH = 1
local TW_PAGE_COLOR = { [1] = 50, [2] = 108, [3] = 84, [4] = 63, [5] = 126, [6] = 22 }  -- vert, rose, rouge, jaune, bleu, cyan
-- Page 6 : une teinte par colonne (enc = row*4 + col) — orange, violet, vert, corail
local TW_PAGE6_COL = { [0] = 92, [1] = 115, [2] = 48, [3] = 100 }
local midi_maps = {}       -- id -> { status, ch, d1, gate, ret, dev }
local sent_log = {}        -- anti-echo : derniers messages envoyes (st/ch/d1 -> {v, t})
local ECHO_WIN = 0.10
local function log_sent(st, ch, d1, v)
  sent_log[(st << 16) | (ch << 8) | d1] = { v = v, t = reaper.time_precise() }
end
local midi_out_res_t = -10

-- Port de sortie resolu par NOM (les index changent au rebranchement) ; jamais de choix automatique.
local function out_by_name(name, idx)
  if name and name ~= "" and reaper.GetNumMIDIOutputs then
    for i = 0, (reaper.GetNumMIDIOutputs() or 0) - 1 do
      local ok, nm = reaper.GetMIDIOutputName(i, "")
      if ok and nm == name then return i end
    end
    return -1
  end
  return idx or -1
end
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
  local rawd = reaper.GetExtState(LEARN_EXT, "maps_dev") or ""
  local sig = raw .. "#" .. rawd
  if sig == midi_maps_sig and not force then return end
  midi_maps_sig = sig
  midi_maps = {}
  for line in raw:gmatch("[^\n]+") do
    local id, st, ch, d1, d2, ret, gate = line:match("^([^|]+)|(%d+)|(%d+)|(%d+)|(%-?%d+)|(%d+)|(%d+)$")
    if id and (id:match("^tw:knob:%d+$") or id:match("^tw:btn:%d+$")) then
      midi_maps[id] = {
        status = tonumber(st), ch = tonumber(ch), d1 = tonumber(d1),
        gate = gate == "1", ret = ret == "1", dev = "",
      }
    end
  end
  for line in rawd:gmatch("[^\n]+") do
    local id, dev = line:match("^([^|]+)|(.*)$")
    if id and midi_maps[id] then midi_maps[id].dev = dev end
  end
end

-- Applique un slot physique 0..15 selon la page Twister courante

local function midi_send(m, val)
  if not m or midi_out_idx < 0 then return end
  if not reaper.SendMIDIMessageToHardware then return end
  local v = math.max(0, math.min(127, math.floor(val + 0.5)))
  if m.status == 0xB0 then
    log_sent(0xB0, m.ch or 0, m.d1 or 0, v)
    pcall(reaper.SendMIDIMessageToHardware, midi_out_idx, string.char(0xB0 + (m.ch or 0), m.d1 or 0, v))
  elseif m.status == 0x90 or m.status == 0x80 then
    log_sent(0x90, m.ch or 0, m.d1 or 0, v)
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
      return speed_to_n(speed)
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
    -- page Slicer : meme definition que la fenetre (PAGES[4]) ; idx = ligne*4 + colonne
    local spec = PAGES[4][math.floor(idx / 4) .. "," .. (idx % 4)]
    if not spec then return 0 end
    local tg = page_targets()
    local i = tg[1]
    if not i or not looper_alive(i, now_t) then return 0 end
    return clamp(spec.to_n(spec.get()), 0, 1)
  elseif page == 5 then
    -- v3.3 : meme definition que la fenetre (PAGES[5]) ; idx = ligne*4 + colonne
    local spec = PAGES[5][math.floor(idx / 4) .. "," .. (idx % 4)]
    if not spec then return 0 end
    local tg = page_targets()
    local i = tg[1]
    if not i or not looper_alive(i, now_t) then return 0 end
    return clamp(spec.to_n(spec.get()), 0, 1)
  elseif page == 6 then
    local s, p = fx_idx_to_slot_param(idx)
    return clamp(fx_get_param_norm(s, p) or 0, 0, 1)
  elseif page == 7 or page == 8 then
    local spec = CU.page_cells(page)[math.floor(idx / 4) .. "," .. (idx % 4)]
    if not spec then return 0 end
    local li = spec.looper or sel_looper()
    if not looper_alive(li, now_t) then return 0 end
    return clamp(spec.to_n(spec.get(li)), 0, 1)
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
  local t = reaper.time_precise()
  if t - midi_out_res_t < 1 then return midi_out_idx end
  midi_out_res_t = t
  midi_out_idx = out_by_name(reaper.GetExtState(LEARN_EXT, "midi_out_name"),
    tonumber(reaper.GetExtState(LEARN_EXT, "midi_out")) or -1)
  return midi_out_idx
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
    local okn, nm = reaper.GetMIDIOutputName(midi_out_idx, "")
    reaper.SetExtState(LEARN_EXT, "midi_out", tostring(midi_out_idx), true)
    reaper.SetExtState(LEARN_EXT, "midi_out_name", (okn and nm) or "", true)
  else
    midi_out_idx = -1
    reaper.SetExtState(LEARN_EXT, "midi_out", "-1", true)
    reaper.SetExtState(LEARN_EXT, "midi_out_name", "", true)
  end
  midi_out_res_t = -10
  midi_fb_status = "OUT: " .. midi_out_name()
  last_fighter_page = -1  -- force renvoi au prochain cycle
end

local function midi_feedback_page(page)
  midi_reload_maps(true)
  local nmaps = 0
  for id, m in pairs(midi_maps) do
    if id:find("tw:knob:", 1, true) and m.status and m.status > 0 and (m.ret or not FB_REQUIRE_RET) then nmaps = nmaps + 1 end
  end
  if resolve_midi_out() < 0 then
    midi_fb_status = "FB: pas de MIDI OUT (clic header)"
    return
  end
  if nmaps == 0 then
    midi_fb_status = FB_REQUIRE_RET and "FB: aucun knob avec Return coche" or "FB: aucun knob learn (tw:knob)"
    return
  end
  local now_t = reaper.time_precise()
  local sent = 0
  for idx = 0, 15 do
    local id = string.format("tw:knob:%d", idx)
    local m = midi_maps[id]
    if m and m.status and m.status > 0 and (m.ret or not FB_REQUIRE_RET) then
      local n = read_knob_norm(page, idx, now_t)
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

-- Colore les 16 encodeurs du Twister selon la page active (envoye au changement de page seulement)
-- Page 6 : une couleur par colonne (enc % 4)
local function twister_send_colors(page)
  if not TW_COLORS then return end
  if resolve_midi_out() < 0 or not reaper.SendMIDIMessageToHardware then return end
  -- v3.4 : luminosite RGB par encodeur (canal 3 du Twister : 17 = eteint ... 47 = plein)
  local function bright(enc, on)
    local v = on and 47 or 17
    log_sent(0xB0, 2, enc, v)
    pcall(reaper.SendMIDIMessageToHardware, midi_out_idx, string.char(0xB2, enc, v))
  end
  if page == 7 or page == 8 then
    local cells = (page == 7) and CU.cells() or {}
    for enc = 0, 15 do
      local spec = cells[math.floor(enc / 4) .. "," .. (enc % 4)]
      local val = spec and spec.twc
      if val then
        log_sent(0xB0, TW_COLOR_CH, enc, val)
        pcall(reaper.SendMIDIMessageToHardware, midi_out_idx, string.char(0xB0 + TW_COLOR_CH, enc, val))
      end
      bright(enc, val ~= nil)                        -- page 8 / encodeur non assigne : couleur eteinte
    end
    return
  end
  for enc = 0, 15 do bright(enc, true) end            -- autres pages : couleur rallumee
  if page == 6 then
    for enc = 0, 15 do
      local val = TW_PAGE6_COL[enc % 4] or TW_PAGE_COLOR[6]
      log_sent(0xB0, TW_COLOR_CH, enc, val)
      pcall(reaper.SendMIDIMessageToHardware, midi_out_idx, string.char(0xB0 + TW_COLOR_CH, enc, val))
    end
  else
    local val = TW_PAGE_COLOR[page]
    if not val then return end
    for enc = 0, 15 do
      log_sent(0xB0, TW_COLOR_CH, enc, val)   -- anti-echo : ne pas le prendre pour un appui de push
      pcall(reaper.SendMIDIMessageToHardware, midi_out_idx, string.char(0xB0 + TW_COLOR_CH, enc, val))
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
    if m and m.status and m.status > 0 and (m.ret or not FB_REQUIRE_RET) then
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

-- GROUPES en MIDI : un geste sur le knob d'un looper groupe reporte le DELTA sur les pairs
-- (meme logique que le drag souris : pitch/vol/fdbk additif, speed en ratio, In/Out/Width proportionnels a la longueur).
-- Le snapshot des pairs est pris au debut du geste (sans ca, les bornes ecraseraient la proportionnalite).
local gsnap = nil
local GSNAP_TIMEOUT = 0.6
local function gesture(key, now_t, make)
  if gsnap and gsnap.key == key and (now_t - gsnap.t) < GSNAP_TIMEOUT then
    gsnap.t = now_t
    return gsnap
  end
  gsnap = make()
  gsnap.key, gsnap.t = key, now_t
  return gsnap
end
local function scalar_snapshot(src, off, now_t)
  local peers = {}
  for _, pr in ipairs(group_peers(src)) do
    if looper_alive(pr, now_t) then peers[pr] = read_fb(pr, off) end
  end
  return { src0 = read_fb(src, off), peers = peers }
end

-- [SCN] Mode CAPTURE du script NowUndo_Scenario : tant que son heartbeat est vivant, les knobs / push du Twister
-- lui signalent la valeur (native) en plus d'agir normalement. In/Out sont signales meme si le looper est vide
-- (le scenario les stocke en fractions : aucune longueur de boucle necessaire).
local SCN = {}
function SCN.on()
  local hb = tonumber(reaper.GetExtState("NowUndo_Scn", "hb")) or 0
  return reaper.time_precise() - hb < 0.6
end
function SCN.emit(line, prefix)
  local q = reaper.GetExtState("NowUndo_Scn", "q")
  if prefix then                                   -- coalesce : on ne garde que la derniere valeur d'un meme knob
    local last = q:match("([^\n]*)\n$")
    if last and last:sub(1, #prefix) == prefix then q = q:sub(1, #q - #last - 1) end
  end
  reaper.SetExtState("NowUndo_Scn", "q", q .. line .. "\n", false)
end
SCN.P5 = { [0] = "cdens", [1] = "cchaos", [2] = "cspread", [3] = "cpitch", [4] = "cpos", [5] = "clfo", [6] = "clfodepth", [7] = "clfoshape" }
SCN.P5R = { [0] = {0,1}, [1] = {0,1}, [2] = {0,1}, [3] = {0,100}, [4] = {0,100}, [5] = {0.1,4}, [6] = {0,100}, [7] = {0,2} }
function SCN.knob(idx, norm, page)
  if not SCN.on() then return end
  norm = clamp(norm, 0, 1)
  local key, looper, v
  if page == 1 then
    looper = math.floor(idx / 2) + 1; key = (idx % 2 == 0) and "in" or "out"; v = norm
  elseif page == 2 then
    looper = (idx % 8) + 1
    if idx < 8 then key = "pitch"; v = norm * 96 - 48 else key = "speed"; v = n_to_speed(norm) end
  elseif page == 3 then
    looper = (idx % 8) + 1; key = (idx < 8) and "vol" or "fb"; v = norm * 2
  elseif page == 5 and SCN.P5[idx] then
    key = SCN.P5[idx]; local r = SCN.P5R[idx]; v = r[1] + norm * (r[2] - r[1]); looper = sel_looper()
  end
  if key then
    SCN.emit(string.format("val\t%s\t%d\t%.6f", key, looper, v), string.format("val\t%s\t%d\t", key, looper))
  end
end
function SCN.btn(idx, page)
  if not SCN.on() then return end
  if page == 1 then
    if idx % 2 == 0 then SCN.emit(string.format("rst\tinout\t%d", math.floor(idx / 2) + 1)) end
  elseif page == 2 or page == 3 then
    local looper = (idx % 8) + 1
    local key = (page == 2) and ((idx < 8) and "pitch" or "speed") or ((idx < 8) and "vol" or "fb")
    SCN.emit(string.format("rst\t%s\t%d", key, looper))
  end
end

local function midi_apply_knob(idx, norm, page)
  page = page or fighter_page()
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
    -- snapshot du groupe pris AVANT toute ecriture (debut du geste)
    local g = gesture("p1:" .. idx, now_t, function()
      return { in0 = in_s, out0 = in_s + w_s, w0 = w_s, len0 = len, peers = snapshot_peers_io(looper) }
    end)
    local kind, d_norm
    if is_out then
      if is_width then
        local new_w = math.max(0, math.min(len - in_s, norm * len))
        reaper.gmem_write(b + 162, new_w)
        reaper.gmem_write(b + 160, 3)
        kind, d_norm = "width", (new_w - g.w0) / g.len0
      else
        local out = math.max(in_s, math.min(len, norm * len))
        reaper.gmem_write(b + 162, out)
        reaper.gmem_write(b + 160, 2)
        kind, d_norm = "out", (out - g.out0) / g.len0
      end
    else
      local new_in = math.max(0, math.min(len, norm * len))
      kind = "in"
      if is_width then
        -- garder width : cmd 5. Borne reelle : le Out ne peut pas depasser la fin (In <= len - width)
        new_in = math.min(new_in, math.max(0, len - w_s))
        reaper.gmem_write(b + 161, new_in)
        reaper.gmem_write(b + 160, 5)
        kind = "shift"      -- les pairs suivent la position du Out reel (decalage de fenetre), pas celle du bouton
      else
        -- garder Out : cmd 1 (JSFX recalcule width)
        local out_pos = math.min(len, in_s + w_s)
        new_in = math.max(0, math.min(out_pos, new_in))
        reaper.gmem_write(b + 161, new_in)
        reaper.gmem_write(b + 160, 1)
      end
      d_norm = (new_in - g.in0) / g.len0
    end
    if kind and g.peers then apply_peers_io(g.peers, kind, d_norm) end
  elseif page == 2 then
    local looper = (idx % 8) + 1
    if not looper_alive(looper, now_t) then return end
    local is_pitch = idx < 8
    local newv = is_pitch and (norm * 96 - 48) or n_to_speed(norm)
    local g = gesture("p2:" .. idx, now_t, function() return scalar_snapshot(looper, is_pitch and 4 or 3, now_t) end)
    write_param(looper, is_pitch and 4 or 3, newv)
    for peer, base in pairs(g.peers) do
      if is_pitch then
        write_param(peer, 4, clamp(base + (newv - g.src0), -48, 48))          -- delta en demi-tons
      elseif g.src0 > 0 then
        write_param(peer, 3, clamp(base * (newv / g.src0), 0.01, 100))        -- ratio de vitesse
      end
    end
  elseif page == 3 then
    local looper = (idx % 8) + 1
    if not looper_alive(looper, now_t) then return end
    local pid = (idx < 8) and 22 or 19
    local newv = norm * 2
    local g = gesture("p3:" .. idx, now_t, function() return scalar_snapshot(looper, pid, now_t) end)
    write_param(looper, pid, newv)
    for peer, base in pairs(g.peers) do
      write_param(peer, pid, clamp(base + (newv - g.src0), 0, 2))
    end
  elseif page == 4 then
    local spec = PAGES[4][math.floor(idx / 4) .. "," .. (idx % 4)]
    if not spec then return end
    if spec.inactive and spec.inactive() then return end  -- knob desactive (mode / source)
    spec.set(nil, spec.from_n(norm))
  elseif page == 5 then
    local spec = PAGES[5][math.floor(idx / 4) .. "," .. (idx % 4)]
    if not spec then return end
    spec.set(nil, spec.from_n(norm))
  elseif page == 6 then
    local s, p = fx_idx_to_slot_param(idx)
    fx_set_param(s, p, norm)
  elseif page == 7 then
    local spec = CU.cells()[math.floor(idx / 4) .. "," .. (idx % 4)]
    if spec then spec.set(nil, norm) end
  end                                                  -- page 8 : affichage seul
end

local function midi_apply_btn(idx, page)
  page = page or fighter_page()
  SCN.btn(idx, page)   -- [SCN]
  local now_t = reaper.time_precise()
  if page == 1 then
    local looper = math.floor(idx / 2) + 1
    local is_out = (idx % 2) == 1
    if not looper_alive(looper, now_t) then return end
    if is_out then
      -- Push Out : bascule mode In/Out <-> In/Width
      tw_mode_io[looper] = 1 - (tw_mode_io[looper] or 0)
    else
      -- Push In : reset In/Out (boucle pleine) sur le looper ET les membres de son groupe
      local b = gbase(looper, active_part(looper))
      local len = reaper.gmem_read(b + 46) or 0
      if len > 0 then
        pending_reset[looper] = { gbase = b, len = len, step = 1 }
      end
      for _, peer in ipairs(group_peers(looper)) do
        if looper_alive(peer, now_t) then
          local plen = read_fb(peer, 46)
          if plen > 0 then
            pending_reset[peer] = { gbase = gbase(peer, active_part(peer)), len = plen, step = 1 }
          end
        end
      end
    end
  elseif page == 2 or page == 3 then
    local looper = (idx % 8) + 1
    if not looper_alive(looper, now_t) then return end
    local pid, def
    if page == 2 then
      if idx < 8 then pid, def = 4, 0 else pid, def = 3, 1 end
    else
      if idx < 8 then pid, def = 22, 1 else pid, def = 19, 1 end
    end
    write_param(looper, pid, def)
    for _, peer in ipairs(group_peers(looper)) do
      if looper_alive(peer, now_t) then write_param(peer, pid, def) end
    end
  elseif page == 4 or page == 5 then
    local spec = PAGES[page][math.floor(idx / 4) .. "," .. (idx % 4)]
    if spec and spec.inactive and spec.inactive() then return end
    if spec and spec.push then spec.push() end   -- v3.3 : push actif aussi sur la page Cloud
  elseif page == 6 then
    local s, p = fx_idx_to_slot_param(idx)
    fx_reset_param(s, p)
  elseif page == 7 then
    local spec = CU.cells()[math.floor(idx / 4) .. "," .. (idx % 4)]
    if spec and spec.push then spec.push() end
  end
end


--------------------------------------------------------------------------
-- LEARN AUX : controleurs supplementaires par page (maps "aux:P:knob:i")
-- Une page qui a des learns aux est pilotee EN PERMANENCE par ces messages
-- (meme si elle n'est pas la page active du Twister principal).
-- Le Twister principal reste actif dessus sauf si "exclusif" est coche.
--------------------------------------------------------------------------
local aux_maps, aux_by_page = {}, {}
local aux_out, aux_excl = {}, {}
local aux_sig, aux_t, aux_fb_t = "", 0, 0
local aux_fb_last = {}
local dev_cache = {}

-- SOFT TAKEOVER (knobs sans retour) : la valeur entrante est ignoree tant qu'elle n'a pas rejoint
-- (ou croise) la valeur actuelle du parametre. Se rearme si le parametre est modifie ailleurs.
local pk_set = {}
local pk_main, pk_aux = {}, {}
local pk_sl, pk_fp, pk_fsrc = nil, nil, nil
local PK_TOL = 0.02

local function pickup_ok(tbl, id, page, idx, norm)
  local now = reaper.time_precise()
  local st = tbl[id]
  if not st then st = { eng = false }; tbl[id] = st end
  local c = read_knob_norm(page, idx, now)
  if st.eng and st.t_set and (now - st.t_set) > 0.3 and math.abs(c - (st.last or c)) > 0.03 then
    st.eng = false; st.prev = nil          -- valeur changee par un autre controleur / la page / l'UI
  end
  if not st.eng then
    local d = norm - c
    if math.abs(d) <= PK_TOL or (st.prev and st.prev * d < 0) then
      st.eng = true
    end
    st.prev = d
    if not st.eng then return false end
  end
  st.last, st.t_set = norm, now
  return true
end

local function knob_in(tbl, id, page, idx, norm)
  if pk_set[id] and not pickup_ok(tbl, id, page, idx, norm) then return end
  SCN.knob(idx, norm, page)   -- [SCN] signale la valeur (apres soft-takeover) ; le knob agit normalement
  midi_apply_knob(idx, norm, page)
end

local function dev_name(dev)
  if type(dev) ~= "number" then return "" end
  local n = dev_cache[dev]
  if n == nil then
    n = ""
    if reaper.GetMIDIInputName then
      local ok, nm = reaper.GetMIDIInputName(math.floor(dev) & 0xFFFF, "")
      if ok and nm then n = nm end
    end
    if n ~= "" then dev_cache[dev] = n end
  end
  return n
end

local function aux_reload(force)
  local t = reaper.time_precise()
  if not force and (t - aux_t) < 0.5 then return end
  aux_t = t
  local raw = reaper.GetExtState(LEARN_EXT, "maps_aux") or ""
  local extra = {}
  for p = 1, 8 do
    extra[#extra + 1] = reaper.GetExtState(LEARN_EXT, "aux_out_" .. p)
    extra[#extra + 1] = reaper.GetExtState(LEARN_EXT, "aux_out_name_" .. p)
    extra[#extra + 1] = reaper.GetExtState(LEARN_EXT, "aux_excl_" .. p)
  end
  local rawpk = reaper.GetExtState(LEARN_EXT, "pickup") or ""
  local sig = raw .. "#" .. table.concat(extra, ";") .. "#" .. rawpk
  if sig == aux_sig and not force then return end
  aux_sig = sig
  aux_maps, aux_by_page = {}, {}
  for line in raw:gmatch("[^\n]+") do
    local id, st, ch, d1, ret, dev = line:match("^([^|]+)|(%d+)|(%d+)|(%d+)|(%d+)|%d+|(.*)$")
    if id then
      local p, kind, idx = id:match("^aux:(%d):(%a+):(%d+)$")
      if p then
        p = tonumber(p)
        aux_maps[#aux_maps + 1] = {
          page = p, kind = kind, idx = tonumber(idx),
          status = tonumber(st), ch = tonumber(ch), d1 = tonumber(d1), dev = dev or "",
          ret = ret == "1",
        }
        aux_by_page[p] = (aux_by_page[p] or 0) + 1
      end
    end
  end
  for p = 1, 8 do
    aux_out[p] = out_by_name(reaper.GetExtState(LEARN_EXT, "aux_out_name_" .. p),
      tonumber(reaper.GetExtState(LEARN_EXT, "aux_out_" .. p)) or -1)
    aux_excl[p] = reaper.GetExtState(LEARN_EXT, "aux_excl_" .. p) == "1"
  end
  pk_set = {}
  for id in rawpk:gmatch("[^,]+") do pk_set[id] = true end
  aux_fb_last = {}  -- force renvoi des valeurs vers les controleurs aux
end

-- Le Twister principal est-il ignore sur la page active ?
local function main_blocked()
  local pg = fighter_page()
  return aux_excl[pg] and (aux_by_page[pg] or 0) > 0
end

-- Retourne true si le message appartient a un learn aux (il est alors "consomme")
local function aux_handle(st, ch, d1, d2, dev)
  if #aux_maps == 0 then return false end
  local dn = nil
  local hit = false
  for _, a in ipairs(aux_maps) do
    if a.status == st and a.ch == ch and a.d1 == d1 then
      if a.dev ~= "" then
        dn = dn or dev_name(dev)
      end
      if a.dev == "" or a.dev == dn then
        hit = true
        if a.kind == "knob" then
          if st == 0xB0 or d2 > 0 then
            knob_in(pk_aux, string.format("aux:%d:knob:%d", a.page, a.idx), a.page, a.idx, d2 / 127)
          end
        elseif a.kind == "btn" then
          if d2 > 0 then midi_apply_btn(a.idx, a.page) end
        end
      end
    end
  end
  return hit
end

local function aux_send(out, a, v)
  if not reaper.SendMIDIMessageToHardware then return end
  if a.status == 0xB0 then
    log_sent(0xB0, a.ch, a.d1, v)
    pcall(reaper.SendMIDIMessageToHardware, out, string.char(0xB0 + a.ch, a.d1, v))
  else
    log_sent(0x90, a.ch, a.d1, v)
    pcall(reaper.SendMIDIMessageToHardware, out, string.char(0x90 + a.ch, a.d1, v))
  end
end

-- Renvoi des valeurs vers chaque controleur aux (page a lui, toujours active)
local function aux_feedback()
  local t = reaper.time_precise()
  if (t - aux_fb_t) < 0.03 then return end
  aux_fb_t = t
  aux_reload(false)
  for _, a in ipairs(aux_maps) do
    local out = aux_out[a.page] or -1
    if a.kind == "knob" and out >= 0 and (a.ret or not FB_REQUIRE_RET) then
      local n = read_knob_norm(a.page, a.idx, t)
      local v = math.max(0, math.min(127, math.floor(n * 127 + 0.5)))
      local last = aux_fb_last[a.page]
      if not last then last = {}; aux_fb_last[a.page] = last end
      if last[a.idx] ~= v then
        aux_send(out, a, v)
        last[a.idx] = v
      end
    end
  end
end

local function midi_process()
  if not reaper.MIDI_GetRecentInputEvent then return end
  midi_reload_maps(false)
  aux_reload(false)
  do
    local sl, fp = sel_looper(), fighter_page()
    if sl ~= pk_sl then pk_sl = sl; pk_main = {}; pk_aux = {} end
    if fp ~= pk_fp then pk_fp = fp; pk_main = {} end
    local fsrc = fx_source()
    if fsrc ~= pk_fsrc then pk_fsrc = fsrc; pk_main = {}; pk_aux = {} end
  end

  -- MIDI_GetRecentInputEvent(0) = le plus RECENT. On collecte puis on traite du plus ancien au plus recent
  -- (avant : plus recent d'abord => la valeur la plus ANCIENNE du lot gagnait, puis le feedback la
  -- renvoyait au controleur : le knob "se battait" contre la main).
  local evs, newest = {}, nil
  for i = 0, 255 do
    local seq, msg, ts, dev = reaper.MIDI_GetRecentInputEvent(i)
    if not seq or seq == 0 then break end
    if i == 0 then newest = seq end
    if midi_last_seq ~= 0 and seq <= midi_last_seq then break end
    evs[#evs + 1] = { msg = msg, dev = dev }
  end
  if newest then midi_last_seq = newest end

  local now = reaper.time_precise()
  for k = #evs, 1, -1 do
    local msg, dev = evs[k].msg, evs[k].dev
    local dn = dev_name(dev)
    local skip = false
    if dn ~= "" then
      local low = dn:lower()
      for _, sub in ipairs(IGNORE_DEV_SUBSTR) do
        if low:find(sub, 1, true) then skip = true; break end
      end
    end

    if not skip and msg and #msg >= 2 then
      local b1 = msg:byte(1)
      local st, ch = b1 & 0xF0, b1 & 0x0F
      local d1, d2 = msg:byte(2) or 0, msg:byte(3) or 0
      if st == 0x80 then st, d2 = 0x90, 0 end
      if st == 0x90 or st == 0xB0 then
        -- Anti-echo : un message identique a ce qu'on vient d'ENVOYER est un renvoi (controleur qui
        -- repete, port en boucle) : on l'ignore, sinon boucle de feedback / derive sur params a pas.
        local sl = sent_log[(st << 16) | (ch << 8) | d1]
        local echo = sl and sl.v == d2 and (now - sl.t) < ECHO_WIN
        if not echo then
          local consumed = aux_handle(st, ch, d1, d2, dev)
          local blocked = consumed or main_blocked()
          if not blocked then
            for id, m in pairs(midi_maps) do
              -- le peripherique appris est respecte (dev == "" : ancienne map, accepte tout)
              if m.status == st and m.ch == ch and m.d1 == d1 and (m.dev == "" or m.dev == dn) then
                local idx = tonumber(id:match(":(%d+)$"))
                -- idx 0 est valide (Knob 1) : ne pas utiliser "if idx then" (0 est falsy en Lua)
                if idx ~= nil then
                  if id:find("knob", 1, true) then
                    if st == 0xB0 or (st == 0x90 and d2 > 0) then
                      knob_in(pk_main, id, fighter_page(), idx, d2 / 127)
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
      end
    end
  end
end

function main()
  -- Une nouvelle version demande a l'ancienne instance de s'arreter (le moteur tourne meme fenetre fermee)
  if reaper.GetExtState(HB_EXT, "quit_req") == "1" then
    reaper.SetExtState(HB_EXT, "quit_req", "", false)
    reaper.SetExtState(HB_EXT, "hb", "0", false)
    if gfx and gfx.quit then gfx.quit() end
    return
  end
  reaper.SetExtState(HB_EXT, "hb", tostring(reaper.time_precise()), false)
  reaper.SetExtState(HB_EXT, "ver", SCRIPT_VERSION, false)
  reaper.gmem_attach(GMEM)
  midi_process()
  fx_poll()

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
  if page == 7 then CU.cells() end
  if page ~= last_fighter_page or (page == 7 and CU.recolor) then
    last_fighter_page = page
    CU.recolor = false
    for i = 0, 15 do midi_fb_last[i] = -1 end  -- forcer renvoi complet
    midi_feedback_page(page)
    twister_send_colors(page)
  else
    midi_feedback_sync(page, false)
  end
  aux_feedback()

  -- Fenetre : le moteur continue meme si elle est fermee
  if reaper.GetExtState(HB_EXT, "ui_req") == "1" then
    reaper.SetExtState(HB_EXT, "ui_req", "", false)
    if not ui_open then init(); ui_open = true end
  end
  if not ui_open then reaper.defer(main) return end
  local char = gfx.getchar()
  if char < 0 then ui_open = false; gfx.quit(); reaper.defer(main) return end
  NDDOCK.tick()

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
  gfx.drawstr(string.format("TWISTER  P%d %s", PAGE_SLOT_SWAP[page] or page, PAGE_NAME[page] or ""))   -- numero affiche = bouton Launchpad
  gfx.setfont(1, "Arial", math.floor(8 * s))
  gfx.set(0.65, 0.65, 0.7, 1)
  gfx.x, gfx.y = 6 * s, 16 * s
  local fb = midi_fb_status
  if fb == "" then fb = "OUT: " .. midi_out_name() .. " | clic ici = port MIDI" end
  gfx.drawstr(fb)
  if mouse_click and gfx.mouse_y < 26 * s then
    pick_midi_out()
  end
  if page == 7 then
    gfx.setfont(1, "Arial", math.floor(9 * s))
    gfx.set(0.7, 0.7, 0.7, 1)
    gfx.x = 6 * s
    gfx.y = 16 * s
    gfx.drawstr("→ L" .. table.concat(page_targets(), ",L") .. "   (assignations : MIDI Learn > Custom P7)")
  elseif page >= 4 and page <= 5 then
    gfx.setfont(1, "Arial", math.floor(9 * s))
    gfx.set(0.7, 0.7, 0.7, 1)
    gfx.x = 6 * s
    gfx.y = 16 * s
    local tg = page_targets()
    gfx.drawstr("→ L" .. table.concat(tg, ",L"))
  elseif page == 6 then
    local st6 = fx_struct()
    local info = st6.label .. "  ·  slot " .. fx_slot_sel()
    if fx_sel.pending then
      local e = fx_lib[fx_sel.pending]
      info = string.format("S%d → %s", fx_sel.slot, e and e.name or "Aucun")
    end
    gfx.setfont(1, "Arial", math.floor(9 * s))
    gfx.set(col[1], col[2], col[3], 1)
    gfx.x = math.max(6 * s, w - gfx.measurestr(info) - 6 * s)
    gfx.y = 5 * s
    gfx.drawstr(info)
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
                  new_in = math.max(0, math.min(math.max(0, len - w_s), val * len))
                  val = new_in / len
                  reaper.gmem_write(b + 161, new_in)
                  reaper.gmem_write(b + 160, 5)
                  kind, d_norm = "shift", (drag.len0 > 0) and ((new_in - drag.in0) / drag.len0) or 0
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
    local cells = (page == 6) and fx_cells() or ((page >= 7) and CU.page_cells(page)) or PAGES[page] or {}
    local fx6 = (page == 6) and fx_struct() or nil
    for row = 0, ROWS - 1 do
      for coln = 0, COLS - 1 do
        local key = row .. "," .. coln
        local spec = cells[key]
        local cx = start_x + coln * cell_w + cell_w * 0.5
        local cy = start_y + row * cell_h + 22 * s
        -- couleur par colonne sur la page 6, sinon couleur de page
        local kcol = (page == 6) and (PAGE6_COL[coln] or col) or ((page == 7 and spec and spec.col) or col)
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
          local off = spec.inactive and spec.inactive() or false
          local hov = alive and (not off) and gfx.mouse_x >= cx - 20*s and gfx.mouse_x <= cx + 20*s
                           and gfx.mouse_y >= cy - 20*s and gfx.mouse_y <= cy + 20*s

          if mouse_down then
            if mouse_click and hov and active_id < 0 and not pedal_capture(spec) then
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
            if active_id == tw_id and alive and (not off) and drag and drag.spec == spec then
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
              if has_moved == 0 and alive and (not off) and spec.push then
                spec.push()
              elseif has_moved == 0 and alive and (not off) and li and spec.def ~= nil then
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
          if page >= 4 and page <= 5 then grouped = #page_targets() > 1 end
          local dim = (fx6 and fx6.slots[coln + 1] and fx6.slots[coln + 1].inactive) or off or false
          if alive then
            local dstr = (spec.disp and alive) and spec.disp(raw) or nil
            draw_knob(cx, cy, kr, val, spec.label, kcol, s, grouped, dim, dstr)
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

-- Instance unique : relancer le script ne fait que rouvrir la fenetre
local function boot()
  reaper.atexit(function() reaper.SetExtState(HB_EXT, "hb", "0", false) end)
  init()
  if reaper.MIDI_GetRecentInputEvent then midi_last_seq = reaper.MIDI_GetRecentInputEvent(0) or 0 end
  midi_reload_maps(true)
  aux_reload(true)
  resolve_midi_out()
  reaper.SetExtState(FX_EXT, "step", "", false)   -- purge des commandes FX orphelines
  reaper.SetExtState(FX_EXT, "abs", "", false)
  fx_rescan()
  last_fighter_page = -1  -- force FB au 1er cycle
  reaper.defer(main)
end

do
  local hb0 = tonumber(reaper.GetExtState(HB_EXT, "hb")) or 0
  if reaper.time_precise() - hb0 < 2 then
    if reaper.GetExtState(HB_EXT, "ver") == SCRIPT_VERSION then
      reaper.SetExtState(HB_EXT, "ui_req", "1", false)   -- meme version deja en cours : on rouvre juste la fenetre
      return
    end
    -- une AUTRE version tourne encore : on lui demande de s'arreter puis on prend le relais
    reaper.SetExtState(HB_EXT, "quit_req", "1", false)
    local t0 = reaper.time_precise()
    local function takeover()
      local hb = tonumber(reaper.GetExtState(HB_EXT, "hb")) or 0
      if reaper.time_precise() - hb >= 1 then boot() return end
      if reaper.time_precise() - t0 > 4 then
        reaper.SetExtState(HB_EXT, "quit_req", "", false)
        reaper.ShowMessageBox("Une ancienne version du script Twister tourne encore (elle reste active meme fenetre fermee).\n\n"
          .. "Fermez-la : Actions > 'ReaScript: Close all running reascripts', puis relancez ce script.", "Twister", 0)
        return
      end
      reaper.defer(takeover)
    end
    reaper.defer(takeover)
    return
  end
end
boot()




