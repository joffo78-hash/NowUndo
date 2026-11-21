"""LFO Random du Cloud (V3.27) : sauts (Smooth 0) / glissement (Smooth > 0). cd tools && cp ../NowUndo/NowUndo_V3.27.jsfx v327.jsfx && python3 tlfo.py ."""
import sys, math, re
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = 'v327.jsfx'
A = load(path, 'lfo'); bench.jsfx_path_of[A] = path
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
            x = 0.2 * math.sin(2 * math.pi * 220 * n / SR); m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
        N[0] = n0 + BLK
def b(): return 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200
def cmd(c): GM[b() + 48] = c
def par(i, v): GM[b() + 181] = v; GM[b() + 180] = i; step(1)
def secs(t): return int(t * SR / BLK)
cmd(1); step(secs(1.0)); cmd(1); step(4)
cmd(7); step(secs(0.3))                              # Cloud on
par(37, 1); par(39, 3); par(40, 4.0); par(41, 100)   # Free, Random, 4 Hz, depth 100
for sm in (0.0, 0.6):
    par(68, sm); step(secs(0.3))
    vals = []
    for k in range(secs(1.0)):
        step(1); vals.append(m.v_cl_lfo_sm)
    jumps = sum(1 for a, c in zip(vals, vals[1:]) if abs(c - a) > 0.2)
    nan = sum(1 for v in vals if v != v)
    print('smooth %.1f : forme=%d  publie(112000)=%.2f g39=%.0f g190=%.0f  valeurs %s  sauts>0.2/bloc=%d  NaN=%d' % (sm, m.v_cloud_lfo_shape, GM[112000 + int(m.v_inst_idx) * 60], GM[b() + 39], GM[b() + 190],
          ' '.join('%+.2f' % v for v in vals[::max(1, len(vals) // 12)]), jumps, nan))
