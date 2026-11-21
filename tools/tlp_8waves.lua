-- Commandes sel_ / stap_ / ctrlgrp_ du Launchpad (V3.27). Usage : cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='virtuallaunchpad_main.lua'; l.execute(open('../../../tools/tlp_8waves.lua').read())"
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
for i = 0, 7 do local b = 1000 + i * 600; GM[100 + i] = 1; GM[130 + i] = 99; GM[b + 42] = 1; GM[b + 2] = 2; GM[b + 46] = 1000; GM[b + 45] = 1000 end
local VL = dofile(arg_path)
local S = VL.S or VL.state
local SENT = {}
local SNT = {}
local function cmd(s) EXT["NowUndo_VLcmd/q"] = (EXT["NowUndo_VLcmd/q"] or "") .. s .. "\t" .. string.format("%.3f", CLOCK) .. "\n"; VL.ext_cmd_poll() end
local function groups() local t = {}; for i = 1, 8 do t[#t + 1] = (VL.group_of and VL.group_of(i)) or "?" end; return table.concat(t, " ") end
print("S ?", S ~= nil)
cmd("sel_3"); print("sel_3 -> sel_looper =", S.sel_looper)
cmd("ctrlgrp_5_1"); cmd("ctrlgrp_6_0"); cmd("ctrlgrp_2_0"); print("groupes :", table.concat(S.group_of, " "), " sel", S.sel_looper)
cmd("ctrlgrp_6_0"); print("L6 ressort :", table.concat(S.group_of, " "))
for i = 0, 7 do GM[1000 + i * 600 + 48] = 0 end
pcall(VL.tick, CLOCK); print("L4 playing", S.loopers[4].playing, S.loopers[4].length); for i = 0, 7 do GM[1000 + i * 600 + 48] = 0 end; cmd("stap_4"); local c = {}; for i = 0, 7 do local v = GM[1000 + i * 600 + 48]; if v and v > 0 then c[#c + 1] = "L" .. (i + 1) .. ":cmd" .. v end end
print("stap_4 (L4 en lecture) :", table.concat(c, " "), " sel =", S.sel_looper)
