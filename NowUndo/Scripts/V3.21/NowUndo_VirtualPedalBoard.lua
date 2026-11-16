-- NowUndo Virtual Pedal Board
-- Pedalier virtuel : iCON G-Board / Behringer FCB1010 / M-Vave Chocolate.
--   * MIDI learn par switch / pedale d'expression
--   * Modes de switch : Gate, Toggle (note off ignoree) ou Absolu (note on = ON, note off = OFF)
--   * Mode PROG : les appuis n'executent rien ; clic sur un switch = armement, puis
--       - appui sur le pedalier = MIDI learn
--       - clic sur un pad du Launchpad virtuel / un knob du Fighter (Twister) = action
--       - ou clic droit > liste d'actions
--   * Import / export des reglages (fichier .nupb)
--   * V3.10 : actions Mode EXCLU et Sync/Unsync (verrouille sur le looper selectionne), Max slices detectes 0..32 ;
--       en mode EXCLU le REC est transmis au Launchpad (regles groupes / synchro)
-- Necessite : le JSFX NowUndo (gmem "nowundo_sync"). Le Launchpad et le Twister patches
-- publient l'action cliquee dans ExtState "NowUndo_Pedal/capture" quand un switch est arme.

local r = reaper
local EXT, VLX, GMEM = "NowUndo_Pedal", "nowundo_vl", "nowundo_sync"
r.gmem_attach(GMEM)

local floor, max, min = math.floor, math.max, math.min
local function clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end
local function now() return r.time_precise() end
local function split(s, sep)
  local t, i = {}, 1
  while true do
    local j = s:find(sep, i, true)
    if not j then t[#t + 1] = s:sub(i); break end
    t[#t + 1] = s:sub(i, j - 1); i = j + 1
  end
  return t
end
local function esc(s) return (tostring(s or ""):gsub("[|\r\n\t]", "/")) end
local function num(v) if v == nil then return "" end return string.format("%.6g", v) end

--------------------------------------------------------------------------
-- Modeles de pedaliers (coordonnees en unites du boitier)
--------------------------------------------------------------------------
local function build_gboard()
  local c = {}
  for i = 1, 8 do
    local row, col = (i <= 4) and 0 or 1, (i - 1) % 4
    c[#c + 1] = { id = "s" .. i, kind = "sw", shape = "circle", x = 75 + col * 190, y = row == 0 and 58 or 168, r = 25, label = tostring(i) }
  end
  return c
end
local function build_fcb()
  local c = {}
  local top = { "6", "7", "8", "9", "0", "UP" }
  local bot = { "1", "2", "3", "4", "5", "DOWN" }
  for i = 1, 6 do
    c[#c + 1] = { id = "s" .. top[i], kind = "sw", shape = "rect", x = 28 + (i - 1) * 68, y = 70, w = 56, h = 86, label = top[i] }
    c[#c + 1] = { id = "s" .. bot[i], kind = "sw", shape = "rect", x = 28 + (i - 1) * 68, y = 176, w = 56, h = 86, label = bot[i] }
  end
  c[#c + 1] = { id = "expA", kind = "exp", shape = "rect", orient = "v", x = 462, y = 40, w = 150, h = 230, label = "EXP A" }
  c[#c + 1] = { id = "expB", kind = "exp", shape = "rect", orient = "v", x = 632, y = 40, w = 150, h = 230, label = "EXP B" }
  return c
end
local function build_choc()
  return {
    { id = "A", kind = "sw", shape = "circle", x = 70,  y = 118, r = 30, label = "A" },
    { id = "B", kind = "sw", shape = "circle", x = 215, y = 118, r = 30, label = "B" },
    { id = "C", kind = "sw", shape = "circle", x = 385, y = 118, r = 30, label = "C" },
    { id = "D", kind = "sw", shape = "circle", x = 530, y = 118, r = 30, label = "D" },
    { id = "E", kind = "sw", shape = "circle", x = 142, y = 118, r = 13, label = "E" },
    { id = "F", kind = "sw", shape = "circle", x = 457, y = 118, r = 13, label = "F" },
    { id = "exp", kind = "exp", shape = "rect", orient = "h", x = 410, y = 22, w = 150, h = 18, label = "PEDAL" },
  }
end
local MODELS = {
  { id = "gboard", name = "iCON G-Board",         w = 720, h = 235, ctrls = build_gboard(), logo = "iCON", sub = "G-BOARD" },
  { id = "fcb",    name = "Behringer FCB1010",    w = 800, h = 290, ctrls = build_fcb(),    logo = "FCB1010", sub = "MIDI FOOT CONTROLLER" },
  { id = "choc",   name = "M-Vave Chocolate",     w = 600, h = 190, ctrls = build_choc(),   logo = "M-VAVE", sub = "" },
  -- pour ajouter un pedalier : ajouter une entree ici (id, name, w, h, ctrls)
}

--------------------------------------------------------------------------
-- Catalogue d'actions
--------------------------------------------------------------------------
local CMDID = {
  rec_overdub = 1, clear = 2, clear_part = 2, stop_play = 3, reverse = 4, auto_rev = 5, slicer = 6, cloud = 7,
  link = 8, replace = 9, auto_rep = 10, clear_full = 11, part = 12, multiply = 13, undo = 14, redo = 15,
  restart = 16, rerec = 17, one_shot = 18, auto = 19, speed_step = 20, pitch_step = 21, full_loop = 22,
  quantise_inout = 23, reset_params = 24, reset = 24,
  mute = 37,                                   -- V3.25 : mute du looper
}
local CMD_LIST = {
  { grp = "Selection looper", items = {
    { "next_looper", nil, "Looper suivant" }, { "prev_looper", nil, "Looper precedent" },
    { "select_looper", 1, "Looper 1" }, { "select_looper", 2, "Looper 2" }, { "select_looper", 3, "Looper 3" }, { "select_looper", 4, "Looper 4" },
    { "select_looper", 5, "Looper 5" }, { "select_looper", 6, "Looper 6" }, { "select_looper", 7, "Looper 7" }, { "select_looper", 8, "Looper 8" },
  } },
  { grp = "Transport / enregistrement", items = {
    { "rec_overdub", nil, "Rec / Overdub" }, { "replace", nil, "Replace" }, { "auto_rep", nil, "Auto-Replace" },
    { "multiply", nil, "Multiply" }, { "stop_play", nil, "Play / Stop" }, { "auto", nil, "Auto" },
    { "undo", nil, "Undo" }, { "redo", nil, "Redo" }, { "restart", nil, "Restart" }, { "rerec", nil, "Re-Rec" },
  } },
  { grp = "Lecture / modes", items = {
    { "reverse", nil, "Reverse" }, { "auto_rev", nil, "Auto Rev (ping-pong)" }, { "one_shot", nil, "One-Shot" },
    { "slicer", nil, "Slicer on/off" }, { "cloud", nil, "Cloud on/off" }, { "link", nil, "Link Pitch/Speed" },
    { "full_loop", nil, "Full loop" }, { "quantise_inout", nil, "Quantise In/Out" },
    { "mute", nil, "Mute (looper)" },
  } },
  { grp = "Synchro / Exclu", items = {
    { "excl_toggle", nil, "Mode EXCLU on/off" },
    { "excl_super_toggle", nil, "SUPER EXCLU (loopers seuls = groupes)" },
    { "sync_toggle", nil, "Sync / Unsync (part en cours)" }, { "sync_toggle_all", nil, "Sync / Unsync (3 parts)" },
    { "drop_group", nil, "DROP du groupe (mixdown)" },
  } },
  { grp = "Clear / Reset", items = {
    { "clear", nil, "Clear (part active)" }, { "clear_full", nil, "Clear (3 parts)" },
    { "clear_all", nil, "Clear ALL (part active)" }, { "clear_all_full", nil, "Clear ALL (3 parts) = double clic CLEAR du Launchpad" },
    { "reset_params", nil, "Reset parametres" }, { "reset_all", nil, "Reset ALL loopers" },
    { "reset_volume", nil, "Reset volume" }, { "reset_pitch", nil, "Reset pitch" }, { "reset_speed", nil, "Reset speed" },
  } },
  { grp = "Parts / pas", items = {
    { "part", 1, "Part MAIN" }, { "part", 2, "Part CHORUS" }, { "part", 3, "Part BRIDGE" },
    { "pitch_step", 12, "Pitch +12" }, { "pitch_step", -12, "Pitch -12" }, { "pitch_step", 1, "Pitch +1" }, { "pitch_step", -1, "Pitch -1" },
    { "speed_step", 12, "Speed +12 st" }, { "speed_step", -12, "Speed -12 st" },
    { "volume_step", 1, "Volume +1 dB" }, { "volume_step", -1, "Volume -1 dB" },
    { "volume_pct", 10, "Volume +10%" }, { "volume_pct", -10, "Volume -10%" },
  } },
}
local CMD_LABEL = {}
for _, g in ipairs(CMD_LIST) do for _, it in ipairs(g.items) do CMD_LABEL[it[1] .. ":" .. tostring(it[2])] = it[3] end end
local function cmd_label(name, args)
  return CMD_LABEL[name .. ":" .. tostring(args)] or (name .. (args and (" " .. tostring(args)) or ""))
end

-- parametres continus / discrets (id = id d'ecriture du JSFX)
local PARAM_LIST = {
  { grp = "Lecture", items = {
    { id = 3, label = "Speed", lo = 0.01, hi = 100, log = true, von = 2, voff = 1 },
    { id = 4, label = "Pitch (st)", lo = -48, hi = 48, von = 12, voff = 0 },
    { id = 5, label = "Mix", lo = 0, hi = 1 }, { id = 6, label = "Grain (ms)", lo = 20, hi = 200 },
    { id = 7, label = "Fade (ms)", lo = 0, hi = 500 }, { id = 10, label = "Position (%)", lo = 0, hi = 100 },
    { id = 13, label = "Grain fade (%)", lo = 5, hi = 50 },
  } },
  { grp = "Slicer", items = {
    { id = 14, label = "Slicer mode", lo = 0, hi = 5, int = true }, { id = 15, label = "Slicer rate", lo = 0, hi = 5, int = true },
    { id = 16, label = "Slice decay (ms)", lo = 4, hi = 2000, log = true }, { id = 55, label = "Slice attack (ms)", lo = 0, hi = 100, int = true },
    { id = 47, label = "Steps", lo = 1, hi = 32, int = true }, { id = 48, label = "Max slices (detectes)", lo = 0, hi = 32, int = true },
    { id = 49, label = "Slice preset", lo = 1, hi = 4, int = true }, { id = 32, label = "Source Trans/Grid", lo = 0, hi = 1, int = true },
    { id = 57, label = "Source Auto", lo = 0, hi = 1, int = true }, { id = 33, label = "Grid sub", lo = 0, hi = 9, int = true },
    { id = 58, label = "Link Rate (Grid)", lo = 0, hi = 1, int = true }, { id = 34, label = "Slicer pitch spread", lo = 0, hi = 100 },
    { id = 50, label = "Detect threshold", lo = 0.001, hi = 0.8, log = true }, { id = 51, label = "Detect hold (ms)", lo = 30, hi = 1000 },
    { id = 56, label = "Slicer Regen (trig)", lo = 0, hi = 1, int = true, von = 1, voff = 0 },
    { id = 42, label = "Sampler root", lo = 0, hi = 127, int = true }, { id = 43, label = "Sampler pitch mode", lo = 0, hi = 1, int = true },
    { id = 44, label = "Sampler release (ms)", lo = 0, hi = 3000 },
  } },
  { grp = "Cloud", items = {
    { id = 26, label = "Cloud density", lo = 0, hi = 1 }, { id = 27, label = "Cloud chaos", lo = 0, hi = 1 },
    { id = 28, label = "Cloud spread", lo = 0, hi = 1 }, { id = 35, label = "Cloud pitch spread", lo = 0, hi = 100 },
    { id = 36, label = "Cloud mix", lo = 0, hi = 1 }, { id = 37, label = "Cloud pos mode", lo = 0, hi = 1, int = true },
    { id = 38, label = "Cloud pos (%)", lo = 0, hi = 100 }, { id = 39, label = "LFO shape", lo = 0, hi = 2, int = true },
    { id = 40, label = "LFO rate (Hz)", lo = 0.1, hi = 4 }, { id = 41, label = "LFO depth (%)", lo = 0, hi = 100 },
  } },
  { grp = "Sortie / REC", items = {
    { id = 22, label = "Output volume", lo = 0, hi = 2, von = 1, voff = 0 }, { id = 19, label = "Feedback", lo = 0, hi = 2, von = 1, voff = 0 },
    { id = 20, label = "Degradation", lo = 0, hi = 1 }, { id = 21, label = "Stereo width", lo = 0, hi = 1 },
    { id = 29, label = "Density REC (%)", lo = 0, hi = 100 }, { id = 11, label = "Auto-REC seuil", lo = 0.01, hi = 0.8, log = true },
    { id = 12, label = "Auto-REC hold (ms)", lo = 30, hi = 1000 },
  } },
}
local PARAM_BY_ID = {}
for _, g in ipairs(PARAM_LIST) do for _, p in ipairs(g.items) do
  p.von = p.von or p.hi; p.voff = p.voff or p.lo; PARAM_BY_ID[p.id] = p
end end

--------------------------------------------------------------------------
-- Acces JSFX (gmem)
--------------------------------------------------------------------------
local function rd(i) return r.gmem_read(i) or 0 end
local function gbase(l, part) return 1000 + (l - 1) * 600 + ((part or 1) - 1) * 200 end
local function active_part(l)
  local ap = floor(rd(1000 + (l - 1) * 600 + 42) + 0.5)
  if ap < 1 or ap > 3 then ap = 1 end
  return ap
end
local function alive(l)
  return rd(100 + l - 1) > 0 and (now() - rd(130 + l - 1)) <= 3.0
end
local function fb(l, off) return rd(gbase(l, active_part(l)) + off) end

local function targets(act)
  local t = {}
  if act.tgt and act.tgt >= 1 then
    if alive(act.tgt) then t[1] = act.tgt end
    return t
  end
  local sel = floor(tonumber(r.GetExtState(VLX, "sel_looper")) or 1)
  local grp = floor(tonumber(r.GetExtState(VLX, "sel_group")) or 0)
  if grp > 0 then
    for i = 1, 8 do if alive(i) and floor(rd(6000 + i) + 0.5) == grp then t[#t + 1] = i end end
    if #t > 0 then return t end
  end
  if sel >= 1 and sel <= 8 and alive(sel) then t[1] = sel end
  return t
end

local function send_cmd(l, cmd, arg, part)
  local b = gbase(l, part or active_part(l))
  if arg ~= nil then r.gmem_write(b + 49, arg) end
  r.gmem_write(b + 48, cmd)
end
local function write_param(l, id, v)
  local b = gbase(l, active_part(l))
  r.gmem_write(b + 181, v)
  r.gmem_write(b + 180, id)
end

-- etat (feedback JSFX) des actions on/off : permet le mode Absolu et les voyants
local function jstate(l) return floor(fb(l, 2) + 0.5) end
local STATE = {
  rec_overdub = function(l) local s = jstate(l) return s == 1 or s == 3 end,
  replace = function(l) local s = jstate(l) return s == 4 or s == 5 end,
  multiply = function(l) return jstate(l) == 6 end,
  stop_play = function(l) local s = jstate(l) return s ~= 0 and s ~= 7 end,
  reverse = function(l) return fb(l, 17) > 0.5 end,
  auto_rev = function(l) return fb(l, 18) > 0.5 end,
  slicer = function(l) return floor(fb(l, 8) + 0.5) == 1 end,
  one_shot = function(l) return floor(fb(l, 8) + 0.5) == 2 end,
  cloud = function(l) return fb(l, 24) > 0.5 end,
  link = function(l) return fb(l, 9) > 0.5 end,
  auto = function(l) return fb(l, 43) > 0.5 end,
  mute = function(l) return fb(l, 199) > 0.5 end,     -- V3.25
}

local function all_alive()
  local t = {}
  for i = 1, 8 do if alive(i) then t[#t + 1] = i end end
  return t
end

local function exec_cmd(act, mode, on)
  local name, args = act.name, act.args
  -- selection du looper : la selection appartient au Launchpad, on lui passe la commande (ExtState lp_cmd)
  -- EXCLU et SYNC/UNSYNC appartiennent aussi au Launchpad (groupes, module Master Sync) : meme canal lp_cmd
  if name == "excl_toggle" or name == "excl_super_toggle" or name == "sync_toggle" or name == "sync_toggle_all" or name == "drop_group" then
    if on == false then return end
    r.SetExtState(EXT, "lp_cmd", string.format("%.6f\t%s\t", now(), name), false)
    return
  end
  if name == "next_looper" or name == "prev_looper" or name == "select_looper" then
    if on == false then return end          -- jamais sur note off (Absolu compris)
    r.SetExtState(EXT, "lp_cmd", string.format("%.6f\t%s\t%s", now(), name, args and tostring(floor(args)) or ""), false)
    return
  end
  if name == "clear_all" or name == "clear_all_full" or name == "reset_all" then
    local id = (name == "clear_all") and 2 or ((name == "clear_all_full") and 11 or 24)
    for _, l in ipairs(all_alive()) do send_cmd(l, id) end
    return
  end
  -- Mode EXCLU actif : le REC passe par le Launchpad (il decide synchro / arret des autres groupes AVANT le REC)
  if name == "rec_overdub" and on ~= false and r.GetExtState(VLX, "exclusive") == "1" then
    r.SetExtState(EXT, "lp_cmd", string.format("%.6f\ttrigger\t%s", now(), name), false)
    return
  end
  for _, l in ipairs(targets(act)) do
    if name == "part" then
      send_cmd(l, 12, nil, floor(args or 1))
    elseif name == "speed_step" or name == "pitch_step" then
      send_cmd(l, CMDID[name], args or 12)
    elseif name == "reset_volume" then write_param(l, 22, 1)
    elseif name == "reset_pitch" then write_param(l, 4, 0)
    elseif name == "reset_speed" then write_param(l, 3, 1)
    elseif name == "volume_step" then
      local cur = fb(l, 22); if cur <= 0 then cur = 0.0001 end
      write_param(l, 22, clamp(cur * 10 ^ ((args or 0) / 20), 0, 2))
    elseif name == "volume_pct" then
      write_param(l, 22, clamp(fb(l, 22) + (args or 0) * 0.01, 0, 2))
    elseif CMDID[name] then
      local st = STATE[name]
      if mode == "abs" and st then
        -- Absolu : on pose l'etat voulu (on -> ON, off -> OFF), sans bascule aveugle
        if st(l) ~= on then send_cmd(l, CMDID[name]) end
      elseif mode == "abs" and not on then
        -- action ponctuelle (undo, clear...) : pas d'equivalent "off"
      else
        send_cmd(l, CMDID[name])
      end
    end
  end
end

local function par_value(act, n)
  n = clamp(n, 0, 1)
  local v
  if act.log and act.lo > 0 and act.hi > act.lo then v = act.lo * (act.hi / act.lo) ^ n
  else v = act.lo + n * (act.hi - act.lo) end
  if act.int then v = floor(v + 0.5) end
  return clamp(v, min(act.lo, act.hi), max(act.lo, act.hi))
end

--------------------------------------------------------------------------
-- Configuration (par controle) + persistance
--------------------------------------------------------------------------
local CFG = {}     -- "modele:ctrl" -> { status, ch, d1, dev, mode, inv, act }
local RT = {}      -- etat runtime : lit_until, tog, pressed, last_exp, flash
local S = { model = 1, prog = false, armed = nil, arm_t = 0, sel = nil, dev = "", msg = "", msg_t = 0, last_cap = 0 }

local function rt(key) local x = RT[key]; if not x then x = { lit_until = 0, tog = false, pressed = false, last_exp = -1, flash = 0 }; RT[key] = x end return x end
local function cfg_of(key, create)
  local c = CFG[key]
  if not c and create then c = { mode = "gate", inv = false }; CFG[key] = c end
  return c
end
local function say(m) S.msg = m; S.msg_t = now() end

local function ser_cfg(key, c)
  local a = c.act or {}
  return table.concat({
    esc(key), num(c.status), num(c.ch), num(c.d1), esc(c.dev), esc(c.mode), c.inv and "1" or "0",
    esc(a.t), esc(a.name), num(a.args), num(a.id), num(a.lo), num(a.hi), num(a.von), num(a.voff),
    a.log and "1" or "0", a.int and "1" or "0", num(a.tgt), esc(a.label),
  }, "|")
end
local function parse_cfg(line)
  local f = split(line, "|")
  if #f < 19 or f[1] == "" then return nil end
  local c = { status = tonumber(f[2]), ch = tonumber(f[3]), d1 = tonumber(f[4]), dev = f[5], mode = (f[6] ~= "" and f[6] or "gate"), inv = f[7] == "1" }
  if f[8] ~= "" then
    c.act = { t = f[8], name = f[9], args = tonumber(f[10]), id = tonumber(f[11]), lo = tonumber(f[12]), hi = tonumber(f[13]),
              von = tonumber(f[14]), voff = tonumber(f[15]), log = f[16] == "1", int = f[17] == "1", tgt = tonumber(f[18]) or 0, label = f[19] }
  end
  return f[1], c
end
local function ser_all()
  local out = {}
  local keys = {}
  for k in pairs(CFG) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do out[#out + 1] = ser_cfg(k, CFG[k]) end
  return table.concat(out, "\n")
end
local function save_all()
  r.SetExtState(EXT, "cfg", ser_all(), true)
  r.SetExtState(EXT, "model", MODELS[S.model].id, true)
  r.SetExtState(EXT, "dev", S.dev, true)
end
local function load_all()
  CFG = {}
  local raw = r.GetExtState(EXT, "cfg")
  for line in raw:gmatch("[^\n]+") do local k, c = parse_cfg(line); if k then CFG[k] = c end end
  local mid = r.GetExtState(EXT, "model")
  for i, m in ipairs(MODELS) do if m.id == mid then S.model = i end end
  S.dev = r.GetExtState(EXT, "dev") or ""
end

--------------------------------------------------------------------------
-- Export / import
--------------------------------------------------------------------------
local function pb_dir()
  local d = r.GetResourcePath() .. "/Data/NowUndo_Pedal"
  if r.RecursiveCreateDirectory then r.RecursiveCreateDirectory(d, 0) end
  return d
end
local function do_export()
  local def = "pedal_" .. MODELS[S.model].id .. "_" .. os.date("%Y%m%d_%H%M")
  local path
  if r.JS_Dialog_BrowseForSaveFile then
    local ok, p = r.JS_Dialog_BrowseForSaveFile("Exporter les reglages du pedalier", pb_dir(), def .. ".nupb", "NowUndo pedal (*.nupb)\0*.nupb\0\0")
    if ok == 1 and p and p ~= "" then path = p end
  else
    local ok, name = r.GetUserInputs("Exporter les reglages", 1, "Nom du fichier,extrawidth=200", def)
    if ok and name ~= "" then path = pb_dir() .. "/" .. name:gsub("[^%w%-%._ ]", "_") end
  end
  if not path then return end
  if not path:lower():match("%.nupb$") then path = path .. ".nupb" end
  local f = io.open(path, "w")
  if not f then say("Export impossible : " .. path) return end
  f:write("NOWUNDO_PEDALBOARD 1\n")
  f:write("model=" .. MODELS[S.model].id .. "\n")
  f:write("dev=" .. esc(S.dev) .. "\n")
  f:write(ser_all() .. "\n")
  f:close()
  say("Exporte : " .. path)
end
local function do_import()
  local ok, path = r.GetUserFileNameForRead(pb_dir() .. "/", "Importer les reglages du pedalier", "nupb")
  if not ok or not path or path == "" then return end
  local f = io.open(path, "r")
  if not f then say("Lecture impossible : " .. path) return end
  local first = f:read("l")
  if not first or not first:match("^NOWUNDO_PEDALBOARD") then f:close(); say("Fichier non reconnu") return end
  local n, model, dev = 0, nil, nil
  for line in f:lines() do
    if line:sub(1, 6) == "model=" then model = line:sub(7)
    elseif line:sub(1, 4) == "dev=" then dev = line:sub(5)
    elseif line ~= "" then
      local k, c = parse_cfg(line)
      if k then CFG[k] = c; n = n + 1 end
    end
  end
  f:close()
  if model then for i, m in ipairs(MODELS) do if m.id == model then S.model = i end end end
  if dev and dev ~= "" then S.dev = dev end
  S.armed = nil
  save_all()
  say(string.format("Importe : %d reglage(s)", n))
end

--------------------------------------------------------------------------
-- Declenchement
--------------------------------------------------------------------------
local function is_lit(key, c)
  local x = rt(key)
  if x.lit_until > now() or x.pressed then return true end
  if c and c.act then
    if c.act.t == "par" then return x.tog and c.mode == "toggle" end
    local st = STATE[c.act.name]
    if st then local t = targets(c.act); if t[1] then return st(t[1]) end end
  end
  return false
end

local function fire(key, c, on)
  local a = c.act
  if not a then return end
  local x = rt(key)
  if a.t == "cmd" then
    exec_cmd(a, c.mode, on)
  elseif a.t == "par" then
    local v
    if c.mode == "abs" then v = on and a.von or a.voff
    elseif c.mode == "toggle" then x.tog = not x.tog; v = x.tog and a.von or a.voff
    else v = a.von end
    v = a.int and floor(v + 0.5) or v
    v = clamp(v, min(a.lo, a.hi), max(a.lo, a.hi))
    for _, l in ipairs(targets(a)) do write_param(l, a.id, v) end
  end
  x.lit_until = now() + 0.18
end

local function trigger(key, c, ctrl, on, val127)
  if ctrl.kind == "exp" then
    local a = c.act
    if not a or a.t ~= "par" then return end
    local n = val127 / 127
    if c.inv then n = 1 - n end
    local v = par_value(a, n)
    local x = rt(key)
    x.vfrac = clamp(val127 / 127, 0, 1)
    if x.last_exp ~= v then
      x.last_exp = v
      for _, l in ipairs(targets(a)) do write_param(l, a.id, v) end
    end
    x.lit_until = now() + 0.12
    return
  end
  if c.mode ~= "abs" and not on then return end    -- Gate / Toggle : note off ignoree
  fire(key, c, on)
end

--------------------------------------------------------------------------
-- MIDI
--------------------------------------------------------------------------
local last_seq = 0
do local rv = r.MIDI_GetRecentInputEvent(0); last_seq = rv or 0 end
local devnames = {}
local function devname(i)
  local n = devnames[i]
  if n == nil then
    local ok, nm = r.GetMIDIInputName(i, "")
    n = (ok and nm) or ""
    devnames[i] = n
  end
  return n
end
local function poll_midi()
  local evs, i = {}, 0
  while i < 128 do
    local rv, buf, _, dev = r.MIDI_GetRecentInputEvent(i)
    if not rv or rv == 0 or rv <= last_seq then break end
    evs[#evs + 1] = { seq = rv, buf = buf, dev = devname(dev or 0) }
    i = i + 1
  end
  if #evs == 0 then return {} end
  last_seq = evs[1].seq
  local out = {}
  for k = #evs, 1, -1 do out[#out + 1] = evs[k] end
  return out
end

local function bind_str(c)
  if not c or not c.d1 then return "MIDI : -" end
  local nm = ({ [0x90] = "Note", [0xB0] = "CC", [0xC0] = "PC" })[c.status] or "?"
  return string.format("%s %d  ch%d", nm, c.d1, (c.ch or 0) + 1)
end

local function matches(c, st, ch, d1)
  return c and c.d1 ~= nil and c.status == st and c.ch == ch and c.d1 == d1
end

local function handle_midi(ev)
  local b1, b2, b3 = ev.buf:byte(1, 3)
  if not b1 or b1 >= 0xF0 then return end
  local st, ch = b1 & 0xF0, b1 & 0x0F
  b2, b3 = b2 or 0, b3 or 0
  if st ~= 0x90 and st ~= 0x80 and st ~= 0xB0 and st ~= 0xC0 then return end
  if S.dev ~= "" and ev.dev ~= S.dev then return end
  local on, val
  if st == 0xB0 then on = b3 >= 64; val = b3
  elseif st == 0xC0 then on = true; val = 127
  else
    on = (st == 0x90 and b3 > 0)
    val = on and 127 or 0
    st = 0x90
  end
  local model = MODELS[S.model]
  -- MIDI learn du controle arme
  if S.armed then
    local ctrl
    for _, cc in ipairs(model.ctrls) do if model.id .. ":" .. cc.id == S.armed then ctrl = cc end end
    if ctrl and not (ctrl.kind == "exp" and st ~= 0xB0) then
      for _, o in ipairs(model.ctrls) do
        local k = model.id .. ":" .. o.id
        if k ~= S.armed and matches(CFG[k], st, ch, b2) then CFG[k].status, CFG[k].ch, CFG[k].d1 = nil, nil, nil end
      end
      local c = cfg_of(S.armed, true)
      c.status, c.ch, c.d1, c.dev = st, ch, b2, ev.dev
      save_all()
      say("MIDI appris : " .. bind_str(c))
      if c.act then S.armed = nil end
    end
    return
  end
  for _, ctrl in ipairs(model.ctrls) do
    local key = model.id .. ":" .. ctrl.id
    local c = CFG[key]
    if matches(c, st, ch, b2) then
      local x = rt(key)
      if S.prog then
        S.sel = key; x.flash = now() + 0.4
      else
        x.pressed = (ctrl.kind == "sw") and on or false
        trigger(key, c, ctrl, on, val)
      end
    end
  end
end

--------------------------------------------------------------------------
-- Capture d'action depuis le Launchpad / le Fighter
--------------------------------------------------------------------------
local function apply_action(key, act)
  local c = cfg_of(key, true)
  c.act = act
  save_all()
  say("Action : " .. (act.label or act.name or "?"))
  if c.d1 then S.armed = nil end
end
local function make_par_act(id, label)
  local p = PARAM_BY_ID[id]
  return { t = "par", id = id, name = label or (p and p.label) or ("param " .. id), label = label or (p and p.label) or ("param " .. id),
           lo = p and p.lo or 0, hi = p and p.hi or 1, von = p and p.von or 1, voff = p and p.voff or 0,
           log = p and p.log or false, int = p and p.int or false, tgt = 0 }
end
local function make_cmd_act(name, args)
  return { t = "cmd", name = name, args = args, label = cmd_label(name, args), tgt = 0 }
end
local function poll_capture()
  if not S.armed then return end
  r.SetExtState(EXT, "armed_hb", string.format("%.4f", now()), false)
  local s = r.GetExtState(EXT, "capture")
  if s == "" then return end
  local f = split(s, "\t")
  local ts = tonumber(f[1]) or 0
  if ts <= S.arm_t or ts == S.last_cap then return end
  S.last_cap = ts
  r.SetExtState(EXT, "capture", "", false)
  local model = MODELS[S.model]
  local ctrl
  for _, cc in ipairs(model.ctrls) do if model.id .. ":" .. cc.id == S.armed then ctrl = cc end end
  local act
  if f[2] == "cmd" and f[3] and f[3] ~= "" then act = make_cmd_act(f[3], tonumber(f[4]))
  elseif f[2] == "par" and tonumber(f[5]) then
    act = make_par_act(floor(tonumber(f[5])), (f[8] ~= "" and f[8]) or nil)
    if tonumber(f[9]) then act.tgt = floor(tonumber(f[9])) end   -- knob d'un looper precis (pages par looper du Fighter)
  end
  if not act then return end
  if ctrl and ctrl.kind == "exp" and act.t ~= "par" then say("Pedale d'expression : choisir un parametre continu") return end
  apply_action(S.armed, act)
end

--------------------------------------------------------------------------
-- Menus
--------------------------------------------------------------------------
local function show_menu(str)
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  return gfx.showmenu(str)
end
local function pick_action()
  local cats = {}
  for _, g in ipairs(CMD_LIST) do cats[#cats + 1] = { kind = "cmd", g = g, label = "Commande : " .. g.grp } end
  for _, g in ipairs(PARAM_LIST) do cats[#cats + 1] = { kind = "par", g = g, label = "Parametre : " .. g.grp } end
  local m = {}
  for i, c in ipairs(cats) do m[i] = c.label end
  local ch = show_menu(table.concat(m, "|"))
  if ch < 1 then return nil end
  local cat = cats[ch]
  local items, labels = {}, {}
  for _, it in ipairs(cat.g.items) do
    items[#items + 1] = it
    labels[#labels + 1] = (cat.kind == "cmd") and it[3] or it.label
  end
  local ch2 = show_menu(table.concat(labels, "|"))
  if ch2 < 1 then return nil end
  local it = items[ch2]
  if cat.kind == "cmd" then return make_cmd_act(it[1], it[2]) end
  return make_par_act(it.id)
end

local function context_menu(key, ctrl)
  local c = cfg_of(key, true)
  local a = c.act
  local entries = {}
  local function add(label, fn) entries[#entries + 1] = { label = label, fn = fn } end
  local function chk(b) return b and "!" or "" end
  if ctrl.kind == "sw" then
    add(chk(c.mode == "gate") .. "Mode : Gate (note off ignoree)", function() c.mode = "gate" end)
    add(chk(c.mode == "toggle") .. "Mode : Toggle (note off ignoree)", function() c.mode = "toggle" end)
    add(chk(c.mode == "abs") .. "Mode : Absolu (on = ON, off = OFF)", function() c.mode = "abs" end)
  else
    add(chk(c.inv) .. "Inverser la pedale", function() c.inv = not c.inv end)
  end
  add("Choisir l'action dans la liste...", function() local x = pick_action(); if x then apply_action(key, x) end end)
  if a then
    local tg = {}
    tg[#tg + 1] = chk(not a.tgt or a.tgt == 0) .. "Cible : looper selectionne (Launchpad)"
    for i = 1, 8 do tg[#tg + 1] = chk(a.tgt == i) .. "Cible : looper " .. i end
    for i, label in ipairs(tg) do add(label, function() a.tgt = (i == 1) and 0 or (i - 1) end) end
    if a.t == "par" then
      add("Valeurs ON / OFF...", function()
        local ok, csv = r.GetUserInputs("Valeurs ON / OFF", 2, "Valeur ON,Valeur OFF", string.format("%g,%g", a.von, a.voff))
        if ok then
          local p = split(csv, ",")
          if tonumber(p[1]) then a.von = tonumber(p[1]) end
          if tonumber(p[2]) then a.voff = tonumber(p[2]) end
        end
      end)
      add("Plage (pedale) min / max...", function()
        local ok, csv = r.GetUserInputs("Plage", 2, "Min,Max", string.format("%g,%g", a.lo, a.hi))
        if ok then
          local p = split(csv, ",")
          if tonumber(p[1]) then a.lo = tonumber(p[1]) end
          if tonumber(p[2]) then a.hi = tonumber(p[2]) end
        end
      end)
    end
    add("Effacer l'action", function() c.act = nil end)
  end
  if c.d1 then add("Effacer le MIDI", function() c.status, c.ch, c.d1, c.dev = nil, nil, nil, "" end) end
  add("Effacer tout ce controle", function() CFG[key] = nil; if S.armed == key then S.armed = nil end end)
  local labels = {}
  for i, e in ipairs(entries) do labels[i] = e.label end
  local ch = show_menu(table.concat(labels, "|"))
  if ch >= 1 then entries[ch].fn(); save_all() end
end

local function model_menu()
  local m = {}
  for i, mod in ipairs(MODELS) do m[i] = (i == S.model and "!" or "") .. mod.name end
  local ch = show_menu(table.concat(m, "|"))
  if ch >= 1 then S.model = ch; S.armed = nil; S.sel = nil; save_all() end
end
local function dev_menu()
  local names, m = { "" }, { (S.dev == "" and "!" or "") .. "Toutes les entrees MIDI" }
  local n = r.GetNumMIDIInputs and r.GetNumMIDIInputs() or 0
  for i = 0, n - 1 do
    local ok, nm = r.GetMIDIInputName(i, "")
    if ok and nm and nm ~= "" then names[#names + 1] = nm; m[#m + 1] = (S.dev == nm and "!" or "") .. nm end
  end
  local ch = show_menu(table.concat(m, "|"))
  if ch >= 1 then S.dev = names[ch]; save_all() end
end

--------------------------------------------------------------------------
-- Dessin
--------------------------------------------------------------------------
local W, H = 860, 560
local TOP, BOT = 40, 96
local function setc(rr, g, b, a) gfx.set(rr, g, b, a or 1) end
local function txt(x, y, s, size, rr, g, b, a, align, maxw)
  gfx.setfont(1, "Arial", size)
  setc(rr, g, b, a)
  s = tostring(s)
  local tw, th = gfx.measurestr(s)
  if maxw and tw > maxw then
    while #s > 1 and gfx.measurestr(s .. "..") > maxw do s = s:sub(1, #s - 1) end
    s = s .. ".."
    tw, th = gfx.measurestr(s)
  end
  if align == "c" then x = x - tw / 2 elseif align == "r" then x = x - tw end
  gfx.x, gfx.y = x, y
  gfx.drawstr(s)
  return tw, th
end

local LDOWN, RDOWN, wasL, wasR = false, false, false, false
local btn_click = false
local function button(x, y, w, h, label, on, cr, cg, cb)
  local hov = gfx.mouse_x >= x and gfx.mouse_x < x + w and gfx.mouse_y >= y and gfx.mouse_y < y + h
  if on then setc(cr or 0.8, cg or 0.3, cb or 0.2, 1) else setc(hov and 0.30 or 0.22, hov and 0.31 or 0.23, hov and 0.35 or 0.26, 1) end
  gfx.rect(x, y, w, h, 1)
  setc(0.55, 0.57, 0.63, 1); gfx.rect(x, y, w, h, 0)
  txt(x + w / 2, y + (h - 12) / 2, label, 12, 0.95, 0.95, 0.97, 1, "c", w - 6)
  return hov and LDOWN
end

local function geom()
  local m = MODELS[S.model]
  local aw, ah = W - 30, H - TOP - BOT - 14
  local sc = min(aw / m.w, ah / m.h)
  local ox = (W - m.w * sc) / 2
  local oy = TOP + 8 + (ah - m.h * sc) / 2
  return m, sc, ox, oy
end

local function ctrl_rect(c, sc, ox, oy)
  if c.shape == "circle" then
    return ox + (c.x - c.r) * sc, oy + (c.y - c.r) * sc, c.r * 2 * sc, c.r * 2 * sc
  end
  return ox + c.x * sc, oy + c.y * sc, c.w * sc, c.h * sc
end
local function hit(c, sc, ox, oy, mx, my)
  if c.shape == "circle" then
    local cx, cy = ox + c.x * sc, oy + c.y * sc
    return (mx - cx) ^ 2 + (my - cy) ^ 2 <= (c.r * sc) ^ 2
  end
  local x, y, w, h = ctrl_rect(c, sc, ox, oy)
  return mx >= x and mx < x + w and my >= y and my < y + h
end

local function draw_ctrl(m, c, sc, ox, oy, blink)
  local key = m.id .. ":" .. c.id
  local cf = CFG[key]
  local x, y, w, h = ctrl_rect(c, sc, ox, oy)
  local lit = is_lit(key, cf)
  local armed = (S.armed == key)
  local bound = cf and cf.d1 ~= nil
  local hasact = cf and cf.act ~= nil
  if c.kind == "exp" then
    setc(0.10, 0.10, 0.12, 1); gfx.rect(x, y, w, h, 1)
    local frac = rt(key).vfrac or 0
    setc(0.75, 0.55, 0.15, 0.9)
    if c.orient == "v" then gfx.rect(x + 3, y + h - 3 - (h - 6) * frac, w - 6, (h - 6) * frac, 1)
    else gfx.rect(x + 3, y + 3, (w - 6) * frac, h - 6, 1) end
    setc(0.42, 0.44, 0.50, 1)
    if c.orient == "v" then
      for i = 1, 9 do gfx.line(x + 8, y + 8 + i * (h - 16) / 10, x + w - 8, y + 8 + i * (h - 16) / 10) end
    end
  else
    if c.shape == "circle" then
      setc(0.55, 0.57, 0.60, 1); gfx.circle(x + w / 2, y + h / 2, w / 2, 1, 1)
      setc(lit and 0.30 or 0.78, lit and 0.85 or 0.80, lit and 0.45 or 0.84, 1); gfx.circle(x + w / 2, y + h / 2, w / 2 - 3, 1, 1)
    else
      setc(0.08, 0.08, 0.09, 1); gfx.rect(x, y, w, h, 1)
      setc(lit and 0.30 or 0.20, lit and 0.85 or 0.21, lit and 0.45 or 0.23, 1); gfx.rect(x + 3, y + 3, w - 6, h - 6, 1)
    end
  end
  -- contour d'etat
  if armed then
    setc(1, 0.85, 0.1, blink and 1 or 0.25)
    gfx.rect(x - 2, y - 2, w + 4, h + 4, 0); gfx.rect(x - 3, y - 3, w + 6, h + 6, 0)
  elseif S.sel == key then
    setc(0.4, 0.75, 1, 1); gfx.rect(x - 2, y - 2, w + 4, h + 4, 0)
  end
  -- libelle
  local lbl = c.label
  if c.shape == "circle" then txt(x + w / 2, y + h / 2 - 6, lbl, c.r > 20 and 14 or 11, 0.05, 0.05, 0.07, 1, "c")
  elseif c.kind == "exp" then txt(x + w / 2, y + 4, lbl, 11, 0.9, 0.9, 0.95, 1, "c")
  else txt(x + w / 2, y + 6, lbl, 13, 0.92, 0.92, 0.96, 1, "c") end
  -- pastilles : MIDI (vert) / action (bleu)
  local py = (c.shape == "circle") and (y + h + 4) or (y + h - 10)
  if bound then setc(0.3, 0.9, 0.4, 1) else setc(0.3, 0.3, 0.33, 1) end
  gfx.circle(x + w / 2 - 6, py + 3, 3, 1, 1)
  if hasact then setc(0.35, 0.65, 1, 1) else setc(0.3, 0.3, 0.33, 1) end
  gfx.circle(x + w / 2 + 6, py + 3, 3, 1, 1)
  -- nom d'action abrege sous le controle
  if hasact and c.kind == "sw" then
    local ty = (c.shape == "circle") and (y + h + 12) or (y + h + 3)
    txt(x + w / 2, ty, cf.act.label or cf.act.name, 9, 0.85, 0.87, 0.92, 1, "c", max(w + 30 * sc, 60))
  end
end

local MODE_NAME = { gate = "Gate", toggle = "Toggle", abs = "Absolu" }

local function draw_all()
  setc(0.09, 0.09, 0.11, 1); gfx.rect(0, 0, W, H, 1)
  -- barre du haut
  local bx = 10
  if button(bx, 6, 150, 26, MODELS[S.model].name .. "  v", false) then model_menu() end
  bx = bx + 156
  local dl = (S.dev == "" and "Entree : toutes" or ("Entree : " .. S.dev))
  if button(bx, 6, 210, 26, dl .. "  v", false) then dev_menu() end
  bx = bx + 216
  if button(bx, 6, 90, 26, S.prog and "PROG ON" or "PROG", S.prog, 0.85, 0.2, 0.2) then
    S.prog = not S.prog; S.armed = nil
    say(S.prog and "Mode PROG : les appuis n'executent rien" or "Mode PROG termine")
  end
  bx = bx + 96
  if button(bx, 6, 70, 26, "Export", false) then do_export() end
  bx = bx + 76
  if button(bx, 6, 70, 26, "Import", false) then do_import() end
  bx = bx + 76
  if button(bx, 6, 90, 26, "Tout effacer", false) then
    local ok = r.ShowMessageBox("Effacer tous les reglages du pedalier " .. MODELS[S.model].name .. " ?", "Pedalier", 4)
    if ok == 6 then
      for _, c in ipairs(MODELS[S.model].ctrls) do CFG[MODELS[S.model].id .. ":" .. c.id] = nil end
      S.armed = nil; save_all(); say("Reglages effaces")
    end
  end

  local m, sc, ox, oy = geom()
  -- boitier
  setc(0.04, 0.04, 0.05, 1); gfx.rect(ox, oy, m.w * sc, m.h * sc, 1)
  setc(0.35, 0.36, 0.40, 1); gfx.rect(ox, oy, m.w * sc, m.h * sc, 0)
  if m.id == "gboard" then
    txt(ox + m.w * sc / 2, oy + 38 * sc, m.logo, 16, 0.9, 0.9, 0.95, 1, "c")
    txt(ox + m.w * sc / 2, oy + 105 * sc, m.sub, 26 * sc + 4, 0.95, 0.95, 1, 1, "c")
  elseif m.id == "fcb" then
    setc(0.78, 0.78, 0.80, 1); gfx.rect(ox + 1, oy + 1, m.w * sc - 2, m.h * sc - 2, 1)
    txt(ox + 30 * sc, oy + 14 * sc, m.logo, 20, 0.1, 0.1, 0.12, 1, "l")
    txt(ox + 30 * sc, oy + 38 * sc, m.sub, 10, 0.2, 0.2, 0.24, 1, "l")
    setc(0.05, 0.05, 0.06, 1); gfx.rect(ox + 420 * sc, oy + 12 * sc, 30 * sc, 22 * sc, 1)
    txt(ox + 435 * sc, oy + 14 * sc, "5", 14, 1, 0.2, 0.2, 1, "c")
  else
    setc(0.08, 0.08, 0.1, 1); gfx.rect(ox + 255 * sc, oy + 96 * sc, 90 * sc, 44 * sc, 1)
    txt(ox + 300 * sc, oy + 105 * sc, "000", 22, 0.85, 0.95, 1, 1, "c")
    txt(ox + 482 * sc, oy + 8 * sc, "PEDAL", 10, 0.8, 0.8, 0.85, 1, "c")
    txt(ox + 80 * sc, oy + 14 * sc, "M-VAVE", 14, 0.9, 0.9, 0.95, 1, "l")
    txt(ox + 178 * sc, oy + 128 * sc, "A+B", 9, 0.6, 0.6, 0.66, 1, "c")
    txt(ox + 421 * sc, oy + 128 * sc, "C+D", 9, 0.6, 0.6, 0.66, 1, "c")
  end

  local blink = (floor(now() * 3) % 2) == 0
  for _, c in ipairs(m.ctrls) do draw_ctrl(m, c, sc, ox, oy, blink) end

  -- panneau d'infos
  local iy = H - BOT
  setc(0.13, 0.13, 0.16, 1); gfx.rect(0, iy, W, BOT, 1)
  setc(0.30, 0.31, 0.36, 1); gfx.line(0, iy, W, iy)
  local key = S.armed or S.sel
  local line1, line2
  if S.armed then
    local cfa = CFG[S.armed]
    line1 = "ARME : appuyez sur le pedalier (MIDI learn) et cliquez un pad du Launchpad / un knob du Fighter (ou clic droit > liste).  Echap = annuler."
    line2 = string.format("%s    Action : %s", bind_str(cfa), cfa and cfa.act and (cfa.act.label or cfa.act.name) or "-")
  elseif key then
    local cf = CFG[key]
    local id = key:match(":(.*)$") or key
    line1 = "Controle " .. id .. "   " .. bind_str(cf) .. (cf and cf.dev and cf.dev ~= "" and ("   [" .. cf.dev .. "]") or "")
    if cf and cf.act then
      local a = cf.act
      line2 = string.format("Action : %s   |   Mode : %s   |   Cible : %s", a.label or a.name, MODE_NAME[cf.mode] or cf.mode, (a.tgt and a.tgt > 0) and ("looper " .. a.tgt) or "looper selectionne")
      if a.t == "par" then line2 = line2 .. string.format("   |   ON=%g OFF=%g", a.von, a.voff) end
    else line2 = "Aucune action  (clic droit pour choisir)" end
  else
    line1 = S.prog and "Mode PROG : cliquez un switch pour l'armer." or "Cliquez un switch pour le tester ; clic droit = reglages ; PROG pour programmer."
    line2 = "Pastille verte = MIDI appris, bleue = action assignee."
  end
  txt(10, iy + 8, line1, 12, 0.92, 0.92, 0.96, 1, "l", W - 20)
  txt(10, iy + 28, line2, 12, 0.75, 0.85, 1, 1, "l", W - 20)
  if now() - S.msg_t < 5 then txt(10, iy + 54, S.msg, 12, 1, 0.85, 0.35, 1, "l", W - 20) end
  if S.prog then
    setc(0.85, 0.2, 0.2, 1); gfx.rect(0, 0, W, 3, 1); gfx.rect(0, H - 3, W, 3, 1)
  end
  return m, sc, ox, oy
end

--------------------------------------------------------------------------
-- Boucle principale
--------------------------------------------------------------------------
local drag_key, drag_ctrl, drag_geom
local ext_t = 0
local function save_window()
  local t = now(); if t - ext_t < 1 then return end; ext_t = t
  local d, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
  r.SetExtState(EXT, "win", string.format("%d,%d,%d,%d,%d", floor(d or 0), floor(x), floor(y), floor(w), floor(h)), true)
end

local function frame()
  local ch = gfx.getchar()
  if ch < 0 then save_all(); return false end
  if ch == 27 then if S.armed then S.armed = nil; say("Armement annule") end end
  W, H = max(gfx.w, 500), max(gfx.h, 380)

  local cap = gfx.mouse_cap
  LDOWN = ((cap & 1) == 1) and not wasL
  RDOWN = ((cap & 2) == 2) and not wasR
  local lheld = (cap & 1) == 1
  local lup = (not lheld) and wasL
  wasL, wasR = lheld, (cap & 2) == 2

  for _, ev in ipairs(poll_midi()) do handle_midi(ev) end
  poll_capture()

  local m, sc, ox, oy = draw_all()
  -- clics sur les controles
  local mx, my = gfx.mouse_x, gfx.mouse_y
  if (LDOWN or RDOWN) and my > TOP then
    for _, c in ipairs(m.ctrls) do
      if hit(c, sc, ox, oy, mx, my) then
        local key = m.id .. ":" .. c.id
        if RDOWN then
          S.sel = key
          context_menu(key, c)
        else
          S.sel = key
          if S.prog then
            if S.armed == key then S.armed = nil
            else S.armed = key; S.arm_t = now(); cfg_of(key, true) end
          else
            local cf = cfg_of(key, true)
            if c.kind == "exp" then drag_key, drag_ctrl, drag_geom = key, c, { sc, ox, oy }
            else rt(key).pressed = true; drag_key = key; trigger(key, cf, c, true, 127) end
          end
        end
        break
      end
    end
  end
  -- glisser une pedale d'expression virtuelle / relacher un switch virtuel
  if drag_key then
    local c = drag_ctrl
    local cf = cfg_of(drag_key, true)
    if c and c.kind == "exp" and lheld then
      local x, y, w, h = ctrl_rect(c, drag_geom[1], drag_geom[2], drag_geom[3])
      local n = (c.orient == "v") and (1 - (my - y) / h) or ((mx - x) / w)
      n = clamp(n, 0, 1)
      rt(drag_key).vfrac = n
      trigger(drag_key, cf, c, true, n * 127)
    elseif lup or not lheld then
      if not (c and c.kind == "exp") then
        rt(drag_key).pressed = false
        local mm = m
        for _, cc in ipairs(mm.ctrls) do
          if mm.id .. ":" .. cc.id == drag_key then trigger(drag_key, cf, cc, false, 0) end
        end
      end
      drag_key, drag_ctrl = nil, nil
    end
  end
  save_window()
  return true
end

local function loop()
  if frame() then r.defer(loop) else r.SetExtState(EXT, "armed_hb", "0", false) end
end

local function start()
  load_all()
  local w = r.GetExtState(EXT, "win")
  local d, x, y, ww, hh = 0, 100, 100, W, H
  if w ~= "" then
    local p = split(w, ",")
    d, x, y, ww, hh = tonumber(p[1]) or 0, tonumber(p[2]) or 100, tonumber(p[3]) or 100, tonumber(p[4]) or W, tonumber(p[5]) or H
    if ww < 500 then ww = W end; if hh < 380 then hh = H end
  end
  gfx.init("NowUndo Virtual Pedal Board", ww, hh, d, x, y)
  r.atexit(function() save_all(); r.SetExtState(EXT, "armed_hb", "0", false) end)
  loop()
end

start()
