"""Pics de calcul par bloc (decrochages temps reel) : Cloud / granulaire. cd tools && python3 tcpu.py . v327.jsfx [cloud|gran|off]"""
import sys, math, re, time
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = sys.argv[2]; mode = sys.argv[3] if len(sys.argv) > 3 else 'cloud'
A = load(path, 'cpu'); GM = A.GM; m = A
m.v_srate = float(SR); m.v_samplesblock = 128.0; m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
T0 = 100.0; A._clock[0] = T0; m.v_manual_id = 1.0; m.sec_init(); m.sec_slider()
B = 128; N = [0]; TIMES = []
def step(k=1, meas=False):
    for _ in range(k):
        n0 = N[0]; t = time.perf_counter(); A._clock[0] = T0 + n0 / SR; m.sec_block()
        for i in range(B):
            x = 0.3 * math.sin(2 * math.pi * 220 * (n0 + i) / SR); m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
        if meas: TIMES.append((time.perf_counter() - t, n0))
        N[0] = n0 + B
def cmd(c): GM[1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200 + 48] = c
cmd(1); step(int(2 * SR / B)); cmd(1); step(20)
if mode == 'cloud': m.v_cloud_on = 1.0; m.sec_slider()
elif mode == 'gran': m.v_speed = 1.5; m.v_link_on = 0.0; m.sec_slider()
step(int(3 * SR / B), True)
ts = sorted(t for t, _ in TIMES); med = ts[len(ts) // 2]
big = [(t / med, n) for t, n in TIMES if t > 4 * med]
print('%-6s blocs %d : median %.2f ms (python), max %.1f x la mediane, blocs > 4x : %d' % (mode, len(ts), med * 1000, ts[-1] / med, len(big)))
for r, n in sorted(big, reverse=True)[:8]: print('   bloc a %.3f s : %.1f x' % (n / SR, r))
