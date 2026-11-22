"""Looper seul a la souris (V3.27, 22 nov.) : clic sur REC a t0, le son part a t0 et arrive avec la latence d'entree ;
le clic atteint l'audio avec du retard (interface). cd tools && python3 tstart2.py . v327.jsfx <retard_clic_ms> <latence_ms> <LAT_ms|-1>"""
import sys, math, re
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = sys.argv[2]; clk = float(sys.argv[3]) / 1000; inl = float(sys.argv[4]) / 1000; latown = float(sys.argv[5])
A = load(path, 'start2'); bench.jsfx_path_of[A] = path
GM = A.GM; m = A
m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
T0 = 100.0; A._clock[0] = T0
m.v_manual_id = 1.0; m.v_lat_own = latown; m.sec_init(); m.sec_slider()
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
def secs(t): return int(t * SR / BLK)
step(50)
t_click = N[0]; HIT[0] = t_click + int(inl * SR)          # le son joue au clic arrive apres la latence d'entree
step(secs(clk)); m.v_rec_cmd = 1.0; m.v_ui_rec_t = T0 + t_click / SR   # le clic arrive a l'audio apres le retard de l'interface
step(secs(1.0)); t2 = N[0]; step(secs(clk)); m.v_rec_cmd = 1.0; m.v_ui_rec_t = T0 + t2 / SR; step(4)
L = int(m.v_length); buf = int(m.v_left_buf)
first = next((k for k in range(L) if abs(A.M[buf + k]) > 0.01), None)
print('clic %3.0f ms, latence %3.0f ms, LAT %4s : boucle %.3f s, 1er son a %s ms' % (clk * 1000, inl * 1000, 'auto' if latown < 0 else '%d' % latown,
      L / SR, 'aucun' if first is None else '%.1f' % (first * 1000 / SR)))
