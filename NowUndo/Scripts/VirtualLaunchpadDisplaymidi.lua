--[[
  Virtual_Launchpad_secondary.lua  -  nowundo (miroir)
  Affiche les 3 pages NON selectionnees du Virtual Launchpad.
  - Redimensionnable, position / dock memorises (ExtState NowUndo_VL_Mirror).
  - Pas de rangee du haut ni de colonne de droite.
  - Page 4 suit la couche courante.
  - INTERACTIF : les pads envoient les memes actions que le controleur.
  - Sync via ExtState.

  Placez ce fichier a cote de virtuallaunchpad_main.lua (meme dossier).
]]

local MAIN_CANDIDATES = {
  "VirtualLaunchpad_LaunchpadMiniMK3_Test.lua",   -- controleur Launchpad Mini MK3 (publie page active + etat)
  "virtuallaunchpad_main.lua",           -- nom choisi par l'utilisateur
  "virtuallaunchpadvecorisecouleur.lua",
  "Virtual_Launchpad.lua",
  "Virtual_Launchpad_core.lua",
  "virtual_launchpad.lua",
}

local function candidate_dirs()
  local dirs, seen = {}, {}
  local function add(d)
    if not d or d == "" then return end
    if not d:match("[\\/]$") then d = d .. "/" end
    if not seen[d] then seen[d] = true; dirs[#dirs + 1] = d end
  end

  local ok, ctx = pcall(reaper.get_action_context)
  if ok then
    local src = select(2, reaper.get_action_context())
    if type(src) == "string" then
      local dir = src:match("^(.*)[/\\][^/\\]+$")
      if dir then add(dir) end
    end
  end

  local info = debug.getinfo(1, "S")
  if info and info.source then
    local src = info.source:gsub("^@", "")
    local dir = src:match("^(.*)[/\\][^/\\]+$")
    if dir then add(dir) end
  end

  local res = reaper.GetResourcePath and reaper.GetResourcePath() or nil
  if res then
    add(res .. "/Scripts")
    add(res .. "/Scripts/nowundo")
    add(res .. "/Scripts/NowUndo")
    add(res)
  end
  return dirs
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

local function load_vl()
  local tried = {}
  -- 1) le fichier exact publie par le controleur en cours d'execution (garantit la meme version du coeur)
  local paths = {}
  local cp = reaper.GetExtState("nowundo_vl", "core_path")
  if cp ~= "" then paths[#paths + 1] = cp end
  -- 2) sinon recherche par nom, a cote de ce script puis dans Scripts/
  for _, dir in ipairs(candidate_dirs()) do
    for _, name in ipairs(MAIN_CANDIDATES) do paths[#paths + 1] = dir .. name end
  end
  for _, path in ipairs(paths) do
    tried[#tried + 1] = path
    if file_exists(path) then
      VL_TEST = true
      local ok, result = pcall(dofile, path)
      VL_TEST = nil
      if ok and type(result) == "table" and result.build_frame then
        return result, path
      end
      tried[#tried] = path .. "  [trouve mais ne renvoie pas VL — version trop ancienne ?]"
    end
  end

  local msg = "Impossible de charger le coeur Virtual Launchpad.\n\n"
    .. "Placez CE script et le principal dans le MEME dossier.\n"
    .. "Noms attendus du principal :\n"
    .. "  • VirtualLaunchpad_LaunchpadMiniMK3_Test.lua\n"
    .. "  • virtuallaunchpad_main.lua\n"
    .. "  • virtuallaunchpadvecorisecouleur.lua\n"
    .. "  • Virtual_Launchpad.lua\n\n"
    .. "Chemins testes :\n"
  for i, p in ipairs(tried) do
    if i > 14 then msg = msg .. "  …\n"; break end
    msg = msg .. "  " .. p .. "\n"
  end
  reaper.ShowMessageBox(msg, "VL Mirror", 0)
  return nil
end

local VL, VL_PATH = load_vl()
if not VL then return end

VL.mirror_mode = true

--------------------------------------------------------------------------
local BLINK_HZ = 2
local LEVEL = { off = 0.0, idle = 0.45, on = 1.0, warn = 1.0, cursor = 1.0 }
local BLINK = {
  armed = { 1.0, 0.0 }, armed_other = { 0.8, 0.45 }, member_cursor = { 1.0, 0.45 },
}

local function hex_to_rgb(h)
  return (h >> 16) & 255, (h >> 8) & 255, h & 255
end

local function resolve_rgb(hex, state, t)
  local level = LEVEL[state] or 0
  local bl = BLINK[state]
  if bl then
    local phase = (math.floor(t * BLINK_HZ * 2) % 2 == 0)
    level = phase and bl[1] or bl[2]
  end
  local r, g, b = hex_to_rgb(hex)
  return math.floor(r * level + 0.5), math.floor(g * level + 0.5), math.floor(b * level + 0.5)
end

local function layer_name()
  local id = VL.S and VL.S.p4_layer
  if not id then return "?" end
  for _, l in ipairs(VL.layers()) do
    if l.id == id then return l.name end
  end
  return tostring(id)
end

local function frame_for_page(page)
  local saved = VL.S.page
  VL.S.page = page
  local f = VL.build_frame()
  VL.S.page = saved
  return f
end

local function page_title(p)
  if p == 4 then return string.format("PAGE 4  ·  %s", layer_name()) end
  local names = { "PAGE 1  ·  Main", "PAGE 2  ·  Routing in", "PAGE 3  ·  Routing L→L" }
  return names[p] or ("PAGE " .. p)
end

--------------------------------------------------------------------------
local ND = {}
function ND.init(title, ext, dw, dh)
  local function ld(k, d) return tonumber(reaper.GetExtState(ext, k)) or d end
  ND.ext, ND.last_t, ND.sig = ext, 0, ""
  local w, h = ld("w", dw), ld("h", dh)
  if w < 120 then w = dw end
  if h < 80 then h = dh end
  gfx.init(title, w, h, ld("dock", 0), ld("x", 120), ld("y", 120))
end
function ND.tick()
  local t = reaper.time_precise()
  if t - ND.last_t < 1 then return end
  ND.last_t = t
  local d, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
  d = math.floor(d or 0)
  local sig = d .. "," .. x .. "," .. y .. "," .. w .. "," .. h
  if sig == ND.sig then return end
  ND.sig = sig
  local e = ND.ext
  reaper.SetExtState(e, "dock", tostring(d), true)
  if d & 1 == 0 then
    reaper.SetExtState(e, "x", tostring(math.floor(x)), true)
    reaper.SetExtState(e, "y", tostring(math.floor(y)), true)
    reaper.SetExtState(e, "w", tostring(math.floor(w)), true)
    reaper.SetExtState(e, "h", tostring(math.floor(h)), true)
  end
end

--------------------------------------------------------------------------
local REF_CELL, REF_GAP, REF_MARGIN, REF_TITLE = 40, 18, 10, 22
local REF_W = REF_MARGIN * 2 + 3 * (REF_CELL * 8) + 2 * REF_GAP
local REF_H = REF_MARGIN + REF_TITLE + REF_CELL * 8 + REF_MARGIN + 28

local function layout()
  local w, h = gfx.w, gfx.h
  local s = math.max(0.45, math.min(math.min(w / REF_W, h / REF_H), 2.4))
  local CELL, GAP, MARGIN, TITLE = REF_CELL * s, REF_GAP * s, REF_MARGIN * s, REF_TITLE * s
  local total = 3 * (CELL * 8) + 2 * GAP
  return s, CELL, GAP, MARGIN, TITLE, (w - total) * 0.5, MARGIN + TITLE
end

local function layout_label(label, maxw, base_size)
  for _, size in ipairs({ base_size, base_size - 2, base_size - 3, 7 }) do
    if size < 7 then size = 7 end
    gfx.setfont(1, "Arial", size)
    local lines, cur, fits = {}, "", true
    for word in label:gmatch("%S+") do
      local first = true
      for part in word:gmatch("[^/]+/?") do
        local sep = first and " " or ""
        local try = (cur == "") and part or (cur .. sep .. part)
        if cur == "" or gfx.measurestr(try) <= maxw then cur = try
        else lines[#lines + 1] = cur; cur = part end
        first = false
      end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    for _, l in ipairs(lines) do if gfx.measurestr(l) > maxw then fits = false end end
    if fits or size <= 8 then return lines, size end
  end
  return { label }, 7
end

local function pad_at(mx, my, pages, CELL, GAP, ox, oy)
  for pi, page in ipairs(pages) do
    local grid_x = ox + (pi - 1) * (CELL * 8 + GAP)
    if mx >= grid_x and mx < grid_x + CELL * 8 and my >= oy and my < oy + CELL * 8 then
      local col = math.floor((mx - grid_x) / CELL) + 1
      local row = math.floor((my - oy) / CELL) + 1
      if col >= 1 and col <= 8 and row >= 1 and row <= 8 then return page, row, col end
    end
  end
end

--------------------------------------------------------------------------
VL.sync_enable()
ND.init("nowundo - VL Mirror (3 pages)", "NowUndo_VL_Mirror", REF_W, REF_H)

local OS = (reaper.GetOS and reaper.GetOS()) or ""
local CTRL_MASK = 4 | (OS:find("OSX") and 32 or 0)
local down_pad, last_pad, was_pressed = nil, nil, false

local function with_page(page, fn)
  local saved = VL.S.page
  VL.S.page = page
  fn()
  VL.S.page = saved
end

local function loop()
  local t = reaper.time_precise and reaper.time_precise() or os.clock()
  local ch = gfx.getchar()
  if ch == -1 or ch == 27 then gfx.quit() return end
  ND.tick()
  VL.sync_poll()

  local active = tonumber(reaper.GetExtState("nowundo_vl", "active_page")) or 1
  active = math.max(1, math.min(4, active))
  local pages = {}
  for p = 1, 4 do if p ~= active then pages[#pages + 1] = p end end

  local s, CELL, GAP, MARGIN, TITLE, ox, oy = layout()

  local cap = math.floor(gfx.mouse_cap)
  if VL.set_ctrl_hold then VL.set_ctrl_hold((cap & CTRL_MASK) ~= 0) end
  local pressed = (cap & 1) == 1
  local edge_down = pressed and not was_pressed
  local edge_up   = (not pressed) and was_pressed
  was_pressed = pressed

  if down_pad then with_page(down_pad[1], function() VL.tick(t) end) else VL.tick(t) end

  if edge_down then
    local page, row, col = pad_at(gfx.mouse_x, gfx.mouse_y, pages, CELL, GAP, ox, oy)
    if page then
      down_pad = { page, row, col }
      last_pad = { page, row, col }
      with_page(page, function() VL.on_pad_pressed(row, col, t) end)
    end
  elseif pressed and down_pad then
    local page, row, col = pad_at(gfx.mouse_x, gfx.mouse_y, pages, CELL, GAP, ox, oy)
    if page and page == down_pad[1]
       and (not last_pad or row ~= last_pad[2] or col ~= last_pad[3]) then
      last_pad = { page, row, col }
      with_page(page, function() VL.on_pad_dragged(row, col) end)
    end
  elseif edge_up and down_pad then
    with_page(down_pad[1], function() VL.on_pad_released(down_pad[2], down_pad[3], t) end)
    down_pad, last_pad = nil, nil
  end

  gfx.set(0.07, 0.07, 0.07, 1)
  gfx.rect(0, 0, gfx.w, gfx.h, 1)

  gfx.setfont(1, "Arial", math.floor(11 * s + 0.5))
  gfx.set(0.75, 0.75, 0.75, 1)
  gfx.x, gfx.y = MARGIN, 4 * s
  gfx.drawstr(string.format(
    "Miroir interactif  ·  page active controleur : %d  ·  couche P4 : %s",
    active, layer_name()))

  for pi, page in ipairs(pages) do
    local grid_x = ox + (pi - 1) * (CELL * 8 + GAP)
    local frame = frame_for_page(page)

    gfx.setfont(1, "Arial", math.floor(12 * s + 0.5))
    gfx.set(0.92, 0.92, 0.92, 1)
    gfx.x, gfx.y = grid_x, oy - TITLE + 2 * s
    gfx.drawstr(page_title(page))

    for row = 1, 8 do
      for col = 1, 8 do
        local v = frame[row .. "," .. col]
        local hex, state = 0x808080, "off"
        if v then hex, state = v[1], v[2] end
        local r, g, b = resolve_rgb(hex, state, t)
        local x = grid_x + (col - 1) * CELL
        local y = oy + (row - 1) * CELL
        local pad_s = 2.5 * s
        gfx.set(r / 255, g / 255, b / 255, 1)
        gfx.rect(x + pad_s, y + pad_s, CELL - pad_s * 2, CELL - pad_s * 2, 1)

        local label = VL.pad_label(page, row, col)
        if label and label ~= "" then
          local lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255
          if lum > 0.5 then gfx.set(0.05, 0.05, 0.05, 1) else gfx.set(0.95, 0.95, 0.95, 1) end
          local lines, size = layout_label(label, CELL - 6 * s, math.floor(9 * s + 0.5))
          local lh = size + 1.5 * s
          local y0 = y + (CELL - #lines * lh) / 2
          for i, l in ipairs(lines) do
            gfx.x = x + (CELL - gfx.measurestr(l)) / 2
            gfx.y = y0 + (i - 1) * lh
            gfx.drawstr(l)
          end
        end
      end
    end

    if pi < 3 then
      local sx = grid_x + CELL * 8 + GAP * 0.5
      gfx.set(0.18, 0.18, 0.18, 1)
      gfx.line(sx, oy, sx, oy + CELL * 8)
    end
  end

  gfx.setfont(1, "Arial", math.floor(10 * s + 0.5))
  gfx.set(0.55, 0.55, 0.55, 1)
  gfx.x, gfx.y = MARGIN, oy + CELL * 8 + 6 * s
  gfx.drawstr("Pads actifs — memes actions que le controleur (sync automatique)")

  -- Diagnostic de la liaison avec le controleur
  local rev = reaper.GetExtState("nowundo_vl", "rev")
  local st  = reaper.GetExtState("nowundo_vl", "state")
  local cv  = st:match('%["_v"%]="([^"]*)"')
  local raw = reaper.GetExtState("nowundo_vl", "active_page")
  local hb  = tonumber(reaper.GetExtState("nowundo_vl", "heartbeat"))
  local age = hb and (t - hb) or nil
  local bad, diag = true, nil
  if rev == "" then diag = "AUCUN controleur ne publie (ancien script Test encore actif ?) : relance VirtualLaunchpad_LaunchpadMiniMK3_Test.lua"
  elseif cv and cv ~= VL.VERSION then diag = "VERSIONS DIFFERENTES : controleur " .. cv .. " / display " .. tostring(VL.VERSION)
  elseif raw == "" then diag = "le controleur ne publie PAS la page active (ancienne version du script ?)"
  elseif not hb then diag = "pas de battement de coeur : controleur ancien ou bloque"
  elseif age > 2 then diag = string.format("controleur SILENCIEUX depuis %.0f s (script arrete ?)", age)
  else bad, diag = false, "synchro OK" end
  diag = diag .. string.format("   |   page lue : %s   |   coeur : %s", raw == "" and "-" or raw,
    VL_PATH and VL_PATH:match("[^/\\]+$") or "?")
  if bad then gfx.set(1.0, 0.45, 0.35, 1) else gfx.set(0.45, 0.8, 0.5, 1) end
  gfx.x, gfx.y = MARGIN, oy + CELL * 8 + 6 * s + 14 * s
  gfx.drawstr(diag)

  gfx.update()
  reaper.defer(loop)
end

loop()