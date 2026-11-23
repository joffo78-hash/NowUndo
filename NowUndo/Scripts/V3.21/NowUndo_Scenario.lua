--[==[
  NowUndo_Scenario.lua  -  sequenceur de scenarios pas a pas pour les 8 loopers NowUndo
  Script REAPER autonome (gfx) : parle directement aux loopers via la gmem "nowundo_sync",
  exactement comme le Virtual Launchpad (aucune modification de ce dernier necessaire).

  SYNTAXE
    un PAS      = une ou plusieurs ACTIONS separees par des virgules, termine (ou non) par ;
    une ACTION  = CIBLE  MOT [valeur]  [MOT [valeur]] ...
    CIBLE       = l1  |  l1/3/6  |  l2-4  |  l(1/3)  |  g2  |  g1/3  |  g(2)  |  all   (/ separe ; g = groupe du Launchpad)
                  (g(2) SEUL dans une action = rappel du preset de groupe 2 ; "g(2) rec" = REC sur le groupe 2)
    MOTS        = rec dub(=rec) play stop clear clearfull replace multiply autorep
                  rev pp slicer cloud link auto oneshot br      -> on / off (sans valeur = ON ; rien ne se passe si deja dans cet etat)
                  undo redo restart rerec fullloop quant reset (tous les params)
                  vol speed pitch                            -> valeur absolue (vol: 0..2, 50%, -6db)
                  in out                                     -> fraction de la boucle (0.25 ou 25%) ou reset
                  smix                                       -> dry/wet du slicer : 0..1 ou % (0 = boucle d'origine, 1 = slicer seul), reset (= 1)
                  brmix                                      -> dry/wet du beat repeat : 0..1 ou % (0 = boucle d'origine, 1 = beat repeat seul), reset (= 1)
                  brf                                        -> fraction du beat repeat : 1/2 1/3 1/4 1/6 1/8 1/12 1/16 1/32 1/64 | free  (ex : l1 brf 1/8, l1 br)
                  part 1|2|3
    On peut grouper des mots avec / :  "l1 in/out reset",  "l1 slicer/cloud off"
    On peut coller on/off au mot :     "l2 recoff"
    Mots de liaison ignores :          "a", "à", "=", ":"       ("l1 in 0.25 out à 0.5")
    Decimales avec un POINT (la virgule separe les actions).
    Cible omise apres une virgule = meme cible que l'action precedente :  "l1 rec off, rev"  =  "l1 recoff, l1 rev"
    R(n) | G(n)       = rappelle le preset de ROUTING (R) ou de GROUPE (G) numero n (1-8) de la page principale du Launchpad
                         (comme un appui sur son pad ; slot vide = rien). Utilisable seul ou avec d'autres actions : "r(2), l1 rec"
    sync | unsync     = synchro Master Sync de la part en cours (comme le pad SYNC/UNSYNC) ; syncall | unsyncall = les 3 parts
    e1..e4 | e(1)..e(4) = effet 1-4 du looper (page Effects du Launchpad), comme slicer :  "l1 e1" active, "l1 e1 off" desactive
    * en fin d'action  = l'action est ARMEE : elle part au prochain point de synchro (grille de sortie du Master Sync)
                         ex : "l1 rev*, l2 recoff"   (l2 part tout de suite, l1 attend le point de synchro)

  EXEMPLE
    l1/3/6 rev, l2 recoff;
    l1/3/6 revoff, l2 rec;
    l1 in 0.25 out 0.5, l4 vol -6db;
    l1 in/out reset, l1 slicer/cloud off;

  RUSHES (ex macros, onglet MACROS) : chutier d'actions, partage avec la page 4 du Launchpad (V3.27 : sous-pages a..z de 64
  pads, boutons + PAGE / NOM PAGE / SUPPR PAGE ; l3 to g2 = groupe ; go lp 2 | go 4c | go t3 = pages LP / rushes / Twister). V3.27 : meme syntaxe que
  les pas, la CIBLE est facultative : sans cible = looper / groupe selectionne ("rec"), sinon l1 | l(1/3) | g2 | g(1/3) | all
  ("g2 rec", "all stop", "rec, l3 play" : l3 seulement pour play). Voir le lexique (?) pour le detail.

  COMMANDES CLAVIER : Espace / Entree / Droite = GO | Gauche / Backspace = BACK
                      Haut / Bas = choisir le pas | E = editer le pas | double-clic sur un pas = l'editer
]==]

local GMEM, EXT, NLOOP = "nowundo_sync", "nowundo_scn", 8
local SEP = "¦"

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

--------------------------------------------------------------------------
-- gmem : lecture du feedback + ecriture des commandes (meme protocole que le Virtual Launchpad)
--------------------------------------------------------------------------
local function rd(a) return reaper.gmem_read(a) or 0 end
local function wr(a, v) reaper.gmem_write(a, v) end
local function base(i, part) return 1000 + (i - 1) * 600 + (part - 1) * 200 end

local function fb(i)
  local part = math.floor(rd(base(i, 1) + 42) + 0.5)
  if part < 1 or part > 3 then part = 1 end
  local b = base(i, part)
  local st = math.floor(rd(b + 2) + 0.5)
  local pm = rd(b + 8)
  return {
    alive = rd(100 + i - 1) > 0, part = part, b = b, st = st,
    rec = (st == 1 or st == 3 or st == 7 or st == 8),
    playing = (st >= 2 and st <= 6),
    rev = rd(b + 17) > 0.5, pp = rd(b + 18) > 0.5, cloud = rd(b + 24) > 0.5,
    slicer = (pm > 0.5 and pm < 1.5), oneshot = pm > 1.5,
    link = rd(b + 9) > 0.5, auto = rd(b + 43) > 0.5,
    br = rd(b + 189) > 0.5, mute = rd(b + 199) > 0.5, raw = rd(b + 159) > 0.5,
    len = rd(b + 46), lstart = rd(b + 44), lwidth = rd(b + 45),
  }
end

--------------------------------------------------------------------------
-- Valeurs
--------------------------------------------------------------------------
local function onoff(v)
  if v == "on" or v == "true" or v == "yes" or v == "1" then return true end
  if v == "off" or v == "false" or v == "no" or v == "0" then return false end
  return nil
end

local function num(v)
  local n, suf = v:match("^([+-]?%d*%.?%d+)(.*)$")
  if not n then return nil end
  n = tonumber(n)
  if suf == "" then return n, "" end
  if suf == "%" then return n / 100, "pct" end
  if suf == "db" then return n, "db" end
  return nil
end

--------------------------------------------------------------------------
-- Mots-cles : chaque handler(v) -> liste d'ops | nil, erreur
-- op = { ch = "cmd"|"param"|"edit", f = function(i) -> base, a, c, d }   (f est PURE : evaluee au moment d'ecrire)
--   cmd   : a = numero de commande, c = argument optionnel   (+48 / +49)
--   param : a = id parametre, c = valeur                      (+180 / +181)
--   edit  : a = edit_cmd, c = in (+161), d = out (+162)       (+160)
--------------------------------------------------------------------------
local H = {}
local tmode = false      -- vrai pendant la compilation d'une macro en mode TOGGLE
local VPID               -- offsets de lecture du feedback (defini avec la capture)

local function tog(cmd, get)
  return function(v)
    if tmode then return { { ch = "cmd", f = function(i) return fb(i).b, cmd end } } end   -- TOGGLE : on inverse l'etat de chaque looper
    local want = true                      -- sans precision = ON
    if v ~= nil then
      want = onoff(v)
      if want == nil then return nil, "on/off attendu" end
    end
    if H._omode then want = not want end   -- GATE, relachement : l'inverse de ce qui est ecrit
    return { { ch = "cmd", f = function(i)
      local F = fb(i)
      if get(F) ~= want then return F.b, cmd end   -- deja dans l'etat voulu : rien ne se passe
    end } }
  end
end

local function cmdonly(cmd)
  return function(v)
    if v then return nil, "pas de valeur attendue" end
    if H._omode then return {} end         -- GATE, relachement : une commande ponctuelle ne se defait pas
    return { { ch = "cmd", f = function(i) return fb(i).b, cmd end } }
  end
end

H.rec      = tog(1,  function(F) return F.rec end)
H.replace  = tog(9,  function(F) return F.st == 4 end)
H.autorep  = tog(10, function(F) return F.st == 5 end)
H.multiply = tog(13, function(F) return F.st == 6 end)
H.rev      = tog(4,  function(F) return F.rev end)
H.pp       = tog(5,  function(F) return F.pp end)
H.slicer   = tog(6,  function(F) return F.slicer end)
H.cloud    = tog(7,  function(F) return F.cloud end)
H.link     = tog(8,  function(F) return F.link end)
H.auto     = tog(19, function(F) return F.auto end)
H.oneshot  = tog(18, function(F) return F.oneshot end)
H.br       = tog(33, function(F) return F.br end)
H.mute     = tog(37, function(F) return F.mute end)   -- V3.25 : mute du looper (sans couper la piste)
do   -- V3.27 : mode d'overdub  a = A (compense, "bande")  |  d = D (brut, transforme comme la boucle) ; "d off" = A
  local function dubm(raw)
    return function(v)
      local want = true
      if v ~= nil then
        want = onoff(v)
        if want == nil then return nil, "on/off attendu" end
      end
      if H._omode then want = not want end   -- GATE, relachement : l'autre mode
      if tmode then return { { ch = "cmd", f = function(i) return fb(i).b, 39 end } } end
      local val = (want == raw) and 1 or 0
      return { { ch = "param", f = function(i)
        local F = fb(i)
        if (F.raw and 1 or 0) ~= val then return F.b, 67, val end   -- deja dans ce mode : rien
      end } }
    end
  end
  H.a = dubm(false); H.d = dubm(true)
end

-- e1..e4 : effets (slots FX 1-4 du looper = page Effects du Launchpad). Comme slicer : "l1 e1" active, "l1 e1 off" desactive.
-- Execute par le Launchpad (commande ExtState), qui garde son affichage a jour. Macro TOGGLE : on inverse.
for slot = 1, 4 do
  H["e" .. slot] = function(v)
    local want = true
    if tmode then want = nil
    elseif v ~= nil then
      want = onoff(v)
      if want == nil then return nil, "on/off attendu" end
    end
    if H._omode and want ~= nil then want = not want end
    return { { glob = "fx", slot = slot, want = want } }
  end
end

H.clear     = cmdonly(2)
H.clearfull = cmdonly(11)
local function cmdall(cmd)                          -- CLEAR ALL : ignore la cible (et la selection d'une macro), vise les 8 loopers
  return function(v)
    if v then return nil, "pas de valeur attendue" end
    if H._omode then return {} end
    return { { ch = "cmd", all = true, f = function(i) return fb(i).b, cmd end } }
  end
end
H.clearall     = cmdall(2)
H.clearallfull = cmdall(11)
H.undo      = cmdonly(14)
H.redo      = cmdonly(15)
H.restart   = cmdonly(16)
H.rerec     = cmdonly(17)
H.fullloop  = cmdonly(22)
H.quant     = cmdonly(23)
H.reset     = cmdonly(24)

local function play_h(default_on)
  return function(v)
    if tmode then return { { ch = "cmd", f = function(i) return fb(i).b, 3 end } } end    -- TOGGLE : play <-> stop
    local want = default_on
    if v ~= nil then
      want = onoff(v)
      if want == nil then return nil, "on/off attendu" end
      if not default_on then want = not want end
    end
    if H._omode then want = not want end
    return { { ch = "cmd", f = function(i)
      local F = fb(i)
      if (want and F.st == 0) or ((not want) and F.playing) then return F.b, 3 end
    end } }
  end
end
H.play = play_h(true)
H.stop = play_h(false)

H.part = function(v)
  local n = v and tonumber(v)
  if not n or n < 1 or n > 3 or n ~= math.floor(n) then return nil, "part 1, 2 ou 3" end
  if H._omode then return {} end
  return { { ch = "cmd", f = function(i) return base(i, n), 12 end } }
end

local function param_h(id, default, lo, hi, conv, key)
  return function(v)
    if not v then return nil, "valeur attendue" end
    local x
    if v == "reset" then x = default
    else
      local n, k = num(v)
      if not n then return nil, "nombre attendu" end
      x = conv(n, k)
    end
    x = math.max(lo, math.min(hi, x))
    if H._omode then                        -- GATE, relachement : retour a la valeur par defaut
      if v == "reset" then return {} end
      return { { ch = "param", f = function(i) return fb(i).b, id, default end } }
    end
    if tmode and v ~= "reset" then          -- TOGGLE : valeur enregistree <-> valeur par defaut (selon l'etat de CHAQUE looper)
      return { { ch = "param", f = function(i)
        local F = fb(i)
        local off = key and VPID and VPID[key]
        local val = x
        if off then
          local cur = rd(F.b + off)
          if key == "speed" and cur <= 0 then cur = 1 end
          if math.abs(cur - x) <= 1e-3 + 0.003 * math.max(math.abs(cur), math.abs(x)) then val = default end
        end
        return F.b, id, val
      end } }
    end
    return { { ch = "param", f = function(i) return fb(i).b, id, x end } }
  end
end
H.vol   = param_h(22, 1, 0, 2,    function(n, k) return k == "db" and 10 ^ (n / 20) or n end, "vol")
H.speed = param_h(3,  1, 0.01, 100, function(n, k) return n end, "speed")
H.pitch = param_h(69, 0, -48, 48,   function(n, k) return n end, "pitch")   -- V3.27 : 69 = pitch ABSOLU (ignore la gamme du Scaler)
-- V3.27 : Scaler (gamme du Pitch / clavier / Pitch Spread) : scale 0..9 ou free demi ton penta maj mharm mmel dim aug oct
H._scnames = { free = 0, demi = 1, ton = 2, penta = 3, maj = 4, mharm = 5, mmel = 6, dim = 7, aug = 8, oct = 9 }
H._scale_p = param_h(70, 0, 0, 9, function(n, k) return math.floor(n + 0.5) end, "scale")
H.scale = function(v) if v and H._scnames[v] then v = tostring(H._scnames[v]) end return H._scale_p(v) end

local function inout_h(which)
  return function(v)
    if not v then return nil, "valeur attendue (0..1, 25% ou reset)" end
    if H._omode then v = "reset" end        -- GATE, relachement : In / Out reviennent en pleine boucle
    if v == "reset" then
      return { { ch = "edit", f = function(i)
        local F = fb(i); if F.len <= 0 then return nil end
        if which == "in" then return F.b, 1, 0, nil end
        return F.b, 2, nil, F.len
      end } }
    end
    local n, k = num(v)
    if not n or k == "db" then return nil, "fraction 0..1 ou % attendue" end
    if n < 0 or n > 1 then return nil, "hors de 0..1 (ecris 0.25 ou 25%)" end
    local tg = tmode
    return { { ch = "edit", f = function(i)
      local F = fb(i); if F.len <= 0 then return nil end
      local cur = (which == "in") and (F.lstart / F.len) or ((F.lstart + F.lwidth) / F.len)
      local val = n
      if tg and math.abs(cur - n) <= 0.004 then val = (which == "in") and 0 or 1 end   -- TOGGLE : valeur <-> defaut
      if which == "in" then return F.b, 1, val * F.len, nil end
      return F.b, 2, nil, val * F.len
    end } }
  end
end
local function idc(n, k) return n end
local function c100(n, k) return k == "pct" and n * 100 or n end
H.fb        = param_h(19, 1,   0,   2,   idc, "fb")
H.cdens     = param_h(26, 0.5, 0,   1,   idc, "cdens")
H.cchaos    = param_h(27, 0,   0,   1,   idc, "cchaos")
H.cspread   = param_h(28, 0.1, 0,   1,   idc, "cspread")
H.cpitch    = param_h(35, 0,   0,   100, c100, "cpitch")
H.cpos      = param_h(38, 50,  0,   100, c100, "cpos")
H.clfo      = param_h(40, 1,   0.1, 4,   idc, "clfo")
H.clfodepth = param_h(41, 0,   0,   100, c100, "clfodepth")
H.clfoshape = param_h(39, 0,   0,   3,   idc, "clfoshape")
H.sattack  = param_h(55, 0,     0,     100,  idc, "sattack")     -- slicer
H.sdecay   = param_h(16, 150,   4,     2000, idc, "sdecay")
H.ssteps   = param_h(47, 8,     1,     32,   idc, "ssteps")
H.srate    = param_h(15, 3,     0,     5,    idc, "srate")
H.smode    = param_h(14, 5,     0,     5,    idc, "smode")
H.sgrid    = param_h(33, 3,     0,     9,    idc, "sgrid")
H.spreset  = param_h(49, 1,     1,     4,    idc, "spreset")
H.smax     = param_h(48, 16,    0,     32,   idc, "smax")
H.sdetect  = param_h(50, 0.002, 0.001, 0.8,  idc, "sdetect")
H.sdhold   = param_h(51, 120,   30,    1000, idc, "sdhold")
H.sroot    = param_h(42, 48,    0,     127,  idc, "sroot")
H.srelease = param_h(44, 0,     0,     3000, idc, "srelease")
H.spitch   = param_h(34, 0,     0,     100,  idc, "spitch")
H["in"]  = inout_h("in")
H["out"] = inout_h("out")
H.smix     = param_h(61, 1, 0, 1, idc, "smix")        -- slicer dry/wet : 0 = boucle d'origine, 1 = slicer
H.brmix    = param_h(60, 1, 0, 1, idc, "brmix")      -- beat repeat dry/wet : 0 = boucle d'origine, 1 = beat repeat

do
-- brf : fraction de quantification du beat repeat (= bouton Quant). Index JSFX : 0=Free 1=1/2 2=1/3 3=1/4 4=1/6 5=1/8 6=1/12 7=1/16 8=1/32 9=1/64
-- Ecrit "1/8", "8" (denominateur seul accepte) ou "free". Si le BR est actif, la fenetre est recalculee tout de suite.
local BRF_IDX = { [2] = 1, [3] = 2, [4] = 3, [6] = 4, [8] = 5, [12] = 6, [16] = 7, [32] = 8, [64] = 9 }
local function brf_parse(v)
  if v == "free" or v == "libre" or v == "reset" or v == "0" then return 0 end
  local den = v:match("^1/(%d+)$") or v:match("^(%d+)$")
  den = den and tonumber(den)
  return den and BRF_IDX[den] or nil
end
H.brf = function(v)
  if not v then return nil, "fraction attendue (1/2 1/3 1/4 1/6 1/8 1/12 1/16 1/32 1/64 ou free)" end
  local idx = brf_parse(v)
  if not idx then return nil, "fraction inconnue : " .. v .. " (1/2 1/3 1/4 1/6 1/8 1/12 1/16 1/32 1/64 ou free)" end
  local tg, om = tmode, H._omode           -- lus a la compilation (la fonction part plus tard, depuis la file)
  return { { ch = "param", f = function(i)
    local F = fb(i)
    local val = idx
    if tg and math.floor(rd(F.b + 25) + 0.5) == idx then val = 0 end   -- TOGGLE : fraction <-> Free
    if om then val = 0 end                                             -- GATE, relachement : Free
    return F.b, 59, val
  end } }
end
end

local ALIAS = { feedback = "fb", reverse = "rev", pingpong = "pp", ping = "pp", pong = "pp", volume = "vol", dub = "rec",
  mult = "multiply", rep = "autorep", full = "fullloop", clr = "clear", oneshot = "oneshot", beatrepeat = "br", beatrep = "br", beatfrac = "brf", brfrac = "brf", vitesse = "speed",
  tempo = "speed", ["1shot"] = "oneshot" }
local VALKEYS = { ["in"] = 1, out = 1, brf = 1, brmix = 1, smix = 1, vol = 1, speed = 1, pitch = 1, fb = 1, cdens = 1, cchaos = 1, cspread = 1,
  cpitch = 1, cpos = 1, clfo = 1, clfodepth = 1, clfoshape = 1,
  sattack = 1, sdecay = 1, ssteps = 1, srate = 1, smode = 1, sgrid = 1, spreset = 1, smax = 1, sdetect = 1, sdhold = 1,
  sroot = 1, srelease = 1, spitch = 1, scale = 1 }

-- "recoff" -> rec + off
local function split_key(piece)
  local k = ALIAS[piece] or piece
  if type(H[k]) == "function" then return k end
  local p0, sfx = piece:match("^(.-)(off)$")
  if not p0 then p0, sfx = piece:match("^(.-)(on)$") end
  if p0 and p0 ~= "" then
    p0 = ALIAS[p0] or p0
    if type(H[p0]) == "function" then return p0, sfx end
  end
end

-- CIBLE : all | l1 | l1/3/6 | l2-4 | l(1/3) | g2 | g1/3 | g(2) | l1/g2 ...  (V3.27 : groupes = gmem 6000+i, lus a l'execution)
-- is_tgt : le mot est-il une cible ?  ("g(2)" SEUL dans une action reste le rappel du preset de groupe, traite avant)
-- V3.27 : entrees in1..in8 (ou i1) : seulement pour les effets (fx 1..4 / e1..e4), codees 100 + n dans la liste des cibles
local function is_tgt(w)
  return w == "all" or w == "tous" or w == "*" or w:match("^l?%d") ~= nil or w:match("^[lg]%(") ~= nil or w:match("^g%d") ~= nil
      or w:match("^in?%d") ~= nil or w:match("^in?%(") ~= nil
end
H._norm = function(text)                  -- e(2) = e2 ; V3.27 : fx 2 / fx(2) = e2
  text = text:gsub("%f[%a]([eE])%s*%(%s*([1-4])%s*%)", "%1%2")
  text = text:gsub("%f[%a][fF][xX]%s*%(%s*([1-4])%s*%)", "e%1")
  text = text:gsub("%f[%a][fF][xX]%s*([1-4])%f[%D]", "e%1")
  return text
end
local function parse_target(s)
  if s == "all" or s == "tous" or s == "*" then
    local t = {}; for i = 1, NLOOP do t[i] = i end; return t
  end
  s = s:gsub("[%(%)]", "")
  local t, pre, grp, seen = {}, "l", false, {}
  for piece in s:gmatch("[^/]+") do
    local p, rest = piece:match("^(in)(%d.*)$")
    if not p then p, rest = piece:match("^([lgi]?)(.*)$") end
    if p == "i" then p = "in" end
    if p ~= "" then pre = p end
    local a, b = rest:match("^(%d+)%-(%d+)$")
    if not a and rest:match("^%d+$") then a, b = rest, rest end
    if not a then return nil, "cible invalide : " .. piece end
    for n = tonumber(a), tonumber(b) do
      if pre == "g" then
        grp = true
        for i = 1, NLOOP do if rd(6000 + i) == n and not seen[i] then seen[i] = true; t[#t + 1] = i end end
      elseif pre == "in" then
        if n < 1 or n > 8 then return nil, "entree " .. n .. " inexistante (in1-in8)" end
        if not seen[100 + n] then seen[100 + n] = true; t[#t + 1] = 100 + n end
      elseif not seen[n] then
        if n < 1 or n > NLOOP then return nil, "looper " .. n .. " inexistant (1-" .. NLOOP .. ")" end
        seen[n] = true; t[#t + 1] = n
      end
    end
  end
  if #t == 0 and not grp then return nil, "cible manquante" end
  for _, i in ipairs(t) do
    if (i < 1 or i > NLOOP) and i <= 100 then return nil, "looper " .. i .. " inexistant (1-" .. NLOOP .. ")" end
  end
  return t
end

local PRESET_MAX = 8      -- presets de routing / de groupe du Launchpad (NPRESET)
-- V3.27 : go lp 1..4 (page du Launchpad) | go 4c / go lp 4c (sous-page c de la page 4 = rushes) | go t1..8 (page du Twister)
-- renvoie le nom de commande pour le Launchpad (NowUndo_VLcmd/q), ou nil, erreur ; nil, nil si ce n'est pas un "go"
H._go = function(a)
  if not a:match("^go%f[%A]") then return nil end
  local r = a:gsub("^go", ""):gsub("%s+", "")
  local tw, tws = r:match("^t(%d+)([a-d]?)$")
  if tw then
    tw = tonumber(tw)
    if tw < 1 or tw > 9 then return nil, "page du Twister 1-9" end
    if tws ~= "" then
      if tw ~= 7 then return nil, "sous-pages a-d : seulement t7 (Custom)" end
      return "twpage_7_" .. (tws:byte() - 96)
    end
    return "twpage_" .. tw
  end
  r = r:gsub("^lp", "")
  local lp, sub = r:match("^(%d)(%a?)$")
  if not lp then return nil, "go lp 1 | go 4c | go t1 attendu" end
  lp = tonumber(lp)
  if sub ~= "" then
    if lp ~= 4 then return nil, "seule la page 4 a des sous-pages (go 4a .. go 4z)" end
    return "p4page_" .. (sub:byte() - 96)
  end
  if lp < 1 or lp > 4 then return nil, "page du Launchpad 1-4" end
  return "lppage_" .. lp
end
-- sync / unsync : synchro Master Sync de la part en cours (comme le pad SYNC/UNSYNC) ; syncall / unsyncall : les 3 parts
local SYNC_WORDS = { sync = { true, false }, unsync = { false, false }, syncall = { true, true }, unsyncall = { false, true } }

-- Compile un pas -> liste d'items {i, ch, f} (ou {glob, n} pour R(n) / G(n)), liste d'erreurs
local function compile(text, forced, toggle, gate_off)
  local items, errs = {}, {}
  local last_targets = nil
  tmode = toggle and true or false
  H._omode = gate_off and true or false     -- macro GATE au relachement : chaque action est defaite
  text = (text:gsub("//.*$", ""))
  text = H._norm(text)                                             -- e(2) = e2, fx 2 = e2
  for act in (text .. ","):gmatch("([^,]*),") do
    act = trim(act)
    local sync = false
    -- V3.27 : * = au prochain debut de cycle du looper ; *1/4, *1/8 = prochain 1/4, 1/8 de cycle ; *2 = au 2e debut de cycle
    local sb, sq = act:match("^(.-)%s*%*%s*([%d%./]*)$")
    if sb and trim(sb) ~= "" then
      sync = H._qparse(sq)
      if not sync then errs[#errs + 1] = "[" .. act .. "] * : *, *1/4, *1/8, *2 ... attendu"; sync = 1 end
      act = trim(sb)
    end
    local pk, pn = act:lower():match("^([rg])%s*%(%s*(%d+)%s*%)$")
    local sc = SYNC_WORDS[(act:lower():gsub("%s+", ""))]
    local gq, gerr = H._go(act:lower())                 -- V3.27 : go lp 2 | go 4c | go t3
    local tgs, tgn = act:lower():match("^(.-)%s*%f[%a]to%s+g%s*%(?%s*(%d+)%s*%)?$")   -- V3.27 : l3 to g2 (g0 = sans groupe)
    if gq or gerr then
      if gerr then errs[#errs + 1] = "[" .. act .. "] " .. gerr
      elseif not H._omode then items[#items + 1] = { glob = "go", qname = gq } end
    elseif tgn then
      tgn = tonumber(tgn)
      local tt, te
      if tgs == "" then tt = last_targets or forced; te = "cible manquante (l3 to g2)"
      else tt, te = parse_target(tgs:gsub("%s+", "")) end
      if tgn > 4 then errs[#errs + 1] = "[" .. act .. "] groupe " .. tgn .. " inexistant (g1-g4, g0 = sans groupe)"
      elseif not tt then errs[#errs + 1] = "[" .. act .. "] " .. te
      else
        if tgs ~= "" then last_targets = tt end
        for _, i in ipairs(tt) do
          local qn
          if H._omode then qn = (tgn > 0) and string.format("grpoff_%d_%d", i, tgn) or nil   -- relachement / OFF : sort du groupe
          else qn = string.format("grp_%d_%d", i, tgn) end
          if qn then items[#items + 1] = { glob = "grp", qname = qn } end
        end
      end
    elseif (sc or pk) and H._omode then
      -- GATE, relachement : pas de rappel de preset ni de synchro
    elseif sc then
      items[#items + 1] = { glob = "sync", on = sc[1], parts_all = sc[2] }
    elseif pk then
      -- R(n) / G(n) : preset de routing / de groupe du Launchpad (global : ni cible, ni file par looper)
      pn = tonumber(pn)
      if pn < 1 or pn > PRESET_MAX then
        errs[#errs + 1] = "[" .. act .. "] preset " .. pn .. " inexistant (1-" .. PRESET_MAX .. ")"
      else
        items[#items + 1] = { glob = (pk == "r") and "routing" or "group", n = pn }
      end
    elseif act ~= "" then
      local s = act:lower():gsub("à", " "):gsub("[=:]", " ")
      s = s:gsub("%f[%a]([lg])%s*%(([%d/%-%s]+)%)", function(p, inner) return p .. "(" .. inner:gsub("%s+", "") .. ")" end)
      local t = {}
      for w in s:gmatch("%S+") do
        -- "a" = mot de liaison, sauf en position de mot (V3.27 : a = dub A) : "l1 a", "a" seul dans un rush
        local word_pos = #t == 0 or (#t == 1 and is_tgt(t[1]))
        if (w ~= "a" or word_pos) and w ~= "to" and w ~= "at" and w ~= "->" then t[#t + 1] = w end
      end
      local first = t[1] or ""
      local targets, terr
      local is_target = is_tgt(first)
      if not is_target and last_targets and split_key(first:match("[^/]+") or "") then
        targets = last_targets                -- pas de cible : on garde celle de l'action precedente
        table.insert(t, 1, "_")
      elseif not is_target and forced then
        targets = forced                      -- rush sans cible : looper / groupe selectionne (impose a l'execution)
        table.insert(t, 1, "_")
      else
        targets, terr = parse_target(first)
        if targets then last_targets = targets end
      end
      if not targets then errs[#errs + 1] = "[" .. act .. "] " .. terr
      elseif #t < 2 then errs[#errs + 1] = "[" .. act .. "] action manquante" .. (is_target and (" (cible seule : ecris \"" .. first .. " rec\" sans virgule)") or "")
      else
        local idx, ok = 2, true
        while idx <= #t and ok do
          local keys, inline = {}, {}
          for piece in t[idx]:gmatch("[^/]+") do
            local k, iv = split_key(piece)
            if not k then errs[#errs + 1] = "[" .. act .. "] mot inconnu : " .. piece; ok = false; break end
            keys[#keys + 1] = k; inline[#keys] = iv
          end
          if not ok then break end
          idx = idx + 1
          local val
          local tn = t[idx]
          if tn then
            local acceptsreset = false
            for _, k in ipairs(keys) do if VALKEYS[k] then acceptsreset = true end end
            local isbrf = false
            for _, k in ipairs(keys) do if k == "brf" then isbrf = true end end
            if onoff(tn) ~= nil or num(tn) or (tn == "reset" and acceptsreset) or (keys[1] == "scale" and H._scnames[tn])
               or (isbrf and (tn:match("^1/%d+$") or tn == "free" or tn == "libre")) then val = tn; idx = idx + 1 end
          end
          for n, k in ipairs(keys) do
            local ops, err = H[k](inline[n] or val)
            if not ops then errs[#errs + 1] = "[" .. act .. "] " .. k .. " : " .. err; ok = false; break end
            for _, i in ipairs(targets) do
              for _, op in ipairs(ops) do
                if i > 100 and k == "mute" then             -- V3.27 : mute d'une ENTREE = sortie du parent (page 2, par le Launchpad)
                  local w = true
                  local vv = inline[n] or val
                  if vv ~= nil then w = onoff(vv) end
                  if H._omode then w = not w end
                  local md = tmode and "tog" or (w and "on" or "off")
                  items[#items + 1] = { i = i, glob = "inmute", qname = string.format("inmute_%d_%s", i - 100, md), key = "mute" }
                  break
                end
                if i > 100 and op.glob ~= "fx" then errs[#errs + 1] = "[" .. act .. "] sur une entree (in" .. (i - 100) .. ") : seulement fx 1..4 et mute"; ok = false; break end
                if not op.all then items[#items + 1] = { i = i, ch = op.ch, f = op.f, sync = sync, glob = op.glob, slot = op.slot, want = op.want, key = k .. (op.slot and ("#" .. op.slot) or "") } end
              end
            end
            for _, op in ipairs(ops) do
              if op.all then for i = 1, NLOOP do items[#items + 1] = { i = i, ch = op.ch, f = op.f, sync = sync, all = true, key = k } end end
            end
          end
        end
      end
    end
  end
  tmode = false
  H._omode = false
  return items, errs
end

--------------------------------------------------------------------------
-- File d'envoi par looper : un looper consomme ses commandes une par une (cmd/param/edit),
-- on n'ecrit donc le suivant qu'une fois le slot vide, avec un petit delai pour que le feedback se mette a jour.
--------------------------------------------------------------------------
local Q, nextok, grp_counter = {}, {}, 0
for i = 1, NLOOP do Q[i] = {} end

local function slot_free(ch, b)
  local a = (ch == "cmd") and (b + 48) or (ch == "param" and (b + 180) or (b + 160))
  return rd(a) == 0
end

-- Point de synchro d'un looper : meme horloge et meme grille que le looper lui-meme
-- (slot Main/Chorus/Bridge = (part-1)*10 ; +2 periode, +3 phase en samples ; grille de sortie = gmem[99])
local function sync_info(i)
  local F = fb(i)
  local so = (F.part - 1) * 10
  local locked, period = rd(so), rd(so + 2)
  if (locked ~= 1 and locked ~= 2) or period <= 0 then return nil end
  local sr = rd(F.b + 186); if sr <= 0 then sr = 48000 end
  local sg = math.max(0, math.min(4, math.floor(rd(99) + 0.5)))
  local unit = period
  if sg > 0 then
    local hb
    if locked == 2 then
      hb = 60 * sr / math.max(reaper.Master_GetTempo(), 20)
    else
      local mid = rd(so + 1)
      for k = 0, NLOOP - 1 do
        local bb = 1000 + k * 600
        if mid > 0 and (rd(bb) == mid or rd(bb + 1) == mid) then
          local pp = rd(bb + 42); if pp < 1 then pp = 1 end
          local bpm = rd(bb + (pp - 1) * 200 + 155)
          if bpm > 0 then hb = 60 * sr / bpm end
          break
        end
      end
    end
    if hb and hb > 0 then
      local nb = period / hb
      if nb >= 1 and math.abs(nb - math.floor(nb + 0.5)) < 0.05 then unit = hb / sg end
    end
  end
  local ph = rd(so + 3) / unit
  return ph - math.floor(ph), unit, sr, locked
end

-- V3.27 : valeur du suffixe de * : "" = 1 cycle, "1/4" = 0.25, "2" = 2 cycles, "0.5" ; nil si illisible
H._qparse = function(q)
  if q == nil or q == "" then return 1 end
  local a, b = q:match("^(%d+)/(%d+)$")
  local v = a and (tonumber(a) / math.max(1, tonumber(b))) or tonumber(q)
  if not v or v <= 0 or v > 64 then return nil end
  return v
end
-- true quand l'action armee (*) peut partir : au prochain point de la grille (fraction ou nombre de cycles) du CYCLE DU
-- LOOPER VISE (sa position dans In / Out, dans le sens ou il joue). Boucle en cours de creation (1er REC) : tout de suite.
-- On part juste AVANT le point (latence du script + bloc audio), comme avant.
local function sync_ready(i, op, q, t, dt)
  if q.released == op.grp then return true end       -- meme appui, meme looper : part avec la 1re
  local F = fb(i)
  if not F.alive or F.len <= 0 or F.st == 1 then return true end   -- pas encore de boucle (ou 1er REC) : immediat
  local lw = (F.lwidth > 0) and F.lwidth or F.len
  local pos = rd(F.b + 47) * 0.01 * F.len
  local ph = (pos - F.lstart) / lw; ph = ph - math.floor(ph)
  if F.rev then ph = 1 - ph end                        -- en reverse le cycle entendu repart de Out
  local qv = (type(op.sync) == "number") and op.sync or 1
  if op.prog == nil then                               -- armement : prochain point de la grille
    op.prog, op.prev, op.chg, op.rate = ph, ph, t, nil
    op.goal = (math.floor(ph / qv + 1e-9) + 1) * qv
    return false
  end
  local d = ph - op.prev; d = d - math.floor(d + 0.5)  -- avance depuis la derniere lecture (bouclage compris)
  if d < 0 then d = 0 end
  if d > 0 then
    op.chg = t
    local r = d / math.max(1e-3, t - (op.tl or t - 0.03))
    op.rate = op.rate and (op.rate * 0.7 + r * 0.3) or r
  end
  op.prog = op.prog + d; op.prev = ph; op.tl = t
  local lead = math.max(0.012, dt * 0.75) * (op.rate or 0)
  local hit = op.prog >= op.goal - lead
  if t - op.chg > 0.6 then hit = true end              -- looper arrete (horloge figee) : pas d'attente
  if hit then q.released = op.grp end
  return hit
end

local last_pump = 0
local function pump()
  local t = reaper.time_precise()
  local dt = math.min(0.1, t - last_pump); last_pump = t
  for i = 1, NLOOP do
    local q = Q[i]
    while #q > 0 and t >= (nextok[i] or 0) do
      local op = q[1]
      if t - op.t0 > (op.sync and 300 or 3) then table.remove(q, 1)   -- bloque trop longtemps : on abandonne
      elseif op.sync and not sync_ready(i, op, q, t, dt) then break   -- arme (*) : attend le point de synchro
      else
        local b, a, c, d = op.f(i)
        if not b then table.remove(q, 1)                      -- rien a faire (deja dans l'etat voulu)
        elseif slot_free(op.ch, b) then
          if op.ch == "cmd" then
            if c ~= nil then wr(b + 49, c) end
            -- V3.27 : REC / Re-Rec d'un rush calé sur l'APPUI du pad (comme le Launchpad : heure gmem 950, cible 951)
            if (a == 1 or a == 17) and not op.sync then wr(950, op.t0); wr(951, b + 48) end
            wr(b + 48, a)
          elseif op.ch == "param" then
            wr(b + 181, c); wr(b + 180, a)
          else
            if c ~= nil then wr(b + 161, c) end
            if d ~= nil then wr(b + 162, d) end
            wr(b + 160, a)
          end
          table.remove(q, 1); nextok[i] = t + 0.04
          break
        else break end
      end
    end
  end
end

local function pending()
  local n = 0
  for i = 1, NLOOP do n = n + #Q[i] end
  return n
end

--------------------------------------------------------------------------
-- Scenario
--------------------------------------------------------------------------
local steps, parsed = {}, {}
local tab = "scn"                      -- onglet courant : "scn" (scenario) ou "mac" (macros)
local mac_from_capture, mac_count = nil, function() return 0 end   -- definis avec le bloc MACROS
local cur, last = 1, 0
local loop_on = false                     -- boucle : apres le dernier pas, GO repart au pas 1
local msg, msg_err = "Pret.", false
local scroll, want_visible = 0, true
local last_name = ""
local DIR = reaper.GetResourcePath() .. "/Data/NowUndo_Scenarios/"

local function reparse(i)
  local id = tonumber((steps[i] or ""):match("^@(%d+)$"))   -- V3.27 : un pas = un rush (reference "@id")
  if id then
    local m = H._mfind and H._mfind(id)
    parsed[i] = { items = {}, errs = {}, err = (not m) and "rush supprime" or m.err, rush = id }
    return
  end
  local items, errs = compile(steps[i])
  parsed[i] = { items = items, errs = errs, err = errs[1] }
end

local function persist()
  reaper.SetExtState(EXT, "steps", table.concat(steps, SEP), true)
  reaper.SetExtState(EXT, "name", last_name, true)
end

local function toggle_loop()
  loop_on = not loop_on
  reaper.SetExtState(EXT, "loop", loop_on and "1" or "0", true)
  msg = loop_on and "Boucle ON : apres le dernier pas, GO repart au pas 1." or "Boucle OFF."; msg_err = false
end

local function reparse_all()
  parsed = {}
  for i = 1, #steps do reparse(i) end
  if cur > #steps then cur = math.max(1, #steps) end
  persist()
end

local function split_steps(text)
  local out = {}
  text = text:gsub("\r", "")
  for line in text:gmatch("[^\n]+") do
    line = trim(line)
    if line ~= "" and not line:match("^#") and not line:match("^//") then
      for st in (line .. ";"):gmatch("([^;]*);") do
        st = trim(st)
        if st ~= "" then out[#out + 1] = st end
      end
    end
  end
  return out
end

-- R(n) / G(n) / e<n> -> commande au Virtual Launchpad (ExtState NowUndo_VLcmd/q : lignes "nom<TAB>temps", lu par VL.ext_cmd_poll)
local function fire_glob(it)
  local name
  if it.glob == "fx" then
    name = string.format(it.i > 100 and "fxin_%d_%d_%s" or "fx_%d_%d_%s", it.i > 100 and it.i - 100 or it.i, it.slot, it.want == nil and "tog" or (it.want and "on" or "off"))
  elseif it.glob == "sync" then
    name = "sync_" .. (it.parts_all and "all_" or "") .. (it.on and "on" or "off")
  elseif it.qname then
    name = it.qname                       -- V3.27 : grp_<l>_<g>, grpoff_<l>_<g>, lppage_<n>, p4page_<k>, twpage_<n>
  else
    name = string.format("preset_%s_%d", it.glob, it.n)
  end
  local q = reaper.GetExtState("NowUndo_VLcmd", "q")
  reaper.SetExtState("NowUndo_VLcmd", "q", q .. string.format("%s\t%.3f\n", name, reaper.time_precise()), false)
end

local function go()
  if #steps == 0 then return end
  reparse(cur)                          -- V3.27 : recompile au GO (cibles de groupe g2 = composition du moment)
  local p = parsed[cur]
  if p.err then msg = "Pas " .. cur .. " invalide : " .. p.err; msg_err = true; return end
  if p.rush then                        -- V3.27 : scenario = liste de rushes : GO lance le rush du pas
    H._run_step(p.rush)
    last = cur
    msg = "Pas " .. last .. " : " .. msg
    if cur < #steps then cur = cur + 1 elseif loop_on then cur = 1 end
    want_visible = true
    return
  end
  reaper.gmem_attach(GMEM)
  local dead, seen, nsync, nglob = {}, {}, 0, 0
  grp_counter = grp_counter + 1
  local t0 = reaper.time_precise()
  for _, it in ipairs(p.items) do
    if it.glob then
      fire_glob(it); nglob = nglob + 1
    elseif rd(100 + it.i - 1) > 0 then
      Q[it.i][#Q[it.i] + 1] = { ch = it.ch, f = it.f, t0 = t0, sync = it.sync, grp = grp_counter }
      if it.sync then nsync = nsync + 1 end
    elseif not it.all and not seen[it.i] then seen[it.i] = true; dead[#dead + 1] = "L" .. it.i end
  end
  last = cur
  msg_err = #dead > 0
  msg = "Pas " .. last .. " execute" .. (#dead > 0 and ("  (looper absent : " .. table.concat(dead, ",") .. ")") or "")
        .. (nsync > 0 and ("  -  " .. nsync .. " action(s) * en attente du point de synchro") or "")
        .. (nglob > 0 and ("  -  " .. nglob .. " commande(s) envoyee(s) au Launchpad") or "")
  if cur < #steps then cur = cur + 1 elseif loop_on then cur = 1 end
  want_visible = true
end

local function back()
  if #steps == 0 then return end
  local base = (last > 0 and last or cur) - 1
  if base < 1 then base = loop_on and #steps or 1 end
  cur = base
  go()
end

local function cancel_all()
  for i = 1, NLOOP do Q[i] = {} end
  msg = "Actions en attente annulees."; msg_err = false
end

-- GetUserInputs traite la valeur par defaut comme du CSV : les virgules coupent le texte et seule la derniere action restait
-- affichee. On remplace donc ", " par " | " dans la fenetre, et on remet les virgules au retour.
local function ui_in(s) return (tostring(s or ""):gsub("%s*,%s*", " | ")) end
local function ui_out(s) return (tostring(s or ""):gsub("%s*|%s*", ", ")) end

local function edit_step()
  if not steps[cur] then return end
  if H._step_edit and steps[cur]:match("^@%d+$") then return H._step_edit() end   -- V3.27 : pas = rush
  local ok, ret = reaper.GetUserInputs("Modifier le pas " .. cur, 1, "Pas :,extrawidth=520", ui_in(steps[cur]))
  if ok then
    local new = split_steps(ui_out(ret))
    if #new > 0 then
      steps[cur] = new[1]
      for k = 2, #new do table.insert(steps, cur + k - 1, new[k]) end
      reparse_all()
    end
  end
end

local function add_step()
  local ok, ret = reaper.GetUserInputs("Ajouter un pas apres le " .. cur, 1, "Pas (; pour en mettre plusieurs) :,extrawidth=520", "")
  if ok then
    local new = split_steps(ret)
    local at = (#steps == 0) and 0 or cur
    for k, s in ipairs(new) do table.insert(steps, at + k, s) end
    if #new > 0 then cur = at + 1; reparse_all(); want_visible = true end
  end
end

local function del_step()
  if #steps == 0 then return end
  table.remove(steps, cur); reparse_all()
end

local function move_step(d)
  local j = cur + d
  if j < 1 or j > #steps then return end
  steps[cur], steps[j] = steps[j], steps[cur]
  cur = j; reparse_all(); want_visible = true
end

local function new_scn()
  steps = {}; cur = 1; last = 0; last_name = ""; reparse_all()
  msg = "Nouveau scenario."; msg_err = false
end

local function save_scn()
  local def = last_name
  if def == "" and steps[1] then                       -- titre propose : le contenu des premiers pas
    def = trim(((steps[1] or "") .. (steps[2] and (" ; " .. steps[2]) or "")):gsub("[\\/:*?\"<>|]", ""):gsub("%s*,%s*", " - "):gsub("%s+", " "))
    def = def:gsub("%.", "_")                            -- "0.25" ne doit pas passer pour une extension
    if #def > 48 then def = def:sub(1, 48) end
  end
  local ok, name = reaper.GetUserInputs("Sauver le scenario", 1, "Nom du fichier :,extrawidth=200", (def:gsub(",", " ")))
  if not ok or trim(name) == "" then return end
  name = trim(name):gsub("[\\/:*?\"<>|]", "_")
  if not name:match("%.%w+$") then name = name .. ".txt" end
  reaper.RecursiveCreateDirectory(DIR, 0)
  local f = io.open(DIR .. name, "w")
  if not f then msg = "Ecriture impossible : " .. DIR .. name; msg_err = true; return end
  f:write("# NowUndo scenario (V3.27 : un pas = un rush ; # = nom du rush)\n")
  for _, s in ipairs(steps) do                          -- le fichier garde le TEXTE des rushes : il se relit partout
    local m = H._mfind(tonumber(s:match("^@(%d+)$") or "") or -1)
    if m then f:write("# ", (m.name ~= "" and m.name or m.text), "\n", m.text, ";\n")
    elseif not s:match("^@") then f:write(s, ";\n") end
  end
  f:close()
  last_name = name; persist()
  msg = "Sauve : " .. name; msg_err = false
end

local function load_scn()
  reaper.RecursiveCreateDirectory(DIR, 0)
  local ok, file = reaper.GetUserFileNameForRead(DIR .. last_name, "Charger un scenario", ".txt")
  if not ok then return end
  local f = io.open(file, "r")
  if not f then msg = "Lecture impossible"; msg_err = true; return end
  local text = f:read("*a"); f:close()
  steps = split_steps(text); cur = 1; last = 0
  last_name = file:match("([^/\\]+)$") or ""
  if H._scn_conv then H._scn_conv() else reparse_all() end   -- V3.27 : chaque pas devient (ou retrouve) un rush
  msg = "Charge : " .. last_name .. "  (" .. #steps .. " pas)"; msg_err = false
end

--------------------------------------------------------------------------
-- Init : restaure le dernier scenario (ExtState) ou propose l'exemple
--------------------------------------------------------------------------
do
  local saved = reaper.GetExtState(EXT, "steps")
  if saved ~= "" then
    for s in (saved .. SEP):gmatch("(.-)" .. SEP) do if s ~= "" then steps[#steps + 1] = s end end
  end
  last_name = reaper.GetExtState(EXT, "name")
  loop_on = reaper.GetExtState(EXT, "loop") == "1"
  -- V3.27 : plus de scenario d'exemple (un scenario = des rushes) ; l'ancien exemple encore enregistre est vide
  if table.concat(steps, "|") == "l1/3/6 rev, l2 recoff|l1/3/6 revoff, l2 rec|l1 in 0.25 out 0.5|l1 in/out reset, l1 slicer/cloud off" then
    steps = {}
  end
  reparse_all()
end

--------------------------------------------------------------------------
-- Interface
--------------------------------------------------------------------------
local function ld(k, d) return tonumber(reaper.GetExtState(EXT, k)) or d end
-- Instance unique : le script continue fenetre fermee (rushes, scenarios) ; le relancer rouvre juste la fenetre
do
  local al = tonumber(reaper.GetExtState("NowUndo_Scn", "alive")) or 0
  if reaper.time_precise() - al < 1 then
    reaper.SetExtState("NowUndo_Scn", "ui_req", "1", false)
    return
  end
end
-- V3.27 : scenario + rushes cote a cote : 1000 px de large au minimum a l'ouverture (la fenetre reste redimensionnable)
H._open = function() gfx.init("NowUndo Scenario", math.max(1000, ld("w", 1100)), math.max(560, ld("h", 640)), ld("dock", 0), ld("x", 120), ld("y", 120)); H._bg = false end
H._open()

local was_down, last_click_t, last_click_row = false, 0, 0
local RH, LIST_Y = 24, 78

local function fit(s, w)
  if gfx.measurestr(s) <= w then return s end
  while #s > 1 and gfx.measurestr(s .. "…") > w do
    s = s:sub(1, (utf8.offset(s, -1) or #s) - 1)
  end
  return s .. "…"
end

local mx, my, click = 0, 0, false
local function btn(x, y, w, h, label, r, g, b)
  local hov = mx >= x and mx <= x + w and my >= y and my <= y + h
  local k = hov and 1.25 or 1
  gfx.set(math.min(1, r * k), math.min(1, g * k), math.min(1, b * k), 1)
  gfx.rect(x, y, w, h)
  gfx.set(1, 1, 1, 0.2); gfx.rect(x, y, w, h, 0)
  gfx.set(1, 1, 1, 0.95)
  local tw, th = gfx.measurestr(label)
  gfx.x = x + (w - tw) / 2; gfx.y = y + (h - th) / 2
  gfx.drawstr(label)
  return click and hov
end

local function save_win()
  local d, x, y, w, h = gfx.dock(-1)
  reaper.SetExtState(EXT, "dock", tostring(d), true)
  reaper.SetExtState(EXT, "x", tostring(math.floor(x)), true)
  reaper.SetExtState(EXT, "y", tostring(math.floor(y)), true)
  reaper.SetExtState(EXT, "w", tostring(math.floor(w)), true)
  reaper.SetExtState(EXT, "h", tostring(math.floor(h)), true)
end

-- Lexique (popup) : { mot, description } ; description absente = titre de section ; mot vide = ligne vide
local HELP = {
  { "SYNTAXE" },
  { ";", "fin d'un pas (un pas = une ligne dans le fichier)" },
  { ",", "separe les actions d'un meme pas :  l1 rev, l2 rec" },
  { ", mot", "cible omise = celle de l'action precedente :  l1 rec off, rev   (= l1 recoff, l1 rev)" },
  { "/", "plusieurs loopers (l1/3/6) ou plusieurs mots (l1 slicer/cloud off, l1 in/out reset)" },
  { "-", "plage de loopers (l2-4) ; signe moins d'une valeur (vol -6db, pitch -5)" },
  { "*", "en fin d'action : part au prochain debut de cycle du looper  (l1 rev*) ; *1/4, *1/8 = prochain 1/4, 1/8 de cycle ; *2 = au 2e debut de cycle ; 1er REC : immediat" },
  { "off", "precise l'arret (rev off, recoff). Sans precision = ON ; deja dans l'etat = rien" },
  { "a  à  =  :", "mots de liaison ignores  (l1 in 0.25 out à 0.5) ; a juste apres la cible (ou seul dans un rush) = dub A" },
  { ".", "separateur decimal (0.25) : la virgule separe les actions" },
  { "//", "commentaire jusqu'a la fin de la ligne" },
  { "R(n)  G(n)", "rappelle le preset de ROUTING (R) / de GROUPE (G) n°1-8 de la page principale du Launchpad  (r(2), g(3))" },
  { "in1 fx 2", "effet 2 de l'entree 1 (in1-in8, ou i1) ; l1 fx 2 = l1 e2 = effet 2 du looper 1. Sur une entree : fx et mute" },
  { "in1 mute", "sort l'entree 1 du parent (comme l'appui long en page 2 : plus d'ecoute directe, les loopers la recoivent toujours) ; in1 mute off = la remet" },
  { "l3 to g2", "met L3 dans le groupe 2 (il quitte son ancien groupe) ; to g0 = sans groupe. En toggle / gate : OFF = sort du groupe" },
  { "go lp 2  go 4c  go t3", "appelle la page 2 du Launchpad | la page de rushes c (page 4) | la page 3 du Twister" },
  { "double-clic", "sur un pas de la liste : l'editer   (GO / Espace : l'executer)" },
  { "" },
  { "CIBLES" },
  { "l1", "un looper" },
  { "l1/3/6", "plusieurs loopers" },
  { "l2-4", "une plage (2, 3 et 4)" },
  { "all", "les 8 loopers   (all rec, all stop)" },
  { "l(1/3)", "meme chose avec parentheses" },
  { "g2  g1/3  g(2)", "les loopers du groupe 2 (des groupes 1 et 3) du Launchpad, au moment de l'action" },
  { "(rien)", "dans un rush : le looper / groupe selectionne  (rec)  ;  apres une virgule : la cible precedente" },
  { "" },
  { "ON / OFF" },
  { "rec  (dub)", "enregistrement / overdub  (rec on sur boucle existante = dub)" },
  { "play  stop", "lecture / arret   (stop = play off)" },
  { "replace", "mode replace" },
  { "multiply", "mode multiply" },
  { "autorep", "auto-repeat" },
  { "rev", "reverse" },
  { "pp", "ping-pong" },
  { "slicer", "mode slicer" },
  { "sync  unsync", "synchro Master Sync de la part en cours, comme le pad SYNC/UNSYNC  (syncall / unsyncall : les 3 parts)" },
  { "e1 .. e4", "effet 1-4 du looper (page Effects du Launchpad) : l1 e1 = actif, l1 e1 off = bypass   (e(1) accepte)" },
  { "cloud", "mode cloud" },
  { "link", "link pitch/speed" },
  { "auto", "auto-rec" },
  { "oneshot", "mode one-shot" },
  { "a  d", "mode d'overdub : a = A (compense, la couche reste telle que jouee) | d = D (brut, transformee comme la boucle)" },
  { "" },
  { "COMMANDES" },
  { "clear", "efface la part active" },
  { "clearfull", "efface les 3 parts" },
  { "clearall / clearallfull", "clear (ou clear complet) sur LES 8 LOOPERS, quelle que soit la cible ou la selection (rush compris)" },
  { "undo  redo", "annuler / refaire" },
  { "restart", "relance la lecture au debut" },
  { "rerec", "efface la part et relance un REC" },
  { "fullloop", "remet la boucle entiere (In/Out)" },
  { "br", "beat repeat : In a la tete de lecture, Out a la fraction quantize suivante (Free = prochaine transitoire). br off desactive" },
  { "brf", "fraction du beat repeat : 1/2  1/3  1/4  1/6  1/8  1/12  1/16  1/32  1/64  |  free  (ex : l1 brf 1/16, l1 br). Agit aussi sur le bouton Quant" },
  { "smix", "dry/wet du slicer : 0..1  |  50%  |  reset (= 1). 0 = boucle d'origine seule, 1 = slicer seul (ex : l1 slicer, l1 smix 50%)" },
  { "brmix", "dry/wet du beat repeat : 0..1  |  50%  |  reset (= 1). 0 = boucle d'origine seule, 1 = beat repeat seul (ex : l1 br, l1 brmix 50%)" },
  { "quant", "quantise In/Out" },
  { "reset", "tous les parametres a leur defaut (sauf volume)" },
  { "" },
  { "VALEURS" },
  { "vol", "0..2  |  50%  |  -6db  |  reset (= 1)" },
  { "speed", "0.01..100  |  reset (= 1)" },
  { "pitch", "-48..48 demi-tons  |  reset (= 0)" },
  { "in  out", "fraction de la boucle : 0.25  |  25%  |  reset" },
  { "part", "1, 2 ou 3 (bascule quantifiee : a mettre seul dans un pas)" },
  { "fb", "feedback 0..2  |  reset (= 1)" },
  { "cdens cchaos cspread", "cloud : densite, chaos, spread (0..1)" },
  { "cpitch cpos", "cloud : pitch spread, position (0..100)" },
  { "clfo clfodepth clfoshape", "cloud LFO : rate (0.1..4), depth (0..100), shape (0..3 : sine, saw, inv saw, random)" },
  { "sattack sdecay ssteps", "slicer : attack (0..100), decay (4..2000), steps (1..32)" },
  { "srate smode sgrid spreset", "slicer : rate (0..5), mode (0 1 5), grid (0..9), preset (1..4)" },
  { "smax sdetect sdhold", "slicer : max slices (0..32), detect, detect hold" },
  { "sroot srelease spitch", "slicer : root (0..127), release (0..3000), pitch (0..100)" },
  { "scale", "gamme du Pitch : free demi ton penta maj mharm mmel dim aug oct (ou 0..9) ; pitch d'un rush = valeur exacte" },
  { "" },
  { "TIMELINE REAPER  (touche T)" },
  { "principe", "un item nomme S<n> sur la piste choisie lance le pas n quand la lecture l'atteint" },
  { "nom de l'item", "note de l'item vide (ou nom du take) : S1, S18, s3 intro ..." },
  { "piste", "bouton PISTE : 1, 2 ... ou TOUTES" },
  { "inhiber", "bouton TIMELINE ON/OFF (ou T) ; inactive pendant la capture" },
  { "saut / boucle", "un saut ne declenche que l'item pile sur le nouveau point de depart" },
  { "glisser un pas", "prends un pas dans la liste, relache-le sur la piste dans REAPER : cree l'item S<n> (SWS requis)" },
  { "→ ITEM  (touche I)", "pose le pas selectionne au curseur de lecture (si ca joue) ou d'edition" },
  { "compteur", "le message affiche S<n> lance (xN) : N = nombre de fois depuis le debut de la lecture" },
  { "" },
  { "BOUCLE  (touche L)" },
  { "boucle ON", "apres le dernier pas, GO repart au pas 1 (BACK depuis le pas 1 va au dernier)" },
  { "pads (hors capture)", "PAS PRECEDENT = BACK ; PAS SUIVANT = GO" },
  { "" },
  { "CAPTURE  (C ou appui long Launch)" },
  { "principe", "tu joues (Launchpad, Twister, souris) : le scenario ecrit le pas" },
  { "VALIDER", "bouton ou Entree : toutes tes interventions depuis le dernier pas" },
  { "potards", "derniere valeur de chaque potard (in/out, pitch, speed, vol, fb, cloud, slicer)" },
  { "pads", "allume = on  (rev) ; eteint = off  (rev off)" },
  { "pas +/-", "cumules : pitch +5 puis +7  ->  pitch 12" },
  { "in / out", "enregistres en fractions : marche meme looper vide" },
  { "Launch + GO", "si tu armes une suite d'actions, le GO valide le pas tout seul" },
  { "appui long Launch", "demarre / arrete la capture" },
  { "pads MAIN/CHORUS/BRIDGE", "VALIDER / PAS PRECEDENT / PAS SUIVANT (en capture : choisit ou inserer, sans executer)" },
  { "Retour arriere", "annule la ligne en cours" },
  { "SYNC *", "ajoute * a chaque action des pas enregistres" },
  { "SNAP", "arrondit les valeurs (pitch entier, in/out au centieme ...)" },
  { "" },
  { "REORDONNER LES PAS" },
  { "glisser dans la liste", "prends un pas et relache-le sur un autre pas : il prend sa place (hors fenetre = timeline REAPER)" },
  { "" },
  { "RUSHES  (onglet RUSHES)" },
  { "principe", "chutier de 64 actions individuelles, meme syntaxe que les pas MAIS sans looper : elles agissent sur le looper / groupe selectionne" },
  { "exemple", "rev, pitch 12, slicer off   (pas de l1 : la cible est le looper ou groupe choisi au moment de l'appui)" },
  { "● CAPTURE / VALIDER", "meme bouton (ou touche C / Entree) : 1er appui = capture, 2e = enregistre UN rush (pas d'incrementation)" },
  { "ADD / EDIT / NOM", "ecrire la syntaxe, la modifier (double-clic aussi), renommer" },
  { "T  (case toggle)", "entre la pastille et le titre (ou touche T) : on/off (rec, rev, slicer, cloud, play, br...) s'INVERSENT ; vol, speed, pitch, in/out... basculent valeur enregistree <-> defaut" },
  { "G  (case gate)", "entre T et A (ou touche G) : APPUI sur le pad = le rush tel qu'ecrit (tout ON), RELACHEMENT = tout OFF (on/off coupes, valeurs par defaut, In/Out en plein ; undo/clear... ne se defont pas). Ideal pour beat repeat" },
  { "Ctrl+C / X / V / D", "copier / couper / coller (juste apres la selection) / dupliquer les rushes selectionnes ; clic droit sur une ligne = menu" },
  { "libelle du pad", "le nom ; s'il est vide, l'action elle-meme (NOM vide = retour a l'action)" },
  { "Ctrl+clic sur un pad LP", "page 4 du Launchpad : retire le rush de ce pad (il reste dans le chutier)" },
  { "pastille / COULEUR", "clic sur la pastille = couleur suivante ; COULEUR = choisir librement (toute la selection)" },
  { "DEL  (Suppr)", "supprime la selection (retire aussi les pads du Launchpad)" },
  { "selection", "clic ; Ctrl/Cmd+clic = ajouter / retirer ; Maj+clic = plage ; Ctrl+A = tout" },
  { "glisser", "hors de la fenetre sur le Launchpad = pose a la suite (cases libres, rien n'est ecrase) ; sur un autre rush = reordonner" },
  { "clic droit (Launchpad)", "sur une case vide de la page 4 : cree un rush pose sur cette case ; sur un rush : l'edite" },
  { "LISTE 1/2  < >", "pages de la liste des rushes (64 par page) ; un rush selectionne / cree ouvre sa page" },
  { "RETIRER DU LP / VIDER", "retire la selection / tout du Launchpad (les rushes restent dans le chutier)" },
  { "▶ TESTER  (Espace)", "execute la selection sur le looper / groupe choisi sur le Launchpad" },
  { "EXPORT / IMPORT", "fichier .txt dans Data/NowUndo_Macros : rushes + disposition Launchpad" },
  { "Launchpad page 4", "page 4 -> couche 'Rushes' (remplace Tune) : un pad = un rush ; ce script doit tourner" },
  { "" },
  { "EXEMPLES" },
  { "l1/3/6 rev, l2 recoff;", "reverse sur 1, 3, 6 ; stop du rec sur 2" },
  { "l1 in 0.25 out 0.5;", "In a 25 %, Out a 50 % de la boucle" },
  { "l1 in/out reset, l1 slicer/cloud off;", "remet In/Out ; coupe slicer et cloud" },
  { "l2 rec*, l1 vol -6db;", "l1 change tout de suite, l2 entre en rec au point de synchro" },
}
local show_help, help_scroll = false, 0


--------------------------------------------------------------------------
-- MODE CAPTURE : le Launchpad et le Twister agissent NORMALEMENT ; tant que ce script publie son heartbeat
-- (ExtState NowUndo_Scn/hb) ils lui envoient en plus ce qu'ils font (ExtState NowUndo_Scn/q) :
--   op<TAB>action<TAB>looper<TAB>valeur   (Launchpad : operation reellement executee, par looper ; toggle = on/off voulu)
--   val<TAB>mot<TAB>looper<TAB>valeur     (Twister : valeur native du potard)      rst<TAB>mot<TAB>looper (push)
--   go  /  done                           (Launchpad : GO du mode Launch / file d'execution videe)
-- VALIDER (bouton / Entree) ecrit toutes les interventions depuis le dernier pas (derniere valeur pour les potards) ; un GO du
-- mode Launch valide aussi automatiquement. Appui long sur le pad Launch : demarre / arrete la capture.
--------------------------------------------------------------------------
local CAPEXT = "NowUndo_Scn"
local capturing = false
local cap = { ops = {}, touched = {}, tlist = {}, virt = {}, snap = true, star = false, go_t = nil, done = false, last_ev = 0, nop = 0, nval = 0, lastev = "(rien recu)" }

local ACT_TOGGLE = { rec_overdub = "rec", replace = "replace", multiply = "multiply", auto = "auto", stop_play = "play",
  reverse = "rev", auto_rev = "pp", one_shot = "oneshot", cloud = "cloud", slicer = "slicer", link = "link", auto_rep = "autorep" }
for s = 1, 4 do ACT_TOGGLE["fx" .. s] = "e" .. s end   -- effets du looper (page Effects du Launchpad)
local ACT_TRIG = { clear = "clear", clear_part = "clear", clear_full = "clearfull", clear_all = "clearall", clear_all_full = "clearallfull",
  rerec = "rerec", undo = "undo", redo = "redo", restart = "restart", quantise_inout = "quant", full_loop = "fullloop",
  reset = "reset", reset_params = "reset" }
local ACT_RESET = { reset_volume = "vol", reset_pitch = "pitch", reset_speed = "speed", reset_loop_in = "in", reset_loop_out = "out" }
local STEP = {
  pitch_step    = function(V, a) return "pitch", V.pitch + a end,
  speed_step    = function(V, a) return "speed", V.speed * 2 ^ (a / 12) end,
  volume_step   = function(V, a) return "vol", V.vol * 10 ^ (a / 20) end,
  volume_pct    = function(V, a) return "vol", V.vol + a / 100 end,
  loop_in_step  = function(V, a) return "in", V["in"] + a / 100 end,
  loop_out_step = function(V, a) return "out", V.out + a / 100 end,
}
local RANGE = { pitch = { -48, 48 }, speed = { 0.01, 100 }, vol = { 0, 2 }, fb = { 0, 2 }, ["in"] = { 0, 1 }, out = { 0, 1 },
  cdens = { 0, 1 }, cchaos = { 0, 1 }, cspread = { 0, 1 }, cpitch = { 0, 100 }, cpos = { 0, 100 },
  clfo = { 0.1, 4 }, clfodepth = { 0, 100 }, clfoshape = { 0, 3 },
  sattack = { 0, 100 }, sdecay = { 4, 2000 }, ssteps = { 1, 32 }, srate = { 0, 5 }, smode = { 0, 5 }, sgrid = { 0, 9 },
  spreset = { 1, 4 }, smax = { 0, 32 }, sdetect = { 0.001, 0.8 }, sdhold = { 30, 1000 }, sroot = { 0, 127 },
  srelease = { 0, 3000 }, spitch = { 0, 100 }, scale = { 0, 9 } }
local SNAP = { pitch = 1, speed = 0.01, vol = 0.05, fb = 0.05, ["in"] = 0.01, out = 0.01, cdens = 0.01, cchaos = 0.01,
  cspread = 0.01, cpitch = 1, cpos = 1, clfo = 0.05, clfodepth = 1, clfoshape = 1,
  sattack = 1, sdecay = 1, ssteps = 1, srate = 1, smode = 1, sgrid = 1, spreset = 1, smax = 1, sdetect = 0.001, sdhold = 10,
  sroot = 1, srelease = 5, spitch = 1 }
local RESETV = { pitch = 0, speed = 1, vol = 1, fb = 1, ["in"] = 0, out = 1, cdens = 0.5, cchaos = 0, cspread = 0.1,
  cpitch = 0, cpos = 50, clfo = 1, clfodepth = 0, clfoshape = 0,
  sattack = 0, sdecay = 150, ssteps = 8, srate = 3, smode = 5, sgrid = 3, spreset = 1, smax = 16, sdetect = 0.002, sdhold = 120,
  sroot = 48, srelease = 0, spitch = 0 }
-- offsets de lecture du feedback (comme le Twister : pitch 4, speed 3, vol 22, fb 19, slicer 14..174)
VPID = { pitch = 4, speed = 3, vol = 22, fb = 19, cdens = 26, cchaos = 27, cspread = 28, cpitch = 35, cpos = 38,
  clfo = 40, clfodepth = 41, clfoshape = 39,
  sattack = 174, sdecay = 16, ssteps = 167, srate = 15, smode = 14, sgrid = 33, spreset = 169, smax = 168, sdetect = 165,
  sdhold = 166, sroot = 150, srelease = 170, spitch = 34 }
-- ce qu'on relit sur les loopers au moment de valider (souris, groupes...) ; cloud exclu (offsets non confirmes)
local SAFE = { "pitch", "speed", "vol", "fb", "sattack", "sdecay", "ssteps", "srate", "smode", "sgrid", "spreset", "smax",
  "sdetect", "sdhold", "sroot", "srelease", "spitch" }
local SAFE_ALL = {}
for _, k in ipairs(SAFE) do SAFE_ALL[#SAFE_ALL + 1] = k end
SAFE_ALL[#SAFE_ALL + 1] = "in"; SAFE_ALL[#SAFE_ALL + 1] = "out"

local function sorted(set) local t = {}; for i in pairs(set) do t[#t + 1] = i end; table.sort(t); return t end
local function tgt_text(t) if #t >= NLOOP then return "all" end; return "l" .. table.concat(t, "/") end
local function num_str(v)
  local s = string.format("%.4f", v)
  s = s:gsub("0+$", ""):gsub("%.$", "")
  if s == "-0" or s == "" then s = "0" end
  return s
end
local function snapv(key, v)
  local lo, hi = RANGE[key][1], RANGE[key][2]
  v = math.max(lo, math.min(hi, v))
  if cap.snap and SNAP[key] then
    v = math.floor(v / SNAP[key] + 0.5) * SNAP[key]
    v = math.max(lo, math.min(hi, v))
  end
  return v
end

-- etat memorise de chaque looper (valeurs numeriques) : photo du Launchpad / Twister au debut, puis mis a jour par chaque ligne
local function snapshot()
  local V = {}
  for l = 1, NLOOP do
    local F = fb(l)
    V[l] = {}
    for k, v in pairs(RESETV) do V[l][k] = v end        -- valeurs par defaut = looper vide / absent
    if F.alive then
      for key, pid in pairs(VPID) do
        local x = rd(F.b + pid)
        if key ~= "speed" or x > 0 then V[l][key] = x end
      end
      if F.len > 0 then V[l]["in"] = F.lstart / F.len; V[l].out = (F.lstart + F.lwidth) / F.len end
    end
  end
  return V
end
local function copyV(V)
  local C = {}
  for l, t in pairs(V) do C[l] = {}; for k, v in pairs(t) do C[l][k] = v end end
  return C
end

-- construit le texte de la ligne en cours ; V = etat virtuel (modifie : passer une copie pour un simple apercu)
local function build(V)
  local items, idx, unknown = {}, {}, {}
  local function put(l, key, val, merge)
    local id = l .. "|" .. key
    if merge and idx[id] then idx[id].val = val; return end
    local it = { l = l, key = key, val = val }
    items[#items + 1] = it
    if merge then idx[id] = it end
  end
  for _, o in ipairs(cap.ops) do
    local a, l, v = o.a, o.l, o.v
    local av = tonumber(v)
    if V[l] then
      if ACT_TOGGLE[a] then
        local on = (v == "true")                       -- allume = on (sans suffixe) ; eteint = off
        put(l, ACT_TOGGLE[a], (not on) and "off" or nil, true)
      elseif ACT_TRIG[a] then
        local c = ACT_TRIG[a]
        put(l, c, nil, false)
        if c == "clear" or c == "clearfull" or c == "reset" or c == "clearall" or c == "clearallfull" then
          local ls = (c == "clearall" or c == "clearallfull") and {} or { l }
          if #ls == 0 then for k = 1, NLOOP do ls[k] = k end end
          for _, k in ipairs(ls) do
            if V[k] then
              V[k].pitch, V[k].speed, V[k]["in"], V[k].out = 0, 1, 0, 1
              if c ~= "reset" then V[k].vol = 1 end
            end
          end
        end
      elseif ACT_RESET[a] then
        local key = ACT_RESET[a]
        put(l, key, "reset", true); V[l][key] = RESETV[key]
      elseif a == "part" and av then put(l, "part", tostring(math.floor(av)), true)
      elseif av and STEP[a] then
        local key, nv = STEP[a](V[l], av)
        nv = snapv(key, nv)
        V[l][key] = nv
        put(l, key, num_str(nv), true)
      else unknown[a] = true end
    end
  end
  for _, tk in ipairs(cap.tlist) do
    local l, key = tk[1], tk[2]
    local v = cap.touched[l][key]
    if V[l] then
      if v == "reset" then
        if key == "inout" then V[l]["in"], V[l].out = 0, 1; put(l, "in/out", "reset", true)
        elseif RANGE[key] then V[l][key] = RESETV[key]; put(l, key, "reset", true) end
      elseif RANGE[key] and type(v) == "number" then
        local nv = snapv(key, v)
        V[l][key] = nv                                                  -- potard touche : on garde la DERNIERE valeur, meme si c'est la valeur de depart (in 0, vol 1...)
        put(l, key, num_str(nv), true)
      end
    end
  end
  -- filet de securite : ce qui a reellement change sur les loopers (souris, groupes, Twister non patche...) sans avoir ete signale
  for l = 1, NLOOP do
    local F = fb(l)
    if F.alive and V[l] then
      local real = {}
      for _, key in ipairs(SAFE) do real[key] = rd(F.b + VPID[key]) end
      if real.speed <= 0 then real.speed = 1 end
      if F.len > 0 then real["in"] = F.lstart / F.len; real.out = (F.lstart + F.lwidth) / F.len end
      for _, key in ipairs(SAFE_ALL) do
        local rv = real[key]
        if rv ~= nil and not idx[l .. "|" .. key] and not idx[l .. "|in/out"] then
          local a = V[l][key] or rv
          local diff
          if cap.snap and SNAP[key] then diff = snapv(key, a) ~= snapv(key, rv) else diff = math.abs(a - rv) > 0.002 end
          if diff then
            local nv = snapv(key, rv)
            V[l][key] = nv
            put(l, key, num_str(nv), true)
          end
        end
      end
    end
  end
  -- regroupe les loopers qui recoivent la meme action (l1/3 rev) sans jamais faire passer une action devant une autre du meme looper
  local groups, lastpos = {}, {}
  for _, it in ipairs(items) do
    local gid = it.key .. "|" .. tostring(it.val)
    local g
    for gi, cand in ipairs(groups) do
      if cand.gid == gid and not cand.ls[it.l] and gi > (lastpos[it.l] or 0) then g = cand; g.pos = gi; break end
    end
    if not g then
      groups[#groups + 1] = { gid = gid, key = it.key, val = it.val, ls = {} }
      g = groups[#groups]; g.pos = #groups
    end
    g.ls[it.l] = true; lastpos[it.l] = g.pos
  end
  local out, prevt = {}, nil
  for _, g in ipairs(groups) do
    local t = sorted(g.ls)
    local tk = table.concat(t, ",")
    local str = g.key .. (g.val and (" " .. g.val) or "") .. (cap.star and "*" or "")
    if g.key == "clearall" or g.key == "clearallfull" then
      if not cap.macro then str = "all " .. str end                      -- CLEAR ALL : toujours les 8 loopers
    elseif tk ~= prevt and not cap.macro then str = tgt_text(t) .. " " .. str end       -- cible identique a l'action precedente : omise
    prevt = tk
    out[#out + 1] = str
  end
  local text = table.concat(out, ", ")
  local gl = cap.globs or {}                                   -- R(n) / G(n) captures : en tete de ligne
  if #gl > 0 then text = table.concat(gl, ", ") .. (text ~= "" and ", " or "") .. text end
  return text, #groups + #gl, unknown
end

local function touch(l, key, v)
  if not l or not key then return end
  cap.touched[l] = cap.touched[l] or {}
  if cap.touched[l][key] == nil then cap.tlist[#cap.tlist + 1] = { l, key } end
  cap.touched[l][key] = v
end

local function cap_event(line)
  local f = {}
  for w in (line .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = w end
  local kind = f[1]
  cap.last_ev = reaper.time_precise()
  if kind == "op" then cap.nop = cap.nop + 1
  elseif kind == "val" or kind == "rst" then cap.nval = cap.nval + 1 end
  cap.lastev = (line:gsub("\t", " "))
  if kind == "op" then
    local l = tonumber(f[3])
    if l then
      cap.ops[#cap.ops + 1] = { a = f[2], l = l, v = f[4] or "" }
      if ACT_TRIG[f[2]] or ACT_RESET[f[2]] then cap.optime = cap.optime or {}; cap.optime[l] = reaper.time_precise() end
    end
  elseif kind == "val" then
    local v = tonumber(f[4])
    if RANGE[f[2]] and v then touch(tonumber(f[3]), f[2], v) end
  elseif kind == "rst" then touch(tonumber(f[3]), f[2], "reset")
  elseif kind == "glob" then                                   -- R(n) / G(n) : preset de routing / de groupe rappele sur le Launchpad
    local g = f[2] or ""
    cap.nop = cap.nop + 1
    cap.globs = cap.globs or {}
    if (g:match("^[rg]%(%d+%)$") or SYNC_WORDS[g]) and cap.globs[#cap.globs] ~= g then cap.globs[#cap.globs + 1] = g end
  elseif kind == "go" then cap.go_t = cap.last_ev; cap.done = false
  elseif kind == "done" then cap.done = true end
end

local function cap_reset_line()
  cap.ops, cap.touched, cap.tlist, cap.go_t, cap.done = {}, {}, {}, nil, false
  cap.globs = {}
end

local function cap_finalize()
  local text, n, unknown = build(cap.virt)
  cap_reset_line()
  if n == 0 then msg = "Rien a enregistrer : aucun changement depuis la ligne precedente."; msg_err = true; return end
  if cap.macro then mac_from_capture(text); return end
  local at = (#steps == 0) and 0 or cur
  local m = H._mk(text, "S" .. (at + 1) .. " " .. text)            -- V3.27 : le pas capture devient un rush perso
  if not m then msg = "Trop de rushes : impossible d'ajouter le pas."; msg_err = true; return end
  H._msave()
  table.insert(steps, at + 1, "@" .. m.id); cur = at + 1
  reparse_all(); want_visible = true
  local un = next(unknown) and ("   (ignore : " .. table.concat(sorted(unknown), ",") .. ")") or ""
  msg = "Ligne " .. cur .. " enregistree : " .. text .. un; msg_err = false
end

local function cap_start()
  if tab == "mac" and mac_count() >= 128 then msg = "128 rushes maximum : supprimes-en un d'abord."; msg_err = true; return end
  capturing = true
  cap.macro = (tab == "mac")
  cap.virt = snapshot()
  cap.prev, cap.optime = {}, {}
  cap_reset_line()
  reaper.SetExtState(CAPEXT, "q", "", false)
  cap.nop, cap.nval, cap.lastev = 0, 0, "(rien recu)"
  msg = cap.macro and "CAPTURE RUSH : fais ton action, puis VALIDER (Entree ou meme bouton). Launch + GO valide tout seul."
        or "CAPTURE : fais tes actions, puis VALIDER (Entree). Launch + GO valide tout seul."
  msg_err = false
end
local function cap_stop()
  capturing = false
  reaper.SetExtState(CAPEXT, "hb", "0", false)
  reaper.SetExtState(CAPEXT, "q", "", false)
end
-- SURVEILLANCE : tout parametre qui bouge pendant la capture (Twister, souris, Launchpad...) est enregistre avec sa DERNIERE
-- valeur, y compris s'il revient a sa valeur par defaut / de depart (pitch 0, speed 1, vol 1, in 0, slicer, cloud...)
local WATCH = {}
for k in pairs(VPID) do WATCH[#WATCH + 1] = k end
table.sort(WATCH)
WATCH[#WATCH + 1] = "in"; WATCH[#WATCH + 1] = "out"
local function cap_watch(now)
  cap.prev, cap.optime = cap.prev or {}, cap.optime or {}
  for l = 1, NLOOP do
    local F = fb(l)
    if F.alive then
      local P = cap.prev[l]
      if not P or P.part ~= F.part then P = { part = F.part }; cap.prev[l] = P end   -- changement de part : nouvelle reference
      local quiet = (cap.optime[l] or -9) + 0.8 > now                               -- juste apres un clear / reset : valeurs remises a zero, pas un geste
      for _, key in ipairs(WATCH) do
        local x
        if key == "in" or key == "out" then
          if F.len > 0 then x = (key == "in") and (F.lstart / F.len) or ((F.lstart + F.lwidth) / F.len) end
        else
          x = rd(F.b + VPID[key])
          if key == "speed" and x <= 0 then x = 1 end
        end
        if x then
          if P[key] ~= nil and math.abs(x - P[key]) > 1e-4 and not quiet then touch(l, key, x) end
          P[key] = x
        end
      end
    end
  end
end
local function cap_poll()
  local now = reaper.time_precise()
  cap_watch(now)
  reaper.SetExtState(CAPEXT, "hb", string.format("%.3f", now), false)
  local q = reaper.GetExtState(CAPEXT, "q")
  if q ~= "" then
    reaper.SetExtState(CAPEXT, "q", "", false)
    for line in q:gmatch("[^\n]+") do
      local ok, err = pcall(cap_event, line)
      if not ok then msg = "Capture : " .. tostring(err); msg_err = true end
    end
  end
  -- GO recu : on attend que la file d'execution du Launchpad soit videe (ou 1 s de calme), puis on ecrit la ligne
  if cap.go_t and ((cap.done and now - cap.last_ev > 0.2) or now - cap.last_ev > 1.0) then
    local ok, err = pcall(cap_finalize)
    if not ok then msg = "Capture : " .. tostring(err); msg_err = true; cap_reset_line() end
  end
end

-- appui long sur le pad Launch du Launchpad : demande de bascule de la capture (ExtState NowUndo_Scn/cmd)
local function cap_cmd_poll()
  local c = reaper.GetExtState(CAPEXT, "cmd")
  if c == "" then return end
  reaper.SetExtState(CAPEXT, "cmd", "", false)
  local now = reaper.time_precise()
  for line in c:gmatch("[^\n]+") do
    local what, t = line:match("^(%a+)\t([%d%.]+)")
    if what and t and now - tonumber(t) < 2 then
      if what == "toggle" then
        if capturing then cap_stop() else cap_start() end
      elseif what == "validate" then
        if capturing then cap_finalize()                -- capture en cours (scenario ou macro) : on valide la ligne / la macro
        elseif tab == "mac" then cap_start() end        -- onglet MACROS, capture arretee : VALIDER (pad LP) arme la capture macro
                                                        -- (en onglet SCENARIO la capture s'active par appui long sur Launch : VALIDER n'ouvre rien)
      elseif what == "prev" then            -- pads du Launchpad : en capture = on choisit ou inserer ; sinon = BACK
        if capturing then cur = math.max(1, cur - 1); want_visible = true else back() end
      elseif what == "next" then            -- en capture = pas suivant (sans executer) ; sinon = GO
        if capturing then cur = math.min(math.max(1, #steps), cur + 1); want_visible = true else go() end
      end
    end
  end
end

local function tail_fit(s, w)
  if gfx.measurestr(s) <= w then return s end
  s = "…" .. s
  while #s > 4 and gfx.measurestr(s) > w do s = "…" .. s:sub(utf8.offset(s, 3) or 4) end
  return s
end

local function cap_panel(W, Hh)
  local bx, by, bw, bh = 12, Hh - 96, W - 24, 30
  gfx.set(0.06, 0.02, 0.03, 1); gfx.rect(bx, by, bw, bh)
  gfx.set(1, 0.3, 0.3, 0.8); gfx.rect(bx, by, bw, bh, 0)
  gfx.setfont(2, "Arial", 14, 'b')
  local text = build(copyV(cap.virt))
  local lbl = cap.macro and "Rush : " or ("Ligne " .. ((#steps == 0) and 1 or (cur + 1)) .. " : ")
  if text == "" then
    gfx.set(1, 1, 1, 0.4); text = "en attente : fais tes actions, puis VALIDER (ou GO si Launch)"
  else gfx.set(1, 1, 1, 0.95) end
  gfx.x, gfx.y = bx + 8, by + 8
  gfx.drawstr(tail_fit(lbl .. text, bw - 16))
  gfx.setfont(2, "Arial", 11)
  gfx.set(1, 1, 1, 0.5)
  gfx.x, gfx.y = bx, Hh - 112
  gfx.drawstr(tail_fit(string.format("recu : %d op Launchpad | %d val Twister | dernier : %s", cap.nop, cap.nval, cap.lastev), bw))
  gfx.setfont(2, "Arial", 12, 'b')
  local specs = {
    { cap.macro and "✔ VALIDER LE RUSH" or "VALIDER (sans GO)", 1.6, 0.15, 0.50, 0.25, function() cap_finalize() end },
    { "ANNULER LIGNE", 1.3, 0.45, 0.30, 0.10, function() cap_reset_line(); msg = "Ligne annulee."; msg_err = false end },
    { cap.star and "SYNC * : ON" or "SYNC * : OFF", 1.2, cap.star and 0.15 or 0.20, cap.star and 0.50 or 0.25, cap.star and 0.30 or 0.35, function() cap.star = not cap.star end },
    { cap.snap and "SNAP : ON" or "SNAP : OFF", 1, 0.20, 0.25, 0.35, function() cap.snap = not cap.snap end },
  }
  local total = 0; for _, sp in ipairs(specs) do total = total + sp[2] end
  local gap = 4
  local unit = (bw - gap * (#specs - 1)) / total
  local x = bx
  for _, sp in ipairs(specs) do
    local w = math.floor(unit * sp[2])
    if btn(x, Hh - 62, w, 26, sp[1], sp[3], sp[4], sp[5]) then sp[6]() end
    x = x + w + gap
  end
  if btn(bx, Hh - 32, bw, 26, cap.macro and "ANNULER LA CAPTURE" or "TERMINER LA CAPTURE", 0.45, 0.15, 0.15) then cap_stop() end
end


--------------------------------------------------------------------------
-- TIMELINE REAPER : des items (vides) nommes S<n> sur une piste lancent le pas n quand la lecture les atteint.
-- Nom lu dans la NOTE de l'item (item vide), sinon dans le nom du take. Exemples : S1  S18  s3 intro.
--------------------------------------------------------------------------
local tl = { on = reaper.GetExtState(EXT, "tl_on") ~= "0", track = tonumber(reaper.GetExtState(EXT, "tl_track")) or 1,
             items = {}, sc = -1, last_scan = 0, prev = nil, count = {} }

local function tl_item_name(item)
  local _, notes = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
  local nm = trim(notes or "")
  if nm == "" then
    local take = reaper.GetActiveTake(item)
    if take then nm = trim(reaper.GetTakeName(take) or "") end
  end
  return nm
end

local function tl_scan()
  local list = {}
  local nt = reaper.CountTracks(0)
  local first, last = tl.track, tl.track
  if tl.track == 0 or tl.track > nt then first, last = 1, (tl.track == 0) and nt or 0 end
  for t = first, last do
    local tr = reaper.GetTrack(0, t - 1)
    if tr then
      for k = 0, reaper.CountTrackMediaItems(tr) - 1 do
        local it = reaper.GetTrackMediaItem(tr, k)
        local d, rest = tl_item_name(it):match("^[sS](%d+)(.*)$")
        if d and (rest == "" or rest:match("^[^%w]")) then
          list[#list + 1] = { pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION"), step = tonumber(d) }
        end
      end
    end
  end
  table.sort(list, function(a, b) return a.pos < b.pos end)
  tl.items = list
end

local function tl_save()
  reaper.SetExtState(EXT, "tl_on", tl.on and "1" or "0", true)
  reaper.SetExtState(EXT, "tl_track", tostring(tl.track), true)
end
local function toggle_tl()
  tl.on = not tl.on; tl.prev = nil; tl_save()
  if tl.on then tl_scan() end
  msg = tl.on and ("Timeline ON : " .. #tl.items .. " item(s) S<n> sur " .. (tl.track == 0 and "toutes les pistes" or ("la piste " .. tl.track)) .. ".") or "Timeline OFF (inhibee)."
  msg_err = false
end
local function cycle_tl_track(x, y)                  -- V3.27 : menu des pistes (nom), plus de +1 par clic
  local nt = reaper.CountTracks(0)
  local items = { (tl.track == 0 and "!" or "") .. "Toutes les pistes" }
  for t = 1, nt do
    local tr = reaper.GetTrack(0, t - 1)
    local _, nm = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    items[#items + 1] = (tl.track == t and "!" or "") .. t .. " : " .. ((nm or "") ~= "" and nm:gsub("|", "/") or "(sans nom)")
  end
  gfx.x, gfx.y = x or mx, y or my
  local k = gfx.showmenu(table.concat(items, "|"))
  if not k or k < 1 then return end
  tl.track = k - 1                                  -- 0 = toutes les pistes
  tl.prev = nil; tl_save(); tl_scan()
  msg = "Timeline : " .. (tl.track == 0 and "toutes les pistes" or ("piste " .. tl.track)) .. "  (" .. #tl.items .. " item(s))"; msg_err = false
end

-- appelee a chaque image : declenche les pas dont l'item est atteint par la lecture (position du moteur audio, avec
-- une petite anticipation pour compenser l'image de rafraichissement)
local function tl_poll()
  local now = reaper.time_precise()
  local sc = reaper.GetProjectStateChangeCount(0)
  if sc ~= tl.sc or now - tl.last_scan > 2 then tl.sc = sc; tl.last_scan = now; tl_scan() end
  local ps = reaper.GetPlayState()
  if (ps & 5) == 0 then tl.prev = nil; return end                 -- ni lecture ni enregistrement
  local pos = reaper.GetPlayPosition2()
  local LEAD = 0.03
  if tl.prev == nil then tl.count = {} end                         -- nouvelle lecture : compteurs a zero
  local jump = (tl.prev == nil) or pos < tl.prev - 1e-6 or pos - tl.prev > 0.5   -- depart, saut, bouclage
  local lo = jump and (pos - 0.06) or (tl.prev + LEAD)
  local hi = pos + LEAD
  tl.prev = pos
  for _, it in ipairs(tl.items) do
    if it.pos > hi then break end
    if it.pos > lo then
      if it.step >= 1 and it.step <= #steps then
        cur = it.step; go()
        tl.count[it.step] = (tl.count[it.step] or 0) + 1
        msg = string.format("Timeline : S%d lance (x%d, a %.2f s)", it.step, tl.count[it.step], it.pos)
      else
        msg = "Timeline : S" .. it.step .. " n'existe pas."; msg_err = true
      end
    end
  end
end
tl_scan()

-- "prendre" un pas et le deposer : cree un item VIDE nomme S<n> (1 mesure) sur la piste timeline
local drag = nil
local function tl_track_for(dropped)
  if tl.track > 0 then return reaper.GetTrack(0, tl.track - 1) end      -- piste timeline choisie
  return dropped or reaper.GetSelectedTrack(0, 0) or reaper.GetTrack(0, 0)
end
local function make_item(stepn, pos, track)
  if not track then msg = "Aucune piste : cree d'abord une piste dans REAPER."; msg_err = true; return end
  reaper.Undo_BeginBlock()
  local it = reaper.AddMediaItemToTrack(track)
  local _, _, cml = reaper.TimeMap2_timeToBeats(0, pos)
  local len = (cml or 4) * 60 / math.max(20, reaper.TimeMap_GetDividedBpmAtTime(pos))
  reaper.SetMediaItemInfo_Value(it, "D_POSITION", pos)
  reaper.SetMediaItemInfo_Value(it, "D_LENGTH", len)
  reaper.GetSetMediaItemInfo_String(it, "P_NOTES", "S" .. stepn, true)
  reaper.SetMediaItemInfo_Value(it, "I_CUSTOMCOLOR", reaper.ColorToNative(230, 190, 40) | 0x1000000)
  reaper.Undo_EndBlock("NowUndo : item S" .. stepn, -1)
  reaper.UpdateArrange()
  tl_scan()
  msg = string.format("Item S%d cree a %.2f s.", stepn, pos); msg_err = false
end
-- bouton / touche I : pose le pas selectionne au curseur de lecture (si ca joue) ou d'edition
local function stamp_step()
  if not steps[cur] then return end
  local playing = (reaper.GetPlayState() & 1) == 1
  local pos = playing and reaper.GetPlayPosition() or reaper.GetCursorPosition()
  make_item(cur, pos, tl_track_for(nil))
end
-- relache d'un pas glisse HORS de la fenetre : position / piste sous la souris (extension SWS), sinon curseur
local function drop_step(row)
  local pos, tr
  if reaper.APIExists and reaper.APIExists("BR_GetMouseCursorContext") then
    local window = reaper.BR_GetMouseCursorContext()
    if window ~= "arrange" then
      msg = "Relache le pas sur la zone des pistes de REAPER (fenetre des items)."; msg_err = true; return
    end
    pos = reaper.BR_PositionAtMouseCursor(false)
    tr = reaper.BR_GetMouseCursorContext_Track()
    if pos and pos >= 0 then
      if reaper.GetToggleCommandState(1157) == 1 then pos = reaper.SnapToGrid(0, pos) end   -- grille magnetique active
    else pos = nil end
  end
  if not pos then
    local playing = (reaper.GetPlayState() & 1) == 1
    pos = playing and reaper.GetPlayPosition() or reaper.GetCursorPosition()
    msg = "SWS absent : pas pose au curseur."; msg_err = false
  end
  make_item(row, pos, tl_track_for(tr))
end

local function move_to(from, to)
  if from == to or not steps[from] then return end
  local st = table.remove(steps, from)
  table.insert(steps, to, st)
  if last == from then last = to
  elseif last > 0 and from < last and to >= last then last = last - 1
  elseif last > 0 and from > last and to <= last then last = last + 1 end
  cur = to
  reparse_all(); want_visible = true
  msg = "Pas deplace : " .. from .. " -> " .. to .. ((#tl.items > 0) and "  (attention : les items S<n> de la timeline gardent leur numero)" or "")
  msg_err = false
end

--------------------------------------------------------------------------
-- MACROS (rushes) : chutier d'actions. Meme syntaxe que les pas du scenario ; V3.27 : cible facultative
-- (sans cible = looper / groupe selectionne ; l1, l(1/3), g2, g(1/3), all = cible ecrite).
-- Partage avec le Launchpad (page 4, couche "Action macros") par l'ExtState "NowUndo_Macros" :
--   set = macros + disposition sur le Launchpad ; rev = numero de version (le Launchpad recharge quand il change).
--------------------------------------------------------------------------
local MAC_EXT, MAC_MAX = "NowUndo_Macros", 26 * 64   -- V3.27 : page 4 du Launchpad = sous-pages de rushes a..z (64 pads chacune)
-- V3.27 : sous-pages de la page 4 : H._pages = noms (1 = a ... 26 = z), H._pg = page affichee ici ; case c du LP -> page ceil(c/64)
H._pages, H._pg, H._PMAX = { "RC-505" }, 1, 26
local MDIR = reaper.GetResourcePath() .. "/Data/NowUndo_Macros/"
local PALETTE = { 0xFF4040, 0xFF9040, 0xFFD320, 0x99FF66, 0x30E060, 0x40D0D0, 0x66CCFF, 0x3A7BFF, 0x9933FF, 0xE040FF, 0xFF66AA, 0xDDDDDD }
local macros, layout, mac_next_id = {}, {}, 1
local msel, mcur, manchor, mscroll, mwant = {}, 0, 0, 0, true     -- selection (ids), curseur (id), ancre (id)
local last_export = "macros.txt"
local mac_last_click_t, mac_last_click_id, mac_alive_t = 0, nil, 0
local OSX = ((reaper.GetOS and reaper.GetOS()) or ""):find("OSX") ~= nil

local function mac_find(id)
  for i, m in ipairs(macros) do if m.id == id then return m, i end end
end
H._mfind = mac_find
local function mac_clean(s)
  s = (s or ""):gsub("[\t\r\n]+", " ")
  return trim(s)
end
local mac_my_rev = ""                                  -- derniere version ecrite par ce script (autre = modifie ailleurs, ex. Ctrl+clic sur le Launchpad)
local function mac_label(m)                            -- libelle affiche : le nom, sinon l'action elle-meme (jamais "Macro 3")
  local n = m.name or ""
  if n == "" or n:match("^Macro %d+$") then return m.text end
  return n
end
local function mac_check(m)
  if trim(m.text) == "" then m.err = "rush vide"; return end
  if m.toggle then   -- toggle "a" = interrupteur A / D : ecrit "d" (le pad affiche d et s'allume en D, comme "d")
    local head, rest = m.text:match("^([^,]*)(.*)$")
    local h2 = head:gsub("^(%s*)a(%s*%*?[%d%./]*%s*)$", "%1d%2")
    if h2 == head then h2 = head:gsub("^(%s*(%S+)%s+)a(%s*%*?[%d%./]*%s*)$", function(p, w, x) if is_tgt(w:lower()) then return p .. "d" .. x end end) end
    if h2 ~= head then m.text = h2 .. rest end
  end
  local _, errs = compile(m.text, { 1 }, m.toggle)
  m.err = errs[1]
end
local function mac_serialize()
  local t = { "NOWUNDO_MACROS 1" }
  for _, m in ipairs(macros) do
    t[#t + 1] = table.concat({ "M", m.id, m.color, m.name, m.text, m.toggle and 1 or 0, m.all and 1 or 0, m.gate and 1 or 0, m.midi or "", m.rom and "R" or "" }, "\t")
  end
  local cells = {}
  for c in pairs(layout) do cells[#cells + 1] = c end
  table.sort(cells)
  for _, c in ipairs(cells) do t[#t + 1] = "L\t" .. c .. "\t" .. layout[c] end
  for k, nm in ipairs(H._pages) do t[#t + 1] = "P\t" .. k .. "\t" .. nm end
  return table.concat(t, "\n")
end
local function mac_deserialize(txt)
  local list, lay, seen, pages = {}, {}, {}, nil
  for line in (txt or ""):gmatch("[^\r\n]+") do
    local f = {}
    for w in (line .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = w end
    if f[1] == "M" and tonumber(f[2]) and #list < MAC_MAX then
      local id = math.floor(tonumber(f[2]))
      if not seen[id] then
        seen[id] = true
        list[#list + 1] = { id = id, color = math.floor(tonumber(f[3]) or 0xAAAAAA), name = f[4] or "", text = f[5] or "", toggle = (f[6] == "1"), all = (f[7] == "1"), gate = (f[8] == "1"), midi = f[9] or "", rom = (f[10] == "R") }
      end
    elseif f[1] == "L" and tonumber(f[2]) and tonumber(f[3]) then
      lay[math.floor(tonumber(f[2]))] = math.floor(tonumber(f[3]))
    elseif f[1] == "P" and tonumber(f[2]) then
      local k = math.floor(tonumber(f[2]))
      if k >= 1 and k <= H._PMAX then pages = pages or {}; pages[k] = mac_clean(f[3]) end
    end
  end
  local maxc = 0
  for c, id in pairs(lay) do                       -- disposition : seulement des macros existantes
    if c < 1 or c > H._PMAX * 64 or not seen[id] then lay[c] = nil elseif c > maxc then maxc = c end
  end
  local had_p = pages ~= nil
  pages = pages or {}
  local np = #pages; for k in pairs(pages) do if k > np then np = k end end
  np = math.max(np, math.ceil(maxc / 64), 1)
  for k = 1, np do if not pages[k] or pages[k] == "" then pages[k] = (k == 1 and not had_p) and "Rushes" or ("Rushes " .. k) end end
  return list, lay, pages, had_p
end
local function mac_apply(list, lay, pages)
  macros, layout, mac_next_id = list, lay, 1
  if pages then H._pages = pages; H._pg = math.min(H._pg, #pages) end
  for _, m in ipairs(macros) do
    if m.id >= mac_next_id then mac_next_id = m.id + 1 end
    mac_check(m)
  end
  if H._rom_fix then H._rom_fix() end
  msel, mcur, manchor = {}, 0, 0
end
-- V3.27 : rushes de la page RC-505 (une colonne par looper, de BAS en HAUT : Rec, Clear, Replace, Restart, Rev,
-- Ping-pong, Slicer, Cloud), poses sur la sous-page a (cases 1..64)
-- V3.27 : RUSHES D'USINE (ROM, lecture seule) : page RC-505 (une colonne par looper, de BAS en HAUT : Rec, Clear, Replace,
-- Restart, Rev, Ping-pong, Slicer, Cloud) et page Effets (rangees 1-4 = FX 1-4 des entrees IN1..IN8, 5-8 = FX 1-4 des
-- loopers). Ni effacables, ni modifiables (Ctrl+D = copie perso modifiable) ; toujours rangees APRES les rushes perso.
H._fdefs = function()
  if H._fd then return H._fd end
  local d = {}
  local ROWS = { { "cloud", "CLOUD", 0x3A7BFF, true }, { "slicer", "SLICER", 0xFFD320, true }, { "pp", "PING PONG", 0xE040FF, true },
                 { "rev", "REVERSE", 0xFF66AA, true }, { "restart", "RESTART", 0x40D0D0, false }, { "replace", "REPLACE", 0xFF9040, true },
                 { "clear", "CLEAR", 0xDDDDDD, false }, { "rec", "REC", 0xFF4040, true } }
  for r, x in ipairs(ROWS) do
    for col = 1, 8 do d[#d + 1] = { pg = "rc", cell = (r - 1) * 8 + col, name = "L" .. col .. " " .. x[2], color = x[3], text = "l" .. col .. " " .. x[1], toggle = x[4] } end
  end
  for r = 1, 8 do
    for col = 1, 8 do
      local inp, sl = r <= 4, (r - 1) % 4 + 1
      d[#d + 1] = { pg = "fx", cell = (r - 1) * 8 + col, name = (inp and "IN" or "L") .. col .. " FX" .. sl, color = inp and 0x99FF66 or 0xFFFF99,
                    text = (inp and "in" or "l") .. col .. " fx " .. sl, toggle = true }
    end
  end
  for k, x in ipairs(d) do x.k = k end
  H._fd = d
  return d
end
H._fnew = function(x)
  local id = mac_next_id; mac_next_id = id + 1
  local m = { id = id, name = x.name, color = x.color, text = x.text, toggle = x.toggle, rom = true }
  mac_check(m)
  macros[#macros + 1] = m
  return m
end
-- V3.27 : rush perso cree sans toucher a la selection (pas de scenario captures / convertis) ; pas d'enregistrement ici
H._mk = function(text, name)
  if #macros >= MAC_MAX then return nil end
  local id = mac_next_id; mac_next_id = id + 1
  local nm = trim((name or ""):gsub("[\t\r\n]+", " "):gsub("%s*,%s*", " - "))
  if #nm > 40 then nm = nm:sub(1, 40) end
  local m = { id = id, name = nm, color = PALETTE[(id - 1) % #PALETTE + 1], text = trim((text or ""):gsub("[\t\r\n]+", " ")) }
  mac_check(m)
  macros[#macros + 1] = m
  return m
end
H._rc505 = function()
  for _, x in ipairs(H._fdefs()) do if x.pg == "rc" then layout[x.cell] = H._fnew(x).id end end
end
-- ancienne couche Effects en rushes (ajoutee une fois, en derniere page)
H._fxpage = function()
  if #H._pages >= H._PMAX then return end
  H._pages[#H._pages + 1] = "Effets"
  local p0 = (#H._pages - 1) * 64
  for _, x in ipairs(H._fdefs()) do if x.pg == "fx" then layout[p0 + x.cell] = H._fnew(x).id end end
end
-- au chargement : les rushes d'usine deja crees (avant la ROM) sont reconnus a leur nom + texte d'origine ; ceux qui
-- manquent sont recrees (non poses) ; puis tri
H._rom_fix = function()
  local key, have = {}, {}
  for _, x in ipairs(H._fdefs()) do key[x.name .. "\t" .. x.text] = x end
  for _, m in ipairs(macros) do
    local x = key[(m.name or "") .. "\t" .. (m.text or "")]
    if x and not have[x.k] then m.rom = true; m.fk = x.k; have[x.k] = true else m.rom = false end
  end
  if reaper.GetExtState(MAC_EXT, "fx_page") == "1" then         -- migration deja faite : l'usine est complete
    for _, x in ipairs(H._fdefs()) do if not have[x.k] and #macros < MAC_MAX then H._fnew(x).fk = x.k end end
  end
  H._msort()
end
-- ordre de la liste : rushes perso (ordre choisi avec haut / bas), puis l'usine dans son ordre fixe
H._msort = function()
  local fk = {}
  for _, x in ipairs(H._fdefs()) do fk[x.name .. "\t" .. x.text] = x.k end
  local perso, rom = {}, {}
  for _, m in ipairs(macros) do
    if m.rom then m.fk = m.fk or fk[(m.name or "") .. "\t" .. (m.text or "")] or 999; rom[#rom + 1] = m else perso[#perso + 1] = m end
  end
  table.sort(rom, function(a, b) if a.fk ~= b.fk then return a.fk < b.fk end return a.id < b.id end)
  for _, m in ipairs(rom) do perso[#perso + 1] = m end
  macros = perso
end
-- lecture seule : refuse si un rush d'usine est dans la liste ms (ou m seul)
H._ro = function(ms)
  for _, m in ipairs(ms) do
    if m.rom then msg = "Rush d'usine (" .. mac_label(m) .. ") : lecture seule. Ctrl+D = copie perso modifiable."; msg_err = true; return true end
  end
  return false
end
local function mac_save()
  H._msort()                                      -- perso d'abord, usine ensuite (ordre fixe)
  local txt = mac_serialize()
  reaper.SetExtState(MAC_EXT, "set", txt, true)
  mac_my_rev = string.format("%.4f", reaper.time_precise())
  reaper.SetExtState(MAC_EXT, "rev", mac_my_rev, false)
  reaper.RecursiveCreateDirectory(MDIR, 0)         -- copie de secours a cote des exports
  local f = io.open(MDIR .. "_autosave.txt", "w")
  if f then f:write(txt); f:close() end
end
-- V3.27 : MODELE de demarrage (comme le MIDI Learn) : ExtState persistant NowUndo_Macros/model = nom d'un fichier de
-- Data/NowUndo_Macros/ (vide = aucun : on reprend la derniere seance, _autosave.txt). Le FICHIER est lu en priorite :
-- la memoire de REAPER peut ne relire qu'une partie d'un texte long. Le modele n'est jamais reecrit automatiquement.
H._read = function(fn) local f = io.open(MDIR .. fn, "r"); if not f then return nil end; local t = f:read("*a"); f:close(); return t end
do                                                  -- chargement au demarrage
  local model = reaper.GetExtState(MAC_EXT, "model")
  local txt = (model ~= "" and H._read(model)) or H._read("_autosave.txt") or ""
  if txt == "" then txt = reaper.GetExtState(MAC_EXT, "set") end
  local list, lay, pages, had_p = mac_deserialize(txt)
  if not had_p then
    -- V3.27 : ancienne disposition (Rushes / Rushes 2) -> sous-pages b, c ; la page a = RC-505 en rushes (cree une fois)
    local nl = {}
    for c, id in pairs(lay) do nl[c + 64] = id end
    lay = nl
    local np = { "RC-505" }
    if next(lay) then for k = 1, #pages do np[k + 1] = (k == 1) and "Rushes" or ("Rushes " .. k) end end
    pages = np
    mac_apply(list, lay, pages)
    H._rc505()
  else
    mac_apply(list, lay, pages)
  end
  if reaper.GetExtState(MAC_EXT, "fx_page") ~= "1" then H._fxpage(); reaper.SetExtState(MAC_EXT, "fx_page", "1", true) end
  mac_save()                                        -- publie tout de suite pour le Launchpad
end
H._msave = mac_save
-- V3.27 : SCENARIO = liste de rushes. Les pas ecrits en texte (anciens scenarios, fichiers importes) deviennent des rushes
-- perso ; un rush perso de meme texte deja present est reutilise (pas de doublons a chaque import).
H._scn_conv = function()
  local by_text, n = {}, 0
  for _, m in ipairs(macros) do if not m.rom and not by_text[m.text] then by_text[m.text] = m end end
  for i, st in ipairs(steps) do
    if not st:match("^@%d+$") then
      local m = by_text[trim(st)]
      if not m then m = H._mk(st, "S" .. i .. " " .. st); if m then by_text[m.text] = m; n = n + 1 end end
      if m then steps[i] = "@" .. m.id end
    end
  end
  if n > 0 then mac_save() end
  reparse_all()
  return n
end
H._scn_conv()
mac_count = function() return #macros end

local function sel_ids()
  local t = {}
  for _, m in ipairs(macros) do if msel[m.id] then t[#t + 1] = m end end
  return t
end
local function sel_count() local n = 0; for _ in pairs(msel) do n = n + 1 end; return n end
local function lp_count() local n = 0; for _ in pairs(layout) do n = n + 1 end; return n end
local function lp_cell_of(id) for c, i in pairs(layout) do if i == id then return c end end end
local function lp_name(c) local k = (c - 1) % 64; return string.format("%s%d.%d", string.char(96 + math.ceil(c / 64)), k // 8 + 1, k % 8 + 1) end

local function lp_remove(ms)
  local n = 0
  for _, m in ipairs(ms) do
    for c, id in pairs(layout) do if id == m.id then layout[c] = nil; n = n + 1 end end
  end
  if n > 0 then mac_save() end
  msg = n .. " pad(s) retire(s) du Launchpad."; msg_err = false
end

local function mac_add(text, name, color)
  if #macros >= MAC_MAX then msg = MAC_MAX .. " rushes maximum : supprimes-en un d'abord."; msg_err = true; return nil end
  local id = mac_next_id; mac_next_id = id + 1
  local nm = mac_clean(name)
  local txt = (text or ""):gsub(";", ",")
  local m = { id = id, name = nm, color = color or PALETTE[(id - 1) % #PALETTE + 1], text = mac_clean(txt) }
  mac_check(m)
  macros[#macros + 1] = m
  msel = { [id] = true }; mcur = id; manchor = id; mwant = true
  mac_save()
  return m
end

-- EDITEUR DE MACRO : texte + palette d'actions par categorie (un clic = l'action ajoutee apres une virgule)
local ED = { on = false }
local function mac_edit()
  local m = mac_find(mcur)
  if not m then msg = "Selectionne un rush."; msg_err = true; return end
  if H._ro({ m }) then return end
  ED.on, ED.id, ED.new, ED.text, ED.off, ED.star = true, m.id, false, m.text or "", false, false
  ED.cur, ED.sug, ED.si, ED.view = #ED.text, {}, 1, 0
  ED.refocus()
end
-- rend le focus clavier a la fenetre du Scenario (apres un menu ou une boite REAPER, les touches partaient vers REAPER)
function ED.refocus()
  if reaper.JS_Window_Find and reaper.JS_Window_SetFocus then
    local h = reaper.JS_Window_Find("NowUndo Scenario", true)
    if h then reaper.JS_Window_SetFocus(h) end
  end
end
-- boite REAPER a l'ancienne (Maj+E, ou bouton dans l'editeur)
function ED.classic(text)
  reaper.SetExtState("NowUndo_Scn", "typing", string.format("%.3f", reaper.time_precise() + 3600), false)   -- MIDI Learn : clavier en pause
  local ok, ret = reaper.GetUserInputs("Modifier le rush", 1, "Syntaxe (sans looper) :,extrawidth=520", ui_in(text))
  reaper.SetExtState("NowUndo_Scn", "typing", "0", false)
  if ok then return ui_out(ret) end
end
-- mots on / off (le bouton OFF leur ajoute "off")
ED.ONOFF = { rec = 1, replace = 1, autorep = 1, multiply = 1, rev = 1, pp = 1, slicer = 1, cloud = 1, link = 1, auto = 1,
             oneshot = 1, br = 1, e1 = 1, e2 = 1, e3 = 1, e4 = 1, play = 1 }
-- { libelle de categorie, { mot, ... } } ; un mot suivi de "..." ouvre un menu de valeurs
ED.CATS = {
  { "Derniere action", { "off", "*" } },          -- off : ajoute / retire "off" ; * : armee au point de synchro
  { "Cible",          { "l1", "l2", "l3", "l4", "l5", "l6", "l7", "l8", "g1", "g2", "g3", "g4", "all" } },   -- rien = selection
  { "Enregistrement", { "rec", "replace", "autorep", "multiply", "rerec", "auto" } },
  { "Lecture",        { "play", "stop", "restart", "rev", "pp", "oneshot", "fullloop", "part..." } },
  { "Modes",          { "slicer", "cloud", "br", "brf...", "link", "mute", "a", "d" } },
  { "Effets",         { "e1", "e2", "e3", "e4" } },
  { "Niveaux",        { "vol...", "speed...", "pitch...", "scale...", "fb...", "smix...", "brmix..." } },
  { "Boucle",         { "in...", "out...", "quant", "undo", "redo", "clear", "clearfull", "reset" } },
  { "Cloud",          { "cdens...", "cchaos...", "cspread...", "cpitch...", "cpos...", "clfo...", "clfodepth..." } },
  { "Slicer",         { "ssteps...", "srate...", "sgrid...", "sdecay...", "sattack...", "spitch...", "smax..." } },
  { "Global",         { "clearall", "clearallfull", "sync", "unsync", "syncall", "unsyncall", "r(n)...", "g(n)..." } },
  { "Groupes / pages", { "to...", "go..." } },     -- V3.27 : l3 to g2 | go lp 1, go 4c, go t1
}
ED.VALS = {
  vol = { "0db", "-3db", "-6db", "-12db", "-24db", "50%", "reset" }, speed = { "0.5", "0.75", "1", "1.5", "2", "reset" },
  pitch = { "-12", "-7", "-5", "5", "7", "12", "reset" }, fb = { "0", "0.5", "1", "1.5", "reset" },
  smix = { "0", "25%", "50%", "75%", "1", "reset" }, brmix = { "0", "25%", "50%", "75%", "1", "reset" },
  ["in"] = { "0", "0.25", "0.5", "0.75", "reset" }, out = { "0.25", "0.5", "0.75", "1", "reset" },
  brf = { "1/2", "1/3", "1/4", "1/6", "1/8", "1/12", "1/16", "1/32", "1/64", "free" }, part = { "1", "2", "3" },
  cdens = { "0", "0.25", "0.5", "0.75", "1", "reset" }, cchaos = { "0", "0.25", "0.5", "0.75", "1", "reset" },
  cspread = { "0", "0.25", "0.5", "0.75", "1", "reset" }, cpitch = { "0", "25", "50", "100", "reset" },
  cpos = { "0", "25", "50", "75", "reset" }, clfo = { "0.25", "0.5", "1", "2", "4", "reset" },
  clfodepth = { "0", "25", "50", "100", "reset" }, ssteps = { "4", "8", "16", "32", "reset" }, srate = { "0", "1", "2", "3", "4", "5", "reset" },
  sgrid = { "0", "1", "2", "3", "5", "7", "reset" }, sdecay = { "20", "50", "150", "500", "2000", "reset" },
  scale = { "free", "demi", "ton", "penta", "maj", "mharm", "mmel", "dim", "aug", "oct" },
  sattack = { "0", "10", "50", "100", "reset" }, spitch = { "0", "25", "50", "100", "reset" }, smax = { "4", "8", "16", "32", "reset" },
  ["to"] = { "g1", "g2", "g3", "g4", "g0" },
  ["go"] = { "lp 1", "lp 2", "lp 3", "4a", "4b", "4c", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "t7b", "t7c", "t7d", "t8", "t9" },
  ["r(n)"] = { "1", "2", "3", "4", "5", "6", "7", "8" }, ["g(n)"] = { "1", "2", "3", "4", "5", "6", "7", "8" },
}
function ED.add(tok)                       -- ajoute une action (apres une virgule) a l'emplacement du curseur
  local a, b = ED.text:sub(1, ED.cur), ED.text:sub(ED.cur + 1)
  a = a:gsub("[%s,]+$", "")
  -- derniere action = une cible seule ("all", "l3", "g2", "in1") ou "l3 to" : le mot la complete (espace, pas de virgule)
  local seg = trim(a:match("([^,]*)$") or "")
  local glue = (seg ~= "" and ((not seg:find("%s") and is_tgt(seg:lower())) or seg:lower():match("%sto$"))) and " " or ", "
  local ins = (a == "") and tok or (a .. glue .. tok)
  b = b:gsub("^[%s,]+", "")
  ED.text = ins .. ((b ~= "") and (", " .. b) or "")
  ED.cur = #ins
end
-- ASSISTANT : mots possibles pour le mot en cours de frappe (ou valeurs apres un mot qui en attend une)
function ED.words()
  if ED._w then return ED._w end
  local w, seen = {}, {}
  local function add(k) if not seen[k] and not k:match("^_") then seen[k] = true; w[#w + 1] = k end end
  for k, f in pairs(H) do if type(f) == "function" then add(k) end end
  for k in pairs(ALIAS) do add(k) end
  for _, k in ipairs({ "off", "on", "reset", "sync", "unsync", "syncall", "unsyncall", "all" }) do add(k) end
  table.sort(w)
  ED._w = w
  return w
end
function ED.suggest()
  local before = ED.text:sub(1, ED.cur)
  local pre = before:match("([%w%(%)/%.%%%-]*)$") or ""
  local prevw = before:sub(1, #before - #pre):match("(%a+)%s+$")
  local out = {}
  local pk = prevw and (ALIAS[prevw] or prevw)
  local vals = pk and (ED.VALS[pk] or (ED.ONOFF[pk] and { "off" }))
  if vals and not before:sub(1, #before - #pre):match(",%s*$") then
    for _, v in ipairs(vals) do if v:sub(1, #pre) == pre and v ~= pre then out[#out + 1] = v end end
  elseif #pre >= 1 and pre:match("^%a") and not split_key(pre:lower()) then   -- mot deja complet : rien a proposer
    local p = pre:lower()
    for _, k in ipairs(ED.words()) do if k:sub(1, #p) == p and k ~= p then out[#out + 1] = k end end
  end
  while #out > 8 do out[#out] = nil end
  ED.sug, ED.pre = out, pre
  if ED.si > #out then ED.si = 1 end
end
function ED.accept(i)
  local w = ED.sug[i or ED.si]
  if not w then return false end
  local k = ALIAS[w] or w
  local tail = (VALKEYS[k] or k == "part") and " " or ""
  ED.text = ED.text:sub(1, ED.cur - #ED.pre) .. w .. tail .. ED.text:sub(ED.cur + 1)
  ED.cur = ED.cur - #ED.pre + #w + #tail
  ED.si = 1
  return true
end
-- modifie la DERNIERE action du texte : "off" (ajoute / retire) ou "*" (synchro, ajoute / retire)
function ED.mod_last(kind)
  local head, seg = ED.text:match("^(.*,)%s*(.-)%s*$")
  if not seg then head, seg = "", trim(ED.text) end
  if seg == "" then msg = "Ajoute d'abord une action."; msg_err = true; return end
  local suf = seg:match("(%*[%d%./]*)$")                     -- *, *1/4, *2 ... garde tel quel par OFF
  if suf then seg = trim(seg:sub(1, -#suf - 1)) end
  if kind == "*" then suf = (not suf) and "*" or nil
  elseif seg:match("%soff$") then seg = trim(seg:sub(1, -5))
  elseif seg:match("^%a+off$") and split_key(seg) then seg = seg:sub(1, -4)
  else seg = seg .. " off" end
  ED.text = head .. ((head ~= "") and " " or "") .. seg .. (suf or "")
  ED.cur = #ED.text
end
function ED.pick(word, as_off)
  if word == "off" or word == "*" then ED.mod_last(word) return end
  if is_tgt(word) and not word:find("%.") then                     -- cible : apres une cible seule, on l'ajoute (l1/l3) ; all remplace
    local a, b = ED.text:sub(1, ED.cur):gsub("[%s,]+$", ""), ED.text:sub(ED.cur + 1)
    local head, seg = a:match("^(.*,%s*)(.-)$"); if not seg then head, seg = "", a end
    if seg ~= "" and not seg:find("%s") and is_tgt(seg:lower()) then
      seg = (word == "all" or seg:lower() == "all") and word or (seg .. "/" .. word)
      ED.text = head .. seg .. b; ED.cur = #head + #seg
      return
    end
  end
  local key = word:gsub("%.%.%.$", "")
  local tok = key
  if word:sub(-3) == "..." then
    local vals = ED.VALS[key] or {}
    local items = {}
    for i, v in ipairs(vals) do items[i] = v end
    items[#items + 1] = "autre valeur..."
    gfx.x, gfx.y = mx, my
    local k = gfx.showmenu(table.concat(items, "|"))
    ED.refocus()
    if not k or k < 1 then return end
    local v = vals[k]
    if not v then
      local ok, r = reaper.GetUserInputs("Valeur : " .. key, 1, key .. " =", "")
      ED.refocus()
      if not ok or trim(r) == "" then return end
      v = trim(r)
    end
    if key == "r(n)" or key == "g(n)" then tok = key:sub(1, 1) .. "(" .. v .. ")" else tok = key .. " " .. v end
  elseif as_off and ED.ONOFF[key] then
    tok = key .. " off"
  end
  ED.add(tok)
end
function ED.close(save)
  if ED.new then
    ED.on, ED.new = false, false
    if save then ED.create(ED.text) end
    return
  end
  local m = mac_find(ED.id)
  if save and m then
    m.text = mac_clean((ED.text):gsub(";", ","))
    mac_check(m); mac_save()
    msg = m.err and ("Rush invalide : " .. m.err) or "Rush modifie."; msg_err = m.err ~= nil
  end
  ED.on = false
end
function ED.prev(t, i) i = i - 1; while i > 0 and (t:byte(i) or 0) >= 0x80 and (t:byte(i) or 0) < 0xC0 do i = i - 1 end return math.max(0, i) end
function ED.next(t, i) i = i + 1; while i < #t and (t:byte(i + 1) or 0) >= 0x80 and (t:byte(i + 1) or 0) < 0xC0 do i = i + 1 end return math.min(#t, i) end
function ED.key(c)
  if c == 0 then return end
  local t, i = ED.text, ED.cur
  local has = #ED.sug > 0
  if c == 9 then if has then ED.accept() end                                -- Tab : accepte la proposition
  elseif c == 13 then if has then ED.accept() else ED.close(true) end      -- Entree : proposition, sinon valider
  elseif c == 30064 then if has then ED.si = (ED.si - 2) % #ED.sug + 1 end -- haut / bas : choisir la proposition
  elseif c == 1685026670 then if has then ED.si = ED.si % #ED.sug + 1 end
  elseif c == 1818584692 then ED.cur = ED.prev(t, i)                        -- gauche / droite / debut / fin
  elseif c == 1919379572 then ED.cur = ED.next(t, i)
  elseif c == 1752132965 then ED.cur = 0
  elseif c == 6647396 then ED.cur = #t
  elseif c == 8 then if i > 0 then local j = ED.prev(t, i); ED.text = t:sub(1, j) .. t:sub(i + 1); ED.cur = j end
  elseif c == 6579564 then if i < #t then local j = ED.next(t, i); ED.text = t:sub(1, i) .. t:sub(j + 1) end
  elseif c >= 32 and c <= 255 and c ~= 127 then
    local ch = utf8.char(c)
    ED.text = t:sub(1, i) .. ch .. t:sub(i + 1); ED.cur = i + #ch
  else return end
  ED.suggest()
end
function ED.draw(W, Hh, eclick)
  local saved = click
  click = eclick
  gfx.set(0, 0, 0, 0.75); gfx.rect(0, 0, W, Hh)
  local px, py, pw, ph = 14, 14, W - 28, Hh - 28
  gfx.set(0.10, 0.10, 0.14, 1); gfx.rect(px, py, pw, ph)
  gfx.set(1, 1, 1, 0.25); gfx.rect(px, py, pw, ph, 0)
  local m = mac_find(ED.id)
  gfx.setfont(3, "Arial", 13, 'b'); gfx.set(0.9, 0.8, 0.2, 1)
  gfx.x, gfx.y = px + 12, py + 10
  gfx.drawstr(ED.new and "NOUVEAU RUSH" or ("EDITION DU RUSH" .. ((m and m.name ~= "") and ("  -  " .. m.name) or "")))
  -- zone de texte
  local tx, ty, tw, th = px + 12, py + 34, pw - 24, 30
  gfx.set(0.04, 0.04, 0.06, 1); gfx.rect(tx, ty, tw, th)
  gfx.set(0.55, 0.85, 1, 0.6); gfx.rect(tx, ty, tw, th, 0)
  gfx.setfont(2, "Arial", 14); gfx.set(1, 1, 1, 1)
  local t = ED.text
  ED.cur = math.max(0, math.min(#t, ED.cur or #t))
  ED.view = math.max(0, math.min(ED.view or 0, ED.cur))                    -- defilement : le curseur reste visible
  while ED.view < ED.cur and gfx.measurestr(t:sub(ED.view + 1, ED.cur)) > tw - 24 do ED.view = ED.next(t, ED.view) end
  local vis = t:sub(ED.view + 1)
  while #vis > 0 and gfx.measurestr(vis) > tw - 16 do vis = vis:sub(1, ED.prev(vis, #vis)) end
  gfx.x, gfx.y = tx + 8, ty + 7; gfx.drawstr(vis)
  local cx = tx + 8 + gfx.measurestr(t:sub(ED.view + 1, ED.cur))
  if math.floor(reaper.time_precise() * 2) % 2 == 0 then gfx.line(cx, ty + 6, cx, ty + th - 6) end
  if click and mx >= tx and mx <= tx + tw and my >= ty and my <= ty + th then   -- clic : place le curseur
    local p = ED.view
    while p < #t and tx + 8 + gfx.measurestr(t:sub(ED.view + 1, ED.next(t, p))) <= mx + 3 do p = ED.next(t, p) end
    ED.cur = p; ED.suggest()
  end
  -- verification en direct
  local _, errs = compile(ED.text, { 1 }, m and m.toggle)
  gfx.setfont(2, "Arial", 12)
  if ED.text == "" then gfx.set(1, 1, 1, 0.45); gfx.x, gfx.y = tx, ty + th + 6; gfx.drawstr("Tapez (l'assistant propose, Tab / Entree accepte) ou cliquez des actions ; clic droit = action en OFF.")
  elseif #errs > 0 then gfx.set(1, 0.4, 0.4, 1); gfx.x, gfx.y = tx, ty + th + 6; gfx.drawstr(fit(errs[1], tw))
  else gfx.set(0.4, 1, 0.5, 1); gfx.x, gfx.y = tx, ty + th + 6; gfx.drawstr("OK") end
  -- commandes
  local by, bh = ty + th + 26, 26
  gfx.setfont(2, "Arial", 12, 'b')
  if btn(tx, by, 130, bh, "VALIDER (Entree)", 0.15, 0.45, 0.20) then ED.close(true) end
  if btn(tx + 136, by, 130, bh, "ANNULER (Echap)", 0.45, 0.15, 0.15) then ED.close(false) end
  if btn(tx + 272, by, 150, bh, "RETIRER LA DERNIERE", 0.25, 0.25, 0.32) then ED.text = ED.text:match("^(.*),") or "" end
  if btn(tx + 428, by, 80, bh, "EFFACER", 0.25, 0.25, 0.32) then ED.text = "" end
  if btn(tx + 514, by, 110, bh, "<- RETOUR ARR.", 0.25, 0.25, 0.32) then ED.key(8) end
  if btn(tx + 630, by, 110, bh, "BOITE REAPER", 0.25, 0.25, 0.32) then
    local r = ED.classic(ED.text)
    ED.refocus()
    if r then ED.text = r; ED.cur = #r; ED.suggest() end
  end
  -- palette (clic droit sur une action on/off = ajoutee en "off")
  local rdn = (gfx.mouse_cap & 2) == 2
  local rclick = rdn and not ED.rwas
  ED.rwas = rdn
  local y = by + bh + 14
  gfx.setfont(2, "Arial", 12)
  for _, cat in ipairs(ED.CATS) do
    gfx.set(0.9, 0.8, 0.2, 1); gfx.setfont(2, "Arial", 12, 'b')
    gfx.x, gfx.y = tx, y + 6; gfx.drawstr(cat[1])
    gfx.setfont(2, "Arial", 12)
    local x = tx + 112
    for _, w in ipairs(cat[2]) do
      local bw = gfx.measurestr(w) + 18
      if x + bw > tx + tw then x = tx + 112; y = y + 28 end
      local key = w:gsub("%.%.%.$", "")
      local mod = (w == "off" or w == "*")
      if btn(x, y, bw, 24, w, mod and 0.45 or 0.20, mod and 0.30 or 0.26, mod and 0.10 or 0.36) then ED.pick(w); ED.suggest() end
      if rclick and ED.ONOFF[key] and mx >= x and mx <= x + bw and my >= y and my <= y + 24 then ED.pick(w, true); ED.suggest() end
      x = x + bw + 5
    end
    y = y + 32
  end
  -- propositions de l'assistant (sous le curseur, par-dessus la palette)
  if #ED.sug > 0 then
    gfx.setfont(2, "Arial", 13)
    local lw = 140
    for _, w in ipairs(ED.sug) do lw = math.max(lw, gfx.measurestr(w) + 24) end
    local lx, ly, lh = math.min(cx, tx + tw - lw), ty + th + 2, 22
    gfx.set(0.16, 0.18, 0.24, 1); gfx.rect(lx, ly, lw, lh * #ED.sug)
    gfx.set(0.55, 0.85, 1, 0.6); gfx.rect(lx, ly, lw, lh * #ED.sug, 0)
    for n, w in ipairs(ED.sug) do
      local yy = ly + (n - 1) * lh
      local hov = mx >= lx and mx <= lx + lw and my >= yy and my < yy + lh
      if n == ED.si or hov then gfx.set(0.25, 0.45, 0.70, 1); gfx.rect(lx + 1, yy, lw - 2, lh) end
      gfx.set(1, 1, 1, 1); gfx.x, gfx.y = lx + 10, yy + 4; gfx.drawstr(w)
      if hov and click then ED.accept(n); ED.suggest() end
    end
  end
  click = saved
end
local function mac_rename()
  local m = mac_find(mcur)
  if not m then msg = "Selectionne un rush."; msg_err = true; return end
  if H._ro({ m }) then return end
  local ok, ret = reaper.GetUserInputs("Nommer le rush", 1, "Nom (vide = afficher l'action) :,extrawidth=240", (m.name ~= "") and m.name or ED.title(m.text))
  if ok then m.name = mac_clean(ret); mac_save(); msg = (m.name == "") and "Nom efface : le pad affichera l'action." or "Rush renomme."; msg_err = false end
end
local function mac_new()                    -- ADD : ouvre l'editeur (assistant + palette) sur une macro vide
  if #macros >= MAC_MAX then msg = MAC_MAX .. " rushes maximum."; msg_err = true; return end
  ED.on, ED.id, ED.new, ED.text, ED.off, ED.star = true, nil, true, "", false, false
  ED.cur, ED.sug, ED.si, ED.view, ED.cell = 0, {}, 1, 0, nil
  ED.refocus()
end
-- titre propose = le contenu (virgules -> " - ", tronque)
function ED.title(text)
  local t = trim((text or ""):gsub("%s*,%s*", " - "):gsub("%s+", " "))
  if #t > 40 then t = t:sub(1, 40) end
  return t
end
-- validation d'une NOUVELLE macro (appelee par ED.close) : nom demande (contenu propose), puis creation
function ED.create(text)
  if trim(text) == "" then return end
  reaper.SetExtState("NowUndo_Scn", "typing", string.format("%.3f", reaper.time_precise() + 3600), false)
  local ok2, nm = reaper.GetUserInputs("Nom du rush", 1, "Nom (vide = afficher l'action) :,extrawidth=240", ED.title(text))
  reaper.SetExtState("NowUndo_Scn", "typing", "0", false)
  local m = mac_add(text, ok2 and nm or "", nil)
  if m and ED.cell then                                            -- V3.27 : cree par clic droit sur une case du Launchpad
    if not layout[ED.cell] then layout[ED.cell] = m.id; mac_save() end
    ED.cell = nil
  end
  if m then msg = m.err and ("Rush cree mais invalide : " .. m.err) or ("Rush cree : " .. mac_label(m)); msg_err = m.err ~= nil end
end
local function mac_recolor()
  local ms = sel_ids()
  if #ms == 0 then msg = "Selectionne un rush."; msg_err = true; return end
  if H._ro(ms) then return end
  local ok, res, col = pcall(reaper.GR_SelectColor)
  if ok and res ~= 0 and col then
    local r, g, b = reaper.ColorFromNative(col)
    local hex = (r << 16) | (g << 8) | b
    for _, m in ipairs(ms) do m.color = hex end
    mac_save()
  end
end
local function mac_delete()
  local ms = sel_ids()
  if #ms == 0 then return end
  if H._ro(ms) then return end
  if #ms > 1 and reaper.MB("Supprimer " .. #ms .. " rushes ?", "NowUndo - rushes", 4) ~= 6 then return end
  local rm = {}
  for _, m in ipairs(ms) do rm[m.id] = true end
  local keep = {}
  for _, m in ipairs(macros) do if not rm[m.id] then keep[#keep + 1] = m end end
  macros = keep
  for c, id in pairs(layout) do if rm[id] then layout[c] = nil end end
  msel, mcur, manchor = {}, 0, 0
  mac_save()
  msg = #ms .. " rush(es) supprime(s)."; msg_err = false
end
-- COPIER / COUPER / COLLER / DUPLIQUER (Ctrl+C / X / V / D, ou clic droit sur une ligne de la liste)
function ED.mcopy(quiet)
  local ms = sel_ids()
  if #ms == 0 then msg = "Selectionne un ou plusieurs rushes."; msg_err = true; return false end
  H._mclip = {}
  for _, o in ipairs(ms) do
    H._mclip[#H._mclip + 1] = { text = o.text, name = o.name, color = o.color, toggle = o.toggle, all = o.all, gate = o.gate }
  end
  if not quiet then msg = #ms .. " rush(es) copie(s) : Ctrl+V pour les coller."; msg_err = false end
  return true
end
function ED.mcut()
  if H._ro(sel_ids()) then return end
  if not ED.mcopy(true) then return end
  local rm = {}
  for _, m in ipairs(sel_ids()) do rm[m.id] = true end
  local keep = {}
  for _, m in ipairs(macros) do if not rm[m.id] then keep[#keep + 1] = m end end
  macros = keep
  for c, id in pairs(layout) do if rm[id] then layout[c] = nil end end
  msel, mcur, manchor = {}, 0, 0
  mac_save()
  msg = #H._mclip .. " rush(es) coupe(s) : Ctrl+V pour les coller."; msg_err = false
end
-- colle des copies JUSTE APRES la derniere macro selectionnee (sinon a la fin)
function ED.mpaste(src)
  src = src or H._mclip
  if not src or #src == 0 then msg = "Rien a coller : Ctrl+C ou Ctrl+X sur un ou plusieurs rushes d'abord."; msg_err = true; return end
  local after = 0
  for i, m in ipairs(macros) do if msel[m.id] then after = i end end
  if after == 0 then local _, ci = mac_find(mcur); after = ci or #macros end
  local made = {}
  for _, o in ipairs(src) do
    local m = mac_add(o.text, o.name, o.color)
    if not m then break end
    m.toggle, m.all, m.gate = o.toggle, o.all, o.gate
    mac_check(m); made[#made + 1] = m
  end
  if #made == 0 then return end
  for _ = 1, #made do table.remove(macros) end                           -- mac_add les a mises a la fin : on les replace
  for k, m in ipairs(made) do table.insert(macros, math.min(after + k, #macros + 1), m) end
  msel = {}; for _, m in ipairs(made) do msel[m.id] = true end
  mcur = made[1].id; manchor = mcur; mwant = true
  mac_save(); msg = #made .. " rush(es) colle(s)."; msg_err = false
end
-- Ctrl+C / X / V / D lus directement (js_ReaScriptAPI) quand la fenetre a le focus : marche meme si le MIDI Learn
-- bloque C / V (touches apprises sans modificateur) ou si getchar ne renvoie pas les codes de controle.
function ED.vk_poll()
  if not reaper.JS_VKeys_GetState then return end
  local st = reaper.JS_VKeys_GetState(0)
  if not st or #st < 254 then return end
  local prev = ED.vkprev or st
  ED.vkprev = st
  if (gfx.getchar(65536) & 2) == 0 then return end                          -- la fenetre n'a pas le focus
  if st:byte(17) == 0 and st:byte(91) == 0 then return end                   -- ni Ctrl ni Win/Cmd
  local function edge(vk) return st:byte(vk) ~= 0 and prev:byte(vk) == 0 end
  local k = edge(67) and 1 or edge(88) and 2 or edge(86) and 3 or edge(68) and 4 or nil
  if not k or reaper.time_precise() - (ED.ck_t or 0) < 0.3 then return end   -- deja traite par getchar
  ED.vk_t = reaper.time_precise()
  if k == 1 then ED.mcopy() elseif k == 2 then ED.mcut() elseif k == 3 then ED.mpaste() else ED.mdup() end
end
function ED.mdup()
  local ms = sel_ids()
  if #ms == 0 then msg = "Selectionne un ou plusieurs rushes."; msg_err = true; return end
  local src = {}
  for _, o in ipairs(ms) do src[#src + 1] = { text = o.text, name = o.name, color = o.color, toggle = o.toggle, all = o.all, gate = o.gate } end
  ED.mpaste(src)
end
local function mac_move(d)                           -- decale la selection d'un cran (les blocs se deplacent ensemble)
  if H._ro(sel_ids()) then return end
  local n = #macros
  if d < 0 then
    for i = 2, n do
      if msel[macros[i].id] and not msel[macros[i - 1].id] then macros[i], macros[i - 1] = macros[i - 1], macros[i] end
    end
  else
    for i = n - 1, 1, -1 do
      if msel[macros[i].id] and not msel[macros[i + 1].id] then macros[i], macros[i + 1] = macros[i + 1], macros[i] end
    end
  end
  mwant = true; mac_save()
end
local function mac_move_sel(set, to_idx)            -- glisser-deposer : la selection va a la place de la macro visee
  for id in pairs(set) do local m = mac_find(id); if m and H._ro({ m }) then return end end
  local target = macros[to_idx]
  if not target or set[target.id] then return end
  local moving, rest, first = {}, {}, nil
  for i, m in ipairs(macros) do
    if set[m.id] then moving[#moving + 1] = m; first = first or i else rest[#rest + 1] = m end
  end
  local pos = 0
  for i, m in ipairs(rest) do if m == target then pos = i; break end end
  local ins = (to_idx > first) and (pos + 1) or pos
  for k, m in ipairs(moving) do table.insert(rest, ins + k - 1, m) end
  macros = rest
  mac_save()
end

-- cibles d'un essai depuis cette fenetre : looper / groupe selectionne sur le Launchpad (ExtState publie par le coeur VL)
local function sel_targets()
  local sl = math.floor(tonumber(reaper.GetExtState("nowundo_vl", "sel_looper")) or 1)
  local sg = math.floor(tonumber(reaper.GetExtState("nowundo_vl", "sel_group")) or 0)
  if sg > 0 then
    local t = {}
    for i = 1, NLOOP do if rd(6000 + i) == sg then t[#t + 1] = i end end    -- gmem 6000+i = groupe du looper i (publie par le Launchpad)
    if #t > 0 then return t end
  end
  return { math.max(1, math.min(NLOOP, sl)) }
end

-- ===== RUSHES GATE / TOGGLE : le DERNIER rush actif gagne =====
-- Chaque rush active (pad gate tenu, pad toggle allume) est empile. Activer = appliquer tel qu'ecrit (jamais d'inversion :
-- un 2e beat repeat ne coupe pas le 1er, la fraction devient la sienne, rien ne s'additionne). Desactiver = pour chaque
-- action (looper + mot), remettre la valeur du rush actif le plus recent qui la porte encore, sinon la defaire (defaut).
H._live = {}
H._live_find = function(mid)
  for n, e in ipairs(H._live) do if e.mid == mid then return n, e end end
end
H._rush_live = function(m, targets, on)
  local n = H._live_find(m.id)
  if n then table.remove(H._live, n) end
  if on then
    H._live[#H._live + 1] = { mid = m.id, targets = targets }
    return compile(m.text, targets, false, false)
  end
  local out = {}
  for _, it in ipairs(compile(m.text, targets, false, true)) do
    local repl = nil
    if it.key and it.i then
      for k = #H._live, 1, -1 do
        local e2 = H._live[k]
        local m2 = mac_find(e2.mid)
        if m2 and not m2.err then          -- V3.27 : les cibles peuvent etre ecrites dans le rush (l2, g1...) : on compare les items
          for _, it2 in ipairs(compile(m2.text, e2.targets, false, false)) do
            if it2.i == it.i and it2.key == it.key then repl = repl or {}; repl[#repl + 1] = it2 end
          end
          if repl then break end
        end
      end
    end
    if repl then for _, x in ipairs(repl) do out[#out + 1] = x end else out[#out + 1] = it end
  end
  return out
end
local function run_macro(m, targets, gst, press_t)   -- gst : "on" / "off" pour une macro GATE (appui / relachement du pad) ; press_t : heure de l'appui
  if m.err then msg = "Rush '" .. mac_label(m) .. "' invalide : " .. m.err; msg_err = true; return end
  reaper.gmem_attach(GMEM)
  if m.all then targets = {}; for i = 1, NLOOP do targets[i] = i end end       -- mode ALL : action collective sur les 8 loopers
  local items
  if m.gate and (gst == "on" or gst == "off") then
    items = H._rush_live(m, targets, gst == "on")          -- GATE : appui = tel qu'ecrit, relachement = defait (dernier actif gagne)
  elseif m.toggle and not m.err then
    -- TOGGLE : allume -> eteint selon la pile ; si l'etat a ete change ailleurs (ex. BR coupe a la main), on rallume
    local _, e = H._live_find(m.id)
    local on = not e
    if e and H._probe_ok and H._probe_ok(m) and not H._mac_active(m, e.targets) then on = true end
    if H._mirror and H._mirror(m) then on = not H._mac_active(m, targets) end   -- V3.27 : effet / groupe : suit l'etat reel
    items = H._rush_live(m, (e and not on) and e.targets or targets, on)
  else
    items = compile(m.text, targets, false)
  end
  grp_counter = grp_counter + 1
  local t0 = math.min(reaper.time_precise(), press_t or 1e12)
  local dead, seen, nsync, nglob = {}, {}, 0, 0
  for _, it in ipairs(items) do
    if it.glob then
      fire_glob(it); nglob = nglob + 1
    elseif rd(100 + it.i - 1) > 0 then
      Q[it.i][#Q[it.i] + 1] = { ch = it.ch, f = it.f, t0 = t0, sync = it.sync, grp = grp_counter, mid = m.id }
      if it.sync then nsync = nsync + 1 end
    elseif not it.all and not m.all and not seen[it.i] then seen[it.i] = true; dead[#dead + 1] = "L" .. it.i end   -- ALL : les loopers absents sont ignores
  end
  local tl_, tseen = {}, {}
  for _, it in ipairs(items) do if it.i and not tseen[it.i] then tseen[it.i] = true; tl_[#tl_ + 1] = it.i end end   -- V3.27 : cibles reelles
  table.sort(tl_); for n, i in ipairs(tl_) do tl_[n] = i > 100 and ("IN" .. (i - 100)) or ("L" .. i) end
  msg = "Rush '" .. mac_label(m) .. "' -> " .. (m.all and "ALL" or table.concat(tl_, ",")) .. (m.toggle and " [toggle]" or "") .. (m.gate and " [gate]" or "")
        .. (#dead > 0 and ("  (looper absent : " .. table.concat(dead, ",") .. ")") or "")
        .. (nsync > 0 and ("  -  " .. nsync .. " action(s) * en attente du point de synchro") or "")
        .. (nglob > 0 and ("  -  " .. nglob .. " commande(s) envoyee(s) au Launchpad") or "")
  msg_err = #dead > 0
end
H._run_step = function(id)                           -- V3.27 : GO du scenario = le rush du pas, comme son bouton lecture
  local m = mac_find(id)
  if not m then msg = "rush supprime"; msg_err = true; return end
  H._sflash = { id = id, t = reaper.time_precise() }
  run_macro(m, sel_targets(), nil, reaper.time_precise())
end
local function mac_test()
  local ms = sel_ids()
  if #ms == 0 then msg = "Selectionne un rush a tester."; msg_err = true; return end
  local tg = sel_targets()
  for _, m in ipairs(ms) do run_macro(m, tg) end
end

-- etat ON/OFF d'une macro TOGGLE (pour allumer son pad sur le Launchpad) : on regarde la 1re action de la macro
-- sur le(s) looper(s) cible(s) ; ON = tous les loopers cibles sont dans l'etat "enregistre" (rev actif, in = valeur, ...)
local PROBE = {
  rec = function(F) return F.rec end, replace = function(F) return F.st == 4 end, autorep = function(F) return F.st == 5 end,
  multiply = function(F) return F.st == 6 end, rev = function(F) return F.rev end, pp = function(F) return F.pp end,
  slicer = function(F) return F.slicer end, cloud = function(F) return F.cloud end, link = function(F) return F.link end,
  auto = function(F) return F.auto end, oneshot = function(F) return F.oneshot end, br = function(F) return F.br end, mute = function(F) return F.mute end, play = function(F) return F.playing end,
  d = function(F) return F.raw end, a = function(F) return not F.raw end,
}
local function mac_active(m, targets)
  if not m.toggle or m.err then return false end
  local s = H._norm(m.text):lower():gsub("à", " "):gsub("[=:]", " ")
  local act = s:match("^[^,]*") or ""
  local tgs, tgn = trim(act):match("^(.-)%s*%f[%a]to%s+g%s*%(?%s*(%d+)%s*%)?$")   -- V3.27 : "l3 to g2" allume = L3 dans le groupe 2
  if tgn then
    local tt = (tgs ~= "") and parse_target(tgs:gsub("%s+", "")) or targets
    if not tt or #tt == 0 then return false end
    for _, i in ipairs(tt) do if rd(6000 + i) ~= tonumber(tgn) then return false end end
    return true
  end
  local t = {}
  for w in act:gmatch("%S+") do t[#t + 1] = (w:gsub("%*[%d%./]*$", "")) end
  if #t == 0 then return false end
  if is_tgt(t[1]) and #t > 1 then                    -- V3.27 : cible ecrite dans le rush (l2, g1, all...) : c'est elle qu'on verifie
    local tt = parse_target(t[1]); if not tt then return false end
    targets = tt; table.remove(t, 1)
  end
  local key = split_key(t[1]:match("[^/]+") or "")
  if not key then return false end
  if key == "mute" and #targets > 0 and targets[1] > 100 then   -- V3.27 : entree mute (gmem 6050+n, publie par le Launchpad)
    local want = not (t[2] == "off" or (t[1]:match("off$") ~= nil))
    for _, i in ipairs(targets) do if i <= 100 or ((rd(6050 + i - 100) > 0.5) ~= want) then return false end end
    return true
  end
  local fsl = tonumber(key:match("^e([1-4])$"))         -- V3.27 : effet allume = slot actif (gmem 6030+i loopers, 6040+n entrees)
  if fsl then
    if m.all then targets = {}; for i = 1, NLOOP do targets[i] = i end end
    local want = not (t[2] == "off" or (t[1]:match("off$") ~= nil))
    for _, i in ipairs(targets) do
      local mask = (i > 100) and rd(6040 + i - 100) or rd(6030 + i)
      if ((math.floor(mask) >> (fsl - 1)) & 1 == 1) ~= want then return false end
    end
    return #targets > 0
  end
  local x, kind = nil, nil
  if t[2] then x, kind = num(t[2]) end
  local any = false
  if m.all then targets = {}; for i = 1, NLOOP do targets[i] = i end end
  for _, i in ipairs(targets) do
    local F = fb(i)
    if F.alive then
      any = true
      local ok
      if PROBE[key] then ok = PROBE[key](F)
      elseif (key == "in" or key == "out") and x and F.len > 0 then
        local cur = (key == "in") and (F.lstart / F.len) or ((F.lstart + F.lwidth) / F.len)
        ok = math.abs(cur - x) <= 0.004
      elseif VPID and VPID[key] and x then
        if key == "vol" and kind == "db" then x = 10 ^ (x / 20) end
        local cur = rd(F.b + VPID[key])
        if key == "speed" and cur <= 0 then cur = 1 end
        ok = math.abs(cur - x) <= 1e-3 + 0.003 * math.max(math.abs(cur), math.abs(x))
      else return false end
      if not ok then return false end
    end
  end
  return any
end
H._mac_active = mac_active
H._probe_ok = function(m)
  local s = H._norm(m.text):lower():gsub("à", " "):gsub("[=:]", " ")
  if trim(s:match("^[^,]*") or ""):match("%f[%a]to%s+g%s*%(?%s*%d+%s*%)?$") then return true end   -- V3.27 : l3 to g2
  local t = {}
  for w in (s:match("^[^,]*") or ""):gmatch("%S+") do t[#t + 1] = (w:gsub("%*[%d%./]*$", "")) end
  if t[1] and is_tgt(t[1]) and #t > 1 then table.remove(t, 1) end   -- V3.27 : cible ecrite dans le rush
  local key = t[1] and split_key(t[1]:match("[^/]+") or "")
  if not key then return false end
  if PROBE[key] or key:match("^e[1-4]$") then return true end
  local x = t[2] and num(t[2])
  return x ~= nil and (key == "in" or key == "out" or (VPID and VPID[key] ~= nil))
end
-- V3.27 : rushes toggle "miroir" (1re action = effet e1..e4 / fx n, ou "to g") : le pad suit l'etat reel (effet actif,
-- looper membre), meme change ailleurs (Launchpad, web, FX Router), comme l'ancienne couche Effects / la matrice de groupes
H._mirror = function(m)
  if not m.toggle or m.err then return false end
  local a = trim((H._norm(m.text):lower():match("^[^,]*") or ""))
  if a:match("%f[%a]to%s+g%s*%(?%s*%d+%s*%)?$") then return true end
  local w = {}
  for x in a:gmatch("%S+") do w[#w + 1] = x end
  local inp = w[1] and w[1]:match("^in?[%d%(]") ~= nil
  if w[1] and is_tgt(w[1]) then table.remove(w, 1) end
  if inp and w[1] and w[1]:match("^mute") then return true end        -- mute d'une entree : suit la piste
  if w[1] == "d" or w[1] == "d*" then return true end  -- interrupteur A / D : suit le mode reel (allume = D)
  return w[1] ~= nil and w[1]:match("^e[1-4]") ~= nil
end
local mac_on_t, mac_on_s = 0, nil

-- declenchements venant du Launchpad (ExtState NowUndo_Scn/mcr : id<TAB>cibles<TAB>temps) + heartbeat "alive"
local function mac_poll()
  local t = reaper.time_precise()
  local rq = reaper.GetExtState(CAPEXT, "lp_new")                  -- V3.27 : clic droit sur un pad de la page 4 du Launchpad
  if rq ~= "" then
    reaper.SetExtState(CAPEXT, "lp_new", "", false)
    local c, id, ts = rq:match("^(%d+)\t(%d+)\t([%d%.]+)")
    if c and t - tonumber(ts) < 3 then H._lpreq = { cell = tonumber(c), id = tonumber(id) }; if H._bg then H._open() end end
  end
  if t - mac_on_t > 0.12 then                                      -- pads toggle du Launchpad : ON = plein feu, OFF = attenue
    mac_on_t = t
    local tg, ids = sel_targets(), {}
    for _, m in ipairs(macros) do
      if m.toggle then
        local _, e = H._live_find(m.id)
        if H._mirror(m) then if mac_active(m, tg) then ids[#ids + 1] = m.id end
        elseif e and (not H._probe_ok(m) or mac_active(m, e.targets)) then ids[#ids + 1] = m.id end
      end
    end
    local s = table.concat(ids, ",")
    if s ~= mac_on_s then mac_on_s = s; reaper.SetExtState(MAC_EXT, "on", s, false) end
    -- macros dont une action armee (*) attend le point de synchro : leur pad clignote sur le Launchpad
    local pend, pl = {}, {}
    for i = 1, NLOOP do for _, op in ipairs(Q[i]) do if op.sync and op.mid then pend[op.mid] = true end end end
    for id in pairs(pend) do pl[#pl + 1] = id end
    table.sort(pl)
    local ps = table.concat(pl, ",")
    H._pend = pend
    if ps ~= H._pend_s then H._pend_s = ps; reaper.SetExtState(MAC_EXT, "pend", ps, false) end
  end
  if t - mac_alive_t > 0.3 then
    mac_alive_t = t
    reaper.SetExtState(CAPEXT, "alive", string.format("%.3f", t), false)
  end
  if reaper.GetExtState(MAC_EXT, "rev") ~= mac_my_rev then       -- modifie ailleurs (Ctrl+clic sur un pad du Launchpad)
    local list, lay, pages = mac_deserialize(reaper.GetExtState(MAC_EXT, "set"))
    macros, layout = list, lay
    H._pages = pages; H._pg = math.min(H._pg, #pages)
    mac_next_id = 1
    for _, m in ipairs(macros) do
      if m.id >= mac_next_id then mac_next_id = m.id + 1 end
      mac_check(m)
    end
    for id in pairs(msel) do if not mac_find(id) then msel[id] = nil end end
    if not mac_find(mcur) then mcur = 0 end
    mac_my_rev = reaper.GetExtState(MAC_EXT, "rev")
  end
  H._learn_poll()
  local q = reaper.GetExtState(CAPEXT, "mcr")
  if q == "" then return end
  reaper.SetExtState(CAPEXT, "mcr", "", false)
  for line in q:gmatch("[^\n]+") do
    local id, tg, ts, gst = line:match("^(%d+)\t([%d,]*)\t([%d%.]+)\t?(%a*)")
    if id and t - tonumber(ts) < 2 then
      local m = mac_find(tonumber(id))
      if m then
        local targets = {}
        for n in tg:gmatch("%d+") do
          local k = tonumber(n)
          if k >= 1 and k <= NLOOP then targets[#targets + 1] = k end
        end
        if #targets == 0 then targets = sel_targets() end   -- V3.27 : cible vide (MIDI d'un rush) = selection du Launchpad
        run_macro(m, targets, gst, tonumber(ts))
      end
    end
  end
end

mac_from_capture = function(text)                    -- capture et validation = un seul bouton : une capture = une macro
  local m = mac_add(text, "", nil)
  cap_stop()
  if m then msg = "Rush enregistre : " .. text; msg_err = false end
end

local function mac_capture_toggle()
  if capturing then
    if cap.macro then cap_finalize() else cap_stop() end
  else
    cap_start()
  end
end

local function mac_export()
  local ok, name = reaper.GetUserInputs("Exporter les rushes", 1, "Nom du fichier :,extrawidth=200", last_export)
  if not ok or trim(name) == "" then return end
  name = trim(name):gsub("[\\/:*?\"<>|]", "_")
  if not name:match("%.%w+$") then name = name .. ".txt" end
  reaper.RecursiveCreateDirectory(MDIR, 0)
  local f = io.open(MDIR .. name, "w")
  if not f then msg = "Ecriture impossible : " .. MDIR .. name; msg_err = true; return end
  f:write(mac_serialize(), "\n"); f:close()
  last_export = name
  msg = "Exporte : " .. name .. "  (" .. #macros .. " macros + disposition Launchpad)"; msg_err = false
end
local function mac_import()
  reaper.RecursiveCreateDirectory(MDIR, 0)
  local ok, file = reaper.GetUserFileNameForRead(MDIR .. last_export, "Importer des rushes", ".txt")
  if not ok then return end
  local f = io.open(file, "r")
  if not f then msg = "Lecture impossible"; msg_err = true; return end
  local txt = f:read("*a"); f:close()
  local list, lay, pages = mac_deserialize(txt)
  if #list == 0 then msg = "Aucun rush dans ce fichier."; msg_err = true; return end
  if #macros > 0 and reaper.MB("Remplacer les " .. #macros .. " macros actuelles (et leur disposition) par les " .. #list .. " du fichier ?", "NowUndo - rushes", 4) ~= 6 then return end
  mac_apply(list, lay, pages); mac_save()
  last_export = file:match("([^/\\]+)$") or last_export
  msg = "Importe : " .. last_export .. "  (" .. #list .. " rushes)"; msg_err = false
end

-- V3.27 : MIDI d'un rush. LEARN (bouton MIDI) = demande au script MIDI Learn ; Ctrl + MIDI = cumul (les autres rushes
-- gardent ce controle) ; sinon un controle = un seul rush. Le MIDI est range dans le rush (m.midi = "status:ch:d1@appareil").
H._midi_txt = function(k)
  local st, ch, d1, dv = (k or ""):match("^(%d+):(%d+):(%d+)@(.*)$")
  if not st then return "" end
  st = tonumber(st)
  return string.format("%s %d ch%d", st == 0xB0 and "CC" or "Note", tonumber(d1), tonumber(ch) + 1) .. (dv ~= "" and (" @" .. dv) or "")
end
H._learn_start = function(add)
  local m = mac_find(mcur)
  if H._learn then
    reaper.SetExtState("NowUndo_MIDILearn", "rush_learn", "", false); H._learn = nil
    msg = "Learn annule."; msg_err = false; return
  end
  if not m then msg = "Selectionne un rush."; msg_err = true; return end
  local hb = tonumber(reaper.GetExtState("NowUndo_MIDILearn", "hb")) or 0
  if reaper.time_precise() - hb > 2 then msg = "Lance le script MIDI Learn : c'est lui qui ecoute le MIDI."; msg_err = true; return end
  H._learn, H._learn_add = m.id, add
  reaper.SetExtState("NowUndo_MIDILearn", "rush_learned", "", false)
  reaper.SetExtState("NowUndo_MIDILearn", "rush_learn", string.format("%d\t%.3f", m.id, reaper.time_precise()), false)
  msg = "LEARN : bouge le controle pour « " .. mac_label(m) .. " »  (Echap ou MIDI = annuler)"; msg_err = false
end
H._learn_poll = function()
  if not H._learn then return end
  local r = reaper.GetExtState("NowUndo_MIDILearn", "rush_learned")
  local id, key, txt = r:match("^(%d+)\t([^\t]*)\t([^\t]*)")
  if not id then return end
  reaper.SetExtState("NowUndo_MIDILearn", "rush_learned", "", false)
  local m = mac_find(tonumber(id))
  H._learn = nil
  if not m then return end
  local stolen = {}
  if not H._learn_add then
    for _, o in ipairs(macros) do
      if o ~= m and o.midi == key then o.midi = ""; stolen[#stolen + 1] = mac_label(o) end
    end
  end
  m.midi = key; mac_save()
  msg = "MIDI appris : « " .. mac_label(m) .. " » ← " .. txt .. (#stolen > 0 and ("   (retire de : " .. table.concat(stolen, ", ") .. ")") or "")
  msg_err = false
end
-- MODELE : choisir / enregistrer / recharger / aucun
H._model_menu = function(x, y)
  local cur = reaper.GetExtState(MAC_EXT, "model")
  local items = { "Choisir un fichier comme modele de demarrage...",
                  (cur ~= "" and "" or "#") .. "Enregistrer l'etat actuel dans le modele" .. (cur ~= "" and (" (" .. cur .. ")") or ""),
                  (cur ~= "" and "" or "#") .. "Recharger le modele maintenant",
                  (cur ~= "" and "" or "!") .. "Aucun modele (reprendre la derniere seance)" }
  gfx.x, gfx.y = x + (H._ox or 0), y
  local k = gfx.showmenu(table.concat(items, "|"))
  if k == 1 then
    reaper.RecursiveCreateDirectory(MDIR, 0)
    local ok, file = reaper.GetUserFileNameForRead(MDIR .. (cur ~= "" and cur or "modele.txt"), "Modele de demarrage des rushes", ".txt")
    if not ok then return end
    local fn = file:match("([^/\\]+)$")
    if not H._read(fn) then msg = "Le modele doit etre dans " .. MDIR; msg_err = true; return end
    reaper.SetExtState(MAC_EXT, "model", fn, true)
    msg = "Modele de demarrage : " .. fn .. "  (charge a chaque lancement ; tes changements ne le reecrivent pas)"; msg_err = false
  elseif k == 2 then
    local f = io.open(MDIR .. cur, "w")
    if f then f:write(mac_serialize(), "\n"); f:close(); msg = "Modele enregistre : " .. cur; msg_err = false
    else msg = "Ecriture impossible : " .. cur; msg_err = true end
  elseif k == 3 then
    local txt = H._read(cur)
    if not txt then msg = "Modele introuvable : " .. cur; msg_err = true; return end
    if reaper.MB("Remplacer les rushes actuels par le modele " .. cur .. " ?", "NowUndo - rushes", 4) ~= 6 then return end
    local list, lay, pages = mac_deserialize(txt)
    mac_apply(list, lay, pages); mac_save(); msg = "Modele recharge : " .. cur; msg_err = false
  elseif k == 4 then
    reaper.SetExtState(MAC_EXT, "model", "", true); msg = "Aucun modele : on reprend la derniere seance."; msg_err = false
  end
end

-- V3.27 : sous-pages de la page 4 (a..z) : ajouter / renommer / supprimer / choisir
H._pg_label = function(k) return string.char(96 + k) .. "  " .. (H._pages[k] or "") end
H._pg_add = function()
  if #H._pages >= H._PMAX then msg = H._PMAX .. " pages maximum (a..z)."; msg_err = true; return end
  local ok, nm = reaper.GetUserInputs("Nouvelle page de rushes", 1, "Nom de la page :,extrawidth=150", "Rushes " .. (#H._pages + 1))
  if not ok then return end
  H._pages[#H._pages + 1] = mac_clean(nm) ~= "" and mac_clean(nm) or ("Rushes " .. (#H._pages + 1))
  H._pg = #H._pages; mac_save()
  msg = "Page 4" .. string.char(96 + H._pg) .. " creee : " .. H._pages[H._pg] .. "  (go 4" .. string.char(96 + H._pg) .. ")"; msg_err = false
end
H._pg_ren = function()
  local ok, nm = reaper.GetUserInputs("Renommer la page", 1, "Nom de la page :,extrawidth=150", H._pages[H._pg])
  if not ok or mac_clean(nm) == "" then return end
  H._pages[H._pg] = mac_clean(nm); mac_save(); msg = "Page renommee."; msg_err = false
end
H._pg_del = function()
  if #H._pages <= 1 then msg = "Il faut garder au moins une page."; msg_err = true; return end
  local k = H._pg
  if reaper.MB("Supprimer la page " .. H._pg_label(k) .. " ? Ses pads sont retires du Launchpad (les rushes restent dans la liste) ; les pages suivantes remontent d'une lettre.", "NowUndo - pages de rushes", 4) ~= 6 then return end
  local nl = {}
  for c, id in pairs(layout) do
    local pg = math.ceil(c / 64)
    if pg < k then nl[c] = id elseif pg > k then nl[c - 64] = id end
  end
  layout = nl
  table.remove(H._pages, k)
  H._pg = math.min(k, #H._pages); mac_save()
  msg = "Page supprimee."; msg_err = false
end
H._pg_menu = function(x, y)
  local items = {}
  for k = 1, #H._pages do items[k] = (k == H._pg and "!" or "") .. H._pg_label(k) end
  gfx.x, gfx.y = x + (H._ox or 0), y
  local pick = gfx.showmenu(table.concat(items, "|"))
  if pick and pick > 0 then H._pg = pick end
end
H._pg_count = function(k) local n = 0; for c in pairs(layout) do if math.ceil(c / 64) == k then n = n + 1 end end; return n end

local function mac_status()
  return string.format("%d/%d rushes | %d sur le LP%s", #macros, MAC_MAX, lp_count(), msel and (sel_count() > 0 and (" | " .. sel_count() .. " sel.") or "") or "")
end
local function set_tab(t)
  if capturing then msg = "Termine la capture avant de changer d'onglet."; msg_err = true; return end
  tab = t; drag = nil; show_help = false
end

-- glisser des macros hors de la fenetre : sur le Launchpad. Si l'extension JS_ReaScriptAPI est installee,
-- on verifie que le curseur est bien au-dessus d'une fenetre "Virtual Launchpad" ; sinon n'importe quel endroit hors de cette fenetre.
local function drag_macros(d)
  if msel[d.id] then return sel_ids() end
  local m = mac_find(d.id)
  return m and { m } or {}
end
local function mac_drop_outside(d)
  -- le depot est confie au Launchpad : on lui envoie les macros + la position ECRAN du curseur ; il les pose sur la case
  -- relachee (ou a la suite si le curseur est sur sa fenetre mais pas sur un pad ; rien si le curseur est hors de sa fenetre)
  local ms = drag_macros(d)
  if #ms == 0 then return end
  local ids = {}
  for _, m in ipairs(ms) do ids[#ids + 1] = tostring(m.id) end
  local x, y = reaper.GetMousePosition()
  reaper.SetExtState(MAC_EXT, "drop", string.format("%s\t%d\t%d\t%.3f", table.concat(ids, ","), x, y, reaper.time_precise()), false)
  msg = #ms .. " rush(es) envoye(s) au Launchpad..."; msg_err = false
  H._dropchk = { id = ms[1].id, t = reaper.time_precise() }        -- verifie 1,5 s plus tard que le Launchpad l'a bien pose
end

local function mac_key(c)
  -- Ctrl + lettre : selon le systeme, gfx.getchar renvoie le code de controle (3) OU la lettre (99) ; on normalise
  -- d'apres Ctrl reellement tenu, sinon Ctrl+C lancait la CAPTURE (touche C) au lieu de copier.
  if (gfx.mouse_cap & 4) ~= 0 and c > 0 then
    local CTRL = { [99] = 3, [67] = 3, [120] = 24, [88] = 24, [118] = 22, [86] = 22, [100] = 4, [68] = 4, [97] = 1, [65] = 1 }
    if CTRL[c] then c = CTRL[c]
    elseif c ~= 3 and c ~= 24 and c ~= 22 and c ~= 4 and c ~= 1 then return end   -- autre Ctrl+touche : ignore
  end
  if c == 3 or c == 24 or c == 22 or c == 4 then                          -- une seule voie par appui (getchar / lecture directe)
    if reaper.time_precise() - (ED.vk_t or 0) < 0.3 then return end
    ED.ck_t = reaper.time_precise()
  end
  if c == 63 or c == 104 or c == 72 then show_help = true; help_scroll = 0; return end
  if c == 99 or c == 67 then mac_capture_toggle(); return end
  if capturing then
    if c == 13 then cap_finalize()
    elseif c == 8 then cap_reset_line(); msg = "Ligne annulee."; msg_err = false end
    return
  end
  if c == 6579564 or c == 127 or c == 8 then mac_delete()                 -- Suppr / Delete / Retour arriere (Mac) : supprime la selection
  elseif c == 13 or c == 32 then mac_test()
  elseif c == 101 then mac_edit()                                          -- E : editeur (assistant + palette)
  elseif c == 69 then                                                      -- Maj+E : boite REAPER a l'ancienne
    local m = mac_find(mcur)
    if not m then msg = "Selectionne un rush."; msg_err = true
    elseif H._ro({ m }) then
    else
      local t = ED.classic(m.text)
      if t then
        m.text = mac_clean(t:gsub(";", ",")); mac_check(m); mac_save()
        msg = m.err and ("Rush invalide : " .. m.err) or "Rush modifie."; msg_err = m.err ~= nil
      end
    end
  elseif c == 110 or c == 78 then mac_rename()
  elseif c == 103 or c == 71 then                                          -- G : mode GATE de la selection
    local ms = sel_ids()
    if H._ro(ms) then return end
    if #ms == 0 then msg = "Selectionne un ou plusieurs rushes."; msg_err = true
    else
      local nv = not ms[1].gate
      for _, o in ipairs(ms) do o.gate = nv end
      mac_save(); msg = nv and "Mode GATE actif (appui/relachement sur le Launchpad)." or "Mode GATE retire."; msg_err = false
    end
  elseif c == 97 or c == 65 then                                           -- A : mode ALL de la selection
    local ms = sel_ids()
    if H._ro(ms) then return end
    if #ms > 0 then
      local nv = not ms[1].all
      for _, o in ipairs(ms) do o.all = nv end
      mac_save(); msg = nv and "Mode ALL actif (8 loopers)." or "Mode ALL retire."; msg_err = false
    end
  elseif c == 116 or c == 84 then                                          -- T : mode toggle de la selection
    local ms = sel_ids()
    if H._ro(ms) then return end
    if #ms > 0 then
      local nv = not ms[1].toggle
      for _, o in ipairs(ms) do o.toggle = nv; mac_check(o) end
      mac_save(); msg = nv and "Mode TOGGLE actif." or "Mode TOGGLE retire."; msg_err = false
    end
  elseif c == 3 then ED.mcopy()                                           -- Ctrl+C : copier
  elseif c == 24 then ED.mcut()                                            -- Ctrl+X : couper
  elseif c == 22 then ED.mpaste()                                          -- Ctrl+V : coller (apres la selection)
  elseif c == 4 then ED.mdup()                                             -- Ctrl+D : dupliquer
  elseif c == 1 then for _, k in ipairs(H._view()) do msel[macros[k].id] = true end   -- Ctrl+A (rushes affiches par le filtre)
  elseif c == 30064 or c == 1685026670 then
    local V = H._view()                                                    -- V3.27 : on se deplace dans la liste filtree
    local _, i = mac_find(mcur)
    local vp = (i and H._vpos[i]) or 0
    local nv = math.max(1, math.min(#V, vp + (c == 30064 and -1 or 1)))
    local ni = V[nv]
    if ni and macros[ni] then
      local id = macros[ni].id
      if (gfx.mouse_cap & 8) ~= 0 then
        local _, a = mac_find(manchor); a = (a and H._vpos[a]) or nv
        msel = {}
        for k = math.min(a, nv), math.max(a, nv) do msel[macros[V[k]].id] = true end
      else msel = { [id] = true }; manchor = id end
      mcur = id; mwant = true
    end
  end
end

-- V3.27 : FILTRE de la liste des rushes (demande de l'utilisateur) : H._flt.pg = nil (toutes les pages) | 0 (pas poses sur
-- le Launchpad) | k (poses sur la sous-page 4k) ; H._flt.tg = nil | "tgt" (cible ecrite : l1, g2, in1...) | "all" | "none"
-- (sans cible = looper / groupe selectionne). H._view() = indices des rushes affiches, H._vpos[i] = leur rang dans la vue.
H._flt, H._tcl, H._vpos = {}, {}, {}
H._tclass = function(m)
  if m.all then return "all" end
  local c = H._tcl[m.text]; if c then return c end
  c = "none"
  local s = H._norm(m.text):lower():gsub("//.*$", ""):gsub("à", " "):gsub("[=:]", " ")
  for act in (s .. ","):gmatch("([^,]*),") do
    act = trim(act):gsub("%s*%*%s*[%d%./]*$", "")
    local tgs = act:match("^(.-)%s*%f[%a]to%s+g%s*%(?%s*%d+%s*%)?$")      -- l3 to g2
    local w = (tgs or act:match("^%S+") or ""):gsub("%s+", "")
    if w ~= "" and not act:match("^go%f[%A]") and not act:match("^[rg]%s*%(%s*%d+%s*%)$") and is_tgt(w) then
      if w == "all" or w == "tous" or w == "*" then c = "all"; break end
      c = "tgt"
    end
  end
  H._tcl[m.text] = c
  return c
end
H._view = function()
  local f, V, P, pc = H._flt, {}, {}, nil
  if f.pg then pc = {}; for cell, id in pairs(layout) do pc[id] = math.ceil(cell / 64) end end
  for i, m in ipairs(macros) do
    local ok = true
    if f.pg then local p = pc[m.id]; if f.pg == 0 then ok = (p == nil) else ok = (p == f.pg) end end
    if ok and f.tg then ok = (H._tclass(m) == f.tg) end
    if ok then V[#V + 1] = i; P[i] = #V end
  end
  H._vpos = P
  return V
end
H._TGN = { tgt = "cibles", all = "all", none = "non cibles" }
H._flt_txt = function()
  local f, t = H._flt, {}
  if f.pg == 0 then t[#t + 1] = "pas poses" elseif f.pg then t[#t + 1] = "page 4" .. string.char(96 + f.pg) end
  if f.tg then t[#t + 1] = H._TGN[f.tg] end
  return table.concat(t, ", ")
end
H._flt_menu = function(x, y)
  local f, np = H._flt, #H._pages
  local it = { "Tout afficher", "", ">Page du Launchpad", (f.pg == nil and "!" or "") .. "Toutes les pages",
               (f.pg == 0 and "!" or "") .. "Pas poses sur le Launchpad", "" }
  for k = 1, np do
    it[#it + 1] = ((k == np) and "<" or "") .. ((f.pg == k) and "!" or "") .. "4" .. H._pg_label(k) .. "   (" .. H._pg_count(k) .. ")"
  end
  it[#it + 1] = ">Cible"
  it[#it + 1] = (f.tg == nil and "!" or "") .. "Toutes"
  it[#it + 1] = (f.tg == "tgt" and "!" or "") .. "Cibles  (l1, l2/l3, g2, in1 ...)"
  it[#it + 1] = (f.tg == "all" and "!" or "") .. "All  (les 8 loopers)"
  it[#it + 1] = "<" .. (f.tg == "none" and "!" or "") .. "Non cibles  (= looper / groupe selectionne)"
  gfx.x, gfx.y = x + (H._ox or 0), y
  local k = gfx.showmenu(table.concat(it, "|"))
  if k <= 0 then return end
  if k == 1 then H._flt = {}
  elseif k == 2 then f.pg = nil elseif k == 3 then f.pg = 0
  elseif k <= 3 + np then f.pg = k - 3
  else
    local tg = ({ false, "tgt", "all", "none" })[k - 3 - np]
    f.tg = tg or nil
  end
  H._lp = 1; mscroll = 0
end
-- clic sur "LP c1.3" d'un rush : la page 4 du Launchpad affiche cette sous-page, et les boutons du bas la gerent
H._show_pg = function(cell)
  local k = math.ceil(cell / 64)
  H._pg = k
  fire_glob({ qname = "p4page_" .. k })
  msg = "Launchpad : page 4" .. string.char(96 + k) .. " (" .. (H._pages[k] or "") .. ") affichee, rush en " .. lp_name(cell) .. "."; msg_err = false
end

local MPC = 32                                         -- macros par colonne : la 33e repart en haut de la 2e colonne
local mflash = {}
local function mac_draw(W, Hh, down)
  -- V3.27 : mise en page par groupes. En haut : la liste (pages de la liste) et les actions principales (CAPTURE, NOUVEAU,
  -- EDIT) ; au milieu : la liste ; en bas, sous titres : rush selectionne | fichier, puis la page 4 du Launchpad.
  local LY = LIST_Y + 30
  if H._dropchk and reaper.time_precise() - H._dropchk.t > 1.5 then
    local c = lp_cell_of(H._dropchk.id); H._dropchk = nil
    if c then msg = "Rush pose sur le Launchpad en " .. lp_name(c) .. "."; msg_err = false
    else msg = "Le Launchpad n'a pas pris le rush : relache-le sur sa fenetre (page 4, sous-page non pleine)."; msg_err = true end
  end
  local list_h = Hh - LY - (capturing and 162 or 140)
  local rows = math.max(1, math.min(MPC, math.floor(list_h / RH)))
  local NC = (W >= 760) and 2 or 1                     -- V3.27 : une seule colonne si le panneau est etroit
  local PG = NC * MPC
  local cw = math.floor((W - 24 - 6 * (NC - 1)) / NC)
  local function colx(c) return 12 + c * (cw + 6) end
  -- pages de la LISTE : NC colonnes de 32 rushes ; H._lp = page affichee
  local V = H._view()                                  -- V3.27 : rushes affiches (filtre page / cible)
  local NV = #V
  local npg = math.max(1, math.ceil(NV / PG))
  H._lp = math.max(1, math.min(npg, H._lp or 1))
  local base = (H._lp - 1) * PG
  local function idx_at(px, py)                        -- macro sous la souris (liste a 2 colonnes) : indice dans macros
    if py < LY or py >= LY + rows * RH then return nil end
    local c
    if px >= colx(0) and px < colx(0) + cw then c = 0 elseif NC > 1 and px >= colx(1) and px < colx(1) + cw then c = 1 else return nil end
    return V[base + c * MPC + mscroll + math.floor((py - LY) / RH) + 1]
  end
  -- clic droit sur une ligne : menu Copier / Couper / Coller / Dupliquer / Supprimer / Editer / Renommer
  local rdn = (gfx.mouse_cap & 2) == 2
  if rdn and not ED.mrwas and not ED.on and not show_help and not capturing then
    local ri = idx_at(mx, my)
    if ri then
      local rm = macros[ri]
      if not msel[rm.id] then msel = { [rm.id] = true }; mcur = rm.id; manchor = rm.id end
    end
    gfx.x, gfx.y = mx + (H._ox or 0), my
    local items = { ri and "Copier  (Ctrl+C)" or "#Copier  (Ctrl+C)", ri and "Couper  (Ctrl+X)" or "#Couper  (Ctrl+X)",
                    (H._mclip and #H._mclip > 0) and "Coller  (Ctrl+V)" or "#Coller  (Ctrl+V)",
                    ri and "Dupliquer  (Ctrl+D)" or "#Dupliquer  (Ctrl+D)", "",
                    ri and "Supprimer  (Suppr)" or "#Supprimer  (Suppr)", "",
                    ri and "Editer  (E)" or "#Editer  (E)", ri and "Renommer  (N)" or "#Renommer  (N)", "",
                    ri and "MIDI Learn de ce rush" or "#MIDI Learn de ce rush",
                    (ri and (macros[ri].midi or "") ~= "") and ("Oublier le MIDI (" .. H._midi_txt(macros[ri].midi) .. ")") or "#Oublier le MIDI" }
    local k = gfx.showmenu(table.concat(items, "|"))
    if k == 1 then ED.mcopy() elseif k == 2 then ED.mcut() elseif k == 3 then ED.mpaste()
    elseif k == 4 then ED.mdup() elseif k == 5 then mac_delete() elseif k == 6 then mac_edit() elseif k == 7 then mac_rename()
    elseif k == 8 then H._learn = nil; H._learn_start(false)
    elseif k == 9 and ri then macros[ri].midi = ""; mac_save(); msg = "MIDI oublie."; msg_err = false end
  end
  ED.mrwas = rdn
  local _, ci = mac_find(mcur)
  if mwant then
    ci = ci and H._vpos[ci]                                          -- rang dans la liste filtree (nil = cache par le filtre)
    if ci then
      local lp = math.ceil(ci / PG)                                  -- rush sur une autre page de la liste : on y va
      if lp ~= H._lp then H._lp = lp; base = (lp - 1) * PG; mscroll = 0 end
      local r = (ci - 1 - base) % MPC + 1
      if r - 1 < mscroll then mscroll = r - 1 end
      if r > mscroll + rows then mscroll = r - rows end
    end
    mwant = false
  end
  local wheel = gfx.mouse_wheel
  if wheel ~= 0 and not show_help then
    mscroll = mscroll - (wheel > 0 and 1 or -1) * 2
    gfx.mouse_wheel = 0
  end
  mscroll = math.max(0, math.min(math.max(0, math.min(MPC, NV - base) - rows), mscroll))
  do                                                               -- en-tete de la liste
    local hy = LIST_Y + 2
    gfx.setfont(2, "Arial", 12, 'b')
    local function go_lp(k) H._lp = (H._lp - 1 + k) % npg + 1; mscroll = 0 end
    local a1, a2 = base + 1, math.min(NV, base + PG)
    if btn(12, hy, 26, 22, "<", 0.20, 0.25, 0.35) and npg > 1 then go_lp(-1) end
    gfx.set(1, 1, 1, 0.85); gfx.x, gfx.y = 46, hy + 5
    gfx.drawstr(NV == 0 and "RUSHES : aucun" or string.format("RUSHES %d-%d sur %d", a1, a2, NV))
    local tx = gfx.x + 8
    if btn(tx, hy, 26, 22, ">", 0.20, 0.25, 0.35) and npg > 1 then go_lp(1) end
    tx = tx + 34                                                   -- V3.27 : FILTRE (page du Launchpad / cible)
    local ft = H._flt_txt()
    local flbl = ft == "" and "FILTRE  v" or ("FILTRE : " .. ft .. "  v")
    local fw = math.min(230, gfx.measurestr(flbl) + 20)
    if btn(tx, hy, fw, 22, flbl, ft == "" and 0.20 or 0.15, ft == "" and 0.25 or 0.40, ft == "" and 0.35 or 0.55) then H._flt_menu(tx, hy + 22) end
    tx = tx + fw + 4
    if ft ~= "" then
      if btn(tx, hy, 22, 22, "×", 0.35, 0.18, 0.18) then H._flt = {}; H._lp = 1; mscroll = 0 end
      tx = tx + 26
    end
    local bw3 = math.min(120, math.floor((W - 24 - (tx - 12) - 8) / 3))
    local x3 = W - 12 - 3 * bw3 - 8
    if btn(x3, hy, bw3, 22, capturing and "■ VALIDER" or "● CAPTURE RUSH", 0.55, 0.15, 0.15) then mac_capture_toggle() end
    if not capturing then
      if btn(x3 + bw3 + 4, hy, bw3, 22, "+ NOUVEAU", 0.15, 0.40, 0.25) then mac_new() end
      if btn(x3 + 2 * (bw3 + 4), hy, bw3, 22, "EDIT", 0.20, 0.25, 0.35) then mac_edit() end
    end
  end
  local cap_mod = gfx.mouse_cap
  local ctrl = (cap_mod & 4) ~= 0 or (OSX and (cap_mod & 32) ~= 0)
  local shift = (cap_mod & 8) ~= 0

  gfx.set(0.10, 0.03, 0.04, 1)
  for c = 0, NC - 1 do gfx.rect(colx(c), LY, cw, rows * RH) end
  if #macros == 0 then
    gfx.setfont(2, "Arial", 13); gfx.set(1, 1, 1, 0.45)
    gfx.x, gfx.y = 24, LY + 10
    gfx.drawstr("Aucun rush : ● CAPTURE (fais l'action puis VALIDER) ou ADD (ecris la syntaxe, sans looper).")
  elseif NV == 0 then
    gfx.setfont(2, "Arial", 13); gfx.set(1, 1, 1, 0.45)
    gfx.x, gfx.y = 24, LY + 10
    gfx.drawstr("Aucun rush pour ce filtre (" .. H._flt_txt() .. ").  × a cote de FILTRE = tout afficher.")
  end
  local now_t = reaper.time_precise()
  for c = 0, NC - 1 do
    local x0 = colx(c)
    for r = 1, rows do
      local vi = base + c * MPC + mscroll + r
      local i = V[vi]
      local m = i and macros[i]
      if m then
        local y = LY + (r - 1) * RH
        if msel[m.id] then gfx.set(0.40, 0.28, 0.08, 1); gfx.rect(x0, y, cw, RH)
        elseif m.rom then gfx.set(0.09, 0.08, 0.12, 1); gfx.rect(x0, y, cw, RH)     -- usine : fond gris-bleu
        elseif r % 2 == 0 then gfx.set(0.13, 0.05, 0.06, 1); gfx.rect(x0, y, cw, RH) end
        if m.id == mcur then gfx.set(0.9, 0.8, 0.2, 0.9); gfx.rect(x0, y, cw, RH, 0) end
        if H._pend and H._pend[m.id] and math.floor(reaper.time_precise() * 4) % 2 == 0 then   -- en attente du point de synchro : clignote
          gfx.set(0.3, 0.6, 1, 0.35); gfx.rect(x0, y, cw, RH)
        end
        gfx.setfont(2, "Arial", 12)
        gfx.set(1, 1, 1, 0.55); gfx.x, gfx.y = x0 + 4, y + 5
        gfx.drawstr(string.format("%02d", i))
        gfx.set(((m.color >> 16) & 255) / 255, ((m.color >> 8) & 255) / 255, (m.color & 255) / 255, 1)
        gfx.rect(x0 + 26, y + 3, 14, RH - 6)
        gfx.set(1, 1, 1, 0.35); gfx.rect(x0 + 26, y + 3, 14, RH - 6, 0)
        if m.toggle then gfx.set(0.10, 0.60, 0.70, 1) else gfx.set(0.20, 0.20, 0.25, 1) end
        gfx.rect(x0 + 44, y + 3, 18, RH - 6)
        gfx.set(1, 1, 1, 0.30); gfx.rect(x0 + 44, y + 3, 18, RH - 6, 0)
        gfx.setfont(2, "Arial", 12, 'b')
        if m.toggle then gfx.set(1, 1, 1, 1) else gfx.set(1, 1, 1, 0.35) end
        gfx.x, gfx.y = x0 + 49, y + 5; gfx.drawstr("T")
        if m.gate then gfx.set(0.55, 0.30, 0.70, 1) else gfx.set(0.20, 0.20, 0.25, 1) end      -- case G : mode GATE (appui/relachement)
        gfx.rect(x0 + 64, y + 3, 18, RH - 6)
        gfx.set(1, 1, 1, 0.30); gfx.rect(x0 + 64, y + 3, 18, RH - 6, 0)
        gfx.setfont(2, "Arial", 12, 'b')
        if m.gate then gfx.set(1, 1, 1, 1) else gfx.set(1, 1, 1, 0.35) end
        gfx.x, gfx.y = x0 + 69, y + 5; gfx.drawstr("G")
        if m.all then gfx.set(0.75, 0.45, 0.10, 1) else gfx.set(0.20, 0.20, 0.25, 1) end      -- case A : mode ALL (les 8 loopers)
        gfx.rect(x0 + 84, y + 3, 18, RH - 6)
        gfx.set(1, 1, 1, 0.30); gfx.rect(x0 + 84, y + 3, 18, RH - 6, 0)
        gfx.setfont(2, "Arial", 12, 'b')
        if m.all then gfx.set(1, 1, 1, 1) else gfx.set(1, 1, 1, 0.35) end
        gfx.x, gfx.y = x0 + 89, y + 5; gfx.drawstr("A")
        -- triangle de lecture : lance cette macro sur le looper / groupe selectionne
        local px = x0 + 106
        local hov = mx >= px and mx < px + 20 and my >= y and my < y + RH
        local fl = (mflash[m.id] or 0) > now_t
        if fl then gfx.set(0.35, 0.85, 0.45, 1) elseif hov then gfx.set(0.20, 0.60, 0.30, 1) else gfx.set(0.14, 0.34, 0.20, 1) end
        gfx.rect(px, y + 3, 20, RH - 6)
        gfx.set(1, 1, 1, fl and 1 or 0.9)
        gfx.triangle(px + 6, y + 6, px + 6, y + RH - 6, px + 15, y + RH / 2)
        -- nom (la macro porte son propre label) ; erreur = rouge
        gfx.setfont(2, "Arial", 13, 'b')
        if m.err then gfx.set(1, 0.35, 0.35, 1)
        elseif (m.name or "") == "" or m.name:match("^Macro %d+$") then gfx.set(1, 1, 1, 0.65) else gfx.set(1, 1, 1, 0.97) end
        gfx.x, gfx.y = x0 + 132, y + 5
        gfx.drawstr(fit(mac_label(m), cw - 132 - 104))
        if (m.midi or "") ~= "" or H._learn == m.id then                 -- V3.27 : rush appris en MIDI
          gfx.setfont(2, "Arial", 11, 'b')
          if H._learn == m.id then gfx.set(1, 0.45, 0.2, (now_t * 3) % 1 < 0.5 and 1 or 0.3) else gfx.set(1, 0.55, 0.95, 1) end
          gfx.x, gfx.y = x0 + cw - 100, y + 6
          gfx.drawstr("MIDI")
        end
        -- case de destination sur le Launchpad (ex. 3.5) a la place de l'ancien label secondaire
        local lc = lp_cell_of(m.id)
        local lph = lc and mx >= x0 + cw - 84 and mx < x0 + cw - 22 and my >= y and my < y + RH
        if lc then                                                     -- V3.27 : clic = affiche cette page sur le Launchpad
          gfx.setfont(2, "Arial", 11, 'b')
          if lph then gfx.set(0.2, 0.45, 0.55, 1); gfx.rect(x0 + cw - 84, y + 3, 62, RH - 6) end
          gfx.set(0.4, 0.9, 1, 1)
          gfx.x, gfx.y = x0 + cw - 82, y + 6
          gfx.drawstr("LP " .. lp_name(lc))
        end
        -- suppression de cette macro
        local dx = x0 + cw - 20
        local dh = mx >= dx and mx < dx + 16 and my >= y and my < y + RH
        if m.rom then                                                   -- usine : pas de croix, etiquette ROM
          gfx.setfont(2, "Arial", 10, 'b'); gfx.set(0.6, 0.7, 1, 0.7); gfx.x, gfx.y = dx - 6, y + 7; gfx.drawstr("ROM")
        else
          gfx.setfont(2, "Arial", 14, 'b')
          if dh then gfx.set(1, 0.4, 0.4, 1) else gfx.set(1, 1, 1, 0.35) end
          gfx.x, gfx.y = dx + 3, y + 4; gfx.drawstr("×")
        end

        if click and mx >= x0 and mx < x0 + cw and my >= y and my < y + RH then
          local t = reaper.time_precise()
          if mx >= x0 + 26 and mx < x0 + 102 and H._ro(msel[m.id] and sel_ids() or { m }) then
            -- rush d'usine : couleur / T / G / A verrouilles (message affiche par H._ro)
          elseif mx >= x0 + 26 and mx < x0 + 40 then                     -- pastille : couleur suivante de la palette
            local k = 0
            for q, col in ipairs(PALETTE) do if col == m.color then k = q end end
            m.color = PALETTE[k % #PALETTE + 1]; mac_save()
          elseif mx >= x0 + 44 and mx < x0 + 62 then                     -- case T : mode toggle (toute la selection si la macro en fait partie)
            local nv = not m.toggle
            if msel[m.id] then for _, o in ipairs(sel_ids()) do o.toggle = nv; mac_check(o) end else m.toggle = nv; mac_check(m) end
            mac_save()
            msg = nv and "Mode TOGGLE : on/off s'inversent, les valeurs basculent enregistree <-> defaut." or "Mode TOGGLE retire."; msg_err = false
          elseif mx >= x0 + 64 and mx < x0 + 82 then                     -- case G : mode GATE
            local nv = not m.gate
            if msel[m.id] then for _, o in ipairs(sel_ids()) do o.gate = nv end else m.gate = nv end
            mac_save()
            msg = nv and "Mode GATE : le pad Launchpad active a l'appui et desactive au relachement." or "Mode GATE retire."; msg_err = false
          elseif mx >= x0 + 84 and mx < x0 + 102 then                    -- case A : mode ALL
            local nv = not m.all
            if msel[m.id] then for _, o in ipairs(sel_ids()) do o.all = nv end else m.all = nv end
            mac_save()
            msg = nv and "Mode ALL : le rush s'applique aux 8 loopers, pas seulement au looper selectionne." or "Mode ALL retire."; msg_err = false
          elseif mx >= px and mx < px + 20 then                          -- ▶ : lecture de CETTE macro
            mflash[m.id] = now_t + 0.25
            mcur = m.id
            run_macro(m, sel_targets())
          elseif mx >= dx and mx < dx + 16 then                          -- × : supprimer cette macro
            if not H._ro({ m }) and reaper.MB("Supprimer le rush '" .. mac_label(m) .. "' ?", "NowUndo - rushes", 4) == 6 then
              msel = { [m.id] = true }; mcur = m.id; mac_delete()
            end
          elseif lph then                                                -- LP c1.3 : affiche la sous-page sur le Launchpad
            mcur = m.id; msel = { [m.id] = true }; H._show_pg(lc)
          elseif mac_last_click_id == m.id and t - mac_last_click_t < 0.35 then
            mcur = m.id; msel = { [m.id] = true }; drag = nil; mac_edit()
          else
            if shift then
              local _, a = mac_find(manchor); a = (a and H._vpos[a]) or vi
              if not ctrl then msel = {} end
              for k = math.min(a, vi), math.max(a, vi) do msel[macros[V[k]].id] = true end
              mcur = m.id
            elseif ctrl then
              if msel[m.id] then msel[m.id] = nil else msel[m.id] = true end
              mcur = m.id; manchor = m.id
            else
              local collapse = msel[m.id] and sel_count() > 1
              if not msel[m.id] then msel = { [m.id] = true } end       -- une selection multiple se garde pour pouvoir la glisser
              mcur = m.id; manchor = m.id
              if not capturing then
                drag = { kind = "mac", id = m.id, x = mx, y = my, active = false, collapse = collapse, label = mac_label(m) }
              elseif collapse then msel = { [m.id] = true } end
            end
          end
          mac_last_click_id, mac_last_click_t = m.id, t
        end
      end
    end
  end

  -- glisser : hors fenetre = vers le Launchpad ; sur un autre rush = reordonner
  local over = nil
  if drag and drag.kind == "mac" then
    if down then
      if not drag.active and (math.abs(mx - drag.x) + math.abs(my - drag.y)) > 10 then
        drag.active = true
        local n = msel[drag.id] and sel_count() or 1
        drag.label = n > 1 and (drag.label .. "  +" .. (n - 1)) or drag.label
        msg = "Relache sur le Launchpad (hors de cette fenetre) ou sur un autre rush pour reordonner."; msg_err = false
      end
      if drag.active then over = idx_at(mx, my) end
    else
      if drag.active then
        if mx < 0 and mx + (H._ox or 0) >= 0 and my >= LY and my <= Hh then H._to_scn(drag_macros(drag), my)   -- sur le scenario
        elseif mx < 0 or my < 0 or mx > W or my > Hh then mac_drop_outside(drag)
        else
          local to = idx_at(mx, my)
          if to then
            local set = {}
            for _, m in ipairs(drag_macros(drag)) do set[m.id] = true end
            if next(set) then mac_move_sel(set, to) end
          end
        end
      elseif drag.collapse then msel = { [drag.id] = true } end
      drag = nil
    end
  end
  if over then
    local ov = H._vpos[over] or 1
    local oc, orow = math.floor((ov - 1 - base) / MPC), (ov - 1 - base) % MPC - mscroll
    gfx.set(1, 1, 1, 0.9); gfx.rect(colx(oc), LY + orow * RH, cw, RH, 0)
  end

  -- message
  local my0 = Hh - (capturing and 156 or 134)
  gfx.setfont(2, "Arial", 12)
  if msg_err then gfx.set(1, 0.4, 0.4, 1) else gfx.set(0.6, 0.9, 0.6, 1) end
  gfx.x, gfx.y = 14, my0
  gfx.drawstr(fit(msg, W - 28))
  local cm = mac_find(mcur)
  if cm and cm.err then
    gfx.set(1, 0.4, 0.4, 1); gfx.x, gfx.y = 14, my0 + 16
    gfx.drawstr(fit("Rush '" .. mac_label(cm) .. "' : " .. cm.err, W - 28))
  elseif cm then
    gfx.set(1, 1, 1, 0.55); gfx.x, gfx.y = 14, my0 + 16
    gfx.drawstr(fit("Action : " .. cm.text .. (cm.toggle and "   [toggle]" or "") .. (cm.gate and "   [gate]" or "") .. (cm.all and "   [all]" or "")
      .. ((cm.midi or "") ~= "" and ("   MIDI : " .. H._midi_txt(cm.midi)) or ""), W - 28))
  end

  -- boutons
  if capturing then -- panneau de capture : dessine par main, sur toute la largeur
  else
    local function title(x, y, t) gfx.setfont(2, "Arial", 10, 'b'); gfx.set(1, 1, 1, 0.45); gfx.x, gfx.y = x, y; gfx.drawstr(t) end
    -- rangee 1 : RUSH SELECTIONNE (5 boutons) | FICHIER (3 boutons)
    local y1 = Hh - 76
    local bw = math.floor((W - 24 - 7 * 4 - 12) / 8)
    local function bx(k) return 12 + (k - 1) * (bw + 4) + (k > 5 and 12 or 0) end
    title(bx(1), y1 - 14, "RUSH SELECTIONNE"); title(bx(6), y1 - 14, "FICHIER")
    gfx.setfont(2, "Arial", 12, 'b')
    local labels = { "NOM", "COULEUR", H._learn and "MIDI ..." or "MIDI", "▲", "▼", "EXPORT", "IMPORT",
                     reaper.GetExtState(MAC_EXT, "model") ~= "" and "MODELE ✓" or "MODELE" }
    local fns = { mac_rename, mac_recolor, function() H._learn_start(ctrl) end, function() mac_move(-1) end, function() mac_move(1) end,
                  mac_export, mac_import, function() H._model_menu(bx(8), y1 + 22) end }
    for k = 1, 8 do
      if btn(bx(k), y1, bw, 22, labels[k], (k == 3 and H._learn) and 0.75 or 0.20, 0.25, 0.35) then fns[k]() end
    end
    -- rangee 2 : LAUNCHPAD PAGE 4 (la sous-page geree + ses boutons)
    local y2 = Hh - 30
    title(12, y2 - 14, "LAUNCHPAD PAGE 4 : sous-page geree par ces boutons")
    gfx.setfont(2, "Arial", 12, 'b')
    local pw = 22
    local plbl = "4" .. H._pg_label(H._pg) .. "  (" .. H._pg_count(H._pg) .. "/64)  v"
    local bwp = math.min(220, gfx.measurestr(plbl) + 20)
    if btn(12, y2, pw, 22, "<", 0.20, 0.25, 0.35) then H._pg = (H._pg - 2) % #H._pages + 1 end
    if btn(12 + pw + 4, y2, bwp, 22, plbl, 0.20, 0.25, 0.35) then H._pg_menu(12 + pw + 4, y2 + 22) end
    local xx = 12 + pw + 4 + bwp + 4
    if btn(xx, y2, pw, 22, ">", 0.20, 0.25, 0.35) then H._pg = H._pg % #H._pages + 1 end
    xx = xx + pw + 10
    local wb = math.floor((W - 12 - xx - 4 * 4) / 5)
    local function px(k) return xx + (k - 1) * (wb + 4) end
    if btn(px(1), y2, wb, 22, "+ PAGE", 0.15, 0.40, 0.25) then H._pg_add() end
    if btn(px(2), y2, wb, 22, "RENOMMER", 0.20, 0.25, 0.35) then H._pg_ren() end
    if btn(px(3), y2, wb, 22, "SUPPRIMER", 0.45, 0.15, 0.15) then H._pg_del() end
    if btn(px(4), y2, wb, 22, "VIDER", 0.45, 0.15, 0.15) then
      local n = H._pg_count(H._pg)
      if n > 0 and reaper.MB("Retirer les " .. n .. " rushes de la page " .. H._pg_label(H._pg) .. " ? (ils restent dans la liste)", "NowUndo - rushes", 4) == 6 then
        for c in pairs(layout) do if math.ceil(c / 64) == H._pg then layout[c] = nil end end
        mac_save(); msg = "Page videe."; msg_err = false
      end
    end
    if btn(px(5), y2, wb, 22, "RETIRER SEL.", 0.35, 0.22, 0.15) then
      local ms = sel_ids()
      if #ms == 0 then msg = "Selectionne un ou plusieurs rushes."; msg_err = true else lp_remove(ms) end
    end
  end
end

local STC = { [0] = { .25, .25, .28 }, [1] = { .9, .15, .15 }, [2] = { .2, .7, .3 }, [3] = { .95, .55, .1 },
  [4] = { .3, .6, .9 }, [5] = { .6, .4, .9 }, [6] = { .3, .8, .8 }, [7] = { .95, .85, .2 }, [8] = { .95, .85, .2 } }

-- V3.27 : PANNEAU SCENARIO (a gauche) : la liste des pas (un pas = un rush), GO / BACK / BOUCLE, le pas selectionne,
-- capture / timeline, fichier. On y ajoute des rushes en les glissant depuis la liste de droite (ou + SELECTION).
H._to_scn = function(ms, wy)
  if #ms == 0 then return end
  local g = H._sgeo
  local at = (#steps == 0) and 0 or cur
  if g and wy >= g.ly and wy < g.ly + g.rows * RH then
    at = math.min(#steps, g.scroll + math.floor((wy - g.ly) / RH))      -- depose AVANT la ligne visee
  end
  for k, m in ipairs(ms) do table.insert(steps, at + k, "@" .. m.id) end
  cur = at + 1; reparse_all(); want_visible = true
  msg = #ms .. " rush(es) ajoute(s) au scenario (pas " .. (at + 1) .. ")."; msg_err = false
end
H._step_edit = function()
  local id = tonumber((steps[cur] or ""):match("^@(%d+)$") or "")
  local m = id and mac_find(id)
  if not m then msg = "Ce pas pointe vers un rush supprime : retire-le (RETIRER)."; msg_err = true; return end
  msel = { [m.id] = true }; mcur = m.id; manchor = m.id; mwant = true
  mac_edit()
end
H._scn_draw = function(SW, Hh, down)
  local function title(x, y, t) gfx.setfont(2, "Arial", 10, 'b'); gfx.set(1, 1, 1, 0.45); gfx.x, gfx.y = x, y; gfx.drawstr(t) end
  local LY = LIST_Y + 30
  local hy = LIST_Y + 2
  gfx.setfont(2, "Arial", 13, 'b'); gfx.set(1, 1, 1, 0.9); gfx.x, gfx.y = 12, hy + 4
  gfx.drawstr("SCENARIO")
  gfx.setfont(2, "Arial", 11); gfx.set(1, 1, 1, 0.5); gfx.x = gfx.x + 8
  gfx.drawstr(fit(#steps .. " pas" .. (last_name ~= "" and ("  " .. last_name) or ""), SW - 200))
  gfx.setfont(2, "Arial", 12, 'b')
  if btn(SW - 12 - 110, hy, 110, 22, "+ SELECTION", 0.15, 0.40, 0.25) then
    local ms = sel_ids()
    if #ms == 0 then msg = "Selectionne des rushes a droite (ou glisse-les ici)."; msg_err = true else H._to_scn(ms, -1) end
  end
  local bottom = capturing and 162 or 182
  local rows = math.max(1, math.floor((Hh - LY - bottom) / RH))
  if want_visible then
    if cur - 1 < scroll then scroll = cur - 1 end
    if cur > scroll + rows then scroll = cur - rows end
    want_visible = false
  end
  if mx < SW and my >= LY and gfx.mouse_wheel ~= 0 and not show_help then
    scroll = scroll - (gfx.mouse_wheel > 0 and 1 or -1) * 2; gfx.mouse_wheel = 0
  end
  scroll = math.max(0, math.min(math.max(0, #steps - rows), scroll))
  H._sgeo = { ly = LY, rows = rows, scroll = scroll }
  local lw = SW - 24
  gfx.set(0.10, 0.03, 0.04, 1); gfx.rect(12, LY, lw, rows * RH)
  if #steps == 0 then
    gfx.setfont(2, "Arial", 12); gfx.set(1, 1, 1, 0.45); gfx.x, gfx.y = 20, LY + 8
    gfx.drawstr(fit("Glisse des rushes ici depuis la liste de droite.", lw - 16))
  end
  local now_t = reaper.time_precise()
  for r = 1, rows do
    local i = scroll + r
    if i > #steps then break end
    local y = LY + (r - 1) * RH
    local p = parsed[i] or {}
    local m = p.rush and mac_find(p.rush)
    if i == cur then gfx.set(0.55, 0.40, 0.08, 1); gfx.rect(12, y, lw, RH)
    elseif i == last then gfx.set(0.12, 0.30, 0.18, 1); gfx.rect(12, y, lw, RH)
    elseif r % 2 == 0 then gfx.set(0.13, 0.05, 0.06, 1); gfx.rect(12, y, lw, RH) end
    if H._sflash and m and H._sflash.id == m.id and now_t - H._sflash.t < 0.25 then gfx.set(0.35, 0.85, 0.45, 0.5); gfx.rect(12, y, lw, RH) end
    gfx.setfont(2, "Arial", 12)
    gfx.set(1, 1, 1, 0.55); gfx.x, gfx.y = 16, y + 5
    gfx.drawstr((i == last and "✓" or "") .. string.format("%02d", i))
    if m then
      gfx.set(((m.color >> 16) & 255) / 255, ((m.color >> 8) & 255) / 255, (m.color & 255) / 255, 1); gfx.rect(46, y + 4, 10, RH - 8)
    end
    gfx.setfont(2, "Arial", 13, 'b')
    if p.err then gfx.set(1, 0.35, 0.35, 1) else gfx.set(1, 1, 1, 0.95) end
    gfx.x, gfx.y = 62, y + 5
    gfx.drawstr(fit(m and mac_label(m) or (p.rush and "(rush supprime)" or steps[i]), lw - 60))
    if click and mx >= 12 and mx <= 12 + lw and my >= y and my < y + RH then
      local t = reaper.time_precise()
      if last_click_row == i and t - last_click_t < 0.35 then cur = i; drag = nil; edit_step()
      else
        cur = i
        if not capturing then drag = { kind = "step", row = i, x = mx, y = my, active = false, label = "S" .. i } end
      end
      last_click_row, last_click_t = i, t
    end
  end
  -- glisser un pas : sur un autre pas = reordonner ; hors de la fenetre = item S<n> dans REAPER (timeline)
  if drag and drag.kind == "step" then
    if down then
      if not drag.active and (math.abs(mx - drag.x) + math.abs(my - drag.y)) > 10 then
        drag.active = true
        msg = "Glisse le pas S" .. drag.row .. " : sur la piste dans REAPER (timeline) ou sur un autre pas (reordonner)."; msg_err = false
      end
      if drag.active and mx >= 12 and mx <= 12 + lw and my >= LY and my < LY + rows * RH then
        local to = math.max(1, math.min(#steps, scroll + math.floor((my - LY) / RH) + 1))
        gfx.set(1, 1, 1, 0.9); gfx.rect(12, LY + (to - scroll - 1) * RH, lw, RH, 0)
      end
    else
      if drag.active then
        if mx < 0 or my < 0 or mx > gfx.w or my > Hh then drop_step(drag.row)
        elseif mx >= 12 and mx <= 12 + lw and my >= LY and my < LY + rows * RH then
          move_to(drag.row, math.max(1, math.min(#steps, scroll + math.floor((my - LY) / RH) + 1)))
        end
      end
      drag = nil
    end
  end
  -- erreur du pas selectionne
  local p = parsed[cur]
  if p and p.err then
    gfx.setfont(2, "Arial", 12); gfx.set(1, 0.4, 0.4, 1); gfx.x, gfx.y = 14, LY + rows * RH + 4
    gfx.drawstr(fit("Pas " .. cur .. " : " .. p.err, lw))
  end
  if capturing then return end
  -- GO / BACK / BOUCLE
  local yg = Hh - 166
  gfx.setfont(2, "Arial", 13, 'b')
  local wg = math.floor((lw - 8) / 3)
  if btn(12, yg, wg, 26, "◀ BACK", 0.30, 0.22, 0.12) then back() end
  if btn(12 + wg + 4, yg, wg, 26, "GO ▶", 0.15, 0.50, 0.25) then go() end
  if btn(12 + 2 * (wg + 4), yg, lw - 2 * (wg + 4), 26, loop_on and "↻ BOUCLE ON" or "↻ BOUCLE", loop_on and 0.15 or 0.20, loop_on and 0.45 or 0.25, loop_on and 0.60 or 0.35) then toggle_loop() end
  -- pas selectionne
  local y1 = Hh - 116
  title(12, y1 - 14, "PAS SELECTIONNE")
  gfx.setfont(2, "Arial", 12, 'b')
  local w6 = math.floor((lw - 5 * 4) / 6)
  local function x6(k) return 12 + (k - 1) * (w6 + 4) end
  if btn(x6(1), y1, w6, 22, "EDIT", 0.20, 0.25, 0.35) then edit_step() end
  if btn(x6(2), y1, w6, 22, "RETIRER", 0.45, 0.15, 0.15) then del_step() end
  if btn(x6(3), y1, w6, 22, "▲", 0.20, 0.25, 0.35) then move_step(-1) end
  if btn(x6(4), y1, w6, 22, "▼", 0.20, 0.25, 0.35) then move_step(1) end
  if btn(x6(5), y1, w6, 22, "→ ITEM", 0.20, 0.25, 0.35) then stamp_step() end
  if btn(x6(6), y1, w6, 22, "VIDER", 0.45, 0.15, 0.15) then
    if #steps == 0 or reaper.MB("Vider le scenario (" .. #steps .. " pas) ? Les rushes restent.", "NowUndo - scenario", 4) == 6 then new_scn() end
  end
  -- capture / timeline
  local y2 = Hh - 72
  title(12, y2 - 14, "CAPTURE (un pas par VALIDER) / TIMELINE")
  gfx.setfont(2, "Arial", 12, 'b')
  local w3 = math.floor((lw - 8) / 3)
  if btn(12, y2, w3, 22, "● CAPTURE PAS", 0.55, 0.15, 0.15) then tab = "scn"; cap_start() end
  if btn(12 + w3 + 4, y2, w3, 22, tl.on and "⏱ TIMELINE ON" or "⏱ TIMELINE OFF", tl.on and 0.15 or 0.20, tl.on and 0.50 or 0.25, tl.on and 0.30 or 0.35) then toggle_tl() end
  local tlab = "PISTE : " .. (tl.track == 0 and "TOUTES" or tl.track) .. "  v"
  if btn(12 + 2 * (w3 + 4), y2, lw - 2 * (w3 + 4), 22, tlab, 0.20, 0.25, 0.35) then cycle_tl_track(12 + 2 * (w3 + 4), y2 + 22) end
  -- fichier
  local y3 = Hh - 28
  title(12, y3 - 14, "FICHIER SCENARIO")
  gfx.setfont(2, "Arial", 12, 'b')
  local w2 = math.floor((lw - 4) / 2)
  if btn(12, y3, w2, 22, "IMPORT", 0.20, 0.25, 0.35) then load_scn() end
  if btn(12 + w2 + 4, y3, lw - w2 - 4, 22, "EXPORT", 0.20, 0.25, 0.35) then save_scn() end
end

local function main()
  if H._bg then                                                    -- fenetre fermee : rushes et scenarios continuent
    if reaper.GetExtState(CAPEXT, "ui_req") == "1" then
      reaper.SetExtState(CAPEXT, "ui_req", "", false)
      H._open()
    else
      reaper.gmem_attach(GMEM)
      pump(); cap_cmd_poll(); mac_poll()
      if capturing then cap_poll() end
      if tl.on and not capturing then tl_poll() end
      reaper.defer(main)
      return
    end
  end
  local c = gfx.getchar()
  local close = c == -1
  if c == 27 and H._learn then H._learn_start(false); c = 0 end   -- V3.27 : Echap = annule le learn MIDI d'un rush
  if c == 27 then
    if ED.on then ED.close(false); c = 0
    elseif show_help then show_help = false
    elseif capturing then cap_stop()
    else close = true end
  end
  if close then                                                    -- on ferme la fenetre, pas le script
    if c ~= -1 then save_win() else pcall(save_win) end
    if ED.on then ED.close(false) end
    if capturing then cap_stop() end
    show_help = false
    gfx.quit(); H._bg = true
    reaper.defer(main)
    return
  end
  reaper.gmem_attach(GMEM)
  pump()
  cap_cmd_poll()
  mac_poll()
  if capturing then cap_poll() end
  if tl.on and not capturing then tl_poll() end
  if H._lpreq then                                                 -- V3.27 : clic droit sur un pad du Launchpad
    local rq = H._lpreq; H._lpreq = nil
    if capturing then msg = "Termine la capture avant de creer un rush."; msg_err = true
    else
      if ED.on then ED.close(false) end
      show_help = false
      if tab ~= "mac" then set_tab("mac") end
      local m = rq.id > 0 and mac_find(rq.id)
      if m then msel = { [m.id] = true }; mcur = m.id; mwant = true; mac_edit()
      else mac_new(); if ED.on then ED.cell = rq.cell end
        msg = "Nouveau rush pour la case " .. lp_name(rq.cell) .. " du Launchpad : ecris-le puis Entree."; msg_err = false end
    end
  end

  mx, my = gfx.mouse_x, gfx.mouse_y
  local down = (gfx.mouse_cap & 1) == 1
  click = down and not was_down
  was_down = down
  local helpclick = click and show_help
  if show_help then click = false end
  local edclick = click and ED.on
  if ED.on then click = false end
  local W, Hh = gfx.w, gfx.h

  -- clavier
  if ED.on then ED.key(c)
  elseif show_help then
    if c == 63 or c == 104 or c == 72 or c == 13 or c == 32 then show_help = false
    elseif c == 30064 then help_scroll = help_scroll - 1
    elseif c == 1685026670 then help_scroll = help_scroll + 1 end
  elseif tab == "mac" then mac_key(c)
  elseif c == 63 or c == 104 or c == 72 then show_help = true
  elseif c == 99 or c == 67 then if capturing then cap_stop() else cap_start() end
  elseif c == 108 or c == 76 then toggle_loop()
  elseif c == 116 or c == 84 then toggle_tl()
  elseif c == 105 or c == 73 then stamp_step()
  elseif capturing and c == 13 then cap_finalize()
  elseif capturing and c == 8 then cap_reset_line(); msg = "Ligne annulee."; msg_err = false
  elseif capturing and (c == 32 or c == 1919379572 or c == 1818584692) then -- GO / BACK du scenario : desactives pendant la capture
  elseif c == 32 or c == 13 or c == 1919379572 then go()
  elseif c == 8 or c == 1818584692 then back()
  elseif c == 30064 then cur = math.max(1, cur - 1); want_visible = true
  elseif c == 1685026670 then cur = math.min(math.max(1, #steps), cur + 1); want_visible = true
  elseif c == 101 or c == 69 then edit_step() end

  gfx.set(0.14, 0.05, 0.06, 1); gfx.rect(0, 0, W, Hh)
  gfx.setfont(2, "Arial", 12, 'b')
  gfx.setfont(2, "Arial", 14, 'b'); gfx.set(1, 1, 1, 0.9); gfx.x, gfx.y = 14, 9; gfx.drawstr("NowUndo  SCENARIO + RUSHES")
  gfx.setfont(2, "Arial", 12)
  if capturing then gfx.set(1, 0.35, 0.35, 1) else gfx.set(1, 1, 1, 0.5) end
  gfx.x = gfx.x + 18; gfx.y = 11
  local pn = pending()
  gfx.drawstr(capturing and "● CAPTURE ACTIVE" or (mac_status() .. string.format(" | file %d", pn)))
  gfx.setfont(2, "Arial", 12, 'b')
  if btn(W - 104, 6, 92, 22, "ANNULER *", 0.45, 0.15, 0.15) then cancel_all() end
  if btn(W - 204, 6, 92, 22, "? LEXIQUE", 0.20, 0.25, 0.35) then show_help = true; help_scroll = 0 end
  gfx.setfont(2, "Arial", 12)

  -- bandeau d'etat des 8 loopers
  local cw = math.floor((W - 24 - 7 * 4) / 8)
  local selset = {}
  for _, k in ipairs(sel_targets()) do selset[k] = true end      -- looper / groupe vise par les rushes (et les pas)
  for i = 1, NLOOP do
    local F = fb(i)
    local x = 12 + (i - 1) * (cw + 4)
    local col = F.alive and (STC[F.st] or STC[0]) or { .12, .12, .12 }
    gfx.set(col[1], col[2], col[3], 1); gfx.rect(x, 34, cw, 30)
    gfx.set(1, 1, 1, 0.25); gfx.rect(x, 34, cw, 30, 0)
    gfx.set(1, 1, 1, F.alive and 0.95 or 0.3)
    gfx.x, gfx.y = x + 6, 38; gfx.drawstr("L" .. i)
    gfx.setfont(2, "Arial", 10)
    gfx.x, gfx.y = x + 6, 51
    gfx.drawstr((F.rev and "R " or "") .. (F.slicer and "S " or "") .. (F.cloud and "C " or ""))
    if Q[i][1] and Q[i][1].sync then gfx.set(1, 0.9, 0.2, 1); gfx.x = x + cw - 12; gfx.y = 36; gfx.drawstr("*") end
    if true then
      if selset[i] then
        gfx.set(1, 0.85, 0.2, 1); gfx.rect(x, 34, cw, 30, 0); gfx.rect(x + 1, 35, cw - 2, 28, 0); gfx.rect(x + 2, 36, cw - 4, 26, 0)
        gfx.set(1, 0.85, 0.2, 1); gfx.triangle(x + cw / 2 - 5, 66, x + cw / 2 + 5, 66, x + cw / 2, 72)
      else
        gfx.set(0.10, 0.03, 0.04, 0.55); gfx.rect(x, 34, cw, 30)         -- non vises : assombris
      end
    end
    gfx.setfont(2, "Arial", 12)
  end

  if tab == "mac" and not ED.on and not show_help then ED.vk_poll() else ED.vkprev = nil end
  -- V3.27 : SCENARIO (gauche) + RUSHES (droite) dans la meme fenetre ; un clic dans un panneau lui donne le clavier
  local SW = math.max(250, math.min(math.floor(W * 0.38), 440))
  if click and my >= LIST_Y and not capturing then tab = (mx < SW) and "scn" or "mac" end
  H._scn_draw(SW, Hh, down)
  local RW = W - SW
  gfx.setimgdim(7, RW, Hh); gfx.dest = 7
  gfx.set(0.14, 0.05, 0.06, 1); gfx.rect(0, 0, RW, Hh)
  local smx = mx; mx = mx - SW; H._ox = SW
  mac_draw(RW, Hh, down)
  mx = smx; H._ox = 0
  gfx.dest = -1
  gfx.blit(7, 1, 0, 0, LIST_Y, RW, Hh - LIST_Y, SW, LIST_Y, RW, Hh - LIST_Y)
  gfx.set(1, 1, 1, 0.18); gfx.rect(SW - 2, LIST_Y, 2, Hh - LIST_Y)                -- separation des deux panneaux
  local fw = tab == "scn" and { 0, SW - 2 } or { SW, RW }                         -- panneau qui a le clavier : liseré
  gfx.set(0.9, 0.75, 0.15, 0.8); gfx.rect(fw[1], LIST_Y - 2, fw[2], 2)
  if capturing then cap_panel(W, Hh) end

  if drag and drag.active and mx >= 0 and my >= 0 and mx <= W and my <= Hh then   -- etiquette qui suit la souris
    gfx.setfont(2, "Arial", 13, 'b')
    local lab = drag.label or ("S" .. drag.row)
    local tw = gfx.measurestr(lab)
    gfx.set(0.9, 0.75, 0.15, 0.95); gfx.rect(mx + 10, my + 6, tw + 14, 22)
    gfx.set(0, 0, 0, 1); gfx.x, gfx.y = mx + 17, my + 10; gfx.drawstr(lab)
  end

  -- popup lexique
  if show_help then
    local px, py, pw, ph = 10, 10, W - 20, Hh - 20
    gfx.set(0.04, 0.02, 0.03, 0.98); gfx.rect(px, py, pw, ph)
    gfx.set(0.9, 0.8, 0.2, 1); gfx.rect(px, py, pw, ph, 0)
    gfx.setfont(1, "Arial", 15, 'b'); gfx.x, gfx.y = px + 12, py + 8
    gfx.drawstr("LEXIQUE")
    local cx, cy, cw2, ch2 = px + pw - 90, py + 6, 78, 22
    local chov = mx >= cx and mx <= cx + cw2 and my >= cy and my <= cy + ch2
    gfx.set(0.45, 0.15, 0.15, 1); if chov then gfx.set(0.6, 0.2, 0.2, 1) end
    gfx.rect(cx, cy, cw2, ch2)
    gfx.setfont(3, "Arial", 12, 'b'); gfx.set(1, 1, 1, 0.95)
    gfx.x, gfx.y = cx + 14, cy + 5; gfx.drawstr("FERMER")
    local LH, top = 17, py + 38
    local vis = math.max(1, math.floor((ph - 38 - 26) / LH))
    local wh = gfx.mouse_wheel
    if wh ~= 0 then help_scroll = help_scroll - (wh > 0 and 3 or -3); gfx.mouse_wheel = 0 end
    help_scroll = math.max(0, math.min(math.max(0, #HELP - vis), help_scroll))
    for r = 1, vis do
      local e = HELP[help_scroll + r]
      if not e then break end
      local y = top + (r - 1) * LH
      if e[2] == nil and e[1] ~= "" then
        gfx.setfont(3, "Arial", 12, 'b'); gfx.set(0.9, 0.8, 0.2, 1)
        gfx.x, gfx.y = px + 12, y; gfx.drawstr(e[1])
        gfx.set(0.9, 0.8, 0.2, 0.3); gfx.line(px + 12, y + LH - 2, px + pw - 12, y + LH - 2)
      elseif e[2] then
        gfx.setfont(3, "Arial", 12, 'b'); gfx.set(0.55, 0.85, 1, 1)
        gfx.x, gfx.y = px + 20, y; gfx.drawstr(fit(e[1], 190))
        gfx.setfont(2, "Arial", 12); gfx.set(1, 1, 1, 0.9)
        gfx.x, gfx.y = px + 215, y; gfx.drawstr(fit(e[2], pw - 230))
      end
    end
    gfx.setfont(2, "Arial", 11); gfx.set(1, 1, 1, 0.45)
    gfx.x, gfx.y = px + 12, py + ph - 20
    gfx.drawstr("molette / haut-bas : defiler   |   ?  ou  Echap : fermer")
    if helpclick and (chov or mx < px or mx > px + pw or my < py or my > py + ph) then show_help = false end
  end
  if ED.on then
    ED.draw(W, Hh, edclick)
    if reaper.time_precise() - (ED.tt or 0) > 0.2 then             -- signale la saisie au MIDI Learn (raccourcis clavier en pause)
      ED.tt = reaper.time_precise()
      reaper.SetExtState("NowUndo_Scn", "typing", string.format("%.3f", ED.tt), false)
    end
  end

  gfx.update()
  reaper.defer(main)
end

reaper.atexit(function() cap_stop(); persist(); reaper.SetExtState(CAPEXT, "alive", "0", false) end)
main()






