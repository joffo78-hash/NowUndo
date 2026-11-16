-- @description FX Router v2.8 : bibliothèque JSFX scannée, un seul effet chargé par container
-- @version 2.8
-- v2.8 : source suivie par le Launchpad ; changement d'effet sans réactivation du container ; état piloté par la matrice FX
-- Nécessite l'extension ReaImGui (ReaPack > ReaTeam Extensions > ReaImGui)

------------------------------------------------------------
-- CONFIGURATION
------------------------------------------------------------
local LIB_FOLDER         = "MonRig"  
local INPUT_FIRST_TRACK  = 2         
local LOOPER_FIRST_TRACK = 11        
local NB_SOURCES = 8
local NB_SLOTS   = 4                 -- Exactement 4 slots
local NB_PARAMS  = 4                 
------------------------------------------------------------

local shim = reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua'
if reaper.file_exists(shim) then dofile(shim)('0.9') end
if not reaper.ImGui_CreateContext then
  reaper.MB("L'extension ReaImGui est requise.", "FX Router", 0)
  return
end
local ctx = reaper.ImGui_CreateContext('FX Router')

------------------------------------------------------------
-- Sources
------------------------------------------------------------
local sources = {}
for i = 1, NB_SOURCES do
  sources[#sources + 1] = { label = "Entrée " .. i, track = INPUT_FIRST_TRACK - 1 + (i - 1), is_looper = false }
end
for i = 1, NB_SOURCES do
  sources[#sources + 1] = { label = "Looper " .. i, track = LOOPER_FIRST_TRACK - 1 + (i - 1), is_looper = true }
end
local current = tonumber(reaper.GetExtState("FXRouter", "src")) or 1
if current < 1 or current > #sources then current = 1 end

-- Le Virtual Launchpad publie la source a suivre : 1..8 = entrees, 9..16 = loopers.
local last_launchpad_source = nil
local function sync_launchpad_source()
  local raw = reaper.GetExtState("nowundo_vl", "fx_source")
  local n = tonumber(raw)
  if n and n >= 1 and n <= #sources then
    n = math.floor(n)
    if n ~= last_launchpad_source then
      current = n
      last_launchpad_source = n
      reaper.SetExtState("FXRouter", "src", tostring(n), false)
    end
  end
end

------------------------------------------------------------
-- Bibliothèque
------------------------------------------------------------
local library = {}   
local function norm(s)
  s = (s or ""):lower():gsub("\\", "/")
  s = s:gsub("^js:%s*", ""):gsub("%.jsfx$", "")
  return s
end

local function scan(rel)
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
      library[#library + 1] = { ident = ident, name = desc or f }
    end
    i = i + 1
  end
  local j = 0
  while true do
    local d = reaper.EnumerateSubdirectories(base .. rel, j)
    if not d then break end
    scan(rel .. "/" .. d)
    j = j + 1
  end
end

local function rescan()
  library = {}
  scan(LIB_FOLDER)
  table.sort(library, function(a, b) return a.name:lower() < b.name:lower() end)
end
rescan()

local function find_entry(ident)
  local n = norm(ident)
  for _, e in ipairs(library) do
    if norm(e.ident) == n then return e end
  end
end

------------------------------------------------------------
-- Utilitaires containers
------------------------------------------------------------
local function clean_name(n)
  n = n:gsub("^[%w]+i?: ", "")
  n = n:gsub("%s*%b()%s*$", "")
  n = n:gsub("%s*%b[]%s*$", "")
  return n
end

-- Méthode robuste : on cherche explicitement les containers en ignorant le 1er effet si demandé
local function get_containers(tr, is_looper)
  local list = {}
  local fx_count = reaper.TrackFX_GetCount(tr)
  local start_idx = is_looper and 1 or 0 -- Si looper, on commence à l'index 1 (le looper est à l'index 0)
  
  for i = start_idx, fx_count - 1 do
    -- On vérifie que la clé existe et que c'est un vrai container
    local retval, cnt = reaper.TrackFX_GetNamedConfigParm(tr, i, "container_count")
    if retval and cnt ~= nil then
      list[#list + 1] = i
      if #list >= NB_SLOTS then break end -- On s'arrête à 4 slots
    end
  end
  return list
end

local function get_children(tr, cidx)
  local children = {}
  local _, cnt = reaper.TrackFX_GetNamedConfigParm(tr, cidx, "container_count")
  cnt = tonumber(cnt) or 0
  for n = 0, cnt - 1 do
    local _, s = reaper.TrackFX_GetNamedConfigParm(tr, cidx, "container_item." .. n)
    local fx = tonumber(s)
    if fx then
      local _, name = reaper.TrackFX_GetFXName(tr, fx, "")
      local _, ident = reaper.TrackFX_GetNamedConfigParm(tr, fx, "fx_ident")
      children[#children + 1] = { fx = fx, name = clean_name(name), ident = ident }
    end
  end
  return children
end

local function child_addr(tr, cidx, n)
  return 0x2000000 + (n + 1) * (reaper.TrackFX_GetCount(tr) + 1) + (cidx + 1)
end

------------------------------------------------------------
-- Mémoire des réglages (conservée pour le comportement existant)
------------------------------------------------------------
local function pkey(s, ident)
  return "P_EXT:FXR_" .. s .. "_" .. norm(ident):gsub("[^%w]", "_")
end

local function save_params(tr, fx, s, ident)
  if not ident or ident == "" then return end
  local t = {}
  for p = 0, reaper.TrackFX_GetNumParams(tr, fx) - 1 do
    t[#t + 1] = string.format("%.6f", reaper.TrackFX_GetParamNormalized(tr, fx, p))
  end
  reaper.GetSetMediaTrackInfo_String(tr, pkey(s, ident), table.concat(t, ","), true)
end

local function load_params(tr, fx, s, ident)
  local ok, str = reaper.GetSetMediaTrackInfo_String(tr, pkey(s, ident), "", false)
  if not ok or str == "" then return end
  local p = 0
  for v in str:gmatch("[^,]+") do
    local n = tonumber(v)
    if n then reaper.TrackFX_SetParamNormalized(tr, fx, p, n) end
    p = p + 1
  end
end

------------------------------------------------------------
-- Utilitaires FX Router v2.6
------------------------------------------------------------
local GREEN = 0x7FD67FFF
local GREY  = 0x888888FF
local RED   = 0xFF7777FF
local CYAN  = 0x4FE3F0FF
-- Slot inactif (container ou effet bypassé) : panneaux bleu foncé "éteint"
local DARKBLUE = {
  bg      = 0x0F1B3FFF,
  bg_hov  = 0x16275AFF,
  bg_act  = 0x1C3270FF,
  grab    = 0x2C4C9CFF,
  grab_ac = 0x3A62C4FF,
  button  = 0x1A2D66FF,
}
local clipboard_set = nil
local clear_popup_requested = false
local first_frame = true
local last_saved_geometry = ""

local function get_geometry()
  local x, y = reaper.ImGui_GetWindowPos(ctx)
  local w, h = reaper.ImGui_GetWindowSize(ctx)
  return x, y, w, h
end

local function save_geometry(force)
  local x, y, w, h = get_geometry()
  local value = string.format("%.1f,%.1f,%.1f,%.1f", x, y, w, h)
  if force or value ~= last_saved_geometry then
    reaper.SetExtState("FXRouter", "window_geometry", value, true)
    last_saved_geometry = value
  end
end

local function load_geometry()
  local value = reaper.GetExtState("FXRouter", "window_geometry")
  if value == "" then return nil end
  local x, y, w, h = value:match("^([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)$")
  x, y, w, h = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
  if x and y and w and h and w >= 400 and h >= 150 then
    return x, y, w, h
  end
end

local function make_temp_track()
  local idx = reaper.CountTracks(0)
  reaper.InsertTrackAtIndex(idx, false)
  local tr = reaper.GetTrack(0, idx)
  if tr then
    reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "__FXRouter_TEMP__", true)
    reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", 0)
    reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", 0)
  end
  return tr
end

local function remove_temp_track(tr)
  if tr and reaper.ValidatePtr2(0, tr, "MediaTrack*") then
    reaper.DeleteTrack(tr)
  end
end

-- Capture un FX complet (état natif REAPER, pas seulement les paramètres visibles).
-- Un track temporaire sert de conteneur de transport pour le state chunk.
local function capture_fx_chunk(src_track, fx_index)
  local temp = make_temp_track()
  if not temp then return nil, "Impossible de créer la piste temporaire." end

  local ok, err = pcall(function()
    reaper.TrackFX_CopyToTrack(src_track, fx_index, temp, 0, false)
  end)

  local chunk_ok, chunk = false, ""
  if ok and reaper.TrackFX_GetCount(temp) > 0 then
    chunk_ok, chunk = reaper.GetTrackStateChunk(temp, "", false)
  end
  remove_temp_track(temp)

  if not ok then return nil, tostring(err) end
  if not chunk_ok or not chunk or chunk == "" then
    return nil, "REAPER n'a pas fourni l'état complet de l'effet."
  end
  return chunk
end

local function capture_set(tr, containers)
  local set = { version = 2, slots = {} }
  for s = 1, NB_SLOTS do
    local cidx = containers[s]
    if not cidx then
      return nil, "Le container du slot " .. s .. " est absent."
    end

    local children = get_children(tr, cidx)
    if #children > 1 then
      return nil, "Le slot " .. s .. " contient plusieurs effets. Le FX Router attend un seul effet par container."
    end

    local slot = {
      enabled = reaper.TrackFX_GetEnabled(tr, cidx),
      chunk = ""
    }

    if children[1] then
      local chunk, err = capture_fx_chunk(tr, children[1].fx)
      if not chunk then
        return nil, "Copie du slot " .. s .. " impossible : " .. tostring(err)
      end
      slot.chunk = chunk
    end
    set.slots[s] = slot
  end
  return set
end

local function encode_set(set)
  local out = { "FXROUTER_SET_2\n" }
  for s = 1, NB_SLOTS do
    local slot = set.slots[s] or { enabled = true, chunk = "" }
    local chunk = slot.chunk or ""
    out[#out + 1] = (slot.enabled and "1" or "0") .. " " .. #chunk .. "\n"
    out[#out + 1] = chunk
    out[#out + 1] = "\n"
  end
  return table.concat(out)
end

local function decode_set(data)
  if type(data) ~= "string" or not data:match("^FXROUTER_SET_2\n") then
    return nil, "Ce fichier n'est pas un set FX Router v2 valide."
  end

  local pos = #"FXROUTER_SET_2\n" + 1
  local set = { version = 2, slots = {} }

  for s = 1, NB_SLOTS do
    local eol = data:find("\n", pos, true)
    if not eol then return nil, "Fichier incomplet (slot " .. s .. ")." end
    local enabled, length = data:sub(pos, eol - 1):match("^([01]) (%d+)$")
    length = tonumber(length)
    if not enabled or not length or length > #data then
      return nil, "En-tête invalide pour le slot " .. s .. "."
    end
    pos = eol + 1
    local chunk = data:sub(pos, pos + length - 1)
    if #chunk ~= length then return nil, "Données incomplètes pour le slot " .. s .. "." end
    pos = pos + length
    if data:sub(pos, pos) ~= "\n" then return nil, "Fin de données invalide pour le slot " .. s .. "." end
    pos = pos + 1
    set.slots[s] = { enabled = enabled == "1", chunk = chunk }
  end

  return set
end

local function write_file(path, data)
  local f, err = io.open(path, "wb")
  if not f then return false, err end
  local ok, write_err = f:write(data)
  f:close()
  if not ok then return false, write_err end
  return true
end

local function read_file(path)
  local f, err = io.open(path, "rb")
  if not f then return nil, err end
  local data = f:read("*a")
  f:close()
  return data
end

local function choose_set_file(save)
  local mode = save and 0 or 1
  local initial = save and "FXRouter.fxrouter" or ""
  local ok, path = reaper.GetUserFileName(
    mode,
    save and "Exporter un set FX Router" or "Importer un set FX Router",
    initial,
    "Sets FX Router|*.fxrouter|Tous les fichiers|*.*"
  )
  if not ok or not path or path == "" then return nil end
  if save and not path:lower():match("%.fxrouter$") then path = path .. ".fxrouter" end
  return path
end

local function load_chunk_on_temp(temp, chunk)
  local ok = reaper.SetTrackStateChunk(temp, chunk, false)
  if not ok or reaper.TrackFX_GetCount(temp) < 1 then
    return false, "Impossible de relire l'état d'un effet depuis le fichier."
  end
  return true
end

local function validate_set_chunks(set)
  local temp = make_temp_track()
  if not temp then return false, "Impossible de créer la piste temporaire de vérification." end

  local ok, err = true, nil
  for s = 1, NB_SLOTS do
    local chunk = set.slots[s].chunk
    if chunk ~= "" then
      local loaded, why = load_chunk_on_temp(temp, chunk)
      if not loaded then
        ok, err = false, "Slot " .. s .. " : " .. tostring(why)
        break
      end
      -- Vider la chaîne temporaire avant de vérifier le prochain slot.
      for fx = reaper.TrackFX_GetCount(temp) - 1, 0, -1 do
        reaper.TrackFX_Delete(temp, fx)
      end
    end
  end

  remove_temp_track(temp)
  return ok, err
end

local function apply_set(tr, containers, set, undo_label)
  -- Vérifier les quatre containers avant toute modification.
  for s = 1, NB_SLOTS do
    if not containers[s] then
      return false, "Le container du slot " .. s .. " est absent sur cette source."
    end
  end

  local valid, validation_error = validate_set_chunks(set)
  if not valid then return false, validation_error end

  local temp = make_temp_track()
  if not temp then return false, "Impossible de créer la piste temporaire d'import." end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  local success, failure = true, nil

  for s = 1, NB_SLOTS do
    local cidx = containers[s]
    local children = get_children(tr, cidx)

    -- Vider uniquement le contenu du container, jamais le container lui-même.
    for i = #children, 1, -1 do
      reaper.TrackFX_Delete(tr, children[i].fx)
    end

    local chunk = set.slots[s].chunk or ""
    if chunk ~= "" then
      local loaded, why = load_chunk_on_temp(temp, chunk)
      if not loaded then
        success, failure = false, "Slot " .. s .. " : " .. tostring(why)
        break
      end

      local copied = reaper.TrackFX_CopyToTrack(
        temp, 0, tr, child_addr(tr, cidx, 0), false
      )
      -- TrackFX_CopyToTrack ne renvoie pas de statut fiable selon les versions.
      local new_children = get_children(tr, cidx)
      if #new_children ~= 1 then
        success, failure = false, "REAPER n'a pas pu appliquer l'effet du slot " .. s .. "."
        break
      end

      for fx = reaper.TrackFX_GetCount(temp) - 1, 0, -1 do
        reaper.TrackFX_Delete(temp, fx)
      end
    end

    reaper.TrackFX_SetEnabled(tr, cidx, set.slots[s].enabled ~= false)
  end

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock(undo_label, -1)
  remove_temp_track(temp)

  return success, failure
end

local function export_current_set(tr, containers)
  local set, err = capture_set(tr, containers)
  if not set then
    reaper.MB(err, "FX Router — Export", 0)
    return
  end

  local path = choose_set_file(true)
  if not path then return end

  local ok, why = write_file(path, encode_set(set))
  if not ok then
    reaper.MB("Impossible d'écrire le fichier :\n" .. tostring(why), "FX Router — Export", 0)
  else
    reaper.MB("Set exporté :\n" .. path, "FX Router — Export", 0)
  end
end

local function import_set(tr, containers)
  local path = choose_set_file(false)
  if not path then return end

  local data, read_error = read_file(path)
  if not data then
    reaper.MB("Impossible de lire le fichier :\n" .. tostring(read_error), "FX Router — Import", 0)
    return
  end

  local set, parse_error = decode_set(data)
  if not set then
    reaper.MB(parse_error, "FX Router — Import", 0)
    return
  end

  local answer = reaper.MB(
    "Importer ce set va remplacer le contenu des 4 slots de la source actuelle.\n\nContinuer ?",
    "FX Router — Confirmation",
    4
  )
  if answer ~= 6 then return end

  local ok, why = apply_set(tr, containers, set, "FX Router : importer un set")
  if not ok then
    reaper.MB("Import interrompu :\n" .. tostring(why) .. "\n\nVérifie les slots et fais un Undo si nécessaire.",
      "FX Router — Import", 0)
  end
end

local function copy_current_set(tr, containers)
  local set, err = capture_set(tr, containers)
  if not set then
    reaper.MB(err, "FX Router — Copier", 0)
    return
  end
  clipboard_set = set
end

local function paste_set(tr, containers)
  if not clipboard_set then
    reaper.MB("Le presse-papiers FX Router est vide.\nUtilise d'abord Copier ou Ctrl/Cmd+C.",
      "FX Router — Coller", 0)
    return
  end
  local ok, why = apply_set(tr, containers, clipboard_set, "FX Router : coller un set")
  if not ok then
    reaper.MB("Collage impossible :\n" .. tostring(why), "FX Router — Coller", 0)
  end
end

local function clear_set(tr, containers)
  for s = 1, NB_SLOTS do
    if not containers[s] then
      reaper.MB("Le container du slot " .. s .. " est absent. Aucun slot n'a été modifié.",
        "FX Router — Clear", 0)
      return
    end
  end

  local answer = reaper.MB(
    "Vider les 4 slots de la source actuelle ?\n\nLes containers seront conservés, seuls leurs effets seront supprimés.",
    "FX Router — Confirmation Clear",
    4
  )
  if answer ~= 6 then return end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  for s = 1, NB_SLOTS do
    local cidx = containers[s]
    local children = get_children(tr, cidx)
    for i = #children, 1, -1 do
      save_params(tr, children[i].fx, s, children[i].ident)
      reaper.TrackFX_Delete(tr, children[i].fx)
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("FX Router : Clear des 4 slots", -1)
end

local function launchpad_slot()
  local n = tonumber(reaper.GetExtState("nowundo_vl", "fx_slot")) or 1
  return math.max(1, math.min(NB_SLOTS, math.floor(n)))
end

local function push_dark()
  local C = DARKBLUE
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),            C.bg)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(),     C.bg_hov)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),      C.bg_act)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(),         C.grab)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(),   C.grab_ac)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),             C.button)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),      C.bg_act)
  return 7
end

local function draw_slot(tr, s, cidx)
  if not cidx then
    reaper.ImGui_TextColored(ctx, GREY, "Slot " .. s)
    reaper.ImGui_TextDisabled(ctx, "(container absent)")
    return
  end

  local children = get_children(tr, cidx)
  local cur = children[1]

  -- Inactif = container bypassé, ou effet bypassé à l'intérieur
  local inactive = not reaper.TrackFX_GetEnabled(tr, cidx)
  if cur and not reaper.TrackFX_GetEnabled(tr, cur.fx) then inactive = true end

  local title_col = inactive and DARKBLUE.grab_ac or (cur and GREEN or GREY)
  local selected_on_pad = (launchpad_slot() == s)
  reaper.ImGui_TextColored(ctx, selected_on_pad and CYAN or title_col, (selected_on_pad and "▶ " or "") .. "Slot " .. s)
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_BeginDisabled(ctx, cur == nil)
  if reaper.ImGui_SmallButton(ctx, "Edit##edit" .. s) and cur then
    reaper.TrackFX_Show(tr, cur.fx, 3)
  end
  reaper.ImGui_EndDisabled(ctx)

  local preview = "— Aucun —"
  if cur then
    local e = find_entry(cur.ident)
    preview = e and e.name or cur.name
  end

  local npushed = inactive and push_dark() or 0

  reaper.ImGui_SetNextItemWidth(ctx, -1)
  if reaper.ImGui_BeginCombo(ctx, "##fx" .. s, preview) then
    -- À l'ouverture, la liste repart de l'élément sélectionné (et pas du début)
    local none_clicked = reaper.ImGui_Selectable(ctx, "— Aucun —", cur == nil)
    if cur == nil then
      reaper.ImGui_SetItemDefaultFocus(ctx)
      if reaper.ImGui_IsWindowAppearing(ctx) then reaper.ImGui_SetScrollHereY(ctx, 0.5) end
    end
    if none_clicked then
      if cur then
        reaper.Undo_BeginBlock()
        reaper.PreventUIRefresh(1)
        for i = #children, 1, -1 do
          save_params(tr, children[i].fx, s, children[i].ident)
          reaper.TrackFX_Delete(tr, children[i].fx)
        end
        reaper.PreventUIRefresh(-1)
        reaper.Undo_EndBlock("FX Router : vider un slot", -1)
      end
    end

    for i, e in ipairs(library) do
      local selected = cur ~= nil and norm(cur.ident) == norm(e.ident)
      local clicked = reaper.ImGui_Selectable(ctx, e.name .. "##" .. i, selected)
      if selected then
        reaper.ImGui_SetItemDefaultFocus(ctx)
        if reaper.ImGui_IsWindowAppearing(ctx) then reaper.ImGui_SetScrollHereY(ctx, 0.5) end
      end
      if clicked then
        if not selected then
          -- L'état ON/OFF du container est la seule autorité (matrice FX page 4).
          -- Le conserver explicitement car certaines opérations d'insertion peuvent le modifier.
          local container_was_enabled = reaper.TrackFX_GetEnabled(tr, cidx)
          reaper.Undo_BeginBlock()
          reaper.PreventUIRefresh(1)
          for j = #children, 1, -1 do
            save_params(tr, children[j].fx, s, children[j].ident)
            reaper.TrackFX_Delete(tr, children[j].fx)
          end

          local name = "JS:" .. e.ident
          local addr = child_addr(tr, cidx, 0)
          local idx = reaper.TrackFX_AddByName(tr, name, false, -1000 - addr)
          if idx < 0 then
            local top = reaper.TrackFX_AddByName(tr, name, false, -1)
            if top >= 0 then
              local dest = 0x2000000 + 1 * (reaper.TrackFX_GetCount(tr) + 1) + (cidx + 1)
              reaper.TrackFX_CopyToTrack(tr, top, tr, dest, true)
            else
              reaper.ShowConsoleMsg("FX Router : impossible de charger " .. name .. "\n")
            end
          end

          local new = get_children(tr, cidx)
          if new[1] then
            load_params(tr, new[1].fx, s, e.ident)
            -- L'effet interne reste activé dans le container ; l'activation audible du slot
            -- dépend exclusivement du bypass du container, piloté par la matrice FX (page 4).
            -- Ne pas modifier ici l'état du container : il doit rester strictement inchangé.
            reaper.TrackFX_SetEnabled(tr, new[1].fx, true)
          end
          -- Restaurer exactement l'état précédent du container après le remplacement.
          -- Changer/charger un effet ne peut donc jamais activer le slot.
          reaper.TrackFX_SetEnabled(tr, cidx, container_was_enabled)
          reaper.PreventUIRefresh(-1)
          reaper.Undo_EndBlock("FX Router : changement d'effet", -1)
        end
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end

  if cur then
    local fx = cur.fx
    local np = math.min(NB_PARAMS, reaper.TrackFX_GetNumParams(tr, fx))
    for p = 0, np - 1 do
      local _, pname = reaper.TrackFX_GetParamName(tr, fx, p)
      local _, ptxt  = reaper.TrackFX_GetFormattedParamValue(tr, fx, p)
      local val = reaper.TrackFX_GetParamNormalized(tr, fx, p)
      local fmt = (pname .. " : " .. ptxt):gsub("%%", "%%%%")
      reaper.ImGui_SetNextItemWidth(ctx, -1)
      local changed, nv = reaper.ImGui_SliderDouble(ctx, "##p" .. s .. "_" .. p, val, 0, 1, fmt)
      if changed then reaper.TrackFX_SetParamNormalized(tr, fx, p, nv) end
    end
  end

  if npushed > 0 then reaper.ImGui_PopStyleColor(ctx, npushed) end
end

local function key_down(key_fn)
  return key_fn and reaper.ImGui_IsKeyDown(ctx, key_fn()) or false
end

local function shortcut_pressed(key_fn)
  local ctrl = key_down(reaper.ImGui_Key_LeftCtrl) or key_down(reaper.ImGui_Key_RightCtrl)
  local super = key_down(reaper.ImGui_Key_LeftSuper) or key_down(reaper.ImGui_Key_RightSuper)
  return (ctrl or super) and reaper.ImGui_IsKeyPressed(ctx, key_fn(), false)
end

------------------------------------------------------------
-- Boucle principale
------------------------------------------------------------
local function loop()
  sync_launchpad_source()
  if first_frame then
    local x, y, w, h = load_geometry()
    if x then
      reaper.ImGui_SetNextWindowPos(ctx, x, y, reaper.ImGui_Cond_Always())
      reaper.ImGui_SetNextWindowSize(ctx, w, h, reaper.ImGui_Cond_Always())
    else
      reaper.ImGui_SetNextWindowSize(ctx, 900, 255, reaper.ImGui_Cond_FirstUseEver())
    end
    first_frame = false
  end

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 4)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), 6)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 6, 4)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 10, 8)

  local visible, open = reaper.ImGui_Begin(ctx, "FX Router", true, reaper.ImGui_WindowFlags_NoCollapse())

  if visible then
    reaper.ImGui_AlignTextToFramePadding(ctx)
    reaper.ImGui_Text(ctx, "Source")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 160)
    if reaper.ImGui_BeginCombo(ctx, "##src", sources[current].label) then
      for i, src in ipairs(sources) do
        if i == NB_SOURCES + 1 then reaper.ImGui_Separator(ctx) end
        if reaper.ImGui_Selectable(ctx, src.label, i == current) then
          current = i
          reaper.SetExtState("FXRouter", "src", tostring(i), true)
        end
      end
      reaper.ImGui_EndCombo(ctx)
    end

    local tr = reaper.GetTrack(0, sources[current].track)
    if tr then
      reaper.ImGui_SameLine(ctx)
      local _, tname = reaper.GetTrackName(tr)
      reaper.ImGui_TextDisabled(ctx, "Piste " .. (sources[current].track + 1) .. " — " .. tname)
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_SmallButton(ctx, "Rescan (" .. #library .. ")") then rescan() end

      local containers = get_containers(tr, sources[current].is_looper)

      reaper.ImGui_Separator(ctx)
      if reaper.ImGui_SmallButton(ctx, "Copier  Ctrl/Cmd+C") then copy_current_set(tr, containers) end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_SmallButton(ctx, "Coller  Ctrl/Cmd+V") then paste_set(tr, containers) end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_SmallButton(ctx, "Exporter") then export_current_set(tr, containers) end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_SmallButton(ctx, "Importer") then import_set(tr, containers) end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_SmallButton(ctx, "Clear") then clear_set(tr, containers) end
      reaper.ImGui_Separator(ctx)
      if reaper.ImGui_BeginTable(ctx, "slots", NB_SLOTS, reaper.ImGui_TableFlags_BordersInnerV()) then
        reaper.ImGui_TableNextRow(ctx)
        for s = 1, NB_SLOTS do
          reaper.ImGui_TableNextColumn(ctx)
          draw_slot(tr, s, containers[s])
        end
        reaper.ImGui_EndTable(ctx)
      end

      -- Raccourcis Ctrl+C / Ctrl+V sous Windows et Cmd+C / Cmd+V sous macOS.
      if reaper.ImGui_IsWindowFocused(ctx, 0) then
        if shortcut_pressed(reaper.ImGui_Key_C) then copy_current_set(tr, containers) end
        if shortcut_pressed(reaper.ImGui_Key_V) then paste_set(tr, containers) end
      end
    else
      reaper.ImGui_TextColored(ctx, RED, "Piste introuvable dans le projet.")
    end
  end

  -- Toujours appeler End après Begin, même lorsque visible == false.
  save_geometry(false)
  reaper.ImGui_End(ctx)
  reaper.ImGui_PopStyleVar(ctx, 4)

  if open then
    reaper.defer(loop)
  else
    save_geometry(true)
    reaper.ImGui_DestroyContext(ctx)
  end
end

reaper.defer(loop)


