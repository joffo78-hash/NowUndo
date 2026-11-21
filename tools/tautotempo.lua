-- Auto-Tempo v6 : AUTO-SYNC regle le tempo + PLAY, n'ecrit plus rien dans la synchro (seul le MSV3 le fait)
GM = {}; local W = {}; local LOOP; local BPM = 100; local PLAY = 0; local LOG = {}
reaper = setmetatable({
  gmem_attach = function() end, gmem_read = function(i) return GM[i] or 0 end,
  gmem_write = function(i, v) GM[i] = v; W[#W + 1] = i end,
  time_precise = function() return os.clock() end, GetExtState = function() return "" end, SetExtState = function() end,
  defer = function(f) LOOP = f end, Master_GetTempo = function() return BPM end, GetPlayState = function() return PLAY end,
  SetCurrentBPM = function(_, b) BPM = b; LOG[#LOG + 1] = string.format("tempo %.2f", b) end,
  CSurf_OnPlay = function() PLAY = 1; LOG[#LOG + 1] = "PLAY" end, CSurf_OnStop = function() PLAY = 0; LOG[#LOG + 1] = "STOP" end,
  TimeMap_GetTimeSigAtTime = function() return 4, 4, BPM end, GetPlayPosition = function() return 0 end,
  GetAudioDeviceInfo = function() return true, "48000" end,
}, { __index = function() return function() return 0 end end })
gfx = setmetatable({ w = 300, h = 300, mouse_x = 0, mouse_y = 0, mouse_cap = 0 }, { __index = function() return function() return 0 end end })
gfx.getchar = function() return 0 end; gfx.measurestr = function(t) return 7 * #t end
gfx.dock = function() return 0, 0, 0, 300, 300 end
dofile(arg_path)
GM[95] = 1; GM[910] = 0
GM[0] = 2; GM[2] = 96000; GM[3] = 0; LOOP(); LOOP()                    -- part Main en Host : le script ne doit rien ecrire
GM[0] = 1; GM[1] = 11; GM[2] = 96000 * 2; LOOP(); LOOP()              -- un looper devient maitre : boucle de 4 s
GM[0] = 0; LOOP()                                                     -- Unlock
print("actions : " .. table.concat(LOG, ", "))
print("ecritures gmem du script : " .. (#W == 0 and "aucune" or table.concat(W, " ")))
