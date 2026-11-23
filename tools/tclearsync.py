"""Clear du maitre (V3.27, 23 nov.) : la synchro reste verrouillee tant qu'un looper a une boucle.
cd tools && cp ../NowUndo/NowUndo_V3.27.jsfx v327.jsfx && python3 tclearsync.py . v327.jsfx"""
import sys, math, re
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = sys.argv[2]
A = load(path, 'csA'); B = load(path, 'csB')
B.GM = A.GM; B._clock = A._clock; GM = A.GM
T0 = 100.0
for m, ident in ((A, 1), (B, 2)):
    m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
    for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
        setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
    A._clock[0] = T0; m.v_manual_id = float(ident); m.sec_init(); m.sec_slider()
N = [0]
def step(k=1):
    for _ in range(k):
        n0 = N[0]; A._clock[0] = T0 + n0 / SR
        for m in (A, B): m.sec_block()
        for i in range(BLK):
            x = 0.2 * math.sin(2 * math.pi * 220 * (n0 + i) / SR)
            for m in (A, B): m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
        N[0] = n0 + BLK
def cmd(m, c): GM[1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200 + 48] = c
def secs(t): return int(t * SR / BLK)
def st(t):
    print('%-36s synchro %s, horloge %.2f s pos %.2f s | L1 %.2f s | L2 %.2f s' % (t,
        {0: 'LIBRE', 1: 'VERROUILLEE (L%d)' % GM[1], 2: 'HOST'}[int(GM[0])], GM[2] / SR, GM[3] / SR, A.v_length / SR, B.v_length / SR))
cmd(A, 1); step(secs(2.0)); cmd(A, 1); step(4)
cmd(B, 1); step(secs(0.9)); cmd(B, 1); step(secs(2.5))
st('L1 maitre 2 s, L2 enregistre')
cmd(A, 2); step(secs(0.3)); p1 = GM[3]; step(secs(0.5)); p2 = GM[3]
st('Clear de L1'); print('   l horloge tourne : %.3f s -> %.3f s en 0,5 s' % (p1 / SR, p2 / SR))
cmd(A, 1); step(secs(1.3)); cmd(A, 1); step(secs(3.0))
st('L1 reenregistre ~1,3 s')
cmd(A, 2); step(4); cmd(B, 2); step(secs(0.5))
st('Clear de L1 puis de L2 (plus rien)')
cmd(A, 1); step(secs(2.0)); cmd(A, 1); step(secs(0.5))
st('nouveau REC de L1')
GM[0] = 0; step(secs(0.5)); cmd(A, 2); step(secs(0.5))
st('Unlock manuel puis Clear de L1')
