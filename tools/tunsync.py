"""Unsync puis nouveau REC libre (nouvelle synchro, les anciens gardent la leur) + verrouillage manuel sur le looper
selectionne (comme LPF.sync_lock_selected du Launchpad). cd tools && cp ../NowUndo/NowUndo_V3.27.jsfx v327.jsfx && python3 tunsync.py . v327.jsfx"""
import sys, math, re
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = sys.argv[2]
L = [load(path, 'us%d' % k) for k in range(4)]
for m in L[1:]: m.GM = L[0].GM; m._clock = L[0]._clock
GM = L[0].GM; A, B, C, D = L
T0 = 100.0
for k, m in enumerate(L):
    m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
    for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
        setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
    A._clock[0] = T0; m.v_manual_id = float(k + 1); m.sec_init(); m.sec_slider()
N = [0]; JUMPS = {}
def step(k=1):
    for _ in range(k):
        n0 = N[0]; A._clock[0] = T0 + n0 / SR
        for m in L: m.sec_block()
        for i in range(BLK):
            x = 0.2 * math.sin(2 * math.pi * 220 * (n0 + i) / SR)
            for j, m in enumerate(L):
                p0 = m.v_pos; m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
                if m.v_length > 0 and m.v_state == 2:
                    d = (m.v_pos - p0) % m.v_length
                    if abs(d - 1) > 2 and abs(d - 1 - m.v_length) > 2: JUMPS[j] = JUMPS.get(j, 0) + 1
        N[0] = n0 + BLK
def cmd(m, c): GM[1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200 + 48] = c
def secs(t): return int(t * SR / BLK)
def ph(m): return (m.v_pos % m.v_length) / SR if m.v_length > 0 else -1
def st(t):
    print('%-44s synchro %-12s | L1 %.2f  L2 %.2f  L3 %.2f  L4 %.2f s | sauts %s' % (t,
        {0: 'LIBRE', 1: 'L%d (%.2f s)' % (GM[1], GM[2] / SR), 2: 'HOST'}[int(GM[0])],
        A.v_length / SR, B.v_length / SR, C.v_length / SR, D.v_length / SR, dict(JUMPS) or '-'))
cmd(A, 1); step(secs(2.0)); cmd(A, 1); step(4)
cmd(B, 1); step(secs(0.9)); cmd(B, 1); step(secs(2.5))
st('L1 maitre 2 s, L2 esclave')
dAB = (A.v_pos - B.v_pos * 1.0)
GM[0] = 0; step(secs(0.5)); st('UNSYNC (Launchpad)')
cmd(C, 1); step(secs(1.3)); cmd(C, 1); step(secs(3.0))
st('L3 enregistre 1,3 s apres unsync')
print('   L1 et L2 restent ensemble : ecart de phase avant %.4f s, apres %.4f s' % ((dAB % B.v_length) / SR, ((A.v_pos - B.v_pos) % B.v_length) / SR))
GM[0] = 0; step(2); GM[0] = 1; GM[1] = 2; step(secs(0.5))
st('verrouillage manuel sur L2 (selectionne)')
cmd(D, 1); step(secs(0.8)); cmd(D, 1); step(secs(2.5))
st('L4 enregistre ~0,8 s')
