-- Auto-Tempo dans le Launchpad (VL.autotempo_tick) : cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='virtuallaunchpad_main.lua'; l.execute(open('../../../tools/tlp_autotempo.lua').read())"
VL_TEST = true
EXT = {}; GM = {}; CLOCK = 100
reaper = setmetatable({
  time_precise = function() return CLOCK end,
  GetExtState = function(a, k) return EXT[a .. "/" .. k] or "" end, SetExtState = function(a, k, v) EXT[a .. "/" .. k] = v end,
  HasExtState = function(a, k) return EXT[a .. "/" .. k] ~= nil end, DeleteExtState = function(a, k) EXT[a .. "/" .. k] = nil end,
  gmem_read = function(a) return GM[a] or 0 end, gmem_write = function(a, v) GM[a] = v end, gmem_attach = function() end,
  GetResourcePath = function() return "/nonexistent" end, GetOS = function() return "Win64" end,
  get_action_context = function() return false, "/nonexistent/x.lua" end,
  CountTracks = function() return 0 end, defer = function() end, atexit = function() end,
  ShowConsoleMsg = function() end, file_exists = function() return false end, EnumerateFiles = function() return nil end,
}, { __index = function() return function() return 0 end end })
gfx = setmetatable({ w = 800, h = 600 }, { __index = function() return function() return 0 end end })
local BPM, PLAY, LOG = 100, 0, {}
reaper.Master_GetTempo = function() return BPM end
reaper.GetPlayState = function() return PLAY end
reaper.SetCurrentBPM = function(_, b) BPM = b; LOG[#LOG + 1] = string.format("tempo %.2f", b) end
reaper.CSurf_OnPlay = function() PLAY = 1; LOG[#LOG + 1] = "PLAY" end
reaper.CSurf_OnStop = function() PLAY = 0; LOG[#LOG + 1] = "STOP" end
reaper.SetEditCurPos2 = function(_, p) LOG[#LOG + 1] = string.format("curseur %.3f", p) end
reaper.GetPlayPosition2 = function() return 0 end
reaper.TimeMap2_timeToBeats = function() return 0, 0 end
reaper.TimeMap2_beatsToTime = function(_, _, m) return (m or 0) * 2 end
reaper.GetAudioDeviceInfo = function() return true, "48000" end
gfx = setmetatable({ w = 800, h = 600 }, { __index = function() return function() return 0 end end })
local VL = dofile(arg_path)
local function step(t) CLOCK = CLOCK + 0.1; VL.autotempo_tick(CLOCK) end
local function show(t) print(string.format("%-42s %s", t, #LOG > 0 and table.concat(LOG, ", ") or "-")); LOG = {} end
GM[0] = 1; GM[1] = 11; GM[2] = 192000; GM[3] = 24000; GM[917] = 120; GM[918] = 8
step(); show("AUTO-SYNC OFF, maitre present")
GM[95] = 1; GM[0] = 0; step(); GM[0] = 1; step(); show("AUTO-SYNC ON, un looper devient maitre")
step(); step(); show("rien ne change")
GM[917] = 60; GM[918] = 4; GM[919] = 1; step(); show("temps forces changes dans le MSV3 (lecture)")
GM[0] = 0; step(); show("Unlock")
GM[0] = 2; step(); show("part en Host (pas de maitre looper)")
