-- Gestes de 8Waves (V3.27). Usage : cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='NowUndo_8Waves.lua'; l.execute(open('../../../tools/t8waves_ui.lua').read())"
-- test des gestes de 8Waves (faux gfx / reaper)
G = {}; EXT = {}; M = {}; W = {}
gfx = setmetatable({ w = 1400, h = 820, x = 0, y = 0, mouse_x = 0, mouse_y = 0, mouse_cap = 0 }, { __index = function() return function() return 0 end end })
gfx.measurestr = function(s) return 7 * #tostring(s), 12 end
gfx.dock = function() return 0, 0, 0, 1400, 820 end
CH = 0; gfx.getchar = function() local c = CH; CH = 0; return c end
CLOCK = 100
reaper = { gmem_attach = function() end, time_precise = function() return CLOCK end,
  GetExtState = function(a, k) return EXT[a .. "/" .. k] or "" end, SetExtState = function(a, k, v) EXT[a .. "/" .. k] = v end,
  defer = function(f) G.f = f end, gmem_read = function(a) return M[a] or 0 end, gmem_write = function(a, v) M[a] = v; W[#W + 1] = string.format("%d=%.4g", a, v) end }
for i = 0, 7 do local b = 1000 + i * 600; M[b] = 1; M[b + 42] = 1; M[130 + i] = 99; M[b + 2] = 2; M[b + 46] = 1000; M[b + 45] = 600; M[b + 44] = 200; M[b + 22] = 1
  for k = 0, 99 do M[b + 50 + k] = .5 end end
M[1000 + 2 * 600 + 24] = 1; M[1000 + 2 * 600 + 178] = 40; M[1000 + 2 * 600 + 179] = 60     -- L3 : Cloud, zone 40-60 %
EXT["nowundo_vl/sel_looper"] = "1"
dofile(arg_path)
local function frame(mx, my, cap) gfx.mouse_x, gfx.mouse_y, gfx.mouse_cap = mx, my, cap or 0; CLOCK = CLOCK + .033; G.f() end
local function q() local s = EXT["NowUndo_VLcmd/q"] or ""; EXT["NowUndo_VLcmd/q"] = ""; return (s:gsub("\t[%d%.]+\n", " ")) end
frame(0, 0)
-- geometrie : ligne k = y 6 + k*(rh+4), rh = (820-12-28)/8 = 97.5 ; fenetre x de wx a wx+ww, In a 20 %, Out a 80 %
local function rowy(k) return 6 + k * 101.5 + 50 end
local wx, ww = 6 + 6 + 6, 1388 - 12 - 12
local function X(f) return wx + f * ww end
frame(X(.015), rowy(3) - 40, 1); frame(X(.015), rowy(3) - 40, 0); print("clic etiquette L4    :", q())
frame(10, rowy(3), 1); frame(10, rowy(3), 0); print("clic VU L4           :", q())
frame(X(.5), rowy(4), 5); frame(X(.5), rowy(4), 4); frame(X(.5), rowy(5), 5); frame(X(.5), rowy(5), 4); frame(X(.5), rowy(4), 5); frame(X(.5), rowy(4), 0)
print("Ctrl tenu : L5, L6, L5 :", q())
frame(X(.5), rowy(6), 1); CLOCK = CLOCK + 1; frame(X(.5), rowy(6), 0); print("appui long L7 (pas de tap) :", q())
