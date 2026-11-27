-- 27 nov. : 8Waves affiche et deplace les In / Out pre-regles d'un looper VIDE (longueur fictive 112000+..+4/5/6).
-- Usage : cd NowUndo/Scripts/V3.21 && python3 -c "import lupa.lua54 as L; l=L.LuaRuntime(); l.globals().arg_path='NowUndo_8Waves.lua'; l.execute(open('../../../tools/t8waves_preio.lua').read())"
G = {}; EXT = {}; M = {}; W = {}
gfx = setmetatable({ w = 1400, h = 820, x = 0, y = 0, mouse_x = 0, mouse_y = 0, mouse_cap = 0 }, { __index = function() return function() return 0 end end })
gfx.measurestr = function(s) return 7 * #tostring(s), 12 end
gfx.dock = function() return 0, 0, 0, 1400, 820 end
CH = 0; gfx.getchar = function() local c = CH; CH = 0; return c end
CLOCK = 100
reaper = { gmem_attach = function() end, time_precise = function() return CLOCK end,
  GetExtState = function(a, k) return EXT[a .. "/" .. k] or "" end, SetExtState = function(a, k, v) EXT[a .. "/" .. k] = v end,
  defer = function(f) G.f = f end, gmem_read = function(a) return M[a] or 0 end, gmem_write = function(a, v) M[a] = v; W[#W + 1] = string.format("%d=%.6g", a, v) end }
for i = 0, 7 do local b = 1000 + i * 600; M[b] = 1; M[b + 42] = 1; M[130 + i] = 99; M[b + 2] = 0; M[b + 46] = 0; M[b + 22] = 1
  local x = 112000 + i * 3 * 20; M[x + 4] = 1000000; M[x + 5] = 250000; M[x + 6] = 500000 end      -- vides : In 25 %, Out 75 %
W8_TEST = {}
dofile(arg_path)
VIS = W8_TEST.VIS
local function frame(mx, my, cap) gfx.mouse_x, gfx.mouse_y, gfx.mouse_cap = mx, my, cap or 0; CLOCK = CLOCK + .033; G.f() end
frame(0, 0)
local fails = 0
local function chk(l, got, want) local ok = got == want; if not ok then fails = fails + 1 end; print(ok and "OK  " or "FAUX", l, tostring(got), ok and "" or ("(attendu " .. tostring(want) .. ")")) end
local R = VIS.R[2]
chk("L3 vide : longueur fictive vue par 8Waves", R and R.len, 1000000)
chk("... In 25 %", R and R.ls, 250000)
chk("... Width 50 %", R and R.lw, 500000)
-- glisser la poignee Out (75 %) vers 90 % : commande 2 en unites fictives
local wx, ww = R.wx, R.ww
local y = R.wy + 4
W = {}
frame(wx + .75 * ww - 1, y, 1); frame(wx + .80 * ww, y, 1); frame(wx + .90 * ww, y, 1); frame(wx + .90 * ww, y, 0)
local s = table.concat(W, " ")
local b = 1000 + 2 * 600
chk("glisser Out -> commande 2 ecrite", s:find(tostring(b + 160) .. "=2") ~= nil, true)
local out; for v in s:gmatch(tostring(b + 162) .. "=([%d%.e%+]+)") do out = tonumber(v) end
chk("... vers ~90 % de la longueur fictive", out and math.abs(out / 1000000 - .90) < .01, true)
print(fails == 0 and "TOUT OK" or (fails .. " ECHEC(S)"))
