"""Ping-pong (V3.27) : on / off / on x4, trace de la tete (%, > avant, < arriere). cd tools && cp ../NowUndo/NowUndo_V3.27.jsfx v327.jsfx && python3 tpp.py ."""
import sys, math, re
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = 'v327.jsfx'
A = load(path, 'pp'); bench.jsfx_path_of[A] = path
GM = A.GM; m = A
m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
m.v_manual_id = 1.0; m.sec_init(); m.sec_slider()
N = [0]
def step(k=1):
    for _ in range(k):
        n0 = N[0]; A._clock[0] = n0 / SR; m.sec_block()
        for i in range(BLK):
            n = n0 + i; A._clock[0] = n / SR
            x = 0.1 * math.sin(2 * math.pi * 220 * n / SR); m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
        N[0] = n0 + BLK
def cmd(c):
    b = 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200; GM[b + 48] = c
def secs(t): return int(t * SR / BLK)
cmd(1); step(secs(1.0)); cmd(1); step(4)
L = m.v_length; print('length %.0f state %d sync_a %d' % (L, m.v_state, m.v_sync_a))
def trace(tag, dur, n=12):
    pts = []
    for k in range(n):
        step(secs(dur / n)); pts.append('%3d%s' % (round(100 * m.v_pos / L), '<' if m.v_effective_rev else '>'))
    print('%-14s pp=%d dir=%+d : %s' % (tag, m.v_pingpong_on, m.v_ping_pong_dir, ' '.join(pts)))
trace('normal', 1.0)
for k in range(4):
    cmd(5); step(1); trace('PP ON #%d' % (k + 1), 2.5, 20)
    step(secs(0.37 * (k + 1)))
    cmd(5); step(1); trace('PP OFF #%d' % (k + 1), 1.0, 8)
