"""V3.25 : un NOUVEAU REC sur un looper termine le REC en cours d'un autre (qui attend son point de synchro).
Usage : cd tools && cp ../NowUndo/NowUndo_V3.25.jsfx v325.jsfx && python3 trec.py ."""
import sys, math
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = 'v325.jsfx'
mods = [load(path, 'rc%d' % k) for k in range(3)]
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
def step(nb=1):
    for _ in range(nb):
        for r in rs: r.run(BLK)
def cmd(k, c):
    m = mods[k]; GM[1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200 + 48] = c
def st(): return ' '.join('%s=%d(len %d)' % ('ABC'[k], mods[k].v_state, mods[k].v_length) for k in range(3))
def secs(t): return int(t * SR / BLK)
cmd(0, 1); step(secs(2.0)); cmd(0, 1); step(4)
print('A maitre :', st())
cmd(1, 1); step(secs(0.6)); print('B en REC :', st())
cmd(2, 1); step(2); print('C lance un REC :', st())
t = 0
while mods[1].v_state != 2 and t < secs(3): step(1); t += 1
print('B passe en lecture apres %.2f s : %s' % (t * BLK / SR, st()))
print('B longueur = %.2f boucle(s) de A' % (mods[1].v_length / mods[0].v_length))
step(secs(0.5)); cmd(0, 1); step(2); print('A (joue) recoit REC = overdub, C continue :', st())
