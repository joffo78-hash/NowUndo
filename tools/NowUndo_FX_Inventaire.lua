-- @noindex
-- NowUndo_FX_Inventaire.lua
-- Fait l'inventaire du dossier Effects/MonRig dans un petit fichier texte a envoyer a Claude :
-- pour chaque effet : chemin, taille, ligne desc:, auteur / licence / copyright trouves dans l'en-tete,
-- fichiers importes (import ...), et s'il est utilise dans le projet ouvert (et sur quelles pistes).
-- Les autres fichiers (images, sons...) sont seulement comptes par type.
-- Resultat : <dossier de REAPER>/NowUndo_FX_inventaire.txt

local ROOT_NAME = "MonRig"
local res = reaper.GetResourcePath()
local root = res .. "/Effects/" .. ROOT_NAME
local MAX_HEAD = 80          -- lignes lues en tete de chaque effet

-- pistes du projet qui utilisent chaque effet
local used = {}
for t = 0, reaper.CountTracks(0) - 1 do
  local tr = reaper.GetTrack(0, t)
  local ok, chunk = reaper.GetTrackStateChunk(tr, "", false)
  if ok then
    for path in chunk:gmatch("<JS%s+\"?([^\"\n]-)\"?%s+\"") do
      local p = path:gsub("\\", "/")
      used[p] = used[p] or {}
      used[p][#used[p] + 1] = t + 1
    end
  end
end

local out, others, n_fx = {}, {}, 0
local function add(s) out[#out + 1] = s end

local function is_text_fx(name)
  local ext = name:match("%.([^%.]+)$")
  if not ext then return true end                 -- JSFX sans extension
  ext = ext:lower()
  return ext == "jsfx" or ext == "jsfx-inc" or ext == "eel" or ext == "txt"
end

local function scan_file(full, rel)
  local f = io.open(full, "rb")
  if not f then return end
  local size = f:seek("end"); f:seek("set", 0)
  local head = f:read(4096) or ""
  if head:find("%z") then f:close(); return false end   -- binaire
  f:seek("set", 0)
  n_fx = n_fx + 1
  local desc, infos, imports, i = nil, {}, {}, 0
  for line in f:lines() do
    i = i + 1
    if i > MAX_HEAD then break end
    local l = line:gsub("\r", "")
    if not desc then desc = l:match("^%s*desc:%s*(.*)") end
    local low = l:lower()
    if low:find("author") or low:find("licen") or low:find("copyright") or low:find("%(c%)")
       or low:find("gpl") or low:find("mit ") or low:find("bsd") or low:find("creative commons")
       or low:find("http") or low:find("@version") or low:find("tukan") or low:find("saike")
       or low:find("geraint") or low:find("liteon") or low:find("sonic anomaly") or low:find("tale") then
      if #infos < 8 then infos[#infos + 1] = l:sub(1, 160) end
    end
    local imp = l:match("^%s*import%s+(.+)")
    if imp then imports[#imports + 1] = imp end
  end
  f:close()
  local key = (ROOT_NAME .. "/" .. rel):gsub("%.jsfx$", "")
  local u = used[ROOT_NAME .. "/" .. rel] or used[key]
  add(("== %s  (%d octets)%s"):format(rel, size, u and ("  UTILISE pistes " .. table.concat(u, ",")) or ""))
  add("   desc: " .. (desc or "?"))
  for _, s in ipairs(infos) do add("   | " .. s) end
  if #imports > 0 then add("   import: " .. table.concat(imports, " ; ")) end
  return true
end

local function walk(dir, rel)
  local i = 0
  while true do
    local name = reaper.EnumerateFiles(dir, i)
    if not name then break end
    local r = rel == "" and name or (rel .. "/" .. name)
    local done = false
    if is_text_fx(name) then done = scan_file(dir .. "/" .. name, r) end
    if not done then
      local ext = (name:match("%.([^%.]+)$") or "(sans)"):lower()
      local f = io.open(dir .. "/" .. name, "rb")
      local sz = f and f:seek("end") or 0
      if f then f:close() end
      local o = others[ext] or { n = 0, sz = 0 }
      o.n, o.sz = o.n + 1, o.sz + sz
      others[ext] = o
    end
    i = i + 1
  end
  i = 0
  while true do
    local sub = reaper.EnumerateSubdirectories(dir, i)
    if not sub then break end
    walk(dir .. "/" .. sub, rel == "" and sub or (rel .. "/" .. sub))
    i = i + 1
  end
end

reaper.EnumerateFiles(root, -1)   -- vide le cache de REAPER
walk(root, "")

add("")
add("== Autres fichiers (non lus) par type : nombre, taille totale")
for ext, o in pairs(others) do add(("   .%s : %d fichiers, %.1f Mo"):format(ext, o.n, o.sz / 1048576)) end
add("")
add("== Effets JS du projet ouvert hors de " .. ROOT_NAME .. " :")
for p, t in pairs(used) do
  if not p:find("^" .. ROOT_NAME .. "/") then add("   " .. p .. "  (pistes " .. table.concat(t, ",") .. ")") end
end

local path = res .. "/NowUndo_FX_inventaire.txt"
local f = io.open(path, "w")
if f then
  f:write(("Inventaire de %s : %d effets lus\n\n"):format(root, n_fx))
  f:write(table.concat(out, "\n"))
  f:close()
  reaper.ShowMessageBox("Inventaire ecrit (" .. n_fx .. " effets) :\n" .. path, "NowUndo", 0)
else
  reaper.ShowMessageBox("Impossible d'ecrire " .. path, "NowUndo", 0)
end
