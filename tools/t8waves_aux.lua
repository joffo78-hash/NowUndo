-- Sends aux dans 8Waves (27 nov.). Usage : cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='NowUndo_8Waves.lua'; l.execute(open('../../../tools/t8waves_aux.lua').read())"
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
W8_TEST = {}
reaper.GetTrack = function(_, n) return { n = n + 1 } end
reaper.GetTrackName = function(tr) local N = { [21] = "Reverb Hall", [22] = "Delay", [23] = "", [24] = "Track 24" } return true, N[tr.n] or "" end
M[6098] = 21; M[6099] = 4
M[6100] = 0.5; M[6101] = -0.3; M[6031] = 5;   -- L1 : FX1 et FX3 actifs
 M[6228 + 3] = 1                 -- L1 : aux1 ouvert 50 %, aux2 ferme (30 % garde), aux4 -> L1
dofile(arg_path)
local function frame(mx, my, cap) gfx.mouse_x, gfx.mouse_y, gfx.mouse_cap = mx, my, cap or 0; CLOCK = CLOCK + .033; G.f() end
local function q() local s = EXT["NowUndo_VLcmd/q"] or ""; EXT["NowUndo_VLcmd/q"] = ""; return (s:gsub("\t[%d%.]+\n", " ")) end
frame(0, 0); frame(0, 0)
local R = W8_TEST.VIS.R[0]
local t = {}
for _, b in ipairs(R.ab) do t[#t + 1] = string.format("aux%d v=%.2f x=%d y=%d w=%d h=%d", b.a, b.v, b.x, b.y, b.w, b.h) end
print("pastilles L1 :", #R.ab, table.concat(t, " | "))
local b1, b2 = R.ab[1], R.ab[2]
local cy = b1.y + b1.h / 2
local cy2 = b2.y + b2.h / 2
frame(b1.x + 5, cy, 1); frame(b1.x + 5, cy, 0); print("clic aux1        :", q())
frame(b2.x + 5, cy2, 1); for k = 1, 10 do frame(b2.x + 5 + k * 10, cy2, 1) end; frame(b2.x + 105, cy2, 0)
print("glisser aux2 +100 px :", q())
frame(b1.x + 5, cy, 1); for k = 1, 8 do frame(b1.x + 5 - k * 20, cy, 1) end; frame(b1.x - 155, cy, 0)
print("glisser aux1 vers 0  :", q())
frame(b1.x + 5, cy, 2); frame(b1.x + 5, cy, 0); print("clic droit aux1  :", q())
local f = {}
for _, b in ipairs(R.fb or {}) do f[#f + 1] = string.format("FX%d x=%d y=%d %dpx", b.slot, b.x, b.y, b.w) end
print("carres FX L1 :", #(R.fb or {}), table.concat(f, " | "))
check_x = R.fb[1].x + R.fb[1].w < R.ab[1].x and "avant les sends" or "PAS avant les sends"
print("position :", check_x)
local fb3 = R.fb[3]
frame(fb3.x + 3, fb3.y + 3, 1); frame(fb3.x + 3, fb3.y + 3, 0); print("clic FX3 de L1     :", q())
local R2 = W8_TEST.VIS.R[1]
print("L2 (aucun send) :", #R2.ab, R2.ab[1] and R2.ab[1].v)
