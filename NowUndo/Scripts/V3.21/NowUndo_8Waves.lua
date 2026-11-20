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
local function setc(r, g, b, a) gfx.set(r, g, b, a or 1) end
local function rect(x, y, w, h, r, g, b, a, fill) setc(r, g, b, a); gfx.rect(x, y, w, h, fill == nil and 1 or fill) end
local FONT_SLOT, FONT_N, CUR_FONT = {}, 9, nil
local function setfont(sz, bold)
  local key = sz * 2 + (bold and 1 or 0); local slot = FONT_SLOT[key]
  if not slot then
    FONT_N = FONT_N + 1; if FONT_N > 120 then FONT_N = 10; FONT_SLOT = {}; CUR_FONT = nil end
    slot = FONT_N; FONT_SLOT[key] = slot; gfx.setfont(slot, "Arial", sz, bold and "b" or ""); CUR_FONT = slot
  elseif CUR_FONT ~= slot then gfx.setfont(slot); CUR_FONT = slot end
end
local function text(x, y, str, size, r, g, b, bold)
  setfont(math.max(7, math.floor(size)), bold); setc(r, g, b, 1); gfx.x = x; gfx.y = y; gfx.drawstr(tostring(str))
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
  local wx, wy, ww, wh = x + 4, y + 3, w - 8, h - 6
  if is_stop then rect(wx, wy, ww, wh, .05 + hc[1] * .10, .05 + hc[2] * .10, .06 + hc[3] * .10, 1, 1) else rect(wx, wy, ww, wh, .025, .027, .035, 1, 1) end
  if tc then rect(x, y, w, h, tc[1], tc[2], tc[3], tk, 1) end      -- voile de la couleur du groupe / de la selection
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
      if x1 - x0 >= 1 then setc(.35, .70, 1, .28); gfx.rect(x0, wy, x1 - x0, wh, 1); setc(.60, .85, 1, 1); gfx.line(x0, wy, x0, wy + wh); gfx.line(x1, wy, x1, wy + wh) end
    end
    if z1 > z0 then
      if z1 - z0 >= wl then band(ls, ls + wl)
      else local a = z0 - ls; a = a - math.floor(a / wl) * wl; local b = a + (z1 - z0)
        if b <= wl then band(ls + a, ls + b) else band(ls + a, ls + wl); band(ls, ls + b - wl) end end
    end
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
    setc(.55, 1, .68, 1); local ox = wx + (endpos / length) * ww; gfx.line(ox, wy, ox, wy + wh)
  end
  local px = wx + math.max(0, math.min(100, read(gb, 47))) * .01 * ww
  setc(.95, .55, .82, 1); gfx.line(px, wy, px, wy + wh); gfx.line(px + 1, wy, px + 1, wy + wh)

  -- nom et etat, discrets, en haut a gauche
  local nm = "L" .. math.floor(alias + .5) .. "  " .. PART_NAME[ap]
  setfont(math.floor(fs), true); local nw = gfx.measurestr(nm)
  local sn = STATE_NAME[state] or "STOP"
  local snw = gfx.measurestr(sn)
  rect(wx + 2, wy + 2, nw + snw + 22, fs + 6, 0, 0, 0, .55, 1)
  text(wx + 6, wy + 4, nm, fs, .94, .94, .96, true)
  if is_stop then text(wx + 14 + nw, wy + 4, sn, fs, .62, .64, .68, true) else text(wx + 14 + nw, wy + 4, sn, fs, st_col[1] + .15, st_col[2] + .15, st_col[3] + .15, true) end

  -- cadre de selection / groupe (meme code que le Launchpad et le panneau)
  local ol, thick = nil, 2
  if gc then
    local lvl = .85
    if is_sel then lvl = (math.floor(now_t * 4) % 2 == 0) and 1.0 or .45; thick = 3 end
    ol = {gc[1] * lvl, gc[2] * lvl, gc[3] * lvl}
  elseif is_sel then ol = {.98, .83, .22}; thick = 3 end
  if ol then for k = 0, thick - 1 do rect(x + k, y + k, w - 2 * k, h - 2 * k, ol[1], ol[2], ol[3], 1, 0) end end
end

local function main()
  local ch = gfx.getchar(); if ch < 0 then return end
  win_save()
  local w, h = gfx.w, gfx.h
  local now_t = reaper.time_precise()
  SEL_LOOPER = math.floor(tonumber(reaper.GetExtState("nowundo_vl", "sel_looper")) or 0)
  rect(0, 0, w, h, .055, .06, .075, 1, 1)
  local m, gap = 6, 4
  local rh = (h - 2 * m - gap * (MAX_INST - 1)) / MAX_INST
  for i = 0, MAX_INST - 1 do draw_row(i, m, m + i * (rh + gap), w - 2 * m, rh, now_t) end
  gfx.update(); reaper.defer(main)
end

reaper.gmem_attach("nowundo_sync")
win_init(); gfx.clear = 0x0D0D11
reaper.defer(main)
