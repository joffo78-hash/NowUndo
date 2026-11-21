"""V3.27 : dub brut (mode D). Boucle de 1 s (sinus faible), reverse ON, overdub d'une impulsion, puis on cherche ou elle ressort.
Mode A (compense) : l'impulsion revient au meme instant de la boucle (comme jouee). Mode D (brut) : elle est ecrite telle quelle
vers l'avant puis relue en reverse -> elle ressort a l'instant miroir. Verifie aussi : pas de NaN, amplitude ~ celle jouee.
Usage : cd tools && cp ../NowUndo/NowUndo_V3.27.jsfx v327.jsfx && python3 traw.py . [0|1] [rev|speed]"""
import sys, math
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
mode = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0
what = sys.argv[3] if len(sys.argv) > 3 else 'rev'
path = 'v327.jsfx'
A = load(path, 'raw'); bench.jsfx_path_of[A] = path
GM = A.GM
imp = {'n': -1}
def sig(n): return 0.02 * math.sin(2 * math.pi * 110 * n / SR) + (0.8 if n == imp['n'] else 0.0)
import re
m = A
m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
m.v_manual_id = 1.0; m.sec_init(); m.sec_slider()
out = []; N = [0]
def step(k=1):
    for _ in range(k):
        n0 = N[0]; A._clock[0] = n0 / SR; m.sec_block()
        for i in range(BLK):
            n = n0 + i; A._clock[0] = n / SR
            x = sig(n); m.v_spl0 = x; m.v_spl1 = x; m.sec_sample(); out.append(m.v_spl0)
        N[0] = n0 + BLK
def cmd(c):
    b = 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200; GM[b + 48] = c
def secs(t): return int(t * SR / BLK)
cmd(1); step(secs(1.0)); cmd(1); step(4)
L = int(m.v_length); print('length', L, 'state', m.v_state)
m.v_dub_raw = mode; m.v_slider68 = mode
if what == 'rev': cmd(4); step(2)
else: m.v_speed = 2.0; m.sec_slider()
step(secs(0.5))
cmd(1); step(2); print('state', m.v_state, '(3 = dub)')
pos_at = None
n_imp = N[0] + int(0.3 * SR); imp['n'] = n_imp
while N[0] <= n_imp: step(1)
step(secs(1.2 if what == 'rev' else 0.6)); cmd(1); step(4); print('state', m.v_state)
s0 = N[0]; step(secs(2.2))
seg = out[s0:]; bad = [v for v in seg if v != v or abs(v) > 1.5]
pk = [i for i in range(1, len(seg) - 1) if abs(seg[i]) > 0.15 and abs(seg[i]) >= abs(seg[i - 1]) and abs(seg[i]) >= abs(seg[i + 1])]
cl = []
for i in pk:
    if not cl or i - cl[-1][0] > 200: cl.append([i, abs(seg[i])])
    elif abs(seg[i]) > cl[-1][1]: cl[-1] = [i, abs(seg[i])]
per = L if what == 'rev' else L // 2
print('mode', 'D (brut)' if mode else 'A (compense)', '| NaN/gros', len(bad), '| crete max %.3f' % max(abs(v) for v in seg))
print('impulsions (instant dans la boucle, ms ; amplitude) :', [('%.1f' % (((s0 + i - n_imp) % per) * 1000.0 / SR), '%.2f' % a) for i, a in cl[:6]])
