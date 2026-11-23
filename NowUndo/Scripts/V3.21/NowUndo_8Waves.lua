-- @description NowUndo 8 Waves - les 8 formes d'onde empilees, pleine largeur (variante du 8 Looper Panel)
-- @version 1.0
-- Meme lecture gmem et memes codes que le 8 Looper Panel : couleur d'etat de la forme d'onde (verte en lecture, bleue
-- en Cloud), zone des grains du Cloud, cadre jaune du Slicer / bleu du Cloud, slices, sync point, In / Out, tete de
-- lecture, cadre de selection (jaune) et de groupe (couleur du groupe, clignote si selectionne).
-- Pas de parametres, pas de sources, pas de boutons : affichage seul. La fenetre se redimensionne librement.

local MAX_INST = 8
local DASH_BASE = 6000
local SLICE_GMEM_BASE, SLICE_GMEM_STRIDE, SLICE_GMEM_MAX = 100000, 259, 256
local GROUP_RGB = {{1,.25,.25},{.23,.48,1},{.19,.88,.38},{.88,.25,1}}
local HUES = {{.82,.22,.22},{.88,.48,.15},{.85,.78,.18},{.22,.78,.34},{.18,.72,.78},{.22,.42,.92},{.68,.30,.88},{.88,.35,.68}}
local DIM = .42
local EXT = "NowUndo_8Waves"
local STATE_NAME = {[1]="REC",[2]="PLAY",[3]="OVERDUB",[4]="REPLACE",[5]="AUTO-REP",[6]="MULTIPLY",[7]="WAIT",[8]="SYNC"}
local STATE_COL = {[1]={.92,.20,.22},[2]={.95,.55,.82},[3]={.96,.56,.16},[4]={.80,.80,.86},[5]={.82,.70,.50},[6]={.68,.30,.88},[7]={.95,.58,.18},[8]={.95,.58,.18}}
local PART_NAME = {"MAIN","CHORUS","BRIDGE"}
local SEL_LOOPER = 0
local WV_CACHE, SL_CACHE = {}, {}

local function read(base, off) return reaper.gmem_read(base + off) or 0 end
-- Saturation de TOUT le cadre d'un looper (fond, forme d'onde, reperes, etiquettes, VU de sortie) : Out Vol 0 dB (ou
-- plus) = pleine couleur, -40 dB = noir et blanc, courbe marquee (-6 dB ~ 80 %, -12 dB ~ 60 %, -20 dB ~ 35 %) ; MUTE =
-- noir et blanc direct. En gris, le dessin est aussi un peu assombri, mais les textes et la tete de lecture gardent une
-- luminosite minimale (lisibles). Restent en couleur : VU d'entree (independant du volume de sortie) et cadre de groupe.
-- VU-metres verticaux : entree (+172) avant la forme d'onde, sortie (+173) apres.
local VIS = {s = 1, R = {}}
function VIS.sat(out_vol, muted)
  if muted then return 0 end
  local db = 20 * math.log(math.max(0.000001, out_vol), 10)
  return math.max(0, math.min(1, (db + 40) / 40)) ^ 1.5
end
-- couleur vue a travers la saturation courante VIS.s ; hi = texte / tete : pas assombri, luminosite >= .80 en gris
function VIS.col(r, g, b, hi)
  local s = VIS.s; if s >= 1 then return r, g, b end
  local l = r * .30 + g * .59 + b * .11
  r, g, b = l + (r - l) * s, l + (g - l) * s, l + (b - l) * s
  if hi then
    local nl = l + (math.max(l, .80) - l) * (1 - s)
    if l > .001 then local k = nl / l; r, g, b = math.min(1, r * k), math.min(1, g * k), math.min(1, b * k)
    else r, g, b = nl, nl, nl end
  else local d = .65 + .35 * s; r, g, b = r * d, g * d, b * d end
  return r, g, b
end
local function setc(r, g, b, a) r, g, b = VIS.col(r, g, b); gfx.set(r, g, b, a or 1) end
local function setc_hi(r, g, b, a) r, g, b = VIS.col(r, g, b, true); gfx.set(r, g, b, a or 1) end
local function rect(x, y, w, h, r, g, b, a, fill) setc(r, g, b, a); gfx.rect(x, y, w, h, fill == nil and 1 or fill) end
local FONT_SLOT, FONT_N, CUR_FONT = {}, 9, nil
local function setfont(sz, bold)
  local key = sz * 2 + (bold and 1 or 0); local slot = FONT_SLOT[key]
  if not slot then
    FONT_N = FONT_N + 1; if FONT_N > 120 then FONT_N = 10; FONT_SLOT = {}; CUR_FONT = nil end
    slot = FONT_N; FONT_SLOT[key] = slot; gfx.setfont(slot, "Arial", sz, bold and "b" or ""); CUR_FONT = slot
  elseif CUR_FONT ~= slot then gfx.setfont(slot); CUR_FONT = slot end
end
function VIS.vmeter(x, y, w, h, val)                               -- dB -48 .. 0, du bas vers le haut
  rect(x, y, w, h, .055, .06, .07, 1, 1)
  local db = 20 * math.log(math.max(0.00001, val), 10)
  local ratio = math.max(0, math.min(1, (db + 48) / 48))
  if ratio > 0 then
    local mr, mg, mb = .20, .82, .42
    if ratio > .82 then mr, mg, mb = .95, .30, .20 elseif ratio > .62 then mr, mg, mb = .95, .70, .20 end
    local hh = (h - 2) * ratio
    rect(x + 1, y + h - 1 - hh, w - 2, hh, mr, mg, mb, .95, 1)
  end
end
local function text(x, y, str, size, r, g, b, bold)
  setfont(math.max(7, math.floor(size)), bold); setc_hi(r, g, b, 1); gfx.x = x; gfx.y = y; gfx.drawstr(tostring(str))
end

-- Fenetre : position / taille / dock memorises (comme le 8 Looper Panel)
local DOCK = {t = 0, sig = ""}
local function win_init()
  local function ld(k, d) return tonumber(reaper.GetExtState(EXT, k)) or d end
  local w, h = ld("w", 1400), ld("h", 820)
  if w < 300 then w = 1400 end; if h < 200 then h = 820 end
  gfx.init("NowUndo 8 Waves", w, h, ld("dock", 0), ld("x", 100), ld("y", 100))
end
local function win_save()
  local t = reaper.time_precise(); if t - DOCK.t < 1 then return end; DOCK.t = t
  local d, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0); d = math.floor(d or 0)
  local sig = d .. "," .. x .. "," .. y .. "," .. w .. "," .. h; if sig == DOCK.sig then return end; DOCK.sig = sig
  reaper.SetExtState(EXT, "dock", tostring(d), true)
  if (d & 1) == 0 then
    reaper.SetExtState(EXT, "x", tostring(math.floor(x)), true); reaper.SetExtState(EXT, "y", tostring(math.floor(y)), true)
    reaper.SetExtState(EXT, "w", tostring(math.floor(w)), true); reaper.SetExtState(EXT, "h", tostring(math.floor(h)), true)
  end
end

local function draw_row(i, x, y, w, h, now_t, s)
  VIS.s = 1
  local base0 = 1000 + i * 600
  local ap = math.floor(read(base0, 42) + .5)
  local alive = read(base0, 0) > 0 and (now_t - read(130, i)) <= 3.0 and ap >= 1 and ap <= 3
  local hue = math.floor(read(160, i) + .5); if hue < 1 or hue > 8 then hue = (i % 8) + 1 end
  local hc = HUES[hue]
  local fs = math.max(8, math.min(13, h * .16))                    -- taille du texte suit la hauteur de la ligne
  if not alive then
    rect(x, y, w, h, .06 + hc[1] * .07, .06 + hc[2] * .07, .07 + hc[3] * .07, 1, 1)
    rect(x, y, w, h, hc[1] * .30 + .08, hc[2] * .30 + .08, hc[3] * .30 + .09, 1, 0)
    text(x + 6, y + 4, "LOOPER " .. (i + 1) .. "   INACTIF", fs, hc[1] * .55 + .10, hc[2] * .55 + .10, hc[3] * .55 + .10, true)
    VIS.R[i] = nil
    return
  end
  local p = ap - 1; local gb = base0 + p * 200
  local alias = read(gb, 1); if alias < 1 then alias = i + 1 end
  local state = math.floor(read(gb, 2) + .5)
  local length, ls, lw = read(gb, 46), read(gb, 44), read(gb, 45)
  local sy_pos, sy_id, sy_len, sy_live = read(gb, 182), math.floor(read(gb, 183) + .5), read(gb, 184), read(gb, 185) > .5
  if length <= 0 then sy_pos = -1 end
  local st_col = STATE_COL[state] or {.035, .035, .04}
  local is_stop = STATE_COL[state] == nil
  local muted = read(gb, 199) > .5                                 -- mute du looper
  VIS.s = VIS.sat(read(gb, 22), muted)                             -- saturation de tout le cadre selon le volume de sortie
  local slicer_on, cloud_on = read(gb, 8) == 1, read(gb, 24) > .5
  -- selection / groupe : teinte legere de tout le fond (couleur du groupe, sinon jaune si selectionne) + cadre
  local ds_i = math.floor(alias + .5); if ds_i < 1 or ds_i > 8 then ds_i = i + 1 end
  local gc = GROUP_RGB[math.floor(read(DASH_BASE, ds_i) + .5)]
  local is_sel = (SEL_LOOPER == ds_i)
  local tc = gc or (is_sel and {.98, .83, .22}) or nil
  local tk = (gc and is_sel) and .24 or .17                       -- groupe + selection : un peu plus soutenu

  -- fond de la ligne (teinte du looper) et fond de la forme d'onde (gris clair a l'arret, comme le panneau)
  if is_stop then rect(x, y, w, h, .07 + hc[1] * .07, .07 + hc[2] * .07, .08 + hc[3] * .07, 1, 1)
  else rect(x, y, w, h, .075 + hc[1] * .13, .075 + hc[2] * .13, .085 + hc[3] * .13, 1, 1) end
  local VW = math.max(4, math.min(8, math.floor(h * .07)))       -- VU d'entree (avant) / de sortie (apres)
  local wx, wy, ww, wh = x + 6 + VW, y + 3, w - 12 - 2 * VW, h - 6
  local vs = VIS.s; VIS.s = 1; VIS.vmeter(x + 5, wy, VW, wh, read(gb, 172)); VIS.s = vs; VIS.vmeter(x + w - 2 - VW, wy, VW, wh, read(gb, 173))
  -- fond de la forme d'onde teinte de la couleur du looper : a l'arret, et un peu plus sombre en lecture (la forme d'onde ressort)
  local wbg = is_stop and {.05 + hc[1] * .10, .05 + hc[2] * .10, .06 + hc[3] * .10} or {.035 + hc[1] * .11, .035 + hc[2] * .11, .042 + hc[3] * .11}
  rect(wx, wy, ww, wh, wbg[1], wbg[2], wbg[3], 1, 1)
  -- geometrie de la ligne pour la souris (frame suivante) ; zone des grains en echantillons (+178 / +179 = % de la longueur)
  VIS.R[i] = { ds = ds_i, x = x, y = y, w = w, h = h, wx = wx, wy = wy, ww = ww, wh = wh, gb = gb, len = length, ls = ls, lw = lw,
               cloud = cloud_on and length > 0 and lw > 0, z0 = read(gb, 178) * .01 * length, z1 = read(gb, 179) * .01 * length }
  if tc then
    rect(x, y, w, h, tc[1], tc[2], tc[3], tk, 1)                    -- voile de la couleur du groupe / de la selection
    if length > 0 and lw > 0 then                                    -- ... sauf hors de In / Out : fond normal (non selectionne)
      local ix = wx + math.max(0, math.min(1, ls / length)) * ww
      local ox = wx + math.max(0, math.min(1, math.min(ls + lw, length) / length)) * ww
      local br, bg, bb = wbg[1], wbg[2], wbg[3]
      if ix - wx >= 1 then rect(wx, wy, ix - wx, wh, br, bg, bb, 1, 1) end
      if wx + ww - ox >= 1 then rect(ox, wy, wx + ww - ox, wh, br, bg, bb, 1, 1) end
    end
  end
  rect(x, y, 4, h, is_stop and hc[1] * DIM or hc[1], is_stop and hc[2] * DIM or hc[2], is_stop and hc[3] * DIM or hc[3], 1, 1)   -- liseré couleur du looper
  if slicer_on then rect(wx - 1, wy - 1, ww + 2, wh + 2, .96, .78, .12, 1, 0) end
  if cloud_on then rect(wx - 2, wy - 2, ww + 4, wh + 4, .35, .70, 1, 1, 0) end

  local wc = (state == 2) and {.20, .82, .38} or st_col
  if cloud_on and state == 2 then wc = {.35, .70, 1} end
  if is_stop then wc = {hc[1] * .55, hc[2] * .55, hc[3] * .55} end

  -- forme d'onde : 100 points publies par le looper, interpoles sur toute la largeur (colonnes de 2 px)
  local wv = WV_CACHE[i]
  if not wv or wv.g ~= gb or now_t - wv.t > .05 then
    wv = wv or {a = {}}; wv.t = now_t; wv.g = gb
    for k = 0, 99 do wv.a[k] = math.min(1, read(gb, 50 + k)) end
    WV_CACHE[i] = wv
  end
  local a, mid, amp = wv.a, wy + wh * .5, wh * .46
  setc(wc[1], wc[2], wc[3], .95)
  local step = 2
  for px = 0, ww - 1, step do
    local f = px / ww * 99; local k = math.floor(f); local t = f - k
    local v = a[k] * (1 - t) + (a[math.min(99, k + 1)] or 0) * t
    local hh = v * amp
    if hh >= .5 then gfx.rect(wx + px, mid - hh, step - .5, hh * 2, 1) end
  end

  -- zone des grains du Cloud (+178 / +179 en % de la longueur), repliee dans la fenetre In/Out.
  -- Peinte PAR-DESSUS la forme d'onde (pleine largeur, elle la recouvrirait sinon) : voile bleu + bords
  if cloud_on and not is_stop and length > 0 then
    local z0, z1 = read(gb, 178) * .01 * length, read(gb, 179) * .01 * length
    local wl = math.max(1, lw)
    local function band(a, b)
      local x0 = wx + math.max(0, math.min(1, a / length)) * ww; local x1 = wx + math.max(0, math.min(1, b / length)) * ww
      if x1 - x0 >= 1 then
        setc(.35, .70, 1, .28); gfx.rect(x0, wy, x1 - x0, wh, 1)
        local bh = math.max(3, math.floor(wh * .06))                 -- barres pleines haut / bas : visibles quoi qu'il arrive
        setc(.40, .75, 1, 1); gfx.rect(x0, wy, x1 - x0, bh, 1); gfx.rect(x0, wy + wh - bh, x1 - x0, bh, 1)
        setc(.60, .85, 1, 1); gfx.line(x0, wy, x0, wy + wh); gfx.line(x1, wy, x1, wy + wh) end
    end
    if z1 > z0 then
      if z1 - z0 >= wl then band(ls, ls + wl)
      else local a = z0 - ls; a = a - math.floor(a / wl) * wl; local b = a + (z1 - z0)
        if b <= wl then band(ls + a, ls + b) else band(ls + a, ls + wl); band(ls, ls + b - wl) end end
    end
  end

  -- parties exclues de In / Out : grisees (voile par-dessus la forme d'onde)
  if length > 0 and lw > 0 then
    local gx0 = wx + math.max(0, math.min(1, ls / length)) * ww
    local gx1 = wx + math.max(0, math.min(1, math.min(ls + lw, length) / length)) * ww
    if gx0 - wx >= 1 then rect(wx, wy, gx0 - wx, wh, .13, .13, .15, .72, 1) end
    if wx + ww - gx1 >= 1 then rect(gx1, wy, wx + ww - gx1, wh, .13, .13, .15, .72, 1) end
  end
  if length > 0 and lw > 0 then
    -- slices (jaune), comme le panneau : seulement si l'analyse correspond a la fenetre In/Out actuelle
    local sb = SLICE_GMEM_BASE + ((i * 3) + p) * SLICE_GMEM_STRIDE
    local sc = SL_CACHE[i]
    if not sc or sc.sb ~= sb or now_t - sc.t > .1 then
      sc = sc or {r = {}}; sc.t = now_t; sc.sb = sb
      sc.n = math.max(0, math.min(SLICE_GMEM_MAX, math.floor(read(sb, 0) + .5))); sc.es = read(sb, 1); sc.ew = read(sb, 2)
      for k = 0, sc.n - 1 do sc.r[k] = read(sb, 3 + k) end
      SL_CACHE[i] = sc
    end
    if sc.n > 0 and sc.ew > 0 and math.abs(sc.es - ls) < 2 and math.abs(sc.ew - lw) < 2 then
      setc(1, .83, .12, .40)
      for k = 0, sc.n - 1 do
        local rel = sc.r[k]; local ab = ls + rel
        if rel >= 0 and rel <= lw and ab >= 0 and ab <= length then local sx = wx + (ab / length) * ww; gfx.line(sx, wy + 1, sx, wy + wh - 1) end
      end
    end
    -- sync point (rouge pointille), repete tous les M samples quand la boucle est plus longue que la reference
    if sy_pos >= 0 and sy_id > 0 then
      local al = sy_live and 1 or .45; local k = 0
      while k < 64 and (k == 0 or (sy_len > 1 and sy_pos + k * sy_len < length)) do
        local sx = wx + ((sy_pos + k * sy_len) / length) * ww
        setc(1, .10, .10, k == 0 and al or al * .5)
        for yy = wy, wy + wh - 1, 6 do gfx.line(sx, yy, sx, math.min(yy + 3, wy + wh)) end
        if k == 0 then gfx.triangle(sx, wy + wh, sx + 6, wy + wh, sx, wy + wh - 8) end
        k = k + 1
      end
    end
    local endpos = math.min(ls + lw, length)
    setc(.32, .88, .52, 1); local ix = wx + (ls / length) * ww; gfx.line(ix, wy, ix, wy + wh)
    local hw, hh = math.max(5, math.floor(wh * .06)), math.max(8, math.floor(wh * .16))   -- poignees (souris / doigt)
    gfx.rect(ix, wy, hw, hh, 1); gfx.rect(ix, wy + wh - hh, hw, hh, 1)
    setc(.55, 1, .68, 1); local ox = wx + (endpos / length) * ww; gfx.line(ox, wy, ox, wy + wh)
    gfx.rect(ox - hw + 1, wy, hw, hh, 1); gfx.rect(ox - hw + 1, wy + wh - hh, hw, hh, 1)
  end
  local px = wx + math.max(0, math.min(100, read(gb, 47))) * .01 * ww
  setc_hi(.95, .55, .82, 1); gfx.line(px, wy, px, wy + wh); gfx.line(px + 1, wy, px + 1, wy + wh)

  -- nom et etat, discrets, en haut a gauche
  -- nom (+ partie seulement si ce n'est pas MAIN) et sources qui entrent dans le looper (I = inputs, L = loopers)
  local nm = "L" .. math.floor(alias + .5) .. ((ap ~= 1) and ("  " .. PART_NAME[ap]) or "")
  do
    local im, lm, src = math.floor(read(DASH_BASE, 10 + ds_i) + .5), math.floor(read(DASH_BASE, 20 + ds_i) + .5), {}
    for k = 0, 7 do if (im >> k) & 1 == 1 then src[#src + 1] = "I" .. (k + 1) end end
    for k = 0, 7 do if (lm >> k) & 1 == 1 then src[#src + 1] = "L" .. (k + 1) end end
    if #src > 0 then nm = nm .. "  (" .. table.concat(src, " ") .. ")" end
  end
  setfont(math.floor(fs), true); local nw = gfx.measurestr(nm)
  -- etiquette : nom, etat, puis modes (REVERSE / SLICE / CLOUD) et effets actifs (FX n, en rose)
  local parts = {{nm, .94, .94, .96}}
  local sn = STATE_NAME[state] or "STOP"
  if muted then parts[#parts + 1] = {"MUTE", .70, .70, .74}
  elseif is_stop then parts[#parts + 1] = {sn, .62, .64, .68} else parts[#parts + 1] = {sn, st_col[1] + .15, st_col[2] + .15, st_col[3] + .15} end
  if read(gb, 17) > .5 then parts[#parts + 1] = {"REVERSE", .82, .78, .95} end
  if slicer_on then parts[#parts + 1] = {"SLICE", .98, .83, .22} end
  if cloud_on then parts[#parts + 1] = {"CLOUD", .45, .75, 1} end
  local spd, pch = read(gb, 3), read(gb, 4)                       -- vitesse / pitch publies par le looper (+3 / +4)
  if spd > 0 and math.abs(spd - 1) > .005 then parts[#parts + 1] = {string.format("SP x%.2f", spd), .95, .55, .82} end
  if math.abs(pch) > .05 then parts[#parts + 1] = {string.format("PS %+.1f", pch), .95, .55, .82} end
  local fxm = math.floor(read(DASH_BASE, 30 + ds_i) + .5)       -- slots FX actifs (publie par le Launchpad)
  if fxm > 0 then
    local l = {}
    for sl = 1, 8 do if (fxm >> (sl - 1)) & 1 == 1 then l[#l + 1] = tostring(sl) end end
    parts[#parts + 1] = {"FX " .. table.concat(l, " "), .98, .45, .78}
  end
  local tw, gapw = 0, fs * .9
  for k, pt in ipairs(parts) do pt.w = gfx.measurestr(pt[1]); tw = tw + pt.w + (k > 1 and gapw or 0) end
  rect(wx + 2, wy + 2, tw + 10, fs + 6, 0, 0, 0, .55, 1)
  VIS.R[i].tag = tw + 12                                           -- etiquette : un clic dessus = selection seule
  local tx = wx + 6
  for _, pt in ipairs(parts) do text(tx, wy + 4, pt[1], fs, pt[2], pt[3], pt[4], true); tx = tx + pt.w + gapw end

  -- tout a droite : M (maitre), S (esclave) ou F (libre), meme logique que le 8 Panel
  do
    local sy_master = read(gb, 187) > .5
    local tag, cr, cg, cb = "F", .60, .62, .68
    if sy_id > 0 and sy_pos >= 0 then
      if sy_master then tag, cr, cg, cb = "M", 1, .82, .30
      else tag, cr, cg, cb = "S", .48, .68, .95; if not sy_live then cr, cg, cb = .90, .62, .25 end end
    end
    local bf = math.max(10, math.min(22, h * .26))
    setfont(math.floor(bf), true); local tgw = gfx.measurestr(tag)
    rect(wx + ww - tgw - 12, wy + 2, tgw + 10, bf + 6, 0, 0, 0, .55, 1)
    text(wx + ww - tgw - 7, wy + 4, tag, bf, cr, cg, cb, true)
  end

  -- cadre de selection / groupe (meme code que le Launchpad et le panneau)
  local ol, thick = nil, 2
  if gc then
    local lvl = .85
    if is_sel then lvl = (math.floor(now_t * 4) % 2 == 0) and 1.0 or .45; thick = 3 end
    ol = {gc[1] * lvl, gc[2] * lvl, gc[3] * lvl}
  elseif is_sel then ol = {.98, .83, .22}; thick = 3 end
  if ol then
    -- le cadre entoure la zone In / Out (toute la ligne si la boucle est vide)
    local fx0, fx1 = x, x + w
    if length > 0 and lw > 0 then
      fx0 = wx + math.max(0, math.min(1, ls / length)) * ww - thick
      fx1 = wx + math.max(0, math.min(1, math.min(ls + lw, length) / length)) * ww + thick
      fx0 = math.max(x, fx0); fx1 = math.min(x + w, fx1)
    end
    VIS.s = 1                                                       -- le cadre de groupe garde sa couleur (lisible)
    for k = 0, thick - 1 do rect(fx0 + k, y + k, fx1 - fx0 - 2 * k, h - 2 * k, ol[1], ol[2], ol[3], 1, 0) end
  end
end

-- ============================================================================================================
-- INTERACTION (V3.27) : clic = selection + tap de la 2e rangee du Launchpad (statut : lecture/stop, sortie REC / slicer /
-- reverse / cloud...), clic sur l'etiquette = selection seule, Ctrl + clic = geste de groupe (comme Ctrl + clic sur la
-- rangee du haut du Launchpad), fleches haut / bas = selection, glisser : bords In / Out, milieu = deplacer la fenetre,
-- zone des grains du Cloud (milieu = position, bords = largeur). Commandes vers le Launchpad : NowUndo_VLcmd/q.
-- ============================================================================================================
local UI = { down = false, drag = nil, ctrl_sess = false }
function UI.lp(cmd)
  local q = reaper.GetExtState("NowUndo_VLcmd", "q")
  reaper.SetExtState("NowUndo_VLcmd", "q", q .. cmd .. "\t" .. string.format("%.3f", reaper.time_precise()) .. "\n", false)
end
function UI.row_at(mx, my)
  for i = 0, MAX_INST - 1 do
    local R = VIS.R[i]
    if R and mx >= R.x and mx < R.x + R.w and my >= R.y and my < R.y + R.h then return i, R end
  end
end
local function sx(R, smp) return R.wx + smp / R.len * R.ww end           -- echantillon -> x ecran
local function smp_at(R, px) return math.max(0, math.min(R.len, (px - R.wx) / R.ww * R.len)) end
-- zone des grains repliee dans la fenetre In / Out : centre (dans la fenetre) et demi-largeur, en echantillons
function UI.zone(R)
  if not R.cloud or R.z1 <= R.z0 then return nil end
  local wl = math.max(1, R.lw)
  local half = math.min(wl * .5, (R.z1 - R.z0) * .5)
  local c = (R.z0 + R.z1) * .5 - R.ls; c = c - math.floor(c / wl) * wl
  return R.ls + c, half, wl
end
-- distance (echantillons) entre x et le centre de la zone, en tenant compte du repli dans la fenetre
local function zdist(R, smp, c, wl)
  local d = smp - c; d = d - math.floor(d / wl + .5) * wl; return d
end
function UI.hit(R, mx, my)
  if R.tag and mx >= R.wx and mx < R.wx + R.tag and my >= R.wy and my < R.wy + R.wh * .35 then return "tag" end
  if mx < R.wx or mx >= R.wx + R.ww then return "tag" end              -- VU / marges : selection seule
  if R.len <= 0 or R.lw <= 0 then return "row" end
  local tol = math.max(8, math.min(18, R.ww * .012))
  local ix, ox = sx(R, R.ls), sx(R, math.min(R.len, R.ls + R.lw))
  if math.abs(mx - ix) <= tol and math.abs(mx - ix) <= math.abs(mx - ox) then return "in" end
  if math.abs(mx - ox) <= tol then return "out" end
  local c, half, wl = UI.zone(R)
  if c then
    local d = math.abs(zdist(R, smp_at(R, mx), c, wl)) / R.len * R.ww          -- en pixels
    local hp = half / R.len * R.ww
    if math.abs(d - hp) <= tol and hp > tol then return "zedge" end
    if d < hp then return "zmove" end
  end
  if mx > ix and mx < ox then return "win" end
  return "row"
end
local CURSOR = { ["in"] = 32644, out = 32644, zedge = 32644, win = 32646, zmove = 32646 }   -- <-> / deplacement
function UI.param(gb, box, id, v) reaper.gmem_write(gb + box + 1, v); reaper.gmem_write(gb + box, id) end
function UI.tick(ch)
  local mx, my, cap = gfx.mouse_x, gfx.mouse_y, gfx.mouse_cap
  local down, ctrl = (cap & 1) == 1, (cap & 4) == 4
  if not ctrl then UI.ctrl_sess = false end                           -- Ctrl relache = fin du geste de groupe
  -- fleches haut / bas : looper actif suivant / precedent (ordre des lignes)
  if ch == 30064 or ch == 1685026670 then
    local list, cur = {}, nil
    for i = 0, MAX_INST - 1 do if VIS.R[i] then list[#list + 1] = VIS.R[i].ds; if VIS.R[i].ds == SEL_LOOPER then cur = #list end end end
    if #list > 0 then
      local k = cur and (cur + (ch == 30064 and -1 or 1)) or 1
      k = math.max(1, math.min(#list, k))
      if list[k] ~= SEL_LOOPER then UI.lp("sel_" .. list[k]); SEL_LOOPER = list[k] end
    end
  end
  local D = UI.drag
  if down and not UI.down then                                        -- appui
    local i, R = UI.row_at(mx, my)
    if R then
      if ctrl then
        UI.lp("ctrlgrp_" .. R.ds .. "_" .. (UI.ctrl_sess and "0" or "1")); UI.ctrl_sess = true
      else
        local kind = UI.hit(R, mx, my)
        D = { i = i, ds = R.ds, kind = kind, x0 = mx, t0 = reaper.time_precise(), moved = false, gb = R.gb, len = R.len,
              ls = R.ls, lw = R.lw }
        if kind == "zmove" or kind == "zedge" then D.zc, D.zh, D.zw = UI.zone(R) end
        if R.ds ~= SEL_LOOPER then UI.lp("sel_" .. R.ds); SEL_LOOPER = R.ds end
        UI.drag = D
      end
    end
  elseif down and D then                                              -- glisser
    local R = VIS.R[D.i]
    if R and math.abs(mx - D.x0) > 4 then D.moved = true end
    if R and D.moved and D.len > 0 and (D.lx ~= mx) then
      D.lx = mx
      local s = smp_at(R, mx)
      local ds = (mx - D.x0) / R.ww * D.len
      if D.kind == "in" then
        -- REGLE ABSOLUE : la poignee In decale la fenetre, l'ecart ne bouge pas (cmd 5)
        reaper.gmem_write(D.gb + 161, math.max(0, math.min(D.len - D.lw, s))); reaper.gmem_write(D.gb + 160, 5)
      elseif D.kind == "out" then
        reaper.gmem_write(D.gb + 162, math.max(s, D.ls + 1)); reaper.gmem_write(D.gb + 160, 2)
      elseif D.kind == "win" then
        reaper.gmem_write(D.gb + 161, math.max(0, math.min(D.len - D.lw, D.ls + ds))); reaper.gmem_write(D.gb + 160, 5)
      elseif D.kind == "zmove" and D.zc then                          -- position des grains (mode Free) en % de la fenetre
        if not D.free then UI.param(D.gb, 195, 37, 1); D.free = true end
        local c = D.zc + ds - D.ls; c = c - math.floor(c / D.zw) * D.zw
        UI.param(D.gb, 180, 38, math.max(0, math.min(100, c / D.zw * 100)))
      elseif D.kind == "zedge" and D.zc then                          -- largeur de la zone = Spread
        local half = math.abs(zdist(R, s, D.zc, D.zw))
        UI.param(D.gb, 180, 28, math.max(0, math.min(1, half / (D.zw * .5))))
      end
    end
  elseif not down and UI.down and D then                              -- relachement : clic rapide = tap de statut
    if not D.moved and D.kind ~= "tag" and reaper.time_precise() - D.t0 < .4 then UI.lp("stap_" .. D.ds) end
    UI.drag = nil
  end
  if not down then UI.drag = nil end
  UI.down = down
  -- curseur selon ce qui est sous la souris
  local _, R = UI.row_at(mx, my)
  local want = (UI.drag and CURSOR[UI.drag.kind]) or (R and not ctrl and CURSOR[UI.hit(R, mx, my)]) or 32512
  if want ~= UI.cur then UI.cur = want; if gfx.setcursor then gfx.setcursor(want) end end
end

local function main()
  local ch = gfx.getchar(); if ch < 0 then return end
  win_save()
  local w, h = gfx.w, gfx.h
  local now_t = reaper.time_precise()
  SEL_LOOPER = math.floor(tonumber(reaper.GetExtState("nowundo_vl", "sel_looper")) or 0)
  UI.tick(ch)
  rect(0, 0, w, h, .055, .06, .075, 1, 1)
  local m, gap = 6, 4
  local rh = (h - 2 * m - gap * (MAX_INST - 1)) / MAX_INST
  for i = 0, MAX_INST - 1 do draw_row(i, m, m + i * (rh + gap), w - 2 * m, rh, now_t) end
  gfx.update(); reaper.defer(main)
end

reaper.gmem_attach("nowundo_sync")
win_init(); gfx.clear = 0x0D0D11
reaper.defer(main)
