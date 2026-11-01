-- @description NowUndo MIDI Learn — Launchpad + Twister
-- @version 1.3
-- @about
--   Mapping MIDI pour actions NowUndo + navigation + 16 knobs / 16 boutons Twister.
--
--   Twister : 16 knobs + 16 push appris ici ; le script Twister lit les maps
--   et applique selon fighter_page (page active).
--
--   Actions -> gmem direct. Navigation -> ExtState (VL suit si lance).
--   Ports Launchpad ignores. Zoom UI : + / - ou Ctrl+molette.
--
--   ExtState "NowUndo_MIDILearn".

local EXT = "NowUndo_MIDILearn"
local VL_SEC = "nowundo_vl"
local GMEM = "nowundo_sync"
local DASH_BASE = 6000
local IGNORE_DEV_SUBSTR = { "lpminimk3", "launchpad", "lpmini" }

local W, H = 980, 700
local ui_scale = tonumber(reaper.GetExtState(EXT, "ui_scale")) or 1.25
if ui_scale < 0.85 then ui_scale = 0.85 end
if ui_scale > 2.5 then ui_scale = 2.5 end

local function S(v) return math.floor(v * ui_scale + 0.5) end

local function layout_cols()
  return {
    { id = "name",  x = S(8),   w = S(240), title = "Fonction" },
    { id = "cat",   x = S(252), w = S(100), title = "Groupe" },
    { id = "midi",  x = S(358), w = S(160), title = "MIDI" },
    { id = "learn", x = S(526), w = S(80),  title = "Learn" },
    { id = "ret",   x = S(614), w = S(60),  title = "Return" },
    { id = "gate",  x = S(680), w = S(55),  title = "Gate" },
    { id = "clear", x = S(742), w = S(55),  title = "Clear" },
  }
end

--------------------------------------------------------------------------
-- Catalogue
--------------------------------------------------------------------------
local function A(id, name, cat, action, args, toggle)
  return { id = id, name = name, cat = cat, kind = "action", action = action, args = args, toggle = toggle and true or false }
end
local function U(id, name, cat, ui)
  return { id = id, name = name, cat = cat, kind = "ui", ui = ui }
end

local TARGETS = {}

for i = 1, 8 do
  TARGETS[#TARGETS + 1] = U("sel:L" .. i, "Select L" .. i, "Selection", { sel_looper = i })
end
for g = 1, 4 do
  TARGETS[#TARGETS + 1] = U("sel:G" .. g, "Select Group " .. g, "Selection", { sel_group = g })
end
for p = 1, 4 do
  TARGETS[#TARGETS + 1] = U("page:" .. p, "Launchpad Page " .. p, "Pages", { page = p })
end
local FIGHTER_NAMES = { "In/Out", "Pitch/Speed", "Vol/Fdbk", "Slicer", "Cloud" }
for n = 1, 5 do
  TARGETS[#TARGETS + 1] = U("fighter:" .. n, "Twister page " .. n .. " (" .. FIGHTER_NAMES[n] .. ")", "Pages", { fighter = n })
end
for i = 1, 8 do
  TARGETS[#TARGETS + 1] = U("status:" .. i, "Status L" .. i .. " (smart)", "Status", { status = i })
end

local acts = {
  A("act:rec", "Rec / Overdub", "Transport", "rec_overdub", nil, true),
  A("act:stop_play", "Stop / Play", "Transport", "stop_play", nil, true),
  A("act:replace", "Replace", "Transport", "replace", nil, true),
  A("act:multiply", "Multiply", "Transport", "multiply", nil, true),
  A("act:rerec", "Re-Rec", "Transport", "rerec"),
  A("act:restart", "Restart", "Transport", "restart"),
  A("act:clear", "Clear (part)", "Transport", "clear"),
  A("act:clear_full", "Clear Full (3 parts)", "Transport", "clear_full"),
  A("act:clear_all", "Clear All", "Transport", "clear_all"),
  A("act:clear_all_full", "Clear All Full", "Transport", "clear_all_full"),
  A("act:undo", "Undo", "Transport", "undo"),
  A("act:redo", "Redo", "Transport", "redo"),
  A("act:reverse", "Reverse", "Modes", "reverse", nil, true),
  A("act:auto_rev", "Auto Reverse", "Modes", "auto_rev", nil, true),
  A("act:slicer", "Slicer", "Modes", "slicer", nil, true),
  A("act:cloud", "Cloud", "Modes", "cloud", nil, true),
  A("act:one_shot", "One-Shot", "Modes", "one_shot", nil, true),
  A("act:link", "Link P/S", "Modes", "link", nil, true),
  A("act:auto", "Auto Rec", "Modes", "auto", nil, true),
  A("act:part1", "Part Main", "Parts", "part", 1),
  A("act:part2", "Part Chorus", "Parts", "part", 2),
  A("act:part3", "Part Bridge", "Parts", "part", 3),
  A("act:speed_m", "Speed -1 oct", "Tune", "speed_step", -12),
  A("act:speed_p", "Speed +1 oct", "Tune", "speed_step", 12),
  A("act:pitch_m", "Pitch -12 st", "Tune", "pitch_step", -12),
  A("act:pitch_p", "Pitch +12 st", "Tune", "pitch_step", 12),
  A("act:full_loop", "Full Loop", "Tune", "full_loop"),
  A("act:quant", "Quantise In/Out", "Tune", "quantise_inout"),
  A("act:reset", "Reset params", "Tune", "reset"),
  A("act:launch_go", "Launch GO", "Launch", "launch_go"),
  A("act:launch_cancel", "Launch Cancel", "Launch", "launch_cancel"),
  A("act:sync", "Sync Toggle", "Launch", "sync_toggle"),
}
for _, a in ipairs(acts) do TARGETS[#TARGETS + 1] = a end

-- Un seul jeu physique Twister : 16 knobs + 16 push (page = fighter active)
for idx = 0, 15 do
  local row, col = math.floor(idx / 4) + 1, (idx % 4) + 1
  TARGETS[#TARGETS + 1] = {
    id = string.format("tw:knob:%d", idx),
    name = string.format("Twister Knob %d (r%d c%d)", idx + 1, row, col),
    cat = "Twister",
    kind = "tw_knob",
    idx = idx,
  }
  TARGETS[#TARGETS + 1] = {
    id = string.format("tw:btn:%d", idx),
    name = string.format("Twister Push %d (r%d c%d)", idx + 1, row, col),
    cat = "Twister",
    kind = "tw_btn",
    idx = idx,
  }
end

local BY_ID = {}
for _, t in ipairs(TARGETS) do BY_ID[t.id] = t end

local CMD = {
  rec_overdub = 1, clear = 2, clear_part = 2, stop_play = 3,
  reverse = 4, auto_rev = 5, slicer = 6, cloud = 7, link = 8,
  replace = 9, auto_rep = 10, clear_full = 11, part = 12,
  multiply = 13, undo = 14, redo = 15, restart = 16, rerec = 17,
  one_shot = 18, auto = 19, speed_step = 20, pitch_step = 21,
  full_loop = 22, quantise_inout = 23, clear_all = 2, clear_all_full = 11,
}

--------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------
local maps = {}
local learn_id, learn_armed_t = nil, 0
local scroll, filter = 0, ""
local status_msg, status_t = "", 0
local midi_out_idx, last_seq = -1, 0
local last_cap = 0

local function notify(msg)
  status_msg = msg
  status_t = reaper.time_precise()
end

local function save_maps()
  local lines = {}
  for id, m in pairs(maps) do
    lines[#lines + 1] = string.format("%s|%d|%d|%d|%d|%d|%d",
      id, m.status or 0, m.ch or 0, m.d1 or 0, m.d2 or -1,
      m.ret and 1 or 0, m.gate and 1 or 0)
  end
  table.sort(lines)
  reaper.SetExtState(EXT, "maps", table.concat(lines, "\n"), true)
  reaper.SetExtState(EXT, "midi_out", tostring(midi_out_idx), true)
  reaper.SetExtState(EXT, "ui_scale", tostring(ui_scale), true)
end

local function load_maps()
  maps = {}
  local raw = reaper.GetExtState(EXT, "maps") or ""
  for line in raw:gmatch("[^\n]+") do
    local id, st, ch, d1, d2, ret, gate = line:match("^([^|]+)|(%d+)|(%d+)|(%d+)|(%-?%d+)|(%d+)|(%d+)$")
    if id and BY_ID[id] then
      maps[id] = {
        status = tonumber(st), ch = tonumber(ch), d1 = tonumber(d1),
        d2 = tonumber(d2), ret = ret == "1", gate = gate == "1",
      }
    end
  end
  midi_out_idx = tonumber(reaper.GetExtState(EXT, "midi_out")) or -1
end

local function fighter_page()
  local p = tonumber(reaper.GetExtState(VL_SEC, "fighter_page")) or 1
  return math.max(1, math.min(5, math.floor(p)))
end

--------------------------------------------------------------------------
-- MIDI helpers
--------------------------------------------------------------------------
local function fmt_midi(m)
  if not m or not m.status then return "—" end
  local st = m.status
  if st == 0x90 or st == 0x80 then
    return string.format("Note ch%d n%d", m.ch + 1, m.d1)
  elseif st == 0xB0 then
    return string.format("CC ch%d #%d", m.ch + 1, m.d1)
  end
  return string.format("%02X ch%d %d", st, m.ch + 1, m.d1)
end

-- CSV : id,name,cat,status,ch,d1,d2,return,gate,midi
local function browse_save_csv()
  -- 1) extension js_ReaScriptAPI (recommandee)
  if reaper.JS_Dialog_BrowseForSaveFile then
    local rv, file = reaper.JS_Dialog_BrowseForSaveFile(
      "Exporter MIDI Learn (CSV)", "", "nowundo_midi_learn.csv",
      "CSV files (.csv)\0*.csv\0All files\0*.*\0")
    if rv and file and file ~= "" then
      if not file:lower():match("%.csv$") then file = file .. ".csv" end
      return file
    end
    return nil
  end
  -- 2) SWS
  if reaper.BR_Win32_GetSaveFileName then
    local file = reaper.BR_Win32_GetSaveFileName("Exporter MIDI Learn (CSV)", "", "CSV files|*.csv||")
    if file and file ~= "" then
      if not file:lower():match("%.csv$") then file = file .. ".csv" end
      return file
    end
    return nil
  end
  -- 3) Fallback : chemin complet a taper
  local def = "nowundo_midi_learn.csv"
  local proj = reaper.GetProjectPath("") or ""
  if proj ~= "" then
    if not proj:match("[/\\]$") then proj = proj .. "/" end
    def = proj .. "nowundo_midi_learn.csv"
  end
  local ok, fname = reaper.GetUserInputs("Export CSV — indique le chemin complet", 1,
    "Chemin complet du fichier CSV:,extrawidth=420", def)
  if ok and fname and fname ~= "" then return fname end
  return nil
end

local function export_csv()
  local fname = browse_save_csv()
  if not fname then return end
  local lines = { "id,name,cat,status,ch,d1,d2,return,gate,midi" }
  local ids = {}
  for id in pairs(maps) do ids[#ids + 1] = id end
  table.sort(ids)
  for _, id in ipairs(ids) do
    local m = maps[id]
    local t = BY_ID[id]
    local name = (t and t.name or id):gsub('"', "'")
    local cat = (t and t.cat or ""):gsub('"', "'")
    lines[#lines + 1] = string.format('%s,"%s","%s",%d,%d,%d,%d,%d,%d,"%s"',
      id, name, cat,
      m.status or 0, m.ch or 0, m.d1 or 0, m.d2 or -1,
      m.ret and 1 or 0, m.gate and 1 or 0, fmt_midi(m))
  end
  local f = io.open(fname, "w")
  if not f then
    notify("Export impossible: " .. tostring(fname))
    return
  end
  f:write(table.concat(lines, "\n") .. "\n")
  f:close()
  local short = fname:match("([^/\\]+)$") or fname
  notify("Export: " .. short .. " (" .. (#lines - 1) .. " maps)")
end

local function import_csv()
  local rv, fname = reaper.GetUserFileNameForRead("", "Importer MIDI Learn (CSV)", "csv")
  if not rv or not fname or fname == "" then return end
  local f = io.open(fname, "r")
  if not f then
    notify("Import impossible: " .. tostring(fname))
    return
  end
  local content = f:read("*a") or ""
  f:close()
  local n, first = 0, true
  for line in content:gmatch("[^\r\n]+") do
    if first then
      first = false
      if line:lower():find("^id,") then goto cont end
    end
    local id, st, ch, d1, d2, ret, gate = line:match(
      '^([^,]+),"[^"]*","[^"]*",(%d+),(%d+),(%d+),(%-?%d+),(%d+),(%d+)'
    )
    if not id then
      id, st, ch, d1, d2, ret, gate = line:match(
        "^([^,]+),[^,]*,[^,]*,(%d+),(%d+),(%d+),(%-?%d+),(%d+),(%d+)"
      )
    end
    if id and BY_ID[id] then
      maps[id] = {
        status = tonumber(st), ch = tonumber(ch), d1 = tonumber(d1),
        d2 = tonumber(d2), ret = ret == "1", gate = gate == "1",
      }
      n = n + 1
    end
    ::cont::
  end
  save_maps()
  notify(string.format("Import: %d mappings", n))
end


local function send_return(m, vel_or_val)
  if not m or not m.ret or midi_out_idx < 0 then return end
  if not reaper.SendMIDIMessageToHardware then return end
  local d2 = math.max(0, math.min(127, math.floor(vel_or_val or 0)))
  if m.status == 0x90 or m.status == 0x80 then
    pcall(reaper.SendMIDIMessageToHardware, midi_out_idx, string.char(0x90 + m.ch, m.d1, d2))
  elseif m.status == 0xB0 then
    pcall(reaper.SendMIDIMessageToHardware, midi_out_idx, string.char(0xB0 + m.ch, m.d1, d2))
  end
end

--------------------------------------------------------------------------
-- gmem engine
--------------------------------------------------------------------------
local function gbase(looper, part)
  return 1000 + (looper - 1) * 600 + ((part or 1) - 1) * 200
end

local function alive(i)
  reaper.gmem_attach(GMEM)
  if (reaper.gmem_read(1000 + (i - 1) * 600) or 0) <= 0 then return false end
  if (reaper.time_precise() - (reaper.gmem_read(130 + (i - 1)) or 0)) > 3.0 then return false end
  return true
end

local function sel_looper()
  return math.max(1, math.min(8, tonumber(reaper.GetExtState(VL_SEC, "sel_looper")) or 1))
end

local function sel_group()
  return math.max(0, math.min(4, tonumber(reaper.GetExtState(VL_SEC, "sel_group")) or 0))
end

local function group_of(i)
  reaper.gmem_attach(GMEM)
  local g = math.floor((reaper.gmem_read(DASH_BASE + i) or 0) + 0.5)
  return (g >= 1 and g <= 4) and g or 0
end

local function targets()
  local g = sel_group()
  if g > 0 then
    local t = {}
    for i = 1, 8 do if group_of(i) == g then t[#t + 1] = i end end
    if #t > 0 then return t end
  end
  return { sel_looper() }
end

local function active_part(looper)
  local ap = reaper.gmem_read(gbase(looper, 1) + 42) or 1
  if ap < 1 or ap > 3 then ap = 1 end
  return ap
end

local function write_cmd(looper, cmd, arg)
  if not cmd then return end
  reaper.gmem_attach(GMEM)
  local b = gbase(looper, active_part(looper))
  if arg ~= nil then reaper.gmem_write(b + 49, arg) end
  reaper.gmem_write(b + 48, cmd)
end

local function write_param(looper, id, value)
  reaper.gmem_attach(GMEM)
  local b = gbase(looper, active_part(looper))
  reaper.gmem_write(b + 181, value)
  reaper.gmem_write(b + 180, id)
end

local function fire_action(action, args)
  if action == "launch_go" or action == "launch_cancel" or action == "sync_toggle" then
    reaper.SetExtState(VL_SEC, "midi_ui", action, false)
    return
  end
  local cmd = CMD[action]
  if action == "clear_all" or action == "clear_all_full" then
    for i = 1, 8 do if alive(i) then write_cmd(i, cmd) end end
    return
  end
  for _, i in ipairs(targets()) do
    if alive(i) then write_cmd(i, cmd, args) end
  end
end

local function fire_ui(ui)
  if ui.sel_looper then
    reaper.SetExtState(VL_SEC, "sel_looper", tostring(ui.sel_looper), false)
    reaper.SetExtState(VL_SEC, "midi_ui", "sel_looper:" .. ui.sel_looper, false)
  end
  if ui.sel_group then
    reaper.SetExtState(VL_SEC, "sel_group", tostring(ui.sel_group), false)
    reaper.SetExtState(VL_SEC, "midi_ui", "sel_group:" .. ui.sel_group, false)
  end
  if ui.page then reaper.SetExtState(VL_SEC, "midi_ui", "page:" .. ui.page, false) end
  if ui.fighter then
    reaper.SetExtState(VL_SEC, "fighter_page", tostring(ui.fighter), false)
    reaper.SetExtState(VL_SEC, "midi_ui", "fighter:" .. ui.fighter, false)
  end
  if ui.status then reaper.SetExtState(VL_SEC, "midi_ui", "status:" .. ui.status, false) end
end

-- Page active → parametre pour knob idx 0..15
local function tw_apply_knob(idx, norm)
  local page = fighter_page()
  reaper.gmem_attach(GMEM)
  if page == 1 then
    local looper = math.floor(idx / 2) + 1
    local is_out = (idx % 2) == 1
    if not alive(looper) then return end
    local b = gbase(looper, active_part(looper))
    local len = reaper.gmem_read(b + 46) or 0
    if len <= 0 then return end
    local in_s = reaper.gmem_read(b + 44) or 0
    local w_s = reaper.gmem_read(b + 45) or 0
    if is_out then
      local out = math.max(in_s, math.min(len, norm * len))
      reaper.gmem_write(b + 162, out)
      reaper.gmem_write(b + 160, 2)
    else
      local out = in_s + w_s
      local new_in = math.max(0, math.min(out, norm * len))
      reaper.gmem_write(b + 161, new_in)
      reaper.gmem_write(b + 160, 1)
    end
  elseif page == 2 then
    local looper = (idx % 8) + 1
    if not alive(looper) then return end
    if idx < 8 then write_param(looper, 4, norm * 96 - 48)
    else write_param(looper, 3, 2 ^ (norm * 4 - 2)) end
  elseif page == 3 then
    local looper = (idx % 8) + 1
    if not alive(looper) then return end
    if idx < 8 then write_param(looper, 22, norm * 2)
    else write_param(looper, 19, norm * 2) end
  elseif page == 4 then
    local map = {
      [0] = {50, 0.01, 0.8}, [1] = {51, 30, 1000}, [2] = {16, 10, 2000}, [3] = {34, 0, 100},
      [4] = {47, 1, 32}, [5] = {48, 0, 64}, [6] = {49, 1, 4}, [7] = {14, 0, 5},
      [8] = {15, 0, 5}, [9] = {32, 0, 1},
      [12] = {42, 0, 127}, [13] = {44, 0, 3000}, [15] = {43, 0, 1},
    }
    local spec = map[idx]
    if not spec then return end
    local v = spec[2] + norm * (spec[3] - spec[2])
    for _, i in ipairs(targets()) do if alive(i) then write_param(i, spec[1], v) end end
  elseif page == 5 then
    local map = {
      [0] = {26, 0, 1}, [1] = {27, 0, 1}, [2] = {28, 0, 1}, [3] = {35, 0, 100},
      [4] = {38, 0, 100}, [5] = {40, 0.1, 4}, [6] = {41, 0, 100}, [7] = {39, 0, 2},
    }
    local spec = map[idx]
    if not spec then return end
    local v = spec[2] + norm * (spec[3] - spec[2])
    for _, i in ipairs(targets()) do if alive(i) then write_param(i, spec[1], v) end end
  end
end

local function tw_apply_btn(idx, down)
  if not down then return end
  local page = fighter_page()
  if page == 1 then
    local looper = math.floor(idx / 2) + 1
    local is_out = (idx % 2) == 1
    if not alive(looper) or is_out then return end
    local b = gbase(looper, active_part(looper))
    local len = reaper.gmem_read(b + 46) or 0
    if len > 0 then
      reaper.gmem_write(b + 161, 0); reaper.gmem_write(b + 160, 1)
      reaper.gmem_write(b + 162, len); reaper.gmem_write(b + 160, 2)
    end
  elseif page == 2 then
    local looper = (idx % 8) + 1
    if not alive(looper) then return end
    if idx < 8 then write_param(looper, 4, 0) else write_param(looper, 3, 1) end
  elseif page == 3 then
    local looper = (idx % 8) + 1
    if not alive(looper) then return end
    if idx < 8 then write_param(looper, 22, 1) else write_param(looper, 19, 1) end
  end
end

local function execute_target(tgt, m, velocity, is_on, is_off)
  if tgt.kind == "action" then
    if m.gate then
      if is_on or is_off then fire_action(tgt.action, tgt.args) end
    else
      if is_on then fire_action(tgt.action, tgt.args) end
    end
  elseif tgt.kind == "ui" then
    if is_on then fire_ui(tgt.ui) end
  elseif tgt.kind == "tw_knob" or tgt.kind == "tw_btn" then
    -- Applique par le script Twister (lit les memes maps ExtState)
    -- Ici on ne fait que stocker le mapping au learn.
  end
  if is_on then send_return(m, 127) end
  if is_off then send_return(m, 0) end
end

--------------------------------------------------------------------------
-- MIDI poll
--------------------------------------------------------------------------
local function parse_midi_msg(msg)
  if not msg or #msg < 2 then return nil end
  local b1 = msg:byte(1)
  local st, ch = b1 & 0xF0, b1 & 0x0F
  local d1, d2 = msg:byte(2) or 0, msg:byte(3) or 0
  if st == 0x80 then return { status = 0x90, ch = ch, d1 = d1, d2 = 0, note_off = true } end
  if st == 0x90 or st == 0xB0 then return { status = st, ch = ch, d1 = d1, d2 = d2 } end
  return nil
end

local function process_midi()
  if not reaper.MIDI_GetRecentInputEvent then return end
  local i = 0
  while i < 64 do
    local seq, msg, ts, dev = reaper.MIDI_GetRecentInputEvent(i)
    if not seq or seq == 0 then break end
    if seq == last_seq and i == 0 then break end
    if last_seq ~= 0 and seq <= last_seq then break end

    local skip_dev = false
    if dev and type(dev) == "number" and reaper.GetMIDIInputName then
      local ok, dname = reaper.GetMIDIInputName(dev, "")
      if ok and dname then
        local low = dname:lower()
        for _, sub in ipairs(IGNORE_DEV_SUBSTR) do
          if low:find(sub, 1, true) then skip_dev = true; break end
        end
      end
    end

    if not skip_dev then
      local ev = parse_midi_msg(msg)
      if ev then
        if learn_id and reaper.time_precise() - learn_armed_t > 0.05 then
          local ignore_note_off = ev.note_off or (ev.status == 0x90 and ev.d2 == 0)
          if not ignore_note_off then
            maps[learn_id] = {
              status = ev.status, ch = ev.ch, d1 = ev.d1, d2 = -1,
              ret = maps[learn_id] and maps[learn_id].ret or false,
              gate = maps[learn_id] and maps[learn_id].gate or false,
            }
            notify("Learned " .. (BY_ID[learn_id] and BY_ID[learn_id].name or learn_id) .. " ← " .. fmt_midi(maps[learn_id]))
            learn_id = nil
            save_maps()
          end
        else
          for id, m in pairs(maps) do
            if m.status == ev.status and m.ch == ev.ch and m.d1 == ev.d1 then
              local tgt = BY_ID[id]
              if tgt then
                local is_on, is_off = false, false
                if ev.status == 0x90 then
                  if ev.note_off or ev.d2 == 0 then is_off = true else is_on = true end
                elseif ev.status == 0xB0 then
                  if m.gate then
                    if ev.d2 > 0 then is_on = true else is_off = true end
                  else
                    if ev.d2 > 0 then is_on = true end
                  end
                end
                if tgt.kind == "tw_knob" and ev.status == 0xB0 then
                  execute_target(tgt, m, ev.d2, true, false)
                else
                  execute_target(tgt, m, ev.d2, is_on, is_off)
                end
              end
            end
          end
        end
      end
    end
    if i == 0 then last_seq = seq end
    i = i + 1
  end
  local seq0 = reaper.MIDI_GetRecentInputEvent(0)
  if seq0 and seq0 > 0 then last_seq = seq0 end
end

--------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------
local function filtered_list()
  local out, f = {}, filter:lower()
  for _, t in ipairs(TARGETS) do
    if f == "" or t.name:lower():find(f, 1, true) or t.cat:lower():find(f, 1, true) then
      out[#out + 1] = t
    end
  end
  return out
end

local function hit_col(x, cols)
  for _, c in ipairs(cols) do
    if x >= c.x and x < c.x + c.w then return c.id end
  end
end

local function mouse_click()
  local cap = gfx.mouse_cap
  local c = (cap & 1) == 1 and (last_cap & 1) == 0
  last_cap = cap
  return c
end

local function set_zoom(delta)
  ui_scale = math.max(0.85, math.min(2.5, ui_scale + delta))
  reaper.SetExtState(EXT, "ui_scale", tostring(ui_scale), true)
  notify(string.format("Zoom %.0f%%", ui_scale * 100))
end

local function draw()
  local w, h = gfx.w, gfx.h
  local ROW_H = S(26)
  local HEADER_H = S(58)
  local COLS = layout_cols()
  local font_title = S(17)
  local font_body = S(13)
  local font_small = S(12)

  gfx.set(0.10, 0.10, 0.12)
  gfx.rect(0, 0, w, h, 1)

  gfx.set(0.14, 0.14, 0.16)
  gfx.rect(0, 0, w, HEADER_H, 1)
  gfx.setfont(1, "Arial", font_title, "b")
  gfx.set(0.95, 0.45, 0.40)
  gfx.x, gfx.y = S(10), S(6)
  gfx.drawstr("NowUndo MIDI Learn")

  local nmap = 0
  for _ in pairs(maps) do nmap = nmap + 1 end
  gfx.setfont(1, "Arial", font_small)
  gfx.set(0.7, 0.7, 0.7)
  gfx.x, gfx.y = S(220), S(8)
  gfx.drawstr(string.format("%d maps  |  Twister page %d (%s)  |  zoom %.0f%%",
    nmap, fighter_page(), FIGHTER_NAMES[fighter_page()] or "?", ui_scale * 100))

  if learn_id then
    gfx.set(1, 0.4, 0.2)
    gfx.x, gfx.y = S(10), S(32)
    gfx.drawstr("LEARNING: " .. (BY_ID[learn_id] and BY_ID[learn_id].name or learn_id) .. " — note ou CC…")
  elseif status_msg ~= "" and reaper.time_precise() - status_t < 3 then
    gfx.set(0.5, 0.9, 0.6)
    gfx.x, gfx.y = S(10), S(32)
    gfx.drawstr(status_msg)
  else
    gfx.set(0.55, 0.55, 0.6)
    gfx.x, gfx.y = S(10), S(32)
    gfx.drawstr("+/- zoom  |  F filtre  |  S sauver  |  E/I CSV  |  O MIDI OUT  |  Esc annule learn")
  end

  local y0 = HEADER_H
  gfx.set(0.18, 0.18, 0.20)
  gfx.rect(0, y0, w, ROW_H, 1)
  gfx.setfont(1, "Arial", font_body, "b")
  gfx.set(0.8, 0.8, 0.85)
  for _, c in ipairs(COLS) do
    gfx.x, gfx.y = c.x, y0 + S(5)
    gfx.drawstr(c.title)
  end

  local list = filtered_list()
  local visible = math.floor((h - y0 - ROW_H - S(8)) / ROW_H)
  if visible < 1 then visible = 1 end
  if scroll > math.max(0, #list - visible) then scroll = math.max(0, #list - visible) end
  if scroll < 0 then scroll = 0 end

  local mx, my = gfx.mouse_x, gfx.mouse_y
  local clicked = mouse_click()

  gfx.setfont(1, "Arial", font_body)
  for row = 0, visible - 1 do
    local idx = scroll + row + 1
    local t = list[idx]
    if not t then break end
    local y = y0 + ROW_H + row * ROW_H
    local hover = my >= y and my < y + ROW_H
    if learn_id == t.id then gfx.set(0.35, 0.18, 0.12)
    elseif hover then gfx.set(0.16, 0.16, 0.19)
    elseif row % 2 == 0 then gfx.set(0.12, 0.12, 0.14)
    else gfx.set(0.11, 0.11, 0.13) end
    gfx.rect(0, y, w, ROW_H, 1)

    local m = maps[t.id]
    gfx.set(0.92, 0.92, 0.92)
    gfx.x, gfx.y = COLS[1].x, y + S(5)
    gfx.drawstr(t.name)
    gfx.set(0.6, 0.65, 0.7)
    gfx.x = COLS[2].x
    gfx.drawstr(t.cat)
    gfx.set(m and 0.4 or 0.45, m and 0.85 or 0.45, m and 0.55 or 0.5)
    gfx.x = COLS[3].x
    gfx.drawstr(fmt_midi(m))

    local lx, lw = COLS[4].x, COLS[4].w - S(6)
    local learning = learn_id == t.id
    gfx.set(learning and 0.9 or 0.25, learning and 0.35 or 0.25, learning and 0.2 or 0.28)
    gfx.rect(lx, y + S(4), lw, ROW_H - S(8), 1)
    gfx.set(1, 1, 1)
    gfx.x, gfx.y = lx + S(12), y + S(5)
    gfx.drawstr(learning and "..." or "Learn")

    local rx = COLS[5].x + S(18)
    local ret_on = m and m.ret
    gfx.set(ret_on and 0.2 or 0.25, ret_on and 0.7 or 0.25, ret_on and 0.4 or 0.28)
    gfx.rect(rx, y + S(6), S(16), S(16), 1)
    if ret_on then gfx.set(1, 1, 1); gfx.x, gfx.y = rx + S(3), y + S(5); gfx.drawstr("✓") end

    local gx = COLS[6].x + S(16)
    local gate_on = m and m.gate
    gfx.set(gate_on and 0.7 or 0.25, gate_on and 0.5 or 0.25, gate_on and 0.2 or 0.28)
    gfx.rect(gx, y + S(6), S(16), S(16), 1)
    if gate_on then gfx.set(1, 1, 1); gfx.x, gfx.y = gx + S(3), y + S(5); gfx.drawstr("✓") end

    if m then
      local cx = COLS[7].x + S(6)
      gfx.set(0.35, 0.2, 0.2)
      gfx.rect(cx, y + S(4), S(44), ROW_H - S(8), 1)
      gfx.set(1, 0.7, 0.7)
      gfx.x, gfx.y = cx + S(6), y + S(5)
      gfx.drawstr("clr")
    end

    if clicked and hover then
      local col = hit_col(mx, COLS)
      if col == "learn" then
        if learn_id == t.id then learn_id = nil; notify("Learn cancelled")
        else learn_id = t.id; learn_armed_t = reaper.time_precise(); notify("Learning " .. t.name) end
      elseif col == "ret" then
        maps[t.id] = maps[t.id] or { status = 0, ch = 0, d1 = 0 }
        maps[t.id].ret = not maps[t.id].ret
        save_maps()
      elseif col == "gate" then
        maps[t.id] = maps[t.id] or { status = 0, ch = 0, d1 = 0 }
        maps[t.id].gate = not maps[t.id].gate
        save_maps()
      elseif col == "clear" and m then
        maps[t.id] = nil
        save_maps()
        notify("Cleared " .. t.name)
      end
    end
  end

  if #list > visible then
    local sb_h = h - y0 - ROW_H
    local thumb = math.max(S(20), sb_h * visible / #list)
    local max_s = math.max(1, #list - visible)
    local ty = y0 + ROW_H + (sb_h - thumb) * (scroll / max_s)
    gfx.set(0.3, 0.3, 0.35)
    gfx.rect(w - S(10), y0 + ROW_H, S(7), sb_h, 1)
    gfx.set(0.6, 0.4, 0.35)
    gfx.rect(w - S(10), ty, S(7), thumb, 1)
  end
end

--------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------

local function pick_midi_out()
  if not reaper.GetNumMIDIOutputs then
    notify("API MIDI OUT indisponible")
    return
  end
  local n = reaper.GetNumMIDIOutputs() or 0
  local menu, idxs = {}, {}
  for i = 0, n - 1 do
    local ok, name = reaper.GetMIDIOutputName(i, "")
    if ok and name then
      local mark = (i == midi_out_idx) and "!" or ""
      menu[#menu + 1] = mark .. name
      idxs[#idxs + 1] = i
    end
  end
  if #menu == 0 then notify("Aucune sortie MIDI"); return end
  menu[#menu + 1] = ""
  menu[#menu + 1] = "Aucun (desactiver return)"
  local pick = gfx.showmenu(table.concat(menu, "|"))
  if pick and pick > 0 then
    if pick <= #idxs then
      midi_out_idx = idxs[pick]
      reaper.SetExtState(EXT, "midi_out", tostring(midi_out_idx), true)
      local ok, name = reaper.GetMIDIOutputName(midi_out_idx, "")
      notify("MIDI OUT: " .. (name or tostring(midi_out_idx)))
    else
      midi_out_idx = -1
      reaper.SetExtState(EXT, "midi_out", "-1", true)
      notify("MIDI OUT desactive")
    end
  end
end

local function main()
  local char = gfx.getchar()
  if char < 0 then return end

  if char == 27 then
    learn_id = nil
  elseif char == string.byte("+") or char == string.byte("=") then
    set_zoom(0.1)
  elseif char == string.byte("-") or char == string.byte("_") then
    set_zoom(-0.1)
  elseif char == string.byte("s") or char == string.byte("S") then
    save_maps(); notify("Saved")
  elseif char == string.byte("e") or char == string.byte("E") then
    export_csv()
  elseif char == string.byte("i") or char == string.byte("I") then
    import_csv()
  elseif char == string.byte("o") or char == string.byte("O") then
    pick_midi_out()
  elseif char == string.byte("f") or char == string.byte("F") then
    local rv, txt = reaper.GetUserInputs("Filter", 1, "Texte:", filter)
    if rv then filter = txt or ""; scroll = 0 end
  elseif char == 30064 then scroll = math.max(0, scroll - 1)
  elseif char == 30065 then scroll = scroll + 1
  elseif char == 30066 then scroll = math.max(0, scroll - 10)
  elseif char == 30067 then scroll = scroll + 10
  end

  local wheel = gfx.mouse_wheel
  if wheel ~= 0 then
    if (gfx.mouse_cap & 4) ~= 0 then  -- Ctrl + molette = zoom
      set_zoom(wheel > 0 and 0.1 or -0.1)
    else
      scroll = scroll - math.floor(wheel / 20)
    end
    gfx.mouse_wheel = 0
  end

  process_midi()
  draw()
  gfx.update()
  reaper.defer(main)
end

reaper.gmem_attach(GMEM)
load_maps()
if reaper.MIDI_GetRecentInputEvent then
  last_seq = reaper.MIDI_GetRecentInputEvent(0) or 0
end
gfx.init("NowUndo MIDI Learn", W, H, 0, 100, 100)
gfx.clear = 0x1A1A1E
notify(string.format("%d fonctions | zoom +/- ou Ctrl+molette", #TARGETS))
reaper.defer(main)
