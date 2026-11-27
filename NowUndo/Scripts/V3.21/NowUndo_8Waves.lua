-- @description NowUndo 8 Waves - les 8 formes d'onde empilees, pleine largeur (variante du 8 Looper Panel)
-- @version 1.0
-- Meme lecture gmem et memes codes que le 8 Looper Panel : couleur d'etat de la forme d'onde (verte en lecture, bleue
-- en Cloud), zone des grains du Cloud, cadre jaune du Slicer / bleu du Cloud, slices, sync point, In / Out, tete de
-- lecture, cadre de selection (jaune) et de groupe (couleur du groupe, clignote si selectionne).
-- Pas de parametres, pas de sources, pas de boutons. La fenetre se redimensionne librement.
-- Import de fichiers audio (glisser-deposer / clic droit sur une ligne) : voir IMP plus bas.

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

-- 27 nov. : SENDS VERS LES AUX, publies par le Launchpad (gmem 6098 = 1re piste aux, 6099 = nombre,
-- 6100 + (L-1)*8 + (a-1) = send du looper : > 0 ouvert, < 0 ferme (niveau garde), 0 = pas d'envoi ; 6228 + ... = aux -> looper).
-- Une pastille par aux en bas a gauche de la forme d'onde : nom de la piste aux + niveau ; < devant le nom (cadre orange) = l'aux revient dans ce looper.
-- Souris : clic = ouvrir / fermer, glisser a gauche / a droite = niveau, clic droit = aux -> ce looper (on / off).
VIS.AUXN = { t = -10, n = {} }
function VIS.aux_names(now_t)
  local A = VIS.AUXN
  if now_t - A.t < 1 then return A.n end
  A.t = now_t
  local first, cnt = math.floor(read(6098, 0) + .5), math.floor(read(6099, 0) + .5)
  for a = 1, 8 do A.n[a] = nil end
  for a = 1, math.min(8, cnt) do
    local tr = first > 0 and reaper.GetTrack(0, first + a - 2)
    local nm = ""
    if tr then local _, n = reaper.GetTrackName(tr); nm = n or "" end
    nm = nm:gsub("^%s+", ""):gsub("%s+$", "")
    if nm == "" or nm:match("^Track %d+$") or nm:match("^Piste %d+$") then nm = "aux" .. a end
    A.n[a] = (#nm > 8) and nm:sub(1, 8) or nm
  end
  return A.n
end
function VIS.aux_badges(i, ds, wx, wy, ww, wh, fs)
  local names = VIS.aux_names(reaper.time_precise())
  local R = VIS.R[i]; R.ab = {}
  if #names == 0 or wh < fs * 2.6 then return end
  local bf = math.max(9, math.floor(fs * .82))
  setfont(bf, false)
  local vs = VIS.s; VIS.s = 1                                     -- les pastilles gardent leur couleur (Out Vol baisse = grise ailleurs)
  local bx, bh = wx + 4, bf + 5
  local by = wy + wh - bh - 3
  for a = 1, #names do
    local v = read(6100 + (ds - 1) * 8 + (a - 1), 0)
    local rx = read(6228 + (ds - 1) * 8 + (a - 1), 0) > .5
    local lvl = math.abs(v)
    local txt = (rx and "<" or "") .. names[a] .. " " .. ((v == 0) and "-" or string.format("%d%%", math.floor(lvl * 100 + .5)))
    local tw = gfx.measurestr(txt) + 10
    if bx + tw > wx + ww * .7 then break end
    if v > 0 then rect(bx, by, tw, bh, .10, .42, .48, .92, 1); rect(bx, by + bh - 3, (tw) * math.min(1, lvl), 3, .35, .95, 1, 1, 1)
    else rect(bx, by, tw, bh, .12, .12, .14, .80, 1) end
    if rx then rect(bx, by, tw, bh, .98, .70, .25, 1, 0) end
    text(bx + 5, by + 2, txt, bf, v > 0 and .90 or .55, v > 0 and 1 or .57, v > 0 and 1 or .62, false)
    R.ab[#R.ab + 1] = { x = bx, y = by, w = tw, h = bh, a = a, v = v }
    bx = bx + tw + 4
  end
  VIS.s = vs
end

-- Fenetre : position / taille / dock memorises (comme le 8 Looper Panel)
local DOCK = {t = 0, sig = ""}
local function win_init()
  local function ld(k, d) return tonumber(reaper.GetExtState(EXT, k)) or d end
  local w, h = ld("w", 1400), ld("h", 820)
  if w < 300 then w = 1400 end; if h < 200 then h = 820 end
  gfx.init("Dripsody 8 Waves", w, h, ld("dock", 0), ld("x", 100), ld("y", 100))
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

  VIS.aux_badges(i, ds_i, wx, wy, ww, wh, fs)                     -- 27 nov. : sends vers les aux (en bas a gauche)

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
function UI.badge(R, mx, my)                                         -- 27 nov. : pastille d'un send aux sous la souris
  for _, b in ipairs(R.ab or {}) do
    if mx >= b.x and mx < b.x + b.w and my >= b.y and my < b.y + b.h then return b end
  end
end
function UI.hit(R, mx, my)
  if UI.badge(R, mx, my) then return "aux" end
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
local CURSOR = { aux = 32644, ["in"] = 32644, out = 32644, zedge = 32644, win = 32646, zmove = 32646 }   -- <-> / deplacement
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
        if kind == "aux" then local b = UI.badge(R, mx, my); D.a = b.a; D.v0 = math.abs(b.v); D.last = D.v0 end
        if R.ds ~= SEL_LOOPER then UI.lp("sel_" .. R.ds); SEL_LOOPER = R.ds end
        UI.drag = D
      end
    end
  elseif down and D then                                              -- glisser
    local R = VIS.R[D.i]
    if R and math.abs(mx - D.x0) > 4 then D.moved = true end
    if R and D.moved and D.kind == "aux" then                        -- send aux : glisser a gauche / a droite = niveau (0..100 %)
      local lvl = math.max(0, math.min(1, D.v0 + (mx - D.x0) / 200))
      local now = reaper.time_precise()
      if math.abs(lvl - D.last) >= .01 and now - (D.st or 0) > .03 or (lvl == 0 and D.last > 0) or (lvl == 1 and D.last < 1) then
        D.last, D.st = lvl, now
        UI.lp(string.format("aux_l_%d_%d_%d", D.ds, D.a, math.floor(lvl * 1000 + .5)))
      end
    elseif R and D.moved and D.len > 0 and (D.lx ~= mx) then
      D.lx = mx
      local s = smp_at(R, mx)
      local ds = (mx - D.x0) / R.ww * D.len
      if D.kind == "in" then
        reaper.gmem_write(D.gb + 161, math.min(s, D.ls + D.lw - 1)); reaper.gmem_write(D.gb + 160, 1)
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
    if not D.moved and D.kind == "aux" then UI.lp(string.format("aux_l_%d_%d_tog", D.ds, D.a))   -- clic = ouvrir / fermer
    elseif not D.moved and D.kind ~= "tag" and reaper.time_precise() - D.t0 < .4 then UI.lp("stap_" .. D.ds) end
    UI.drag = nil
  end
  if not down then UI.drag = nil end
  UI.down = down
  -- curseur selon ce qui est sous la souris
  local _, R = UI.row_at(mx, my)
  local want = (UI.drag and CURSOR[UI.drag.kind]) or (R and not ctrl and CURSOR[UI.hit(R, mx, my)]) or 32512
  if want ~= UI.cur then UI.cur = want; if gfx.setcursor then gfx.setcursor(want) end end
end

-- ============================================================================================================
-- IMPORT D'UN FICHIER AUDIO (repris du 8 Looper Panel, qui est abandonne) : glisser un son sur la ligne d'un looper,
-- ou clic droit sur la ligne > « Charger un fichier audio... ». Le fichier est decode par REAPER (tous formats lisibles),
-- reechantillonne a la frequence du looper, depose dans gmem, puis copie par le looper dans sa boucle ; le looper reste
-- a l'ARRET. S'il n'y a pas de maitre il le devient (comme un 1er REC) et le fichier fixe le tempo du projet.
-- Si une synchro est active ET qu'une boucle tourne dans un autre looper, le mode choisi (menu du clic droit) s'applique :
--   1 ADAPTER (longueur arrondie au multiple du maitre) | 2 INDEPENDANT (longueur d'origine, sans synchro)
--   3 ETIRER (reechantillonne a la bonne longueur)
-- Meme protocole gmem que le 8 Panel : LD_BASE, commandes +48 = 32 (requete de longueur) puis 31 (copie).
-- ============================================================================================================
local IMP = { LD_BASE = 1000000, LD_MAXN = 3500000, CHUNK = 16384, msg = "", msg_t = 0, rdown = false, job = nil }
IMP.NAMES = { "ADAPTER", "INDEPENDANT", "ETIRER" }
do
  local m = tonumber(reaper.GetExtState(EXT, "load_mode"))
  if not m or m == 0 then m = tonumber(reaper.GetExtState("NowUndo_8Looper_Panel", "load_mode")) end   -- reprend le choix du 8 Panel
  IMP.mode = math.max(1, math.min(3, math.floor(m or 1)))
end
function IMP.say(m) IMP.msg = m; IMP.msg_t = reaper.time_precise() end
function IMP.alive(i, now_t) return read(100, i) > 0 and (now_t - read(130, i)) <= 3.0 end
function IMP.block(i)                                                -- base gmem de la part ACTIVE de l'instance i
  local b0 = 1000 + i * 600; local ap = math.floor(read(b0, 42) + .5); local pp = (ap >= 1 and ap <= 3) and (ap - 1) or 0
  return b0 + pp * 200
end
function IMP.cleanup(J)
  if J.acc then pcall(reaper.DestroyAudioAccessor, J.acc); J.acc = nil end
  if J.tr then pcall(reaper.DeleteTrack, J.tr); J.tr = nil; J.src = nil
  elseif J.src then pcall(reaper.PCM_Source_Destroy, J.src); J.src = nil end
end
function IMP.start(i, path, now_t)
  if IMP.job then IMP.say("Chargement deja en cours"); return end
  if not IMP.alive(i, now_t) then IMP.say("Looper " .. (i + 1) .. " absent : fichier ignore"); return end
  local src = reaper.PCM_Source_CreateFromFile(path)
  if not src then IMP.say("Fichier illisible"); return end
  local D, isqn = reaper.GetMediaSourceLength(src)
  if isqn or not D or D <= 0.01 then reaper.PCM_Source_Destroy(src); IMP.say("Fichier audio invalide"); return end
  local gb = IMP.block(i)
  local sr = read(gb, 186); if sr <= 0 then sr = reaper.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false); if sr <= 0 then sr = 44100 end end
  local N = math.floor(D * sr + .5)
  local qid = math.floor(reaper.time_precise() * 1000) % 1000000 + 1
  IMP.job = { i = i, gb = gb, src = src, D = D, sr = sr, N = N, qid = qid, phase = "query", t0 = now_t, name = path:match("[^/\\]+$") or path }
  reaper.gmem_write(IMP.LD_BASE + 1, N); reaper.gmem_write(IMP.LD_BASE + 2, qid); reaper.gmem_write(IMP.LD_BASE + 3, 0)
  reaper.gmem_write(gb + 49, 0); reaper.gmem_write(gb + 48, 32)          -- cmd 32 : requete de longueur
end
function IMP.step(now_t)
  local J = IMP.job; if not J then return end
  local LB = IMP.LD_BASE
  if J.phase == "query" then
    if read(LB, 3) == J.qid then
      local has_ref = read(LB, 4) > .5; local Nad = math.floor(read(LB, 5) + .5); local cap = math.floor(read(LB, 7) + .5)
      -- 0 = natif : aucune reference (pas de maitre / Host). La reference suffit : l'horloge du maitre tourne meme a l'arret.
      local mode = has_ref and IMP.mode or 0
      J.had_ref = has_ref
      local Nf, refm, stretch = J.N, 0, false
      if mode == 1 then Nf = Nad; refm = 1 elseif mode == 3 then Nf = Nad; refm = 1; stretch = true end
      if cap > 0 and Nf > cap then Nf = cap; IMP.say("Fichier tronque a la capacite du looper") end
      J.Nf = Nf; J.ref = refm; J.stretch = stretch; J.mode = mode
      J.nread = stretch and Nf or math.min(J.N, Nf)
      J.phase = "read"
    elseif now_t - J.t0 > 2.0 then
      IMP.say("Looper " .. (J.i + 1) .. " ne repond pas (JSFX a jour ?)"); IMP.cleanup(J); IMP.job = nil
    end
  elseif J.phase == "read" then
    -- 1) cree la piste / l'item / l'accessor temporaires (rien d'autre dans cette image)
    local ok = pcall(function()
      reaper.PreventUIRefresh(1)
      local n = reaper.CountTracks(0); reaper.InsertTrackAtIndex(n, false); local tr = reaper.GetTrack(0, n); J.tr = tr
      local item = reaper.AddMediaItemToTrack(tr); local take = reaper.AddTakeToMediaItem(item)
      reaper.SetMediaItemTake_Source(take, J.src)               -- la source appartient desormais a la piste temporaire
      reaper.SetMediaItemInfo_Value(item, "D_POSITION", 0); reaper.SetMediaItemInfo_Value(item, "D_LENGTH", J.D)
      J.acc = reaper.CreateTakeAudioAccessor(take)
      J.t0 = reaper.GetAudioAccessorStartTime(J.acc)
      J.sr_req = J.sr                                            -- lecture toujours a la frequence du projet
      J.buf = reaper.new_array(IMP.CHUNK * 2)
      if J.stretch then J.r = J.N / J.Nf; J.bufs = reaper.new_array((IMP.CHUNK * 4 + 16) * 2) end
    end)
    pcall(reaper.PreventUIRefresh, -1)
    if not ok or not J.acc or not J.buf then IMP.cleanup(J); IMP.say("Lecture du fichier impossible"); IMP.job = nil; return end
    J.k = 0; J.phase = "stream"
  elseif J.phase == "stream" then
    -- 2) lecture PAR PETITS BLOCS (jamais tout le fichier d'un coup) et ecriture dans gmem
    local t_end = reaper.time_precise() + 0.008
    local Lb, Rb = LB + 16, LB + 16 + IMP.LD_MAXN
    local ok = pcall(function()
      while J.k < J.Nf and reaper.time_precise() < t_end do
        local k = J.k; local n = math.min(IMP.CHUNK, J.Nf - k)
        local nr = 0
        if J.stretch then
          -- ETIRER : sortie k..k+n-1 <- entree x = sortie * N/Nf (Hermite 4 points), lue par fenetre a la frequence du projet
          local r = J.r
          n = math.max(1, math.min(n, math.floor((IMP.CHUNK * 4) / math.max(r, 0.0001))))
          local i0 = math.max(0, math.floor(k * r) - 1)
          local cnt = math.floor((k + n - 1) * r) + 3 - i0
          reaper.GetAudioAccessorSamples(J.acc, J.sr, 2, J.t0 + i0 / J.sr, cnt, J.bufs)
          local B = J.bufs
          local function g(i, c) local j = i - i0; if j < 0 or j >= cnt then return 0 end return B[2 * j + c] end
          for f = 0, n - 1 do
            local x = (k + f) * r; local i = math.floor(x); local t = x - i
            for c = 1, 2 do
              local y0, y1, y2, y3 = g(i - 1, c), g(i, c), g(i + 1, c), g(i + 2, c)
              local c1 = 0.5 * (y2 - y0); local c2 = y0 - 2.5 * y1 + 2 * y2 - 0.5 * y3; local c3 = 0.5 * (y3 - y0) + 1.5 * (y1 - y2)
              local v = ((c3 * t + c2) * t + c1) * t + y1
              reaper.gmem_write((c == 1 and Lb or Rb) + k + f, v)
            end
          end
          nr = n
        elseif k < J.nread then
          nr = math.min(n, J.nread - k)
          reaper.GetAudioAccessorSamples(J.acc, J.sr_req, 2, J.t0 + k / J.sr_req, nr, J.buf)
        end
        if not J.stretch then
          local buf = J.buf
          for f = 0, nr - 1 do
            reaper.gmem_write(Lb + k + f, buf[2 * f + 1]); reaper.gmem_write(Rb + k + f, buf[2 * f + 2])
          end
          for f = nr, n - 1 do reaper.gmem_write(Lb + k + f, 0); reaper.gmem_write(Rb + k + f, 0) end
        end
        J.k = k + n
      end
    end)
    if not ok then IMP.cleanup(J); IMP.say("Lecture du fichier interrompue"); IMP.job = nil; return end
    if J.k >= J.Nf then J.buf = nil; J.phase = "free_acc" end
  elseif J.phase == "free_acc" then
    -- 3) l'accessor est detruit seul, dans sa propre image
    if J.acc then pcall(reaper.DestroyAudioAccessor, J.acc); J.acc = nil end
    J.phase = "free_track"
  elseif J.phase == "free_track" then
    -- 4) puis la piste temporaire (elle detruit aussi la source) dans une autre image
    if J.tr then pcall(reaper.DeleteTrack, J.tr); J.tr = nil; J.src = nil end
    reaper.gmem_write(LB + 8, J.Nf); reaper.gmem_write(LB + 9, J.ref); reaper.gmem_write(LB + 10, 0)
    reaper.gmem_write(J.gb + 49, 0); reaper.gmem_write(J.gb + 48, 31)   -- cmd 31 : copie dans la boucle
    J.phase = "wait"; J.t1 = now_t
  elseif J.phase == "wait" then
    if read(LB, 10) == J.qid then
      local how = (J.mode == 1) and " (adapte)" or (J.mode == 3 and " (etire)" or (J.mode == 2 and " (independant)" or ""))
      IMP.say(string.format("Looper %d : %s charge, %.2f s%s", J.i + 1, J.name, J.Nf / J.sr, how))
      -- Premier fichier (aucune reference : il devient le maitre) -> il fixe le tempo du projet REAPER
      if not J.had_ref then J.phase = "tempo"; J.t2 = now_t else IMP.job = nil end
    elseif now_t - J.t1 > 30 then
      IMP.say("Looper " .. (J.i + 1) .. " : chargement non termine"); IMP.job = nil
    end
  elseif J.phase == "tempo" then
    -- tempo musical estime par le looper (nombre de temps le plus plausible pour cette longueur), publie a +155
    local bpm = read(J.gb, 155)
    if bpm > 20 and bpm < 400 then
      reaper.SetCurrentBPM(0, bpm, true)
      IMP.say(string.format("Looper %d : %s charge, tempo du projet = %.2f BPM", J.i + 1, J.name, bpm)); IMP.job = nil
    elseif now_t - J.t2 > 1.5 then IMP.job = nil end
  end
end
-- depot de fichiers + clic droit (menu) + etat affiche ; appele a chaque image apres le dessin des lignes
function IMP.tick(now_t, w, h)
  local mx, my = gfx.mouse_x, gfx.mouse_y
  -- glisser-deposer : gfx.getdropfile(idx) renvoie DEUX valeurs (retval, nom) ; retval vaut 0 quand il n'y a (plus) rien
  local rv0 = gfx.getdropfile(0)
  if rv0 and rv0 ~= 0 then
    local files, k = {}, 0
    while k < 64 do
      local rv, f = gfx.getdropfile(k)
      if not rv or rv == 0 or not f or f == "" then break end
      files[#files + 1] = f; k = k + 1
    end
    gfx.getdropfile(-1)
    local i = UI.row_at(mx, my)
    if i and files[1] then
      IMP.start(i, files[1], now_t)
      if #files > 1 then IMP.say("Un seul fichier a la fois : " .. (#files - 1) .. " ignore(s)") end
    else IMP.say("Deposez le fichier sur la ligne d'un looper actif") end
  end
  -- clic droit sur une ligne : charger un fichier / choisir le mode
  local rd = (gfx.mouse_cap & 2) == 2
  if rd and not IMP.rdown then
    local i, R = UI.row_at(mx, my)
    local b = R and UI.badge(R, mx, my)
    if b then UI.lp(string.format("auxrx_%d_%d_tog", R.ds, b.a))   -- 27 nov. : clic droit sur un send = l'aux revient dans ce looper (on / off)
    elseif R then
      -- pas de separateur ni de ligne grisee : la numerotation de gfx.showmenu reste 1, 2, 3, 4
      local items = { "Charger un fichier audio dans le looper " .. (i + 1) .. "...",
                      "Si une boucle tourne deja : ADAPTER la longueur (multiple du maitre)",
                      "Si une boucle tourne deja : fichier INDEPENDANT (longueur d'origine)",
                      "Si une boucle tourne deja : ETIRER a la bonne longueur" }
      items[1 + IMP.mode] = "!" .. items[1 + IMP.mode]
      gfx.x, gfx.y = mx, my
      local c = gfx.showmenu(table.concat(items, "|"))
      if c == 1 then
        local ok, path = reaper.GetUserFileNameForRead("", "Charger un fichier audio dans le looper " .. (i + 1), "")
        if ok and path and path ~= "" then IMP.start(i, path, reaper.time_precise()) end
      elseif c >= 2 and c <= 4 then
        IMP.mode = c - 1; reaper.SetExtState(EXT, "load_mode", tostring(IMP.mode), true)
        IMP.say("Fichier : " .. IMP.NAMES[IMP.mode])
      end
    end
  end
  IMP.rdown = rd
  IMP.step(now_t)
  -- etat du chargement / message (bandeau en haut, au centre)
  local msg
  local J = IMP.job
  if J then
    local pct = J.phase == "stream" and math.floor(100 * (J.k or 0) / math.max(1, J.Nf or 1)) or 0
    msg = string.format("Chargement looper %d : %s  %s", J.i + 1, J.name, J.phase == "stream" and (pct .. "%") or J.phase)
  elseif now_t - IMP.msg_t < 5 and IMP.msg ~= "" then msg = IMP.msg end
  if msg then
    setfont(13, true)
    local tw = gfx.measurestr(msg)
    local bx, by = (w - tw) * .5 - 10, 4
    rect(bx, by, tw + 20, 24, .05, .05, .07, .92, 1); rect(bx, by, tw + 20, 24, 1, .85, .35, 1, 0)
    text(bx + 10, by + 5, msg, 13, 1, .85, .35, true)
  end
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
  IMP.tick(now_t, w, h)
  gfx.update(); reaper.defer(main)
end

reaper.gmem_attach("nowundo_sync")
win_init(); gfx.clear = 0x0D0D11
if W8_TEST then W8_TEST.VIS = VIS end                                -- tests (tools/t8waves_aux.lua)
reaper.defer(main)
