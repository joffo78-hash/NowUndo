"""1er son d'une boucle libre : ou tombe-t-il ? Impulsion jouee au moment du REC. cd tools && python3 tstart.py . v327.jsfx [lat_ms]"""
import sys, math, re
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = sys.argv[2]; latms = float(sys.argv[3]) if len(sys.argv) > 3 else 0
A = load(path, 'start'); bench.jsfx_path_of[A] = path
GM = A.GM; m = A
m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
T0 = 100.0; A._clock[0] = T0
GM[955] = latms * SR / 1000
m.v_manual_id = 1.0; m.sec_init(); m.sec_slider()
N = [0]; HIT = [None]
def step(k=1):
    for _ in range(k):
        n0 = N[0]; A._clock[0] = T0 + n0 / SR; m.sec_block()
        for i in range(BLK):
            n = n0 + i; A._clock[0] = T0 + n / SR
            x = 0.0
            if HIT[0] is not None and 0 <= n - HIT[0] < 2400: x = 0.8 * math.sin(2 * math.pi * 300 * (n - HIT[0]) / SR) * math.exp(-(n - HIT[0]) / 800)
            m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
        N[0] = n0 + BLK
def cmd(c):
    b = 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200; GM[b + 48] = c
step(50)
cmd(1); HIT[0] = N[0]; step(int(1.0 * SR / BLK)); cmd(1); step(4)
L = int(m.v_length); buf = int(m.v_left_buf)
first = next((k for k in range(L) if abs(A.M[buf + k]) > 0.01), None)
print('latence %4.1f ms : boucle %.3f s, 1er son a %s ms du debut' % (latms, L / SR, 'aucun' if first is None else '%.1f' % (first * 1000 / SR)))
