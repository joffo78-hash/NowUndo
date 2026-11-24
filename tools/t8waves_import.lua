-- Import de fichiers audio dans 8Waves (faux reaper + faux JSFX qui repond aux commandes 32 / 31).
-- cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='NowUndo_8Waves.lua'; l.execute(open('../../../tools/t8waves_import.lua').read())"
G = {}; EXT = {}; M = {}; DROPS = {}
gfx = setmetatable({ w = 1400, h = 820, x = 0, y = 0, mouse_x = 0, mouse_y = 0, mouse_cap = 0 }, { __index = function() return function() return 0 end end })
gfx.measurestr = function(s) return 7 * #tostring(s), 12 end
gfx.dock = function() return 0, 0, 0, 1400, 820 end
gfx.getchar = function() return 0 end
gfx.getdropfile = function(k) if k < 0 then DROPS = {}; return 0 end local f = DROPS[k + 1]; if f then return 1, f end return 0 end
MENU = 0; gfx.showmenu = function(s) MENU_STR = s; return MENU end
CLOCK = 100; BPM = nil; TRK = 0; TRK_MAX = 0
SRC_LEN = 2.0; ACC_COUNT = 0
reaper = { gmem_attach = function() end, time_precise = function() return CLOCK end,
  GetExtState = function(a, k) return EXT[a .. "/" .. k] or "" end, SetExtState = function(a, k, v) EXT[a .. "/" .. k] = v end,
  defer = function(f) G.f = f end, gmem_read = function(a) return M[a] or 0 end, gmem_write = function(a, v) M[a] = v end,
  PCM_Source_CreateFromFile = function(p) return { p = p } end, GetMediaSourceLength = function() return SRC_LEN, false end,
  PCM_Source_Destroy = function() end, GetSetProjectInfo = function() return 48000 end,
  PreventUIRefresh = function() end, CountTracks = function() return TRK end, InsertTrackAtIndex = function() TRK = TRK + 1; TRK_MAX = math.max(TRK_MAX, TRK) end,
  GetTrack = function() return {} end, AddMediaItemToTrack = function() return {} end, AddTakeToMediaItem = function() return {} end,
  SetMediaItemTake_Source = function() end, SetMediaItemInfo_Value = function() end, CreateTakeAudioAccessor = function() return {} end,
  GetAudioAccessorStartTime = function() return 0 end, DestroyAudioAccessor = function() end, DeleteTrack = function() TRK = TRK - 1 end,
  new_array = function(n) return setmetatable({}, { __index = function(t, k) return 0.25 end, __newindex = function(t, k, v) rawset(t, k, v) end }) end,
  GetAudioAccessorSamples = function(acc, sr, nch, t, n, buf) ACC_COUNT = ACC_COUNT + n end,
  SetCurrentBPM = function(_, b) BPM = b end,
  GetUserFileNameForRead = function() return true, "/x/choisi.wav" end }
-- looper 1 (indice 0) vivant, a l'arret, vide
for i = 0, 7 do local b = 1000 + i * 600; M[b] = 1; M[b + 42] = 1; M[100 + i] = i + 1; M[130 + i] = 99; M[b + 186] = 48000 end
dofile(arg_path)
local function frame(mx, my, cap) gfx.mouse_x, gfx.mouse_y, gfx.mouse_cap = mx or 0, my or 0, cap or 0; CLOCK = CLOCK + .033; M[130] = CLOCK; for i = 0, 7 do M[130 + i] = CLOCK end; G.f() end
-- faux JSFX : repond a cmd 32 (requete) et 31 (copie)
local HAS_REF, NAD = false, 0
local function jsfx_tick()
  for i = 0, 7 do local b = 1000 + i * 600
    if M[b + 48] == 32 then M[b + 48] = 0; M[1000000 + 3] = M[1000000 + 2]; M[1000000 + 4] = HAS_REF and 1 or 0; M[1000000 + 5] = NAD; M[1000000 + 7] = 0 end
    if M[b + 48] == 31 then M[b + 48] = 0; M[1000000 + 10] = M[1000000 + 2]; LASTCOPY = { Nf = M[1000000 + 8], ref = M[1000000 + 9], i = i } end
  end
end
local function run(max)
  for k = 1, max or 400 do frame(); jsfx_tick(); if k > 2 and not (IMPJOB) then end end
end
local function rowy(k) return 6 + k * 101.5 + 50 end
frame()
-- 1) depot sur la ligne 1, aucune reference : longueur d'origine (2 s a 48 kHz = 96000), le looper devient maitre, tempo fixe
BPM = nil; LASTCOPY = nil; HAS_REF = false; NAD = 0; M[1000 + 155] = 120
DROPS = { "/x/boucle.wav" }; gfx.mouse_x, gfx.mouse_y = 700, rowy(0); frame(700, rowy(0)); 
for k = 1, 60 do frame(700, rowy(0)); jsfx_tick() end
print("1 sans ref   : copie", LASTCOPY and (LASTCOPY.Nf .. " ref=" .. LASTCOPY.ref .. " looper=" .. (LASTCOPY.i + 1)) or "RIEN", "tempo", BPM, "pistes temporaires restantes", TRK)
-- 2) avec reference, mode ADAPTER (1) : longueur arrondie par le looper (Nad = 100000)
BPM = nil; LASTCOPY = nil; HAS_REF = true; NAD = 100000; ACC_COUNT = 0
DROPS = { "/x/b2.wav" }; frame(700, rowy(1))
for k = 1, 60 do frame(700, rowy(1)); jsfx_tick() end
print("2 adapter    : copie", LASTCOPY and (LASTCOPY.Nf .. " ref=" .. LASTCOPY.ref .. " looper=" .. (LASTCOPY.i + 1)) or "RIEN", "tempo", BPM, "echantillons lus", ACC_COUNT)
-- 3) mode ETIRER via le menu du clic droit (items : 1 charger, 2 adapter, 3 independant, 4 etirer)
MENU = 4; frame(700, rowy(2), 2); frame(700, rowy(2), 0); print("menu :", MENU_STR); print("mode enregistre :", EXT["NowUndo_8Waves/load_mode"])
LASTCOPY = nil; ACC_COUNT = 0; DROPS = { "/x/b3.wav" }; frame(700, rowy(2))
for k = 1, 80 do frame(700, rowy(2)); jsfx_tick() end
print("3 etirer     : copie", LASTCOPY and (LASTCOPY.Nf .. " ref=" .. LASTCOPY.ref .. " looper=" .. (LASTCOPY.i + 1)) or "RIEN", "echantillons lus", ACC_COUNT)
-- 4) clic droit > Charger un fichier... (item 1) : ouvre le selecteur et charge sur la ligne cliquee
MENU = 1; LASTCOPY = nil; frame(700, rowy(3), 2); frame(700, rowy(3), 0)
for k = 1, 80 do frame(700, rowy(3)); jsfx_tick() end
print("4 selecteur  : copie", LASTCOPY and (LASTCOPY.Nf .. " ref=" .. LASTCOPY.ref .. " looper=" .. (LASTCOPY.i + 1)) or "RIEN")
-- 5) depot hors des lignes / looper absent / fichier invalide
M[1000 + 7 * 600] = 1; M[107] = 0
DROPS = { "/x/z.wav" }; LASTCOPY = nil; frame(700, rowy(7)); for k = 1, 5 do frame(700, rowy(7)); jsfx_tick() end
print("5 looper 8 absent : copie", LASTCOPY and "OUI" or "non (normal)")
SRC_LEN = 0.001; DROPS = { "/x/y.wav" }; LASTCOPY = nil; frame(700, rowy(0)); for k = 1, 5 do frame(700, rowy(0)); jsfx_tick() end
print("6 fichier trop court : copie", LASTCOPY and "OUI" or "non (normal)")
