"""V3.25 : 4 loopers en REC ensemble SANS synchro, sortie ensemble (le 4e recoit sa commande 0,1 s plus tard) : aucun ne doit attendre le tour suivant.
Usage : cd tools && cp ../NowUndo/NowUndo_V3.25.jsfx v325.jsfx && python3 tcorec.py ."""
import sys, math
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = 'v325.jsfx'
mods = [load(path, 'co%d' % k) for k in range(4)]
for m in mods: bench.jsfx_path_of[m] = path
for m in mods[1:]: m.GM = mods[0].GM; m._clock = mods[0]._clock
GM = mods[0].GM
class R(Run):
    def __init__(s, m, ident):
        s.m = m; s.sig = lambda n: 0.3 * math.sin(2 * math.pi * (100 + 50 * ident) * n / SR); s.n = 0; s.out = []; s.events = []
        m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 1.0
        import re
        for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
            setattr(m, 'v_' + mm.group(1), float(mm.group(2)))
        m.v_manual_id = float(ident); m.sec_init(); m.sec_slider()
rs = [R(m, k + 1) for k, m in enumerate(mods)]
N = 4
def step(nb=1):
    for _ in range(nb):
        for r in rs: r.run(BLK)
def cmd(k, c):
    m = mods[k]; GM[1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200 + 48] = c
def st(): return ' '.join('%s=%d(len %d)' % ('ABCD'[k], mods[k].v_state, mods[k].v_length) for k in range(N))
for k in range(N): cmd(k, 1)
step(int(1.7 * SR / BLK))
for k in range(3): cmd(k, 1)
step(int(0.1 * SR / BLK)); cmd(3, 1)
step(int(0.15 * SR / BLK))
print('0,15 s apres la sortie :', st())
step(int(1.0 * SR / BLK))
print('1 s plus tard          :', st())
# phase : les 3 boucles repartent ensemble (pos identiques a quelques samples pres)
print('positions :', [int(mods[k].v_pos) for k in range(N)])
