"""Maitre fantome (V3.27, 22 nov.) : looper seul, gmem garde un maitre disparu -> esclave + Slicer bloque.
cd tools && cp ../NowUndo/NowUndo_V3.27.jsfx v327.jsfx && python3 tghost.py . v327.jsfx"""
import sys, math, re
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = sys.argv[2]
A = load(path, 'ghost' + str(abs(hash(path)) % 1000)); bench.jsfx_path_of[A] = path
GM = A.GM; m = A
m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
T0 = 100.0
A._clock[0] = T0
m.v_manual_id = 1.0; m.sec_init(); m.sec_slider()
N = [0]
def step(k=1, rec=None):
    for _ in range(k):
        n0 = N[0]; A._clock[0] = T0 + n0 / SR; m.sec_block()
        if rec is not None: rec.add(int(m.v_last_slicer_step))
        for i in range(BLK):
            n = n0 + i; A._clock[0] = T0 + n / SR
            x = 0.3 * math.sin(2 * math.pi * 220 * n / SR) * (1 if (n // 6000) % 2 == 0 else 0.2); m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
        N[0] = n0 + BLK
def cmd(c):
    b = 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200; GM[b + 48] = c
def secs(t): return int(t * SR / BLK)
def ms(): return {0: 'FREE', 1: 'MAITRE L%d' % GM[1], 2: 'HOST'}.get(int(GM[0]), '?')
cmd(1); step(secs(2.0)); cmd(1); step(4)
print('boucle %.2f s, synchro : %s' % (m.v_length / SR, ms()))
# REAPER ouvert avant avec un autre projet : il reste en memoire un maitre L3 (disparu) a l'horloge figee
GM[0] = 1; GM[1] = 3; GM[2] = 0.5 * SR; GM[3] = 1234; GM[130 + 2] = T0 - 60
step(secs(0.1)); print('maitre fantome L3 pose     -> synchro : %s, esclave = %d' % (ms(), m.v_is_slave))
step(secs(3.0)); print('3 s plus tard              -> synchro : %s, esclave = %d' % (ms(), m.v_is_slave))
m.v_play_mode = 1.0; m.sec_slider()
seen = set(); step(secs(4.0), seen)
print('Slicer 4 s : pas joues = %s' % sorted(seen))
